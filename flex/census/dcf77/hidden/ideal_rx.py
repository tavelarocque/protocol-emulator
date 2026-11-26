#!/usr/bin/env python3
"""An ideal DCF77 receiver, as a list of "rx" lines: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_rx.py [--fault NAME] run ANY.s -stimulus FILE -cycles N [ignored ...]

reads the stimulus (the levels of P0 over time, "CYCLE HEX" per line) and
prints what a correct receiver would push, in the simulator's format
("rx CYCLE WORD", the word in decimal), by the task sheet's rules. It works
from the waveform's edges alone, in its own way: it never sees the bits the
judge put in, so the ideal result passes only if the judge's stimulus, the
judge's expected words, this reading of the task sheet and sigrok agree.

--fault breaks the result in one named way (FAULTS below), to show that the
judge fails what it should. A few names are not faults but results at the
very edge of what the task sheet allows, which must still pass."""
import sys

MS = 100                 # cycles a millisecond at 100 kHz

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: each word pushed 1 cycle after its pulse's falling edge"),
    "atrise":      (True,  "each word pushed at its pulse's rising edge (the earliest allowed)"),
    "deadline":    (True,  "each word pushed 500 ms after its pulse's rising edge (the latest allowed)"),
    "late501":     (False, "one word pushed 501 ms after its pulse's rising edge"),
    "flipbit":     (False, "the value of one bit inverted"),
    "noflag":      (False, "the first-of-minute flag left off the last minute's bit 0"),
    "flagmore":    (False, "the first-of-minute flag also set on the pulse after bit 0"),
    "prefix":      (False, "the pulses before the first marker reported too"),
    "threshold200": (False, "a pulse counted as a 1 only from 200 ms (1 bits of 170 to 199 ms read as 0)"),
    "threshold120": (False, "a pulse counted as a 1 from 120 ms (0 bits of 120 to 130 ms read as 1)"),
    "count59":     (False, "minutes found by counting 59 pulses after the first marker, not by the gap"),
    "dropword":    (False, "the last word not pushed"),
    "extraword":   (False, "one word too many, after the last"),
    "dupword":     (False, "one word pushed twice"),
    "swap":        (False, "two neighbouring words pushed in the wrong order"),
}


def edges(stimulus, cycles):
    """[(cycle, level)] of P0: the level at cycle 0, then each change."""
    out = []
    for line in stimulus:
        part = line.split()
        if len(part) != 2 or line.startswith("#"):
            continue
        c, level = int(part[0]), int(part[1], 16) & 1
        if c < cycles and (not out or out[-1][1] != level):
            out.append((c, level))
    return out


def receive(changes, fault):
    """[(cycle, word)] a correct receiver pushes, then the fault applied."""
    pulses = []                       # (rise, fall) of every whole pulse seen
    rise = None
    for c, level in changes[1:] if changes and changes[0][0] == 0 else changes:
        if level == 1:
            rise = c
        elif rise is not None:
            pulses.append((rise, c))
            rise = None
    one_from = {"threshold200": 200 * MS, "threshold120": 120 * MS}.get(fault, 150 * MS)
    out, synced, before, count = [], False, None, 0
    for r, f in pulses:
        gap = None if before is None else r - before
        first = gap is not None and gap > 1500 * MS
        if fault == "count59":
            if not synced and first:
                count = 0
            elif synced:
                count += 1
                first = count % 59 == 0
        synced = synced or first
        bit = int(f - r >= one_from)
        if synced or fault == "prefix":
            when = {"atrise": r, "deadline": r + 500 * MS}.get(fault, f + 1)
            out.append([when, bit | (2 if first else 0), r])
        before = r
    if not out:
        return []
    firsts = [k for k, w in enumerate(out) if w[1] & 2]
    if fault == "late501":
        out[len(out) // 2][0] = out[len(out) // 2][2] + 501 * MS
    if fault == "flipbit":
        out[-3][1] ^= 1
    if fault == "noflag" and firsts:
        out[firsts[-1]][1] &= ~2
    if fault == "flagmore" and firsts and firsts[-1] + 1 < len(out):
        out[firsts[-1] + 1][1] |= 2
    if fault == "dropword":
        out = out[:-1]
    if fault == "extraword":
        out.append([out[-1][0] + 1000 * MS, 0, None])
    if fault == "dupword":
        k = len(out) // 2
        out.insert(k + 1, [out[k][0] + 1, out[k][1], out[k][2]])
    if fault == "swap":
        k = next((k for k in range(len(out) - 1) if out[k][1] != out[k + 1][1]), None)
        if k is not None:
            out[k][1], out[k + 1][1] = out[k + 1][1], out[k][1]
    return [(c, w) for c, w, _ in out]


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if fault not in FAULTS or argv[:1] != ["run"] or "-stimulus" not in argv or "-cycles" not in argv:
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-stimulus") + 1]) as f:
        stimulus = f.read().splitlines()
    cycles = int(argv[argv.index("-cycles") + 1])
    lines = ["pins 0 ff"]
    lines += ["rx %d %d" % (c, w) for c, w in sorted(receive(edges(stimulus, cycles), fault),
                                                     key=lambda x: x[0]) if c < cycles]
    sys.stdout.write("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
