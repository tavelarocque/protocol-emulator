#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""Runs the FPGA bench's demos and judges each recording with sigrok.

For each demo named (all five by default): copy the host driver, the demos,
pico_main.py and the firmware images to the Pico with mpremote, start a
capture on the logic analyser with sigrok-cli (fx2lafw, 24 MHz, D0 to D7),
run the demo on the Pico, then decode the capture with the decoder and
options of the chip-level test the demo comes from (test/test.py) and
compare what sigrok read with what was sent, as that test does. The
capture (.sr) and the decoded output (.txt) go to fpga/bench/captures/.

    fpga/bench/run_bench.py                    # every demo, on the bench
    fpga/bench/run_bench.py uart nec           # two of them
    fpga/bench/run_bench.py --dry-run          # print the commands only
    fpga/bench/run_bench.py --judge x.sr uart  # judge a capture made before

Needs Python 3.8 or later (standard library only), sigrok-cli and mpremote
on the PATH, and openFPGALoader for --bitstream. Not yet run on a board.

How a recording is judged. The analyser's channel D<k> is the chip's pin
P<k>. The capture is made into the trace the chip-level test records: the
test's signals only, under the test's names and in its order (sigrok-cli
gives a decoder named without channel options the channels in order), cut
to their activity (1 ms before the first change, 10 ms after the last).
So the decoder argument is the test's, unchanged. sigrok-cli decodes it
with --protocol-decoder-samplenum and the test's -A option, its lines are
read with the pattern test/sigrok.py uses, and the comparison is the
test's assertion. sim/test_bench_sim.py feeds this same code a capture
made from a cocotb run of the demos.
"""

import argparse
import configparser
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CAPTURES = os.path.join(HERE, "captures")
RATE = 24_000_000  # the analyser's sample rate
CHIP_HZ = 10_000_000
CHANNELS = ",".join("D%d" % k for k in range(8))

# --- Captures -----------------------------------------------------------------


def parse_rate(text):
    """A sigrok samplerate string ('24 MHz', '24000000') in Hz."""
    m = re.match(r"\s*([0-9.]+)\s*([kMG]?)Hz\s*$", text) or re.match(r"\s*([0-9.]+)\s*()$", text)
    if not m:
        raise ValueError("samplerate %r" % text)
    return round(float(m.group(1)) * {"": 1, "k": 10**3, "M": 10**6, "G": 10**9}[m.group(2)])


def format_rate(hz):
    for unit, scale in (("GHz", 10**9), ("MHz", 10**6), ("kHz", 10**3)):
        if hz % scale == 0:
            return "%d %s" % (hz // scale, unit)
    return "%d Hz" % hz


class Capture:
    """A logic recording: one byte a sample (bit k is channel k), its rate,
    and the name of each channel."""

    def __init__(self, data, rate, names):
        self.data, self.rate, self.names = bytes(data), rate, list(names)

    @classmethod
    def read(cls, path):
        """A sigrok session file (srzip), as sigrok-cli -o writes it. Only
        the first 8 logic channels are kept."""
        with zipfile.ZipFile(path) as z:
            meta = configparser.ConfigParser(interpolation=None)
            meta.read_string(z.read("metadata").decode())
            dev = meta["device 1"]
            prefix = dev.get("capturefile", "logic-1")
            unit = int(dev.get("unitsize", "1"))
            probes = int(dev.get("total probes", "8"))
            names = [dev.get("probe%d" % (k + 1), "D%d" % k) for k in range(min(probes, 8))]
            chunks = sorted((int(n[len(prefix) + 1:]), n) for n in z.namelist()
                            if re.fullmatch(re.escape(prefix) + r"-\d+", n))
            raw = b"".join(z.read(n) for _, n in chunks) if chunks else z.read(prefix)
        if unit > 1:
            raw = raw[0::unit]  # the low byte: channels 1 to 8
        return cls(raw, parse_rate(dev["samplerate"]), names)

    def write(self, path):
        """As a sigrok session file sigrok-cli and PulseView read."""
        meta = ["[global]", "sigrok version=0.5.2", "", "[device 1]", "capturefile=logic-1",
                "total probes=%d" % len(self.names), "samplerate=%s" % format_rate(self.rate),
                "total analog=0"]
        meta += ["probe%d=%s" % (k + 1, n) for k, n in enumerate(self.names)]
        meta += ["unitsize=1", ""]
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("version", "2")
            z.writestr("metadata", "\n".join(meta))
            z.writestr("logic-1-1", self.data)

    @classmethod
    def from_changes(cls, changes, names, clock_hz, n, rate=RATE):
        """A recording at [rate] of levels known at a clock's edges, as an
        analyser sampling the wires would make it: [changes] is
        [(clock edge, levels)], as sigrok.Trace keeps them, [n] the number of
        edges; sample k takes the levels after edge floor(k * clock_hz / rate)."""
        out = bytearray()
        for i, (t, levels) in enumerate(changes):
            t_next = changes[i + 1][0] if i + 1 < len(changes) else n
            k0, k1 = -(-t * rate // clock_hz), -(-t_next * rate // clock_hz)
            out += bytes([sum(int(v) << b for b, v in enumerate(levels))]) * (k1 - k0)
        return cls(out, rate, names)

    def _bit(self, name):
        if name not in self.names:
            raise KeyError("no channel %r in %s" % (name, self.names))
        return self.names.index(name)

    def channel(self, name):
        k = self._bit(name)
        return self.data.translate(bytes((v >> k) & 1 for v in range(256)))

    def level(self, name):
        """[(sample, level)] for one channel, changes only (and the first)."""
        line = self.channel(name)
        return [(m.start(), line[m.start()]) for m in re.finditer(rb"\x00+|\x01+", line)]

    def low_pulses(self, name):
        """[(first sample low, first sample high again)]."""
        out, fell = [], None
        for t, v in self.level(name):
            if v == 0:
                fell = t
            elif fell is not None:
                out.append((fell, t))
                fell = None
        return out

    def forced(self, name, start, end, level):
        """A copy with one channel held at [level] from sample start to end:
        a fault planted on the wire, as sigrok.Trace.forced plants one."""
        k = self._bit(name)
        start, end = max(0, start), min(len(self.data), end)
        table = bytes((v | (1 << k)) if level else (v & ~(1 << k)) for v in range(256))
        data = self.data[:start] + self.data[start:end].translate(table) + self.data[end:]
        return Capture(data, self.rate, self.names)

    def window(self, start=0, end=None):
        return Capture(self.data[start:end], self.rate, self.names)

    def active(self, names, before, after):
        """Cut to the span in which the named channels change, with [before]
        and [after] samples of margin."""
        mask = sum(1 << self._bit(n) for n in names)
        line = self.data.translate(bytes(v & mask for v in range(256)))
        n = len(line)
        if n == 0:
            return self
        first = n - len(line.lstrip(line[:1]))
        if first == n:
            return self  # nothing changes
        last = len(line.rstrip(line[-1:]))
        return self.window(max(0, first - before), min(n, last + after))

    def us(self, us):
        return round(us * self.rate / 1_000_000)

    def clocks(self, n):
        """[n] chip clocks at 10 MHz, in samples."""
        return round(n * self.rate / CHIP_HZ)


# --- Decoding, as test/sigrok.py does it --------------------------------------


def decode(cap, decoder, annotations=None, start=0, end=None, log=None, shown=None):
    """[(start, end, text)] that sigrok-cli's [decoder] (its -P argument)
    reads in samples start to end of [cap], in [cap]'s sample numbers.
    What it read goes to [log], only the texts [shown] accepts if given."""
    if shutil.which("sigrok-cli") is None:
        raise RuntimeError("sigrok-cli is not installed")
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "window.sr")
        cap.window(start, end).write(path)
        cmd = ["sigrok-cli", "-i", path, "-P", decoder, "--protocol-decoder-samplenum"]
        if annotations:
            cmd += ["-A", annotations]
        out = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    found = []
    for line in out.splitlines():
        m = re.match(r"(\d+)-(\d+) [^:]+: (.*)", line)
        if m:
            found.append((int(m.group(1)) + start, int(m.group(2)) + start, m.group(3).strip()))
    if log is not None:
        args = " ".join(["-P", decoder] + (["-A", annotations] if annotations else []))
        window = "" if (start, end) == (0, None) else " (samples %d to %s)" % (start, end)
        log.append("sigrok-cli %s%s%s:" % (args, window, "" if shown is None else ", in part"))
        log.extend("  %d-%d %s" % f for f in found if shown is None or shown(f[2]))
    return found


def texts(found):
    return [text for _, _, text in found]


# --- The demos' judges --------------------------------------------------------
#
# Each: the pins the test records, in its order, with the names it gives
# them and the chip pin each is (the analyser's channel D<k> is P<k>), the
# test it comes from, check(cap, log) returning what is wrong
# (nothing, to pass), and fault(cap): where that test plants its fault on
# the wire, as (channel, first sample, end sample, level).


class Demo:
    def __init__(self, name, pins, test, want, check, fault):
        self.name, self.pins, self.test, self.want = name, pins, test, want
        self.check, self.fault = check, fault


def compare(got, want, what):
    return [] if got == want else ["%s: read %r, sent %r" % (what, got, want)]


# uart: test_modbus_rtu.
UART_DECODER = "uart:tx=tx:baudrate=114943,modbus"
UART_WANT = ["Slave ID: 17", "Function 3: Read Holding Registers",
             "Start at address 0x6B / 30108", "Read 3 units of data", "CRC correct"]


def uart_check(cap, log):
    return compare(texts(decode(cap, UART_DECODER, "modbus", log=log)), UART_WANT, "modbus")


def uart_fault(cap):
    """One data bit of the register count held high: the CRC no longer fits."""
    a = decode(cap, UART_DECODER, "modbus")[3][0]
    bit = cap.clocks(87)
    return "tx", a + 2 * bit, a + 3 * bit, 1


# spi: test_max7219's writes and verdict.
SPI_DECODER = "spi:clk=sck:mosi=mosi:cs=cs,max7219"
SPI_WANT = ["Shutdown: off", "Decode: 0b11111111", "Intensity: 8", "Scan limit: 8",
            "Digit 1: 05", "Digit 8: 09"]


def spi_check(cap, log):
    return compare(texts(decode(cap, SPI_DECODER, "max7219", log=log)), SPI_WANT, "max7219")


def spi_fault(cap):
    """The data line held high for the last write: not digit 8's 09."""
    a, b, _ = decode(cap, SPI_DECODER, "max7219")[-1]
    return "mosi", a - cap.clocks(20), b, 1


# i2c: test_eeprom_24xx.
I2C_DECODER = "i2c,eeprom24xx"
I2C_WANT = ["Page write (addr=10, 3 bytes): DE AD BE", "Byte write (addr=0F, 1 byte): 55",
            "Sequential random read (addr=11, 2 bytes): AD BE"]


def i2c_check(cap, log):
    named = [t for t in texts(decode(cap, I2C_DECODER, "eeprom24xx", log=log)) if "(addr=" in t]
    wrong = compare(named, I2C_WANT, "eeprom24xx")
    bus = texts(decode(cap, "i2c", log=log, shown=lambda t: t.startswith(("Start", "Stop"))))
    marks = [t for t in bus if t.startswith(("Start", "Stop"))]
    if bus.count("Start repeat") != 1 or bus.count("Stop") != 4:
        wrong.append("i2c: want one repeated START and four STOPs, read %r" % marks)
    return wrong


def i2c_fault(cap):
    """The data line held low through the first data byte: not 0xDE."""
    a, b = next((a, b) for a, b, t in decode(cap, I2C_DECODER, "eeprom24xx")
                if t == "Data byte 10: DE")
    return "sda", a, b, 0


# nec: test_nec_infrared.
NEC_DECODER = "ir_nec:polarity=active-high:cd_freq=38000"
NEC_WANT = ["Address: 0x04", "Address#: 0xFB", "Command: 0x08", "Command#: 0xF7"]


def nec_check(cap, log):
    fields = [t for t in texts(decode(cap, NEC_DECODER, log=log)) if ": 0x" in t]
    return compare(fields, NEC_WANT, "ir_nec")


def nec_fault(cap):
    """One burst of carrier blanked out: the frame must not decode."""
    a = next(a for a, _, t in decode(cap, NEC_DECODER) if t == "Command: 0x08")
    return "ir", a, a + cap.clocks(9000), 0


# dmx: test_dmx512. sigrok's decoder takes the first long run of either
# level as the break and looks for the next only after 512 slots, so it is
# shown each packet on its own, from the moment its break begins.
DMX_PACKETS = [[0x00, 0xFF, 0x55, 0x81, 0x7E], [0x10, 0x20]]
DMX_WANT = ["packet %d: Break, MAB, slots %s, nothing invalid" % (k, [0] + p)
            for k, p in enumerate(DMX_PACKETS)]


def dmx_packets(cap, log=None):
    breaks = [a for a, b in cap.low_pulses("dmx") if b - a >= cap.us(92)]
    out = []
    for k, start in enumerate(breaks):
        end = breaks[k + 1] if k + 1 < len(breaks) else None
        out.append(decode(cap, "dmx512", start=start, end=end, log=log))
    return out


def dmx_check(cap, log):
    packets = dmx_packets(cap, log)
    wrong = compare(len(packets), len(DMX_PACKETS), "breaks of 92 us or more")
    for k, (found, slots) in enumerate(zip(packets, DMX_PACKETS)):
        names = texts(found)
        got = [int(t.split(" / ")[0]) for t in names if " / 0x" in t]
        bad = [t for t in names if "nvalid" in t]
        wrong += compare(names[:2], ["Break", "MAB"], "packet %d starts" % k)
        wrong += compare(got, [0] + slots, "packet %d slots" % k)
        wrong += ["packet %d: %s" % (k, t) for t in bad]
    return wrong


def dmx_fault(cap):
    """One slot's first stop bit pulled low, in the last packet."""
    at = next(a for a, _, t in dmx_packets(cap)[-1] if t == "Stop bit")
    return "dmx", at, at + cap.clocks(40), 0


DEMOS = {d.name: d for d in [
    Demo("uart", [("tx", 0)], "test_modbus_rtu", UART_WANT, uart_check, uart_fault),
    Demo("spi", [("sck", 0), ("mosi", 1), ("cs", 3)], "test_max7219", SPI_WANT,
         spi_check, spi_fault),
    Demo("i2c", [("scl", 1), ("sda", 0)], "test_eeprom_24xx", I2C_WANT, i2c_check, i2c_fault),
    Demo("nec", [("ir", 0)], "test_nec_infrared", NEC_WANT, nec_check, nec_fault),
    Demo("dmx", [("dmx", 0)], "test_dmx512", DMX_WANT, dmx_check, dmx_fault),
]}


def prepare(cap, demo):
    """The recording as the chip-level test's trace has it: the test's
    signals only, in the test's order (sigrok-cli gives a decoder named
    without channel options the channels in order), from the analyser's
    channel D<k> for pin P<k>, and cut to those pins' activity."""
    old = []
    for name, pin in demo.pins:
        if "D%d" % pin not in cap.names:
            raise ValueError("the capture has no channel D%d (%s)" % (pin, name))
        old.append(cap.names.index("D%d" % pin))
    table = bytes(sum(((v >> k) & 1) << i for i, k in enumerate(old)) for v in range(256))
    cap = Capture(cap.data.translate(table), cap.rate, [name for name, _ in demo.pins])
    return cap.active(cap.names, cap.us(1000), cap.us(10_000))


def judge(name, cap):
    """Decode a prepared capture of demo [name] and compare it with what was
    sent. Returns (passed, report lines)."""
    demo, log = DEMOS[name], []
    try:
        wrong = demo.check(cap, log)
    except (StopIteration, IndexError, ValueError) as e:  # a field the check needs is missing
        wrong = ["could not read the recording: %r" % (e,)]
    log.append("%s: %s (%s, %d samples at %s)" % (
        name, "PASS" if not wrong else "FAIL", demo.test, len(cap.data), format_rate(cap.rate)))
    log.extend("  " + w for w in wrong)
    return not wrong, log


# --- The bench ---------------------------------------------------------------

PICO_FILES = [os.path.join(ROOT, "host", "protocol_emulator.py"),
              os.path.join(ROOT, "host", "more_protocols.py"),
              os.path.join(HERE, "demos.py"), os.path.join(HERE, "pico_main.py")]


def images(names):
    sys.path.insert(0, HERE)
    sys.path.insert(0, os.path.join(ROOT, "host"))
    import demos  # only for its table of images; needs the host driver on the path
    return [os.path.join(ROOT, "test", demos.IMAGES[n] + ".hex") for n in names]


def show(cmd, then=""):
    here = os.getcwd() + os.sep
    print("$ " + " ".join(shlex.quote(c[len(here):] if c.startswith(here) else c) for c in cmd) + then)


def run(cmd, dry, **kw):
    show(cmd)
    if dry:
        return None
    return subprocess.run(cmd, check=True, **kw)


def bench(names, args):
    dry = args.dry_run
    port = ["connect", args.port]
    if not dry:
        for tool in ["mpremote", "sigrok-cli"] + (["openFPGALoader"] if args.bitstream else []):
            if shutil.which(tool) is None:
                sys.exit("%s is not installed (see fpga/bench/README.md)" % tool)
        os.makedirs(CAPTURES, exist_ok=True)
    if args.bitstream:
        run(["openFPGALoader", "-b", "tangnano20k", args.bitstream], dry)
    if not args.no_copy:
        run(["mpremote"] + port + ["cp"] + PICO_FILES + images(names) + [":"], dry)
    # The first use of an FX2 analyser loads its firmware and takes a few
    # seconds; after that it stays loaded until it is unplugged.
    run(["sigrok-cli", "-d", "fx2lafw", "--show"], dry, capture_output=True)
    results = {}
    for name in names:
        path = os.path.join(CAPTURES, name + ".sr")
        capture = ["sigrok-cli", "-d", "fx2lafw", "--config", "samplerate=24m",
                   "--channels", CHANNELS, "--time", str(int(args.seconds * 1000)), "-o", path]
        trigger = ["mpremote"] + port + ["exec", 'import pico_main; pico_main.main("%s")' % name]
        show(capture, " &")
        if dry:
            print("$ sleep %g" % args.arm)
            show(trigger)
            print("$ wait")
            continue
        if os.path.exists(path):
            os.remove(path)
        recorder = subprocess.Popen(capture, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        time.sleep(args.arm)
        pico = subprocess.run(trigger, capture_output=True, text=True, timeout=60)
        out, _ = recorder.communicate(timeout=args.seconds + 30)
        log = ["Pico:"] + ["  " + l for l in (pico.stdout + pico.stderr).splitlines()]
        if out.strip():
            log += ["sigrok-cli:"] + ["  " + l for l in out.splitlines()]
        if pico.returncode != 0 or recorder.returncode != 0 or not os.path.exists(path):
            ok = False
            log.append("%s: FAIL (the %s did not finish)" % (
                name, "Pico" if pico.returncode != 0 else "capture"))
        else:
            ok, more = judge(name, prepare(Capture.read(path), DEMOS[name]))
            log += more
        with open(os.path.join(CAPTURES, name + ".txt"), "w") as f:
            f.write("\n".join(log) + "\n")
        print("\n".join(log))
        results[name] = ok
    return results


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("demos", nargs="*", help="demos to run: %s (default all)" % ", ".join(DEMOS))
    p.add_argument("--dry-run", action="store_true", help="print the commands, run nothing")
    p.add_argument("--port", default="auto", help="mpremote's device (default auto)")
    p.add_argument("--bitstream", help="load this .fs into the FPGA first (openFPGALoader, SRAM)")
    p.add_argument("--no-copy", action="store_true", help="the Pico already has the files")
    p.add_argument("--seconds", type=float, default=6.0, help="capture length (default 6)")
    p.add_argument("--arm", type=float, default=1.5,
                   help="seconds between starting the capture and the demo (default 1.5)")
    p.add_argument("--judge", metavar="CAPTURE", help="judge this capture of the one demo named")
    args = p.parse_args()
    names = args.demos or list(DEMOS)
    for n in names:
        if n not in DEMOS:
            p.error("no demo %r: %s" % (n, ", ".join(DEMOS)))
    if args.judge:
        if len(names) != 1:
            p.error("--judge takes exactly one demo")
        ok, log = judge(names[0], prepare(Capture.read(args.judge), DEMOS[names[0]]))
        print("\n".join(log))
        sys.exit(0 if ok else 1)
    results = bench(names, args)
    if results:
        print("\n".join("%-5s %s" % (n, "PASS" if ok else "FAIL") for n, ok in results.items()))
        sys.exit(0 if all(results.values()) else 1)


if __name__ == "__main__":
    main()
