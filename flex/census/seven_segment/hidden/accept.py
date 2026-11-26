#!/usr/bin/env python3
"""Hidden acceptance test for the blind 7-segment display driver firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (seven_segment.s, run_args.txt) and pe_sim, which
may be a wrapper script: it is always invoked as RUN_DIR/pe_sim. There is no
host-side code: the task sheet fixes what the TX words mean, and this test
builds them itself.

For each case (a list of characters, each (digit, dp, blank)) the test
  1. builds the TX words the task sheet defines: bits 3..0 the digit, bit 4
     the decimal point, bit 5 blank, bit 6 set on the last word, the rest 0,
  2. runs RUN_DIR/pe_sim on RUN_DIR/seven_segment.s with those words,
  3. turns the printed changes of P0..P7 into a logic capture (a VCD file,
     one sample per core clock cycle, 10 MHz),
  4. has sigrok-cli's `seven_segment` decoder (common-anode, a..g on P0..P6,
     dp on P7) read it, and requires the decoded characters to be exactly
     the wanted ones, in order, each for as many 1000-cycle slots as the run
     shows it, with nothing extra,
  5. checks, from the pin changes themselves, what the decoder does not:
     every pin high until the first character, the first character within
     2 ms, every change within +-2 cycles of its ideal place counted from
     the first change, a change of character being one change of the pins,
     the display blank (all pins high) after the last character, and nothing
     after that.

Also refuses a run_args.txt with any flag other than -config and -mode, and
one that does not make all eight pins push-pull.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<characters shown> cycles=<cycles from the first pin change to the last>
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

CLOCK_HZ = 10_000_000        # core clock: one cycle = 100 ns
SLOT = 1000                  # cycles each character is shown (100 us)
TOL = 2                      # cycles a change may be from its ideal place
START_MAX = 20_000           # the first character appears by this cycle
TAIL = 5_000                 # cycles the run goes on after the last slot
MAX_WORDS = 64               # words in a run, 1 to this
DP, BLANK, LAST = 0x10, 0x20, 0x40
ALL_HIGH = 0xFF              # blank display, and the pins' reset state
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")
NAME = "seven_segment"
DECODER = ("seven_segment:polarity=common-anode:a=P0:b=P1:c=P2:d=P3:"
           "e=P4:f=P5:g=P6:dp=P7")


# ------------------------------------------------------- the host interface

def tx_words(chars):
    """The TX words of one run, as the task sheet defines them. A character
    is (digit, dp, blank). Payload only: nothing about the pins."""
    words = []
    for i, (digit, dp, blank) in enumerate(chars):
        w = (0 if blank else digit) | (DP if dp else 0) | (BLANK if blank else 0)
        if i == len(chars) - 1:
            w |= LAST
        words.append(w)
    return words


def text_of(state):
    """What the decoder prints for a display state (digit, dp, blank)."""
    digit, dp, blank = state
    return (" " if blank else "%X" % digit) + ("." if dp else "")


def norm(state):
    digit, dp, blank = state
    return (0 if blank else digit, bool(dp), bool(blank))


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name).
    All eight pins must be made push-pull."""
    i, pp = 0, set()
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
            m = re.fullmatch(r"([0-7])=(\w+)", args[i + 1])
            if m:
                pin = int(m.group(1))
                if m.group(2) == "pp":
                    pp.add(pin)
                else:
                    pp.discard(pin)
        i += 2
    if pp != set(range(8)):
        return "run_args.txt must make all eight pins push-pull (-mode P=pp); missing %s" % \
            ", ".join("P%d" % p for p in range(8) if p not in pp)
    return None


# ------------------------------------------------- from pe_sim to a capture

def pin_changes(sim_stdout):
    """[(cycle, value)] of the eight pins from pe_sim's "pins CYCLE XX"
    lines: the value at the first line, then only real changes."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, value = int(part[1]), int(part[2], 16) & 0xFF
            if not out or out[-1][1] != value:
                out.append((cycle, value))
    return out


def write_vcd(path, changes, cycles):
    ids = "!\"#$%&'("
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n$scope module pins $end\n" % (1_000_000_000 // CLOCK_HZ))
        for p in range(8):
            f.write("$var wire 1 %s P%d $end\n" % (ids[p], p))
        f.write("$upscope $end\n$enddefinitions $end\n")
        for cycle, value in changes:
            if cycle < cycles:
                f.write("#%d\n" % cycle)
                for p in range(8):
                    f.write("%d%s\n" % ((value >> p) & 1, ids[p]))
        f.write("#%d\n" % cycles)


def sigrok_annotations(changes, cycles):
    """What sigrok's seven_segment decoder makes of the capture:
    [(start sample, end sample, text)], in order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "pins.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", DECODER,
               "-A", "seven_segment", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if out.returncode != 0 or out.stderr.strip():
        raise RuntimeError("sigrok-cli failed: " + (out.stderr.strip() or "status %d" % out.returncode)[:200])
    found = []
    for line in out.stdout.split("\n"):
        m = re.match(r"(\d+)-(\d+) seven_segment-\d+: (.*)$", line)
        if m:
            found.append((int(m.group(1)), int(m.group(2)), m.group(3)))
        elif line.strip():
            raise RuntimeError("unexpected sigrok-cli output: %r" % line[:100])
    return found


# ------------------------------------------------------------ the two checks

def runs_of(chars):
    """The display over the run as [(state, slots)]: the blank before the
    first character (slots None), each run of equal characters, and the
    blank after the last (slots None), with equal neighbours merged."""
    blank = (0, False, True)
    seq = [(blank, None)] + [(norm(c), 1) for c in chars] + [(blank, None)]
    out = []
    for state, n in seq:
        if out and out[-1][0] == state:
            prev = out[-1][1]
            out[-1] = (state, None if prev is None or n is None else prev + n)
        else:
            out.append((state, n))
    return out


def check_decoder(chars, changes, cycles):
    """The decoded characters must be the wanted ones and nothing else.

    The decoder writes one annotation for every stretch of a valid pattern
    that ends with a change, so the blank before the first character and
    every character are annotated, and the final blank is not."""
    got = sigrok_annotations(changes, cycles)
    runs = runs_of(chars)[:-1]
    want = [text_of(s) for s, _ in runs]
    got_text = [t for _, _, t in got]
    if got_text != want:
        if len(got_text) != len(want):
            note = "decoded %d stretches, wanted %d" % (len(got_text), len(want))
        else:
            i = next(i for i in range(len(want)) if got_text[i] != want[i])
            note = "stretch %d decoded as %r, wanted %r" % (i, got_text[i], want[i])
        return [note + " (decoded %s)" % " ".join(repr(t) for t in got_text[:12])]
    for i, ((ss, es, t), (_, slots)) in enumerate(zip(got, runs)):
        if slots is not None and abs((es - ss) - slots * SLOT) > 2 * TOL:
            return ["%r (stretch %d) shown for %d cycles, wanted %d" % (t, i, es - ss, slots * SLOT)]
    return []


def check_waveform(chars, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    if not changes or changes[0][0] != 0:
        return ["no pin levels at cycle 0 in the simulator's output"]
    errs = []
    if changes[0][1] != ALL_HIGH:
        errs.append("the pins are %02x at cycle 0: all must be high until the first character"
                    % changes[0][1])
    moves = changes[1:]
    if not moves:
        return errs + ["the pins never change"]
    t0 = moves[0][0]
    if t0 > START_MAX:
        errs.append("the first character appears at cycle %d, limit %d" % (t0, START_MAX))
    # Where the pins must change: at T0, and at every slot boundary where the
    # character differs from the one before (the last followed by a blank).
    states = [norm(c) for c in chars] + [(0, False, True)]
    want = [t0] + [t0 + SLOT * k for k in range(1, len(states)) if states[k] != states[k - 1]]
    got = [c for c, _ in moves]
    for i, (a, w) in enumerate(zip(got, want)):
        if abs(a - w) > TOL:
            if i and abs(got[i] - got[i - 1]) < SLOT // 2:
                errs.append("change %d at cycle %d comes %d cycles after the one before: "
                            "a change of character must be one change of the pins"
                            % (i, a, a - got[i - 1]))
            else:
                errs.append("change %d is %d cycles after T0, ideal %d (limit +-%d)"
                            % (i, a - t0, w - t0, TOL))
            break
    else:
        if len(got) != len(want):
            errs.append("%d changes of the pins, wanted %d" % (len(got), len(want)))
    if moves[-1][1] != ALL_HIGH:
        errs.append("the pins end at %02x: the display must be blank (ff) after the last character"
                    % moves[-1][1])
    if cycles - (t0 + SLOT * len(chars)) < SLOT:
        errs.append("the run ended too soon after the last character to see the blank")
    return errs


def judge(chars, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = pin_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(chars, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(chars, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(chars):
    return START_MAX + SLOT * len(chars) + TAIL


def run_case(run_dir, args, chars):
    """(objections, cycles from the first pin change to the last or None)."""
    words = tx_words(chars)
    cycles = run_cycles(chars)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, NAME + ".s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in pin_changes(out.stdout)[1:]]
    return judge(chars, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def cases_for(seed):
    """(name, characters): fixed cases, then seeded random ones."""
    def d(text):
        """'3.14' style text to characters; '_' is a blank."""
        out = []
        for ch in text:
            if ch == ".":
                digit, _, blank = out[-1]
                out[-1] = (digit, True, blank)
            elif ch == "_":
                out.append((0, False, True))
            else:
                out.append((int(ch, 16), False, False))
        return out
    fixed = [
        ("the task sheet's example", d("3.14")),
        ("all sixteen digits", d("0123456789ABCDEF")),
        ("all sixteen with the decimal point", d("0.1.2.3.4.5.6.7.8.9.A.B.C.D.E.F.")),
        ("one character", d("8.")),
        ("a repeated digit", d("5555")),
        ("only the decimal point changes", d("77.77.7")),
        ("blanks, with and without the point", d("A_B_._.C_")),
        ("the point alone first", d("_.8_")),
        ("64 words", [((k * 7 + 3) % 16, k % 3 == 0, k % 11 == 5) for k in range(MAX_WORDS)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_WORDS if n % 2 else 12)
        chars = []
        while len(chars) < count:
            if chars and rng.random() < 0.25:
                c = chars[-1]                       # a repeat
            elif rng.random() < 0.12:
                c = (0, rng.random() < 0.5, True)   # a blank
            else:
                c = (rng.randrange(16), rng.random() < 0.3, False)
            if not chars and c[2] and not c[1]:
                continue                            # never a plain blank first
            chars.append(c)
        rand.append(("random %d" % n, chars))
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
    for name in ("pe_sim", NAME + ".s", "run_args.txt"):
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
    for n, (name, chars) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, chars)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (len(chars), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d word%s): %s"
              % (n, name, len(chars), "" if len(chars) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
