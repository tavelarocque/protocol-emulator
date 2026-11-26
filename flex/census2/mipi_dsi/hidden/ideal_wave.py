#!/usr/bin/env python3
"""An ideal MIPI DSI low-power (escape mode, LPDT) transmitter, as a
waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints the output register's changes in the simulator's format
("pins CYCLE XX"), starting at "pins 0 ff" as after reset. P0 is Dp and P1
is Dn of data lane 0, P2 and P3 the clock lane. The words it takes are the
task sheet's: per packet the data identifier (bit 8 set for a long packet),
the two parameters or the word count, and a long packet's payload bytes. It
reads them back into packets in its own way (packets_of below, written apart
from accept.py's tx_words), forms each packet's ECC and checksum in its own
way (from the specification's parity equations, and a CRC computed most
significant bit first on bit-reversed bytes, where accept.py uses a column
table and a reflected CRC), and exits with an error, which the judge counts
as a failure, if the stream is not what the sheet says.

It is written apart from accept.py on purpose, and works differently: it
schedules rises and falls of the single lines (a mark raises Dp for a 1 or
Dn for a 0, the space after it lowers the same line again), where accept.py
lists the lane's states.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. Several names are not faults but waveforms
at the very edge of what the task sheet allows, which must still pass."""
import sys

LONG = 1 << 8      # task sheet: this bit of a packet's first word marks a long packet

# The ECC's parity bits, as the DSI specification lists them: P(j) is the
# exclusive or of these bits of the 24-bit header D[23:0].
PARITY = [
    [0, 1, 2, 4, 5, 7, 10, 11, 13, 16, 20, 21, 22, 23],
    [0, 1, 3, 4, 6, 8, 10, 12, 14, 17, 20, 21, 22, 23],
    [0, 2, 3, 5, 6, 9, 11, 12, 15, 18, 20, 21, 22],
    [1, 2, 3, 7, 8, 9, 13, 14, 15, 19, 20, 21, 23],
    [4, 5, 6, 7, 8, 9, 16, 17, 18, 19, 20, 22, 23],
    [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23],
]
P_DP, P_DN, P_CLKP, P_CLKN, P_SPARE = 0, 1, 2, 3, 4

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: states of 5 cycles, first transmission at cycle 6000, Stop states of 200"),
    "fast":        (True,  "every state 3 cycles, first at cycle 5000, Stop states of 3 (all the limits)"),
    "slow":        (True,  "every state 50 cycles, first at cycle 10000, Stop states of 1000 (all the limits)"),
    "uneven":      (True,  "state lengths scattered from 3 to 50 cycles"),
    "spare":       (True,  "P4, which the sheet leaves unused, toggling all through the run"),
    "flipbit":     (False, "one bit of the last byte of the last packet inverted on the wire"),
    "badecc":      (False, "ECC bit P2 inverted in every packet"),
    "eccrev":      (False, "the six ECC bits in reverse order (P0 in bit 5)"),
    "eccp6":       (False, "ECC bits P6 and P7 set to 1 instead of 0"),
    "nocheck":     (False, "the checksum of every long packet left out"),
    "badcheck":    (False, "one bit of every long packet's checksum inverted"),
    "checkswap":   (False, "the checksum sent high byte first"),
    "checkinit0":  (False, "the checksum's CRC started from 0 instead of 0xFFFF"),
    "checkinv":    (False, "the checksum inverted (as CRC-16/X-25 would send it)"),
    "wcmissing":   (False, "a long packet's word count bytes left out of the header"),
    "msbfirst":    (False, "bytes sent most significant bit first"),
    "cmdrev":      (False, "the LPDT command sent in reverse, 1,0,0,0,0,1,1,1"),
    "ulps":        (False, "the ULPS entry command 0,0,0,1,1,1,1,0 instead of LPDT"),
    "bta":         (False, "a turnaround request's entry (LP-10, LP-00, LP-10, LP-00) instead of escape entry"),
    "nomark1":     (False, "exit straight from LP-00 to LP-11, no Mark-1"),
    "nospace":     (False, "no space between two marks of different value (Dp and Dn change together)"),
    "merged":      (False, "all of a run's packets in one transmission (the sheet asks one per packet)"),
    "partial":     (False, "the last bit of the last transmission is not sent"),
    "short2":      (False, "one state of the first transmission lasts 2 cycles"),
    "long51":      (False, "one state of the first transmission lasts 51 cycles"),
    "start4999":   (False, "first transmission at cycle 4999"),
    "start10001":  (False, "first transmission at cycle 10001"),
    "gap2":        (False, "Stop states of 2 cycles between transmissions"),
    "gap1001":     (False, "Stop states of 1001 cycles between transmissions"),
    "clkglitch":   (False, "CLKN low for 10 cycles in the middle of the run"),
    "clklow":      (False, "the whole lane idle low from cycle 1: clock lane LP-00, data lane LP-00 between"),
    "glitch":      (False, "Dn low for one cycle in the first Stop state after a transmission"),
    "tail":        (False, "Dp low for 5 cycles, 1000 cycles after the last transmission"),
    "droptx":      (False, "the last transmission is not sent"),
    "extratx":     (False, "the last transmission is sent twice"),
}


def reverse8(b):
    return int("{:08b}".format(b)[::-1], 2)


def ecc_of(header, fault):
    d = header[0] | header[1] << 8 | header[2] << 16
    e = 0
    for j, bits in enumerate(PARITY):
        parity = 0
        for i in bits:
            parity ^= (d >> i) & 1
        e |= parity << j
    if fault == "badecc":
        e ^= 0x04
    if fault == "eccrev":
        e = int("{:06b}".format(e)[::-1], 2)
    if fault == "eccp6":
        e |= 0xC0
    return e


def checksum_of(payload, fault):
    """CRC-16-CCITT (x^16 + x^12 + x^5 + 1) computed most significant bit
    first on bit-reversed bytes, then reversed: the same as DSI's reflected
    CRC, computed the other way round."""
    c = 0 if fault == "checkinit0" else 0xFFFF
    for b in payload:
        c ^= reverse8(b) << 8
        for _ in range(8):
            c = ((c << 1) ^ 0x1021) & 0xFFFF if c & 0x8000 else (c << 1) & 0xFFFF
    c = int("{:016b}".format(c)[::-1], 2)
    if fault == "badcheck":
        c ^= 0x0100
    if fault == "checkinv":
        c ^= 0xFFFF
    return c


def packet_bytes(packet, fault):
    """The bytes of one packet on the wire."""
    kind, di, second, payload = packet
    header = [di, second & 0xFF, second >> 8]
    out = header + [ecc_of(header, fault)]
    if kind == "long":
        if fault == "wcmissing":
            out = [di, ecc_of(header, fault)]
        c = checksum_of(payload, fault)
        tail = [] if fault == "nocheck" else [c >> 8, c & 0xFF] if fault == "checkswap" else [c & 0xFF, c >> 8]
        out += payload + tail
    return out


def bits_of(data, fault):
    cmd = {"cmdrev": [1, 0, 0, 0, 0, 1, 1, 1], "ulps": [0, 0, 0, 1, 1, 1, 1, 0]}.get(
        fault, [1, 1, 1, 0, 0, 0, 0, 1])
    order = range(7, -1, -1) if fault == "msbfirst" else range(8)
    return cmd + [(b >> k) & 1 for b in data for k in order]


class Line:
    """Events (cycle, pin, level), and a clock for state lengths."""

    def __init__(self, fault):
        self.fault = fault
        self.events = []
        self.n = 0          # states scheduled so far in this run
        self.seed = 12345

    def length(self):
        f = self.fault
        self.n += 1
        if f == "fast":
            return 3
        if f == "slow":
            return 50
        if f == "uneven":
            self.seed = (self.seed * 1103515245 + 12345) % (1 << 31)
            return 3 + (self.seed >> 8) % 48
        if f == "short2" and self.n == 30:
            return 2
        if f == "long51" and self.n == 30:
            return 51
        return 5

    def at(self, t, pin, level):
        self.events.append((t, pin, level))


def schedule(transmissions, fault="none"):
    """The events of one run, and the cycle the last transmission ended."""
    ln = Line(fault)
    t = {"fast": 5000, "slow": 10000, "start4999": 4999, "start10001": 10001}.get(fault, 6000)
    gap = {"fast": 3, "slow": 1000, "gap2": 2, "gap1001": 1001}.get(fault, 200)
    txs = [packet_bytes(p, fault) for p in transmissions]
    if fault == "flipbit":
        txs[-1][-1] ^= 0x04
    if fault == "droptx":
        txs = txs[:-1]
    if fault == "extratx":
        txs = txs + [txs[-1]]
    if fault == "merged":
        txs = [[b for d in txs for b in d]]
    if fault == "clklow":
        ln.at(1, P_CLKP, 0)
        ln.at(1, P_CLKN, 0)
        ln.at(1, P_DP, 0)
        ln.at(1, P_DN, 0)
        ln.at(t - 100, P_DP, 1)
        ln.at(t - 100, P_DN, 1)
    ends = []
    for index, data in enumerate(txs):
        # Escape mode entry: LP-11 > LP-10 > LP-00 > LP-01 > LP-00.
        entry = [(P_DN, 0), (P_DP, 0), (P_DP, 1), (P_DP, 0)] if fault == "bta" else \
                [(P_DN, 0), (P_DP, 0), (P_DN, 1), (P_DN, 0)]
        for pin, level in entry:
            ln.at(t, pin, level)
            t += ln.length()
        bits = bits_of(data, fault)
        if fault == "partial" and index == len(txs) - 1:
            bits = bits[:-1]
        skipped = False
        for k, b in enumerate(bits):
            pin = P_DP if b else P_DN
            ln.at(t, pin, 1)                      # the mark
            t += ln.length()
            ln.at(t, pin, 0)                      # the space
            if (fault == "nospace" and index == 0 and not skipped and k >= 8
                    and k + 1 < len(bits) and bits[k + 1] != b):
                skipped = True                    # no space: the next mark rises in this cycle
                continue
            t += ln.length()
        if fault == "nomark1":
            ln.at(t, P_DP, 1)
            ln.at(t, P_DN, 1)
        else:
            ln.at(t, P_DP, 1)                     # Mark-1
            t += ln.length()
            ln.at(t, P_DN, 1)                     # Stop state
        ends.append(t)
        if fault == "glitch" and index == 0:
            ln.at(t + 20, P_DN, 0)
            ln.at(t + 21, P_DN, 1)
        if fault == "clklow" and index < len(txs) - 1:
            ln.at(t + 10, P_DP, 0)
            ln.at(t + 10, P_DN, 0)
            ln.at(t + gap - 10, P_DP, 1)
            ln.at(t + gap - 10, P_DN, 1)
        t += gap
    if fault == "tail":
        ln.at(ends[-1] + 1000, P_DP, 0)
        ln.at(ends[-1] + 1005, P_DP, 1)
    if fault == "clkglitch":
        mid = ends[0] // 2
        ln.at(mid, P_CLKN, 0)
        ln.at(mid + 10, P_CLKN, 1)
    if fault == "spare":
        for c in range(50, ends[-1] + 500, 100):
            ln.at(c, P_SPARE, 0)
            ln.at(c + 50, P_SPARE, 1)
    return ln.events


def pins_text(transmissions, cycles, fault="none"):
    """What pe_sim would print: the register at cycle 0, then every change."""
    reg = 0xFF
    lines = ["pins 0 ff"]
    by_cycle = {}
    for c, pin, level in schedule(transmissions, fault):
        by_cycle.setdefault(c, []).append((pin, level))
    for c in sorted(by_cycle):
        new = reg
        for pin, level in by_cycle[c]:
            new = (new & ~(1 << pin)) | (level << pin)
        if new != reg and c < cycles:
            lines.append("pins %d %02x" % (c, new))
        reg = new
    return "\n".join(lines) + "\n"


def transitions(transmissions, fault="none"):
    """Cycles at which P0..P3 change, for the RATE line."""
    reg, out = 0xFF, []
    by_cycle = {}
    for c, pin, level in schedule(transmissions, fault):
        by_cycle.setdefault(c, []).append((pin, level))
    for c in sorted(by_cycle):
        new = reg
        for pin, level in by_cycle[c]:
            new = (new & ~(1 << pin)) | (level << pin)
        if (new ^ reg) & 0x0F:
            out.append(c)
        reg = new
    return out


def packets_of(words):
    """The packets a word stream asks for, by the task sheet's rules:
    (kind, data identifier, second word, payload)."""
    out, k = [], 0
    while k < len(words):
        first = words[k]
        if first >> 9:
            raise ValueError("first word 0x%04x has a bit above bit 8 set" % first)
        if k + 1 >= len(words):
            raise ValueError("a packet with no second word")
        second = words[k + 1]
        k += 2
        if first & LONG:
            if second > 26:
                raise ValueError("word count %d" % second)
            payload = words[k:k + second]
            if len(payload) != second or any(b >> 8 for b in payload):
                raise ValueError("bad payload words")
            k += second
            out.append(("long", first & 0xFF, second, payload))
        else:
            out.append(("short", first & 0xFF, second, []))
    if not out or len(out) > 6:
        raise ValueError("%d packets" % len(out))
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
        txs = packets_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(txs, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
