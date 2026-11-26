#!/usr/bin/env python3
"""An ideal FSI master, as a waveform generator: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints what pe_sim would: the outputs of P0 (FSI_DAT) and P1 (FSI_CLK)
("pins CYCLE XX", starting from "pins 0 ff") and the words pushed to the
host ("rx CYCLE WORD", decimal).

It is written apart from accept.py on purpose, and works differently. It
reads the TX words back into transactions by the task sheet's rules in its
own code (and exits with an error, which the judge counts as a failure, if
they break them). It does not know what the slave will answer or when: it
behaves as a master does, clocking and reading the slave's level from the
stimulus file at each falling edge, hunting for the slave's START, then
reading the code and, for a read answered ACK, the data. Its CRC is the
table-driven nibble method of Linux's lib/crc4.c, where accept.py shifts
bit by bit. So the ideal waveform passes only if the words, the stimulus,
the judge's ideal link and the decoder all agree.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. A few names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

PERIOD = 20
F0 = 100
HALF = 10
FIRST = 4
GAP = 20
CRC4_TAB = [0x0, 0x7, 0xE, 0x9, 0xB, 0xC, 0x5, 0x2, 0x1, 0x6, 0xF, 0x8, 0xA, 0xD, 0x4, 0x3]

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":       (True,  "ideal: DATA changes at each falling edge, clock stops after the last rising edge of the run"),
    "jitter_a":   (True,  "every falling edge 2 cycles late and every rising edge 2 early (clock low 6 cycles)"),
    "jitter_b":   (True,  "every falling edge 2 cycles early and every rising edge 2 late (clock high 6 cycles)"),
    "earlydata":  (True,  "DATA changes 1 cycle after the rising edge before (the earliest; 'none' is the latest)"),
    "runon":      (True,  "the clock keeps running to the end of the simulation"),
    "flipaddr":   (False, "one address bit of the last command inverted, its CRC that of the right address"),
    "addrlsb":    (False, "the address sent least significant bit first"),
    "idlsb":      (False, "the slave ID sent least significant bit first"),
    "noinvert":   (False, "FSI_DAT not inverted: the chip pulls low for a 0"),
    "crcnostart": (False, "the command CRC computed without the START bit"),
    "word00":     (False, "4-byte accesses sent with address bits 1..0 = 00"),
    "dsbyte":     (False, "the data size bit sent as 1 for 1-byte accesses"),
    "rxbit":      (False, "one rx data bit inverted"),
    "rxswap":     (False, "a 4-byte read's two rx words in the wrong order"),
    "rxnocode":   (False, "no response-code word"),
    "rxextra":    (False, "one extra rx word at the end"),
    "ackonly":    (False, "every response read as if it were ACK (data read after an ERR)"),
    "fixeddelay": (False, "the slave's START assumed at D = 17 instead of found"),
    "late1":      (False, "every command one clock late"),
    "gap19":      (False, "19 idle clocks after a response instead of 20"),
    "edge3":      (False, "one rising edge 3 cycles late"),
    "period21":   (False, "a clock period of 21 cycles"),
    "afterfall":  (False, "every DATA change 1 cycle after its falling edge (clock already low)"),
    "setup":      (False, "the first START bit put on DATA in the cycle before its rising edge"),
    "hold":       (False, "the first START bit put on DATA in the cycle of its rising edge"),
    "glitch":     (False, "a one-cycle low pulse on DATA while the clock is high, in the turnaround after the first command"),
    "clockearly": (False, "FSI_CLK first falls at cycle 5"),
    "stopearly":  (False, "the clock stops 6 clocks after the last response"),
    "droplast":   (False, "the last transaction is not performed"),
}


def crc4_nibbles(value, nbits):
    """Linux lib/crc4.c: CRC-4 (x^4 + x^2 + x + 1) from 0, by nibbles,
    most significant first, the value padded to a whole nibble at the top."""
    c = 0
    nbits = (nbits + 3) & ~3
    for i in range(nbits - 4, -1, -4):
        c = CRC4_TAB[c ^ ((value >> i) & 0xF)]
    return c


class Msg:
    """A message as Linux's fsi-master-gpio builds one: bits pushed at the
    bottom of an integer, sent from the top."""

    def __init__(self):
        self.value, self.bits = 0, 0

    def push(self, value, n, lsb_first=False):
        if lsb_first:
            value = int(format(value & ((1 << n) - 1), "0%db" % n)[::-1], 2)
        self.value = (self.value << n) | (value & ((1 << n) - 1))
        self.bits += n

    def bitlist(self):
        return [(self.value >> i) & 1 for i in range(self.bits - 1, -1, -1)]


def parse_words(words):
    """Transactions by the task sheet's rules: (read, nbytes, sid, addr, data)."""
    out, i = [], 0
    while i < len(words):
        op = words[i]
        if op >> 5 or (op & 3) == 3:
            raise ValueError("bad operation word 0x%04x" % op)
        if i + 2 >= len(words):
            raise ValueError("a transaction is cut short")
        hi, lo = words[i + 1], words[i + 2]
        if hi >> 5 or lo >> 16:
            raise ValueError("bad address words")
        nbytes, read, sid = 1 << (op & 3), bool(op & 4), (op >> 3) & 3
        addr = (hi << 16) | lo
        if addr % nbytes:
            raise ValueError("address 0x%06x not aligned to %d bytes" % (addr, nbytes))
        i += 3
        data = None
        if not read:
            if nbytes == 4:
                data = (words[i] << 16) | words[i + 1]
                i += 2
            else:
                data = words[i]
                if data >> (8 * nbytes):
                    raise ValueError("data word 0x%04x too wide" % data)
                i += 1
        out.append((read, nbytes, sid, addr, data))
    return out


def command(read, nbytes, sid, addr, data, fault, flip):
    m = Msg()
    m.push(1, 1)
    m.push(sid, 2, lsb_first=(fault == "idlsb"))
    m.push(0b100, 3)
    m.push(1 if read else 0, 1)
    a = addr
    if nbytes == 4 and fault != "word00":
        a = (a & ~3) | 1
    if flip:
        a ^= 1 << 7
    m.push(a, 21, lsb_first=(fault == "addrlsb"))
    m.push(1 if nbytes > 1 or fault == "dsbyte" else 0, 1)
    if not read:
        m.push(data, 8 * nbytes)
    if fault == "crcnostart":
        crc = crc4_nibbles(m.value & ((1 << (m.bits - 1)) - 1), m.bits - 1)
    elif flip:   # the CRC of the message as it should have been
        crc = crc4_nibbles(m.value ^ (1 << (7 + 1 + (0 if read else 8 * nbytes))), m.bits)
    else:
        crc = crc4_nibbles(m.value, m.bits)
    m.push(crc, 4)
    return m.bitlist()


def master(trans, slave, cycles, fault):
    """{clock: bit sent}, [(cycle, rx word)], the clock after the last
    idle clock (where a further START would be), the last response's last
    clock, and the clock of each command's last bit."""
    period = 21 if fault == "period21" else PERIOD

    def fall(k):
        return F0 + period * k + {"jitter_a": 2, "jitter_b": -2}.get(fault, 0)

    def line(k):
        """The slave's bit of clock k, read just after its falling edge."""
        c = fall(k) + 1
        return 1 - slave[c] if c < len(slave) else 0

    sent, rx, ends = {}, [], []
    k = FIRST + (1 if fault == "late1" else 0)
    e = k
    for n, (read, nbytes, sid, addr, data) in enumerate(trans):
        bits = command(read, nbytes, sid, addr, data, fault, fault == "flipaddr" and n == len(trans) - 1)
        for i, b in enumerate(bits):
            sent[k + i] = b
        c = k + len(bits)
        ends.append(c - 1)
        if fault == "fixeddelay":
            c = c - 1 + 17
        else:
            while not line(c):
                c += 1
                if fall(c) >= cycles:
                    return sent, rx, c, c, ends
        c += 1                                   # past the START
        c += 2                                   # the slave ID, not checked
        code = 2 * line(c) + line(c + 1)
        c += 2
        words = [] if fault == "rxnocode" else [code]
        if read and (code == 0 or fault == "ackonly"):
            v = 0
            for _ in range(8 * nbytes):
                v = 2 * v + line(c)
                c += 1
            if fault == "rxbit" and n == 0:
                v ^= 1
            if nbytes == 4:
                words += [v & 0xFFFF, v >> 16] if fault == "rxswap" else [v >> 16, v & 0xFFFF]
            else:
                words.append(v)
        c += 4                                   # the CRC, not checked
        e = c - 1
        at = fall(c) + 5
        rx += [(at + j, w) for j, w in enumerate(words)]
        k = e + 1 + (19 if fault == "gap19" else GAP)
    if fault == "rxextra":
        rx.append((rx[-1][0] + 1 if rx else 1, 0x0055))
    return sent, rx, k, e, ends


def outputs(trans, slave, cycles, fault):
    """[(cycle, register)] changes, and the rx words."""
    period = 21 if fault == "period21" else PERIOD
    sent, rx, s_end, e_last, ends = master(trans, slave, cycles, fault)
    shift_f = {"jitter_a": 2, "jitter_b": -2}.get(fault, 0)
    shift_r = {"jitter_a": -2, "jitter_b": 2}.get(fault, 0)
    clk = [1] * cycles
    stop = cycles if fault == "runon" else (
        F0 + period * (e_last + 7) if fault == "stopearly" else F0 + period * (s_end - 1) + HALF + 1)
    k = 0
    while True:
        f = F0 + period * k + shift_f
        r = F0 + period * k + HALF + shift_r
        if k == 0 and fault == "clockearly":
            f = 5
        if fault == "edge3" and k == 30:
            r += 3
        if f >= min(stop, cycles):
            break
        for c in range(f, min(r, cycles)):
            clk[c] = 0
        k += 1
    # DATA: the level for clock k's bit (released for a 0, low for a 1; the
    # other way round with "noinvert", whose idle line is then low), put on
    # the line at the falling edge that begins clock k unless a fault says
    # otherwise. Every clock not in a command carries a 0.
    data = [1] * cycles
    last = max(sent) + 2 if sent else 0
    points = []
    for k in range(last + 1):
        b = sent.get(k, 0)
        level = b if fault == "noinvert" else 1 - b
        f = F0 + period * k + shift_f
        r_prev = F0 + period * (k - 1) + HALF + shift_r
        r = F0 + period * k + HALF + shift_r
        start = {"afterfall": f + 1, "earlydata": r_prev + 1}.get(fault, f)
        if fault == "setup" and k == FIRST:
            start = r - 1
        if fault == "hold" and k == FIRST:
            start = r
        points.append((max(start, 0), level))
    for (a, level), (b, _) in zip(points, points[1:] + [(cycles, None)]):
        for c in range(a, min(b, cycles)):
            data[c] = level
    if fault == "glitch":
        k0 = ends[0] + 5             # in the turnaround after the first command
        c = F0 + period * k0 + HALF + 3   # clock high: only the ownership rule forbids it
        if c < cycles:
            data[c] = 0
    changes, prev = [], None
    for c in range(cycles):
        v = 0xFC | (clk[c] << 1) | data[c]
        if c == 0:
            v = 0xFF
        if v != prev:
            changes.append((c, v))
            prev = v
    return changes, rx


def read_stimulus(path, cycles):
    """The slave's level on P0 in every cycle."""
    pts = []
    with open(path) as f:
        for line in f:
            if line.strip():
                c, h = line.split()
                pts.append((int(c), int(h, 16) & 1))
    level, out, i = 1, [], 0
    for c in range(cycles):
        while i < len(pts) and pts[i][0] <= c:
            level = pts[i][1]
            i += 1
        out.append(level)
    return out


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    need = ("-tx", "-stimulus", "-cycles")
    if fault not in FAULTS or argv[:1] != ["run"] or any(x not in argv for x in need):
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(line, 0) for line in f if line.strip()]
    cycles = int(argv[argv.index("-cycles") + 1])
    slave = read_stimulus(argv[argv.index("-stimulus") + 1], cycles)
    try:
        trans = parse_words(words)
    except (ValueError, IndexError) as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    if fault == "droplast":
        trans = trans[:-1]
    changes, rx = outputs(trans, slave, cycles, fault)
    lines = [(c, "pins %d %02x" % (c, v)) for c, v in changes]
    lines += [(c, "rx %d %d" % (c, w)) for c, w in rx if c < cycles]
    sys.stdout.write("".join(l + "\n" for _, l in sorted(lines, key=lambda x: x[0])))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
