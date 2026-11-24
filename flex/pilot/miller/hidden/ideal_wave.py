#!/usr/bin/env python3
"""An ideal Miller transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"). The
words it takes are the round-two task sheet's: one word per byte, bit 8 set
on the last byte of a message. It reads them back into messages in its own
way (messages_of below, written apart from accept.py's tx_words) and exits
with an error, which the judge counts as a failure, if the stream is not
what the sheet says: a bit above bit 8 set, or a last message left open.

It is written apart from accept.py on purpose, and works differently: it
walks the bits and toggles a level by the coding rule, where accept.py lists
the places transitions belong. If the two disagree, the self-test fails.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. A few names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

BIT = 100          # cycles a bit at 10 MHz and 100 kbit/s
LAST = 1 << 8      # task sheet: this bit is 1 on the last byte of a message

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: first start at cycle 1000, gaps of exactly 400 cycles"),
    "jitter2":     (True,  "every other transition 2 cycles late, the rest 2 early (the limit)"),
    "gap20000":    (True,  "gaps of exactly 20000 cycles (the limit)"),
    "start20000":  (True,  "first start bit at cycle 20000 (the limit)"),
    "flipbit":     (False, "one data bit of the last message inverted"),
    "msbfirst":    (False, "bytes sent most significant bit first"),
    "late3":       (False, "one transition 3 cycles late"),
    "early3":      (False, "one transition 3 cycles early"),
    "slow101":     (False, "bits of 101 cycles: the error adds up along a message"),
    "halfrate":    (False, "bits of 200 cycles (50 kbit/s)"),
    "gap399":      (False, "gaps of 399 cycles"),
    "gap150":      (False, "gaps of 150 cycles"),
    "gap20001":    (False, "gaps of 20001 cycles"),
    "start20001":  (False, "first start bit at cycle 20001"),
    "idlelow":     (False, "P0 driven low at cycle 1, before the first message"),
    "noend":       (False, "no end bit (shows only after a data bit of 0)"),
    "nostart":     (False, "no start bit: the first data bit begins the message"),
    "tail":        (False, "one more transition 5000 cycles after the last message"),
    "glitch":      (False, "a pulse one cycle long in the middle of the first message's gap or tail"),
    "dropmsg":     (False, "the last message is not sent"),
    "extramsg":    (False, "the last message is sent twice"),
}


def toggles(messages, fault="none"):
    """The cycles at which P0 changes level."""
    bit = {"slow101": 101, "halfrate": 200}.get(fault, BIT)
    gap = {"gap20000": 20000, "gap399": 399, "gap150": 150, "gap20001": 20001}.get(fault, 400)
    t = {"start20000": 20000, "start20001": 20001}.get(fault, 1000)
    messages = [list(m) for m in messages]
    if fault == "flipbit":
        messages[-1][-1] ^= 0x20
    if fault == "dropmsg":
        messages = messages[:-1]
    if fault == "extramsg":
        messages = messages + [messages[-1]]
    out = [1] if fault == "idlelow" else []
    for index, message in enumerate(messages):
        order = range(7, -1, -1) if fault == "msbfirst" else range(8)
        bits = [(byte >> k) & 1 for byte in message for k in order]
        bits = ([] if fault == "nostart" else [0]) + bits + ([] if fault == "noend" else [0])
        mine = []
        before = 0  # a message starts as if a 0 came before it
        for position, b in enumerate(bits):
            if position == 0 and b == 1:
                mine.append(t)  # only without a start bit: something must begin the message
            if b == 0 and before == 0:
                mine.append(t)               # 0 after 0: at the bit's start
            if b == 1:
                mine.append(t + bit // 2)    # 1: in the middle
            before = b
            t += bit
        middle = len(mine) // 2
        if fault == "late3" and index == 0:
            mine[middle] += 3
        if fault == "early3" and index == 0:
            mine[middle] -= 3
        if fault == "jitter2":
            mine = mine[:1] + [c + (2 if n % 2 else -2) for n, c in enumerate(mine[1:])]
        out += mine
        if fault == "glitch" and index == 0:
            out += [t + 200, t + 201]
        t += gap
    if fault == "tail":
        out.append(t + 5000)
    return out


def pins_text(messages, cycles, fault="none"):
    """What pe_sim would print: P0 high at cycle 0, then every change."""
    lines, level = ["pins 0 ff"], 1
    for c in toggles(messages, fault):
        level ^= 1
        if c < cycles:
            lines.append("pins %d %02x" % (c, 0xFE | level))
    return "\n".join(lines) + "\n"


def messages_of(words):
    """The messages a word stream asks for, by the task sheet's rules."""
    out, cur = [], []
    for w in words:
        if w >> 9:
            raise ValueError("word 0x%04x has a bit above bit 8 set" % w)
        cur.append(w % 256)
        if w & LAST:
            out.append(cur)
            cur = []
    if cur:
        raise ValueError("the last word does not end a message")
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
        messages = messages_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(messages, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
