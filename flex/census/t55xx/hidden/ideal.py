#!/usr/bin/env python3
"""An ideal T55xx reader downlink, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"). It
reads the TX words back into commands by the task sheet's rules, in its own
code (commands_of below, written apart from accept.py's tx_words), and
exits with an error, which the judge counts as a failure, if the words are
not what the sheet says.

It works differently from accept.py on purpose: it lays the waveform down
half period by half period, as a reader would, where accept.py measures
intervals between edges. --fault breaks the waveform in one named way. A few
names are waveforms at the very edge of what the task sheet allows, which
must still pass.

Times: core clock 10 MHz, one field clock (FC) = 80 cycles, half a carrier
period = 40 cycles."""
import sys

HALF = 40
FC = 80

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":         (True,  "ideal: first change at cycle 200, 0 = 47 halves, 1 = 111 halves, write gap 12 FC, start gap 20 FC, 300 halves before the first command, 401 after each"),
    "slowcarrier":  (True,  "every half period 42 cycles (the limit)"),
    "fastcarrier":  (True,  "every half period 38 cycles (the limit)"),
    "shortest":     (True,  "0 = 1440 cycles, 1 = 4000, gaps of 800, lead and tail of exactly 8000 (all limits)"),
    "longest":      (True,  "0 = 2320 cycles, 1 = 4880, write gaps 2400, start gaps 4000, lead 80000 (all limits)"),
    "freeze":       (True,  "the line stops 401 halves after the last command's last gap"),
    "flipbit":      (False, "one data bit of the last command inverted"),
    "lsbfirst":     (False, "data sent least significant bit first"),
    "droplock":     (False, "the lock bit left out of every write"),
    "half43":       (False, "every half period 43 cycles"),
    "half37":       (False, "every half period 37 cycles"),
    "glitch":       (False, "one half period of 10 cycles in the lead-in"),
    "zero1439":     (False, "0 bits of 1439 cycles (the decoder still reads 0)"),
    "one4881":      (False, "1 bits of 4881 cycles (the decoder still reads 1)"),
    "wgap799":      (False, "write gaps of 799 cycles (the decoder still sees gaps)"),
    "wgap2401":     (False, "write gaps of 2401 cycles"),
    "sgap4001":     (False, "start gaps of 4001 cycles"),
    "gaphigh":      (False, "gaps held high instead of low"),
    "tail7999":     (False, "the line stops 7999 cycles after the last gap (the decoder still ends the command)"),
    "lead7999":     (False, "start gap 7999 cycles after the previous command's last gap"),
    "lead80001":    (False, "start gap 80001 cycles after the previous command"),
    "late":         (False, "first change of P0 at cycle 401"),
    "dropcmd":      (False, "the last command is not sent"),
    "extracmd":     (False, "the last command is sent twice"),
    "nostartgap":   (False, "no start gap: the first bit's on-time is measured from carrier start"),
}


def commands_of(words):
    """The commands a word stream asks for, by the task sheet's rules, as
    lists of bits in the order they go on the line."""
    out, i = [], 0
    while i < len(words):
        h = words[i]
        i += 1
        if h >> 8:
            raise ValueError("header 0x%04x has a bit above bit 7 set" % h)
        op = [(h >> 1) & 1, h & 1]
        if h & 0x80:
            if h != 0x80:
                raise ValueError("reset header 0x%04x is not 0x0080" % h)
            out.append(op)
            continue
        if op[0] != 1:
            raise ValueError("write header 0x%04x has opcode %d%d" % (h, op[0], op[1]))
        need = 4 if h & 0x40 else 2
        if i + need > len(words):
            raise ValueError("command cut short")
        body = words[i:i + need]
        i += need
        if any(w >> 16 for w in body):
            raise ValueError("a word is wider than 16 bits")
        bits = list(op)
        if h & 0x40:
            pwd = (body[0] << 16) | body[1]
            bits += [(pwd >> (31 - k)) & 1 for k in range(32)]
            body = body[2:]
        bits.append((h >> 2) & 1)
        data = (body[0] << 16) | body[1]
        bits += [(data >> (31 - k)) & 1 for k in range(32)]
        bits += [(h >> 5) & 1, (h >> 4) & 1, (h >> 3) & 1]
        out.append(bits)
    if not out:
        raise ValueError("no words")
    return out


def carrier_half(fault):
    return {"slowcarrier": 42, "fastcarrier": 38, "half43": 43, "half37": 37}.get(fault, HALF)


def plan(commands, fault):
    """The waveform's pieces in order: ('lead', cycles), ('gap', cycles),
    ('bit', cycles), ('tail', cycles), then ('stop',) or ('forever',)."""
    half = carrier_half(fault)
    zero, one = 47 * half, 111 * half
    wgap, sgap, lead, tail = 12 * FC, 20 * FC, 300 * half, 401 * half
    if fault == "shortest":
        zero, one, wgap, sgap, lead, tail = 1440, 4000, 800, 800, 8000, 8000
    if fault == "longest":
        zero, one, wgap, sgap, lead = 2320, 4880, 2400, 4000, 80000
    zero = {"zero1439": 1439}.get(fault, zero)
    one = {"one4881": 4881}.get(fault, one)
    wgap = {"wgap799": 799, "wgap2401": 2401}.get(fault, wgap)
    sgap = {"sgap4001": 4001}.get(fault, sgap)
    commands = [list(c) for c in commands]
    if fault == "flipbit":
        commands[-1][-6] ^= 1
    if fault == "lsbfirst":
        for c in commands:
            if len(c) >= 38:
                n = len(c)
                c[n - 35:n - 3] = c[n - 35:n - 3][::-1]
    if fault == "droplock":
        commands = [c[:-36] + c[-35:] if len(c) >= 38 else c for c in commands]
    if fault == "dropcmd":
        commands = commands[:-1]
    if fault == "extracmd":
        commands = commands + [commands[-1]]
    out = []
    for n, bits in enumerate(commands):
        if n == 0:
            out.append(("lead", lead))
        else:
            gapless = {"lead7999": 7999, "lead80001": 80001}.get(fault, tail)
            out.append(("tail", gapless))
        if not (fault == "nostartgap" and n == 0):
            out.append(("gap", sgap))
        for k, b in enumerate(bits):
            out.append(("bit", one if b else zero))
            out.append(("gap", wgap))
    out.append(("tail", 7999 if fault == "tail7999" else tail))
    out.append(("stop",) if fault in ("freeze", "tail7999") else ("forever",))
    return out


def halves(length, count):
    """count half periods adding up to length, as even as can be."""
    base, extra = divmod(length, count)
    return [base + (1 if k < extra else 0) for k in range(count)]


def toggles(commands, fault, cycles):
    """[(cycle, level)]: P0 high at cycle 0, then every change, as pe_sim
    would print it. Carrier stretches are laid down half by half; a
    stretch that ends in a gap holds the number of halves (odd or even)
    that leaves the line at the gap's level when the gap begins."""
    half = carrier_half(fault)
    gap_level = 1 if fault == "gaphigh" else 0
    t = 401 if fault == "late" else 200
    edges = [t]          # the first change of P0, a fall
    level = 0
    pieces = plan(commands, fault)
    for i, piece in enumerate(pieces):
        kind = piece[0]
        if kind == "gap":
            # the gap began with the last edge; it ends with the next one
            t += piece[1]
            edges.append(t)
            level ^= 1
        elif kind in ("lead", "bit", "tail"):
            length = piece[1]
            into_gap = pieces[i + 1][0] == "gap"
            n = max(1, round(length / half))
            if into_gap and (level ^ (n & 1)) != gap_level:
                n = min((n - 1, n + 1), key=lambda m: abs(length / m - half))
            for h in halves(length, n):
                t += h
                edges.append(t)
                level ^= 1
            if into_gap and level != gap_level:
                raise AssertionError("parity")
        elif kind == "forever":
            while t < cycles:
                t += half
                edges.append(t)
    if fault == "glitch":
        e = edges[50]
        edges[51:51] = [e + 10, e + 20]
    out, level = [(0, 1)], 1
    for e in edges:
        if e < cycles:
            level ^= 1
            out.append((e, level))
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
        commands = commands_of(words)
    except ValueError as e:
        sys.stderr.write("ideal: the TX words are not the task sheet's: %s\n" % e)
        return 3
    for c, v in toggles(commands, fault, cycles):
        sys.stdout.write("pins %d %02x\n" % (c, 0xFE | v))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
