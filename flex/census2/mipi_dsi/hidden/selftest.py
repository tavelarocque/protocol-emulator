#!/usr/bin/env python3
"""Checks the judge (accept.py) for the MIPI DSI low-power transmitter. No
chip firmware is involved.

Usage: selftest.py [seed ...]        (default: seed 1)

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (../../kits/mipi_dsi/TASK.md), and
   the bytes on the wire the sheet prints for its packets must be the
   judge's. The judge's ECC must give two packets widely published, and its
   checksum CRC-16's check value.
2. The example. The lane states in the sheet's table for "exit sleep mode"
   must be accept.lane_states for it, 86 of them, and the generator's own.
3. The waveforms. For every waveform in ideal_wave.FAULTS it builds a
   stand-in hand-in folder whose `pe_sim` is a wrapper script around
   ideal_wave.py (an ideal waveform generator, not chip firmware), runs
   accept.py on it from end to end exactly as on a real hand-in, and
   compares the verdict with the one that waveform must get. The stand-in
   reads the judge's TX words back into transmissions by the task sheet's
   rules, in its own code, so a judge that built the words wrongly would
   fail the ideal waveform.
4. The RATE line, against the ideal generator's own transition list.
5. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode, or that leaves P0..P3 other than push-pull, is refused.
6. The real simulator, with two programs that are not DSI firmware: one
   that never writes a pin, and one that drives P0 low and then does
   nothing. The command line and the word file must be accepted, and every
   case must fail cleanly.

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

KIT = os.path.join(HERE, "..", "..", "kits", "mipi_dsi")
EXIT_SLEEP = [0x05, 0x11, 0x00, 0x36]
DISPLAY_ON = [0x05, 0x29, 0x00, 0x1C]
SHEET_PACKETS = [accept.short_packet(0x05, 0, 0x11, 0x00),
                 accept.long_packet(0x39, 0, [0x2A, 0x00, 0x00, 0x00, 0xEF])]
SHEET_WORDS = "0x0005, 0x0011, 0x0139, 0x0005, 0x002A, 0x0000, 0x0000, 0x0000, 0x00EF"
SHEET_LONG = "0x39, 0x05, 0x00, 0x36, 0x2A, 0x00, 0x00, 0x00, 0xEF, 0x48, 0x03"
GOOD_ARGS = "-mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp\n"
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
    with open(os.path.join(d, "mipi_dsi.s"), "w") as f:
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
    with open(os.path.join(d, "mipi_dsi.s"), "w") as f:
        f.write(program)
    return d


def judge(d, seed, env):
    run = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                         capture_output=True, text=True, env=env)
    return run, run.stdout.splitlines()


def sheet_table(raw):
    """(bits, states) of the sheet's example table, in order."""
    bits, states = [], []
    for line in raw.splitlines():
        if not line.startswith("| ") or "Lane states" in line or "---" in line:
            continue
        cells = [c.strip() for c in line.split("|")[1:-1]]
        if len(cells) != 3 or not re.fullmatch(r"[01 ]+", cells[2]):
            continue
        bits += [int(b) for b in cells[1].split()]
        states += [(int(s[0]), int(s[1])) for s in cells[2].split()]
    return bits, states


def generator_states(data):
    """The lane states ideal_wave.py makes for one transmission."""
    out = []
    packet = ideal_wave.packets_of(accept.tx_words([accept.short_packet(*data)]))[0]
    for line in ideal_wave.pins_text([packet], 10 ** 9).splitlines()[1:]:
        reg = int(line.split()[2], 16)
        out.append((reg & 1, (reg >> 1) & 1))
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
    expect(accept.wire(accept.short_packet(0x05, 0, 0x11, 0x00)) == EXIT_SLEEP
           and accept.wire(accept.short_packet(0x05, 0, 0x29, 0x00)) == DISPLAY_ON,
           "packets: exit sleep mode is 05 11 00 36 and display on 05 29 00 1C (the ECCs published for them)")
    expect(accept.checksum(b"123456789") == 0x6F91,
           "packets: the checksum is CRC-16 0x1021 reflected from 0xFFFF (check value 0x6F91)")
    words = accept.tx_words(SHEET_PACKETS)
    expect(", ".join("0x%04X" % w for w in words) == SHEET_WORDS and SHEET_WORDS in sheet,
           "interface: the task sheet's example gives the words printed in the sheet (%s)" % SHEET_WORDS)
    expect(", ".join("0x%02X" % b for b in accept.wire(SHEET_PACKETS[1])) == SHEET_LONG
           and SHEET_LONG in sheet and "0x05, 0x11, 0x00, 0x36" in sheet,
           "interface: the wire bytes the sheet prints for its packets are the judge's (%s)" % SHEET_LONG)
    expect(accept.tx_words([accept.short_packet(0x15, 2, 0x36, 0x48)]) == [0x95, 0x4836]
           and accept.tx_words([accept.long_packet(0x29, 1, [])]) == [0x169, 0]
           and accept.wire(accept.long_packet(0x29, 1, []))[-2:] == [0xFF, 0xFF],
           "interface: short packet two words; empty long packet two words, checksum 0xFFFF")
    for name, packets in accept.cases_for(seeds[0]):
        back = ideal_wave.packets_of(accept.tx_words(packets))
        if [ideal_wave.packet_bytes(p, "none") for p in back] != [accept.wire(p) for p in packets]:
            expect(False, "generator: wire bytes differ from the judge's in case %r" % name)
            break
    else:
        expect(True, "generator: its own ECC and checksum give the judge's wire bytes in every case")
    bits, states = sheet_table(raw)
    ideal = accept.lane_states(EXIT_SLEEP)
    expect(bits == accept.tx_bits(EXIT_SLEEP) and states == ideal and len(ideal) == 86
           and "85 states between the two LP-11s, and 86 changes" in sheet
           and len(ideal) == 22 + 16 * len(EXIT_SLEEP),
           "example: the sheet's table for exit sleep mode is the judge's ideal (%d changes)" % len(ideal))
    expect(generator_states((0x05, 0, 0x11, 0x00)) == ideal,
           "example: the generator's lane states for exit sleep mode are the judge's ideal")
    sizes = [len(accept.wire(p)) for _, txs in accept.cases_for(seeds[0]) for p in txs]
    expect(min(sizes) >= 1 and max(sizes) <= accept.MAX_BYTES
           and all(1 <= len(txs) <= accept.MAX_TX for _, txs in accept.cases_for(seeds[0]))
           and len(accept.cases_for(seeds[0])) == N_CASES,
           "cases: %d cases, 1 to 6 packets of 4 to 32 bytes on the wire (sizes %d to %d)"
           % (N_CASES, min(sizes), max(sizes)))

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
                              and (not rates or lines[-2] == rates[0])
                              and not any("judge:" in l for l in cases))
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
                    t = ideal_wave.transitions(ideal_wave.packets_of(accept.tx_words(last_case)))
                    want = "RATE bytes=%d cycles=%d" % (sum(len(accept.wire(x)) for x in last_case),
                                                        t[-1] - t[0])
                    print()
                    expect(rates == [want], "seed %d: %s, as the generator's transitions give"
                           % (seed, rates[0] if rates else "no RATE line"))
                    print()
        print()
        for n, (text, good) in enumerate([
                (GOOD_ARGS.strip() + " -config set_count=2,clkdiv=1\n", True),
                ("-mo 0=pp -mo 1=pp -mo 2=pp -mo 3=pp -mo 4=in\n", True),
                ("-mode 0=pp -mode 1=pp -mode 2=pp\n", False),
                ("-mode 0=pp -mode 1=od -mode 2=pp -mode 3=pp\n", False),
                ("-mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp -mode 3=in\n", False),
                ("-mode 0=pp,1=pp,2=pp,3=pp\n", False),
                (GOOD_ARGS.strip() + " -tx other.txt\n", False),
                (GOOD_ARGS.strip() + " -t other.txt\n", False),
                (GOOD_ARGS.strip() + " -cycles 5\n", False),
                (GOOD_ARGS.strip() + " -inputs 0xff\n", False),
                (GOOD_ARGS.strip() + " -stimulus s.txt\n", False),
                (GOOD_ARGS.strip() + " -c clkdiv=1\n", False),
                (GOOD_ARGS + "-config clkdiv=1\n", False),
                (GOOD_ARGS.strip() + " -mode\n", False)]):
            d = stand_in(parent, "none", run_args=text, name="args%d" % n)
            run, lines = judge(d, seeds[0], env)
            got = run.returncode == 0 and lines[-1] == "ACCEPT PASS"
            refused = run.returncode == 1 and lines[-1] == "ACCEPT FAIL" and lines[0].startswith("setup: FAIL")
            expect(got if good else refused,
                   "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][:100]))
        # The real simulator, with programs that are not DSI firmware.
        for name, program, said in [
                ("real_idle",
                 "; Not DSI firmware: one instruction that loops on itself and drives no pin.\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: 0 transmissions on data lane 0"),
                ("real_p0_low",
                 "; Not DSI firmware: drives P0 low once, then loops on itself.\n"
                 "        set pins, 0\n"
                 "idle:   jmp idle\n",
                 "FAIL: waveform: data lane 0 is not back in LP-11 at the end of the run")]:
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
