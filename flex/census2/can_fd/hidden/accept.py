#!/usr/bin/env python3
"""Hidden acceptance test for the blind CAN FD transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (can_fd.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet fixes
what the TX and RX words mean, and this test builds the TX words itself.

The chip is a CAN FD node that transmits. P0 is the bus line at logic level,
open-drain (wired-AND): released is recessive (1), pulled low is dominant
(0). A scripted receiver on the same line acknowledges a frame by pulling the
line low for that frame's ACK slot; the test leaves some frames
unacknowledged. The stimulus cannot react, so the task sheet fixes when every
frame starts.

For each case (a list of frames) the test
  1. builds the TX words the task sheet defines (a header word, one or two
     identifier words, the data bytes two to a word) and the stimulus: the
     line released, and pulled low for exactly the ideal ACK slot of each
     frame that is to be acknowledged,
  2. runs RUN_DIR/pe_sim on RUN_DIR/can_fd.s with them,
  3. checks the chip's own P0 output against the ideal transmitter, edge by
     edge: the same number of changes, each within +-1 cycle of its ideal
     place counted from cycle 0 of the run (bit times, the bit rate switch
     at the sample points, stuff bits, fixed stuff bits, stuff count, CRC,
     the ACK slot left recessive, the active error flag after a missing ACK,
     the start of every frame, nothing after the last),
  4. builds the bus line (the chip's output AND the scripted receiver's), as
     a logic capture at one sample per cycle (50 MHz), and has DSView's
     `can-fd` decoder (ported to sigrok-cli 0.7.2, see PORT.diff) read it.
     For every frame its annotations must be exactly the ideal frame's: start
     of frame, identifier, IDE, FDF, RRS or SRR, reserved bit, BRS, ESI, DLC,
     every data byte, the stuff count, its parity, the CRC sequence (equal to
     the ISO CAN FD CRC this test computes; the decoder does not check it),
     the CRC delimiter, and for an acknowledged frame ACK, ACK delimiter and
     end of frame, with no warning. For an unacknowledged frame everything up
     to the CRC delimiter must be exact; what the decoder makes of the error
     flag after it is not its to judge (step 3 checks it),
  5. requires the RX words to be one per frame, in order, 0x0001 for an
     acknowledged frame and 0x0000 for one that was not, each pushed no
     earlier than the start of its frame's ACK slot and no later than the
     frame's end, and nothing else.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<data bytes> cycles=<cycles from P0's first change to its last>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
exit status is 0 only on a full pass. Python standard library and sigrok-cli
only. Written apart from the firmware and kept from its author."""
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

# The round-2 decoders (sigrok-cli 0.7.2's own plus the round-2 ones, can-fd
# ported as PORT.diff shows). CANFD_DECODERS overrides it, for a copy kept
# elsewhere.
DECODERS = os.environ.get("CANFD_DECODERS",
                          "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4"
                          "/scratchpad/flex2/decoders")

CLOCK_HZ = 50_000_000        # core clock: one cycle = 20 ns
NB = 100                     # cycles a nominal bit (500 kbit/s)
DB = 25                      # cycles a data-phase bit (2 Mbit/s)
NSP = 80                     # nominal sample point, cycles after a bit's start (80 %)
DSP = 20                     # data sample point (80 %)
BRS_LEN = NSP + DB - DSP     # 85: the BRS bit when the rate switches
DEL_LEN = DSP + NB - NSP     # 40: the CRC delimiter when the rate switched
FIRST_SOF = 2000             # the first frame's start of frame
IFS = 3 * NB                 # intermission: the next SOF this long after a frame's end
TAIL = 2000                  # the run goes on this long after the last frame's end
TOL = 1                      # cycles a chip edge may be from its ideal place
MAX_FRAMES = 6
MAX_DLC = 10                 # 16 data bytes: every frame of the test has a CRC-17
IDE_BIT = 1 << 15            # header word: extended identifier
BRS_BIT = 1 << 14            # header word: bit rate switch
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
PIN = 0                      # P0
DECODER = "can-fd:can_rx=P0:nominal_bitrate=500000:fast_bitrate=2000000"
DLC_LEN = [0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 16, 20, 24, 32, 48, 64]
GRAY = [0b000, 0b001, 0b011, 0b010, 0b110, 0b111, 0b101, 0b100]


class Frame:
    """One frame the host asks for, and whether the scripted receiver
    acknowledges it."""

    def __init__(self, ide, brs, dlc, ident, data, ack=True):
        assert len(data) == DLC_LEN[dlc]
        assert 0 <= ident < (1 << (29 if ide else 11))
        self.ide, self.brs, self.dlc, self.ident = int(ide), int(brs), dlc, ident
        self.data, self.ack = list(data), bool(ack)

    def base_id(self):
        return self.ident >> 18 if self.ide else self.ident

    def __repr__(self):
        return "Frame(%d, %d, %d, 0x%x, %d bytes, ack=%s)" % (
            self.ide, self.brs, self.dlc, self.ident, len(self.data), self.ack)


# ---------------------------------------------------------------- the code

def msb(value, width):
    return [(value >> k) & 1 for k in range(width - 1, -1, -1)]


def crc_iso(bits, width):
    """ISO CAN FD CRC-17 or CRC-21: polynomial 0x3685B or 0x302899, the
    register starting with its top bit 1 and the rest 0, one bit at a time
    most significant first. Returns the register after the last bit."""
    poly = {17: 0x1685B, 21: 0x102899}[width]
    top, mask, reg = 1 << (width - 1), (1 << width) - 1, 1 << (width - 1)
    for b in bits:
        feedback = b ^ (1 if reg & top else 0)
        reg = (reg << 1) & mask
        if feedback:
            reg ^= poly
    return reg


def crc_check_values():
    """The catalogue check values of CRC-17/CAN-FD (0x04F03) and
    CRC-21/CAN-FD (0x0ED841), which use a zero start: this verifies the
    polynomials and the shift; the ISO start only changes the first state."""
    def plain(width, data):
        poly = {17: 0x1685B, 21: 0x102899}[width]
        top, mask, reg = 1 << (width - 1), (1 << width) - 1, 0
        for b in [bit for byte in data for bit in msb(byte, 8)]:
            feedback = b ^ (1 if reg & top else 0)
            reg = (reg << 1) & mask
            if feedback:
                reg ^= poly
        return reg
    return plain(17, b"123456789"), plain(21, b"123456789")


def frame_fields(f):
    """The frame's bits from SOF to the last bit of the data field, before
    stuffing: [(bit, name)]."""
    out = [(0, "SOF")]
    if f.ide:
        out += [(b, "ID") for b in msb(f.ident >> 18, 11)]
        out += [(1, "SRR"), (1, "IDE")]
        out += [(b, "ID") for b in msb(f.ident & 0x3FFFF, 18)]
        out += [(0, "RRS")]
    else:
        out += [(b, "ID") for b in msb(f.ident, 11)]
        out += [(0, "RRS"), (0, "IDE")]
    out += [(1, "FDF"), (0, "res"), (f.brs, "BRS"), (0, "ESI")]
    out += [(b, "DLC") for b in msb(f.dlc, 4)]
    out += [(b, "data") for byte in f.data for b in msb(byte, 8)]
    return out


class Coded:
    """A frame as it goes on the wire, the chip's side: [(bit, name)] from SOF
    to the end of EOF (or of the error delimiter), and the numbers."""

    def __init__(self, f):
        head, run, last, stuffed = [], 0, None, 0
        for b, name in frame_fields(f):
            if run == 5:                 # five equal bits: a dynamic stuff bit
                last = 1 - last
                head.append((last, "stuff"))
                stuffed += 1
                run = 1
            head.append((b, name))
            run = run + 1 if b == last else 1
            last = b
        # No dynamic stuff bit after the last bit of the data field: the
        # fixed stuff bit stands there.
        self.stuff_count = stuffed
        g = GRAY[stuffed % 8]
        sc = msb(g, 3)
        parity = sum(sc) % 2
        self.width = 17 if DLC_LEN[f.dlc] <= 16 else 21
        self.crc = crc_iso([b for b, _ in head] + sc + [parity], self.width)
        tail = [(1 - head[-1][0], "FSB")]
        tail += [(b, "SC") for b in sc] + [(parity, "parity")]
        for i, b in enumerate(msb(self.crc, self.width)):
            if i % 4 == 0:
                tail.append((1 - tail[-1][0], "FSB"))
            tail.append((b, "CRC"))
        tail.append((1, "CRC delimiter"))
        self.bits = head + tail
        self.sc_bits = "".join(map(str, sc))
        self.parity = parity

    def stuffed(self):
        return "".join(str(b) for b, _ in self.bits)


def frame_timeline(f, sof):
    """[(start cycle, length, level, name)] of every bit the chip sends in
    one frame, from SOF to its end, and (ack slot start, frame end)."""
    coded = Coded(f)
    t, fast, out = sof, False, []
    for b, name in coded.bits:
        if name == "BRS" and f.brs:
            length = BRS_LEN
        elif name == "CRC delimiter" and f.brs:
            length = DEL_LEN
        else:
            length = DB if fast else NB
        out.append((t, length, b, name))
        t += length
        if name == "BRS" and f.brs:
            fast = True
        if name == "CRC delimiter":
            fast = False
    ack_at = t
    out.append((t, NB, 1, "ACK slot"))
    t += NB
    if f.ack:
        out += [(t, NB, 1, "ACK delimiter"), (t + NB, 7 * NB, 1, "EOF")]
        t += 8 * NB
    else:
        out += [(t, 6 * NB, 0, "error flag"), (t + 6 * NB, 8 * NB, 1, "error delimiter")]
        t += 14 * NB
    return out, ack_at, t


class Schedule:
    """Where everything belongs in one run."""

    def __init__(self, frames):
        self.frames = frames
        self.sofs, self.acks, self.ends, self.timelines = [], [], [], []
        t = FIRST_SOF
        for f in frames:
            line, ack_at, end = frame_timeline(f, t)
            self.sofs.append(t)
            self.acks.append(ack_at)
            self.ends.append(end)
            self.timelines.append(line)
            t = end + IFS
        self.cycles = self.ends[-1] + TAIL

    def chip_edges(self):
        """[(cycle, level)] of every change of the chip's ideal P0 output,
        starting from released (1) at cycle 0."""
        level, out = 1, []
        for line in self.timelines:
            for start, _, b, _ in line:
                if b != level:
                    out.append((start, b))
                    level = b
        return out

    def stimulus(self):
        """[(cycle, level)] of the scripted receiver on P0: 1, and 0 for the
        ACK slot of every frame it acknowledges."""
        out = [(0, 1)]
        for f, a in zip(self.frames, self.acks):
            if f.ack:
                out += [(a, 0), (a + NB, 1)]
        return out


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The TX words of one run, as the task sheet defines them. For each
    frame: a header word (bit 15 IDE, bit 14 BRS, bits 3..0 DLC); then the
    identifier, one word for a standard frame (bits 10..0), two for an
    extended one (identifier bits 28..16 in bits 12..0, then bits 15..0);
    then the data bytes two to a word, the first byte in bits 15..8, a last
    odd byte with 0 in bits 7..0. Payload only: nothing about the line."""
    words = []
    for f in frames:
        words.append((IDE_BIT if f.ide else 0) | (BRS_BIT if f.brs else 0) | f.dlc)
        if f.ide:
            words += [f.ident >> 16, f.ident & 0xFFFF]
        else:
            words.append(f.ident)
        d = f.data + ([0] if len(f.data) % 2 else [])
        words += [(d[i] << 8) | d[i + 1] for i in range(0, len(d), 2)]
    return words


def rx_wanted(frames):
    return [1 if f.ack else 0 for f in frames]


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name). P0
    must be made open-drain."""
    i, p0 = 0, None
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) == 1 and hits[0] in ("tx", "cycles", "stimulus", "inputs"):
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.match(r"(\d+)=(\w+)$", args[i + 1])
            if m and int(m.group(1)) == PIN:
                p0 = m.group(2)
        i += 2
    if p0 != "od":
        return "run_args.txt must make P0 open-drain (-mode 0=od)"
    return None


# ------------------------------------------------- from pe_sim to a capture

def p0_changes(sim_stdout):
    """[(cycle, level)] of the chip's P0 output from pe_sim's "pins CYCLE XX"
    lines: the level at the first line, then only the cycles it changed."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, level = int(part[1]), (int(part[2], 16) >> PIN) & 1
            if not out or out[-1][1] != level:
                out.append((cycle, level))
    return out


def rx_words(sim_stdout):
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "rx":
            out.append((int(part[1]), int(part[2])))
    return out


def bus_line(chip, stim):
    """The wired-AND of the chip's output and the scripted receiver, as
    [(cycle, level)] changes from cycle 0."""
    cycles = sorted(set(c for c, _ in chip) | set(c for c, _ in stim))
    out, ci, si, cl, sl = [], 0, 0, 1, 1
    for c in cycles:
        while ci < len(chip) and chip[ci][0] <= c:
            cl = chip[ci][1]
            ci += 1
        while si < len(stim) and stim[si][0] <= c:
            sl = stim[si][1]
            si += 1
        level = cl & sl
        if not out or out[-1][1] != level:
            out.append((c, level))
    if not out or out[0][0] != 0:
        out.insert(0, (0, 1))
    return out


def write_vcd(path, changes, cycles):
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for cycle, level in changes:
            if cycle < cycles:
                f.write("#%d\n%d!\n" % (cycle, level))
        f.write("#%d\n" % cycles)


def sigrok_annotations(changes, cycles):
    """The can-fd decoder on the capture: [(start sample, text)] of its
    field and warning annotations, in the order it gives them."""
    env = dict(os.environ, SIGROKDECODE_DIR=DECODERS)
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", DECODER,
               "-A", "can-fd=fields:warnings", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=900, env=env)
    if out.returncode != 0 or out.stderr.strip():
        raise RuntimeError("sigrok-cli failed: " + " ".join(out.stderr.split())[:300])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append((int(m.group(1)), m.group(3).strip()))
    return found


# ------------------------------------------------------------ the checks

def decoder_wants(f):
    """The annotation texts DSView's can-fd decoder gives for one ideal frame,
    in the order it gives them, and how many of them (from the start) are
    judged: all for an acknowledged frame, up to the CRC delimiter for one
    that was not."""
    c = Coded(f)
    base = f.base_id()
    out = ["Start of frame", "Identifier: %d (0x%x)" % (base, base)]
    if f.ide:
        ext = f.ident & 0x3FFFF
        out += ["Identifier extension bit: extended frame",
                "Extended Identifier: %d (0x%x)" % (ext, ext),
                "Full Identifier: %d (0x%x)" % (f.ident, f.ident),
                "Substitute remote request: 1",
                "Flexible data format: 1",
                "Remote requset substituion: 0"]
    else:
        out += ["Identifier extension bit: standard frame",
                "Flexible data format: 1",
                "Remote request subtitution"]
    out += ["Reserved bit 0: 0", "Bit rate switch: %d" % f.brs,
            "Error state indicator: 0", "Data length code: %d" % f.dlc]
    out += ["Data byte %d: 0x%02x" % (i, b) for i, b in enumerate(f.data)]
    out += ["Stuff count: %s" % c.sc_bits, "Parity: %d" % c.parity,
            "CRC-%d sequence: 0x%04x" % (c.width, c.crc), "CRC delimiter: 1"]
    judged = len(out)
    out += ["ACK slot: ACK", "ACK delimiter: 1", "End of frame"]
    return out, (len(out) if f.ack else judged)


def check_decoder(sched, line):
    """Every frame's annotations must be the ideal frame's, in order, and
    nothing else may be decoded."""
    anns = sigrok_annotations(line, sched.cycles)
    frames, cur = [], None
    errs = []
    for ss, text in anns:
        if text == "Start of frame":
            cur = [text]
            frames.append(cur)
        elif cur is None:
            errs.append("the decoder said %r before any frame" % text[:60])
            return errs
        else:
            cur.append(text)
    if len(frames) != len(sched.frames):
        errs.append("the decoder found %d frames, wanted %d" % (len(frames), len(sched.frames)))
    for k, (got, f) in enumerate(zip(frames, sched.frames)):
        want, judged = decoder_wants(f)
        if got[:judged] != want[:judged]:
            i = next((i for i in range(judged) if i >= len(got) or got[i] != want[i]), judged)
            errs.append("frame %d: the decoder said %r where %r was wanted"
                        % (k, got[i] if i < len(got) else "nothing more", want[i]))
            break
        if f.ack and len(got) != len(want):
            errs.append("frame %d: the decoder said %r after the end of frame" % (k, got[len(want)]))
            break
        if not f.ack and "End of frame" not in got[judged:]:
            errs.append("frame %d (not acknowledged): the decoder never ended the frame" % k)
            break
    return errs


def bit_at(sched, cycle):
    """A frame bit's description, for the messages."""
    for k, line in enumerate(sched.timelines):
        for start, length, b, name in line:
            if start - TOL <= cycle < start + length:
                return "frame %d, %s bit at %d" % (k, name, start)
    return "outside every frame"


def check_waveform(sched, changes):
    """The chip's P0 output against the ideal transmitter, edge by edge."""
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    if changes[0][1] != 1:
        return ["P0 does not start released"]
    got = changes[1:]
    want = sched.chip_edges()
    for i, (g, w) in enumerate(zip(got, want)):
        if g[1] != w[1] or abs(g[0] - w[0]) > TOL:
            return ["change %d of P0: %s at cycle %d, wanted %s at %d (limit +-%d; %s)"
                    % (i, "falls" if g[1] == 0 else "rises", g[0],
                       "a fall" if w[1] == 0 else "a rise", w[0], TOL, bit_at(sched, w[0]))]
    if len(got) > len(want):
        g = got[len(want)]
        return ["P0 %s at cycle %d, where nothing should change (%s)"
                % ("falls" if g[1] == 0 else "rises", g[0], bit_at(sched, g[0]))]
    if len(got) < len(want):
        w = want[len(got)]
        return ["P0 never makes change %d: %s at cycle %d (%s)"
                % (len(got), "a fall" if w[1] == 0 else "a rise", w[0], bit_at(sched, w[0]))]
    return []


def check_rx(sched, words):
    errs = []
    want = rx_wanted(sched.frames)
    for k, ((cycle, w), ew) in enumerate(zip(words, want)):
        if w != ew:
            errs.append("word %d is 0x%04x, wanted 0x%04x (frame %d was %sacknowledged)"
                        % (k, w, ew, k, "" if ew else "not "))
            break
        lo, hi = sched.acks[k], sched.ends[k]
        if not lo <= cycle <= hi:
            errs.append("word %d pushed at cycle %d, allowed %d (start of the ACK slot) to %d (end of the frame)"
                        % (k, cycle, lo, hi))
            break
    if len(words) != len(want):
        errs.append("%d words pushed, wanted %d" % (len(words), len(want)))
    return errs


def judge(sched, sim_stdout):
    """Every objection to one run, each marked with the check that made it."""
    changes = p0_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(sched, changes)]
    errs += ["rx: " + e for e in check_rx(sched, rx_words(sim_stdout))]
    if changes and changes[0][0] == 0:
        line = bus_line(changes, sched.stimulus())
        errs += ["decoder: " + e for e in check_decoder(sched, line)]
    return errs


# ------------------------------------------------------------------ running

def run_case(run_dir, args, frames):
    """(objections, cycles from P0's first change to its last or None)."""
    sched = Schedule(frames)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("0x%04x\n" % w for w in tx_words(frames)))
        st = os.path.join(d, "stimulus.txt")
        with open(st, "w") as f:
            f.write("".join("%d %02x\n" % (c, 0xFE | level) for c, level in sched.stimulus()))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "can_fd.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(sched.cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in p0_changes(out.stdout)[1:]]
    return judge(sched, out.stdout), (moved[-1] - moved[0] if moved else None)


def random_ident(rng, ide):
    """Any identifier whose base identifier's bits 10..4 are not all 1 (the
    task sheet's rule)."""
    while True:
        ident = rng.randrange(1 << (29 if ide else 11))
        base = ident >> 18 if ide else ident
        if base & 0x7F0 != 0x7F0:
            return ident


def random_frame(rng, ack=True):
    ide = rng.random() < 0.4
    brs = rng.random() < 0.7
    dlc = rng.choice(list(range(MAX_DLC + 1)) + [10, 10, 9, 8])
    kind = rng.random()
    n = DLC_LEN[dlc]
    if kind < 0.6:
        data = [rng.randrange(256) for _ in range(n)]
    elif kind < 0.8:
        data = [rng.choice([0x00, 0xFF, 0x0F, 0xF0, 0x80, 0x7F]) for _ in range(n)]
    else:
        v = rng.choice([0x00, 0xFF, 0x55, 0x83])
        data = [v] * n
    return Frame(ide, brs, dlc, random_ident(rng, ide), data, ack)


def cases_for(seed):
    """(name, frames): fixed cases, then seeded random ones."""
    fixed = [
        ("the task sheet's example", [Frame(0, 1, 1, 0x020, [0xF0])]),
        ("the task sheet's words",
         [Frame(0, 1, 1, 0x020, [0xF0]), Frame(1, 0, 3, 0x1ABCDE12, [0x11, 0x22, 0x33])]),
        ("no data, standard and extended, both rates",
         [Frame(0, 1, 0, 0x000, []), Frame(1, 0, 0, 0x00000000, []),
          Frame(0, 0, 0, 0x7EF, []), Frame(1, 1, 0, 0x1FBFFFFF, [])]),
        ("16 bytes of 0x00 at the data rate", [Frame(0, 1, 10, 0x100, [0x00] * 16)]),
        ("16 bytes of 0xFF at the nominal rate", [Frame(1, 0, 10, 0x0F0F0F0F, [0xFF] * 16)]),
        ("8, 12 and 16 bytes: DLC 8, 9 and 10",
         [Frame(0, 1, 8, 0x3C3, list(range(8))), Frame(1, 1, 9, 0x3C3, list(range(12))),
          Frame(0, 1, 10, 0x3C4, list(range(16)))]),
        ("1, 3, 5 and 7 bytes (an odd byte in the last word)",
         [Frame(0, 1, n, 0x055 + n, [0xA0 + k for k in range(n)]) for n in (1, 3, 5, 7)]),
        ("a frame nobody acknowledges between two that are",
         [Frame(0, 1, 2, 0x010, [0x12, 0x34]), Frame(1, 1, 9, 0x0ABCDEF0, [0x5A] * 12, ack=False),
          Frame(0, 0, 2, 0x011, [0x56, 0x78])]),
        ("not acknowledged, both rates, last frame too",
         [Frame(0, 0, 8, 0x222, [0xFF] * 8, ack=False), Frame(1, 1, 10, 0x1555AAAA, [0x00] * 16, ack=False)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_FRAMES)
        frames = [random_frame(rng, ack=rng.random() > 0.2) for _ in range(count)]
        rand.append(("random %d" % n, frames))
    cases = fixed + rand
    assert all(f.dlc <= MAX_DLC for _, frames in cases for f in frames)
    return cases


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    if not os.path.isdir(os.path.join(DECODERS, "can-fd")):
        setup.append("the can-fd decoder is not in %s" % DECODERS)
    for name in ("pe_sim", "can_fd.s", "run_args.txt"):
        if not os.path.exists(os.path.join(run_dir, name)):
            setup.append("%s is missing from %s" % (name, run_dir))
    args = []
    if not setup:
        try:
            with open(os.path.join(run_dir, "run_args.txt")) as f:
                lines = [l for l in f.read().splitlines() if l.strip()]
            if len(lines) > 1:
                setup.append("run_args.txt must be one line")
            args = shlex.split(" ".join(lines))
        except (OSError, ValueError) as e:
            setup.append("run_args.txt: %s" % e)
        problem = args_problem(args)
        if problem:
            setup.append(problem)
    if setup:
        print("setup: FAIL: " + "; ".join(setup))
        print("ACCEPT FAIL")
        return 1
    failed, rate = 0, None
    for n, (name, frames) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, frames)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (sum(len(f.data) for f in frames), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "rx:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        size = sum(len(f.data) for f in frames)
        print("case %d (%s: %d frame%s, %d byte%s): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
