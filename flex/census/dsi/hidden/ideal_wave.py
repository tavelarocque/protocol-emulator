#!/usr/bin/env python3
"""An ideal DSI transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"), with
P0 high at cycle 0 as the real chip's output register is at reset. The
words it takes are the task sheet's: one word per frame, the level in bits
7..0. It reads them back in its own way (levels_of below) and exits with an
error, which the judge counts as a failure, if a word has a bit above bit 7
set.

It is written apart from accept.py on purpose, and works differently: it
keeps a running time in exact thirds of a cycle and emits the line's level
half-bit by half-bit, where accept.py lists the places changes belong.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. Some names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

THIRDS_HALF = 25000          # a half-bit is 25000/3 cycles: count in thirds
FRAME_THIRDS = 21 * THIRDS_HALF  # 175000 cycles

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: low at cycle 20, first rise at 60000, rests of 100000"),
    "jitter80":    (True,  "every change after a frame's rise 80 cycles off, alternately late and early (the limit)"),
    "whole8333":   (True,  "half-bits of a whole 8333 cycles: 5.7 cycles short by the end"),
    "lowat1000":   (True,  "P0 driven low at cycle 1000 (the limit)"),
    "start50000":  (True,  "first rise at cycle 50000 (the limit)"),
    "start200000": (True,  "first rise at cycle 200000 (the limit)"),
    "rest50000":   (True,  "rests of exactly 50000 cycles after the stop bits (the limit)"),
    "rest200000":  (True,  "rests of exactly 200000 cycles (the limit)"),
    "flipbit":     (False, "one data bit (D2) of the last frame inverted"),
    "lsbfirst":    (False, "bits sent D0 first"),
    "invcode":     (False, "Manchester the other way: 1 as low-high, 0 as high-low"),
    "late81":      (False, "one change 81 cycles late"),
    "early81":     (False, "one change 81 cycles early"),
    "slow8400":    (False, "half-bits of 8400 cycles: the error adds up along a frame"),
    "double":      (False, "half-bits of 4167 cycles (2400 a second)"),
    "rest49999":   (False, "rests of 49999 cycles"),
    "rest200001":  (False, "rests of 200001 cycles"),
    "start49999":  (False, "first rise at cycle 49999"),
    "start200001": (False, "first rise at cycle 200001"),
    "lowat1001":   (False, "P0 driven low at cycle 1001"),
    "neverlow":    (False, "P0 left high until the first frame, which then begins with its data"),
    "idlehigh":    (False, "the whole line inverted: idles high"),
    "nostart":     (False, "no start bit: D7 begins at the rise"),
    "longstart":   (False, "the start bit two half-bits long"),
    "tail":        (False, "a 1 ms high pulse 15 ms after the last frame's stop bits"),
    "glitch":      (False, "a pulse one cycle long in the first rest"),
    "dropframe":   (False, "the last frame is not sent"),
    "extraframe":  (False, "the last frame is sent twice"),
}


def levels_of(words):
    """The frames a word stream asks for, by the task sheet's rules."""
    if not words:
        raise ValueError("no words")
    for w in words:
        if w >> 8:
            raise ValueError("word 0x%04x has a bit above bit 7 set" % w)
    return list(words)


def edges(levels, fault="none"):
    """[(cycle, level)] of P0 after cycle 0, at which it is high."""
    half3 = {"whole8333": 3 * 8333, "slow8400": 3 * 8400, "double": 3 * 4167}.get(fault, THIRDS_HALF)
    rest = {"rest50000": 50000, "rest200000": 200000, "rest49999": 49999,
            "rest200001": 200001}.get(fault, 100000)
    start = {"start50000": 50000, "start200000": 200000, "start49999": 49999,
             "start200001": 200001}.get(fault, 60000)
    low_at = {"lowat1000": 1000, "lowat1001": 1001}.get(fault, 20)
    levels = list(levels)
    if fault == "flipbit":
        levels[-1] ^= 0x04
    if fault == "dropframe":
        levels = levels[:-1]
    if fault == "extraframe":
        levels = levels + [levels[-1]]
    out = [] if fault == "neverlow" else [(low_at, 0)]
    line = 0 if fault != "neverlow" else 1
    t0 = start
    for index, level in enumerate(levels):
        order = range(8) if fault == "lsbfirst" else range(7, -1, -1)
        halves = [] if fault == "nostart" else ([1, 1] if fault == "longstart" else [1])
        for k in order:
            one = (level >> k) & 1
            if fault == "invcode":
                one ^= 1
            halves += [1, 0] if one else [0, 1]
        halves += [0, 0, 0, 0]
        mine = []
        for n, h in enumerate(halves):
            if h != line:
                mine.append([t0 + (n * half3 + 1) // 3, h])   # nearest cycle
                line = h
        if fault == "neverlow" and index == 0:
            mine = mine[1:] if mine and mine[0][1] == 1 else mine
        if fault == "jitter80":
            for n, e in enumerate(mine[1:]):
                e[0] += 80 if n % 2 else -80
        if index == 0 and fault in ("late81", "early81"):
            mine[len(mine) // 2][0] += 81 if fault == "late81" else -81
        out += [tuple(e) for e in mine]
        end = t0 + (len(halves) * half3 + 1) // 3 if fault in ("nostart", "longstart") \
            else t0 + (FRAME_THIRDS * half3 // THIRDS_HALF + 1) // 3
        if fault == "glitch" and index == 0:
            out += [(end + 20000, 1), (end + 20001, 0)]
        t0 = end + rest
    if fault == "tail":
        out += [(t0 - rest + 15000 * 10, 1), (t0 - rest + 16000 * 10, 0)]
    if fault == "idlehigh":
        out = [(c, 1 - l) for c, l in out]
    return out


def pins_text(levels, cycles, fault="none"):
    """What pe_sim would print: P0 high at cycle 0, then every change."""
    lines = ["pins 0 ff"]
    for c, l in edges(levels, fault):
        if c < cycles:
            lines.append("pins %d %02x" % (c, 0xFE | l))
    return "\n".join(lines) + "\n"


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
        levels = levels_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(levels, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
