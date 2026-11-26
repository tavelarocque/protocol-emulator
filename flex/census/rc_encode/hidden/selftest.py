#!/usr/bin/env python3
"""Checks the rc_encode judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own examples
   into the words printed in the sheet (../../kits/rc_encode/TASK.md), and
   the sheet's example table must agree with accept.ideal_offsets.
2. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into code words by the task sheet's
   rules, in its own code, so a judge that built the words wrongly would
   fail the ideal waveform.
3. The RATE line, against the ideal generator's own edge list.
4. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode is refused.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not rc_encode firmware): the command line and the word file must be
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

KIT = os.path.join(HERE, "..", "..", "kits", "rc_encode")
SHEET_EXAMPLES = [
    (["0f1000100f01"], [0x0018, 0x0481], "0x0018, 0x0481"),
    (["111111111111"], [0x0555, 0x0555], "0x0555, 0x0555"),
    (["ffffffffffff"], [0x0AAA, 0x0AAA], "0x0AAA, 0x0AAA"),
]
SHEET_TABLE = ["| 0 | 0 | short, short | 0, 1600, 6400, 8000 |",
               "| 1 | f | short, long | 12800, 14400, 19200, 24000 |",
               "| 2 | 1 | long, long | 25600, 30400, 32000, 36800 |",
               "| 11 | 1 | long, long | 140800, 145600, 147200, 152000 |",
               "| sync | | | 153600, 155200 |",
               "The next frame's first rise is at 204800."]


def stand_in(parent, fault, run_args="-mode 0=pp\n", name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal_wave.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "rc_encode.s"), "w") as f:
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
        raw = f.read()
    sheet = " ".join(raw.split())
    for codes, words, text in SHEET_EXAMPLES:
        expect(accept.tx_words(codes) == words and text in sheet,
               "interface: %s gives the words printed in the sheet (%s)" % (codes[0], text))
    expect(accept.tx_words(["000000000000", "f00000000001"]) == [0, 0, 2, 0x400],
           "interface: two words per code word, first-sent trit in bits 1..0")
    offs = accept.ideal_offsets("0f1000100f01")
    table = [[0, 1600, 6400, 8000], [12800, 14400, 19200, 24000],
             [25600, 30400, 32000, 36800]]
    agree = all(all(" ".join(l.split()) in sheet for l in SHEET_TABLE) for _ in [0])
    agree = agree and [c for c, _ in offs[:12]] == sum(table, [])
    agree = agree and [c for c, _ in offs[44:]] == [140800, 145600, 147200, 152000, 153600, 155200]
    agree = agree and accept.FRAME == 204800 and len(offs) == 50
    expect(agree, "interface: the sheet's example table matches the judge's ideal edges")
    expect(chr(0x2014) not in raw, "the task sheet has no em-dash")

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
                              and (not rates or lines[-2] == rates[0]))
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
                    t = ideal_wave.toggles(last_case)
                    want = "RATE bytes=%d cycles=%d" % (3 * len(last_case), t[-1] - t[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's edges give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([("-mode 0=pp -config clkdiv=400\n", True),
                                          ("-mo 0=pp\n", True),
                                          ("-mode 0=pp -tx other.txt\n", False),
                                          ("-mode 0=pp -t other.txt\n", False),
                                          ("-mode 0=pp -cycles 5\n", False),
                                          ("-mode 0=pp -inputs ff\n", False),
                                          ("-mode 0=pp -stimulus s.txt\n", False),
                                          ("-mode 0=pp -c clkdiv=1\n", False),
                                          ("-mode 0=pp\n-config clkdiv=1\n", False),
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
            f.write("-mode 0=pp\n")
        with open(os.path.join(d, "rc_encode.s"), "w") as f:
            f.write("; Not rc_encode firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 15
               and all("FAIL: waveform: P0 never changes" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:100] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
