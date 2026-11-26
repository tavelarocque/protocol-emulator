#!/usr/bin/env python3
"""Checks the judge (accept.py). No chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's example into
   the words printed in the sheet (../../kits/sda2506/TASK.md), and the RX
   word the sheet gives must be what the judge expects.
2. The scripted EEPROM. On every case of every seed, sigrok decodes the
   ideal host plus the stimulus to exactly the operations and read bytes
   (the judge does this before each run too). And the check has teeth: an
   EEPROM that puts its bits out 3 us after CLK falls, later than the
   2.5 us the data sheet allows and later than the decoder looks, is
   refused.
3. The waveforms. For every result in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper around ideal_wave.py
   (an ideal host as a waveform and RX words, not chip firmware), runs
   accept.py on it exactly as on a real hand-in, and compares the verdict
   with the one that result must get. The stand-in reads the judge's TX
   words back into operations in its own code, and reads the bytes it
   returns from the judge's stimulus file, so a judge whose words, stimulus
   or memory model were wrong would fail the ideal result.
4. The RATE line, against the generator's own pin changes.
5. The hand-in rules: run_args.txt with a flag other than -config and
   -mode, or the wrong pin modes, is refused.
6. The real simulator, once, with a one-instruction program that drives no
   pin (not SDA 2506 firmware): the command line, the word file and the
   stimulus file must be accepted, and every case must fail cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "sda2506")
GOOD_ARGS = "-mode 0=pp -mode 1=od -mode 2=pp\n"


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
    with open(os.path.join(d, "sda2506.s"), "w") as f:
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

    # 1. the interface
    with open(os.path.join(KIT, "TASK.md")) as f:
        sheet = " ".join(f.read().split())
    ex = [(accept.ERASE, 0x12, 0), (accept.WRITE, 0x12, 0x3C), (accept.READ, 0x12, 0)]
    expect(accept.tx_words(ex) == [0x1201, 0x923C, 0x1200]
           and "0x1201, 0x923C, 0x1200" in sheet and "0x003C" in sheet
           and accept.run_memory(ex, {0x12: 0x81}) == [0x3C],
           "interface: the sheet's example gives 0x1201, 0x923C, 0x1200 and RX 0x003C")
    clk, ce, _, _, _ = accept.schedule([(accept.WRITE, 0x12, 0x3C)])
    expect(clk[0] == (2050, 1) and clk[31] == (5150, 0) and clk[32:] == [(5450, 1), (5550, 0)]
           and ce == [(5250, 0), (205600, 1)],
           "schedule: the sheet's worked write (CLK 2050..5150, CE fall 5250, start 5450/5550, CE rise 205600)")

    # 2. the scripted EEPROM
    bad = 0
    total = 0
    for seed in seeds:
        for name, ops, memory in accept.cases_for(seed):
            total += 1
            bad += bool(accept.check_stimulus(ops, memory, accept.run_cycles(ops)))
    expect(bad == 0, "stimulus: sigrok decodes the ideal host and the scripted EEPROM to the payload, %d cases" % total)
    saved = accept.DEV_DELAY
    accept.DEV_DELAY = 30
    try:
        name, ops, memory = accept.cases_for(seeds[0])[0]
        late = accept.check_stimulus(ops, memory, accept.run_cycles(ops))
    finally:
        accept.DEV_DELAY = saved
    expect(bool(late), "stimulus: an EEPROM 3 us late is refused (%s)" % (late[0][:70] if late else "accepted"))

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-12s %-4s %-8s %-6s %-6s %-8s %-7s %-3s %s"
              % ("result", "seed", "expected", "judge", "failed", "waveform", "decoder", "rx", "what it is"))
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
                              and not any("judge:" in l for l in failed))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-12s %-4d %-8s %-6s %-6s %-8s %-7s %-3s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail", "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         "obj" if any("rx:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    _, last_ops, _ = accept.cases_for(seed)[-1]
                    words = accept.tx_words(last_ops)
                    ev, _ = ideal_wave.run(ideal_wave.operations(words), [], "none")
                    cyc = sorted(c for c, _, _ in ev)
                    want = "RATE bytes=%d cycles=%d" % (
                        sum(1 for k, _, _ in last_ops if k != accept.ERASE), cyc[-1] - cyc[0])
                    expect(rates == [want], "seed %d: %s, as the generator's pin changes give"
                           % (seed, rates[0] if rates else "no RATE line"))
        print()
        for n, (text, good) in enumerate([
                (GOOD_ARGS, True),
                ("-mo 0=pp -mo 1=od -mo 2=pp -config clkdiv=1\n", True),
                ("-mode 0=pp -mode 1=pp -mode 2=pp\n", False),
                ("-mode 0=pp -mode 1=od\n", False),
                (GOOD_ARGS.strip() + " -tx other.txt\n", False),
                (GOOD_ARGS.strip() + " -stimulus other.txt\n", False),
                (GOOD_ARGS.strip() + " -s other.txt\n", False),
                (GOOD_ARGS.strip() + " -cycles 5\n", False),
                (GOOD_ARGS.strip() + " -inputs ff\n", False),
                (GOOD_ARGS.strip() + " -c clkdiv=1\n", False),
                ("-mode 0=pp -mode 1=od\n-mode 2=pp\n", False),
                (GOOD_ARGS.strip() + " -config\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # The real simulator, with a program that is not SDA 2506 firmware.
        d = os.path.join(parent, "real_pe_sim_idle")
        os.mkdir(d)
        sim = os.path.join(d, "pe_sim")
        with open(sim, "w") as f:
            f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
        os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
        with open(os.path.join(d, "run_args.txt"), "w") as f:
            f.write(GOOD_ARGS)
        with open(os.path.join(d, "sda2506.s"), "w") as f:
            f.write("; Not SDA 2506 firmware: one instruction that loops on itself and drives no pin.\n"
                    "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 15
               and all("FAIL: waveform: CLK is not low" in l for l in cases)
               and not any("simulator:" in l or "judge:" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
