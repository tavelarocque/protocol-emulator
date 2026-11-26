#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words and accept.slot_values must turn the task
   sheet's own example into the words and slot values printed in the sheet
   (../../kits/ac97/TASK.md).
2. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into frames, and the judge's stimulus
   file back into clock edges, in its own code.
3. The RATE line, against the stand-in's own output for the last case.
4. The hand-in rules: run_args.txt with a flag other than -config and -mode,
   or without P1 and P2 push-pull, or with P0 an output, is refused.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not AC '97 firmware): the command line, the word file and the
   stimulus file must be accepted, and every case must fail cleanly.

The stand-in folders are made inside this folder and removed afterwards.
Exit status 0 only if everything is as expected."""
import os
import random
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import accept  # noqa: E402
import ideal_wave  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "ac97")
GOOD_ARGS = "-mode 1=pp -mode 2=pp\n"
EXAMPLE = [("write", 0x02, 0x0808, 0x1234, 0xEDCB), ("read", 0x7C, 0, 0x7FFF, 0x8000)]
EXAMPLE_WORDS = [0x0102, 0x0808, 0x1234, 0xEDCB, 0x01FC, 0x0000, 0x7FFF, 0x8000]
EXAMPLE_TEXT = "0x0102, 0x0808, 0x1234, 0xEDCB, 0x01FC, 0x0000, 0x7FFF, 0x8000"
EXAMPLE_SLOTS = [[0xF800, 0x02000, 0x08080, 0x12340, 0xEDCB0] + [0] * 8,
                 [0xD800, 0xFC000, 0x00000, 0x7FFF0, 0x80000] + [0] * 8]
TABLE_ROWS = ["| 0, tag | 0xF800 | 0xD800 |", "| 1, command address | 0x02000 | 0xFC000 |",
              "| 2, command data | 0x08080 | 0x00000 |", "| 3, left | 0x12340 | 0x7FFF0 |",
              "| 4, right | 0xEDCB0 | 0x80000 |"]


def stand_in(parent, fault, run_args=GOOD_ARGS, name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal_wave.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "ac97.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def expected_rate(seed):
    """The RATE line for the ideal waveform, from the stand-in's own output
    for the last case, with the judge's clock for that case."""
    cases = accept.cases_for(seed)
    rng = random.Random("clock %d" % seed)
    for _, frames in cases:
        cycles = accept.run_cycles(frames)
        rises = accept.clock(rng, cycles)
    stim = [(0, 0)] + [e for r in rises for e in ((r, 1), (r + accept.HIGH, 0))]
    text = ideal_wave.pins_text(ideal_wave.frames_of(accept.tx_words(frames)), stim, cycles)
    moves, last = [], 0x06
    for line in text.splitlines():
        _, c, v = line.split()
        v = int(v, 16) & 0x06
        if v != last:
            moves.append(int(c))
            last = v
    return "RATE bytes=%d cycles=%d" % (8 * len(frames), moves[-1] - moves[0])


def main(argv):
    seeds = [int(s) for s in argv] or [1]
    wrong = 0

    def expect(ok, what):
        nonlocal wrong
        wrong += not ok
        print("%-5s %s" % ("ok" if ok else "WRONG", what))

    with open(os.path.join(KIT, "TASK.md")) as f:
        raw = f.read()
    sheet = " ".join(raw.split())
    expect(accept.tx_words(EXAMPLE) == EXAMPLE_WORDS and EXAMPLE_TEXT in sheet,
           "interface: the sheet's example gives the words printed in the sheet (%s)" % EXAMPLE_TEXT)
    expect([accept.slot_values(fr) for fr in EXAMPLE] == EXAMPLE_SLOTS
           and all(row in raw for row in TABLE_ROWS),
           "interface: the sheet's example gives the slot values in the sheet's table")
    expect(accept.tx_words([(None, 0, 0, 1, 2)]) == [0, 0, 1, 2]
           and accept.slot_values((None, 0, 0, 1, 2))[:3] == [0x9800, 0, 0],
           "interface: a frame without a command is CTRL 0, DATA 0, tag 0x9800, slots 1 and 2 zero")
    expect("The host sends only the words defined above. All line coding, framing and timing "
           "must be done by the firmware." in sheet, "the sheet states the host-interface rule")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-11s %-4s %-8s %-6s %-7s %-7s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "pins", "decoder", ""))
        print("%-11s %-4s %-8s %-6s %-7s %-7s %-7s %s"
              % ("", "", "", "", "failed", "check", "check", "what it is"))
        for fault, (should_pass, what) in ideal_wave.FAULTS.items():
            d = stand_in(parent, fault)
            for seed in seeds:
                run, lines = judge(d, seed, env)
                last = lines[-1] if lines else ""
                cases = [l for l in lines if l.startswith("case ")]
                failed = [l for l in cases if ": FAIL" in l]
                rates = [l for l in lines if l.startswith("RATE ")]
                passed = run.returncode == 0
                consistent = (last == ("ACCEPT PASS" if passed else "ACCEPT FAIL")
                              and passed == (not failed) and len(cases) == 13
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l or "simulator:" in l for l in failed))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-11s %-4d %-8s %-6s %-7s %-7s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("pins:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok or (failed and seed == seeds[0]):
                    for l in (failed[:1] if ok else lines):
                        print("        " + l[:230])
                if not ok:
                    sys.stdout.write(run.stderr)
                if fault == "none":
                    want = expected_rate(seed)
                    expect(rates == [want], "seed %d: %s, as the stand-in's own output gives"
                           % (seed, rates[0] if rates else "no RATE line"))
        print()
        for n, (text, good) in enumerate([(GOOD_ARGS, True),
                                          ("-mo 1=pp -mo 2=pp -config autopull=1\n", True),
                                          ("-mode 0=in -mode 1=pp -mode 2=pp\n", True),
                                          ("-mode 1=pp -mode 2=pp -tx other.txt\n", False),
                                          ("-mode 1=pp -mode 2=pp -stimulus s.txt\n", False),
                                          ("-mode 1=pp -mode 2=pp -s s.txt\n", False),
                                          ("-mode 1=pp -mode 2=pp -cycles 5\n", False),
                                          ("-mode 1=pp -mode 2=pp -inputs 01\n", False),
                                          ("-mode 1=pp -mode 2=pp -c clkdiv=1\n", False),
                                          ("-mode 1=pp\n-mode 2=pp\n", False),
                                          ("-mode 1=pp\n", False),
                                          ("-mode 1=pp -mode 2=od\n", False),
                                          ("-mode 0=pp -mode 1=pp -mode 2=pp\n", False),
                                          ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # The real simulator, with a program that is not AC '97 firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write(GOOD_ARGS)
        with open(os.path.join(d, "ac97.s"), "w") as f:
            f.write("; Not AC '97 firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 13
               and all("FAIL: pins: SYNC is not low at cycle 40" in l and "simulator:" not in l
                       and "judge:" not in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:150] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
