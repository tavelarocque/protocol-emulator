#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: validate.py [seed ...]        (default: seed 1)

1. The interface: accept.tx_words and accept.rx_words on the task sheet's
   example give the words printed in the sheet, and the sheet's CRC
   examples are what accept.py computes.
2. The waveforms: for every entry of ideal.FAULTS it builds a stand-in
   hand-in folder whose `pe_sim` wraps ideal.py (an ideal host as a
   waveform generator, not chip firmware), runs accept.py on it end to end
   exactly as on a real hand-in, and compares the verdict with the one that
   waveform must get.
3. The RATE line, against the stand-in's own output.
4. The hand-in rules: run_args.txt with a flag other than -config and
   -mode, or without P0 push-pull and P1 open-drain, is refused.
5. The real simulator, once, with a one-instruction program that drives no
   pin (not SD firmware): every case must fail cleanly.

Stand-in folders are made in a temporary folder inside this one and
removed afterwards. Exit status 0 only if everything is as expected."""
import os
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import accept  # noqa: E402
import ideal  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "sdcard_sd")
GOOD_ARGS = "-mode 0=pp -mode 1=od\n"


def stand_in(parent, fault, run_args=GOOD_ARGS, name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "sdcard_sd.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
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

    # 1. The interface, against the sheet's text.
    with open(os.path.join(KIT, "TASK.md")) as f:
        sheet = " ".join(f.read().split())
    ex = accept.cases_for(1)[1][1]
    expect([(t.index, t.arg, t.rtype, t.ncr) for t in ex] == [(0, 0, 0, None), (8, 0x1AA, 1, 5)],
           "the fixed case 'the task sheet's example' is the sheet's run")
    tx = ", ".join("0x%04X" % w for w in accept.tx_words(ex))
    rx = ", ".join("0x%04X" % w for w in accept.rx_words(ex))
    expect(tx == "0x0000, 0x0000, 0x0000, 0x0108, 0x0000, 0x01AA" and ("TX words " + tx) in sheet,
           "sheet example TX words: %s" % tx)
    expect(rx == "0x0008, 0x0000, 0x01AA" and ("RX words " + rx) in sheet,
           "sheet example RX words: %s" % rx)
    toks, _ = accept.schedule(ex)
    expect([(s, len(b)) for s, b, _ in toks] == [(80, 48), (136, 48), (188, 48)]
           and "edges 188 to 235" in sheet and accept.rise(80) == 3400,
           "sheet example schedule: edges 80, 136, 188; edge 80 at cycle 3400")
    hexes = lambda bits: " ".join("%02X" % accept.bits_num(bits[i:i + 8]) for i in range(0, 48, 8))
    for tok in (accept.command_token(0, 0), accept.command_token(8, 0x1AA),
                accept.command_token(17, 0), accept.response48(8, 0x1AA)):
        expect(hexes(tok) in sheet, "CRC example in the sheet: %s" % hexes(tok))
    expect(ideal.crc7_poly(accept.command_token(55, 0x1234ABCD)[:40])
           == accept.crc7(accept.command_token(55, 0x1234ABCD)[:40]),
           "the two CRC7 codes (LFSR in accept.py, long division in ideal.py) agree")

    with tempfile.TemporaryDirectory(prefix="validate_", dir=HERE) as parent:
        print()
        print("%-10s %-4s %-8s %-6s %-7s %s" % ("waveform", "seed", "expected", "judge", "failed", "what it is / first objection"))
        for fault, (should_pass, what) in ideal.FAULTS.items():
            d = stand_in(parent, fault)
            for seed in seeds:
                run, lines = judge(d, seed)
                last = lines[-1] if lines else ""
                cases = [l for l in lines if l.startswith("case ")]
                failed = [l for l in cases if ": FAIL" in l]
                rates = [l for l in lines if l.startswith("RATE ")]
                passed = run.returncode == 0
                consistent = (last == ("ACCEPT PASS" if passed else "ACCEPT FAIL")
                              and passed == (not failed) and len(cases) == 14
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not run.stderr.strip())
                ok = consistent and passed == should_pass
                wrong += not ok
                first = failed[0].split(": FAIL: ", 1)[1][:90] if failed else ""
                print("%-10s %-4d %-8s %-6s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail", "%d/%d" % (len(failed), len(cases)),
                         what if should_pass else first, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    # 3. RATE from the stand-in's own output for the last case.
                    txns = accept.cases_for(seed)[-1][1]
                    toks, end = accept.schedule(txns)
                    stim = accept.card_stimulus(toks)
                    tdir = os.path.join(parent, "rate%d" % seed)
                    os.mkdir(tdir)
                    with open(os.path.join(tdir, "tx"), "w") as f:
                        f.write("".join("%d\n" % w for w in accept.tx_words(txns)))
                    with open(os.path.join(tdir, "st"), "w") as f:
                        f.write("\n".join(stim) + "\n")
                    out = subprocess.run([sys.executable, "-B", os.path.join(HERE, "ideal.py"),
                                          "run", "x.s", "-tx", os.path.join(tdir, "tx"),
                                          "-stimulus", os.path.join(tdir, "st"),
                                          "-cycles", str(accept.run_cycles(end))],
                                         capture_output=True, text=True).stdout
                    pins = [int(l.split()[1]) for l in out.splitlines() if l.startswith("pins")]
                    want = "RATE bytes=%d cycles=%d" % (accept.payload_bytes(txns), pins[-1] - pins[1])
                    expect(rates == [want], "seed %d: %s, as the stand-in's own pin changes give"
                           % (seed, rates[0] if rates else "no RATE line"))
        print()
        # 4. run_args.txt rules.
        for n, (text, good) in enumerate([
                (GOOD_ARGS, True),
                ("-mo 1=od -m 0=pp -config clkdiv=2\n", True),
                ("-mode 0=pp -mode 1=od -mode 5=in\n", True),
                ("-mode 0=pp -mode 1=pp\n", False),
                ("-mode 0=pp\n", False),
                ("-mode 0=pp -mode 1=od -mode 2=pp\n", False),
                ("-mode 0=pp -mode 1=od -tx other.txt\n", False),
                ("-mode 0=pp -mode 1=od -stimulus s.txt\n", False),
                ("-mode 0=pp -mode 1=od -s s.txt\n", False),
                ("-mode 0=pp -mode 1=od -cycles 5\n", False),
                ("-mode 0=pp -mode 1=od -inputs ff\n", False),
                ("-mode 0=pp -mode 1=od -c clkdiv=1\n", False),
                ("-mode 0=pp\n-mode 1=od\n", False),
                ("-mode 0=pp -mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0])
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # 5. The real simulator, with a program that is not SD firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write(GOOD_ARGS)
        with open(os.path.join(d, "sdcard_sd.s"), "w") as f:
            f.write("; Not SD firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0])
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 14
               and all("FAIL: clock: CLK stopped after 0 rising edges" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("VALIDATE PASS" if not wrong else "VALIDATE FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
