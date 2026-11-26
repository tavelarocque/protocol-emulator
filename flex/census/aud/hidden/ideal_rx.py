#!/usr/bin/env python3
"""A stand-in for `pe_sim run` that behaves like an ideal AUD receiver.
NOT chip firmware: it never reads the program. It reads the -stimulus file,
decodes AUD branch trace from it in its own code (written apart from the
judge's generator), and prints "pins 0 ff" and "rx CYCLE WORD" lines as the
real simulator would for a correct receiver, optionally with a named fault.

Usage: ideal_rx.py --fault NAME run PROGRAM.s -stimulus FILE -cycles N [...]"""
import sys

LATENCY = 5   # cycles after the last nibble's rising edge for the first word

# fault -> (must the judge pass it?, what it is)
FAULTS = {
    "none": (True, "ideal receiver, words 5 and 6 cycles after the last nibble's edge"),
    "at_limit": (True, "words 199 and 200 cycles after the last nibble's edge, the limit"),
    "next_edge": (True, "words pushed only at the next sync-high edge, as sigrok annotates"),
    "too_late": (False, "the high word 201 cycles after the last nibble's edge"),
    "too_early": (False, "words pushed 2 and 1 cycles before the last nibble's edge"),
    "bit_flip": (False, "one bit of one word flipped, in the middle address"),
    "swapped": (False, "high half pushed before low half"),
    "no_merge": (False, "short addresses not merged: the bits not sent read 0"),
    "nibble_msb": (False, "nibbles taken most significant first"),
    "drop_last": (False, "the last address is missing"),
    "extra": (False, "one extra word after the last address"),
    "dup": (False, "the first address pushed twice"),
    "data_msb": (False, "AUDATA pins read in the wrong order (AUDATA3 as bit 0)"),
}


def levels_at_rises(changes):
    """[(cycle, pins)] at every rising edge of P0."""
    out, prev = [], None
    for cycle, v in changes:
        ck = v & 1
        if prev == 0 and ck == 1:
            out.append((cycle, v))
        prev = ck
    return out


def decode(changes, fault):
    """[(cycle of the last nibble's edge, cycle of the next sync-high edge,
    32-bit address)]."""
    addr, res = 0, []
    want, got, value, start = 0, 0, 0, None
    for cycle, v in levels_at_rises(changes):
        sync = (v >> 1) & 1
        d = (v >> 2) & 0xF
        if fault == "data_msb":
            d = int("{:04b}".format(d)[::-1], 2)
        if sync:
            if want and got == want:
                res[-1] = (res[-1][0], cycle, res[-1][2])
            want = {0x8: 1, 0x9: 2, 0xA: 4, 0xB: 8}.get(d, 0)
            got, value = 0, 0
            continue
        if not want or got >= want:
            continue
        if fault == "nibble_msb":
            value |= d << (4 * (want - 1 - got))
        else:
            value |= d << (4 * got)
        got += 1
        if got == want:
            mask = (1 << (4 * want)) - 1
            base = 0 if fault == "no_merge" else addr & ~mask & 0xFFFFFFFF
            addr = base | value
            res.append((cycle, None, addr))
    return res


def main(argv):
    fault = argv[argv.index("--fault") + 1]
    stim = argv[argv.index("-stimulus") + 1]
    changes = []
    with open(stim) as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                c, v = line.split()
                changes.append((int(c), int(v, 16)))
    found = decode(changes, fault)
    if fault == "drop_last":
        found = found[:-1]
    if fault == "dup":
        found = found[:1] + found
    lines = []
    for n, (last, nxt, a) in enumerate(found):
        lo, hi = a & 0xFFFF, a >> 16
        t = last + LATENCY
        if fault == "at_limit":
            t = last + 199
        elif fault == "too_early":
            t = last - 2
        elif fault == "next_edge":
            t = nxt
        words = [lo, hi]
        if fault == "swapped":
            words = [hi, lo]
        if fault == "bit_flip" and n == len(found) // 2:
            words[0] ^= 0x0010
        t2 = t + 1
        if fault == "too_late" and n == len(found) - 1:
            t2 = last + 201
        lines += [(t, words[0]), (t2, words[1])]
    if fault == "extra":
        lines.append((lines[-1][0] + 1, 0x0000))
    print("pins 0 ff")
    for c, w in sorted(lines, key=lambda x: x[0]):
        print("rx %d %d" % (c, w))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
