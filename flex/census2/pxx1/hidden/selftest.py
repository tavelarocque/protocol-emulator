#!/usr/bin/env python3
"""Checks the judge (accept.py) for the PXX1 transmitter. No chip firmware
is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's two example
   frames into the words printed in the sheet (../../kits/pxx1/TASK.md).
2. The CRC. accept's table (the register run bit by bit) must equal the
   sheet's definition (carry-less products, ideal_wave.table) on all 256
   values, and the values the sheet prints.
3. The examples. The bytes, CRC and bit strings (stuffed 0s marked) that
   the sheet prints for its two examples must be the judge's.
4. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into frames by the sheet's rules, in its
   own code, so a judge that built the words wrongly would fail the ideal
   waveform.
5. The RATE line, against the ideal generator's own edge list.
6. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode is refused.
7. The real simulator, with two programs that are not PXX1 firmware: one
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

KIT = os.path.join(HERE, "..", "..", "kits", "pxx1")
EX1 = (3, 0x00, 0x00, 0x00, [1024] * 8)
EX2 = (0x1F, 0x11, 0x00, 0x04, [0x7FF, 0xF81] + [1024] * 6)
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
    with open(os.path.join(d, "pxx1.s"), "w") as f:
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
    with open(os.path.join(d, "pxx1.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def marked(frame):
    """The frame's wire bits as the sheet prints them, stuffed 0s as [0]."""
    return "".join("[0]" if k == ("stuff",) else str(b) for b, k in accept.line_bits(frame))


def sheet_blocks(raw):
    """The indented blocks of the sheet (its examples), whitespace removed."""
    blocks, cur = [], []
    for line in raw.splitlines():
        if line.startswith("    "):
            cur.append(line.strip())
        elif cur:
            blocks.append(cur)
            cur = []
    return blocks


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
    words = accept.tx_words([EX1, EX2])
    text = ", ".join("0x%04X" % w for w in words)
    expect(text in sheet, "interface: the sheet's two examples give the twenty words it prints")
    expect(accept.tx_words([(1, 2, 3, 4, list(range(8)))]) == [0x0201, 0x0403] + list(range(8)),
           "interface: word 0 is flag 1 << 8 | receiver, word 1 extra << 8 | flag 2, then channels")
    expect("The host sends only the words defined above. All line coding, framing and timing must be done by the firmware." in sheet,
           "interface: the sheet says the host sends payload only")

    # 2. The CRC.
    expect(all(accept.crc_table_entry(v) == ideal_wave.table(v) for v in range(256)),
           "CRC: the judge's table (register run bit by bit) equals the sheet's carry-less products on all 256 values")
    listed = re.search(r"T\[0\] to T\[15\] are (.*?);", sheet).group(1)
    expect([int(x, 16) for x in re.findall(r"0x[0-9A-F]{4}", listed)] == [accept.crc_table_entry(v) for v in range(16)]
           and accept.crc_table_entry(16) == 0x1081 and accept.crc_table_entry(128) == 0x8408
           and accept.crc_table_entry(255) == 0x0F78 and "T[255] = 0xF8F7 XOR 0xF78F = 0x0F78" in sheet,
           "CRC: the values the sheet prints (T[0..15], T[16], T[128], T[255]) are the judge's")
    std = 0
    for b in b"123456789":
        std = (std >> 8) ^ accept.crc_table_entry((std ^ b) & 0xFF)
    expect(std == 0x2189 and accept.crc16(b"123456789") != std,
           "CRC: the table is CRC-16/KERMIT's (check value 0x2189 when used reflected), and PXX1's CRC differs from it")

    # 3. The examples.
    blocks = sheet_blocks(raw)
    for name, frame, crc in (("first", EX1, 0x21A3), ("second", EX2, 0xFF54)):
        data = accept.frame_bytes(frame)
        btext = " ".join("%02X" % b for b in data)
        expect(accept.crc16(data) == crc and btext in sheet and ("the CRC is 0x%04X" % crc) in sheet,
               "example %s: bytes %s and CRC 0x%04X as the sheet prints them" % (name, btext, crc))
    want1 = marked(EX1)
    b1 = next(b for b in blocks if b[0].startswith("01111110 00000011"))
    head, tail = "".join(b1[0].replace("...", "").split()), "".join(b1[1].replace("...", "").split())
    expect("[0]" not in want1 and len(want1) == 160 and want1.startswith(head) and want1.endswith(tail),
           "example first: no stuffed bit, 160 bits, the sheet's opening and closing bits are the judge's")
    b2 = next(b for b in blocks if b[0] == "01111110" and len(b) > 1)
    got2 = "".join("".join(b2).split())
    want2 = marked(EX2)
    expect(got2 == want2 and want2.count("[0]") == 4 and len(accept.line_bits(EX2)) == 164,
           "example second: the sheet's 164 bits with four stuffed 0s are the judge's")
    g = ideal_wave.toggles([EX1])
    expect(g[:4] == [100000, 100400, 100800, 101200] and g[4] == 102000,
           "example first: the generator puts the edges where the sheet says (0, 400, 800, 1200, 2000)")
    expect(accept.stuff_after_crc(accept.find_crc_stuff_frame())
           and marked(accept.find_crc_stuff_frame()).endswith("11111[0]01111110"),
           "the fixed case with a stuffed 0 straight after the CRC has one")

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-12s %-4s %-8s %-6s %-7s %-8s %-7s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", ""))
        print("%-12s %-4s %-8s %-6s %-7s %-8s %-7s %s"
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
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l for l in cases))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-12s %-4d %-8s %-6s %-7s %-8s %-7s %s%s"
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
                    want = "RATE bytes=%d cycles=%d" % (16 * len(last_case), t[-1] - t[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's edges give"
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
                                          ("-mode\n", False),
                                          ("-config clkdiv=1\n", False),
                                          ("-mode 0=od\n", False),
                                          ("-mode 1=pp\n", False),
                                          ("-mode 0=pp -mode 0=in\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:90]))
        # The real simulator, with programs that are not PXX1 firmware.
        for name, program, said in [
                ("real_idle_high",
                 "; Not PXX1 firmware: one instruction that loops on itself and drives no pin.\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: 0 separate bursts"),
                ("real_low_only",
                 "; Not PXX1 firmware: drives P0 low once, then loops on itself.\n"
                 "        set pins, 0\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: P0 is low at the end of the run")]:
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
