#!/usr/bin/env python3
"""An ideal LPC host, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints what the simulator would print for a perfect hand-in: the chip's
pin outputs ("pins CYCLE XX", bit k = Pk) and the words it pushes ("rx
CYCLE WORD"). It reads the TX words by the task sheet's rules in its own
code (transactions_of, written apart from accept.py's tx_words) and exits
with an error if they break those rules. It does not know the data bytes:
it reads them from the stimulus file, as the chip would, by sampling the
wire (its own open-drain output AND the peripheral's level) one cycle
before each rising edge of LCLK.

It is written apart from accept.py and works differently: it walks the
clocks and changes outputs on falling edges of LCLK, where accept.py lists
the level every rising edge must sample.

--fault breaks the waveform in one named way (FAULTS below). A few names
are not faults but waveforms at the edge of what the task sheet allows,
which must still pass."""
import sys

PERIOD, R0, SLOT, FIRST = 20, 100, 24, 4
LCLK, LFRAME = 5, 4

FAULTS = {
    "none":       (True,  "ideal: outputs change on LCLK's falling edge, clock stops after the last clock"),
    "runon":      (True,  "LCLK keeps running on schedule to the end of the run"),
    "jitter2":    (True,  "rising edges alternately 2 cycles late and 2 early (the limit)"),
    "setup2":     (True,  "LFRAME#/LAD change 2 cycles before the rising edge (the limit)"),
    "hold1":      (True,  "LFRAME#/LAD change 1 cycle after the rising edge (the limit)"),
    "phase6":     (True,  "LCLK high for 6 cycles, low for 14 (the limit)"),
    "flipaddr":   (False, "one address bit of the last transaction inverted on the bus"),
    "lsnfirst":   (False, "address nibbles sent least significant first"),
    "wrongct":    (False, "memory reads sent with the I/O read cycle type"),
    "rxflip":     (False, "one bit of the last rx word wrong"),
    "rxswap":     (False, "rx words with their nibbles swapped"),
    "rxextra":    (False, "one extra rx word at the end"),
    "late3":      (False, "one LCLK rising edge 3 cycles late"),
    "slow21":     (False, "LCLK period 21 cycles: the error adds up"),
    "short5":     (False, "LCLK high for 5 cycles"),
    "setup1":     (False, "LFRAME#/LAD change 1 cycle before the rising edge"),
    "hold0":      (False, "LFRAME#/LAD change in the cycle of the rising edge"),
    "norelease":  (False, "LAD0 held low by the chip through the peripheral's clocks of the last read"),
    "ladidle":    (False, "the chip drives LAD to 0000 in the idle clocks"),
    "lframe2":    (False, "LFRAME# low for two clocks (START repeated)"),
    "glitch":     (False, "a one-cycle low pulse on LFRAME# between two rising edges while idle"),
    "lateslot":   (False, "every transaction one clock late"),
    "stopearly":  (False, "LCLK stops one clock before the last transaction ends"),
    "dropxact":   (False, "the last transaction is not run"),
}


def R(k):
    return R0 + PERIOD * k


def transactions_of(words):
    """[(nibbles, address)] by the sheet: a type word (0 I/O read, 1 memory
    read), then one address word, or two (high half first)."""
    out, i = [], 0
    while i < len(words):
        kind = words[i]
        if kind not in (0, 1):
            sys.exit("ideal_wave: word %d is %#x, not a type word (0 or 1)" % (i, kind))
        n = 1 if kind == 0 else 2
        if i + n >= len(words):
            sys.exit("ideal_wave: the words end inside a transaction")
        addr = 0
        for w in words[i + 1:i + 1 + n]:
            if w >> 16:
                sys.exit("ideal_wave: %#x is wider than 16 bits" % w)
            addr = (addr << 16) | w
        out.append((kind, addr))
        i += 1 + n
    return out


def level_at(stim, c):
    v = 0xFF
    for at, val in stim:
        if at <= c:
            v = val
    return v


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if fault not in FAULTS:
        sys.exit("ideal_wave: no fault named %s" % fault)
    words, stim, cycles = [], [], 0
    i = 0
    while i < len(argv):
        if argv[i] == "-tx":
            words = [int(l, 0) for l in open(argv[i + 1]).read().split()]
        elif argv[i] == "-stimulus":
            for line in open(argv[i + 1]):
                if line.strip():
                    c, v = line.split()
                    stim.append((int(c), int(v, 16)))
        elif argv[i] == "-cycles":
            cycles = int(argv[i + 1])
        i += 1
    trans = transactions_of(words)
    if fault == "dropxact":
        trans = trans[:-1]

    shift = 1 if fault == "lateslot" else 0
    # Clock by clock: what the chip drives during clock k (LFRAME#, LAD outputs).
    drive = {}
    ends = []
    for n, (kind, addr) in enumerate(trans):
        s = FIRST + SLOT * n + shift
        nib = 4 if kind == 0 else 8
        ct = 0b0100 if kind == 1 and fault != "wrongct" else 0
        nibbles = [(addr >> (4 * j)) & 0xF for j in range(nib)]
        if fault != "lsnfirst":
            nibbles.reverse()
        if fault == "flipaddr" and n == len(trans) - 1:
            nibbles[-1] ^= 0b0010
        seq = [(0, 0)] + ([(0, 0)] if fault == "lframe2" else []) + [(1, ct)] + [(1, x) for x in nibbles]
        if fault == "lframe2":
            s -= 1
        for j, v in enumerate(seq):
            drive[s + j] = v
        t = s + len(seq)
        drive[t] = (1, 0xF)
        ends.append((t, t + 6))
        if fault == "norelease" and n == len(trans) - 1:
            for k in range(t + 1, t + 7):
                drive[k] = (1, 0xE)
    last = ends[-1][1] if ends else 0
    stop = last - 1 if fault == "stopearly" else last
    if fault == "runon":
        stop = 10 ** 9
    if fault == "ladidle":
        busy = {k for t, e in ends for k in range(t, e + 1)}
        for k in range(0, last):
            if k not in busy:
                drive.setdefault(k, (1, 0x0))

    def rise(k):
        if fault == "jitter2":
            return R(k) + (2 if k % 2 else -2)
        if fault == "late3" and k == 7:
            return R(k) + 3
        if fault == "slow21":
            return R0 + 21 * k
        return R(k)

    high = 6 if fault == "phase6" else (5 if fault == "short5" else 10)
    change = {"setup2": -2, "hold1": -PERIOD + 1, "setup1": -1, "hold0": -PERIOD}.get(fault, -10)
    events = {}  # cycle -> {bit: level}

    def put(c, b, lvl):
        events.setdefault(c, {})[b] = lvl

    k = 0
    while True:
        r = rise(k)
        if k > stop or r >= cycles:
            break
        put(r - PERIOD + high, LCLK, 0)
        put(r, LCLK, 1)
        k += 1
    lad_cur = None
    for k in sorted(set(range(0, last + 1)) | set(drive)):
        lf, lad = drive.get(k, (1, 0xF))
        c = rise(k) + change          # the change that sets up clock k
        put(c, LFRAME, lf)
        for b in range(4):
            put(c, b, (lad >> b) & 1)
    if fault == "glitch":
        put(R(1) - 8, LFRAME, 0)
        put(R(1) - 7, LFRAME, 1)

    out, cur = [], 0xFF
    rx = []
    for c in range(cycles):
        for b, lvl in events.get(c, {}).items():
            cur = (cur & ~(1 << b)) | (lvl << b)
        out.append(cur)
    print("pins 0 %02x" % out[0])
    for c in range(1, cycles):
        if out[c] != out[c - 1]:
            print("pins %d %02x" % (c, out[c]))
    for n, (t, _) in enumerate(ends):
        lo_c, hi_c = rise(t + 3) - 1, rise(t + 4) - 1
        if hi_c >= cycles:
            break
        lo = out[lo_c] & level_at(stim, lo_c) & 0xF
        hi = out[hi_c] & level_at(stim, hi_c) & 0xF
        rx.append((hi_c + 6, (lo << 4 | hi) if fault == "rxswap" else (hi << 4 | lo)))
    if fault == "rxflip" and rx:
        rx[-1] = (rx[-1][0], rx[-1][1] ^ 0x08)
    if fault == "rxextra" and rx:
        rx.append((rx[-1][0] + 1, 0))
    for c, w in rx:
        print("rx %d %d" % (c, w))


if __name__ == "__main__":
    main(sys.argv[1:])
