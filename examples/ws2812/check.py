"""Test harness: encode frames with host.py, run pe_sim, decode P0 like an LED.

Usage: python3 check.py [seed] [nframes] [maxleds]
"""
import os
import random
import shlex
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import host  # noqa: E402

NS = 100  # ns per cycle


def run_sim(words, cycles, txname="tx_check.txt"):
    txpath = os.path.join(HERE, txname)
    with open(txpath, "w") as f:
        for w in words:
            f.write("0x%04x\n" % w)
    with open(os.path.join(HERE, "run_args.txt")) as f:
        args = shlex.split(f.read())
    cmd = [os.path.join(HERE, "pe_sim"), "run", os.path.join(HERE, "ws2812.s")]
    cmd += args + ["-tx", txpath, "-cycles", str(cycles)]
    out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    events = []
    for line in out.splitlines():
        parts = line.split()
        if len(parts) == 3 and parts[0] == "pins":
            events.append((int(parts[1]), int(parts[2], 16) & 1))
    return events


def decode(events, end_cycle):
    """Return (frames as lists of bits, list of error strings, notes)."""
    # Build list of (level, start, length) runs for P0.
    runs = []
    level, start = None, 0
    for cyc, lvl in events:
        if lvl == level:
            continue
        if level is not None:
            runs.append((level, start, cyc - start))
        level, start = lvl, cyc
    runs.append((level, start, end_cycle - start))
    errors, notes = [], []
    frames, cur = [], []
    # Leading: the output register resets high; allow a reset-time pulse
    # if it is followed by >= 280 us low.
    i = 0
    if runs and runs[0][0] == 1 and runs[0][1] == 0:
        notes.append("reset-time high pulse of %d ns at cycle 0" % (runs[0][2] * NS))
        if len(runs) < 2 or runs[1][2] * NS < 280_000:
            errors.append("reset high pulse not followed by a latch")
        i = 2
    elif runs and runs[0][0] == 0:
        if runs[0][2] * NS < 280_000 and len(runs) > 1:
            errors.append("initial low only %d ns" % (runs[0][2] * NS))
        i = 1
    while i < len(runs):
        lvl, st, ln = runs[i]
        assert lvl == 1
        hi = ln * NS
        if 250 <= hi <= 550:
            bit = 0
        elif 650 <= hi <= 950:
            bit = 1
        else:
            errors.append("cycle %d: high of %d ns is neither bit" % (st, hi))
            bit = None
        cur.append(bit)
        if i + 1 >= len(runs):
            errors.append("trace ends high")
            break
        _, lst, lln = runs[i + 1]
        lo = lln * NS
        last_run = i + 2 >= len(runs)
        if lo >= 280_000 or (last_run and lo >= 280_000):
            frames.append(cur)
            cur = []
        elif last_run:
            errors.append("trace ends %d ns after a bit, no full latch" % lo)
            frames.append(cur)
            cur = []
        else:
            lim = (700, 1000) if bit == 0 else (300, 600)
            if not lim[0] <= lo <= lim[1]:
                errors.append("cycle %d: low of %d ns after a %s bit" % (lst, lo, bit))
        i += 2
    return frames, errors, notes


def bits_of(frame):
    out = []
    for r, g, b in frame:
        for v in (g, r, b):
            out += [(v >> k) & 1 for k in range(7, -1, -1)]
    return out


def check(frames, verbose=True):
    words = host.encode(frames)
    cycles = 3200 + sum(len(f) * 24 * 13 + 3200 for f in frames) + 3200
    events = run_sim(words, cycles)
    got, errors, notes = decode(events, cycles)
    want = [bits_of(f) for f in frames if f]  # empty frames are just latches
    if got != want:
        errors.append("decoded %d frames %s, wanted %d %s" % (
            len(got), [len(x) for x in got], len(want), [len(x) for x in want]))
        for k, (a, b) in enumerate(zip(got, want)):
            if a != b:
                errors.append("frame %d differs" % k)
                break
    if verbose:
        for n in notes:
            print("note:", n)
        for e in errors[:20]:
            print("ERROR:", e)
    return errors, events


if __name__ == "__main__":
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 1
    nframes = int(sys.argv[2]) if len(sys.argv) > 2 else 3
    maxleds = int(sys.argv[3]) if len(sys.argv) > 3 else 5
    rng = random.Random(seed)
    frames = [[tuple(rng.randrange(256) for _ in range(3))
               for _ in range(rng.randrange(0, maxleds + 1))]
              for _ in range(nframes)]
    print("frames:", [len(f) for f in frames])
    errors, _ = check(frames)
    print("OK" if not errors else "FAIL (%d errors)" % len(errors))
