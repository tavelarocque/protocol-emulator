#!/usr/bin/env python3
"""Validates accept.py before any firmware exists: no chip firmware involved.

Usage: validate.py [seed ...]        (default seeds 1 2 3)

1. The interface. accept.tx_words must turn the task sheet's own example
   into the words printed in the sheet (KIT/TASK.md).
2. The waveforms. For every variant in ideal.py this builds a run directory
   under selftest/VARIANT/ whose `pe_sim` is ideal.py (a stand-in that
   prints the ideal waveform, or one with a planted fault, for whatever
   transfers accept.py asks for), then runs accept.py on it exactly as it
   would be run on a hand-in. The two good variants must pass every case;
   every bad variant must end in ACCEPT FAIL. The stand-in reads the judge's
   TX words back into transfers by the task sheet's rules, in its own code,
   so a judge that built the words wrongly would fail the good variants.
   For each bad variant it also says which judge objected: sigrok's decoder,
   the direct check, or both.
3. The RATE line, against the ideal waveform's own list of changes.
4. The hand-in rules: a run_args.txt with a flag other than -config and
   -mode is refused, and so is one that leaves P0 to P3 not push-pull.
5. The real pe_sim, once, with a program that does nothing, to prove the
   real simulator's command line, word file and output are handled; that
   run must fail cleanly.
6. The decoder folder is unchanged from its commit (no port was needed)."""
import os
import shutil
import stat
import subprocess
import sys

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import accept  # noqa: E402
import ideal  # noqa: E402

KIT = os.path.join(HERE, "..", "..", "kits", "st7789")
MODES = "-mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp\n"
SHEET_EXAMPLE = ([(0x2A, [0x00, 0x00, 0x00, 0xEF]), (0x29, [])],
                 [0x012A, 0x0000, 0x0000, 0x0000, 0x02EF, 0x0329],
                 "0x012A, 0x0000, 0x0000, 0x0000, 0x02EF, 0x0329")
SELF = os.path.join(HERE, "selftest")


def write(path, text, executable=False):
    with open(path, "w") as f:
        f.write(text)
    if executable:
        os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def make_dir(variant, name=None, run_args=MODES):
    d = os.path.join(SELF, name or variant)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    shutil.copyfile(os.path.join(HERE, "ideal.py"), os.path.join(d, "pe_sim"))
    os.chmod(os.path.join(d, "pe_sim"), 0o755)
    write(os.path.join(d, "variant.txt"), variant + "\n")
    write(os.path.join(d, "run_args.txt"), run_args)
    write(os.path.join(d, "st7789.s"),
          "; Placeholder, not firmware. The stand-in pe_sim in this directory ignores it.\n")
    return d


def run_accept(d, seed):
    env = dict(os.environ, TMPDIR=os.path.join(SELF, "tmp"))
    os.makedirs(env["TMPDIR"], exist_ok=True)
    p = subprocess.run([sys.executable, "-B", os.path.join(HERE, "accept.py"), d, str(seed)],
                       capture_output=True, text=True, env=env)
    lines = p.stdout.strip().splitlines()
    return p.returncode, lines, p.stderr


def which_judge(line):
    """Which of the two judges objected in one failed case line."""
    sig = "sigrok" in line
    direct = "cycle " in line or "framing:" in line
    return "both" if sig and direct else "sigrok" if sig else "direct" if direct else "other"


def main():
    seeds = [int(a) for a in sys.argv[1:]] or [1, 2, 3]
    ok = True

    def expect(good, what):
        nonlocal ok
        ok &= bool(good)
        print("%-5s %s" % ("ok" if good else "WRONG", what))

    transfers, words, text = SHEET_EXAMPLE
    sheet = " ".join(open(os.path.join(KIT, "TASK.md")).read().split())
    expect(accept.tx_words(transfers) == words and text in sheet,
           "interface: the task sheet's example gives the words printed in the sheet (%s)" % text)
    expect(accept.tx_words([(0x11, [])]) == [0x311]
           and accept.tx_words([(0x2C, [1, 2, 3])]) == [0x12C, 1, 2, 0x203],
           "interface: a lone command has bits 8 and 9 set; bit 9 only on a transfer's last byte")
    for phrase in ("The host sends only the words defined above.",
                   "All line coding, framing and timing must be done by the firmware.",
                   "100 cycles per byte", "plus 2000 cycles", "0 to 1000 data bytes", "50 MHz"):
        expect(phrase in sheet, "the task sheet says %r" % phrase)

    tally = {"good": 0, "bad": 0}
    for variant, what in ideal.VARIANTS.items():
        d = make_dir(variant)
        for seed in seeds:
            rc, lines, stderr = run_accept(d, seed)
            cases = [l for l in lines if l.startswith("case ")]
            failed = [l for l in cases if "): FAIL" in l]
            rates = [l for l in lines if l.startswith("RATE ")]
            verdict = lines[-1] if lines else "(no output) " + stderr[-200:]
            good = variant.startswith("good")
            right = (rc == 0 and verdict == "ACCEPT PASS" and not failed) if good else \
                    (rc != 0 and verdict == "ACCEPT FAIL" and failed)
            right = right and len(rates) == (1 if len(failed) < len(cases) else 0) \
                and (not rates or lines[-2] == rates[0]) and not stderr.strip()
            ok &= bool(right)
            if right:
                tally["good" if good else "bad"] += 1
            judges = sorted({which_judge(l) for l in failed})
            print("%-16s seed %d: %s, %d of %d cases failed, exit %d%s  -> %s"
                  % (variant, seed, verdict, len(failed), len(cases), rc,
                     ", caught by " + "/".join(judges) if failed else "",
                     "as expected" if right else "WRONG"))
            if seed == seeds[0]:
                print("    (%s)" % what)
                if failed:
                    print("    first: " + failed[0][:240])
            if stderr.strip():
                print("    stderr: " + stderr.strip()[-300:])
            if variant == "good":
                # The RATE line, worked out from the ideal waveform's own changes.
                last = accept.make_cases(seed)[-1][1]
                ch = ideal.waveform(last, "good", accept.budget(last))
                want = "RATE bytes=%d cycles=%d" % (sum(1 + len(x) for _, x in last),
                                                    ch[-1][0] - ch[1][0])
                expect(rates == [want], "seed %d: %s, as the ideal waveform's changes give"
                       % (seed, rates[0] if rates else "no RATE line"))
    print("verdicts as expected: %d good runs passed, %d bad runs failed"
          % (tally["good"], tally["bad"]))

    # run_args.txt: only -config and -mode, on one line, P0..P3 push-pull.
    arg_cases = [(" -config clkdiv=1", True), (" -tx other.txt", False),
                 (" -t other.txt", False), (" -cycles 5", False),
                 (" -inputs 0xff", False), (" -stimulus s.txt", False),
                 ("\n-config clkdiv=1", False)]
    for n, (extra, good) in enumerate(arg_cases):
        d = make_dir("good", name="args%d" % n, run_args=MODES.strip() + extra + "\n")
        rc, lines, stderr = run_accept(d, seeds[0])
        passed = rc == 0 and lines[-1] == "ACCEPT PASS"
        refused = rc == 1 and lines[-1] == "ACCEPT FAIL" and all("run_args.txt" in l for l in lines[:-1])
        expect(passed if good else refused, "run_args.txt with %r: %s"
               % (extra, "accepted" if good else lines[0][lines[0].find("FAIL"):][:90]))
    d = make_dir("good", name="args_od", run_args="-mode 0=pp -mode 1=pp -mode 2=pp -mode 3=od\n")
    rc, lines, stderr = run_accept(d, seeds[0])
    expect(rc == 1 and all("P3 (CSX) is not made push-pull" in l for l in lines[:-1]),
           "run_args.txt with P3 open-drain is refused")
    for name in ["args%d" % n for n in range(len(arg_cases))] + ["args_od"]:
        shutil.rmtree(os.path.join(SELF, name), ignore_errors=True)

    # The real simulator, with a program that drives nothing.
    d = os.path.join(SELF, "real_pe_sim_idle")
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    write(os.path.join(d, "pe_sim"),
          '#!/bin/sh\nexec "%s" "$@"\n' % os.path.abspath(os.path.join(KIT, "pe_sim")), executable=True)
    write(os.path.join(d, "run_args.txt"), MODES)
    write(os.path.join(d, "st7789.s"),
          "; Not ST7789 firmware: one instruction that loops on itself and drives no pin.\n"
          "; Only here so the judge is run once against the real pe_sim binary.\n"
          "idle:   jmp idle\n")
    rc, lines, stderr = run_accept(d, seeds[0])
    failed = [l for l in lines if "): FAIL" in l]
    right = rc != 0 and lines and lines[-1] == "ACCEPT FAIL" and len(failed) == len(lines) - 1 \
        and all("sigrok decoded 0 bytes" in l for l in failed) and not stderr.strip()
    ok &= bool(right)
    print("real pe_sim, idle program: %s, %d cases failed, no RATE line, exit %d -> %s"
          % (lines[-1] if lines else "(no output)", len(failed), rc,
             "as expected" if right else "WRONG"))
    if failed:
        print("    first: " + failed[0][:240])
    if stderr.strip():
        print("    stderr: " + stderr.strip()[-300:])

    # The decoder ran as committed: no port.
    p = subprocess.run(["git", "-C", accept.DECODERS, "diff", "--stat", "--", "st7789"],
                       capture_output=True, text=True)
    expect(p.returncode == 0 and not p.stdout.strip(),
           "the st7789 decoder folder has no change against its commit (no port)")

    shutil.rmtree(os.path.join(SELF, "tmp"), ignore_errors=True)
    print("VALIDATION OK" if ok else "VALIDATION WRONG")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
