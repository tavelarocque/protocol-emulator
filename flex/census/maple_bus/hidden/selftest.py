#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's two examples
   into the words printed in the sheet, and accept.ideal_changes must give
   exactly the 98 changes of the sheet's example table.
2. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into frames by the task sheet's rules,
   in its own code, so a judge that built the words wrongly would fail the
   ideal waveform.
3. The RATE line, against the ideal generator's own list of changes.
4. The hand-in rules: run_args.txt may hold only -config and -mode, and
   must make P0 and P1 push-pull.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not Maple bus firmware): the command line and the word file must be
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

KIT = os.path.join(HERE, "..", "..", "kits", "maple_bus")
GOOD_ARGS = "-mode 0=pp -mode 1=pp\n"


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
    with open(os.path.join(d, "maple_bus.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def sheet_table(sheet):
    part = sheet.split("### An example")[1].split("### The host")[0]
    toks = []
    for row in part.splitlines():
        if row.startswith("|") and not row.startswith("|---") and "Changes" not in row:
            toks += row.split("|")[2].split()
    return toks


def main(argv):
    seeds = [int(s) for s in argv] or [1]
    wrong = 0

    def expect(ok, what):
        nonlocal wrong
        wrong += not ok
        print("%-5s %s" % ("ok" if ok else "WRONG", what))

    with open(os.path.join(KIT, "TASK.md")) as f:
        raw_sheet = f.read()
    sheet = " ".join(raw_sheet.split())
    ex1 = (0x00, 0x20, 0x01, [])
    ex2 = (0x00, 0x01, 0x09, [0xDE, 0xAD, 0xBE, 0xEF])
    expect(accept.tx_words([ex1]) == [0x0000, 0x2001] and "the two words 0x0000, 0x2001" in sheet,
           "interface: the sheet's first example gives the words printed in the sheet")
    expect(accept.tx_words([ex2]) == [0x0100, 0x0109, 0xDEAD, 0xBEEF]
           and "the four words 0x0100, 0x0109, 0xDEAD, 0xBEEF" in sheet
           and accept.frame_bytes(ex2)[-1] == 0x2B and accept.frame_bytes(ex1)[-1] == 0x21,
           "interface: the sheet's second example, and both checksums (0x21, 0x2B)")
    want = ["%s%s" % ("AB"[l], "+" if v else "-") for l, v, _ in accept.ideal_changes(ex1)]
    expect(sheet_table(raw_sheet) == want and len(want) == 98,
           "the sheet's table of 98 changes is the judge's ideal sequence, change for change")
    expect(accept.tx_words([ex1, ex2]) == [0, 0x2001, 0x0100, 0x0109, 0xDEAD, 0xBEEF],
           "interface: frames follow one another with nothing between them")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-12s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", ""))
        print("%-12s %-4s %-8s %-6s %-7s %-8s %-7s %s"
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
                              and (not rates or lines[-2] == rates[0])
                              and not run.stderr.strip())
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-12s %-4d %-8s %-6s %-7s %-8s %-7s %s%s"
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
                    raw = [[len(f[3]) // 4, f[0], f[1], f[2]] + list(f[3]) for f in last_case]
                    ev = ideal_wave.changes(raw)
                    want = "RATE bytes=%d cycles=%d" % (sum(len(r) for r in raw), ev[-1][0] - ev[0][0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's changes give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([("-mode 0=pp -mode 1=pp -config clkdiv=2\n", True),
                                          ("-mo 0=pp -m 1=pp -mode 2=in\n", True),
                                          ("-mode 0=pp\n", False),
                                          ("-mode 0=pp -mode 1=od\n", False),
                                          ("-mode 0=pp -mode 1=pp -mode 1=in\n", False),
                                          ("-mode 0=pp -mode 1=pp -tx other.txt\n", False),
                                          ("-mode 0=pp -mode 1=pp -t other.txt\n", False),
                                          ("-mode 0=pp -mode 1=pp -cycles 5\n", False),
                                          ("-mode 0=pp -mode 1=pp -inputs ff\n", False),
                                          ("-mode 0=pp -mode 1=pp -stimulus s.txt\n", False),
                                          ("-mode 0=pp -mode 1=pp -c clkdiv=1\n", False),
                                          ("-mode 0=pp\n-mode 1=pp\n", False),
                                          ("-mode 0=pp -mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # The real simulator, with a program that is not Maple bus firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write(GOOD_ARGS)
        with open(os.path.join(d, "maple_bus.s"), "w") as f:
            f.write("; Not Maple bus firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 16
               and all("FAIL: waveform: 0 changes on the lines" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
