#!/usr/bin/env python3
"""Hidden acceptance test for the blind Miller transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (miller.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. There is no host.py
in round two: the task sheet fixes what the TX words mean, and this test
builds them itself.

For each case (a list of messages, each a list of bytes) the test
  1. builds the TX words the task sheet defines: one word per byte, bits
     7..0 the byte, bit 8 set on the last byte of a message, the rest 0,
  2. runs RUN_DIR/pe_sim on RUN_DIR/miller.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per core clock cycle, 10 MHz),
  4. has sigrok-cli's `miller` decoder (100000 baud, either edge) read it and
     requires the decoded bits to be exactly the wanted messages, in order,
     with nothing extra and no decoder error,
  5. checks, from the pin changes themselves, what the decoder does not:
     P0 high until the first start bit, every transition within +-2 cycles
     of its ideal place counted from its message's first transition, the
     gap between messages, the first start within 2 ms, and silence after
     the last message.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
exit status is 0 only on a full pass. Python standard library and sigrok-cli
only. Written apart from the firmware and kept from its author."""
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

CLOCK_HZ = 10_000_000        # core clock: one cycle = 100 ns
BAUD = 100_000               # bit rate
BIT = CLOCK_HZ // BAUD       # 100 cycles a bit
HALF = BIT // 2              # 50 cycles a half bit
TOL = 2                      # cycles a transition may be from its ideal place
GAP_MIN = 4 * BIT            # silence after an end bit, at least (40 us)
GAP_MAX = 20_000             # and at most (2 ms)
START_MAX = 20_000           # the first start bit begins by this cycle
MAX_BYTES = 32               # bytes in a message, 1 to this
MAX_MESSAGES = 8             # messages in one run
LAST = 0x100                 # bit 8 of a TX word: the last byte of a message
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "tx", "help")  # pe_sim run's
SPLIT = 3 * BIT              # more silence than this between two transitions
                             # ends a message: the decoder's own time-out
PIN = 0                      # P0


# ---------------------------------------------------------------- the code

def frame_bits(message):
    """Start bit, the bytes least significant bit first, end bit."""
    return [0] + [(b >> k) & 1 for b in message for k in range(8)] + [0]


def ideal_offsets(bits):
    """Where the transitions of a message belong, in cycles after its first.

    A 1 has a transition in the middle of the bit. A 0 has one at its start
    if the bit before was a 0, and none otherwise. The start bit begins with
    a transition whatever came before."""
    out = [0]
    for k in range(1, len(bits)):
        if bits[k]:
            out.append(k * BIT + HALF)
        elif not bits[k - 1]:
            out.append(k * BIT)
    return out


# ------------------------------------------------------- the host interface

def tx_words(messages):
    """The TX words of one run, as the task sheet defines them: one word per
    byte in order, the byte in bits 7..0, bit 8 set on the last byte of each
    message, every other bit 0. Payload only: nothing about the line."""
    words = []
    for message in messages:
        for i, byte in enumerate(message):
            words.append(byte | (LAST if i == len(message) - 1 else 0))
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name)."""
    i = 0
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits == ["tx"] or hits == ["cycles"]:
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        i += 2
    return None


# ------------------------------------------------- from pe_sim to a capture

def p0_changes(sim_stdout):
    """[(cycle, level)] of P0 from pe_sim's "pins CYCLE XX" lines: the level
    at the first line, then only the cycles at which it changed."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, level = int(part[1]), (int(part[2], 16) >> PIN) & 1
            if not out or out[-1][1] != level:
                out.append((cycle, level))
    return out


def write_vcd(path, changes, cycles):
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for cycle, level in changes:
            if cycle < cycles:
                f.write("#%d\n%d!\n" % (cycle, level))
        f.write("#%d\n" % cycles)


def sigrok_bitstrings(changes, cycles):
    """What sigrok's miller decoder makes of the capture: one text per
    message (its bits as 0 and 1) or 'ERROR', in order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "miller:baudrate=%d:edge=either:data=P0" % BAUD,
               "-A", "miller=bitstring", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append(m.group(3).replace(" ", ""))
    return found


# ------------------------------------------------------------ the two checks

def where(k):
    """Bit k of a framed message, in words."""
    if k == 0:
        return "the start bit"
    return "bit %d of byte %d" % ((k - 1) % 8, (k - 1) // 8)


def check_decoder(messages, changes, cycles):
    """The decoded bits must be the wanted messages and nothing else."""
    got = sigrok_bitstrings(changes, cycles)
    want = ["".join(str(b) for b in frame_bits(m)) for m in messages]
    errs = []
    if "ERROR" in got:
        errs.append("the decoder reported an error in message %d" % got.index("ERROR"))
    if got == want:
        return errs
    if len(got) != len(want):
        errs.append("decoded %d messages, wanted %d" % (len(got), len(want)))
    for k, (g, w) in enumerate(zip(got, want)):
        if g == w or g == "ERROR":
            continue
        if len(g) != len(w):
            errs.append("message %d decoded as %d bits, wanted %d (start bit, %d data, end bit)"
                        % (k, len(g), len(w), len(w) - 2))
        else:
            i = next(i for i in range(len(w)) if g[i] != w[i])
            what = "the end bit" if i == len(w) - 1 else where(i)
            errs.append("message %d: %s decoded as %s" % (k, what, g[i]))
        break
    return errs or ["decoded messages differ from the wanted ones"]


def check_waveform(messages, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    errs = []
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    if changes[0][1] != 1:
        errs.append("P0 is low at cycle 0: it must be high until the first start bit")
    edges = [c for c, _ in changes[1:]]
    groups = []
    for e in edges:
        if groups and e - groups[-1][-1] <= SPLIT:
            groups[-1].append(e)
        else:
            groups.append([e])
    if len(groups) != len(messages):
        errs.append("%d separate bursts of transitions on P0, wanted %d messages"
                    % (len(groups), len(messages)))
    prev_end = None
    for k, (g, msg) in enumerate(zip(groups, messages)):
        bits = frame_bits(msg)
        want = ideal_offsets(bits)
        got = [e - g[0] for e in g]
        for i, (a, w) in enumerate(zip(got, want)):
            if abs(a - w) > TOL:
                errs.append("message %d: transition %d is %d cycles after the first, ideal %d (limit +-%d)"
                            % (k, i, a, w, TOL))
                break
        else:
            if len(got) != len(want):
                errs.append("message %d: %d transitions, wanted %d" % (k, len(got), len(want)))
        if k == 0:
            if g[0] > START_MAX:
                errs.append("the first start bit begins at cycle %d, limit %d" % (g[0], START_MAX))
        else:
            gap = g[0] - prev_end
            if gap < GAP_MIN:
                errs.append("gap before message %d is %d cycles, at least %d wanted" % (k, gap, GAP_MIN))
            elif gap > GAP_MAX:
                errs.append("gap before message %d is %d cycles, at most %d allowed" % (k, gap, GAP_MAX))
        prev_end = g[0] + len(bits) * BIT
    if groups and len(groups) == len(messages) and cycles - prev_end < GAP_MIN:
        errs.append("the run ended %d cycles after the last end bit, too soon to see the silence"
                    % (cycles - prev_end))
    return errs


def judge(messages, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = p0_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(messages, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(messages, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(messages):
    """Long enough for the latest start and the longest gaps allowed."""
    return START_MAX + sum(len(frame_bits(m)) * BIT + GAP_MAX for m in messages)


def run_case(run_dir, args, messages):
    """(objections, cycles from P0's first change to its last or None)."""
    words = tx_words(messages)
    cycles = run_cycles(messages)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "miller.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    moved = [c for c, _ in p0_changes(out.stdout)[1:]]
    return judge(messages, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def cases_for(seed):
    """(name, messages): fixed cases, then seeded random ones."""
    fixed = [
        ("all zeros", [[0x00]]),
        ("all ones", [[0xFF]]),
        ("the task sheet's example", [[0x16]]),
        ("alternating bits, both orders", [[0x55], [0xAA], [0x01], [0x80]]),
        ("three bytes then two", [[0xDE, 0xAD, 0xBE], [0x00, 0xFF]]),
        ("32 bytes", [[(k * 37 + 11) & 0xFF for k in range(MAX_BYTES)]]),
        ("eight one-byte messages", [[b] for b in (0x00, 0xFF, 0x7F, 0xFE, 0x33, 0xCC, 0x81, 0x18)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, 6)
        longest = MAX_BYTES if n % 2 else 6
        rand.append(("random %d" % n,
                     [[rng.randrange(256) for _ in range(rng.randint(1, longest))]
                      for _ in range(count)]))
    return fixed + rand


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "miller.s", "run_args.txt"):
        if not os.path.exists(os.path.join(run_dir, name)):
            setup.append("%s is missing from %s" % (name, run_dir))
    args = []
    if not setup:
        try:
            with open(os.path.join(run_dir, "run_args.txt")) as f:
                lines = [l for l in f.read().splitlines() if l.strip()]
            if len(lines) > 1:
                setup.append("run_args.txt must be one line")
            args = shlex.split(" ".join(lines))
        except (OSError, ValueError) as e:
            setup.append("run_args.txt: %s" % e)
        problem = args_problem(args)
        if problem:
            setup.append(problem)
    if setup:
        print("setup: FAIL: " + "; ".join(setup))
        print("ACCEPT FAIL")
        return 1
    failed, rate = 0, None
    for n, (name, messages) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, messages)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (sum(len(m) for m in messages), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        size = sum(len(m) for m in messages)
        print("case %d (%s: %d message%s, %d byte%s): %s"
              % (n, name, len(messages), "" if len(messages) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
