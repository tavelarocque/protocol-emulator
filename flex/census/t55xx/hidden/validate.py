#!/usr/bin/env python3
"""Validates the judge (accept.py). No T55xx firmware for the chip is run:
the stand-in pe_sim is a wrapper around ideal.py, which prints the ideal
waveform, or a deliberately broken one, in the simulator's format.

1. The interface. accept.tx_words must turn the task sheet's example into
   the words printed in the sheet, and the sheet must contain that text.
   ideal.commands_of (written apart) must read those words back into the
   bits the sheet lists.
2. The waveforms. For every entry of ideal.FAULTS this runs the whole of
   accept.py, end to end, as it will be run on a hand-in, and requires
   ACCEPT PASS for the waveforms that must pass and ACCEPT FAIL for the
   broken ones. It then asks the two halves of the judge separately (the
   direct check and sigrok's decoder), on the task sheet's example, which
   of them objects, and prints that.
3. The RATE line, against the ideal waveform's own list of changes.
4. The hand-in rules: bad run_args.txt files are refused, good ones taken.
5. The real pe_sim, once, with a one-instruction program that drives no pin
   (not T55xx firmware): the command line and the word file must be
   accepted, and every case must fail cleanly.

Exit status 0 if everything is as expected.

Usage: validate.py [seed ...]"""
import os
import shutil
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
import accept  # noqa: E402
import ideal  # noqa: E402

seeds = sys.argv[1:] or ["1"]
kit = os.path.join(here, "..", "..", "kits", "t55xx")
ok = True


def expect(good, what):
    global ok
    ok &= bool(good)
    print("%-5s %s" % ("ok" if good else "WRONG", what))


def fake_dir(d, fault):
    """A run folder whose pe_sim draws ideal.py's waveform with a fault."""
    sim = os.path.join(d, "pe_sim")
    with open(sim, "w") as f:
        f.write("#!/bin/sh\nexec %s -B %s --fault %s \"$@\"\n" % (sys.executable, os.path.join(here, "ideal.py"), fault))
    os.chmod(sim, os.stat(sim).st_mode | stat.S_IEXEC)
    open(os.path.join(d, "t55xx.s"), "w").write("; stand-in, not firmware\n")
    open(os.path.join(d, "run_args.txt"), "w").write("-mode 0=pp\n")


def run_accept(d, seed):
    r = subprocess.run([sys.executable, "-B", os.path.join(here, "accept.py"), d, seed],
                       capture_output=True, text=True)
    return r, r.stdout.splitlines()


# 1. the interface ---------------------------------------------------------
example = [accept.pwd(2, 0x12345678, 1, 0x9ABCDEF0, 5), accept.reset(), accept.std(3, 0, 0xFFFF0001, 2)]
words = accept.tx_words(example)
printed = "0x006E, 0x1234, 0x5678, 0x9ABC, 0xDEF0, 0x0080,\n0x0013, 0xFFFF, 0x0001"
expect(words == [0x006E, 0x1234, 0x5678, 0x9ABC, 0xDEF0, 0x0080, 0x0013, 0xFFFF, 0x0001],
       "tx_words of the sheet's example: %s" % " ".join("%04X" % w for w in words))
sheet = open(os.path.join(kit, "TASK.md")).read()
expect(printed in sheet, "TASK.md prints those nine words")
expect("The host sends only the words defined above.\nAll line coding, framing and timing must be done by the firmware." in sheet,
       "TASK.md carries the host-interface sentence")
read_back = ideal.commands_of(words)
expect(read_back == [accept.command_bits(c) for c in example],
       "ideal.commands_of reads the words back into accept.command_bits")
expect([len(b) for b in read_back] == [70, 2, 38], "the example is 70, 2 and 38 bits")
expect(read_back[0][:2] == [1, 0] and read_back[0][-3:] == [1, 0, 1] and read_back[0][34] == 1,
       "example command 0: opcode 1 0, lock 1, address 1 0 1")
expect(read_back[2][:3] == [1, 1, 0] and read_back[2][-3:] == [0, 1, 0],
       "example command 2: opcode 1 1, lock 0, address 0 1 0")

# 2. and 3. the waveforms, end to end -------------------------------------
with tempfile.TemporaryDirectory() as d:
    for seed in seeds:
        for fault, (must_pass, what) in ideal.FAULTS.items():
            fake_dir(d, fault)
            r, lines = run_accept(d, seed)
            passed = r.returncode == 0 and lines[-1:] == ["ACCEPT PASS"]
            fails = [l for l in lines if l.startswith("case") and "FAIL" in l]
            note = "" if passed else " | " + (fails[0][:150] if fails else lines[-1:][0] if lines else "")
            expect(passed == must_pass and lines[-1:] in (["ACCEPT PASS"], ["ACCEPT FAIL"]),
                   "seed %s %-12s %s: %s (%s)%s" % (seed, fault, "pass" if must_pass else "fail",
                                                  "passed" if passed else "failed", what, note))
            if fault == "none":
                rate = [l for l in lines if l.startswith("RATE")]
                commands = accept.cases_for(int(seed))[-1][1]
                cycles = accept.run_cycles(commands)
                ch = ideal.toggles([accept.command_bits(c) for c in commands], "none", cycles)
                want = "RATE bytes=%d cycles=%d" % (accept.payload_bytes(commands), ch[-1][0] - ch[1][0])
                expect(rate == [want] and lines[-2] == want, "seed %s RATE line %s, from the generator %s"
                       % (seed, rate, want))

# which half objects, on the sheet's example
print("\nWhich check objects, on the task sheet's example (W = waveform check, D = decoder):")
cycles = accept.run_cycles(example)
bits = [accept.command_bits(c) for c in example]
for fault, (must_pass, what) in ideal.FAULTS.items():
    ch = ideal.toggles(bits, fault, cycles)
    w = accept.check_waveform(example, ch, cycles)
    dd = accept.check_decoder(example, ch, cycles)
    print("  %-12s W:%-4s D:%-4s %s" % (fault, "FAIL" if w else "ok", "FAIL" if dd else "ok",
                                         (w or dd or [""])[0][:110]))
    if must_pass:
        expect(not w and not dd, "%s passes both checks on the example" % fault)

# 4. the hand-in rules -----------------------------------------------------
for bad in ["-tx f", "-t f", "-cycles 9", "-inputs 1", "-stimulus f", "-c x", "-mode 0=pp\n-config clkdiv=2",
            "-mode", "--mode 0=pp"]:
    expect(accept.args_problem(__import__("shlex").split(bad)) is not None or "\n" in bad,
           "run_args %r refused" % bad)
with tempfile.TemporaryDirectory() as d:
    fake_dir(d, "none")
    open(os.path.join(d, "run_args.txt"), "w").write("-mode 0=pp\n-config clkdiv=2\n")
    r, lines = run_accept(d, "1")
    expect(r.returncode != 0 and lines[0].startswith("setup: FAIL"), "a two-line run_args.txt is a setup failure")
for good in ["-mode 0=pp", "-config clkdiv=5,set_base=0 -mode 0=pp", "-conf start=0 -mo 0=pp"]:
    expect(accept.args_problem(__import__("shlex").split(good)) is None, "run_args %r accepted" % good)

# 5. the real simulator ----------------------------------------------------
with tempfile.TemporaryDirectory() as d:
    shutil.copy(os.path.join(kit, "pe_sim"), os.path.join(d, "pe_sim"))
    open(os.path.join(d, "t55xx.s"), "w").write("l: jmp l\n")
    open(os.path.join(d, "run_args.txt"), "w").write("-mode 0=pp\n")
    r, lines = run_accept(d, seeds[0])
    cases = [l for l in lines if l.startswith("case")]
    expect(r.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 14
           and all("waveform: P0 never changes" in l for l in cases)
           and not any(l.startswith("RATE") for l in lines),
           "real pe_sim, idle program: %d cases, all fail cleanly (%s)" % (len(cases), cases[0][:90] if cases else lines))

print("\nVALIDATE PASS" if ok else "\nVALIDATE FAIL")
sys.exit(0 if ok else 1)
