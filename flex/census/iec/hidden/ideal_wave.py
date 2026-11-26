#!/usr/bin/env python3
"""An ideal IEC controller and talker, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints the chip's pin outputs in the simulator's format ("pins CYCLE XX",
P0 DATA, P1 CLK, P2 ATN, the other pins 1). It reads the task sheet's words
back into transactions in its own code, and it reacts to the listener: it
reads the stimulus file as a level on DATA over time, sees each change two
cycles late (as the chip's input synchroniser does), and times each of its
own actions from what it saw, as firmware would. It never sees accept.py's
plan of the listener's timeline.

--fault breaks the waveform in one named way. A few names are not faults
but waveforms at the edge of what the task sheet allows, which must pass."""
import sys

SYNC = 2
LAST = 0x100

FAULTS = {
    "none":       (True,  "ideal: every action near the middle of its window"),
    "edgemin":    (True,  "every action at the earliest the sheet allows, bits of 40 cycles (20 low, 20 high), setup exactly 20"),
    "edgemax":    (True,  "every action at the latest the sheet allows, bits of 100 cycles, DATA released 20 after the 8th fall"),
    "flipbit":    (False, "one data bit of the last transaction inverted"),
    "msbfirst":   (False, "bytes sent most significant bit first"),
    "listen40":   (False, "TALK (0x40) sent instead of LISTEN"),
    "noeoi":      (False, "the last byte sent without waiting for the EOI pulse"),
    "eoiall":     (False, "waits as for EOI on every data byte (CLK held past 200)"),
    "noatn":      (False, "commands sent with ATN high"),
    "atnstay":    (False, "ATN kept low through the data bytes"),
    "nounl":      (False, "UNLISTEN not sent"),
    "setup19":    (False, "DATA set 19 cycles before a CLK rise"),
    "datahigh":   (False, "DATA changed while CLK is high"),
    "high19":     (False, "CLK high for 19 cycles in each bit"),
    "period101":  (False, "bits of 101 cycles"),
    "ready99":    (False, "CLK released 99 cycles after the listener pulled DATA low"),
    "ready401":   (False, "CLK released 401 cycles after the listener pulled DATA low"),
    "rfd201":     (False, "first CLK fall 201 cycles after the listener released DATA"),
    "eoi61":      (False, "first CLK fall 61 cycles after the EOI pulse ended"),
    "turn19":     (False, "ATN released 19 cycles after SECOND was acknowledged"),
    "turn91":     (False, "ATN and CLK released 91 cycles after UNLISTEN was acknowledged"),
    "atn99":      (False, "ATN pulled low 99 cycles after the bus went free"),
    "clk21":      (False, "CLK pulled low 21 cycles after ATN"),
    "holddata":   (False, "DATA released 21 cycles after the 8th CLK fall"),
    "blind":      (False, "ignores the listener and times everything from the listener's middle delays"),
    "extrabyte":  (False, "the last data byte sent twice"),
    "dropbyte":   (False, "the first data byte of each transaction left out"),
    "tail":       (False, "a pulse on CLK 500 cycles after the run's last transaction"),
}


def transactions_of(words):
    out, i = [], 0
    while i < len(words):
        h = words[i]
        if h & ~0x0F1F:
            raise ValueError("header 0x%04x has bits outside 4..0 and 11..8" % h)
        dev, sa = h & 0x1F, (h >> 8) & 0xF
        if dev == 31:
            raise ValueError("device 31")
        i += 1
        data = []
        while True:
            if i >= len(words):
                raise ValueError("the words end inside a transaction")
            w = words[i]
            i += 1
            if w >> 9:
                raise ValueError("data word 0x%04x has a bit above bit 8 set" % w)
            data.append(w & 0xFF)
            if w & LAST:
                break
        out.append((dev, sa, data))
    if not out:
        raise ValueError("no words")
    return out


class Listener:
    """DATA as the stimulus sets it, seen SYNC cycles late."""

    def __init__(self, changes):
        self.changes = changes  # [(cycle, level)], from cycle 0

    def level(self, c):
        lv = 1
        for t, l in self.changes:
            if t > c:
                break
            lv = l
        return lv

    def wait(self, t, level):
        """The cycle the chip, polling from cycle t, first sees DATA at level."""
        c = t
        while True:
            if self.level(c - SYNC) == level:
                return c
            nxt = [x for x, _ in self.changes if x + SYNC > c]
            if not nxt:
                raise EOFError
            c = nxt[0] + SYNC


def talk(transactions, listener, fault):
    """[(cycle, pin, level)] of the chip's outputs."""
    out = []
    put = lambda c, p, l: out.append((c, p, l))
    S = SYNC  # every "after event" delay below is from the event itself
    gap = {"edgemin": 100, "edgemax": 400, "atn99": 99}.get(fault, 200)
    clkd = {"edgemin": 0, "edgemax": 20, "clk21": 21}.get(fault, 5)
    ready = {"edgemin": 100, "edgemax": 400, "ready99": 99, "ready401": 401}.get(fault, 200)
    rfd = {"edgemin": S, "edgemax": 200, "rfd201": 201}.get(fault, 50)
    eoid = {"edgemin": S, "edgemax": 60, "eoi61": 61}.get(fault, 25)
    turn = {"edgemin": 20, "edgemax": 90, "turn19": 19}.get(fault, 40)
    low_, high_ = {"edgemin": (20, 20), "edgemax": (80, 20), "high19": (41, 19),
                   "period101": (61, 40)}.get(fault, (40, 25))
    setup = {"setup19": 19, "edgemin": 20, "edgemax": 20}.get(fault, 30)
    release = {"edgemax": 20, "holddata": 21}.get(fault, 3)
    if fault == "listen40":
        transactions = [(0x20 | d, s, x) for d, s, x in transactions]
    if fault == "flipbit":
        d, s, x = transactions[-1]
        transactions = transactions[:-1] + [(d, s, x[:-1] + [x[-1] ^ 0x08])]
    if fault == "extrabyte":
        transactions = [(d, s, x[:-1] + [x[-1], x[-1]]) for d, s, x in transactions]
    blind_t = [0]

    def see(t, level, nominal):
        if fault == "blind":
            return t + nominal
        return listener.wait(t, level)

    free = 0  # the bus is free from cycle 0
    try:
        for dev, sa, data in transactions:
            ta = free + gap
            atn_low = fault != "noatn"
            if atn_low:
                put(ta, 2, 0)
            put(ta + clkd, 1, 0)
            k = see(ta + clkd + 1, 0, 700 - gap - clkd) - S
            seq = [(0x20 | dev if fault != "listen40" else 0x40 | (dev & 0x1F), True, False),
                   (0x60 | sa, True, False)]
            body = data[1:] if fault == "dropbyte" else data
            seq += [(b, False, i == len(body) - 1) for i, b in enumerate(body)]
            if fault != "nounl":
                seq.append((0x3F, True, False))
            for n, (byte, atn, eoi) in enumerate(seq):
                r_clk = k + ready
                put(r_clk, 1, 1)
                r = see(r_clk + 1, 1, 700 - ready) - S
                if (eoi and fault != "noeoi") or (fault == "eoiall" and not atn):
                    p0 = see(r + S, 0, 300) - S
                    p1 = see(p0 + S, 1, 100) - S
                    f = p1 + eoid
                else:
                    f = r + rfd
                put(f, 1, 0)
                bits = [(byte >> i) & 1 for i in range(8)]
                if fault == "msbfirst":
                    bits.reverse()
                level = 1
                for i, bit in enumerate(bits):
                    rise = f + low_
                    if bit != level:
                        at = rise - setup
                        if fault == "datahigh" and i == 3:
                            at = rise + 2
                        put(at, 0, bit)
                        level = bit
                    put(rise, 1, 1)
                    f = rise + high_
                    put(f, 1, 0)
                if level == 0:
                    put(f + release, 0, 1)
                k = see(f + release + 1, 0, 1185 - (f - r)) - S
                last_data = n == len(seq) - 2
                if n == 1 and fault != "atnstay" and atn_low:
                    put(k + turn, 2, 1)
                if last_data and fault != "atnstay" and atn_low and fault != "nounl":
                    put(k + turn, 2, 0)
                if n == len(seq) - 1:
                    tt = {"turn91": 91}.get(fault, turn)
                    if atn_low:
                        put(k + tt, 2, 1)
                    put(k + tt, 1, 1)
                    free = see(k + tt + 1, 1, 200) - S
                    if fault == "nounl":
                        free = k + 200
            last = free
        if fault == "tail":
            put(last + 500, 1, 0)
            put(last + 501, 1, 1)
    except EOFError:
        pass
    return out


def pins_text(events, cycles):
    lines, v = ["pins 0 ff"], 0xFF
    by = {}
    for c, p, l in events:
        by.setdefault(c, []).append((p, l))
    for c in sorted(by):
        if c >= cycles:
            break
        new = v
        for p, l in by[c]:
            new = (new & ~(1 << p)) | (l << p)
        if new != v:
            lines.append("pins %d %02x" % (c, new))
            v = new
    return "\n".join(lines) + "\n"


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if fault not in FAULTS or argv[:1] != ["run"] or not all(f in argv for f in ("-tx", "-stimulus", "-cycles")):
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(line, 0) for line in f if line.strip()]
    changes = []
    with open(argv[argv.index("-stimulus") + 1]) as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                c, v = line.split()
                changes.append((int(c), int(v, 16) & 1))
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        transactions = transactions_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(talk(transactions, Listener(changes), fault), cycles))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
