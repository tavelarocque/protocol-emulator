#!/usr/bin/env python3
"""Hidden acceptance test for the blind SWIM host firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (swim.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet fixes
what the TX words mean; this test builds them itself.

The chip is the SWIM host (the debug probe) of an STM8 target, on P0,
open-drain. The target is a scripted waveform given to pe_sim with
-stimulus: it cannot react, so the task sheet fixes the whole timetable. For
each case (a list of SRST, ROTF and WOTF operations, the bytes the target
returns, and which host frames the target refuses with a NACK) the test
  1. builds the TX words of the task sheet and the target's stimulus,
  2. runs RUN_DIR/pe_sim on RUN_DIR/swim.s with them,
  3. makes the wire (the chip's open-drain output AND the target's) into a
     logic capture, one sample per core clock cycle (40 MHz), and has
     sigrok-cli's `swim` decoder read it: the enter sequence must be seen,
     then the target's synchronization frame, then exactly the commands,
     byte counts, addresses and data bytes of the operations, in order,
     nothing else,
  4. checks, from the chip's own pin changes, what the decoder does not:
     every edge the chip makes at its place within the stated limits, and
     no other edge (so it never drives the line while the target owns it),
  5. requires the "rx" words to be the bytes the target returned to ROTF
     commands, in order, nothing extra.
Before any of that it requires sigrok to decode the target's stimulus,
together with an ideal host, to exactly the wanted content: the stimulus is
then a real instance of the protocol.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>
(none if no case passed), and a last line, ACCEPT PASS or ACCEPT FAIL. The
exit status is 0 only on a full pass. Python standard library and sigrok-cli
only. Written apart from any firmware and kept from its author."""
import os
import random
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import zipfile

sys.dont_write_bytecode = True

CLOCK_HZ = 40_000_000      # core clock: one cycle = 25 ns
CLK = 5                    # cycles per SWIM clock period (8 MHz)
BIT = 22 * CLK             # 110 cycles: a low-speed bit is 22 SWIM clocks
LOW1 = 2 * CLK             # a 1 is low for 2 SWIM clocks (10 cycles)
LOW0 = 20 * CLK            # a 0 is low for 20 SWIM clocks (100 cycles)
TOL = 2                    # cycles an edge of a frame may be from its place

# The entry sequence, from its first falling edge.
ENTRY_FIRST_MIN = 400      # the first falling edge, no earlier than this cycle
ENTRY_FIRST_MAX = 4000     # and no later
ENTRY_LOW = 640            # 16 us low
HALF_1K = 20_000           # half a period at 1 kHz: 500 us
HALF_2K = 10_000           # half a period at 2 kHz: 250 us
ENTRY_TOL_FALL = 2         # a falling edge, from the rising edge before it
ENTRY_TOL_RISE = 1         # a rising edge, from the rising edge before it

SYNC_AT = 250_000          # the target's synchronization frame starts here
SYNC_LOW = 128 * CLK       # 640 cycles low (128 SWIM clocks, 16 us)
FIRST_GAP = 2 * BIT        # first frame: this long after the sync frame ends
NEXT_GAP = 2 * BIT         # next frame: this long after an ack bit starts
TAIL = 40 * BIT            # quiet time the run lasts after the last ack

SRST, ROTF, WOTF = 0, 1, 2
CMD_BITS = {SRST: (0, 0, 0), ROTF: (0, 0, 1), WOTF: (0, 1, 0)}
CMD_TEXT = {SRST: "system reset", ROTF: "read on-the-fly", WOTF: "write on-the-fly"}
SIM_FLAGS = ("config", "cycles", "help", "inputs", "mode", "stimulus", "tx")
PIN = 0


# ------------------------------------------------------- the host interface

def tx_words(ops):
    """The TX words of one run, as the task sheet defines them.

    Per operation: one command word, bits 9..8 the command (0 SRST, 1 ROTF,
    2 WOTF), bits 7..0 the byte count N (0 for SRST). For ROTF and WOTF two
    address words follow: bits 7..0 address bits 23..16, then address bits
    15..0. For WOTF, N data words follow, the byte in bits 7..0. Every other
    bit is 0. Payload only: nothing about the line."""
    words = []
    for op in ops:
        kind = op["kind"]
        if kind == SRST:
            words.append(0)
            continue
        n = len(op["data"])
        words += [(kind << 8) | n, (op["addr"] >> 16) & 0xFF, op["addr"] & 0xFFFF]
        if kind == WOTF:
            words += list(op["data"])
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name).
    The modes must make P0 open-drain and give no other pin a mode."""
    i, modes = 0, []
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
            modes.append(args[i + 1])
        i += 2
    if [m.replace(" ", "").lower() for m in modes] != ["0=od"]:
        return "run_args.txt must give exactly one mode, 0=od (P0 open-drain), not %r" % modes
    return None


# ------------------------------------------------------------ the timetable

def parity(bits):
    p = 0
    for b in bits:
        p ^= b
    return p


def byte_bits(value):
    return tuple((value >> k) & 1 for k in range(7, -1, -1))


class Timetable:
    """Everything that happens on the wire after the synchronization frame,
    at its ideal place: the target's edges (the stimulus), the host's edges
    (what the chip must do), the content sigrok must decode, the rx words."""

    def __init__(self, ops):
        self.target = [(0, 1), (SYNC_AT, 0), (SYNC_AT + SYNC_LOW, 1)]
        self.host = []           # (cycle, level, what) the chip must make
        self.tokens = [("enterseq", "enter sequence"), ("enterseq", "synchronization frame")]
        self.rx = []
        self.t = SYNC_AT + SYNC_LOW + FIRST_GAP
        for n, op in enumerate(ops):
            self.operation(n, op)
        self.end = self.t + TAIL   # the run's length: 40 bits after one more frame would start

    def bit(self, edges, start, value, what):
        edges.append((start, 0, what))
        edges.append((start + (LOW1 if value else LOW0), 1, what))

    def host_frame(self, data_bits, nacks, what):
        bits = (0,) + tuple(data_bits) + (parity(data_bits),)
        for attempt in range(nacks + 1):
            for k, b in enumerate(bits):
                name = "start bit" if k == 0 else ("parity bit" if k == len(bits) - 1
                                                   else "bit %d" % (len(bits) - 3 - (k - 1)))
                self.bit(self.host, self.t + k * BIT, b,
                         "%s, %s%s" % (what, name, " (resent %d)" % attempt if attempt else ""))
            ack = self.t + len(bits) * BIT
            nack = attempt < nacks
            self.target.append((ack, 0))
            self.target.append((ack + (LOW0 if nack else LOW1), 1))
            self.t = ack + NEXT_GAP

    def target_frame(self, value, what):
        bits = (1,) + byte_bits(value) + (parity(byte_bits(value)),)
        for k, b in enumerate(bits):
            self.target.append((self.t + k * BIT, 0))
            self.target.append((self.t + k * BIT + (LOW1 if b else LOW0), 1))
        ack = self.t + len(bits) * BIT
        self.bit(self.host, ack, 1, what + ", the host's ack bit")
        self.t = ack + NEXT_GAP

    def operation(self, n, op):
        kind = op["kind"]
        label = "operation %d (%s)" % (n, {SRST: "SRST", ROTF: "ROTF", WOTF: "WOTF"}[kind])
        self.host_frame(CMD_BITS[kind], op.get("cmd_nacks", 0), label + " command frame")
        self.tokens.append(("cmd", CMD_TEXT[kind]))
        if kind == SRST:
            return
        data = op["data"]
        self.host_frame(byte_bits(len(data)), 0, label + " N frame")
        self.tokens.append(("bytes", "byte count 0x%02x" % len(data)))
        for k, shift in enumerate((16, 8, 0)):
            self.host_frame(byte_bits((op["addr"] >> shift) & 0xFF), 0,
                            label + " address frame %s" % "EHL"[k])
        self.tokens.append(("address", "address 0x%06x" % op["addr"]))
        nacks = op.get("data_nacks", [0] * len(data))
        for i, value in enumerate(data):
            if kind == WOTF:
                self.host_frame(byte_bits(value), nacks[i], label + " data frame %d" % i)
                self.tokens.append(("data-write", "0x%02x" % value))
            else:
                self.target_frame(value, label + " target data frame %d" % i)
                self.tokens.append(("data-read", "0x%02x" % value))
                self.rx.append(value)

    def entry(self, first):
        """The host's ideal entry sequence, starting at cycle `first`."""
        edges = [(first, 0), (first + ENTRY_LOW, 1)]
        t = first + ENTRY_LOW
        for half in [HALF_1K] * 4 + [HALF_2K] * 4:
            edges += [(t + half, 0), (t + 2 * half, 1)]
            t += 2 * half
        return edges


def stimulus_text(target):
    """The stimulus file: one line per change of P0's level (the other input
    pins stay high)."""
    lines, level = [], None
    for cycle, lv in target:
        if lv != level:
            lines.append("%d %s" % (cycle, "ff" if lv else "fe"))
            level = lv
    return "\n".join(lines) + "\n"


# ------------------------------------------------- from pe_sim to a capture

def p0_changes(sim_stdout):
    """[(cycle, level)] of the chip's own P0 output from pe_sim's
    "pins CYCLE XX" lines: the level at the first line, then only changes."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            cycle, level = int(part[1]), (int(part[2], 16) >> PIN) & 1
            if not out or out[-1][1] != level:
                out.append((cycle, level))
    return out


def rx_words(sim_stdout):
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "rx":
            out.append(int(part[2]))
    return out


def wire(chip, target, cycles):
    """The line as a logic analyser sees it: open-drain, so the AND of the
    chip's output and the target's. Both lists are (cycle, level), sorted,
    the first at cycle 0."""
    events = sorted(set(c for c, _ in chip) | set(c for c, _ in target))
    out, a, b, i, j, level = [], 1, 1, 0, 0, None
    for c in events:
        while i < len(chip) and chip[i][0] <= c:
            a = chip[i][1]
            i += 1
        while j < len(target) and target[j][0] <= c:
            b = target[j][1]
            j += 1
        if c < cycles and (a & b) != level:
            level = a & b
            out.append((c, level))
    return out


def write_sr(path, changes, cycles):
    """A sigrok session file, one sample per cycle. (sigrok-cli 0.7.2 starts
    the swim decoder before it passes on the sample rate of a VCD or binary
    input, and the decoder then stops; a session file carries the rate.)"""
    samples = bytearray(cycles)
    for k, (cycle, level) in enumerate(changes):
        stop = changes[k + 1][0] if k + 1 < len(changes) else cycles
        samples[cycle:stop] = bytes([level]) * (min(stop, cycles) - cycle)
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("version", "2")
        z.writestr("metadata", "[global]\nsigrok version=0.5.2\n\n[device 1]\n"
                   "capturefile=logic-1\ntotal probes=1\nsamplerate=%d Hz\n"
                   "total analog=0\nprobe1=SWIM\nunitsize=1\n" % CLOCK_HZ)
        z.writestr("logic-1-1", bytes(samples))


ANN = re.compile(r"(\d+)-(\d+) swim-1: (.*)$")


def sigrok_tokens(changes, cycles):
    """What sigrok's swim decoder makes of the capture, as (class, text) in
    order of start sample. Two runs, because a data byte read and a data
    byte written print alike."""
    found = []
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "swim.sr")
        write_sr(path, changes, cycles)
        for classes in ("enterseq:cmd-unknown:cmd:bytes:address:data-write", "data-read"):
            cmd = ["sigrok-cli", "-i", path, "-P", "swim:swim=SWIM",
                   "-A", "swim=" + classes, "--protocol-decoder-samplenum"]
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            if out.returncode != 0 or "rror" in out.stderr:
                raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
            for line in out.stdout.splitlines():
                m = ANN.match(line.strip())
                if not m:
                    continue
                text = m.group(3)
                if classes == "data-read":
                    kind = "data-read"
                elif text in ("enter sequence", "synchronization frame"):
                    kind = "enterseq"
                elif text in CMD_TEXT.values():
                    kind = "cmd"
                elif text == "unknown":
                    kind = "cmd-unknown"
                elif text.startswith("byte count"):
                    kind = "bytes"
                elif text.startswith("address"):
                    kind = "address"
                else:
                    kind = "data-write"
                found.append((int(m.group(1)), kind, text))
    found.sort(key=lambda x: x[0])
    return [(k, t) for _, k, t in found]


def content_problem(got, want):
    """The decoded content against the wanted one. sigrok also reports the
    16 us low that opens the enter sequence as a synchronization frame;
    everything before the enter sequence is therefore left out."""
    if ("enterseq", "enter sequence") not in got:
        return ["no enter sequence decoded"]
    got = got[got.index(("enterseq", "enter sequence")):]
    if got == want:
        return []
    for k, (g, w) in enumerate(zip(got, want)):
        if g != w:
            return ["decoded item %d is %s %r, wanted %s %r" % (k, g[0], g[1], w[0], w[1])]
    if len(got) > len(want):
        return ["%d extra items decoded, the first %s %r" % ((len(got) - len(want),) + got[len(want)])]
    return ["only %d of %d items decoded; missing from %s %r"
            % ((len(got), len(want)) + want[len(got)])]


# ---------------------------------------------------------- the edge check

def edge_problems(chip, table):
    """The chip's own P0 edges against the timetable. The entry sequence is
    judged from its first falling edge, each later edge of it from the
    rising edge before it; every edge after the synchronization frame
    within +-TOL cycles of its place."""
    errs = []
    if not chip or chip[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    if chip[0][1] != 1:
        errs.append("P0 is driven low at cycle 0: it must be released until the enter sequence")
    edges = chip[1:]
    if not edges:
        return errs + ["the chip never moves P0"]
    first = edges[0][0]
    if edges[0][1] != 0:
        return errs + ["P0's first change is not a fall"]
    if not ENTRY_FIRST_MIN <= first <= ENTRY_FIRST_MAX:
        errs.append("the enter sequence starts at cycle %d, outside %d..%d"
                    % (first, ENTRY_FIRST_MIN, ENTRY_FIRST_MAX))
    ideal = table.entry(first)
    got = edges[:len(ideal)]
    if len(got) < len(ideal):
        return errs + ["only %d edges on P0, the enter sequence alone has %d" % (len(got), len(ideal))]
    last_rise_got, last_rise_ideal = first, first
    for k, ((c, lv), (ic, ilv)) in enumerate(zip(got, ideal)):
        if lv != ilv:
            errs.append("enter sequence edge %d goes the wrong way" % k)
            return errs
        if k == 0:
            continue
        if k == 1:
            if abs((c - first) - ENTRY_LOW) > TOL:
                errs.append("enter sequence: the first low lasts %d cycles, wanted %d +-%d"
                            % (c - first, ENTRY_LOW, TOL))
        else:
            off, want = c - last_rise_got, ic - last_rise_ideal
            lim = ENTRY_TOL_RISE if lv else ENTRY_TOL_FALL
            if abs(off - want) > lim:
                errs.append("enter sequence edge %d (a %s) is %d cycles after the rising edge "
                            "before it, wanted %d +-%d"
                            % (k, "rise" if lv else "fall", off, want, lim))
        if lv:
            last_rise_got, last_rise_ideal = c, ic
        if len(errs) > 2:
            return errs
    rest = edges[len(ideal):]
    if rest and rest[0][0] < SYNC_AT:
        errs.append("P0 moves at cycle %d, after the enter sequence and before the "
                    "synchronization frame" % rest[0][0])
        return errs
    want = table.host
    for k, ((c, lv), (ic, ilv, what)) in enumerate(zip(rest, want)):
        if lv != ilv or abs(c - ic) > TOL:
            errs.append("%s: the %s is at cycle %d, its place is %d +-%d"
                        % (what, "fall" if ilv else "rise", c, ic, TOL)
                        if lv == ilv else
                        "%s: wanted a %s at cycle %d, the chip's next edge is a %s at %d"
                        % (what, "rise" if ilv else "fall", ic, "rise" if lv else "fall", c))
            return errs
    if len(rest) > len(want):
        errs.append("%d edges more than the timetable has, the first at cycle %d"
                    % (len(rest) - len(want), rest[len(want)][0]))
    elif len(rest) < len(want):
        errs.append("the chip stops early: missing %s, a %s at cycle %d"
                    % (want[len(rest)][2], "rise" if want[len(rest)][1] else "fall",
                       want[len(rest)][0]))
    return errs


# ------------------------------------------------------------------ cases

def op_srst(cmd_nacks=0):
    return {"kind": SRST, "cmd_nacks": cmd_nacks}


def op_rotf(addr, data, cmd_nacks=0):
    return {"kind": ROTF, "addr": addr, "data": list(data), "cmd_nacks": cmd_nacks}


def op_wotf(addr, data, cmd_nacks=0, data_nacks=None):
    return {"kind": WOTF, "addr": addr, "data": list(data), "cmd_nacks": cmd_nacks,
            "data_nacks": list(data_nacks) if data_nacks else [0] * len(data)}


def random_op(rng, longest):
    kind = rng.choice((SRST, ROTF, WOTF, ROTF, WOTF))
    nack = lambda: rng.choice((0, 0, 0, 0, 0, 1, 2))
    if kind == SRST:
        return op_srst(nack())
    addr = rng.randrange(1 << 24) if rng.random() < 0.5 else rng.randrange(0x8000)
    data = [rng.randrange(256) for _ in range(rng.randint(1, longest))]
    if kind == ROTF:
        return op_rotf(addr, data, nack())
    return op_wotf(addr, data, nack(), [nack() for _ in data])


def cases_for(seed):
    """(name, ops): fixed cases, then seeded random ones."""
    fixed = [
        ("SRST alone", [op_srst()]),
        ("the start-up write: 0xA0 to SWIM_CSR", [op_wotf(0x007F80, [0xA0])]),
        ("the task sheet's example", [op_wotf(0x007F80, [0xA0]), op_rotf(0x004800, [0x5A, 0x00])]),
        ("write 4, read 4", [op_wotf(0x000100, [0xDE, 0xAD, 0xBE, 0xEF]),
                             op_rotf(0x000100, [0x00, 0xFF, 0x80, 0x01])]),
        ("NACKs", [op_srst(1), op_wotf(0xABCDEF, [0x11, 0x22, 0x33], 2, [0, 2, 1]),
                   op_rotf(0xFEDCBA, [0x96], 1), op_wotf(0x000000, [0xFF], 0, [1])]),
        ("ROTF of 255 bytes", [op_rotf(0x008000, [(k * 73 + 5) & 0xFF for k in range(255)])]),
        ("WOTF of 64 bytes", [op_wotf(0x00A5A5, [(k * 37 + 11) & 0xFF for k in range(64)])]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        longest = 40 if n % 2 else 6
        rand.append(("random %d" % n, [random_op(rng, longest) for _ in range(rng.randint(1, 5))]))
    return fixed + rand


# ------------------------------------------------------------------ running

def ideal_host_changes(table, first=1000):
    """The chip's ideal P0 output, (cycle, level) from cycle 0: used only to
    show that sigrok decodes the stimulus to the wanted content."""
    return [(0, 1)] + table.entry(first) + [(c, lv) for c, lv, _ in table.host]


def run_case(run_dir, args, ops):
    """(objections, cycles from P0's first change to its last or None)."""
    table = Timetable(ops)
    cycles = table.end
    # The stimulus must itself be SWIM, as sigrok reads it.
    ideal_wire = wire(ideal_host_changes(table), table.target, cycles)
    bad = content_problem(sigrok_tokens(ideal_wire, cycles), table.tokens)
    if bad:
        return ["judge: the stimulus with an ideal host does not decode: " + bad[0]], None
    with tempfile.TemporaryDirectory() as d:
        tx, stim = os.path.join(d, "tx.txt"), os.path.join(d, "stimulus.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in tx_words(ops)))
        with open(stim, "w") as f:
            f.write(stimulus_text(table.target))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "swim.s"),
               "-tx", tx, "-stimulus", stim, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=900)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    chip = p0_changes(out.stdout)
    errs = ["edges: " + e for e in edge_problems(chip, table)]
    if chip and chip[0][0] == 0:
        errs += ["decoder: " + e for e in
                 content_problem(sigrok_tokens(wire(chip, table.target, cycles), cycles), table.tokens)]
    got = rx_words(out.stdout)
    if got != table.rx:
        if len(got) != len(table.rx):
            errs.append("rx: %d words pushed, wanted %d" % (len(got), len(table.rx)))
        diff = [k for k, (g, w) in enumerate(zip(got, table.rx)) if g != w]
        if diff:
            errs.append("rx: word %d is 0x%04x, wanted 0x%04x" % (diff[0], got[diff[0]], table.rx[diff[0]]))
    moved = [c for c, _ in chip[1:]]
    return errs, (moved[-1] - moved[0] if moved else None)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "swim.s", "run_args.txt"):
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
    for n, (name, ops) in enumerate(cases_for(seed)):
        try:
            errs, span = run_case(run_dir, args, ops)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        size = sum(len(op.get("data", [])) for op in ops)
        if not errs:
            rate = (size, span)
        shown = []
        for kind in ("simulator:", "judge:", "edges:", "decoder:", "rx:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d operation%s, %d byte%s): %s"
              % (n, name, len(ops), "" if len(ops) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
