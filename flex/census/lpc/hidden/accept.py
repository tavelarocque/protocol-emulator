#!/usr/bin/env python3
"""Hidden acceptance test for the blind LPC host firmware (sigrok decoder `lpc`).

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (lpc.s, run_args.txt) and pe_sim, which may be a
wrapper script: it is always invoked as RUN_DIR/pe_sim.

The chip is the LPC host. It drives LCLK (P5), LFRAME# (P4) and, during the
host's part of each cycle, LAD[3:0] (P0..P3, open-drain). A scripted
peripheral answers each read with SYNC, two data nibbles and TAR at fixed
times, given to the simulator as -stimulus. The task sheet fixes when every
LCLK rising edge and every transaction belongs, so the script lines up.

For each case (a list of transactions: I/O read or memory read, an address,
the byte the peripheral returns) the test
  1. builds the TX words the task sheet defines and the peripheral's
     stimulus, and first requires sigrok's `lpc` decoder to decode an ideal
     capture of the whole bus (ideal host plus that stimulus) to exactly the
     wanted transactions, so the input is a real instance of the protocol;
  2. runs RUN_DIR/pe_sim on RUN_DIR/lpc.s with those words and the stimulus;
  3. works out the wire level of every pin in every cycle (push-pull: the
     chip's output; open-drain: the chip's output AND the peripheral's);
  4. checks the waveform directly: every LCLK rising edge within +-2 cycles
     of its place, high and low at least 6 cycles, no change of a line the
     chip drives in the cycle of a rising edge or the one before, LFRAME#
     low only around START clocks, LAD released by the chip outside its
     part of each transaction, and the level sampled at every rising edge
     equal to the ideal bus;
  5. samples the wire at each rising edge, builds a logic capture from those
     samples and has sigrok-cli's `lpc` decoder read it: its annotations
     must be exactly the wanted transactions, in order, with no warning and
     nothing extra (see README.md for the one-clock LFRAME# adjustment the
     0.7.2 decoder needs);
  6. requires the "rx" words to be the bytes read, in order, nothing extra.

Prints one line per case, then for the last passing case
    RATE bytes=<data bytes read> cycles=<cycles from first to last pin change>
and a last line ACCEPT PASS or ACCEPT FAIL. Exit status 0 only on a full
pass. Python standard library and sigrok-cli only."""
import os
import random
import shlex
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

CLOCK_HZ = 50_000_000      # core clock: one cycle = 20 ns
PERIOD = 20                # cycles per LCLK period (2.5 MHz)
R0 = 100                   # ideal cycle of LCLK rising edge 0
TOL = 2                    # cycles a rising edge may be from its place
MIN_PHASE = 6              # cycles LCLK must stay high, and low
SLOT = 24                  # LCLK clocks per transaction slot
FIRST = 4                  # clock of transaction 0's START
DEV_DELAY = 4              # the peripheral changes LAD this long after an ideal rising edge
MAX_TRANS = 8

LAD_PINS = (0, 1, 2, 3)
LFRAME = 4
LCLK = 5
REQUIRED_MODES = {0: "od", 1: "od", 2: "od", 3: "od", 4: "pp", 5: "pp"}
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")

IO, MEM = 0, 1
CT_DR = {IO: 0b0000, MEM: 0b0100}
ADDR_NIBBLES = {IO: 4, MEM: 8}


# ------------------------------------------------------------ the schedule

def R(k):
    """Ideal cycle of LCLK rising edge k (the edge that ends clock k)."""
    return R0 + PERIOD * k


def start_clock(n):
    return FIRST + SLOT * n


def length(kind):
    """Clocks in one read: START, CT/DIR, address, TAR x2, SYNC, data x2, TAR x2."""
    return 1 + 1 + ADDR_NIBBLES[kind] + 2 + 1 + 2 + 2


def tar_clock(n, kind):
    """The first TAR clock of transaction n."""
    return start_clock(n) + 2 + ADDR_NIBBLES[kind]


def last_clock(trans):
    n = len(trans) - 1
    return start_clock(n) + length(trans[n][0]) - 1


def run_cycles(trans):
    """To the ideal start of the slot after the last transaction."""
    return R(start_clock(len(trans)))


def ideal_bus(trans):
    """[(lframe, lad)] sampled at rising edges 0 .. last_clock(trans)."""
    bus = [(1, 0xF)] * (last_clock(trans) + 1)
    for n, (kind, addr, data) in enumerate(trans):
        s = start_clock(n)
        nib = ADDR_NIBBLES[kind]
        seq = [(0, 0x0), (1, CT_DR[kind])]
        seq += [(1, (addr >> (4 * (nib - 1 - i))) & 0xF) for i in range(nib)]
        seq += [(1, 0xF), (1, 0xF), (1, 0x0), (1, data & 0xF), (1, data >> 4), (1, 0xF), (1, 0xF)]
        bus[s:s + len(seq)] = seq
    return bus


# ------------------------------------------------------- the host interface

def tx_words(trans):
    """The task sheet's words: per transaction, the type (0 I/O read, 1
    memory read), then the address: one word for I/O, the high then the low
    half for memory. Payload only."""
    words = []
    for kind, addr, _ in trans:
        words.append(kind)
        if kind == MEM:
            words += [(addr >> 16) & 0xFFFF, addr & 0xFFFF]
        else:
            words.append(addr & 0xFFFF)
    return words


def rx_words(trans):
    return [data for _, _, data in trans]


def stimulus(trans):
    """[(cycle, hex)]: the peripheral's LAD (bits 0..3; 1 = not driving,
    pulled up), all other bits 1. It drives SYNC 0000, the low nibble, the
    high nibble, then 1111, each from DEV_DELAY cycles after the ideal
    rising edge that ends the clock before."""
    lines = [(0, 0xFF)]
    for n, (kind, _, data) in enumerate(trans):
        t = tar_clock(n, kind)
        lines += [(R(t + 1) + DEV_DELAY, 0xF0),
                  (R(t + 2) + DEV_DELAY, 0xF0 | (data & 0xF)),
                  (R(t + 3) + DEV_DELAY, 0xF0 | (data >> 4)),
                  (R(t + 4) + DEV_DELAY, 0xFF)]
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
    """The pe_sim flag an argument names, or None (prefixes allowed)."""
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
        return ("pin modes must be P0..P3 od (LAD), P4 pp (LFRAME#), P5 pp (LCLK); got "
                + ", ".join(bad))
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
    """Expand [(cycle, value)] into a list of one value per cycle."""
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


# ------------------------------------------------------------- the checks

def check_waveform(trans, out, wire):
    """The limits of the task sheet, from the pins themselves.
    Returns (objections, rising edges)."""
    errs = []
    cycles = len(wire)
    clk = [bit(w, LCLK) for w in wire]
    rises = [c for c in range(1, cycles) if clk[c] and not clk[c - 1]]
    falls = [c for c in range(1, cycles) if not clk[c] and clk[c - 1]]
    K = last_clock(trans)

    # LCLK: every rising edge on its place; none missing up to the last clock.
    for k, e in enumerate(rises):
        if abs(e - R(k)) > TOL:
            errs.append("LCLK rising edge %d at cycle %d, ideal %d (limit +-%d)" % (k, e, R(k), TOL))
            break
    if len(rises) < K + 1:
        errs.append("LCLK has %d rising edges, the transactions need %d (to cycle %d)"
                    % (len(rises), K + 1, R(K)))
    # High and low phases.
    edges = sorted([(c, 1) for c in rises] + [(c, 0) for c in falls])
    for (a, lvl), (b, _) in zip(edges, edges[1:]):
        if b - a < MIN_PHASE:
            errs.append("LCLK %s for %d cycles from cycle %d (at least %d)"
                        % ("high" if lvl else "low", b - a, a, MIN_PHASE))
            break
    if rises and falls and falls[0] > rises[0]:
        errs.append("LCLK rose at cycle %d before it ever fell" % rises[0])
    elif rises and falls and rises[0] - falls[0] < MIN_PHASE:
        errs.append("LCLK low for only %d cycles before edge 0" % (rises[0] - falls[0]))

    # Setup and hold: lines the chip drives do not change at E-1 or E.
    drove = [(o & 0x0F) | (bit(o, LFRAME) << 4) for o in out]
    rise_set = set(rises)
    for c in range(1, cycles):
        if drove[c] != drove[c - 1] and (c in rise_set or c + 1 in rise_set):
            e = c if c in rise_set else c + 1
            errs.append("LFRAME#/LAD output changes at cycle %d, %s the LCLK rising edge at %d"
                        % (c, "in the cycle of" if c == e else "one cycle before", e))
            break

    # Windows: LFRAME# low and LAD driven only where the chip owns them.
    def E(k):
        return rises[k] if 0 <= k < len(rises) else None

    lf_ok = [False] * cycles
    lad_ok = [False] * cycles
    for n, (kind, _, _) in enumerate(trans):
        s, t = start_clock(n), tar_clock(n, kind)
        if E(s + 1) is None or E(t) is None:
            continue
        for c in range(E(s - 1) + 1, E(s + 1)):
            lf_ok[c] = True
        for c in range(E(s - 1) + 1, E(t)):
            lad_ok[c] = True
    for c in range(cycles):
        if not bit(out[c], LFRAME) and not lf_ok[c]:
            errs.append("LFRAME# low at cycle %d, outside a START clock" % c)
            break
    for c in range(cycles):
        if (out[c] & 0xF) != 0xF and not lad_ok[c]:
            errs.append("the chip drives LAD (outputs %s) at cycle %d, outside its part of a transaction"
                        % (format(out[c] & 0xF, "04b")[::-1], c))
            break
    lf = [bit(w, LFRAME) for w in wire]
    falls_lf = sum(1 for c in range(1, cycles) if lf[c - 1] and not lf[c])
    if falls_lf != len(trans):
        errs.append("LFRAME# falls %d times, wanted %d (one per transaction)" % (falls_lf, len(trans)))

    # The bus as sampled at every rising edge, against the ideal bus.
    want = ideal_bus(trans)
    for k in range(min(len(want), len(rises))):
        w = wire[rises[k] - 1]
        got = (bit(w, LFRAME), w & 0xF)
        if got != want[k]:
            errs.append("at rising edge %d (cycle %d) LFRAME#=%d LAD=%s, wanted LFRAME#=%d LAD=%s"
                        % (k, rises[k], got[0], format(got[1], "04b"), want[k][0],
                           format(want[k][1], "04b")))
            break
    return errs, rises


def decoder_capture(samples):
    """A binary capture, 8 channels, two samples per LCLK clock (low, high),
    from the (lframe, lad) sampled at each rising edge. The 0.7.2 decoder
    takes the first LAD value after it sees LFRAME# high as START, one clock
    late, so LFRAME# is presented one clock early (README.md)."""
    data = bytearray()
    for k, (_, lad) in enumerate(samples):
        lf = samples[k + 1][0] if k + 1 < len(samples) else 1
        base = lad | (lf << LFRAME)
        data.append(base)
        data.append(base | (1 << LCLK))
    return bytes(data)


def want_annotations(trans):
    out = []
    for kind, addr, data in trans:
        out += ["Start of cycle for a target",
                "Cycle type: " + ("I/O read" if kind == IO else "Memory read"),
                ("Address: 0x%04x" % addr) if kind == IO else ("Address: 0x%08x" % addr),
                "TAR, cycle 0: 1111", "TAR, cycle 1: 1111", "SYNC, cycle 0: 0000",
                "DATA: 0x%02x" % data,
                "TAR, cycle 0: 1111", "TAR, cycle 1: 1111"]
    return out


def sigrok_annotations(samples):
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "lpc.bin")
        with open(path, "wb") as f:
            f.write(decoder_capture(samples))
        cmd = ["sigrok-cli", "-i", path, "-I", "binary:numchannels=8:samplerate=5000000",
               "-P", "lpc:lad0=0:lad1=1:lad2=2:lad3=3:lframe=4:lclk=5", "-A", "lpc"]
        run = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if run.returncode != 0 or "srd:" in run.stderr or "Traceback" in run.stderr:
        raise RuntimeError("sigrok-cli failed: " + " ".join(run.stderr.split())[:200])
    got = []
    for line in run.stdout.splitlines():
        if line.startswith("lpc-1: "):
            got.append(line[len("lpc-1: "):])
    return got


def compare_annotations(got, want):
    if got == want:
        return []
    for i, (g, w) in enumerate(zip(got, want)):
        if g != w:
            return ["annotation %d is %r, wanted %r" % (i, g, w)]
    return ["%d annotations, wanted %d (first extra or missing: %r)"
            % (len(got), len(want), (got[len(want):] or want[len(got):])[0])]


def check_decoder(trans, wire, rises):
    samples = [(bit(wire[e - 1], LFRAME), wire[e - 1] & 0xF) for e in rises]
    return compare_annotations(sigrok_annotations(samples), want_annotations(trans))


def check_stimulus(trans):
    """Sigrok must read the ideal bus (ideal host plus the stimulus) as the
    wanted transactions: the scripted peripheral is a real LPC peripheral."""
    bus = ideal_bus(trans) + [(1, 0xF)] * 3
    return compare_annotations(sigrok_annotations(bus), want_annotations(trans))


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
    errs, rises = check_waveform(trans, out, wire)
    errs = ["waveform: " + e for e in errs]
    try:
        errs += ["decoder: " + e for e in check_decoder(trans, wire, rises)]
    except Exception as e:  # a decoder that falls over is a failure
        errs.append("decoder: %s: %s" % (type(e).__name__, e))
    errs += ["rx: " + e for e in check_rx(trans, rx)]
    return errs


# ------------------------------------------------------------------ running

def run_case(run_dir, args, modes, trans):
    """(objections, cycles from the first pin change to the last or None)."""
    bad = check_stimulus(trans)
    if bad:
        return ["judge: the stimulus does not decode: " + bad[0]], None
    cycles = run_cycles(trans)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in tx_words(trans)))
        st = os.path.join(d, "stimulus.txt")
        with open(st, "w") as f:
            f.write("".join("%d %02x\n" % (c, v) for c, v in stimulus(trans)))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "lpc.s"),
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


def cases_for(seed):
    """(name, transactions): fixed cases, then seeded random ones. A
    transaction is (kind, address, data byte)."""
    fixed = [
        ("POST port read", [(IO, 0x0080, 0x5A)]),
        ("memory read, all ones", [(MEM, 0xFFFFFFFF, 0xFF)]),
        ("I/O read, all zeros", [(IO, 0x0000, 0x00)]),
        ("every nibble value", [(MEM, 0x01234567, 0x10), (MEM, 0x89ABCDEF, 0xFE),
                                (IO, 0x5AA5, 0x81)]),
        ("eight alternating", [(n % 2, (0xFFC0F00F + n * 0x1111) & (0xFFFF if n % 2 == 0 else 0xFFFFFFFF),
                                (0x0F << (4 * (n % 2))) ^ n) for n in range(MAX_TRANS)]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_TRANS) if n % 2 else rng.randint(1, 3)
        trans = []
        for _ in range(count):
            kind = rng.choice((IO, MEM))
            addr = rng.randrange(1 << 16) if kind == IO else rng.randrange(1 << 32)
            trans.append((kind, addr, rng.randrange(256)))
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
    for name in ("pe_sim", "lpc.s", "run_args.txt"):
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
            rate = (len(trans), span)
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
