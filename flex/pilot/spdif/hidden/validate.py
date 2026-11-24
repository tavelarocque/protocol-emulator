#!/usr/bin/env python3
"""Validates the round-two judge (accept.py). No firmware for S/PDIF is run:
selftest/fake_run/pe_sim is a stand-in that prints the ideal waveform of
ideal.py, or a deliberately broken one.

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (../../kits2/spdif/TASK.md).
2. The waveforms. For every waveform this runs the whole of accept.py, end
   to end, as it will be run on a hand-in, and then asks the two halves of
   the judge separately (the direct check and sigrok's decoder) which of
   them objects, on one run of 200 frames. The stand-in reads the judge's TX
   words back into samples by the task sheet's rules, in its own code, so a
   judge that built the words wrongly would fail the ideal waveform. There
   is no host.py anywhere.
3. The cell length now comes from the first line of run_args.txt: a
   waveform drawn with another cell length than the one declared must fail.
4. The RATE line, against the ideal waveform's own list of changes.
5. The hand-in rules: a host.py left in the folder is never loaded, and a
   run_args.txt that is not `cell_cycles=N` plus one line of -config and
   -mode flags is refused.
6. The real pe_sim, once, with a one-instruction program that drives no pin
   (not S/PDIF firmware): the command line and the word file must be
   accepted, and every case must fail cleanly.

Exit status 0 if everything is as expected.

Usage: validate.py [seed]"""
import os
import random
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

seed = sys.argv[1] if len(sys.argv) > 1 else "1"
fake = os.path.join(here, "selftest", "fake_run")
kit = os.path.join(here, "..", "..", "kits2", "spdif")
FLAGS = "-mode 0=pp"

GOOD = [  # (cell, variant): must pass
    (8, "none"), (2, "none"), (3, "none"), (12, "none"), (48, "none"),
    (8, "setup"), (8, "closing"), (2, "closing"), (40, "jitter"), (48, "setup"),
]
BAD = [(8, f) for f in ideal.FAULTS if f != "jitter_big"] + [
    (2, "width"), (2, "bit"), (48, "width"), (40, "jitter_big"), (19, "width_pair"),
]

rng = random.Random(5)
pairs = [(rng.randrange(1 << 24), rng.randrange(1 << 24)) for _ in range(200)]
ok = True


def expect(good, what):
    global ok
    ok &= bool(good)
    print("%-5s %s" % ("ok" if good else "WRONG", what))


def run_accept(run_args, drawn_cell=8, variant=None, fault=None, run_dir=fake):
    """accept.py on a run directory whose run_args.txt holds run_args."""
    with open(os.path.join(run_dir, "run_args.txt"), "w") as f:
        f.write(run_args)
    env = dict(os.environ, SPDIF_CELL=str(drawn_cell))
    env.pop("SPDIF_VARIANT", None)
    env.pop("SPDIF_FAULT", None)
    if variant:
        env["SPDIF_VARIANT"] = variant
    if fault:
        env["SPDIF_FAULT"] = fault
    r = subprocess.run([sys.executable, "-B", os.path.join(here, "accept.py"), run_dir, seed],
                       capture_output=True, text=True, env=env)
    return r, r.stdout.splitlines()


def halves(cell, variant, fault):
    cycles = accept.START_LIMIT + (128 * len(pairs) + 256) * cell
    text = ideal.waveform(pairs, cell, cycles, variant=variant, fault=fault)
    want = accept.expected(pairs)
    direct, stream = accept.direct_check(accept.parse_pins(text), want, cell, cycles)
    with tempfile.TemporaryDirectory() as d:
        sig = accept.sigrok_check(stream, want, cell, d) if stream else ["not run"]
    return direct, sig


sheet = " ".join(open(os.path.join(kit, "TASK.md")).read().split())
expect(accept.tx_words([(0x123456, 0xABCDEF)]) == [0x3456, 0x0012, 0xCDEF, 0x00AB]
       and "0x3456, 0x0012, 0xCDEF, 0x00AB" in sheet,
       "interface: the task sheet's example gives the words printed in the sheet "
       "(0x3456, 0x0012, 0xCDEF, 0x00AB)")
expect(accept.tx_words([(0xFFFFFF, 0), (1, 0x800000)]) == [0xFFFF, 0xFF, 0, 0, 1, 0, 0, 0x80],
       "interface: four words a frame, frames in order, high words hold 8 bits")
print()

print("%-5s %-14s %-12s %-7s %-7s %s" % ("cell", "waveform", "accept.py", "direct", "sigrok", "first complaint"))
for expect_pass, rows in ((True, GOOD), (False, BAD)):
    for cell, name in rows:
        r, lines = run_accept("cell_cycles=%d\n%s\n" % (cell, FLAGS), cell,
                              variant=name if expect_pass else None,
                              fault=None if expect_pass else name)
        cases = [l for l in lines if l.startswith("case ")]
        failed = sum(": FAIL" in l for l in cases)
        rates = [l for l in lines if l.startswith("RATE ")]
        verdict = lines[-1] if lines else "no output"
        consistent = ((verdict == "ACCEPT PASS") == (r.returncode == 0) and len(cases) == 11
                      and len(rates) == (1 if failed < len(cases) else 0)
                      and (not rates or lines[-2] == rates[0]))
        direct, sig = halves(cell, name if expect_pass else "none", "none" if expect_pass else name)
        right = consistent and (r.returncode == 0) == expect_pass
        ok &= right
        first = (direct + sig + [""])[0]
        print("%-5d %-14s %-12s %-7s %-7s %s%s" % (
            cell, name if name != "none" else "ideal",
            "pass" if r.returncode == 0 else "FAIL %d/%d" % (failed, len(cases)),
            "ok" if not direct else "objects", "ok" if not sig else "objects",
            first[:90], "" if right else "   <== JUDGE IS WRONG HERE"))
        if expect_pass and name == "none" and cell in (8, 48):
            # The RATE line, worked out from the ideal waveform's own changes.
            last = accept.make_cases(int(seed))[-1][1]
            cycles = accept.START_LIMIT + (128 * len(last) + 256) * cell
            at = [int(l.split()[1]) for l in ideal.waveform(last, cell, cycles).splitlines()][1:]
            want = "RATE frames=%d cycles=%d" % (len(last), at[-1] - at[0])
            expect(rates == [want], "cell %d: %s, as the ideal waveform's changes give"
                   % (cell, rates[0] if rates else "no RATE line"))
print()

# The declared cell length is what the waveform is judged against.
for declared, drawn in ((8, 9), (9, 8), (8, 16)):
    r, lines = run_accept("cell_cycles=%d\n%s\n" % (declared, FLAGS), drawn)
    cases = [l for l in lines if l.startswith("case ")]
    expect(r.returncode == 1 and lines[-1] == "ACCEPT FAIL" and all(": FAIL" in l for l in cases)
           and len(cases) == 11,
           "cell_cycles=%d declared, ideal waveform drawn with %d: fails every case" % (declared, drawn))

# A host.py in the folder must never be loaded.
marker = os.path.join(fake, "host_was_loaded")
with open(os.path.join(fake, "host.py"), "w") as f:
    f.write("CELL_CYCLES = 9\nopen(%r, 'w').close()\nraise SystemExit('host.py was loaded')\n" % marker)
r, lines = run_accept("cell_cycles=8\n%s\n" % FLAGS, 8)
expect(r.returncode == 0 and lines[-1] == "ACCEPT PASS" and not os.path.exists(marker),
       "a host.py left in the folder is not loaded, and changes nothing")
os.remove(os.path.join(fake, "host.py"))

# run_args.txt: cell_cycles=N, then one line of -config and -mode flags.
for text, good in (("cell_cycles=8\n-mode 0=pp -config clkdiv=1\n", True),
                   ("cell_cycles=8\n-mode 0=pp\n\n", True),
                   ("-mode 0=pp\n", False),
                   ("-mode 0=pp\ncell_cycles=8\n", False),
                   ("cell_cycles=8\n", False),
                   ("cell_cycles=1\n-mode 0=pp\n", False),
                   ("cell_cycles=49\n-mode 0=pp\n", False),
                   ("cell_cycles=8.0\n-mode 0=pp\n", False),
                   ("CELL_CYCLES = 8\n-mode 0=pp\n", False),
                   ("cell_cycles=8\n-mode 0=pp\n-config clkdiv=1\n", False),
                   ("cell_cycles=8\n-mode 0=pp -tx other.txt\n", False),
                   ("cell_cycles=8\n-mode 0=pp -cy 5\n", False),
                   ("cell_cycles=8\n-mode 0=pp -inputs ff\n", False)):
    r, lines = run_accept(text, 8)
    passed = r.returncode == 0 and lines[-1] == "ACCEPT PASS"
    refused = (r.returncode == 1 and len(lines) == 2 and lines[1] == "ACCEPT FAIL"
               and lines[0].startswith("cannot load the hand-in"))
    expect(passed if good else refused,
           "run_args.txt %r: %s" % (text, "accepted" if good else lines[0][25:110]))

# The real simulator, with a program that is not S/PDIF firmware.
d = os.path.join(here, "selftest", "real_pe_sim_idle")
shutil.rmtree(d, ignore_errors=True)
os.makedirs(d)
with open(os.path.join(d, "pe_sim"), "w") as f:
    f.write('#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(kit, "pe_sim")))
os.chmod(os.path.join(d, "pe_sim"), os.stat(os.path.join(d, "pe_sim")).st_mode | stat.S_IXUSR)
with open(os.path.join(d, "spdif.s"), "w") as f:
    f.write("; Not S/PDIF firmware: one instruction that loops on itself and drives no pin.\n"
            "; Only here so the judge is run once against the real pe_sim binary.\n"
            "idle:   jmp idle\n")
r, lines = run_accept("cell_cycles=8\n%s\n" % FLAGS, run_dir=d)
cases = [l for l in lines if l.startswith("case ")]
expect(r.returncode == 1 and lines[-1] == "ACCEPT FAIL" and len(cases) == 11
       and all("FAIL: P0 never changes" in l for l in cases)
       and not any(l.startswith("RATE") for l in lines) and not r.stderr.strip(),
       "real pe_sim, idle program: every case fails cleanly, no RATE line (%s)"
       % (cases[0][:80] if cases else (r.stdout + r.stderr)[:120]))

# Leave the stand-in folder as documented: cell 8, the ideal waveform.
with open(os.path.join(fake, "run_args.txt"), "w") as f:
    f.write("cell_cycles=8\n%s\n" % FLAGS)
print("JUDGE VALIDATED" if ok else "JUDGE NOT VALIDATED")
sys.exit(0 if ok else 1)
