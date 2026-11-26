#!/usr/bin/env python3
"""An ideal USB PD (BMC) transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"). It reads
the judge's TX words back into packets by the task sheet's rules, in its own
code (packets_of below), and exits with an error, which the judge counts as a
failure, if the word stream is not what the sheet says.

It is written apart from accept.py on purpose and works differently: the
4b5b table is typed from the specification's bit strings, the CRC-32 is
computed bit by bit as a shift register (accept.py uses zlib), and the line
is made by toggling a level, where accept.py lists where transitions belong.

--fault breaks the waveform in one named way (FAULTS below). A few names are
not faults but waveforms at the edge of what the task sheet allows, which
must still pass."""
import sys

UI, HALF = 66, 33

# The specification's 4b5b table, written b4..b0; b0 is sent first.
TABLE = {0x0: "11110", 0x1: "01001", 0x2: "10100", 0x3: "10101",
         0x4: "01010", 0x5: "01011", 0x6: "01110", 0x7: "01111",
         0x8: "10010", 0x9: "10011", 0xA: "10110", 0xB: "10111",
         0xC: "11010", 0xD: "11011", 0xE: "11100", 0xF: "11101"}
K = {"S1": "11000", "S2": "10001", "S3": "00110", "EOP": "01101"}
SOP = {0: ["S1", "S1", "S1", "S2"], 1: ["S1", "S1", "S3", "S3"], 2: ["S1", "S3", "S1", "S3"]}

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: line low at cycle 1, first preamble at 1000, gaps of 500"),
    "jitter2":     (True,  "transitions alternately 2 cycles late and 2 early (the limit)"),
    "gap40000":    (True,  "gaps of exactly 40000 cycles (the limit)"),
    "start40000":  (True,  "first preamble at cycle 40000 (the limit)"),
    "lowat100":    (True,  "P0 falls at cycle 100 (the limit), preamble at 600"),
    "flipbit":     (False, "one data bit of the last packet inverted (CRC then wrong)"),
    "badcrc":      (False, "right data, CRC's lowest bit inverted"),
    "crcfwd":      (False, "CRC computed most significant bit first (wrong algorithm)"),
    "nibbleswap":  (False, "nibbles of each byte sent high first"),
    "late3":       (False, "one transition 3 cycles late"),
    "early3":      (False, "one transition 3 cycles early"),
    "slow67":      (False, "bits of 67 cycles: the error adds up along a packet"),
    "pre62":       (False, "a preamble of 62 bits"),
    "pre66":       (False, "a preamble of 66 bits"),
    "wrongsop":    (False, "SOP' sent for every SOP"),
    "noeop":       (False, "no EOP symbol"),
    "noclose":     (False, "no transition after the last bit of EOP"),
    "highclose":   (False, "the closing rise is not followed by a fall: line left high"),
    "gap499":      (False, "gaps of 499 cycles"),
    "gap40001":    (False, "gaps of 40001 cycles"),
    "start40001":  (False, "first preamble at cycle 40001"),
    "lowat101":    (False, "P0 falls at cycle 101"),
    "neverlow":    (False, "P0 never driven low: preamble begins with a fall"),
    "tail":        (False, "one more pulse 5000 cycles after the last packet"),
    "dropmsg":     (False, "the last packet is not sent"),
    "extramsg":    (False, "the last packet is sent twice"),
}


def crc32_bits(bits):
    """Ethernet's CRC-32 as a shift register on the bits in sending order."""
    reg = 0xFFFFFFFF
    for b in bits:
        if (reg ^ b) & 1:
            reg = (reg >> 1) ^ 0xEDB88320
        else:
            reg >>= 1
    return reg ^ 0xFFFFFFFF


def crc32_forward(bits):
    """A wrong CRC on purpose: the non-reflected form, MSB-first register."""
    reg = 0xFFFFFFFF
    for b in bits:
        top = (reg >> 31) & 1
        reg = (reg << 1) & 0xFFFFFFFF
        if top ^ b:
            reg ^= 0x04C11DB7
    return reg ^ 0xFFFFFFFF


def lsb_bits(value, width):
    return [(value >> i) & 1 for i in range(width)]


def code_bits(s):
    """A b4..b0 string, in the order sent (b0 first)."""
    return [int(c) for c in reversed(s)]


def line_bits(kind, header, objects, fault):
    data = lsb_bits(header, 16)
    for o in objects:
        data += lsb_bits(o, 32)
    crc = (crc32_forward if fault == "crcfwd" else crc32_bits)(data)
    if fault == "badcrc":
        crc ^= 1
    payload = data + lsb_bits(crc, 32)
    if fault == "flipbit":
        payload[17] ^= 1  # a header or data bit; the CRC stays the right one's
    nib = []
    for i in range(0, len(payload), 4):
        nib.append(sum(payload[i + j] << j for j in range(4)))
    if fault == "nibbleswap":
        nib = [nib[i ^ 1] for i in range(len(nib))]
    pre = {"pre62": 62, "pre66": 66}.get(fault, 64)
    bits = [i % 2 for i in range(pre)]
    if pre % 2:
        bits = bits[1:] + [1]
    for s in SOP[1 if fault == "wrongsop" and kind == 0 else kind]:
        bits += code_bits(K[s])
    for n in nib:
        bits += code_bits(TABLE[n])
    if fault != "noeop":
        bits += code_bits(K["EOP"])
    return bits


def toggles(packets, fault="none"):
    """The cycles at which P0 changes level, the line high at cycle 0."""
    ui = 67 if fault == "slow67" else UI
    gap = {"gap40000": 40000, "gap499": 499, "gap40001": 40001}.get(fault, 500)
    low_at = {"lowat100": 100, "lowat101": 101}.get(fault, 1)
    t = {"start40000": 40000, "start40001": 40001, "lowat100": 600}.get(fault, 1000)
    packets = list(packets)
    if fault == "dropmsg":
        packets = packets[:-1]
    if fault == "extramsg":
        packets = packets + [packets[-1]]
    out = [] if fault == "neverlow" else [low_at]
    level = 1 if fault == "neverlow" else 0
    for index, packet in enumerate(packets):
        if index == len(packets) - 1 and fault == "flipbit":
            bits = line_bits(*packet, fault=fault)
        else:
            bits = line_bits(*packet, fault="none" if fault == "flipbit" else fault)
        mine = []
        for b in bits:
            mine.append(t)
            level ^= 1
            if b:
                mine.append(t + ui // 2)
                level ^= 1
            t += ui
        if fault != "noclose":
            mine.append(t)
            level ^= 1
            if level and fault != "highclose":
                mine.append(t + ui // 2)
                level ^= 1
        if fault in ("late3", "early3") and index == 0:
            mine[len(mine) // 2] += 3 if fault == "late3" else -3
        if fault == "jitter2":
            mine = mine[:1] + [c + (2 if n % 2 else -2) for n, c in enumerate(mine[1:])]
        out += mine
        t = mine[-1] + gap
    if fault == "tail":
        out += [mine[-1] + 5000, mine[-1] + 5033]
    return out


def pins_text(packets, cycles, fault="none"):
    """What pe_sim would print: P0 high at cycle 0, then every change."""
    lines, level = ["pins 0 ff"], 1
    for c in toggles(packets, fault):
        level ^= 1
        if c < cycles:
            lines.append("pins %d %02x" % (c, 0xFE | level))
    return "\n".join(lines) + "\n"


def packets_of(words):
    """The packets a word stream asks for, by the task sheet's rules."""
    out, i = [], 0
    while i < len(words):
        first = words[i]
        if first & ~0x1F or first & 3 == 3:
            raise ValueError("first word 0x%04x is not (objects << 2) | kind" % first)
        kind, count = first & 3, first >> 2
        if i + 2 + 2 * count > len(words):
            raise ValueError("the words run out inside a packet")
        header = words[i + 1]
        if (header >> 12) & 7 != count:
            raise ValueError("header 0x%04x does not say %d data objects" % (header, count))
        objects = [words[i + 2 + 2 * j] | (words[i + 3 + 2 * j] << 16) for j in range(count)]
        if any(w >> 16 for w in words[i:i + 2 + 2 * count]):
            raise ValueError("a word wider than 16 bits")
        out.append((kind, header, objects))
        i += 2 + 2 * count
    if not out:
        raise ValueError("no words")
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
        packets = packets_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(packets, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
