#!/usr/bin/env python3
"""Hidden acceptance test for the blind MIPI DSI low-power (escape mode,
LPDT) transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (mipi_dsi.s, run_args.txt) and pe_sim, which may be
a wrapper script: it is always invoked as RUN_DIR/pe_sim. The task sheet fixes
what the TX words mean, and this test builds them itself.

For each case (a list of DSI packets) the test
  1. builds the TX words the task sheet defines, which carry only each
     packet's content: a word with the data identifier (bits 7..0) and
     bit 8 set for a long packet; a word with the two short-packet
     parameters, or the long packet's word count; then, for a long packet,
     one word per payload byte. It also forms each packet as the firmware
     must put it on the wire: header, ECC, payload, checksum,
  2. runs RUN_DIR/pe_sim on RUN_DIR/mipi_dsi.s with those words and the
     flags in run_args.txt (-config and -mode only, P0 to P3 push-pull),
  3. turns the printed changes of P0 (Dp) and P1 (Dn) into a logic capture
     (a VCD file, one sample per core clock cycle, 50 MHz), exactly as
     printed,
  4. has the MIPI_DSI decoder (DSView's, ported to sigrok-cli 0.7.2 by
     mechanical changes only, see PORT.diff) read it, and requires its
     annotations to be exactly, per packet, "Escape mode entry", the LPDT
     entry command (0x87 as the decoder reads it), every byte of the packet
     in order (so the ECC and the checksum the firmware computed are checked
     byte for byte), and "Stop", with nothing else,
  5. checks, from the pin changes themselves, what the decoder does not:
     the exact sequence of lane states of each transmission, one data line
     changing at a time, every state 3 to 50 cycles long, the first
     transmission between cycle 5000 and 10000, Stop state between
     transmissions for 3 to 1000 cycles, the clock lane (P2, P3) held in
     LP-11 throughout, and no change after the last transmission.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<packet bytes on the wire> cycles=<cycles from the first change on P0..P3 to the last>
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

# The round-2 decoder folder: sigrok-cli 0.7.2's decoders plus the round-2
# ones, with MIPI_DSI ported as PORT.diff shows. MIPI_DSI_DECODERS overrides it.
DECODERS = os.environ.get(
    "MIPI_DSI_DECODERS",
    "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders")

CLOCK_HZ = 50_000_000        # core clock: one cycle = 20 ns
STATE_MIN = 3                # cycles: every LP state of a transmission, at least (60 ns >= TLPX 50 ns)
STATE_MAX = 50               # and at most (1 us), the sheet's own limit
INIT_MIN = 5_000             # T_INIT, 100 us of Stop state before the first transmission
INIT_MAX = 10_000            # the first transmission begins no later than this cycle
GAP_MIN = 3                  # Stop state between transmissions, at least (TLPX, as every LP state)
GAP_MAX = 1_000              # and at most (20 us)
MAX_PAYLOAD = 26             # payload bytes of a long packet, 0 to this (the sheet's limit, to keep runs short)
MAX_BYTES = 6 + MAX_PAYLOAD  # so a transmission is 4 to 32 bytes
MAX_TX = 6                   # packets (one transmission each) in one run
LONG = 0x100                 # bit 8 of a packet's first TX word: a long packet
LPDT = [1, 1, 1, 0, 0, 0, 0, 1]   # the LPDT entry command, in the order sent
DP, DN, CLKP, CLKN = 0, 1, 2, 3   # pins
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")  # pe_sim run's
DECODER = "MIPI_DSI:D0N=P1:D0P=P0"
STOP = (1, 1)
NAMES = {(1, 1): "LP-11", (1, 0): "LP-10", (0, 1): "LP-01", (0, 0): "LP-00"}


# ------------------------------------------------------------------ the code

def tx_bits(data):
    """The bits of one transmission after the escape entry, in the order
    sent: the LPDT command, then each byte least significant bit first."""
    return LPDT + [(b >> k) & 1 for b in data for k in range(8)]


def lane_states(data):
    """The states (Dp, Dn) data lane 0 takes in one transmission, in order,
    after the Stop state it starts from: the escape entry, a mark and a
    space per bit, the Mark-1 and the Stop state that end it."""
    out = [(1, 0), (0, 0), (0, 1), (0, 0)]
    for b in tx_bits(data):
        out += [(1, 0) if b else (0, 1), (0, 0)]
    return out + [(1, 0), STOP]


def decoder_wants(data):
    """The annotations the decoder gives one correct transmission. It reads
    every eight bits after the escape entry least significant bit first, the
    entry command included, so LPDT's 1,1,1,0,0,0,0,1 reads 0x87."""
    return (["Escape mode entry", "0x87"] + ["0x%02X" % b for b in data] + ["Stop"])


# --------------------------------------------- DSI packets, the test's content

ECC_COLUMNS = [0x07, 0x0B, 0x0D, 0x0E, 0x13, 0x15, 0x16, 0x19, 0x1A, 0x1C, 0x23, 0x25,
               0x26, 0x29, 0x2A, 0x2C, 0x31, 0x32, 0x34, 0x38, 0x1F, 0x2F, 0x37, 0x3B]


def ecc(b0, b1, b2):
    """DSI's packet header ECC (P0..P5 of the 24 header bits, P6 = P7 = 0)."""
    d = b0 | b1 << 8 | b2 << 16
    e = 0
    for i, col in enumerate(ECC_COLUMNS):
        if d >> i & 1:
            e ^= col
    return e


def checksum(payload):
    """DSI's long packet checksum: CRC-16, x^16 + x^12 + x^5 + 1, from 0xFFFF,
    bits taken least significant first."""
    c = 0xFFFF
    for b in payload:
        for k in range(8):
            if (c ^ (b >> k)) & 1:
                c = (c >> 1) ^ 0x8408
            else:
                c >>= 1
    return c


def short_packet(dt, vc, d0, d1):
    """A packet as the host knows it: its content only."""
    return ("short", (vc << 6) | dt, d0, d1)


def long_packet(dt, vc, payload):
    return ("long", (vc << 6) | dt, list(payload))


def wire(packet):
    """The bytes of a packet on the wire, in order: data identifier, two
    header bytes (the parameters, or the word count low byte first), the ECC
    over those 24 bits, and for a long packet the payload and the checksum,
    low byte first."""
    if packet[0] == "short":
        _, di, d0, d1 = packet
        return [di, d0, d1, ecc(di, d0, d1)]
    _, di, payload = packet
    wc0, wc1 = len(payload) & 0xFF, len(payload) >> 8
    c = checksum(payload)
    return [di, wc0, wc1, ecc(di, wc0, wc1)] + list(payload) + [c & 0xFF, c >> 8]


# ------------------------------------------------------- the host interface

def tx_words(packets):
    """The TX words of one run, as the task sheet defines them. Per packet:
    the data identifier in bits 7..0, with bit 8 set for a long packet; then
    the two parameters (first in bits 7..0, second in bits 15..8) of a short
    packet, or the word count of a long one; then one word per payload byte
    of a long packet, in bits 7..0. Content only: no ECC, no checksum and
    nothing about the lane."""
    words = []
    for packet in packets:
        if packet[0] == "short":
            _, di, d0, d1 = packet
            words += [di, d0 | d1 << 8]
        else:
            _, di, payload = packet
            words += [di | LONG, len(payload)] + list(payload)
    return words


def args_problem(args):
    """run_args.txt may hold -config and -mode flags, each with a value, and
    nothing else (pe_sim takes any unambiguous prefix of a flag's name). The
    -mode flags must leave P0 to P3 push-pull."""
    i, modes = 0, {}
    while i < len(args):
        name = args[i][1:] if args[i].startswith("-") else None
        hits = [name] if name in SIM_FLAGS else [f for f in SIM_FLAGS if name and f.startswith(name)]
        if hits == ["tx"] or hits == ["cycles"]:
            return "run_args.txt must not give -%s: the test does" % hits[0]
        if len(hits) != 1 or hits[0] not in ("config", "mode"):
            return "run_args.txt may hold only -config and -mode flags, not %r" % args[i]
        if i + 1 >= len(args):
            return "run_args.txt: %s has no value" % args[i]
        if hits[0] == "mode":
            m = re.match(r"^([0-7])=(pp|od|in)$", args[i + 1])
            if not m:
                return "run_args.txt: -mode %r is not P=pp|od|in" % args[i + 1]
            modes[int(m.group(1))] = m.group(2)
        i += 2
    wrong = [p for p in (DP, DN, CLKP, CLKN) if modes.get(p) != "pp"]
    if wrong:
        return "run_args.txt must make P0 to P3 push-pull (-mode P=pp); not so for %s" % (
            ", ".join("P%d" % p for p in wrong))
    return None


# ------------------------------------------------- from pe_sim to a capture

def pin_lines(sim_stdout):
    """[(cycle, register)] from pe_sim's "pins CYCLE XX" lines."""
    out = []
    for line in sim_stdout.splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            out.append((int(part[1]), int(part[2], 16)))
    return out


def changes_of(lines, pins):
    """[(cycle, levels)] of the given pins: the levels at the first line,
    then only the cycles at which one of them changed."""
    out = []
    for cycle, reg in lines:
        levels = tuple((reg >> p) & 1 for p in pins)
        if not out or out[-1][1] != levels:
            out.append((cycle, levels))
    return out


def write_vcd(path, lane, cycles):
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$var wire 1 \" P1 $end\n"
                "$upscope $end\n$enddefinitions $end\n")
        for cycle, (dp, dn) in lane:
            if cycle < cycles:
                f.write("#%d\n%d!\n%d\"\n" % (cycle, dp, dn))
        f.write("#%d\n" % cycles)


def sigrok_annotations(lane, cycles):
    """The MIPI_DSI decoder on the capture: its annotations' texts, in order."""
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "lane0.vcd")
        write_vcd(path, lane, cycles)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", DECODER,
               "-A", "MIPI_DSI", "--protocol-decoder-samplenum"]
        env = dict(os.environ, SIGROKDECODE_DIR=DECODERS)
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=600, env=env)
    if out.returncode != 0 or "srd:" in out.stderr or "Traceback" in out.stderr:
        raise RuntimeError("sigrok-cli failed: " + " ".join(out.stderr.split())[:200])
    found = []
    for line in out.stdout.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append(m.group(3).strip())
    return found


# ------------------------------------------------------------ the two checks

def check_decoder(transmissions, lane, cycles):
    """The decoder's annotations must be exactly the wanted ones."""
    got = sigrok_annotations(lane, cycles)
    want = [a for data in transmissions for a in decoder_wants(data)]
    if got == want:
        return []
    i = next((i for i in range(min(len(got), len(want))) if got[i] != want[i]),
             min(len(got), len(want)))
    k = sum(1 for a in want[:i] if a == "Stop")
    j = i - sum(len(decoder_wants(d)) for d in transmissions[:k])
    field = "?"
    if k < len(transmissions):
        n = len(transmissions[k])
        field = ({0: "escape entry", 1: "entry command", 2: "data identifier", 3: "header byte 1",
                  4: "header byte 2", 5: "ECC"}.get(j)
                 or ("Stop" if j == n + 2 else "checksum" if j >= n and n > 4 else "payload"))
    return ["annotation %d (packet %d, %s) is %r, wanted %r; %d annotations, wanted %d"
            % (i, k, field, got[i] if i < len(got) else "nothing", want[i] if i < len(want) else "nothing",
               len(got), len(want))]


def where(data, i):
    """State i of a transmission (counted after its starting Stop state), in words."""
    if i < 4:
        return "escape entry state %d" % i
    j = i - 4
    nbits = 8 + 8 * len(data)
    if j < 2 * nbits:
        bit, half = divmod(j, 2)
        part = "space" if half else "mark"
        if bit < 8:
            return "the %s of LPDT command bit %d" % (part, bit)
        bit -= 8
        return "the %s of bit %d of byte %d" % (part, bit % 8, bit // 8)
    return "exit state %d" % (j - 2 * nbits)


def check_waveform(transmissions, lines, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    errs = []
    if not lines or lines[0][0] != 0:
        return ["no pin levels at cycle 0 in the simulator's output"]
    clock = changes_of(lines, (CLKP, CLKN))
    if clock[0][1] != (1, 1) or len(clock) > 1:
        bad = clock[1] if len(clock) > 1 else clock[0]
        errs.append("the clock lane leaves LP-11: %s at cycle %d" % (NAMES[bad[1]], bad[0]))
    lane = changes_of(lines, (DP, DN))
    if lane[0][1] != STOP:
        return errs + ["data lane 0 does not start in LP-11"]
    # Every change of the lane must move exactly one of Dp and Dn.
    for (c0, s0), (c1, s1) in zip(lane, lane[1:]):
        if s0[0] != s1[0] and s0[1] != s1[1]:
            errs.append("Dp and Dn change in the same cycle %d (%s to %s)" % (c1, NAMES[s0], NAMES[s1]))
            break
    # Cut the lane into transmissions: each starts on leaving LP-11 and ends
    # on entering it again.
    groups, cur = [], None
    for cycle, state in lane[1:]:
        if cur is None:          # the lane was in LP-11, so this leaves it
            cur = [(cycle, state)]
            continue
        cur.append((cycle, state))
        if state == STOP:
            groups.append(cur)
            cur = None
    if cur is not None:
        errs.append("data lane 0 is not back in LP-11 at the end of the run (left it at cycle %d, now %s)"
                    % (cur[0][0], NAMES[cur[-1][1]]))
        groups.append(cur)
    if len(groups) != len(transmissions):
        errs.append("%d transmissions on data lane 0 (runs of states between Stop states), wanted %d"
                    % (len(groups), len(transmissions)))
    prev_end = None
    for k, (g, data) in enumerate(zip(groups, transmissions)):
        want = lane_states(data)
        got = [s for _, s in g]
        for i, (a, w) in enumerate(zip(got, want)):
            if a != w:
                errs.append("transmission %d: state %d (%s) is %s, wanted %s"
                            % (k, i, where(data, i), NAMES[a], NAMES[w]))
                break
        else:
            if len(got) != len(want):
                errs.append("transmission %d: %d states, wanted %d" % (k, len(got), len(want)))
        for i in range(len(g) - 1):
            d = g[i + 1][0] - g[i][0]
            if d < STATE_MIN or d > STATE_MAX:
                errs.append("transmission %d: state %d (%s, %s) lasts %d cycles, limits %d to %d"
                            % (k, i, where(data, i), NAMES[g[i][1]], d, STATE_MIN, STATE_MAX))
                break
        if k == 0:
            if g[0][0] < INIT_MIN:
                errs.append("the first transmission begins at cycle %d, not before %d allowed"
                            % (g[0][0], INIT_MIN))
            elif g[0][0] > INIT_MAX:
                errs.append("the first transmission begins at cycle %d, limit %d" % (g[0][0], INIT_MAX))
        else:
            gap = g[0][0] - prev_end
            if gap < GAP_MIN:
                errs.append("Stop state before transmission %d lasts %d cycles, at least %d wanted"
                            % (k, gap, GAP_MIN))
            elif gap > GAP_MAX:
                errs.append("Stop state before transmission %d lasts %d cycles, at most %d allowed"
                            % (k, gap, GAP_MAX))
        prev_end = g[-1][0]
    if (groups and len(groups) == len(transmissions) and lane[-1][1] == STOP
            and cycles - prev_end < GAP_MAX):
        errs.append("the run ended %d cycles after the last transmission, too soon to see the Stop state"
                    % (cycles - prev_end))
    return errs


def judge(transmissions, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    lines = pin_lines(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(transmissions, lines, cycles)]
    if lines and lines[0][0] == 0:
        lane = changes_of(lines, (DP, DN))
        errs += ["decoder: " + e for e in check_decoder(transmissions, lane, cycles)]
    return errs


# ------------------------------------------------------------------ running

def run_cycles(transmissions):
    """The sheet's N: long enough for the latest start, the longest states
    and the longest Stop states allowed, with room after."""
    return INIT_MAX + 1000 + sum(GAP_MAX + STATE_MAX * (21 + 16 * len(d)) for d in transmissions)


def span(sim_stdout):
    """Cycles from the first change on P0..P3 to the last, or None."""
    moved = [c for c, _ in changes_of(pin_lines(sim_stdout), (DP, DN, CLKP, CLKN))[1:]]
    return moved[-1] - moved[0] if moved else None


def run_case(run_dir, args, packets):
    """(objections, cycles from the first change on P0..P3 to the last, or None)."""
    words = tx_words(packets)
    transmissions = [wire(p) for p in packets]
    cycles = run_cycles(transmissions)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run", os.path.join(run_dir, "mipi_dsi.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    return judge(transmissions, out.stdout, cycles), span(out.stdout)


SHORT_TYPES = [0x03, 0x13, 0x23, 0x05, 0x15, 0x37, 0x06, 0x14, 0x24]   # short packet data types
LONG_TYPES = [0x29, 0x39]                                               # generic and DCS long write


def random_packet(rng, any_type):
    """A DSI packet. With any_type, any of the 64 data types, short or long
    at random (the firmware takes the kind from bit 8, not from the type);
    otherwise a type a host sends in LPDT."""
    vc = rng.randrange(4)
    short = rng.random() < 0.4
    if any_type:
        dt = rng.randrange(64)
    else:
        dt = rng.choice(SHORT_TYPES if short else LONG_TYPES)
    if short:
        return short_packet(dt, vc, rng.randrange(256), rng.randrange(256))
    n = rng.randint(0, MAX_PAYLOAD)
    return long_packet(dt, vc, [rng.randrange(256) for _ in range(n)])


def cases_for(seed):
    """(name, packets): fixed cases, then seeded random ones."""
    pixels = [(k * 37 + 11) & 0xFF for k in range(25)]
    fixed = [
        ("the task sheet's example, exit sleep mode", [short_packet(0x05, 0, 0x11, 0x00)]),
        ("the task sheet's words, exit sleep then column address set",
         [short_packet(0x05, 0, 0x11, 0x00), long_packet(0x39, 0, [0x2A, 0x00, 0x00, 0x00, 0xEF])]),
        ("short packets: all header bits 1, all 0, alternating",
         [short_packet(0x3F, 3, 0xFF, 0xFF), short_packet(0x00, 0, 0x00, 0x00),
          short_packet(0x15, 1, 0x55, 0xAA), short_packet(0x2A, 2, 0xAA, 0x55)]),
        ("a 32-byte DCS long write (memory write, 25 pixel bytes)",
         [long_packet(0x39, 0, [0x2C] + pixels)]),
        ("six packets: init commands on virtual channels 0 to 3, an empty long packet",
         [short_packet(0x15, 0, 0x36, 0x48), short_packet(0x15, 1, 0x3A, 0x55),
          long_packet(0x39, 2, [0x2A, 0x00, 0x00, 0x00, 0xEF]), short_packet(0x37, 3, 0x02, 0x00),
          long_packet(0x29, 0, []), short_packet(0x03, 0, 0x00, 0x00)]),
        ("long packets of 26 bytes 0xFF, 26 bytes 0x00, one byte 0x80",
         [long_packet(0x29, 1, [0xFF] * 26), long_packet(0x39, 0, [0x00] * 26),
          long_packet(0x29, 3, [0x80])]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, MAX_TX)
        rand.append(("random %d, %s" % (n, "any data type" if n % 2 == 0 else "LPDT command types"),
                     [random_packet(rng, n % 2 == 0) for _ in range(count)]))
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
    if not os.path.exists(os.path.join(DECODERS, "MIPI_DSI", "pd.py")):
        setup.append("the MIPI_DSI decoder is not in %s" % DECODERS)
    for name in ("pe_sim", "mipi_dsi.s", "run_args.txt"):
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
    for n, (name, packets) in enumerate(cases_for(seed)):
        try:
            errs, cyc = run_case(run_dir, args, packets)
        except Exception as e:  # never report a pass because the judge fell over
            errs, cyc = ["judge: %s: %s" % (type(e).__name__, e)], None
        size = sum(len(wire(p)) for p in packets)
        if not errs:
            rate = (size, cyc)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        print("case %d (%s: %d packet%s, %d byte%s on the wire): %s"
              % (n, name, len(packets), "" if len(packets) == 1 else "s",
                 size, "" if size == 1 else "s", status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
