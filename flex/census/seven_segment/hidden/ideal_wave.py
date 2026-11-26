#!/usr/bin/env python3
"""An ideal 7-segment display driver, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints the eight pins' changes in the simulator's format ("pins CYCLE
XX"). The words it takes are the task sheet's: bits 3..0 a digit, bit 4 the
decimal point, bit 5 blank, bit 6 the last word. It reads them back in its
own way (chars_of below, written apart from accept.py's tx_words) and exits
with an error, which the judge counts as a failure, if the stream is not
what the sheet says.

It is written apart from accept.py on purpose. It has its own segment table,
written from the task sheet's table of lit segments, and it draws the pins
level by level, where accept.py only knows where changes belong and leaves
the patterns to sigrok's decoder. If they disagree, the self-test fails.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. A few names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

SLOT = 1000
DP, BLANK, LAST = 0x10, 0x20, 0x40

# The task sheet's table: the lit segments of each hexadecimal digit.
LIT = ["abcdef", "bc", "abdeg", "abcdg", "bcfg", "acdfg", "acdefg", "abc",
       "abcdefg", "abcdfg", "abcefg", "cdefg", "adef", "bcdeg", "adefg", "aefg"]

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: first character at cycle 500"),
    "jitter2":     (True,  "every change after the first alternately 2 cycles late and 2 early (the limit)"),
    "start20000":  (True,  "first character at cycle 20000 (the limit)"),
    "flipbit":     (False, "one character of each run shows the digit with bit 0 flipped"),
    "seven_f":     (False, "7 drawn with segment f too (a common variant the decoder does not know)"),
    "activehigh":  (False, "common-cathode levels: lit segments high"),
    "nodp":        (False, "the decimal point is never lit"),
    "late3":       (False, "one change 3 cycles late"),
    "early3":      (False, "one change 3 cycles early"),
    "slot1001":    (False, "characters of 1001 cycles: the error adds up along a run"),
    "start20001":  (False, "first character at cycle 20001"),
    "dp_after":    (False, "P7 changes one cycle after P0..P6 at a change of character"),
    "two_halves":  (False, "P0..P3 change one cycle before P4..P7 at every change"),
    "repeatblink": (False, "a blank of one cycle between two equal characters"),
    "noblank":     (False, "the last character stays lit after its slot"),
    "early_on":    (False, "the pins show 8 from cycle 1, before the first character"),
    "dropchar":    (False, "the last character is not shown: the blank comes a slot early"),
    "extrachar":   (False, "the last character is shown for two slots"),
    "tail":        (False, "a stray change to 8 and back 3000 cycles after the blank"),
}


def pattern(digit, dp, blank, fault):
    """The eight pin levels of one character, P0..P6 = a..g, P7 = dp.
    Common-anode: a lit segment is a low pin."""
    lit = "" if blank else LIT[digit]
    if fault == "seven_f" and not blank and digit == 7:
        lit += "f"
    if dp and fault != "nodp":
        lit += "p"
    on = sum(1 << "abcdefgp".index(s) for s in lit)
    return on if fault == "activehigh" else 0xFF ^ on


def toggles(chars, fault="none"):
    """[(cycle, value)]: the pins' changes after cycle 0."""
    slot = 1001 if fault == "slot1001" else SLOT
    t0 = {"start20000": 20000, "start20001": 20001}.get(fault, 500)
    chars = list(chars)
    if fault == "flipbit":
        k = next((i for i, c in enumerate(chars) if not c[2]), None)
        if k is not None:
            digit, dp, blank = chars[k]
            chars[k] = (digit ^ 1, dp, blank)
    if fault == "dropchar":
        chars = chars[:-1]
    if fault == "extrachar":
        chars = chars + [chars[-1]]
    levels = [pattern(d, p, b, fault) for d, p, b in chars] + [0xFF]
    blank = 0xFF if fault != "activehigh" else 0x00
    levels[-1] = blank
    if fault == "noblank":
        levels[-1] = levels[-2]
    out = [(1, pattern(8, False, False, "none"))] if fault == "early_on" else []
    level = out[-1][1] if out else 0xFF
    for k, v in enumerate(levels):
        t = t0 + slot * k
        if fault == "repeatblink" and k and v == level:
            out += [(t, 0xFF), (t + 1, v)]
        if v == level:
            continue
        if fault == "dp_after" and (v ^ level) & 0x80 and (v ^ level) & 0x7F:
            out += [(t, (v & 0x7F) | (level & 0x80)), (t + 1, v)]
        elif fault == "two_halves" and (v ^ level) & 0x0F and (v ^ level) & 0xF0:
            out += [(t, (v & 0x0F) | (level & 0xF0)), (t + 1, v)]
        else:
            out.append((t, v))
        level = v
    if fault == "jitter2":
        out = out[:1] + [(c + (2 if n % 2 else -2), v) for n, (c, v) in enumerate(out[1:])]
    if fault in ("late3", "early3") and len(out) > 1:
        m = max(1, len(out) // 2)
        c, v = out[m]
        out[m] = (c + (3 if fault == "late3" else -3), v)
    if fault == "tail":
        t = out[-1][0] + 3000
        out += [(t, pattern(8, False, False, "none")), (t + 1, out[-1][1])]
    return out


def pins_text(chars, cycles, fault="none"):
    """What pe_sim would print: all pins high at cycle 0, then every change."""
    lines = ["pins 0 ff"]
    for c, v in toggles(chars, fault):
        if c < cycles:
            lines.append("pins %d %02x" % (c, v))
    return "\n".join(lines) + "\n"


def chars_of(words):
    """The characters a word stream asks for, by the task sheet's rules."""
    out = []
    for i, w in enumerate(words):
        if w >> 7:
            raise ValueError("word 0x%04x has a bit above bit 6 set" % w)
        if w & BLANK and w & 0x0F:
            raise ValueError("word 0x%04x is a blank with a digit" % w)
        if bool(w & LAST) != (i == len(words) - 1):
            raise ValueError("word %d has bit 6 wrong" % i)
        out.append((w & 0x0F, bool(w & DP), bool(w & BLANK)))
    if not out:
        raise ValueError("no words")
    if out[0][2] and not out[0][1]:
        raise ValueError("the run starts with a plain blank, which the sheet rules out")
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
        chars = chars_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(chars, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
