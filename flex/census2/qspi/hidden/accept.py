#!/usr/bin/env python3
"""Hidden acceptance test for the blind Quad SPI controller firmware (a
NOR flash written with Write Enable and Quad Page Program).

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (qspi.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet fixes
what the TX words mean, and this test builds them itself.

Pins: P0..P3 IO0..IO3, P4 SCK, P5 CS#, all push-pull. Core clock 50 MHz.

For each case (a list of pages, each an address and its data bytes) the test
  1. builds the TX words the task sheet defines: one word per byte, the byte
     in bits 7..0, bit 8 set on the last byte of a page, each page being
     three address bytes (high first) then its data,
  2. runs RUN_DIR/pe_sim on RUN_DIR/qspi.s with those words,
  3. checks the pin changes directly against every limit of the task sheet
     (start-up, SCK idle low, frames, the bit on each line at each SCK rise,
     setup and hold, CS# high times, the wait after each page program, SCK
     speed, silence at the end),
  4. writes the changes as a logic capture (a VCD file, one sample per core
     clock cycle, 50 MHz) and has two decoders from DSView read it, both run
     by sigrok-cli 0.7.2 (SIGROKDECODE_DIR is set to the census copy, which
     holds a mechanical port of each, see PORT.diff):
       qspi        (SPI mode 0, 8-bit words, MSB first, all four IO lines
                    and CS#): every byte it reports, in order, must be the
                    wanted one and fall inside the wanted CS# frame. It reads
                    every clock as four bits, so in the single-line command
                    and address it is compared on IO0's bits only (bits 4
                    and 0 of each byte); the flash ignores IO1..IO3 there.
       smart_qspi  (the same, twolinesmode=qspi): per page "Write Enable
                    (0x06)", then "Quad Page Program(0x32)", "24-Bit Address",
                    and one "Write Data" per byte, in order, each inside the
                    wanted CS# frame, and nothing else.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<data bytes> cycles=<cycles from the first change of P0..P5 to the last>
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

# The census copy of the decoders: sigrok-cli 0.7.2's own plus round 2's,
# with qspi and smart_qspi ported mechanically (PORT.diff beside this file).
DECODERS = "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders"

CLOCK_HZ = 50_000_000         # core clock: one cycle = 20 ns
IO = (0, 1, 2, 3)             # IO0..IO3 on P0..P3
SCK, CS = 4, 5                # SCK on P4, CS# on P5
USED = 0x3F                   # P0..P5
WREN, QPP = 0x06, 0x32        # Write Enable, Quad Page Program (1-1-4)
LAST = 0x100                  # bit 8 of a TX word: the last byte of a page
SCK_LOW_BY = 100              # SCK driven low by this cycle
FIRST_CS_BY = 10_000          # the first CS# fall, at the latest
CS_HIGH_MIN = 3               # CS# high between WREN and QPP: tSHSL 50 ns -> 3 cycles
CS_HIGH_MAX = 1_000           # and at most this (so the test knows how long to run)
PAGE_GAP_MIN = 150_000        # QPP CS# rise to next WREN CS# fall: tPP max 3 ms
PAGE_GAP_MAX = 200_000        # and at most 4 ms
SCK_SLOW = 20                 # CS# fall -> first rise, rise -> rise, last rise -> CS# rise
MAX_PAGES = 6
DATA_MAX = 256                # data bytes in a page: 4 to 256, a multiple of 4
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
NAMES = ("IO0", "IO1", "IO2", "IO3", "SCK", "CSN")
CHANNELS = "clk=SCK:io0=IO0:io1=IO1:io2=IO2:io3=IO3:cs=CSN"
QSPI = "qspi:" + CHANNELS + ":cpol=0:cpha=0:bitorder=msb-first:wordsize=8:cs_polarity=active-low"
SMART = ("smart_qspi:" + CHANNELS + ":cpol=0:cpha=0:bitorder=msb-first:cs_polarity=active-low"
         ":twolinesmode=qspi:ads=24-Bit Address:frame=no")


# ------------------------------------------------------- the host interface

def page_bytes(page):
    addr, data = page
    return [(addr >> 16) & 0xFF, (addr >> 8) & 0xFF, addr & 0xFF] + list(data)


def tx_words(pages):
    """The TX words of one run, as the task sheet defines them: one word per
    byte, the byte in bits 7..0, bit 8 set on the last byte of each page,
    every other bit 0; a page is its three address bytes, high first, then
    its data bytes. Payload only: nothing about the lines."""
    words = []
    for page in pages:
        b = page_bytes(page)
        words += [x | (LAST if i == len(b) - 1 else 0) for i, x in enumerate(b)]
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name);
    P0..P5 must be push-pull."""
    i, modes = 0, {}
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
            m = re.fullmatch(r"([0-7])=(pp|od|in)", args[i + 1])
            if not m:
                return "run_args.txt: -mode %r is not P=pp|od|in" % args[i + 1]
            modes[int(m.group(1))] = m.group(2)
        i += 2
    wrong = [p for p in range(6) if modes.get(p) != "pp"]
    if wrong:
        return "run_args.txt must make P0..P5 push-pull (not: %s)" % ", ".join("P%d" % p for p in wrong)
    return None


# ------------------------------------------------------- what must be sent

def frames_for(pages):
    """[(kind, page index, beats)]: beats are (value, mask) at each SCK rise,
    value bit k on IO k; mask 1 means only IO0 counts (single-line phases)."""
    out = []
    for n, (addr, data) in enumerate(pages):
        single = lambda v, bits: [((v >> k) & 1, 1) for k in range(bits - 1, -1, -1)]
        out.append(("WREN", n, single(WREN, 8)))
        beats = single(QPP, 8) + single(addr, 24)
        for b in data:
            beats += [(b >> 4, 0xF), (b & 0xF, 0xF)]
        out.append(("QPP", n, beats))
    return out


def run_cycles(pages):
    """Long enough for the slowest waveform the task sheet allows."""
    frame = lambda rises: SCK_SLOW * (rises + 1)
    return FIRST_CS_BY + sum(frame(8) + CS_HIGH_MAX + frame(32 + 2 * len(d)) + PAGE_GAP_MAX
                             for _, d in pages)


# ------------------------------------------------- from pe_sim to the pins

def pin_changes(sim_stdout):
    """[(cycle, levels of P0..P5)] from pe_sim's "pins CYCLE XX" lines: the
    state at the first line, then only the cycles at which P0..P5 changed."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, value = int(part[1]), int(part[2], 16) & USED
            if not out or out[-1][1] != value:
                out.append((cycle, value))
    return out


def bit(v, pin):
    return (v >> pin) & 1


def nib(v):
    return v & 0xF


def cs_frames(changes):
    """[(fall, rise or None)] of CS#, from the changes."""
    out, fall = [], None
    for c, v in changes:
        if bit(v, CS) == 0 and fall is None:
            fall = c
        elif bit(v, CS) == 1 and fall is not None:
            out.append((fall, c))
            fall = None
    if fall is not None:
        out.append((fall, None))
    return out


# ------------------------------------------------------------ the two checks

def where(kind, n, i):
    if kind == "WREN":
        return "page %d WREN bit %d" % (n, i)
    if i < 8:
        return "page %d QPP command bit %d" % (n, i)
    if i < 32:
        return "page %d address bit %d" % (n, 31 - i)
    k = i - 32
    return "page %d data byte %d %s nibble" % (n, k // 2, "high" if k % 2 == 0 else "low")


def check_waveform(pages, changes, cycles):
    """Every limit of the task sheet, from the pin changes themselves."""
    errs = []
    if not changes or changes[0][0] != 0:
        return ["no pin state at cycle 0 in the simulator's output"]
    # SCK low by SCK_LOW_BY, and from then on low whenever CS# is high and
    # in every cycle in which CS# changes.
    low_at = next((c for c, v in changes if bit(v, SCK) == 0), None)
    if low_at is None or low_at > SCK_LOW_BY:
        errs.append("SCK is not driven low by cycle %d" % SCK_LOW_BY)
        return errs
    prev = changes[0][1]
    for c, v in changes[1:]:
        if bit(v, CS) != bit(prev, CS) and bit(v, SCK):
            errs.append("CS# %s at cycle %d with SCK high" % ("rises" if bit(v, CS) else "falls", c))
        elif c >= low_at and bit(v, SCK) and bit(v, CS):
            errs.append("SCK high while CS# is high, at cycle %d" % c)
        prev = v
        if len(errs) > 3:
            return errs
    frames = cs_frames(changes)
    want = frames_for(pages)
    if frames and frames[-1][1] is None:
        errs.append("CS# is still low at the end of the run")
        frames = frames[:-1]
    if len(frames) != len(want):
        errs.append("%d CS# frames, wanted %d (a WREN and a QPP per page)" % (len(frames), len(want)))
    if frames and frames[0][0] > FIRST_CS_BY:
        errs.append("the first CS# fall is at cycle %d, limit %d" % (frames[0][0], FIRST_CS_BY))
    for k, ((fall, rise), (kind, n, beats)) in enumerate(zip(frames, want)):
        # the levels at each SCK rise inside the frame, and setup/hold
        rises, prev = [], None
        for c, v in changes:
            if prev is not None and fall < c < rise and bit(v, SCK) and not bit(prev, SCK):
                rises.append((c, v))
                if nib(v) != nib(prev):
                    errs.append("%s frame %d: IO lines change at cycle %d, the cycle of an SCK rise"
                                % (kind, k, c))
            prev = v
        if not rises:
            errs.append("%s frame %d (cycles %d to %d): no SCK rise" % (kind, k, fall, rise))
            continue
        times = [fall] + [c for c, _ in rises] + [rise]
        slow = [(a, b) for a, b in zip(times, times[1:]) if b - a > SCK_SLOW]
        if slow:
            a, b = slow[0]
            errs.append("%s frame %d: %d cycles from cycle %d to %d with no SCK rise (at most %d)"
                        % (kind, k, b - a, a, b, SCK_SLOW))
        got = [nib(v) for _, v in rises]
        for i, ((value, mask), g) in enumerate(zip(beats, got)):
            if (g ^ value) & mask:
                errs.append("%s frame %d: %s is %s at the SCK rise in cycle %d, wanted %s"
                            % (kind, k, where(kind, n, i),
                               ("%x" % (g & mask)) if mask != 1 else "IO0=%d" % (g & 1),
                               rises[i][0], ("%x" % value) if mask != 1 else "IO0=%d" % value))
                break
        else:
            if len(got) != len(beats):
                errs.append("%s frame %d: %d SCK rises, wanted %d" % (kind, k, len(got), len(beats)))
        if k + 1 < len(frames) and k + 1 < len(want):
            gap = frames[k + 1][0] - rise
            lo, hi = (CS_HIGH_MIN, CS_HIGH_MAX) if kind == "WREN" else (PAGE_GAP_MIN, PAGE_GAP_MAX)
            if not lo <= gap <= hi:
                errs.append("CS# high %d cycles after %s frame %d, wanted %d to %d"
                            % (gap, kind, k, lo, hi))
    if frames and len(frames) == len(want) and cycles - frames[-1][1] < PAGE_GAP_MIN:
        errs.append("the run ended %d cycles after the last frame, too soon to see the silence"
                    % (cycles - frames[-1][1]))
    return errs


def write_vcd(path, changes, cycles):
    ids = "!\"#$%&"
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n$scope module pins $end\n" % (1_000_000_000 // CLOCK_HZ))
        for i, name in enumerate(NAMES):
            f.write("$var wire 1 %s %s $end\n" % (ids[i], name))
        f.write("$upscope $end\n$enddefinitions $end\n")
        for c, v in changes:
            if c < cycles:
                f.write("#%d\n" % c + "".join("%d%s\n" % (bit(v, i), ids[i]) for i in range(6)))
        f.write("#%d\n" % cycles)


def sigrok(vcd, decoder, show):
    """[(start sample, text)] of one decoder's annotations, and its stderr."""
    env = dict(os.environ, SIGROKDECODE_DIR=DECODERS)
    cmd = ["sigrok-cli", "-i", vcd, "-I", "vcd", "-P", decoder, "-A", show,
           "--protocol-decoder-samplenum"]
    out = subprocess.run(cmd, capture_output=True, text=True, timeout=900, env=env)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed (%s): %s" % (decoder.split(":")[0], out.stderr.strip()[:200]))
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)$", line)
        found.append((int(m.group(1)), m.group(3).strip()) if m else (-1, line.strip()))
    return found, out.stderr.strip()


def frame_of(sample, frames):
    for k, (fall, rise) in enumerate(frames):
        if fall <= sample <= (rise if rise is not None else sample):
            return k
    return None


def qspi_wants(pages):
    """[(frame, value, mask)] for every byte the qspi decoder must report."""
    out = []
    for k, (kind, n, beats) in enumerate(frames_for(pages)):
        for i in range(0, len(beats), 2):
            (v0, m0), (v1, m1) = beats[i], beats[i + 1]
            out.append((k, (v0 << 4) | v1, (m0 << 4) | m1))
    return out


def smart_wants(pages):
    """[(frame, label, value)] for every annotation smart_qspi must make."""
    out = []
    for k, (kind, n, beats) in enumerate(frames_for(pages)):
        addr, data = pages[n]
        if kind == "WREN":
            out.append((k, "Write Enable", WREN))
        else:
            out += [(k, "Quad Page Program", QPP), (k, "24-Bit Address", addr)]
            out += [(k, "Write Data", b) for b in data]
    return out


def check_decoders(pages, changes, cycles):
    errs = []
    frames = cs_frames(changes)
    with tempfile.TemporaryDirectory() as d:
        vcd = os.path.join(d, "pins.vcd")
        write_vcd(vcd, changes, cycles)
        q, q_err = sigrok(vcd, QSPI, "qspi")
        s, s_err = sigrok(vcd, SMART, "smart_qspi=data-transfer")
    if q_err:
        errs.append("qspi: sigrok-cli said %r" % q_err[:120])
    if s_err:
        errs.append("smart_qspi: sigrok-cli said %r" % s_err[:120])
    # qspi
    got = []
    for ss, text in q:
        if not re.fullmatch(r"[0-9A-F]{2}", text):
            errs.append("qspi: unexpected annotation %r" % text[:60])
            break
        got.append((frame_of(ss, frames), int(text, 16), ss))
    want = qspi_wants(pages)
    for i, (w, g) in enumerate(zip(want, got)):
        if g[0] != w[0] or (g[1] ^ w[1]) & w[2]:
            errs.append("qspi: byte %d is %02X in CS# frame %s at sample %d, wanted %02X (mask %02X) in frame %d"
                        % (i, g[1], g[0], g[2], w[1], w[2], w[0]))
            break
    else:
        if len(got) != len(want):
            errs.append("qspi: %d bytes decoded, wanted %d" % (len(got), len(want)))
    # smart_qspi
    got = []
    for ss, text in s:
        m = (re.fullmatch(r"(.+?)\(0x([0-9a-fA-F]+)\)", text)
             or re.fullmatch(r"(.+?) : 0x([0-9a-fA-F]+)", text))
        if not m:
            errs.append("smart_qspi: unexpected annotation %r" % text[:60])
            break
        got.append((frame_of(ss, frames), m.group(1), int(m.group(2), 16), ss))
    want = smart_wants(pages)
    for i, (w, g) in enumerate(zip(want, got)):
        if g[:3] != w:
            errs.append("smart_qspi: annotation %d is %s 0x%x in CS# frame %s at sample %d, wanted %s 0x%x in frame %d"
                        % (i, g[1], g[2], g[0], g[3], w[1], w[2], w[0]))
            break
    else:
        if len(got) != len(want):
            errs.append("smart_qspi: %d annotations, wanted %d" % (len(got), len(want)))
    return errs


def judge(pages, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = pin_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(pages, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoders(pages, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_case(run_dir, args, pages):
    """(objections, cycles from the first change of P0..P5 to the last, or None)."""
    words = tx_words(pages)
    cycles = run_cycles(pages)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "qspi.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in pin_changes(out.stdout)[1:]]
    return judge(pages, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def random_page(rng, longest):
    n = 4 * rng.randint(1, longest // 4)
    low = rng.randint(0, 256 - n)
    return ((rng.randrange(0x10000) << 8) | low, [rng.randrange(256) for _ in range(n)])


def cases_for(seed):
    """(name, pages): fixed cases, then seeded random ones."""
    fixed = [
        ("the task sheet's example", [(0x012300, [0xDE, 0xAD, 0xBE, 0xEF]),
                                      (0xABCD10, [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])]),
        ("all zeros, address 0", [(0x000000, [0x00] * 4)]),
        ("all ones, the last 4 bytes of a 16 MB flash", [(0xFFFFFC, [0xFF] * 4)]),
        ("every nibble on every line", [(0x5AA5F0, [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF,
                                                    0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10])]),
        ("a full 256-byte page", [(0x123400, [(k * 151 + 7) & 0xFF for k in range(256)])]),
        ("six pages of 4 bytes", [((k * 0x2B1F) << 8 | (k * 36), [0x11 * k, 0xA5, 0x5A, 0xFF - k])
                                  for k in range(MAX_PAGES)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, 4)
        longest = DATA_MAX if n % 2 else 32
        rand.append(("random %d" % n, [random_page(rng, longest) for _ in range(count)]))
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
    for sub in ("qspi", "smart_qspi"):
        if not os.path.exists(os.path.join(DECODERS, sub, "pd.py")):
            setup.append("decoder %s is missing from %s" % (sub, DECODERS))
    for name in ("pe_sim", "qspi.s", "run_args.txt"):
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
    for n, (name, pages) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, pages)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (sum(len(d) for _, d in pages), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        size = sum(len(d) for _, d in pages)
        print("case %d (%s: %d page%s, %d data byte%s): %s"
              % (n, name, len(pages), "" if len(pages) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
