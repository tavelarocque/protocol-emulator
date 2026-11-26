#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words and accept.plan must turn the task
   sheet's example into the words and the stimulus file printed in the
   sheet (../../kits/iec/TASK.md).
2. The decoder sees the stimulus as IEC: the ideal waveform of every case
   decodes to exactly the wanted bus bytes (that is part of every pass).
3. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper around ideal_wave.py
   (an ideal controller as a waveform generator, not chip firmware) and runs
   accept.py on it end to end, as on a real hand-in, comparing the verdict
   with the one that waveform must get. The stand-in reads the judge's TX
   words back by the sheet's rules and reacts to the judge's stimulus file,
   in its own code.
4. The RATE line, against the generator's own output.
5. The hand-in rules: run_args.txt with a flag other than -config and
   -mode, or without P0..P2 open-drain, is refused.
6. The real simulator, once, with a one-instruction program that drives no
   pin (not IEC firmware): every case must fail cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "iec")
GOOD_ARGS = "-mode 0=od -mode 1=od -mode 2=od\n"


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
    with open(os.path.join(d, "iec.s"), "w") as f:
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

    # 1. The interface, against the sheet's own example.
    with open(os.path.join(KIT, "TASK.md")) as f:
        sheet_raw = f.read()
    sheet = " ".join(sheet_raw.split())
    example = [(4, 7, [0x48, 0x49])]
    words = accept.tx_words(example)
    expect(words == [0x0704, 0x0048, 0x0149] and "0x0704, 0x0048, 0x0149" in sheet,
           "interface: the sheet's example gives the words printed in the sheet")
    expect([b for b, _, _ in accept.bus_bytes(example)] == [0x24, 0x67, 0x48, 0x49, 0x3F]
           and "0x24 (LISTEN 4), 0x67 (SECOND 7), 0x48, 0x49 (EOI), 0x3F" in sheet,
           "interface: the sheet's example bus bytes")
    events, _ = accept.plan(example, accept.low)
    stim = accept.stimulus_text(events)
    block = "\n".join("    " + l for l in stim.strip().splitlines())
    expect(block in sheet_raw, "interface: the sheet's stimulus example is the quickest listener's script")
    expect(accept.tx_words([(30, 15, [7])]) == [0x0F1E, 0x107],
           "interface: one data byte is two words, bit 8 on the data word")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-10s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "failed", "waveform", "decoder", "what it is"))
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
                              and passed == (not failed) and len(cases) == 15
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l or "simulator:" in l for l in cases))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-10s %-4d %-8s %-6s %-7s %-8s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail", "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    name, trs, pick = accept.cases_for(seed)[-1]
                    ev, tr = accept.plan(trs, pick)
                    out = ideal_wave.talk(trs, ideal_wave.Listener([(0, 1)] + ev), "none")
                    times = sorted({c for c, _, _ in out})
                    want = "RATE bytes=%d cycles=%d" % (sum(len(t[2]) for t in trs),
                                                        times[-1] - times[0])
                    expect(rates == [want], "seed %d: %s, as the generator's output gives"
                           % (seed, rates[0] if rates else "no RATE line"))
        print()
        for n, (text, good) in enumerate([
                (GOOD_ARGS, True),
                ("-mo 0=od -mo 1=od -mo 2=od -config clkdiv=10\n", True),
                ("-mode 0=od -mode 1=od\n", False),
                ("-mode 0=pp -mode 1=od -mode 2=od\n", False),
                ("-mode 0=od -mode 1=od -mode 2=od -tx other.txt\n", False),
                ("-mode 0=od -mode 1=od -mode 2=od -s other.txt\n", False),
                ("-mode 0=od -mode 1=od -mode 2=od -cycles 5\n", False),
                ("-mode 0=od -mode 1=od -mode 2=od -inputs ff\n", False),
                ("-mode 0=od -mode 1=od -mode 2=od -c clkdiv=1\n", False),
                ("-mode 0=od -mode 1=od\n-mode 2=od\n", False),
                ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused, "run_args.txt %r: %s"
                   % (text, "accepted" if good else lines[0][:90]))
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write(GOOD_ARGS)
        with open(os.path.join(d, "iec.s"), "w") as f:
            f.write("; Not IEC firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 15
               and all("FAIL: waveform: transaction 0: ATN pulled low: the chip never does it" in l
                       for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
