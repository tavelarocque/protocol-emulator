#!/usr/bin/env python3
"""Hidden acceptance test for the blind IEC (Commodore serial bus) firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (iec.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim.

The chip is the bus controller and talker (the computer's side of the bus).
A scripted listener (a printer or drive) answers on DATA at times the test
draws in advance, within the ranges the task sheet gives. For each case (a
list of transactions, each a device number, a secondary address and 1 to 16
data bytes) the test
  1. builds the TX words the task sheet defines: a header word (device in
     bits 4..0, secondary address in bits 11..8), then one word per data
     byte (bits 7..0, bit 8 set on the last byte),
  2. draws the listener's timeline and writes it as a -stimulus file (the
     listener drives DATA, P0, only),
  3. runs RUN_DIR/pe_sim on RUN_DIR/iec.s with those words and that stimulus,
  4. builds the bus as it would be on the wires (DATA is the AND of the
     chip's P0 and the listener's DATA; CLK is P1, ATN is P2), writes it as
     a VCD at one sample per core clock cycle (1 MHz), and has sigrok-cli's
     `iec` decoder read it: the decoded bytes must be, in order and with
     nothing extra, LISTEN, SECOND, the data bytes and UNLISTEN of every
     transaction, the commands under ATN and the data not, with EOI on the
     last data byte of each transaction and on no other byte,
  5. checks, from the chip's own pin changes, every timing limit of the task
     sheet, each measured from the listener event it answers.

Prints one line per case, then for the last case that passed
    RATE bytes=<data bytes> cycles=<cycles from the chip's first pin change to its last>
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

CLOCK_HZ = 1_000_000           # core clock: one cycle = 1 us
DATA, CLK, ATN = 0, 1, 2       # pins
LISTEN, SECOND, UNLISTEN = 0x20, 0x60, 0x3F
LAST = 0x100                   # bit 8 of a data word: last byte, send with EOI
MAX_DATA = 16                  # data bytes in a transaction, 1 to this
MAX_TRANS = 4                  # transactions in a run, 1 to this
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")

# The chip's limits, in cycles after the event named.
ATN_START = (100, 400)   # ATN pulled low, after the bus went free
CLK_START = (0, 20)      # CLK pulled low, after the chip pulled ATN low
READY = (100, 400)       # CLK released (ready to send), after the listener pulled DATA low
NO_EOI = (0, 200)        # first CLK fall of a byte, after the listener released DATA
AFTER_EOI = (0, 60)      # first CLK fall of the last byte, after the listener's EOI pulse ended
PERIOD = (40, 100)       # from one CLK fall to the next, during the 8 bits
LOW_MIN = 20             # CLK low before each rise, at least
HIGH_MIN = 20            # CLK high for each bit, at least (Tv)
SETUP = 20               # DATA unchanged for at least this long before each CLK rise (Ts)
RELEASE = 20             # DATA released at most this long after the 8th CLK fall
TURN = (20, 90)          # ATN changes, and CLK's release after UNLISTEN, after a byte's acknowledge

# The listener's ranges, in cycles after the event named (drawn per event).
DEV_ATN = (450, 950)     # pulls DATA low, after the bus went free
DEV_RFD = (450, 950)     # releases DATA (ready for data), after it pulled DATA low
DEV_EOI_AT = (250, 350)  # starts the EOI pulse, after it released DATA
DEV_EOI_LEN = (80, 120)  # EOI pulse length
DEV_ACK = (1050, 1320)   # pulls DATA low (frame acknowledge), after it released DATA
DEV_ACK_EOI = (910, 1320)  # the same for the last byte, after the EOI pulse ended
DEV_FREE = (150, 250)    # releases DATA (bus free), after acknowledging UNLISTEN
TAIL = 2000              # cycles the run goes on after the bus went free the last time


# ------------------------------------------------------- the host interface

def tx_words(transactions):
    """The TX words as the task sheet defines them. Payload only."""
    words = []
    for dev, sa, data in transactions:
        words.append(dev | (sa << 8))
        for i, b in enumerate(data):
            words.append(b | (LAST if i == len(data) - 1 else 0))
    return words


def bus_bytes(transactions):
    """[(byte, under ATN, EOI)] that must appear on the bus, in order."""
    out = []
    for dev, sa, data in transactions:
        out.append((LISTEN | dev, True, False))
        out.append((SECOND | sa, True, False))
        for i, b in enumerate(data):
            out.append((b, False, i == len(data) - 1))
        out.append((UNLISTEN, True, False))
    return out


# ------------------------------------------------------------ the listener

def plan(transactions, pick):
    """The listener's timeline. pick(lo, hi) chooses each delay.

    Returns (events, trans) where events is [(cycle, DATA level)] and trans
    holds, per transaction, the free time E before it and per byte the
    listener's times K (DATA low before it), R (DATA released), eoi
    (start, end) or None, and ack."""
    events, trans = [], []
    t = 0  # the bus is free from cycle 0
    for dev, sa, data in transactions:
        tr = {"E": t, "bytes": []}
        k = t + pick(*DEV_ATN)
        events.append((k, 0))
        tr["A"] = k
        seq = [False, False] + [i == len(data) - 1 for i in range(len(data))] + [False]
        for eoi in seq:
            by = {"K": k}
            r = k + pick(*DEV_RFD)
            events.append((r, 1))
            by["R"] = r
            if eoi:
                p0 = r + pick(*DEV_EOI_AT)
                p1 = p0 + pick(*DEV_EOI_LEN)
                events += [(p0, 0), (p1, 1)]
                by["eoi"] = (p0, p1)
                k = p1 + pick(*DEV_ACK_EOI)
            else:
                by["eoi"] = None
                k = r + pick(*DEV_ACK)
            events.append((k, 0))
            by["ack"] = k
            tr["bytes"].append(by)
        t = k + pick(*DEV_FREE)
        events.append((t, 1))
        tr["free"] = t
        trans.append(tr)
    return events, trans


def stimulus_text(events):
    lines = ["0 ff"]
    for c, level in events:
        lines.append("%d %02x" % (c, 0xFE | level))
    return "\n".join(lines) + "\n"


def run_cycles(trans):
    return trans[-1]["free"] + TAIL


# ------------------------------------------------- from pe_sim to the bus

def chip_changes(sim_stdout):
    """{pin: [(cycle, level)]}: the level at the first "pins" line, then
    every change, of the chip's own output on P0, P1, P2."""
    out = {DATA: [], CLK: [], ATN: []}
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, v = int(part[1]), int(part[2], 16)
            for p in out:
                level = (v >> p) & 1
                if not out[p] or out[p][-1][1] != level:
                    out[p].append((cycle, level))
    return out


def level_at(changes, cycle):
    lv = 1
    for c, l in changes:
        if c > cycle:
            break
        lv = l
    return lv


def bus(chip, events):
    """{name: [(cycle, level)]} of the three wires: DATA is wired-AND."""
    dev = [(0, 1)] + list(events)
    times = sorted({c for c, _ in chip[DATA]} | {c for c, _ in dev})
    data = []
    for c in times:
        lv = level_at(chip[DATA], c) & level_at(dev, c)
        if not data or data[-1][1] != lv:
            data.append((c, lv))
    return {"DATA": data, "CLK": list(chip[CLK]), "ATN": list(chip[ATN])}


def write_vcd(path, wires, cycles):
    ids = {"DATA": "!", "CLK": '"', "ATN": "#"}
    by_time = {}
    for name, ch in wires.items():
        for c, lv in ch:
            if c < cycles:
                by_time.setdefault(c, []).append("%d%s" % (lv, ids[name]))
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module bus $end\n")
        for name in ("DATA", "CLK", "ATN"):
            f.write("$var wire 1 %s %s $end\n" % (ids[name], name))
        f.write("$upscope $end\n$enddefinitions $end\n")
        for c in sorted(by_time):
            f.write("#%d\n%s\n" % (c, "\n".join(by_time[c])))
        f.write("#%d\n" % cycles)


def sigrok_items(wires, cycles):
    """[(ss, byte text, gpib text, eoi text)] as sigrok's iec decoder gives."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "bus.vcd")
        write_vcd(path, wires, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "iec:data=DATA:clk=CLK:atn=ATN",
               "-A", "iec", "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if out.returncode != 0:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    groups = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)$", line)
        if not m:
            continue
        key = (int(m.group(1)), int(m.group(2)))
        if groups and groups[-1][0] == key:
            groups[-1][1].append(m.group(3))
        else:
            groups.append((key, [m.group(3)]))
    items = []
    for (ss, _), texts in groups:
        texts = texts + [""] * (3 - len(texts))
        items.append((ss, texts[0].strip(), texts[1], texts[2].strip()))
    return items


def gpib_text(byte, atn):
    """What the decoder's DAT/CMD row says for a byte (its own table)."""
    s = " "
    if atn:
        named = {0x01: "GTL", 0x04: "SDC", 0x05: "PPC", 0x08: "GET", 0x09: "TCT",
                 0x11: "LLO", 0x14: "DCL", 0x15: "PPU", 0x18: "SPE", 0x19: "SPD",
                 0x3F: "UNL", 0x5F: "UNT"}
        s = named.get(byte, s)
        if 0x1F < byte < 0x3F:
            s = "L" + chr(byte + 0x10)
        if 0x3F < byte < 0x5F:
            s = "T" + chr(byte - 0x10)
        if 0x5F < byte < 0x70:
            s = "R" + chr(byte - 0x30)
        if 0xDF < byte < 0xF0:
            s = "C" + chr(byte - 0xB0)
        if byte > 0xEF:
            s = "O" + chr(byte - 0xC0)
    else:
        if 0x1F < byte < 0x7F:
            s = chr(byte)
        if byte == 0x0A:
            s = "LF"
        if byte == 0x0D:
            s = "CR"
    return s


# ------------------------------------------------------------ the two checks

def name_of(k, want):
    byte, atn, eoi = want[k]
    if atn:
        kind = "UNLISTEN" if byte == UNLISTEN else "LISTEN" if byte & 0xE0 == LISTEN else "SECOND"
        return "bus byte %d (%s 0x%02X)" % (k, kind, byte)
    return "bus byte %d (data 0x%02X%s)" % (k, byte, ", EOI" if eoi else "")


def check_decoder(transactions, wires, cycles):
    want = bus_bytes(transactions)
    got = sigrok_items(wires, cycles)
    errs = []
    for k, (w, g) in enumerate(zip(want, got)):
        byte, atn, eoi = w
        ss, text, gp, eo = g
        problems = []
        if text != "%02X" % byte:
            problems.append("decoded as 0x%s" % text)
        if level_at(wires["ATN"], ss) != (0 if atn else 1):
            problems.append("ATN %s when it began" % ("high" if atn else "low"))
        if gp != gpib_text(byte, atn):
            problems.append("decoder's DAT/CMD says %r, wanted %r" % (gp, gpib_text(byte, atn)))
        if (eo == "EOI") != eoi:
            problems.append("EOI %s" % ("missing" if eoi else "where none belongs"))
        if problems:
            errs.append("%s: %s" % (name_of(k, want), ", ".join(problems)))
            break
    if len(got) != len(want):
        errs.append("decoded %d bus bytes, wanted %d" % (len(got), len(want)))
    return errs


class Fail(Exception):
    pass


def check_waveform(transactions, trans, chip):
    """Every limit of the task sheet, from the chip's own pin changes."""
    errs = []
    for p, nm in ((DATA, "DATA"), (CLK, "CLK"), (ATN, "ATN")):
        if not chip[p] or chip[p][0][0] != 0:
            return ["no level for the pins at cycle 0 in the simulator's output"]
        if chip[p][0][1] != 1:
            errs.append("%s (P%d) is pulled low at cycle 0: all lines must start released" % (nm, p))
    if errs:
        return errs
    atn = [c for c, _ in chip[ATN][1:]]
    clk = [c for c, _ in chip[CLK][1:]]
    dat = chip[DATA][1:]
    ia, ic = [0], [0]

    def nxt(lst, idx, what):
        if idx[0] >= len(lst):
            raise Fail("%s: the chip never does it" % what)
        c = lst[idx[0]]
        idx[0] += 1
        return c

    def within(c, base, lim, what):
        lo, hi = base + lim[0], base + lim[1]
        if not lo <= c <= hi:
            raise Fail("%s at cycle %d, %d after %s; allowed %d to %d"
                       % (what[0], c, c - base, what[1], lim[0], lim[1]))

    windows = []   # (lo, hi): where chip DATA may change
    lows = []      # (from, to): where chip DATA may be low
    try:
        for n, (tr, (dev, sa, data)) in enumerate(zip(trans, transactions)):
            tag = "transaction %d" % n
            ta = nxt(atn, ia, "%s: ATN pulled low" % tag)
            within(ta, tr["E"], ATN_START, ("%s: ATN pulled low" % tag, "the bus went free"))
            tc = nxt(clk, ic, "%s: CLK pulled low with ATN" % tag)
            within(tc, ta, CLK_START, ("%s: CLK pulled low" % tag, "ATN fell"))
            nb = len(tr["bytes"])
            for b, by in enumerate(tr["bytes"]):
                btag = "%s, byte %d" % (tag, b)
                r = nxt(clk, ic, "%s: CLK released (ready to send)" % btag)
                within(r, by["K"], READY, ("%s: CLK released (ready to send)" % btag,
                                           "the listener pulled DATA low"))
                f = nxt(clk, ic, "%s: first CLK fall" % btag)
                if by["eoi"]:
                    within(f, by["eoi"][1], AFTER_EOI, ("%s: first CLK fall" % btag,
                                                       "the listener's EOI pulse ended"))
                else:
                    within(f, by["R"], NO_EOI, ("%s: first CLK fall" % btag,
                                                "the listener released DATA"))
                f0 = f
                for i in range(8):
                    rise = nxt(clk, ic, "%s: CLK rise of bit %d" % (btag, i))
                    fall = nxt(clk, ic, "%s: CLK fall of bit %d" % (btag, i))
                    if rise - f < LOW_MIN:
                        raise Fail("%s, bit %d: CLK low for %d cycles before its rise, at least %d"
                                   % (btag, i, rise - f, LOW_MIN))
                    if fall - rise < HIGH_MIN:
                        raise Fail("%s, bit %d: CLK high for %d cycles, at least %d"
                                   % (btag, i, fall - rise, HIGH_MIN))
                    if not PERIOD[0] <= fall - f <= PERIOD[1]:
                        raise Fail("%s, bit %d: %d cycles from CLK fall to CLK fall, allowed %d to %d"
                                   % (btag, i, fall - f, PERIOD[0], PERIOD[1]))
                    windows.append((f, rise - SETUP))
                    f = fall
                windows.append((f, f + RELEASE))
                lows.append((f0, f + RELEASE))
                if f >= by["ack"]:
                    raise Fail("%s: the 8th CLK fall comes after the listener acknowledged" % btag)
                if b == 1:
                    c = nxt(atn, ia, "%s: ATN released after SECOND" % tag)
                    within(c, by["ack"], TURN, ("%s: ATN released after SECOND" % tag,
                                                "SECOND was acknowledged"))
                if b == nb - 2:
                    c = nxt(atn, ia, "%s: ATN pulled low for UNLISTEN" % tag)
                    within(c, by["ack"], TURN, ("%s: ATN pulled low for UNLISTEN" % tag,
                                                "the last data byte was acknowledged"))
                if b == nb - 1:
                    c = nxt(atn, ia, "%s: ATN released after UNLISTEN" % tag)
                    within(c, by["ack"], TURN, ("%s: ATN released after UNLISTEN" % tag,
                                                "UNLISTEN was acknowledged"))
                    c = nxt(clk, ic, "%s: CLK released after UNLISTEN" % tag)
                    within(c, by["ack"], TURN, ("%s: CLK released after UNLISTEN" % tag,
                                                "UNLISTEN was acknowledged"))
        if ia[0] < len(atn):
            raise Fail("ATN changes at cycle %d, where the task sheet has no change of ATN" % atn[ia[0]])
        if ic[0] < len(clk):
            raise Fail("CLK changes at cycle %d, where the task sheet has no change of CLK" % clk[ic[0]])
    except Fail as e:
        errs.append(str(e))
        return errs
    # DATA: changes only in the windows, low only inside a byte's bits.
    for c, lv in dat:
        if not any(lo <= c <= hi for lo, hi in windows):
            what = "while CLK is high or less than %d cycles before a CLK rise" % SETUP
            if not any(a <= c <= b for a, b in lows):
                what = "outside a byte's bits"
            errs.append("the chip's DATA changes at cycle %d, %s" % (c, what))
            break
    for a, b in lows:
        if level_at(chip[DATA], a - 1) != 1 or level_at(chip[DATA], b) != 1:
            errs.append("the chip holds DATA low outside the bits of the byte at cycle %d" % a)
            break
    return errs


def judge(transactions, trans, events, sim_stdout, cycles):
    chip = chip_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(transactions, trans, chip)]
    if chip[DATA] and chip[DATA][0][0] == 0:
        wires = bus(chip, events)
        errs += ["decoder: " + e for e in check_decoder(transactions, wires, cycles)]
    return errs


# ------------------------------------------------------------------ running

def args_problem(args):
    """run_args.txt: -config and -mode flags with values only, and P0, P1, P2
    open-drain (pe_sim takes any unambiguous prefix of a flag's name)."""
    i, modes = 0, {}
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.fullmatch(r"(\d+)=(\w+)", args[i + 1])
            if m:
                modes[int(m.group(1))] = m.group(2)
        i += 2
    for p, nm in ((DATA, "DATA"), (CLK, "CLK"), (ATN, "ATN")):
        if modes.get(p) != "od":
            return "run_args.txt must make P%d (%s) open-drain: -mode %d=od" % (p, nm, p)
    return None


def run_case(run_dir, args, transactions, pick):
    words = tx_words(transactions)
    events, trans = plan(transactions, pick)
    cycles = run_cycles(trans)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        st = os.path.join(d, "stimulus.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        with open(st, "w") as f:
            f.write(stimulus_text(events))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "iec.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    chip = chip_changes(out.stdout)
    moved = sorted(c for p in chip for c, _ in chip[p][1:])
    return judge(transactions, trans, events, out.stdout, cycles), (moved[-1] - moved[0] if moved else None)


def low(lo, hi):
    return lo


def high(lo, hi):
    return hi


def cases_for(seed):
    """(name, transactions, pick): fixed cases, then seeded random ones."""
    rng = random.Random(seed)
    mid = random.Random(1000 + seed)
    fixed = [
        ("one byte, quickest listener", [(4, 7, [0x41])], low),
        ("one byte, slowest listener", [(4, 7, [0x41])], high),
        ("HELLO CR to a printer", [(4, 0, [0x48, 0x45, 0x4C, 0x4C, 0x4F, 0x0D])], mid.randint),
        ("zeros and ones, two devices", [(8, 15, [0x00, 0xFF]), (30, 0, [0x55, 0xAA, 0x01, 0x80])],
         mid.randint),
        ("16 bytes, quickest listener", [(9, 2, [(k * 37 + 11) & 0xFF for k in range(MAX_DATA)])], low),
        ("16 bytes, slowest listener", [(9, 2, [(k * 53 + 7) & 0xFF for k in range(MAX_DATA)])], high),
        ("four one-byte transactions", [(0, 0, [0xFF]), (30, 15, [0x00]), (31 - 1, 1, [0x3F]),
                                        (16, 8, [0x5F])], mid.randint),
    ]
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_TRANS)
        trs = [(rng.randint(0, 30), rng.randint(0, 15),
                [rng.randrange(256) for _ in range(rng.randint(1, MAX_DATA if n % 2 else 4))])
               for _ in range(count)]
        rand.append(("random %d" % n, trs, random.Random(rng.random()).randint))
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
    for name in ("pe_sim", "iec.s", "run_args.txt"):
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
    for n, (name, transactions, pick) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, transactions, pick)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        size = sum(len(t[2]) for t in transactions)
        if not errs:
            rate = (size, span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d transaction%s, %d data byte%s): %s"
              % (n, name, len(transactions), "" if len(transactions) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
