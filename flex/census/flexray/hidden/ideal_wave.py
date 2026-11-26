#!/usr/bin/env python3
"""An ideal FlexRay transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"). It
reads the TX words back into frames by the task sheet's rules (frames_of
below, written apart from accept.py's tx_words) and exits with an error,
which the judge counts as a failure, if the stream is not what the sheet
says: a stray bit set in a header word, or a frame cut short.

It works differently from accept.py on purpose: its CRCs run least
significant bit first on reflected polynomials (the form of the chip's CRC
register), and it emits levels bit by bit, where accept.py lists the
places edges belong. If the two disagree, the self-test fails.

--fault breaks the waveform in one named way (FAULTS below). A few names
are not faults but waveforms at the very edge of what the task sheet
allows, which must still pass."""
import sys

BIT = 5  # cycles a bit at 50 MHz and 10 Mbit/s

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":       (True,  "ideal: TSS of 5 bits, first TSS at cycle 500, CID plus 1 bit between frames"),
    "tss3":       (True,  "TSS of 3 bits (15 cycles), the shortest"),
    "tss15":      (True,  "TSS of 15 bits (75 cycles), the longest"),
    "jitter1":    (True,  "every edge after the FSS edge 1 cycle late or early, alternately (the limit)"),
    "gapmin":     (True,  "next TSS exactly 60 cycles after the FES edge (the shortest)"),
    "gapmax":     (True,  "next TSS exactly 10000 cycles after the FES edge (the longest)"),
    "start10000": (True,  "first TSS at cycle 10000 (the limit)"),
    "flipbit":    (False, "one payload bit of the last frame inverted (CRC computed on the wrong data)"),
    "flipcrc":    (False, "one frame CRC bit of the last frame inverted"),
    "badhcrc":    (False, "header CRC sent as 0"),
    "chanb":      (False, "frame CRC with channel B's initial value"),
    "lsbfirst":   (False, "payload bytes sent least significant bit first"),
    "swapbytes":  (False, "the two bytes of every payload word swapped"),
    "late2":      (False, "one edge in the middle of the first frame 2 cycles late"),
    "early2":     (False, "one edge in the middle of the first frame 2 cycles early"),
    "slow6":      (False, "bits of 6 cycles"),
    "tss2":       (False, "TSS of 2 bits"),
    "tss16":      (False, "TSS of 16 bits"),
    "nobss":      (False, "the BSS before the frame CRC's first byte left out"),
    "bss11":      (False, "a BSS sent as 1 1"),
    "nofes":      (False, "no FES: the line rises after the CRC"),
    "fes11":      (False, "FES low for two bits"),
    "dts":        (False, "a dynamic trailing sequence after the FES"),
    "gap59":      (False, "next TSS 59 cycles after the FES edge"),
    "gap10001":   (False, "next TSS 10001 cycles after the FES edge"),
    "start10001": (False, "first TSS at cycle 10001"),
    "idlelow":    (False, "P0 low at cycle 0"),
    "tail":       (False, "a one-cycle low pulse 3000 cycles after the last frame"),
    "dropframe":  (False, "the last frame is not sent"),
    "extraframe": (False, "the last frame is sent twice"),
    "cycleoff":   (False, "cycle count sent one higher (header CRC still right)"),
}


def reflect(value, width):
    return int(format(value, "0%db" % width)[::-1], 2)


def crc_lsb(bits, poly, init, width):
    """The chip's style: register reflected, shift right, polynomial added
    when the incoming bit differs from bit 0."""
    rpoly, reg = reflect(poly, width), reflect(init, width)
    for b in bits:
        if (reg & 1) != b:
            reg = (reg >> 1) ^ rpoly
        else:
            reg >>= 1
    return reflect(reg, width)


def msb(value, width):
    return [int(c) for c in format(value, "0%db" % width)]


def frames_of(words):
    """The frames a word stream asks for, by the task sheet's rules."""
    out, i = [], 0
    while i < len(words):
        if i + 4 > len(words):
            raise ValueError("a frame's header is cut short")
        w0, length, hcrc, cycle = words[i:i + 4]
        if w0 & 0x8000 or length >> 7 or hcrc >> 11 or cycle >> 6:
            raise ValueError("a header word has a bit set outside its field")
        if not w0 & 0x7FF:
            raise ValueError("frame ID 0")
        body = words[i + 4:i + 4 + length]
        if len(body) != length:
            raise ValueError("a frame's payload is cut short")
        payload = []
        for w in body:
            payload += [w >> 8, w & 0xFF]
        out.append(dict(ppi=(w0 >> 14) & 1, nf=(w0 >> 13) & 1, sync=(w0 >> 12) & 1,
                        startup=(w0 >> 11) & 1, fid=w0 & 0x7FF, length=length,
                        hcrc=hcrc, cycle=cycle, payload=payload))
        i += 4 + length
    if not out:
        raise ValueError("no words")
    return out


def frame_levels(fr, fault, last):
    """P0's level for every bit after the TSS, FSS first."""
    hcrc = 0 if fault == "badhcrc" else fr["hcrc"]
    cycle = (fr["cycle"] + 1) % 64 if fault == "cycleoff" else fr["cycle"]
    header = ([0, fr["ppi"], fr["nf"], fr["sync"], fr["startup"]] + msb(fr["fid"], 11)
              + msb(fr["length"], 7) + msb(hcrc, 11) + msb(cycle, 6))
    payload = list(fr["payload"])
    if fault == "swapbytes":
        for i in range(0, len(payload), 2):
            payload[i], payload[i + 1] = payload[i + 1], payload[i]
    pbits = []
    for byte in payload:
        b = msb(byte, 8)
        pbits += b[::-1] if fault == "lsbfirst" else b
    if fault == "flipbit" and last and pbits:
        pbits[len(pbits) // 2] ^= 1
    init = 0xABCDEF if fault == "chanb" else 0xFEDCBA
    crc = crc_lsb(header + pbits, 0x5D6DCB, init, 24)
    if fault == "flipcrc" and last:
        crc ^= 1 << 7
    cbits = msb(crc, 24)
    stream = header + pbits + cbits
    out = [1]  # FSS
    nbytes = len(stream) // 8
    for k in range(nbytes):
        if fault == "nobss" and k == nbytes - 3:
            pass
        elif fault == "bss11" and k == 2:
            out += [1, 1]
        else:
            out += [1, 0]
        out += stream[8 * k:8 * k + 8]
    if fault == "nofes":
        out += [1]
    elif fault == "fes11":
        out += [0, 0, 1]
    elif fault == "dts":
        out += [0, 1, 0, 1]
    else:
        out += [0, 1]
    return out


def changes(frames, fault="none"):
    """[(cycle, level)] for P0 after cycle 0."""
    bit = 6 if fault == "slow6" else BIT
    tss = {"tss3": 3, "tss15": 15, "tss2": 2, "tss16": 16}.get(fault, 5) * bit
    gap = {"gapmin": 60, "gapmax": 10000, "gap59": 59, "gap10001": 10001}.get(fault, 65)
    t = {"start10000": 10000, "start10001": 10001}.get(fault, 500)
    if fault == "dropframe":
        frames = frames[:-1]
    if fault == "extraframe":
        frames = frames + [frames[-1]]
    out = []
    for index, fr in enumerate(frames):
        mine = [(t, 0)]
        t += tss
        level = 0
        for n, b in enumerate(frame_levels(fr, fault, index == len(frames) - 1)):
            if b != level:
                mine.append((t + n * bit, b))
                level = b
        if fault == "jitter1":
            mine = mine[:2] + [(c + (1 if i % 2 else -1), v) for i, (c, v) in enumerate(mine[2:])]
        if index == 0 and fault in ("late2", "early2"):
            m = len(mine) // 2
            mine[m] = (mine[m][0] + (2 if fault == "late2" else -2), mine[m][1])
        out += mine
        t = mine[-1][0] + gap
    if fault == "tail":
        out += [(out[-1][0] + 3000, 0), (out[-1][0] + 3001, 1)]
    return out


def pins_text(frames, cycles, fault="none"):
    lines = ["pins 0 %02x" % (0xFE if fault == "idlelow" else 0xFF)]
    for c, level in changes(frames, fault):
        if c < cycles:
            lines.append("pins %d %02x" % (c, 0xFE | level))
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
