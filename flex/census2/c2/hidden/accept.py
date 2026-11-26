#!/usr/bin/env python3
"""Hidden acceptance test for the blind C2 master firmware (decoder `C2`, from DSView).

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (c2.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim.

The chip is the master of a Silicon Labs C2 debug interface. It drives C2CK
(P0, push-pull) and, in its own fields, C2D (P1, open-drain with a pull-up).
A scripted C2 device answers in its fields (ADDRESS of an Address Read,
WAIT, DATA of a Data Read) at fixed times, given to the simulator as
-stimulus. The task sheet fixes when every strobe belongs, so the script
lines up.

For each case (a list of C2 frames) the test
  1. builds the TX words the task sheet defines and the device's stimulus,
     and first requires the C2 decoder to decode an ideal capture of the
     whole bus (an ideal master plus that stimulus) to exactly the wanted
     frames, so the input is a real instance of the protocol;
  2. runs RUN_DIR/pe_sim on RUN_DIR/c2.s with those words and the stimulus;
  3. works out the level of both lines in every cycle (C2CK: the chip's
     output; C2D: the chip's output AND the device's, a wired-AND with a
     pull-up);
  4. checks the waveform directly: the device reset, every strobe's rising
     edge within +-2 cycles of its place, low and high times, no other
     C2CK edge, no change of the chip's C2D output from the fall to the
     rise of any of its own strobes, the chip's C2D bit at every rising
     edge of its own fields, and C2D released by the chip everywhere
     outside its own fields;
  5. turns both lines into a logic capture (a VCD at 50 MHz, one sample per
     cycle) and has sigrok-cli's C2 decoder read it: its annotations must
     be exactly the wanted fields and frames, in order, nothing extra. A
     C2 device puts each bit out just after the rising edge of its strobe,
     and this decoder reads C2D in the sample of that edge, so in the copy
     handed to the decoder C2D shows, through each of the device's strobes,
     the level the master reads 6 cycles (120 ns) after its rising edge
     (README.md);
  6. requires the "rx" words to be the bytes the device sent, in order,
     nothing extra.

Prints one line per case, then for the last passing case
    RATE bytes=<payload bytes> cycles=<cycles from first to last pin change>
and a last line ACCEPT PASS or ACCEPT FAIL. Exit status 0 only on a full
pass. Python standard library and sigrok-cli only."""
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
DECODERS = os.environ.get(
    "C2_DECODERS", "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders")

CLOCK_HZ = 50_000_000      # core clock: one cycle = 20 ns
SLOT = 50                  # cycles per strobe slot (1 us)
R0 = 2000                  # ideal cycle of the rising edge of slot 0
TOL = 2                    # cycles a rising edge may be from its place
DEV_DELAY = 3              # the device changes C2D this long after an ideal rising edge
READ_AT = 6                # the decoder is shown the level this long after a device strobe's rise
LOW_MIN, LOW_MAX = 4, 40   # C2CK low time of a strobe, cycles (80 ns to 800 ns)
HIGH_MIN = 6               # C2CK high time between two strobes, cycles (120 ns)
RESET_FALL_BY = 300        # C2CK must fall for the device reset by this cycle
RESET_LOW_MIN = 1100       # and stay low at least this long (22 us)
RESET_RISE_BY = 1800       # and rise again by this cycle
MAX_FRAMES = 10

C2CK = 0                   # P0
C2D = 1                    # P1
REQUIRED_MODES = {0: "pp", 1: "od"}
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")

AW, AR, DW, DR = "AW", "AR", "DW", "DR"
INS = {DR: 0b00, DW: 0b01, AR: 0b10, AW: 0b11}       # the C2 instruction codes
CMD = {AW: 0x1000, AR: 0x2000, DW: 0x3000, DR: 0x4000}  # the task sheet's command words


# ---------------------------------------------------------------- the frames
#
# A frame is (kind, data): AW with the address written, AR with the byte the
# device returns, DW with the list of bytes written, DR with the list of
# bytes the device returns (1 to 4 bytes for DW and DR).

def lsb_bits(value, n):
    return [(value >> k) & 1 for k in range(n)]


def strobes(frame):
    """The strobes of one frame: [(field, who, bit)], who is 'none' (START,
    STOP: nobody drives C2D), 'chip' or 'dev'. Every field LSB first."""
    kind, data = frame
    out = [("START", "none", 1)]
    out += [("INS", "chip", b) for b in lsb_bits(INS[kind], 2)]
    if kind == AW:
        out += [("ADDRESS", "chip", b) for b in lsb_bits(data, 8)]
    elif kind == AR:
        out += [("ADDRESS", "dev", b) for b in lsb_bits(data, 8)]
    elif kind == DW:
        out += [("LENGTH", "chip", b) for b in lsb_bits(len(data) - 1, 2)]
        out += [("DATA", "chip", b) for byte in data for b in lsb_bits(byte, 8)]
        out += [("WAIT", "dev", 1)]
    else:
        out += [("LENGTH", "chip", b) for b in lsb_bits(len(data) - 1, 2)]
        out += [("WAIT", "dev", 1)]
        out += [("DATA", "dev", b) for byte in data for b in lsb_bits(byte, 8)]
    out += [("STOP", "none", 1)]
    return out


def R(slot):
    """Ideal cycle of the rising edge of a strobe in this slot."""
    return R0 + SLOT * slot


def schedule(frames):
    """([(slot, frame index, field, who, bit)] for every strobe of the run,
    the slot after the last frame's idle slot). Frame 0 starts in slot 0;
    each frame starts one idle slot after the previous one's STOP."""
    out, slot = [], 0
    for n, frame in enumerate(frames):
        for field, who, b in strobes(frame):
            out.append((slot, n, field, who, b))
            slot += 1
        slot += 1          # the idle slot
    return out, slot


def run_cycles(frames):
    return R(schedule(frames)[1] + 2)


def payload_bytes(frames):
    return sum(1 if k in (AW, AR) else len(d) for k, d in frames)


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The task sheet's TX words: one command word per frame (0x1000 | address
    for an Address Write, 0x2000 for an Address Read, 0x3000 | n and then n
    words, one byte each, for a Data Write, 0x4000 | n for a Data Read).
    Payload only: nothing about the line."""
    words = []
    for kind, data in frames:
        if kind == AW:
            words.append(CMD[AW] | data)
        elif kind == AR:
            words.append(CMD[AR])
        elif kind == DW:
            words.append(CMD[DW] | len(data))
            words += list(data)
        else:
            words.append(CMD[DR] | len(data))
    return words


def rx_words(frames):
    """One word per byte the device sends, in order, the byte in bits 7..0."""
    out = []
    for kind, data in frames:
        if kind == AR:
            out.append(data)
        elif kind == DR:
            out += list(data)
    return out


# ------------------------------------------------------------- the device

def stimulus(frames):
    """[(cycle, levels)]: the device's side of the pins. For each of its
    strobes it drives C2D with its bit from DEV_DELAY cycles after the ideal
    rising edge of that strobe to DEV_DELAY cycles after the ideal rising
    edge of the next strobe (a device field is always followed by another
    strobe of the same frame); elsewhere it leaves C2D to the pull-up (1)."""
    sched, _ = schedule(frames)
    level = {}
    for i, (slot, _, _, who, b) in enumerate(sched):
        if who != "dev":
            continue
        for c in range(R(slot) + DEV_DELAY, R(sched[i + 1][0]) + DEV_DELAY):
            level[c] = b
    lines, cur = [(0, 0xFF)], 1
    for c in sorted(level):
        if level[c] != cur:
            lines.append((c, 0xFF & ~((1 - level[c]) << C2D)))
            cur = level[c]
        if c + 1 not in level and cur != 1:
            lines.append((c + 1, 0xFF))
            cur = 1
    return lines


# -------------------------------------------------------- run_args.txt

def flag_name(arg):
    """The pe_sim flag an argument names, or None (prefixes allowed)."""
    if not arg.startswith("-"):
        return None
    name = arg.lstrip("-")
    hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
    return hits[0] if len(hits) == 1 else None


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name)."""
    i = 0
    while i < len(args):
        name = flag_name(args[i])
        if name in ("tx", "cycles", "stimulus", "inputs"):
            return "run_args.txt must not give -%s: the test does" % name
        if name not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        i += 2
    return None


def modes_of(args):
    """{pin: mode} from the -mode flags (pe_sim's default is input)."""
    modes = {p: "in" for p in range(8)}
    for i in range(0, len(args) - 1, 2):
        if flag_name(args[i]) == "mode":
            p, _, m = args[i + 1].partition("=")
            if m not in ("pp", "od", "in") or not 0 <= int(p) < 8:
                raise ValueError(args[i + 1])
            modes[int(p)] = m
    return modes


def modes_problem(modes):
    bad = ["P%d=%s" % (p, modes[p]) for p, m in REQUIRED_MODES.items() if modes[p] != m]
    if bad:
        return "pin modes must be P0 pp (C2CK) and P1 od (C2D); got " + ", ".join(bad)
    return None


# ------------------------------------------------- from pe_sim to the wire

def parse_sim(stdout):
    """([(cycle, outputs)], [rx words])."""
    outs, rx = [], []
    for line in stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            outs.append((int(part[1]), int(part[2], 16)))
        elif len(part) == 3 and part[0] == "rx":
            rx.append(int(part[2]))
    return outs, rx


def per_cycle(changes, cycles, initial):
    """Expand [(cycle, value)] into one value per cycle."""
    vals, cur, i = [], initial, 0
    changes = sorted(changes)
    for c in range(cycles):
        while i < len(changes) and changes[i][0] <= c:
            cur = changes[i][1]
            i += 1
        vals.append(cur)
    return vals


def bit(v, p):
    return (v >> p) & 1


def lines_of(out, stim):
    """(C2CK, C2D) levels per cycle: C2CK is push-pull, C2D a wired-AND of
    the chip's open-drain output and the device."""
    clk = [bit(o, C2CK) for o in out]
    dat = [bit(o, C2D) & bit(s, C2D) for o, s in zip(out, stim)]
    return clk, dat


# ------------------------------------------------------------- the checks

def check_waveform(frames, out):
    """The limits of the task sheet, from the chip's outputs. Returns the
    objections."""
    errs = []
    cycles = len(out)
    clk = [bit(o, C2CK) for o in out]
    dat = [bit(o, C2D) for o in out]
    falls = [c for c in range(1, cycles) if clk[c - 1] and not clk[c]]
    rises = [c for c in range(1, cycles) if clk[c] and not clk[c - 1]]
    sched, _ = schedule(frames)

    # The device reset.
    if clk[0] != 1:
        errs.append("C2CK is low at cycle 0")
        return errs
    if not falls or falls[0] > RESET_FALL_BY:
        errs.append("C2CK does not fall for the device reset by cycle %d" % RESET_FALL_BY)
        return errs
    if not rises or rises[0] > RESET_RISE_BY:
        errs.append("C2CK does not rise at the end of the device reset by cycle %d" % RESET_RISE_BY)
        return errs
    if rises[0] - falls[0] < RESET_LOW_MIN:
        errs.append("the device reset holds C2CK low for %d cycles, at least %d wanted"
                    % (rises[0] - falls[0], RESET_LOW_MIN))
    strobe_falls, strobe_rises = falls[1:], rises[1:]

    # One strobe per slot of the schedule, and nothing else.
    if len(strobe_rises) != len(sched) or len(strobe_falls) != len(sched):
        errs.append("C2CK has %d strobes after the reset, wanted %d"
                    % (min(len(strobe_rises), len(strobe_falls)), len(sched)))
    prev_rise = rises[0]
    for k, (slot, n, field, _, _) in enumerate(sched[:min(len(strobe_rises), len(strobe_falls))]):
        f, e = strobe_falls[k], strobe_rises[k]
        if abs(e - R(slot)) > TOL:
            errs.append("strobe %d (frame %d, %s) rises at cycle %d, ideal %d (limit +-%d)"
                        % (k, n, field, e, R(slot), TOL))
            break
        if not LOW_MIN <= e - f <= LOW_MAX:
            errs.append("strobe %d (frame %d, %s) is low for %d cycles (%d to %d allowed)"
                        % (k, n, field, e - f, LOW_MIN, LOW_MAX))
            break
        if f - prev_rise < HIGH_MIN:
            errs.append("C2CK high for only %d cycles before strobe %d (at least %d)"
                        % (f - prev_rise, k, HIGH_MIN))
            break
        prev_rise = e
    if clk[-1] != 1:
        errs.append("C2CK is low at the end of the run")

    if len(strobe_rises) != len(sched) or len(strobe_falls) != len(sched) or errs:
        return errs

    # The chip's C2D output: low only while the chip owns C2D, that is from
    # the cycle after the rising edge of the strobe before a run of the
    # chip's strobes to the cycle before the falling edge of the strobe
    # after it.
    owned = [False] * cycles
    for k, (_, _, _, who, _) in enumerate(sched):
        if who == "chip" and sched[k - 1][3] != "chip":
            m = k
            while sched[m + 1][3] == "chip":
                m += 1
            for c in range(strobe_rises[k - 1] + 1, strobe_falls[m + 1]):
                owned[c] = True
    for c in range(cycles):
        if not dat[c] and not owned[c]:
            where = "outside the chip's own fields"
            for k, (slot, n, field, who, _) in enumerate(sched):
                if strobe_falls[k] <= c <= strobe_rises[k]:
                    where = "during the %s strobe of frame %d (falls %d, rises %d)" % (
                        field, n, strobe_falls[k], strobe_rises[k])
            if c < strobe_falls[0]:
                where = "before the first frame"
            errs.append("the chip pulls C2D low at cycle %d, %s" % (c, where))
            break

    # Setup and hold: no change from the fall to the rise of the chip's
    # strobes; and the chip's bit at each rising edge.
    for k, (slot, n, field, who, b) in enumerate(sched):
        if who != "chip":
            continue
        f, e = strobe_falls[k], strobe_rises[k]
        moved = [c for c in range(f, e + 1) if dat[c] != dat[c - 1]]
        if moved:
            errs.append("frame %d, %s: the chip's C2D output changes at cycle %d, while C2CK is "
                        "low or rising (falls %d, rises %d)" % (n, field, moved[0], f, e))
            break
        if dat[e] != b:
            errs.append("frame %d, %s: the chip's C2D output is %d at the rising edge (cycle %d), wanted %d"
                        % (n, field, dat[e], e, b))
            break
    return errs


def vcd_text(clk, dat):
    out = ["$timescale %d ns $end" % (1_000_000_000 // CLOCK_HZ),
           "$scope module c2 $end",
           "$var wire 1 ! C2CK $end",
           "$var wire 1 \" C2D $end",
           "$upscope $end",
           "$enddefinitions $end"]
    pc = pd = None
    for c, (a, b) in enumerate(zip(clk, dat)):
        if a != pc or b != pd:
            out.append("#%d" % c)
            if a != pc:
                out.append("%d!" % a)
            if b != pd:
                out.append("%d\"" % b)
            pc, pd = a, b
    out.append("#%d" % len(clk))
    return "\n".join(out) + "\n"


def sigrok_annotations(clk, dat):
    """The decoder's annotations: ([raw field texts], [frame texts])."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "c2.vcd")
        with open(path, "w") as f:
            f.write(vcd_text(clk, dat))
        env = dict(os.environ, SIGROKDECODE_DIR=DECODERS, PYTHONDONTWRITEBYTECODE="1")
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "C2:c2ck=C2CK:c2d=C2D", "-A", "C2"]
        run = subprocess.run(cmd, capture_output=True, text=True, timeout=300, env=env)
    if run.returncode != 0 or "srd:" in run.stderr or "Traceback" in run.stderr:
        raise RuntimeError("sigrok-cli failed: " + " ".join(run.stderr.split())[:200])
    raw, frames = [], []
    for line in run.stdout.splitlines():
        m = re.match(r"C2-1: (.*)$", line)
        if not m:
            continue
        text = m.group(1).strip()
        if re.match(r"(Read|Write)(Data|Address)\(", text):
            frames.append(text)
        else:
            raw.append(text)
    return raw, frames


def le_value(data):
    return sum(b << (8 * i) for i, b in enumerate(data))


def want_annotations(frames):
    """What the decoder must print: its field texts and one text per frame."""
    raw, out = ["Reset"], []
    for kind, data in frames:
        raw += ["Start", "%d" % INS[kind]]
        if kind == AW:
            raw += ["%02X" % data]
            out.append("WriteAddress(0x%02X)" % data)
        elif kind == AR:
            raw += ["%02X" % data]
            out.append("ReadAddress()=0x%02X" % data)
        elif kind == DW:
            raw += ["%d" % (len(data) - 1)] + ["%02X" % b for b in data] + ["Wait"]
            out.append("WriteData(0x%02X,%d)" % (le_value(data), len(data)))
        else:
            raw += ["%d" % (len(data) - 1), "Wait"] + ["%02X" % b for b in data]
            out.append("ReadData(%d)=0x%02X" % (len(data), le_value(data)))
        raw += ["End"]
    return raw, out


def compare(got, want, what):
    if got == want:
        return []
    for i, (g, w) in enumerate(zip(got, want)):
        if g != w:
            return ["%s %d is %r, wanted %r" % (what, i, g, w)]
    return ["%d %ss, wanted %d (first extra or missing: %r)"
            % (len(got), what, len(want), (got[len(want):] or want[len(got):])[0])]


def decoder_view(frames, clk, dat):
    """The capture handed to the decoder: C2CK as it is, and C2D as it is
    except through each of the device's strobes, from the cycle C2CK falls
    to READ_AT cycles after it rises, where it shows the level at that
    later cycle: the bit the device answers that strobe with, which a C2
    master reads after the rising edge and the decoder looks for in the
    sample of the rising edge itself. Strobes are taken from C2CK as it is,
    after the reset; nothing changes if they are not the scheduled ones."""
    sched, _ = schedule(frames)
    cycles = len(clk)
    falls = [c for c in range(1, cycles) if clk[c - 1] and not clk[c]]
    rises = [c for c in range(1, cycles) if clk[c] and not clk[c - 1]]
    view = list(dat)
    if len(falls) == len(sched) + 1 and len(rises) == len(sched) + 1:
        for k, (_, _, _, who, _) in enumerate(sched):
            f, e = falls[k + 1], rises[k + 1]
            if who == "dev" and e + READ_AT < cycles:
                for c in range(f, e + READ_AT):
                    view[c] = dat[e + READ_AT]
    return view


def check_decoder(frames, clk, dat):
    raw, got = sigrok_annotations(clk, decoder_view(frames, clk, dat))
    want_raw, want = want_annotations(frames)
    return compare(got, want, "frame") or compare(raw, want_raw, "field")


def ideal_outputs(frames, cycles):
    """An ideal master's outputs per cycle: C2CK falls at cycle 1 for the
    reset and rises at 1500; each strobe is low the 20 cycles before its
    rising edge; the chip pulls C2D low for a 0 from 10 cycles after the
    rising edge before to 10 cycles after its own. Used only to check the
    stimulus (step 1)."""
    sched, _ = schedule(frames)
    clk = [1] * cycles
    dat = [1] * cycles
    for c in range(1, 1500):
        clk[c] = 0
    for slot, _, _, who, b in sched:
        for c in range(R(slot) - 20, R(slot)):
            clk[c] = 0
        if who == "chip" and b == 0:
            for c in range(R(slot - 1) + 10, R(slot) + 10):
                dat[c] = 0
    return [(k << C2CK) | (d << C2D) | 0xFC for k, d in zip(clk, dat)]


def check_stimulus(frames):
    """The decoder must read the ideal bus (an ideal master plus the
    stimulus) as the wanted frames: the scripted device is a real C2 device."""
    cycles = run_cycles(frames)
    out = ideal_outputs(frames, cycles)
    stim = per_cycle(stimulus(frames), cycles, 0xFF)
    clk, dat = lines_of(out, stim)
    return check_waveform(frames, out) + check_decoder(frames, clk, dat)


def check_rx(frames, rx):
    return compare(["0x%04x" % w for w in rx], ["0x%04x" % w for w in rx_words(frames)], "rx word")


def judge(frames, sim_stdout, cycles):
    outs, rx = parse_sim(sim_stdout)
    if not outs or outs[0][0] != 0:
        return ["waveform: no pin levels at cycle 0 in the simulator's output"]
    out = per_cycle(outs, cycles, 0xFF)
    stim = per_cycle(stimulus(frames), cycles, 0xFF)
    clk, dat = lines_of(out, stim)
    errs = ["waveform: " + e for e in check_waveform(frames, out)]
    try:
        errs += ["decoder: " + e for e in check_decoder(frames, clk, dat)]
    except Exception as e:  # a decoder that falls over is a failure
        errs.append("decoder: %s: %s" % (type(e).__name__, e))
    errs += ["rx: " + e for e in check_rx(frames, rx)]
    return errs


# ------------------------------------------------------------------ running

def run_case(run_dir, args, frames):
    """(objections, cycles from the first pin change to the last or None)."""
    bad = check_stimulus(frames)
    if bad:
        return ["judge: the ideal bus does not decode: " + bad[0]], None
    cycles = run_cycles(frames)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in tx_words(frames)))
        st = os.path.join(d, "stimulus.txt")
        with open(st, "w") as f:
            f.write("".join("%d %02x\n" % (c, v) for c, v in stimulus(frames)))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "c2.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(cycles)] + args
        try:
            run = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if run.returncode != 0:
        said = " ".join(run.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (run.returncode, said[:200])], None
    outs, _ = parse_sim(run.stdout)
    moved = [c for c, _ in outs[1:]]
    return judge(frames, run.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def random_frame(rng):
    kind = rng.choice((AW, AR, DW, DR))
    if kind in (AW, AR):
        return (kind, rng.randrange(256))
    return (kind, [rng.randrange(256) for _ in range(rng.randint(1, 4))])


def cases_for(seed):
    """(name, frames): fixed cases, then seeded random ones."""
    fixed = [
        ("the task sheet's example", [(AW, 0x00), (DR, [0x30])]),
        ("one address read", [(AR, 0xA5)]),
        ("all four, ones and zeros", [(AW, 0xFF), (AR, 0x00), (DW, [0x00]), (DR, [0xFF]),
                                      (AW, 0x00), (AR, 0xFF), (DW, [0xFF]), (DR, [0x00])]),
        ("four bytes each way", [(DW, [0x12, 0x34, 0x56, 0x78]), (DR, [0x9A, 0xBC, 0xDE, 0xF0])]),
        ("every length", [(DW, [0x01]), (DR, [0x80]), (DW, [0x55, 0xAA]), (DR, [0xAA, 0x55]),
                          (DW, [0x0F, 0xF0, 0x3C]), (DR, [0xC3, 0x5A, 0xA5]),
                          (DW, [0xFE, 0x7F, 0x01, 0x80]), (DR, [0x01, 0x02, 0x04, 0x08])]),
        ("a flash erase sequence", [(AW, 0x02), (DW, [0x02]), (DW, [0x04]), (DW, [0x01]),
                                    (AW, 0xB4), (DW, [0x03]), (AR, 0x02), (AR, 0x01),
                                    (DR, [0x0D]), (AW, 0x00)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_FRAMES) if n % 2 else rng.randint(1, 3)
        rand.append(("random %d" % n, [random_frame(rng) for _ in range(count)]))
    return fixed + rand


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    if not os.path.isdir(os.path.join(DECODERS, "C2")):
        setup.append("the C2 decoder is not in %s" % DECODERS)
    for name in ("pe_sim", "c2.s", "run_args.txt"):
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
        else:
            try:
                problem = modes_problem(modes_of(args))
                if problem:
                    setup.append(problem)
            except (ValueError, KeyError) as e:
                setup.append("run_args.txt: bad -mode value (%s)" % e)
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
            rate = (payload_bytes(frames), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d frame%s, %d byte%s): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s",
                 payload_bytes(frames), "" if payload_bytes(frames) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
