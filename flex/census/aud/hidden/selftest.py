#!/usr/bin/env python3
"""Checks the AUD judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface: accept.rx_words on the task sheet's own example gives the
   words printed in the sheet.
2. The stimulus: on every case of every seed, sigrok's aud decoder reads the
   judge's stimulus as exactly the addresses the judge wants.
3. The results. For every fault in ideal_rx.FAULTS it builds a stand-in
   hand-in folder whose `pe_sim` is a wrapper around ideal_rx.py (an ideal
   receiver's output generator that decodes the stimulus in its own code,
   not chip firmware), runs accept.py on it end to end, and compares the
   verdict with the one that result must get.
4. The RATE line, against the stimulus.
5. The hand-in rules: run_args.txt with a flag other than -config and
   -mode, or with P0..P5 made outputs, is refused.
6. The real simulator, once, with a one-instruction program that loops on
   itself (not AUD firmware): every case must fail cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "aud")
EXAMPLE = ([(32, 0x0C001234, 0), (8, 0x5A, 0), (4, 0x7, 0)],
           "0x1234, 0x0C00, 0x125A, 0x0C00, 0x1257, 0x0C00")


def stand_in(parent, fault, run_args="-config in_base=2\n", name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal_rx.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "aud.s"), "w") as f:
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

    items, text = EXAMPLE
    with open(os.path.join(KIT, "TASK.md")) as f:
        sheet = " ".join(f.read().split())
    words = ", ".join("0x%04X" % w for w in accept.rx_words(items))
    expect(words == text and text in sheet,
           "interface: the sheet's example gives the words printed in the sheet (%s)" % words)

    for seed in seeds:
        bad = 0
        for name, case in accept.cases_for(seed):
            ch, _ = accept.stimulus(case)
            bad += accept.sigrok_addresses(ch, accept.run_cycles(ch)) != accept.full_addresses(case["items"])
        expect(bad == 0, "seed %d: sigrok reads every case's stimulus as the wanted addresses" % seed)

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-10s %-4s %-8s %-6s %-7s %s" % ("result", "seed", "expected", "judge", "failed", "what it is"))
        for fault, (should_pass, what) in ideal_rx.FAULTS.items():
            d = stand_in(parent, fault)
            for seed in seeds:
                run, lines = judge(d, seed, env)
                cases = [l for l in lines if l.startswith("case ")]
                failed = [l for l in cases if ": FAIL" in l]
                rates = [l for l in lines if l.startswith("RATE ")]
                passed = run.returncode == 0
                consistent = (lines and lines[-1] == ("ACCEPT PASS" if passed else "ACCEPT FAIL")
                              and passed == (not failed) and len(cases) == 14
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l for l in cases))
                ok = bool(consistent) and passed == should_pass
                wrong += not ok
                print("%-10s %-4d %-8s %-6s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail", "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)), what, "" if ok else "   <-- WRONG"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                elif failed and seed == seeds[0]:
                    print("           e.g. " + failed[0][:150])
                if fault == "none":
                    name, case = accept.cases_for(seed)[-1]
                    ch, _ = accept.stimulus(case)
                    want = "RATE bytes=%d cycles=%d" % (4 * len(case["items"]), ch[-1][0] - ch[1][0])
                    expect(rates == [want], "seed %d: %s, as the stimulus gives"
                           % (seed, rates[0] if rates else "no RATE line"))
        print()
        for n, (text, good) in enumerate([("-config in_base=2\n", True),
                                          ("-mode 6=pp -config in_base=2\n", True),
                                          ("-mo 2=in\n", True),
                                          ("\n", True),
                                          ("-mode 0=pp\n", False),
                                          ("-mode 5=od\n", False),
                                          ("-stimulus x.txt\n", False),
                                          ("-tx x.txt\n", False),
                                          ("-inputs ff\n", False),
                                          ("-cycles 5\n", False),
                                          ("-c in_base=2\n", False),
                                          ("-config in_base=2\n-mode 6=pp\n", False),
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
            f.write("-config in_base=2\n")
        with open(os.path.join(d, "aud.s"), "w") as f:
            f.write("; Not AUD firmware: one instruction that loops on itself.\nidle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 14
               and all("FAIL: rx: 0 rx words" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:100] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
