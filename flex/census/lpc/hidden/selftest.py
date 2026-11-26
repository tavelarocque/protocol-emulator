#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware for LPC is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface: accept.tx_words, accept.stimulus and accept.rx_words on
   the task sheet's own example give exactly the words and stimulus lines
   printed in the sheet (../../kits/lpc/TASK.md).
2. The stimulus: for every case of every seed, sigrok's lpc decoder reads
   the ideal bus (ideal host plus the scripted peripheral) as the wanted
   reads (accept.check_stimulus).
3. The waveforms: for every waveform in ideal_wave.FAULTS, a stand-in
   hand-in folder whose pe_sim is a wrapper around ideal_wave.py (an ideal
   waveform generator, not chip firmware) is judged end to end by
   accept.py, and the verdict must be the one that waveform must get. The
   stand-in reads the judge's words back by the sheet's rules and reads the
   data bytes from the judge's stimulus file, so a judge whose words or
   stimulus were wrong would fail the ideal waveform.
4. The RATE line equals the figure worked out from the stand-in's own
   output for the ideal waveform.
5. The hand-in rules: bad run_args.txt files (other flags, wrong pin
   modes) are refused as a setup failure, good ones accepted.
6. The real simulator, once, with a one-instruction program that loops on
   itself and drives no pin (not LPC firmware): the command line, the word
   file and the stimulus file must be accepted, and every case must fail
   cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "lpc")
GOOD_ARGS = "-mode 0=od -mode 1=od -mode 2=od -mode 3=od -mode 4=pp -mode 5=pp\n"


def stand_in(parent, fault, run_args=GOOD_ARGS, name=None, real=False):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        if real:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.join(KIT, "pe_sim"))
        else:
            f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                    % (sys.executable, os.path.join(HERE, "ideal_wave.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "lpc.s"), "w") as f:
        f.write("idle: jmp idle   ; drives no pin: NOT LPC firmware\n" if real else
                "; placeholder: the stand-in simulator never reads this file\n")
    return d


def judge(d, seed):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True)
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
    ex = [(accept.IO, 0x0080, 0x5A), (accept.MEM, 0xFFC01234, 0x07)]
    words = accept.tx_words(ex)
    text = ", ".join("0x%04X" % w for w in words)
    expect(words == [0x0000, 0x0080, 0x0001, 0xFFC0, 0x1234] and text in sheet,
           "interface: the sheet's example gives the words printed in it (%s)" % text)
    rx = accept.rx_words(ex)
    expect(rx == [0x5A, 0x07] and "pushes 0x005A and then 0x0007" in sheet,
           "interface: the sheet's example gives the rx words printed in it")
    stim = " ".join("%d %02x" % cv for cv in accept.stimulus(ex[:1]))
    expect(stim == "0 ff 324 f0 344 fa 364 f5 384 ff" and stim in sheet,
           "interface: the sheet's example stimulus is the judge's (%s)" % stim)
    expect(accept.run_cycles(ex[:1]) == 100 + 20 * (4 + 24) and accept.last_clock(ex[:1]) == 16,
           "interface: N and L for the sheet's example (660, 16)")

    for seed in seeds:
        bad = [(name, accept.check_stimulus(t)) for name, t in accept.cases_for(seed)]
        bad = [(n, b) for n, b in bad if b]
        expect(not bad, "stimulus: sigrok decodes the ideal bus of every case, seed %d%s"
               % (seed, (": " + str(bad[0])) if bad else ""))

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        for fault, (should_pass, what) in ideal_wave.FAULTS.items():
            d = stand_in(parent, fault)
            for seed in seeds:
                run, lines = judge(d, seed)
                passed = run.returncode == 0 and lines[-1:] == ["ACCEPT PASS"]
                fails = [l for l in lines if l.startswith("case") and "FAIL" not in l]
                detail = ""
                if not should_pass:
                    failing = [l for l in lines if "FAIL:" in l]
                    detail = " (%d of %d cases fail; first: %s)" % (
                        len(failing), len(failing) + len(fails),
                        failing[0].split("FAIL: ", 1)[1][:110] if failing else "none")
                expect(passed == should_pass,
                       "%s, seed %d: %s, must %s%s" % (fault, seed, what,
                                                      "pass" if should_pass else "fail", detail))
            if fault == "none":
                for seed in seeds:
                    run, lines = judge(d, seed)
                    name, trans = accept.cases_for(seed)[-1]
                    with tempfile.TemporaryDirectory() as t:
                        tx = os.path.join(t, "tx")
                        st = os.path.join(t, "st")
                        open(tx, "w").write("".join("%d\n" % w for w in accept.tx_words(trans)))
                        open(st, "w").write("".join("%d %02x\n" % cv for cv in accept.stimulus(trans)))
                        out = subprocess.run([sys.executable, "-B", os.path.join(HERE, "ideal_wave.py"),
                                              "run", "x.s", "-tx", tx, "-stimulus", st, "-cycles",
                                              str(accept.run_cycles(trans))],
                                             capture_output=True, text=True).stdout
                    pins = [int(l.split()[1]) for l in out.splitlines() if l.startswith("pins")]
                    want = "RATE bytes=%d cycles=%d" % (len(trans), pins[-1] - pins[1])
                    expect(want in lines, "RATE, seed %d: %s" % (seed, want))

        refused = [
            ("-tx", "-tx foo " + GOOD_ARGS),
            ("-stimulus", GOOD_ARGS.strip() + " -stimulus foo\n"),
            ("-s (prefix of -stimulus)", GOOD_ARGS.strip() + " -s foo\n"),
            ("-cycles", GOOD_ARGS.strip() + " -cycles 5\n"),
            ("-inputs", GOOD_ARGS.strip() + " -inputs ff\n"),
            ("-c (ambiguous)", GOOD_ARGS.strip() + " -c start=0\n"),
            ("two lines", GOOD_ARGS + "-config start=0\n"),
            ("flag without value", GOOD_ARGS.strip() + " -config\n"),
            ("LAD push-pull", GOOD_ARGS.replace("0=od", "0=pp")),
            ("LCLK open-drain", GOOD_ARGS.replace("5=pp", "5=od")),
            ("LFRAME# missing", GOOD_ARGS.replace("-mode 4=pp ", "")),
        ]
        for n, (what, args) in enumerate(refused):
            d = stand_in(parent, "none", args, name="bad%d" % n)
            run, lines = judge(d, seeds[0])
            expect(run.returncode != 0 and lines[0].startswith("setup: FAIL"),
                   "hand-in rules: run_args.txt with %s refused" % what)
        accepted = [("modes in another order, with -config", "-config clkdiv=1 -mode 5=pp -mode 4=pp "
                     "-mode 3=od -mode 2=od -mode 1=od -mode 0=od\n"),
                    ("shortened -mo", GOOD_ARGS.replace("-mode", "-mo"))]
        for n, (what, args) in enumerate(accepted):
            d = stand_in(parent, "none", args, name="good%d" % n)
            run, lines = judge(d, seeds[0])
            expect(run.returncode == 0 and lines[-1] == "ACCEPT PASS",
                   "hand-in rules: run_args.txt with %s accepted" % what)

        d = stand_in(parent, "none", name="real", real=True)
        run, lines = judge(d, seeds[0])
        cases = [l for l in lines if l.startswith("case")]
        clean = all("FAIL: waveform:" in l and "judge:" not in l and "simulator:" not in l
                    for l in cases)
        expect(run.returncode != 0 and cases and clean and not any(l.startswith("RATE") for l in lines),
               "real simulator: an idle program is run (tx, stimulus accepted) and all %d cases "
               "fail cleanly (%s)" % (len(cases), cases[0].split("FAIL: ", 1)[-1][:90] if cases else ""))

    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
