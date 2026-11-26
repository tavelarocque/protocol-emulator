#!/usr/bin/env python3
"""Hidden acceptance test for the blind Ethernet auto-negotiation (IEEE 802.3
clause 28, fast link pulse) transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (eth_an.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet
fixes what the TX words mean, and this test builds them itself.

For each case (a list of 16-bit link code words, one FLP burst each) the test
  1. writes the TX words the task sheet defines: one word per burst, the
     link code word itself, D0 in bit 0,
  2. runs RUN_DIR/pe_sim on RUN_DIR/eth_an.s with those words,
  3. checks, from the printed changes of P0 (TD+) and P1 (TD-), every limit
     of the task sheet: both pins low by cycle 100, TD- low and still after
     that, every pulse 3 to 5 cycles wide, 17 clock pulses and a data pulse
     for each 1 in every burst, every pulse's rise within +-40 cycles of its
     nominal place counted from the burst's first rise, the first burst
     between cycle 40,000 and 640,000, bursts 320,000 to 960,000 cycles
     apart start to start, nothing else on the line,
  4. turns P0 into the capture sigrok's `eth_auto_negotiation` decoder was
     written for (one sample a microsecond, a sample high if P0 was high at
     any time in that microsecond: see README.md) and requires the decoder
     to read every burst as the word sent, in order, nothing extra, with one
     link pulse annotation per pulse.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<2 per code word> cycles=<cycles from the first change of P0 or P1 to the last>
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

HERE = os.path.dirname(os.path.abspath(__file__))
# The round-2 decoder repository (sigrok-cli 0.7.2's decoders plus DSView's,
# as fetched); if this folder has been moved, the one beside it.
DECODERS = "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders"
if not os.path.isdir(DECODERS):
    DECODERS = os.path.normpath(os.path.join(HERE, "..", "..", "decoders"))
DECODER_ID = "eth_auto_negotiation"

CLOCK_HZ = 40_000_000        # core clock: one cycle = 25 ns
CLOCK_STEP = 5_000           # 125 us from one clock pulse to the next
DATA_AT = 2_500              # 62.5 us from a clock pulse to its data pulse
TOL = 40                     # +-1 us: how far a rise may be from its nominal place
WIDTH_MIN, WIDTH_MAX = 3, 5  # a pulse is high 75 to 125 ns (nominal 100 ns, 4 cycles)
LOW_BY = 100                 # P0 and P1 driven low by this cycle
START_MIN = 40_000           # the first burst's first rise: not before 1 ms
START_MAX = 640_000          # and not after 16 ms
BURST_MIN = 320_000          # burst to burst, start to start: 8 ms
BURST_MAX = 960_000          # to 24 ms
PER_RUN = 960_000            # -cycles is this times (words + 1)
SPLIT = 20_000               # a quiet longer than this between two rises ends a burst
MAX_WORDS = 8                # code words in one run, 1 to this
BIN = CLOCK_HZ // 1_000_000  # cycles in one sample of the decoder's capture (1 MHz)
TD_PLUS, TD_MINUS = 0, 1     # pins
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's


# ------------------------------------------------------------ the burst

def ideal_offsets(word):
    """Where the pulses of one burst rise, in cycles after its first: a
    clock pulse every 125 us (17 of them), and between clock pulses k and
    k + 1 a data pulse 62.5 us after the first if bit Dk of the word is 1."""
    clocks = [k * CLOCK_STEP for k in range(17)]
    data = [k * CLOCK_STEP + DATA_AT for k in range(16) if (word >> k) & 1]
    return sorted(clocks + data)


def pulse_name(offset):
    """A nominal pulse place, in words."""
    k, rest = divmod(offset, CLOCK_STEP)
    return "clock pulse %d" % k if rest == 0 else "data pulse D%d" % k


# ------------------------------------------------------- the host interface

def tx_words(words):
    """The TX words of one run, as the task sheet defines them: one word per
    FLP burst, the link code word itself (bit k is Dk). Payload only:
    nothing about the line."""
    return [w & 0xFFFF for w in words]


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name). The
    modes must make P0 and P1 push-pull and no other pin an output."""
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
            m = re.fullmatch(r"(\d+)=(pp|od|in)", args[i + 1])
            if not m or int(m.group(1)) > 7:
                return "run_args.txt: bad -mode value %r" % args[i + 1]
            modes[int(m.group(1))] = m.group(2)
        i += 2
    for pin in (TD_PLUS, TD_MINUS):
        if modes.get(pin) != "pp":
            return "run_args.txt must make P%d push-pull (-mode %d=pp)" % (pin, pin)
    for pin, mode in sorted(modes.items()):
        if pin not in (TD_PLUS, TD_MINUS) and mode != "in":
            return "run_args.txt makes P%d an output; only P0 and P1 are used" % pin
    return None


# ------------------------------------------------- from pe_sim to the pins

def pin_changes(sim_stdout, pin):
    """[(cycle, level)] of one pin from pe_sim's "pins CYCLE XX" lines: the
    level at the first line, then only the cycles at which it changed."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, level = int(part[1]), (int(part[2], 16) >> pin) & 1
            if not out or out[-1][1] != level:
                out.append((cycle, level))
    return out


def pulses_of(changes):
    """(start-up fall or None, [(rise, fall)], left high at the end?) of P0.
    The level at cycle 0 is the reset level; if it is high, its first fall
    is the start-up fall, not a pulse."""
    edges = list(changes[1:])
    first_fall = None
    if changes[0][1] == 1 and edges:
        first_fall = edges.pop(0)[0]
    pulses = []
    for i in range(0, len(edges) - 1, 2):
        pulses.append((edges[i][0], edges[i + 1][0]))
    left_high = changes[-1][1] == 1
    return first_fall, pulses, left_high


# ------------------------------------------------------------ the two checks

def check_waveform(words, sim_stdout, cycles):
    """Every limit of the task sheet, from the pin changes themselves."""
    errs = []
    plus = pin_changes(sim_stdout, TD_PLUS)
    minus = pin_changes(sim_stdout, TD_MINUS)
    if not plus or plus[0][0] != 0 or not minus or minus[0][0] != 0:
        return ["no level for P0 and P1 at cycle 0 in the simulator's output"]
    # TD-: low by cycle 100, then never again changed.
    if minus[0][1] == 1:
        if len(minus) < 2 or minus[1][0] > LOW_BY:
            errs.append("P1 (TD-) is not driven low by cycle %d" % LOW_BY)
        rest = minus[2:]
    else:
        rest = minus[1:]
    if rest:
        errs.append("P1 (TD-) changes again at cycle %d; it must stay low" % rest[0][0])
    # TD+: low by cycle 100.
    first_fall, pulses, left_high = pulses_of(plus)
    if plus[0][1] == 1 and (first_fall is None or first_fall > LOW_BY):
        errs.append("P0 (TD+) is not driven low by cycle %d" % LOW_BY)
        return errs
    if left_high:
        errs.append("P0 (TD+) is high at the end of the run")
    for rise, fall in pulses:
        if not WIDTH_MIN <= fall - rise <= WIDTH_MAX:
            errs.append("a pulse at cycle %d is %d cycles wide, wanted %d to %d"
                        % (rise, fall - rise, WIDTH_MIN, WIDTH_MAX))
            break
    groups = []
    for rise, _ in pulses:
        if groups and rise - groups[-1][-1] <= SPLIT:
            groups[-1].append(rise)
        else:
            groups.append([rise])
    if len(groups) != len(words):
        errs.append("%d separate bursts on P0, wanted %d" % (len(groups), len(words)))
    for k, (g, word) in enumerate(zip(groups, words)):
        want = ideal_offsets(word)
        got = [r - g[0] for r in g]
        for i, (a, w) in enumerate(zip(got, want)):
            if abs(a - w) > TOL:
                errs.append("burst %d (0x%04X): pulse %d rises %d cycles after the first, "
                            "nominal %d for %s (limit +-%d)"
                            % (k, word, i, a, w, pulse_name(w), TOL))
                break
        else:
            if len(got) != len(want):
                errs.append("burst %d (0x%04X): %d pulses, wanted %d" % (k, word, len(got), len(want)))
        if k == 0:
            if not START_MIN <= g[0] <= START_MAX:
                errs.append("the first burst begins at cycle %d, wanted %d to %d"
                            % (g[0], START_MIN, START_MAX))
        else:
            apart = g[0] - groups[k - 1][0]
            if not BURST_MIN <= apart <= BURST_MAX:
                errs.append("burst %d begins %d cycles after burst %d began, wanted %d to %d"
                            % (k, apart, k - 1, BURST_MIN, BURST_MAX))
    return errs


def capture_1mhz(changes, cycles):
    """P0 as one sample a microsecond, high if P0 was high at any time in
    that microsecond: [(sample, level)] changes, first at sample 0."""
    high = []                      # [first bin, last bin] stretches that are high
    level, since = changes[0][1], 0
    for cycle, new in changes[1:] + [(cycles, None)]:
        if level == 1 and cycle > since:
            high.append((since // BIN, (cycle - 1) // BIN))
        level, since = new, cycle
    merged = []                    # stretches that touch or overlap become one
    for a, b in high:
        if merged and a <= merged[-1][1] + 1:
            merged[-1] = (merged[-1][0], max(merged[-1][1], b))
        else:
            merged.append((a, b))
    out = [(0, 0)]
    for a, b in merged:
        if a == 0:
            out = [(0, 1)]
        else:
            out.append((a, 1))
        out.append((b + 1, 0))
    return out


def write_vcd(path, samples, total):
    with open(path, "w") as f:
        f.write("$timescale 1 us $end\n")
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for s, v in samples:
            if s < total:
                f.write("#%d\n%d!\n" % (s, v))
        f.write("#%d\n" % total)


def sigrok_annotations(changes, cycles):
    """[(row, text)] of sigrok's decoder on the 1 MHz capture of P0, rows
    data (one per page), bit and NLP (one per pulse)."""
    total = cycles // BIN
    env = dict(os.environ, SIGROKDECODE_DIR=DECODERS, PYTHONDONTWRITEBYTECODE="1")
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, capture_1mhz(changes, cycles), total)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", "%s:dp=P0" % DECODER_ID,
               "-A", DECODER_ID + "=data:bit:NLP", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600, env=env)
    if out.returncode != 0 or "rror" in out.stderr:
        raise RuntimeError("sigrok-cli failed: " + " ".join(out.stderr.split())[:300])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) %s-\d+: (.*)" % re.escape(DECODER_ID), line)
        if not m:
            raise RuntimeError("unexpected sigrok output %r" % line[:100])
        found.append(classify(m.group(3).strip()))
    return found


def classify(text):
    """The three rows asked for have texts that cannot be mistaken: a page
    ("base page:0x61"), a bit ("0x0", "0x1"), a link pulse ("NLP")."""
    if text == "NLP":
        return ("NLP", text)
    if text in ("0x0", "0x1"):
        return ("bit", text)
    return ("data", text)


def check_decoder(words, changes, cycles):
    """The decoder must read each burst as the word sent, in order, and
    nothing else, with one link pulse annotation per pulse."""
    errs = []
    anns = sigrok_annotations(changes, cycles)
    pages = []
    for cls, text in anns:
        if cls == "data":
            m = re.fullmatch(r"(base|next) page:0x([0-9a-f]+)", text)
            if not m:
                errs.append("the decoder said %r" % text[:60])
                continue
            pages.append(int(m.group(2), 16))
    if pages != list(words):
        if len(pages) != len(words):
            errs.append("decoded %d pages, wanted %d" % (len(pages), len(words)))
        for k, (g, w) in enumerate(zip(pages, words)):
            if g != w:
                errs.append("burst %d decoded as 0x%04X, sent 0x%04X" % (k, g, w))
                break
        return errs or ["decoded pages differ from the words sent"]
    bits = "".join(t for c, t in anns if c == "bit")
    want_bits = "".join("0x%d" % ((w >> k) & 1) for w in words for k in range(16))
    if bits != want_bits:
        errs.append("the decoder's bit annotations differ from the words sent")
    pulses = sum(1 for c, t in anns if c == "NLP")
    want_pulses = sum(17 + bin(w).count("1") for w in words)
    if pulses != want_pulses:
        errs.append("the decoder saw %d link pulses, wanted %d" % (pulses, want_pulses))
    return errs


def judge(words, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    errs = ["waveform: " + e for e in check_waveform(words, sim_stdout, cycles)]
    plus = pin_changes(sim_stdout, TD_PLUS)
    if plus and plus[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(words, plus, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(words):
    """Long enough for the latest start and the longest gaps allowed, and
    for more than 24 ms of silence after the last burst."""
    return PER_RUN * (len(words) + 1)


def span(sim_stdout):
    """Cycles from the first change of P0 or P1 to the last, or None."""
    moved = sorted(c for pin in (TD_PLUS, TD_MINUS) for c, _ in pin_changes(sim_stdout, pin)[1:])
    return moved[-1] - moved[0] if moved else None


def run_case(run_dir, args, words):
    """(objections, cycles from the first change to the last or None)."""
    cycles = run_cycles(words)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in tx_words(words)))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "eth_an.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    return judge(words, out.stdout, cycles), span(out.stdout)


def cases_for(seed):
    """(name, words): fixed cases, then seeded random ones."""
    fixed = [
        ("all zeros", [0x0000]),
        ("all ones", [0xFFFF]),
        ("the task sheet's example", [0x01E1, 0x01E1, 0x41E1]),
        ("a next page exchange", [0x81E1, 0xC1E1, 0xA008, 0xE008, 0x0300]),
        ("alternating bits, both phases", [0x5555, 0xAAAA]),
        ("one bit set, first and last", [0x0001, 0x8000]),
        ("eight words", [0x0021, 0x0061, 0x00A1, 0x01E1, 0x8000, 0x7FFF, 0x0000, 0xFFFF]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_WORDS if n % 2 else 3)
        rand.append(("random %d" % n, [rng.randrange(0x10000) for _ in range(count)]))
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
    if not os.path.isdir(os.path.join(DECODERS, DECODER_ID)):
        setup.append("the decoder %s is not in %s" % (DECODER_ID, DECODERS))
    for name in ("pe_sim", "eth_an.s", "run_args.txt"):
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
    for n, (name, words) in enumerate(cases_for(seed)):
        try:
            errs, cyc = run_case(run_dir, args, words)
        except Exception as e:  # never report a pass because the judge fell over
            errs, cyc = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (2 * len(words), cyc)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d word%s): %s"
              % (n, name, len(words), "" if len(words) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
