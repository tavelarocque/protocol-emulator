#!/usr/bin/env python3
"""Hidden acceptance test for the blind FrSky PXX1 transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (pxx1.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet fixes
what the TX words mean, and this test builds them itself.

For each case (a list of frames, each a receiver number, three flag bytes
and eight 12-bit channel values) the test
  1. builds the TX words the task sheet defines: ten per frame (receiver
     number and flag 1, flag 2 and the extra flags, then the eight channels),
  2. runs RUN_DIR/pe_sim on RUN_DIR/pxx1.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per core clock cycle, 50 MHz), exactly as printed, and adds one
     falling edge at the very end of the capture, so that the decoder, which
     reads each bit from one falling edge to the next, can read the last bit
     of the last frame (see README.md),
  4. has DSView's `pxx1` decoder, run by sigrok-cli, read it and requires
     its annotations (every bit, every byte, every field) to be exactly
     those of the wanted frames, in order, with nothing extra,
  5. checks, from the pin changes themselves, what the decoder does not:
     every low pulse 8 us and every bit period 16 or 24 us, each within
     +-0.5 us, every bit of every frame (header, stuffing, CRC, tail), the
     start of the first frame, the frame period, and a quiet high line after
     the last frame.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>
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

DECODERS = "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders"
DECODER = "pxx1:data=P0"

CLOCK_HZ = 50_000_000        # core clock: one cycle = 20 ns
US = CLOCK_HZ // 1_000_000   # 50 cycles a microsecond
LOW = 8 * US                 # every bit starts with the line low for 8 us
PERIOD = {0: 16 * US, 1: 24 * US}   # falling edge to falling edge
TOL = US // 2                # 0.5 us = 25 cycles, on every low pulse and period
SPLIT = 40 * US              # a period longer than this ends a frame
START_MIN = 5_000            # the first frame's first fall, not before this cycle
START_MAX = 500_000          # and not after this one
FRAME_MIN = 400_000          # 8 ms: first fall of a frame to the next frame's
FRAME_MAX = 500_000          # 10 ms
FRAME_NOMINAL = 450_000      # 9 ms
MAX_FRAMES = 4
HEAD = 0x7E
PIN = 0                      # P0
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
TYPES = ["FCC", "EU", "EU+", "AU+"]


# ---------------------------------------------------------------- the frame

def frame_bytes(frame):
    """The 16 bytes the CRC covers: receiver number, flag 1, flag 2, the
    eight channels packed two to three bytes, the extra flags."""
    rx, flag1, flag2, extra, ch = frame
    out = [rx, flag1, flag2]
    for i in range(0, 8, 2):
        a, b = ch[i], ch[i + 1]
        out += [a & 0xFF, ((a >> 8) & 0x0F) | ((b & 0x0F) << 4), (b >> 4) & 0xFF]
    out.append(extra)
    return out


def crc_table_entry(v):
    """T[v] of the PXX1 CRC: eight steps of the reflected CCITT register
    (polynomial 0x8408) started from v. Computed bit by bit here; the task
    sheet gives it as two carry-less products, and selftest.py checks that
    the two agree on all 256 values."""
    c = v
    for _ in range(8):
        c = (c >> 1) ^ (0x8408 if c & 1 else 0)
    return c


def crc16(data):
    crc = 0
    for b in data:
        crc = ((crc << 8) & 0xFFFF) ^ crc_table_entry(((crc >> 8) ^ b) & 0xFF)
    return crc


def line_bits(frame):
    """[(bit, kind)] for one frame in the order sent. kind is 'head', 'data'
    (byte index, bit index), 'crc', 'stuff' or 'tail'. The header and tail
    0x7E are not stuffed; after five 1s in a row anywhere from the first bit
    of the receiver number to the last bit of the CRC, a 0 is put in, and
    that 0 starts the count again."""
    data = frame_bytes(frame)
    crc = crc16(data)
    out = [((HEAD >> k) & 1, ("head", 7 - k)) for k in range(7, -1, -1)]
    ones = 0
    body = [(b, ("byte", i)) for i, b in enumerate(data)] + \
           [(crc >> 8, ("crc", 0)), (crc & 0xFF, ("crc", 1))]
    for value, (what, idx) in body:
        for k in range(7, -1, -1):
            bit = (value >> k) & 1
            out.append((bit, (what, idx, k)))
            if bit:
                ones += 1
                if ones == 5:
                    out.append((0, ("stuff",)))
                    ones = 0
            else:
                ones = 0
    out += [((HEAD >> k) & 1, ("tail", 7 - k)) for k in range(7, -1, -1)]
    return out


def describe(kind):
    if kind[0] == "head":
        return "header bit %d" % kind[1]
    if kind[0] == "tail":
        return "closing 0x7E bit %d" % kind[1]
    if kind[0] == "stuff":
        return "a stuffed 0"
    if kind[0] == "byte":
        return "bit %d of byte %d" % (kind[2], kind[1])
    return "bit %d of the CRC's %s byte" % (kind[2], "high" if kind[1] == 0 else "low")


def stuff_after_crc(frame):
    """True when the CRC's last bit ends a run of five 1s, so that a stuffed
    0 follows the CRC directly."""
    bits = line_bits(frame)
    return bits[-9][1] == ("stuff",)


# ------------------------------------------------- what the decoder will say

def decoder_wants(frame):
    """(bit texts, byte texts, field texts) that DSView's pxx1 decoder gives
    for one correct frame, followed by the start of a later one.

    Two things in it come from the decoder, not from the protocol, and are
    checked against sigrok on the ideal waveforms by selftest.py:
    - The decoder stops removing stuffed bits once it has counted 19 bytes
      (header to CRC). When the CRC's last bit ends a run of five 1s, the
      stuffed 0 after it is read as data: the closing byte then reads 0x3F
      and the decoder says "Header error" instead of "Stop Header".
    - The channel list shows the first channel of each pair with the two
      nibbles of its low byte swapped (it reads nibbles 3, 1, 0 for nibbles
      3, 0, 1). The bytes row is unaffected."""
    bits = line_bits(frame)
    quirk = stuff_after_crc(frame)
    bit_texts = []
    for n, (bit, kind) in enumerate(bits):
        if kind == ("stuff",) and not (quirk and n == len(bits) - 9):
            bit_texts.append("S")
        else:
            bit_texts.append(str(bit))
    data = frame_bytes(frame)
    crc = crc16(data)
    byte_texts = ["%02X" % b for b in [HEAD] + data + [crc >> 8, crc & 0xFF]]
    byte_texts.append("3F" if quirk else "7E")
    rx, flag1, flag2, extra, ch = frame
    onoff = lambda v: "On" if v else "Off"
    yesno = lambda v: "Yes" if v else "No"
    pairs, upper = [], False
    for i in range(4):
        b0, b1, b2 = data[3 + 3 * i: 6 + 3 * i]
        n0, n1, n2, n3, n4, n5 = b0 >> 4, b0 & 15, b1 >> 4, b1 & 15, b2 >> 4, b2 & 15
        ch1 = n3 << 8 | n1 << 4 | n0
        ch2 = n4 << 8 | n5 << 4 | n2
        pairs.append("%04u %04u" % (ch1, ch2))
        upper = upper or ch1 > 2048
    fields = [
        "Start Header",
        "Model ID: %d" % rx,
        "Type: %s" % TYPES[flag1 >> 6],
        "Range Check: %s" % onoff(flag1 >> 5 & 1),
        "FailSafe: %s" % onoff(flag1 >> 4 & 1),
        "CountryCode: %u" % (flag1 >> 1 & 7),
        "Bind: %s" % onoff(flag1 & 1),
        "Flag2: %u" % flag2,
        "Channels %s: [%s]" % ("(9-16)" if upper else "(1-8)", " ".join(pairs)),
        "Reserved",
        "EUPlus: %s" % yesno(extra >> 6 & 1),
        "SPort: %s" % ("Disabled" if extra >> 5 & 1 else "Enable"),
        "PowerLevel: %u" % (extra >> 3 & 3),
        "RX HighChannel: %s" % yesno(extra >> 2 & 1),
        "Telemetry: %s" % ("Off" if extra >> 1 & 1 else "On"),
        "ExternalAntena: %s" % yesno(extra & 1),
        "CRC: 0x%04X" % crc,
        "Header error" if quirk else "Stop Header",
    ]
    return bit_texts, byte_texts, fields


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The TX words of one run, as the task sheet defines them: per frame,
    flag 1 << 8 | receiver number, extra flags << 8 | flag 2, then the eight
    channel values. Payload only: nothing about the line."""
    words = []
    for rx, flag1, flag2, extra, ch in frames:
        words += [flag1 << 8 | rx, extra << 8 | flag2] + list(ch)
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name), and
    must make P0 push-pull, as the task sheet says (pe_sim's default is
    input, whose printed output changes would drive nothing)."""
    i = 0
    p0_mode = None
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits == ["tx"] or hits == ["cycles"]:
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            pin, _, mode = args[i + 1].partition("=")
            if pin.strip() == str(PIN):
                p0_mode = mode.strip()
        i += 2
    if p0_mode != "pp":
        return "run_args.txt must make P0 push-pull (-mode 0=pp), as the task sheet says; it gives %s" \
            % ("no mode for P0" if p0_mode is None else "-mode 0=%s" % p0_mode)
    return None


# ------------------------------------------------- from pe_sim to a capture

def p0_changes(sim_stdout):
    """[(cycle, level)] of P0 from pe_sim's "pins CYCLE XX" lines: the level
    at the first line, then only the cycles at which it changed."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, level = int(part[1]), (int(part[2], 16) >> PIN) & 1
            if not out or out[-1][1] != level:
                out.append((cycle, level))
    return out


def write_vcd(path, changes, cycles):
    """The capture as printed, plus one falling edge at the end of the run
    when the line is high there (the decoder reads a bit from its falling
    edge to the next one, so the last bit of the last frame needs one more)."""
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        level = None
        for cycle, lv in changes:
            if cycle < cycles:
                f.write("#%d\n%d!\n" % (cycle, lv))
                level = lv
        if level == 1:
            f.write("#%d\n0!\n" % cycles)
        f.write("#%d\n" % (cycles + 10 * US))


def sigrok_annotations(changes, cycles):
    """DSView's pxx1 decoder on the capture: its annotations' texts, in order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", DECODER,
               "-A", "pxx1", "--protocol-decoder-samplenum"]
        env = dict(os.environ, SIGROKDECODE_DIR=DECODERS, PYTHONDONTWRITEBYTECODE="1")
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=900, env=env)
    if out.returncode != 0 or "rror" in out.stderr:
        raise RuntimeError("sigrok-cli failed: " + " ".join(out.stderr.split())[:300])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)$", line)
        if m:
            found.append(m.group(3))
        elif line.strip():
            raise RuntimeError("sigrok-cli printed an unexpected line: %r" % line[:100])
    return found


def split_rows(annotations):
    """The decoder's three rows: bits are one character (0, 1, S), bytes two
    hex digits, fields longer than that."""
    bits = [a for a in annotations if len(a) == 1]
    byts = [a for a in annotations if len(a) == 2]
    fields = [a for a in annotations if len(a) > 2]
    return bits, byts, fields


# ------------------------------------------------------------ the two checks

def check_decoder(frames, changes, cycles):
    """The decoded bits, bytes and fields must be the wanted frames' and
    nothing else."""
    got = split_rows(sigrok_annotations(changes, cycles))
    want = ([], [], [])
    for f in frames:
        for row, part in zip(want, decoder_wants(f)):
            row += part
    errs = []
    for name, g, w in zip(("bits", "bytes", "fields"), got, want):
        if g == w:
            continue
        i = next((i for i in range(min(len(g), len(w))) if g[i] != w[i]), min(len(g), len(w)))
        errs.append("%s row: %d annotations, wanted %d; first difference at %d: %r, wanted %r"
                    % (name, len(g), len(w), i, g[i] if i < len(g) else None,
                       w[i] if i < len(w) else None))
    return errs


def check_waveform(frames, changes, cycles):
    """The limits of the task sheet, from the pin changes themselves."""
    errs = []
    if not changes or changes[0] != (0, 1):
        return ["P0 is not high at cycle 0 in the simulator's output"]
    edges = changes[1:]
    if edges and edges[-1][1] == 0:
        errs.append("P0 is low at the end of the run (cycle %d on)" % edges[-1][0])
    pulses = []  # (fall, rise or None)
    for i in range(0, len(edges), 2):
        fall = edges[i][0]
        rise = edges[i + 1][0] if i + 1 < len(edges) else None
        pulses.append((fall, rise))
    groups = []
    for p in pulses:
        if groups and p[0] - groups[-1][-1][0] <= SPLIT:
            groups[-1].append(p)
        else:
            groups.append([p])
    if len(groups) != len(frames):
        errs.append("%d separate bursts of pulses on P0, wanted %d frames" % (len(groups), len(frames)))
    prev = None
    for k, (g, frame) in enumerate(zip(groups, frames)):
        want = line_bits(frame)
        start = g[0][0]
        if k == 0:
            if start < START_MIN:
                errs.append("the first frame begins at cycle %d, not before %d allowed" % (start, START_MIN))
            elif start > START_MAX:
                errs.append("the first frame begins at cycle %d, limit %d" % (start, START_MAX))
        else:
            gap = start - prev
            if gap < FRAME_MIN or gap > FRAME_MAX:
                errs.append("frame %d begins %d cycles after frame %d began, wanted %d to %d"
                            % (k, gap, k - 1, FRAME_MIN, FRAME_MAX))
        prev = start
        got, problem = [], None
        for i, (fall, rise) in enumerate(g):
            if rise is None or abs(rise - fall - LOW) > TOL:
                problem = ("frame %d: the low pulse of bit %d (%s) lasts %s cycles, wanted %d +-%d"
                           % (k, i, describe(want[i][1]) if i < len(want) else "beyond the frame",
                              "no end of" if rise is None else rise - fall, LOW, TOL))
                break
            if i + 1 < len(g):
                period = g[i + 1][0] - fall
                bit = next((b for b, p in PERIOD.items() if abs(period - p) <= TOL), None)
                if bit is None:
                    problem = ("frame %d: bit %d (%s) lasts %d cycles from fall to fall, wanted %d or %d +-%d"
                               % (k, i, describe(want[i][1]) if i < len(want) else "beyond the frame",
                                  period, PERIOD[0], PERIOD[1], TOL))
                    break
                got.append(bit)
            else:
                got.append(0)   # the last bit lasts until the next frame: a 0
        if problem:
            errs.append(problem)
            continue
        wbits = [b for b, _ in want]
        if got != wbits:
            i = next((i for i in range(min(len(got), len(wbits))) if got[i] != wbits[i]),
                     min(len(got), len(wbits)))
            if i < len(wbits) and i < len(got):
                errs.append("frame %d: bit %d on the line is %d, wanted %d (%s)"
                            % (k, i, got[i], wbits[i], describe(want[i][1])))
            else:
                errs.append("frame %d: %d bits on the line, wanted %d" % (k, len(got), len(wbits)))
    if len(groups) == len(frames) and groups:
        last_rise = groups[-1][-1][1]
        if last_rise is not None and cycles - last_rise < SPLIT:
            errs.append("the run ended %d cycles after the last pulse, too soon to see the line idle"
                        % (cycles - last_rise))
    return errs


def judge(frames, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = p0_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(frames, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(frames, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(frames):
    """Long enough for the latest start and the longest frame period allowed,
    with the last frame's idle line after it."""
    return START_MAX * (len(frames) + 1)


def run_case(run_dir, args, frames):
    """(objections, cycles from P0's first change to its last or None)."""
    words = tx_words(frames)
    cycles = run_cycles(frames)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "pxx1.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in p0_changes(out.stdout)[1:]]
    return judge(frames, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def find_crc_stuff_frame():
    """A fixed frame (found by a fixed search) whose CRC ends a run of five
    1s, so a stuffed 0 follows the CRC directly."""
    for n in range(4096):
        frame = (0x01, 0x00, 0x00, 0x00, [1024] * 7 + [n])
        if stuff_after_crc(frame):
            return frame
    raise AssertionError("no frame found")


def cases_for(seed):
    """(name, frames): fixed cases, then seeded random ones."""
    centre = [1024] * 8
    fixed = [
        ("all zero", [(0, 0, 0, 0, [0] * 8)]),
        ("all ones: stuffing everywhere", [(0xFF, 0xFF, 0xFF, 0xFF, [4095] * 8)]),
        ("typical: receiver 3, sticks centred", [(3, 0x00, 0x00, 0x00, centre)]),
        ("bytes of 0x7E and 0x7D in the payload", [(0x7E, 0x7E, 0x7D, 0x7E, [0xE7E, 0x7E7, 0x07E, 0x7E0, 0xD7D, 0x7D7, 0x7E7, 0xE7E])]),
        ("bind, failsafe, range check, every extra flag",
         [(63, 0xC0 | 0x20 | 0x10 | (5 << 1) | 1, 0x00, 0x7F, [1, 2046, 2049, 4094, 0, 2048, 4095, 1023])]),
        ("CRC followed directly by a stuffed 0", [find_crc_stuff_frame()]),
        ("four frames, channels 9-16 in the second", [
            (5, 0x00, 0, 0x04, [1024 + 64 * k for k in range(8)]),
            (5, 0x00, 0, 0x04, [3072 - 64 * k for k in range(8)]),
            (5, 0x40, 0, 0x04, [0x555, 0xAAA, 0x333, 0xCCC, 0x0F0, 0xF0F, 0x00F, 0xFF0]),
            (5, 0x80, 0, 0x04, [4095 - 117 * k for k in range(8)])]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_FRAMES)
        frames = []
        for _ in range(count):
            frames.append((rng.randrange(256), rng.randrange(256), rng.randrange(256),
                           rng.randrange(256), [rng.randrange(4096) for _ in range(8)]))
        rand.append(("random %d" % n, frames))
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
    if not os.path.isdir(os.path.join(DECODERS, "pxx1")):
        setup.append("the pxx1 decoder is not in %s" % DECODERS)
    for name in ("pe_sim", "pxx1.s", "run_args.txt"):
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
            rate = (16 * len(frames), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d frame%s): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
