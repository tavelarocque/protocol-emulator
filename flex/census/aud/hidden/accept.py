#!/usr/bin/env python3
"""Hidden acceptance test for the blind AUD branch-trace receiver firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (aud.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The chip is a
RECEIVER: a scripted target microcontroller drives AUDCK, nAUDSYNC and
AUDATA3..0 into the chip, and the firmware must push every branch
destination address to the host. The host sends the chip no words.

For each case (a list of address outputs, each a width and the bits sent)
the test
  1. builds the stimulus itself, from the task sheet's description of the
     target: AUDCK on P0 with a 50-cycle period, nAUDSYNC on P1, AUDATA0..3
     on P2..P5, idle nibbles between address outputs,
  2. turns that stimulus into a logic capture (VCD, one sample per core
     clock cycle, 50 MHz) and requires sigrok-cli's `aud` decoder to read it
     as exactly the wanted destination addresses, in order: so the input is
     a real instance of the protocol as sigrok understands it,
  3. runs RUN_DIR/pe_sim on RUN_DIR/aud.s with that stimulus and the flags
     in run_args.txt (only -config and -mode, and P0..P5 must stay inputs),
  4. requires the "rx" words to be exactly two per address, low half then
     high half of the full 32-bit destination, in order, nothing extra,
  5. checks the latency limit of the sheet: both words of an address are
     pushed no earlier than its last nibble's rising AUDCK edge and no later
     than DEADLINE cycles after it.

Prints one line per case, then for the last case that passed
    RATE bytes=<4 per address> cycles=<cycles from the stimulus's first change to its last>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
exit status is 0 only on a full pass. Python standard library and sigrok-cli
only."""
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

CLOCK_HZ = 50_000_000        # core clock: one cycle = 20 ns
PERIOD = 50                  # AUDCK period in cycles (1 MHz)
HIGH = 25                    # AUDCK high for 25 cycles, low for 25
DEADLINE = 200               # cycles after the last nibble's rising edge
LEAD_MIN = 4                 # idle clock periods before the first command
TAIL = 4                     # idle clock periods after the last address
GAP_MAX = 20                 # idle periods between two addresses, 0 to this
MAX_ADDRS = 40               # addresses in one run
AFTER = 1000                 # cycles the run goes on after the last change
WIDTHS = {4: 0x8, 8: 0x9, 16: 0xA, 32: 0xB}   # address bits -> command nibble
IDLE = 0x3                   # the idle nibble, with nAUDSYNC high
CK, SYNC, D0 = 0, 1, 2       # pins: AUDCK P0, nAUDSYNC P1, AUDATA0..3 P2..P5
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")


# --------------------------------------------------------------- the target

def full_addresses(items):
    """The destination addresses the host must get: each output replaces the
    lowest `width` bits of the previous address, which is 0 at reset."""
    prev, out = 0, []
    for width, sent, _gap in items:
        mask = (1 << width) - 1
        prev = (prev & ~mask & 0xFFFFFFFF) | (sent & mask)
        out.append(prev)
    return out


def rx_words(items):
    """The RX words the sheet defines: low half, then high half, of every
    destination address, in order."""
    words = []
    for a in full_addresses(items):
        words += [a & 0xFFFF, a >> 16]
    return words


def edge_values(case):
    """(sync, nibble) for every rising AUDCK edge, and for each address the
    index of the edge carrying its last nibble."""
    vals = [(1, IDLE)] * case["lead"]
    last = []
    for n, (width, sent, gap) in enumerate(case["items"]):
        vals.append((1, WIDTHS[width]))
        for k in range(width // 4):
            vals.append((0, (sent >> (4 * k)) & 0xF))
        last.append(len(vals) - 1)
        idle = TAIL if n == len(case["items"]) - 1 else gap
        vals += [(1, IDLE)] * idle
    return vals, last


def level(clk, sync, nib):
    return (clk << CK) | (sync << SYNC) | (nib << D0)


def stimulus(case):
    """([(cycle, pins)] changes from cycle 0, [rising cycle of each address's
    last nibble]). AUDCK starts low; the k-th rising edge is at phase + k *
    PERIOD. nAUDSYNC and AUDATA change together with each falling edge (and at
    cycle 0 for the first rising edge), so they are stable for 25 cycles
    either side of every rising edge. After the tail the clock stops low."""
    vals, last = edge_values(case)
    p = case["phase"]
    ch = [(0, level(0, *vals[0]))]
    for k, (s, n) in enumerate(vals):
        r = p + k * PERIOD
        ch.append((r, level(1, s, n)))
        nxt = vals[k + 1] if k + 1 < len(vals) else (s, n)
        ch.append((r + HIGH, level(0, *nxt)))
    return ch, [p + i * PERIOD for i in last]


def run_cycles(changes):
    return changes[-1][0] + AFTER


# ------------------------------------------------ sigrok reads the stimulus

NAMES = ["AUDCK", "nAUDSYNC", "AUDATA0", "AUDATA1", "AUDATA2", "AUDATA3"]


def write_vcd(path, changes, cycles):
    ids = "!\"#$%&"
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n$scope module pins $end\n" % (1_000_000_000 // CLOCK_HZ))
        for i, name in enumerate(NAMES):
            f.write("$var wire 1 %s %s $end\n" % (ids[i], name))
        f.write("$upscope $end\n$enddefinitions $end\n")
        prev = None
        for cycle, v in changes:
            bits = [(v >> i) & 1 for i in range(6)]
            f.write("#%d\n" % cycle)
            for i in range(6):
                if prev is None or prev[i] != bits[i]:
                    f.write("%d%s\n" % (bits[i], ids[i]))
            prev = bits
        f.write("#%d\n" % cycles)


def sigrok_addresses(changes, cycles):
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "aud.vcd")
        write_vcd(path, changes, cycles)
        dec = ("aud:audck=AUDCK:naudsync=nAUDSYNC:audata3=AUDATA3:audata2=AUDATA2"
               ":audata1=AUDATA1:audata0=AUDATA0")
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", dec, "-A", "aud=dest"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    return [int(m, 16) for m in re.findall(r"0x([0-9A-Fa-f]{8})", out.stdout)]


# ----------------------------------------------------------- the hand-in

def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else; P0 to P5 must stay inputs."""
    i = 0
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.fullmatch(r"(\d+)=(\w+)", args[i + 1])
            if m and int(m.group(1)) <= 5 and m.group(2) != "in":
                return "run_args.txt: P%s is an AUD input and must stay an input" % m.group(1)
        i += 2
    return None


def rx_lines(sim_stdout):
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "rx":
            out.append((int(part[1]), int(part[2])))
    return out


def judge(case, sim_stdout):
    """Every objection to one run's RX words."""
    items = case["items"]
    want = rx_words(items)
    _, last = stimulus(case)
    got = rx_lines(sim_stdout)
    words = [w for _, w in got]
    errs = []
    if words != want:
        if len(words) != len(want):
            errs.append("%d rx words, wanted %d (two per address)" % (len(words), len(want)))
        for i, (g, w) in enumerate(zip(words, want)):
            if g != w:
                errs.append("rx word %d (address %d, %s half) is 0x%04X, wanted 0x%04X"
                            % (i, i // 2, "low" if i % 2 == 0 else "high", g, w))
                break
        return errs
    for i, (cycle, _) in enumerate(got):
        r = last[i // 2]
        if cycle < r:
            errs.append("rx word %d pushed at cycle %d, before its last nibble's edge at %d"
                        % (i, cycle, r))
            break
        if cycle > r + DEADLINE:
            errs.append("rx word %d pushed at cycle %d, %d cycles after its last nibble's edge (limit %d)"
                        % (i, cycle, cycle - r, DEADLINE))
            break
    return errs


# ------------------------------------------------------------------ cases

def make_case(rng, n, phase=None, lead=None, gaps=None):
    items = []
    for _ in range(n):
        width = rng.choice(sorted(WIDTHS))
        gap = rng.randint(0, GAP_MAX) if gaps is None else rng.choice(gaps)
        items.append((width, rng.getrandbits(width), gap))
    return {"phase": rng.randint(30, 79) if phase is None else phase,
            "lead": rng.randint(LEAD_MIN, 40) if lead is None else lead,
            "items": items}


def fixed(items, gap=2):
    return {"phase": 40, "lead": LEAD_MIN,
            "items": [(w, v, gap) for w, v in items]}


def cases_for(seed):
    b2b = fixed([(32, 0x8000_1000), (4, 0xC), (8, 0x40), (16, 0x2468), (4, 0x1),
                 (32, 0x0123_4567), (8, 0xFE), (4, 0x0)], gap=0)
    many = make_case(random.Random(12345), MAX_ADDRS, phase=55, lead=6, gaps=[0, 0, 1, 2, 3])
    out = [
        ("one 32-bit address", fixed([(32, 0x1234_5678)])),
        ("each width in turn", fixed([(32, 0xDEAD_BEEF), (16, 0x1234), (8, 0x56), (4, 0x7)])),
        ("short addresses from reset", fixed([(4, 0xA), (8, 0x5C), (16, 0xF00D)])),
        ("back to back, no idle", b2b),
        ("all zeros and all ones", fixed([(32, 0xFFFF_FFFF), (4, 0x0), (32, 0x0), (16, 0xFFFF),
                                           (8, 0xFF), (4, 0xF), (8, 0x00)], gap=1)),
        ("40 addresses, short gaps", many),
    ]
    rng = random.Random(seed)
    for n in range(8):
        count = rng.randint(1, 8) if n % 2 == 0 else rng.randint(9, 30)
        out.append(("random %d" % n, make_case(rng, count)))
    return out


# ------------------------------------------------------------------ running

def run_case(run_dir, args, case):
    """(objections, cycles from the stimulus's first change to its last)."""
    changes, _ = stimulus(case)
    cycles = run_cycles(changes)
    span = changes[-1][0] - changes[1][0]
    got = sigrok_addresses(changes, cycles)
    want = full_addresses(case["items"])
    if got != want:
        return ["judge: sigrok reads the stimulus as %d addresses, not the %d wanted: the test is broken"
                % (len(got), len(want))], None
    with tempfile.TemporaryDirectory() as d:
        stim = os.path.join(d, "stimulus.txt")
        with open(stim, "w") as f:
            f.write("".join("%d %02x\n" % (c, v) for c, v in changes))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "aud.s"),
               "-stimulus", stim, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    return ["rx: " + e for e in judge(case, out.stdout)], span


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "aud.s", "run_args.txt"):
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
    for n, (name, case) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, case)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        count = len(case["items"])
        if not errs:
            rate = (4 * count, span)
        status = "PASS" if not errs else "FAIL: " + "; ".join(errs[:2])
        print("case %d (%s: %d address%s): %s"
              % (n, name, count, "" if count == 1 else "es", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
