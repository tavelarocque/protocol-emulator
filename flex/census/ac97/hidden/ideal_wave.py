#!/usr/bin/env python3
"""An ideal AC'97 controller output, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

reads the codec's BIT_CLK (P0) from the stimulus file, and prints the
changes of SYNC (P1) and SDATA_OUT (P2) in the simulator's format
("pins CYCLE XX"). It reads the TX words back into frames in its own way
(frames_of below, written apart from accept.py's tx_words and slot_values)
and exits with an error, which the judge counts as a failure, if the words
are not what the task sheet says.

It is written apart from accept.py on purpose and works differently: it
builds the 256 bits of each frame field by field and drives each bit on
the rising edge of BIT_CLK before the falling edge that samples it, where
accept.py lists the 13 slot values sigrok must report and checks levels at
the falling edges.

--fault breaks the waveform in one named way (FAULTS below), to show that
the judge fails what it should. A few names are not faults but waveforms at
the very edge of what the task sheet allows, which must still pass."""
import sys

SYNC_PIN, DATA_PIN = 1, 2

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":       (True,  "ideal: every change on a rising edge of BIT_CLK, first frame early"),
    "hold1":      (True,  "every change 1 cycle after the falling edge before (the hold limit)"),
    "setup1":     (True,  "every change 1 cycle before the falling edge that samples it (the setup limit)"),
    "first255":   (True,  "SYNC first sampled high at falling edge 255 (the latest allowed)"),
    "low40":      (True,  "SYNC and SDATA_OUT driven low only at cycle 40 (the latest allowed)"),
    "glitchdata": (True,  "SDATA_OUT pulses for one cycle between two falling edges (never sampled)"),
    "flipbit":    (False, "one bit of the last frame's right sample inverted"),
    "lsbfirst":   (False, "every slot sent least significant bit first"),
    "noshift":    (False, "16-bit values put in the low 16 bits of their 20-bit slots"),
    "tagread":    (False, "a read marks slot 2 valid in the tag"),
    "tagnocmd":   (False, "a frame without a command marks slots 1 and 2 valid"),
    "atfall":     (False, "one SDATA_OUT change in the same cycle as the falling edge that samples it"),
    "syncatfall": (False, "SYNC rises in the same cycle as a falling edge"),
    "sync15":     (False, "SYNC high for 15 bit times, not 16"),
    "sync17":     (False, "SYNC high for 17 bit times, not 16"),
    "gap1":       (False, "one idle bit between two frames (a 257-bit frame period)"),
    "first256":   (False, "SYNC first sampled high at falling edge 256"),
    "first0":     (False, "SYNC already high at the very first falling edge"),
    "low41":      (False, "SYNC and SDATA_OUT driven low only at cycle 41"),
    "idledata":   (False, "SDATA_OUT high at one falling edge before the first frame"),
    "taildata":   (False, "SDATA_OUT high at one falling edge after the last frame"),
    "glitchsync": (False, "SYNC pulses for one cycle between two falling edges, after the last frame"),
    "extraframe": (False, "one more frame, all zeros, after the last"),
    "dropframe":  (False, "the last frame is not sent"),
}


def frames_of(words):
    """The frames a word stream asks for, by the task sheet's rules:
    four words a frame, CTRL, DATA, LEFT, RIGHT."""
    if not words or len(words) % 4:
        raise ValueError("%d words is not a whole number of frames" % len(words))
    frames = []
    for k in range(0, len(words), 4):
        ctrl, data, left, right = words[k:k + 4]
        if any(w < 0 or w > 0xFFFF for w in (ctrl, data, left, right)):
            raise ValueError("a word is not 16 bits")
        if ctrl & 0xFE00:
            raise ValueError("CTRL 0x%04x has a bit above bit 8 set" % ctrl)
        command = bool(ctrl & 0x100)
        read = bool(ctrl & 0x80)
        reg = ctrl & 0x7F
        if not command and ctrl:
            raise ValueError("CTRL 0x%04x: no command, yet bits 7..0 are not 0" % ctrl)
        if reg & 1:
            raise ValueError("odd register address 0x%02x" % reg)
        if (read or not command) and data:
            raise ValueError("DATA must be 0 for a read and for a frame without a command")
        frames.append(dict(command=command, read=read, reg=reg, data=data, left=left, right=right))
    return frames


def field(value, width, fault):
    bits = [(value >> (width - 1 - k)) & 1 for k in range(width)]
    return bits[::-1] if fault == "lsbfirst" else bits


def frame_bits(fr, fault):
    """The 256 bits of one output frame, in the order they are sent."""
    def wide(v16):   # a 16-bit value in a 20-bit slot
        return (v16 << 4) if fault != "noshift" else v16
    slot2_valid = fr["command"] and (not fr["read"] or fault == "tagread")
    slot1_valid = fr["command"] or fault == "tagnocmd"
    if fault == "tagnocmd" and not fr["command"]:
        slot2_valid = True
    tag = [1, int(slot1_valid), int(slot2_valid), 1, 1] + [0] * 8 + [0, 0, 0]
    if fault == "lsbfirst":
        tag = tag[::-1]
    bits = list(tag)
    bits += field((int(fr["read"]) << 19) | (fr["reg"] << 12) if fr["command"] else 0, 20, fault)
    bits += field(wide(fr["data"]), 20, fault)
    bits += field(wide(fr["left"]), 20, fault)
    bits += field(wide(fr["right"]), 20, fault)
    bits += [0] * (20 * 8)
    assert len(bits) == 256
    return bits


def clock_edges(stimulus, cycles):
    """(rises, falls) of P0, in cycles."""
    rises, falls, level = [], [], 0
    for c, v in stimulus:
        b = v & 1
        if c < cycles and b != level:
            (rises if b else falls).append(c)
        level = b
    return rises, falls


def waveform(frames, rises, falls, fault):
    """{fall index: (sync, data)} for the levels the codec must sample."""
    if fault == "dropframe":
        frames = frames[:-1]
    i0 = {"first255": 255, "first256": 256, "first0": 0}.get(fault, 3)
    want = {}
    pos = i0
    for n, fr in enumerate(frames + ([dict(command=False, read=False, reg=0, data=0, left=0, right=0)]
                                     if fault == "extraframe" else [])):
        width = {"sync15": 15, "sync17": 17}.get(fault, 16)
        for k in range(width):
            want.setdefault(pos + k, [0, 0])[0] = 1
        bits = frame_bits(fr, fault)
        if fault == "flipbit" and n == len(frames) - 1:
            bits[16 + 20 * 3 + 9] ^= 1
        for k, b in enumerate(bits):
            want.setdefault(pos + 1 + k, [0, 0])[1] = b
        pos += 256 + (1 if fault == "gap1" and n == 0 else 0)
    if fault == "idledata":
        want.setdefault(i0 - 2, [0, 0])[1] = 1
    if fault == "taildata":
        want.setdefault(pos + 20, [0, 0])[1] = 1
    return want, pos


def pins_text(frames, stimulus, cycles, fault="none"):
    rises, falls = clock_edges(stimulus, cycles)
    want, end = waveform(frames, rises, falls, fault)
    low_at = {"low40": 40, "low41": 41}.get(fault, 1)
    events = {low_at: (0, 0)}
    level = (0, 0)
    for i, f in enumerate(falls):
        lv = tuple(want.get(i, (0, 0)))
        if lv == level:
            continue
        prev_fall = falls[i - 1] if i else None
        rise = max(r for r in rises if r < f)
        if fault == "hold1" and prev_fall is not None:
            at = prev_fall + 1
        elif fault == "setup1":
            at = f - 1
        else:
            at = rise
        if fault == "atfall" and i >= end - 255 and lv[0] == level[0]:
            at = f
            fault = "none"   # only once
        if fault == "syncatfall" and lv[0] != level[0]:
            at = f
            fault = "none"   # only once
        events[at] = lv
        level = lv
    lines = ["pins 0 ff"]
    extra = {}
    if fault == "glitchdata":
        c = falls[end + 10] + 1
        extra = {c: 1, c + 1: 0}
    if fault == "glitchsync":
        c = falls[end + 10] + 1
        extra = {c: 2, c + 1: 0}
    out, cur = {}, (1, 1)
    for c in sorted(set(events) | set(extra)):
        if c in events:
            cur = events[c]
        v = 0xF9 | (cur[0] << SYNC_PIN) | (cur[1] << DATA_PIN)
        if c in extra and extra[c] == 1:
            v ^= 1 << DATA_PIN
        if c in extra and extra[c] == 2:
            v ^= 1 << SYNC_PIN
        out[c] = v
    last = 0xFF
    for c in sorted(out):
        if c < cycles and out[c] != last:
            lines.append("pins %d %02x" % (c, out[c]))
            last = out[c]
    return "\n".join(lines) + "\n"


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if fault not in FAULTS or argv[:1] != ["run"] or "-tx" not in argv \
            or "-cycles" not in argv or "-stimulus" not in argv:
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(line, 0) for line in f if line.strip()]
    with open(argv[argv.index("-stimulus") + 1]) as f:
        stimulus = [tuple(int(x, 16) if i else int(x) for i, x in enumerate(line.split()))
                    for line in f if line.strip()]
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        frames = frames_of(words)
    except ValueError as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    sys.stdout.write(pins_text(frames, stimulus, cycles, fault))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
