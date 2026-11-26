#!/usr/bin/env python3
"""Hidden acceptance test for the blind OOK (on-off keying) transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (ook.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet fixes
what the TX words mean, and this test builds them itself.

For each case (a list of frames, each a list of payload bytes) the test
  1. builds the TX words the task sheet defines: one word per byte, bits
     7..0 the byte, bit 8 set on the last byte of a frame, the rest 0,
  2. runs RUN_DIR/pe_sim on RUN_DIR/ook.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per core clock cycle, 1 MHz), exactly as printed, the start-up
     level included,
  4. has sigrok-cli's `ook` decoder (Manchester, preamble 1111, filter
     length 7, not inverted) read it and requires the decoded bits to be
     exactly the wanted frames, in order, with nothing extra, no 'E' bit, no
     error message and no preamble reset after the first frame began,
  5. checks, from the pin changes themselves, what the decoder does not:
     P0 driven low by cycle 100, the first frame between cycle 5000 and
     20000, every transition within +-2 cycles of its ideal place counted
     from its frame's first rise, the line low at the end of each frame,
     the gap between frames, and silence after the last frame.

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

CLOCK_HZ = 1_000_000         # core clock: one cycle = 1 us
BAUD = 2000                  # bit rate
BIT = CLOCK_HZ // BAUD       # 500 cycles a bit
HALF = BIT // 2              # 250 cycles a half bit
TOL = 2                      # cycles a transition may be from its ideal place
GAP_MIN = 10 * BIT           # silence between frames, at least (5 ms)
GAP_MAX = 20_000             # and at most (20 ms)
LOW_BY = 100                 # P0 must be driven low by this cycle
START_MIN = 5_000            # the first frame's first rise, not before this cycle
START_MAX = 20_000           # and not after this one
MAX_BYTES = 16               # payload bytes in a frame, 1 to this
MAX_FRAMES = 6               # frames in one run
LAST = 0x100                 # bit 8 of a TX word: the last byte of a frame
PREAMBLE = [1] * 16
SYNC = [0, 1, 0, 1]
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
SPLIT = 2 * BIT              # more silence than this between two transitions
                             # ends a frame (inside one the most is BIT)
PIN = 0                      # P0
DECODER = "ook:data=P0:decodeas=Manchester:preamble=1111:preamlen=7:invert=no"


# ---------------------------------------------------------------- the code

def frame_bits(frame):
    """Preamble, sync nibble, the bytes most significant bit first."""
    return PREAMBLE + SYNC + [(b >> k) & 1 for b in frame for k in range(7, -1, -1)]


def ideal_offsets(bits):
    """Where the transitions of a frame belong, in cycles after its first.

    The frame as a row of half-bit levels (a 1 is high then low, a 0 low
    then high), the line low before it and low after it: a transition
    wherever two neighbouring halves differ."""
    halves = [0]
    for b in bits:
        halves += [1, 0] if b else [0, 1]
    halves.append(0)
    at = [i * HALF for i in range(len(halves) - 1) if halves[i] != halves[i + 1]]
    return [a - at[0] for a in at]


def decoder_wants(bits):
    """What sigrok's ook decoder prints for one ideal frame: every bit, and
    one '1' more when the last bit is a 0. That extra bit is the decoder's
    reading of the end of the frame (its time-out takes the high second half
    of a final 0 as the start of another bit); it is checked against the
    decoder on the ideal waveforms by selftest.py."""
    return "".join(str(b) for b in bits) + ("1" if bits[-1] == 0 else "")


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The TX words of one run, as the task sheet defines them: one word per
    byte in order, the byte in bits 7..0, bit 8 set on the last byte of each
    frame, every other bit 0. Payload only: nothing about the line."""
    words = []
    for frame in frames:
        for i, byte in enumerate(frame):
            words.append(byte | (LAST if i == len(frame) - 1 else 0))
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


def sigrok_annotations(changes, cycles):
    """sigrok's ook decoder on the capture: its annotations' texts, in order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", DECODER,
               "-A", "ook", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append(m.group(3).strip())
    return found


def decoded_frames(annotations):
    """(frames as bit strings, objections). 'T' ends a frame. 'R' is the
    decoder throwing away pulses that do not look like a preamble: allowed
    only before the first bit (the start-up level of a push-pull pin, which
    the firmware drives low by cycle 100, gives one), never later."""
    frames, cur, errs = [], "", []
    for a in annotations:
        if a in ("0", "1"):
            cur += a
        elif a == "T":
            frames.append(cur)
            cur = ""
        elif a == "R":
            if frames or cur:
                errs.append("the decoder reset its preamble search after frame %d had begun"
                            % len(frames))
        elif a == "E":
            errs.append("the decoder marked a bit of frame %d invalid (E)" % len(frames))
            cur += "E"
        else:
            errs.append("the decoder said %r" % a[:60])
    if cur:
        frames.append(cur)
    return frames, errs


# ------------------------------------------------------------ the two checks

def where(k):
    """Bit k of a frame, in words."""
    if k < 16:
        return "preamble bit %d" % k
    if k < 20:
        return "sync bit %d" % (k - 16)
    return "bit %d of byte %d" % (7 - (k - 20) % 8, (k - 20) // 8)


def check_decoder(frames, changes, cycles):
    """The decoded bits must be the wanted frames and nothing else."""
    got, errs = decoded_frames(sigrok_annotations(changes, cycles))
    want = [decoder_wants(frame_bits(f)) for f in frames]
    if got == want:
        return errs
    if len(got) != len(want):
        errs.append("decoded %d frames, wanted %d" % (len(got), len(want)))
    for k, (g, w) in enumerate(zip(got, want)):
        if g == w:
            continue
        n = min(len(g), len(w))
        i = next((i for i in range(n) if g[i] != w[i]), n)
        if i < len(frame_bits(frames[k])):
            errs.append("frame %d: %s decoded as %s" % (k, where(i), g[i] if i < len(g) else "nothing"))
        else:
            errs.append("frame %d decoded as %d bits, wanted %d" % (k, len(g), len(w)))
        break
    return errs or ["decoded frames differ from the wanted ones"]


def check_waveform(frames, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    errs = []
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    edges = [c for c, _ in changes[1:]]
    if changes[0][1] == 1:
        if not edges or edges[0] > LOW_BY:
            errs.append("P0 is not driven low by cycle %d" % LOW_BY)
            return errs
        edges = edges[1:]
    groups = []
    for e in edges:
        if groups and e - groups[-1][-1] <= SPLIT:
            groups[-1].append(e)
        else:
            groups.append([e])
    if len(groups) != len(frames):
        errs.append("%d separate bursts of transitions on P0, wanted %d frames"
                    % (len(groups), len(frames)))
    prev_end = None
    for k, (g, frame) in enumerate(zip(groups, frames)):
        bits = frame_bits(frame)
        want = ideal_offsets(bits)
        got = [e - g[0] for e in g]
        for i, (a, w) in enumerate(zip(got, want)):
            if abs(a - w) > TOL:
                errs.append("frame %d: transition %d is %d cycles after the first, ideal %d (limit +-%d)"
                            % (k, i, a, w, TOL))
                break
        else:
            if len(got) != len(want):
                errs.append("frame %d: %d transitions, wanted %d" % (k, len(got), len(want)))
        if k == 0:
            if g[0] < START_MIN:
                errs.append("the first frame begins at cycle %d, not before %d allowed" % (g[0], START_MIN))
            elif g[0] > START_MAX:
                errs.append("the first frame begins at cycle %d, limit %d" % (g[0], START_MAX))
        else:
            gap = g[0] - prev_end
            if gap < GAP_MIN:
                errs.append("gap before frame %d is %d cycles, at least %d wanted" % (k, gap, GAP_MIN))
            elif gap > GAP_MAX:
                errs.append("gap before frame %d is %d cycles, at most %d allowed" % (k, gap, GAP_MAX))
        prev_end = g[0] + len(bits) * BIT
    # Every burst holds an even number of transitions only if the line ends
    # each frame where it began, low; check the level itself too.
    level = changes[-1][1]
    if level != 0:
        errs.append("P0 is high at the end of the run")
    if groups and len(groups) == len(frames) and cycles - prev_end < GAP_MIN:
        errs.append("the run ended %d cycles after the last frame, too soon to see the silence"
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
    """Long enough for the latest start and the longest gaps allowed."""
    return START_MAX + sum(len(frame_bits(f)) * BIT + GAP_MAX for f in frames)


def run_case(run_dir, args, frames):
    """(objections, cycles from P0's first change to its last or None)."""
    words = tx_words(frames)
    cycles = run_cycles(frames)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "ook.s"),
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
        ("all zeros", [[0x00]]),
        ("all ones", [[0xFF]]),
        ("the task sheet's example", [[0xA5]]),
        ("the task sheet's words", [[0xA5], [0x12, 0x34, 0xFF]]),
        ("alternating bits, both orders, ends 0 and 1", [[0x55], [0xAA], [0x01], [0x80]]),
        ("16 bytes", [[(k * 37 + 11) & 0xFF for k in range(MAX_BYTES)]]),
        ("six one-byte frames", [[b] for b in (0x00, 0xFF, 0x7F, 0xFE, 0x33, 0xCC)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_FRAMES)
        longest = MAX_BYTES if n % 2 else 4
        rand.append(("random %d" % n,
                     [[rng.randrange(256) for _ in range(rng.randint(1, longest))]
                      for _ in range(count)]))
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
    for name in ("pe_sim", "ook.s", "run_args.txt"):
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
            rate = (sum(len(f) for f in frames), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        size = sum(len(f) for f in frames)
        print("case %d (%s: %d frame%s, %d byte%s): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
