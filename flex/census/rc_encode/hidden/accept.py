#!/usr/bin/env python3
"""Hidden acceptance test for the blind PT2262 (rc_encode) transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (rc_encode.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet fixes
what the TX words mean, and this test builds them itself.

For each case (a list of code words, each twelve trits from '0', '1', 'f'),
the test
  1. builds the TX words the task sheet defines: two words per code word,
     six trits in each, two bits a trit (0 = '0', 1 = '1', 2 = 'f'), the
     first-sent trit in bits 1..0, bits 15..12 zero,
  2. runs RUN_DIR/pe_sim on RUN_DIR/rc_encode.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per core clock cycle, 10 MHz). The line counts as low until
     P0's first change (the sheet: the host makes P0 an output only after
     the firmware has driven it low), so P0's reset level is not shown to
     the decoder,
  4. has sigrok-cli's `rc_encode` decoder read it and requires its bit row
     to be exactly the wanted trits, each code word followed by its Sync,
     in order, with nothing extra and no 'U' (undecodable) bit,
  5. checks, from the pin changes themselves, what the decoder does not:
     P0 driven low by cycle 100; the first frame starting between cycles
     50000 and 100000; every edge of a frame within +-2 cycles of its ideal
     place counted from that frame's first rise; each frame starting 512
     alpha after the one before, +-2 cycles; and no change after the last
     sync bit's fall.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. A code
word counts as 3 payload bytes (12 trits of 2 bits). The exit status is 0
only on a full pass. Python standard library and sigrok-cli only. Written
apart from the firmware and kept from its author."""
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
ALPHA = 400                  # cycles in one alpha, 40 us
SHORT = 4 * ALPHA            # a short high (1600 cycles)
LONG = 12 * ALPHA            # a long high (4800 cycles)
CYCLE = 16 * ALPHA           # one pulse cycle, a high and a low
BIT = 2 * CYCLE              # one trit, 32 alpha
SYNC_HIGH = 4 * ALPHA        # the sync bit's high part
FRAME = 12 * BIT + 128 * ALPHA   # twelve trits and the sync bit, 512 alpha
TOL = 2                      # cycles an edge may be from its ideal place
FALL_MAX = 100               # P0 must first go low by this cycle
START_MIN = 50_000           # the first frame's first rise, at the earliest
START_MAX = 100_000          # and at the latest
TAIL = 20_000                # cycles run after the latest possible end
MAX_CODES = 8                # code words in one run
BYTES_PER_CODE = 3           # 12 trits x 2 bits
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "tx", "help", "stimulus")  # pe_sim run's
PIN = 0                      # P0
TRIT_CODE = {"0": 0, "1": 1, "f": 2}


# ---------------------------------------------------------------- the code

def ideal_offsets(code):
    """Where the 50 edges of one frame belong, in cycles after its first rise,
    with the level each one leaves.

    A trit is two pulse cycles of 16 alpha, each a high then a low: '0' is
    short, short; '1' is long, long; 'f' is short, long. A short high is 4
    alpha (then 12 low), a long high 12 alpha (then 4 low). The sync bit is
    4 alpha high and 124 alpha low."""
    out = []
    for k, trit in enumerate(code):
        highs = {"0": (SHORT, SHORT), "1": (LONG, LONG), "f": (SHORT, LONG)}[trit]
        for j, high in enumerate(highs):
            start = k * BIT + j * CYCLE
            out.append((start, 1))
            out.append((start + high, 0))
    out.append((12 * BIT, 1))
    out.append((12 * BIT + SYNC_HIGH, 0))
    return out


def describe_edge(i):
    """Edge i of a frame, in words."""
    if i >= 48:
        return "the sync bit's %s" % ("rise" if i == 48 else "fall")
    trit, rest = divmod(i, 4)
    return "trit %d (A%d), pulse cycle %d, %s" % (trit, trit, rest // 2 + 1,
                                                  "rise" if rest % 2 == 0 else "fall")


# ------------------------------------------------------- the host interface

def tx_words(codes):
    """The TX words of one run, as the task sheet defines them: two words per
    code word, trits 0..5 then trits 6..11, trit k of a word in bits 2k+1..2k
    with 0 for '0', 1 for '1', 2 for 'f', bits 15..12 zero. Payload only:
    nothing about the line."""
    words = []
    for code in codes:
        assert len(code) == 12 and set(code) <= set("01f"), code
        for half in (code[:6], code[6:]):
            words.append(sum(TRIT_CODE[t] << (2 * k) for k, t in enumerate(half)))
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


def line_changes(changes):
    """The line as the receiver sees it: low from cycle 0, P0's reset level
    not shown (the host makes P0 an output only once the firmware has
    driven it low). [(cycle, level)] with only real changes."""
    out = [(0, 0)]
    for cycle, level in changes[1:]:
        if level != out[-1][1]:
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


def sigrok_bits(changes, cycles):
    """What sigrok's rc_encode decoder makes of the capture: its bit row, one
    entry per annotation ('0', '1', 'f', 'U' or 'Sync'), in order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, line_changes(changes), cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "rc_encode:data=P0",
               "-A", "rc_encode=bits", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append(m.group(3).strip())
    return found


# ------------------------------------------------------------ the two checks

def check_decoder(codes, changes, cycles):
    """The decoded trits must be the wanted code words and nothing else."""
    got = sigrok_bits(changes, cycles)
    want = []
    for code in codes:
        want += list(code) + ["Sync"]
    if got == want:
        return []
    errs = []
    if "U" in got:
        i = got.index("U")
        errs.append("the decoder could not read entry %d of its output (U)" % i)
    if len(got) != len(want):
        errs.append("decoded %d entries (trits and Syncs), wanted %d" % (len(got), len(want)))
    for i, (g, w) in enumerate(zip(got, want)):
        if g != w:
            frame, pos = divmod(i, 13)
            what = "its Sync" if pos == 12 else "trit %d" % pos
            errs.append("code word %d: %s decoded as %s, wanted %s" % (frame, what, g, w))
            break
    return errs or ["decoded output differs from the wanted code words"]


def check_waveform(codes, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    errs = []
    rest = changes[1:]
    if changes[0][1] == 1:
        if not rest:
            return ["P0 never changes: it must go low by cycle %d" % FALL_MAX]
        fall_cycle = rest[0][0]
        if fall_cycle > FALL_MAX:
            errs.append("P0 first goes low at cycle %d, limit %d" % (fall_cycle, FALL_MAX))
        rest = rest[1:]
    edges = [c for c, _ in rest]
    per = len(ideal_offsets(codes[0]))
    if len(edges) != per * len(codes):
        errs.append("%d edges on P0 after it first went low, wanted %d (%d frames of %d)"
                    % (len(edges), per * len(codes), len(codes), per))
    prev = None
    for k, code in enumerate(codes):
        chunk = rest[k * per:(k + 1) * per]
        if not chunk:
            break
        t0 = chunk[0][0]
        if k == 0:
            if not START_MIN <= t0 <= START_MAX:
                errs.append("the first frame starts at cycle %d, allowed %d to %d"
                            % (t0, START_MIN, START_MAX))
        else:
            if abs(t0 - prev - FRAME) > TOL:
                errs.append("frame %d starts %d cycles after frame %d, ideal %d (limit +-%d)"
                            % (k, t0 - prev, k - 1, FRAME, TOL))
        prev = t0
        for i, ((c, level), (off, want_level)) in enumerate(zip(chunk, ideal_offsets(code))):
            if level != want_level or abs(c - t0 - off) > TOL:
                errs.append("frame %d: %s is %d cycles after the frame's first rise, ideal %d (limit +-%d)"
                            % (k, describe_edge(i), c - t0, off, TOL)
                            if level == want_level else
                            "frame %d: %s goes the wrong way" % (k, describe_edge(i)))
                break
    if rest and rest[-1][1] != 0:
        errs.append("P0 is left high at the end of the run")
    return errs


def judge(codes, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = p0_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(codes, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(codes, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(codes):
    """Long enough for the latest start, every frame and the decoder's look
    past the last sync bit."""
    return START_MAX + len(codes) * FRAME + TAIL


def run_case(run_dir, args, codes):
    """(objections, cycles from P0's first change to its last or None)."""
    words = tx_words(codes)
    cycles = run_cycles(codes)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "rc_encode.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in p0_changes(out.stdout)[1:]]
    return judge(codes, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def random_code(rng):
    return "".join(rng.choice("01f") for _ in range(12))


def cases_for(seed):
    """(name, code words): fixed cases, then seeded random ones."""
    fixed = [
        ("all 0", ["000000000000"]),
        ("all 1", ["111111111111"]),
        ("all f", ["ffffffffffff"]),
        ("the task sheet's example", ["0f1000100f01"]),
        ("every trit after every trit", ["001101ff0f1f", "10f0ff1100f1"]),
        ("a key press: one code word four times", ["0f0f0f0f1000"] * 4),
        ("eight code words", ["0000000000f1", "f1ffffffff10", "1f0f1f0f1f0f", "011001100110",
                              "ff00ff00ff00", "1111f1111111", "00000f000000", "f0f0f0f0f0f0"]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        if n % 3 == 1:
            code = random_code(rng)
            codes = [code] * rng.randint(2, 6)
        else:
            codes = [random_code(rng) for _ in range(rng.randint(1, MAX_CODES))]
        rand.append(("random %d" % n, codes))
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
    for name in ("pe_sim", "rc_encode.s", "run_args.txt"):
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
    for n, (name, codes) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, codes)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (BYTES_PER_CODE * len(codes), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d code word%s): %s"
              % (n, name, len(codes), "" if len(codes) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
