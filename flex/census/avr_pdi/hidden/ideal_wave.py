#!/usr/bin/env python3
"""An ideal PDI programmer, as a waveform and rx lines: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints what pe_sim would: "pins CYCLE XX" for every change of the
chip's outputs, and "rx CYCLE WORD" for every word pushed to the host. It
reads the TX words by the task sheet's rules in its own code (not
accept.py's), walks them slot by slot, and reads the device's answers back
out of the stimulus file by sampling P1 at each rising edge of its own
clock, as a real receiver would. It exits with an error if the words are
not what the sheet says.

--fault breaks the result in one named way (FAULTS below). A few names are
not faults but results at the very edge of what the sheet allows, which
must still pass."""
import sys

SLOT, HIGH, T0 = 50, 25, 2000
END = 0x8000

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":       (True,  "ideal: data changes on the falling edge itself"),
    "jitter2":    (True,  "falling edges 2 cycles late, rising edges 2 early (the limit)"),
    "datalate":   (True,  "P1 changes 5 cycles before the rising edge (the limit)"),
    "rxlate":     (True,  "rx words pushed together at the very end of the run"),
    "rewrite":    (True,  "in every slot it sends, P1 released at the fall, then the bit 3 cycles later"),
    "flipbit":    (False, "one data bit of the last byte sent inverted"),
    "badparity":  (False, "odd parity instead of even"),
    "onestop":    (False, "one stop bit per frame instead of two"),
    "msbfirst":   (False, "bytes sent most significant bit first"),
    "late3":      (False, "one PDI_CLK edge 3 cycles late"),
    "slow51":     (False, "PDI_CLK period 51 cycles"),
    "t0late":     (False, "first falling edge at cycle 2003"),
    "guard127":   (False, "127 guard slots before an answer"),
    "guard129":   (False, "129 guard slots before an answer"),
    "after1":     (False, "1 idle slot after an answer instead of 2"),
    "datarise4":  (False, "P1 changes 4 cycles before the rising edge"),
    "databefore": (False, "P1 changes 1 cycle before the falling edge"),
    "nodrop":     (False, "chip pulls P1 low during the device's first stop bit"),
    "guardpulse": (False, "chip pulls P1 low briefly inside a guard slot, released by the rise"),
    "rxwrong":    (False, "one rx word wrong"),
    "rxmissing":  (False, "last rx word not pushed"),
    "rxextra":    (False, "one rx word too many"),
    "rxparity":   (False, "rx word carries the parity bit in bit 8"),
    "endshort":   (False, "15 idle slots at the end instead of 16"),
    "endlong":    (False, "17 idle slots at the end"),
    "p2":         (False, "P2 written low once"),
    "idlelow":    (False, "P1 driven low at cycle 0"),
}


def read_words(words):
    """[(bytes sent, answer length)] by the sheet's rules."""
    if not words or words[-1] != END or words.count(END) != 1:
        raise ValueError("the words do not end with exactly one 0x8000")
    out, cur = [], []
    for w in words[:-1]:
        if w & 0xF000:
            raise ValueError("word 0x%04x has a bit above bit 11 set" % w)
        cur.append(w & 0xFF)
        if w >> 8:
            out.append((cur, w >> 8))
            cur = []
    if cur:
        out.append((cur, 0))
    return out


def frame(b, fault):
    data = [(b >> k) & 1 for k in (range(7, -1, -1) if fault == "msbfirst" else range(8))]
    par = sum(data) & 1
    if fault == "badparity":
        par ^= 1
    return [0] + data + [par] + ([1] if fault == "onestop" else [1, 1])


def simulate(words, stim, cycles, fault):
    period = 51 if fault == "slow51" else SLOT
    t0 = T0 + 3 if fault == "t0late" else T0
    guard = {"guard127": 127, "guard129": 129}.get(fault, 128)
    after = 1 if fault == "after1" else 2
    endidle = {"endshort": 15, "endlong": 17}.get(fault, 16)
    groups = read_words(words)

    def dev(c):
        lv = 1
        for at, v in stim:
            if at > c:
                break
            lv = (v >> 1) & 1
        return lv

    # owned: per slot, the chip's P1 level, or None while the device may speak
    plan = [1] * 16
    reads = []      # (first slot of an answer, number of bytes)
    for sent, n in groups:
        for i, b in enumerate(sent):
            bits = frame(b, fault)
            if fault == "flipbit" and (sent, n) == groups[-1] and i == len(sent) - 1:
                bits[3] ^= 1
            plan += bits
        if n:
            plan += [1] * guard
            reads.append((len(plan), n))
            plan += [None] * (12 * n)
            plan += [1] * after
    plan += [1] * endidle

    events = {}  # cycle -> {bit: level}
    def put(c, bit, v):
        events.setdefault(c, {})[bit] = v

    level = 1
    for k, want in enumerate(plan):
        f = t0 + period * k
        r = f + HIGH
        if fault == "jitter2":
            f, r = f + 2, r - 2
        if fault == "late3" and k == 20:
            f += 3
        put(f, 0, 0)
        put(r, 0, 1)
        lv = 1 if want is None else want
        if fault == "rewrite" and want is not None and k >= 16 and plan[k - 1] is not None:
            if level == 0:
                put(f, 1, 1)
            put(f + 3, 1, lv)
            level = lv
            continue
        if lv != level:
            at = {"datalate": r - 5, "datarise4": r - 4, "databefore": f - 1}.get(fault, f)
            put(at, 1, lv)
            level = lv
    if fault == "nodrop" and reads:
        s = reads[0][0] + 10
        put(t0 + period * s + 1, 1, 0)
        put(t0 + period * (s + 1), 1, 1)
    if fault == "guardpulse":
        s = 16 + 12 * len(groups[0][0]) + 3 if groups else 5
        put(t0 + period * s + 2, 1, 0)
        put(t0 + period * s + 6, 1, 1)
    if fault == "p2":
        put(t0 + 10, 2, 0)
        put(t0 + 11, 2, 1)

    # the device's bytes, sampled at our own rising edges
    rx = []
    for first, n in reads:
        for j in range(n):
            s = first + 12 * j
            bits = [dev(t0 + period * (s + i) + HIGH) for i in range(12)]
            byte = sum(bits[1 + i] << i for i in range(8))
            word = byte | (bits[9] << 8 if fault == "rxparity" else 0)
            rx.append((t0 + period * (s + 12), word))
    if fault == "rxwrong" and rx:
        rx[0] = (rx[0][0], rx[0][1] ^ 0x10)
    if fault == "rxmissing" and rx:
        rx.pop()
    if fault == "rxextra":
        rx.append((rx[-1][0] + 1 if rx else t0, 0x55))
    if fault == "rxlate":
        rx = [(cycles - 1, w) for _, w in rx]

    out = []
    pins = 0xFE if fault == "idlelow" else 0xFF
    out.append((0, "pins 0 %02x" % pins))
    if fault == "idlelow":
        events.setdefault(1, {})[1] = 1
    for c in sorted(events):
        if c >= cycles:
            break
        for bit, v in events[c].items():
            pins = (pins & ~(1 << bit)) | (v << bit)
        out.append((c, "pins %d %02x" % (c, pins)))
    for c, w in rx:
        if c < cycles:
            out.append((c, "rx %d %d" % (c, w)))
    out.sort(key=lambda x: x[0])
    return "\n".join(t for _, t in out) + "\n"


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    need = ("-tx", "-stimulus", "-cycles")
    if fault not in FAULTS or argv[:1] != ["run"] or any(n not in argv for n in need):
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(l, 0) for l in f if l.strip()]
    with open(argv[argv.index("-stimulus") + 1]) as f:
        stim = []
        for l in f:
            if l.strip():
                c, v = l.split()
                stim.append((int(c), int(v, 16)))
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        text = simulate(words, stim, cycles, fault)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
