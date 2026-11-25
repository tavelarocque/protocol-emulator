"""Pin traces judged by sigrok's protocol decoders (libsigrokdecode), which
this project did not write. A Trace samples named signals on every clock
edge while a test runs; decode() writes them as a VCD file and returns what
a sigrok decoder made of it, as (start sample, end sample, text) tuples.

Needs sigrok-cli (apt install sigrok-cli). Without it, available() is False
and the tests that use this say so and skip the decoder's verdict; CI sets
REQUIRE_SIGROK=1, which turns a missing sigrok-cli into a failure.

A few decoders are not in the packaged release: newer ones from sigrok's
own source, and three published by others (SENT, DShot, I3C). The script
extra_decoders.sh fetches them, each at a fixed commit, into
extra_decoders/; decode(..., extra=True) uses that folder instead of the
packaged decoders, and extra_available() says whether it is there."""

import os
import re
import shutil
import subprocess
import tempfile

import cocotb
from cocotb.triggers import RisingEdge


def available():
    found = shutil.which("sigrok-cli") is not None
    assert found or not os.environ.get("REQUIRE_SIGROK"), "sigrok-cli is not installed"
    return found


EXTRA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "extra_decoders")


def extra_available():
    found = available() and os.path.isdir(EXTRA_DIR)
    assert found or not os.environ.get("REQUIRE_SIGROK"), \
        "extra decoders missing: run test/extra_decoders.sh"
    return found


class Trace:
    def __init__(self, dut, signals, clock_hz=10_000_000):
        """signals: {name in the VCD: a function returning 0 or 1}."""
        self.dut, self.signals, self.clock_hz = dut, signals, clock_hz
        self.names = list(signals)
        self.changes = []  # (sample number, tuple of levels)
        self.n = 0
        self.task = cocotb.start_soon(self._run())

    async def _run(self):
        last = None
        while True:
            await RisingEdge(self.dut.clk)
            now = tuple(int(f()) for f in self.signals.values())
            if now != last:
                self.changes.append((self.n, now))
                last = now
            self.n += 1

    def stop(self):
        self.task.cancel()

    def forced(self, name, start, end, level):
        """A copy of the trace with one signal held at level from sample
        start to end: a fault planted on the wire, to show a decoder's
        verdict depends on what it is shown."""
        k, at = self.names.index(name), dict(self.changes)
        other = Trace.__new__(Trace)
        other.names, other.clock_hz, other.n, other.changes = self.names, self.clock_hz, self.n, []
        cur = None
        for t in sorted(set(at) | {start, end}):
            cur = at.get(t, cur)
            if cur is None:
                continue
            now = list(cur)
            if start <= t < end:
                now[k] = level
            if not other.changes or other.changes[-1][1] != tuple(now):
                other.changes.append((t, tuple(now)))
        return other

    def level(self, name):
        """[(sample number, level)] for one signal, changes only."""
        k, out = self.names.index(name), []
        for t, levels in self.changes:
            if not out or out[-1][1] != levels[k]:
                out.append((t, levels[k]))
        return out

    def low_pulses(self, name):
        """[(first sample low, first sample high again)] for one signal."""
        out, fell = [], None
        for t, v in self.level(name):
            if v == 0:
                fell = t
            elif fell is not None:
                out.append((fell, t))
                fell = None
        return out

    def vcd(self, path, start=0, end=None, invert=(), then_fall=None):
        """Samples start to end, renumbered from 0; signals named in invert
        are written inverted. then_fall names a signal given one more
        falling edge after the last sample."""
        end = self.n if end is None else min(end, self.n)
        flip = [name in invert for name in self.names]
        ids = [chr(33 + k) for k in range(len(self.names))]
        with open(path, "w") as f:
            f.write(f"$timescale {1_000_000_000 // self.clock_hz} ns $end\n")
            f.write("$scope module pins $end\n")
            for i, name in zip(ids, self.names):
                f.write(f"$var wire 1 {i} {name} $end\n")
            f.write("$upscope $end\n$enddefinitions $end\n")
            last = [None] * len(ids)
            now = None
            for t, levels in self.changes:
                if t <= start:
                    now = levels
                    continue
                if now is not None and last[0] is None:
                    self._emit(f, 0, now, last, ids, flip)
                if t >= end:
                    break
                self._emit(f, t - start, levels, last, ids, flip)
                now = levels
            if now is not None and last[0] is None:
                self._emit(f, 0, now, last, ids, flip)
            f.write(f"#{end - start}\n")
            if then_fall:
                f.write(f"0{ids[self.names.index(then_fall)]}\n#{end - start + 10}\n")

    @staticmethod
    def _emit(f, t, levels, last, ids, flip):
        f.write(f"#{t}\n")
        for k, v in enumerate(levels):
            v ^= flip[k]
            if v != last[k]:
                f.write(f"{v}{ids[k]}\n")
                last[k] = v

    def decode(self, decoder, annotations=None, start=0, end=None, invert=(),
               then_fall=None, extra=False):
        """decoder: sigrok-cli's -P argument, e.g. 'can:can_rx=rxd'. Returns
        [(start, end, text)] in the decoder's order, in this trace's sample
        numbers. extra=True decodes with the decoders in EXTRA_DIR."""
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "trace.vcd")
            self.vcd(path, start, end, invert, then_fall)
            cmd = ["sigrok-cli", "-i", path, "-I", "vcd", "-P", decoder,
                   "--protocol-decoder-samplenum"]
            if annotations:
                cmd += ["-A", annotations]
            env = dict(os.environ, SIGROKDECODE_DIR=EXTRA_DIR) if extra else None
            out = subprocess.run(cmd, capture_output=True, text=True, check=True,
                                 env=env).stdout
        found = []
        for line in out.splitlines():
            m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
            if m:
                found.append((int(m.group(1)) + start, int(m.group(2)) + start,
                              m.group(3).strip()))
        return found


def can_frames(texts):
    """The CAN decoder's field annotations as [(identifier, data bytes, CRC,
    'ACK' or 'NACK')]. Any warning from the decoder fails."""
    frames, cur = [], None
    for text in texts:
        key, _, value = text.partition(": ")
        if key == "Start of frame":
            cur = {"data": []}
        elif cur is None:
            continue
        elif key == "Identifier":
            cur["id"] = int(value.split()[0])
        elif key.startswith("Data byte"):
            cur["data"].append(int(value, 16))
        elif key == "CRC-15 sequence":
            cur["crc"] = int(value, 16)
        elif key == "ACK slot":
            cur["ack"] = value
        elif key == "End of frame":
            frames.append((cur["id"], cur["data"], cur["crc"], cur["ack"]))
            cur = None
        elif key in ("Identifier extension bit", "Reserved bit 0", "Data length code",
                     "Remote transmission request", "CRC delimiter", "ACK delimiter"):
            pass
        else:
            raise AssertionError(f"CAN decoder: {text}")
    return frames


def ps2_frames(trace, clk="clk", data="data"):
    """Every PS/2 frame in a trace, as [('device' or 'host', byte)], each
    read by sigrok's decoder, which takes a bit on each falling edge of CLK,
    wants a start bit of 0 and checks odd parity over the 8 data bits. The
    stop bit it reports but does not check, so that is checked here.

    The decoder (libsigrokdecode 0.5.3) knows one frame shape, a device's,
    has no idea of an idle bus, and reports a frame only when the clock
    edge after it arrives. So each frame is handed to it alone, followed by
    one more falling edge. A frame from the host begins with CLK held low
    for 100 us or more and its bits are valid as CLK rises, so for those the
    decoder is given CLK inverted: the release of CLK then samples the start
    bit, each rise a bit, and the device's ACK clock is the edge after."""
    us = trace.clock_hz // 1_000_000
    pulses = trace.low_pulses(clk)
    frames, i = [], 0
    while i < len(pulses):
        if pulses[i][1] - pulses[i][0] >= 100 * us:
            group, who = pulses[i:i + 12], "host"  # inhibit, 10 bits, ACK
            i += 12
        else:
            j = i
            while j < len(pulses) and j - i < 11 and pulses[j][1] - pulses[j][0] < 100 * us:
                j += 1
            group, who = pulses[i:j], "device"
            i = j
            if len(group) < 11:
                continue  # a frame the host cut off; the device sends it again
        seen = [text for _, _, text in trace.decode(
            f"ps2:clk={clk}:data={data}",
            start=group[0][0] - 10 * us, end=group[-1][1] + 10 * us,
            invert=(clk,) if who == "host" else (),
            then_fall=None if who == "host" else clk)]
        bits, fields = seen[:11], seen[11:]
        assert (len(bits) == 11 and bits[10] == "1" and len(fields) == 4
                and fields[0] == "Start bit" and fields[1].startswith("Data: ")
                and fields[2] == "Parity OK" and fields[3] == "Stop bit"), (who, seen)
        frames.append((who, int(fields[1][6:], 16)))
    return frames


def can_crc15(ident, data):
    """CRC-15/CAN (polynomial 0x4599) of a standard data frame, from its
    start-of-frame bit through its data, written here from ISO 11898-1 so
    the decoder's CRC is compared with one the driver did not compute."""
    bits = [0] + [(ident >> (10 - k)) & 1 for k in range(11)] + [0, 0, 0]
    bits += [(len(data) >> (3 - k)) & 1 for k in range(4)]
    for byte in data:
        bits += [(byte >> (7 - k)) & 1 for k in range(8)]
    crc = 0
    for b in bits:
        top = (crc >> 14) & 1
        crc = (crc << 1) & 0x7FFF
        if top ^ b:
            crc ^= 0x4599
    return crc
