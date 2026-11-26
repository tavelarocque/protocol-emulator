#!/usr/bin/env python3
"""Checks the judge (accept.py) for the MIPI RFFE master. No chip firmware
is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words, rx_wanted and stimulus_text must turn the
   task sheet's own example into the words, the RX word and the stimulus
   file printed in the sheet (../../kits/mipi_rffe/TASK.md), and the
   schedule must give the sheet's cycles (S(1) = 1020, N = 1760).
2. The example. The bits in the sheet's two tables, row by row, must be the
   judge's bits for those sequences, and each row's first rising edge the
   judge's place for it.
3. The scripted slave. On every case of every seed, sigrok's decoder must
   read the ideal bus (accept's own ideal master with the stimulus) as
   exactly the wanted annotations, the decoder's parity-warning quirk
   included, and the bus must pass the judge's own wire checks.
4. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into sequences by the task sheet's rules,
   in its own code, and reads the read bytes off the judge's stimulus file,
   so a judge that built either wrongly would fail the ideal waveform.
5. The RATE line, against the stand-in's own pin changes.
6. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode, or other pin modes than P0 push-pull and P1 open-drain, is refused.
7. The real simulator, with two programs that are not RFFE firmware: one
   that never writes a pin (both left high from reset), and one that drives
   P0 and P1 low and then does nothing. The command line, the word file and
   the stimulus file must be accepted, and every case must fail cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "mipi_rffe")
EXAMPLE = [accept.seq(accept.RW, 5, 0x13, [0xA7]), accept.seq(accept.RR, 7, 0x1F, [0x3C])]
EXAMPLE_WORDS = "0x0115, 0x0013, 0x00A7, 0x0127, 0x001F"
GOOD_ARGS = "-mode 0=pp -mode 1=od\n"


def n_cases(seed):
    return len(accept.cases_for(seed))


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
    with open(os.path.join(d, "mipi_rffe.s"), "w") as f:
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
    with open(os.path.join(d, "mipi_rffe.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def sheet_tables(raw):
    """[(first rising edge, bits)] per row of the sheet's two example
    tables, split into the two tables."""
    tables, cur = [], None
    for line in raw.splitlines():
        if line.startswith("| Clocks | Rising edges at"):
            cur = []
            tables.append(cur)
            continue
        if cur is None or not line.startswith("| ") or "---" in line:
            if cur is not None and not line.startswith("|"):
                cur = None
            continue
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if cells[0] == "SSC":
            continue
        cur.append((int(cells[1].split()[0]), cells[3]))
    return tables


def stand_in_span(seqs, fault="none"):
    """First to last change of P0 or P1 in the stand-in's own output."""
    words = accept.tx_words(seqs)
    _, n = accept.schedule(seqs)
    text = ideal_wave.run(words, accept.stimulus_text(seqs).splitlines(), n, fault)
    moved, last = [], None
    for line in text.splitlines():
        p = line.split()
        if p[0] == "pins":
            v = int(p[2], 16) & 3
            if last is not None and v != last:
                moved.append(int(p[1]))
            last = v
    return moved[-1] - moved[0]


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
    words = ", ".join("0x%04X" % w for w in accept.tx_words(EXAMPLE))
    expect(words == EXAMPLE_WORDS and EXAMPLE_WORDS in sheet,
           "interface: the sheet's example gives the words printed in the sheet (%s)" % words)
    expect(accept.rx_wanted(EXAMPLE) == [0x3C] and "pushes 0x003C" in sheet and "rx CYCLE 60" in sheet,
           "interface: the example's RX word is 0x003C, printed as 60")
    expect(accept.tx_words([accept.seq(accept.R0W, 0, 0, [0x7F])]) == [0x0100, 0x7F]
           and accept.tx_words([accept.seq(accept.ERRL, 3, 0xABCD, [1] * 8)]) == [0x0863, 0xABCD]
           and accept.tx_words([accept.seq(accept.ERW, 15, 0x80, [9] * 16)]) == [0x103F, 0x80] + [9] * 16,
           "interface: kind 0 has no address word, reads no data words, n in bits 12..8")
    stim = accept.stimulus_text(EXAMPLE)
    block = "\n".join(l.strip() for l in raw.split("for the example above it is")[1].split("and N is")[0].strip().splitlines())
    expect(stim.strip() == block, "interface: the example's stimulus is the file printed in the sheet")
    plan, n = accept.schedule(EXAMPLE)
    expect([p[0] for p in plan] == [400, 1020] and n == 1760 and "N is 1760" in sheet
           and "start at 1020 + 20 x (24 + 8) = 1660" in sheet,
           "interface: S(0) = 400, S(1) = 1020, N = 1760, as in the sheet")

    # 2. The example's tables.
    tables = sheet_tables(raw)
    ok = len(tables) == 2
    for t, (start, bits, turn) in zip(tables, plan):
        got = "".join(b for _, b in t)
        ok &= got == "".join(str(b) for b, _ in bits)
        j = 0
        for first, b in t:
            ok &= first == accept.rise_at(start, j)
            j += len(b)
    expect(ok and plan[1][2] == 13 and len(plan[1][1]) == 24 and len(plan[0][1]) == 23,
           "example: the sheet's two tables are the judge's bits and rising edges (23 and 24 clocks)")
    lens = {accept.R0W: (14, 0), accept.RW: (23, 0), accept.RR: (24, 0), accept.ERW: (23, 9),
            accept.ERR: (24, 9), accept.ERWL: (32, 9), accept.ERRL: (33, 9)}
    ok = True
    for kind, (base, per) in lens.items():
        for nb in range(1, accept.MAX_N[kind] + 1):
            ok &= len(accept.clocks(accept.seq(kind, 1, 0, [0] * nb))[0]) == base + per * nb
    turns = [accept.clocks(accept.seq(k, 1, 0, [0]))[1] for k in (accept.RR, accept.ERR, accept.ERRL)]
    expect(ok and turns == [13, 22, 31], "example: the clock counts L and turnaround clocks b of the sheet's table")

    # 3. The scripted slave is an RFFE slave, by the decoder.
    bad, count, warned = 0, 0, 0
    for seed in seeds:
        for name, seqs in accept.cases_for(seed):
            count += 1
            errs = accept.stimulus_is_rffe(seqs)
            bad += bool(errs)
            warned += sum(1 for s in seqs if bin(s["sa"]).count("1") % 2)
            if errs:
                print("      seed %d, %s: %s" % (seed, name, errs[0]))
    expect(bad == 0, "slave: the decoder reads the ideal bus of all %d cases as wanted (%d predicted "
           "command-parity warnings among them, all as predicted)" % (count, warned))

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-15s %-4s %-8s %-6s %-7s %-8s %-7s %-4s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", "rx", ""))
        print("%-15s %-4s %-8s %-6s %-7s %-8s %-7s %-4s %s"
              % ("", "", "", "", "failed", "check", "check", "", "what it is"))
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
                              and passed == (not failed) and len(cases) == n_cases(seed)
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l or "simulator:" in l for l in failed))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-15s %-4d %-8s %-6s %-7s %-8s %-7s %-4s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         "obj" if any("rx:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    last_case = accept.cases_for(seed)[-1][1]
                    want = "RATE bytes=%d cycles=%d" % (sum(len(s["data"]) for s in last_case),
                                                        stand_in_span(last_case))
                    print()
                    expect(rates == [want], "seed %d: %s, as the stand-in's own pin changes give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for k, (text, good) in enumerate([
                ("-mode 0=pp -mode 1=od -config clkdiv=10,sideset_count=1\n", True),
                ("-mo 1=od -m 0=pp\n", True),
                ("-mode 0=pp -mode 1=od -tx other.txt\n", False),
                ("-mode 0=pp -mode 1=od -stimulus s.txt\n", False),
                ("-mode 0=pp -mode 1=od -s s.txt\n", False),
                ("-mode 0=pp -mode 1=od -cycles 5\n", False),
                ("-mode 0=pp -mode 1=od -inputs 0xff\n", False),
                ("-mode 0=pp -mode 1=od -c clkdiv=1\n", False),
                ("-mode 0=pp\n-mode 1=od\n", False),
                ("-mode 0=pp -mode\n", False),
                ("-mode 0=pp -mode 1=pp\n", False),
                ("-mode 0=od -mode 1=od\n", False),
                ("-mode 0=pp\n", False),
                ("-mode 0=pp -mode 1=od -mode 2=pp\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % k)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:100]))
        # The real simulator, with programs that are not RFFE firmware.
        for name, program, args, said in [
                ("real_idle_high",
                 "; Not RFFE firmware: one instruction that loops on itself and drives no pin.\n"
                 "idle:   jmp idle\n",
                 GOOD_ARGS, "FAIL: waveform: SCLK is not low from cycle 100"),
                ("real_low_only",
                 "; Not RFFE firmware: drives P0 and P1 low once, then loops on itself.\n"
                 "        set pins, 0\n"
                 "idle:   jmp idle\n",
                 "-mode 0=pp -mode 1=od -config set_count=2\n",
                 "FAIL: waveform: SCLK has 0 edges after cycle 100")]:
            d = real_sim_folder(parent, name, program, args)
            run, lines = judge(d, seeds[0], env)
            cases = [l for l in lines if l.startswith("case ")]
            expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == n_cases(seeds[0])
                   and all(said in l for l in cases)
                   and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
                   "real pe_sim, %s: every case fails cleanly, no RATE line (%s)"
                   % (name, cases[0][:120] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
