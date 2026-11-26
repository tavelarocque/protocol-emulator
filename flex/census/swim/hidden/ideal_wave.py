#!/usr/bin/env python3
"""An ideal SWIM host, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints what pe_sim would: P0's output changes ("pins CYCLE XX", open
drain, so 1 means released) and the words pushed to the host ("rx CYCLE
WORD"). It reads the TX words by the task sheet's rules in its own code
(ops_of below, written apart from accept.py's tx_words) and exits with an
error, which the judge counts as a failure, if they break those rules.

It does not know the judge's timetable. Like a real host it listens to the
target: it finds the synchronization frame in the stimulus, reads every ack
bit's length to tell ACK from NACK and resends after a NACK, and reads the
target's data frames bit by bit from their low times. Everything it does is
timed from the target edges it has found, by the task sheet's rules. So the
ideal waveform passes only if the judge's stimulus, the judge's idea of the
host's edges and sigrok's decoder all agree with this reading of the sheet.

--fault breaks the waveform in one named way (FAULTS below). A few names are
not faults but waveforms at the very edge of what the sheet allows, which
must still pass."""
import sys

BIT, LOW1, LOW0 = 110, 10, 100     # 40 MHz: 22, 2 and 20 SWIM clocks of 5 cycles

FAULTS = {
    "none":         (True,  "ideal: enter sequence from cycle 1000, every edge at its place"),
    "entry400":     (True,  "enter sequence from cycle 400 (the earliest allowed)"),
    "entry4000":    (True,  "enter sequence from cycle 4000 (the latest allowed)"),
    "entryedge":    (True,  "enter sequence periods 1 cycle long and short in turn, falls 2 off (the limits)"),
    "jitter2":      (True,  "every frame edge 2 cycles off its place, early and late in turn (the limit)"),
    "flipbit":      (False, "one data bit of the last WOTF byte inverted"),
    "badparity":    (False, "the parity bit of the first command frame inverted"),
    "lsbfirst":     (False, "bytes sent least significant bit first"),
    "late3":        (False, "one edge of a frame 3 cycles late"),
    "early3":       (False, "the first frame starts 3 cycles early"),
    "entry399":     (False, "enter sequence from cycle 399"),
    "entry4001":    (False, "enter sequence from cycle 4001"),
    "entryrise2":   (False, "one rising edge of the enter sequence 2 cycles late"),
    "noentry":      (False, "no enter sequence"),
    "ignorenack":   (False, "a NACKed frame is not resent"),
    "noack":        (False, "the host does not acknowledge the target's last data frame"),
    "longack":      (False, "the host answers the target's last data frame with a NACK"),
    "collide":      (False, "the host pulls the line low during the target's first data bit"),
    "tail":         (False, "one more 1 bit after the last operation"),
    "rxwrong":      (False, "the last rx word has bit 0 inverted"),
    "rxextra":      (False, "the last rx word is pushed twice"),
    "rxlow":        (False, "rx words carry the byte in bits 15..8"),
    "dropop":       (False, "the last operation is not done"),
}


def ops_of(words):
    """The operations a word stream asks for, by the task sheet's rules."""
    ops, i = [], 0
    while i < len(words):
        w = words[i]
        if w >> 10:
            raise ValueError("command word 0x%04x has a bit above bit 9 set" % w)
        cmd, n = w >> 8, w & 0xFF
        if cmd == 0:
            if n:
                raise ValueError("SRST word 0x%04x has a byte count" % w)
            ops.append(("SRST", None, []))
            i += 1
            continue
        if cmd not in (1, 2) or n == 0:
            raise ValueError("bad command word 0x%04x" % w)
        if i + 2 >= len(words) or words[i + 1] >> 8:
            raise ValueError("address words missing or wrong after 0x%04x" % w)
        addr = (words[i + 1] << 16) | words[i + 2]
        i += 3
        data = []
        if cmd == 2:
            data = words[i:i + n]
            if len(data) != n or any(d >> 8 for d in data):
                raise ValueError("WOTF data words missing or wrong")
            i += n
        ops.append(("ROTF" if cmd == 1 else "WOTF", addr, data if cmd == 2 else [0] * n))
    if not ops:
        raise ValueError("no words")
    return ops


class Line:
    """The target's side of the line, from the stimulus file."""

    def __init__(self, text):
        self.edges = []                  # (cycle, level) of P0 as the target drives it
        for raw in text.splitlines():
            raw = raw.strip()
            if not raw or raw.startswith("#"):
                continue
            c, v = raw.split()
            lv = int(v, 16) & 1
            if not self.edges or self.edges[-1][1] != lv:
                self.edges.append((int(c), lv))

    def next_low(self, after):
        """(fall, length of the low) of the target's first low at or after `after`."""
        for k, (c, lv) in enumerate(self.edges):
            if c >= after and lv == 0:
                return c, self.edges[k + 1][0] - c
        return after, 0          # none: only when out of step with the target (a fault)


class Host:
    def __init__(self, line, fault):
        self.line, self.fault, self.out, self.rx = line, fault, [], []
        self.flip = 0

    def edge(self, cycle, level):
        if self.fault == "jitter2" and self.t_sync is not None:
            self.flip ^= 1
            cycle += 2 if self.flip else -2
        self.out.append((cycle, level))

    def bit(self, t, value):
        self.edge(t, 0)
        self.edge(t + (LOW1 if value else LOW0), 1)

    def entry(self, t):
        self.t_sync = None
        if self.fault == "noentry":
            return
        self.out += [(t, 0), (t + 640, 1)]
        rise = t + 640
        periods = [40000] * 4 + [20000] * 4
        for k, p in enumerate(periods):
            if self.fault == "entryedge":
                fall = rise + p // 2 + (2 if k % 2 else -2)
                p += 1 if k % 2 == 0 else -1
            else:
                fall = rise + p // 2
            nxt = rise + p
            if self.fault == "entryrise2" and k == 5:
                nxt += 2
            self.out += [(fall, 0), (nxt, 1)]
            rise = nxt

    def send(self, t, bits):
        """One host frame from cycle t, resent after every NACK. Returns the
        start of the next frame."""
        bits = list(bits)
        p = 0
        for b in bits:
            p ^= b
        frame = [0] + bits + [p]
        if self.fault == "badparity" and not self.done_bad:
            frame[-1] ^= 1
            self.done_bad = True
        while True:
            for k, b in enumerate(frame):
                self.bit(t + k * BIT, b)
            end = t + len(frame) * BIT
            fall, low = self.line.next_low(end - BIT // 2)
            if abs(fall - end) > 5:          # out of step with the target (a fault)
                return end + 2 * BIT
            t = fall + 2 * BIT
            if low < 4 * 5 * 2:          # an ack: low for 2 SWIM clocks, not 20
                return t
            if self.fault == "ignorenack":
                return t

    def receive(self, t, last):
        """The target's data frame, which starts at cycle t. Returns (byte,
        start of the next frame)."""
        bits = []
        for k in range(10):
            fall, low = self.line.next_low(t + k * BIT - BIT // 2)
            bits.append(1 if low < 40 else 0)
        value = 0
        for b in bits[1:9]:
            value = value << 1 | b
        ack = t + 10 * BIT
        if not (last and self.fault == "noack"):
            self.bit(ack, 0 if (last and self.fault == "longack") else 1)
        return value, ack + 2 * BIT

    def run(self, ops, first):
        self.done_bad = False
        self.entry(first)
        # The synchronization frame: the target's first low after the entry.
        fall, low = self.line.next_low(first + 640 + 240000 + 1)
        if not 64 * 5 <= low <= 128 * 5 * 2:
            raise ValueError("the target's first low is not a synchronization frame")
        self.t_sync = fall + low
        t = self.t_sync + 2 * BIT - (3 if self.fault == "early3" else 0)
        if self.fault == "dropop":
            ops = ops[:-1]
        reads = sum(1 for o in ops if o[0] == "ROTF")
        seen = 0
        for kind, addr, data in ops:
            order = (lambda v: [(v >> k) & 1 for k in range(8)]) if self.fault == "lsbfirst" \
                else (lambda v: [(v >> k) & 1 for k in range(7, -1, -1)])
            t = self.send(t, {"SRST": [0, 0, 0], "ROTF": [0, 0, 1], "WOTF": [0, 1, 0]}[kind])
            if kind == "SRST":
                continue
            t = self.send(t, order(len(data)))
            for shift in (16, 8, 0):
                t = self.send(t, order((addr >> shift) & 0xFF))
            for i, value in enumerate(data):
                if kind == "WOTF":
                    if self.fault == "flipbit" and (kind, addr, data) == [o for o in ops if o[0] == "WOTF"][-1] \
                            and i == len(data) - 1:
                        value ^= 0x10
                    t = self.send(t, order(value))
                else:
                    if self.fault == "collide" and seen == 0 and i == 0:
                        self.out += [(t + 50, 0), (t + 60, 1)]
                    seen += i == 0
                    value, t = self.receive(t, seen == reads and i == len(data) - 1)
                    self.rx.append((t - 2 * BIT, value))
        if self.fault == "tail":
            self.bit(t, 1)
        if self.fault == "late3":
            k = 18 + (len(self.out) - 18) // 2   # an edge after the enter sequence
            self.out[k] = (self.out[k][0] + 3, self.out[k][1])


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
    with open(argv[argv.index("-stimulus") + 1]) as f:
        line = Line(f.read())
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        ops = ops_of(words)
        host = Host(line, fault)
        first = {"entry400": 400, "entry4000": 4000, "entry399": 399, "entry4001": 4001}.get(fault, 1000)
        host.run(ops, first)
    except ValueError as e:
        sys.stderr.write("ideal_wave: %s\n" % e)
        return 3
    rx = host.rx
    if fault == "rxwrong" and rx:
        rx[-1] = (rx[-1][0], rx[-1][1] ^ 1)
    if fault == "rxextra" and rx:
        rx.append((rx[-1][0] + 1, rx[-1][1]))
    if fault == "rxlow":
        rx = [(c, v << 8) for c, v in rx]
    events = [(c, "pins %d %02x" % (c, 0xFE | lv)) for c, lv in sorted(host.out) if c < cycles]
    events += [(c, "rx %d %d" % (c, v)) for c, v in rx if c < cycles]
    events.sort(key=lambda e: e[0])
    sys.stdout.write("pins 0 ff\n" + "".join(text + "\n" for _, text in events))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
