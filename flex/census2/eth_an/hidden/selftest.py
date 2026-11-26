#!/usr/bin/env python3
"""Checks the judge (accept.py) for the Ethernet auto-negotiation (fast link
pulse) transmitter. No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's example into
   the words printed in the sheet (../../kits/eth_an/TASK.md).
2. The example. accept.ideal_offsets(0x01E1) must be the 22 rises the
   sheet lists, and the generator's own rises for that word too.
3. The decoder on its own: sigrok's decoder, on the judge's 1 MHz capture
   of the ideal waveform, reads every word of every case on every seed.
4. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX file in its own code.
5. The RATE line, against the ideal generator's own pin changes.
6. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode, or with the wrong pin modes, is refused.
7. The real simulator, with a program that is not auto-negotiation
   firmware (`idle: jmp idle`, which never writes a pin). The command line
   and the word file must be accepted, and every case must fail cleanly.

The stand-in folders are made inside this folder and removed afterwards.
Exit status 0 only if everything is as expected."""
import concurrent.futures
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

KIT = os.path.join(HERE, "..", "..", "kits", "eth_an")
SHEET_WORDS = ([0x01E1, 0x01E1, 0x41E1], "0x01E1, 0x01E1, 0x41E1")
N_CASES = 15
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
    with open(os.path.join(d, "eth_an.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
    return d


def real_sim_folder(parent, name, program, run_args=GOOD_ARGS):
    d = os.path.join(parent, name)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "eth_an.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def sheet_rises(sheet):
    """The rises the sheet lists for 0x01E1, after "rise at these cycles"."""
    m = re.search(r"rise at these cycles after the first:\s*([\d,\s]+)\.", sheet)
    return [int(n) for n in re.findall(r"\d+", m.group(1))] if m else []


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
    words, text = SHEET_WORDS
    expect(accept.tx_words(words) == words and text in sheet
           and "The host sends only the words defined above. All line coding, framing and "
               "timing must be done by the firmware." in sheet,
           "interface: the sheet's example is the words printed in it (%s), and the sheet "
           "says the host sends only them" % text)
    expect(accept.tx_words([0x1234]) == [0x1234] and accept.run_cycles([1, 2, 3]) == 3_840_000
           and "N is 960,000 times one more than the number of words" in sheet,
           "interface: one word per burst, the word itself; N as the sheet states")
    listed = sheet_rises(sheet)
    ideal = accept.ideal_offsets(0x01E1)
    gen = ideal_wave.burst_rises(0x01E1)
    expect(listed == ideal and len(ideal) == 22 and "22 in all" in sheet,
           "example: the sheet's 22 rises for 0x01E1 are the judge's ideal")
    expect(gen == ideal, "example: the generator's rises for 0x01E1 are the judge's ideal")
    expect(all(ideal_wave.burst_rises(w) == accept.ideal_offsets(w)
               for w in (0, 0xFFFF, 0x5555, 0xAAAA, 0x8000, 0x0001, 0x1234, 0xBEEF)),
           "example: generator and judge agree on eight more words")

    # The decoder on its own, on the judge's capture of the ideal waveform.
    for seed in seeds:
        bad = []
        for name, ws in accept.cases_for(seed):
            cyc = accept.run_cycles(ws)
            changes = accept.pin_changes(ideal_wave.pins_text(ws, cyc), accept.TD_PLUS)
            anns = accept.sigrok_annotations(changes, cyc)
            pages = [int(t.split(":0x")[1], 16) for c, t in anns if c == "data"]
            if pages != ws:
                bad.append(name)
        expect(not bad, "decoder: sigrok reads every word of the ideal waveform, all %d cases, "
               "seed %d%s" % (N_CASES, seed, (" (not: %s)" % ", ".join(bad)) if bad else ""))

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-12s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", ""))
        print("%-12s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("", "", "", "", "failed", "check", "check", "what it is"))
        jobs = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
            for fault in ideal_wave.FAULTS:
                d = stand_in(parent, fault)
                for seed in seeds:
                    jobs.append((fault, seed, pool.submit(judge, d, seed, env)))
            for fault, seed, fut in jobs:
                should_pass, what = ideal_wave.FAULTS[fault]
                run, lines = fut.result()
                last = lines[-1] if lines else ""
                cases = [l for l in lines if l.startswith("case ")]
                failed = [l for l in cases if ": FAIL" in l]
                rates = [l for l in lines if l.startswith("RATE ")]
                passed = run.returncode == 0
                consistent = (last == ("ACCEPT PASS" if passed else "ACCEPT FAIL")
                              and passed == (not failed) and len(cases) == N_CASES
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l or "simulator:" in l for l in cases))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-12s %-4d %-8s %-6s %-7s %-8s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG"))
                if not ok:
                    for l in lines[-6:]:
                        print("      | " + l)
                if fault == "none":
                    name, ws = accept.cases_for(seed)[-1]
                    cyc = accept.run_cycles(ws)
                    moved = sorted(c for c, _, _ in ideal_wave.events(ws) if c < cyc)
                    want = "RATE bytes=%d cycles=%d" % (2 * len(ws), moved[-1] - moved[0])
                    expect(rates == [want], "seed %d: %s, as the generator's pin changes give"
                           % (seed, want))

        print()
        bad_args = [
            ("-tx x.txt -mode 0=pp -mode 1=pp", "-tx"),
            ("-mode 0=pp -mode 1=pp -cycles 5", "-cycles"),
            ("-mode 0=pp -mode 1=pp -stimulus s.txt", "-stimulus"),
            ("-mode 0=pp -mode 1=pp -inputs 0xff", "-inputs"),
            ("-c clkdiv=4 -mode 0=pp -mode 1=pp", "ambiguous -c"),
            ("-mode 0=pp\n-mode 1=pp", "two lines"),
            ("-mode 0=pp -mode 1=pp -config", "a flag with no value"),
            ("-mode 0=pp", "P1 not push-pull"),
            ("-mode 0=od -mode 1=pp", "P0 open-drain"),
            ("-mode 0=pp -mode 1=pp -mode 2=pp", "P2 an output"),
            ("-mode 0=pp -mode 1=pp -mode 9=in", "pin 9"),
        ]
        for args, what in bad_args:
            d = stand_in(parent, "none", run_args=args + "\n", name="args_%d" % bad_args.index((args, what)))
            run, lines = judge(d, 1, env)
            expect(run.returncode != 0 and lines and lines[0].startswith("setup: FAIL")
                   and lines[-1] == "ACCEPT FAIL",
                   "hand-in rules: run_args.txt with %s is refused" % what)
        for n, args in enumerate(["-mode 0=pp -mode 1=pp",
                                  "-config clkdiv=4,set_base=0,set_count=2 -mode 1=pp -mode 0=pp -mode 2=in"]):
            d = stand_in(parent, "none", run_args=args + "\n", name="good_%d" % n)
            run, lines = judge(d, 1, env)
            expect(run.returncode == 0 and lines[-1] == "ACCEPT PASS",
                   "hand-in rules: run_args.txt %r is accepted" % args)

        print()
        d = real_sim_folder(parent, "real_idle", "idle:   jmp idle\n")
        run, lines = judge(d, 1, env)
        cases = [l for l in lines if l.startswith("case ")]
        clean = (len(cases) == N_CASES and all(": FAIL: waveform:" in l for l in cases)
                 and not any("simulator:" in l or "judge:" in l for l in cases)
                 and not any(l.startswith("RATE") for l in lines) and lines[-1] == "ACCEPT FAIL")
        expect(clean, "real simulator: a program that drives no pin fails every case cleanly")
        if cases:
            print("      | " + cases[0])

    print()
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
