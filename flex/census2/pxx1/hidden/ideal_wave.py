#!/usr/bin/env python3
"""An ideal PXX1 transmitter, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -cycles N [ignored ...]

and prints P0's changes in the simulator's format ("pins CYCLE XX"),
starting high at cycle 0 as a push-pull pin does after reset. It reads the
task sheet's TX words back into frames in its own way (frames_of below,
written apart from accept.py's tx_words) and exits with an error, which the
judge counts as a failure, if the stream is not what the sheet says.

It is written apart from accept.py on purpose and works differently: its
CRC uses the task sheet's carry-less products where accept.py runs the
register bit by bit, it packs the channels from a 96-bit string where
accept.py slices bytes, and it stuffs by scanning the bit string for runs
of five 1s. If the two disagree, the self-test fails.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. A few names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

US = 50                       # cycles a microsecond at 50 MHz

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal: first frame at cycle 100000, frames every 9 ms, pulses 8 us, bits 16/24 us"),
    "jitter25":    (True,  "every low pulse and every period 25 cycles (0.5 us) off, alternately long and short (the limit)"),
    "period8ms":   (True,  "frames every 8 ms (the limit)"),
    "period10ms":  (True,  "frames every 10 ms (the limit)"),
    "fixedgap":    (True,  "a fixed 5.5 ms of idle line after each frame instead of a fixed 9 ms period"),
    "start5000":   (True,  "first frame at cycle 5000 (the earliest allowed)"),
    "start500000": (True,  "first frame at cycle 500000 (the limit)"),
    "flipbit":     (False, "one channel bit of the last frame inverted (the CRC still the right one for the sent bytes)"),
    "flipdata":    (False, "one channel value of the last frame off by one, CRC computed on the wrong bytes"),
    "badcrc":      (False, "the CRC of the standard CRC-16/KERMIT instead of PXX1's"),
    "crcswap":     (False, "CRC bytes sent low byte first"),
    "nostuff":     (False, "no bit stuffing at all"),
    "stuff6":      (False, "a 0 stuffed after six 1s instead of five"),
    "stuffhead":   (False, "the header and closing 0x7E stuffed as well"),
    "nocrcstuff":  (False, "no stuffed 0 after the CRC's last bit when it ends a run of five 1s"),
    "stuffreset":  (False, "the run of 1s counted again from zero at the start of every byte"),
    "lsbfirst":    (False, "bytes sent least significant bit first"),
    "nibbles":     (False, "the shared middle byte of each channel pair with its nibbles swapped"),
    "notail":      (False, "no closing 0x7E"),
    "inverted":    (False, "the whole line inverted: idle low, high pulses"),
    "long26":      (False, "one period 26 cycles too long"),
    "short26":     (False, "one period 26 cycles too short"),
    "pulse9us":    (False, "every low pulse 9 us"),
    "pulse7us":    (False, "one low pulse 7 us"),
    "bit17us":     (False, "zeros of 17 us (the decoder still reads them)"),
    "period7999":  (False, "frames every 7.99 ms"),
    "period10001": (False, "frames every 10.0002 ms"),
    "start4999":   (False, "first frame at cycle 4999"),
    "start500001": (False, "first frame at cycle 500001"),
    "glitch":      (False, "a 1-cycle low glitch 1 ms after the last frame"),
    "endlow":      (False, "the line driven low after the last frame"),
    "dropframe":   (False, "the last frame is not sent"),
    "extraframe":  (False, "the last frame is sent twice"),
}

# The task sheet's CRC table: T[v] = clmul(0x1189, v & 15) ^ clmul(0x1081, v >> 4)
def clmul(a, b):
    r = 0
    for k in range(8):
        if b >> k & 1:
            r ^= a << k
    return r & 0xFFFF


def table(v):
    return clmul(0x1189, v & 15) ^ clmul(0x1081, v >> 4)


def pxx_crc(data, fault):
    crc = 0
    for b in data:
        if fault == "badcrc":          # CRC-16/KERMIT, reflected
            crc = (crc >> 8) ^ table((crc ^ b) & 0xFF)
        else:
            crc = ((crc << 8) & 0xFFFF) ^ table(((crc >> 8) ^ b) & 0xFF)
    return crc


def frame_string(rx, f1, f2, ex, ch, fault):
    """The frame's 16 payload bytes as a string of '0'/'1', MSB first."""
    s = format(rx, "08b") + format(f1, "08b") + format(f2, "08b")
    for i in range(0, 8, 2):
        a, b = format(ch[i], "012b"), format(ch[i + 1], "012b")
        mid = b[8:] + a[:4]          # (b & 15) << 4 | a >> 8
        if fault == "nibbles":
            mid = a[:4] + b[8:]
        s += a[4:] + mid + b[:8]
    s += format(ex, "08b")
    return s


def stuffed(bits, limit=5, reset_each_byte=False):
    out, run = "", 0
    for n, c in enumerate(bits):
        if reset_each_byte and n % 8 == 0:
            run = 0
        out += c
        run = run + 1 if c == "1" else 0
        if run == limit:
            out += "0"
            run = 0
    return out


def wire(frame, fault):
    rx, f1, f2, ex, ch = frame
    s = frame_string(rx, f1, f2, ex, ch, fault)
    data = [int(s[i:i + 8], 2) for i in range(0, len(s), 8)]
    crc = pxx_crc(data, fault)
    if fault == "flipbit":
        s = s[:40] + ("1" if s[40] == "0" else "0") + s[41:]
    body = s + format(crc, "016b") if fault != "crcswap" else s + format(crc & 0xFF, "08b") + format(crc >> 8, "08b")
    if fault == "lsbfirst":
        body = "".join(body[i:i + 8][::-1] for i in range(0, len(body), 8))
    if fault == "nostuff":
        mid = body
    elif fault == "stuff6":
        mid = stuffed(body, 6)
    elif fault == "stuffreset":
        mid = stuffed(body, 5, reset_each_byte=True)
    else:
        mid = stuffed(body)
        if fault == "nocrcstuff" and mid != stuffed(body[:-1]) + body[-1]:
            mid = mid[:-1]                 # the 0 after the CRC's last bit
    head = "01111110"
    if fault == "stuffhead":
        return stuffed(head + body + head)
    return head + mid + ("" if fault == "notail" else head)


def toggles(frames, fault="none"):
    """The cycles at which P0 changes level."""
    frames = [list(f) for f in frames]
    if fault == "flipdata":
        frames[-1][4] = list(frames[-1][4])
        frames[-1][4][3] ^= 1
    if fault == "dropframe":
        frames = frames[:-1]
    if fault == "extraframe":
        frames = frames + [frames[-1]]
    t = {"start5000": 5000, "start4999": 4999, "start500000": 500000,
         "start500001": 500001}.get(fault, 100000)
    period = {"period8ms": 400000, "period10ms": 500000, "period7999": 399500,
              "period10001": 500010}.get(fault, 450000)
    out = []
    n = 0
    for index, frame in enumerate(frames):
        start = t
        bits = wire(frame, fault)
        for k, c in enumerate(bits):
            low = 9 * US if fault == "pulse9us" else 8 * US
            if fault == "pulse7us" and index == 0 and k == 20:
                low = 7 * US
            length = 24 * US if c == "1" else (17 * US if fault == "bit17us" else 16 * US)
            if fault == "jitter25":
                low += 25 if n % 2 else -25
                length += 25 if n % 2 else -25
            if fault == "long26" and index == 0 and k == 30:
                length += 26
            if fault == "short26" and index == 0 and k == 30:
                length -= 26
            n += 1
            out += [t, t + low]
            t += length
        if fault == "fixedgap":
            t = t - length + 5500 * US     # the last bit's fall, then 5.5 ms
        else:
            t = start + period
    if fault == "glitch":
        last = out[-1]
        out += [last + 1000 * US, last + 1000 * US + 1]
    if fault == "endlow":
        out.append(out[-1] + 1000 * US)
    return out


def pins_text(frames, cycles, fault="none"):
    """What pe_sim would print: P0 high at cycle 0, then every change."""
    level = 1
    lines = ["pins 0 ff"]
    marks = toggles(frames, fault)
    if fault == "inverted":
        lines = ["pins 0 ff", "pins 1 fe"]
        level = 0
    for c in marks:
        level ^= 1
        if c < cycles:
            lines.append("pins %d %02x" % (c, 0xFE | level))
    return "\n".join(lines) + "\n"


def frames_of(words):
    """The frames a word stream asks for, by the task sheet's rules."""
    if len(words) % 10 or not words:
        raise ValueError("%d words is not a whole number of frames" % len(words))
    out = []
    for i in range(0, len(words), 10):
        w = words[i:i + 10]
        if any(x >> 16 for x in w) or any(x >> 12 for x in w[2:]):
            raise ValueError("a word has bits set that the sheet keeps 0")
        out.append((w[0] & 0xFF, w[0] >> 8, w[1] & 0xFF, w[1] >> 8, w[2:]))
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
        frames = frames_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(frames, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
