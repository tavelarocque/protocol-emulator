#!/usr/bin/env python3
"""Hidden acceptance test for the blind S/PDIF transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (spdif.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always run as RUN_DIR/pe_sim. Exit status 0 only if
every case passes. A header line, one line per case, an info line, one line
for the last case that passed,
    RATE frames=<frames> cycles=<cycles from P0's first change to its last>
(none if no case passed), then ACCEPT PASS or ACCEPT FAIL.

There is no host.py in round two. The task sheet fixes what the TX words
mean and this test builds them itself: per frame four words, the left
sample's bits 15..0, its bits 23..16 in bits 7..0, then the same two for
the right sample. run_args.txt is two lines: `cell_cycles=N` (2 to 48),
then the -config and -mode flags for pe_sim.

Each case is a list of (left, right) 24-bit samples. The test writes its TX
words, pe_sim runs the firmware, and P0's changes are judged twice:

  1. Directly, from the cycle numbers: the limits of TASK.md that a
     decoder does not look at (every interval between edges 1, 2 or 3 cells
     within 5% of a cell, every subframe 64 cells within 5% of a cell, no
     gaps, the quiet stretch after any start-up edges, nothing after the
     last subframe), and an own decode of preambles, biphase-mark bits and
     parity.
  2. By sigrok's `spdif` protocol decoder (sigrok-cli), which this project
     did not write: its preambles, audio samples, validity, user, channel
     status and parity bits must equal what was asked for, in order.

Python standard library and sigrok-cli only. Written separately from the
firmware and kept from its author (README.md)."""
import os
import random
import re
import shlex
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True  # leave no __pycache__ in the run directory

CLOCK_HZ = 49_152_000        # core clock in TASK.md: one cycle = 20.345 ns
BLOCK = 192                  # frames per block
SUB_CELLS = 64               # cells per subframe
CELL_MIN, CELL_MAX = 2, 48   # allowed CELL_CYCLES
MAX_FRAMES = 400
START_LIMIT = 10_000         # the first preamble must start by this cycle
QUIET_CELLS = 64             # steady cells required after a start-up edge
TOL = 0.05                   # of one cell: the transmitter jitter limit
CSTAT_ONES = (2, 24)         # frames of a block whose channel status bit is 1
PREAMBLES = {(1, 1, 1, 0, 1, 0, 0, 0): "B",
             (1, 1, 1, 0, 0, 0, 1, 0): "M",
             (1, 1, 1, 0, 0, 1, 0, 0): "W"}
K = 4                        # samples per cycle in the capture given to sigrok
SIM_TIMEOUT = 300
WORDS_PER_FRAME = 4
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "tx", "help")  # pe_sim run's


def tx_words(pairs):
    """The TX words of one run, as the task sheet defines them. Per frame:
    left bits 15..0, left bits 23..16 (in bits 7..0), right bits 15..0, right
    bits 23..16 (in bits 7..0). Payload only: no preamble, no coded bit, no
    V, U, C or parity, no count."""
    words = []
    for left, right in pairs:
        words += [left & 0xFFFF, (left >> 16) & 0xFF, right & 0xFFFF, (right >> 16) & 0xFF]
    return words


def args_problem(args):
    """The flags line of run_args.txt may hold -config and -mode flags, each
    with a value, and nothing else (pe_sim takes any unambiguous prefix of a
    flag's name)."""
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


def read_run_args(path):
    """(cell length in cycles, pe_sim flags) from the two lines of run_args.txt."""
    lines = open(path).read().splitlines()
    while lines and not lines[-1].strip():
        lines.pop()
    m = re.fullmatch(r"cell_cycles=([0-9]+)", lines[0].strip()) if lines else None
    if not m:
        raise ValueError("the first line of run_args.txt must be cell_cycles=N")
    n = int(m.group(1))
    if not CELL_MIN <= n <= CELL_MAX:
        raise ValueError("cell_cycles is %d, not an integer from %d to %d" % (n, CELL_MIN, CELL_MAX))
    if len(lines) != 2:
        raise ValueError("run_args.txt must be two lines: cell_cycles=N, then the pe_sim flags")
    args = shlex.split(lines[1])
    problem = args_problem(args)
    if problem:
        raise ValueError(problem)
    return n, args


def expected(pairs):
    """What each subframe must carry: (preamble, sample, V, U, C, P)."""
    want = []
    for f, pair in enumerate(pairs):
        c = 1 if f % BLOCK in CSTAT_ONES else 0
        for ch, sample in enumerate(pair):
            pre = "W" if ch else ("B" if f % BLOCK == 0 else "M")
            p = (bin(sample).count("1") + c) & 1
            want.append((pre, sample, 0, 0, c, p))
    return want


def parse_pins(text):
    """pe_sim's output -> [(cycle, level of P0)], changes of P0 only."""
    changes = []
    for line in text.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            c, v = int(part[1]), int(part[2], 16) & 1
            if not changes or changes[-1][1] != v:
                changes.append((c, v))
    return changes


def direct_check(changes, want, n, cycles):
    """Judge P0 from its changes alone. Returns (errors, stream) where
    stream is None or a dict the sigrok check needs: the edges of the
    stream (cycles), the level before it, and where it should be closed."""
    errs = []
    tol = TOL * n
    if not changes:
        return ["pe_sim printed no pin changes"], None
    edges = [c for c, _ in changes[1:]]
    if not edges:
        return ["P0 never changes"], None
    # The stream starts at the first edge, or, if P0 changed before it
    # (start-up edges), at the last edge that follows a steady stretch of
    # QUIET_CELLS cells or more.
    j = 0
    for i in range(1, len(edges)):
        if edges[i] - edges[i - 1] >= QUIET_CELLS * n:
            j = i
    te = edges[j:]
    idle = changes[j][1]
    note = ""
    if j:
        note = ("the stream was taken to start at cycle %d, the last edge that follows %d "
                "steady cells; %d earlier edge(s) were taken as start-up"
                % (te[0], QUIET_CELLS, j))
    if te[0] > START_LIMIT:
        errs.append("the stream starts at cycle %d, later than %d" % (te[0], START_LIMIT))
    total = SUB_CELLS * len(want)
    cells, at = [], {0: te[0]}          # at: cell index -> cycle of the edge there
    level, bad_width = idle, 0
    close_at = None                     # where an open last pulse should end
    k = 0
    while True:
        level ^= 1                      # the level after edge te[k]
        rest = total - len(cells)       # cells still owed, at least 1
        if k + 1 == len(te):            # the last pulse has no closing edge
            if rest > 3:
                errs.append("the stream stops at cycle %d after %d cells (%.2f subframes); "
                            "wanted %d subframes" % (te[k], len(cells), len(cells) / SUB_CELLS,
                                                     len(want)))
            elif cycles - te[k] < rest * n:
                errs.append("the run ended before the last subframe did")
            else:
                close_at = te[k] + rest * n
            cells += [level] * min(rest, 3)
            break
        d = te[k + 1] - te[k]
        m = max(1, round(d / n))
        if m > rest and rest <= 3:      # the next edge comes after the stream's end
            errs.append("P0 changes at cycle %d, after the last subframe ended" % te[k + 1])
            close_at = te[k] + rest * n
            cells += [level] * rest
            break
        if m > 3 or abs(d - m * n) > tol:
            bad_width += 1
            if bad_width <= 3:
                errs.append("interval of %d cycles at cycle %d is not 1, 2 or 3 cells "
                            "of %d cycles within %.2f" % (d, te[k], n, tol)
                            + (" (a start-up edge must be followed by %d steady cells)"
                               % QUIET_CELLS if k == 0 and m > 3 else ""))
        m = min(m, rest)
        cells += [level] * m
        at[len(cells)] = te[k + 1]
        k += 1
        if len(cells) == total:         # te[k] closes the last cell: allowed, once
            if k + 1 < len(te):
                errs.append("P0 changes at cycle %d, after the last subframe ended" % te[k + 1])
            break
    used = te[:k + 1]
    if bad_width > 3:
        errs.append("%d intervals out of tolerance in all" % bad_width)
    # Subframe length: preamble start to preamble start.
    bad_len = 0
    for s in range(1, len(want) + 1):
        a, b = at.get(SUB_CELLS * (s - 1)), at.get(SUB_CELLS * s)
        if a is not None and b is not None and abs((b - a) - SUB_CELLS * n) > tol:
            bad_len += 1
            if bad_len <= 2:
                errs.append("subframe %d lasts %d cycles, not %d within %.2f"
                            % (s - 1, b - a, SUB_CELLS * n, tol))
    # Own decode of the cells.
    bad = 0

    def complain(msg):
        nonlocal bad
        bad += 1
        if bad <= 4:
            errs.append(msg)

    for s, (pre, sample, v, u, c, p) in enumerate(want):
        sub = cells[SUB_CELLS * s:SUB_CELLS * (s + 1)]
        if len(sub) < SUB_CELLS:
            complain("subframe %d is missing or cut short" % s)
            break
        prev = idle if s == 0 else cells[SUB_CELLS * s - 1]
        got_pre = PREAMBLES.get(tuple(x ^ prev for x in sub[:8]))
        if got_pre is None:
            complain("subframe %d: cells %s are no preamble" %
                     (s, "".join(str(x ^ prev) for x in sub[:8])))
            continue
        if got_pre != pre:
            complain("subframe %d: preamble %s, wanted %s" % (s, got_pre, pre))
        bits, ok = [], True
        for b in range(28):
            first, second = sub[8 + 2 * b], sub[9 + 2 * b]
            if first == sub[7 + 2 * b]:
                ok = False
            bits.append(first ^ second)
        if not ok:
            complain("subframe %d: a bit does not start with an edge (not biphase-mark)" % s)
            continue
        if sum(bits) & 1:
            complain("subframe %d: odd parity over time slots 4 to 31" % s)
        got = sum(bit << i for i, bit in enumerate(bits[:24]))
        if got != sample:
            complain("subframe %d: sample 0x%06x, wanted 0x%06x" % (s, got, sample))
        if bits[24:28] != [v, u, c, p]:
            complain("subframe %d: V U C P = %d %d %d %d, wanted %d %d %d %d"
                     % (s, *bits[24:28], v, u, c, p))
    if bad > 4:
        errs.append("%d subframe errors in all" % bad)
    if errs and note:
        errs.append(note)
    return errs, {"edges": used, "idle": idle, "close_at": close_at}


def sigrok_check(stream, want, n, workdir):
    """Hand the stream to sigrok's spdif decoder and compare what it reports.

    The decoder learns the three pulse widths from the first pulses it sees
    and only then looks for a preamble, so it can never report the first
    subframe of a capture. The capture therefore begins with one ideal
    lead-in subframe made here (preamble W, 28 zero bits, at the nominal
    cell width, ending at the level the firmware's line idles at). The
    decoder locks on it, reports nothing for it, and is ready when the
    firmware's first preamble arrives. Everything from that edge on is the
    firmware's own waveform, sample for sample, except one closing edge
    appended where the last subframe ends if the firmware (correctly) leaves
    the line steady there: a decoder only sees a cell when an edge ends it."""
    te, idle = stream["edges"], stream["idle"]
    lead = [0, 3, 5, 6] + list(range(8, SUB_CELLS, 2))   # 32 edges: ends at idle
    s0 = 1 + SUB_CELLS * n * K                           # sample of the first edge
    times = [1 + c * n * K for c in lead] + [s0 + (t - te[0]) * K for t in te]
    if stream["close_at"] is not None:
        times.append(s0 + (stream["close_at"] - te[0]) * K)
    path = os.path.join(workdir, "p0.vcd")
    with open(path, "w") as f:
        f.write("$timescale %d ps $end\n" % round(1e12 / (CLOCK_HZ * K)))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n#0\n%d!\n" % idle)
        level = idle
        for t in times:
            level ^= 1
            f.write("#%d\n%d!\n" % (t, level))
        f.write("#%d\n" % (times[-1] + 8 * n * K))
    cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", "spdif",
           "--protocol-decoder-samplenum",
           "-A", "spdif=preamble:samples:validity:subcode:chan_stat:parity"]
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=SIM_TIMEOUT)
    except FileNotFoundError:
        return ["sigrok-cli is not installed"]
    except subprocess.TimeoutExpired:
        return ["sigrok-cli timed out"]
    if r.returncode != 0 or "Traceback" in r.stderr or "srd:" in r.stderr:
        tail = [l for l in r.stderr.splitlines() if l.strip()][-1:] or ["no message"]
        return ["sigrok's decoder failed on the waveform (%s)" % tail[0][:120]]
    got, cur = [], None
    for line in r.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if not m:
            continue
        start, text = int(m.group(1)), m.group(3).strip()
        if text.startswith("Preamble") or text.startswith("Unknown"):
            cur = {"start": start, "pre": text.split()[-1]}
            got.append(cur)
        elif cur is None:
            continue
        elif text.startswith("Audio"):
            cur["sample"] = int(text.split()[1], 16)
        elif text in ("V", "E"):
            cur["v"] = 0 if text == "V" else 1
        elif text.startswith("S:"):
            cur["u"] = int(text[2:])
        elif text.startswith("C:"):
            cur["c"] = int(text[2:])
        elif text.startswith("P:"):
            cur["p"] = int(text[2:])
    got = [g for g in got if g["start"] >= s0 - n * K]    # none is expected before
    errs = []
    if len(got) != len(want):
        errs.append("sigrok decoded %d subframes, wanted %d" % (len(got), len(want)))
    bad = 0
    for s, (g, w) in enumerate(zip(got, want)):
        seen = (g["pre"], g.get("sample"), g.get("v"), g.get("u"), g.get("c"), g.get("p"))
        if seen != w:
            bad += 1
            if bad <= 3:
                errs.append("sigrok subframe %d: %s, wanted %s" % (s, show(seen), show(w)))
    if bad > 3:
        errs.append("sigrok: %d subframes differ in all" % bad)
    return errs


def show(t):
    pre, sample, v, u, c, p = t
    if None in t:
        return "preamble %s, incomplete subframe" % pre
    return "preamble %s sample 0x%06x V%d U%d C%d P%d" % (pre, sample, v, u, c, p)


def judge_text(text, pairs, n, cycles, workdir):
    """Judge one run from pe_sim's printed output. Returns a list of errors."""
    want = expected(pairs)
    errs, stream = direct_check(parse_pins(text), want, n, cycles)
    if stream is not None:
        errs += sigrok_check(stream, want, n, workdir)
    return errs


def make_cases(seed):
    rng = random.Random(seed)
    r24 = lambda: rng.randrange(1 << 24)
    special = [0, 0xFFFFFF, 0x800000, 0x7FFFFF, 1, 0x555555, 0xAAAAAA, 0xF, 0xFFFFF0]
    cases = [
        ("one frame of silence", [(0, 0)]),
        ("extremes", [(0xFFFFFF, 0x000000), (0x000001, 0x800000), (0x7FFFFF, 0xFFFFFF)]),
        ("patterns", [(0x123456, 0xABCDEF), (0x555555, 0xAAAAAA), (0x00000F, 0xFFFFF0),
                      (0xF0F0F0, 0x0F0F0F), (0xFFFFFF, 0xFFFFFF)]),
        ("ramp across a block boundary", [(i * 0x010203 & 0xFFFFFF, 0xFFFFFF - i) for i in range(193)]),
        ("two block boundaries", [(r24(), r24()) for _ in range(MAX_FRAMES)]),
    ]
    lengths = [rng.randint(1, 12), rng.randint(13, 60), rng.randint(61, 191),
               rng.randint(193, 300), rng.randint(301, MAX_FRAMES), rng.randint(1, MAX_FRAMES)]
    for length in lengths:
        pairs = []
        for _ in range(length):
            pairs.append(tuple(rng.choice(special) if rng.random() < 0.15 else r24()
                               for _ in range(2)))
        cases.append(("random", pairs))
    return cases


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(sys.argv[1])
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    sim = os.path.join(run_dir, "pe_sim")
    try:
        n, args = read_run_args(os.path.join(run_dir, "run_args.txt"))
    except Exception as e:  # noqa: BLE001
        print("cannot load the hand-in: %s: %s" % (type(e).__name__, e))
        print("ACCEPT FAIL")
        return 1
    print("cell = %d cycles = %.1f ns, sample rate %.1f Hz, seed %d"
          % (n, n * 1e9 / CLOCK_HZ, CLOCK_HZ / (128 * n), seed))
    failures, rate = 0, None
    cases = make_cases(seed)
    for num, (name, pairs) in enumerate(cases):
        errs, span = [], None
        with tempfile.TemporaryDirectory() as d:
            words = tx_words(pairs)
            tx = os.path.join(d, "tx.txt")
            with open(tx, "w") as f:
                f.write("".join("%d\n" % w for w in words))
            cycles = START_LIMIT + (128 * len(pairs) + 256) * n
            cmd = [sim, "run", os.path.join(run_dir, "spdif.s"),
                   "-tx", tx, "-cycles", str(cycles)] + args
            try:
                r = subprocess.run(cmd, capture_output=True, text=True, timeout=SIM_TIMEOUT)
                if r.returncode != 0:
                    said = [l.strip() for l in r.stderr.splitlines()
                            if l.strip() and not l.startswith(("Raised", "Called", "Re-raised"))]
                    errs.append("pe_sim exited with status %d: %s"
                                % (r.returncode, " ".join(said[:3])[:200]))
                else:
                    errs = judge_text(r.stdout, pairs, n, cycles, d)
                    moved = [c for c, _ in parse_pins(r.stdout)[1:]]
                    span = moved[-1] - moved[0] if moved else None
            except (OSError, subprocess.TimeoutExpired) as e:
                errs.append("pe_sim could not be run: %s" % e)
            except Exception as e:  # never report a pass because the judge fell over
                errs = ["judge: %s: %s" % (type(e).__name__, e)]
        if not errs and span is not None:
            rate = (len(pairs), span)
        status = "PASS" if not errs else "FAIL: " + "; ".join(errs[:6])
        print("case %d (%s, %d frames): %s" % (num, name, len(pairs), status))
        failures += bool(errs)
    # Not part of the verdict: the simulator's host never falls behind, a real one can.
    print("info: %d TX words a frame, %.0f words a second at this sample rate "
          "(isa.md: the host port carries 260,000)"
          % (WORDS_PER_FRAME, WORDS_PER_FRAME * CLOCK_HZ / (128 * n)))
    if rate:
        print("RATE frames=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failures else "ACCEPT FAIL")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
