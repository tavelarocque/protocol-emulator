#!/usr/bin/env python3
"""Hidden acceptance test for the blind ST7789 firmware (census round 2, Part A).

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (st7789.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet
fixes what the TX words mean, and this test builds them itself (one word per
byte on the wire, bits 7..0 the byte, bit 8 set for a command byte, bit 9
set on the last byte of a transfer, the rest 0). For each case this runs
RUN_DIR/pe_sim on RUN_DIR/st7789.s with those words, turns the printed pin
changes into a logic capture (one sample per 20 ns cycle, 50 MHz), and
judges it twice:

1. sigrok-cli's `st7789` protocol decoder (DSView's, run unchanged from the
   DECODERS folder) must report exactly the commands and data bytes asked
   for, in order, with nothing extra.
2. A direct check of the pin changes against the timing and framing limits
   in TASK.md, which the decoder does not look at.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<bytes on the wire> cycles=<cycles from the first change of P0..P3 to the last>
(none if no case passed), then `ACCEPT PASS` or `ACCEPT FAIL`. Exit status
0 only on a full pass. Python standard library plus sigrok-cli only.

Written separately from the firmware and kept from its author."""
import os
import random
import re
import shlex
import subprocess
import sys

sys.dont_write_bytecode = True   # leave no __pycache__ in the run directory
import tempfile

DECODERS = "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders"

# ---- what TASK.md states ---------------------------------------------------
NS = 20                       # one cycle at 50 MHz
SDA, SCL, DCX, CSX = 0, 1, 2, 3   # pin numbers (the decoder's sdo, dcx, wrx, csx)
T_CSS = 15      # CSX falling to first SCL rising
T_CS_SCL = 15   # TCSH: SCL low and unchanged this long before any CSX edge
T_CHW = 40      # CSX high between transfers
T_SCYC = 66     # SCL period
T_SHW = 15      # SCL high
T_SLW = 15      # SCL low
T_SDS = 10      # SDA setup before SCL rising
T_SDH = 10      # SDA hold after SCL rising
T_DCS = 10      # D/CX setup before the 8th SCL rising edge
T_DCH = 10      # D/CX hold after the falling edge that ends the 8th pulse
MAX_DATA = 1000
COMMAND, LAST = 0x100, 0x200  # bits 8 and 9 of a TX word
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
CYCLES_PER_BYTE, CYCLES_SLACK = 100, 2000
DECODER = "st7789:csx=%d:dcx=%d:sdo=%d:wrx=%d" % (CSX, SCL, SDA, DCX)


def cyc(ns):
    """Whole cycles needed to cover ns."""
    return -(-ns // NS)


def budget(transfers):
    return CYCLES_PER_BYTE * sum(1 + len(d) for _, d in transfers) + CYCLES_SLACK


# ---- the host interface ----------------------------------------------------
def tx_words(transfers):
    """The TX words of one run, as the task sheet defines them: one word per
    byte on the wire in order, the byte in bits 7..0, bit 8 set for a command
    byte, bit 9 set on the last byte of each transfer, every other bit 0.
    Payload only: nothing about the pins."""
    words = []
    for command, data in transfers:
        body = [command | COMMAND] + list(data)
        body[-1] |= LAST
        words += body
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


# ---- cases -----------------------------------------------------------------
def make_cases(seed):
    rng = random.Random(seed)
    long_rng = random.Random(7789)      # the long cases do not depend on seed
    cases = [
        ("one command, no data", [(0x11, [])]),
        ("the task sheet's example", [(0x2A, [0x00, 0x00, 0x00, 0xEF]), (0x29, [])]),
        ("window set and pixels", [(0x2A, [0x00, 0x00, 0x00, 0xEF]),
                                   (0x2B, [0x00, 0x00, 0x01, 0x3F]),
                                   (0x2C, [0xF8, 0x00, 0x07, 0xE0, 0x00, 0x1F])]),
        ("bit patterns", [(0x00, [0x00, 0xFF, 0xAA, 0x55, 0x80, 0x01, 0x7F, 0xFE]),
                          (0xFF, [0xFF, 0xFF, 0x00, 0x00]),
                          (0x80, [0x2A]), (0x01, [0x0F, 0xF0, 0x33, 0xCC]),
                          (0x7F, [0x01]), (0xFE, [0x80])]),
        ("commands back to back", [(0x01, []), (0x11, []), (0x13, []),
                                   (0x21, []), (0x29, []), (0x00, [])]),
        ("a data byte equal to a command's word", [(0x3A, [0x55]), (0x36, [0x00]),
                                                    (0x2C, [0x2C, 0x29, 0x00])]),
        ("255, 256 and 257 data bytes",
         [(0x2C, [long_rng.randrange(256) for _ in range(255)]),
          (0x3C, [long_rng.randrange(256) for _ in range(256)]),
          (0x3C, [long_rng.randrange(256) for _ in range(257)]),
          (0x29, [])]),
        ("1000 data bytes", [(0x36, [0xC0]),
                             (0x2C, [long_rng.randrange(256) for _ in range(MAX_DATA)]),
                             (0x3A, [0x05]), (0x29, [])]),
    ]
    for k in range(8):
        transfers = []
        for _ in range(rng.randint(1, 10)):
            r = rng.random()
            n = 0 if r < 0.25 else rng.randint(1, 8) if r < 0.8 else rng.randint(9, 70)
            transfers.append((rng.randrange(256), [rng.randrange(256) for _ in range(n)]))
        cases.append(("random %d" % k, transfers))
    return cases


# ---- running the simulator -------------------------------------------------
def pin_modes(args):
    """The -mode flags in run_args.txt, read the way pe_sim reads them."""
    modes = {}
    for i, a in enumerate(args):
        v = None
        if len(a) > 1 and "-mode".startswith(a) and i % 2 == 0 and i + 1 < len(args):
            v = args[i + 1]
        if v and "=" in v:
            p, m = v.split("=", 1)
            try:
                modes[int(p.strip(), 0)] = m.strip().lower()
            except ValueError:
                pass
    return modes


def run_sim(run_dir, args, words, cycles, tmp):
    """Returns ([(cycle, pins)], None) or (None, error text)."""
    tx = os.path.join(tmp, "tx.txt")
    with open(tx, "w") as f:
        f.write("".join("%d\n" % w for w in words))
    cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "st7789.s"),
           "-tx", tx, "-cycles", str(cycles)] + args
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    except (OSError, subprocess.TimeoutExpired) as e:
        return None, "pe_sim did not run: %s" % e
    if p.returncode != 0:
        return None, "pe_sim exit %d: %s" % (p.returncode, (p.stderr or p.stdout).strip()[:300])
    changes = []
    for line in p.stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            changes.append((int(part[1]), int(part[2], 16) & 0xFF))
    return changes, None


def samples_of(changes, cycles):
    """One byte per cycle: the pins' levels during that cycle."""
    out = bytearray(cycles)
    changes = sorted(c for c in changes if 0 <= c[0] < cycles)
    if not changes or changes[0][0] != 0:
        changes.insert(0, (0, 0xFF))    # the output register resets to all ones
    for i, (c, v) in enumerate(changes):
        end = changes[i + 1][0] if i + 1 < len(changes) else cycles
        out[c:end] = bytes([v]) * (end - c)
    return bytes(out)


# ---- judge 1: sigrok's st7789 decoder --------------------------------------
ANN = re.compile(r"(\d+)-(\d+) st7789-\d+: (?:Data|[A-Za-z0-9]+)\(([0-9A-Fa-f]{2})\)\s*$")


def sigrok_decode(samples, tmp):
    """Returns ([('C' or 'D', byte)], None) or (None, error text). The
    decoder's "command" annotation reads NAME(XX) (Unknown(XX) for a code it
    has no name for), its "data" annotation Data(XX)."""
    path = os.path.join(tmp, "capture.bin")
    with open(path, "wb") as f:
        f.write(samples)
    env = dict(os.environ, SIGROKDECODE_DIR=DECODERS, PYTHONDONTWRITEBYTECODE="1")
    found = []
    for kind, ann in (("C", "command"), ("D", "data")):
        cmd = ["sigrok-cli", "-i", path,
               "-I", "binary:numchannels=8:samplerate=%d" % (1_000_000_000 // NS),
               "-P", DECODER, "-A", "st7789=" + ann, "--protocol-decoder-samplenum"]
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=600, env=env)
        except (OSError, subprocess.TimeoutExpired) as e:
            return None, "sigrok-cli did not run: %s" % e
        if p.returncode != 0 or "srd:" in p.stderr or "Error" in p.stderr:
            err = [l for l in p.stderr.splitlines() if l.strip()]
            return None, "sigrok-cli failed: %s" % (" | ".join(err[:1] + err[-1:]) or p.returncode)
        for line in p.stdout.splitlines():
            m = ANN.match(line)
            if not m:
                return None, "sigrok-cli printed something unexpected: %r" % line[:80]
            if kind == "D" and not line.split(": ", 1)[1].startswith("Data("):
                return None, "sigrok-cli printed a data row that is not Data(..): %r" % line[:80]
            found.append((int(m.group(1)), kind, int(m.group(3), 16)))
    found.sort()
    return [(k, b) for _, k, b in found], None


# ---- judge 2: timing and framing, straight from the pins -------------------
def direct_check(s, cycles):
    """s: one byte per cycle. Returns (transfers seen, errors). A transfer is
    (command, [data]) for one CSX low pulse."""
    errs = []

    def bit(c, pin):
        return (s[c] >> pin) & 1

    def err(c, text):
        errs.append("cycle %d: %s" % (c, text))

    if not bit(0, CSX):
        err(0, "CSX is low at the start")
    # CSX low pulses.
    windows, fall = [], None if bit(0, CSX) else 0
    for c in range(1, cycles):
        a, b = bit(c - 1, CSX), bit(c, CSX)
        if a and not b:
            fall = c
        elif b and not a:
            windows.append((fall, c))
            fall = None
    if fall is not None:
        err(fall, "CSX is still low when the run ends (cycle %d)" % cycles)
    seen = []
    for i, (f, r) in enumerate(windows):
        if i and f - windows[i - 1][1] < cyc(T_CHW):
            err(f, "CSX high for only %d ns between transfers (min %d)"
                % ((f - windows[i - 1][1]) * NS, T_CHW))
        for e, name in ((f, "falling"), (r, "rising")):
            if bit(e, SCL) or (e and bit(e - 1, SCL)):
                err(e, "SCL is not low, or changes less than %d ns before, at this %s edge of CSX"
                    % (T_CS_SCL, name))
        rises = [c for c in range(max(f, 1), r) if bit(c, SCL) and not bit(c - 1, SCL)]
        falls = [c for c in range(max(f, 1), r + 1) if not bit(c, SCL) and bit(c - 1, SCL)]
        # A pulse already high at the CSX edge was reported above; pair up
        # only whole pulses inside the window.
        if falls and rises and falls[0] < rises[0]:
            falls = falls[1:]
        pulses = list(zip(rises, falls))
        if len(pulses) != len(rises):
            err(r, "SCL still high when CSX rises")
        if rises and (rises[0] - f) * NS < T_CSS:
            err(rises[0], "first SCL rising edge %d ns after CSX falls (min %d)"
                % ((rises[0] - f) * NS, T_CSS))
        for k, (up, down) in enumerate(pulses):
            if (down - up) * NS < T_SHW:
                err(up, "SCL high for %d ns (min %d)" % ((down - up) * NS, T_SHW))
            if k:
                pup, pdown = pulses[k - 1]
                if (up - pdown) * NS < T_SLW:
                    err(pdown, "SCL low for %d ns (min %d)" % ((up - pdown) * NS, T_SLW))
                if (up - pup) * NS < T_SCYC or (down - pdown) * NS < T_SCYC:
                    err(pup, "SCL period %d ns (min %d)"
                        % (min(up - pup, down - pdown) * NS, T_SCYC))
            # SDA must hold one level from T_SDS before to T_SDH after the rise.
            lo, hi = up - cyc(T_SDS), up + cyc(T_SDH) - 1
            if any(bit(c, SDA) != bit(up, SDA) for c in range(max(lo, 0), min(hi, cycles - 1) + 1)):
                err(up, "SDA changes within %d ns before or %d ns after this SCL rising edge"
                    % (T_SDS, T_SDH))
        if not pulses:
            err(f, "CSX low pulse with no clock pulses in it")
            continue
        if len(pulses) % 8:
            err(f, "%d clock pulses in this CSX low pulse, not a whole number of bytes"
                % len(pulses))
        cmd, data = None, []
        for n in range(len(pulses) // 8):
            byte = 0
            for up, _ in pulses[8 * n:8 * n + 8]:
                byte = (byte << 1) | bit(up, SDA)
            up8, down8 = pulses[8 * n + 7]
            lo, hi = up8 - cyc(T_DCS), down8 + cyc(T_DCH) - 1
            want = 0 if n == 0 else 1
            if any(bit(c, DCX) != bit(up8, DCX) for c in range(max(lo, 0), min(hi, cycles - 1) + 1)):
                err(up8, "D/CX changes between %d ns before the 8th SCL rising edge and "
                    "%d ns after the falling edge that ends that pulse" % (T_DCS, T_DCH))
            elif bit(up8, DCX) != want:
                err(up8, "D/CX is %d for %s" % (bit(up8, DCX),
                    "the command byte" if n == 0 else "data byte %d" % n))
            if n == 0:
                cmd = byte
            else:
                data.append(byte)
        seen.append((cmd, data))
    return seen, errs


def span_of(changes, cycles):
    """Cycles from the first change of P0..P3 to the last, or None."""
    s = samples_of(changes, cycles)
    moved = [c for c in range(1, cycles) if (s[c] ^ s[c - 1]) & 0x0F]
    return moved[-1] - moved[0] if moved else None


def describe(transfers):
    return "%d transfers, %d bytes" % (len(transfers), sum(1 + len(d) for _, d in transfers))


def judge(changes, transfers, cycles, tmp):
    """Every complaint about one run, as a list of strings (empty: pass)."""
    errs = []
    s = samples_of(changes, cycles)
    want = [(c, list(d)) for c, d in transfers]
    flat = [x for c, d in want for x in [("C", c)] + [("D", b) for b in d]]
    got, e = sigrok_decode(s, tmp)
    if e:
        errs.append(e)
    elif got != flat:
        k = next((i for i, (a, b) in enumerate(zip(got, flat)) if a != b), min(len(got), len(flat)))
        show = lambda seq: " ".join("%s:%02X" % x for x in seq[k:k + 4]) or "(nothing)"
        errs.append("sigrok decoded %d bytes, wanted %d; first difference at byte %d: got %s, wanted %s"
                    % (len(got), len(flat), k, show(got), show(flat)))
    seen, derrs = direct_check(s, cycles)
    errs += derrs
    if seen != want:
        k = next((i for i, (a, b) in enumerate(zip(seen, want)) if a != b), min(len(seen), len(want)))
        show = lambda seq: ("command %s with %d data bytes" % (
            "none" if seq[k][0] is None else "%02X" % seq[k][0], len(seq[k][1]))
            if k < len(seq) else "(nothing)")
        errs.append("framing: %d CSX low pulses, wanted %d; pulse %d holds %s, wanted %s%s"
                    % (len(seen), len(want), k, show(seen), show(want),
                       ", with other byte values" if k < min(len(seen), len(want))
                       and show(seen) == show(want) else ""))
    return errs


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    run_dir = os.path.abspath(sys.argv[1])
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    setup = []
    args = []
    try:
        lines = [l for l in open(os.path.join(run_dir, "run_args.txt")).read().splitlines()
                 if l.strip()]
        if len(lines) > 1:
            setup.append("run_args.txt must be one line")
        args = shlex.split(" ".join(lines))
    except Exception as e:
        setup.append("run_args.txt: %r" % e)
    problem = args_problem(args)
    if problem:
        setup.append(problem)
    modes = pin_modes(args)
    for pin, name in ((SDA, "SDA"), (SCL, "SCL"), (DCX, "D/CX"), (CSX, "CSX")):
        if modes.get(pin) != "pp":
            setup.append("P%d (%s) is not made push-pull in run_args.txt" % (pin, name))
    for f in ("st7789.s", "pe_sim"):
        if not os.path.exists(os.path.join(run_dir, f)):
            setup.append("%s is missing" % f)
    if not os.path.isfile(os.path.join(DECODERS, "st7789", "pd.py")):
        setup.append("the st7789 decoder is not in %s" % DECODERS)
    cases = make_cases(seed)
    failures, rate = 0, None
    for n, (name, transfers) in enumerate(cases):
        errs = list(setup)
        if not errs:
            with tempfile.TemporaryDirectory() as tmp:
                cycles = budget(transfers)
                span = None
                try:
                    words = tx_words(transfers)
                    changes, e = run_sim(run_dir, args, words, cycles, tmp)
                    if e:
                        errs.append(e)
                    else:
                        errs += judge(changes, transfers, cycles, tmp)
                        span = span_of(changes, cycles)
                except Exception as e:  # never report a pass because the judge fell over
                    errs.append("judge: %s: %s" % (type(e).__name__, e))
                if not errs and span is not None:
                    rate = (sum(1 + len(d) for _, d in transfers), span)
        uniq = []
        for e in errs:
            if e not in uniq:
                uniq.append(e)
        more = "" if len(uniq) <= 4 else " (and %d more)" % (len(uniq) - 4)
        status = "PASS" if not uniq else "FAIL: " + "; ".join(uniq[:4]) + more
        print("case %d (%s: %s): %s" % (n, name, describe(transfers), status))
        failures += bool(uniq)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failures else "ACCEPT FAIL")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
