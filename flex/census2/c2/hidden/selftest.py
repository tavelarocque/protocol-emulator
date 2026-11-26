#!/usr/bin/env python3
"""Checks the judge (accept.py) for the C2 master. No chip firmware is
involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words and accept.rx_words must turn the task
   sheet's own examples into the words printed in the sheet
   (../../kits/c2/TASK.md).
2. The example. The sheet's table (rising edges, bits, who drives), its
   stimulus file and its N must be what accept.py's schedule and stimulus
   give. The ideal bus must decode as the example's frames with the
   judge's adjustment for the device's bits (README.md), and must not
   without it, which is the decoder behaviour the adjustment is for.
3. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal C2 master as a waveform generator, not chip
   firmware), runs accept.py on it from end to end exactly as on a real
   hand-in, and compares the verdict with the one that waveform must get.
   The stand-in reads the judge's TX words back into frames by the task
   sheet's rules, in its own code, and reads the device's bytes from the
   judge's stimulus file, so a judge that built either wrongly would fail
   the ideal waveform.
4. The RATE line, against the ideal generator's own output.
5. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode, or without the required pin modes, is refused.
6. The real simulator, with two programs that are not C2 firmware: one that
   never writes a pin, and one that drives C2CK low and then does nothing.
   The command line, the word file and the stimulus file must be accepted,
   and every case must fail cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "c2")
EXAMPLE = [(accept.AW, 0x00), (accept.DR, [0x30])]
N_CASES = 14
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
    with open(os.path.join(d, "c2.s"), "w") as f:
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
    with open(os.path.join(d, "c2.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def sheet_table(raw):
    """[(rising edge cycle or None, C2D bit, driven by)] for every slot in
    the sheet's example table, in order."""
    rows = []
    for line in raw.splitlines():
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if len(cells) != 5 or not re.match(r"^\d", cells[0]):
            continue
        slot, edge, _, bits, who = cells
        m = re.match(r"(\d+) to (\d+)", slot)
        slots = list(range(int(m.group(1)), int(m.group(2)) + 1)) if m else \
            [int(x) for x in slot.split(",")]
        if edge == "none":
            edges = [None] * len(slots)
        else:
            m = re.match(r"(\d+) to (\d+)", edge)
            edges = (list(range(int(m.group(1)), int(m.group(2)) + 1, 50)) if m else
                     [int(x) for x in edge.split(",")])
        if bits.endswith("each"):
            bl = [int(bits.split()[0])] * len(slots)
        else:
            bl = [int(x) for x in bits.split(",")]
        who = who.split()[0]
        for s, e, b in zip(slots, edges, bl):
            rows.append((s, e, b, who))
    return rows


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

    # 1. The interface.
    expect(accept.tx_words(EXAMPLE) == [0x1000, 0x4001] and "0x1000, 0x4001" in sheet
           and accept.rx_words([(accept.AW, 0), (accept.DR, [0x30])]) == [0x0030]
           and "the firmware pushes 0x0030" in sheet,
           "interface: the example is the words 0x1000, 0x4001, and the firmware pushes 0x0030")
    expect(accept.tx_words([(accept.DW, [0x12, 0x34])]) == [0x3002, 0x0012, 0x0034]
           and "0x3002, 0x0012, 0x0034" in sheet,
           "interface: a Data Write of 0x12, 0x34 is 0x3002, 0x0012, 0x0034")
    expect(accept.tx_words([(accept.AR, 0x55)]) == [0x2000]
           and accept.rx_words([(accept.AR, 0x55), (accept.DR, [1, 2, 3, 4])]) == [0x55, 1, 2, 3, 4],
           "interface: an Address Read is 0x2000; one rx word per byte the device sends")
    expect(ideal_wave.frames_of(accept.tx_words([(accept.AW, 7), (accept.DW, [1, 2]), (accept.AR, 9),
                                                 (accept.DR, [5, 6, 7])]))
           == [("AW", 7), ("DW", [1, 2]), ("AR", None), ("DR", 3)],
           "interface: the stand-in reads the judge's words back into the same frames")

    # 2. The example.
    sched, S = accept.schedule(EXAMPLE)
    table = sheet_table(raw)
    want = []
    by_slot = {slot: (who, b) for slot, _, _, who, b in sched}
    for s in range(S):
        if s in by_slot:
            who, b = by_slot[s]
            want.append((s, accept.R(s), b, {"none": "nobody", "chip": "chip", "dev": "device"}[who]))
        else:
            want.append((s, None, 1, "nobody"))
    expect(table == want and len(table) == 29,
           "example: the sheet's table is the judge's schedule, slot by slot (%d slots)" % len(table))
    stim_lines = re.findall(r"^    (\d+ [0-9a-f]{2})$", raw, re.M)
    expect(stim_lines == ["%d %02x" % (c, v) for c, v in accept.stimulus(EXAMPLE)],
           "example: the sheet's stimulus file is the judge's (%s)" % "; ".join(stim_lines))
    expect(accept.run_cycles(EXAMPLE) == 3550 and "S is 29 and N is 3550" in sheet,
           "example: N = 3550, S = 29")
    expect(accept.payload_bytes(EXAMPLE) == 2 and accept.check_stimulus(EXAMPLE) == [],
           "example: the ideal bus with the sheet's stimulus decodes as the sheet's frames")
    cyc = accept.run_cycles(EXAMPLE)
    out = accept.ideal_outputs(EXAMPLE, cyc)
    clk, dat = accept.lines_of(out, accept.per_cycle(accept.stimulus(EXAMPLE), cyc, 0xFF))
    raw_frames = accept.sigrok_annotations(clk, dat)[1]
    expect(raw_frames != accept.want_annotations(EXAMPLE)[1],
           "example: without the adjustment the decoder misreads the device's bits (%s)"
           % ", ".join(raw_frames))

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-13s %-4s %-8s %-6s %-7s %-8s %-7s %-6s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", "rx", ""))
        print("%-13s %-4s %-8s %-6s %-7s %-8s %-7s %-6s %s"
              % ("", "", "", "", "failed", "check", "check", "check", "what it is"))
        for fault, (should_pass, what) in ideal_wave.FAULTS.items():
            d = stand_in(parent, fault)
            for seed in seeds:
                run, lines = judge(d, seed, env)
                last_line = lines[-1] if lines else ""
                cases = [l for l in lines if l.startswith("case ")]
                failed = [l for l in cases if ": FAIL" in l]
                rates = [l for l in lines if l.startswith("RATE ")]
                passed = run.returncode == 0
                consistent = (last_line == ("ACCEPT PASS" if passed else "ACCEPT FAIL")
                              and passed == (not failed) and len(cases) == N_CASES
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l for l in cases))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-13s %-4d %-8s %-6s %-7s %-8s %-7s %-6s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         "objects" if any("rx:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    # 4. RATE, from the generator's own output on the last case.
                    frames = accept.cases_for(seed)[-1][1]
                    cyc = accept.run_cycles(frames)
                    with tempfile.TemporaryDirectory(dir=parent) as t:
                        st = os.path.join(t, "st.txt")
                        with open(st, "w") as f:
                            f.write("".join("%d %02x\n" % cv for cv in accept.stimulus(frames)))
                        stim = ideal_wave.read_stimulus(st, cyc)
                    clk, dat, _ = ideal_wave.waveform(ideal_wave.frames_of(accept.tx_words(frames)),
                                                      stim, cyc, "none")
                    moved = [c for c in range(1, cyc) if (clk[c], dat[c]) != (clk[c - 1], dat[c - 1])]
                    want_rate = "RATE bytes=%d cycles=%d" % (accept.payload_bytes(frames),
                                                            moved[-1] - moved[0])
                    print()
                    expect(rates == [want_rate], "seed %d: %s, as the generator's output gives"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()

        # 5. The hand-in rules.
        for n, (text, good) in enumerate([
                (GOOD_ARGS, True),
                ("-mode 1=od -mode 0=pp -config clkdiv=5,set_base=0\n", True),
                ("-mo 0=pp -mo 1=od\n", True),
                ("-mode 0=pp -mode 1=od -mode 2=in\n", True),
                ("-mode 0=pp -mode 1=pp\n", False),
                ("-mode 0=od -mode 1=od\n", False),
                ("-mode 0=pp\n", False),
                ("-mode 0=pp -mode 1=od -tx other.txt\n", False),
                ("-mode 0=pp -mode 1=od -stimulus s.txt\n", False),
                ("-mode 0=pp -mode 1=od -cycles 5\n", False),
                ("-mode 0=pp -mode 1=od -inputs 0xff\n", False),
                ("-mode 0=pp -mode 1=od -c clkdiv=1\n", False),
                ("-mode 0=pp\n-mode 1=od\n", False),
                ("-mode 0=pp -mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:100]))

        # 6. The real simulator, with programs that are not C2 firmware.
        for name, program, said in [
                ("real_idle",
                 "; Not C2 firmware: one instruction that loops on itself and drives no pin.\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: C2CK does not fall for the device reset by cycle 300"),
                ("real_clk_low",
                 "; Not C2 firmware: drives P0 low once, then loops on itself.\n"
                 "        set pins, 0\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: C2CK does not rise at the end of the device reset by cycle 1800")]:
            d = real_sim_folder(parent, name, program)
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
