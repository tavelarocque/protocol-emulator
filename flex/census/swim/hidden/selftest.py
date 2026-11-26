#!/usr/bin/env python3
"""Checks the SWIM judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (../../kits/swim/TASK.md), and the
   judge's timetable must put the example's edges where the sheet's table
   does.
2. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal SWIM host as a waveform generator that listens
   to the judge's stimulus; not chip firmware), runs accept.py on it from
   end to end exactly as on a real hand-in, and compares the verdict with
   the one that waveform must get.
3. The RATE line, against the stand-in's own output.
4. The hand-in rules: run_args.txt with a flag other than -config and
   -mode, or without exactly -mode 0=od, is refused.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not SWIM firmware): the command line, the word file and the
   stimulus file must be accepted, and every case must fail cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "swim")
EXAMPLE_OPS = [accept.op_srst(), accept.op_wotf(0x007F80, [0xA0]), accept.op_rotf(0x004800, [0x12, 0x34])]
EXAMPLE_WORDS = [0x0000, 0x0201, 0x0000, 0x7F80, 0x00A0, 0x0102, 0x0000, 0x4800]
EXAMPLE_TEXT = "0x0000, 0x0201, 0x0000, 0x7F80, 0x00A0, 0x0102, 0x0000, 0x4800"
# The sheet's table: a WOTF of 0xA0 to 0x007F80 right after the sync frame.
TABLE = [(250860, 0), (250960, 1), (250970, 0), (251070, 1), (251080, 0), (251090, 1),
         (251190, 0), (251290, 1), (251300, 0), (251310, 1)]


def stand_in(parent, fault, run_args="-mode 0=od\n", name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal_wave.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "swim.s"), "w") as f:
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
    expect(accept.tx_words(EXAMPLE_OPS) == EXAMPLE_WORDS and EXAMPLE_TEXT in sheet,
           "interface: the task sheet's example gives the words printed in the sheet (%s)" % EXAMPLE_TEXT)
    t = accept.Timetable([accept.op_wotf(0x007F80, [0xA0])])
    expect([(c, lv) for c, lv, _ in t.host[:10]] == TABLE
           and t.target[3:5] == [(251410, 0), (251420, 1)] and t.target[5][0] == 252730
           and t.host[10][0] == 251630 and "| ACK | 1 | 251410 | 251420 | target |" in sheet,
           "timetable: the sheet's example table, ACK at 251410, next frame at 251630, its ACK at 252730")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-11s %-4s %-8s %-6s %-7s %-7s %-7s %-3s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "edges", "decoder", "rx", ""))
        print("%-11s %-4s %-8s %-6s %-7s %-7s %-7s %-3s %s"
              % ("", "", "", "", "failed", "check", "check", "", "what it is"))
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
                              and not any("judge:" in l or "simulator:" in l for l in cases))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-11s %-4d %-8s %-6s %-7s %-7s %-7s %-3s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("edges:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         "obj" if any("rx:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    # The RATE line, from the stand-in's own output on the last case.
                    ops = accept.cases_for(seed)[-1][1]
                    table = accept.Timetable(ops)
                    with tempfile.TemporaryDirectory(dir=parent) as w:
                        tx, st = os.path.join(w, "tx"), os.path.join(w, "st")
                        with open(tx, "w") as f:
                            f.write("".join("%d\n" % x for x in accept.tx_words(ops)))
                        with open(st, "w") as f:
                            f.write(accept.stimulus_text(table.target))
                        out = subprocess.run([sys.executable, "-B", os.path.join(HERE, "ideal_wave.py"),
                                              "run", "x.s", "-tx", tx, "-stimulus", st,
                                              "-cycles", str(table.end)],
                                             capture_output=True, text=True).stdout
                    moved = [c for c, _ in accept.p0_changes(out)[1:]]
                    want = "RATE bytes=%d cycles=%d" % (sum(len(o.get("data", [])) for o in ops),
                                                        moved[-1] - moved[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the stand-in's own edges give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([("-mode 0=od -config clkdiv=1\n", True),
                                          ("-mo 0=od\n", True),
                                          ("-mode 0=pp\n", False),
                                          ("-config clkdiv=1\n", False),
                                          ("-mode 0=od -mode 1=pp\n", False),
                                          ("-mode 0=od -tx other.txt\n", False),
                                          ("-mode 0=od -s other.txt\n", False),
                                          ("-mode 0=od -cycles 5\n", False),
                                          ("-mode 0=od -inputs ff\n", False),
                                          ("-mode 0=od -c clkdiv=1\n", False),
                                          ("-mode 0=od\n-config clkdiv=1\n", False),
                                          ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:100]))
        # The real simulator, with a program that is not SWIM firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write("-mode 0=od\n")
        with open(os.path.join(d, "swim.s"), "w") as f:
            f.write("; Not SWIM firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 15
               and all("FAIL: edges: the chip never moves P0" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
