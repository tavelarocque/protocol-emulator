#!/usr/bin/env python3
"""An ideal PT2262 encoder, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"), starting
with "pins 0 ff" as the real chip does (its output register resets high).
The words it takes are the task sheet's: two words per code word, each
holding six trits two bits apiece (0 = '0', 1 = '1', 2 = 'f'), first-sent
trit in bits 1..0, bits 15..12 zero. It reads them back into code words in
its own way (codes_of below, written apart from accept.py's tx_words) and
exits with an error, which the judge counts as a failure, if the stream is
not what the sheet says: an odd number of words, a trit code of 3, or a bit
above bit 11 set.

It is written apart from accept.py on purpose, and works differently: it
walks the pulses (a high then a low, short or long) and accumulates time,
where accept.py lists the place every edge belongs.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. A few names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

A = 400            # cycles in one alpha (40 us at 10 MHz)

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: fall at cycle 1, first frame at cycle 60000"),
    "jitter2":     (True,  "every edge after a frame's first 2 cycles off, alternately late and early (the limit)"),
    "fall100":     (True,  "first fall at cycle 100 (the limit)"),
    "start50000":  (True,  "first frame at cycle 50000 (the earliest allowed)"),
    "start100000": (True,  "first frame at cycle 100000 (the latest allowed)"),
    "fall101":     (False, "first fall at cycle 101"),
    "start49999":  (False, "first frame at cycle 49999"),
    "start100001": (False, "first frame at cycle 100001"),
    "nofall":      (False, "P0 never driven low first: frames sent with the line idling high (inverted)"),
    "flipf":       (False, "one trit of the last code word sent as f instead of 0"),
    "fasl":        (False, "trit 1 sent as f and f as 1 everywhere"),
    "reverse":     (False, "the twelve trits of every code word sent in reverse order"),
    "late3":       (False, "one edge of the first frame 3 cycles late"),
    "early3":      (False, "one edge of the first frame 3 cycles early"),
    "alpha401":    (False, "alpha of 401 cycles: the error adds up along a frame"),
    "alpha399":    (False, "alpha of 399 cycles"),
    "short3":      (False, "short highs of 3 alpha (lows of 13), long highs of 12 (the decoder still reads it)"),
    "long10":      (False, "long highs of 10 alpha (lows of 6), short highs of 4 (the decoder still reads it)"),
    "synclong":    (False, "sync low part one alpha too long (next frame late)"),
    "syncshort":   (False, "sync low part one alpha too short (next frame early)"),
    "synchigh8":   (False, "sync high part of 8 alpha instead of 4"),
    "nosync":      (False, "no sync bit between frames (frames run together)"),
    "dropframe":   (False, "the last code word is not sent"),
    "extraframe":  (False, "the last code word is sent twice"),
    "tail":        (False, "one more rise 3000 cycles after the last frame's end, and stays high"),
    "glitch":      (False, "a pulse one cycle long in the low part of the first sync bit"),
}

PULSES = {"0": ("S", "S"), "1": ("L", "L"), "f": ("S", "L")}


def toggles(codes, fault="none"):
    """The cycles at which P0 changes level, after the "pins 0 ff" start."""
    a = {"alpha401": 401, "alpha399": 399}.get(fault, A)
    short_hi = 3 * a if fault == "short3" else 4 * a
    long_hi = 10 * a if fault == "long10" else 12 * a
    hi = {"S": short_hi, "L": long_hi}
    lo = {p: 16 * a - hi[p] for p in hi}   # a pulse cycle is 16 alpha
    sync_hi = 8 * a if fault == "synchigh8" else 4 * a
    sync_lo = {"synclong": 125 * a, "syncshort": 123 * a}.get(fault, 124 * a)
    if fault == "synchigh8":
        sync_lo = 128 * a - sync_hi
    codes = [list(c) for c in codes]
    if fault == "flipf":
        last = codes[-1]
        i = next((i for i, t in enumerate(last) if t == "0"), None)
        if i is None:
            last[0] = "0"
        else:
            last[i] = "f"
    if fault == "fasl":
        codes = [[{"1": "f", "f": "1"}.get(t, t) for t in c] for c in codes]
    if fault == "reverse":
        codes = [c[::-1] for c in codes]
    if fault == "dropframe":
        codes = codes[:-1]
    if fault == "extraframe":
        codes = codes + [codes[-1]]
    fall = 100 if fault == "fall100" else 101 if fault == "fall101" else 1
    t = {"start50000": 50000, "start100000": 100000,
         "start49999": 49999, "start100001": 100001}.get(fault, 60000)
    out = [] if fault == "nofall" else [fall]
    for index, code in enumerate(codes):
        mine = []
        for trit in code:
            for p in PULSES[trit]:
                mine.append(t)           # rise
                t += hi[p]
                mine.append(t)           # fall
                t += lo[p]
        if fault != "nosync":
            mine.append(t)
            t += sync_hi
            mine.append(t)
            t += sync_lo
            if fault == "glitch" and index == 0:
                mine += [t - 50 * a, t - 50 * a + 1]
        if fault == "late3" and index == 0:
            mine[17] += 3
        if fault == "early3" and index == 0:
            mine[17] -= 3
        if fault == "jitter2":
            mine = mine[:1] + [c + (2 if n % 2 else -2) for n, c in enumerate(mine[1:])]
        out += sorted(mine)
    if fault == "tail":
        out.append(t + 3000)
    return out


def pins_text(codes, cycles, fault="none"):
    """What pe_sim would print: P0 high at cycle 0, then every change."""
    lines, level = ["pins 0 ff"], 1
    for c in toggles(codes, fault):
        level ^= 1
        if c < cycles:
            lines.append("pins %d %02x" % (c, 0xFE | level))
    return "\n".join(lines) + "\n"


def codes_of(words):
    """The code words a word stream asks for, by the task sheet's rules."""
    if not words or len(words) % 2:
        raise ValueError("%d words: code words take two each" % len(words))
    out = []
    for first, second in zip(words[0::2], words[1::2]):
        trits = ""
        for w in (first, second):
            if w >> 12:
                raise ValueError("word 0x%04x has a bit above bit 11 set" % w)
            for k in range(6):
                v = (w >> (2 * k)) & 3
                if v == 3:
                    raise ValueError("word 0x%04x holds the trit code 3" % w)
                trits += "01f"[v]
        out.append(trits)
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
        codes = codes_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(codes, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
