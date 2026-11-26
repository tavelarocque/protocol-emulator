#!/usr/bin/env python3
"""Hidden acceptance test for the blind USB Power Delivery transmitter firmware.

Usage: accept.py RUN_DIR [seed]

RUN_DIR holds the hand-in (usb_power_delivery.s, run_args.txt) and pe_sim,
which may be a wrapper script: it is always invoked as RUN_DIR/pe_sim. There
is no host-side code: the task sheet fixes what the TX words mean, and this
test builds them itself.

For each case (a list of packets: SOP kind, header, data objects) the test
  1. builds the TX words the task sheet defines: a first word holding the
     SOP kind (bits 1..0) and the number of data objects (bits 4..2), then
     the header, then each data object as two words, low half first,
  2. runs RUN_DIR/pe_sim on RUN_DIR/usb_power_delivery.s with those words,
  3. turns the printed changes of P0 into a logic capture (a VCD file, one
     sample per core clock cycle, 20 MHz),
  4. has sigrok-cli's `usb_power_delivery` decoder (CC1 = P0) read it and
     requires, packet by packet and in order with nothing extra: the right
     start of packet, the header, every data object, the CRC-32 the
     packet's content gives, an EOP, and no decoder warning,
  5. checks, from the pin changes themselves, what the decoder does not:
     P0 low from cycle 100 until the first preamble, every transition of a
     packet within +-2 cycles of its ideal place counted from the packet's
     first transition (this covers the 64-bit preamble, the bit rate, the
     biphase mark code and the closing transitions after the EOP), the gap
     between packets, the first packet within 2 ms, and silence after the
     last packet.

Prints one line per case, then one line for the last case that passed,
    RATE bytes=<payload bytes> cycles=<cycles from the first packet's first
    transition to the last packet's last transition>
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
import zlib

sys.dont_write_bytecode = True

CLOCK_HZ = 20_000_000        # core clock: one cycle = 50 ns
UI = 66                      # cycles a bit (3.3 us, 303.03 kbit/s)
HALF = UI // 2               # 33 cycles a half bit
TOL = 2                      # cycles a transition may be from its ideal place
LOW_BY = 100                 # P0 must be low from this cycle until the first preamble
GAP_MIN = 500                # 25 us: tInterFrameGap
GAP_MAX = 40_000             # 2 ms
START_MAX = 40_000           # the first preamble begins by this cycle
MAX_OBJECTS = 7              # data objects in a packet, 0 to this
SIM_FLAGS = ("config", "cycles", "inputs", "mode", "stimulus", "tx", "help")
SPLIT = 3 * UI               # more silence than this between two transitions
                             # ends a packet (the decoder's own limit is 5 us)
PIN = 0                      # P0 = CC1

# 4b5b: the 5-bit code of each nibble; bit 0 of a code is sent first.
CODE = [0x1E, 0x09, 0x14, 0x15, 0x0A, 0x0B, 0x0E, 0x0F,
        0x12, 0x13, 0x16, 0x17, 0x1A, 0x1B, 0x1C, 0x1D]
SYNC1, SYNC2, SYNC3, EOP = 0x18, 0x11, 0x06, 0x0D
SOPS = {0: ((SYNC1, SYNC1, SYNC1, SYNC2), "SOP"),
        1: ((SYNC1, SYNC1, SYNC3, SYNC3), "SOP'"),
        2: ((SYNC1, SYNC3, SYNC1, SYNC3), 'SOP"')}


# ---------------------------------------------------------------- the packet

def crc32(header, objects):
    """The packet's CRC-32: Ethernet's, over the header and the data objects,
    each least significant byte first."""
    data = header.to_bytes(2, "little") + b"".join(o.to_bytes(4, "little") for o in objects)
    return zlib.crc32(data) & 0xFFFFFFFF


def packet_bits(packet):
    """Every bit of a packet as it goes on the line, in order."""
    kind, header, objects = packet
    bits = [k & 1 for k in range(64)]                 # preamble 0101...01
    symbols = list(SOPS[kind][0])

    def nibbles(value, count):
        return [CODE[(value >> (4 * i)) & 0xF] for i in range(count)]

    symbols += nibbles(header, 4)
    for o in objects:
        symbols += nibbles(o, 8)
    symbols += nibbles(crc32(header, objects), 8)
    symbols.append(EOP)
    for s in symbols:
        bits += [(s >> i) & 1 for i in range(5)]
    return bits


def ideal_offsets(bits):
    """Where the transitions of a packet belong, in cycles after its first.

    The line is low before it. Every bit begins with a transition, and a 1
    has another in its middle. After the last bit there is one more
    transition, at the place the next bit would begin; if that one leaves
    the line high, it falls again half a bit later."""
    out = []
    for k, b in enumerate(bits):
        out.append(k * UI)
        if b:
            out.append(k * UI + HALF)
    end = len(bits) * UI
    out.append(end)
    if len(out) % 2:          # an odd number of transitions from low: high now
        out.append(end + HALF)
    return out


# ------------------------------------------------------- the host interface

def tx_words(packets):
    """The TX words of one run, as the task sheet defines them. Per packet:
    (number of data objects << 2) | SOP kind, then the header, then each data
    object as its low 16 bits and its high 16 bits. Payload only."""
    words = []
    for kind, header, objects in packets:
        words.append((len(objects) << 2) | kind)
        words.append(header)
        for o in objects:
            words += [o & 0xFFFF, o >> 16]
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


def write_vcd(path, changes, end):
    with open(path, "w") as f:
        f.write("$timescale %d ns $end\n" % (1_000_000_000 // CLOCK_HZ))
        f.write("$scope module pins $end\n$var wire 1 ! P0 $end\n$upscope $end\n")
        f.write("$enddefinitions $end\n")
        for cycle, level in changes:
            f.write("#%d\n%d!\n" % (cycle, level))
        f.write("#%d\n" % end)


LINE = re.compile(r"(\d+)-(\d+) usb_power_delivery-\d+: (.*)$")


def sigrok_packets(changes, cycles):
    """What sigrok's decoder makes of the capture: per packet it finds, a
    dict of the parts it annotated (sop, header, data, crc, eop, warnings)."""
    # The decoder closes a packet only when it next wakes, at the latest
    # 1 ms (20000 samples) after the last edge: give it room to do so.
    end = max(cycles, (changes[-1][0] if changes else 0) + 3 * 20_000)
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "p0.vcd")
        write_vcd(path, changes, end)
        cmd = ["sigrok-cli", "-i", path, "-I", "vcd",
               "-P", "usb_power_delivery:cc1=P0",
               "-A", "usb_power_delivery=preamble:sop:header:data:crc:eop:warnings",
               "--protocol-decoder-samplenum"]
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if out.returncode != 0 or "rror" in out.stderr:
        raise RuntimeError("sigrok-cli failed: " + out.stderr.strip()[:200])
    packets = []
    for line in out.stdout.splitlines():
        m = LINE.match(line)
        if not m:
            continue
        text = m.group(3)
        if text in ("Preamble", "Junk???"):
            packets.append({"sop": None, "header": None, "data": [], "crc": None,
                            "eop": False, "warnings": [], "junk": text == "Junk???"})
            continue
        if not packets:
            packets.append({"sop": None, "header": None, "data": [], "crc": None,
                            "eop": False, "warnings": ["annotation before any preamble: " + text],
                            "junk": False})
        p = packets[-1]
        if text in ("SOP", "SOP'", 'SOP"', "SOP' Debug", 'SOP" Debug'):
            p["sop"] = text
        elif text.startswith("H:"):
            p["header"] = int(text[2:], 16)
        elif re.match(r"\[\d+\][0-9a-f]{8}$", text):
            p["data"].append(int(text.split("]")[1], 16))
        elif text.startswith("CRC:"):
            p["crc"] = int(text[4:], 16)
        elif text == "EOP":
            p["eop"] = True
        else:
            p["warnings"].append(text)
    return packets


# ------------------------------------------------------------ the two checks

def show(packet):
    kind, header, objects = packet
    return "%s H:%04x %d objects" % (SOPS[kind][1], header, len(objects))


def check_decoder(packets, changes, cycles):
    """The decoded packets must be the wanted ones and nothing else."""
    got = sigrok_packets(changes, cycles)
    errs = []
    if len(got) != len(packets):
        errs.append("decoded %d packets, wanted %d" % (len(got), len(packets)))
    for k, (g, w) in enumerate(zip(got, packets)):
        kind, header, objects = w
        problems = []
        if g["junk"]:
            problems.append("no start of packet found")
        if g["sop"] != SOPS[kind][1]:
            problems.append("start of packet %s, wanted %s" % (g["sop"], SOPS[kind][1]))
        if g["header"] != header:
            problems.append("header %s, wanted %04x"
                            % ("none" if g["header"] is None else "%04x" % g["header"], header))
        if g["data"] != objects:
            problems.append("data objects [%s], wanted [%s]"
                            % (" ".join("%08x" % o for o in g["data"]),
                               " ".join("%08x" % o for o in objects)))
        want_crc = crc32(header, objects)
        if g["crc"] != want_crc:
            problems.append("CRC %s, wanted %08x"
                            % ("none" if g["crc"] is None else "%08x" % g["crc"], want_crc))
        if not g["eop"]:
            problems.append("no EOP")
        if g["warnings"]:
            problems.append("decoder warnings: " + ", ".join(g["warnings"]))
        if problems:
            errs.append("packet %d (%s): %s" % (k, show(w), "; ".join(problems)))
    return errs


def check_waveform(packets, changes, cycles):
    """The limits of the task sheet that the decoder does not hold to."""
    if not changes or changes[0][0] != 0:
        return ["no level for P0 at cycle 0 in the simulator's output"]
    errs = []
    edges = [c for c, _ in changes[1:]]
    # P0 starts high (the output register's reset value); it may fall once,
    # by cycle LOW_BY, and must then stay low until the first preamble.
    if changes[0][1] == 1:
        if not edges or edges[0] > LOW_BY:
            return ["P0 is still high at cycle %d: it must be low from then until the first preamble"
                    % LOW_BY]
        settle = edges[0]
        edges = edges[1:]
    else:
        settle = 0
    groups = []
    for e in edges:
        if groups and e - groups[-1][-1] <= SPLIT:
            groups[-1].append(e)
        else:
            groups.append([e])
    if len(groups) != len(packets):
        errs.append("%d separate bursts of transitions on P0, wanted %d packets"
                    % (len(groups), len(packets)))
    prev_end = None
    for k, (g, pkt) in enumerate(zip(groups, packets)):
        want = ideal_offsets(packet_bits(pkt))
        got = [e - g[0] for e in g]
        for i, (a, w) in enumerate(zip(got, want)):
            if abs(a - w) > TOL:
                errs.append("packet %d: transition %d is %d cycles after the first, ideal %d (limit +-%d)"
                            % (k, i, a, w, TOL))
                break
        else:
            if len(got) != len(want):
                errs.append("packet %d: %d transitions, wanted %d" % (k, len(got), len(want)))
        if k == 0:
            if g[0] > START_MAX:
                errs.append("the first preamble begins at cycle %d, limit %d" % (g[0], START_MAX))
            if g[0] - settle < GAP_MIN:
                errs.append("the first preamble begins %d cycles after P0 went low, at least %d wanted"
                            % (g[0] - settle, GAP_MIN))
        else:
            gap = g[0] - prev_end
            if gap < GAP_MIN:
                errs.append("gap before packet %d is %d cycles, at least %d wanted" % (k, gap, GAP_MIN))
            elif gap > GAP_MAX:
                errs.append("gap before packet %d is %d cycles, at most %d allowed" % (k, gap, GAP_MAX))
        prev_end = g[-1]
    if groups and len(groups) == len(packets) and cycles - prev_end < GAP_MIN:
        errs.append("the run ended %d cycles after the last packet, too soon to see the silence"
                    % (cycles - prev_end))
    return errs


def judge(packets, sim_stdout, cycles):
    """Every objection to one run, each marked with the check that made it."""
    changes = p0_changes(sim_stdout)
    errs = ["waveform: " + e for e in check_waveform(packets, changes, cycles)]
    if changes and changes[0][0] == 0:
        errs += ["decoder: " + e for e in check_decoder(packets, changes, cycles)]
    return errs


# ------------------------------------------------------------------ running

def packet_cycles(packet):
    return ideal_offsets(packet_bits(packet))[-1]


def run_cycles(packets):
    """Long enough for the latest start and the longest gaps allowed."""
    return START_MAX + sum(packet_cycles(p) + GAP_MAX for p in packets)


def burst_span(sim_stdout):
    """Cycles from the first packet's first transition to the last one's last."""
    changes = p0_changes(sim_stdout)
    edges = [c for c, _ in changes[1:]]
    if changes and changes[0][1] == 1 and edges and edges[0] <= LOW_BY:
        edges = edges[1:]
    return edges[-1] - edges[0] if edges else None


def run_case(run_dir, args, packets):
    """(objections, span or None)."""
    words = tx_words(packets)
    cycles = run_cycles(packets)
    with tempfile.TemporaryDirectory() as d:
        tx = os.path.join(d, "tx.txt")
        with open(tx, "w") as f:
            f.write("".join("%d\n" % w for w in words))
        cmd = [os.path.join(run_dir, "pe_sim"), "run",
               os.path.join(run_dir, "usb_power_delivery.s"),
               "-tx", tx, "-cycles", str(cycles)] + args
        try:
            out = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        except (OSError, subprocess.TimeoutExpired) as e:
            return ["simulator: %s" % e], None
    if out.returncode != 0:
        said = " ".join(out.stderr.split())
        return ["simulator: pe_sim exited with status %d: %s" % (out.returncode, said[:200])], None
    return judge(packets, out.stdout, cycles), burst_span(out.stdout)


def header_of(rng, objects, kind):
    """A plausible PD header: message type, data role, spec revision, power
    role (or cable plug), message ID, and the number of data objects. Bit 15
    (extended) is 0."""
    mtype = rng.randrange(1, 16)
    return ((objects << 12) | (rng.randrange(8) << 9) | (rng.randrange(2) << 8)
            | (rng.randrange(3) << 6) | ((rng.randrange(2) if kind == 0 else 0) << 5) | mtype)


def cases_for(seed):
    """(name, packets): fixed cases, then seeded random ones."""
    good_crc = (0, 0x0041, [])                             # GoodCRC, SOP
    src_caps = (0, 0x11A1, [0x0001912C])                   # the sheet's example
    fixed = [
        ("GoodCRC, no data objects", [good_crc]),
        ("the task sheet's example", [src_caps]),
        ("SOP' and SOP'' control messages", [(1, 0x0141, []), (2, 0x0F43, [])]),
        ("all-zero and all-one objects", [(0, 0x2002, [0x00000000, 0xFFFFFFFF])]),
        ("seven data objects", [(0, 0x7FAF, [(k * 0x9E3779B1 + 0x1234567) & 0xFFFFFFFF
                                              for k in range(MAX_OBJECTS)])]),
        ("source caps, request, accept, ps_rdy", [
            (0, 0x21A1, [0x0801912C, 0x0002D12C]),
            (0, 0x1042, [0x1304B12C]),
            (0, 0x0363, []),
            (0, 0x0566, []),
        ]),
    ]
    rng = random.Random(seed)
    rand = []
    for n in range(8):
        count = rng.randint(1, 5)
        packets = []
        for _ in range(count):
            kind = rng.choice((0, 0, 0, 1, 2))
            objects = rng.randint(0, MAX_OBJECTS if n % 2 else 2)
            packets.append((kind, header_of(rng, objects, kind),
                            [rng.getrandbits(32) for _ in range(objects)]))
        rand.append(("random %d" % n, packets))
    return fixed + rand


def payload_bytes(packets):
    return sum(2 + 4 * len(objects) for _, _, objects in packets)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    run_dir = os.path.abspath(argv[1])
    seed = int(argv[2]) if len(argv) > 2 else 1
    setup = []
    if shutil.which("sigrok-cli") is None:
        setup.append("sigrok-cli is not installed")
    for name in ("pe_sim", "usb_power_delivery.s", "run_args.txt"):
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
            errs, span = run_case(run_dir, args, packets)
        except Exception as e:  # never report a pass because the judge fell over
            errs, span = ["judge: %s: %s" % (type(e).__name__, e)], None
        if not errs:
            rate = (payload_bytes(packets), span)
        shown = []
        for kind in ("simulator:", "judge:", "waveform:", "decoder:"):
            shown += [e for e in errs if e.startswith(kind)][:2]
        status = "PASS" if not errs else "FAIL: " + "; ".join(shown)
        size = payload_bytes(packets)
        print("case %d (%s: %d packet%s, %d payload bytes): %s"
              % (n, name, len(packets), "" if len(packets) == 1 else "s", size, status))
        failed += bool(errs)
    if rate:
        print("RATE bytes=%d cycles=%d" % rate)
    print("ACCEPT PASS" if not failed else "ACCEPT FAIL")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
