#!/usr/bin/env python3
"""Hidden acceptance test for the blind DCF77 receiver firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (dcf77.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The chip only
receives: there are no TX words.

For each case the test
  1. builds the demodulated DCF77 signal a receiver module would give on P0:
     real DCF77 minute frames (time and date in BCD with their parity bits,
     random weather bits), joined part way through a minute, with every
     rising edge up to 20 ms from its place and pulse lengths spread over
     the ranges the task sheet allows, and writes it as a -stimulus file,
  2. has sigrok-cli's `dcf77` decoder read that same signal and requires it
     to number exactly the bits this test expects the firmware to report,
     and, for every whole minute, to decode the time and date this test put
     there with every parity OK, so the input is a real instance of DCF77,
  3. runs RUN_DIR/pe_sim on RUN_DIR/dcf77.s with that stimulus,
  4. requires the "rx" words to be exactly the expected words, in order,
     with nothing extra, and each pushed no earlier than its pulse's rising
     edge and no later than 500 ms after it.

The words, as the task sheet fixes them: one word per pulse that follows the
first minute marker; bit 0 is the bit (1 for a long pulse), bit 1 is 1 when
the pulse is the first after a gap of about 2 s (bit 0 of a minute), all
other bits 0.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bits / 8, rounded up> cycles=<cycles from the first
    to the last change of P0 in the stimulus>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
exit status is 0 only on a full pass. Python standard library and sigrok-cli
only. Written apart from the firmware and kept from its author."""
import calendar
import datetime
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

CLOCK_HZ = 100_000           # core clock: one cycle = 10 us
MS = CLOCK_HZ // 1000        # 100 cycles a millisecond
SECOND = 1000 * MS
JITTER = 20 * MS             # a rising edge may be this far from its place
ZERO_W = (70 * MS, 130 * MS)     # pulse length of a 0
ONE_W = (170 * MS, 230 * MS)     # pulse length of a 1
DEADLINE = 500 * MS          # a word is due within this of its pulse's rising edge
TAIL = 1500 * MS             # the run goes on this long after the last rising edge
FIRST = 0x2                  # bit 1 of an RX word: first pulse after a marker
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
PIN = 0                      # P0


# ------------------------------------------------------------- DCF77 frames

def bcd(value, width):
    """value in BCD, least significant bit first, `width` bits."""
    b = (value % 10) | ((value // 10) << 4)
    return [(b >> k) & 1 for k in range(width)]


def last_sunday(year, month):
    day = max(d for d in range(1, 32)
              if d <= calendar.monthrange(year, month)[1]
              and calendar.weekday(year, month, d) == 6)
    return datetime.datetime(year, month, day)


def summer(t):
    """German civil time is CEST from the last Sunday of March, 02:00, to the
    last Sunday of October, 03:00 (to the minute is enough here)."""
    a = last_sunday(t.year, 3).replace(hour=2)
    b = last_sunday(t.year, 10).replace(hour=3)
    return a <= t < b


def frame(t, rng):
    """The 59 bits sent in the minute before `t` begins: they encode `t`."""
    bits = [0]                                   # 0: start of minute, always 0
    bits += [rng.randrange(2) for _ in range(14)]  # 1-14: weather and warnings
    bits += [1 if rng.random() < 0.05 else 0]    # 15: call bit
    st = summer(t)
    change = summer(t) != summer(t + datetime.timedelta(hours=1))
    bits += [int(change), int(st), int(not st), 0]   # 16-19: A1, Z1, Z2, A2
    bits += [1]                                  # 20: start of time, always 1
    m = bcd(t.minute, 7)
    bits += m + [sum(m) % 2]                     # 21-27 minutes, 28 parity
    h = bcd(t.hour, 6)
    bits += h + [sum(h) % 2]                     # 29-34 hours, 35 parity
    date = bcd(t.day, 6) + bcd(t.isoweekday(), 3) + bcd(t.month, 5) + bcd(t.year % 100, 8)
    bits += date + [sum(date) % 2]               # 36-57 date, 58 parity
    assert len(bits) == 59
    return bits


# ------------------------------------------------------------ one test case

class Case:
    """A run's signal and what must come of it.

    seconds: one entry per second of the run, None for a second without a
    pulse (the 59th of a minute, or a pulse the receiver module missed), or
    the bit. pulses: [(rise, fall, bit)] in cycles. expected: [(word, rise)]
    of the pulses the firmware must report. whole: [(index of the pulse that
    is bit 0, time encoded, whether the minute before had a missed pulse)]
    of every minute sigrok must decode in full.
    The prefix is sent during minute `start` - 1 and encodes `start`; whole
    minute i is sent during `start` + i and encodes the minute after it."""

    def __init__(self, name, start, joined, minutes, trailing, rng,
                 cut_short=False, extreme=False, missed=None):
        self.name = name
        frames = [frame(start + datetime.timedelta(minutes=i), rng) for i in range(minutes + 2)]
        seconds, owner = [], []
        for b in frames[0][joined:]:
            seconds.append(b)
            owner.append(None)
        seconds.append(None)
        owner.append(None)
        for i in range(minutes):
            for k, b in enumerate(frames[i + 1]):
                seconds.append(b)
                owner.append((i, k))
            seconds.append(None)
            owner.append(None)
        for b in frames[minutes + 1][:trailing]:
            seconds.append(b)
            owner.append(None)
        broken = set()
        if missed is not None:                   # (minute, bit), bit 1 to 57
            at = owner.index(missed)
            seconds[at] = None
            broken = {missed[0]}
        self.seconds = seconds
        # Where the edges fall.
        changes = []
        if cut_short:
            t0 = rng.randint(900 * MS, 975 * MS)
            changes = [(0, 1), (rng.randint(1 * MS, 60 * MS), 0)]
        else:
            t0 = rng.randint(25 * MS, 975 * MS)
            changes = [(0, 0)]
        pulses, n = [], 0
        for s, b in enumerate(seconds):
            if b is None:
                continue
            if extreme:
                rise = t0 + s * SECOND + (JITTER if n % 2 else -JITTER)
                width = (ZERO_W, ONE_W)[b][n // 2 % 2]
            else:
                rise = t0 + s * SECOND + rng.randint(-JITTER, JITTER)
                width = rng.randint(*(ZERO_W, ONE_W)[b])
            pulses.append((rise, rise + width, b))
            changes += [(rise, 1), (rise + width, 0)]
            n += 1
        self.pulses = pulses
        self.changes = changes
        self.cycles = pulses[-1][0] + TAIL
        # What the firmware must report, from the seconds (not the edges).
        expected, whole, synced, before = [], [], False, None
        for s, b in enumerate(seconds):
            if b is None:
                continue
            first = before is not None and s - before == 2
            synced = synced or first
            if synced:
                expected.append((b | (FIRST if first else 0), s))
            before = s
        rise_of = {}
        k = 0
        for s, b in enumerate(seconds):
            if b is not None:
                rise_of[s] = pulses[k][0]
                k += 1
        self.expected = [(w, rise_of[s]) for w, s in expected]
        for i in range(minutes):
            if i not in broken:
                s0 = owner.index((i, 0))
                idx = [j for j, (_, s) in enumerate(expected) if s == s0][0]
                # sigrok's decoder clears its list of date bits only at bit 58,
                # so after a missed pulse past bit 36 the next minute's date
                # parity also counts the bits of the broken one: not checked.
                whole.append((idx, start + datetime.timedelta(minutes=i + 1), i - 1 in broken))
        self.whole = whole

    def payload_bits(self):
        return len(self.expected)


def word(bit, first):
    """The RX word for one pulse, as the task sheet defines it."""
    return (bit & 1) | (FIRST if first else 0)


def cases_for(seed):
    fixed = [
        Case("joined at bit 50", datetime.datetime(2026, 11, 24, 14, 37), 50, 1, 2,
             random.Random(101)),
        Case("line high at the start: a pulse cut short", datetime.datetime(2026, 3, 29, 1, 59), 30, 1, 1,
             random.Random(102), cut_short=True),
        Case("a whole minute before the first marker", datetime.datetime(2027, 2, 28, 9, 5), 0, 1, 3,
             random.Random(103)),
        Case("shortest and longest pulses, edges 20 ms off", datetime.datetime(2026, 7, 4, 18, 0), 55, 1, 5,
             random.Random(104), extreme=True),
        Case("three minutes across a new year", datetime.datetime(2026, 12, 31, 23, 58), 56, 3, 1,
             random.Random(105)),
        Case("a pulse the receiver missed", datetime.datetime(2026, 10, 25, 2, 30), 40, 2, 4,
             random.Random(106), missed=(0, 30)),
        Case("ten pulses after the last whole minute", datetime.datetime(2026, 8, 15, 12, 12), 20, 1, 10,
             random.Random(107)),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        start = datetime.datetime(2026, 1, 1) + datetime.timedelta(minutes=rng.randrange(74 * 525600))
        minutes = rng.randint(1, 2)
        missed = None
        if rng.random() < 0.25:
            missed = (rng.randrange(minutes), rng.randint(1, 57))
        rand.append(Case("random %d" % n, start, rng.randint(0, 56), minutes, rng.randint(1, 10),
                         random.Random(rng.random()), cut_short=rng.random() < 0.25,
                         extreme=False, missed=missed))
    return fixed + rand


# ---------------------------------------------------- sigrok on the stimulus

def write_vcd(path, changes, cycles):
    with open(path, "w") as f:
        f.write("$timescale %d us $end\n" % (1_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for cycle, level in changes:
            f.write("#%d\n%d!\n" % (cycle, level))
        f.write("#%d\n" % cycles)


def sigrok_annotations(case):
    """[(start sample, end sample, text)] from sigrok's dcf77 decoder."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, case.changes, case.cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", "dcf77:data=P0",
               "-A", "dcf77", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if out.returncode != 0 or out.stderr.strip():
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append((int(m.group(1)), int(m.group(2)), m.group(3)))
    return found


def check_stimulus(case):
    """sigrok must number exactly the bits the firmware is to report, and
    decode every whole minute to the time put in it, all parities OK."""
    anns = sigrok_annotations(case)
    numbered = []
    for ss, _, text in anns:
        m = re.match(r"Bit (\d+): ([01])$", text)
        if m:
            numbered.append((int(m.group(1)), int(m.group(2)), ss))
    errs = []
    if len(numbered) != len(case.expected):
        errs.append("sigrok numbered %d bits, the test expects %d words" % (len(numbered), len(case.expected)))
    for k, ((n, b, ss), (w, rise)) in enumerate(zip(numbered, case.expected)):
        if b != w & 1 or (n == 0) != bool(w & FIRST) or ss != rise:
            errs.append("sigrok's bit %d (number %d, value %d, at %d) differs from the test's word 0x%04x at %d"
                        % (k, n, b, ss, w, rise))
            break
    for idx, t, after_miss in case.whole:
        if idx + 59 > len(numbered) or idx >= len(numbered):
            errs.append("minute %s: not decoded whole" % t)
            continue
        lo, hi = numbered[idx][2], numbered[idx + 58][2]
        texts = [x for ss, _, x in anns if lo <= ss <= hi]
        want = ["Minutes: %d" % t.minute, "Hours: %d" % t.hour, "Day: %d" % t.day,
                "Day of week: %d (%s)" % (t.isoweekday(), calendar.day_name[t.weekday()]),
                "Month: %d (%s)" % (t.month, calendar.month_name[t.month]), "Year: %d" % (t.year % 100),
                "Minute parity: OK", "Hour parity: OK",
                "Start of minute (always 0)", "Start of encoded time (always 1)"]
        if not after_miss:
            want.append("Date parity: OK")
        for x in want:
            if x not in texts:
                errs.append("minute %s: sigrok did not give %r" % (t, x))
                break
        bad = [x for x in texts if ("INVALID" in x or "!=" in x or "nvalid" in x)
               and not (after_miss and x.startswith("Date parity"))]
        if bad:
            errs.append("minute %s: sigrok warns %r" % (t, bad[0]))
    return errs


# ------------------------------------------------------------ the rx check

def rx_words(sim_stdout):
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "rx":
            out.append((int(part[1]), int(part[2])))
    return out


def check_rx(case, sim_stdout):
    got = rx_words(sim_stdout)
    want = case.expected
    errs = []
    for k, ((cycle, w), (ew, rise)) in enumerate(zip(got, want)):
        if w != ew:
            errs.append("word %d is 0x%04x, wanted 0x%04x (%s)"
                        % (k, w, ew, "first pulse after a marker" if ew & FIRST else "a %d bit" % (ew & 1)))
            break
        if not rise <= cycle <= rise + DEADLINE:
            errs.append("word %d pushed at cycle %d, %.2f ms after its pulse's rising edge (allowed 0 to %d ms)"
                        % (k, cycle, (cycle - rise) / MS, DEADLINE // MS))
            break
    if len(got) != len(want):
        errs.append("%d words pushed, wanted %d" % (len(got), len(want)))
    return errs


# ------------------------------------------------------------------ running

def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name)."""
    i = 0
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) == 1 and hits[0] in ("stimulus", "cycles", "tx", "inputs"):
            return "run_args.txt must not give -%s" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        i += 2
    return None


def run_case(run_dir, args, case):
    """Every objection to one case, each marked with the check that made it."""
    errs = ["stimulus: " + e for e in check_stimulus(case)]
    with tempfile.TemporaryDirectory() as d:
        st = os.path.join(d, "stimulus.txt")
        with open(st, "w") as f:
            f.write("".join("%d %02x\n" % (c, level << PIN) for c, level in case.changes))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "dcf77.s"),
               "-stimulus", st, "-cycles", str(case.cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        except (OSError, subprocess.TimeoutExpired) as e:
            return errs + ["simulator: %s" % e]
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return errs + ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])]
    return errs + ["rx: " + e for e in check_rx(case, out.stdout)]


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "dcf77.s", "run_args.txt"):
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
    try:
        cases = cases_for(seed)
    except Exception as e:  # never report a pass because the judge fell over
        print("judge: FAIL: %s: %s" % (type(e).__name__, e))
        print("ACCEPT FAIL")
        return 1
    for n, case in enumerate(cases):
        try:
            errs = run_case(run_dir, args, case)
        except Exception as e:
            errs = ["judge: %s: %s" % (type(e).__name__, e)]
        if not errs:
            moved = [c for c, _ in case.changes[1:]]
            rate = ((case.payload_bits() + 7) // 8, moved[-1] - moved[0])
        shown = []
        for kind in ("judge:", "stimulus:", "simulator:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d pulses, %d words): %s"
              % (n, case.name, len(case.pulses), len(case.expected), status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
