#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words and accept.frame_bits must turn the task
   sheet's own examples into the words and bits printed in the sheet
   (../../kits/em4305/TASK.md).
2. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into commands by the task sheet's rules,
   in its own code, so a judge that built the words wrongly would fail the
   ideal waveform.
3. The RATE line, against the ideal generator's own layout.
4. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode is refused.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not EM4305 firmware): the command line and the word file must be
   accepted, and every case must fail cleanly.

The stand-in folders are made inside this folder and removed afterwards.
Exit status 0 only if everything is as expected."""
import os
import stat
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import accept  # noqa: E402
import ideal_wave  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "em4305")
LOGIN = ("login", 0, 0x12345678)
WRITE = ("write", 4, 0xDEADBEEF)
SHEET_WORDS = "0x0000, 0x5678, 0x1234, 0x0104, 0xBEEF, 0xDEAD"
SHEET_LOGIN = "0  0011  01111000 0  01010110 0  00110100 1  00010010 0  00001000  0"
SHEET_WRITE = "0  0101  0010 00 1  11101111 1  10111110 0  10101101 1  11011110 0  00100010  0"


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
    with open(os.path.join(d, "em4305.s"), "w") as f:
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
        sheet = f.read()
    flat = " ".join(sheet.split())
    words = ", ".join("0x%04X" % w for w in accept.tx_words([LOGIN, WRITE]))
    expect(words == SHEET_WORDS and SHEET_WORDS in flat,
           "interface: the sheet's example gives the words printed in the sheet (%s)" % words)
    for cmd, text in ((LOGIN, SHEET_LOGIN), (WRITE, SHEET_WRITE)):
        bits = "".join(map(str, accept.frame_bits(cmd)))
        expect(bits == text.replace(" ", "") and text in sheet and len(bits) == (50 if cmd[0] == "login" else 57),
               "interface: %s gives the %d bits printed in the sheet" % (accept.name(cmd), len(bits)))
    expect(ideal_wave.commands_of(accept.tx_words([LOGIN, WRITE])) == [LOGIN, WRITE],
           "interface: the stand-in reads the judge's words back into the same commands")
    expect(all(accept.readable(c) for s in seeds for _, cs in accept.cases_for(s) for c in cs)
           and all(1 <= len(cs) <= accept.MAX_COMMANDS for s in seeds for _, cs in accept.cases_for(s)),
           "cases: no command puts nine 1 bits in a row on the line; 1 to 6 commands a run")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        jobs = []
        for fault in ideal_wave.FAULTS:
            d = stand_in(parent, fault)
            for seed in seeds:
                jobs.append((fault, seed, d))
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(lambda j: judge(j[2], j[1], env), jobs))
        print()
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", ""))
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("", "", "", "", "failed", "check", "check", "what it is"))
        rate_lines = {}
        for (fault, seed, d), (run, lines) in zip(jobs, results):
            should_pass, what = ideal_wave.FAULTS[fault]
            last = lines[-1] if lines else ""
            cases = [l for l in lines if l.startswith("case ")]
            failed = [l for l in cases if ": FAIL" in l]
            rates = [l for l in lines if l.startswith("RATE ")]
            passed = run.returncode == 0
            consistent = (last == ("ACCEPT PASS" if passed else "ACCEPT FAIL")
                          and passed == (not failed) and len(cases) == 15
                          and len(rates) == (1 if len(failed) < len(cases) else 0)
                          and (not rates or lines[-2] == rates[0]) and not run.stderr.strip())
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
                sys.stdout.write(run.stdout[-3000:] + run.stderr[-2000:])
            if fault == "none":
                rate_lines[seed] = rates
        print()
        for seed in seeds:
            # The RATE line, from the generator's layout: first fall at 40, the
            # carrier from 80, then per command 400 + 55 periods and its bits.
            last_case = accept.cases_for(seed)[-1][1]
            periods = sum(400 + 55 + 32 * len(ideal_wave.bits_of(c, "none", False)) for c in last_case)
            want = "RATE bytes=%d cycles=%d" % (4 * len(last_case), 80 + 80 * periods - 40)
            expect(rate_lines[seed] == [want], "seed %d: %s, as the generator's layout gives"
                   % (seed, rate_lines[seed][0] if rate_lines[seed] else "no RATE line"))
        print()
        # run_args.txt: only -config and -mode.
        arg_cases = [("-mode 0=pp -config clkdiv=1\n", True),
                     ("-mo 0=pp\n", True),
                     ("-mode 0=pp -tx other.txt\n", False),
                     ("-mode 0=pp -t other.txt\n", False),
                     ("-mode 0=pp -cycles 5\n", False),
                     ("-mode 0=pp -inputs ff\n", False),
                     ("-mode 0=pp -stimulus s.txt\n", False),
                     ("-mode 0=pp -c clkdiv=1\n", False),
                     ("-mode 0=pp\n-config clkdiv=1\n", False),
                     ("-mode\n", False)]
        dirs = [stand_in(parent, "none", run_args=t, name="args%d" % n) for n, (t, _) in enumerate(arg_cases)]
        with ThreadPoolExecutor(max_workers=8) as pool:
            results = list(pool.map(lambda d: judge(d, seeds[0], env), dirs))
        for (text, good), (run, lines) in zip(arg_cases, results):
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # The real simulator, with a program that is not EM4305 firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write("-mode 0=pp\n")
        with open(os.path.join(d, "em4305.s"), "w") as f:
            f.write("; Not EM4305 firmware: one instruction that loops on itself and drives no pin.\n"
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
