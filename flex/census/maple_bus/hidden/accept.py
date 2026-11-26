#!/usr/bin/env python3
"""Hidden acceptance test for the blind Maple bus transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (maple_bus.s, run_args.txt) and pe_sim, which may
be a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet
fixes what the TX words mean, and this test builds them itself.

For each case (one to four frames) the test
  1. builds the TX words the task sheet defines: per frame, the word
     (N << 8 | sender), the word (recipient << 8 | command), then the 4N data
     bytes two to a word, the earlier byte in bits 15..8. No checksum, no
     line levels,
  2. runs RUN_DIR/pe_sim on RUN_DIR/maple_bus.s with those words,
  3. turns the printed changes of P0 (SDCKA) and P1 (SDCKB) into a logic
     capture (a VCD file at 100 MHz, two samples per 50 MHz core cycle),
  4. has sigrok-cli's `maple_bus` decoder read it and requires its
     annotations, bit annotations aside, to be exactly: per frame, the start
     pattern, the size, sender, recipient and command bytes, the data bytes,
     the checksum (the XOR of all the frame's bytes before it) and the end
     pattern, in order, with nothing else (no frame, size or checksum error),
  5. checks from the pin changes what the decoder does not: both lines high
     at cycle 0, the exact order of changes the sheet gives (start pattern,
     clock up, data, clock down, the full end pattern), never both lines in
     one cycle, at least 7 cycles between changes on different lines, at
     least 12 between changes on the same line, at most 100 between changes
     inside a frame, the first frame by cycle 50000, 100 to 50000 cycles of
     idle between frames, nothing after the last frame.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<host bytes> cycles=<cycles from the first change to the last>
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

CLOCK_HZ = 50_000_000      # core clock: one cycle = 20 ns
CROSS_MIN = 7              # cycles between changes on different lines, at least (140 ns)
SAME_MIN = 12              # cycles between changes on the same line, at least (240 ns)
IN_FRAME_MAX = 100         # cycles between neighbouring changes inside a frame, at most (2 us)
GAP_MIN = 100              # idle cycles between frames, at least (2 us)
GAP_MAX = 50_000           # and at most (1 ms)
START_MAX = 50_000         # the first frame's first change by this cycle (1 ms)
MAX_WORDS = 255            # N, the data words of a frame, 0 to this
MAX_FRAMES = 4             # frames in one run
A, B = 0, 1                # SDCKA on P0, SDCKB on P1
NAME = "AB"
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")
FIELD = ["Size", "SrcAP", "DstAP", "Cmd"]


# ---------------------------------------------------------------- the frame

def frame_bytes(frame):
    """The bytes on the wire: N, sender, recipient, command, data, checksum."""
    src, dst, cmd, data = frame
    body = [len(data) // 4, src, dst, cmd] + list(data)
    check = 0
    for b in body:
        check ^= b
    return body + [check]


def byte_name(k, n_bytes):
    if k < 4:
        return "%s byte" % FIELD[k]
    if k == n_bytes - 1:
        return "the checksum"
    return "data byte %d" % (k - 4)


def ideal_changes(frame):
    """[(line, level, where)]: every change of a frame, in order.

    Start: A falls, B falls and rises four times, A rises. Bit j of the frame
    (bytes in order, most significant bit first) is clocked by A if j is even,
    with the data on B, and by B if odd, with the data on A: the clock line
    rises if it is low, the data line takes the bit if it differs, the clock
    line falls. End: A rises if low, B rises, B falls, A falls, rises, falls,
    rises, B rises."""
    level = [1, 1]
    out = []

    def change(line, v, where):
        if level[line] != v:
            level[line] = v
            out.append((line, v, where))

    change(A, 0, "the start pattern")
    for _ in range(4):
        change(B, 0, "the start pattern")
        change(B, 1, "the start pattern")
    change(A, 1, "the start pattern")
    data = frame_bytes(frame)
    j = 0
    for k, byte in enumerate(data):
        for bit in range(7, -1, -1):
            clock, wire = (A, B) if j % 2 == 0 else (B, A)
            where = "%s, bit %d" % (byte_name(k, len(data)), bit)
            change(clock, 1, where)
            change(wire, (byte >> bit) & 1, where)
            change(clock, 0, where)
            j += 1
    for line, v in ((A, 1), (B, 1), (B, 0), (A, 0), (A, 1), (A, 0), (A, 1), (B, 1)):
        change(line, v, "the end pattern")    # all but the first always change
    return out


def decoder_tokens(frame):
    """What sigrok's maple_bus decoder should say of a frame, bits aside."""
    data = frame_bytes(frame)
    out = ["Start pattern"]
    for k, b in enumerate(data):
        name = FIELD[k] if k < 4 else ("Cksum" if k == len(data) - 1 else "Data")
        out.append("%s: %02X" % (name, b))
    return out + ["End pattern"]


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The TX words of one run, as the task sheet defines them. Payload only:
    no checksum, nothing about the lines."""
    words = []
    for src, dst, cmd, data in frames:
        words.append((len(data) // 4) << 8 | src)
        words.append(dst << 8 | cmd)
        for i in range(0, len(data), 2):
            words.append(data[i] << 8 | data[i + 1])
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name). P0
    and P1 must be made push-pull, and never anything else."""
    i = 0
    modes = {}
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) == 1 and hits[0] in ("tx", "cycles"):
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.fullmatch(r"(\d+)=(\w+)", args[i + 1])
            if m:
                modes.setdefault(int(m.group(1)), []).append(m.group(2))
        i += 2
    for pin in (A, B):
        if modes.get(pin, []) == [] or any(m != "pp" for m in modes[pin]):
            return "run_args.txt must make P%d push-pull (-mode %d=pp), and nothing else" % (pin, pin)
    return None


# ------------------------------------------------- from pe_sim to a capture

def line_changes(sim_stdout):
    """[(cycle, a, b)] from pe_sim's "pins CYCLE XX" lines: the levels of P0
    and P1 at the first line, then each line at which either changed."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, v = int(part[1]), int(part[2], 16)
            ab = ((v >> A) & 1, (v >> B) & 1)
            if not out or out[-1][1:] != ab:
                out.append((cycle,) + ab)
    return out


def events_of(changes):
    """[(cycle, line, level)], one per line that changed (two if both did)."""
    out = []
    for (c0, a0, b0), (c1, a1, b1) in zip(changes, changes[1:]):
        if a1 != a0:
            out.append((c1, A, a1))
        if b1 != b0:
            out.append((c1, B, b1))
    return out


def write_vcd(path, changes, cycles):
    with open(path, "w") as f:
        f.write("$timescale 10 ns $end\n$scope module pins $end\n")
        f.write("$var wire 1 ! SDCKA $end\n$var wire 1 \" SDCKB $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for cycle, a, b in changes:
            if cycle < cycles:
                f.write("#%d\n%d!\n%d\"\n" % (2 * cycle, a, b))
        f.write("#%d\n" % (2 * cycles))


def sigrok_tokens(changes, cycles):
    """The maple_bus decoder's annotations, in order, its bit row left out."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "maple.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "maple_bus:sdcka=SDCKA:sdckb=SDCKB",
               "-A", "maple_bus", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m and not m.group(3).startswith("Bit: "):
            found.append(m.group(3).strip())
    return found


# ------------------------------------------------------------ the two checks

def check_decoder(frames, changes, cycles):
    got = sigrok_tokens(changes, cycles)
    want = [t for f in frames for t in decoder_tokens(f)]
    if got == want:
        return []
    errs = []
    bad = [t for t in got if "error" in t.lower()]
    if bad:
        errs.append("the decoder reported %s" % ", ".join(sorted(set(bad))))
    i = next((i for i in range(min(len(got), len(want))) if got[i] != want[i]), None)
    if i is not None:
        errs.append("annotation %d is %r, wanted %r" % (i, got[i], want[i]))
    elif len(got) != len(want):
        errs.append("%d annotations, wanted %d (%s)" % (
            len(got), len(want),
            "first missing %r" % want[len(got)] if len(got) < len(want) else "extra %r" % got[len(want)]))
    return errs


def check_waveform(frames, changes, cycles):
    """The rules of the task sheet that the decoder does not hold to."""
    if not changes or changes[0][0] != 0:
        return ["no level for the lines at cycle 0 in the simulator's output"]
    errs = []
    if changes[0][1:] != (1, 1):
        errs.append("SDCKA=%d SDCKB=%d at cycle 0: both must be high until the first frame"
                    % changes[0][1:])
    events = events_of(changes)
    both = [c for (c, a, b), (_, a0, b0) in zip(changes[1:], changes) if a != a0 and b != b0]
    if both:
        errs.append("both lines changed in the same cycle, first at cycle %d" % both[0])
    want, starts = [], []
    for f in frames:
        starts.append(len(want))
        want += ideal_changes(f)
    got = [(l, v) for (c, l, v) in events]
    for i, (g, w) in enumerate(zip(got, [(l, v) for (l, v, _) in want])):
        if g != w:
            k = max(n for n, s in enumerate(starts) if s <= i)
            errs.append("change %d (cycle %d) is %s %s, wanted %s %s in frame %d, %s"
                        % (i, events[i][0], NAME[g[0]], "rising" if g[1] else "falling",
                           NAME[w[0]], "rising" if w[1] else "falling", k, want[i][2]))
            return errs
    if len(got) != len(want):
        if len(got) < len(want):
            k = max(n for n, s in enumerate(starts) if s <= len(got))
            errs.append("%d changes on the lines, wanted %d: missing from frame %d, %s"
                        % (len(got), len(want), k, want[len(got)][2]))
        else:
            errs.append("%d changes on the lines, wanted %d: %s %s at cycle %d after the last frame"
                        % (len(got), len(want), NAME[events[len(want)][1]],
                           "rising" if events[len(want)][2] else "falling", events[len(want)][0]))
        return errs
    # The order is right: now the timing, frame by frame.
    ends = starts[1:] + [len(events)]
    last = {A: None, B: None}
    for i, (c, line, v) in enumerate(events):
        k = max(n for n, s in enumerate(starts) if s <= i)
        where = "frame %d, %s" % (k, want[i][2])
        if i > 0:
            pc, pline, _ = events[i - 1]
            if pline != line and c - pc < CROSS_MIN:
                errs.append("%s: %s changes %d cycles after %s (at least %d)"
                            % (where, NAME[line], c - pc, NAME[pline], CROSS_MIN))
            if i != starts[k] and c - pc > IN_FRAME_MAX:
                errs.append("%s: %d cycles without a change inside a frame (at most %d)"
                            % (where, c - pc, IN_FRAME_MAX))
        if last[line] is not None and c - last[line] < SAME_MIN:
            errs.append("%s: %s changes %d cycles after its own last change (at least %d)"
                        % (where, NAME[line], c - last[line], SAME_MIN))
        last[line] = c
        if len(errs) > 3:
            break
    first = events[starts[0]][0]
    if first > START_MAX:
        errs.append("the first frame starts at cycle %d, limit %d" % (first, START_MAX))
    for k in range(1, len(frames)):
        gap = events[starts[k]][0] - events[ends[k - 1] - 1][0]
        if gap < GAP_MIN:
            errs.append("idle before frame %d is %d cycles, at least %d" % (k, gap, GAP_MIN))
        elif gap > GAP_MAX:
            errs.append("idle before frame %d is %d cycles, at most %d" % (k, gap, GAP_MAX))
    if cycles - events[-1][0] < GAP_MIN:
        errs.append("the run ended %d cycles after the last change, too soon to see the idle"
                    % (cycles - events[-1][0]))
    return errs


def judge(frames, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = line_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(frames, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(frames, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(frames):
    """Long enough for the latest start, the slowest frames and the longest
    idles allowed."""
    return START_MAX + sum(len(ideal_changes(f)) * IN_FRAME_MAX + GAP_MAX for f in frames)


def run_case(run_dir, args, frames):
    """(objections, cycles from the first change to the last, or None)."""
    words = tx_words(frames)
    cycles = run_cycles(frames)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "maple_bus.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    ev = events_of(line_changes(out.stdout))
    return judge(frames, out.stdout, cycles), (ev[-1][0] - ev[0][0] if ev else None)


def pattern(n, a, b):
    return [(k * a + b) & 0xFF for k in range(n)]


def cases_for(seed):
    """(name, frames): fixed cases, then seeded random ones. A frame is
    (sender, recipient, command, data bytes)."""
    fixed = [
        ("device info request, no data", [(0x00, 0x20, 0x01, [])]),
        ("the task sheet's second example", [(0x00, 0x01, 0x09, [0xDE, 0xAD, 0xBE, 0xEF])]),
        ("all zeros", [(0x00, 0x00, 0x00, [0x00] * 4)]),
        ("all ones", [(0xFF, 0xFF, 0xFF, [0xFF] * 4)]),
        ("alternating bits", [(0x55, 0xAA, 0x55, [0xAA, 0x55, 0xAA, 0x55] * 2)]),
        ("four frames, 0 to 3 words", [(0x00, 0x20, 0x01, []),
                                       (0x20, 0x00, 0x05, pattern(4, 29, 3)),
                                       (0x00, 0x01, 0x0C, pattern(8, 53, 7)),
                                       (0x00, 0x02, 0x0B, pattern(12, 101, 250))]),
        ("128 words", [(0x00, 0x01, 0x0C, pattern(4 * 128, 37, 11))]),
        ("255 words, the most", [(0x00, 0x20, 0x0C, pattern(4 * MAX_WORDS, 91, 200))]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_FRAMES)
        longest = 40 if n % 2 else 6
        frames = []
        for _ in range(count):
            words = rng.randint(0, longest)
            frames.append((rng.randrange(256), rng.randrange(256), rng.randrange(256),
                           [rng.randrange(256) for _ in range(4 * words)]))
        rand.append(("random %d" % n, frames))
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
    for name in ("pe_sim", "maple_bus.s", "run_args.txt"):
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
        size = sum(4 + len(f[3]) for f in frames)
        if not errs:
            rate = (size, span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d frame%s, %d host bytes): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s", size, status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
