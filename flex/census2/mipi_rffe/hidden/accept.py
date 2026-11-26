#!/usr/bin/env python3
"""Hidden acceptance test for the blind MIPI RFFE master firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (mipi_rffe.s, run_args.txt) and pe_sim, which may
be a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet
fixes what the TX and RX words mean and when every sequence happens; this
test builds the words and the slave's scripted replies itself.

For each case (a list of RFFE sequences) the test
  1. builds the TX words the task sheet defines, the RX words the firmware
     must push (the bytes the slave returns to reads) and the slave's
     scripted levels on SDATA (a -stimulus file),
  2. requires sigrok's mipi_rffe decoder to read the ideal bus (an ideal
     master's levels together with the scripted slave) as exactly the wanted
     sequences, so the scripted slave is a real RFFE slave,
  3. runs RUN_DIR/pe_sim on RUN_DIR/mipi_rffe.s with the words and the
     stimulus,
  4. works out the levels on the wire, cycle by cycle (SCLK push-pull: the
     chip's output; SDATA open-drain with a pull-up: the chip's output AND
     the slave's), and checks every timing limit of the task sheet from them:
     each SCLK edge within +-2 cycles of its place, SDATA changing only while
     SCLK is high and at least 3 cycles before it falls (at most once per
     clock), the SSC, the bit on SDATA at every falling edge, the lines low
     when idle, and the chip letting go of SDATA while the slave drives it,
  5. has sigrok-cli's mipi_rffe decoder read the wire and requires its
     annotations to be exactly the wanted ones, in order, nothing extra,
  6. requires the RX words to be the bytes the slave returned, in order,
     nothing extra.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<data bytes written and read> cycles=<first to last change of P0 or P1>
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

HERE = os.path.dirname(os.path.abspath(__file__))
DECODERS = "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders"
if not os.path.isdir(os.path.join(DECODERS, "mipi_rffe")):   # the folder moved with the census
    DECODERS = os.path.normpath(os.path.join(HERE, "..", "..", "decoders"))
DECODER = "mipi_rffe:sclk=SCLK:sdata=SDATA"

CLOCK_HZ = 50_000_000   # core clock: one cycle = 20 ns
T = 20                  # cycles per SCLK period (2.5 MHz)
HIGH = 10               # SCLK is high from a rising edge to the falling edge 10 cycles later
TOL = 2                 # cycles an edge may be from its place
SETUP = 3               # SDATA must change at least this many cycles before SCLK falls
FIRST = 400             # the first sequence's SSC begins at this cycle
IDLE = 6                # idle SCLK periods after a sequence's last clock period
LOW_BY = 100            # SCLK and SDATA low by this cycle
HOLD_AT = 12            # after the turnaround clock's place, the slave holds SDATA low from here
SLAVE_AT = 4            # the slave changes SDATA this many cycles after a rising edge's place
LET_GO_AT = 14          # after the last bus-park clock's place, the slave lets go of SDATA here
TAIL = 100              # the run ends this long after the place of an SSC that does not come
SCLK, SDATA = 0, 1      # pins
MODES = {0: "pp", 1: "od"}
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
MAX_SEQS = 8

# The sequence kinds, as the task sheet numbers them in the header word.
R0W, RW, RR, ERW, ERR, ERWL, ERRL = range(7)
KIND_NAME = {R0W: "Register 0 Write", RW: "Register Write", RR: "Register Read",
             ERW: "Extended Register Write", ERR: "Extended Register Read",
             ERWL: "Extended Register Write Long", ERRL: "Extended Register Read Long"}
READS = (RR, ERR, ERRL)
MAX_N = {R0W: 1, RW: 1, RR: 1, ERW: 16, ERR: 16, ERWL: 8, ERRL: 8}
ADDR_BITS = {R0W: 0, RW: 5, RR: 5, ERW: 8, ERR: 8, ERWL: 16, ERRL: 16}


# ---------------------------------------------------------------- the protocol

def msb(value, width):
    return [(value >> k) & 1 for k in range(width - 1, -1, -1)]


def parity(bits):
    """RFFE's parity bit: odd parity, the frame's ones and it together odd."""
    return 1 - (sum(bits) & 1)


def command_byte(seq):
    kind, n = seq["kind"], len(seq["data"])
    return {R0W: 0x80 | seq["data"][0] if kind == R0W else 0,
            RW: 0x40 | seq["addr"], RR: 0x60 | seq["addr"],
            ERW: 0x00 | (n - 1), ERR: 0x20 | (n - 1),
            ERWL: 0x30 | (n - 1), ERRL: 0x38 | (n - 1)}[kind]


def address_bytes(seq):
    kind, a = seq["kind"], seq["addr"]
    if kind in (ERW, ERR):
        return [a]
    if kind in (ERWL, ERRL):
        return [a >> 8, a & 0xFF]
    return []


def frame(bits):
    return bits + [parity(bits)]


def clocks(seq):
    """(bits, turnaround): the bit SDATA carries in each SCLK clock of the
    sequence, in order, with who drives it ('m' the master, 's' the slave),
    and for a read the index of the master's bus-park clock before the
    slave's data (None for a write). Bus-park clocks carry 0."""
    out = [(b, "m") for b in frame(msb(seq["sa"], 4) + msb(command_byte(seq), 8))]
    for a in address_bytes(seq):
        out += [(b, "m") for b in frame(msb(a, 8))]
    if seq["kind"] in READS:
        turn = len(out)
        out.append((0, "m"))
        for d in seq["data"]:
            out += [(b, "s") for b in frame(msb(d, 8))]
        out.append((0, "s"))
        return out, turn
    if seq["kind"] != R0W:
        for d in seq["data"]:
            out += [(b, "m") for b in frame(msb(d, 8))]
    out.append((0, "m"))
    return out, None


def schedule(seqs):
    """[(start, bits, turnaround)] per sequence, and the run's length. The
    SSC of a sequence rises at `start`; its clock j rises at start + 40 + 20j."""
    out, s = [], FIRST
    for seq in seqs:
        bits, turn = clocks(seq)
        out.append((s, bits, turn))
        s += T * (2 + len(bits) + IDLE)
    return out, s + TAIL


def rise_at(start, j):
    return start + 2 * T + T * j


# ------------------------------------------------------- the host interface

def tx_words(seqs):
    """The TX words of a run, as the task sheet defines them: per sequence a
    header (bits 12..8 the number of data bytes, bits 7..4 the kind, bits
    3..0 the slave address), the register address (not for a Register 0
    Write), then for a write one word per data byte. Payload only."""
    words = []
    for seq in seqs:
        words.append((len(seq["data"]) << 8) | (seq["kind"] << 4) | seq["sa"])
        if seq["kind"] != R0W:
            words.append(seq["addr"])
        if seq["kind"] not in READS:
            words += list(seq["data"])
    return words


def rx_wanted(seqs):
    """One RX word per byte a read returns, the byte in bits 7..0."""
    return [d for seq in seqs if seq["kind"] in READS for d in seq["data"]]


def stimulus(seqs):
    """[(cycle, level of SDATA as the slave leaves it)]: 1 means let go (the
    pull-up), 0 means pulled low. Only reads move it."""
    events = [(0, 1)]
    plan, _ = schedule(seqs)
    for start, bits, turn in plan:
        if turn is None:
            continue
        last = len(bits) - 1
        events.append((rise_at(start, turn) + HOLD_AT, 0))
        for j in range(turn + 1, last):
            events.append((rise_at(start, j) + SLAVE_AT, bits[j][0]))
        events.append((rise_at(start, last) + SLAVE_AT, 0))
        events.append((rise_at(start, last) + LET_GO_AT, 1))
    out = []
    for c, v in events:
        if not out or out[-1][1] != v:
            out.append((c, v))
    return out


def stimulus_text(seqs):
    return "".join("%d %02x\n" % (c, 0xFF if v else 0xFF & ~(1 << SDATA)) for c, v in stimulus(seqs))


def ideal_outputs(seqs):
    """The chip's outputs as an ideal master would set them, as
    [(cycle, sclk, sdata)] changes: both low at cycle 1, SDATA changed in the
    cycle of each rising edge, let go in the middle of the slave's hold and
    taken back 4 cycles after the slave starts the last bus park."""
    ev = [(0, 1, 1), (1, 0, 0)]
    plan, _ = schedule(seqs)
    for start, bits, turn in plan:
        ev += [(start, 0, 1), (start + T, 0, 0)]
        sd = 0
        for j, (b, who) in enumerate(bits):
            r = rise_at(start, j)
            if who == "m":
                sd = b
            ev.append((r, 1, sd))
            if who == "s" and j == len(bits) - 1:
                sd = 0
                ev.append((r + SLAVE_AT + 4, 1, sd))
            ev.append((r + HIGH, 0, sd))
            if j == turn:
                sd = 1
                ev.append((r + HOLD_AT + 3, 0, sd))
    return ev


# ------------------------------------------------- what the decoder must say

def decoder_wants(seqs):
    """The annotations sigrok's mipi_rffe decoder prints for the sequences,
    in order. One is not RFFE's rule but the decoder's: its parity check of
    the command frame leaves out the slave address, so it adds "Parity
    warnings" before a correct command parity bit whenever the slave address
    has an odd number of ones. Checked against the decoder by selftest.py."""
    out = []
    for seq in seqs:
        kind, sa, n = seq["kind"], seq["sa"], len(seq["data"])
        p = lambda bits: "Parity: %d" % parity(bits)
        cmd = command_byte(seq)
        out += ["Sequence Start Condition", "Slave Address[3:0]: %02X" % sa, KIND_NAME[kind]]
        if kind == R0W:
            out.append("Data [6:0]: %02X" % seq["data"][0])
        elif kind in (RW, RR):
            out.append("Address[4:0]: %02X" % seq["addr"])
        elif kind in (ERW, ERR):
            out.append("Byte[3:0]: %02X" % (n - 1))
        else:
            out.append("Byte[2:0]: %02X" % (n - 1))
        if bin(sa).count("1") % 2:
            out.append("Parity warnings")
        out.append(p(msb(sa, 4) + msb(cmd, 8)))
        a = address_bytes(seq)
        if len(a) == 1:
            out += ["Address[7:0]: %02X" % a[0], p(msb(a[0], 8))]
        elif len(a) == 2:
            out += ["Address[15:8]: %02X" % a[0], p(msb(a[0], 8)),
                    "Address[7:0]: %02X" % a[1], p(msb(a[1], 8))]
        if kind in READS:
            out.append("Bus Pack")
        if kind != R0W:
            for i, d in enumerate(seq["data"]):
                hi = 8 * (n - i) - 1 if kind not in (RW, RR) else 7
                out += ["Data [%d:%d]: %02X" % (hi, hi - 7, d), p(msb(d, 8))]
        out.append("Bus Pack")
    return out


# ------------------------------------------------- from pe_sim to the wire

def parse_sim(text):
    """(output changes [(cycle, byte)], rx words) from pe_sim's output."""
    pins, rx = [], []
    for line in text.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            pins.append((int(part[1]), int(part[2], 16)))
        elif len(part) == 3 and part[0] == "rx":
            rx.append(int(part[2]))
    return pins, rx


def per_cycle(changes, n, start):
    """Expand [(cycle, value)] into a list of n values."""
    out, v, k = [], start, 0
    for c in range(n):
        while k < len(changes) and changes[k][0] <= c:
            v = changes[k][1]
            k += 1
        out.append(v)
    return out


def wire(pins, stim, n):
    """Per-cycle levels: SCLK's output, SDATA's output, SDATA on the wire."""
    regs = per_cycle(pins, n, 0xFF)
    sclk = [(r >> SCLK) & 1 for r in regs]
    sd_out = [(r >> SDATA) & 1 for r in regs]
    st = per_cycle(stim, n, 1)
    return sclk, sd_out, [a & b for a, b in zip(sd_out, st)]


def changes_of(levels):
    return [c for c in range(1, len(levels)) if levels[c] != levels[c - 1]]


def write_vcd(path, sclk, sd):
    """Two samples per core cycle (10 ns), only where something changes."""
    with open(path, "w") as f:
        f.write("$timescale 10 ns $end\n$scope module rffe $end\n")
        f.write("$var wire 1 ! SCLK $end\n$var wire 1 \" SDATA $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n#0\n%d!\n%d\"\n" % (sclk[0], sd[0]))
        for c in range(1, len(sclk)):
            if sclk[c] != sclk[c - 1] or sd[c] != sd[c - 1]:
                f.write("#%d\n" % (2 * c))
                if sclk[c] != sclk[c - 1]:
                    f.write("%d!\n" % sclk[c])
                if sd[c] != sd[c - 1]:
                    f.write("%d\"\n" % sd[c])
        f.write("#%d\n" % (2 * len(sclk)))


def sigrok_annotations(sclk, sd):
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "rffe.vcd")
        write_vcd(path, sclk, sd)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", DECODER, "-A", "mipi_rffe",
               "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600,
                             env=dict(os.environ, SIGROKDECODE_DIR=DECODERS))
    if out.returncode != 0 or "rror" in out.stderr:
        raise RuntimeError("sigrok-cli failed: " + " ".join(out.stderr.split())[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append(m.group(3).strip())
    return found


def compare(got, want):
    if got == want:
        return []
    i = next((i for i in range(min(len(got), len(want))) if got[i] != want[i]), min(len(got), len(want)))
    g = got[i] if i < len(got) else "nothing more"
    w = want[i] if i < len(want) else "nothing more"
    return ["annotation %d is %r, wanted %r (%d annotations, wanted %d)" % (i, g, w, len(got), len(want))]


# ------------------------------------------------------------ the checks

def check_wire(seqs, sclk, sd_out, sd):
    """Every limit of the task sheet, from the per-cycle levels."""
    errs = []
    plan, n = schedule(seqs)
    # SCLK: low by LOW_BY, then exactly the clocks of the plan, each edge
    # within TOL of its place.
    if any(sclk[c] for c in range(LOW_BY, min(n, FIRST))):
        errs.append("SCLK is not low from cycle %d until the first sequence" % LOW_BY)
        return errs
    edges = [c for c in changes_of(sclk) if c > LOW_BY]
    places = [(rise_at(s, j) + h, 1 - h // HIGH) for s, bits, _ in plan
              for j in range(len(bits)) for h in (0, HIGH)]
    for k, ((p, up), e) in enumerate(zip(places, edges)):
        if abs(e - p) > TOL:
            errs.append("SCLK %s edge %d of the run is at cycle %d, its place is %d (+-%d)"
                        % ("rising" if up else "falling", k // 2, e, p, TOL))
            return errs
    if len(edges) != len(places):
        errs.append("SCLK has %d edges after cycle %d, wanted %d"
                    % (len(edges), LOW_BY, len(places)))
        return errs
    rise = edges[0::2]
    fall = edges[1::2]
    # SDATA on the wire: low by LOW_BY; afterwards every change is either an
    # SSC edge in its place with SCLK low, or inside a high phase of SCLK at
    # least SETUP cycles before the fall, at most one per clock.
    if any(sd[c] for c in range(LOW_BY, min(n, FIRST - TOL))):
        errs.append("SDATA is not low on the wire from cycle %d until the first SSC" % LOW_BY)
        return errs
    ssc = []
    for s, _, _ in plan:
        ssc += [(s, 1), (s + T, 0)]
    used_ssc, used_clk = set(), set()
    k = 0
    for c in changes_of(sd):
        if c <= LOW_BY:
            continue
        while k < len(rise) and fall[k] < c:
            k += 1
        if k < len(rise) and rise[k] <= c <= fall[k] - SETUP:
            if k in used_clk:
                errs.append("SDATA changes twice while SCLK is high (cycle %d)" % c)
                return errs
            used_clk.add(k)
            continue
        hit = [i for i, (p, v) in enumerate(ssc) if abs(c - p) <= TOL and sd[c] == v]
        if hit and not sclk[c] and hit[0] not in used_ssc:
            used_ssc.add(hit[0])
            continue
        if k < len(rise) and rise[k] <= c:
            why = "%d cycles before SCLK falls at %d (at least %d wanted)" % (fall[k] - c, fall[k], SETUP)
        else:
            why = "while SCLK is low"
        errs.append("SDATA changes on the wire at cycle %d, %s" % (c, why))
        return errs
    if len(used_ssc) != len(ssc):
        i = min(set(range(len(ssc))) - used_ssc)
        errs.append("sequence %d: no SSC %s of SDATA within +-%d of cycle %d"
                    % (i // 2, "rise" if ssc[i][1] else "fall", TOL, ssc[i][0]))
        return errs
    # The bit at every falling edge, as the receiving device takes it.
    k = 0
    for i, (s, bits, turn) in enumerate(plan):
        for j, (b, who) in enumerate(bits):
            got = sd[fall[k] - 1]
            if got != b:
                errs.append("sequence %d: clock %d carries %d at its falling edge (cycle %d), wanted %d"
                            % (i, j, got, fall[k], b))
                return errs
            k += 1
    # While the slave drives SDATA, the chip must let go of it.
    for i, (s, bits, turn) in enumerate(plan):
        if turn is None:
            continue
        a = rise_at(s, turn + 1) + SLAVE_AT
        z = rise_at(s, len(bits) - 1) + SLAVE_AT
        held = [c for c in range(a, min(z, n)) if not sd_out[c]]
        if held:
            errs.append("sequence %d: the chip pulls SDATA low at cycle %d, while the slave drives it (%d to %d)"
                        % (i, held[0], a, z))
            return errs
    return errs


def judge(seqs, sim_stdout, n):
    """Every objection to one run, each marked with the check that made it."""
    pins, rx = parse_sim(sim_stdout)
    if not pins or pins[0][0] != 0:
        return ["waveform: no output state at cycle 0 in the simulator's output"]
    sclk, sd_out, sd = wire(pins, [(c, v) for c, v in stimulus(seqs)], n)
    errs = ["waveform: " + e for e in check_wire(seqs, sclk, sd_out, sd)]
    errs += ["decoder: " + e for e in compare(sigrok_annotations(sclk, sd), decoder_wants(seqs))]
    want = rx_wanted(seqs)
    if rx != want:
        errs.append("rx: pushed %s, wanted %s" % (" ".join("0x%04X" % w for w in rx[:20]),
                                                 " ".join("0x%04X" % w for w in want[:20])))
    return errs


def stimulus_is_rffe(seqs):
    """The ideal master with the scripted slave, through the decoder."""
    _, n = schedule(seqs)
    ev = ideal_outputs(seqs)
    pins = [(c, 0xFC | (a << SCLK) | (b << SDATA)) for c, a, b in ev]
    sclk, sd_out, sd = wire(pins, stimulus(seqs), n)
    errs = check_wire(seqs, sclk, sd_out, sd)
    return errs + compare(sigrok_annotations(sclk, sd), decoder_wants(seqs))


# ------------------------------------------------------------------ running

def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name); the
    modes must be P0 push-pull and P1 open-drain, and no other pin's."""
    modes = {}
    i = 0
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits in (["tx"], ["cycles"], ["stimulus"]):
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.fullmatch(r"([0-7])=(pp|od|in)", args[i + 1])
            if not m:
                return "run_args.txt: -mode %s is not P=pp|od|in" % args[i + 1]
            modes[int(m.group(1))] = m.group(2)
        i += 2
    if modes != MODES:
        return "run_args.txt must set exactly -mode 0=pp -mode 1=od (got %s)" % (
            " ".join("-mode %d=%s" % kv for kv in sorted(modes.items())) or "no -mode")
    return None


def run_case(run_dir, args, seqs):
    """(objections, cycles from the first change of P0 or P1 to the last, or None)."""
    words = tx_words(seqs)
    _, n = schedule(seqs)
    bad = stimulus_is_rffe(seqs)
    if bad:
        return ["judge: the ideal bus does not decode as the case: " + bad[0]], None
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        st = os.path.join(d, "stimulus.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        with open(st, "w") as f:
            f.write(stimulus_text(seqs))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "mipi_rffe.s"),
               "-tx", tx, "-stimulus", st, "-cycles", str(n)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    pins, _ = parse_sim(out.stdout)
    moved, last = [], None
    for c, v in pins:
        v &= (1 << SCLK) | (1 << SDATA)
        if last is not None and v != last:
            moved.append(c)
        last = v
    return judge(seqs, out.stdout, n), (moved[-1] - moved[0] if moved else None)


def seq(kind, sa, addr, data):
    return {"kind": kind, "sa": sa, "addr": addr, "data": list(data)}


def random_seq(rng):
    kind = rng.randrange(7)
    sa = rng.randrange(1 if kind in READS else 0, 16)
    n = rng.randint(1, MAX_N[kind])
    width = 7 if kind == R0W else 8
    return seq(kind, sa, rng.randrange(1 << ADDR_BITS[kind]) if ADDR_BITS[kind] else 0,
               [rng.randrange(1 << width) for _ in range(n)])


def cases_for(seed):
    """(name, sequences): fixed cases, then seeded random ones."""
    fixed = [
        ("the task sheet's example", [seq(RW, 5, 0x13, [0xA7]), seq(RR, 7, 0x1F, [0x3C])]),
        ("every kind once", [seq(R0W, 0, 0, [0x55]), seq(RW, 1, 0x00, [0xFF]),
                             seq(RR, 2, 0x1F, [0x00]), seq(ERW, 3, 0x80, [0x01, 0x02]),
                             seq(ERR, 4, 0x2C, [0xA5, 0x5A, 0xFF]),
                             seq(ERWL, 8, 0x1234, [0x00, 0x80]), seq(ERRL, 15, 0xFFFF, [0x7E])]),
        ("register 0 writes, broadcast and extremes", [seq(R0W, 0, 0, [0x00]), seq(R0W, 15, 0, [0x7F]),
                                                       seq(R0W, 6, 0, [0x40])]),
        ("16-byte extended write and read", [seq(ERW, 9, 0xFF, [(k * 37 + 11) & 0xFF for k in range(16)]),
                                             seq(ERR, 9, 0x00, [(k * 73 + 5) & 0xFF for k in range(16)])]),
        ("8-byte long write and read", [seq(ERWL, 12, 0x0000, [0xFF] * 8),
                                        seq(ERRL, 3, 0x8001, [0x00, 0xFF, 0x01, 0x80, 0x55, 0xAA, 0x0F, 0xF0])]),
        ("reads back to back, every slave address parity", [seq(RR, a, a + 3, [a * 17 & 0xFF])
                                                            for a in (1, 3, 7, 15, 8)]),
    ]
    rng = random.Random(seed)
    rand = []
    for k in range(8):
        count = rng.randint(1, 3 if k % 2 == 0 else MAX_SEQS)
        rand.append(("random %d" % k, [random_seq(rng) for _ in range(count)]))
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
    if not os.path.isfile(os.path.join(DECODERS, "mipi_rffe", "pd.py")):
        setup.append("the mipi_rffe decoder is not in %s" % DECODERS)
    for name in ("pe_sim", "mipi_rffe.s", "run_args.txt"):
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
    for k, (name, seqs) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, seqs)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        size = sum(len(s["data"]) for s in seqs)
        if not errs:
            rate = (size, span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d sequence%s, %d data byte%s): %s"
              % (k, name, len(seqs), "" if len(seqs) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
