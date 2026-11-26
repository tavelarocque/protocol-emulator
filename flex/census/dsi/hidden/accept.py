#!/usr/bin/env python3
"""Hidden acceptance test for the blind DSI transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (dsi.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. There is no host
code: the task sheet fixes what the TX words mean, and this test builds them
itself.

For each case (a list of frames, each one dimming level byte) the test
  1. builds the TX words the task sheet defines: one word per frame, bits
     7..0 the level, every other bit 0,
  2. runs RUN_DIR/pe_sim on RUN_DIR/dsi.s with those words and the flags
     of run_args.txt (only -config and -mode allowed, P0 push-pull),
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per microsecond, 1 MHz; the exact timing is checked in step 5),
  4. has sigrok-cli's `dsi` decoder (polarity active-high) read it and
     requires its raw annotations to be exactly "Startbit: 0" then
     "Data: XX" for each wanted frame, in order, with nothing extra,
  5. checks, from the pin changes themselves, what the decoder does not:
     P0 low by cycle 1000 and low until the first frame, every change of the
     line at its ideal place within +-80 cycles counted from its frame's
     rise, exactly the changes the coding needs and no others, the first
     rise between cycles 50000 and 200000, the 5 ms to 20 ms rest between
     frames, and the line low and still after the last frame.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>
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
HALF_NUM, HALF_DEN = 25000, 3  # a half-bit: 833.33 us = 25000/3 cycles
HALVES = 21                  # start, 8 x 2 data halves, 4 stop bits
FRAME = 175_000              # 21 half-bits = 17.5 ms, in cycles
TOL = 80                     # cycles a change may be from its ideal place
LOW_BY = 1000                # P0 low by this cycle (100 us)
START_MIN = 50_000           # the first rise no earlier (5 ms)
START_MAX = 200_000          # and no later (20 ms)
GAP_MIN = 50_000             # rest from the end of the stop bits, at least 5 ms
GAP_MAX = 200_000            # and at most 20 ms
MAX_FRAMES = 8               # frames in one run
SPLIT = 3 * HALF_NUM // HALF_DEN  # more than 3 half-bits without a change
                                  # ends a frame (inside one: at most 2)
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")
PIN = 0                      # P0
VCD_DIV = 10                 # cycles per sample of the capture (1 MHz)


# ---------------------------------------------------------------- the code

def half_levels(level):
    """The line in half-bits 0 to 16 of a frame: start high, then each bit
    D7 first, 1 as high-low, 0 as low-high. Half-bits 17 to 20 are low."""
    out = [1]
    for k in range(7, -1, -1):
        out += [1, 0] if (level >> k) & 1 else [0, 1]
    return out


def ideal_place(k):
    """Cycles from a frame's rise to the start of its half-bit k, rounded."""
    return (2 * k * HALF_NUM + HALF_DEN) // (2 * HALF_DEN)


def ideal_changes(level):
    """[(cycles after the rise, new level)] of one frame, the rise first."""
    out, before = [], 0
    for k, lvl in enumerate(half_levels(level) + [0]):
        if lvl != before:
            out.append((ideal_place(k), lvl))
        before = lvl
    return out


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The TX words of one run, as the task sheet defines them: one word per
    frame, the level in bits 7..0, every other bit 0."""
    return [level & 0xFF for level in frames]


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name), and
    must make P0 push-pull."""
    i, p0_pp = 0, False
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits in (["tx"], ["cycles"]):
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            for part in args[i + 1].split(","):
                if part.strip().replace(" ", "") == "0=pp":
                    p0_pp = True
        i += 2
    if not p0_pp:
        return "run_args.txt must make P0 push-pull (-mode 0=pp)"
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
    """One sample per VCD_DIV cycles; a change lands on the nearest sample."""
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (VCD_DIV * 1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        last = None
        for cycle, level in changes:
            if cycle < cycles:
                t = (cycle + VCD_DIV // 2) // VCD_DIV
                if t != last:
                    f.write("#%d\n" % t)
                    last = t
                f.write("%d!\n" % level)
        f.write("#%d\n" % (cycles // VCD_DIV))


def sigrok_raw(changes, cycles):
    """The texts of sigrok's dsi decoder's raw annotations, in order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "dsi:polarity=active-high:dsi=P0",
               "-A", "dsi=raw", "--protocol-decoder-samplenum"]
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

def check_decoder(frames, changes, cycles):
    """The decoded frames must be the wanted ones and nothing else."""
    got = sigrok_raw(changes, cycles)
    want = []
    for level in frames:
        want += ["Startbit: 0", "Data: %02X" % level]
    if got == want:
        return []
    datas = [g for g in got if g.startswith("Data:")]
    errs = []
    if len(datas) != len(frames):
        errs.append("decoded %d frames, wanted %d" % (len(datas), len(frames)))
    for k, (g, w) in enumerate(zip(datas, ["Data: %02X" % f for f in frames])):
        if g != w:
            errs.append("frame %d decoded as %r, wanted %r" % (k, g, w))
            break
    return errs or ["decoder's annotations differ from the wanted ones: %r" % got[:6]]


def check_waveform(frames, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    errs = []
    rest = changes[1:]
    if changes[0][1] == 1:
        if not rest or rest[0][1] != 0 or rest[0][0] > LOW_BY:
            return ["P0 is not driven low by cycle %d" % LOW_BY]
        rest = rest[1:]
    groups = []
    for c, lvl in rest:
        if groups and c - groups[-1][-1][0] <= SPLIT:
            groups[-1].append((c, lvl))
        else:
            groups.append([(c, lvl)])
    if len(groups) != len(frames):
        errs.append("%d separate bursts of changes on P0, wanted %d frames"
                    % (len(groups), len(frames)))
    prev_end = None
    for k, (g, level) in enumerate(zip(groups, frames)):
        t0 = g[0][0]
        want = ideal_changes(level)
        got = [(c - t0, lvl) for c, lvl in g]
        for i, ((a, al), (w, wl)) in enumerate(zip(got, want)):
            if al != wl:
                errs.append("frame %d: change %d goes to %d, wanted %d" % (k, i, al, wl))
                break
            if abs(a - w) > TOL:
                errs.append("frame %d: change %d is %d cycles after the rise, ideal %d (limit +-%d)"
                            % (k, i, a, w, TOL))
                break
        else:
            if len(got) != len(want):
                errs.append("frame %d: %d changes, wanted %d" % (k, len(got), len(want)))
        if k == 0:
            if t0 < START_MIN or t0 > START_MAX:
                errs.append("the first frame rises at cycle %d, allowed %d to %d"
                            % (t0, START_MIN, START_MAX))
        else:
            gap = t0 - prev_end
            if gap < GAP_MIN:
                errs.append("rest before frame %d is %d cycles, at least %d wanted" % (k, gap, GAP_MIN))
            elif gap > GAP_MAX:
                errs.append("rest before frame %d is %d cycles, at most %d allowed" % (k, gap, GAP_MAX))
        prev_end = t0 + FRAME
    if groups and len(groups) == len(frames) and cycles - prev_end < GAP_MIN:
        errs.append("the run ended %d cycles after the last stop bits, too soon to see the rest"
                    % (cycles - prev_end))
    return errs


def judge(frames, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = p0_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(frames, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(frames, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(frames):
    """Long enough for the latest first rise and the longest rests allowed."""
    return START_MAX + len(frames) * (FRAME + GAP_MAX)


def run_case(run_dir, args, frames):
    """(objections, cycles from P0's first change to its last or None)."""
    words = tx_words(frames)
    cycles = run_cycles(frames)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "dsi.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in p0_changes(out.stdout)[1:]]
    return judge(frames, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def cases_for(seed):
    """(name, frames): fixed cases, then seeded random ones."""
    fixed = [
        ("all zeros", [0x00]),
        ("all ones", [0xFF]),
        ("the task sheet's example", [0xA5]),
        ("alternating and single bits", [0x55, 0xAA, 0x01, 0x80]),
        ("eight frames", [0x00, 0xFF, 0x7F, 0xFE, 0x33, 0xCC, 0x81, 0x18]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_FRAMES) if n % 2 else rng.randint(1, 3)
        rand.append(("random %d" % n, [rng.randrange(256) for _ in range(count)]))
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
    for name in ("pe_sim", "dsi.s", "run_args.txt"):
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
    for n, (name, frames) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, frames)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (len(frames), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d frame%s): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
