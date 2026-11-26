#!/usr/bin/env python3
"""An ideal Quad SPI controller writing a NOR flash, as a waveform: NOT chip
firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints the pins' outputs in the simulator's format ("pins CYCLE XX"),
starting with every bit 1 at cycle 0 as the output register does after
reset. Pins: P0..P3 IO0..IO3, P4 SCK, P5 CS#. The words it takes are the
task sheet's: one word per byte, bit 8 set on the last byte of a page, each
page three address bytes then its data. It reads them back into pages in
its own way (pages_of below, written apart from accept.py's tx_words) and
exits with an error, which the judge counts as a failure, if the stream is
not what the sheet says.

It is written apart from accept.py on purpose and works differently: it
walks the frames as a list of timed pin events (set the data, raise SCK,
drop SCK), where accept.py rebuilds the bits from the levels seen at each
SCK rise. If the two disagree, the self-test fails.

--fault changes the waveform in one named way (FAULTS below), to show that
the judge fails what it should. Some names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import random
import sys

IO0, IO1, IO2, IO3, SCK, CS = 0, 1, 2, 3, 4, 5
LAST = 1 << 8
WREN, QPP = 0x06, 0x32

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: SCK 12.5 MHz (2 cycles low, 2 high), data set at each SCK fall, "
                           "CS# high 10 cycles between WREN and QPP, 160000 cycles after each QPP"),
    "fast":        (True,  "SCK 25 MHz: 1 cycle low, 1 high, data changing in the cycle SCK falls"),
    "slow20":      (True,  "SCK period 20 cycles (19 low, 1 high), data set 1 cycle before each rise (the limits)"),
    "skew":        (True,  "SCK 3 cycles low and 4 high, data changing 1 cycle after each rise (hold 1 cycle)"),
    "cs3":         (True,  "CS# high exactly 3 cycles between WREN and QPP"),
    "cs1000":      (True,  "CS# high exactly 1000 cycles between WREN and QPP"),
    "gap150000":   (True,  "exactly 150000 cycles from a QPP's CS# rise to the next WREN's CS# fall"),
    "gap200000":   (True,  "exactly 200000 cycles from a QPP's CS# rise to the next WREN's CS# fall"),
    "start10000":  (True,  "first CS# fall at cycle 10000 (the limit)"),
    "sck100":      (True,  "SCK driven low at cycle 100 (the limit), first CS# fall at cycle 101"),
    "csatfall":    (True,  "CS# rises in the same cycle as the last SCK fall"),
    "dontcare":    (True,  "IO1..IO3 random during command and address, IO0..IO3 moving while CS# is high"),
    "flipbit":     (False, "one data bit of the last page inverted"),
    "flipaddr":    (False, "one address bit of the first page inverted"),
    "lownibble":   (False, "each data byte's low nibble sent first"),
    "revlines":    (False, "IO3 carries the nibble's bit 0 and IO0 its bit 3"),
    "cmd02":       (False, "command 0x02 (single-line Page Program) in place of 0x32"),
    "addrquad":    (False, "the address sent on four lines (1-4-4) instead of on IO0"),
    "nowren":      (False, "no WREN frame before each QPP"),
    "merged":      (False, "WREN and QPP in one CS# frame, CS# never rising between them"),
    "datarise":    (False, "one data change in the same cycle as an SCK rise"),
    "cs2":         (False, "CS# high only 2 cycles between WREN and QPP"),
    "cs1001":      (False, "CS# high 1001 cycles between WREN and QPP"),
    "gap149999":   (False, "149999 cycles from a QPP's CS# rise to the next WREN"),
    "gap200001":   (False, "200001 cycles from a QPP's CS# rise to the next WREN"),
    "start10001":  (False, "first CS# fall at cycle 10001"),
    "sck101":      (False, "SCK driven low only at cycle 101"),
    "mode3":       (False, "SPI mode 3: SCK idles high while CS# is high"),
    "sckhighcs":   (False, "CS# rises while SCK is still high (SCK falls one cycle later)"),
    "slow21":      (False, "one SCK rise 21 cycles after the one before it"),
    "extraclk":    (False, "one extra SCK clock at the end of the last QPP"),
    "dropbyte":    (False, "the last 4 data bytes of the last page not sent"),
    "straysck":    (False, "an SCK pulse while CS# is high, after the last page"),
    "csglitch":    (False, "CS# high for one cycle in the middle of a QPP's data"),
    "droppage":    (False, "the last page not sent"),
    "extrapage":   (False, "the last page sent twice"),
}


def pages_of(words):
    """[(address, [data bytes])] from the TX words, by the task sheet's rules."""
    out, cur = [], []
    for w in words:
        if w >> 9:
            raise ValueError("word 0x%04x has a bit above bit 8 set" % w)
        cur.append(w & 0xFF)
        if w & LAST:
            if len(cur) < 7 or (len(cur) - 3) % 4:
                raise ValueError("a page of %d bytes" % len(cur))
            out.append(((cur[0] << 16) | (cur[1] << 8) | cur[2], cur[3:]))
            cur = []
    if cur:
        raise ValueError("the last word does not end a page")
    if not out:
        raise ValueError("no words")
    return out


class Wave:
    """Pin events: {cycle: {pin: level}}, later writes to the same pin and
    cycle win."""

    def __init__(self):
        self.ev = {}

    def at(self, cycle, pin, level):
        self.ev.setdefault(cycle, {})[pin] = level

    def nibble(self, cycle, value, mask=0xF):
        for k in range(4):
            if mask >> k & 1:
                self.at(cycle, k, value >> k & 1)

    def text(self, cycles):
        reg, lines = 0xFF, ["pins 0 ff"]
        for c in sorted(self.ev):
            new = reg
            for pin, level in self.ev[c].items():
                new = (new & ~(1 << pin)) | (level << pin)
            if new != reg and 0 < c < cycles:
                lines.append("pins %d %02x" % (c, new))
            reg = new
        return "\n".join(lines) + "\n"


def frames(pages, fault):
    """Each frame as a list of beats (value, mask): mask 1 is IO0 only."""
    out = []
    for n, (addr, data) in enumerate(pages):
        if fault == "flipaddr" and n == 0:
            addr ^= 0x000400
        if fault == "flipbit" and n == len(pages) - 1:
            data = data[:-1] + [data[-1] ^ 0x10]
        if fault == "dropbyte" and n == len(pages) - 1:
            data = data[:-4]
        single = lambda v, bits: [((v >> k) & 1, 1) for k in range(bits - 1, -1, -1)]
        wren = single(WREN, 8)
        qpp = single(0x02 if fault == "cmd02" else QPP, 8)
        if fault == "addrquad":
            qpp += [((addr >> k) & 0xF, 0xF) for k in range(20, -1, -4)]
        else:
            qpp += single(addr, 24)
        for b in data:
            hi, lo = b >> 4, b & 0xF
            if fault == "lownibble":
                hi, lo = lo, hi
            if fault == "revlines":
                hi = int("{:04b}".format(hi)[::-1], 2)
                lo = int("{:04b}".format(lo)[::-1], 2)
            qpp += [(hi, 0xF), (lo, 0xF)]
        if fault == "extraclk" and n == len(pages) - 1:
            qpp += [(0, 0xF)]
        if fault == "nowren":
            out.append(("qpp", qpp))
        elif fault == "merged":
            out.append(("merged", wren + qpp))
        else:
            out += [("wren", wren), ("qpp", qpp)]
    return out


def build(pages, fault="none"):
    rng = random.Random(5)
    if fault == "droppage":
        pages = pages[:-1]
    if fault == "extrapage":
        pages = pages + [pages[-1]]
    low, high = {"fast": (1, 1), "slow20": (19, 1), "skew": (3, 4)}.get(fault, (2, 2))
    cs_gap = {"cs3": 3, "cs1000": 1000, "cs2": 2, "cs1001": 1001}.get(fault, 10)
    page_gap = {"gap150000": 150000, "gap200000": 200000, "gap149999": 149999,
                "gap200001": 200001}.get(fault, 160000)
    t = {"start10000": 10000, "start10001": 10001, "sck100": 101}.get(fault, 2000)
    w = Wave()
    sck_low_at = {"sck100": 100, "sck101": 101}.get(fault, 1)
    idle_sck = 1 if fault == "mode3" else 0
    w.at(sck_low_at, SCK, 0)
    if idle_sck:
        w.at(sck_low_at + 1, SCK, 1)            # then idles high
    if fault == "sck101":
        t = max(t, 102)
    w.at(sck_low_at, CS, 1)
    fr = frames(pages, fault)
    rises = 0
    for i, (kind, beats) in enumerate(fr):
        w.at(t, CS, 0)
        if idle_sck:
            w.at(t, SCK, 0)
        c = t                                   # SCK low from here
        prev_rise = None
        for j, (value, mask) in enumerate(beats):
            rise = c + low
            if fault == "slow21" and i == len(fr) - 1 and j == 5:
                rise = c + 21 - high            # 21 cycles after the rise before it
            if fault == "slow20":
                when = rise - 1                 # setup exactly 1 cycle
            elif fault == "skew" and prev_rise is not None:
                when = prev_rise + 1            # hold exactly 1 cycle
            else:
                when = c                        # with the SCK fall (or the CS# fall)
            if fault == "dontcare":
                w.nibble(when, rng.randrange(16), 0xE)
            if fault == "datarise" and i == len(fr) - 1 and j == len(beats) - 3:
                w.nibble(when, value ^ 0x1, 0x1)
                when = rise                     # the right value only in the cycle of the rise
            w.nibble(when, value, mask)
            w.at(rise, SCK, 1)
            prev_rise = rise
            rises += 1
            c = rise + high
            w.at(c, SCK, 0)
            if fault == "csglitch" and kind == "qpp" and i == len(fr) - 1 and j == len(beats) - 9:
                w.at(c, CS, 1)
                w.at(c + 1, CS, 0)
        if fault == "sckhighcs" and i == 0:
            w.at(c - 1, CS, 1)                  # SCK still high in that cycle
            end = c - 1
        elif fault == "csatfall":
            w.at(c, CS, 1)
            end = c
        else:
            w.at(c + 1, CS, 1)
            end = c + 1
        if idle_sck:
            w.at(end + 1, SCK, 1)
        if fault == "dontcare":
            for k in range(3):
                w.nibble(end + 1 + k, rng.randrange(16))
        t = end + (cs_gap if kind == "wren" else page_gap)
    if fault == "straysck":
        w.at(t - page_gap + 5000, SCK, 1)
        w.at(t - page_gap + 5001, SCK, 0)
    return w


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
        pages = pages_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(build(pages, fault).text(cycles))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
