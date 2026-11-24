#!/usr/bin/env python3
"""Checks the round-two judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (../../kits2/miller/TASK.md).
2. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into messages by the task sheet's rules,
   in its own code, so a judge that built the words wrongly would fail the
   ideal waveform. There is no host.py anywhere.
3. The RATE line, against the ideal generator's own transition list.
4. The hand-in rules: a host.py left in the folder is never loaded, and a
   run_args.txt with a flag other than -config and -mode is refused.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not Miller firmware): the command line and the word file must be
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

KIT = os.path.join(HERE, "..", "..", "kits2", "miller")
SHEET_EXAMPLE = ([[0x16], [0xDE, 0xAD, 0xBE]], [0x0116, 0x00DE, 0x00AD, 0x01BE],
                 "0x0116, 0x00DE, 0x00AD, 0x01BE")


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
    with open(os.path.join(d, "miller.s"), "w") as f:
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

    messages, words, text = SHEET_EXAMPLE
    with open(os.path.join(KIT, "TASK.md")) as f:
        sheet = " ".join(f.read().split())
    expect(accept.tx_words(messages) == words and text in sheet,
           "interface: the task sheet's example gives the words printed in the sheet (%s)" % text)
    expect(accept.tx_words([[7]]) == [0x107] and accept.tx_words([[1, 2], [3]]) == [1, 0x102, 0x103],
           "interface: a one-byte message is one word with bit 8 set; bit 8 only on last bytes")

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
                ok = consistent and passed == should_pass
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
                    # The RATE line, worked out from the generator's own list.
                    last_case = accept.cases_for(seed)[-1][1]
                    t = ideal_wave.toggles(last_case)
                    want = "RATE bytes=%d cycles=%d" % (sum(len(m) for m in last_case), t[-1] - t[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's transitions give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        # A host.py in the folder must never be loaded.
        d = stand_in(parent, "none", name="with_host_py")
        marker = os.path.join(parent, "host_was_loaded")
        with open(os.path.join(d, "host.py"), "w") as f:
            f.write("open(%r, 'w').close()\nraise SystemExit('host.py was loaded')\n" % marker)
        run, lines = judge(d, seeds[0], env)
        expect(run.returncode == 0 and lines[-1] == "ACCEPT PASS" and not os.path.exists(marker),
               "a host.py left in the folder is not loaded, and changes nothing")
        # run_args.txt: only -config and -mode.
        for n, (text, good) in enumerate([("-mode 0=pp -config clkdiv=1\n", True),
                                          ("-mo 0=pp\n", True),
                                          ("-mode 0=pp -tx other.txt\n", False),
                                          ("-mode 0=pp -t other.txt\n", False),
                                          ("-mode 0=pp -cycles 5\n", False),
                                          ("-mode 0=pp -inputs ff\n", False),
                                          ("-mode 0=pp -c clkdiv=1\n", False),
                                          ("-mode 0=pp\n-config clkdiv=1\n", False),
                                          ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # The real simulator, with a program that is not Miller firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write("-mode 0=pp\n")
        with open(os.path.join(d, "miller.s"), "w") as f:
            f.write("; Not Miller firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 15
               and all("FAIL: waveform: 0 separate bursts" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:100] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
