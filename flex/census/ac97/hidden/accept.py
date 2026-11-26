#!/usr/bin/env python3
"""Hidden acceptance test for the blind AC '97 controller (output) firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (ac97.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet
fixes what the TX words mean, and this test builds them itself.

For each case (a list of frames) the test
  1. builds the TX words the task sheet defines: four a frame, CTRL, DATA,
     LEFT, RIGHT,
  2. builds the codec's BIT_CLK on P0 as a stimulus file: low until a
     seeded cycle from 200 to 299, then 12.288 MHz on the 50 MHz grid,
     every high phase 2 cycles, every period 4 or 5 cycles, with a seeded
     phase,
  3. runs RUN_DIR/pe_sim on RUN_DIR/ac97.s with those words, that stimulus
     and the flags of run_args.txt (only -config and -mode are allowed),
  4. turns BIT_CLK and the printed changes of SYNC (P1) and SDATA_OUT (P2)
     into a logic capture, one sample per core clock cycle (50 MHz),
  5. has sigrok-cli's `ac97` decoder read it and requires its raw output
     slot values (slot-out-raw) to be exactly the wanted frames' 13 slots
     each, in order, with nothing extra and no decoder error annotation,
  6. checks, from the pin changes themselves, what the decoder does not:
     both lines low by cycle 40; no change of either line in a cycle in
     which BIT_CLK falls (setup and hold); SYNC sampled high at exactly 16
     falling edges per frame, frames back to back every 256 falling edges,
     the first within falling edges 1 to 255; SYNC changing only to begin
     and end those pulses; SDATA_OUT low at every falling edge that does not
     carry a frame bit, before the first frame and after the last.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from the first change of P1 or P2 to the last>
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

CLOCK_HZ = 50_000_000          # core clock: one cycle = 20 ns
BIT_CLK_HZ = 12_288_000        # AC '97 BIT_CLK
PERIOD = CLOCK_HZ / BIT_CLK_HZ # 4.069... cycles
HIGH = 2                       # BIT_CLK high phase, cycles
CLK, SYNC, SDO = 0, 1, 2       # pins
LOW_BY = 40                    # SYNC and SDATA_OUT low from this cycle on
FIRST_MAX = 255                # SYNC first sampled high at falling edge 1..this
FRAME = 256                    # bits a frame
SYNC_BITS = 16                 # falling edges per frame at which SYNC is high
MAX_FRAMES = 12
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's


# ------------------------------------------------------- the host interface

def tx_words(frames):
    """The TX words of one run, as the task sheet defines them. A frame is
    (cmd, reg, data, left, right): cmd is None, 'read' or 'write'.
      CTRL : bit 8 = a command is present, bit 7 = 1 read / 0 write,
             bits 6..0 the register address (even); all 0 without a command
      DATA : the value for a write; 0 for a read and without a command
      LEFT, RIGHT : the 16-bit samples
    Payload only: nothing about the line."""
    words = []
    for cmd, reg, data, left, right in frames:
        if cmd is None:
            ctrl, data = 0, 0
        else:
            ctrl = 0x100 | (0x80 if cmd == "read" else 0) | reg
            if cmd == "read":
                data = 0
        words += [ctrl, data, left, right]
    return words


def slot_values(frame):
    """The 13 slot values sigrok must report for one frame, slot 0 first."""
    cmd, reg, data, left, right = frame
    tag = 0x8000 | (1 << 12) | (1 << 11)          # valid frame, slots 3 and 4 valid
    s1 = s2 = 0
    if cmd is not None:
        tag |= 1 << 14
        s1 = ((1 if cmd == "read" else 0) << 19) | (reg << 12)
    if cmd == "write":
        tag |= 1 << 13
        s2 = data << 4
    return [tag, s1, s2, left << 4, right << 4] + [0] * 8


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name).
    P1 and P2 must be made push-pull, and P0 must stay an input."""
    i, modes = 0, {}
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits and hits[0] in ("tx", "cycles", "stimulus", "inputs") and len(hits) == 1:
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.fullmatch(r"([0-7])=(pp|od|in)", args[i + 1])
            if not m:
                return "run_args.txt: bad -mode value %r" % args[i + 1]
            modes[int(m.group(1))] = m.group(2)
        i += 2
    if modes.get(SYNC) != "pp" or modes.get(SDO) != "pp":
        return "run_args.txt must make P1 (SYNC) and P2 (SDATA_OUT) push-pull"
    if modes.get(CLK, "in") != "in":
        return "run_args.txt must leave P0 (BIT_CLK) an input"
    return None


# ------------------------------------------------------------ the codec clock

def clock(rng, cycles):
    """Rising edges of BIT_CLK: low until R0 (200..299), then rise k at
    R0 + floor(k * PERIOD + phase). Each high phase lasts HIGH cycles."""
    r0 = rng.randrange(200, 300)
    phase = rng.random()
    rises, k = [], 0
    while True:
        r = r0 + int(k * PERIOD + phase)
        if r + HIGH >= cycles:
            return rises
        rises.append(r)
        k += 1


def stimulus_text(rises):
    lines = ["0 00"]
    for r in rises:
        lines += ["%d %02x" % (r, 1 << CLK), "%d 00" % (r + HIGH)]
    return "\n".join(lines) + "\n"


def run_cycles(frames):
    """Long enough for the latest first frame, the frames and one frame time
    of silence after them: the task sheet's N = 400 + 1042 * (F + 2)."""
    return 400 + 1042 * (len(frames) + 2)


# ------------------------------------------------- from pe_sim to a capture

def out_changes(sim_stdout):
    """[(cycle, byte)] from pe_sim's "pins CYCLE XX" lines."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            out.append((int(part[1]), int(part[2], 16)))
    return out


def samples_of(changes, rises, cycles):
    """One byte per cycle: BIT_CLK from the stimulus on bit 0, SYNC and
    SDATA_OUT from the simulator on bits 1 and 2, every other bit 0."""
    level = bytearray(cycles)
    changes = sorted(c for c in changes if 0 <= c[0] < cycles)
    if not changes or changes[0][0] != 0:
        changes.insert(0, (0, 0xFF))    # the output register resets to all ones
    mask = (1 << SYNC) | (1 << SDO)
    for i, (c, v) in enumerate(changes):
        end = changes[i + 1][0] if i + 1 < len(changes) else cycles
        level[c:end] = bytes([v & mask]) * (end - c)
    for r in rises:
        for c in range(r, min(r + HIGH, cycles)):
            level[c] |= 1 << CLK
    return bytes(level)


def sigrok_slots(samples):
    """([(start sample, value)] of every slot-out-raw annotation, error
    annotations as text) or raises."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "capture.bin")
        with open(path, "wb") as f:
            f.write(samples)
        cmd = ["sigrok-cli", "-i", path,
               "-I", "binary:numchannels=8:samplerate=%d" % CLOCK_HZ,
               "-P", "ac97:sync=%d:clk=%d:out=%d" % (SYNC, CLK, SDO),
               "-A", "ac97=slot-out-raw:error:warning", "--protocol-decoder-samplenum"]
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if p.returncode != 0 or p.stderr.strip():
        raise RuntimeError("sigrok-cli failed: " + " ".join(p.stderr.split())[:200])
    slots, errors = [], []
    for line in p.stdout.splitlines():
        m = re.fullmatch(r"(\d+)-(\d+) ac97-\d+: (.*)", line.strip())
        if not m:
            raise RuntimeError("sigrok-cli printed something unexpected: %r" % line[:80])
        text = m.group(3).strip()
        if re.fullmatch(r"[0-9a-fA-F]{4,5}", text):
            slots.append((int(m.group(1)), int(text, 16)))
        else:
            errors.append("%s at sample %s" % (text, m.group(1)))
    return slots, errors


# ------------------------------------------------------------ the two checks

SLOT_NAMES = ["slot 0 (tag)", "slot 1 (command address)", "slot 2 (command data)",
              "slot 3 (left)", "slot 4 (right)"] + ["slot %d" % k for k in range(5, 13)]


def check_decoder(frames, samples):
    """The decoded slots must be the wanted frames' and nothing else."""
    slots, errors = sigrok_slots(samples)
    errs = ["the decoder reported: " + e for e in errors[:2]]
    got = [v for _, v in slots]
    want = [v for fr in frames for v in slot_values(fr)]
    if got == want:
        return errs
    if len(got) != len(want):
        errs.append("decoded %d slots (%d whole frames), wanted %d (%d frames)"
                    % (len(got), len(got) // 13, len(want), len(frames)))
    for i, (g, w) in enumerate(zip(got, want)):
        if g != w:
            errs.append("frame %d %s decoded as 0x%x, wanted 0x%x"
                        % (i // 13, SLOT_NAMES[i % 13], g, w))
            break
    return errs or ["decoded slots differ from the wanted ones"]


def check_pins(frames, changes, samples, rises):
    """The limits of the task sheet that the decoder does not hold to.
    samples: one byte per cycle, as samples_of makes them."""
    errs = []
    level = {SYNC: 1, SDO: 1}
    moves = {SYNC: [], SDO: []}
    for c, v in sorted(changes):
        for pin in (SYNC, SDO):
            b = (v >> pin) & 1
            if b != level[pin] and c > 0:
                moves[pin].append((c, b))
            level[pin] = b

    def at(pin, c):
        return (samples[c] >> pin) & 1

    names = {SYNC: "SYNC", SDO: "SDATA_OUT"}
    for pin in (SYNC, SDO):
        if at(pin, LOW_BY):
            errs.append("%s is not low at cycle %d" % (names[pin], LOW_BY))
    falls = [r + HIGH for r in rises]
    fallset = set(falls)
    for pin in (SYNC, SDO):
        bad = [c for c, _ in moves[pin] if c in fallset]
        if bad:
            errs.append("%s changes in cycle %d, the cycle BIT_CLK falls in (setup and hold)"
                        % (names[pin], bad[0]))
    # Levels the codec samples, one per falling edge.
    sync = [at(SYNC, f) for f in falls]
    sdo = [at(SDO, f) for f in falls]
    try:
        i0 = sync.index(1)
    except ValueError:
        return errs + ["SYNC is never high at a falling edge of BIT_CLK"]
    if i0 < 1 or i0 > FIRST_MAX:
        errs.append("SYNC is first high at falling edge %d, allowed 1 to %d" % (i0, FIRST_MAX))
    n = len(frames)
    if i0 + FRAME * n + 1 > len(falls):
        return errs + ["the run ends before the last frame could finish"]
    want_sync = [0] * len(falls)
    carries = [False] * len(falls)
    for j in range(n):
        s = i0 + FRAME * j
        for k in range(SYNC_BITS):
            want_sync[s + k] = 1
        for k in range(FRAME):
            carries[s + 1 + k] = True
    for i, (g, w) in enumerate(zip(sync, want_sync)):
        if g != w:
            j, k = divmod(i - i0, FRAME)
            errs.append("SYNC is %d at falling edge %d (frame %d, bit time %d of its period), wanted %d"
                        % (g, i, j, k, w))
            break
    for i, (d, c) in enumerate(zip(sdo, carries)):
        if d and not c:
            errs.append("SDATA_OUT is high at falling edge %d, which carries no frame bit" % i)
            break
    if len(moves[SYNC]) != 1 + 2 * n:
        errs.append("SYNC changes %d times, wanted %d (low once at the start, then rise and fall once a frame)"
                    % (len(moves[SYNC]), 1 + 2 * n))
    return errs


def judge(frames, sim_stdout, rises, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = out_changes(sim_stdout)
    samples = samples_of(changes, rises, cycles)
    errs = ["pins: " + e for e in check_pins(frames, changes, samples, rises)]
    errs += ["decoder: " + e for e in check_decoder(frames, samples)]
    return errs


def span(sim_stdout):
    """Cycles from the first change of P1 or P2 to the last, or None."""
    mask = (1 << SYNC) | (1 << SDO)
    moved, last = [], mask          # both high at reset
    for c, v in out_changes(sim_stdout):
        if v & mask != last:
            moved.append(c)
            last = v & mask
    return moved[-1] - moved[0] if moved else None


# ------------------------------------------------------------------ running

def run_case(run_dir, args, frames, rng):
    """(objections, span or None)."""
    words = tx_words(frames)
    cycles = run_cycles(frames)
    rises = clock(rng, cycles)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("0x%04x\n" % w for w in words))
        st = os.path.join(d, "stimulus.txt")
        with open(st, "w") as f:
            f.write(stimulus_text(rises))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "ac97.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    return judge(frames, out.stdout, rises, cycles), span(out.stdout)


def cases_for(seed):
    """(name, frames): fixed cases, then seeded random ones."""
    fixed = [
        ("no command, silence", [(None, 0, 0, 0, 0)]),
        ("the task sheet's example", [("write", 0x02, 0x0808, 0x1234, 0xEDCB),
                                      ("read", 0x7C, 0, 0x7FFF, 0x8000)]),
        ("every bit set", [("write", 0x7E, 0xFFFF, 0xFFFF, 0xFFFF)]),
        ("alternating bits", [("write", 0x2A, 0xAAAA, 0x5555, 0xAAAA),
                              ("read", 0x54, 0, 0xAAAA, 0x5555),
                              (None, 0, 0, 0x5555, 0x5555)]),
        ("twelve frames", [(("write", "read", None)[k % 3], (k * 10) & 0x7E,
                            (0x1111 * k) & 0xFFFF if k % 3 == 0 else 0,
                            (k * 0x1357) & 0xFFFF, (0xFFFF - k * 0x0F0F) & 0xFFFF)
                           for k in range(MAX_FRAMES)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_FRAMES if n % 2 else 4)
        frames = []
        for _ in range(count):
            cmd = rng.choice([None, "read", "write"])
            reg = rng.randrange(0, 128, 2) if cmd else 0
            data = rng.randrange(65536) if cmd == "write" else 0
            frames.append((cmd, reg, data, rng.randrange(65536), rng.randrange(65536)))
        rand.append(("random %d" % n, frames))
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
    for name in ("pe_sim", "ac97.s", "run_args.txt"):
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
    clock_rng = random.Random("clock %d" % seed)
    for n, (name, frames) in enumerate(cases_for(seed)):
        try:
            errs, cyc = run_case(run_dir, args, frames, clock_rng)
        except Exception as e:  # never report a pass because the judge fell over
            errs, cyc = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (8 * len(frames), cyc)
        shown = []
        for kind in ("simulator:", "judge:", "pins:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d frame%s): %s"
              % (n, name, len(frames), "" if len(frames) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%s" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
