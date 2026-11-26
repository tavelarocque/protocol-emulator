#!/usr/bin/env python3
"""An ideal MIPI RFFE master, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints what pe_sim would: the chip's output register ("pins CYCLE XX",
P0 = SCLK, P1 = SDATA, every other bit 1) at cycle 0 and at every change,
and the words it pushes ("rx CYCLE WORD", decimal). It reads the task
sheet's TX words back into sequences in its own way (sequences_of below,
written apart from accept.py) and exits with an error, which the judge
counts as a failure, if they break the sheet's rules. It does not know the
bytes a read returns: it reads them off the wire, its own open-drain output
AND the stimulus file, one cycle before each falling edge of SCLK, as a
master would.

It is written apart from accept.py on purpose, and works differently: it
codes the command byte from bit-string prefixes and counts ones in strings,
and it paints per-cycle level arrays, where accept.py builds integers and
lists of changes. Its ideal also sits elsewhere in what the sheet allows
(lines low at cycle 3, SDATA moved 1 cycle after each rising edge, SDATA let
go 18 cycles after the turnaround clock's place and taken back 10 cycles
after the last bus park's place).

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. Some names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

T, HIGH, FIRST, IDLE = 20, 10, 400, 6
KINDS = ("R0W", "RW", "RR", "ERW", "ERR", "ERWL", "ERRL")
PREFIX = {"R0W": "1", "RW": "010", "RR": "011", "ERW": "0000", "ERR": "0010",
          "ERWL": "00110", "ERRL": "00111"}
READ = ("RR", "ERR", "ERRL")

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":           (True,  "ideal: lines low at cycle 3, SDATA moved 1 cycle after each rising edge"),
    "jitter2":        (True,  "SCLK and SSC edges 2 cycles off, alternately late and early (the limit)"),
    "late_data":      (True,  "the master moves SDATA exactly 3 cycles before SCLK falls (the limit)"),
    "early_turn":     (True,  "SDATA let go at the hold's first cycle, taken back as the slave's bus park starts"),
    "late_turn":      (True,  "SDATA let go as the slave's first bit starts, taken back as the slave lets go"),
    "low100":         (True,  "SCLK and SDATA driven low at cycle 100 (the limit)"),
    "flipbit":        (False, "one bit of the last data byte written inverted"),
    "lsbfirst":       (False, "data bytes written least significant bit first"),
    "sa_lsbfirst":    (False, "the slave address sent least significant bit first"),
    "evenparity":     (False, "even parity on data and address frames"),
    "cmdparity_nosa": (False, "the command frame's parity left out the slave address (as the decoder checks it)"),
    "bc_n":           (False, "byte count field n where RFFE wants n - 1"),
    "rx_flip":        (False, "one bit of one RX word wrong"),
    "rx_extra":       (False, "one RX word too many"),
    "rx_missing":     (False, "the last RX word not pushed"),
    "late3":          (False, "one SCLK rising edge 3 cycles late"),
    "period21":       (False, "SCLK period 21 cycles"),
    "data_low_phase": (False, "the master moves SDATA 2 cycles after SCLK falls, while it is low"),
    "setup2":         (False, "the master moves SDATA 2 cycles before SCLK falls"),
    "double_change":  (False, "a 2-cycle low glitch on SDATA inside the high phase of a master's 1"),
    "no_release":     (False, "the chip never lets go of SDATA in a read"),
    "contention":     (False, "the chip pulls SDATA low for 2 cycles while the slave sends a 1"),
    "hold_on_zero":   (False, "the chip pulls SDATA low through a bit the slave sends as 0 (the line does not change)"),
    "early_release":  (False, "SDATA let go 1 cycle after the turnaround clock falls, before the slave holds it"),
    "late_retake":    (False, "SDATA taken back 1 cycle after the slave lets go"),
    "ssc_short":      (False, "SDATA high for 10 cycles in the SSC, not 20"),
    "ssc_missing":    (False, "no SSC before the last sequence"),
    "seq_late":       (False, "7 idle SCLK periods between sequences, not 6"),
    "extra_clock":    (False, "one SCLK pulse too many after the last sequence"),
    "no_bp":          (False, "writes end without their bus-park clock"),
    "idle_high":      (False, "SDATA let go (high) 40 cycles after each write's bus park"),
    "low101":         (False, "SCLK and SDATA driven low at cycle 101"),
    "drop_seq":       (False, "the last sequence not sent"),
}


def bits(value, width, lsb_first=False):
    s = format(value, "0%db" % width)
    return s[::-1] if lsb_first else s


def with_parity(s, even=False):
    ones = s.count("1")
    p = "1" if (ones % 2 == 0) != even else "0"
    return s + p


def sequences_of(words):
    """The sequences a word stream asks for, by the task sheet's rules."""
    out, k = [], 0
    while k < len(words):
        h = words[k]
        k += 1
        if h >> 13:
            raise ValueError("header 0x%04x has a bit above bit 12 set" % h)
        n, kind, sa = (h >> 8) & 31, (h >> 4) & 15, h & 15
        if kind >= len(KINDS):
            raise ValueError("header 0x%04x has kind %d" % (h, kind))
        name = KINDS[kind]
        most = {"ERW": 16, "ERR": 16, "ERWL": 8, "ERRL": 8}.get(name, 1)
        if not 1 <= n <= most:
            raise ValueError("header 0x%04x asks for %d bytes" % (h, n))
        if name in READ and sa == 0:
            raise ValueError("a read from the broadcast address")
        addr = None
        if name != "R0W":
            addr = words[k]
            k += 1
            limit = {"RW": 32, "RR": 32, "ERW": 256, "ERR": 256}.get(name, 65536)
            if addr >= limit:
                raise ValueError("address 0x%x too wide for %s" % (addr, name))
        data = []
        if name not in READ:
            data = words[k:k + n]
            k += n
            if len(data) != n or any(d >= (128 if name == "R0W" else 256) for d in data):
                raise ValueError("bad data words for %s" % name)
        out.append((name, sa, n, addr, data))
    if not out:
        raise ValueError("no words")
    return out


def plan(seq, fault, is_last_write):
    """The clocks of one sequence as a string: '0'/'1' for a master bit,
    's' for a slave bit, 'B' for the master's turnaround bus park, 'P' for
    the slave's last bus park."""
    name, sa, n, addr, data = seq
    lsb = fault == "lsbfirst"
    if name == "R0W":
        cmd = PREFIX[name] + bits(data[0], 7, lsb)
    elif name in ("RW", "RR"):
        cmd = PREFIX[name] + bits(addr, 5)
    else:
        bc = n if fault == "bc_n" else n - 1
        cmd = PREFIX[name] + bits(bc % (16 if name in ("ERW", "ERR") else 8), 8 - len(PREFIX[name]))
    sab = bits(sa, 4, fault == "sa_lsbfirst")
    if fault == "cmdparity_nosa":
        c = sab + cmd + with_parity(cmd)[-1]
    else:
        c = with_parity(sab + cmd)
    even = fault == "evenparity"
    if name in ("ERW", "ERR"):
        c += with_parity(bits(addr, 8), even)
    elif name in ("ERWL", "ERRL"):
        c += with_parity(bits(addr >> 8, 8), even) + with_parity(bits(addr & 255, 8), even)
    if name in READ:
        return c + "B" + "s" * (9 * n) + "P"
    if name != "R0W":
        for i, d in enumerate(data):
            if fault == "flipbit" and is_last_write and i == n - 1:
                d ^= 0x04
            c += with_parity(bits(d, 8, lsb), even)
    elif fault == "flipbit" and is_last_write:
        c = c[:-2] + ("1" if c[-2] == "0" else "0") + c[-1]
    return c if fault == "no_bp" else c + "0"


def run(words, stim_lines, cycles, fault):
    seqs = sequences_of(words)
    if fault == "drop_seq":
        seqs = seqs[:-1]
    period = 21 if fault == "period21" else T
    idle = 7 if fault == "seq_late" else IDLE
    low_at = {"low100": 100, "low101": 101}.get(fault, 3)
    n = cycles + 20000      # room for a fault that runs past the end; only cycles < `cycles` are printed
    sclk = [1] * n
    sd = [1] * n

    def paint(arr, a, b, v):
        for c in range(max(a, 0), min(b, n)):
            arr[c] = v

    paint(sclk, low_at, n, 0)
    paint(sd, low_at, n, 0)
    stim = [1] * n
    pts = sorted((int(c), int(h, 16)) for c, h in (l.split() for l in stim_lines if l.strip()))
    for k, (c, h) in enumerate(pts):
        paint(stim, c, pts[k + 1][0] if k + 1 < len(pts) else n, (h >> 1) & 1)
    writes = [i for i, s in enumerate(seqs) if s[0] not in READ]
    rx = []
    start, edge_no = FIRST, 0
    for i, seq in enumerate(seqs):
        p = plan(seq, fault, bool(writes) and i == writes[-1])
        slot_end = n if i == len(seqs) - 1 else min(n, start + period * (2 + len(p) + idle))
        if not (fault == "ssc_missing" and i == len(seqs) - 1):
            a, b = start, start + T
            if fault == "jitter2":
                a, b = a + 2, b - 2
            if fault == "ssc_short":
                b = start + 10
            paint(sd, a, b, 1)
        level = 0
        got = ""
        for j, ch in enumerate(p):
            r = start + 2 * T + period * j
            f = r + HIGH
            if fault == "jitter2":
                r += 2 if edge_no % 2 else -2
                f += -2 if edge_no % 2 else 2
            if fault == "late3" and i == len(seqs) - 1 and j == 5:
                r += 3
            edge_no += 1
            paint(sclk, r, f, 1)
            if ch in "01B":
                v = 0 if ch == "B" else int(ch)
                at = r + 1
                if fault == "late_data":
                    at = f - 3
                elif fault == "setup2":
                    at = f - 2
                elif fault == "data_low_phase":
                    at = r - period + HIGH + 2 if j else r + 1
                last = ch == "B" or j == len(p) - 1
                paint(sd, at, slot_end if last else at + 2 * period, v)
                if fault == "double_change" and v == 1 and level == 1 and j > 3:
                    paint(sd, r + 1, r + 3, 0)
                    fault = "double_change done"
                level = v
            if ch == "B":
                rel = {"early_turn": r + 12, "late_turn": r + T + 4,
                       "early_release": f + 1}.get(fault, r + 18)
                if fault != "no_release":
                    paint(sd, rel, slot_end, 1)
            if ch == "s":
                got += str(sd[f - 1] & stim[f - 1])
                if fault == "hold_on_zero" and stim[r + 5] == 0:
                    paint(sd, r + 4, r + T + 4, 0)
                    fault = "hold_on_zero done"
                if fault == "contention" and stim[r + 5] == 1:
                    paint(sd, r + 5, r + 7, 0)
                    fault = "contention done"
                if len(got) == 9:
                    word = int(got[:8], 2)
                    rx.append((f + 4, word))
                    got = ""
            if ch == "P":
                back = {"early_turn": r + 4, "late_turn": r + 14, "late_retake": r + 15}.get(fault, r + 10)
                paint(sd, back, slot_end, 0)
        end = start + 2 * T + period * len(p)
        if fault == "idle_high" and seq[0] not in READ:
            paint(sd, end - T + HIGH + 40, start + period * (len(p) + 2 + idle) - 5, 1)
        if fault == "extra_clock" and i == len(seqs) - 1:
            paint(sclk, end + 40, end + 50, 1)
        start += period * (2 + len(p) + idle)
    if fault == "rx_flip" and rx:
        rx[0] = (rx[0][0], rx[0][1] ^ 0x10)
    if fault == "rx_extra":
        rx.append((cycles - 10, 0))
    if fault == "rx_missing" and rx:
        rx.pop()
    out = ["pins 0 ff"]
    last = 0xFF
    events = []
    rx = [(c, w) for c, w in rx if c < cycles]
    for c in range(1, cycles):
        v = 0xFC | sclk[c] | (sd[c] << 1)
        if v != last:
            events.append((c, "pins %d %02x" % (c, v)))
            last = v
    events += [(c, "rx %d %d" % (c, w)) for c, w in rx]
    events.sort(key=lambda e: e[0])
    return "\n".join(out + [e[1] for e in events]) + "\n"


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    need = ("-tx", "-stimulus", "-cycles")
    if fault not in FAULTS or argv[:1] != ["run"] or any(f not in argv for f in need):
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(line, 0) for line in f if line.strip()]
    with open(argv[argv.index("-stimulus") + 1]) as f:
        stim = f.read().splitlines()
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        text = run(words, stim, cycles, fault)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
