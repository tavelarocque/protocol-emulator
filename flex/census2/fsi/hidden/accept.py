#!/usr/bin/env python3
"""Hidden acceptance test for the blind FSI master firmware (decoder `fsi`,
DSView's, run unmodified in sigrok-cli 0.7.2).

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (fsi.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim.

The chip is the FSI master. It drives FSI_CLK (P1, push-pull) and, during
its own command, FSI_DAT (P0, open-drain with a pull-up; a bit is 1 when the
line is low). A scripted slave, given to the simulator as -stimulus, answers
every command after a delay the firmware cannot know (17 to 80 clocks). The
task sheet fixes where every clock edge belongs and when every command
starts, so the script lines up.

For each case (a list of transactions) the test
  1. builds the TX words the task sheet defines and the slave's stimulus,
     and first requires the decoder to decode an ideal capture of the whole
     link (an ideal master plus that stimulus) to exactly the wanted
     commands and responses, so the input is a real instance of FSI;
  2. runs RUN_DIR/pe_sim on RUN_DIR/fsi.s with those words and the stimulus;
  3. works out the wire level of both pins in every cycle (push-pull: the
     chip's output; open-drain: the chip's output AND the slave's);
  4. checks the waveform directly: every clock edge within +-2 cycles of
     its place, none extra, none missing to the end of the run; the chip's
     DATA output changing only while the clock is high (at the latest in the
     cycle of a falling edge);
     DATA pulled low by the chip only inside its own commands; and the bit
     on the line at every rising edge equal to the ideal link;
  5. turns the wire into a logic capture (one sample per cycle) and has the
     decoder read it: its annotations must be exactly the wanted commands
     and responses, in order, with no warning and nothing extra;
  6. requires the "rx" words to be the task sheet's, in order, nothing extra.

Prints one line per case, then for the last passing case
    RATE bytes=<data bytes moved> cycles=<cycles from first to last pin change>
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

# The round-2 decoders (sigrok-cli 0.7.2's own plus DSView's, as fetched).
# FSI_DECODERS overrides the place, for a copy of this folder kept elsewhere.
DECODERS = os.environ.get(
    "FSI_DECODERS",
    "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders")

CLOCK_HZ = 50_000_000      # core clock: one cycle = 20 ns
PERIOD = 20                # cycles per FSI clock (2.5 MHz)
F0 = 100                   # ideal cycle of falling edge 0
HALF = 10                  # rising edge k is HALF cycles after falling edge k
TOL = 2                    # cycles an edge may be from its place
DEV_DELAY = 4              # the slave changes DATA this long after an ideal rising edge
FIRST = 4                  # clock of transaction 0's START
D_MIN, D_MAX = 17, 80      # clocks from the command's last CRC bit to the slave's START
GAP = 20                   # idle clocks between a response and the next START
MAX_TRANS = 8

DATA = 0                   # P0: FSI_DAT
CLK = 1                    # P1: FSI_CLK
REQUIRED_MODES = {DATA: "od", CLK: "pp"}
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")

READ, WRITE = "R", "W"
ACK, ERR_A, ERR_C = 0, 2, 3
SIZE_CODE = {1: 0, 2: 1, 4: 2}           # bytes -> bits 1..0 of the operation word
SIZE_NAME = {1: "BYTE", 2: "HALF_WORD", 4: "WORD"}
RESP_NAME = {ERR_A: "ERR_A", ERR_C: "ERR_C"}


# ----------------------------------------------------------- the protocol

def Fe(k):
    """Ideal cycle of falling edge k (the start of clock k)."""
    return F0 + PERIOD * k


def Re(k):
    """Ideal cycle of rising edge k (the end of clock k)."""
    return F0 + PERIOD * k + HALF


def msb(value, n):
    return [(value >> i) & 1 for i in range(n - 1, -1, -1)]


def crc4(bits):
    """FSI's CRC: x^4 + x^2 + x + 1, from 0, most significant first, over
    every bit given (START included). Returns the 4 bits to send."""
    c = 0
    for b in bits:
        f = ((c >> 3) & 1) ^ b
        c = (c << 1) & 0xF
        if f:
            c ^= 0b0111
    return msb(c, 4)


def wire_address(t):
    """The 21 address bits as sent: a 4-byte access has bits 1..0 = 01."""
    return t["addr"] | 1 if t["size"] == 4 else t["addr"]


def command_bits(t):
    """START, slave ID, ABS_ADR, R/W, address, data size, write data, CRC."""
    b = [1] + msb(t["sid"], 2) + [1, 0, 0] + [1 if t["rw"] == READ else 0]
    b += msb(wire_address(t), 21) + [0 if t["size"] == 1 else 1]
    if t["rw"] == WRITE:
        b += msb(t["data"], 8 * t["size"])
    return b + crc4(b)


def response_bits(t):
    """START, slave ID, response code, read data (on ACK), CRC."""
    b = [1] + msb(t["sid"], 2) + msb(t["code"], 2)
    if t["rw"] == READ and t["code"] == ACK:
        b += msb(t["data"], 8 * t["size"])
    return b + crc4(b)


def schedule(trans):
    """[(S, ce, cs, E)] per transaction, and the START clock of the
    transaction that does not come (the end of the run)."""
    out, s = [], FIRST
    for t in trans:
        ce = s + len(command_bits(t)) - 1
        cs = ce + t["delay"]
        e = cs + len(response_bits(t)) - 1
        out.append((s, ce, cs, e))
        s = e + GAP + 1
    return out, s


def run_cycles(trans):
    """The run ends at the falling edge of the START clock that does not come."""
    return Fe(schedule(trans)[1])


def link_bits(trans):
    """({clock: bit} the master sends, {clock: bit} the slave sends,
    {clock: (transaction, what)} for messages)."""
    master, slave, what = {}, {}, {}
    sched, _ = schedule(trans)
    for n, (t, (s, ce, cs, e)) in enumerate(zip(trans, sched)):
        for i, b in enumerate(command_bits(t)):
            master[s + i] = b
            what[s + i] = (n, "command bit %d" % i)
        for i, b in enumerate(response_bits(t)):
            slave[cs + i] = b
            what[cs + i] = (n, "response bit %d" % i)
    return master, slave, what


# ------------------------------------------------------- the host interface

def tx_words(trans):
    """The task sheet's words, per transaction: the operation (bits 1..0
    size, bit 2 read, bits 4..3 slave ID), address bits 20..16, address bits
    15..0, then for a write the data (one word, or for 4 bytes the high then
    the low half). Payload only."""
    words = []
    for t in trans:
        words.append(SIZE_CODE[t["size"]] | (4 if t["rw"] == READ else 0) | (t["sid"] << 3))
        words += [t["addr"] >> 16, t["addr"] & 0xFFFF]
        if t["rw"] == WRITE:
            words += [t["data"] >> 16, t["data"] & 0xFFFF] if t["size"] == 4 else [t["data"]]
    return words


def rx_words(trans):
    """Per transaction: the response code; then, for a read answered ACK,
    the data (one word, or for 4 bytes the high then the low half)."""
    words = []
    for t in trans:
        words.append(t["code"])
        if t["rw"] == READ and t["code"] == ACK:
            words += [t["data"] >> 16, t["data"] & 0xFFFF] if t["size"] == 4 else [t["data"]]
    return words


def stimulus(trans):
    """[(cycle, hex)]: the slave on P0 (bit 0; 1 = not pulling low), every
    other bit 1. The slave's bit for clock c is on the line from DEV_DELAY
    cycles after the ideal rising edge c-1 to DEV_DELAY after rising edge c;
    a 1 is the line pulled low."""
    _, slave, _ = link_bits(trans)
    lines, level = [(0, 0xFF)], 1
    for c in sorted(slave):
        want = 0 if slave[c] else 1
        if want != level:
            lines.append((Re(c - 1) + DEV_DELAY, 0xFE | want))
            level = want
        if c + 1 not in slave and level == 0:
            lines.append((Re(c) + DEV_DELAY, 0xFF))
            level = 1
    return lines


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name)."""
    i = 0
    while i < len(args):
        name = args[i].lstrip("-") if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if len(hits) == 1 and hits[0] in ("tx", "cycles", "stimulus", "inputs"):
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        i += 2
    return None


def flag_name(arg):
    if not arg.startswith("-"):
        return None
    name = arg.lstrip("-")
    hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
    return hits[0] if len(hits) == 1 else None


def modes_of(args):
    """{pin: mode} from the -mode flags (pe_sim's default is input)."""
    modes = {p: "in" for p in range(8)}
    for i in range(0, len(args) - 1, 2):
        if flag_name(args[i]) == "mode":
            p, _, m = args[i + 1].partition("=")
            if m not in ("pp", "od", "in") or not 0 <= int(p) < 8:
                raise ValueError(args[i + 1])
            modes[int(p)] = m
    return modes


def modes_problem(modes):
    bad = ["P%d=%s" % (p, modes[p]) for p, m in REQUIRED_MODES.items() if modes[p] != m]
    if bad:
        return "pin modes must be P0 od (FSI_DAT), P1 pp (FSI_CLK); got " + ", ".join(bad)
    return None


# ------------------------------------------------- from pe_sim to the wire

def parse_sim(stdout):
    """([(cycle, outputs)], [rx words])."""
    outs, rx = [], []
    for line in stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            outs.append((int(part[1]), int(part[2], 16)))
        elif len(part) == 3 and part[0] == "rx":
            rx.append(int(part[2]))
    return outs, rx


def per_cycle(changes, cycles, initial):
    vals, cur, i = [], initial, 0
    changes = sorted(changes)
    for c in range(cycles):
        while i < len(changes) and changes[i][0] <= c:
            cur = changes[i][1]
            i += 1
        vals.append(cur)
    return vals


def wires(out, stim, modes):
    """The level on each pin, as a logic analyser would see it."""
    lev = []
    for o, s in zip(out, stim):
        v = 0
        for p in range(8):
            ob, sb = (o >> p) & 1, (s >> p) & 1
            m = modes[p]
            b = ob if m == "pp" else (ob & sb if m == "od" else sb)
            v |= b << p
        lev.append(v)
    return lev


def bit(v, p):
    return (v >> p) & 1


def ideal_outputs(trans, cycles):
    """The judge's own ideal master, per cycle: the clock on its places, each
    command bit put on DATA (inverted) at its clock's falling edge."""
    master, _, _ = link_bits(trans)
    out = []
    for c in range(cycles):
        if c < F0:
            clk, k = 1, -1
        else:
            k = (c - F0) // PERIOD
            clk = 0 if (c - F0) % PERIOD < HALF else 1
        d = 0 if master.get(k, 0) else 1
        out.append(0xFC | (clk << CLK) | (d << DATA))
    return out


# ------------------------------------------------------------- the checks

def check_waveform(trans, out, wire):
    """The limits of the task sheet, from the pins. Returns (objections,
    the cycles at which the rising edges show)."""
    errs = []
    cycles = len(wire)
    sched, s_end = schedule(trans)
    clk = [bit(o, CLK) for o in out]
    edges = [c for c in range(1, cycles) if clk[c] != clk[c - 1]]
    if clk[0] != 1:
        errs.append("FSI_CLK is not high at cycle 0")
    # Edge i is falling edge i/2 (i even) or rising edge (i-1)/2 (i odd).
    for i, c in enumerate(edges):
        k, rising = i // 2, i % 2 == 1
        ideal = Re(k) if rising else Fe(k)
        if abs(c - ideal) > TOL:
            errs.append("FSI_CLK %s edge %d at cycle %d, ideal %d (limit +-%d)"
                        % ("rising" if rising else "falling", k, c, ideal, TOL))
            break
    if len(edges) < 2 * s_end:
        errs.append("FSI_CLK has %d edges, the run needs %d (every clock to rising edge %d, cycle %d)"
                    % (len(edges), 2 * s_end, s_end - 1, Re(s_end - 1)))
    rises = edges[1::2]

    # The chip's DATA output changes only while the clock is high: a change
    # shown at cycle c needs FSI_CLK high at cycle c - 1 (so at the latest in
    # the cycle of a falling edge, never in the low half, never in the cycle
    # of a rising edge).
    for c in range(1, cycles):
        if bit(out[c], DATA) != bit(out[c - 1], DATA) and not clk[c - 1]:
            errs.append("the chip's DATA output changes at cycle %d, with FSI_CLK low at cycle %d"
                        % (c, c - 1))
            break

    # The chip pulls DATA low only inside its own commands.
    ok = [False] * cycles
    for s, ce, _, _ in sched:
        if s - 1 < len(rises) and ce + 1 < len(rises):
            for c in range(rises[s - 1] + 1, rises[ce + 1]):
                ok[c] = True
    for c in range(cycles):
        if not bit(out[c], DATA) and not ok[c]:
            errs.append("the chip pulls DATA low at cycle %d, outside its own command" % c)
            break

    # The bit on the line at every rising edge, against the ideal link.
    master, slave, what = link_bits(trans)
    for k in range(min(len(rises), s_end)):
        got = 1 - bit(wire[rises[k] - 1], DATA)
        want = master.get(k, 0) | slave.get(k, 0)
        if got != want:
            n, part = what.get(k, (None, "an idle clock"))
            errs.append("bit %d at rising edge %d (cycle %d), wanted %d (%s%s)"
                        % (got, k, rises[k], want, part,
                           "" if n is None else " of transaction %d" % n))
            break
    return errs, rises


def want_annotations(trans):
    out = []
    for t in trans:
        rev_id = ((t["sid"] & 1) << 1) | (t["sid"] >> 1)   # README.md: the decoder reads the ID LSB first
        out += ["START", "Slave ID: 0x%01x" % rev_id, "Command: ABS_ADR (0x04/3)",
                "Direction: " + ("Read" if t["rw"] == READ else "Write"),
                "Address: 0x%06x" % wire_address(t), "Data Size: " + SIZE_NAME[t["size"]]]
        if t["rw"] == WRITE:
            out.append("Data: 0x%0*x" % (2 * t["size"], t["data"]))
        c = command_bits(t)[-4:]
        out += ["CRC: 0x%01x (GOOD)" % int("".join(map(str, c)), 2), "TAR"]
        out += ["START", "Slave ID: 0x%01x" % rev_id]
        if t["code"] == ACK:
            name = "ACK_D" if t["rw"] == READ else "ACK"
        else:
            name = RESP_NAME[t["code"]]
        out.append("Response: %s (0x%02x/2)" % (name, t["code"]))
        if t["rw"] == READ and t["code"] == ACK:
            out.append("Data: 0x%08x" % t["data"])
        c = response_bits(t)[-4:]
        out += ["CRC: 0x%01x (GOOD)" % int("".join(map(str, c)), 2), "TAR"]
    return out


def sigrok_annotations(wire):
    """The decoder on a capture of P0 and P1, one sample per cycle."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "fsi.vcd")
        with open(path, "w") as f:
            f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
            f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$var wire 1 \" P1 $end\n")
            f.write("$upscope $end\n$enddefinitions $end\n")
            prev = None
            for c, w in enumerate(wire):
                v = (bit(w, DATA), bit(w, CLK))
                if v != prev:
                    f.write("#%d\n%d!\n%d\"\n" % (c, v[0], v[1]))
                    prev = v
            f.write("#%d\n" % len(wire))
        env = dict(os.environ, SIGROKDECODE_DIR=os.path.abspath(DECODERS),
                   PYTHONDONTWRITEBYTECODE="1")
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", "fsi:data=P0:clock=P1",
               "-A", "fsi", "--protocol-decoder-samplenum"]
        run = subprocess.run(cmd, capture_output=True, text=True, timeout=600, env=env)
    if run.returncode != 0 or "srd:" in run.stderr or "Traceback" in run.stderr:
        raise RuntimeError("sigrok-cli failed: " + " ".join(run.stderr.split())[:200])
    got = []
    for line in run.stdout.splitlines():
        m = re.match(r"\d+-\d+ fsi-\d+: (.*)$", line)
        if m:
            got.append(m.group(1).strip())
    return got


def compare_annotations(got, want):
    if got == want:
        return []
    for i, (g, w) in enumerate(zip(got, want)):
        if g != w:
            return ["annotation %d is %r, wanted %r" % (i, g, w)]
    return ["%d annotations, wanted %d (first extra or missing: %r)"
            % (len(got), len(want), (got[len(want):] or want[len(got):])[0])]


def check_stimulus(trans):
    """The decoder must read the ideal link (the judge's ideal master plus
    the stimulus) as the wanted transactions: the scripted slave is a real
    FSI slave."""
    cycles = run_cycles(trans)
    out = ideal_outputs(trans, cycles)
    stim = per_cycle(stimulus(trans), cycles, 0xFF)
    wire = wires(out, stim, {p: ("od" if p == DATA else "pp" if p == CLK else "in") for p in range(8)})
    errs, _ = check_waveform(trans, out, wire)
    return errs + compare_annotations(sigrok_annotations(wire), want_annotations(trans))


def check_rx(trans, rx):
    want = rx_words(trans)
    if rx == want:
        return []
    for i, (g, w) in enumerate(zip(rx, want)):
        if g != w:
            return ["rx word %d is 0x%04x, wanted 0x%04x" % (i, g, w)]
    return ["%d rx words, wanted %d" % (len(rx), len(want))]


def judge(trans, sim_stdout, modes, cycles):
    outs, rx = parse_sim(sim_stdout)
    if not outs or outs[0][0] != 0:
        return ["waveform: no pin levels at cycle 0 in the simulator's output"]
    out = per_cycle(outs, cycles, 0xFF)
    stim = per_cycle(stimulus(trans), cycles, 0xFF)
    wire = wires(out, stim, modes)
    errs, _ = check_waveform(trans, out, wire)
    errs = ["waveform: " + e for e in errs]
    try:
        errs += ["decoder: " + e for e in compare_annotations(sigrok_annotations(wire),
                                                              want_annotations(trans))]
    except Exception as e:  # a decoder that falls over is a failure
        errs.append("decoder: %s: %s" % (type(e).__name__, e))
    errs += ["rx: " + e for e in check_rx(trans, rx)]
    return errs


# ------------------------------------------------------------------ running

def data_bytes(trans):
    return sum(t["size"] for t in trans if t["rw"] == WRITE or t["code"] == ACK)


def run_case(run_dir, args, modes, trans):
    """(objections, cycles from the first pin change to the last or None)."""
    bad = check_stimulus(trans)
    if bad:
        return ["judge: the ideal link does not pass: " + bad[0]], None
    cycles = run_cycles(trans)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in tx_words(trans)))
        st = os.path.join(d, "stimulus.txt")
        with open(st, "w") as f:
            f.write("".join("%d %02x\n" % (c, v) for c, v in stimulus(trans)))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "fsi.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(cycles)] + args
        try:
            run = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if run.returncode != 0:
        said = " ".join(run.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (run.returncode, said[:200])], None
    outs, _ = parse_sim(run.stdout)
    moved = [c for c, _ in outs[1:]]
    return judge(trans, run.stdout, modes, cycles), (moved[-1] - moved[0] if moved else None)


def T(rw, size, sid, addr, data, code=ACK, delay=D_MIN):
    return {"rw": rw, "size": size, "sid": sid, "addr": addr, "data": data,
            "code": code, "delay": delay}


# The task sheet's example (its words, bits, stimulus and rx are checked by selftest.py).
EXAMPLE = [T(WRITE, 1, 0, 0x000C10, 0xA5, ACK, 17), T(READ, 2, 3, 0x1FFFFE, 0x5AC3, ACK, 23)]


def cases_for(seed):
    """(name, transactions): fixed cases, then seeded random ones."""
    fixed = [
        ("the task sheet's example", EXAMPLE),
        ("4-byte read of all ones at the top, slowest answer",
         [T(READ, 4, 3, 0x1FFFFC, 0xFFFFFFFF, ACK, D_MAX)]),
        ("all zeros", [T(WRITE, 1, 0, 0, 0x00, ACK, D_MIN), T(READ, 1, 0, 0, 0x00, ACK, D_MIN)]),
        ("every size both ways, every slave ID",
         [T(WRITE, 1, 1, 0x000001, 0x81, ACK, 30), T(WRITE, 2, 2, 0x0ABCDE, 0x8001, ACK, 45),
          T(WRITE, 4, 3, 0x154AA8, 0xC0FFEE11, ACK, 17), T(READ, 1, 2, 0x1FFFFF, 0x7E, ACK, 80),
          T(READ, 2, 1, 0x00F00E, 0xE817, ACK, 18), T(READ, 4, 0, 0x02D3C4, 0x12345678, ACK, 66)]),
        ("error answers", [T(READ, 4, 0, 0x001000, 0xDEADBEEF, ERR_A, 25),
                           T(WRITE, 2, 1, 0x000802, 0x1234, ERR_C, 40),
                           T(READ, 2, 2, 0x000802, 0xA55A, ACK, 19),
                           T(READ, 1, 3, 0x000803, 0x3C, ERR_C, 79)]),
        ("eight transactions", [T(WRITE if n % 2 else READ, (1, 2, 4)[n % 3], n % 4,
                                  ((0x0A5A5 * (n + 1)) & 0x1FFFFF) & ~((1, 2, 4)[n % 3] - 1),
                                  (0x9E3779B9 * (n + 3)) & ((1 << (8 * (1, 2, 4)[n % 3])) - 1),
                                  ACK, D_MIN + 9 * n) for n in range(MAX_TRANS)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_TRANS) if n % 2 else rng.randint(1, 3)
        trans = []
        for _ in range(count):
            size = rng.choice((1, 2, 4))
            code = rng.choice((ACK,) * 8 + (ERR_A, ERR_C))
            trans.append(T(rng.choice((READ, WRITE)), size, rng.randrange(4),
                           rng.randrange(1 << 21) & ~(size - 1), rng.randrange(1 << (8 * size)),
                           code, rng.randint(D_MIN, D_MAX)))
        rand.append(("random %d" % n, trans))
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
    if not os.path.isfile(os.path.join(DECODERS, "fsi", "pd.py")):
        setup.append("the fsi decoder is not in %s" % os.path.abspath(DECODERS))
    for name in ("pe_sim", "fsi.s", "run_args.txt"):
        if not os.path.exists(os.path.join(run_dir, name)):
            setup.append("%s is missing from %s" % (name, run_dir))
    args, modes = [], None
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
        else:
            try:
                modes = modes_of(args)
                problem = modes_problem(modes)
                if problem:
                    setup.append(problem)
            except (ValueError, KeyError) as e:
                setup.append("run_args.txt: bad -mode value (%s)" % e)
    if setup:
        print("setup: FAIL: " + "; ".join(setup))
        print("ACCEPT FAIL")
        return 1
    failed, rate = 0, None
    for n, (name, trans) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, modes, trans)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (data_bytes(trans), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d transaction%s): %s"
              % (n, name, len(trans), "" if len(trans) == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
