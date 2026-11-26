#!/usr/bin/env python3
"""Checks the judge (accept.py) for the CAN FD transmitter. No chip firmware
is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (../../kits/can_fd/TASK.md).
2. The example. The sheet's bit table (level, start, length of all 64 bits)
   must be the judge's ideal frame, and the generator's edges for it the
   judge's edges. The CRC: both CRC routines, started from zero, must give
   the catalogue check values, and no case may hold a frame with more than
   16 bytes (the sheet promises CRC-17 only).
3. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal CAN FD node, not chip firmware), runs accept.py
   on it from end to end exactly as on a real hand-in, and compares the
   verdict with the one that waveform must get. The stand-in reads the
   judge's TX words back into frames by the sheet's rules and the stimulus
   back into acknowledgements, in its own code.
4. The RATE line, against the generator's own edge list.
5. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode, or without P0 open-drain, is refused.
6. The real simulator, with two programs that are not CAN FD firmware: one
   that never writes P0, and one that pulls P0 low and then does nothing.
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

KIT = os.path.join(HERE, "..", "..", "kits", "can_fd")
EXAMPLE = [accept.Frame(0, 1, 1, 0x020, [0xF0]), accept.Frame(1, 0, 3, 0x1ABCDE12, [0x11, 0x22, 0x33])]
EXAMPLE_WORDS = [0x4001, 0x0020, 0xF000, 0x8003, 0x1ABC, 0xDE12, 0x1122, 0x3300]
EXAMPLE_TEXT = "0x4001, 0x0020, 0xF000, 0x8003, 0x1ABC, 0xDE12, 0x1122, 0x3300"


def stand_in(parent, fault, run_args="-mode 0=od\n", name=None):
    d = os.path.join(parent, name or fault)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" -B "%s" --fault %s "$@"\n'
                % (sys.executable, os.path.join(HERE, "ideal_wave.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "can_fd.s"), "w") as f:
        f.write("; placeholder: the stand-in simulator never reads this file\n")
    return d


def real_sim_folder(parent, name, program, run_args="-mode 0=od\n"):
    d = os.path.join(parent, name)
    os.mkdir(d)
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IXUSR)
    with open(os.path.join(d, "run_args.txt"), "w") as f:
        f.write(run_args)
    with open(os.path.join(d, "can_fd.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def sheet_table(raw):
    """[(level, start, length)] from the sheet's example table."""
    out = []
    for line in raw.splitlines():
        m = re.match(r"\| (\d+) \| [^|]+ \| ([01]) \| (\d+) \| (\d+) \|$", line)
        if m:
            out.append((int(m.group(2)), int(m.group(3)), int(m.group(4))))
    return out


def main(argv):
    seeds = [int(s) for s in argv] or [1]
    wrong = 0
    n_cases = len(accept.cases_for(seeds[0]))

    def expect(ok, what):
        nonlocal wrong
        wrong += not ok
        print("%-5s %s" % ("ok" if ok else "WRONG", what))

    with open(os.path.join(KIT, "TASK.md")) as f:
        raw = f.read()
    sheet = " ".join(raw.split())
    expect(accept.tx_words(EXAMPLE) == EXAMPLE_WORDS and EXAMPLE_TEXT in sheet
           and "pushes 0x0001 and then 0x0000" in sheet,
           "interface: the sheet's example gives the words printed in the sheet (%s)" % EXAMPLE_TEXT)
    expect(accept.tx_words([accept.Frame(0, 0, 0, 0x7EF, [])]) == [0x0000, 0x07EF]
           and accept.tx_words([accept.Frame(1, 1, 9, 0x10000, list(range(12)))])[:3] == [0xC009, 0x0001, 0x0000],
           "interface: no data words for DLC 0; header bits 15 and 14; extended identifier split 13 + 16")
    line, ack_at, end = accept.frame_timeline(EXAMPLE[0], accept.FIRST_SOF)
    judge_rows = [(b, s, l) for s, l, b, _ in line]
    table = sheet_table(raw)
    expect(table == judge_rows and len(table) == 64 and ack_at == 4950 and end == 5850,
           "example: the sheet's table of 64 bits is the judge's ideal frame (ACK slot at %d, end at %d)"
           % (ack_at, end))
    c = accept.Coded(EXAMPLE[0])
    expect(c.crc == 0x5DE7 and c.stuff_count == 3 and c.sc_bits == "010" and c.parity == 1
           and "CRC-17 is 0x05DE7" in sheet and "stuff count 3, Gray code 010, parity 1" in sheet,
           "example: CRC-17 0x05DE7, stuff count 3 (010), parity 1, as the sheet says")
    nack = accept.Schedule([accept.Frame(0, 1, 1, 0x020, [0xF0], ack=False)])
    expect(nack.ends == [6450] and [e for e in nack.chip_edges() if e[0] > 4950] == [(5050, 0), (5650, 1)]
           and "pull the line low from 5050 to 5650" in sheet and "end at 6450" in sheet,
           "example: unacknowledged, the error flag from 5050 to 5650 and the end at 6450, as the sheet says")
    stim = accept.Schedule(EXAMPLE[:1]).stimulus()
    expect(stim == [(0, 1), (4950, 0), (5050, 1)] and "0 ff 4950 fe 5050 ff" in sheet,
           "example: the stimulus file printed in the sheet is the judge's")
    with tempfile.TemporaryDirectory() as d:
        stim_path = os.path.join(d, "s")
        with open(stim_path, "w") as f:
            f.write("0 ff\n4950 fe\n5050 ff\n")
        frames = ideal_wave.frames_of(EXAMPLE_WORDS[:3])
        changes, _ = ideal_wave.run(frames, [(0, 1), (4950, 0), (5050, 1)], 10000, "none")
    expect(changes == accept.Schedule(EXAMPLE[:1]).chip_edges(),
           "example: the generator's edges for the example are the judge's")
    cv = accept.crc_check_values()
    gen17 = ideal_wave.crc_div("".join(ideal_wave.bits_of(b, 8) for b in b"123456789"), 17, False)
    gen21 = ideal_wave.crc_div("".join(ideal_wave.bits_of(b, 8) for b in b"123456789"), 21, False)
    expect(cv == (0x04F03, 0x0ED841) and (gen17, gen21) == cv
           and "is 0x04F03" in sheet and "0x10000" in sheet and "0x1685B" in sheet,
           "CRC: both routines, from zero, give the catalogue check values 0x04F03 (CRC-17, quoted"
           " in the sheet) and 0x0ED841 (CRC-21, used by no case)")
    expect(all(f.dlc <= accept.MAX_DLC for s in seeds for _, fr in accept.cases_for(s) for f in fr)
           and "DLC 0 to 10" in sheet,
           "cases: every frame has DLC 0 to 10 (a CRC-17), as the sheet says")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-6s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "rx", "decoder", ""))
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-6s %-7s %s"
              % ("", "", "", "", "failed", "check", "check", "check", "what it is"))
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
                              and passed == (not failed) and len(cases) == n_cases
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l or "simulator:" in l for l in cases))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-11s %-4d %-8s %-6s %-7s %-8s %-6s %-7s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail",
                         "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("rx:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    last_case = accept.cases_for(seed)[-1][1]
                    sched = accept.Schedule(last_case)
                    words = accept.tx_words(last_case)
                    edges, _ = ideal_wave.run(ideal_wave.frames_of(words), sched.stimulus(), sched.cycles, "none")
                    want = "RATE bytes=%d cycles=%d" % (sum(len(f.data) for f in last_case),
                                                        edges[-1][0] - edges[0][0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's edges give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([("-mode 0=od -config clkdiv=1\n", True),
                                          ("-mo 0=od -mode 1=pp\n", True),
                                          ("-config out_msb_first=1 -mode 0=od\n", True),
                                          ("-mode 0=pp\n", False),
                                          ("-config clkdiv=1\n", False),
                                          ("-mode 0=od -tx other.txt\n", False),
                                          ("-mode 0=od -t other.txt\n", False),
                                          ("-mode 0=od -cycles 5\n", False),
                                          ("-mode 0=od -inputs 0xff\n", False),
                                          ("-mode 0=od -stimulus s.txt\n", False),
                                          ("-mode 0=od -c clkdiv=1\n", False),
                                          ("-mode 0=od\n-config clkdiv=1\n", False),
                                          ("-mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        for name, program, said in [
                ("real_idle",
                 "; Not CAN FD firmware: one instruction that loops on itself and drives no pin.\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: P0 never makes change 0"),
                ("real_low_only",
                 "; Not CAN FD firmware: pulls P0 low once, then loops on itself.\n"
                 "        set pins, 0\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: change 0 of P0: falls at cycle")]:
            d = real_sim_folder(parent, name, program)
            run, lines = judge(d, seeds[0], env)
            cases = [l for l in lines if l.startswith("case ")]
            expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == n_cases
                   and all(said in l for l in cases)
                   and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
                   "real pe_sim, %s: every case fails cleanly, no RATE line (%s)"
                   % (name, cases[0][:120] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
