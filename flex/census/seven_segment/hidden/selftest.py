#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own examples
   into the words printed in the sheet (../../kits/seven_segment/TASK.md).
2. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back by the task sheet's rules, in its own
   code, so a judge that built the words wrongly would fail the ideal.
3. The RATE line, against the ideal generator's own change list.
4. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode, or one that leaves a pin not push-pull, is refused.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not display firmware): the command line and the word file must be
   accepted, and every case must fail cleanly.

The stand-in folders are made inside this folder and removed afterwards.
Exit status 0 only if everything is as expected."""
import os
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import accept  # noqa: E402
import ideal_wave  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "seven_segment")
PP = "-mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp -mode 4=pp -mode 5=pp -mode 6=pp -mode 7=pp"
EXAMPLES = [
    ([(3, True, False), (1, False, False), (4, False, False)], [0x0013, 0x0001, 0x0044],
     "0x0013, 0x0001, 0x0044"),
    ([(0xA, False, False), (0, False, True), (0xB, False, False)], [0x000A, 0x0020, 0x004B],
     "0x000A, 0x0020, 0x004B"),
]


def stand_in(parent, fault, run_args=PP + "\n", name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal_wave.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "seven_segment.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def main(argv):
    seeds = [int(s) for s in argv] or [1]
    wrong = 0

    def expect(ok, what):
        nonlocal wrong
        wrong += not ok
        print("%-5s %s" % ("ok" if ok else "WRONG", what))

    with open(os.path.join(KIT, "TASK.md")) as f:
        sheet = " ".join(f.read().split())
    for chars, words, text in EXAMPLES:
        expect(accept.tx_words(chars) == words and text in sheet,
               "interface: the task sheet's example gives the words printed in the sheet (%s)" % text)
    expect(accept.tx_words([(8, True, False)]) == [0x58]
           and accept.tx_words([(0, True, True), (0xF, False, False)]) == [0x30, 0x4F],
           "interface: one word is the last; a blank's digit bits are 0")
    for seed in seeds:
        for name, chars in accept.cases_for(seed):
            ok = (1 <= len(chars) <= accept.MAX_WORDS and not (chars[0][2] and not chars[0][1]))
            if not ok:
                expect(False, "seed %d case %s breaks the sheet's limits" % (seed, name))
    expect(True, "every case of every seed has 1 to 64 words and does not start with a plain blank")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", ""))
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-7s %s"
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
                              and passed == (not failed) and len(cases) > 0
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0]))
                ok = consistent and passed == should_pass and "judge:" not in run.stdout
                wrong += not ok
                print("%-11s %-4d %-8s %-6s %-7s %-8s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    last_case = accept.cases_for(seed)[-1][1]
                    t = ideal_wave.toggles(last_case)
                    want = "RATE bytes=%d cycles=%d" % (len(last_case), t[-1][0] - t[0][0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's changes give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([(PP + " -config clkdiv=1\n", True),
                                          (PP.replace("-mode", "-mo") + "\n", True),
                                          (PP + " -tx other.txt\n", False),
                                          (PP + " -t other.txt\n", False),
                                          (PP + " -cycles 5\n", False),
                                          (PP + " -inputs ff\n", False),
                                          (PP + " -stimulus s.txt\n", False),
                                          (PP + " -c clkdiv=1\n", False),
                                          (PP + "\n-config clkdiv=1\n", False),
                                          (PP.replace("7=pp", "7=od") + "\n", False),
                                          (PP.replace(" -mode 3=pp", "") + "\n", False),
                                          (PP + " -mode 2=in\n", False),
                                          ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text[-40:], "accepted" if good else lines[0][:90]))
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write(PP + "\n")
        with open(os.path.join(d, "seven_segment.s"), "w") as f:
            f.write("; Not display firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        n_cases = len(accept.cases_for(seeds[0]))
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == n_cases
               and all("FAIL: waveform: the pins never change" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:100] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
