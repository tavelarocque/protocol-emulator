#!/usr/bin/env python3
"""An ideal fast link pulse transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints the pins' changes in the simulator's format ("pins CYCLE XX"),
starting with every pin high at cycle 0 as the output register is after
reset. P0 is TD+, P1 is TD-. The words it takes are the task sheet's: one
16-bit link code word per FLP burst. It exits with an error, which the judge
counts as a failure, if a word is not a 16-bit number.

It is written apart from accept.py on purpose, and works differently: it
walks the 33 pulse positions of a burst, 62.5 us apart, and puts a pulse in
every even position (a clock pulse) and in odd position 2k + 1 when bit k of
the word is 1. accept.py lists clock pulses and data pulses separately and
sorts them. If the two disagree, the self-test fails.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. Some names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

POSITION = 2_500   # cycles between pulse positions: 62.5 us at 40 MHz
WIDTH = 4          # 100 ns
FIRST = 200_000    # the ideal's first burst: 5 ms after reset
APART = 640_000    # and 16 ms from burst to burst

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: pins low at cycle 1, first burst at 5 ms, bursts 16 ms apart, pulses 100 ns"),
    "jitter40":    (True,  "every pulse after a burst's first alternately 40 cycles late and 40 early (the limit)"),
    "width3":      (True,  "pulses 3 cycles (75 ns) wide"),
    "width5":      (True,  "pulses 5 cycles (125 ns) wide"),
    "apart8ms":    (True,  "bursts 320,000 cycles (8 ms) apart, the least allowed"),
    "apart24ms":   (True,  "bursts 960,000 cycles (24 ms) apart, the most allowed"),
    "start1ms":    (True,  "first burst at cycle 40,000 (1 ms), the earliest allowed"),
    "start16ms":   (True,  "first burst at cycle 640,000 (16 ms), the latest allowed"),
    "low100":      (True,  "P0 and P1 driven low at cycle 100 (the limit)"),
    "flipbit":     (False, "one bit (D9) of the last word inverted"),
    "msbfirst":    (False, "each word sent D15 first"),
    "inverted":    (False, "a data pulse for each 0 and none for each 1"),
    "noclose":     (False, "no 17th clock pulse at the end of a burst"),
    "extraclock":  (False, "an 18th clock pulse at the end of a burst"),
    "late41":      (False, "one pulse of the first burst 41 cycles late"),
    "early41":     (False, "one pulse of the first burst 41 cycles early"),
    "slow5003":    (False, "clock pulses 5,003 cycles apart: the error adds up along a burst"),
    "data60":      (False, "every data pulse 60 cycles (1.5 us) late"),
    "width2":      (False, "pulses 2 cycles (50 ns) wide"),
    "width6":      (False, "pulses 6 cycles (150 ns) wide"),
    "width40":     (False, "pulses 40 cycles (1 us) wide"),
    "apart7ms":    (False, "bursts 319,999 cycles apart"),
    "apart25ms":   (False, "bursts 960,001 cycles apart"),
    "start39999":  (False, "first burst at cycle 39,999"),
    "start640001": (False, "first burst at cycle 640,001"),
    "low101":      (False, "P0 driven low only at cycle 101"),
    "tdminus101":  (False, "P1 (TD-) driven low only at cycle 101"),
    "tdminushigh": (False, "P1 (TD-) left high from reset"),
    "tdminuspulse": (False, "a 4-cycle pulse on P1 (TD-) between two bursts"),
    "glitch":      (False, "a pulse one cycle long on P0 between the first two bursts"),
    "tail":        (False, "a lone pulse on P0 4 ms after the last burst"),
    "stuckhigh":   (False, "P0 left high after the last burst"),
    "dropword":    (False, "the last word is not sent"),
    "extraword":   (False, "the last burst is sent twice"),
}


def burst_rises(word, fault="none"):
    """The cycles, from the burst's start, at which its pulses rise."""
    out = []
    for pos in range(33):
        if pos % 2 == 0:
            k = pos // 2
            if fault == "noclose" and k == 16:
                continue
            step = 5003 if fault == "slow5003" else 2 * POSITION
            out.append(k * step)
        else:
            bit = (word >> (pos // 2)) & 1
            if fault == "inverted":
                bit ^= 1
            if bit:
                step = 5003 if fault == "slow5003" else 2 * POSITION
                out.append((pos // 2) * step + POSITION + (60 if fault == "data60" else 0))
    if fault == "extraclock":
        out.append(17 * 2 * POSITION)
    if fault == "jitter40":
        out = out[:1] + [c + (40 if n % 2 else -40) for n, c in enumerate(out[1:])]
    if fault in ("late41", "early41"):
        out[len(out) // 2] += 41 if fault == "late41" else -41
    return out


def reverse16(w):
    return int("{:016b}".format(w)[::-1], 2)


def events(words, fault="none"):
    """[(cycle, pin, level)] after cycle 0, every pin high at cycle 0."""
    width = {"width3": 3, "width5": 5, "width2": 2, "width6": 6, "width40": 40}.get(fault, WIDTH)
    apart = {"apart8ms": 320_000, "apart24ms": 960_000, "apart7ms": 319_999,
             "apart25ms": 960_001}.get(fault, APART)
    t = {"start1ms": 40_000, "start16ms": 640_000, "start39999": 39_999,
         "start640001": 640_001}.get(fault, FIRST)
    words = list(words)
    if fault == "flipbit":
        words[-1] ^= 1 << 9
    if fault == "msbfirst":
        words = [reverse16(w) for w in words]
    if fault == "dropword":
        words = words[:-1]
    if fault == "extraword":
        words = words + words[-1:]
    ev = []
    ev.append(({"low100": 100, "low101": 101}.get(fault, 1), 0, 0))
    if fault != "tdminushigh":
        ev.append(({"low100": 100, "tdminus101": 101}.get(fault, 1), 1, 0))
    last_end = None
    for index, w in enumerate(words):
        burst_fault = fault if (index == 0 or fault not in ("late41", "early41")) else "none"
        for r in burst_rises(w, burst_fault):
            ev.append((t + r, 0, 1))
            ev.append((t + r + width, 0, 0))
        last_end = t + 2 * 16 * POSITION + width
        if index == 0 and fault == "glitch":
            ev += [(t + 300_000, 0, 1), (t + 300_001, 0, 0)]
        if index == 0 and fault == "tdminuspulse":
            ev += [(t + 300_000, 1, 1), (t + 300_004, 1, 0)]
        t += apart
    if fault == "tail" and last_end is not None:
        ev += [(last_end + 160_000, 0, 1), (last_end + 160_004, 0, 0)]
    if fault == "stuckhigh" and last_end is not None:
        ev += [(last_end + 1_000, 0, 1)]
    return sorted(ev)


def pins_text(words, cycles, fault="none"):
    """What pe_sim would print: the register at cycle 0, then every change."""
    reg = 0xFF
    lines = ["pins 0 ff"]
    by_cycle = {}
    for c, pin, level in events(words, fault):
        by_cycle.setdefault(c, []).append((pin, level))
    for c in sorted(by_cycle):
        if c >= cycles:
            break
        new = reg
        for pin, level in by_cycle[c]:
            new = (new & ~(1 << pin)) | (level << pin)
        if new != reg:
            reg = new
            lines.append("pins %d %02x" % (c, reg))
    return "\n".join(lines) + "\n"


def main(argv):
    fault = "none"
    if len(argv) > 2 and argv[1] == "--fault":
        fault = argv[2]
        argv = argv[:1] + argv[3:]
    if fault not in FAULTS:
        sys.stderr.write("unknown fault %s\n" % fault)
        return 2
    args = argv[1:]
    if not args or args[0] != "run":
        sys.stderr.write("usage: ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N\n")
        return 2
    tx, cycles = None, 100_000
    i = 2
    while i < len(args):
        if args[i] == "-tx":
            tx = args[i + 1]
        elif args[i] == "-cycles":
            cycles = int(args[i + 1])
        i += 2
    words = []
    if tx:
        with open(tx) as f:
            for line in f:
                if line.strip():
                    w = int(line.strip(), 0)
                    if not 0 <= w <= 0xFFFF:
                        sys.stderr.write("word %r is not 16 bits\n" % line.strip())
                        return 1
                    words.append(w)
    sys.stdout.write(pins_text(words, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
