#!/usr/bin/env python3
"""Hidden acceptance test for the blind T55xx reader (downlink) firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (t55xx.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. There is no
host-side code: the task sheet fixes what the TX words mean, and this test
builds them itself.

For each case (a list of commands: standard writes, protected writes and
resets) the test
  1. builds the TX words the task sheet defines (a header word, then the
     password's two words for a protected write, then the data's two words
     for any write),
  2. runs RUN_DIR/pe_sim on RUN_DIR/t55xx.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per core clock cycle, 10 MHz),
  4. has sigrok-cli's `t55xx` decoder (coil 125 kHz, start gap and write gap
     minimum 8 field clocks, the rest default) read it, and requires its
     annotations (start gaps, bit values, write mode exits, opcode,
     password, lock, data, address) to be exactly those of the wanted
     commands, in order, with nothing extra,
  5. checks, from the pin changes themselves, every limit of the task sheet
     the decoder does not hold to: the carrier's half period, that gaps are
     low, the length of every start gap, write gap and bit, the carrier
     before each command and after it, and the first change of P0.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
payload bytes of a case are 4 for each 32-bit field it sends (data and
password), 0 for a reset. The exit status is 0 only on a full pass. Python
standard library and sigrok-cli only. Written apart from the firmware and
kept from its author."""
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
FC = 80                      # one field clock (125 kHz) in cycles: 8 us
HALF_MIN, HALF_MAX = 38, 42  # a carrier half period, cycles (nominal 40)
GAP_LEVEL = 0                # the field is off: P0 low
FIRST_MAX = 400              # P0's first change by this cycle
LEAD_MIN = 100 * FC          # carrier before a start gap, at least
LEAD_MAX = 1000 * FC         # and at most
TAIL_MIN = 100 * FC          # carrier after a command's last gap, at least
SGAP = (10 * FC, 50 * FC)    # start gap, edge to edge
WGAP = (10 * FC, 30 * FC)    # write gap, edge to edge
ZERO = (18 * FC, 29 * FC)    # a 0: carrier from the end of one gap to the start of the next
ONE = (50 * FC, 61 * FC)     # a 1
MAX_COMMANDS = 8
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
PIN = 0
DECODER = "t55xx:data=P0:coilfreq=125000:start_gap=8:w_gap=8"
CLASSES = "bit_value:opcode:password:lock:data:address:write_mode_exit:start_gap"


# ------------------------------------------------------ commands and words

def std(op, lock, data, addr):
    return {"kind": "std", "op": op, "lock": lock, "data": data, "addr": addr}


def pwd(op, password, lock, data, addr):
    return {"kind": "pwd", "op": op, "pwd": password, "lock": lock, "data": data, "addr": addr}


def reset():
    return {"kind": "reset", "op": 0}


def tx_words(commands):
    """The TX words of one run, as the task sheet defines them. Header:
    bits 1..0 the opcode, bit 2 the lock bit, bits 5..3 the address, bit 6
    set for a protected write, bit 7 set for a reset, the rest 0. Then for a
    protected write the password's high and low halves, then for any write
    the data's high and low halves. A reset is the header 0x0080 alone.
    Payload only: nothing about the line."""
    words = []
    for c in commands:
        if c["kind"] == "reset":
            words.append(0x80)
            continue
        h = c["op"] | (c["lock"] << 2) | (c["addr"] << 3)
        if c["kind"] == "pwd":
            words += [h | 0x40, c["pwd"] >> 16, c["pwd"] & 0xFFFF]
        else:
            words.append(h)
        words += [c["data"] >> 16, c["data"] & 0xFFFF]
    return words


def msb_bits(value, n):
    return [(value >> (n - 1 - k)) & 1 for k in range(n)]


def command_bits(c):
    """The bits of a command in the order they go on the line."""
    bits = msb_bits(c["op"], 2)
    if c["kind"] == "reset":
        return bits
    if c["kind"] == "pwd":
        bits += msb_bits(c["pwd"], 32)
    return bits + [c["lock"]] + msb_bits(c["data"], 32) + msb_bits(c["addr"], 3)


def decoder_texts(c):
    """What sigrok's t55xx decoder says about one command, in its order."""
    out = ["Start gap"] + [str(b) for b in command_bits(c)] + ["Write mode exit"]
    out.append("Opcode: %d%d" % ((c["op"] >> 1) & 1, c["op"] & 1))
    if c["kind"] == "reset":
        return out
    if c["kind"] == "pwd":
        out.append("Password: %X" % c["pwd"])
    return out + ["Lock: %X" % c["lock"], "Data: %X" % c["data"], "Addr: %X" % c["addr"]]


def payload_bytes(commands):
    return sum({"reset": 0, "std": 4, "pwd": 8}[c["kind"]] for c in commands)


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


def sigrok_texts(changes, cycles):
    """The texts of the decoder's annotations of interest, in its order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", DECODER,
               "-A", "t55xx=" + CLASSES, "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if out.returncode != 0 or out.stderr.strip():
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)$", line)
        if m:
            found.append(m.group(3).strip())
    return found


# ------------------------------------------------------------ the two checks

def check_decoder(commands, changes, cycles):
    got = sigrok_texts(changes, cycles)
    want = [t for c in commands for t in decoder_texts(c)]
    if got == want:
        return []
    i = next((i for i in range(min(len(got), len(want))) if got[i] != want[i]), min(len(got), len(want)))
    # which command is that in
    n, k = 0, i
    for c in commands:
        if k < len(decoder_texts(c)):
            break
        k -= len(decoder_texts(c))
        n += 1
    g = got[i] if i < len(got) else "nothing"
    w = want[i] if i < len(want) else "nothing"
    return ["annotation %d (command %d, item %d) is %r, wanted %r; %d annotations, wanted %d"
            % (i, n, k, g, w, len(got), len(want))]


def check_waveform(commands, changes, cycles):
    """The limits of the task sheet, read straight from the pin changes.
    Every interval between two changes of P0 is either a carrier half
    period or a gap; the carrier between gaps is a bit, or the lead-in
    before a command, or the tail after one."""
    errs = []
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    edges = changes[1:]
    if not edges:
        return ["P0 never changes"]
    if edges[0][0] > FIRST_MAX:
        errs.append("P0 first changes at cycle %d, limit %d" % (edges[0][0], FIRST_MAX))
    found = []            # bit lists of the commands read off the line
    cur = None            # bits of the command being read, or None between commands
    anchor = edges[0][0]  # where the present stretch of carrier began
    for (a, level), (b, _) in zip(edges, edges[1:]):
        d = b - a
        if HALF_MIN <= d <= HALF_MAX:
            continue
        if d < SGAP[0] and d < WGAP[0]:
            errs.append("an interval of %d cycles at cycle %d is neither a carrier half period (%d to %d) nor a gap (%d or more)"
                        % (d, a, HALF_MIN, HALF_MAX, WGAP[0]))
            break
        if level != GAP_LEVEL:
            errs.append("a gap of %d cycles at cycle %d holds P0 high: the field is off in a gap, P0 low" % (d, a))
            break
        on = a - anchor   # carrier from the end of the last gap to this one
        if cur is not None and on < LEAD_MIN:
            if ZERO[0] <= on <= ZERO[1]:
                cur.append(0)
            elif ONE[0] <= on <= ONE[1]:
                cur.append(1)
            else:
                errs.append("command %d, bit %d: carrier of %d cycles between gaps (cycle %d to %d), "
                            "a 0 is %d to %d and a 1 %d to %d"
                            % (len(found), len(cur), on, anchor, a, ZERO[0], ZERO[1], ONE[0], ONE[1]))
                break
            if not WGAP[0] <= d <= WGAP[1]:
                errs.append("command %d: write gap of %d cycles at cycle %d, limits %d to %d"
                            % (len(found), d, a, WGAP[0], WGAP[1]))
                break
        else:
            # a start gap: the carrier before it is a lead-in
            if cur is not None:
                found.append(cur)
            if on < LEAD_MIN:
                errs.append("carrier of %d cycles before the start gap at cycle %d, at least %d"
                            % (on, a, LEAD_MIN))
                break
            if on > LEAD_MAX:
                errs.append("carrier of %d cycles before the start gap at cycle %d, at most %d"
                            % (on, a, LEAD_MAX))
                break
            if not SGAP[0] <= d <= SGAP[1]:
                errs.append("start gap of %d cycles at cycle %d, limits %d to %d" % (d, a, SGAP[0], SGAP[1]))
                break
            cur = []
        anchor = b
    else:
        last = edges[-1][0]
        if cur is not None:
            if last - anchor < TAIL_MIN:
                errs.append("the carrier runs %d cycles after the last gap (cycle %d), at least %d wanted"
                            % (last - anchor, anchor, TAIL_MIN))
            found.append(cur)
    if errs:
        return errs
    want = [command_bits(c) for c in commands]
    if len(found) != len(want):
        errs.append("%d commands on the line, wanted %d" % (len(found), len(want)))
    for n, (g, w) in enumerate(zip(found, want)):
        if g != w:
            if len(g) != len(w):
                errs.append("command %d has %d bits, wanted %d" % (n, len(g), len(w)))
            else:
                i = next(i for i in range(len(w)) if g[i] != w[i])
                errs.append("command %d: bit %d is %d, wanted %d" % (n, i, g[i], w[i]))
            break
    return errs


def judge(commands, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = p0_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(commands, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(commands, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(commands):
    """Long enough for the slowest waveform the sheet allows, and the tail."""
    total = FIRST_MAX
    for c in commands:
        total += LEAD_MAX + SGAP[1] + len(command_bits(c)) * (ONE[1] + WGAP[1])
    return total + TAIL_MIN + 20_000


def run_case(run_dir, args, commands):
    """(objections, cycles from P0's first change to its last or None)."""
    words = tx_words(commands)
    cycles = run_cycles(commands)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "t55xx.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in p0_changes(out.stdout)[1:]]
    return judge(commands, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def random_command(rng):
    r = rng.random()
    if r < 0.15:
        return reset()
    op, lock, addr, data = rng.choice((2, 3)), rng.randrange(2), rng.randrange(8), rng.randrange(1 << 32)
    if r < 0.55:
        return pwd(op, rng.randrange(1 << 32), lock, data, addr)
    return std(op, lock, data, addr)


def cases_for(seed):
    """(name, commands): fixed cases, then seeded random ones."""
    fixed = [
        ("standard write of zeros", [std(2, 0, 0x00000000, 0)]),
        ("standard write of ones", [std(3, 1, 0xFFFFFFFF, 7)]),
        ("the task sheet's example", [pwd(2, 0x12345678, 1, 0x9ABCDEF0, 5), reset(),
                                      std(3, 0, 0xFFFF0001, 2)]),
        ("a reset alone", [reset()]),
        ("alternating bits", [std(2, 1, 0x55555555, 5), pwd(3, 0xAAAAAAAA, 0, 0x5555AAAA, 2)]),
        ("eight commands", [reset(), std(2, 0, 0x80000001, 1), pwd(2, 0, 0, 0, 0), reset(),
                            pwd(3, 0xFFFFFFFF, 1, 0xFFFFFFFF, 7), std(3, 1, 0x00010000, 4),
                            reset(), std(2, 0, 0xC0FFEE00, 6)]),
    ]
    rng = random.Random(seed)
    rand = [("random %d" % n, [random_command(rng) for _ in range(rng.randint(1, 5 if n < 7 else MAX_COMMANDS))])
            for n in range(8)]
    return fixed + rand


def describe(commands):
    kinds = {"std": "write", "pwd": "protected write", "reset": "reset"}
    return ", ".join(kinds[c["kind"]] for c in commands)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "t55xx.s", "run_args.txt"):
        if not os.path.exists(os.path.join(run_dir, name)):
            setup.append("%s is missing from %s" % (name, run_dir))
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
    for n, (name, commands) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, commands)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (payload_bytes(commands), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %s): %s" % (n, name, describe(commands), status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
