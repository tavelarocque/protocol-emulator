#!/usr/bin/env python3
"""Hidden acceptance test for the blind AVR PDI programmer firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (avr_pdi.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. There is no host
code: the task sheet fixes what the TX and RX words mean, and this test
builds the TX words and the device's scripted replies itself.

The chip is a PDI programmer (role: both directions). It drives PDI_CLK on
P0 (push-pull) and PDI_DATA on P1 (open-drain, pulled up); a scripted
ATxmega answers on P1 at the slots the task sheet's fixed schedule gives.

For each case (a PDI session: a list of instructions, each a list of bytes
the programmer sends and the bytes the device answers) the test
  1. builds the TX words of the sheet: one word per byte sent, bits 7..0
     the byte, bits 11..8 the number of bytes the device answers after
     this byte (0 to 15), then the end word 0x8000;
  2. builds the stimulus: the device's frames on P1, each level change 5
     cycles after the ideal falling edge of PDI_CLK that starts its slot;
  3. has sigrok-cli's `avr_pdi` decoder read an IDEAL capture of the whole
     session (ideal clock, ideal programmer frames, the stimulus) and
     requires every byte, both directions, so the stimulus is real PDI on
     the sheet's schedule;
  4. runs RUN_DIR/pe_sim with the words, the stimulus and run_args.txt;
  5. turns the printed pin changes into a capture (P0 as driven, P1 as the
     wired-AND of the chip's open-drain output and the device), has the
     decoder read it and requires exactly the session's bytes, in order,
     with no parity error, stop bit error or BREAK;
  6. checks from the pin changes what the decoder does not: every PDI_CLK
     edge within +-2 cycles of its place on the fixed schedule, nothing
     before or after it, every change of the chip's P1 output inside the
     low half of a clock period (from the falling edge to 5 cycles before
     the rising edge), the chip's P1 level at every rising edge equal to
     the schedule's (released whenever the chip does not own the slot),
     no P1 change at all in a slot whose bit the chip does not send (in its
     own slots P1 may change more than once in the window), and P2..P7
     untouched;
  7. requires the "rx" words to be the device's bytes, one word each, in
     order, bits 15..8 zero, nothing extra.

Prints one line per case, then, for the last case that passed,
    RATE bytes=<bytes both ways> cycles=<cycles from first to last pin change>
and a last line, ACCEPT PASS or ACCEPT FAIL. Exit status 0 only on a full
pass. Python standard library and sigrok-cli only."""
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

CLOCK_HZ = 50_000_000        # core clock: one cycle = 20 ns
SLOT = 50                    # PDI_CLK period (1 MHz) in cycles: one bit slot
HIGH_AT = 25                 # rising edge, cycles after the slot's falling edge
T0 = 2000                    # ideal falling edge of slot 0
TOL = 2                      # cycles a PDI_CLK edge may be off its place
SETUP = 5                    # P1 changes at least this many cycles before a rise
DEV_DELAY = 5                # the device changes P1 this long after a falling edge
ENABLE_IDLE = 16             # idle slots before the first frame
GUARD = 128                  # idle slots between a request and the device's answer
AFTER_REPLY = 2              # idle slots between the answer and the next frame
END_IDLE = 16                # idle slots after the last transaction
TAIL = 3000                  # cycles the run goes on after the last slot
END_WORD = 0x8000
MAX_REPLY = 15
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "tx", "stimulus", "help")
CLK, DAT = 0, 1              # P0 = RESET/PDI_CLK, P1 = PDI_DATA
KEY = [0xFF, 0x88, 0xD8, 0xCD, 0x45, 0xAB, 0x89, 0x12]  # NVM key, sent in this order


# ------------------------------------------------------------ the framing

def frame(byte):
    """Start 0, eight data bits least significant first, even parity, two stop bits."""
    data = [(byte >> k) & 1 for k in range(8)]
    return [0] + data + [sum(data) & 1, 1, 1]


def schedule(session):
    """The session's slots in order, as (who, level) per slot: who is 'idle',
    'prog' (the chip drives that level) or 'dev' (the device does)."""
    slots = [("idle", 1)] * ENABLE_IDLE
    for sent, answer in session:
        for b in sent:
            slots += [("prog", v) for v in frame(b)]
        if answer:
            slots += [("idle", 1)] * GUARD
            for b in answer:
                slots += [("dev", v) for v in frame(b)]
            slots += [("idle", 1)] * AFTER_REPLY
    slots += [("idle", 1)] * END_IDLE
    return slots


def fall(k):
    return T0 + SLOT * k


def rise(k):
    return T0 + SLOT * k + HIGH_AT


def stream(session):
    """Every byte on the line, both directions, in order."""
    out = []
    for sent, answer in session:
        out += list(sent) + list(answer)
    return out


# ------------------------------------------------------- the host interface

def tx_words(session):
    """The sheet's TX words: one per byte sent, bits 11..8 the number of bytes
    the device answers after it, then the end word."""
    words = []
    for sent, answer in session:
        for i, b in enumerate(sent):
            n = len(answer) if i == len(sent) - 1 else 0
            words.append(b | (n << 8))
    return words + [END_WORD]


def stimulus(session):
    """[(cycle, hex)] for pe_sim's -stimulus: the device's levels on P1."""
    out, level = [(0, 0xFF)], 1
    for k, (who, v) in enumerate(schedule(session)):
        want = v if who == "dev" else 1
        if want != level:
            out.append((fall(k) + DEV_DELAY, 0xFF if want else 0xFF & ~(1 << DAT)))
            level = want
    return out


def device_level(stim, cycle):
    level = 1
    for c, v in stim:
        if c > cycle:
            break
        level = (v >> DAT) & 1
    return level


def run_cycles(session):
    return rise(len(schedule(session)) - 1) + SLOT - HIGH_AT + TAIL


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else; it must make P0 push-pull and P1 open-drain."""
    modes = {}
    i = 0
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) == 1 and hits[0] in ("tx", "cycles", "stimulus", "inputs"):
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.fullmatch(r"(\d+)=(pp|od|in)", args[i + 1])
            if m:
                modes[int(m.group(1))] = m.group(2)
        i += 2
    if modes.get(CLK) != "pp":
        return "run_args.txt must make P0 (PDI_CLK) push-pull: -mode 0=pp"
    if modes.get(DAT) != "od":
        return "run_args.txt must make P1 (PDI_DATA) open-drain: -mode 1=od"
    return None


# ------------------------------------------------- from pe_sim to a capture

def parse_sim(text):
    """([(cycle, pins byte)], [(cycle, word)]) from pe_sim's output."""
    pins, rx = [], []
    for line in text.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            pins.append((int(part[1]), int(part[2], 16)))
        elif len(part) == 3 and part[0] == "rx":
            rx.append((int(part[1]), int(part[2], 0)))
    return pins, rx


def bit_changes(pins, bit):
    out = []
    for c, v in pins:
        level = (v >> bit) & 1
        if not out or out[-1][1] != level:
            out.append((c, level))
    return out


def level_at(changes, cycle, default=1):
    level = default
    for c, v in changes:
        if c > cycle:
            break
        level = v
    return level


def line_changes(clk, chip_dat, stim):
    """Capture events: [(cycle, clk, data line)] at every cycle either moves.
    The data line is the wired-AND of the chip's output and the device."""
    cycles = sorted({c for c, _ in clk} | {c for c, _ in chip_dat} | {c for c, _ in stim} | {0})
    out = []
    for c in cycles:
        out.append((c, level_at(clk, c), level_at(chip_dat, c) & device_level(stim, c)))
    return out


def write_vcd(path, events, end):
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$var wire 1 \" P1 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        last = (None, None)
        for c, k, d in events:
            if c >= end:
                break
            if (k, d) == last:
                continue
            f.write("#%d\n" % c)
            if k != last[0]:
                f.write("%d!\n" % k)
            if d != last[1]:
                f.write("%d\"\n" % d)
            last = (k, d)
        f.write("#%d\n" % end)


def sigrok(events, end):
    """(bytes the decoder passes on, [problem annotations], frames seen)."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "pdi.vcd")
        write_vcd(path, events, end)
        base = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", "avr_pdi:reset=P0:data=P1"]
        b = subprocess.run(base + ["-B", "avr_pdi=bytes"], capture_output=True, timeout=300)
        a = subprocess.run(base + ["-A", "avr_pdi=uart_fields", "--protocol-decoder-samplenum"],
                           capture_output=True, text=True, timeout=300)
    for r in (b, a):
        if r.returncode != 0:
            err = r.stderr if isinstance(r.stderr, str) else r.stderr.decode(errors="replace")
            raise RuntimeError("sigrok-cli failed: " + err.strip()[:200])
    problems, frames = [], 0
    for line in a.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if not m:
            continue
        text = m.group(3)
        if text.startswith("Data: "):
            frames += 1
        if text in ("Parity error", "Stop bit error", "Break condition"):
            problems.append("%s at cycle %s" % (text.lower(), m.group(1)))
    return list(b.stdout), problems, frames


def ideal_events(session, stim):
    """The capture an ideal programmer gives: for checking the stimulus."""
    slots = schedule(session)
    chip = [(0, 1)]
    for k, (who, v) in enumerate(slots):
        want = v if who == "prog" else 1
        if want != chip[-1][1]:
            chip.append((fall(k), want))
    clk = [(0, 1)]
    for k in range(len(slots)):
        clk += [(fall(k), 0), (rise(k), 1)]
    return line_changes(clk, chip, stim)


# ------------------------------------------------------------ the checks

def check_decoder(session, events, end):
    got, problems, frames = sigrok(events, end)
    want = stream(session)
    errs = ["the decoder reports a " + p for p in problems[:2]]
    if frames != len(want):
        errs.append("the decoder saw %d frames, wanted %d" % (frames, len(want)))
    if got != want:
        if len(got) != len(want):
            errs.append("decoded %d bytes, wanted %d" % (len(got), len(want)))
        for i, (g, w) in enumerate(zip(got, want)):
            if g != w:
                errs.append("byte %d decoded as 0x%02x, wanted 0x%02x" % (i, g, w))
                break
        if not errs:
            errs.append("decoded bytes differ from the session's")
    return errs


def check_waveform(session, pins, end):
    """The schedule's limits the decoder does not hold to."""
    errs = []
    if not pins or pins[0][0] != 0:
        return ["no pin levels at cycle 0 in the simulator's output"]
    slots = schedule(session)
    clk = bit_changes(pins, CLK)
    dat = bit_changes(pins, DAT)
    for c, v in pins:
        if v & 0xFC != 0xFC:
            errs.append("P2..P7 written at cycle %d (pins %02x): leave them alone" % (c, v))
            break
    # PDI_CLK
    if clk[0][1] != 1:
        errs.append("P0 is low at cycle 0: PDI_CLK must be high until cycle %d" % T0)
    edges = clk[1:]
    want = []
    for k in range(len(slots)):
        want += [(fall(k), 0), (rise(k), 1)]
    actual_fall, actual_rise = [], []
    for i, ((c, v), (w, wv)) in enumerate(zip(edges, want)):
        k = i // 2
        if abs(c - w) > TOL:
            errs.append("PDI_CLK %s edge of slot %d at cycle %d, ideal %d (limit +-%d)"
                        % ("falling" if wv == 0 else "rising", k, c, w, TOL))
            break
        (actual_fall if wv == 0 else actual_rise).append(c)
    else:
        if len(edges) != len(want):
            errs.append("PDI_CLK has %d edges, the schedule %d (%d slots)" % (len(edges), len(want), len(slots)))
    if errs:
        return errs
    # PDI_DATA, as the chip drives it
    if dat[0][1] != 1:
        errs.append("P1 driven low at cycle 0: it must be released until the first frame")
    for c, v in dat[1:]:
        ok = any(f <= c <= r - SETUP for f, r in zip(actual_fall, actual_rise))
        if not ok:
            errs.append("P1 changes at cycle %d, outside the low half of a PDI_CLK period "
                        "(falling edge to %d cycles before the rising edge)" % (c, SETUP))
            break
    for k, (who, v) in enumerate(slots):
        expect = v if who == "prog" else 1
        got = level_at(dat, actual_rise[k])
        if got != expect:
            what = {"prog": "a bit the chip sends", "dev": "a bit the device sends",
                    "idle": "an idle slot"}[who]
            errs.append("slot %d (%s): the chip's P1 is %d at the rising edge, wanted %s"
                        % (k, what, got, "%d" % expect if who == "prog" else "1 (released)"))
            break
    for c, v in dat[1:]:
        k = next((k for k, (f, r) in enumerate(zip(actual_fall, actual_rise)) if f <= c <= r - SETUP), None)
        if k is not None and slots[k][0] != "prog":
            errs.append("P1 changes at cycle %d, in slot %d, whose bit the chip does not send"
                        % (c, k))
            break
    return errs


def check_rx(session, rx):
    want = [b for _, answer in session for b in answer]
    got = [w for _, w in rx]
    errs = []
    if any(w > 0xFF for w in got):
        w = next(w for w in got if w > 0xFF)
        errs.append("rx word 0x%04x has bits 15..8 set" % w)
    if got != want:
        if len(got) != len(want):
            errs.append("%d rx words, wanted %d" % (len(got), len(want)))
        for i, (g, w) in enumerate(zip(got, want)):
            if g != w:
                errs.append("rx word %d is 0x%04x, wanted 0x%04x" % (i, g, w))
                break
    return errs


def judge(session, sim_stdout, stim, end):
    pins, rx = parse_sim(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(session, pins, end)]
    if pins and pins[0][0] == 0:
        events = line_changes(bit_changes(pins, CLK), bit_changes(pins, DAT), stim)
        errs += ["decoder: " + e for e in check_decoder(session, events, end)]
    errs += ["rx: " + e for e in check_rx(session, rx)]
    return errs, pins


# ------------------------------------------------------------------ running

def run_case(run_dir, args, session):
    words = tx_words(session)
    stim = stimulus(session)
    end = run_cycles(session)
    # The stimulus must itself be PDI on the sheet's schedule.
    bad = check_decoder(session, ideal_events(session, stim), end)
    if bad:
        return ["judge: the scripted device is not decoded as the session: " + bad[0]], None
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        st = os.path.join(d, "stimulus.txt")
        with open(tx, "w") as f:
            f.write("".join("0x%04x\n" % w for w in words))
        with open(st, "w") as f:
            f.write("".join("%d %02x\n" % (c, v) for c, v in stim))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "avr_pdi.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(end)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    errs, pins = judge(session, out.stdout, stim, end)
    moved = [c for c, _ in pins[1:]] if pins else []
    return errs, (moved[-1] - moved[0] if moved else None)


# ------------------------------------------------------------------ sessions

def ins_lds(addr, m, answer):
    a = len(addr)
    return ([0x00 | (a - 1) << 2 | (m - 1)] + addr, answer)


def ins_sts(addr, data):
    return ([0x40 | (len(addr) - 1) << 2 | (len(data) - 1)] + addr + data, [])


def ins_ldcs(reg, answer):
    return ([0x80 | reg], [answer])


def ins_stcs(reg, value):
    return ([0xC0 | reg, value], [])


def ins_key():
    return ([0xE0] + KEY, [])


def ins_st_ptr(addr):
    return ([0x68 | (len(addr) - 1)] + addr, [])


def ins_repeat(count_bytes):
    return ([0xA0 | (len(count_bytes) - 1)] + count_bytes, [])


def ins_ld_inc(m, answer):
    return ([0x24 | (m - 1)], answer)


def ins_st_inc(m, data):
    return ([0x64 | (m - 1)] + data, [])


def random_session(rng, length):
    """A plausible PDI session: valid instructions, answers the right size.
    Never writes the CTRL register, so the guard time stays 128 bits."""
    rb = lambda n: [rng.randrange(256) for _ in range(n)]
    out = []
    for _ in range(length):
        kind = rng.choice(["lds", "sts", "ldcs", "stcs", "key", "block_read", "block_write"])
        if kind == "lds":
            m = rng.randint(1, 4)
            out.append(ins_lds(rb(rng.randint(1, 4)), m, rb(m)))
        elif kind == "sts":
            out.append(ins_sts(rb(rng.randint(1, 4)), rb(rng.randint(1, 4))))
        elif kind == "ldcs":
            out.append(ins_ldcs(rng.choice([0, 1, 2]), rng.randrange(256)))
        elif kind == "stcs":
            out.append(ins_stcs(rng.choice([0, 1]), rng.randrange(256)))
        elif kind == "key":
            out.append(ins_key())
        elif kind == "block_read":
            m = rng.choice([1, 1, 2, 3])
            reps = rng.randint(1, MAX_REPLY // m)
            out.append(ins_st_ptr(rb(4)))
            if reps > 1:
                out.append(ins_repeat([reps - 1]))
            out.append(ins_ld_inc(m, rb(m * reps)))
        else:
            m = rng.choice([1, 2])
            reps = rng.randint(1, 6)
            out.append(ins_st_ptr(rb(4)))
            if reps > 1:
                out.append(ins_repeat([reps - 1]))
            out.append(ins_st_inc(m, rb(m * reps)))
    if not any(answer for _, answer in out):
        out.append(ins_ldcs(0, rng.randrange(256)))
    return out


def cases_for(seed):
    fixed = [
        ("the task sheet's example", [ins_ldcs(0, 0x02), ins_stcs(1, 0x59)]),
        ("enable and end, nothing sent", []),
        ("key, then status read twice", [ins_key(), ins_ldcs(0, 0x00), ins_ldcs(0, 0xFF)]),
        ("all-zero and all-one bytes both ways",
         [ins_sts([0x00, 0x00, 0x00, 0x00], [0x00]), ins_sts([0xFF, 0xFF], [0xFF, 0xFF]),
          ins_lds([0x00, 0x00, 0x00, 0x01], 2, [0x00, 0xFF])]),
        ("a 15-byte block read", [ins_st_ptr([0x00, 0x00, 0x80, 0x00]), ins_repeat([14]),
                                  ins_ld_inc(1, [(k * 29 + 7) & 0xFF for k in range(15)])]),
        ("two reads back to back, 4-byte answer", [ins_lds([0x24, 0x00, 0x00, 0x01], 4, [0x1E, 0x97, 0x4C, 0x55]),
                                                   ins_ldcs(2, 0x06)]),
    ]
    rng = random.Random(seed)
    rand = [("random %d" % n, random_session(rng, rng.randint(1, 6))) for n in range(8)]
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
    for name in ("pe_sim", "avr_pdi.s", "run_args.txt"):
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
    for n, (name, session) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, session)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (len(stream(session)), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d instruction%s, %d bytes out, %d back): %s"
              % (n, name, len(session), "" if len(session) == 1 else "s",
                 sum(len(s) for s, _ in session), sum(len(a) for _, a in session), status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
