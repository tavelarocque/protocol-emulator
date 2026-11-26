#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.word must give the words of the task sheet's own
   example (../../kits/dcf77/TASK.md), and the sheet must print them.
2. The results. For every entry of ideal_rx.FAULTS it builds a stand-in
   hand-in folder whose `pe_sim` is a wrapper script around ideal_rx.py (a
   receiver written in Python that reads the judge's stimulus file and
   prints "rx" lines; not chip firmware), runs accept.py on it from end to
   end exactly as on a real hand-in, and compares the verdict with the one
   that entry must get.
3. The RATE line, against the judge's own cases.
4. The hand-in rules: run_args.txt with a flag other than -config and -mode
   is refused, an empty one is accepted.
5. The real simulator, once, with a one-instruction program that loops on
   itself (not DCF77 firmware): the command line and the stimulus file must
   be accepted, and every case must fail cleanly with no words pushed.

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
import ideal_rx  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "dcf77")
NCASES = 15


def stand_in(parent, fault, run_args="-mode 0=in\n", name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal_rx.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "dcf77.s"), "w") as f:
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
    example = [accept.word(0, True), accept.word(1, False), accept.word(0, False), accept.word(0, False)]
    expect(example == [2, 1, 0, 0] and "the words are 0x0002, 0x0001, 0x0000, 0x0000" in sheet
           and "The host sends only the words defined above. All line coding, framing and timing must be done by the firmware." in sheet,
           "interface: the sheet's example gives 0x0002, 0x0001, 0x0000, 0x0000, and the sheet says so")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-13s %-4s %-8s %-6s %-7s %s" % ("result", "seed", "expected", "judge", "failed", "what it is"))
        for fault, (should_pass, what) in ideal_rx.FAULTS.items():
            d = stand_in(parent, fault)
            for seed in seeds:
                run, lines = judge(d, seed, env)
                last = lines[-1] if lines else ""
                cases = [l for l in lines if l.startswith("case ")]
                failed = [l for l in cases if ": FAIL" in l]
                rates = [l for l in lines if l.startswith("RATE ")]
                passed = run.returncode == 0
                consistent = (last == ("ACCEPT PASS" if passed else "ACCEPT FAIL")
                              and passed == (not failed) and len(cases) == NCASES
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("stimulus:" in l or "judge:" in l for l in failed))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-13s %-4d %-8s %-6s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail", "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)), what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok or (not should_pass and seed == seeds[0]):
                    for l in (failed[:1] if ok else lines + run.stderr.splitlines()):
                        print("        " + l[:200])
                if fault == "none":
                    case = accept.cases_for(seed)[-1]
                    moved = [c for c, _ in case.changes[1:]]
                    want = "RATE bytes=%d cycles=%d" % ((len(case.expected) + 7) // 8, moved[-1] - moved[0])
                    expect(rates == [want], "seed %d: %s, as the last case's own stimulus gives"
                           % (seed, rates[0] if rates else "no RATE line"))
        print()
        for n, (text, good) in enumerate([("-mode 0=in -config clkdiv=4\n", True),
                                          ("\n", True),
                                          ("-mo 0=in\n", True),
                                          ("-mode 0=in -stimulus other.txt\n", False),
                                          ("-mode 0=in -s other.txt\n", False),
                                          ("-mode 0=in -cycles 5\n", False),
                                          ("-mode 0=in -inputs ff\n", False),
                                          ("-mode 0=in -tx words.txt\n", False),
                                          ("-mode 0=in -c clkdiv=1\n", False),
                                          ("-mode 0=in\n-config clkdiv=1\n", False),
                                          ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write("-mode 0=in\n")
        with open(os.path.join(d, "dcf77.s"), "w") as f:
            f.write("; Not DCF77 firmware: one instruction that loops on itself.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == NCASES
               and all("FAIL: rx: 0 words pushed" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:100] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
