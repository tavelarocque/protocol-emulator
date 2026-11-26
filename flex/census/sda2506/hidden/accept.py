#!/usr/bin/env python3
"""Hidden acceptance test for the blind SDA 2506 host firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (sda2506.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. There is no host
code: the task sheet fixes what the TX and RX words mean, and this test
builds the TX words itself.

The chip is the host of a Siemens SDA 2506 serial EEPROM: P0 CLK, P1 DATA
(open drain, shared with the EEPROM), P2 CE. It both sends (write, erase and
read commands) and receives (the byte a read returns). The EEPROM is a
scripted waveform on P1 (-stimulus): it cannot react, so the task sheet
fixes the cycle of every CLK and CE edge, and the EEPROM's reply is placed
by that schedule.

For each case (a list of operations, and the EEPROM's starting contents)
the test
  1. builds the TX words the task sheet defines (one per operation),
  2. builds the EEPROM's reply as a stimulus file, and first checks that
     sigrok's sda2506 decoder, given the ideal host waveform and that reply,
     decodes exactly the case's operations and read bytes (so the input is a
     real instance of the protocol),
  3. runs RUN_DIR/pe_sim on RUN_DIR/sda2506.s with those words and that
     stimulus,
  4. builds the bus from the printed pin changes (DATA is the wired AND of
     the chip's open-drain output and the EEPROM's), writes it as a logic
     capture (VCD, one sample per core clock cycle, 10 MHz), and requires
     sigrok's sda2506 decoder to decode exactly the case's operations and
     read bytes, in order, with nothing extra,
  5. checks from the pin changes what the decoder does not: every CLK and CE
     edge within +-2 cycles of its place in the schedule, nothing else on
     CLK or CE, CLK low by cycle 1000, DATA's setup and hold windows and its
     level at the fall of CE, DATA released whenever it carries nothing,
     the 20 ms programming time, a quiet line after the last operation,
  6. requires the RX words to be the read bytes, in order, nothing extra.

Prints one line per case, then for the last case that passed
    RATE bytes=<data bytes written and read> cycles=<first to last pin change>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
exit status is 0 only on a full pass. Python standard library and sigrok-cli
only. Written apart from the firmware and kept from its author."""
import bisect
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

CLOCK_HZ = 10_000_000      # core clock: one cycle = 100 ns
BIT = 200                  # one clock slot: 20 us
RISE, FALL = 50, 150       # CLK rises and falls this far into its slot
WIN = 20                   # DATA may change within +-20 cycles of a slot boundary
TOL = 2                    # CLK and CE edges: +-2 cycles from their place
PROG = 200_000             # 20 ms: CE low after the start pulse (from the slot after it)
NEXT = 150                 # from CE rising to the next operation's first slot
FIRST = 2000               # the first operation's first slot
CLK_LOW_BY = 1000          # CLK must have fallen by this cycle
DEV_DELAY = 10             # the EEPROM changes DATA 1 us after CLK falls / CE rises
TAIL = 2000                # cycles run after the last CE rise
MAX_OPS = 8
SAMPLE = 10                # cycles per sample of the capture given to sigrok (1 MHz)
CLK, DATA, CE = 0, 1, 2    # pins
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")

READ, ERASE, WRITE = "R", "E", "W"


# ------------------------------------------------------- the host interface

def tx_word(op):
    """One word per operation, as the task sheet defines it.
    Write: bit 15 = 1, bits 14..8 address, bits 7..0 data.
    Read:  bit 15 = 0, bits 14..8 address, bits 7..0 = 0x00.
    Erase: bit 15 = 0, bits 14..8 address, bits 7..0 = 0x01."""
    kind, addr, data = op
    if kind == WRITE:
        return 0x8000 | addr << 8 | data
    return addr << 8 | (1 if kind == ERASE else 0)


def tx_words(ops):
    return [tx_word(op) for op in ops]


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name)."""
    i = 0
    modes = {}
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) == 1 and hits[0] in ("tx", "cycles", "stimulus", "inputs"):
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            for item in args[i + 1].split(","):
                pin, _, mode = item.partition("=")
                modes[pin.strip()] = mode.strip()
        i += 2
    for pin, mode in (("0", "pp"), ("1", "od"), ("2", "pp")):
        if modes.get(pin) != mode:
            return "run_args.txt must make P%s %s (the task sheet), found %r" % (pin, mode, modes.get(pin))
    return None


# ------------------------------------------------------------ the protocol

def command_bits(op):
    """The bits shifted in while CE is high, in the order sent."""
    kind, addr, data = op
    a = [(addr >> k) & 1 for k in range(7)]
    if kind == WRITE:
        return [(data >> k) & 1 for k in range(8)] + a + [1]
    return a + [1 if kind == ERASE else 0]


def run_memory(ops, memory):
    """The byte each read returns: erase sets 0xFF, write clears the bits that
    are 0 in its data (the SDA 2506 programs zeros only), read leaves it."""
    mem = dict(memory)
    out = []
    for kind, addr, data in ops:
        if kind == ERASE:
            mem[addr] = 0xFF
        elif kind == WRITE:
            mem[addr] = mem[addr] & data
        else:
            out.append(mem[addr])
    return out


def schedule(ops):
    """The ideal schedule. Returns (clk_edges, ce_edges, data_req, reads, end)
    where the edge lists are [(cycle, new level)], data_req is a list of
    (start, end, level) intervals in which the chip's DATA output must hold
    that level (the gaps between them are the change windows), reads is a
    list of (first CLK fall of the read, CE rise) per read, and end is the
    last CE rise."""
    clk, ce, req, reads = [], [], [], []
    s = FIRST
    level_from = 0        # DATA must be 1 from here until the next window
    for op in ops:
        bits = command_bits(op)
        n = len(bits)
        win = lambda j: (s + BIT * j - WIN, s + BIT * j + WIN)  # noqa: E731
        req.append((level_from, win(0)[0], 1))
        for j, b in enumerate(bits):
            clk += [(s + BIT * j + RISE, 1), (s + BIT * j + FALL, 0)]
            req.append((win(j)[1], win(j + 1)[0], b))
        ce.append((s + BIT * n + RISE, 0))
        if op[0] == READ:
            for i in range(1, 9):
                clk += [(s + BIT * (n + i) + RISE, 1), (s + BIT * (n + i) + FALL, 0)]
            rise = s + BIT * (n + 9) + RISE
            reads.append((s + BIT * (n + 1) + FALL, rise))
            level_from = win(n)[1]
        else:
            sel = 0 if op[0] == WRITE else 1
            clk += [(s + BIT * (n + 1) + RISE, 1), (s + BIT * (n + 1) + FALL, 0)]
            req.append((win(n)[1], win(n + 2)[0], sel))
            rise = s + BIT * (n + 2) + PROG
            level_from = win(n + 2)[1]
        ce.append((rise, 1))
        s = rise + NEXT
    end = ce[-1][0]
    req.append((level_from, end + TAIL, 1))
    return clk, ce, req, reads, end


def device_levels(ops, memory):
    """The EEPROM's own drive of DATA over time, as [(cycle, level)]: released
    (1) except in a read, where bit k of the byte is on the line from 1 us
    after the (k+1)th CLK fall after CE falls until 1 us after the next fall,
    and bit 7 until 1 us after CE rises."""
    _, _, _, reads, _ = schedule(ops)
    out = [(0, 1)]
    for (first_fall, rise), byte in zip(reads, run_memory(ops, memory)):
        for k in range(8):
            out.append((first_fall + BIT * k + DEV_DELAY, (byte >> k) & 1))
        out.append((rise + DEV_DELAY, 1))
    merged = []
    for c, v in out:
        if merged and merged[-1][1] == v:
            continue
        merged.append((c, v))
    return merged


def stimulus_text(dev):
    return "".join("%d %02x\n" % (c, 0xFF if v else 0xFF ^ (1 << DATA)) for c, v in dev)


def ideal_pins(ops):
    """The ideal host's outputs as pin changes [(cycle, byte)]: CLK falls at
    cycle 10, then the schedule."""
    clk, ce, req, _, _ = schedule(ops)
    ev = [(10, CLK, 0)] + [(c, CLK, v) for c, v in clk] + [(c, CE, v) for c, v in ce]
    prev = 1
    for a, b, v in req:
        if v != prev:
            ev.append((a, DATA, v))   # change at the last cycle of the window
            prev = v
    ev.sort()
    pins, out = 0xFF, [(0, 0xFF)]
    for c, p, v in ev:
        pins = (pins & ~(1 << p)) | (v << p)
        if out[-1][0] == c:
            out[-1] = (c, pins)
        else:
            out.append((c, pins))
    return out


# ------------------------------------------------- from pe_sim to a capture

def parse_sim(text):
    """([(cycle, pins byte)], [rx word]) from pe_sim's output."""
    pins, rx = [], []
    for line in text.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            pins.append((int(part[1]), int(part[2], 16)))
        elif len(part) == 3 and part[0] == "rx":
            rx.append(int(part[2], 0))
    return pins, rx


def pin_changes(pins, p):
    """[(cycle, level)] of pin p: its level at the first line, then changes."""
    out = []
    for c, v in pins:
        b = (v >> p) & 1
        if not out or out[-1][1] != b:
            out.append((c, b))
    return out


def level_at(changes, t):
    i = bisect.bisect_right([c for c, _ in changes], t) - 1
    return changes[i][1] if i >= 0 else None


def wired_and(a, b):
    times = sorted(set(c for c, _ in a) | set(c for c, _ in b))
    out = []
    for t in times:
        v = level_at(a, t) & level_at(b, t)
        if not out or out[-1][1] != v:
            out.append((t, v))
    return out


def write_vcd(path, chans, cycles):
    """chans: [(name, changes)]. The capture is written at 1 MHz, one sample
    per microsecond (a change at cycle c lands in sample c // 10, the last
    level in a microsecond wins). Why: sigrok's sda2506 decoder samples a read
    bit int(2.5e6 / samplerate) samples after CLK falls, meant as the
    EEPROM's data delay; at 1 MHz that is 2 us, at 10 MHz it would be 0 and
    the decoder would read every bit before the EEPROM has put it out. The
    timing limits are checked on the cycles themselves, not on this capture."""
    ids = "!\"#"
    ev = {}
    for k, (_, ch) in enumerate(chans):
        for c, v in ch:
            if c < cycles:
                ev.setdefault(c // SAMPLE, {})[k] = v
    with open(path, "w") as f:
        f.write("$timescale 1 us $end\n$scope module bus $end\n")
        for k, (name, _) in enumerate(chans):
            f.write("$var wire 1 %s %s $end\n" % (ids[k], name))
        f.write("$upscope $end\n$enddefinitions $end\n")
        for c in sorted(ev):
            f.write("#%d\n%s\n" % (c, "\n".join("%d%s" % (v, ids[k]) for k, v in sorted(ev[c].items()))))
        f.write("#%d\n" % (cycles // SAMPLE + 1))


def sigrok_tokens(clk, data, ce, cycles):
    """What sigrok's sda2506 decoder makes of the bus: its command and data
    annotations, in order, as text."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "bus.vcd")
        write_vcd(path, [("CLK", clk), ("DATA", data), ("CE", ce)], cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "sda2506:clk=CLK:d=DATA:ce=CE",
               "-A", "sda2506=data:cmd", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if out.returncode != 0 or "rror" in out.stderr:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append((int(m.group(1)), m.group(3).strip()))
    found.sort(key=lambda x: x[0])
    return [t for _, t in found]


def wanted_tokens(ops, memory):
    """The annotations the decoder gives for these operations, in the order
    its starting samples come in."""
    out = []
    reads = iter(run_memory(ops, memory))
    for kind, addr, data in ops:
        if kind == WRITE:
            out += ["data: %02X" % data, "addr: %02X" % addr, "CB: 01",
                    "Write to %02X: %02X" % (addr, data)]
        elif kind == ERASE:
            out += ["addr: %02X" % addr, "CB: 01", "Erase: %02X" % addr]
        else:
            out += ["addr: %02X" % addr, "read: %02X" % addr, "read", "CB: 00",
                    "%02X" % next(reads)]
    return out


def canon(tokens):
    """Order inside one operation's group of annotations is the decoder's
    business: compare each operation's annotations as a sorted group, the
    groups in order. A group starts at an addr/data field of a command."""
    groups, cur = [], []
    for t in tokens:
        if (t.startswith("addr: ") or t.startswith("data: ")) and cur and not (
                cur[-1].startswith("data: ") and t.startswith("addr: ")):
            groups.append(sorted(cur))
            cur = []
        cur.append(t)
    if cur:
        groups.append(sorted(cur))
    return groups


# ------------------------------------------------------------ the checks

def check_decoder(ops, memory, clk, bus, ce, cycles):
    got = canon(sigrok_tokens(clk, bus, ce, cycles))
    want = canon(wanted_tokens(ops, memory))
    if got == want:
        return []
    if len(got) != len(want):
        return ["decoded %d operations, wanted %d (first: %s)"
                % (len(got), len(want), "; ".join(", ".join(g) for g in got[:2]))]
    k = next(k for k in range(len(want)) if got[k] != want[k])
    return ["operation %d decoded as [%s], wanted [%s]" % (k, ", ".join(got[k]), ", ".join(want[k]))]


def check_edges(name, got, want):
    """got: [(cycle, level)] changes after the first line; want likewise."""
    errs = []
    for i, ((gc, gv), (wc, wv)) in enumerate(zip(got, want)):
        if gv != wv:
            errs.append("%s edge %d is a %s at cycle %d, wanted a %s at %d"
                        % (name, i, "rise" if gv else "fall", gc, "rise" if wv else "fall", wc))
            break
        if abs(gc - wc) > TOL:
            errs.append("%s edge %d (%s) at cycle %d, its place is %d (limit +-%d)"
                        % (name, i, "rise" if gv else "fall", gc, wc, TOL))
            break
    if not errs and len(got) != len(want):
        extra = got[len(want)] if len(got) > len(want) else want[len(got)]
        errs.append("%s has %d edges, wanted %d (first %s one near cycle %d)"
                    % (name, len(got), len(want), "extra" if len(got) > len(want) else "missing",
                       extra[0]))
    return errs


def check_waveform(ops, pins, cycles):
    errs = []
    if not pins or pins[0][0] != 0:
        return ["no pin levels at cycle 0 in the simulator's output"]
    clk_w, ce_w, req, _, end = schedule(ops)
    clk = pin_changes(pins, CLK)
    ce = pin_changes(pins, CE)
    data = pin_changes(pins, DATA)
    if ce[0][1] != 1:
        errs.append("CE is low at cycle 0: it must be high until the first operation")
    if clk[0][1] == 1:
        if len(clk) < 2 or clk[1][0] > CLK_LOW_BY:
            errs.append("CLK is not low by cycle %d" % CLK_LOW_BY)
            clk_after = clk[1:]
        else:
            clk_after = clk[2:]
    else:
        clk_after = clk[1:]
    errs += check_edges("CLK", clk_after, clk_w)
    errs += check_edges("CE", ce[1:], ce_w)
    times = [c for c, _ in data]
    for a, b, v in req:
        if a >= b:
            continue
        lv = level_at(data, a)
        i = bisect.bisect_right(times, a)
        moved = i < len(times) and times[i] < b
        if lv != v or moved:
            what = ("a change at cycle %d" % times[i]) if lv == v else ("level %d at cycle %d" % (lv, a))
            errs.append("DATA (the chip's drive) must be %d from cycle %d to %d, found %s"
                        % (v, a, b - 1, what))
            break
    tail = [c for c, _ in pin_changes(pins, CLK)[1:] + pin_changes(pins, CE)[1:] + data[1:]
            if c > end + TOL]
    if tail:
        errs.append("a pin moved at cycle %d, after the last operation ended (CE rise at %d)"
                    % (min(tail), end))
    return errs


def check_rx(ops, memory, rx):
    want = run_memory(ops, memory)
    if rx == want:
        return []
    if len(rx) != len(want):
        return ["%d RX words, wanted %d (got %s)" % (len(rx), len(want),
                                                    " ".join("0x%04X" % w for w in rx[:10]))]
    k = next(k for k in range(len(want)) if rx[k] != want[k])
    return ["RX word %d is 0x%04X, wanted 0x%04X" % (k, rx[k], want[k])]


def judge(ops, memory, sim_stdout, cycles):
    pins, rx = parse_sim(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(ops, pins, cycles)]
    if pins and pins[0][0] == 0:
        clk = pin_changes(pins, CLK)
        ce = pin_changes(pins, CE)
        bus = wired_and(pin_changes(pins, DATA), device_levels(ops, memory))
        errs += ["decoder: " + e for e in check_decoder(ops, memory, clk, bus, ce, cycles)]
    errs += ["rx: " + e for e in check_rx(ops, memory, rx)]
    return errs


def check_stimulus(ops, memory, cycles):
    """The scripted EEPROM must be a real instance of the protocol: with the
    ideal host, sigrok decodes exactly the operations and the read bytes."""
    pins = ideal_pins(ops)
    clk, ce = pin_changes(pins, CLK), pin_changes(pins, CE)
    bus = wired_and(pin_changes(pins, DATA), device_levels(ops, memory))
    return check_decoder(ops, memory, clk, bus, ce, cycles) + check_waveform(ops, pins, cycles)


# ------------------------------------------------------------------ running

def run_cycles(ops):
    return schedule(ops)[4] + TAIL


def run_case(run_dir, args, ops, memory):
    cycles = run_cycles(ops)
    pre = check_stimulus(ops, memory, cycles)
    if pre:
        return ["judge: the scripted EEPROM is not a valid instance: " + pre[0]], None
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        st = os.path.join(d, "stimulus.txt")
        with open(tx, "w") as f:
            f.write("".join("0x%04X\n" % w for w in tx_words(ops)))
        with open(st, "w") as f:
            f.write(stimulus_text(device_levels(ops, memory)))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "sda2506.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    pins, _ = parse_sim(out.stdout)
    moved = sorted(c for p in (CLK, DATA, CE) for c, _ in pin_changes(pins, p)[1:])
    return judge(ops, memory, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def random_memory(rng):
    return {a: rng.randrange(256) for a in range(128)}


def cases_for(seed):
    """(name, ops, memory). An op is (kind, address, data)."""
    base = random.Random(12345)
    mem0 = random_memory(base)
    mem0.update({0x2A: 0x5A, 0x00: 0x00, 0x7F: 0xFF, 0x55: 0x55, 0x12: 0x81})
    fixed = [
        ("one read", [(READ, 0x2A, 0)]),
        ("one write", [(WRITE, 0x55, 0xA5)]),
        ("one erase", [(ERASE, 0x7F, 0)]),
        ("the task sheet's example", [(ERASE, 0x12, 0), (WRITE, 0x12, 0x3C), (READ, 0x12, 0)]),
        ("reads of 0x00, 0xFF, 0x55, 0x5A", [(READ, 0x00, 0), (READ, 0x7F, 0), (READ, 0x55, 0),
                                             (READ, 0x2A, 0)]),
        ("writes of 0x00 and 0xFF at addresses 0 and 127",
         [(WRITE, 0x00, 0x00), (WRITE, 0x7F, 0xFF), (READ, 0x00, 0), (READ, 0x7F, 0)]),
        ("eight reads", [(READ, (k * 37 + 5) & 0x7F, 0) for k in range(MAX_OPS)]),
    ]
    out = [(name, ops, mem0) for name, ops in fixed]
    rng = random.Random(seed)
    for n in range(8):
        memory = random_memory(rng)
        count = MAX_OPS if n == 7 else rng.randint(2, MAX_OPS)
        ops = []
        for _ in range(count):
            kind = rng.choice([READ, READ, READ, WRITE, ERASE])
            addr = rng.randrange(128)
            ops.append((kind, addr, rng.randrange(256) if kind == WRITE else 0))
        if all(k != READ for k, _, _ in ops):
            ops[-1] = (READ, ops[0][1], 0)       # every random case reads something
        out.append(("random %d" % n, ops, memory))
    return out


def describe(ops):
    return ", ".join({READ: "R%02X", ERASE: "E%02X"}.get(k, "W%02X") % a
                     + (":%02X" % d if k == WRITE else "") for k, a, d in ops)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "sda2506.s", "run_args.txt"):
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
    for n, (name, ops, memory) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, ops, memory)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        nbytes = sum(1 for k, _, _ in ops if k != ERASE)
        if not errs:
            rate = (nbytes, span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d operation%s [%s]): %s"
              % (n, name, len(ops), "" if len(ops) == 1 else "s", describe(ops), status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
