#!/usr/bin/env python3
"""An ideal CAN FD transmitting node, as a waveform: NOT chip firmware.

This stands in for pe_sim when the judge itself is being checked. It is
called the way accept.py calls the simulator,

    ideal_wave.py [--fault NAME] run ANY.s -tx FILE -stimulus FILE -cycles N [ignored ...]

and prints, in the simulator's format, P0's output ("pins CYCLE XX", released
at cycle 0) and the words it pushes to the host ("rx CYCLE WORD"). It takes
the task sheet's TX words and reads them back into frames in its own way
(frames_of below, written apart from accept.py's tx_words); it reads the
stimulus file and, like a node, looks at the line at the sample point of
each ACK slot to decide whether the frame was acknowledged.

It is written apart from accept.py on purpose, and works differently:
stuffing is done on a string of bits by scanning for runs, the CRC is a
polynomial division of the whole message (with the ISO start folded in as
leading terms), and bit times are laid out from a list of per-bit lengths.
If the two disagree the self-test fails.

--fault changes the node in one named way (FAULTS below), to show that the
judge fails what it should. A few names are not faults but behaviour at the
very edge of what the task sheet allows, which must still pass."""
import sys

NOM, FAST = 100, 25          # cycles a bit: 500 kbit/s and 2 Mbit/s at 50 MHz
SP_NOM, SP_FAST = 80, 20     # sample points, 80 %
LENGTHS = (0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 16, 20, 24, 32, 48, 64)

# name: (must the judge pass it?, what it is)
FAULTS = {
    "none":        (True,  "ideal node"),
    "jitter1":     (True,  "every chip edge 1 cycle off its place, alternately late and early (the limit)"),
    "late1":       (True,  "every chip edge 1 cycle late (the limit)"),
    "early1":      (True,  "every chip edge 1 cycle early (the limit)"),
    "rxatack":     (True,  "each RX word pushed at the very start of the ACK slot (the earliest allowed)"),
    "rxatend":     (True,  "each RX word pushed at the frame's end (the latest allowed)"),
    "flipbit":     (False, "one data bit of the last frame sent wrong (stuffing and CRC follow it)"),
    "crcbit":      (False, "one CRC bit of each frame inverted"),
    "crcinit0":    (False, "the CRC started from zero (the pre-ISO CAN FD CRC)"),
    "crcnostuff":  (False, "the CRC computed without the dynamic stuff bits"),
    "crcnosc":     (False, "the CRC computed without the stuff count and parity"),
    "binarysc":    (False, "the stuff count sent in binary, not Gray code"),
    "oddparity":   (False, "the stuff count's parity bit inverted"),
    "stufflast":   (False, "a dynamic stuff bit after the last data bit when its five last bits are equal"),
    "nostuff":     (False, "no dynamic stuff bits in the data field"),
    "nofsb":       (False, "no fixed stuff bits in the CRC field"),
    "lsbfirst":    (False, "data bytes sent least significant bit first"),
    "swapbytes":   (False, "the two bytes of each data word taken low byte first"),
    "idsplit":     (False, "an extended identifier read as bits 28..18 in word 1, bits 17..0 in word 2"),
    "esi1":        (False, "ESI sent recessive"),
    "brs100":      (False, "the BRS bit a whole nominal bit: the rate switches at its end"),
    "brs25":       (False, "the rate switches at the start of the BRS bit"),
    "del100":      (False, "the rate switches back at the start of the CRC delimiter: a whole nominal bit"),
    "del25":       (False, "the CRC delimiter a data-phase bit: the rate switches back at its end"),
    "data26":      (False, "data-phase bits of 26 cycles"),
    "nom99":       (False, "nominal bits of 99 cycles"),
    "late2":       (False, "one edge of each frame 2 cycles late"),
    "sof2002":     (False, "the first frame starts at cycle 2002"),
    "ifs302":      (False, "each later frame starts 302 cycles after the one before ends"),
    "selfack":     (False, "the chip pulls its own ACK slot low"),
    "ignoreack":   (False, "the ACK is never looked at: no error flag, every RX word 0x0001"),
    "flag5":       (False, "an error flag of 5 dominant bits"),
    "flag7":       (False, "an error flag of 7 dominant bits"),
    "flaglate":    (False, "the error flag starts a bit late, after a recessive ACK delimiter"),
    "rxwrong":     (False, "the right waveform, but RX word 0x0001 for a frame not acknowledged"),
    "rxmissing":   (False, "no RX word for the last frame"),
    "rxextra":     (False, "an extra RX word after the last frame's"),
    "rxtoolate":   (False, "each RX word pushed 1 cycle after the frame's end"),
    "rxtooearly":  (False, "each RX word pushed 1 cycle before the ACK slot starts"),
    "glitch":      (False, "a one-cycle low pulse in the intermission after the first frame"),
    "tail":        (False, "a one-cycle low pulse 1000 cycles after the last frame's end"),
    "dropframe":   (False, "the last frame is not sent (and has no RX word)"),
    "lowstart":    (False, "P0 pulled low for cycles 10 to 19 of the run"),
}


def bits_of(value, width):
    return "".join("1" if value >> k & 1 else "0" for k in range(width - 1, -1, -1))


def crc_div(message, width, init_top):
    """The CRC as a remainder: message * x^width + init * x^len(message),
    divided by the generator, all over GF(2), on Python integers. (A shift
    register that starts from init holds it already multiplied by x^width.)"""
    gen = {17: 0x3685B, 21: 0x302899}[width]
    value = (int(message, 2) if message else 0) << width
    if init_top:
        value ^= 1 << (width - 1 + len(message))
    glen = gen.bit_length()
    while value.bit_length() >= glen:
        value ^= gen << (value.bit_length() - glen)
    return value


def gray(n):
    return n ^ (n >> 1)


def stuff(raw, fault):
    """Dynamic stuffing of a bit string: (stuffed, stuff bits, mask of
    which stuffed bits are stuff bits)."""
    out, mask, count = "", "", 0
    for i, b in enumerate(raw):
        tail = out[-5:]
        if len(tail) == 5 and tail in ("00000", "11111"):
            if fault != "nostuff" or i <= 0 or not mask_in_data(i, raw):
                out += "1" if tail == "00000" else "0"
                mask += "s"
                count += 1
        out += b
        mask += "."
    if fault == "stufflast" and out[-5:] in ("00000", "11111"):
        out += "1" if out[-1] == "0" else "0"
        mask += "s"
        count += 1
    return out, count, mask


DATA_START = {}


def mask_in_data(i, raw):
    return i >= DATA_START.get(raw, 10 ** 9)


def frame_wire(fr, fault):
    """[(bit char, length class)] of one frame from SOF to the CRC
    delimiter. Length classes: 'n' nominal, 'f' data phase, 'b' the BRS bit,
    'd' the CRC delimiter."""
    ide, brs, dlc, ident, data = fr["ide"], fr["brs"], fr["dlc"], fr["ident"], fr["data"]
    if fault == "lsbfirst":
        payload = "".join(bits_of(b, 8)[::-1] for b in data)
    else:
        payload = "".join(bits_of(b, 8) for b in data)
    esi = "1" if fault == "esi1" else "0"
    if ide:
        arb = "0" + bits_of(ident >> 18, 11) + "11" + bits_of(ident & 0x3FFFF, 18) + "0"
    else:
        arb = "0" + bits_of(ident, 11) + "00"
    ctrl_pre = arb + "10"                      # FDF, res
    brs_index = len(ctrl_pre)
    raw = ctrl_pre + str(brs) + esi + bits_of(dlc, 4)
    DATA_START[raw + payload] = len(raw)
    raw += payload
    st, count, mask = stuff(raw, fault)
    # where the BRS bit is in the stuffed string: the brs_index-th raw bit
    seen, brs_at = -1, None
    for k, m in enumerate(mask):
        if m == ".":
            seen += 1
            if seen == brs_index:
                brs_at = k
                break
    sc = bits_of(count % 8 if fault == "binarysc" else gray(count % 8), 3)
    par = str(sc.count("1") % 2 ^ (1 if fault == "oddparity" else 0))
    width = 17 if len(data) <= 16 else 21
    msg = (raw if fault == "crcnostuff" else st) + ("" if fault == "crcnosc" else sc + par)
    crc = bits_of(crc_div(msg, width, fault != "crcinit0"), width)
    if fault == "crcbit":
        crc = crc[:3] + ("1" if crc[3] == "0" else "0") + crc[4:]
    field = ""
    if fault != "nofsb":
        field += "1" if st[-1] == "0" else "0"
    field += sc + par
    for k in range(0, width, 4):
        if fault != "nofsb":
            field += "1" if field[-1] == "0" else "0"
        field += crc[k:k + 4]
    wire = []
    for k, b in enumerate(st + field + "1"):
        if not brs:
            cls = "n"
        elif k < brs_at:
            cls = "n"
        elif k == brs_at:
            cls = "b"
        elif k < len(st) + len(field):
            cls = "f"
        else:
            cls = "d"
        wire.append((b, cls))
    return wire


def lengths(cls, fault):
    nom = 99 if fault == "nom99" else NOM
    fast = 26 if fault == "data26" else FAST
    if cls == "n":
        return nom
    if cls == "f":
        return fast
    if cls == "b":
        return {"brs100": nom, "brs25": fast}.get(fault, SP_NOM + (fast - SP_FAST))
    if cls == "d":
        return {"del100": nom, "del25": fast}.get(fault, SP_FAST + (nom - SP_NOM))


def frames_of(words):
    """The frames a word stream asks for, by the task sheet's rules."""
    out, i = [], 0
    while i < len(words):
        head = words[i]
        if head & 0x3FF0:
            raise ValueError("header word 0x%04x has bits 13..4 set" % head)
        ide, brs, dlc = head >> 15 & 1, head >> 14 & 1, head & 15
        i += 1
        if ide:
            if words[i] >> 13:
                raise ValueError("identifier word 0x%04x has bits 15..13 set" % words[i])
            ident = words[i] << 16 | words[i + 1]
            i += 2
        else:
            if words[i] >> 11:
                raise ValueError("identifier word 0x%04x has bits 15..11 set" % words[i])
            ident = words[i]
            i += 1
        n = LENGTHS[dlc]
        data = []
        for _ in range((n + 1) // 2):
            data += [words[i] >> 8, words[i] & 0xFF]
            i += 1
        if n % 2 and data[-1] != 0:
            raise ValueError("the last data word of an odd length frame has a low byte")
        out.append({"ide": ide, "brs": brs, "dlc": dlc, "ident": ident, "data": data[:n]})
    return out


def level_at(stim, cycle):
    v = 1
    for c, l in stim:
        if c <= cycle:
            v = l
        else:
            break
    return v


def run(frames, stim, cycles, fault):
    """(pins changes [(cycle, level)], rx [(cycle, word)])."""
    if fault == "swapbytes":
        for f in frames:
            d = f["data"] + ([0] if len(f["data"]) % 2 else [])
            d = [d[k ^ 1] for k in range(len(d))]
            f["data"] = d[:len(f["data"])]
    if fault == "idsplit":
        for f in frames:
            if f["ide"]:
                hi, lo = f["ident"] >> 16, f["ident"] & 0xFFFF
                f["ident"] = ((hi & 0x7FF) << 18) | lo
    if fault == "flipbit":
        frames[-1]["data"] = list(frames[-1]["data"])
        if frames[-1]["data"]:
            frames[-1]["data"][0] ^= 0x10
        else:
            frames[-1]["ident"] ^= 1
    if fault == "dropframe":
        frames = frames[:-1]
    t = 2002 if fault == "sof2002" else 2000
    edges, rx, level = [], [], 1
    nom = 99 if fault == "nom99" else NOM

    def put(at, bit):
        nonlocal level
        if bit != level:
            edges.append(at)
            level = bit

    if fault == "lowstart":
        edges += [10, 20]
    for index, fr in enumerate(frames):
        wire = frame_wire(fr, fault)
        first_edge = len(edges)
        for b, cls in wire:
            put(t, int(b))
            t += lengths(cls, fault)
        ack_start = t
        acked = level_at(stim, ack_start + SP_NOM) == 0
        if fault == "ignoreack":
            acked = True
        if fault == "selfack":
            put(t, 0)
        else:
            put(t, 1)
        t += nom
        if acked:
            put(t, 1)
            t += 8 * nom
        else:
            if fault == "flaglate":
                put(t, 1)
                t += nom
            flag = {"flag5": 5, "flag7": 7}.get(fault, 6)
            put(t, 0)
            t += flag * nom
            put(t, 1)
            t += 8 * nom
        end = t
        if fault == "late2":
            mid = first_edge + (len(edges) - first_edge) // 2
            edges[mid] += 2
        word = 1 if acked else 0
        if fault == "rxwrong":
            word = 1
        at = {"rxatack": ack_start, "rxatend": end, "rxtoolate": end + 1,
              "rxtooearly": ack_start - 1}.get(fault, ack_start + SP_NOM + 10)
        if not (fault == "rxmissing" and index == len(frames) - 1):
            rx.append((at, word))
        if fault == "rxextra" and index == len(frames) - 1:
            rx.append((at + 1, word))
        if fault == "glitch" and index == 0:
            edges += [end + 100, end + 101]
        t = end + (302 if fault == "ifs302" else 300)
    if fault == "tail":
        last_end = t - 300
        edges += [last_end + 1000, last_end + 1001]
    if fault == "jitter1":
        edges = [e + (1 if k % 2 else -1) for k, e in enumerate(edges)]
    if fault in ("late1", "early1"):
        edges = [e + (1 if fault == "late1" else -1) for e in edges]
    changes, lv = [], 1
    for e in sorted(edges):
        lv ^= 1
        changes.append((e, lv))
    return changes, rx


def main(argv):
    fault = "none"
    if argv[:1] == ["--fault"]:
        fault, argv = argv[1], argv[2:]
    if (fault not in FAULTS or argv[:1] != ["run"] or "-tx" not in argv
            or "-stimulus" not in argv or "-cycles" not in argv):
        sys.stderr.write(__doc__)
        return 2
    with open(argv[argv.index("-tx") + 1]) as f:
        words = [int(line, 0) for line in f if line.strip()]
    with open(argv[argv.index("-stimulus") + 1]) as f:
        stim = [(int(a), int(b, 16) & 1) for a, b in (line.split() for line in f if line.strip())]
    cycles = int(argv[argv.index("-cycles") + 1])
    try:
        frames = frames_of(words)
    except (ValueError, IndexError) as e:
        sys.stderr.write("ideal_wave: the TX words are not the task sheet's: %s\n" % e)
        return 3
    changes, rx = run(frames, stim, cycles, fault)
    events = [(c, 0, "pins %d %02x" % (c, 0xFE | lv)) for c, lv in changes if c < cycles]
    events += [(c, 1, "rx %d %d" % (c, w)) for c, w in rx if c < cycles]
    sys.stdout.write("pins 0 ff\n" + "".join(e[2] + "\n" for e in sorted(events)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
