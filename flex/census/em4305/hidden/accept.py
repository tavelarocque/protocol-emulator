#!/usr/bin/env python3
"""Hidden acceptance test for the blind EM4305 reader (transmit) firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (em4305.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet
fixes what the TX words mean, and this test builds them itself.

The chip is an RFID reader. P0 drives the reader's coil: a 125 kHz square
wave while the field is on, held low while it is off. Commands reach the
tag as gaps in the field. For each case (a list of commands, each a Login
with a 32-bit password or a Write word with a 4-bit address and a 32-bit
value) the test
  1. builds the TX words the task sheet defines: three per command,
  2. runs RUN_DIR/pe_sim on RUN_DIR/em4305.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per core clock cycle, 10 MHz),
  4. has sigrok-cli's `em4305` decoder (default options, 125 kHz coil) read
     it and requires, for every command in order and nothing else: one
     first field stop, exactly the command's bits, the command's name, the
     address, the four data bytes (and for a Login the password), every
     parity reported OK, the stop bit, and the end of write mode,
  5. checks, from the pin changes themselves, what the decoder does not:
     every edge of a command within +-2 cycles of its ideal place counted
     from the rise that ends the first field stop, every high pulse and
     every low between pulses outside commands 40 +-2 cycles, the field on
     for 320 to 1280 carrier periods before each command, at least 320
     whole pulses after the last one, and the first fall of P0 within 200
     cycles of the start of the run.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from P0's first change to the
    rise that ends the last command's stop bit>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
exit status is 0 only on a full pass. Python standard library and sigrok-cli
only. Written apart from the firmware and kept from its author."""
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

CLOCK_HZ = 10_000_000        # core clock: one cycle = 100 ns
HALF = 40                    # cycles of a carrier half period (125 kHz)
PERIOD = 2 * HALF            # one carrier period, one "field clock": 8 us
BIT = 32 * PERIOD            # one bit: 32 carrier periods, 256 us
ZERO_ON = 16                 # a 0 bit: the field on for its first 16 periods
FFS = 55                     # the first field stop: 55 periods with the field off
IDLE_MIN = 320               # carrier periods before each command, at least
IDLE_MAX = 1280              # and at most
TAIL_MIN = 320               # whole pulses after the last command, at least
FIRST_FALL_MAX = 200         # P0's first fall, at most this cycle
TOL = 2                      # cycles an edge may be from its ideal place
FFS_FIND = 3000              # a low longer than this is a first field stop
MAX_COMMANDS = 6             # commands in one run
MAX_ONES = 8                 # the test never sends more 1 bits in a row than this
WRITE = 0x100                # bit 8 of the first word: 1 = Write word, 0 = Login
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "tx", "help", "stimulus")  # pe_sim run's
PIN = 0                      # P0
HAND_IN = "em4305.s"


# ------------------------------------------------------------ the protocol

def frame_bits(cmd):
    """The bits of one command in the order they are sent, as the task
    sheet lists them. cmd is ("login", 0, value) or ("write", addr, value)."""
    kind, addr, value = cmd
    data = [(value >> (8 * r)) & 0xFF for r in range(4)]   # least significant byte first
    out = [0]                                               # the leading 0
    if kind == "login":
        out += [0, 0, 1, 1]
    else:
        a = [(addr >> k) & 1 for k in range(4)]             # address, bit 0 first
        out += [0, 1, 0, 1] + a + [0, 0, sum(a) & 1]
    for byte in data:
        row = [(byte >> k) & 1 for k in range(7, -1, -1)]   # each byte bit 7 first
        out += row + [sum(row) & 1]                         # even row parity
    col = data[0] ^ data[1] ^ data[2] ^ data[3]
    out += [(col >> k) & 1 for k in range(7, -1, -1)]       # column parity
    out += [0]                                              # stop bit
    return out


def ideal_edges(bits):
    """[(cycle after the rise that ends the first field stop, level)] for
    every edge of a command: the last pulse before its first field stop,
    every pulse of its bits, and the rise that ends its stop bit."""
    out = [(-(FFS + 1) * PERIOD, 1), (-(FFS + 1) * PERIOD + HALF, 0)]
    for k, b in enumerate(bits):
        for p in range(32 if b else ZERO_ON):
            out += [(k * BIT + p * PERIOD, 1), (k * BIT + p * PERIOD + HALF, 0)]
    out.append((len(bits) * BIT, 1))
    return out


# ------------------------------------------------------- the host interface

def tx_words(commands):
    """The TX words of one run, as the task sheet defines them: three per
    command. First: 0x0000 for a Login, 0x0100 | address for a Write word.
    Then the 32-bit value's bits 15..0, then its bits 31..16. Payload only:
    nothing about the line."""
    words = []
    for kind, addr, value in commands:
        words.append(WRITE | addr if kind == "write" else 0)
        words += [value & 0xFFFF, value >> 16]
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name)."""
    i = 0
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits == ["tx"] or hits == ["cycles"]:
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        i += 2
    return None


# ------------------------------------------------- from pe_sim to a capture

def p0_changes(sim_stdout):
    """[(cycle, level)] of P0 from pe_sim's "pins CYCLE XX" lines: the level
    at the first line, then only the cycles at which it changed."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, level = int(part[1]), (int(part[2], 16) >> PIN) & 1
            if not out or out[-1][1] != level:
                out.append((cycle, level))
    return out


def write_vcd(path, changes, cycles):
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for cycle, level in changes:
            if cycle < cycles:
                f.write("#%d\n%d!\n" % (cycle, level))
        f.write("#%d\n" % cycles)


def sigrok(path, classes):
    """[(start sample, end sample, text)] of the decoder's annotations of
    the given classes."""
    cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", "em4305:data=P0",
           "-A", "em4305=" + ":".join(classes), "--protocol-decoder-samplenum"]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)$", line)
        if m:
            found.append((int(m.group(1)), int(m.group(2)), m.group(3)))
    return sorted(found, key=lambda a: (a[0], a[1]))


# ------------------------------------------------------------ the two checks

def name(cmd):
    kind, addr, value = cmd
    return ("Login 0x%08X" % value) if kind == "login" else ("Write %d 0x%08X" % (addr, value))


def wanted_fields(cmd):
    """What the decoder must report for a command, beyond its bits: the
    opcode row and the address row, in the order it reports them, and the
    32-bit value it prints for a Login or a write to word 2."""
    kind, addr, value = cmd
    data = [(value >> (8 * r)) & 0xFF for r in range(4)]
    if kind == "login":
        ops = ["Login"] + ["Row parity OK"] * 5
        addrs = []
        extra = ["Login password: %X" % value]
    else:
        ops = ["Write word", "Row parity OK", "Zero bits"] + ["Row parity OK"] * 5
        addrs = ["Addr: %d" % addr]
        extra = ["Write password: %X" % value] if addr == 2 else []
    ops += ["Column parity OK", "Stop bit"]
    addrs += ["Data: %X" % b for b in data]
    return ops, addrs, extra


def check_decoder(commands, changes, cycles):
    """The decoder must read exactly the wanted commands, and nothing else."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        bits = sigrok(path, ["bit_value"])
        frame = sigrok(path, ["first_field_stop", "write_mode_exit"])
        fields = sigrok(path, ["opcode", "address"])
        decode = sigrok(path, ["bitrate"])
    ffs = [a for a in frame if a[2] == "First field stop"]
    exits = [a for a in frame if a[2] == "Write mode exit"]
    errs = []
    if len(ffs) != len(commands):
        errs.append("the decoder found %d first field stops, wanted %d" % (len(ffs), len(commands)))
    if len(exits) != len(commands):
        errs.append("the decoder left write mode %d times, wanted %d" % (len(exits), len(commands)))
    if errs:
        return errs
    used = 0
    for k, (cmd, f, x) in enumerate(zip(commands, ffs, exits)):
        lo, hi = f[1], x[0]       # from the end of the field stop to the end of the last gap
        if not (f[0] < lo <= hi):
            errs.append("command %d: the decoder's field stop and write mode exit are out of order" % k)
            break
        inside = lambda a: lo <= a[0] <= hi
        got = "".join(a[2] for a in bits if inside(a))
        used += sum(1 for a in bits if inside(a))
        want = "".join(str(b) for b in frame_bits(cmd))
        if got != want:
            if len(got) != len(want):
                errs.append("command %d (%s): decoded %d bits, wanted %d" % (k, name(cmd), len(got), len(want)))
            else:
                i = next(i for i in range(len(want)) if got[i] != want[i])
                errs.append("command %d (%s): bit %d decoded as %s" % (k, name(cmd), i, got[i]))
            continue
        ops, addrs, extra = wanted_fields(cmd)
        got_ops = [a[2] for a in fields if inside(a) and not a[2].startswith(("Addr:", "Data:"))]
        got_addrs = [a[2] for a in fields if inside(a) and a[2].startswith(("Addr:", "Data:"))]
        if got_ops != ops:
            errs.append("command %d (%s): decoder reports %s, wanted %s"
                        % (k, name(cmd), [t for t in got_ops if t not in ops] or got_ops, ops))
        if got_addrs != addrs:
            errs.append("command %d (%s): decoder reads %s, wanted %s" % (k, name(cmd), got_addrs, addrs))
        got_extra = [a[2] for a in decode if inside(a) and a[2].startswith(("Login password", "Write password"))]
        if got_extra != extra:
            errs.append("command %d (%s): decoder printed %s, wanted %s" % (k, name(cmd), got_extra, extra))
    if used != len(bits):
        errs.append("the decoder found %d bits outside the commands" % (len(bits) - used))
    return errs


def check_waveform(commands, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to.
    Returns (objections, cycle of the rise ending the last stop bit or None)."""
    errs = []
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"], None
    if changes[0][1] != 1:
        errs.append("P0 is low at cycle 0")
    edges = changes[1:]
    if not edges:
        return errs + ["P0 never changes: no carrier"], None
    if edges[0][1] != 0 or edges[0][0] > FIRST_FALL_MAX:
        errs.append("P0's first change is %s at cycle %d: wanted a fall by cycle %d"
                    % ("a rise" if edges[0][1] else "a fall", edges[0][0], FIRST_FALL_MAX))
    # The first field stops: lows longer than FFS_FIND cycles; the rise after each.
    stops = [i for i in range(1, len(edges))
             if edges[i][1] == 1 and edges[i - 1][1] == 0 and edges[i][0] - edges[i - 1][0] > FFS_FIND]
    if len(stops) != len(commands):
        errs.append("%d first field stops (lows over %d cycles), wanted %d commands"
                    % (len(stops), FFS_FIND, len(commands)))
        return errs, None
    idle = []                  # (first index, last index) of each stretch outside commands
    seg_start = 0
    seg_cycle = edges[1][0] if len(edges) > 1 else 0   # the first rise: the first whole period
    end = None
    for k, (cmd, i) in enumerate(zip(commands, stops)):
        r = edges[i][0]
        want = ideal_edges(frame_bits(cmd))
        first = i - 2          # the last pulse before the field stop
        if first < seg_start:
            errs.append("command %d: no carrier pulse before its first field stop" % k)
            return errs, None
        got = edges[first:first + len(want)]
        for n, ((w, wl), (c, l)) in enumerate(zip(want, got)):
            if l != wl or abs(c - r - w) > TOL:
                errs.append("command %d (%s): edge %d (%s) is %d cycles from the rise ending the field stop, ideal %d (limit +-%d)"
                            % (k, name(cmd), n, "rise" if l else "fall", c - r, w, TOL))
                break
        else:
            if len(got) != len(want):
                errs.append("command %d (%s): only %d of its %d edges (the field must come back on after the stop bit)"
                            % (k, name(cmd), len(got), len(want)))
        idle.append((seg_start, first))
        before = (r - FFS * PERIOD) - seg_cycle
        if not (IDLE_MIN * PERIOD - TOL <= before <= IDLE_MAX * PERIOD + TOL):
            errs.append("command %d: the field is on for %d cycles before its field stop, wanted %d to %d (%d to %d periods)"
                        % (k, before, IDLE_MIN * PERIOD, IDLE_MAX * PERIOD, IDLE_MIN, IDLE_MAX))
        seg_start = first + len(want) - 1          # the rise that ends the stop bit
        if seg_start >= len(edges):
            return errs, None
        seg_cycle = end = edges[seg_start][0]
    idle.append((seg_start, len(edges) - 1))
    for n, (a, b) in enumerate(idle):
        for j in range(a, b):
            width = edges[j + 1][0] - edges[j][0]
            if abs(width - HALF) > TOL:
                where = "before the first command" if n == 0 else "after command %d" % (n - 1)
                errs.append("%s: a %s of P0 lasts %d cycles at cycle %d, wanted %d +-%d"
                            % (where, "high" if edges[j][1] else "low", width, edges[j][0], HALF, TOL))
                break
    a, b = idle[-1]
    pulses = sum(1 for j in range(a, b) if edges[j][1] == 1 and edges[j + 1][1] == 0)
    if pulses < TAIL_MIN:
        errs.append("after the last command the field stays on for %d whole pulses, wanted at least %d"
                    % (pulses, TAIL_MIN))
    return errs, end


def judge(commands, sim_stdout, cycles):
    """(every objection to one run, each marked with its check; the rise
    ending the last stop bit, or None)."""
    changes = p0_changes(sim_stdout)
    werrs, end = check_waveform(commands, changes, cycles)
    errs = ["waveform: " + e for e in werrs]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(commands, changes, cycles)]
    return errs, end, changes


# ------------------------------------------------------------------ running

def run_cycles(commands):
    """Long enough for the slowest timing the sheet allows, with room after."""
    return (FIRST_FALL_MAX + sum(IDLE_MAX * PERIOD + FFS * PERIOD + len(frame_bits(c)) * BIT
                                 for c in commands) + (TAIL_MIN + 80) * PERIOD)


def run_case(run_dir, args, commands):
    """(objections, (payload bytes, cycles) or None)."""
    words = tx_words(commands)
    cycles = run_cycles(commands)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, HAND_IN),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    errs, end, changes = judge(commands, out.stdout, cycles)
    span = (4 * len(commands), end - changes[1][0]) if end is not None and len(changes) > 1 else None
    return errs, span


def longest_ones(cmd):
    """The longest run of 1 bits a command puts on the line."""
    return max(len(run) for run in "".join(map(str, frame_bits(cmd))).split("0"))


def readable(cmd):
    """sigrok's decoder leaves write mode after 300 carrier periods without a
    gap, so it cannot read nine 1 bits in a row (9 x 32 + 16 periods). The
    test sends only values that avoid them; the task sheet says so."""
    return longest_ones(cmd) <= MAX_ONES


def rand_command(rng):
    while True:
        if rng.random() < 0.4:
            cmd = ("login", 0, rng.getrandbits(32))
        else:
            cmd = ("write", rng.randrange(16), rng.getrandbits(32))
        if readable(cmd):
            return cmd


def cases_for(seed):
    """(name, commands): fixed cases, then seeded random ones."""
    L = lambda v: ("login", 0, v)
    W = lambda a, v: ("write", a, v)
    fixed = [
        ("login, password 0", [L(0x00000000)]),
        ("login, eight 1 bits in a row", [L(0x7F7F7F7F)]),
        ("the task sheet's examples", [L(0x12345678), W(4, 0xDEADBEEF)]),
        ("write, address bits", [W(15, 0x00000000), W(0, 0xFFFFFFFF), W(1, 0x80000001), W(8, 0x00010080)]),
        ("writes to words 2, 5 and 6", [W(2, 0x0BADF00D), W(5, 0xFE8040C0), W(6, 0x7F3E1C08)]),
        ("alternating bits", [L(0xAAAAAAAA), W(10, 0x55555555), L(0x5555AAAA)]),
        ("six commands", [W(3, 0x01020304), L(0xC0FFEE00), W(7, 0x80808080), W(12, 0x7E00FF00),
                          L(0x00000001), W(9, 0xFEDCBA98)]),
    ]
    assert all(readable(c) for _, cmds in fixed for c in cmds)
    assert all(len(cmds) <= MAX_COMMANDS for _, cmds in fixed)
    rng = random.Random(seed)
    rand = [("random %d" % n, [rand_command(rng) for _ in range(rng.randint(1, 4))]) for n in range(8)]
    return fixed + rand


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for fname in ("pe_sim", HAND_IN, "run_args.txt"):
        if not os.path.exists(os.path.join(run_dir, fname)):
            setup.append("%s is missing from %s" % (fname, run_dir))
    args = []
    if not setup:
        try:
            with open(os.path.join(run_dir, "run_args.txt")) as f:
                lines = [l for l in f.read().splitlines() if l.strip()]
            if len(lines) > 1:
                setup.append("run_args.txt must be one line")
            args = shlex.split(" ".join(lines))
        except (OSError, ValueError) as e:
            setup.append("run_args.txt: %s" % e)
        problem = args_problem(args)
        if problem:
            setup.append(problem)
    if setup:
        print("setup: FAIL: " + "; ".join(setup))
        print("ACCEPT FAIL")
        return 1
    failed, rate = 0, None
    for n, (cname, commands) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, commands)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs and span:
            rate = span
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d command%s): %s"
              % (n, cname, len(commands), "" if len(commands) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
