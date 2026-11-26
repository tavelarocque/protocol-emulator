#!/usr/bin/env python3
"""Hidden acceptance test for the blind FlexRay transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (flexray.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet
fixes what the TX words mean, and this test builds them itself.

For each case (a list of frames) the test
  1. builds the TX words the task sheet defines: per frame, four header
     words (indicators and frame ID, payload length, header CRC, cycle
     count) and then the payload, two bytes per word, first byte high,
  2. runs RUN_DIR/pe_sim on RUN_DIR/flexray.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, two
     samples per 20 ns core clock cycle, so 100 MHz),
  4. has sigrok-cli's `flexray` decoder (channel A, 10 Mbit/s) read it and
     requires, frame by frame and in order, with nothing extra: a TSS, an
     FSS, a reserved bit of 0, the four indicators, the frame ID, the
     payload length, the header CRC marked OK, the cycle count, every
     payload byte, the frame CRC marked OK, an FES and a channel idle
     delimiter, and no collision avoidance symbol,
  5. checks, from the pin changes themselves, what the decoder does not:
     P0 high until the first TSS, which begins within 10000 cycles; each
     TSS 15 to 75 cycles long; every later edge of a frame within +-1 cycle
     of its ideal place, counted from that frame's FSS edge (so the bit
     values of the BSS and FES and the absence of a DTS are checked too);
     the idle time between frames; and silence after the last frame.

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

CLOCK_HZ = 50_000_000        # core clock: one cycle = 20 ns
BITRATE = 10_000_000         # FlexRay at 10 Mbit/s
BIT = CLOCK_HZ // BITRATE    # 5 cycles a bit
TOL = 1                      # cycles an edge may be from its ideal place
TSS_MIN = 3 * BIT            # gdTSSTransmitter, 3 to 15 bits
TSS_MAX = 15 * BIT
CID_BITS = 11                # channel idle delimiter after the FES
GAP_MIN = (1 + CID_BITS) * BIT   # from the FES's rising edge to the next TSS
GAP_MAX = 10_000             # and at most this
START_MAX = 10_000           # the first TSS begins by this cycle
MAX_WORDS = 127              # payload length field, in two-byte words
SPLIT = 10 * BIT + 3         # longest high run inside a frame is 10 bits
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "tx", "stimulus", "help")
PIN = 0                      # P0
VCD_PER_CYCLE = 2            # VCD timescale 10 ns, two samples a cycle

HCRC_POLY, HCRC_INIT, HCRC_SIZE = 0x385, 0x01A, 11
FCRC_POLY, FCRC_INIT, FCRC_SIZE = 0x5D6DCB, 0xFEDCBA, 24   # channel A


# ------------------------------------------------------------- the frame

class Frame:
    """One FlexRay frame as the host describes it."""

    def __init__(self, fid, cycle, payload, ppi=0, nf=1, sync=0, startup=0):
        assert 1 <= fid <= 2047 and 0 <= cycle <= 63
        assert len(payload) % 2 == 0 and len(payload) // 2 <= MAX_WORDS
        self.fid, self.cycle, self.payload = fid, cycle, list(payload)
        self.ppi, self.nf, self.sync, self.startup = ppi, nf, sync, startup

    @property
    def length(self):
        return len(self.payload) // 2


def crc_msb(bits, poly, size, init):
    """CRC computed most significant bit first, as FlexRay defines it."""
    reg, top, mask = init, 1 << (size - 1), (1 << size) - 1
    for b in bits:
        fb = bool(reg & top) ^ b
        reg = (reg << 1) & mask
        if fb:
            reg ^= poly
    return reg


def field(value, width):
    return [(value >> k) & 1 for k in range(width - 1, -1, -1)]


def header_crc(f):
    bits = [f.sync, f.startup] + field(f.fid, 11) + field(f.length, 7)
    return crc_msb(bits, HCRC_POLY, HCRC_SIZE, HCRC_INIT)


def header_bits(f):
    return ([0, f.ppi, f.nf, f.sync, f.startup] + field(f.fid, 11) + field(f.length, 7)
            + field(header_crc(f), 11) + field(f.cycle, 6))


def frame_crc(f):
    bits = header_bits(f) + [b for byte in f.payload for b in field(byte, 8)]
    return crc_msb(bits, FCRC_POLY, FCRC_SIZE, FCRC_INIT)


def line_bits(f):
    """The bits after the TSS: FSS, then BSS and byte for every byte of
    header, payload and frame CRC, then FES. Bit 0 starts at the FSS edge."""
    h = header_bits(f)
    data = [h[i:i + 8] for i in range(0, 40, 8)]
    data += [field(b, 8) for b in f.payload]
    c = frame_crc(f)
    data += [field((c >> s) & 0xFF, 8) for s in (16, 8, 0)]
    out = [1]
    for byte in data:
        out += [1, 0] + byte
    return out + [0, 1]


def ideal_edges(f):
    """Cycles after the FSS edge at which P0 must change, the FSS edge first."""
    bits = line_bits(f)
    out = [0]
    for k in range(1, len(bits)):
        if bits[k] != bits[k - 1]:
            out.append(k * BIT)
    return out


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The TX words of one run, as the task sheet defines them. Per frame:
    word 0 = PPI<<14 | NF<<13 | sync<<12 | startup<<11 | frame ID;
    word 1 = payload length (two-byte words); word 2 = header CRC;
    word 3 = cycle count; then one word per two payload bytes, the first
    byte in bits 15..8. Payload only: nothing about the line."""
    words = []
    for f in frames:
        words.append((f.ppi << 14) | (f.nf << 13) | (f.sync << 12) | (f.startup << 11) | f.fid)
        words.append(f.length)
        words.append(header_crc(f))
        words.append(f.cycle)
        for i in range(0, len(f.payload), 2):
            words.append((f.payload[i] << 8) | f.payload[i + 1])
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name)."""
    i = 0
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits == ["tx"] or hits == ["cycles"]:
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        i += 2
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
    with open(path, "w") as f:
        f.write("$timescale 10 ns $end\n")
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for cycle, level in changes:
            if cycle < cycles:
                f.write("#%d\n%d!\n" % (cycle * VCD_PER_CYCLE, level))
        f.write("#%d\n" % (cycles * VCD_PER_CYCLE))


def sigrok_annotations(changes, cycles):
    """The decoder's annotations, in order: [(start sample, text)], using the
    longest form of each annotation."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "flexray:channel_type=A:bitrate=%d:channel=P0" % BITRATE,
               "-A", "flexray=fields:warnings", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append((int(m.group(1)), m.group(3).strip()))
    return found


def wanted_annotations(f):
    """What the decoder must say about one frame, in its order."""
    out = ["Transmission start sequence", "FSS", "Reserved bit: 0",
           "Payload preamble indicator: %d" % f.ppi,
           "Null frame indicator: %s" % ("data frame" if f.nf else "null frame"),
           "Sync frame indicator: %d" % f.sync,
           "Startup frame indicator: %d" % f.startup,
           "Frame ID: %d" % f.fid,
           "Payload length: %d" % f.length,
           "Header CRC: 0x%X (OK)" % header_crc(f),
           "Cycle: %d" % f.cycle]
    out += ["Data byte %d: 0x%02x" % (i, b) for i, b in enumerate(f.payload)]
    out += ["Frame CRC: 0x%X (OK)" % frame_crc(f), "Frame end sequence", "Channel idle delimiter"]
    return out


def normalise(text):
    """sigrok-cli prints every form of an annotation, quoted; keep the first."""
    m = re.match(r'"([^"]*)"', text)
    return m.group(1) if m else text


# ------------------------------------------------------------ the two checks

def check_decoder(frames, changes, cycles):
    """The decoded frames must be the wanted ones and nothing else."""
    got = [normalise(t) for _, t in sigrok_annotations(changes, cycles)]
    want = [a for f in frames for a in wanted_annotations(f)]
    if got == want:
        return []
    errs = []
    if any(g.startswith("Collision avoidance") for g in got):
        errs.append("the decoder saw a collision avoidance symbol")
    bad = [g for g in got if g.endswith("(bad)")]
    if bad:
        errs.append("the decoder found a bad CRC: %s" % bad[0])
    for i, (g, w) in enumerate(zip(got, want)):
        if g != w:
            k = sum(1 for a in want[:i] if a == "Transmission start sequence") - 1
            errs.append("frame %d: decoder said %r where %r was wanted" % (max(k, 0), g, w))
            break
    else:
        errs.append("decoder gave %d annotations, wanted %d" % (len(got), len(want)))
    return errs


def check_waveform(frames, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    errs = []
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    if changes[0][1] != 1:
        errs.append("P0 is low at cycle 0: it must be high until the first TSS")
    edges = changes[1:]
    bursts = []
    for c, level in edges:
        if bursts and not (level == 0 and c - bursts[-1][-1][0] > SPLIT):
            bursts[-1].append((c, level))
        else:
            bursts.append([(c, level)])
    if len(bursts) != len(frames):
        errs.append("%d separate bursts of edges on P0, wanted %d frames" % (len(bursts), len(frames)))
    prev_end = None
    for k, (burst, f) in enumerate(zip(bursts, frames)):
        if burst[0][1] != 0:
            errs.append("frame %d does not begin with a falling edge" % k)
            prev_end = burst[-1][0]
            continue
        tss_start = burst[0][0]
        if k == 0:
            if tss_start > START_MAX:
                errs.append("the first TSS begins at cycle %d, limit %d" % (tss_start, START_MAX))
        else:
            gap = tss_start - prev_end
            if gap < GAP_MIN:
                errs.append("frame %d's TSS begins %d cycles after the last FES edge, at least %d wanted"
                            % (k, gap, GAP_MIN))
            elif gap > GAP_MAX:
                errs.append("frame %d's TSS begins %d cycles after the last FES edge, at most %d allowed"
                            % (k, gap, GAP_MAX))
        if len(burst) < 2:
            errs.append("frame %d: the line falls and never rises" % k)
            prev_end = None
            break
        tss = burst[1][0] - tss_start
        if not TSS_MIN <= tss <= TSS_MAX:
            errs.append("frame %d: TSS is %d cycles, wanted %d to %d" % (k, tss, TSS_MIN, TSS_MAX))
        zero = burst[1][0]
        got = [c - zero for c, _ in burst[1:]]
        want = ideal_edges(f)
        for i, (a, w) in enumerate(zip(got, want)):
            if abs(a - w) > TOL:
                errs.append("frame %d: edge %d is %d cycles after the FSS edge, ideal %d (limit +-%d)"
                            % (k, i, a, w, TOL))
                break
        else:
            if len(got) != len(want):
                errs.append("frame %d: %d edges after the TSS, wanted %d" % (k, len(got), len(want)))
        prev_end = burst[-1][0]
    if prev_end is not None and len(bursts) == len(frames) and cycles - prev_end < GAP_MIN:
        errs.append("the run ended %d cycles after the last FES edge, too soon to see the idle"
                    % (cycles - prev_end))
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
    """Long enough for the latest start and the longest gaps allowed."""
    return START_MAX + sum(TSS_MAX + len(line_bits(f)) * BIT + GAP_MAX for f in frames)


def run_case(run_dir, args, frames):
    """(objections, cycles from P0's first change to its last or None)."""
    words = tx_words(frames)
    cycles = run_cycles(frames)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "flexray.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in p0_changes(out.stdout)[1:]]
    return judge(frames, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def random_frame(rng, longest):
    startup = rng.random() < 0.2
    sync = 1 if startup else int(rng.random() < 0.3)
    nf = int(rng.random() < 0.85)
    ppi = int(nf and rng.random() < 0.2)
    n = rng.randint(0, longest)
    payload = [rng.randrange(256) for _ in range(2 * n)] if nf else [0] * (2 * n)
    return Frame(rng.randint(1, 2047), rng.randrange(64), payload, ppi, nf, sync, int(startup))


def cases_for(seed):
    """(name, frames): fixed cases, then seeded random ones."""
    fixed = [
        ("the task sheet's example", [Frame(1, 0, [0x12, 0x34])]),
        ("no payload", [Frame(0x7FF, 63, [])]),
        ("all zeros", [Frame(1, 0, [0x00] * 4)]),
        ("all ones", [Frame(0x7FF, 63, [0xFF] * 4, ppi=1, nf=1, sync=1, startup=1)]),
        ("null frame", [Frame(5, 7, [0] * 8, ppi=0, nf=0)]),
        ("three frames", [Frame(3, 1, [0xDE, 0xAD, 0xBE, 0xEF]), Frame(4, 2, [0x55, 0xAA]),
                          Frame(0x400, 33, [0x01, 0x80], sync=1)]),
        ("longest payload", [Frame(42, 21, [(k * 37 + 11) & 0xFF for k in range(2 * MAX_WORDS)])]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        longest = 40 if n % 2 else 6
        rand.append(("random %d" % n, [random_frame(rng, longest) for _ in range(rng.randint(1, 5))]))
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
    for name in ("pe_sim", "flexray.s", "run_args.txt"):
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
            rate = (sum(len(f.payload) for f in frames), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        size = sum(len(f.payload) for f in frames)
        print("case %d (%s: %d frame%s, %d payload byte%s): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
