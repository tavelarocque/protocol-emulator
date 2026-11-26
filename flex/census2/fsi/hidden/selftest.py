#!/usr/bin/env python3
"""Checks the judge (accept.py) for the FSI master. No chip firmware is
involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface and the example. accept.py's words, rx words, command and
   response bits, clocks, N and stimulus for the task sheet's example must
   be exactly what the sheet (../../kits/fsi/TASK.md) prints.
2. Two CRCs. accept.crc4 (bit by bit) must equal ideal_wave.crc4_nibbles
   (Linux's nibble table) on random messages, and the stand-in's command
   bits must equal the judge's for every transaction of every case.
3. The stimulus. The decoder must read the ideal link (ideal master plus
   stimulus) of every case on every seed as the wanted transactions.
4. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper around ideal_wave.py
   (an ideal FSI master as a waveform generator, not chip firmware), runs
   accept.py on it end to end exactly as on a real hand-in, and compares
   the verdict with the one that waveform must get.
5. The RATE line, against the stand-in's own pin changes.
6. The hand-in rules: run_args.txt with a flag other than -config and
   -mode, or the wrong pin modes, is refused.
7. The real simulator, with a program that is not FSI firmware: every case
   must fail cleanly.

Stand-in folders are made inside this folder and removed afterwards. Exit
status 0 only if everything is as expected."""
import os
import random
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

KIT = os.path.join(HERE, "..", "..", "kits", "fsi")
N_CASES = 14
GOOD_ARGS = "-mode 0=od -mode 1=pp\n"


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
    with open(os.path.join(d, "fsi.s"), "w") as f:
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
    with open(os.path.join(d, "fsi.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def bits(b):
    return "".join(map(str, b))


def sheet_rows(raw):
    """(first clock, last clock, sender, bits without spaces) of the example table."""
    rows = []
    for line in raw.splitlines():
        m = re.match(r"\| (\d+) to (\d+) \| (chip|slave) \| ([01 ]+) \|", line)
        if m:
            rows.append((int(m.group(1)), int(m.group(2)), m.group(3), m.group(4).replace(" ", "")))
    return rows


def sheet_stimulus(raw):
    lines = raw.split("(N = 3900) it is", 1)[1].split("In the simulator", 1)[0]
    return [(int(c), int(h, 16)) for c, h in re.findall(r"^    (\d+) ([0-9a-f]{2})$", lines, re.M)]


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
    ex = accept.EXAMPLE

    # 1. The interface and the example.
    words = accept.tx_words(ex)
    text = ", ".join("0x%04X" % w for w in words)
    expect(words == [0x0000, 0x0000, 0x0C10, 0x00A5, 0x001D, 0x001F, 0xFFFE]
           and ("arrive as the seven words " + text) in sheet,
           "interface: the example's TX words are the sheet's (%s)" % text)
    expect(accept.rx_words(ex) == [0, 0, 0x5AC3]
           and "pushes 0x0000 (the write's ACK), then 0x0000 (the read's ACK) and 0x5AC3" in sheet,
           "interface: the example's rx words are the sheet's (0x0000, 0x0000, 0x5AC3)")
    expect(accept.tx_words([accept.T("W", 4, 2, 0x1ABCD4, 0x89ABCDEF)])
           == [0x0012, 0x001A, 0xBCD4, 0x89AB, 0xCDEF]
           and accept.rx_words([accept.T("R", 4, 1, 0, 0x89ABCDEF), accept.T("R", 1, 0, 3, 0x42, 2)])
           == [0, 0x89AB, 0xCDEF, 2],
           "interface: 4-byte data is two words, high half first; an ERR read gives only its code")
    sched, s_end = accept.schedule(ex)
    rows = sheet_rows(raw)
    want_rows = []
    for t, (s, ce, cs, e) in zip(ex, sched):
        want_rows += [(s, ce, "chip", bits(accept.command_bits(t))),
                      (cs, e, "slave", bits(accept.response_bits(t)))]
    expect(rows == want_rows, "example: the sheet's table of bits and clocks is the judge's (%s)"
           % "; ".join("%d-%d %s" % r[:3] for r in rows))
    expect(s_end == 190 and accept.run_cycles(ex) == 3900 and "N = 3900" in sheet
           and "a third START would be clock 190" in sheet,
           "example: the next START would be clock 190 and N = 3900")
    expect(sheet_stimulus(raw) == accept.stimulus(ex),
           "example: the sheet's stimulus file is the judge's (%d lines)" % len(sheet_stimulus(raw)))
    expect(accept.wire_address(accept.T("R", 4, 0, 0x001000, 0)) == 0x001001
           and "0x001000 is sent as 0x001001" in sheet,
           "example: a 4-byte access sends address bits 1..0 as 01")

    # 2. Two CRCs.
    rng = random.Random(99)
    agree = True
    for _ in range(2000):
        n = rng.randint(1, 61)
        v = rng.getrandbits(n) | (1 << (n - 1))     # every message starts with START
        agree &= bits(accept.crc4([(v >> i) & 1 for i in range(n - 1, -1, -1)])) \
            == format(ideal_wave.crc4_nibbles(v, n), "04b")
    expect(agree, "crc: bit by bit (judge) and Linux's nibble table (stand-in) agree on 2000 messages")
    same = True
    for seed in seeds:
        for _, trans in accept.cases_for(seed):
            for t in trans:
                mine = ideal_wave.command(t["rw"] == "R", t["size"], t["sid"], t["addr"],
                                          t["data"], "none", False)
                same &= mine == accept.command_bits(t)
    expect(same, "crc: the stand-in's command bits equal the judge's for every transaction")

    # 3. The stimulus.
    bad = []
    for seed in seeds:
        for name, trans in accept.cases_for(seed):
            e = accept.check_stimulus(trans)
            if e:
                bad.append("seed %d %s: %s" % (seed, name, e[0]))
    expect(not bad, "stimulus: the decoder reads the ideal link of all %d cases on %d seeds as wanted%s"
           % (N_CASES, len(seeds), "" if not bad else ": " + bad[0]))

    with tempfile.TemporaryDirectory(prefix="selftest_", dir=HERE) as parent:
        env = dict(os.environ, TMPDIR=parent)
        print()
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-7s %-4s %s"
              % ("waveform", "seed", "expected", "judge", "cases", "waveform", "decoder", "rx", ""))
        print("%-11s %-4s %-8s %-6s %-7s %-8s %-7s %-4s %s"
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
                              and passed == (not failed) and len(cases) == N_CASES
                              and len(rates) == (1 if len(failed) < len(cases) else 0)
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l for l in failed))
                ok = consistent and passed == should_pass
                wrong += not ok
                print("%-11s %-4d %-8s %-6s %-7s %-8s %-7s %-4s %s%s"
                      % (fault, seed, "pass" if should_pass else "fail",
                         "pass" if passed else "fail", "%d/%d" % (len(failed), len(cases)),
                         "objects" if any("waveform:" in l for l in failed) else "-",
                         "objects" if any("decoder:" in l for l in failed) else "-",
                         "obj" if any("rx:" in l for l in failed) else "-",
                         what, "" if ok else "   <-- WRONG VERDICT"))
                if not ok:
                    sys.stdout.write(run.stdout + run.stderr)
                if fault == "none":
                    # RATE from the stand-in's own output for the last case.
                    last_case = accept.cases_for(seed)[-1][1]
                    with tempfile.TemporaryDirectory(dir=parent) as t:
                        tx, st = os.path.join(t, "tx"), os.path.join(t, "st")
                        with open(tx, "w") as f:
                            f.write("".join("%d\n" % w for w in accept.tx_words(last_case)))
                        with open(st, "w") as f:
                            f.write("".join("%d %02x\n" % p for p in accept.stimulus(last_case)))
                        out = subprocess.run(
                            [sys.executable, "-B", os.path.join(HERE, "ideal_wave.py"), "run", "x.s",
                             "-tx", tx, "-stimulus", st, "-cycles", str(accept.run_cycles(last_case))],
                            capture_output=True, text=True).stdout
                    moved = [int(l.split()[1]) for l in out.splitlines() if l.startswith("pins")][1:]
                    want = "RATE bytes=%d cycles=%d" % (accept.data_bytes(last_case), moved[-1] - moved[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the stand-in's own pin changes give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([
                (GOOD_ARGS, True),
                ("-mo 0=od -mo 1=pp -config clkdiv=1,sideset_base=1\n", True),
                ("-mode 0=od -mode 1=pp -tx other.txt\n", False),
                ("-mode 0=od -mode 1=pp -stimulus s.txt\n", False),
                ("-mode 0=od -mode 1=pp -s s.txt\n", False),
                ("-mode 0=od -mode 1=pp -cycles 5\n", False),
                ("-mode 0=od -mode 1=pp -inputs 0xff\n", False),
                ("-mode 0=od -mode 1=pp -c clkdiv=1\n", False),
                ("-mode 0=od\n-mode 1=pp\n", False),
                ("-mode 0=od -mode\n", False),
                ("-mode 0=pp -mode 1=pp\n", False),
                ("-mode 0=od -mode 1=od\n", False),
                ("-mode 0=od\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:100]))
        # The real simulator, with a program that is not FSI firmware.
        d = real_sim_folder(parent, "real_idle",
                            "; Not FSI firmware: one instruction that loops on itself and drives no pin.\n"
                            "idle:   jmp idle\n")
        run, lines = judge(d, seeds[0], env)
        cases = [l for l in lines if l.startswith("case ")]
        expect(run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == N_CASES
               and all("FAIL: waveform: FSI_CLK has 0 edges" in l for l in cases)
               and not any(l.startswith("RATE") for l in lines) and not run.stderr.strip(),
               "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
               % (cases[0][:110] if cases else run.stdout[:100] + run.stderr[:100]))
    print("SELFTEST PASS" if not wrong else "SELFTEST FAIL: %d wrong" % wrong)
    return 1 if wrong else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
