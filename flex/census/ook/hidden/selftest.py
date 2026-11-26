#!/usr/bin/env python3
"""Checks the judge (accept.py) for the OOK transmitter. No chip firmware is
involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (../../kits/ook/TASK.md).
2. The example. accept.ideal_offsets for the frame 0xA5 must be the
   transitions the sheet's table lists, 46 of them.
3. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into frames by the task sheet's rules,
   in its own code, so a judge that built the words wrongly would fail the
   ideal waveform.
4. The RATE line, against the ideal generator's own transition list.
5. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode is refused.
6. The real simulator, with two programs that are not OOK firmware: one
   that never writes P0 (left high from reset), and one that drives P0 low
   and then does nothing. The command line and the word file must be
   accepted, and every case must fail cleanly.

The stand-in folders are made inside this folder and removed afterwards.
Exit status 0 only if everything is as expected."""
import os
import re
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import accept  # noqa: E402
import ideal_wave  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "ook")
SHEET_EXAMPLE = ([[0xA5], [0x12, 0x34, 0xFF]], [0x01A5, 0x0012, 0x0034, 0x01FF],
                 "0x01A5, 0x0012, 0x0034, 0x01FF")
N_CASES = 15


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
    with open(os.path.join(d, "ook.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
    return d


def real_sim_folder(parent, name, program, run_args="-mode 0=pp\n"):
    d = os.path.join(parent, name)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "ook.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def sheet_table_offsets(sheet):
    """The transitions the sheet's example table lists, in order."""
    out = []
    for line in sheet.splitlines():
        if not line.startswith("| ") or "Transitions" in line or "---" in line:
            continue
        cell = line.split("|")[3]
        if "500k" in cell:
            out += [o for k in range(16) for o in (500 * k, 500 * k + 250)]
        else:
            out += [int(n) for n in re.findall(r"\b(\d+) \(", cell)]
    return out


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
    frames, words, text = SHEET_EXAMPLE
    expect(accept.tx_words(frames) == words and text in sheet,
           "interface: the task sheet's example gives the words printed in the sheet (%s)" % text)
    expect(accept.tx_words([[7]]) == [0x107] and accept.tx_words([[1, 2], [3]]) == [1, 0x102, 0x103],
           "interface: a one-byte frame is one word with bit 8 set; bit 8 only on last bytes")
    table = sheet_table_offsets(raw)
    ideal = accept.ideal_offsets(accept.frame_bits([0xA5]))
    expect(table == ideal and len(ideal) == 46 and "That is 46 transitions" in sheet
           and "".join(map(str, accept.frame_bits([0xA5]))) == "1" * 16 + "0101" + "10100101",
           "example: the sheet's table for 0xA5 is the judge's ideal (%d transitions)" % len(ideal))
    gen = ideal_wave.toggles([[0xA5]])[1:]
    expect([c - gen[0] for c in gen] == ideal,
           "example: the generator's transitions for 0xA5 are the judge's ideal")

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
                              and passed == (not failed) and len(cases) == N_CASES
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
                    last_case = accept.cases_for(seed)[-1][1]
                    t = ideal_wave.toggles(last_case)
                    want = "RATE bytes=%d cycles=%d" % (sum(len(f) for f in last_case), t[-1] - t[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's transitions give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([("-mode 0=pp -config clkdiv=50\n", True),
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
        # The real simulator, with programs that are not OOK firmware.
        for name, program, said in [
                ("real_idle_high",
                 "; Not OOK firmware: one instruction that loops on itself and drives no pin.\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: P0 is not driven low by cycle 100"),
                ("real_low_only",
                 "; Not OOK firmware: drives P0 low once, then loops on itself.\n"
                 "        set pins, 0\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: 0 separate bursts")]:
            d = real_sim_folder(parent, name, program)
            run, lines = judge(d, seeds[0], env)
            cases = [l for l in lines if l.startswith("case ")]
            expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == N_CASES
                   and all(said in l for l in cases)
                   and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
                   "real pe_sim, %s: every case fails cleanly, no RATE line (%s)"
                   % (name, cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
