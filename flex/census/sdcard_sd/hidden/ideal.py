#!/usr/bin/env python3
"""An ideal SD-mode host on the CMD line, as a waveform: NOT chip firmware.

It stands in for pe_sim when the judge itself is being checked, called the
way accept.py calls the simulator,

    ideal.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints, in the simulator's format, every change of the chip's outputs
("pins CYCLE XX": P0 is CLK, P1 is CMD, the other bits stay 1) and every
word pushed to the host ("rx CYCLE WORD").

It is written apart from accept.py on purpose and works differently. It
reads the TX words back into commands by the task sheet's rules and exits
with an error if they break them. It walks the clock edge by edge as a host
would: it sends a command, then watches the card's script, sampled at its
own rising edges, for the response's start bit, reads the response from
it, and pushes the RX words. accept.py instead lays out the whole schedule
from the answers it chose. If the two disagree, the self-test fails.

--fault changes the waveform in one named way (FAULTS below). A few names
are not faults but waveforms at the edge of what the task sheet allows,
which must still pass."""
import sys

FIRST_FALL, HALF = 180, 20
INIT, GAP, TAIL = 80, 8, 8

FAULTS = {
    "none":      (True,  "ideal: CMD changes 10 cycles into the low half; clock stops 3 clocks after the 8 required"),
    "jitter2":   (True,  "every falling edge 2 cycles late and every rising edge 2 early (the limit)"),
    "cmdearly":  (True,  "CMD changes 1 cycle after the ideal falling edge (the earliest allowed)"),
    "cmdlate":   (True,  "CMD changes 1 cycle before the ideal rising edge (the latest allowed)"),
    "runon":     (True,  "the clock keeps running to the end of the run"),
    "stopnow":   (True,  "the clock stops high, on the 8th rising edge after the last end bit"),
    "flipbit":   (False, "one argument bit of the last command inverted (CRC made on the wrong bits)"),
    "badcrc":    (False, "the last bit of every command CRC inverted"),
    "trans0":    (False, "transmission bit 0 in every command"),
    "end0":      (False, "end bit 0 in every command"),
    "late3":     (False, "one rising CLK edge 3 cycles late"),
    "slow41":    (False, "CLK period 41 cycles"),
    "cmdatfall": (False, "CMD changes in the very cycle CLK falls"),
    "cmdatrise": (False, "CMD changes in the very cycle CLK rises"),
    "init74":    (False, "first command after 74 clocks, not 80"),
    "gap7":      (False, "7 clocks between an end bit and the next command, not 8"),
    "gap9":      (False, "9 clocks between an end bit and the next command, not 8"),
    "earlystop": (False, "clock stops 7 clocks after the last end bit"),
    "glitch":    (False, "the host pulls CMD low for 3 cycles of a low half, during the card's first response or else after a command"),
    "rxflip":    (False, "one bit of the last RX word inverted"),
    "rxdrop":    (False, "the last RX word not pushed"),
    "rxextra":   (False, "one extra RX word pushed at the end"),
    "fixedncr":  (False, "the host does not look for the start bit: assumes it comes 2 clocks after the command"),
    "dropcmd":   (False, "the last command is not sent"),
    "tailpulse": (False, "a pulse on CMD 100 cycles after the clock has stopped"),
    "clkextra":  (False, "one more CLK pulse 200 cycles after the clock stopped"),
}


def die(msg):
    sys.stderr.write("ideal.py: %s\n" % msg)
    sys.exit(3)


def read_commands(path):
    """The task sheet's words: three per command. Word 0: command index in
    bits 5..0, response type in bits 9..8 (0 none, 1 48 bits, 2 136 bits),
    nothing else. Words 1 and 2: the argument, high half then low half."""
    with open(path) as f:
        words = [int(x, 0) for x in f.read().split()]
    if len(words) % 3:
        die("%d words is not a whole number of commands" % len(words))
    cmds = []
    for i in range(0, len(words), 3):
        w0, hi, lo = words[i:i + 3]
        if w0 & ~0x33F or (w0 >> 8) & 3 == 3 or hi > 0xFFFF or lo > 0xFFFF:
            die("word %d (0x%x) breaks the sheet's format" % (i, w0))
        cmds.append((w0 & 0x3F, (w0 >> 8) & 3, (hi << 16) | lo))
    return cmds


def read_stimulus(path):
    pts = []
    with open(path) as f:
        for line in f:
            if line.strip():
                c, h = line.split()
                pts.append((int(c), int(h, 16)))
    return pts


def crc7_poly(bits):
    """CRC7 by long division: the 40 bits times x^7, modulo x^7 + x^3 + 1."""
    v = int("".join(map(str, bits)), 2) << 7
    poly = 0b10001001
    for k in range(v.bit_length() - 1, 6, -1):
        if (v >> k) & 1:
            v ^= poly << (k - 7)
    return [(v >> k) & 1 for k in range(6, -1, -1)]


def cmd_bits(index, arg, fault, last):
    head = [0, 0 if fault == "trans0" else 1]
    head += [int(c) for c in format(index, "06b")]
    a = arg ^ (1 << 13) if (fault == "flipbit" and last) else arg
    head += [int(c) for c in format(a, "032b")]
    crc = crc7_poly(head)
    if fault == "badcrc":
        crc[-1] ^= 1
    return head + crc + [0 if fault == "end0" else 1]


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if fault not in FAULTS:
        die("unknown fault " + fault)
    opts = {}
    i = 2
    while i < len(argv):
        if argv[i] in ("-tx", "-stimulus", "-cycles"):
            opts[argv[i]] = argv[i + 1]
        i += 2
    cmds = read_commands(opts["-tx"])
    stim = read_stimulus(opts["-stimulus"])
    cycles = int(opts["-cycles"])
    if fault == "dropcmd":
        cmds = cmds[:-1]
    period = 41 if fault == "slow41" else 2 * HALF
    init = 74 if fault == "init74" else INIT
    gap = {"gap7": 7, "gap9": 9}.get(fault, GAP)

    def rise(n):
        return FIRST_FALL + HALF + period * n

    def card(cycle):
        v = 1
        for c, h in stim:
            if c <= cycle:
                v = (h >> 1) & 1
        return v

    # Walk the edges as a host: what CMD gives on each edge, and the rx words.
    host = {}          # edge -> level the host drives
    rx = []            # (cycle, word)
    n = init
    for k, (index, rtype, arg) in enumerate(cmds):
        bits = cmd_bits(index, arg, fault, k == len(cmds) - 1)
        for j, b in enumerate(bits):
            host[n + j] = b
        end = n + len(bits) - 1
        if rtype:
            length = 48 if rtype == 1 else 136
            if fault == "fixedncr":
                a = end + 2
            else:
                a = end + 2
                while card(rise(a)) != 0:
                    a += 1
                    if a > end + 64:
                        die("no response start bit within 64 clocks")
            resp = [card(rise(a + j)) for j in range(length)]
            end = a + length - 1
            val = lambda bs: int("".join(map(str, bs)), 2)
            if length == 48:
                words = [val(resp[2:8]), val(resp[8:24]), val(resp[24:40])]
            else:
                words = [val(resp[8 + 16 * j: 24 + 16 * j]) for j in range(8)]
            rx += [(rise(end) + 5, w) for w in words]
        n = end + gap + 1
    last_end = n - gap - 1 if cmds else init
    stop_edge = last_end + TAIL + (0 if fault == "stopnow" else 3)
    if fault == "earlystop":
        stop_edge = last_end + TAIL - 1

    # CLK changes.
    clk = []
    k = 0
    while True:
        rising = k % 2 == 1
        c = FIRST_FALL + (k // 2) * period + (HALF if rising else 0)
        if fault == "jitter2":
            c += -2 if rising else 2
        if fault == "late3" and k == 2 * (INIT + 20) + 1:
            c += 3
        if c >= cycles:
            break
        clk.append((c, 1 if rising else 0))
        if fault != "runon" and rising and (k - 1) // 2 >= stop_edge and fault != "stopnow":
            # stop low: one more falling edge
            c2 = c + HALF + (2 if fault == "jitter2" else 0)
            clk.append((c2, 0))
            break
        if fault == "stopnow" and rising and (k - 1) // 2 >= stop_edge:
            break
        k += 1
    stopped = clk[-1][0]
    if fault == "clkextra":
        clk += [(stopped + 200, 1 - clk[-1][1]), (stopped + 220, clk[-1][1])]

    # CMD changes: in the low half before the edge.
    cmd = []
    prev = 1
    for e in range(max(host) + 2 if host else 0):
        b = host.get(e, 1)
        if b != prev:
            r = rise(e)
            c = {"cmdearly": r - HALF + 1, "cmdlate": r - 1,
                 "cmdatfall": r - HALF, "cmdatrise": r}.get(fault, r - HALF + 10)
            cmd.append((c, b))
        prev = b
    if fault == "glitch":
        resp_edges = [e for e in range(max(host) + 20) if e not in host and e > INIT]
        e = resp_edges[0] + 3
        cmd += [(rise(e) - 15, 0), (rise(e) - 12, 1)]
    if fault == "tailpulse":
        cmd += [(stopped + 100, 0), (stopped + 120, 1)]
    if fault == "rxflip" and rx:
        rx[-1] = (rx[-1][0], rx[-1][1] ^ 0x0100)
    if fault == "rxdrop" and rx:
        rx = rx[:-1]
    if fault == "rxextra":
        rx.append((rx[-1][0] + 1 if rx else 10, 0x1234))

    # Print in the simulator's format.
    events = {}
    for c, v in clk:
        events.setdefault(c, []).append((0, v))
    for c, v in cmd:
        events.setdefault(c, []).append((1, v))
    for c, w in rx:
        events.setdefault(c, []).append(("rx", w))
    level = {0: 1, 1: 1}
    print("pins 0 ff")
    for c in sorted(events):
        if c >= cycles:
            break
        before = dict(level)
        for what, v in events[c]:
            if what != "rx":
                level[what] = v
        if level != before and c > 0:
            print("pins %d %02x" % (c, 0xFC | (level[1] << 1) | level[0]))
        for what, v in events[c]:
            if what == "rx":
                print("rx %d %d" % (c, v))


if __name__ == "__main__":
    main(sys.argv[1:])
