#!/usr/bin/env python3
"""An ideal SDA 2506 host, as a waveform and RX words: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints the pins' changes ("pins CYCLE XX") and the words a host would
get back ("rx CYCLE WORD"), in the simulator's format. It reads the TX words
back into operations by the task sheet's rules in its own code, and exits
with an error (which the judge counts as a failure) if a word is not one the
sheet defines. The bytes it returns are read from the stimulus file, the
scripted EEPROM, at the time a host would sample DATA, so they come from the
waveform, not from the judge's memory model.

It is written apart from accept.py on purpose and works differently: it
walks time slot by slot, where accept.py lists every edge's place from
formulas.

--fault breaks the result in one named way (FAULTS below), to show that the
judge fails what it should. A few names are not faults but results at the
very edge of what the task sheet allows, which must still pass."""
import sys

SLOT = 200          # cycles in one clock slot (20 us at 10 MHz)
UP, DOWN = 50, 150  # CLK rises and falls this far into a slot
START = 2000        # first operation's first slot
PROGRAM = 200_000   # 20 ms
GAP = 150           # CE rise to the next operation's first slot

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: CLK low at cycle 10, DATA changed at each slot boundary"),
    "jitter2":     (True,  "every CLK and CE edge 2 cycles off its place, alternately late and early"),
    "datawindow":  (True,  "every DATA change at the very edge of its window, alternately 20 early and 20 late"),
    "clk1000":     (True,  "CLK brought low at cycle 1000 (the limit)"),
    "sample_late": (True,  "each read bit sampled 9 cycles after the next CLK fall (the last moment)"),
    "flipbit":     (False, "one data bit of the first write inverted"),
    "addrmsb":     (False, "addresses sent most significant bit first"),
    "late3":       (False, "one CLK edge 3 cycles late"),
    "early3":      (False, "one CE edge 3 cycles early"),
    "setup21":     (False, "the first DATA change 21 cycles after its slot boundary (outside the +-20 window)"),
    "slow201":     (False, "slots of 201 cycles: the error adds up"),
    "shortprog":   (False, "CE rises 3 cycles early after a write or erase (programming time short)"),
    "nostart":     (False, "no start pulse after a write or erase command"),
    "selhigh":     (False, "DATA high at the fall of CE after a write command (an erase to the EEPROM)"),
    "ninepulse":   (False, "nine CLK pulses in each read instead of eight"),
    "holdlow":     (False, "DATA left driven low (CB = 0) through each read"),
    "clk1001":     (False, "CLK brought low at cycle 1001"),
    "tail":        (False, "one more CLK pulse 1150 cycles after the last CE rise"),
    "dropop":      (False, "the last operation is not done"),
    "extraop":     (False, "the last operation is done twice"),
    "sample_early": (False, "each read bit sampled before the EEPROM has put it out (old bit)"),
    "rxflip":      (False, "one bit of the last RX word inverted"),
    "rxextra":     (False, "one more RX word after the last"),
    "rxhigh":      (False, "RX words carry the address in bits 14..8"),
}


def operations(words):
    """The operations a word stream asks for, by the task sheet's rules."""
    out = []
    for w in words:
        if not 0 <= w <= 0xFFFF:
            raise ValueError("word %r is not 16 bits" % w)
        addr = (w >> 8) & 0x7F
        if w & 0x8000:
            out.append(("write", addr, w & 0xFF))
        elif w & 0xFF == 0:
            out.append(("read", addr, None))
        elif w & 0xFF == 1:
            out.append(("erase", addr, None))
        else:
            raise ValueError("word 0x%04x is not a read, erase or write" % w)
    if not out:
        raise ValueError("no words")
    return out


def load_stimulus(path):
    pts = []
    with open(path) as f:
        for line in f:
            if line.strip():
                c, v = line.split()
                pts.append((int(c), int(v, 16)))
    return pts


def data_from_eeprom(stim, t):
    """The EEPROM's drive of P1 at cycle t (1 = released)."""
    v = 0xFF
    for c, x in stim:
        if c > t:
            break
        v = x
    return (v >> 1) & 1


def run(ops, stim, fault):
    ev = []        # (cycle, pin, level)
    rx = []        # (cycle, word)
    count = [0]

    def edge(c, pin, level):
        n = count[0]
        count[0] += 1
        if fault == "jitter2":
            c += 2 if n % 2 else -2
        ev.append((c, pin, level))

    def data(c, level):
        if fault == "setup21" and not any(e[1] == 1 for e in ev):
            c += 21
        ev.append((c, 1, level))

    slot = 201 if fault == "slow201" else SLOT
    ev.append((1000 if fault == "clk1000" else 1001 if fault == "clk1001" else 10, 0, 0))
    if fault == "dropop":
        ops = ops[:-1]
    if fault == "extraop":
        ops = ops + ops[-1:]
    t = START
    first_write = True
    dchange = [0]

    def boundary(c):
        n = dchange[0]
        dchange[0] += 1
        if fault == "datawindow":
            return c + (20 if n % 2 else -20)
        return c

    reads_done = 0
    for k, (kind, addr, value) in enumerate(ops):
        abits = [(addr >> i) & 1 for i in range(7)]
        if fault == "addrmsb":
            abits = abits[::-1]
        if kind == "write":
            dbits = [(value >> i) & 1 for i in range(8)]
            if fault == "flipbit" and first_write:
                dbits[3] ^= 1
            first_write = False
            bits = dbits + abits + [1]
        else:
            bits = abits + [1 if kind == "erase" else 0]
        level = 1
        for j, b in enumerate(bits):
            if b != level:
                data(boundary(t), b)
                level = b
            edge(t + UP, 0, 1)
            edge(t + DOWN, 0, 0)
            t += slot
        if kind == "read":
            sel = 0 if fault == "holdlow" else 1
        else:
            sel = 1 if (kind == "erase" or fault == "selhigh") else 0
        if sel != level:
            data(boundary(t), sel)
            level = sel
        late = 3 if (fault == "late3" and k == len(ops) - 1) else 0
        edge(t + UP, 2, 0)
        t += slot
        if kind == "read":
            byte = 0
            pulses = 9 if fault == "ninepulse" else 8
            for i in range(pulses):
                edge(t + UP + late, 0, 1)
                edge(t + DOWN, 0, 0)
                late = 0
                if i < 8:
                    when = t + DOWN + slot + 9 if fault == "sample_late" else t + DOWN + 100
                    if fault == "sample_early":
                        when = t + DOWN + 5
                    if i == 7 and fault == "sample_late":
                        when = t + DOWN + 109     # bit 7: before the EEPROM lets go after CE
                    line = data_from_eeprom(stim, when) & level
                    byte |= line << i
                t += slot
            ce_rise = t + UP
            reads_done += 1
            word = byte | (addr << 8 if fault == "rxhigh" else 0)
            rx.append((ce_rise + 20, word))
        else:
            if fault != "nostart":
                edge(t + UP + late, 0, 1)
                edge(t + DOWN, 0, 0)
            t += slot
            if level != 1:
                data(boundary(t), 1)
                level = 1
            ce_rise = t + PROGRAM - (3 if fault == "shortprog" else 0)
        if fault == "early3" and k == 0:
            ev.append((ce_rise - 3, 2, 1))
            count[0] += 1
        else:
            edge(ce_rise, 2, 1)
        t = ce_rise + GAP
    if fault == "tail":
        ev += [(t + 1000, 0, 1), (t + 1100, 0, 0)]
    if fault == "rxflip" and rx:
        rx[-1] = (rx[-1][0], rx[-1][1] ^ 0x10)
    if fault == "rxextra" and rx:
        rx.append((rx[-1][0] + 10, rx[-1][1]))
    return ev, rx


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
    stim = load_stimulus(argv[argv.index("-stimulus") + 1])
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        ops = operations(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    ev, rx = run(ops, stim, fault)
    lines = [(0, 0, "pins 0 ff")]
    pins = 0xFF
    ev.sort()
    i = 0
    while i < len(ev):
        c = ev[i][0]
        while i < len(ev) and ev[i][0] == c:
            _, p, v = ev[i]
            pins = (pins & ~(1 << p)) | (v << p)
            i += 1
        if c < cycles:
            lines.append((c, 0, "pins %d %02x" % (c, pins)))
    for c, w in rx:
        if c < cycles:
            lines.append((c, 1, "rx %d %d" % (c, w)))
    lines.sort()
    sys.stdout.write("".join(l + "\n" for _, _, l in lines))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
