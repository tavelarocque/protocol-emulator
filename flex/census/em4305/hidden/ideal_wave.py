#!/usr/bin/env python3
"""An ideal EM4305 reader, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"). It
reads the TX words back into commands by the task sheet's rules, in its own
code (commands_of below, written apart from accept.py's tx_words), and exits
with an error, which the judge counts as a failure, if the stream is not
what the sheet says.

It is written apart from accept.py on purpose, and works differently: it
lays the run out as a row of carrier periods ("slots"), each with the field
on (a pulse: high for 40 cycles, then low for 40) or off (low for 80), and
only then turns slots into edges. accept.py lists the places edges belong.
If the two disagree, the self-test fails.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. Some names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

HALF = 40          # cycles: half a 125 kHz carrier period at 10 MHz
SLOT = 80          # one carrier period
WRITE = 0x100      # task sheet: bit 8 of a command's first word means Write word

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":       (True,  "ideal: first fall at cycle 40, 400 periods of carrier before each command and after the last"),
    "jitter2":    (True,  "inside commands every edge 2 cycles off its place, alternately late and early (the limit)"),
    "idlewidth":  (True,  "outside commands every high 42 cycles and every low 38 (the limit)"),
    "idle320":    (True,  "exactly 320 periods before each command and 320 whole pulses after the last (the limit)"),
    "idle1280":   (True,  "1280 periods before each command (the limit)"),
    "first200":   (True,  "P0's first fall at cycle 200 (the limit)"),
    "carryon":    (True,  "the carrier runs on to the end of the run"),
    "stophigh":   (True,  "after the last command's 400 pulses one more rise, then P0 stays high"),
    "flipbit":    (False, "one data bit of the last command inverted, its parities made to match"),
    "badrow":     (False, "the first row parity bit of the last command inverted"),
    "badcol":     (False, "one column parity bit of the last command inverted"),
    "lsbfirst":   (False, "each data byte sent bit 0 first"),
    "msbytes":    (False, "the data bytes sent most significant first"),
    "addrmsb":    (False, "a write's address sent bit 3 first"),
    "swapcmd":    (False, "a Login sent with the Write word code and the reverse"),
    "nolead":     (False, "no leading 0 bit"),
    "nostop":     (False, "no stop bit"),
    "late3":      (False, "one edge in the middle of the first command 3 cycles late"),
    "early3":     (False, "one edge in the middle of the first command 3 cycles early"),
    "idlehigh43": (False, "one high pulse before the first command lasts 43 cycles"),
    "idlelow37":  (False, "one low between pulses after the first command lasts 37 cycles"),
    "slow81":     (False, "carrier periods of 81 cycles: the error adds up along a command"),
    "ffs54":      (False, "first field stops of 54 periods"),
    "ffs56":      (False, "first field stops of 56 periods"),
    "zero15":     (False, "0 bits with the field on for 15 periods and off for 17"),
    "zero17":     (False, "0 bits with the field on for 17 periods and off for 15"),
    "idle319":    (False, "319 periods before each command"),
    "idle1281":   (False, "1281 periods before each command"),
    "tail319":    (False, "only 319 whole pulses after the last command, then P0 low"),
    "tail0":      (False, "the field stops at once after the last command"),
    "first201":   (False, "P0's first fall at cycle 201"),
    "latecarrier": (False, "P0 falls at cycle 40 but the carrier's first rise comes at cycle 200"),
    "nofirst":    (False, "P0 high from the start until the first carrier slot at cycle 400"),
    "glitch":     (False, "a pulse one cycle long in the middle of a 0 bit's gap"),
    "dropout":    (False, "two pulses missing from the carrier between the first two commands"),
    "dropcmd":    (False, "the last command is not sent"),
    "extracmd":   (False, "the last command is sent twice"),
}


def commands_of(words):
    """The commands a word stream asks for, by the task sheet's rules."""
    if not words or len(words) % 3:
        raise ValueError("%d words: not a whole number of three-word commands" % len(words))
    out = []
    for n in range(0, len(words), 3):
        head, low, high = words[n:n + 3]
        if max(low, high) > 0xFFFF:
            raise ValueError("a value word over 16 bits")
        if head == 0:
            out.append(("login", 0, low + (high << 16)))
        elif (head & ~0x0F) == WRITE:
            out.append(("write", head & 15, low + (high << 16)))
        else:
            raise ValueError("first word 0x%x is neither a Login nor a Write word" % head)
    return out


def parity(v):
    return bin(v).count("1") & 1


def msb8(byte):
    return [int(c) for c in "{:08b}".format(byte)]


def bits_of(cmd, fault, last):
    kind, addr, value = cmd
    if fault == "flipbit" and last:
        value ^= 1 << 13
    data = list(value.to_bytes(4, "little"))
    if fault == "msbytes":
        data.reverse()
    code = {"login": "0011", "write": "0101"}[kind]
    if fault == "swapcmd":
        code = {"login": "0101", "write": "0011"}[kind]
    head = [int(c) for c in code]
    if kind == "write":
        a = [int(c) for c in "{:04b}".format(addr)]
        if fault != "addrmsb":
            a.reverse()                       # bit 0 first
        head += a + [0, 0, parity(addr)]
    body = []
    for r, byte in enumerate(data):
        row = msb8(byte)
        if fault == "lsbfirst":
            row.reverse()
        p = parity(byte) ^ (1 if fault == "badrow" and last and r == 0 else 0)
        body += row + [p]
    col = msb8(data[0] ^ data[1] ^ data[2] ^ data[3])
    if fault == "lsbfirst":
        col.reverse()
    if fault == "badcol" and last:
        col[5] ^= 1
    bits = ([] if fault == "nolead" else [0]) + head + body + col + ([] if fault == "nostop" else [0])
    return bits


def edges(commands, cycles, fault="none"):
    """[(cycle, level)] of P0's changes."""
    slot = 81 if fault == "slow81" else SLOT
    half = HALF
    idle = {"idle320": 320, "idle1280": 1280, "idle319": 319, "idle1281": 1281}.get(fault, 400)
    tail = {"idle320": 320, "tail319": 319, "tail0": 0}.get(fault, 400)
    ffs = {"ffs54": 54, "ffs56": 56}.get(fault, 55)
    zero_on = {"zero15": 15, "zero17": 17}.get(fault, 16)
    first = {"first200": 200, "first201": 201}.get(fault, 40)
    commands = list(commands)
    if fault == "dropcmd":
        commands = commands[:-1]
    if fault == "extracmd":
        commands = commands + [commands[-1]]
    # The row of slots: (field on?, kind) with kind "idle" or "cmd".
    slots = []
    for n, cmd in enumerate(commands):
        slots += [(True, "idle")] * idle
        slots += [(False, "cmd")] * ffs
        for b in bits_of(cmd, fault, n == len(commands) - 1):
            slots += [(True, "cmd")] * (32 if b else zero_on)
            slots += [(False, "cmd")] * (0 if b else 32 - zero_on)
    slots += [(True, "idle")] * tail
    out = [(0, 1)]
    if fault == "nofirst":
        t = 400
    else:
        out.append((first, 0))
        t = first + (160 if fault == "latecarrier" else half)
    cmd_pulses = 0        # pulses inside commands so far
    idle_pulses = 0       # pulses outside commands so far
    after_first_cmd = False
    offrun = 0            # field-off slots in a row just before this one
    seen_on = False       # the last pulse was inside a command
    glitched = False
    for on, kind in slots:
        if kind == "cmd":
            after_first_cmd = True
        if on:
            rise, fall = t, t + half
            anchor = kind == "cmd" and offrun >= 50   # the rise ending a field stop
            if kind == "cmd" and fault == "jitter2":
                # every edge 2 off, except the rise every other edge is measured from
                if not anchor:
                    rise += 2 if cmd_pulses % 2 else -2
                fall += -2 if cmd_pulses % 2 else 2
            if kind == "cmd" and fault in ("late3", "early3") and cmd_pulses == 300:
                fall += 3 if fault == "late3" else -3
            if kind == "idle" and fault == "idlewidth":
                fall += 2
            if kind == "idle" and fault == "idlehigh43" and not after_first_cmd and idle_pulses == 100:
                fall += 3
            if kind == "idle" and fault == "idlelow37" and after_first_cmd and idle_pulses == 500:
                rise -= 3
            if kind == "idle" and fault == "dropout" and after_first_cmd and idle_pulses in (500, 501):
                rise = None
            if kind == "cmd":
                cmd_pulses += 1
            else:
                idle_pulses += 1
            if rise is not None:
                out += [(rise, 1), (fall, 0)]
            offrun = 0
            seen_on = kind == "cmd"
        else:
            if fault == "glitch" and kind == "cmd" and seen_on and offrun == 8 and not glitched:
                out += [(t + 30, 1), (t + 31, 0)]
                glitched = True
            offrun += 1
        t += slot
    if fault == "carryon":
        while t + half < cycles:
            out += [(t, 1), (t + half, 0)]
            t += slot
    if fault == "stophigh":
        out.append((t, 1))
    return [(c, l) for c, l in out if c < cycles]


def pins_text(commands, cycles, fault="none"):
    """What pe_sim would print: all pins high at cycle 0, then every change of P0."""
    lines = []
    for c, level in edges(commands, cycles, fault):
        lines.append("pins %d %02x" % (c, 0xFE | level))
    return "\n".join(lines) + "\n"


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
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(commands, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
