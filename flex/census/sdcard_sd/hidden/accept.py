#!/usr/bin/env python3
"""Hidden acceptance test for the blind SD-mode host (CMD line) firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (sdcard_sd.s, run_args.txt) and pe_sim, which may
be a wrapper script: it is always invoked as RUN_DIR/pe_sim.

The chip is an SD host on the CMD line, in SD mode: P0 is CLK (push-pull),
P1 is CMD (open-drain, pulled up). It sends commands the host's TX words
describe, the card answers on CMD, and the chip hands the answers to the
host as RX words. The card is scripted (pe_sim -stimulus): it cannot react,
so the task sheet fixes the clock and the schedule exactly, and the card's
answer lands where the sheet says the host's clock will be.

For each case (a list of transactions) the test
  1. builds the TX words the task sheet defines (three per command), the
     card's script, and the RX words the firmware must push,
  2. checks its own script: the ideal bus (ideal clock, ideal host bits,
     the card's script) is decoded by sigrok's sdcard_sd decoder into
     exactly the wanted command and response tokens, so the card's answers
     are real SD responses,
  3. runs RUN_DIR/pe_sim on RUN_DIR/sdcard_sd.s with the words, the script
     and the flags of run_args.txt (only -config and -mode, with P0 push-pull
     and P1 open-drain and no other pin given a mode),
  4. checks from the chip's own pin changes: every CLK edge on its ideal
     cycle +-2, CMD changing only while CLK is low (low in the cycle before
     the change and in the cycle of it), exactly the changes the wanted bits
     need and no others (so the chip never drives CMD while the card does),
     and at least 8 clocks after the last token,
  5. turns the bus (CLK, and CMD as the chip's output AND the card's) into a
     capture, has sigrok-cli's sdcard_sd decoder read it, and requires the
     decoded tokens to be the wanted ones, bit for bit, in order, nothing
     extra (the decoder does not check CRC, transmission or end bits; this
     comparison does),
  6. requires the RX words to be exactly the wanted ones, in order.

Prints one line per case, then for the last case that passed
    RATE bytes=<payload bytes> cycles=<cycles from the first pin change to the last>
and a last line ACCEPT PASS or ACCEPT FAIL. Exit status 0 only on a full
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

CLOCK_HZ = 10_000_000   # core clock: one cycle = 100 ns
PERIOD = 40             # CLK period in cycles: 250 kHz
HALF = PERIOD // 2      # 20 cycles high, 20 low
FIRST_FALL = 180        # CLK high from cycle 0 to here, then falls
TOL = 2                 # cycles a CLK edge may be from its ideal place
INIT = 80               # rising edges with CMD high before the first command
GAP = 8                 # clocks with CMD high between a token's end bit and the next command
NCR_MIN, NCR_MAX = 2, 64  # response start bit on edge e+NCR, e the command's end bit
CARD_DELAY = 2          # the card changes CMD this many cycles after the ideal falling edge
TAIL = 8                # rising edges, on schedule, after the last end bit
CLK, CMD = 0, 1         # pins
R48, R136 = 1, 2        # response types in the TX word
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "tx", "help", "stimulus")


def rise(n):
    """Ideal cycle of rising edge n (n = 0, 1, ...)."""
    return FIRST_FALL + HALF + PERIOD * n


def fall_before(n):
    """Ideal cycle of the falling edge just before rising edge n."""
    return rise(n) - HALF


# ---------------------------------------------------------------- the code

def crc7(bits):
    """CRC7 of the SD specification: x^7 + x^3 + 1, register from 0, bits in
    the order sent. Returns 7 bits, the first to be sent first."""
    reg = 0
    for b in bits:
        fb = b ^ ((reg >> 6) & 1)
        reg = (reg << 1) & 0x7F
        if fb:
            reg ^= 0x09
    return [(reg >> k) & 1 for k in range(6, -1, -1)]


def num_bits(value, width):
    return [(value >> k) & 1 for k in range(width - 1, -1, -1)]


def bits_num(bits):
    v = 0
    for b in bits:
        v = (v << 1) | b
    return v


def command_token(index, arg):
    head = [0, 1] + num_bits(index, 6) + num_bits(arg, 32)
    return head + crc7(head) + [1]


def response48(index, content):
    head = [0, 0] + num_bits(index, 6) + num_bits(content, 32)
    return head + crc7(head) + [1]


def response_r3(ocr):
    return [0, 0] + [1] * 6 + num_bits(ocr, 32) + [1] * 7 + [1]


def response_r2(body120):
    """R2: start, transmission 0, reserved 111111, then the 128-bit CID or
    CSD register: 120 bits, its own CRC7, and its bit 0 (always 1), which is
    the token's end bit."""
    body = num_bits(body120, 120)
    return [0, 0] + [1] * 6 + body + crc7(body) + [1]


# ------------------------------------------------------- the host interface

class Txn:
    """One transaction: a command, and the card's answer if one is wanted."""

    def __init__(self, index, arg, rtype, response=None, ncr=None):
        self.index, self.arg, self.rtype = index, arg, rtype
        self.response, self.ncr = response, ncr
        want_len = {0: None, R48: 48, R136: 136}[rtype]
        assert (response is None) == (want_len is None)
        assert response is None or len(response) == want_len
        assert response is None or NCR_MIN <= ncr <= NCR_MAX


def tx_words(txns):
    """Three words per command, as the task sheet defines them: the command
    index in bits 5..0 and the response type in bits 9..8 (0 none, 1 a
    48-bit response, 2 a 136-bit one), then the argument's high half, then
    its low half. Payload only: nothing about the line."""
    words = []
    for t in txns:
        words += [t.index | (t.rtype << 8), (t.arg >> 16) & 0xFFFF, t.arg & 0xFFFF]
    return words


def rx_words(txns):
    """What the firmware must push, as the task sheet defines it: for a
    48-bit response, its bits 45..40 (right-justified), 39..24 and 23..8;
    for a 136-bit one, its bits 127..0 in eight words, high first. Bits are
    numbered from the end bit, bit 0, so the start bit is bit 47 or 135."""
    out = []
    for t in txns:
        r = t.response
        if r is None:
            continue
        if len(r) == 48:
            out += [bits_num(r[2:8]), bits_num(r[8:24]), bits_num(r[24:40])]
        else:
            out += [bits_num(r[8 + 16 * k: 24 + 16 * k]) for k in range(8)]
    return out


def payload_bytes(txns):
    return sum(5 + {None: 0, 48: 5, 136: 16}[None if t.response is None else len(t.response)]
               for t in txns)


# ---------------------------------------------------------- the schedule

def schedule(txns):
    """[(first edge, bits, 'host' or 'card')] for every token, and the edge
    of the last end bit."""
    tokens, s = [], INIT
    end = None
    for t in txns:
        cmd = command_token(t.index, t.arg)
        tokens.append((s, cmd, "host"))
        end = s + len(cmd) - 1
        if t.response is not None:
            a = end + t.ncr
            tokens.append((a, t.response, "card"))
            end = a + len(t.response) - 1
        s = end + GAP + 1
    return tokens, end


def host_bits(tokens):
    """The level the host must give CMD on each rising edge, as a dict over
    the edges of its own tokens; 1 (released) on every other edge."""
    want = {}
    for first, bits, who in tokens:
        if who == "host":
            for k, b in enumerate(bits):
                want[first + k] = b
    return want


def card_stimulus(tokens):
    """The card's script, pe_sim -stimulus lines: P1 high (released) except
    while the card sends, when it holds each bit from CARD_DELAY cycles after
    the ideal falling edge before that bit's rising edge, to the same point
    of the next one. Every other input pin reads 0."""
    level = {}
    for first, bits, who in tokens:
        if who == "card":
            for k, b in enumerate(bits):
                level[first + k] = b
    lines, cur = ["0 %02x" % (1 << CMD)], 1
    for n in range(max(level) + 2 if level else 0):
        v = level.get(n, 1)
        if v != cur:
            lines.append("%d %02x" % (fall_before(n) + CARD_DELAY, v << CMD))
            cur = v
    return lines


def stimulus_level(lines):
    """A function: cycle -> level of P1 in the script."""
    pts = []
    for line in lines:
        c, h = line.split()
        pts.append((int(c), (int(h, 16) >> CMD) & 1))

    def at(cycle):
        v = 1
        for c, lvl in pts:
            if c <= cycle:
                v = lvl
            else:
                break
        return v
    return at, pts


def run_cycles(last_end):
    return rise(last_end + TAIL) + 12 * PERIOD


# ------------------------------------------------- from pe_sim to a capture

def parse_sim(stdout):
    """{pin: [(cycle, level)]} for P0 and P1 (the level at cycle 0, then only
    changes), and the rx words in order."""
    changes = {CLK: [], CMD: []}
    rx = []
    for line in stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, val = int(part[1]), int(part[2], 16)
            for pin in changes:
                lvl = (val >> pin) & 1
                if not changes[pin] or changes[pin][-1][1] != lvl:
                    changes[pin].append((cycle, lvl))
        elif len(part) == 3 and part[0] == "rx":
            rx.append(int(part[2], 0) if part[2].startswith("0x") else int(part[2]))
    return changes, rx


def level_fn(chg):
    def at(cycle):
        v = None
        for c, lvl in chg:
            if c <= cycle:
                v = lvl
            else:
                break
        return v
    return at


def and_changes(a, b):
    """Changes of the AND of two change lists."""
    fa, fb = level_fn(a), level_fn(b)
    out = []
    for c in sorted(set(c for c, _ in a) | set(c for c, _ in b)):
        va, vb = fa(c), fb(c)
        v = (va if va is not None else 1) & (vb if vb is not None else 1)
        if not out or out[-1][1] != v:
            out.append((c, v))
    return out


def write_vcd(path, clk, cmd, cycles):
    events = {}
    for c, v in clk:
        events.setdefault(c, []).append("%d!" % v)
    for c, v in cmd:
        events.setdefault(c, []).append('%d"' % v)
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module bus $end\n$var wire 1 ! CLK $end\n$var wire 1 \" CMD $end\n"
                "$upscope $end\n$enddefinitions $end\n")
        for c in sorted(events):
            if c < cycles:
                f.write("#%d\n%s\n" % (c, "\n".join(events[c])))
        f.write("#%d\n" % cycles)


def sigrok_tokens(clk, cmd, cycles):
    """The tokens sigrok's sdcard_sd decoder finds: a list of bit lists, in
    order, each from a 'Start bit' annotation to its 'End bit'. Raises on a
    decoder failure."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "bus.vcd")
        write_vcd(path, clk, cmd, cycles)
        run = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "sdcard_sd:cmd=CMD:clk=CLK",
               "-A", "sdcard_sd=raw-bits:fields", "--protocol-decoder-samplenum"]
        out = subprocess.run(run, capture_output=True, text=True, timeout=600)
    if out.returncode != 0 or "Traceback" in out.stderr or "rror" in out.stderr:
        raise DecoderError("sigrok-cli: " + " ".join(out.stderr.split())[:200])
    bits, starts, ends = [], [], []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)$", line)
        if not m:
            continue
        a, b, text = int(m.group(1)), int(m.group(2)), m.group(3).strip()
        if text in ("0", "1"):
            bits.append((a, int(text)))
        elif text == "Start bit":
            starts.append(a)
        elif text == "End bit":
            ends.append(b)
    bits = sorted(set(bits))
    if len(starts) != len(ends):
        raise DecoderError("decoder gave %d start bits and %d end bits" % (len(starts), len(ends)))
    tokens = []
    used = 0
    for a, b in zip(sorted(starts), sorted(ends)):
        tok = [v for s, v in bits if a <= s < b]
        used += len(tok)
        tokens.append(tok)
    if used != len(bits):
        raise DecoderError("%d decoded bits outside any token" % (len(bits) - used))
    return tokens


class DecoderError(Exception):
    pass


# ------------------------------------------------------------- the checks

def check_clock(chg, last_end):
    """P0: high at cycle 0; its changes are a prefix of the ideal edge list,
    each within TOL; long enough to reach rising edge last_end + TAIL."""
    errs = []
    if not chg or chg[0][0] != 0:
        return ["no level for P0 at cycle 0"]
    if chg[0][1] != 1:
        errs.append("CLK is low at cycle 0: it must be high until cycle %d" % FIRST_FALL)
    edges = [c for c, _ in chg[1:]]
    for k, c in enumerate(edges):
        ideal = FIRST_FALL + HALF * k
        if abs(c - ideal) > TOL:
            errs.append("CLK edge %d (%s) at cycle %d, ideal %d (limit +-%d)"
                        % (k, "falling" if k % 2 == 0 else "rising edge %d" % ((k - 1) // 2),
                           c, ideal, TOL))
            break
    need = 2 * (last_end + TAIL) + 2
    if len(edges) < need and not errs:
        n_rise = len(edges) // 2
        errs.append("CLK stopped after %d rising edges; the schedule needs %d (to %d after the last end bit)"
                    % (n_rise, last_end + TAIL + 1, TAIL))
    return errs


def check_cmd(cmd_chg, clk_chg, want):
    """P1 (the chip's own output): released at cycle 0; changes only while
    CLK is low; exactly the changes the wanted bits need, each in the low
    half before the edge it is for."""
    errs = []
    if not cmd_chg or cmd_chg[0][0] != 0:
        return ["no level for P1 at cycle 0"]
    if cmd_chg[0][1] != 1:
        errs.append("CMD driven low at cycle 0")
    clk = level_fn(clk_chg)
    rises = [c for k, (c, v) in enumerate(clk_chg) if k > 0 and v == 1]
    top = max(want) if want else 0
    need = {}
    prev = 1
    for n in range(top + 2):
        b = want.get(n, 1)
        if b != prev:
            need[n] = b
        prev = b
    seen = {}
    for c, v in cmd_chg[1:]:
        if clk(c - 1) != 0 or clk(c) != 0:
            errs.append("CMD changes at cycle %d while CLK is %s" %
                        (c, "high" if clk(c) == 1 else "high in the cycle before"))
            continue
        nxt = [i for i, r in enumerate(rises) if r > c]
        if not nxt:
            errs.append("CMD changes at cycle %d, after the last rising edge of CLK" % c)
            continue
        n = nxt[0]
        if n in seen:
            errs.append("CMD changes twice in the low half before rising edge %d" % n)
        elif need.get(n) != v:
            errs.append("CMD changes to %d at cycle %d, before rising edge %d, where no change belongs"
                        % (v, c, n))
        seen[n] = v
    missing = [n for n in need if n not in seen]
    if missing:
        errs.append("CMD does not change before rising edge %d (wanted %d there): %d changes missing"
                    % (missing[0], need[missing[0]], len(missing)))
    return errs


def describe_token(tok):
    return "".join(str(b) for b in tok)


def check_decoder(tokens_want, clk, bus_cmd, cycles):
    try:
        got = sigrok_tokens(clk, bus_cmd, cycles)
    except DecoderError as e:
        return [str(e)]
    want = [bits for _, bits, _ in tokens_want]
    if got == want:
        return []
    errs = []
    if len(got) != len(want):
        errs.append("decoded %d tokens, wanted %d" % (len(got), len(want)))
    for k, (g, w) in enumerate(zip(got, want)):
        if g != w:
            who = tokens_want[k][2]
            if len(g) != len(w):
                errs.append("token %d (%s) decoded as %d bits, wanted %d" % (k, who, len(g), len(w)))
            else:
                i = next(i for i in range(len(w)) if g[i] != w[i])
                errs.append("token %d (%s): bit %d (counting from the end bit, 0) decoded as %d"
                            % (k, who, len(w) - 1 - i, g[i]))
            break
    return errs or ["decoded tokens differ from the wanted ones"]


def check_rx(got, want):
    if got == want:
        return []
    if len(got) != len(want):
        errs = ["pushed %d RX words, wanted %d" % (len(got), len(want))]
    else:
        errs = []
    for k, (g, w) in enumerate(zip(got, want)):
        if g != w:
            errs.append("RX word %d is 0x%04x, wanted 0x%04x" % (k, g, w))
            break
    return errs or ["RX words differ"]


def judge(txns, sim_stdout, cycles, stim_lines):
    tokens, last_end = schedule(txns)
    changes, rx = parse_sim(sim_stdout)
    errs = ["clock: " + e for e in check_clock(changes[CLK], last_end)]
    errs += ["cmd: " + e for e in check_cmd(changes[CMD], changes[CLK], host_bits(tokens))]
    if changes[CLK] and changes[CMD]:
        _, pts = stimulus_level(stim_lines)
        bus = and_changes(changes[CMD], pts)
        errs += ["decoder: " + e for e in check_decoder(tokens, changes[CLK], bus, cycles)]
    errs += ["rx: " + e for e in check_rx(rx, rx_words(txns))]
    return errs


def ideal_bus(tokens):
    """The ideal bus, from this test's own schedule: (clk, cmd) change lists."""
    last_end = schedule_end(tokens)
    clk = [(0, 1)]
    k = 0
    while True:
        c = FIRST_FALL + HALF * k
        clk.append((c, 0 if k % 2 == 0 else 1))
        if k % 2 == 1 and (k - 1) // 2 >= last_end + TAIL:
            break
        k += 1
    host = [(0, 1)]
    want = host_bits(tokens)
    prev = 1
    for n in range(max(want) + 2):
        b = want.get(n, 1)
        if b != prev:
            host.append((fall_before(n) + HALF // 2, b))
        prev = b
    return clk, host


def schedule_end(tokens):
    first, bits, _ = tokens[-1]
    return first + len(bits) - 1


def check_script(txns, stim_lines):
    """The card's script, with the ideal host, must decode to the wanted
    tokens: the test's own input is a real instance of the protocol."""
    tokens, last_end = schedule(txns)
    clk, host = ideal_bus(tokens)
    _, pts = stimulus_level(stim_lines)
    bus = and_changes(host, pts)
    return check_decoder(tokens, clk, bus, run_cycles(last_end))


# ------------------------------------------------------------------ cases

PLAIN_R136 = (2, 9, 10)
ACMDS = (6, 13, 41, 51, 22, 23, 42)          # after CMD55
PLAIN = [i for i in range(64) if i not in (41, 51)]


def make_txn(rng, index, acmd, arg=None, content=None, ncr=None):
    arg = rng.getrandbits(32) if arg is None else arg
    ncr = rng.randint(NCR_MIN, NCR_MAX) if ncr is None else ncr
    if not acmd and index == 0:
        return Txn(0, arg, 0)
    if not acmd and index in PLAIN_R136:
        body = rng.getrandbits(120) if content is None else content
        return Txn(index, arg, R136, response_r2(body), ncr)
    c = rng.getrandbits(32) if content is None else content
    if acmd and index == 41:
        return Txn(index, arg, R48, response_r3(c), ncr)
    return Txn(index, arg, R48, response48(index, c), ncr)


def random_case(rng, count):
    txns, acmd = [], False
    for _ in range(count):
        if acmd:
            idx = rng.choice(ACMDS)
        else:
            idx = rng.choice(PLAIN + [0, 2, 8, 9, 55, 55, 55, 17])
        txns.append(make_txn(rng, idx, acmd))
        acmd = (not acmd) and idx == 55
    return txns


def cases_for(seed):
    r = random.Random(1000 + seed)
    init = [make_txn(r, 0, False, arg=0),
            make_txn(r, 8, False, arg=0x1AA, content=0x1AA, ncr=2),
            make_txn(r, 55, False, arg=0, content=0x120, ncr=5),
            make_txn(r, 41, True, arg=0x40FF8000, content=0xC0FF8000, ncr=3),
            make_txn(r, 2, False, arg=0, ncr=2),
            make_txn(r, 3, False, arg=0, content=0xB3680500, ncr=2),
            make_txn(r, 9, False, arg=0xB3680000, ncr=64),
            make_txn(r, 7, False, arg=0xB3680000, content=0x700, ncr=2),
            make_txn(r, 16, False, arg=512, content=0x900, ncr=2),
            make_txn(r, 17, False, arg=0, content=0x900, ncr=2)]
    fixed = [
        ("CMD0 alone", [make_txn(r, 0, False, arg=0)]),
        ("the task sheet's example", [make_txn(r, 0, False, arg=0),
                                      make_txn(r, 8, False, arg=0x1AA, content=0x1AA, ncr=5)]),
        ("SD card start-up, ten commands", init),
        ("answer at 64 clocks, then 2", [make_txn(r, 13, False, arg=0xFFFFFFFF, content=0xFFFFFFFF, ncr=64),
                                          make_txn(r, 13, False, arg=0, content=0, ncr=2)]),
        ("two R2s back to back", [make_txn(r, 10, False, arg=0x00010000, content=(1 << 120) - 1, ncr=2),
                                  make_txn(r, 9, False, arg=0x00010000, content=0, ncr=7)]),
        ("CMD0 three times", [make_txn(r, 0, False, arg=a) for a in (0, 0xFFFFFFFF, 0x12345678)]),
    ]
    rng = random.Random(seed)
    rand = [("random %d" % n, random_case(rng, rng.randint(1, 4 if n % 2 == 0 else 10)))
            for n in range(8)]
    return fixed + rand


# ------------------------------------------------------------------ running

def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else; P0 must be push-pull, P1 open-drain, no other pin a mode."""
    i, modes = 0, {}
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
            m = re.fullmatch(r"(\d)=(pp|od|in)", args[i + 1])
            if not m:
                return "run_args.txt: bad -mode value %r" % args[i + 1]
            modes[int(m.group(1))] = m.group(2)
        i += 2
    if modes.get(CLK) != "pp" or modes.get(CMD) != "od":
        return "run_args.txt must make P0 (CLK) push-pull and P1 (CMD) open-drain"
    others = [p for p in modes if p not in (CLK, CMD) and modes[p] != "in"]
    if others:
        return "run_args.txt: P%d is not connected and must stay an input" % others[0]
    return None


def run_case(run_dir, args, txns):
    tokens, last_end = schedule(txns)
    stim = card_stimulus(tokens)
    script = check_script(txns, stim)
    if script:
        return ["judge: the test's own card script does not decode: " + script[0]], None
    cycles = run_cycles(last_end)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        st = os.path.join(d, "stimulus.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in tx_words(txns)))
        with open(st, "w") as f:
            f.write("\n".join(stim) + "\n")
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "sdcard_sd.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    changes, _ = parse_sim(out.stdout)
    moved = sorted(c for pin in changes for c, _ in changes[pin][1:])
    return judge(txns, out.stdout, cycles, stim), (moved[-1] - moved[0] if moved else None)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "sdcard_sd.s", "run_args.txt"):
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
        problem = None if setup else args_problem(args)
        if problem:
            setup.append(problem)
    if setup:
        print("setup: FAIL: " + "; ".join(setup))
        print("ACCEPT FAIL")
        return 1
    failed, rate = 0, None
    for n, (name, txns) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, txns)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (payload_bytes(txns), span)
        shown = []
        for kind in ("simulator:", "judge:", "clock:", "cmd:", "decoder:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        resp = sum(t.response is not None for t in txns)
        print("case %d (%s: %d command%s, %d response%s): %s"
              % (n, name, len(txns), "" if len(txns) == 1 else "s",
                 resp, "" if resp == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
