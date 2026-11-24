#!/usr/bin/env python3
"""An ideal S/PDIF transmitter waveform, as text in pe_sim's output format
("pins CYCLE XX", one line per change of the pins, P0 = bit 0).

This is NOT chip firmware. It is a plain Python model of the line, written
from the task sheet and on purpose without sharing any code with accept.py,
so that the judge can be validated: the judge must pass this waveform and
must fail each of the deliberately broken ones (the `fault` argument).

    waveform(pairs, cell, cycles, ...) -> str
"""
import math

BLOCK = 192
# Cell patterns for a line that was low before the preamble.
PREAMBLE = {"B": "11101000", "M": "11100010", "W": "11100100"}
CSTAT_ONES = (2, 24)  # frames of each block whose channel status bit is 1

GOOD = ("none", "setup", "closing", "jitter")
FAULTS = ("bit", "parity", "width", "width_pair", "gap", "noblock", "cstat0",
          "swap", "msb", "short", "extra", "wrongpre", "vbit", "late",
          "noquiet", "jitter_big", "aux_only", "inverted_mark")


def subframe_bits(sample, cbit, vbit=0, ubit=0, msb=False):
    """The 28 bits of time slots 4 to 31, in the order they are sent."""
    order = range(23, -1, -1) if msb else range(24)
    bits = [(sample >> k) & 1 for k in order] + [vbit, ubit, cbit]
    bits.append(sum(bits) & 1)  # even parity over slots 4..31
    return bits


def waveform(pairs, cell, cycles, start=5, variant="none", fault="none"):
    """pairs: [(left, right)] 24-bit samples. cell: cycles per cell.
    Returns the text pe_sim would print for a perfect transmitter that
    starts its first preamble at cycle `start`, with the
    named variant (still correct) or fault (not correct) applied."""
    assert variant in GOOD and fault in ("none",) + FAULTS
    subs = []  # (preamble letter, 28 bits)
    for f, (left, right) in enumerate(pairs):
        if fault == "swap":
            left, right = right, left
        c = 1 if (f % BLOCK) in CSTAT_ONES else 0
        if fault == "cstat0":
            c = 0
        first = "B" if f % BLOCK == 0 else "M"
        if fault == "noblock" and f != 0:
            first = "M"
        second = "W"
        if fault == "wrongpre":
            first, second = ("B" if first == "B" else "W"), "M"
        if fault == "aux_only":
            left, right = left & ~0xF, right & ~0xF
        subs.append((first, subframe_bits(left, c, msb=fault == "msb")))
        subs.append((second, subframe_bits(right, c, msb=fault == "msb")))
    victim = len(subs) // 2
    if fault == "bit":  # one audio bit wrong, parity still even
        p, bits = subs[victim]
        bits[9] ^= 1
        bits[27] ^= 1
    if fault == "parity":
        subs[victim][1][27] ^= 1
    if fault == "vbit":  # validity set on one subframe, parity still even
        subs[victim][1][24] ^= 1
        subs[victim][1][27] ^= 1
    if fault == "short":
        subs = subs[:-1]

    # Before the stream: the line sits at its reset level, 1, unless the
    # transmitter first drives it low and waits (a start-up edge).
    idle, setup_at = 1, None
    if fault == "late":
        start = 10_500
    if variant == "setup" or fault == "noquiet":
        idle, setup_at = 0, 3
        start = setup_at + (70 if variant == "setup" else 10) * cell

    # Cells: the level of the line in each cell, and each cell's length.
    level = idle
    cells = []
    for p, bits in subs:
        for ch in PREAMBLE[p]:
            cells.append(level ^ int(ch))
        level = cells[-1]
        for b in bits:
            if fault == "inverted_mark":  # biphase-space: mid-bit edge on a 0
                b ^= 1
            level ^= 1          # every bit starts with an edge
            cells.append(level)
            level ^= b          # a 1 has one more edge mid-bit
            cells.append(level)
    width = [cell] * len(cells)
    at = 64 * victim + 20
    over = 1 if cell < 20 else math.ceil(0.05 * cell) + 1
    if fault == "width":        # one cell too long; everything after is late
        width[at] += over
    if fault == "width_pair":   # one cell long, the next short: sum unchanged
        k = next(i for i in range(at, len(cells) - 1) if cells[i] != cells[i + 1])
        width[k] += over
        width[k + 1] -= over
    if variant == "jitter" or fault == "jitter_big":
        j = max(1, math.floor(0.05 * cell)) if variant == "jitter" else math.floor(0.05 * cell) + 1
        for i in range(3, len(cells) - 1, 7):   # moves one edge, sum unchanged
            if i % 64 != 63:
                width[i] += j
                width[i + 1] -= j
    if fault == "gap":          # the line idles for 8 cells between subframes
        width[64 * victim - 1] += 8 * cell

    out = [(0, 1)]  # the pins come out of reset high
    cur = 1

    def drive(t, v):
        nonlocal cur
        if v != cur:
            out.append((t, v))
            cur = v

    if setup_at is not None:
        drive(setup_at, 0)
    t = start
    for v, w in zip(cells, width):
        drive(t, v)
        t += w
    if variant == "closing":
        drive(t, cur ^ 1)
    if fault == "extra":
        drive(t + 5 * cell, cur ^ 1)
    return "".join("pins %d %02x\n" % (c, 0xFE | v) for c, v in out if c < cycles)


if __name__ == "__main__":
    import sys
    sys.stdout.write(waveform([(0x123456, 0xABCDEF), (0, 0xFFFFFF)], 8, 100_000,
                              fault=sys.argv[1] if len(sys.argv) > 1 else "none"))
