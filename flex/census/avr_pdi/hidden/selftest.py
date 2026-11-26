#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface: accept.tx_words and accept.stimulus turn the task sheet's
   example into the words and cycles printed in the sheet.
2. The waveforms: for every entry of ideal_wave.FAULTS, a stand-in hand-in
   folder whose `pe_sim` is a wrapper around ideal_wave.py (an ideal PDI
   programmer as a waveform generator, not chip firmware) is judged end to
   end by accept.py, and the verdict compared with the one it must get.
3. The RATE line of the ideal result.
4. The hand-in rules for run_args.txt.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not PDI firmware): the command line, the word file and the
   stimulus file must be accepted, and every case must fail cleanly.

Stand-in folders are made inside this folder and removed afterwards.
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

KIT = os.path.join(HERE, "..", "..", "kits", "avr_pdi")
GOOD_ARGS = "-mode 0=pp -mode 1=od\n"


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
    with open(os.path.join(d, "avr_pdi.s"), "w") as f:
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
    ex = accept.cases_for(1)[0][1]
    words = accept.tx_words(ex)
    expect(words == [0x0180, 0x00C1, 0x0059, 0x8000]
           and "0x0180, 0x00C1, 0x0059, 0x8000" in sheet,
           "interface: the sheet's example gives the words printed in the sheet")
    expect(accept.stimulus(ex) == [(0, 0xFF), (9805, 0xFD), (9905, 0xFF), (9955, 0xFD), (10255, 0xFF)]
           and "low at cycle 9805" in sheet and "10255" in sheet,
           "interface: the example's stimulus is at the cycles printed in the sheet")
    slots = accept.schedule(ex)
    expect(len(slots) == 210 and accept.rise(209) == 12475 and "cycle 12475" in sheet,
           "interface: the example has 210 slots, last edge at cycle 12475")
    last = accept.schedule(accept.cases_for(1)[5][1])
    expect(last[-19][0] == "dev" and all(w == "idle" for w, _ in last[-18:]) and "2 + 16 = 18" in sheet,
           "interface: an answered last instruction is followed by 2 + 16 = 18 idle slots, as the sheet says")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-11s %-4s %-8s %-6s %-7s %s" % ("result", "seed", "expected", "judge", "failed", "what it is"))
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
                              and not any("judge:" in l for l in cases))
                ok = consistent and passed == should_pass
                wrong += not ok
                kinds = sorted({k for l in failed for k in ("waveform", "decoder", "rx", "simulator")
                                if k + ":" in l})
                print("%-11s %-4d %-8s %-6s %-7s %s [%s]%s"
                      % (fault, seed, "pass" if should_pass else "fail", "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)), what, ",".join(kinds),
                         "" if ok else "   <-- WRONG VERDICT"))
                if not ok or (not should_pass and fault in ("flipbit", "late3")):
                    for l in (failed[:1] if ok else lines):
                        print("        " + l[:220])
                if fault == "none":
                    sess = accept.cases_for(seed)[-1][1]
                    want = "RATE bytes=%d cycles=%d" % (len(accept.stream(sess)),
                                                        accept.rise(len(accept.schedule(sess)) - 1) - accept.T0)
                    expect(rates == [want], "seed %d: %s, as the schedule gives"
                           % (seed, rates[0] if rates else "no RATE line"))
        print()
        for n, (text, good) in enumerate([("-mode 0=pp -mode 1=od -config clkdiv=1\n", True),
                                          ("-mo 0=pp -mo 1=od\n", True),
                                          ("-mode 0=pp -mode 1=pp\n", False),
                                          ("-mode 1=od\n", False),
                                          ("-mode 0=pp -mode 1=od -tx other.txt\n", False),
                                          ("-mode 0=pp -mode 1=od -stimulus s.txt\n", False),
                                          ("-mode 0=pp -mode 1=od -st s.txt\n", False),
                                          ("-mode 0=pp -mode 1=od -inputs ff\n", False),
                                          ("-mode 0=pp -mode 1=od -cycles 5\n", False),
                                          ("-mode 0=pp -mode 1=od -c clkdiv=1\n", False),
                                          ("-mode 0=pp\n-mode 1=od\n", False),
                                          ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # The real simulator, with a program that is not PDI firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write(GOOD_ARGS)
        with open(os.path.join(d, "avr_pdi.s"), "w") as f:
            f.write("; Not PDI firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 14
               and all("FAIL: waveform: PDI_CLK has 0 edges" in l for l in cases)
               and not any("judge:" in l or "simulator:" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
