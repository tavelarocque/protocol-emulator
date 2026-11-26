#!/usr/bin/env python3
"""An ideal OOK (Manchester) transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"),
starting high at cycle 0 as a push-pull pin does after reset. The words it
takes are the task sheet's: one word per byte, bit 8 set on the last byte
of a frame. It reads them back into frames in its own way (frames_of below,
written apart from accept.py's tx_words) and exits with an error, which the
judge counts as a failure, if the stream is not what the sheet says: a bit
above bit 8 set, or a last frame left open.

It is written apart from accept.py on purpose, and works differently: it
walks the bits and places rises and falls by the coding rule (a 1 rises at
its start if the line is low and falls in its middle; a 0 falls at its
start if the line is high and rises in its middle), where accept.py lists
half-bit levels and finds where neighbours differ. If the two disagree, the
self-test fails.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. A few names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

BIT = 500          # cycles a bit at 1 MHz and 2000 bit/s
LAST = 1 << 8      # task sheet: this bit is 1 on the last byte of a frame

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: P0 low at cycle 1, first frame at cycle 8000, gaps of exactly 5000 cycles"),
    "jitter2":     (True,  "every other transition 2 cycles late, the rest 2 early (the limit)"),
    "gap20000":    (True,  "gaps of exactly 20000 cycles (the limit)"),
    "start5000":   (True,  "first frame at cycle 5000 (the earliest allowed)"),
    "start20000":  (True,  "first frame at cycle 20000 (the limit)"),
    "low100":      (True,  "P0 driven low at cycle 100 (the limit)"),
    "flipbit":     (False, "one data bit of the last frame inverted"),
    "lsbfirst":    (False, "bytes sent least significant bit first"),
    "ieee":        (False, "the other Manchester convention: a 1 is low then high"),
    "inverted":    (False, "the whole line inverted: idle high, carrier on when low"),
    "pre15":       (False, "a preamble of 15 bits, not 16"),
    "pre24":       (False, "a preamble of 24 bits, not 16"),
    "nosync":      (False, "no sync nibble"),
    "sync1010":    (False, "sync nibble 1, 0, 1, 0"),
    "late3":       (False, "one transition 3 cycles late"),
    "early3":      (False, "one transition 3 cycles early"),
    "slow501":     (False, "bits of 501 cycles: the error adds up along a frame"),
    "fast400":     (False, "bits of 400 cycles (2500 bit/s)"),
    "gap4999":     (False, "gaps of 4999 cycles"),
    "gap1500":     (False, "gaps of 1500 cycles"),
    "gap20001":    (False, "gaps of 20001 cycles"),
    "start4999":   (False, "first frame at cycle 4999"),
    "start20001":  (False, "first frame at cycle 20001"),
    "low101":      (False, "P0 driven low at cycle 101"),
    "neverlow":    (False, "P0 left high from reset until 250 cycles before the first frame"),
    "nofall":      (False, "a frame ending in a 0 leaves the line high (no fall at its end)"),
    "latefall":    (False, "a frame ending in a 0 falls 3 cycles after the end of its last bit"),
    "tail":        (False, "a 1-cycle pulse 5000 cycles after the last frame"),
    "glitch":      (False, "a pulse one cycle long in the first frame's gap or tail"),
    "dropmsg":     (False, "the last frame is not sent"),
    "extramsg":    (False, "the last frame is sent twice"),
}


def toggles(frames, fault="none"):
    """The cycles at which P0 changes level, the reset fall included."""
    bit = {"slow501": 501, "fast400": 400}.get(fault, BIT)
    half = bit // 2
    gap = {"gap20000": 20000, "gap4999": 4999, "gap1500": 1500, "gap20001": 20001}.get(fault, 5000)
    t = {"start5000": 5000, "start20000": 20000, "start4999": 4999,
         "start20001": 20001}.get(fault, 8000)
    frames = [list(f) for f in frames]
    if fault == "flipbit":
        frames[-1][-1] ^= 0x04
    if fault == "dropmsg":
        frames = frames[:-1]
    if fault == "extramsg":
        frames = frames + [frames[-1]]
    low_at = {"low100": 100, "low101": 101, "neverlow": t - 250}.get(fault, 1)
    out = [low_at]
    preamble = {"pre15": 15, "pre24": 24}.get(fault, 16)
    sync = {"nosync": [], "sync1010": [1, 0, 1, 0]}.get(fault, [0, 1, 0, 1])
    marked = False
    for index, frame in enumerate(frames):
        order = range(8) if fault == "lsbfirst" else range(7, -1, -1)
        bits = [1] * preamble + sync + [(byte >> k) & 1 for byte in frame for k in order]
        if fault == "ieee":
            bits = [1 - b for b in bits]   # same levels as a 1 sent low-high
        mine, high = [], False
        for b in bits:
            if b == 1:
                if not high:
                    mine.append(t)            # rise at the start
                mine.append(t + half)         # fall in the middle
                high = False
            else:
                if high:
                    mine.append(t)            # fall at the start
                mine.append(t + half)         # rise in the middle
                high = True
            t += bit
        if high:
            if fault == "nofall" and not marked:
                marked = True
            elif fault == "latefall" and not marked:
                marked = True
                mine.append(t + 3)
            else:
                mine.append(t)                # back to low at the end
        middle = len(mine) // 2
        if fault == "late3" and index == 0:
            mine[middle] += 3
        if fault == "early3" and index == 0:
            mine[middle] -= 3
        if fault == "jitter2":
            mine = mine[:1] + [c + (2 if n % 2 else -2) for n, c in enumerate(mine[1:])]
        out += mine
        if fault == "glitch" and index == 0:
            out += [t + 2000, t + 2001]
        t += gap
    if fault == "tail":
        out += [t, t + 1]
    return out


def pins_text(frames, cycles, fault="none"):
    """What pe_sim would print: P0 high at cycle 0, then every change."""
    level = 1
    if fault == "inverted":
        lines = ["pins 0 ff"]
        # idle high: never the reset fall; the frames' levels inverted
        level = 1
        for c in toggles(frames)[1:]:
            level ^= 1
            if c < cycles:
                lines.append("pins %d %02x" % (c, 0xFE | level))
        return "\n".join(lines) + "\n"
    lines = ["pins 0 ff"]
    for c in toggles(frames, fault):
        level ^= 1
        if c < cycles:
            lines.append("pins %d %02x" % (c, 0xFE | level))
    return "\n".join(lines) + "\n"


def frames_of(words):
    """The frames a word stream asks for, by the task sheet's rules."""
    out, cur = [], []
    for w in words:
        if w >> 9:
            raise ValueError("word 0x%04x has a bit above bit 8 set" % w)
        cur.append(w % 256)
        if w & LAST:
            out.append(cur)
            cur = []
    if cur:
        raise ValueError("the last word does not end a frame")
    if not out:
        raise ValueError("no words")
    return out


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if fault not in FAULTS or argv[:1] != ["run"] or "-tx" not in argv or "-cycles" not in argv:
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(line, 0) for line in f if line.strip()]
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        frames = frames_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(frames, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
