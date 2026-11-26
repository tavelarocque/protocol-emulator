#!/usr/bin/env python3
"""An ideal Maple bus host transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints the lines' changes in the simulator's format ("pins CYCLE XX",
SDCKA on P0, SDCKB on P1, the other pins high). It reads the task sheet's
words back into frames in its own way (frames_of below, written apart from
accept.py's tx_words), and exits with an error, which the judge counts as a
failure, if the words do not make whole frames.

It is written apart from accept.py on purpose and works differently. It
walks the host's phases, as a real host does: every phase drives one line
to a level, a phase that finds the line already there changes nothing but
still takes its time, and a line that changed in the phase before waits one
more phase. accept.py instead lists the changes and checks their spacing.
If the two disagree, the self-test fails.

--fault breaks the waveform in one named way (FAULTS below). A few names
are not faults but waveforms at the very edge of what the task sheet allows,
which must still pass."""
import sys

PHASE = 8          # cycles a phase: 160 ns at 50 MHz, the Dreamcast's own pace

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":          (True,  "ideal: phases of 8 cycles, first frame at 1000, idle of 400"),
    "tightest":      (True,  "every change at the earliest the rules allow (7 and 12 cycles)"),
    "slowest":       (True,  "every change inside a frame exactly 100 cycles after the one before"),
    "gap100":        (True,  "idle of exactly 100 cycles between frames"),
    "late50000":     (True,  "first frame at cycle 50000 and idle of exactly 50000 (the limits)"),
    "flipbit":       (False, "one data bit inverted, the checksum left as it was"),
    "badsum":        (False, "checksum is the sum of the bytes, not their XOR"),
    "nosum":         (False, "no checksum byte"),
    "lsbfirst":      (False, "bits sent least significant first"),
    "swapbytes":     (False, "the two bytes of each TX word sent in the other order"),
    "shortframe":    (False, "the last data word left out, the size byte unchanged"),
    "start3":        (False, "start pattern with 3 pulses on SDCKB"),
    "start6":        (False, "start pattern with 6 pulses (the start-with-CRC pattern)"),
    "shortend":      (False, "end pattern without SDCKB's rise and fall (the decoder accepts it)"),
    "dataearly":     (False, "data set before the clock line rises (the decoder accepts it)"),
    "cross6":        (False, "one change 6 cycles after a change on the other line"),
    "same11":        (False, "two changes of SDCKB in the start pattern 11 cycles apart"),
    "samecycle":     (False, "one change in the same cycle as the change before it, on the other line"),
    "slow101":       (False, "one wait of 101 cycles between changes inside a frame"),
    "gap99":         (False, "idle of 99 cycles between frames"),
    "gap50001":      (False, "idle of 50001 cycles between frames"),
    "start50001":    (False, "first frame at cycle 50001"),
    "idlelow":       (False, "SDCKB low at cycle 0, up at cycle 10"),
    "leftlow":       (False, "SDCKB left low after the last frame (no final rise)"),
    "tail":          (False, "one more SDCKA pulse 5000 cycles after the last frame"),
    "dropframe":     (False, "the last frame is not sent"),
    "extraframe":    (False, "the last frame is sent twice"),
}


def frames_of(words):
    """The frames a word stream asks for, by the task sheet's rules."""
    out, i = [], 0
    while i < len(words):
        if i + 2 > len(words):
            raise ValueError("a frame header is cut short")
        n, src = divmod(words[i], 256)
        dst, cmd = divmod(words[i + 1], 256)
        body = words[i + 2:i + 2 + 2 * n]
        if len(body) != 2 * n or n > 255:
            raise ValueError("frame %d wants %d data words, the stream ends first" % (len(out), n))
        data = []
        for w in body:
            data += [w >> 8, w & 0xFF]
        out.append([n, src, dst, cmd] + data)
        i += 2 + 2 * n
    if not out or any(w >> 16 for w in words):
        raise ValueError("no frames, or a word wider than 16 bits")
    return out


def phases(raw, fault):
    """The host's phases for one frame: (line, level) pairs, 'A' or 'B'."""
    raw = list(raw)
    if fault == "swapbytes":
        for i in range(0, len(raw) - 1, 2):
            raw[i], raw[i + 1] = raw[i + 1], raw[i]
    if fault == "shortframe" and len(raw) > 4:
        raw = raw[:-4]
    total = 0
    for b in raw:
        total ^= b
    if fault == "badsum":
        total = sum(raw) & 0xFF
    if fault == "flipbit":
        raw[-1] ^= 0x08
    wire = raw + ([] if fault == "nosum" else [total])
    pulses = {"start3": 3, "start6": 6}.get(fault, 4)
    ph = [("A", 0)] + [("B", 0), ("B", 1)] * pulses + [("A", 1)]
    clocks = "AB"
    for n, bit in enumerate(b >> k & 1 for b in wire
                            for k in (range(8) if fault == "lsbfirst" else range(7, -1, -1))):
        clk = clocks[n % 2]
        dat = clocks[1 - n % 2]
        if fault == "dataearly":
            ph += [(dat, bit), (clk, 1), (clk, 0)]
        else:
            ph += [(clk, 1), (dat, bit), (clk, 0)]
    if fault == "shortend":
        ph += [("A", 1), ("A", 0), ("A", 1), ("A", 0), ("A", 1), ("B", 1)]
    else:
        ph += [("A", 1), ("B", 1), ("B", 0), ("A", 0), ("A", 1), ("A", 0), ("A", 1), ("B", 1)]
    return ph


def changes(frames, fault="none"):
    """[(cycle, line, level)] of the whole run."""
    if fault == "dropframe":
        frames = frames[:-1]
    if fault == "extraframe":
        frames = frames + frames[-1:]
    t = {"late50000": 50000, "start50001": 50001}.get(fault, 1000)
    gap = {"gap100": 100, "late50000": 50000, "gap99": 99, "gap50001": 50001}.get(fault, 400)
    level = {"A": 1, "B": 1}
    out = []
    marked = False
    for f in frames:
        ph = phases(f, fault)
        if fault == "leftlow" and f is frames[-1]:
            ph = ph[:-1]
        last_line, last_t, last_same = None, None, {"A": None, "B": None}
        for line, v in ph:
            if level[line] == v:
                if fault not in ("tightest", "slowest"):
                    t += PHASE              # an idle phase still takes its time
                continue
            if last_t is None:
                pass                        # the frame's first change: t is set by the idle
            elif fault == "tightest":
                t = max(last_t + (7 if line != last_line else 0),
                        (last_same[line] or 0) + 12)
            elif fault == "slowest":
                t = last_t + 100
            else:
                t += PHASE
                if line == last_line:
                    t += PHASE              # a line never changes in two phases running
            if fault == "cross6" and not marked and last_line not in (None, line):
                t, marked = last_t + 6, True
            if fault == "same11" and not marked and line == "B" and last_same["B"] is not None:
                t, marked = last_same["B"] + 11, True
            if fault == "samecycle" and not marked and len(out) > 30 and last_line not in (None, line):
                t, marked = last_t, True
            if fault == "slow101" and not marked and len(out) > 30 and last_t is not None:
                t, marked = last_t + 101, True
            level[line] = v
            out.append((t, line, v))
            last_line, last_t = line, t
            last_same[line] = t
        t += gap
    if fault == "tail":
        out += [(t + 5000, "A", 0), (t + 5100, "A", 1)]
    return out


def pins_text(frames, cycles, fault="none"):
    """What pe_sim would print: both lines high at cycle 0, then every change."""
    a, b = 1, 1
    lines = ["pins 0 ff"]
    events = changes(frames, fault)
    if fault == "idlelow":
        lines = ["pins 0 fd", "pins 10 ff"]
    for c, line, v in events:
        if c >= cycles:
            break
        if line == "A":
            a = v
        else:
            b = v
        text = "pins %d %02x" % (c, 0xFC | b << 1 | a)
        if lines and lines[-1].split()[1] == str(c):
            lines[-1] = text            # two changes in one cycle: one line, as pe_sim prints
        else:
            lines.append(text)
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
        frames = frames_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(frames, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
