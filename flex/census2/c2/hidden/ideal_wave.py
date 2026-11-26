#!/usr/bin/env python3
"""An ideal C2 master, as a waveform and a list of rx words: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints, in the simulator's format, the chip's outputs ("pins CYCLE XX":
C2CK on P0, the chip's C2D output on P1, the other bits 1) and the words it
pushes ("rx CYCLE WORD", decimal). The TX words are the task sheet's; it
reads them back into frames in its own way (frames_of below, written apart
from accept.py's tx_words) and exits with an error, which the judge counts
as a failure, if they are not what the sheet says. The bytes it pushes are
not taken from the test's frames: it reads them from the stimulus file, at
each rising edge it makes, as the chip would read the C2D pin.

It is written apart from accept.py and builds the waveform differently: it
walks the frames field by field, keeping the slot count itself, draws C2CK
and C2D into per-cycle arrays, and puts each of the chip's bits out at a
chosen offset after the place of the rising edge before (10 cycles by
default) and reads each device bit 6 cycles after the rising edge it makes.
accept.py works from a schedule and the edges it finds.

--fault changes the waveform in one named way (FAULTS below), to show that
the judge fails what it should. Some names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

R0, SLOT = 2000, 50
LAST_BYTE_CMD = {1: "AW", 2: "AR", 3: "DW", 4: "DR"}

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: reset from cycle 1 to 1500, strobes low 20 cycles, chip bits put out and C2D released 10 cycles after a rising edge"),
    "jitter2":     (True,  "rising edges alternately 2 cycles early and 2 late (the limit)"),
    "late2":       (True,  "every rising edge 2 cycles late"),
    "low4":        (True,  "strobes low 4 cycles (the shortest allowed)"),
    "low40jit":    (True,  "strobes low 40 cycles with rising edges alternately 2 late and 2 early: high for 6 cycles (both limits)"),
    "reset1100":   (True,  "reset low from cycle 300 to 1400: the latest fall, the shortest reset"),
    "reset1800":   (True,  "reset low from cycle 300 to 1800: the latest rise"),
    "setuplimit":  (True,  "each chip bit put out in the cycle before C2CK falls (the latest allowed)"),
    "holdlimit":   (True,  "each chip bit put out in the cycle after the rising edge before (the earliest allowed)"),
    "releaselimit": (True, "C2D released in the cycle C2CK falls for the strobe after the chip's field (the latest allowed)"),
    "pushlate":    (True,  "every rx word pushed at the very end of the run"),
    "flipbit":     (False, "the last chip-driven bit of the last frame inverted"),
    "msbfirst":    (False, "ADDRESS and DATA bytes sent and read most significant bit first"),
    "insmsb":      (False, "the INS code sent most significant bit first (Address Read and Data Write swapped)"),
    "lenn":        (False, "LENGTH sent as n, not n - 1"),
    "rxwrong":     (False, "the last rx word has its lowest bit inverted"),
    "rxmissing":   (False, "the last rx word is not pushed"),
    "rxextra":     (False, "one extra rx word, 0, after the last"),
    "rxhigh":      (False, "rx words with bits 15..8 set"),
    "readatedge":  (False, "the device's bits read in the cycle of the rising edge, before the device answers"),
    "late3":       (False, "the sixth strobe (its fall and rise) 3 cycles late"),
    "early3":      (False, "the sixth strobe (its fall and rise) 3 cycles early"),
    "slot51":      (False, "slots of 51 cycles: the error adds up"),
    "low3":        (False, "strobes low 3 cycles"),
    "low41":       (False, "strobes low 41 cycles"),
    "reset1099":   (False, "reset low for 1099 cycles (cycle 1 to 1100)"),
    "resetfall301": (False, "reset falls at cycle 301"),
    "resetrise1801": (False, "reset rises at cycle 1801"),
    "noreset":     (False, "no device reset"),
    "holdbad":     (False, "chip bits changed in the cycle of the rising edge before"),
    "setupbad":    (False, "chip bits put out in the cycle C2CK falls"),
    "contend":     (False, "C2D released one cycle after C2CK falls for the strobe after the chip's field"),
    "startpull":   (False, "the chip pulls C2D low for 5 cycles while C2CK is low in every START strobe"),
    "strayclk":    (False, "an extra strobe in the first idle slot"),
    "nostop":      (False, "the last frame has no STOP strobe"),
    "nowait":      (False, "WAIT fields left out (no strobe)"),
    "gap2":        (False, "two idle slots between frames"),
    "dropframe":   (False, "the last frame is not sent"),
    "extraframe":  (False, "the last frame is sent twice"),
    "clkglitch":   (False, "a one-cycle low pulse on C2CK in the first idle slot"),
    "endlow":      (False, "C2CK falls in the slot after the last idle slot and stays low"),
    "datlowend":   (False, "the chip pulls C2D low after the last frame and leaves it there"),
}


def frames_of(words):
    """[(kind, value)] from the TX words, by the task sheet's rules: kind
    AW/AR/DW/DR, value the address (AW), None (AR), the bytes (DW) or the
    byte count (DR)."""
    out, i = [], 0
    while i < len(words):
        w = words[i]
        top, low = w >> 12, w & 0xFFF
        kind = LAST_BYTE_CMD.get(top)
        if kind is None:
            raise ValueError("word %d (0x%04x) is not a command word" % (i, w))
        if kind == "AW":
            if low > 0xFF:
                raise ValueError("Address Write word 0x%04x has bits above 7" % w)
            out.append((kind, low))
        elif kind == "AR":
            if low:
                raise ValueError("Address Read word 0x%04x is not 0x2000" % w)
            out.append((kind, None))
        else:
            if not 1 <= low <= 4:
                raise ValueError("word 0x%04x: n must be 1 to 4" % w)
            if kind == "DW":
                data = words[i + 1:i + 1 + low]
                if len(data) != low or any(b > 0xFF for b in data):
                    raise ValueError("Data Write at word %d: bad data words" % i)
                out.append((kind, list(data)))
                i += low
            else:
                out.append((kind, low))
        i += 1
    if not out:
        raise ValueError("no words")
    return out


def read_stimulus(path, cycles):
    lev = [0xFF] * cycles
    rows = []
    with open(path) as f:
        for line in f:
            if line.strip():
                c, v = line.split()
                rows.append((int(c), int(v, 16)))
    for (c, v), nxt in zip(rows, rows[1:] + [(cycles, None)]):
        for t in range(c, min(nxt[0], cycles)):
            lev[t] = v
    return lev


def waveform(frames, stim, cycles, fault):
    """(clk, dat, rx): per-cycle C2CK and chip C2D outputs, rx [(cycle, word)]."""
    clk = [1] * cycles
    dat = [1] * cycles
    rx = []
    slot_len = 51 if fault == "slot51" else SLOT
    low = {"low4": 4, "low40jit": 40, "low3": 3, "low41": 41}.get(fault, 20)
    doff = {"setuplimit": SLOT - low - 1, "holdlimit": 1, "holdbad": 0,
            "setupbad": SLOT - low, "low40jit": 4}.get(fault, 10)
    release = {"releaselimit": SLOT - low, "contend": SLOT - low + 1}.get(fault, doff)

    # The device reset.
    fall, rise = {"reset1100": (300, 1400), "reset1800": (300, 1800), "reset1099": (1, 1100),
                  "resetfall301": (301, 1500), "resetrise1801": (300, 1801)}.get(fault, (1, 1500))
    if fault != "noreset":
        for c in range(fall, rise):
            clk[c] = 0

    def place(s):
        return R0 + slot_len * s

    strobe_no = [0]

    def strobe(s, shift=0):
        k = strobe_no[0]
        strobe_no[0] += 1
        jit = 0
        if fault in ("jitter2", "low40jit"):
            jit = 2 if k % 2 == 0 else -2
        if fault == "late2":
            jit = 2
        if fault in ("late3", "early3") and k == 5:
            jit = 3 if fault == "late3" else -3
        e = place(s) + jit + shift
        for c in range(max(e - low, 0), min(e, cycles)):
            clk[c] = 0
        return e

    def drive(s, b):
        """The chip's bit for the strobe of slot s: from doff after the place
        of the edge before to the next change (or release)."""
        start = place(s - 1) + doff
        for c in range(start, min(place(s) + SLOT, cycles)):
            dat[c] = b

    def let_go(s):
        for c in range(place(s) + release, cycles):
            dat[c] = 1

    if fault == "dropframe":
        frames = frames[:-1]
    if fault == "extraframe":
        frames = frames + [frames[-1]]
    s = 0
    first_idle = None
    for index, (kind, value) in enumerate(frames):
        last_frame = index == len(frames) - 1
        ins = {"DR": (0, 0), "DW": (1, 0), "AR": (0, 1), "AW": (1, 1)}[kind]
        if fault == "insmsb":
            ins = ins[::-1]
        if fault == "startpull":
            for c in range(place(s) - 15, place(s) - 10):
                dat[c] = 0
        strobe(s)                                  # START
        s += 1
        chip = list(ins)
        if kind in ("DW", "DR"):
            n = len(value) if kind == "DW" else value
            ln = n if fault == "lenn" else n - 1
            chip += [ln & 1, (ln >> 1) & 1]
        if kind == "AW":
            chip += [(value >> (7 - k if fault == "msbfirst" else k)) & 1 for k in range(8)]
        if kind == "DW":
            chip += [(byte >> (7 - k if fault == "msbfirst" else k)) & 1
                     for byte in value for k in range(8)]
        if fault == "flipbit" and last_frame:
            chip[-1] ^= 1
        for b in chip:
            drive(s, b)
            strobe(s)
            s += 1
        let_go(s - 1)
        reads = []
        if kind == "AR":
            reads = [8]
        if kind == "DW" and fault != "nowait":
            strobe(s)                              # WAIT
            s += 1
        if kind == "DR":
            if fault != "nowait":
                strobe(s)                          # WAIT
                s += 1
            reads = [8] * value
        for count in reads:
            byte = 0
            for k in range(count):
                e = strobe(s)
                s += 1
                at = e if fault == "readatedge" else e + 6
                b = (stim[at] >> 1) & 1 if at < cycles else 1
                byte |= b << (7 - k if fault == "msbfirst" else k)
            rx.append((min(e + 5, cycles - 1), byte))
        if not (fault == "nostop" and last_frame):
            strobe(s)                              # STOP
            s += 1
        if first_idle is None:
            first_idle = s
        s += 2 if fault == "gap2" else 1           # the idle slot
    if fault == "strayclk" and len(frames) > 0:
        strobe(first_idle)
    if fault == "clkglitch":
        clk[place(first_idle) - 10] = 0
    if fault == "endlow":
        for c in range(place(s) - 10, cycles):
            clk[c] = 0
    if fault == "datlowend":
        for c in range(place(s) - 10, cycles):
            dat[c] = 0
    if fault == "rxwrong" and rx:
        rx[-1] = (rx[-1][0], rx[-1][1] ^ 1)
    if fault == "rxmissing" and rx:
        rx = rx[:-1]
    if fault == "rxextra":
        rx.append((cycles - 1, 0))
    if fault == "rxhigh":
        rx = [(c, w | 0xFF00) for c, w in rx]
    if fault == "pushlate":
        rx = [(cycles - 1, w) for _, w in rx]
    return clk, dat, rx


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if (fault not in FAULTS or argv[:1] != ["run"] or "-tx" not in argv
            or "-cycles" not in argv or "-stimulus" not in argv):
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(line, 0) for line in f if line.strip()]
    cycles = int(argv[argv.index("-cycles") + 1])
    stim = read_stimulus(argv[argv.index("-stimulus") + 1], cycles)
    try:
        frames = frames_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    clk, dat, rx = waveform(frames, stim, cycles, fault)
    lines, prev = [], None
    for c in range(cycles):
        v = 0xFC | clk[c] | (dat[c] << 1)
        if v != prev:
            lines.append((c, "pins %d %02x" % (c, v)))
            prev = v
    lines += [(c, "rx %d %d" % (c, w)) for c, w in rx]
    lines.sort(key=lambda t: t[0])
    sys.stdout.write("".join(l + "\n" for _, l in lines))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
