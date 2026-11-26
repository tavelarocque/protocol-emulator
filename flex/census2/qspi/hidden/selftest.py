#!/usr/bin/env python3
"""Checks the judge (accept.py) for the Quad SPI controller. No chip
firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (../../kits/qspi/TASK.md).
2. The example. The bits the judge wants for the sheet's first page must be
   the ones in the sheet's table, and the generator (ideal_wave.py, its own
   code) must want the same bits for random pages.
3. The run length the judge uses must be the sheet's formula.
4. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into pages by the task sheet's rules,
   in its own code, so a judge that built the words wrongly would fail the
   ideal waveform.
5. The RATE line, against the ideal generator's own events.
6. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode, or without P0..P5 push-pull, is refused.
7. The real simulator, with two programs that are not Quad SPI firmware:
   one that never writes a pin (SCK left high from reset), and one that
   drives SCK low and then does nothing. The command line and the word file
   must be accepted, and every case must fail cleanly.

The stand-in folders are made inside this folder and removed afterwards.
Exit status 0 only if everything is as expected."""
import os
import random
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import accept  # noqa: E402
import ideal_wave  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "qspi")
EXAMPLE = [(0x012300, [0xDE, 0xAD, 0xBE, 0xEF]),
           (0xABCD10, [0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])]
EXAMPLE_WORDS = [0x0001, 0x0023, 0x0000, 0x00DE, 0x00AD, 0x00BE, 0x01EF, 0x00AB, 0x00CD,
                 0x0010, 0x0001, 0x0023, 0x0045, 0x0067, 0x0089, 0x00AB, 0x00CD, 0x01EF]
GOOD_ARGS = "-mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp -mode 4=pp -mode 5=pp\n"
N_CASES = 14


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
    with open(os.path.join(d, "qspi.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
    return d


def real_sim_folder(parent, name, program, run_args):
    d = os.path.join(parent, name)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "qspi.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def io0(beats):
    return "".join(str(v & 1) for v, _ in beats)


def main(argv):
    seeds = [int(s) for s in argv] or [1]
    wrong = 0

    def expect(ok, what):
        nonlocal wrong
        wrong += not ok
        print("%-5s %s" % ("ok" if ok else "WRONG", what))

    with open(os.path.join(KIT, "TASK.md")) as f:
        sheet = " ".join(f.read().split())
    text = ", ".join("0x%04X" % w for w in EXAMPLE_WORDS)
    expect(accept.tx_words(EXAMPLE) == EXAMPLE_WORDS and text in sheet and "the 18 words" in sheet,
           "interface: the task sheet's example gives the 18 words printed in the sheet")
    expect(accept.tx_words([(0x000102, [1, 2, 3, 4])]) == [0, 1, 2, 1, 2, 3, 0x104],
           "interface: three address bytes high first, bit 8 only on the last data byte")

    (k1, _, wren), (k2, _, qpp) = accept.frames_for(EXAMPLE[:1])
    nibbles = "".join("%X" % v for v, m in qpp[32:])
    expect(k1 == "WREN" and io0(wren) == "00000110" and "0, 0, 0, 0, 0, 1, 1, 0" in sheet
           and io0(qpp[:8]) == "00110010" and "0, 0, 1, 1, 0, 0, 1, 0" in sheet
           and io0(qpp[8:32]) == "000000010010001100000000"
           and "0000 0001 0010 0011 0000 0000" in sheet
           and nibbles == "DEADBEEF" and "D, E, A, D, B, E, E, F on IO3..IO0" in sheet
           and len(wren) == 8 and len(qpp) == 40
           and "8 rises in the WREN frame and 40 in the QPP frame" in sheet,
           "example: the judge's bits for the sheet's first page are the sheet's table")
    rng = random.Random(99)
    same = True
    for _ in range(50):
        pages = [accept.random_page(rng, 256) for _ in range(rng.randint(1, 6))]
        mine = [(k, b) for k, _, b in accept.frames_for(pages)]
        theirs = [(k.upper(), b) for k, b in ideal_wave.frames(pages, "none")]
        same &= mine == theirs and ideal_wave.pages_of(accept.tx_words(pages)) == \
            [(a, list(d)) for a, d in pages]
    expect(same, "example: the generator wants the judge's bits, and reads the judge's words "
                 "back into the same pages, on 50 random runs")
    expect(all(accept.run_cycles(p) == 10000 + sum(201840 + 40 * len(d) for _, d in p)
               for _, p in accept.cases_for(seeds[0]))
           and "N is 10000 plus, for each page of n data bytes, 201840 + 40n" in sheet,
           "run length: the judge's -cycles is the sheet's formula")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-6s %-6s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "qspi", "smart", ""))
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-6s %-6s %s"
              % ("", "", "", "", "failed", "check", "", "", "what it is"))
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
                              and (not rates or lines[-2] == rates[0])
                              and not run.stderr.strip())
                ok = consistent and passed == should_pass
                wrong += not ok
                seen = lambda tag: "objects" if any(tag in l for l in failed) else "-"
                print("%-11s %-4d %-8s %-6s %-7s %-8s %-6s %-6s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         seen("waveform:"), "obj" if seen("decoder: qspi:") != "-" else "-",
                         "obj" if seen("decoder: smart_qspi:") != "-" else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    pages = accept.cases_for(seed)[-1][1]
                    ev = ideal_wave.build(pages).ev
                    moved = sorted(c for c in ev if c > 0)
                    want = "RATE bytes=%d cycles=%d" % (sum(len(p) for _, p in pages),
                                                        moved[-1] - moved[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's events give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        pp = GOOD_ARGS.strip()
        for n, (text, good) in enumerate([
                (GOOD_ARGS, True),
                ("-config sideset_base=4,sideset_count=1,out_count=4 " + pp + "\n", True),
                ("-mo 0=pp -mo 1=pp -mo 2=pp -mo 3=pp -mo 4=pp -mo 5=pp -mo 6=in\n", True),
                ("-mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp -mode 4=pp\n", False),
                (pp.replace("4=pp", "4=od") + "\n", False),
                (pp + " -tx other.txt\n", False),
                (pp + " -t other.txt\n", False),
                (pp + " -cycles 5\n", False),
                (pp + " -inputs 0xff\n", False),
                (pp + " -stimulus s.txt\n", False),
                (pp + " -c clkdiv=1\n", False),
                (pp + "\n-config clkdiv=1\n", False),
                (pp + " -mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:100]))
        for name, program, args, said in [
                ("real_idle",
                 "; Not Quad SPI firmware: one instruction that loops on itself and drives no pin.\n"
                 "idle:   jmp idle\n",
                 GOOD_ARGS,
                 "FAIL: waveform: SCK is not driven low by cycle 100"),
                ("real_sck_low_only",
                 "; Not Quad SPI firmware: drives SCK (P4) low once, then loops on itself.\n"
                 "        set pins, 0\n"
                 "idle:   jmp idle\n",
                 "-config set_base=4 " + GOOD_ARGS,
                 "FAIL: waveform: 0 CS# frames")]:
            d = real_sim_folder(parent, name, program, args)
            run, lines = judge(d, seeds[0], env)
            cases = [l for l in lines if l.startswith("case ")]
            expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == N_CASES
                   and all(said in l for l in cases)
                   and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
                   "real pe_sim, %s: every case fails cleanly, no RATE line (%s)"
                   % (name, cases[0][:120] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
