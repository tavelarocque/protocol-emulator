# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Tiny Tapeout testbench, run against the RTL and against the post-layout
# gate-level netlist. It drives the chip only through its pins, the way the
# demo board's RP2040 will: an SPI host loads firmware (assembled from
# model/firmware.ml into *.hex by dune), configures the core, and moves data
# through the FIFOs. The protocol pins are judged by an independent UART
# receiver written here in Python.

import os
import random
import re
import zlib

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge, ValueChange

HALF = 6  # core clocks per SCK phase (must be >= 4)

CTRL, PIN_MODES, TX_FIFO, RX_FIFO, STATUS = 0x40, 0x47, 0x48, 0x49, 0x4A
FIFO_DEPTH = 4

HERE = os.path.dirname(os.path.abspath(__file__))


def firmware(name):
    with open(os.path.join(HERE, name + ".hex")) as f:
        return [int(line, 16) for line in f if line.strip()]


def drive(dut, sck, cs_n, mosi):
    dut.ui_in.value = sck | (cs_n << 1) | (mosi << 2)


async def reset(dut, period_ps=100_000):
    """Starts the clock and resets the chip; returns the clock."""
    clock = Clock(dut.clk, period_ps, unit="ps")
    clock.start()  # 10 MHz by default
    dut.ena.value = 1
    drive(dut, 0, 1, 0)
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 4)
    return clock


async def transfer(dut, write, addr, data=0):
    """One SPI mode-0 transaction, MSB first. Returns the 16 bits on MISO."""
    word = (int(write) << 23) | (addr << 16) | (data & 0xFFFF)
    drive(dut, 0, 0, 0)
    await ClockCycles(dut.clk, HALF)
    read = 0
    for b in range(23, -1, -1):
        mosi = (word >> b) & 1
        drive(dut, 0, 0, mosi)
        await ClockCycles(dut.clk, HALF)
        if b < 16:
            read = (read << 1) | (int(dut.uo_out.value) & 1)
        drive(dut, 1, 0, mosi)
        await ClockCycles(dut.clk, HALF)
    drive(dut, 0, 0, 0)
    await ClockCycles(dut.clk, HALF)
    drive(dut, 0, 1, 0)
    await ClockCycles(dut.clk, 2 * HALF)
    return read


async def write(dut, addr, data):
    await transfer(dut, True, addr, data)


async def read(dut, addr):
    return await transfer(dut, False, addr)


async def load(dut, words):
    await write(dut, CTRL, 0)
    for addr, w in enumerate(words):
        await write(dut, addr, w)


BANK1 = 0x10  # thread 1's registers are thread 0's plus this


async def push(dut, v, bank=0):
    while (await read(dut, STATUS + bank)) & 0x7 >= FIFO_DEPTH:
        pass
    await write(dut, TX_FIFO + bank, v)


async def pop(dut, bank=0):
    while ((await read(dut, STATUS + bank)) >> 4) & 0x7 == 0:
        pass
    return await read(dut, RX_FIFO + bank)


def uart_decode(samples, divisor):
    out, t = [], 1
    while t < len(samples):
        if samples[t - 1] == 1 and samples[t] == 0:
            mids = [t + k * divisor + divisor // 2 for k in range(10)]
            assert mids[-1] < len(samples), "truncated frame"
            bits = [samples[m] for m in mids]
            assert bits[0] == 0, "bad start bit"
            assert bits[9] == 1, "bad stop bit"
            out.append(sum(bits[1 + k] << k for k in range(8)))
            t = mids[-1] + 1
        else:
            t += 1
    return out


@cocotb.test()
async def test_registers(dut):
    await reset(dut)
    assert await read(dut, 0x42) == 0x10  # OUT config reset value
    assert await read(dut, 0x45) == 8  # THRESHOLD reset value
    await write(dut, PIN_MODES, 0xA5C3)
    assert await read(dut, PIN_MODES) == 0xA5C3


@cocotb.test()
async def test_echo(dut):
    """Words round-trip through SPI, both FIFOs and the core."""
    await reset(dut)
    await load(dut, firmware("echo"))
    await write(dut, CTRL, 1)
    values = [0x0000, 0xFFFF, 0x1234, 0xBEEF, 0x8001]
    got = []
    for v in values:
        await push(dut, v)
        got.append(await pop(dut))
    assert got == values, f"sent {values}, got {got}"


@cocotb.test()
async def test_uart_tx(dut):
    """UART firmware loaded over SPI; bytes on uio[0] decode correctly."""
    await reset(dut)
    divisor = 16
    data = [0x55, 0x00, 0xFF, 0x4D]
    await load(dut, firmware("uart_tx"))
    await write(dut, PIN_MODES, 0b01)  # uio[0] push-pull, rest inputs
    await write(dut, CTRL, 1)

    samples = []

    async def record():
        while True:
            await RisingEdge(dut.clk)
            assert int(dut.uio_oe.value) & 1 == 1, "uio[0] not driven"
            samples.append(int(dut.uio_out.value) & 1)

    recorder = cocotb.start_soon(record())
    await push(dut, divisor - 4)
    for b in data:
        await push(dut, b)
    await ClockCycles(dut.clk, (FIFO_DEPTH + 1) * (10 * divisor + 4))
    recorder.cancel()
    got = uart_decode(samples, divisor)
    assert got == data, f"sent {data}, decoded {got}"


# --- I2C --------------------------------------------------------------------
#
# A Python I2C target and bus monitor, written separately from the OCaml
# ones in model/i2c_model.ml so the two cannot share a misreading of the
# spec. The open-drain bus is resolved every clock: a line is low if the
# chip drives it (uio_oe set on an open-drain pin) or the target pulls it.

SET_CFG, TIMEOUT_VECTOR, TIMEOUT = 0x43, 0x46, 0x4B
I2C_TIMEOUT_VECTOR = 42  # Firmware.i2c_timeout_vector; checked by the OCaml tests


def i2c_words(address, data):
    """Host words for one write transaction (see model/firmware.ml)."""
    raw = [address << 1] + list(data)
    out = []
    for i, b in enumerate(raw):
        rev = int(f"{b:08b}"[::-1], 2)
        out.append(rev | (1 << 8) | ((i == len(raw) - 1) << 9))
    return out


class I2cTarget:
    """Writes: ACKs and collects bytes. Reads: sends to_send MSB first,
    changing SDA only while SCL is low, until the controller NACKs."""

    def __init__(self, address, stretch, to_send=()):
        self.address, self.stretch = address, stretch
        self.state, self.bits, self.shift = "idle", 0, 0
        self.first, self.reading = True, False
        self.stretch_left = 0
        self.prev = (1, 1)
        self.received, self.to_send, self.sent = [], list(to_send), []
        self.out, self.acked = 0xFF, False

    def _load(self):
        self.out = self.to_send.pop(0) if self.to_send else 0xFF
        self.sent.append(self.out)

    def drive(self):
        """(pull SDA low, pull SCL low) for this cycle."""
        sending_zero = self.state == "tx" and not (self.out >> (7 - self.bits)) & 1
        return self.state == "ack" or sending_zero, self.stretch_left > 0

    def step(self, sda, scl):
        psda, pscl = self.prev
        if self.stretch_left:
            self.stretch_left -= 1
        rise, fall = (not pscl and scl), (pscl and not scl)
        if pscl and scl and sda != psda:
            if sda == 0:
                self.state, self.bits, self.shift, self.first = "rx", 0, 0, True
                self.reading = False
            else:
                self.state = "idle"
        elif self.state == "rx" and not pscl and scl:
            self.shift = ((self.shift << 1) | sda) & 0xFF
            self.bits += 1
        elif self.state == "rx" and self.bits == 8 and pscl and not scl:
            if self.first:
                self.reading = bool(self.shift & 1)
                self.state = "ack" if (self.shift >> 1) == self.address else "ignore"
            else:
                self.received.append(self.shift)
                self.state = "ack"
        elif self.state == "ack" and fall:
            self.bits, self.shift, self.first = 0, 0, False
            self.stretch_left = self.stretch
            if self.reading:
                self._load()
                self.state = "tx"
            else:
                self.state = "rx"
        elif self.state == "tx" and fall:
            self.bits += 1
            if self.bits == 8:
                self.state = "cack"
        elif self.state == "cack" and rise:
            self.acked = sda == 0
        elif self.state == "cack" and fall:
            if self.acked:
                self._load()
                self.state, self.bits = "tx", 0
                self.stretch_left = self.stretch
            else:
                self.state = "ignore"
        self.prev = (sda, scl)


class I2cMonitor:
    def __init__(self):
        self.events, self.errors = [], []
        self.prev, self.bits, self.active = (1, 1), [], False

    def step(self, sda, scl):
        psda, pscl = self.prev
        if pscl and scl and sda != psda:
            if 2 <= len(self.bits) <= 8:
                self.errors.append(f"START/STOP after {len(self.bits)} bits")
            self.events.append("START" if sda == 0 else "STOP")
            self.active, self.bits = sda == 0, []
        elif self.active and not pscl and scl:
            self.bits.append(sda)
            if len(self.bits) == 9:
                value = int("".join(map(str, self.bits[:8])), 2)
                self.events.append((value, "ACK" if self.bits[8] == 0 else "NACK"))
                self.bits = []
        self.prev = (sda, scl)


async def i2c_bus(dut, target, monitor):
    while True:
        await FallingEdge(dut.clk)  # mid-cycle: chip outputs have settled
        oe = int(dut.uio_oe.value)
        t_sda, t_scl = target.drive()
        sda = 0 if (oe & 1 or t_sda) else 1
        scl = 0 if (oe & 2 or t_scl) else 1
        dut.uio_in.value = 0xFC | sda | (scl << 1)
        target.step(sda, scl)
        monitor.step(sda, scl)


@cocotb.test()
async def test_i2c(dut):
    """I2C firmware loaded over SPI writes to a target that stretches SCL."""
    await reset(dut)
    address, data = 0x3C, [0xAE, 0x5A, 0x00]
    target, monitor = I2cTarget(address, stretch=40), I2cMonitor()
    await load(dut, firmware("i2c_controller"))
    await write(dut, SET_CFG, 0x11)  # SET drives SCL: base 1, count 1
    await write(dut, TIMEOUT_VECTOR, I2C_TIMEOUT_VECTOR)
    await write(dut, TIMEOUT, 10000)
    await write(dut, PIN_MODES, 0b1010)  # P0 SDA, P1 SCL open-drain
    bus = cocotb.start_soon(i2c_bus(dut, target, monitor))
    await write(dut, CTRL, 1)
    for w in [4] + i2c_words(address, data):
        await push(dut, w)
    reports = [await pop(dut) for _ in range(len(data) + 1)]
    await ClockCycles(dut.clk, 400)
    bus.cancel()
    assert monitor.errors == [], monitor.errors
    expected = ["START", (address << 1, "ACK")] + [(b, "ACK") for b in data] + ["STOP"]
    assert monitor.events == expected, f"bus: {monitor.events}"
    assert target.received == data, f"target got {target.received}"
    assert reports == [0] * (len(data) + 1), f"ACK reports {reports}"


# --- SPI --------------------------------------------------------------------
#
# A Python SPI mode-0 slave and monitor, separate from model/spi_model.ml.
# P0 SCK, P1 MOSI, P3 CS_N are driven by the chip; P2 MISO by the slave.
# Undriven pins read as the board pulls them: SCK low, CS_N high.

OUT_CFG, IN_BASE, SIDESET = 0x42, 0x44, 0x4C
SYNC_BYPASS = 0x4E  # pins read without the 2-flop input synchroniser


def rev8(b):
    return int(f"{b:08b}"[::-1], 2)


class SpiSlave:
    def __init__(self, responses):
        self.responses = list(responses)
        self.received = []
        self.selected, self.shift, self.bits = False, 0, 0
        self.out, self.fresh, self.miso, self.prev_sck = 0xFF, False, 1, 0

    def _load(self):
        self.out = self.responses.pop(0) if self.responses else 0xFF
        self.fresh, self.miso = True, (self.out >> 7) & 1

    def step(self, sck, mosi, cs_n):
        rise, fall = (not self.prev_sck and sck), (self.prev_sck and not sck)
        if cs_n:
            self.selected, self.miso = False, 1
        elif not self.selected:
            self.selected, self.shift, self.bits = True, 0, 0
            if self.fresh:
                self.miso = (self.out >> 7) & 1
            else:
                self._load()
        elif rise:
            self.shift = ((self.shift << 1) | mosi) & 0xFF
            self.bits += 1
            self.fresh = False
        elif fall:
            if self.bits == 8:
                self.received.append(self.shift)
                self.shift, self.bits = 0, 0
                self._load()
            else:
                self.miso = (self.out >> (7 - self.bits)) & 1
        self.prev_sck = sck


class SpiMonitor:
    def __init__(self):
        self.prev = (0, 0, 1)
        self.mosi_bits, self.miso_bits = [], []
        self.events, self.errors = [], []

    def step(self, sck, mosi, miso, cs_n):
        psck, pmosi, pcs = self.prev
        if cs_n != pcs:
            if sck or psck:
                self.errors.append("CS_N changed while SCK high")
            if cs_n and self.mosi_bits:
                self.errors.append(f"deselected after {len(self.mosi_bits)} bits")
            self.events.append("DESELECT" if cs_n else "SELECT")
            self.mosi_bits, self.miso_bits = [], []
        elif not cs_n:
            if psck and sck and mosi != pmosi:
                self.errors.append("MOSI changed while SCK high")
            if not psck and sck:
                self.mosi_bits.append(mosi)
                self.miso_bits.append(miso)
                if len(self.mosi_bits) == 8:
                    to = lambda bits: int("".join(map(str, bits)), 2)
                    self.events.append((to(self.mosi_bits), to(self.miso_bits)))
                    self.mosi_bits, self.miso_bits = [], []
        self.prev = (sck, mosi, cs_n)


async def spi_bus(dut, slave, monitor):
    while True:
        await FallingEdge(dut.clk)
        out, oe = int(dut.uio_out.value), int(dut.uio_oe.value)
        sck = (out & 1) if oe & 1 else 0
        mosi = ((out >> 1) & 1) if oe & 2 else 0
        cs_n = ((out >> 3) & 1) if oe & 8 else 1
        monitor.step(sck, mosi, slave.miso, cs_n)
        slave.step(sck, mosi, cs_n)
        # Respond before the chip's next sample (well under one clock, as
        # real SPI devices do); the side-set firmware relies on it.
        dut.uio_in.value = slave.miso << 2


async def spi_transfer(dut, fast):
    sent, responses = [0x9F, 0x00, 0xA5], [0x11, 0xEF, 0x5A]
    slave, monitor = SpiSlave(responses), SpiMonitor()
    if fast:
        await load(dut, firmware("spi_fast"))
        await write(dut, SIDESET, 0x10)  # side-set drives SCK: base 0, count 1
        await write(dut, SYNC_BYPASS, 0b100)  # MISO is sampled one clock after SCK falls
    else:
        await load(dut, firmware("spi_controller"))
        await write(dut, SET_CFG, 0x10)  # SET drives SCK: base 0, count 1
    await write(dut, OUT_CFG, 0x31)  # OUT/MOV: base 1 (MOSI), count 3 (.., CS_N)
    await write(dut, IN_BASE, 2)  # MISO
    await write(dut, PIN_MODES, 0b01_00_01_01)  # P0, P1, P3 push-pull; P2 input
    bus = cocotb.start_soon(spi_bus(dut, slave, monitor))
    await write(dut, CTRL, 1)
    words = ([] if fast else [1]) + [rev8(b) | ((i == len(sent) - 1) << 8) for i, b in enumerate(sent)]
    for w in words:
        await push(dut, w)
    got = [rev8((await pop(dut)) & 0xFF) for _ in sent]
    await ClockCycles(dut.clk, 200)
    bus.cancel()
    assert monitor.errors == [], monitor.errors
    assert monitor.events == ["SELECT"] + list(zip(sent, responses)) + ["DESELECT"], monitor.events
    assert slave.received == sent, f"slave got {slave.received}"
    assert got == responses, f"host got {got}"


@cocotb.test()
async def test_spi(dut):
    """SPI controller firmware loaded over SPI, full duplex with a slave."""
    await reset(dut)
    await spi_transfer(dut, fast=False)


@cocotb.test()
async def test_spi_fast(dut):
    """Side-set SPI firmware: 2 core clocks per bit."""
    await reset(dut)
    await spi_transfer(dut, fast=True)


SHIFT = 0x4F  # bit 0: OUT MSB first, bit 1: IN MSB first


@cocotb.test()
async def test_spi_msb_first(dut):
    """Side-set SPI with the thread shifting MSB first: the host pushes and
    pops plain bytes, no bit reversal."""
    await reset(dut)
    sent, responses = [0x9F, 0x01, 0x80], [0x12, 0xFE, 0x7F]
    slave, monitor = SpiSlave(responses), SpiMonitor()
    await load(dut, firmware("spi_fast"))
    await write(dut, SIDESET, 0x10)
    await write(dut, OUT_CFG, 0x31)
    await write(dut, IN_BASE, 2)
    await write(dut, SHIFT, 0b11)
    await write(dut, SYNC_BYPASS, 0b100)
    await write(dut, PIN_MODES, 0b01_00_01_01)
    bus = cocotb.start_soon(spi_bus(dut, slave, monitor))
    await write(dut, CTRL, 1)
    for i, b in enumerate(sent):
        await push(dut, (b << 8) | ((i == len(sent) - 1) << 7))
    got = [await pop(dut) for _ in sent]
    await ClockCycles(dut.clk, 200)
    bus.cancel()
    assert monitor.errors == [], monitor.errors
    assert monitor.events == ["SELECT"] + list(zip(sent, responses)) + ["DESELECT"], monitor.events
    assert slave.received == sent, f"slave got {slave.received}"
    assert got == responses, f"host got {got}"


# --- Two threads ------------------------------------------------------------

START = 0x41
UART_ORIGIN = 26  # Firmware.Two_protocols.uart_origin; checked by the OCaml tests


@cocotb.test()
async def test_two_protocols(dut):
    """Side-set SPI on thread 0 and UART on thread 1, running together from
    one memory image, each checked by its own Python oracle."""
    await reset(dut)
    sent, responses = [0x3C, 0xC3, 0x01], [0x81, 0x7E, 0xF0]
    divisor, data = 12, [0xA5, 0x0F, 0x80]
    slave, monitor = SpiSlave(responses), SpiMonitor()
    await load(dut, firmware("two_protocols"))
    # Thread 0: SPI on P0..P3, SCK by side-set.
    await write(dut, SIDESET, 0x10)
    await write(dut, OUT_CFG, 0x31)
    await write(dut, IN_BASE, 2)
    # Thread 1: UART on P4, running from where the image put it.
    await write(dut, START + BANK1, UART_ORIGIN)
    await write(dut, OUT_CFG + BANK1, 0x14)
    await write(dut, SET_CFG + BANK1, 0x14)
    await write(dut, PIN_MODES, 0b01_01_00_01_01)  # P0, P1, P3, P4 push-pull
    await write(dut, SYNC_BYPASS, 0b100)  # MISO (P2) read directly
    bus = cocotb.start_soon(spi_bus(dut, slave, monitor))
    samples = []

    async def record():
        while True:
            await RisingEdge(dut.clk)
            samples.append((int(dut.uio_out.value) >> 4) & 1)

    recorder = cocotb.start_soon(record())
    await write(dut, CTRL, 0b11)  # both threads start in the same cycle
    for w in [divisor - 4] + data:
        await push(dut, w, bank=BANK1)
    for i, b in enumerate(sent):
        await push(dut, rev8(b) | ((i == len(sent) - 1) << 8))
    got = [rev8((await pop(dut)) & 0xFF) for _ in sent]
    await ClockCycles(dut.clk, (FIFO_DEPTH + 1) * (10 * divisor + 4))
    bus.cancel()
    recorder.cancel()
    assert monitor.errors == [], monitor.errors
    assert monitor.events == ["SELECT"] + list(zip(sent, responses)) + ["DESELECT"], monitor.events
    assert slave.received == sent, f"slave got {slave.received}"
    assert got == responses, f"host got {got}"
    uart = uart_decode(samples, divisor)
    assert uart == data, f"UART sent {data}, decoded {uart}"
    assert int(dut.uo_out.value) & 0b10010 == 0b10010, "both threads reported running"


# --- I2C controller v2 (clock divider; reads and writes) ---------------------

CLKDIV = 0x4D
I2C_STUCK = 23  # Firmware.i2c_stuck; checked by the OCaml tests


async def configure_i2c(dut, bank=0, clkdiv=3):
    await write(dut, OUT_CFG + bank, 0x10)  # OUT: SDA (P0), 1 pin
    await write(dut, SET_CFG + bank, 0x10)  # SET: SDA (P0), 1 pin
    await write(dut, IN_BASE + bank, 0)
    await write(dut, SIDESET + bank, 0x11)  # side-set: SCL (P1), 1 bit
    await write(dut, TIMEOUT_VECTOR + bank, I2C_STUCK)
    await write(dut, TIMEOUT + bank, 10000)
    await write(dut, CLKDIV + bank, clkdiv)


def i2c_write_word(b, stop, restart=False):
    """[restart]: a repeated START after this byte, in place of a STOP."""
    return rev8(b) | (1 << 8) | (int(stop) << 9) | (int(restart) << 10)


def i2c_read_word(last):
    return 0xFF | (int(last) << 8) | (int(last) << 9)


@cocotb.test()
async def test_i2c_register_read(dut):
    """Divider-timed I2C: write a register pointer, then read three bytes."""
    await reset(dut)
    address, register, data = 0x48, 0x0F, [0xC3, 0x00, 0x7E]
    target, monitor = I2cTarget(address, stretch=30, to_send=data), I2cMonitor()
    await load(dut, firmware("i2c"))
    await configure_i2c(dut)
    await write(dut, PIN_MODES, 0b1010)  # P0 SDA, P1 SCL open-drain
    bus = cocotb.start_soon(i2c_bus(dut, target, monitor))
    await write(dut, CTRL, 1)
    words = [i2c_write_word(address << 1, False), i2c_write_word(register, True),
             i2c_write_word((address << 1) | 1, False)]
    words += [i2c_read_word(i == len(data) - 1) for i in range(len(data))]
    for w in words:
        await push(dut, w)
    reports = [await pop(dut) for _ in words]
    await ClockCycles(dut.clk, 400)
    bus.cancel()
    assert monitor.errors == [], monitor.errors
    expected = ["START", (address << 1, "ACK"), (register, "ACK"), "STOP",
                "START", ((address << 1) | 1, "ACK")]
    expected += [(b, "ACK" if i < len(data) - 1 else "NACK") for i, b in enumerate(data)]
    assert monitor.events == expected + ["STOP"], f"bus: {monitor.events}"
    assert target.received == [register], f"target got {target.received}"
    assert [rev8(r & 0xFF) for r in reports[3:]] == data, f"reports {reports}"
    assert reports[-1] & 0x100, "last byte reported as NACKed"


# --- The bridge: I2C read in, SPI out, chained, no host in the data path -----

BRIDGE_SPI_ORIGIN = 30  # Firmware.Bridge.spi_origin; checked by the OCaml tests


@cocotb.test()
async def test_bridge(dut):
    """Thread 0 reads an I2C device; CHAIN feeds each byte to thread 1, which
    sends it over SPI. The host only queues the read and drains SPI replies."""
    await reset(dut)
    address, data = 0x29, [0x12, 0xF0, 0x81]
    sent = [(address << 1) | 1] + data
    responses = [0x5A, 0x00, 0xFF, 0x3C]
    target, i2c_mon = I2cTarget(address, stretch=20, to_send=data), I2cMonitor()
    slave, spi_mon = SpiSlave(responses), SpiMonitor()
    await load(dut, firmware("bridge"))
    await configure_i2c(dut)
    await write(dut, START + BANK1, BRIDGE_SPI_ORIGIN)
    await write(dut, SIDESET + BANK1, 0x12)  # SCK = P2 by side-set
    await write(dut, OUT_CFG + BANK1, 0x33)  # MOSI P3, (MISO P4), CS_N P5
    await write(dut, IN_BASE + BANK1, 4)  # MISO
    await write(dut, PIN_MODES, 0b01_00_01_01_10_10)
    await write(dut, SYNC_BYPASS, 0b1_0000)  # MISO (P4) read directly

    async def buses():
        while True:
            await FallingEdge(dut.clk)
            out, oe = int(dut.uio_out.value), int(dut.uio_oe.value)
            t_sda, t_scl = target.drive()
            sda = 0 if (oe & 1 or t_sda) else 1
            scl = 0 if (oe & 2 or t_scl) else 1
            sck = (out >> 2) & 1 if oe & 4 else 0
            mosi = (out >> 3) & 1 if oe & 8 else 0
            cs_n = (out >> 5) & 1 if oe & 32 else 1
            target.step(sda, scl)
            i2c_mon.step(sda, scl)
            spi_mon.step(sck, mosi, slave.miso, cs_n)
            slave.step(sck, mosi, cs_n)
            dut.uio_in.value = 0xEC | sda | (scl << 1) | (slave.miso << 4)

    bus = cocotb.start_soon(buses())
    await write(dut, CTRL, 0b111)  # both threads, CHAIN
    words = [i2c_write_word((address << 1) | 1, False)]
    words += [i2c_read_word(i == len(data) - 1) for i in range(len(data))]
    for w in words:
        await push(dut, w)
    replies = [rev8((await pop(dut, bank=BANK1)) & 0xFF) for _ in sent]
    await ClockCycles(dut.clk, 400)
    bus.cancel()
    assert i2c_mon.errors == [], i2c_mon.errors
    assert spi_mon.errors == [], spi_mon.errors
    expected_i2c = ["START", ((address << 1) | 1, "ACK")]
    expected_i2c += [(b, "ACK" if i < len(data) - 1 else "NACK") for i, b in enumerate(data)]
    assert i2c_mon.events == expected_i2c + ["STOP"], f"I2C: {i2c_mon.events}"
    assert spi_mon.events == ["SELECT"] + list(zip(sent, responses)) + ["DESELECT"], f"SPI: {spi_mon.events}"
    assert slave.received == sent, f"SPI device got {slave.received}"
    assert replies == responses, f"host got {replies}"


# --- Full-duplex UART: TX on thread 0 (P0), RX on thread 1 (P1) --------------

UART_RX_ORIGIN = 15  # Firmware.Uart_duplex.rx_origin; checked by the OCaml tests


@cocotb.test()
async def test_uart_duplex(dut):
    """UART TX looped back into the UART RX firmware on the other thread, and
    frames from an independent Python sender, off-rate by 2%."""
    await reset(dut)
    divisor = 16
    await load(dut, firmware("uart_duplex"))
    await write(dut, OUT_CFG, 0x10)  # TX: OUT/SET on P0
    await write(dut, SET_CFG, 0x10)
    await write(dut, START + BANK1, UART_RX_ORIGIN)
    await write(dut, IN_BASE + BANK1, 1)  # RX on P1
    await write(dut, 0x45 + BANK1, 9)  # THRESHOLD: 8 data bits + stop bit
    await write(dut, TIMEOUT + BANK1, 0)  # stop-bit check: low jumps at once
    await write(dut, TIMEOUT_VECTOR + BANK1, UART_RX_ORIGIN + 13)  # Firmware.uart_rx_bad
    await write(dut, PIN_MODES, 0b00_01)  # P0 push-pull, P1 input
    external = []  # when non-empty, P1 is driven from here instead of P0

    async def wire():
        while True:
            await FallingEdge(dut.clk)
            tx = int(dut.uio_out.value) & 1
            rx = external.pop(0) if external else tx
            dut.uio_in.value = 0xFD | (rx << 1)

    w = cocotb.start_soon(wire())
    await write(dut, CTRL, 0b11)
    for v in [divisor - 4, divisor // 2 - 1]:
        await push(dut, v, bank=BANK1)
    await push(dut, divisor - 4)
    data = [0x00, 0xFF, 0x5A, 0x81]
    got = []
    for b in data:
        await push(dut, b)
        got.append(await pop(dut, bank=BANK1))
    assert got == [b | 0x100 for b in data], f"loopback: sent {data}, got {got}"
    # Now an independent sender, 2% slow: bit time 16.32 cycles.
    bit_time = divisor * 1.02
    for b in [0xC3, 0x0F]:
        bits = [1] * 3 + [0] + [(b >> k) & 1 for k in range(8)] + [1] * 3
        external.extend(bits[int(c / bit_time)] for c in range(int(len(bits) * bit_time)))
        got = await pop(dut, bank=BANK1)
        assert got == b | 0x100, f"off-rate sender: sent {b:#x}, got {got:#x}"
    w.cancel()


# --- Third-party devices -----------------------------------------------------
#
# Every device above was written for this project. These tests connect the
# chip to device models written by other people, from real datasheets, via
# bus wires in tb.v (dev_mode): picosoc's Verilog SPI flash (YosysHQ, ISC),
# and the I2C EEPROM and UART models from cocotbext-i2c and cocotbext-uart
# (Alex Forencich, MIT). The chip's firmware has to speak the real protocol
# well enough for someone else's device to understand it.

from cocotbext.i2c import I2cDevice, I2cMaster, I2cMemory
from cocotbext.uart import UartSink, UartSource


@cocotb.test(timeout_time=20, timeout_unit="ms")
async def test_thirdparty_spi_flash(dut):
    """Read a SPI flash the way a real driver does: release from power-down
    (0xAB), then a 0x03 read at a 24-bit address. Plain bytes both ways
    (SHIFT = MSB first)."""
    await reset(dut)
    address, data = 0x012345, [0xC0, 0xFF, 0xEE, 0x42]
    for k, b in enumerate(data):
        dut.flash.memory[address + k].value = b
    dut.dev_mode.value = 2
    await load(dut, firmware("spi_fast"))
    await write(dut, SIDESET, 0x10)  # SCK = P0 by side-set
    await write(dut, OUT_CFG, 0x31)  # MOSI P1, (MISO P2), CS_N P3
    await write(dut, IN_BASE, 2)
    await write(dut, SHIFT, 0b11)
    await write(dut, SYNC_BYPASS, 0b100)
    await write(dut, PIN_MODES, 0b01_00_01_01)
    await write(dut, CTRL, 1)

    async def transaction(tx):
        for i, b in enumerate(tx):
            await push(dut, (b << 8) | ((i == len(tx) - 1) << 7))
        return [await pop(dut) for _ in tx]

    await transaction([0xAB])  # the model starts powered down, as real parts can
    command = [0x03, address >> 16, (address >> 8) & 0xFF, address & 0xFF]
    got = await transaction(command + [0] * len(data))
    assert got[len(command):] == data, f"flash returned {got[len(command):]}"


@cocotb.test(timeout_time=40, timeout_unit="ms")
async def test_thirdparty_i2c_eeprom(dut):
    """Write three bytes into an I2C EEPROM, set its address pointer, and
    read them back, with the divider-timed I2C controller."""
    await reset(dut)
    dut.dev_mode.value = 1
    eeprom = I2cMemory(
        sda=dut.i2c_sda, sda_o=dut.i2c_sda_dev, scl=dut.i2c_scl, scl_o=dut.i2c_scl_dev,
        addr=0x50, size=256)
    await load(dut, firmware("i2c"))
    await configure_i2c(dut)
    await write(dut, PIN_MODES, 0b1010)  # P0 SDA, P1 SCL open-drain
    await write(dut, CTRL, 1)
    pointer, data = 0x10, [0xDE, 0xAD, 0xBE]
    # Write: address + W, memory pointer, data, STOP.
    words = [i2c_write_word(0x50 << 1, False), i2c_write_word(pointer, False)]
    words += [i2c_write_word(b, i == len(data) - 1) for i, b in enumerate(data)]
    for w in words:
        await push(dut, w)
    reports = [await pop(dut) for _ in words]
    assert all(r & 0x100 == 0 for r in reports), f"NACKed: {[hex(r) for r in reports]}"
    assert eeprom.read_mem(pointer, len(data)) == bytes(data), "EEPROM contents"
    # Read back: set the pointer, then address + R and three reads.
    words = [i2c_write_word(0x50 << 1, False), i2c_write_word(pointer, True),
             i2c_write_word((0x50 << 1) | 1, False)]
    words += [i2c_read_word(i == len(data) - 1) for i in range(len(data))]
    for w in words:
        await push(dut, w)
    reports = [await pop(dut) for _ in words]
    got = [rev8(r & 0xFF) for r in reports[3:]]
    assert got == data, f"read back {got}"
    # And as devices expect a register read: a repeated START where that
    # STOP was. The bus is never free between the pointer and the read.
    words = [i2c_write_word(0x50 << 1, False), i2c_write_word(pointer + 1, False, restart=True),
             i2c_write_word((0x50 << 1) | 1, False)]
    words += [i2c_read_word(i == 1) for i in range(2)]
    for w in words:
        await push(dut, w)
    reports = [await pop(dut) for _ in words]
    assert all(r & 0x100 == 0 for r in reports[:3]), f"NACKed: {[hex(r) for r in reports]}"
    got = [rev8(r & 0xFF) for r in reports[3:]]
    assert got == data[1:], f"read back after a repeated START: {got}"


@cocotb.test(timeout_time=40, timeout_unit="ms")
async def test_thirdparty_uart(dut):
    """The chip's UART transmitter into an outside UART receiver, and an
    outside UART transmitter into the chip's receiver, at 625 kbaud."""
    await reset(dut)
    divisor = 16
    baud = 10_000_000 // divisor
    dut.dev_mode.value = 3
    sink = UartSink(dut.uart_tx, baud=baud, bits=8)
    source = UartSource(dut.uart_rx, baud=baud, bits=8)
    await load(dut, firmware("uart_duplex"))
    await write(dut, OUT_CFG, 0x10)
    await write(dut, SET_CFG, 0x10)
    await write(dut, START + BANK1, UART_RX_ORIGIN)
    await write(dut, IN_BASE + BANK1, 1)
    await write(dut, 0x45 + BANK1, 9)
    await write(dut, TIMEOUT + BANK1, 0)
    await write(dut, TIMEOUT_VECTOR + BANK1, UART_RX_ORIGIN + 13)
    await write(dut, PIN_MODES, 0b00_01)
    await write(dut, CTRL, 0b11)
    for v in [divisor - 4, divisor // 2 - 1]:
        await push(dut, v, bank=BANK1)
    await push(dut, divisor - 4)
    sent = b"Hi, JS!"
    for b in sent:
        await push(dut, b)
    received = bytearray()
    while len(received) < len(sent):  # read() returns whatever has arrived
        received += await sink.read()
    assert bytes(received) == sent, f"outside receiver got {bytes(received)!r}"
    incoming = b"\x00\xffOK"
    await source.write(incoming)
    words = [await pop(dut, bank=BANK1) for _ in incoming]
    assert all(w & 0x100 for w in words), "stop bits"
    got = bytes(w & 0xFF for w in words)
    assert got == incoming, f"chip received {got!r}"


# --- Device mode: the chip as an I2C device, driven by an outside controller -

I2C_TARGET_REST = 57  # Firmware.i2c_target_rest; checked by the OCaml tests
THRESHOLD = 0x45


def marker(address, read):
    """The RX word Firmware.i2c_target pushes for a START addressed to it."""
    return ((address << 1) | int(read)) << 8


LOAD = 0x50  # where program writes go: page [1:0], thread 0 [4], thread 1 [5]


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_separate_programs(dut):
    """Each thread has its own program memory. Thread 0 runs the I2C target
    (63 words) for cocotbext-i2c's controller while thread 1 runs the UART
    transmitter (15 words) into cocotbext-uart's receiver: 78 words, both
    starting at address 0 of their own memory. Then thread 1 is stopped and
    reloaded with the echo program while thread 0 goes on answering."""
    await reset(dut)
    dut.dev_mode.value = 1
    master = I2cMaster(
        sda=dut.i2c_sda, sda_o=dut.i2c_sda_dev, scl=dut.i2c_scl, scl_o=dut.i2c_scl_dev,
        speed=400e3)
    divisor = 16
    sink = UartSink(dut.uart_tx_p4, baud=10_000_000 // divisor, bits=8)
    target, uart = firmware("i2c_target"), firmware("uart_tx")
    assert len(target) + len(uart) > 64, "the point: these do not fit one 64-word memory"
    await write(dut, CTRL, 0)
    await write(dut, LOAD, 0x10)  # thread 0's memory only
    for a, w in enumerate(target):
        await write(dut, a, w)
    await write(dut, LOAD, 0x20)  # thread 1's memory only
    for a, w in enumerate(uart):
        await write(dut, a, w)
    address = 0x3C
    await write(dut, OUT_CFG, 0x10)
    await write(dut, SET_CFG, 0x10)
    await write(dut, IN_BASE, 0)
    await write(dut, SIDESET, 0x11)
    await write(dut, THRESHOLD, 8)
    await write(dut, TIMEOUT, 0)
    await write(dut, TIMEOUT_VECTOR, I2C_TARGET_REST)
    await write(dut, SHIFT, 0b10)
    await write(dut, OUT_CFG + BANK1, 0x14)  # the UART on P4
    await write(dut, SET_CFG + BANK1, 0x14)
    await write(dut, PIN_MODES, 0b01_00_00_10_10)  # P0, P1 open-drain; P4 push-pull
    await write(dut, CTRL, 0b11)
    await push(dut, address)
    await push(dut, divisor - 4, bank=BANK1)

    # Both at once: a write over I2C while the UART sends.
    sent = b"v2"
    register, data = 0x10, [0xDE, 0xAD]
    async def i2c_write():
        await master.write(address, [register] + data)
        await master.send_stop()

    writer = cocotb.start_soon(i2c_write())
    for b in sent:
        await push(dut, b, bank=BANK1)
    got = [await pop(dut) for _ in range(4)]
    await writer
    assert got == [marker(address, False), register] + data, f"I2C RX {[hex(w) for w in got]}"
    received = bytearray()
    while len(received) < len(sent):
        received += await sink.read()
    assert bytes(received) == sent, f"UART got {bytes(received)!r}"

    # Stop thread 1 and give it another program. Thread 0 keeps its own, and
    # a write aimed at its memory while it runs changes nothing.
    await write(dut, CTRL, 0b01)
    await write(dut, LOAD, 0x30)  # both: thread 0 is running, so only thread 1's lands
    for a, w in enumerate(firmware("echo")):
        await write(dut, a, w)
    await write(dut, CTRL, 0b11)
    for v in [0x1234, 0xBEEF]:
        await push(dut, v, bank=BANK1)
        assert await pop(dut, bank=BANK1) == v, "thread 1 is not running the echo program"
    writer = cocotb.start_soon(i2c_write())
    got = [await pop(dut) for _ in range(4)]
    await writer
    assert got == [marker(address, False), register] + data, "thread 0's program was overwritten"


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_thirdparty_i2c_controller(dut):
    """The roles reversed: cocotbext-i2c's I2cMaster is the controller and the
    chip is the device, at 400 kHz. A probe of its address and of another
    one, a write that fills the RX FIFO (the chip stretches the clock until
    the host drains it), and a register read with a repeated START."""
    await reset(dut)
    dut.dev_mode.value = 1
    master = I2cMaster(
        sda=dut.i2c_sda, sda_o=dut.i2c_sda_dev, scl=dut.i2c_scl, scl_o=dut.i2c_scl_dev,
        speed=400e3)
    address = 0x3C
    await load(dut, firmware("i2c_target"))
    await write(dut, OUT_CFG, 0x10)  # OUT: SDA (P0), 1 pin
    await write(dut, SET_CFG, 0x10)  # SET: SDA (P0), 1 pin
    await write(dut, IN_BASE, 0)
    await write(dut, SIDESET, 0x11)  # side-set: SCL (P1), 1 bit, for stretching
    await write(dut, THRESHOLD, 8)
    await write(dut, TIMEOUT, 0)  # timed waits become branches on a pin
    await write(dut, TIMEOUT_VECTOR, I2C_TARGET_REST)
    await write(dut, SHIFT, 0b10)  # IN MSB first: bytes arrive as they are
    await write(dut, PIN_MODES, 0b1010)  # P0 SDA, P1 SCL open-drain
    await write(dut, CTRL, 1)
    await push(dut, address)  # the device's 7-bit address

    # Probe, as i2cdetect does: START, address + W, STOP.
    async def probe(a):
        await master.send_start()
        nack = await master.send_byte(a << 1)
        await master.send_stop()
        return nack

    assert not await probe(address), "the chip's address was NACKed"
    assert await probe(address + 1), "another address was ACKed"
    assert await pop(dut) == marker(address, False)

    # A write of five RX words (marker, register, three bytes) into a 4-deep
    # FIFO nobody is draining: the chip must hold SCL low after the last
    # byte's ACK, so the STOP waits, rather than lose a byte.
    register, data = 0x10, [0xDE, 0xAD, 0xBE]
    async def write_and_stop():
        await master.write(address, [register] + data)
        await master.send_stop()

    writer = cocotb.start_soon(write_and_stop())
    await ClockCycles(dut.clk, 3000)  # 300 us: the write itself takes ~120
    assert not writer.done(), "the controller finished while the RX FIFO was full"
    got = [await pop(dut) for _ in range(5)]
    await writer
    assert got == [marker(address, False), register] + data, f"RX {[hex(w) for w in got]}"

    # Register read: write the pointer, then a repeated START and three reads.
    # The host queues the reply first: cocotbext's I2cMaster samples SDA just
    # before it raises SCL, so it would not see a bit the chip drives after
    # a stretch at the start of a byte (a controller that samples on the
    # rising edge, as the I2C spec has it, would).
    reply = [0x5A, 0x00, 0xC3]
    for b in reply:
        await push(dut, rev8(b))
    await master.write(address, [register])
    back = await master.read(address, len(reply))
    await master.send_stop()
    assert list(back) == reply, f"controller read {list(back)}"
    got = [await pop(dut) for _ in range(3)]
    assert got == [marker(address, False), register, marker(address, True)], \
        f"RX {[hex(w) for w in got]}"


# --- Device mode: the chip as an SPI device, driven by an outside controller -

# cocotbext-spi 0.5.0 predates cocotb 2.0, which removed two things it
# uses: cocotb.clock.BaseClock (only a base class holding the signal) and
# the .integer of a one-bit value (it reads MISO as bool(v.integer)). Both
# are put back, with the same meaning; the package itself is unchanged.
import cocotb.clock  # noqa: E402
import cocotb.types  # noqa: E402

if not hasattr(cocotb.clock, "BaseClock"):
    class _BaseClock:
        def __init__(self, signal):
            self.signal = signal

    cocotb.clock.BaseClock = _BaseClock
if not hasattr(cocotb.types.Logic, "integer"):
    cocotb.types.Logic.integer = property(lambda v: int(v))

from cocotbext.spi import SpiBus, SpiConfig, SpiMaster  # noqa: E402

SPI_TARGET_DESEL = 16  # Firmware.spi_target_desel; checked by the OCaml tests
SPI_END = 0x100  # Firmware.spi_target_end_marker


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_thirdparty_spi_controller(dut):
    """The roles reversed for SPI: cocotbext-spi's SpiMaster is the controller
    (mode 0, 500 kHz) and the chip is the device. Two transfers, a JEDEC ID
    read and a 3-byte command, with the host keeping the replies queued."""
    await reset(dut)
    dut.dev_mode.value = 4
    master = SpiMaster(SpiBus.from_prefix(dut, "spi"), SpiConfig(
        word_width=8, sclk_freq=500e3, cpol=False, cpha=False, msb_first=True,
        cs_active_low=True, frame_spacing_ns=2000))
    await load(dut, firmware("spi_target"))
    await write(dut, OUT_CFG, 0x12)  # OUT: MISO (P2), 1 pin
    await write(dut, IN_BASE, 1)  # MOSI
    await write(dut, THRESHOLD, 8)
    await write(dut, TIMEOUT, 0)  # timed waits become branches on a pin
    await write(dut, TIMEOUT_VECTOR, SPI_TARGET_DESEL)
    await write(dut, SHIFT, 0b10)  # IN MSB first: bytes arrive as they are
    await write(dut, PIN_MODES, 0b00_01_00_00)  # P2 MISO push-pull, the rest inputs
    await write(dut, CTRL, 1)

    async def transfer(mosi, replies, more):
        """Queue [replies] (plus [more], the start of the next transfer's,
        to keep one ahead), run one transfer, return what the controller read
        and what the chip received."""
        for b in replies + more:
            await push(dut, rev8(b))
        master.write_nowait(mosi, burst=True)
        await master.wait()
        miso = list(master.read_nowait())
        rx = [await pop(dut) for _ in range(len(mosi) + 1)]
        return miso, rx

    jedec = [0xEF, 0x40, 0x18]
    command = [0x03, 0x12, 0x34]
    status = [0x00, 0x5A, 0xA5]
    # The firmware takes the first reply at start and one more after every
    # byte, so the first transfer's 4 replies plus 1 for the next.
    miso, rx = await transfer([0x9F, 0, 0, 0], [0x00] + jedec, [status[0]])
    assert miso == [0x00] + jedec, f"controller read {[hex(b) for b in miso]}"
    assert rx == [0x9F, 0, 0, 0, SPI_END], f"chip RX {[hex(w) for w in rx]}"
    miso, rx = await transfer(command, status[1:], [0xFF])
    assert miso == status, f"controller read {[hex(b) for b in miso]}"
    assert rx == command + [SPI_END], f"chip RX {[hex(w) for w in rx]}"


# --- The host driver: the board's MicroPython code, run against the chip ------
#
# host/protocol_emulator.py is the driver the demo board's RP2040 runs. These
# tests run that same file, unchanged, against the chip: the driver is
# blocking code, so it runs in a thread (cocotb's bridge), and each pin change
# it makes is handed back to the simulator, which waits HALF core clocks
# before the next one, as a slow microcontroller would.

import sys  # noqa: E402

sys.path.insert(0, os.path.join(HERE, "..", "host"))
import protocol_emulator as pe
import more_protocols as more
import extra_protocols as extra
import sigrok  # noqa: E402

try:
    from cocotb import bridge, resume  # noqa: E402
except ImportError:  # cocotb 2.0 exposes them only inside a running simulation
    from cocotb._bridge import bridge, resume  # noqa: E402


def sim_port(dut):
    # Whether the transaction under way is a write: its first bit, taken
    # here as the host sends it.
    state = {"bits": 0, "write": False}

    @resume
    async def set_pins(sck, cs_n, mosi):
        if cs_n:
            state["bits"] = 0
        elif sck:
            if state["bits"] == 0:
                state["write"] = bool(mosi)
            state["bits"] += 1
        drive(dut, sck, cs_n, mosi)
        await ClockCycles(dut.clk, HALF)

    @resume
    async def read_miso():
        miso = dut.uo_out.value[0]
        # During a write, MISO carries whatever the address would read, and
        # nobody uses it. For the packet buffer's data register that is a
        # word of memory never written, which a simulator shows as unknown.
        # A read must resolve.
        if state["write"] and not miso.is_resolvable:
            return 0
        return int(miso)

    return pe.BitBangPort(set_pins, read_miso)


def test_driver_constants():
    assert (pe.I2C_STUCK, pe.I2C_TARGET_REST, pe.SPI_TARGET_DESEL) == (
        I2C_STUCK, I2C_TARGET_REST, SPI_TARGET_DESEL)
    assert (pe.CTRL, pe.PIN_MODES, pe.TX_FIFO, pe.RX_FIFO, pe.STATUS, pe.SHIFT) == (
        CTRL, PIN_MODES, TX_FIFO, RX_FIFO, STATUS, SHIFT)


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_host_driver_uart_and_spi(dut):
    """The board driver sends UART to cocotbext-uart's receiver, then reads
    picosoc's SPI flash, from the same driver code the RP2040 runs."""
    test_driver_constants()
    await reset(dut)
    dut.dev_mode.value = 3
    divisor = 16
    sink = UartSink(dut.uart_tx, baud=10_000_000 // divisor, bits=8)
    chip = pe.Chip(sim_port(dut))
    message = b"pins to pins"

    @bridge
    def send():
        pe.UartTx(chip, firmware("uart_tx"), divisor=divisor).write(message)

    await send()
    received = bytearray()
    while len(received) < len(message):
        received += await sink.read()
    assert bytes(received) == message, f"UART receiver got {bytes(received)!r}"

    address, data = 0x000100, [0x12, 0x34, 0x56]
    for k, b in enumerate(data):
        dut.flash.memory[address + k].value = b
    dut.dev_mode.value = 2

    @bridge
    def read_flash():
        spi = pe.SpiController(chip, firmware("spi_fast"))
        spi.transfer([0xAB])  # wake from power-down
        return spi.transfer([0x03, 0x00, 0x01, 0x00, 0, 0, 0])[4:]

    got = await read_flash()
    assert got == data, f"flash returned {got}"


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_host_driver_devices(dut):
    """The board driver runs the chip as an I2C device (cocotbext-i2c's
    controller reads a register through a repeated START) and then as an SPI
    device (cocotbext-spi's controller)."""
    await reset(dut)
    chip = pe.Chip(sim_port(dut))
    dut.dev_mode.value = 1
    master = I2cMaster(
        sda=dut.i2c_sda, sda_o=dut.i2c_sda_dev, scl=dut.i2c_scl, scl_o=dut.i2c_scl_dev,
        speed=400e3)

    @bridge
    def start_i2c():
        device = pe.I2cDevice(chip, firmware("i2c_target"), address=0x2A)
        device.reply([0xBE, 0xEF])
        return device

    device = await start_i2c()
    await master.write(0x2A, [0x07])
    back = await master.read(0x2A, 2)
    await master.send_stop()
    assert list(back) == [0xBE, 0xEF], f"controller read {list(back)}"
    events = await bridge(device.events)()
    assert events == [("start", False), 0x07, ("start", True)], events

    dut.dev_mode.value = 4
    spi_master = SpiMaster(SpiBus.from_prefix(dut, "spi"), SpiConfig(
        word_width=8, sclk_freq=500e3, cpol=False, cpha=False, msb_first=True,
        cs_active_low=True, frame_spacing_ns=2000))

    @bridge
    def start_spi():
        spi_device = pe.SpiDevice(chip, firmware("spi_target"))
        spi_device.reply([0xA1, 0xB2, 0xC3, 0x00])  # 3 bytes, plus 1 held ahead
        return spi_device

    spi_device = await start_spi()
    spi_master.write_nowait([0x9F, 0x01, 0x02], burst=True)
    await spi_master.wait()
    assert list(spi_master.read_nowait()) == [0xA1, 0xB2, 0xC3]
    transfers = await bridge(spi_device.transfers)()
    assert transfers == [[0x9F, 0x01, 0x02]], transfers



# --- JTAG: the chip as a JTAG controller, judged by cocotbext-jtag's monitor --

from cocotbext.jtag import JTAGBus, JTAGMonitor  # noqa: E402

JTAG_IDCODE = 0x1BADC0DE  # jtag_tap.v's IDCODE parameter


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_thirdparty_jtag(dut):
    """The JTAG firmware, driven through the board driver, against a TAP
    written from IEEE 1149.1 (test/jtag_tap.v): reset, read the IDCODE, select
    a user register, write it, read it back, then BYPASS. cocotbext-jtag's
    passive monitor decodes every scan on the wires, separately from the
    driver's own reading of TDO."""
    await reset(dut)
    dut.dev_mode.value = 5
    monitor = JTAGMonitor(JTAGBus.from_prefix(dut, "jtag"))
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        j = pe.JtagController(chip, firmware("jtag"))
        j.reset()
        idcode = j.shift_dr(0, 32)  # IDCODE is selected after reset
        captured = j.shift_ir(0b1000, 4)  # USER
        before = j.shift_dr(0xCAFEF00D, 32)
        after = j.shift_dr(0x12345678, 32)
        j.shift_ir(0b1111, 4)  # BYPASS
        bypass = j.shift_dr(0b1011, 4)
        return idcode, captured, before, after, bypass

    idcode, captured, before, after, bypass = await session()
    assert idcode == JTAG_IDCODE, f"IDCODE {idcode:#x}"
    assert captured == 0b0101, f"IR capture {captured:#x}"  # 1149.1: low bits 01
    assert (before, after) == (0, 0xCAFEF00D), f"USER {before:#x} {after:#x}"
    assert bypass == 0b0110, f"BYPASS {bypass:#b}"  # one clock of delay
    seen = [(t.ir_val, t.dr_cnt, t.tdi, t.tdo) for t in monitor.queue_txn]
    assert seen == [
        (0x0, 32, 0, JTAG_IDCODE),
        (0x8, 32, 0xCAFEF00D, 0),
        (0x8, 32, 0x12345678, 0xCAFEF00D),
        (0xF, 4, 0b1011, 0b0110),
    ], f"monitor saw {seen}"



# --- SWD: the chip as an Arm Serial Wire Debug host ---------------------------

SWD_DPIDR = 0x2BA01477  # swd_dp.v's DPIDR
SWD_AP_IDR = 0x24770011


@cocotb.test(timeout_time=200, timeout_unit="ms")
async def test_swd(dut):
    """The SWD clock engine with the board driver's framing, against an SWD
    target written from Arm's ADIv5 (test/swd_dp.v): no answer before the
    JTAG-to-SWD switch, then DPIDR, a power-up request acknowledged in
    CTRL/STAT, an AP's IDR through a posted read and RDBUFF, and an AP
    register written and read back."""
    await reset(dut)
    dut.dev_mode.value = 6
    trace = sigrok.Trace(dut, {"swclk": lambda: dut.swd_clk.value,
                               "swdio": lambda: dut.swdio.value})
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        swd = pe.SwdController(chip, firmware("swd"))
        try:
            swd.read_dp(swd.DPIDR)
            silent = False
        except pe.SwdError:
            silent = True  # still in JTAG mode: nobody answers
        dpidr = swd.connect()
        swd.write_dp(swd.CTRL_STAT, 0x50000000)  # CSYSPWRUPREQ, CDBGPWRUPREQ
        ctrl = swd.read_dp(swd.CTRL_STAT)
        swd.write_dp(swd.SELECT, 0x000000F0)  # AP 0, bank 0xF
        idr = swd.read_ap_now(0xC)
        swd.write_dp(swd.SELECT, 0x00000000)
        swd.write_ap(0x4, 0xDEADBEEF)
        posted = swd.read_ap(0x4)  # returns the previous AP read: the IDR
        tar = swd.read_dp(swd.RDBUFF)
        return silent, dpidr, ctrl, idr, posted, tar

    silent, dpidr, ctrl, idr, posted, tar = await session()
    trace.stop()
    if sigrok.available():
        # sigrok's SWD decoder on the whole session.
        seen = [text for _, _, text in trace.decode("swd")]
        assert seen == [
            "IDCODE", "NOREPLY", "LINERESET", "JTAG->SWD", "LINERESET",
            "IDCODE", "OK", f"0x{SWD_DPIDR:08x}",
            "W CTRL/STAT", "OK", "0x50000000", "R CTRL/STAT", "OK", "0xf0000000",
            "W SELECT", "OK", "0x000000f0", "R APc", "OK", "0x00000000",
            "RDBUFF", "OK", f"0x{SWD_AP_IDR:08x}",
            "W SELECT", "OK", "0x00000000", "W AP4", "OK", "0xdeadbeef",
            "R AP4", "OK", f"0x{SWD_AP_IDR:08x}", "RDBUFF", "OK", "0xdeadbeef"], seen
        # One bit of the first word written forced high: the decoder must
        # report different data and a parity error.
        start = next(a for a, _, text in trace.decode("swd") if text == "0x50000000")
        wrong = [text for _, _, text in
                 trace.forced("swdio", start, start + 60, 1).decode("swd")]
        assert "0x50000000" not in wrong and len(wrong) == len(seen) + 1, wrong
    assert silent, "the target answered before the JTAG-to-SWD switch"
    assert dpidr == SWD_DPIDR, f"DPIDR {dpidr:#x}"
    assert ctrl == 0xF0000000, f"CTRL/STAT {ctrl:#x}"  # both requests acknowledged
    assert idr == SWD_AP_IDR, f"AP IDR {idr:#x}"
    assert (posted, tar) == (SWD_AP_IDR, 0xDEADBEEF), f"posted {posted:#x}, RDBUFF {tar:#x}"
    assert int(dut.dp.parity_errors.value) == 0


# --- 1-Wire: a protocol added as firmware alone, on the finished chip ----------
#
# On the wire (tb.v, dev_mode 8) are three copies of Iztok Jeras's 1-Wire
# slave model (sockit_owm, LGPL), at the shortest, typical and longest
# timing the rules allow: each samples the host's bit 15, 30 or 60 us into a
# slot, holds a 0 that long, and answers a reset after that long. The model
# is bit level: it sends what dat_r says and reports what it read on dat_w.
# Above it, OneWireDevice is a DS18B20's ROM and function layers, written
# here from Maxim's data sheet, driven one slot at a time.

from cocotb.triggers import Timer  # noqa: E402
from cocotb.utils import get_sim_time  # noqa: E402

ONEWIRE_TS = (15, 30, 60)  # each slave model's time slot, us (tb.v)


class OneWireDevice:
    """A DS18B20 above the bit level: ROM commands (READ, MATCH, SKIP,
    SEARCH), then CONVERT T (reads 0 for three slots while busy) and READ
    SCRATCHPAD."""

    def __init__(self, serial, temp_raw):
        rom = [0x28] + [(serial >> (8 * i)) & 0xFF for i in range(6)]
        self.rom = bytes(rom + [pe.onewire_crc8(rom)])
        pad = [temp_raw & 0xFF, (temp_raw >> 8) & 0xFF, 0x4B, 0x46, 0x7F, 0xFF, 0x0C, 0x10]
        self.scratchpad = bytes(pad + [pe.onewire_crc8(pad)])
        self.mode = "idle"
        self.tx, self.rx, self.after = [], [], "idle"
        self.slots_seen = 0

    @staticmethod
    def bits(data):
        return [(b >> k) & 1 for b in data for k in range(8)]

    def reset(self):
        self.mode, self.rx, self.tx = "rom", [], []

    def send(self, data, after):
        self.mode, self.tx, self.after = "send", self.bits(data), after

    def to_send(self):
        if self.mode == "send":
            return self.tx[0]
        if self.mode == "search":
            b = self.rom_bits[self.i]
            return (b, 1 - b, 1)[self.phase]
        if self.mode == "busy":
            return 0 if self.busy else 1
        return 1

    def slot(self, seen):
        """After each slot, with the line as the slave model sampled it."""
        self.slots_seen += 1
        m = self.mode
        if m == "send":
            self.tx.pop(0)
            if not self.tx:
                self.mode = self.after
        elif m in ("rom", "match", "function"):
            self.rx.append(seen)
            if len(self.rx) == (64 if m == "match" else 8):
                v = sum(b << k for k, b in enumerate(self.rx))
                self.rx = []
                self.command(m, v)
        elif m == "search":
            if self.phase < 2:
                self.phase += 1
            elif seen != self.rom_bits[self.i]:
                self.mode = "idle"  # the host went the other way
            else:
                self.i, self.phase = self.i + 1, 0
                if self.i == 64:
                    self.mode = "function"
        elif m == "busy" and self.busy:
            self.busy -= 1

    def command(self, m, v):
        if m == "rom":
            if v == pe.OneWire.READ_ROM:
                self.send(self.rom, "function")
            elif v == pe.OneWire.SKIP_ROM:
                self.mode = "function"
            elif v == pe.OneWire.MATCH_ROM:
                self.mode = "match"
            elif v == pe.OneWire.SEARCH_ROM:
                self.mode, self.rom_bits, self.i, self.phase = "search", self.bits(self.rom), 0, 0
            else:
                self.mode = "idle"
        elif m == "match":
            self.mode = "function" if v == int.from_bytes(self.rom, "little") else "idle"
        elif v == pe.OneWire.CONVERT_T:
            self.mode, self.busy = "busy", 3
        elif v == pe.OneWire.READ_SCRATCHPAD:
            self.send(self.scratchpad, "idle")
        else:
            self.mode = "idle"


async def onewire_device(dut, k, dev, dat_r):
    """Feeds slave model k its next bit before each slot and hands what it
    read to [dev]. [dat_r] is shared by the three, so each write carries the
    others' bits."""
    line = dut.onewire
    while True:
        dat_r[0] = (dat_r[0] & ~(1 << k)) | (dev.to_send() << k)
        dut.onewire_dat_r.value = dat_r[0]
        await FallingEdge(line)
        t0 = get_sim_time("us")
        await Timer(ONEWIRE_TS[k] * 1000 + 500, "ns")  # past the model's sample point
        if not int(line.value):
            await RisingEdge(line)
        if get_sim_time("us") - t0 > 300:  # a reset pulse
            dev.reset()
            await Timer(330, "us")  # every device's presence pulse is over
            continue
        # The model's transfer task hands back what it read when it ends:
        # at its sample point, or when the line is released, if later.
        await Timer(100, "ns")
        dev.slot(int(str(dut.onewire_dat_w.value)[2 - k]))


def onewire_celsius(raw):
    return (raw - 0x10000 if raw & 0x8000 else raw) / 16


ONEWIRE_DEVICES = [  # serial number, raw temperature (1/16 degree)
    (0x00000000A5C1, 0x0191),  # 25.0625
    (0x00000000A5C3, 0xFF5E),  # -10.125
    (0x0000004213F0, 0x0550),  # 85.0
]


async def onewire_start(dut, enabled):
    """Puts the devices numbered in [enabled] on the wire, each running on
    the slave model of the same index."""
    dut.dev_mode.value = 8
    dut.onewire_ena.value = sum(1 << k for k in enabled)
    dat_r = [0b111]
    devs, tasks = {}, []
    for k in enabled:
        devs[k] = OneWireDevice(*ONEWIRE_DEVICES[k])
        tasks.append(cocotb.start_soon(onewire_device(dut, k, devs[k], dat_r)))
    await ClockCycles(dut.clk, 2)
    return devs, tasks


@cocotb.test(timeout_time=200, timeout_unit="ms")
async def test_onewire_read_rom(dut):
    """Each device alone on the wire, at the shortest, typical and longest
    legal timing: the reset finds it, READ ROM returns its ROM code with a
    good CRC, and its temperature reads back. With none, no presence."""
    for k in range(3):
        await reset(dut)
        devs, tasks = await onewire_start(dut, [k])
        wire = sigrok.Trace(dut, {"owr": lambda: str(dut.onewire.value) != "0"})
        chip = pe.Chip(sim_port(dut))

        @bridge
        def session():
            ow = pe.OneWire(chip, firmware("onewire"))
            return ow.read_rom(), ow.ds18b20_temperature()

        rom, temp = await session()
        wire.stop()
        if sigrok.available() and k > 0:
            # sigrok's 1-Wire decoders on the wire itself, device and all:
            # the reset and presence, READ ROM and the code the device
            # sent, then the conversion and the nine-byte scratchpad read.
            # Not for the fastest device: it lets go of the wire 15 us into
            # a slot, which is where sigrok samples, and sigrok reads ones.
            # The chip samples sooner and reads it right (above).
            stack = "onewire_link:owr=owr,onewire_network"
            found = wire.decode(stack, "onewire_network")
            code = "ROM: 0x%016x" % int.from_bytes(devs[k].rom, "little")
            want = ["Reset/presence: true", "ROM command: 0x33 'Read ROM'", code, "Reset/presence: true",
                    "ROM command: 0xcc 'Skip ROM'", "Data: 0x44", "Reset/presence: true",
                    "ROM command: 0xcc 'Skip ROM'", "Data: 0xbe"]
            assert texts(found)[:len(want)] == want, texts(found)
            assert len(found) == len(want) + 9, texts(found)
            # The wire held low while the device sends its code: not that code.
            a, b = next((a, b) for a, b, text in found if text == code)
            assert code not in texts(wire.forced("owr", a, b, 0).decode(stack, "onewire_network"))
        for t in tasks:
            t.cancel()
        assert rom == devs[k].rom, f"device {k}: ROM {rom.hex()}"
        assert temp == onewire_celsius(ONEWIRE_DEVICES[k][1]), f"device {k}: {temp} C"
    await reset(dut)
    await onewire_start(dut, [])
    chip = pe.Chip(sim_port(dut))

    @bridge
    def empty():
        return pe.OneWire(chip, firmware("onewire")).reset()

    assert not await empty(), "presence with no device on the wire"


@cocotb.test(timeout_time=1500, timeout_unit="ms")
async def test_onewire_search(dut):
    """All three on one wire: SEARCH ROM finds every ROM code, and MATCH ROM
    reaches each device alone, reading its own temperature."""
    await reset(dut)
    devs, _ = await onewire_start(dut, [0, 1, 2])
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        ow = pe.OneWire(chip, firmware("onewire"))
        roms = ow.search()
        return roms, {rom: ow.ds18b20_temperature(rom) for rom in roms}

    roms, temps = await session()
    want = {devs[k].rom: onewire_celsius(ONEWIRE_DEVICES[k][1]) for k in devs}
    assert sorted(roms) == sorted(want), f"found {[r.hex() for r in roms]}"
    assert temps == want, f"temperatures {temps}"


# --- Planted driver bugs: each must make its test fail ------------------------
#
# Each bug is planted by replacing one driver method for the length of one
# scenario, then restored. The scenarios are the checks above, cut down to
# what can fail without hanging: every call clocks a fixed number of bits,
# so a broken driver gets wrong data or an SwdError, never a wait for
# something that will not come.

def _pin_modes_one_bit_per_pin(self, modes):
    v = 0
    for pin, mode in modes.items():
        v |= mode << pin  # the bug: one bit per pin instead of two
    self.write(pe.PIN_MODES, v)


def _make_scan_swapped(original):
    def scan(self, tms, tdi):
        return original(self, tdi, tms)  # the bug: TMS and TDI swapped
    return scan


def _make_request_bad_parity(original):
    def _request(apndp, rnw, addr):
        req = original(apndp, rnw, addr)
        req[5] ^= 1  # the bug: request parity inverted
        return req
    return staticmethod(_request)


def _transfer_no_write_turnaround(self, apndp, rnw, addr, value=0):
    req = self._request(apndp, rnw, addr)
    if rnw:
        bits = req + [1] + [1] * 3 + [1] * 33 + [1] + [0, 0]
    else:  # the bug: no turnaround between the ACK and the write data
        data = [(value >> i) & 1 for i in range(32)]
        bits = req + [1] + [1] * 3 + data + [sum(data) & 1] + [0, 0]
    s = self.clock(bits)
    ack = s[9] | (s[10] << 1) | (s[11] << 2)
    if ack != 0b001:
        raise pe.SwdError("ACK %s" % format(ack, "03b"))
    if not rnw:
        return None
    v = sum(s[12 + i] << i for i in range(32))
    if (sum(s[12:44]) & 1) != s[44]:
        raise pe.SwdError("read data parity error")
    return v


async def _flash_read_ok(dut):
    address, data = 0x000200, [0xC4, 0x5E, 0x91]
    for k, b in enumerate(data):
        dut.flash.memory[address + k].value = b
    dut.dev_mode.value = 2
    chip = pe.Chip(sim_port(dut))

    @bridge
    def read_flash():
        spi = pe.SpiController(chip, firmware("spi_fast"))
        spi.transfer([0xAB])
        return spi.transfer([0x03, 0x00, 0x02, 0x00, 0, 0, 0])[4:]

    return await read_flash() == data


async def _jtag_idcode_ok(dut):
    dut.dev_mode.value = 5
    chip = pe.Chip(sim_port(dut))

    @bridge
    def idcode():
        j = pe.JtagController(chip, firmware("jtag"))
        j.reset()
        return j.shift_dr(0, 32)

    return await idcode() == JTAG_IDCODE


async def _swd_power_up_ok(dut):
    dut.dev_mode.value = 6
    chip = pe.Chip(sim_port(dut))
    errors_before = int(dut.dp.parity_errors.value)  # the target is never reset

    @bridge
    def session():
        swd = pe.SwdController(chip, firmware("swd"))
        try:
            dpidr = swd.connect()
            swd.write_dp(swd.CTRL_STAT, 0x50000000)
            return dpidr, swd.read_dp(swd.CTRL_STAT)
        except pe.SwdError:
            return None

    got = await session()
    return (got == (SWD_DPIDR, 0xF0000000)
            and int(dut.dp.parity_errors.value) == errors_before)


def _onewire_write_msb_first(self, data):
    bits = []
    for b in data:
        for k in range(7, -1, -1):  # the bug: most significant bit first
            bits.append((b >> k) & 1)
    self.slots(bits)


def _onewire_search_never_revisits(self):
    roms, rom = [], [0] * 64
    if not self.reset():
        return roms
    self.write([self.SEARCH_ROM])
    for i in range(64):
        bit, cmp = self.slots([1, 1])
        d = bit if bit != cmp else 0  # the bug: one pass, always the 0 branch
        rom[i] = d
        self.slots([d])
    return [bytes([sum(rom[8 * j + k] << k for k in range(8)) for j in range(8)])]


async def _onewire_read_rom_ok(dut):
    devs, tasks = await onewire_start(dut, [1])
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        try:
            return pe.OneWire(chip, firmware("onewire")).read_rom()
        except pe.OneWireError:
            return None

    got = await session()
    for t in tasks:
        t.cancel()
    return got == devs[1].rom


async def _onewire_search_two_ok(dut):
    devs, tasks = await onewire_start(dut, [0, 1])
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        try:
            return pe.OneWire(chip, firmware("onewire")).search()
        except pe.OneWireError:
            return None

    got = await session()
    for t in tasks:
        t.cancel()
    return got is not None and sorted(got) == sorted(d.rom for d in devs.values())


# --- PS/2: the chip as host, a keyboard written from the protocol's rules ----
#
# DATA and CLK are P0 and P1, open-drain, on the same testbench wiring as I2C
# (dev_mode 1: i2c_sda_dev and i2c_scl_dev are the device's drives). The
# keyboard makes every clock, 40 us a phase, starts a frame only on an idle
# bus, gives it up and sends it again if the host holds CLK low before the
# 11th clock, and takes a host byte after 100 us of CLK low followed by DATA
# low. Its command layer is a keyboard's: 0xFF reset (ACK, then 0xAA), 0xF2
# identify (ACK, 0xAB, 0x83), 0xED set LEDs (ACK, then ACK for the argument);
# a byte with bad parity or no stop bit gets 0xFE, resend.


class Ps2Keyboard:
    def __init__(self):
        self.queue, self.got, self.aborted, self.leds = [], [], 0, None
        self._want_leds = False

    def command(self, byte, ok):
        if not ok:
            self.queue.append(0xFE)
        elif self._want_leds:
            self.leds, self._want_leds = byte, False
            self.queue.append(0xFA)
        elif byte == 0xFF:
            self.queue += [0xFA, 0xAA]
        elif byte == 0xF2:
            self.queue += [0xFA, 0xAB, 0x83]
        elif byte == 0xED:
            self._want_leds = True
            self.queue.append(0xFA)
        else:
            self.queue.append(0xFA)


async def ps2_keyboard(dut, kb):
    dut.dev_mode.value = 1
    dut.i2c_sda_dev.value = 1
    dut.i2c_scl_dev.value = 1
    data, clk = dut.i2c_sda_dev, dut.i2c_scl_dev

    def lines():
        return int(dut.i2c_sda.value), int(dut.i2c_scl.value)

    async def released(us):
        """Waits with CLK released; False if the host pulls it low."""
        for _ in range(us):
            await Timer(1, "us")
            if not lines()[1]:
                return False
        return True

    async def send(byte):
        parity = 1 - bin(byte).count("1") % 2
        bits = [0] + [(byte >> k) & 1 for k in range(8)] + [parity, 1]
        for n, b in enumerate(bits):
            data.value = b
            if not await released(15):
                data.value = 1
                return False
            clk.value = 0
            await Timer(40, "us")
            clk.value = 1
            if n < 10 and not await released(25):
                data.value = 1
                return False
        return True

    async def receive():
        await Timer(500, "us")
        bits = []
        for _ in range(10):
            clk.value = 0
            await Timer(40, "us")
            bits.append(lines()[0])
            clk.value = 1
            await Timer(40, "us")
        data.value = 0  # the ACK
        await Timer(15, "us")
        clk.value = 0
        await Timer(40, "us")
        clk.value = 1
        data.value = 1
        byte = sum(b << k for k, b in enumerate(bits[:8]))
        kb.got.append(byte)
        kb.command(byte, (bin(byte).count("1") + bits[8]) % 2 == 1 and bits[9] == 1)

    clk_low = idle = 0
    while True:
        await Timer(1, "us")
        d, c = lines()
        inhibited = clk_low >= 100
        clk_low = 0 if c else clk_low + 1
        idle = idle + 1 if (c and d) else 0
        if inhibited and c and not d:
            await receive()
            clk_low = idle = 0
        elif idle >= 50 and kb.queue:
            if await send(kb.queue[0]):
                kb.queue.pop(0)
            else:
                kb.aborted += 1
            idle = 0


def _ps2_session(chip, kb):
    """Reset, identify, set the LEDs, then a key pressed and released."""
    ps2 = pe.Ps2(chip, firmware("ps2"))

    def expect(n):
        out = []
        while len(out) < n:
            b = ps2.read()
            if b is not None:
                out.append(b)
        return out

    ps2.write(0xFF)
    log = [expect(2)]
    ps2.write(0xF2)
    log.append(expect(3))
    ps2.write(0xED)
    log.append(expect(1))
    ps2.write(0x05)
    log.append(expect(1))
    kb.queue += [0x1C, 0xF0, 0x1C]  # A down, A up (scan code set 2)
    log.append(expect(3))
    return log


PS2_EXPECTED = [[0xFA, 0xAA], [0xFA, 0xAB, 0x83], [0xFA], [0xFA], [0x1C, 0xF0, 0x1C]]


@cocotb.test(timeout_time=400, timeout_unit="ms")
async def test_ps2_keyboard(dut):
    """The driver resets and identifies a keyboard, sets its LEDs and reads a
    key press and release; the keyboard got each command intact. Then, with
    no keyboard, a write reports that nothing clocked."""
    await reset(dut)
    kb = Ps2Keyboard()
    task = cocotb.start_soon(ps2_keyboard(dut, kb))
    trace = sigrok.Trace(dut, {"clk": lambda: dut.i2c_scl.value,
                               "data": lambda: dut.i2c_sda.value})
    chip = pe.Chip(sim_port(dut))
    log = await bridge(lambda: _ps2_session(chip, kb))()
    task.cancel()
    trace.stop()
    if sigrok.available():
        # sigrok's PS/2 decoder on every frame, both ways.
        assert sigrok.ps2_frames(trace) == [
            ("host", 0xFF), ("device", 0xFA), ("device", 0xAA),
            ("host", 0xF2), ("device", 0xFA), ("device", 0xAB), ("device", 0x83),
            ("host", 0xED), ("device", 0xFA), ("host", 0x05), ("device", 0xFA),
            ("device", 0x1C), ("device", 0xF0), ("device", 0x1C)]
        # The keyboard's first reply, 0xFA, with its first data bit (a 0)
        # forced to 1: the decoder must report a parity error.
        low = trace.low_pulses("clk")
        try:
            sigrok.ps2_frames(trace.forced("data", low[12][1], low[13][1], 1))
            caught = False
        except AssertionError:
            caught = True
        assert caught, "sigrok's PS/2 decoder accepted a frame with a flipped bit"
    assert log == PS2_EXPECTED, [[hex(b) for b in group] for group in log]
    assert kb.got == [0xFF, 0xF2, 0xED, 0x05] and kb.leds == 0x05, (kb.got, kb.leds)

    await reset(dut)
    dut.dev_mode.value = 1
    dut.i2c_sda_dev.value = 1
    dut.i2c_scl_dev.value = 1
    chip = pe.Chip(sim_port(dut))

    @bridge
    def alone():
        try:
            pe.Ps2(chip, firmware("ps2")).write(0xFF)
        except pe.Ps2Error as e:
            return str(e)

    assert "never clocked" in (await alone() or ""), "no error with no keyboard"


def _ps2_even_parity(byte):
    return bin(byte & 0xFF).count("1") % 2


async def _ps2_identify_ok(dut):
    kb = Ps2Keyboard()
    task = cocotb.start_soon(ps2_keyboard(dut, kb))
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        try:
            ps2 = pe.Ps2(chip, firmware("ps2"))
            ps2.write(0xF2)
            out = []
            while len(out) < 3:
                b = ps2.read()
                if b is not None:
                    out.append(b)
                    if b == 0xFE:
                        break
            return out
        except pe.Ps2Error:
            return None

    got = await session()
    task.cancel()
    return got == [0xFA, 0xAB, 0x83]


# --- CAN: the chip as a node, and another node -----------------------------
#
# dev_mode 9: RXD (P0) is the wired-AND of the chip's TXD (P1) and can_dev,
# the node's drive. The node is written from ISO 11898-1's rules: it hard-
# synchronises on a start of frame, resynchronises on later falling edges,
# samples at 70%, removes stuff bits as they come, checks the CRC, drives
# the ACK slot of a good frame, and can send a frame of its own. Its clock
# is 1% slow. It is the only other thing on the bus, so an acknowledgement
# of one of its frames is the chip's. Its frames' bits are checked against
# the ones the OCaml suite prints for the same frame (sim/test_can.ml).

CAN_BIT = 160  # core clocks: 62.5 kbit/s at 10 MHz
CAN_NODE_BIT = 162
CAN_VECTOR = "01010101010100000110000010000111110111001000010110001111"


def can_crc15(bits):
    crc = 0
    for b in bits:
        top = (crc >> 14) & 1
        crc = (crc << 1) & 0x7FFF
        if top ^ b:
            crc ^= 0x4599
    return crc


def can_frame_bits(ident, data, crc_error=0):
    """A data frame on the wire (1 = recessive), from its start-of-frame
    bit to its ACK delimiter: what the node sends. Written here, apart
    from the chip's stuffing and CRC, which are firmware. [crc_error] is
    XORed into the CRC."""
    body = [0] + [(ident >> (10 - k)) & 1 for k in range(11)] + [0, 0, 0]
    body += [(len(data) >> (3 - k)) & 1 for k in range(4)]
    for byte in data:
        body += [(byte >> (7 - k)) & 1 for k in range(8)]
    crc = can_crc15(body) ^ crc_error
    body += [(crc >> (14 - k)) & 1 for k in range(15)]
    out, last, run = [], -1, 0
    for b in body:
        run = run + 1 if b == last else 1
        last = b
        out.append(b)
        if run == 5:
            last, run = 1 - b, 1
            out.append(last)
    return out + [1, 1, 1]


class CanNode:
    def __init__(self):
        self.got, self.to_send, self.sent, self.acked = [], [], 0, 0
        self.phase, self.prev, self.idle = -1, 1, 0
        self.drive = 1

    def _start(self, sending):
        self.phase, self.raw, self.bits = 0, [], []
        self.run, self.last, self.state, self.ones = 0, -1, "frame", 0
        self.sending = list(sending)
        self.drive = self.sending[0] if self.sending else 1

    def _sample(self, b):
        self.ones = self.ones + 1 if b else 0
        if self.state == "frame":
            if self.run == 5:
                self.state = "frame" if b != self.last else "bad"
                self.last, self.run = b, 1
                return
            self.run = self.run + 1 if b == self.last else 1
            self.last = b
            self.bits.append(b)
            if len(self.bits) >= 19:
                n = int("".join(map(str, self.bits[15:19])), 2)
                if n > 8:
                    self.state = "bad"
                elif len(self.bits) == 34 + 8 * n:
                    body, crc = self.bits[:19 + 8 * n], self.bits[19 + 8 * n:]
                    ok = int("".join(map(str, crc)), 2) == can_crc15(body)
                    self.state = "delim" if ok else "bad"
                    if ok and not self.sending:
                        ident = int("".join(map(str, body[1:12])), 2)
                        data = [int("".join(map(str, body[19 + 8 * k:27 + 8 * k])), 2)
                                for k in range(n)]
                        self.got.append((ident, data))
        elif self.state == "delim":
            if self.run == 5 and b != self.last:
                self.run = 0  # the stuff bit after the CRC
            else:
                self.state = "ack" if b else "bad"
        elif self.state == "ack":
            self.state = "done"

    def tick(self, bus):
        fell = self.prev and not bus
        self.prev = bus
        if self.phase < 0:
            self.idle = self.idle + 1 if bus else 0
            if fell:
                self._start([])
            elif self.idle >= 11 * CAN_NODE_BIT and self.to_send:
                self._start(self.to_send[0])
            return
        if fell and self.drive:
            # Resynchronise on an edge it did not cause: late in a bit, the
            # next bit is starting; early in one, this one has just begun.
            if self.phase > CAN_NODE_BIT // 2:
                self.phase = CAN_NODE_BIT - 1
            elif self.phase <= CAN_NODE_BIT // 4:
                self.phase = 0
        self.phase += 1
        if self.phase == CAN_NODE_BIT * 7 // 10:
            if len(self.sending) == 2 and not bus:
                self.acked += 1  # the ACK slot of a frame it is sending
            self._sample(bus)
        if self.phase >= CAN_NODE_BIT:
            self.phase = 0
            if self.sending:
                self.sending.pop(0)
                if self.sending:
                    self.drive = self.sending[0]
                else:
                    self.drive, self.sent = 1, self.sent + 1
                    self.to_send.pop(0)
            else:
                self.drive = 0 if self.state == "ack" else 1
            if self.ones >= 8 and not self.sending:
                self.phase, self.idle = -1, 0


async def can_node(dut, node):
    dut.dev_mode.value = 9
    dut.can_dev.value = 1
    while True:
        await RisingEdge(dut.clk)
        node.tick(int(dut.can_bus.value))
        dut.can_dev.value = node.drive


def _can_session(chip, node, stop_trace):
    can = pe.Can(chip, firmware("can"), bitrate=62_500)
    acked = can.send(0x123, [1, 2, 3])
    node.to_send.append(can_frame_bits(0x321, [0xAA, 0x55, 0x00, 0xFF]))
    got = []
    while len(got) < 1:
        f = can.receive()
        if f is not None:
            got.append(f)
    while node.sent < 1 or node.phase >= 0:
        chip.status()
    stop_trace()
    # A frame with a wrong CRC, then a good one: only the second comes out.
    node.to_send.append(can_frame_bits(0x0F0, [0xDE, 0xAD], crc_error=0x0100))
    node.to_send.append(can_frame_bits(0x0F1, [0xBE, 0xEF, 0x00, 0xFF, 0x00, 0xFF, 0x55, 0xAA]))
    while len(got) < 2:
        f = can.receive()
        if f is not None:
            got.append(f)
    return acked, got


@cocotb.test(timeout_time=400, timeout_unit="ms")
async def test_can(dut):
    """The chip as a CAN node. The driver sends a frame that the other
    node receives and acknowledges. The other node sends one: the chip
    acknowledges it and hands it over. A frame with a wrong CRC it neither
    acknowledges nor hands over. With no other node, its own frame goes
    unacknowledged, and it does not receive it itself."""
    assert "".join(map(str, can_frame_bits(0x555, [0x00, 0xFF]))) == CAN_VECTOR
    await reset(dut)
    node = CanNode()
    task = cocotb.start_soon(can_node(dut, node))
    trace = sigrok.Trace(dut, {"rxd": lambda: dut.can_bus.value})
    chip = pe.Chip(sim_port(dut))
    acked, got = await bridge(lambda: _can_session(chip, node, trace.stop))()
    task.cancel()
    if sigrok.available():
        # sigrok's CAN decoder on the bus: the chip's frame, acknowledged by
        # the node, then the node's, acknowledged by the chip.
        def frames(t):
            found = t.decode("can:can_rx=rxd:nominal_bitrate=62500", "can=fields:warnings")
            return found, [text for _, _, text in found]

        found, seen = frames(trace)
        assert sigrok.can_frames(seen) == [
            (0x123, [1, 2, 3], sigrok.can_crc15(0x123, [1, 2, 3]), "ACK"),
            (0x321, [0xAA, 0x55, 0x00, 0xFF],
             sigrok.can_crc15(0x321, [0xAA, 0x55, 0x00, 0xFF]), "ACK"),
        ], seen
        # One bit of the first data byte forced recessive: the decoder must
        # no longer report the frame as sent.
        start = next(a for a, _, text in found if text.startswith("Data byte 0"))
        try:
            wrong = sigrok.can_frames(frames(trace.forced("rxd", start, start + 160, 1))[1])
        except (AssertionError, KeyError):
            wrong = None
        assert wrong is None or wrong[0][:3] != (0x123, [1, 2, 3], sigrok.can_crc15(0x123, [1, 2, 3]))
    assert acked and node.got == [(0x123, [1, 2, 3])], (acked, node.got)
    assert got == [(0x321, [0xAA, 0x55, 0x00, 0xFF], False),
                   (0x0F1, [0xBE, 0xEF, 0x00, 0xFF, 0x00, 0xFF, 0x55, 0xAA], False)], got
    # Three frames from the node; the chip acknowledged the two good ones.
    assert (node.sent, node.acked) == (3, 2), (node.sent, node.acked)

    await reset(dut)
    dut.dev_mode.value = 9
    dut.can_dev.value = 1
    chip = pe.Chip(sim_port(dut))

    @bridge
    def alone():
        can = pe.Can(chip, firmware("can"), bitrate=62_500)
        acked = can.send(0x7FF, [])
        for _ in range(20):
            chip.status()
        return acked, can.receive()

    assert await alone() == (False, None)


def _can_words_sixteen_bits(tx_words):
    def words(ident, data):
        right = tx_words(ident, data)
        bits = [(w >> k) & 1 for w in right[1:] for k in range(15)][:right[0] + 1]
        return [right[0]] + [sum(b << j for j, b in enumerate(bits[k:k + 16]))
                             for k in range(0, len(bits), 16)]

    return staticmethod(words)


async def _can_send_ok(dut):
    node = CanNode()
    task = cocotb.start_soon(can_node(dut, node))
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        return pe.Can(chip, firmware("can"), bitrate=62_500).send(0x100, [0x00, 0xFF, 0x00])

    acked = await session()
    task.cancel()
    return acked and node.got == [(0x100, [0x00, 0xFF, 0x00])]


async def _can_receive_ok(dut):
    node = CanNode()
    task = cocotb.start_soon(can_node(dut, node))
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        can = pe.Can(chip, firmware("can"), bitrate=62_500)
        # The receiver joins the bus after ten recessive bit times, as a CAN
        # node must: the other node's eleven are counted from here.
        node.idle = 0
        node.to_send.append(can_frame_bits(0x2C3, [0x81, 0x7E, 0x00]))
        for _ in range(400):
            f = can.receive()
            if f is not None:
                return f
        return None

    try:
        got = await session()
    except pe.CanError:
        got = None
    task.cancel()
    return got == (0x2C3, [0x81, 0x7E, 0x00], False)


def _can_frame_words_of_sixteen(frame):
    """The receiver's words read as 16 bits each: the last word's bits land
    in the wrong places."""
    def wrong(cls, words):
        right = frame.__func__(cls, words)
        if right is None:
            return None
        ident, data, remote = right
        bits = [(w >> (15 - j)) & 1 for w in words[1:] for j in range(16)]
        data = [sum(b << (7 - j) for j, b in enumerate(bits[4 + 8 * k:12 + 8 * k]))
                for k in range(len(data))]
        return ident, data, remote

    return classmethod(wrong)


async def _dali_query_ok(dut):
    """A DALI controller asks a gear for its status and reads the answer."""
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    bus = DaliBus(dut)
    tasks = [cocotb.start_soon(bus.follow(dut.uio_out)), cocotb.start_soon(bus.follow(dut.uio_oe)),
             cocotb.start_soon(dali_gear(bus, 0x03, {0x90: 0xC4}))]
    chip = pe.Chip(sim_port(dut))

    @bridge
    def query():
        try:
            controller = more.Dali(chip, firmware("dali_tx"), firmware("dali_rx"))
            return controller.query(0x03, 0x90, patience=6000, wait=3000)
        except more.DaliError:
            return None

    got = await query()
    for task in tasks:
        task.cancel()
    return got == 0xC4


def _dali_frame_backwards(frame):
    """A frame's bits handed over last first."""
    def wrong(words):
        bits = frame.__func__(words)
        return bits if bits is None else bits[::-1]

    return staticmethod(wrong)


DRIVER_BUGS = [
    ("pin modes packed one bit per pin", pe.Chip, "set_pin_modes",
     lambda _: _pin_modes_one_bit_per_pin, _flash_read_ok),
    ("JTAG TMS and TDI swapped", pe.JtagController, "scan",
     _make_scan_swapped, _jtag_idcode_ok),
    ("SWD request parity inverted", pe.SwdController, "_request",
     lambda _: _make_request_bad_parity(pe.SwdController._request), _swd_power_up_ok),
    ("SWD write turnaround missing", pe.SwdController, "_transfer",
     lambda _: _transfer_no_write_turnaround, _swd_power_up_ok),
    ("1-Wire bytes sent MSB first", pe.OneWire, "write",
     lambda _: _onewire_write_msb_first, _onewire_read_rom_ok),
    ("1-Wire search never revisits a fork", pe.OneWire, "search",
     lambda _: _onewire_search_never_revisits, _onewire_search_two_ok),
    ("PS/2 parity even, not odd", pe.Ps2, "_odd_parity",
     lambda _: staticmethod(_ps2_even_parity), _ps2_identify_ok),
    ("CAN frame's bits packed 16 to a word", pe.Can, "tx_words",
     _can_words_sixteen_bits, _can_send_ok),
    ("CAN received words read 16 bits each", pe.Can, "frame",
     _can_frame_words_of_sixteen, _can_receive_ok),
    ("DALI frames read last bit first", more.DaliRx, "frame",
     _dali_frame_backwards, _dali_query_ok),
]


@cocotb.test(timeout_time=1500, timeout_unit="ms")
async def test_driver_planted_bugs(dut):
    """Every planted driver bug fails its scenario, and each scenario passes
    with the real driver, so a later change cannot quietly blind the driver
    tests."""
    results = []
    for name, cls, attr, make, scenario in DRIVER_BUGS:
        await reset(dut)
        assert await scenario(dut), f"scenario for {name!r} fails without the bug"
        original = cls.__dict__[attr]
        setattr(cls, attr, make(original))
        try:
            await reset(dut)
            caught = not await scenario(dut)
        finally:
            setattr(cls, attr, original)
        dut._log.info("%-34s %s", name, "caught" if caught else "MISSED")
        results.append((name, caught))
    missed = [name for name, caught in results if not caught]
    assert not missed, f"planted driver bugs not caught: {missed}"



# --- Low-speed USB: the chip as host, usbhostslave's usbDevice as the device -

USB_CLK_PS = 83_334  # 12 MHz (even, for cocotb): 8 clocks per bit at 1.5 Mbit/s
USB_DEV_CLK_PS = 20_834  # 48 MHz, the device's own clock


def usb_line(dp, dm):
    return {(0, 1): "J", (1, 0): "K", (0, 0): "SE0"}.get((dp, dm), "SE1")


async def usb_monitor(dut, trace):
    """Records (who drives, line state) once per core clock: 8 per bit."""
    while True:
        await RisingEdge(dut.clk)
        who = "host" if dut.host_oe.value == 1 else "dev" if dut.dev_oe.value == 1 else None
        try:
            line = usb_line(int(dut.usb_dp.value), int(dut.usb_dm.value))
        except ValueError:
            line = "X"  # both sides driving
        trace.append((who, line))


def usb_decode(lines):
    """A low-speed receiver written from the USB 1.1 spec: from the first K,
    one sample in the middle of each 8-clock bit, NRZI and stuffing undone,
    up to an EOP of two bit times of SE0 then J. Returns the bytes after
    SYNC, or a string saying what is wrong."""
    start = lines.index("K") if "K" in lines else None
    if start is None:
        return "no packet"
    levels = []
    k = 0
    while True:
        i = start + 8 * k + 4
        if i >= len(lines):
            return "no EOP"
        if lines[i] == "SE0":
            tail = [lines[j] if j < len(lines) else "J" for j in (i + 8, i + 16)]
            if tail != ["SE0", "J"]:
                return "bad EOP"
            break
        levels.append(lines[i])
        k += 1
    bits, prev, run = [], "J", 0
    for lv in levels:
        b = 1 if lv == prev else 0
        prev = lv
        if run == 6:
            if b:
                return "stuffing violation"
            run = 0
            continue
        run = run + 1 if b else 0
        bits.append(b)
    if bits[:8] != [0, 0, 0, 0, 0, 0, 0, 1]:
        return "bad SYNC"
    bits = bits[8:]
    if not bits or len(bits) % 8:
        return "not whole bytes"
    return [sum(bits[8 * n + i] << i for i in range(8)) for n in range(len(bits) // 8)]


def usb_packets(trace):
    """Splits the bus record into packets by who drove them: [(who, bytes)]."""
    packets, cur, who = [], [], None
    for w, line in trace + [(None, "J")]:
        if w is not None and (who is None or w == who):
            cur.append(line)
            who = w
        elif cur:
            packets.append((who, usb_decode(["J"] + cur + ["J", "J"])))
            cur, who = ([line], w) if w is not None else ([], None)
    return packets


def check_usb_image():
    """The driver's constants must match the image: at the timeout vector is
    the engine's [mov osr, pins] (opcode 5, dst OSR = 4, src PINS = 2), and
    at its origin its first [pull]."""
    image = firmware("usb_host")
    assert image[pe.USB_ENGINE_ORIGIN + pe.USB_TMO] & 0xE1F8 == 0xA110, "USB_TMO"
    assert image[pe.USB_ENGINE_ORIGIN] & 0xE1FF == 0x8100, "USB_ENGINE_ORIGIN"


async def usb_start(dut):
    """Chip at 12 MHz, the device at 48 MHz on the bus; returns once the
    device has connected (its pull-up on D-)."""
    check_usb_image()
    await reset(dut, period_ps=USB_CLK_PS)
    cocotb.start_soon(Clock(dut.usb_clk, USB_DEV_CLK_PS, unit="ps").start())
    dut.dev_mode.value = 7
    dut.usb_rst.value = 1
    await ClockCycles(dut.usb_clk, 64)
    dut.usb_rst.value = 0
    for _ in range(200):
        await ClockCycles(dut.clk, 100)
        if dut.dev_dm_pullup.value == 1:
            return
    raise AssertionError("the USB device never connected")


USB_DEVICE_DESCRIPTOR = [  # usbhostslave/usbROM.v, bMaxPacketSize0 8 at low speed
    0x12, 0x01, 0x10, 0x01, 0x00, 0x00, 0x00, 0x08, 0xC7, 0x05,
    0x13, 0x01, 0x01, 0x00, 0x01, 0x02, 0x03, 0x01]
GET_DEVICE_DESCRIPTOR = [0x80, 0x06, 0x00, 0x01, 0x00, 0x00, 0x12, 0x00]


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_usb_device_acks_setup(dut):
    """The chip, as a low-speed USB host driven by the board driver, sends a
    SETUP token and GET_DESCRIPTOR's DATA0 to usbhostslave's USB device,
    which checks PID, bit stuffing, CRC5 and CRC16 before it answers; the
    chip receives its ACK. With one CRC16 bit flipped there is no answer."""
    await usb_start(dut)
    trace = []
    cocotb.start_soon(usb_monitor(dut, trace))
    chip = pe.Chip(sim_port(dut))
    setup = pe.usb_token(pe.USB_SETUP, 0, 0)
    request = pe.usb_data(pe.USB_DATA0, GET_DEVICE_DESCRIPTOR)
    corrupt = request[:-1] + [request[-1] ^ 0x01]

    @bridge
    def send(packets):
        usb = pe.UsbHost(chip, firmware("usb_host"))
        return usb.transaction(packets + [pe.RECEIVE], polls=60)

    silent = await send([setup, corrupt])
    bad = usb_packets(trace)
    trace.clear()
    answer = await send([setup, request])
    good = usb_packets(trace)
    assert silent is None, f"an answer to a corrupted packet: {silent}"
    assert bad == [("host", setup), ("host", corrupt)], f"corrupted CRC: {bad}"
    assert good == [("host", setup), ("host", request), ("dev", [0xD2])], f"bus saw {good}"
    assert answer == [0xD2], f"the chip received {answer}"


@cocotb.test(timeout_time=300, timeout_unit="ms")
async def test_usb_get_descriptor(dut):
    """A whole USB control transfer, GET_DESCRIPTOR (device), between the
    chip as a low-speed host and usbhostslave's USB device: SETUP stage, IN
    data stages (the chip receives each data packet with its own clock
    recovery and ACKs it in time), OUT status stage. The descriptor read
    must be the one in the device's ROM, and every packet on the bus must
    decode."""
    await usb_start(dut)
    trace = []
    cocotb.start_soon(usb_monitor(dut, trace))
    wires = sigrok.Trace(dut, {"dp": lambda: str(dut.usb_dp.value) == "1",
                               "dm": lambda: str(dut.usb_dm.value) == "1"}, clock_hz=12_000_000)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def read():
        usb = pe.UsbHost(chip, firmware("usb_host"))
        return usb.control_read(0, GET_DEVICE_DESCRIPTOR, 18)

    descriptor = await read()
    wires.stop()
    assert descriptor == USB_DEVICE_DESCRIPTOR, f"descriptor {descriptor}"
    if sigrok.available():
        # sigrok's USB decoders, three deep, on D+ and D- as recorded: the
        # line states, then the packets with their CRCs, then the request.
        def show(data):
            return "[ " + " ".join(f"{b:02X}" for b in data) + " ]"

        stack = "usb_signalling:dp=dp:dm=dm:signalling=low-speed,usb_packet"
        found = wires.decode(stack, "usb_packet")
        read = iter(texts(found))
        first = "DATA1 " + show(USB_DEVICE_DESCRIPTOR[:8])
        want = ["SETUP ADDR 0 EP 0", "DATA0 " + show(GET_DEVICE_DESCRIPTOR), "ACK", "IN ADDR 0 EP 0", first,
                "ACK", "IN ADDR 0 EP 0", "DATA0 " + show(USB_DEVICE_DESCRIPTOR[8:16]), "ACK",
                "IN ADDR 0 EP 0", "DATA1 " + show(USB_DEVICE_DESCRIPTOR[16:]), "ACK"]
        assert all(text in read for text in want), texts(found)
        # The decoder checks each packet's SYNC, PID and CRC, and says so.
        assert not any("ERR" in text for text in texts(found)), texts(found)
        request = f"SETUP in: {show(GET_DEVICE_DESCRIPTOR)}{show(USB_DEVICE_DESCRIPTOR)} : ACK"
        assert request in texts(wires.decode(stack + ",usb_request", "usb_request"))
        # D+ held high through the device's first data packet: not that packet.
        a, b = next((a, b) for a, b, text in found if text == first)
        assert first not in texts(wires.forced("dp", a, b, 1).decode(stack, "usb_packet"))
    packets = usb_packets(trace)
    assert all(isinstance(b, list) for _, b in packets), f"undecodable: {packets}"
    pids = [(who, b[0]) for who, b in packets]
    dev_data = [b for who, b in packets if who == "dev" and b[0] in (0xC3, 0x4B)]
    assert [len(b) - 3 for b in dev_data] == [8, 8, 2], f"data packets {dev_data}"
    assert ("host", 0xD2) in pids and pids[-1] == ("dev", 0xD2), f"PIDs {pids}"


@cocotb.test(timeout_time=200, timeout_unit="ms")
async def test_usb_driver_planted_bugs(dut):
    """Planted bugs in the driver's USB code must each break a SETUP
    transaction with usbhostslave's device; the real driver must not."""
    await usb_start(dut)
    chip = pe.Chip(sim_port(dut))
    crc16, decode = pe.usb_crc16, pe.usb_decode
    bugs = [
        ("CRC16 sent uninverted", "usb_crc16", lambda data: ~crc16(data) & 0xFFFF),
        ("received levels read inverted", "usb_decode",
         lambda words: decode([~w & 0xFFFF for w in words[:-1]] + words[-1:])),
    ]

    @bridge
    def setup_acked():
        usb = pe.UsbHost(chip, firmware("usb_host"))
        got = usb.transaction([pe.usb_token(pe.USB_SETUP, 0, 0),
                               pe.usb_data(pe.USB_DATA0, GET_DEVICE_DESCRIPTOR),
                               pe.RECEIVE], polls=60)
        return got == [pe.usb_pid(pe.USB_ACK)]

    assert await setup_acked(), "the real driver's SETUP was not acknowledged"
    missed = []
    for name, attr, bug in bugs:
        original = getattr(pe, attr)
        setattr(pe, attr, bug)
        try:
            caught = not await setup_acked()
        finally:
            setattr(pe, attr, original)
        dut._log.info("%-32s %s", name, "caught" if caught else "MISSED")
        if not caught:
            missed.append(name)
    assert not missed, f"planted USB driver bugs not caught: {missed}"


# --- Protocols added on v2: each judged by a sigrok decoder -------------------
#
# Transmitters with no device model on the other end: what the pins did is
# recorded and handed to sigrok's decoder for that protocol, which must read
# back exactly what the host asked for. Each test also damages the recording
# once and requires the decoder's reading to change, so a decoder that would
# accept anything cannot pass.


def pin_trace(dut, **pins):
    """The named protocol pins as a receiver sees them: the chip's level
    while it drives the pin, high (a pull-up) while it does not."""
    def level(k):
        return (int(dut.uio_out.value) >> k) & 1 if (int(dut.uio_oe.value) >> k) & 1 else 1
    return sigrok.Trace(dut, {name: (lambda k=k: level(k)) for name, k in pins.items()})


def texts(found):
    return [text for _, _, text in found]


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_i2s(dut):
    """I2S: 16-bit stereo samples, read back by sigrok's I2S decoder. The
    first two frames are queued before the clock starts, so the bit clock
    must not stretch across them."""
    await reset(dut)
    trace = pin_trace(dut, sck=0, ws=1, sd=2)
    chip = pe.Chip(sim_port(dut))
    frames = [(0x1234, 0xABCD), (0x8001, 0x7FFE), (0x0000, 0xFFFF), (0x5A5A, 0xA5A5)]

    @bridge
    def play():
        # One more frame than is checked: a decoder closes a sample on the
        # word-select edge after it.
        more.I2sTx(chip, firmware("i2s_tx"), first=frames[:2]).write(frames[2:] + [(0, 0)])

    await play()
    await ClockCycles(dut.clk, 400)
    trace.stop()
    rises = [t for t, v in trace.level("sck") if v == 1][1:]  # [0]: before the pin drives
    gaps = {b - a for a, b in zip(rises[:63], rises[1:64])}
    assert gaps == {4}, f"bit clock periods over two queued frames: {sorted(gaps)}"
    if sigrok.available():
        want = [f"{side} channel: {v:08x}" for frame in frames
                for side, v in zip(("Left", "Right"), frame)]
        found = trace.decode("i2s")
        assert texts(found)[:8] == want, texts(found)
        # The data line held high across the first sample: it must read 0xffff.
        wrong = texts(trace.forced("sd", found[0][0], found[0][1], 1).decode("i2s"))
        assert wrong[0] == "Left channel: 0000ffff" and wrong[1:8] == want[1:], wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_dmx512(dut):
    """DMX512: two packets, read back by sigrok's DMX512 decoder, which
    also checks the break, the mark after it and both stop bits."""
    await reset(dut)
    trace = pin_trace(dut, dmx=0)
    chip = pe.Chip(sim_port(dut))
    packets = [[0x00, 0xFF, 0x55, 0x81, 0x7E], [0x10, 0x20]]

    @bridge
    def play():
        dmx = more.DmxTx(chip, firmware("dmx_tx"))
        for slots in packets:
            dmx.send(slots)

    await play()
    await ClockCycles(dut.clk, 3000)
    trace.stop()
    breaks = [a for a, b in trace.low_pulses("dmx") if b - a >= 920]  # 92 us or more
    assert len(breaks) == len(packets), f"{len(breaks)} breaks for {len(packets)} packets"
    if sigrok.available():
        # sigrok's decoder takes the first long run of either level as the
        # break and looks for the next one only after 512 slots, so it is
        # shown each packet on its own, from the moment its break begins.
        def read(recording, k):
            end = breaks[k + 1] if k + 1 < len(breaks) else None
            found = recording.decode("dmx512", start=breaks[k], end=end)
            names = texts(found)
            assert names[:2] == ["Break", "MAB"], names[:4]
            return ([int(t.split(" / ")[0]) for t in names if " / 0x" in t],
                    [t for t in names if "nvalid" in t], found)

        for k, slots in enumerate(packets):
            got, bad, found = read(trace, k)
            assert got == [0] + slots and not bad, (got, bad)
        # One slot's first stop bit pulled low: the decoder must object.
        at = next(a for a, _, text in found if text == "Stop bit")
        _, bad, _ = read(trace.forced("dmx", at, at + 40, 0), len(packets) - 1)
        assert bad, "a missing stop bit went unnoticed"


@cocotb.test(timeout_time=200, timeout_unit="ms")
async def test_wiegand(dut):
    """Wiegand: a 26-bit card number, read back by sigrok's Wiegand
    decoder as one frame of 26 bits."""
    await reset(dut)
    trace = pin_trace(dut, d0=0, d1=1)
    chip = pe.Chip(sim_port(dut))
    facility, card = 0x9C, 0xB1E5

    @bridge
    def play():
        more.WiegandTx(chip, firmware("wiegand_tx")).send26(facility, card)

    await play()
    await ClockCycles(dut.clk, 300_000)
    trace.stop()
    pulses = sorted(trace.low_pulses("d0") + trace.low_pulses("d1"))
    assert len(pulses) == 26 and {b - a for a, b in pulses} == {500}, pulses
    assert {b[0] - a[0] for a, b in zip(pulses, pulses[1:])} == {10_000}, "bits not 1 ms apart"
    if sigrok.available():
        data = f"{facility:08b}{card:016b}"
        want = f"{data[:12].count('1') & 1}{data}{1 ^ (data[12:].count('1') & 1)}"
        frames = [t for t in texts(trace.decode("wiegand:bitwidth_ms=1")) if " bits " in t]
        assert frames == [f"26 bits {want}"], frames
        # Both lines low at once is not a Wiegand bit.
        a = pulses[5][0]
        wrong = texts(trace.forced("d0", a, a + 500, 0).forced("d1", a, a + 500, 0)
                      .decode("wiegand:bitwidth_ms=1"))
        assert f"26 bits {want}" not in wrong, wrong


@cocotb.test(timeout_time=400, timeout_unit="ms")
async def test_nec_infrared(dut):
    """NEC infrared with its 38 kHz carrier, as the LED is driven: read
    back by sigrok's NEC decoder, which checks every interval to 5% and
    each byte against its complement."""
    await reset(dut)
    trace = pin_trace(dut, ir=0)
    chip = pe.Chip(sim_port(dut))
    address, command = 0x04, 0x08

    @bridge
    def play():
        more.NecTx(chip, firmware("nec_tx")).send(address, command)

    await play()
    await ClockCycles(dut.clk, 760_000)
    trace.stop()
    highs = [(a, b) for (a, _), (b, _) in zip(trace.level("ir"), trace.level("ir")[1:])]
    periods = {b[0] - a[0] for a, b in zip(highs[1::2], highs[3::2]) if b[0] - a[0] < 1000}
    assert periods == {264}, f"carrier periods {periods}"  # 37.9 kHz
    if sigrok.available():
        decoder = "ir_nec:polarity=active-high:cd_freq=38000"
        fields = [t for t in texts(trace.decode(decoder)) if ": 0x" in t]
        want = [f"Address: 0x{address:02X}", f"Address#: 0x{address ^ 0xFF:02X}",
                f"Command: 0x{command:02X}", f"Command#: 0x{command ^ 0xFF:02X}"]
        assert fields == want, fields
        # One burst of carrier blanked out: the frame must not decode.
        a = next(a for a, _, text in trace.decode(decoder) if text == "Command: 0x08")
        wrong = [t for t in texts(trace.forced("ir", a, a + 9000, 0).decode(decoder))
                 if ": 0x" in t]
        assert wrong != want, wrong


# Two device-level protocols that need no firmware of their own: the engine
# is one the chip already has, and sigrok's decoder for the device, stacked
# on its decoder for the bus, says what a real device would have understood.


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_midi(dut):
    """MIDI is 31,250 baud 8N1: the UART transmitter with a divisor of
    320. sigrok's MIDI decoder, on its UART decoder, must read the notes."""
    await reset(dut)
    trace = pin_trace(dut, midi=0)
    chip = pe.Chip(sim_port(dut))
    message = [0x90, 60, 100, 0x80, 60, 0, 0xB0, 7, 127, 0xC0, 5]

    @bridge
    def play():
        pe.UartTx(chip, firmware("uart_tx"), divisor=320).write(message)

    await play()
    await ClockCycles(dut.clk, 5 * 3200)
    trace.stop()
    if sigrok.available():
        decoder = "uart:rx=midi:baudrate=31250,midi"
        found = trace.decode(decoder, "midi")
        want = ["Channel 1: note on (note = 60 'C4', velocity = 100)",
                "Channel 1: note off (note = 60 'C4', velocity = 0)",
                "Channel 1: control change 'channel volume MSB",
                "Channel 1: program change to instrument 6"]
        got = texts(found)
        assert len(got) == len(want) and all(g.startswith(w) for g, w in zip(got, want)), got
        # The lowest bit of the first note number held high: note 61, not 60.
        at = found[0][0] + 10 * 320  # the second byte's first data bit
        wrong = texts(trace.forced("midi", at, at + 320, 1).decode(decoder, "midi"))
        assert wrong[0].startswith("Channel 1: note on (note = 61"), wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_max7219(dut):
    """A MAX7219 display driver is set up and given two digits over the SPI
    controller; sigrok's MAX7219 decoder, on its SPI decoder, must read
    each register write."""
    await reset(dut)
    trace = pin_trace(dut, sck=0, mosi=1, cs=3)
    chip = pe.Chip(sim_port(dut))
    writes = [(0x0C, 0x01), (0x09, 0xFF), (0x0A, 0x08), (0x0B, 0x07), (0x01, 0x05), (0x08, 0x09)]

    @bridge
    def play():
        spi = pe.SpiController(chip, firmware("spi_fast"))
        for register, value in writes:
            spi.transfer([register, value])

    await play()
    await ClockCycles(dut.clk, 500)
    trace.stop()
    if sigrok.available():
        decoder = "spi:clk=sck:mosi=mosi:cs=cs,max7219"
        found = trace.decode(decoder, "max7219")
        want = ["Shutdown: off", "Decode: 0b11111111", "Intensity: 8", "Scan limit: 8",
                "Digit 1: 05", "Digit 8: 09"]
        assert texts(found) == want, texts(found)
        # The data line held high for the last write: not digit 8's 09.
        a, b, _ = found[-1]
        wrong = texts(trace.forced("mosi", a - 20, b, 1).decode(decoder, "max7219"))
        assert wrong[:-1] == want[:-1] and wrong[-1] != want[-1], wrong



async def mdio_phy(dut, registers, driving, address=5, delay=3):
    """A PHY written from clause 22 of IEEE 802.3, on MDC (pin 0) and MDIO
    (pin 1, pulled up). It reads MDIO as MDC rises and, in a read addressed
    to it, drives the turnaround 0 and the register MSB first, each bit
    appearing [delay] cycles after a rising edge: 300 ns, the longest the
    standard allows. [driving]["phy"] is the level the PHY puts on the
    line."""
    bits, drive, out, was, cycle, due = [], [], 1, 0, 0, []
    while True:
        await RisingEdge(dut.clk)
        cycle += 1
        while due and due[0][0] <= cycle:
            out = due.pop(0)[1]
        driving["phy"] = out
        oe, pins = int(dut.uio_oe.value), int(dut.uio_out.value)
        mdc = pins & 1
        chip = 0 if (oe >> 1) & 1 and not (pins >> 1) & 1 else 1
        dut.uio_in.value = (int(dut.uio_in.value) & ~2) | ((chip & out) << 1)
        if mdc and not was:  # MDC rose on the pin one cycle ago
            if drive:
                due.append((cycle + delay - 2, drive.pop(0)))
            else:
                bits.append(chip & out)
                frame = bits[-46:]
                if len(frame) == 46 and all(frame[:32]) and frame[32:34] == [0, 1]:
                    number = lambda field: int("".join(map(str, field)), 2)
                    if frame[34:36] == [1, 0] and number(frame[36:41]) == address:
                        value = registers.get(number(frame[41:46]), 0xFFFF)
                        # Released, then 0, then the register, then released.
                        drive = [1, 0] + [(value >> (15 - k)) & 1 for k in range(16)] + [1]
                        due.append((cycle + delay - 2, drive.pop(0)))
                    bits = []
        was = mdc


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_mdio(dut):
    """MDIO: a register write and two reads against a PHY that takes the
    full 300 ns to answer, and a read of a PHY that is not there. sigrok's
    MDIO decoder reads every frame off the bus."""
    await reset(dut)
    dut.dev_mode.value = 0  # an earlier test's device may still be wired to the pins
    driving = {"phy": 1}
    # The line is low when either end pulls it low.
    line = lambda: driving["phy"] & ~(int(dut.uio_oe.value) & ~int(dut.uio_out.value)) >> 1 & 1
    trace = sigrok.Trace(dut, {"mdc": lambda: int(dut.uio_out.value) & 1, "mdio": line})
    cocotb.start_soon(mdio_phy(dut, {2: 0x0141, 3: 0x0DD1}, driving))
    chip = pe.Chip(sim_port(dut))
    got = []

    @bridge
    def play():
        bus = more.Mdio(chip, firmware("mdio"))
        bus.write(5, 0, 0x1140)
        got.append(bus.read(5, 2))
        got.append(bus.read(5, 3))
        try:
            bus.read(6, 2)
        except more.MdioError:
            got.append("nobody")

    await play()
    await ClockCycles(dut.clk, 100)
    trace.stop()
    assert got == [0x0141, 0x0DD1, "nobody"], got
    if sigrok.available():
        frames = lambda found: [t for t in texts(found) if t.startswith(("WRITE", "READ"))]
        found = trace.decode("mdio")
        want = ["WRITE: 1140 PHYAD: 05 REGAD: 00", "READ:  0141 PHYAD: 05 REGAD: 02",
                "READ:  0DD1 PHYAD: 05 REGAD: 03", "READ:  FFFF PHYAD: 06 REGAD: 02 ERROR"]
        assert frames(found) == want, frames(found)
        # The line held high through the first read's turnaround: an error.
        first_read = next(a for a, _, text in found if text == "OP: READ")
        a, b = next((a, b) for a, b, text in found if text == "TA" and a > first_read)
        wrong = frames(trace.forced("mdio", a, b, 1).decode("mdio"))
        assert wrong[1].endswith("ERROR") and wrong[2:] == want[2:], wrong


async def mdio_mmd(dut, registers, driving, prtad, devad, delay=3):
    """A clause 45 MMD written from IEEE 802.3 clause 45, on the same pins as
    mdio_phy. After 32 ones of preamble it takes ST 00, the opcode, PRTAD and
    DEVAD. An address frame (opcode 00) sets its register address and a
    write (01) stores to it, each from the 16 bits after the turnaround; a
    read (11) drives the turnaround 0 and the register MSB first, [delay]
    cycles after each rising edge, as mdio_phy does. Frames for another port
    or device, and clause 22 frames, it leaves alone."""
    bits, drive, out, was, cycle, due = [], [], 1, 0, 0, []
    address, taking = 0, None  # taking: (opcode, bits still to come)
    number = lambda field: int("".join(map(str, field)), 2)
    while True:
        await RisingEdge(dut.clk)
        cycle += 1
        while due and due[0][0] <= cycle:
            out = due.pop(0)[1]
        driving["phy"] = out
        oe, pins = int(dut.uio_oe.value), int(dut.uio_out.value)
        mdc = pins & 1
        chip = 0 if (oe >> 1) & 1 and not (pins >> 1) & 1 else 1
        dut.uio_in.value = (int(dut.uio_in.value) & ~2) | ((chip & out) << 1)
        if mdc and not was:  # MDC rose on the pin one cycle ago
            if drive:
                due.append((cycle + delay - 2, drive.pop(0)))
            elif taking is not None:
                bits.append(chip & out)
                if len(bits) == 18:  # the turnaround, then the 16 bits
                    if taking == 0b00:
                        address = number(bits[2:])
                    else:
                        registers[address] = number(bits[2:])
                    bits, taking = [], None
            else:
                bits.append(chip & out)
                frame = bits[-46:]
                if len(frame) == 46 and all(frame[:32]) and frame[32:34] == [0, 0]:
                    opcode = number(frame[34:36])
                    if number(frame[36:41]) == prtad and number(frame[41:46]) == devad:
                        if opcode == 0b11:
                            value = registers.get(address, 0xFFFF)
                            drive = [1, 0] + [(value >> (15 - k)) & 1 for k in range(16)] + [1]
                            due.append((cycle + delay - 2, drive.pop(0)))
                        elif opcode in (0b00, 0b01):
                            taking = opcode
                    bits = []
        was = mdc


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_cfp_module(dut):
    """A CFP 100 Gigabit module's management interface on the MDIO
    controller: MDIO clause 45, which the same firmware carries because the
    host writes the frame's header word. As the CFP MSA lays it out, the
    module answers device address 1 at its port address, and the host reads
    the first four registers of NVR 1, the basic ID table, each with an
    address frame and a read frame. sigrok's CFP decoder, on its MDIO
    decoder, must place each read in NVR 1 and name the module a CFP; the
    module is written here from the MSA's register map."""
    await reset(dut)
    dut.dev_mode.value = 0  # an earlier test's device may still be wired to the pins
    driving = {"phy": 1}
    line = lambda: driving["phy"] & ~(int(dut.uio_oe.value) & ~int(dut.uio_out.value)) >> 1 & 1
    trace = sigrok.Trace(dut, {"mdc": lambda: int(dut.uio_out.value) & 1, "mdio": line})
    # Identifier CFP; power class 2; LC connector; 100GE-LR4. Each a byte in
    # the low half of its register.
    nvr1 = {0x8000: 0x0E, 0x8001: 0x40, 0x8002: 0x07, 0x8003: 0x01}
    cocotb.start_soon(mdio_mmd(dut, dict(nvr1), driving, prtad=1, devad=1))
    chip = pe.Chip(sim_port(dut))
    got = []

    def header(opcode, prtad, devad):
        """ST 00 (clause 45), the opcode, the port and device, and the
        turnaround: released for a read, 10 otherwise."""
        return (opcode << 12) | (prtad << 7) | (devad << 2) | (0b11 if opcode & 0b10 else 0b10)

    @bridge
    def play():
        bus = more.Mdio(chip, firmware("mdio"))
        for register in nvr1:
            bus._words([0xFFFF, 0xFFFF, header(0b00, 1, 1), register])
            back = bus._words([0xFFFF, 0xFFFF, header(0b11, 1, 1), 0xFFFF])
            got.append(None if back[2] & 1 else back[3])

    await play()
    await ClockCycles(dut.clk, 100)
    trace.stop()
    assert got == list(nvr1.values()), got
    if sigrok.available():
        decoder = "mdio,cfp"
        want = ["CFP NVR 1: Basic ID register", "Module identifier: CFP"] + \
            ["CFP NVR 1: Basic ID register"] * 3
        found = trace.decode(decoder, "cfp")
        assert texts(found) == want, texts(found)
        reads = [t for t in texts(trace.decode("mdio")) if t.startswith("ADDR: ")]
        assert reads == [f"ADDR: {r:04X} READ:  {v:04X} PRTAD: 01 DEVAD: 01"
                         for r, v in nvr1.items()], reads
        # The identifier's last bit held high as the module sends it: 0x0F.
        a, b, _ = found[0]
        rises = [t for t, v in trace.level("mdc") if v == 1 and a <= t <= b]
        last = rises[-1]
        wrong = texts(trace.forced("mdio", last - 2, last + 2, 1).decode(decoder, "cfp"))
        assert wrong == [want[0], "Module identifier: CXP (TBD)"] + want[2:], wrong


@cocotb.test(timeout_time=200, timeout_unit="ms")
async def test_dali(dut):
    """DALI forward frames, read back by sigrok's DALI decoder; every half
    bit must be the same length, whatever the bits either side of it."""
    await reset(dut)
    trace = pin_trace(dut, dali=0)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        dali = more.DaliTx(chip, firmware("dali_tx"))
        dali.send(0xFF, 0x05)  # broadcast: recall maximum level
        dali.send(0x02, 0xA5)  # short address 1: arc power 165

    await play()
    await ClockCycles(dut.clk, 500_000)
    trace.stop()
    half = 8 * 521
    lows = {b - a for a, b in trace.low_pulses("dali")}
    assert lows == {half, 2 * half}, f"low times {sorted(lows)}"
    if sigrok.available():
        want = ["BROADCAST", "Command: 5 (Recall Maximum Level)", "Short address: 1",
                "Arc Power Level: 165"]
        found = trace.decode("dali")
        got = [t for t in texts(found) if t in want]
        assert got == want, texts(found)
        # The second half of the last bit of the first frame held low: not
        # command 5 any more.
        a, b = next((a, b) for a, b, text in found if text == "Raw data: 05")
        wrong = texts(trace.forced("dali", b - half, b, 0).decode("dali"))
        assert "Command: 5 (Recall Maximum Level)" not in wrong, wrong


def ir_receiver(dut, pin, hold):
    """What an IR receiver module makes of the LED on [pin]: its output is
    active for as long as carrier has been seen within the last [hold]
    cycles."""
    since = [hold]

    def level():
        lit = (int(dut.uio_oe.value) >> pin) & (int(dut.uio_out.value) >> pin) & 1
        since[0] = 0 if lit else since[0] + 1
        return 1 if since[0] < hold else 0
    return level


@cocotb.test(timeout_time=400, timeout_unit="ms")
async def test_rc5_infrared(dut):
    """RC-5 infrared with its 36 kHz carrier, as the LED is driven. The
    bursts must be whole numbers of carrier periods with no gap inside
    them; sigrok's RC-5 decoder, which takes a receiver module's output,
    is given the LED as such a module would report it."""
    await reset(dut)
    trace = sigrok.Trace(dut, {"ir": ir_receiver(dut, 0, 417)})  # 1.5 carrier periods
    led = pin_trace(dut, led=0)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        more.Rc5Tx(chip, firmware("rc5_tx")).send(0x05, 0x35)

    await play()
    await ClockCycles(dut.clk, 280_000)
    trace.stop()
    led.stop()
    rises = [t for t, v in led.level("led") if v == 1][1:]  # [0]: before the pin drives
    bursts, n = [], 1
    for a, b in zip(rises, rises[1:]):
        if b - a == 278:  # one carrier period, 36.0 kHz
            n += 1
        else:
            bursts.append(n)
            n = 1
    bursts.append(n)
    # Worked out here from RC-5's rules: a 1 is silence then a burst of 32
    # periods, a 0 a burst then silence, so where a 1 meets a 0 the two
    # bursts are one of 64.
    halves = "".join("01" if bit == "1" else "10" for bit in "111" "00101" "110101")
    want_bursts = [32 * len(run) for run in halves.split("0") if run]
    assert bursts == want_bursts, (bursts, want_bursts)
    if sigrok.available():
        decoder = "ir_rc5:polarity=active-high"
        fields = lambda found: [t for t in texts(found) if not t.isdigit()]
        want = ["Startbit1: 1", "Startbit2: 1", "Togglebit: 1",
                "Address: 5 (Video cassette recorder 1)", "Command: 53 (Play)"]
        found = trace.decode(decoder)
        assert fields(found) == want, fields(found)
        # The last burst blanked out: not command 53.
        a, b = next((a, b) for a, b, text in found if text.startswith("Command"))
        wrong = fields(trace.forced("ir", b - 10_000, b + 1_000, 0).decode(decoder))
        assert wrong != want, wrong


@cocotb.test(timeout_time=400, timeout_unit="ms")
async def test_rc6_infrared(dut):
    """RC-6 infrared, with its 36 kHz carrier, on the infrared burst
    sender. The bursts must be whole numbers of carrier periods, as worked
    out here from RC-6's rules; sigrok's RC-6 decoder is given the LED as
    a receiver module would report it."""
    await reset(dut)
    trace = sigrok.Trace(dut, {"ir": ir_receiver(dut, 0, 417)})  # 1.5 carrier periods
    led = pin_trace(dut, led=0)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        more.Rc6Tx(chip, firmware("ir_tx")).send(0x04, 0x0C, toggle=1)

    await play()
    await ClockCycles(dut.clk, 300_000)
    trace.stop()
    led.stop()
    rises = [t for t, v in led.level("led") if v == 1][1:]  # [0]: before the pin drives
    bursts, n = [], 1
    for a, b in zip(rises, rises[1:]):
        if b - a == 278:  # one carrier period, 36.0 kHz
            n += 1
        else:
            bursts.append(n)
            n = 1
    bursts.append(n)
    # From RC-6's rules: a leader lit for 6 units of 16 periods and dark for
    # 2; then a 1 is lit then dark and a 0 dark then lit, the fifth bit
    # (the toggle) twice as long.
    bits = "1000" "T" "00000100" "00001100"
    halves = "11111100" + "".join(
        ("1100" if i == 4 else "10" if bit == "1" else "01") for i, bit in enumerate(bits))
    want_bursts = [16 * len(run) for run in halves.split("0") if run]
    assert bursts == want_bursts, (bursts, want_bursts)
    if sigrok.available():
        decoder = "ir_rc6:polarity=active-high"
        fields = lambda found: [t for t in texts(found) if len(t) > 3]
        found = trace.decode(decoder)
        want = ["Synchronisation", "Startbit", "Field: 0", "Toggle: 1", "Address: 04", "Data: 0C"]
        assert fields(found) == want, fields(found)
        # The last burst blanked out: not command 0C.
        a, b = next((a, b) for a, b, text in found if text.startswith("Data"))
        wrong = fields(trace.forced("ir", b - 10_000, b + 1_000, 0).decode(decoder))
        assert wrong != want, wrong


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_lin(dut):
    """A LIN frame from the master (break, sync, identifier, four data bytes,
    checksum) on the DMX512 engine at 19,200 baud: sigrok's LIN decoder, on
    its UART decoder, must read every field."""
    await reset(dut)
    trace = pin_trace(dut, lin=0)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        more.LinMaster(chip, firmware("dmx_tx")).send(0x23, [0x11, 0x22, 0x33, 0x44])

    await play()
    await ClockCycles(dut.clk, 80_000)
    trace.stop()
    if sigrok.available():
        decoder = "uart:rx=lin:baudrate=19200,lin"
        # Worked by hand: identifier 0x23 has parity bits 10, so 0xA3 goes on
        # the wire; 0xA3 + 0x11 + 0x22 + 0x33 + 0x44 with the carries added
        # back is 0x4E, and the checksum is its complement.
        want = ["Break condition", "Sync", "ID: 23 Parity: 2 (ok)", "Data: 0x11", "Data: 0x22",
                "Data: 0x33", "Data: 0x44", "Checksum: 0xB1"]
        found = trace.decode(decoder, "lin")
        assert texts(found) == want, texts(found)
        # One bit of the identifier held low: its parity no longer fits.
        a = found[2][0]
        wrong = texts(trace.forced("lin", a + 521, a + 2 * 521, 0).decode(decoder, "lin"))
        dut._log.info("%s", wrong)
        assert wrong != want and "ID: 23 Parity: 2 (ok)" not in wrong, wrong


# --- Receivers: sources written here from each protocol's rules ---------------


def drive_pin(dut, k, level):
    dut.uio_in.value = (int(dut.uio_in.value) & ~(1 << k)) | (level << k)


async def wiegand_send(dut, bits, pulse=500, interval=10_000):
    """A reader sending [bits] on D0 (pin 0) and D1 (pin 1): a low pulse of
    [pulse] cycles on D0 for a 0 and on D1 for a 1, [interval] cycles from
    one pulse to the next."""
    for b in bits:
        drive_pin(dut, b, 0)
        await ClockCycles(dut.clk, pulse)
        drive_pin(dut, b, 1)
        await ClockCycles(dut.clk, interval - pulse)


def wiegand26(facility, card):
    data = [(facility >> (7 - k)) & 1 for k in range(8)] + [(card >> (15 - k)) & 1 for k in range(16)]
    return [sum(data[:12]) & 1] + data + [1 ^ (sum(data[12:]) & 1)]


@cocotb.test(timeout_time=400, timeout_unit="ms")
async def test_wiegand_receive(dut):
    """Wiegand frames from a reader: a 26-bit card, a 34-bit frame with the
    shortest pulses readers send, and a frame that stops short, which must
    be thrown away without spoiling the one after it."""
    await reset(dut)
    dut.dev_mode.value = 0  # an earlier test's device may still be wired to the pins
    dut.uio_in.value = 0xFF
    chip = pe.Chip(sim_port(dut))
    rx = []

    @bridge
    def start():
        rx.append(more.WiegandRx(chip, firmware("wiegand_rx")))

    @bridge
    def expect(bits):
        rx[0].expect(bits)

    @bridge
    def read26():
        try:
            return rx[0].read26(patience=20)
        except more.WiegandError as e:
            return str(e)

    @bridge
    def read():
        return rx[0].read(patience=20)

    await start()
    await expect(26)
    await wiegand_send(dut, wiegand26(0x9C, 0xB1E5))  # 50 us pulses, 1 ms apart
    assert await read26() == (0x9C, 0xB1E5)

    long = [(0x2A5C3F19B >> k) & 1 for k in range(34)]
    await expect(34)
    await wiegand_send(dut, long, pulse=200, interval=2_500)  # 20 us pulses
    assert await read() == long

    await expect(26)
    await wiegand_send(dut, wiegand26(0x9C, 0xB1E5)[:10])
    assert await read26() == "no complete frame of 26 bits"

    await expect(26)
    await wiegand_send(dut, wiegand26(0x01, 0x0203), pulse=1000, interval=5_000)
    assert await read26() == (0x01, 0x0203)


async def nec_send(dut, address_word, command_word, unit=5625, bits=32, repeat=False):
    """An IR receiver module's output (pin 0, low while it sees carrier) for
    an NEC frame: 16 units of burst and 8 of silence, then for each bit, LSB
    first, a burst of one unit and silence of one (a 0) or three (a 1), and a
    last burst. [unit]: cycles in 562.5 us. [repeat]: a repeat code instead,
    16 units of burst, 4 of silence and a burst."""
    async def burst(units):
        drive_pin(dut, 0, 0)
        await ClockCycles(dut.clk, units * unit)
        drive_pin(dut, 0, 1)

    await burst(16)
    await ClockCycles(dut.clk, (4 if repeat else 8) * unit)
    if not repeat:
        value = address_word | (command_word << 16)
        for k in range(bits):
            await burst(1)
            await ClockCycles(dut.clk, (3 if (value >> k) & 1 else 1) * unit)
    await burst(1)


@cocotb.test(timeout_time=600, timeout_unit="ms")
async def test_nec_receive(dut):
    """NEC frames from a receiver module: a plain frame, a repeat code (which
    must be ignored), an extended-address frame from a remote running 15%
    slow, a frame that stops after 20 bits, and a frame from one 15% fast,
    whose zeros come at a word boundary, where the receiver is busiest."""
    await reset(dut)
    dut.dev_mode.value = 0  # an earlier test's device may still be wired to the pins
    dut.uio_in.value = 0xFF
    chip = pe.Chip(sim_port(dut))
    rx = []

    @bridge
    def start():
        rx.append(more.NecRx(chip, firmware("nec_rx")))

    @bridge
    def read():
        try:
            return rx[0].read(patience=4)
        except more.NecError as e:
            return str(e)

    @bridge
    def waiting():
        return chip.status()["rx_level"]

    pair = lambda byte: byte | ((byte ^ 0xFF) << 8)
    rest = ClockCycles(dut.clk, 12 * 5625)  # longer than the 8 units that abandon a frame
    await start()
    await nec_send(dut, pair(0x04), pair(0x08))
    await rest
    assert await read() == (0x04, 0x08)

    await nec_send(dut, 0, 0, repeat=True)
    await rest
    assert await waiting() == 0, "a repeat code was taken for a frame"

    await nec_send(dut, 0x1234, pair(0xA5), unit=6470)
    await rest
    assert await read() == (0x1234, 0xA5)

    await nec_send(dut, pair(0x04), pair(0x08), bits=20)
    await rest
    assert await read() == "frame cut short"

    await nec_send(dut, pair(0xFF), pair(0x00), unit=4780)
    await rest
    assert await read() == (0xFF, 0x00)
    assert await waiting() == 0


async def dali_send(dut, value, bits, half=4167, pin=1):
    """The DALI bus on [pin] for one frame: the start bit, a 1, then [bits]
    bits of [value], the highest first. A 1 is low for half a bit and then
    high. [half]: cycles in the sender's half bit."""
    for k in [None] + list(range(bits - 1, -1, -1)):
        b = 1 if k is None else (value >> k) & 1
        drive_pin(dut, pin, 1 - b)
        await ClockCycles(dut.clk, half)
        drive_pin(dut, pin, b)
        await ClockCycles(dut.clk, half)
    drive_pin(dut, pin, 1)


@cocotb.test(timeout_time=900, timeout_unit="ms")
async def test_dali_receive(dut):
    """DALI received through the bit sampler and its prescaler: a forward
    frame; the answer to it 2.9 ms later, the shortest DALI allows; a
    24-bit frame from a sender 10% fast; a bus held low, which is no frame;
    and a forward frame from a sender 10% slow. The host takes the words
    as they come, as it must: a frame is more words than the FIFO holds.
    sigrok's DALI decoder reads the first two frames off the same wire
    and must find what the chip found."""
    await reset(dut)
    dut.dev_mode.value = 0  # an earlier test's device may still be wired to the pins
    dut.uio_in.value = 0xFF
    trace = sigrok.Trace(dut, {"dali": lambda: (int(dut.uio_in.value) >> 1) & 1})
    chip = pe.Chip(sim_port(dut))
    rx = []
    half = 4167

    @bridge
    def start():
        rx.append(more.DaliRx(chip, firmware("dali_rx")))

    @bridge
    def read():
        try:
            return rx[0].read(patience=4000)
        except more.DaliError as e:
            return str(e)

    async def bus():
        await ClockCycles(dut.clk, 12 * half)
        await dali_send(dut, 0xFF90, 16)  # broadcast: query status
        await ClockCycles(dut.clk, 7 * half)
        await dali_send(dut, 0xC4, 8)  # the gear's answer
        await ClockCycles(dut.clk, 12 * half)
        trace.stop()
        await dali_send(dut, 0xC1A55A, 24, half=3750)
        await ClockCycles(dut.clk, 12 * half)
        drive_pin(dut, 1, 0)
        await ClockCycles(dut.clk, 20 * half)
        drive_pin(dut, 1, 1)
        await ClockCycles(dut.clk, 12 * half)
        await dali_send(dut, 0x02A5, 16, half=4584)

    await start()
    sender = cocotb.start_soon(bus())
    got = [await read() for _ in range(5)]
    await sender
    assert got == [(0xFF90, 16), (0xC4, 8), (0xC1A55A, 24), "low for a whole bit", (0x02A5, 16)], got
    if sigrok.available():
        wire = lambda found: [t for t in texts(found)
                              if re.fullmatch(r"(Raw data|Reply): [0-9A-F]{2}", t)]
        found = trace.decode("dali")
        assert wire(found) == ["Raw data: FF", "Raw data: 90", "Reply: C4"], \
            [t for t in texts(found) if len(t) > 1]
        # The answer's last bit, a 0, held high throughout: not 0xC4.
        a, b = next((a, b) for a, b, text in found if text == "Reply: C4")
        wrong = texts(trace.forced("dali", b - 2 * half, b, 1).decode("dali"))
        assert "Reply: C4" not in wrong, wrong


class DaliBus:
    """A DALI bus between the chip and one gear: low while either pulls it
    low. The chip sends on pin 0 and listens on pin 1."""

    def __init__(self, dut):
        self.dut = dut
        self.gear = 1

    def chip(self):
        return (int(self.dut.uio_out.value) & 1) if int(self.dut.uio_oe.value) & 1 else 1

    def update(self):
        drive_pin(self.dut, 1, self.chip() & self.gear)

    async def follow(self, signal):
        while True:
            await ValueChange(signal)
            self.update()


async def dali_gear(bus, address, answers, half=4167):
    """A DALI gear, written from the standard's description of a frame. It
    reads each forward frame off the bus by looking at the middle of every
    half bit from the frame's first edge, and answers the commands in
    [answers] ({command: byte}) sent to [address] or to everyone (0xFF),
    about ten half bits after the frame: DALI asks for 7 to 22."""
    dut = bus.dut
    while True:
        while bus.chip():
            await ValueChange(dut.uio_out)
        await ClockCycles(dut.clk, half // 2)
        halves = []
        while halves[-4:] != [1, 1, 1, 1]:
            halves.append(bus.chip())
            await ClockCycles(dut.clk, half)
        pairs = list(zip(halves[0:-4:2], halves[1:-4:2]))
        if any(a == b for a, b in pairs) or len(pairs) != 17 or pairs[0] != (0, 1):
            continue  # not a forward frame
        bits = [b for _, b in pairs[1:]]
        to = int("".join(map(str, bits[:8])), 2)
        command = int("".join(map(str, bits[8:])), 2)
        if to not in (address, 0xFF) or command not in answers:
            continue
        await ClockCycles(dut.clk, 6 * half)
        for k in [None] + list(range(7, -1, -1)):
            b = 1 if k is None else (answers[command] >> k) & 1
            bus.gear = 1 - b
            bus.update()
            await ClockCycles(dut.clk, half)
            bus.gear = b
            bus.update()
            await ClockCycles(dut.clk, half)
        bus.gear = 1
        bus.update()


@cocotb.test(timeout_time=900, timeout_unit="ms")
async def test_dali_query(dut):
    """A DALI controller on the two threads: the transmitter on one, the
    receiver, through the bit sampler, on the other. It asks a gear for its
    status and reads the answer; a query to an address nobody has gets no
    answer; a broadcast query is answered. The receiver hears each of the
    chip's own frames first, and the driver checks it. sigrok's DALI
    decoder reads the first query and its answer off the bus."""
    await reset(dut)
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    half = 4167
    bus = DaliBus(dut)
    tasks = [cocotb.start_soon(bus.follow(dut.uio_out)), cocotb.start_soon(bus.follow(dut.uio_oe)),
             cocotb.start_soon(dali_gear(bus, 0x03, {0x90: 0xC4, 0xA0: 0x7F}))]
    trace = sigrok.Trace(dut, {"dali": lambda: (int(dut.uio_in.value) >> 1) & 1})
    chip = pe.Chip(sim_port(dut))
    controller = []

    @bridge
    def start():
        controller.append(more.Dali(chip, firmware("dali_tx"), firmware("dali_rx")))

    @bridge
    def query(address, command):
        try:
            return controller[0].query(address, command, patience=6000, wait=3000)
        except more.DaliError as e:
            return str(e)

    await start()
    await ClockCycles(dut.clk, 12 * half)
    assert await query(0x03, 0x90) == 0xC4
    await ClockCycles(dut.clk, 12 * half)
    trace.stop()
    assert await query(0x05, 0x90) is None
    assert await query(0xFF, 0xA0) == 0x7F
    for task in tasks:
        task.cancel()
    if sigrok.available():
        wire = lambda found: [t for t in texts(found)
                              if re.fullmatch(r"(Raw data|Reply): [0-9A-F]{2}", t)]
        found = trace.decode("dali")
        assert wire(found) == ["Raw data: 03", "Raw data: 90", "Reply: C4"], \
            [t for t in texts(found) if len(t) > 1]
        # The answer's last bit, a 0, held high throughout: not 0xC4.
        a, b = next((a, b) for a, b, text in found if text == "Reply: C4")
        wrong = texts(trace.forced("dali", b - 2 * half, b, 1).decode("dali"))
        assert "Reply: C4" not in wrong, wrong


async def rc5_send(dut, bits, half=8890):
    """An IR receiver module's output (pin 0, low while it sees carrier) for
    the bits of an RC-5 transmission: a 1 is silence and then carrier, a 0
    carrier and then silence. [half]: cycles in the remote's half bit."""
    for b in bits:
        drive_pin(dut, 0, b)
        await ClockCycles(dut.clk, half)
        drive_pin(dut, 0, 1 - b)
        await ClockCycles(dut.clk, half)
    drive_pin(dut, 0, 1)


def rc5_bits(toggle, address, command):
    word = (0b11 << 12) | (toggle << 11) | (address << 6) | command
    return [(word >> k) & 1 for k in range(13, -1, -1)]


@cocotb.test(timeout_time=900, timeout_unit="ms")
async def test_rc5_receive(dut):
    """RC-5 from a receiver module, through the bit sampler and its
    prescaler: a frame; a transmission that stops after nine bits, which
    must be dropped; a frame from a remote 15% slow and one from a remote
    15% fast. sigrok's RC-5 decoder reads the first frame off the same
    wire and must find what the chip found."""
    await reset(dut)
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    trace = sigrok.Trace(dut, {"ir": lambda: int(dut.uio_in.value) & 1})
    chip = pe.Chip(sim_port(dut))
    rx = []
    half = 8890
    rest = ClockCycles(dut.clk, 12 * half)

    @bridge
    def start():
        rx.append(more.Rc5Rx(chip, firmware("rc5_rx")))

    @bridge
    def read():
        try:
            return rx[0].read(patience=4)
        except more.Rc5Error as e:
            return str(e)

    @bridge
    def waiting():
        return chip.status()["rx_level"]

    await start()
    await rest
    await rc5_send(dut, rc5_bits(1, 5, 0x35))
    await rest
    trace.stop()
    assert await read() == (1, 5, 0x35)

    await rc5_send(dut, rc5_bits(0, 21, 42)[:9])
    await rest
    assert await waiting() == 0, "a transmission cut short was taken for a frame"

    await rc5_send(dut, rc5_bits(0, 16, 12), half=10_224)
    await rest
    assert await read() == (0, 16, 12)

    await rc5_send(dut, rc5_bits(1, 0, 63), half=7557)
    await rest
    assert await read() == (1, 0, 63)
    assert await waiting() == 0
    if sigrok.available():
        fields = lambda found: [t for t in texts(found) if not t.isdigit()]
        want = ["Startbit1: 1", "Startbit2: 1", "Togglebit: 1",
                "Address: 5 (Video cassette recorder 1)", "Command: 53 (Play)"]
        found = trace.decode("ir_rc5")
        assert fields(found) == want, fields(found)
        # The last bit's carrier blanked out: not command 53.
        a, b = next((a, b) for a, b, text in found if text.startswith("Command"))
        wrong = fields(trace.forced("ir", b - 3 * half, b + half, 1).decode("ir_rc5"))
        assert wrong != want, wrong


class Eeprom93c46Model:
    """A 93C46 serial EEPROM, 64 words of 16 bits, from its datasheet. It
    takes DI as SK rises while CS is high and changes DO at that edge. A
    command is a start bit, two opcode bits and six address bits; a read
    answers the last of them with a 0 and then sends the word, and the
    words after it for as long as it is clocked. A write is stored when CS
    falls, if writing is enabled, and for [busy] cycles after that the part
    takes no command and holds DO low whenever CS is high."""

    def __init__(self, busy=3000):
        self.mem = [0xFFFF] * 64
        self.enabled = False
        self.taken, self.to_send = [], []
        self.do, self.cs, self.sk = 1, 0, 0
        self.busy, self.busy_until, self.cycle = busy, 0, 0
        self.log = []

    @staticmethod
    def _value(bits):
        return int("".join(map(str, bits)), 2)

    def step(self, cs, sk, di):
        self.cycle += 1
        busy = self.cycle < self.busy_until
        if self.cs and not cs:
            t = self.taken
            if len(t) == 25 and t[:3] == [1, 0, 1]:
                address, word = self._value(t[3:9]), self._value(t[9:])
                if self.enabled:
                    self.mem[address] = word
                    self.busy_until = self.cycle + self.busy
                self.log.append(("write", address, word, self.enabled))
            self.taken, self.to_send, self.do = [], [], 1
        if cs and not self.cs:
            self.do = 0 if busy else 1
        if cs and busy:
            self.do = 0
        elif cs and not self.taken and not self.to_send:
            self.do = 1
        if cs and sk and not self.sk and not busy:
            if self.to_send:
                self.do = self.to_send.pop(0)
            elif self.taken or di:
                self.taken.append(di)
                t = self.taken
                if len(t) == 9 and t[:3] == [1, 1, 0]:
                    address = self._value(t[3:])
                    self.log.append(("read", address))
                    self.do = 0
                    self.to_send = [(w >> k) & 1 for w in self.mem[address:]
                                    for k in range(15, -1, -1)]
                elif len(t) == 9 and t[:5] == [1, 0, 0, 1, 1]:
                    self.enabled = True
                    self.log.append(("enable",))
                elif len(t) == 9 and t[:5] == [1, 0, 0, 0, 0]:
                    self.enabled = False
                    self.log.append(("disable",))
        self.cs, self.sk = cs, sk


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_microwire_eeprom(dut):
    """A 93C46 EEPROM on the Microwire controller: a write refused because
    writing is not enabled, the enable, two writes with the part's busy
    time waited out by asking it, and reads. The EEPROM is a model written
    from the datasheet; sigrok's Microwire decoder and its 93xx decoder on
    top read the wires and must name every command with its address and
    data."""
    await reset(dut)
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    model = Eeprom93c46Model()

    async def wires():
        while True:
            await FallingEdge(dut.clk)
            out, oe = int(dut.uio_out.value), int(dut.uio_oe.value)
            driven = out & oe
            model.step(driven & 1, (driven >> 1) & 1, (driven >> 2) & 1)
            dut.uio_in.value = 0xF7 | (model.do << 3)

    line = lambda k: (lambda: (int(dut.uio_out.value) & int(dut.uio_oe.value)) >> k & 1)
    trace = sigrok.Trace(dut, {"cs": line(0), "sk": line(1), "si": line(2),
                               "so": lambda: (int(dut.uio_in.value) >> 3) & 1})
    bus = cocotb.start_soon(wires())
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        eeprom = more.Eeprom93c46(more.Microwire(chip, firmware("microwire")))
        eeprom.write(5, 0x1234)  # writing is not enabled yet
        refused = eeprom.read(5)
        eeprom.write_enable()
        waits = []
        for address, value in ((5, 0xBEEF), (63, 0x8001)):
            eeprom.write(address, value)
            waits.append(0)
            while not eeprom.ready():
                waits[-1] += 1
        return refused, waits, [eeprom.read(a) for a in (5, 63, 0)]

    refused, waits, read = await session()
    await ClockCycles(dut.clk, 200)
    trace.stop()
    bus.cancel()
    assert refused == 0xFFFF and read == [0xBEEF, 0x8001, 0xFFFF], (refused, read)
    assert all(w > 0 for w in waits), f"the busy time was never seen: {waits}"
    assert (model.mem[5], model.mem[63]) == (0xBEEF, 0x8001)
    assert model.log[0] == ("write", 5, 0x1234, False), model.log
    if sigrok.available():
        decoder = "microwire,eeprom93xx:addresssize=6"
        named = lambda found: [t for t in texts(found) if t.startswith(
            ("Read word", "Write word", "Write enable", "Address: ", "Data: "))]
        word = lambda kind, address, data: [kind, "Address: 0x%04x" % address, "Data: 0x%04x" % data]
        want = (word("Write word", 5, 0x1234) + word("Read word", 5, 0xFFFF) + ["Write enable"]
                + word("Write word", 5, 0xBEEF) + word("Write word", 63, 0x8001)
                + word("Read word", 5, 0xBEEF) + word("Read word", 63, 0x8001)
                + word("Read word", 0, 0xFFFF))
        found = trace.decode(decoder, "eeprom93xx")
        assert named(found) == want, named(found)
        # The part's busy time shows too: the Microwire decoder sees it.
        assert "Busy" in texts(trace.decode("microwire")), "no busy time on the wire"
        # DO held low through the word read back from address 5: not 0xbeef.
        a, b = next((a, b) for a, b, text in found if text == "Data: 0xbeef" and a > found[10][0])
        wrong = named(trace.forced("so", a, b, 0).decode(decoder, "eeprom93xx"))
        assert wrong != want, wrong


def bits_of(value, width):
    return [(value >> (width - 1 - k)) & 1 for k in range(width)]


def value_of(bits):
    return int("".join(map(str, bits)), 2) if bits else 0


class Ade7758Model:
    """An ADE7758 energy meter's serial interface, from its datasheet, with
    CS tied low, as the datasheet allows when the part is alone on the
    bus. It takes DIN as SCLK falls. The first byte is the communications
    register: bit 7 set for a write, the register's address below it. A
    write's data follows, MSB first, a byte for every eight bits of the
    register or part of eight. A read's data goes out on DOUT from the
    next rising edge of SCLK, which must come 1.1 us (t9) or more after the
    command's last falling edge, and DOUT lets go after the last falling
    edge. Nothing pulls DOUT, so it keeps its last level: the part holds
    its bit 10 ns or more past that edge, which a recording at 10 MHz
    could not show had the line been made to move at once."""

    WIDTH = {0x13: 8, 0x1C: 16, 0x0D: 24}  # OPMODE, LINECYC, AVRMS

    def __init__(self, registers):
        self.registers = dict(registers)
        self.dout, self.sclk, self.cycle = 1, 0, 0
        self.taken, self.cmd, self.sending, self.sent = [], None, [], 0
        self.log, self.t9 = [], []

    def step(self, sclk, din):
        self.cycle += 1
        if sclk and not self.sclk and self.sending:
            if self.sent == 0:
                self.t9.append(self.cycle - self.last_fall)
            self.dout, self.sent = self.sending[self.sent], self.sent + 1
        elif self.sclk and not sclk:
            self.last_fall = self.cycle
            if self.sending:
                if self.sent == len(self.sending):
                    self.log.append(("read", self.cmd & 0x7F, value_of(self.sending)))
                    self.sending, self.cmd = [], None
            else:
                self.taken.append(din)
                if self.cmd is None and len(self.taken) == 8:
                    self.cmd, self.taken = value_of(self.taken), []
                    self.n = -(-self.WIDTH[self.cmd & 0x7F] // 8) * 8  # whole bytes
                    if not self.cmd & 0x80:
                        self.sending, self.sent = bits_of(self.registers[self.cmd], self.n), 0
                elif self.cmd is not None and len(self.taken) == self.n:
                    register, value = self.cmd & 0x7F, value_of(self.taken)
                    self.registers[register] = value
                    self.log.append(("write", register, value))
                    self.cmd, self.taken = None, []
        self.sclk = sclk


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_ade7758(dut):
    """An ADE7758 three-phase energy meter on the Microwire controller,
    which has the part's clock phase: the part takes DIN as SCLK falls and
    sends DOUT from each rise, and the controller changes DI after SK falls
    and reads DO after SK rises. Its chip select is tied low, as the
    datasheet allows for a part alone on its bus; the controller's CS goes
    nowhere. At CLKDIV 4, SK is low for 1.2 us, longer than the 1.1 us the
    part needs between a read's command and its data. The driver reads the
    mode register, sets the line cycle count and reads it back, and reads
    phase A's voltage. sigrok's ADE77xx decoder, on its SPI decoder with
    the same clock phase, must read each register and its value."""
    await reset(dut)
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    model = Ade7758Model({0x13: 0x04, 0x1C: 0xFFFF, 0x0D: 0x0C1E8A})

    async def wires():
        while True:
            await FallingEdge(dut.clk)
            driven = int(dut.uio_out.value) & int(dut.uio_oe.value)
            model.step((driven >> 1) & 1, (driven >> 2) & 1)
            dut.uio_in.value = 0xF7 | (model.dout << 3)

    line = lambda k: (lambda: (int(dut.uio_out.value) & int(dut.uio_oe.value)) >> k & 1)
    trace = sigrok.Trace(dut, {"sclk": line(1), "din": line(2),
                               "dout": lambda: (int(dut.uio_in.value) >> 3) & 1})
    bus = cocotb.start_soon(wires())
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        wire = more.Microwire(chip, firmware("microwire"), clkdiv=4)

        def read(register, size):
            return value_of(wire.transfer(bits_of(register, 8) + [0] * 8 * size)[8:])

        def write(register, value, size):
            wire.transfer(bits_of(0x80 | register, 8) + bits_of(value, 8 * size))

        opmode = read(0x13, 1)
        write(0x1C, 200, 2)  # LINECYC: 200 half cycles of the line
        return opmode, read(0x1C, 2), read(0x0D, 3)

    got = await session()
    await ClockCycles(dut.clk, 200)
    trace.stop()
    bus.cancel()
    assert got == (0x04, 200, 0x0C1E8A), got
    assert model.log == [("read", 0x13, 0x04), ("write", 0x1C, 200), ("read", 0x1C, 200),
                         ("read", 0x0D, 0x0C1E8A)], model.log
    assert min(model.t9) >= 11, model.t9  # cycles of 100 ns
    if sigrok.available():
        decoder = "spi:clk=sclk:mosi=din:miso=dout:cpha=1,ade77xx"
        found = trace.decode(decoder, "ade77xx")
        want = ["OPMODE: 0x4", "LINECYC: 0xc8", "LINECYC: 0xc8", "AVRMS: 0xc1e8a"]
        assert texts(found) == want, texts(found)
        assert texts(trace.decode(decoder, "ade77xx=write")) == ["LINECYC: 0xc8"]
        # DOUT held low through the voltage's middle byte: not that voltage.
        a, b = found[-1][0], found[-1][1]
        rises = [t for t, v in trace.level("sclk") if v and t <= b][-32:]  # command, three bytes
        assert a - 20 < rises[0] < a, (a, rises)
        wrong = texts(trace.forced("dout", rises[16], rises[24], 0).decode(decoder, "ade77xx"))
        assert wrong[:3] == want[:3] and wrong[3] != want[3], wrong


class X2444Model:
    """A Xicor X2444 NOVRAM, sixteen 16-bit words of RAM with an EEPROM
    copy, from its datasheet. CE high selects it; it takes DI as SK rises,
    passes over 0s until a 1, and takes that 1 and the seven bits after it
    as an instruction, 1AAAAOOO. WRITE (011) puts the next 16 bits in RAM
    word AAAA; STO (001) copies the RAM to the EEPROM; WREN (100) and WRDS
    (000) set and clear the write enable latch, which is clear at power-up
    and without which writes and stores are ignored. CE falling ends an
    instruction."""

    def __init__(self):
        self.ram, self.eeprom = [0xFFFF] * 16, [0xFFFF] * 16
        self.enabled, self.taken, self.ce, self.sk, self.log = False, [], 0, 0, []

    def step(self, ce, sk, di):
        if not ce:
            self.taken = []
        elif sk and not self.sk and (self.taken or di):
            self.taken.append(di)
            t = self.taken
            if len(t) == 8:
                op, address = value_of(t[5:]), value_of(t[1:5])
                if op == 0b100:
                    self.enabled = True
                elif op == 0b000:
                    self.enabled = False
                elif op == 0b001 and self.enabled:
                    self.eeprom = list(self.ram)
                if op != 0b011:
                    self.log.append(({0b100: "WREN", 0b000: "WRDS", 0b001: "STO"}.get(op, op), self.enabled))
            elif len(t) == 24 and value_of(t[5:8]) == 0b011:
                address, word = value_of(t[1:5]), value_of(t[8:])
                if self.enabled:
                    self.ram[address] = word
                self.log.append(("WRITE", address, word, self.enabled))
        self.ce, self.sk = ce, sk


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_x2444_novram(dut):
    """An X2444 NOVRAM on the Microwire controller, whose chip select is
    active high as the part's CE is: a write refused because the write
    enable latch is clear at power-up, the latch set, two words written to
    RAM, and the RAM stored in the EEPROM. Only writes: the part puts a
    read's first bit out as SK falls on the instruction's last bit and the
    rest as SK rises, and the controller reads DO only after SK rises, so
    that bit would be missed. The NOVRAM is a model written from the
    datasheet; sigrok's X2444M/P decoder, on its SPI decoder with CE active
    high, must name every instruction, with the address and word of each
    write."""
    await reset(dut)
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    model = X2444Model()

    async def wires():
        while True:
            await FallingEdge(dut.clk)
            driven = int(dut.uio_out.value) & int(dut.uio_oe.value)
            model.step(driven & 1, (driven >> 1) & 1, (driven >> 2) & 1)

    line = lambda k: (lambda: (int(dut.uio_out.value) & int(dut.uio_oe.value)) >> k & 1)
    trace = sigrok.Trace(dut, {"ce": line(0), "sk": line(1), "di": line(2),
                               "do": lambda: (int(dut.uio_in.value) >> 3) & 1})
    bus = cocotb.start_soon(wires())
    chip = pe.Chip(sim_port(dut))
    writes = [(3, 0x1234), (5, 0xBEEF), (15, 0x8001)]

    @bridge
    def session():
        wire = more.Microwire(chip, firmware("microwire"))
        instruction = lambda address, op: bits_of(0x80 | (address << 3) | op, 8)
        wire.transfer(instruction(writes[0][0], 0b011) + bits_of(writes[0][1], 16))
        wire.transfer(instruction(0, 0b100))  # WREN
        for address, word in writes[1:]:
            wire.transfer(instruction(address, 0b011) + bits_of(word, 16))
        wire.transfer(instruction(0, 0b001))  # STO

    await session()
    await ClockCycles(dut.clk, 200)
    trace.stop()
    bus.cancel()
    assert model.log == [("WRITE", 3, 0x1234, False), ("WREN", True), ("WRITE", 5, 0xBEEF, True),
                         ("WRITE", 15, 0x8001, True), ("STO", True)], model.log
    assert model.eeprom[3] == 0xFFFF and (model.eeprom[5], model.eeprom[15]) == (0xBEEF, 0x8001)
    if sigrok.available():
        decoder = "spi:clk=sk:mosi=di:miso=do:cs=ce:cs_polarity=active-high,x2444m"
        found = trace.decode(decoder, "x2444m")
        want = ["WRITE: 0x3 => 0x1234", "WREN", "WRITE: 0x5 => 0xbeef", "WRITE: 0xf => 0x8001", "STO"]
        assert texts(found) == want, texts(found)
        # DI held high through the word written to address 5: not 0xbeef.
        a, b = next((a, b) for a, b, text in found if text == "WRITE: 0x5 => 0xbeef")
        wrong = texts(trace.forced("di", (a + b) // 2, b, 1).decode(decoder, "x2444m"))
        assert wrong[:2] == want[:2] and wrong[2] != want[2] and wrong[3:] == want[3:], wrong


class CecFollower:
    """A CEC follower at [address], from the specification's timing table
    for receivers: a start bit is low for 3.5 to 3.9 ms of a 4.3 to 4.7 ms
    period; a bit is 2.05 to 2.75 ms long and low for 0.4 to 0.8 ms (a 1)
    or 1.3 to 1.7 ms (a 0). It acknowledges the blocks of a message sent
    to it by holding the line low for 1.5 ms from the ACK bit's edge. It
    looks at the line every [step] cycles of the 10 MHz clock."""

    def __init__(self, dut, address, step=200):
        self.dut, self.address, self.step = dut, address, step
        self.messages, self.errors = [], []

    @staticmethod
    def _within(us, lo, hi):
        return lo * 1000 <= us <= hi * 1000

    def _pulse(self, low, period):
        if self.ack_bit:
            self.ack_bit = False
            if period is not None and not self._within(period, 2.05, 2.75):
                self.errors.append(f"ACK bit {period} us long")
            self.bits = []
        elif self._within(low, 3.5, 3.9) and (period is None or self._within(period, 4.3, 4.7)):
            # A start bit begins a message whenever it comes.
            self.in_message, self.bits, self.blocks = True, [], []
        elif not self.in_message:
            self.errors.append(f"not a start bit: low {low} us")
        else:
            bit = 1 if self._within(low, 0.4, 0.8) else 0 if self._within(low, 1.3, 1.7) else None
            if bit is None or (period is not None and not self._within(period, 2.05, 2.75)):
                self.errors.append(f"a bit low {low} us of {period}")
                self.in_message = False
            else:
                self.bits.append(bit)

    async def run(self):
        dut, us = self.dut, self.step / 10
        t, line, fell, low, hold_until = 0, 1, None, 0, -1
        self.in_message, self.bits, self.blocks, self.ack_bit = False, [], [], False
        for_me = False
        while True:
            await ClockCycles(dut.clk, self.step)
            t += us
            chip_low = bool(int(dut.uio_oe.value) & 1) and not int(dut.uio_out.value) & 1
            now = 0 if chip_low or t < hold_until else 1
            drive_pin(dut, 0, now)
            if line and not now:
                if fell is not None:
                    self._pulse(low, t - fell)
                fell = t
                if self.in_message and len(self.bits) == 9:  # this pulse is the ACK bit
                    data = int("".join(map(str, self.bits[:8])), 2)
                    if not self.blocks:
                        for_me = data & 0xF == self.address
                    self.blocks.append(data)
                    self.ack_bit = True
                    if for_me:
                        hold_until = t + 1500
                    if self.bits[8]:
                        self.messages.append(self.blocks)
                        self.in_message = False
            elif not line and now and fell is not None:
                low = t - fell
            elif line and now and fell is not None and t - fell > 5000:
                self._pulse(low, None)
                fell = None
            line = now


@cocotb.test(timeout_time=900, timeout_unit="ms")
async def test_hdmi_cec(dut):
    """The HDMI-CEC initiator: a message a follower acknowledges; one to an
    address nobody has, which must stop at its header; and one to
    everyone. The follower is written from the specification's receiver
    timing and rejects any pulse outside it. sigrok's CEC decoder reads the
    same wire: it must name the three messages with their
    acknowledgements, and warn about nothing."""
    await reset(dut)
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    follower = CecFollower(dut, 4)
    listening = cocotb.start_soon(follower.run())
    trace = sigrok.Trace(dut, {"cec": lambda: int(dut.uio_in.value) & 1})
    chip = pe.Chip(sim_port(dut))

    @bridge
    def session():
        cec = more.Cec(chip, firmware("cec"), address=1)
        return [cec.send(4, [0x04]), cec.send(5, [0x8F]), cec.send(15, [0x82, 0x10, 0x00])]

    got = await session()
    await ClockCycles(dut.clk, 60_000)
    trace.stop()
    listening.cancel()
    assert got == [True, False, True], got
    assert follower.errors == [], follower.errors
    assert follower.messages == [[0x14, 0x04], [0x1F, 0x82, 0x10, 0x00]], follower.messages
    if sigrok.available():
        found = trace.decode("cec")
        frames = lambda found: [t for a, b, t in found
                                if re.fullmatch(r"[0-9a-f]{2}(:[0-9a-f]{2})*", t) and b - a > 100_000]
        results = [t.rsplit("| R: ", 1)[1] for t in texts(found) if "| R: " in t]
        warnings = [t for t in texts(found) if re.search(r"Invalid|Expected|ERROR|exceeds|below", t)]
        assert frames(found) == ["14:04", "15", "1f:82:10:00"], frames(found)
        assert results == ["ACK", "NACK", "ACK"], results
        assert warnings == [], warnings
        # The first message's data block cut short by a line held high: not 14:04.
        a, b = next((a, b) for a, b, text in found if text == "14:04")
        wrong = frames(trace.forced("cec", (a + b) // 2, b, 1).decode("cec"))
        assert "14:04" not in wrong, wrong


# --- Devices on the engines the chip already had ------------------------------
#
# A device's own protocol on top of a bus: no new firmware, only what the
# host sends. sigrok's decoder for the device, stacked on its decoder for the
# bus, must find in the recording what the host meant.


async def i2c_session(dut, address, size=None, device=None):
    """The divider-timed I2C controller on a bus with cocotbext-i2c's memory
    at [address], or with the model [device] makes of the bus wires; returns
    the memory (or model) and a function running one transfer (the words to
    push; the reports popped)."""
    dut.dev_mode.value = 1
    pins = dict(sda=dut.i2c_sda, sda_o=dut.i2c_sda_dev, scl=dut.i2c_scl, scl_o=dut.i2c_scl_dev)
    memory = device(**pins) if device else I2cMemory(**pins, addr=address, size=size)
    await load(dut, firmware("i2c"))
    await configure_i2c(dut)
    await write(dut, PIN_MODES, 0b1010)  # P0 SDA, P1 SCL open-drain
    await write(dut, CTRL, 1)

    async def transfer(words):
        reports = []
        for w in words:  # a report comes back for every word, and the FIFOs hold four
            await push(dut, w)
            reports.append(await pop(dut))
        return reports

    def write_bytes(data):
        """START, address + W, the bytes, STOP."""
        return [i2c_write_word(address << 1, False)] + [
            i2c_write_word(b, k == len(data) - 1) for k, b in enumerate(data)]

    def read_bytes(pointer, n):
        """Set the pointer, repeated START, address + R, n bytes, STOP."""
        return [i2c_write_word(address << 1, False),
                i2c_write_word(pointer, False, restart=True),
                i2c_write_word((address << 1) | 1, False)] + [
                    i2c_read_word(k == n - 1) for k in range(n)]

    return memory, transfer, write_bytes, read_bytes


def i2c_trace(dut):
    return sigrok.Trace(dut, {"scl": lambda: int(dut.i2c_scl.value),
                              "sda": lambda: int(dut.i2c_sda.value)})


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_eeprom_24xx(dut):
    """A 24Cxx EEPROM on the I2C controller: a page write, a byte write, a
    read from the address they leave behind, and a read from an address of
    the host's choosing, which takes a repeated START. sigrok's 24xx
    decoder, on its I2C decoder, names the writes and that read;
    cocotbext-i2c's memory holds what was written and supplies what is
    read."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, write_bytes, read_bytes = await i2c_session(dut, 0x50, 256)
    await transfer(write_bytes([0x10, 0xDE, 0xAD, 0xBE]))
    await ClockCycles(dut.clk, 200)
    await transfer(write_bytes([0x0F, 0x55]))
    await ClockCycles(dut.clk, 200)
    reports = await transfer([i2c_write_word(0xA1, False)] + [i2c_read_word(k == 2) for k in range(3)])
    await ClockCycles(dut.clk, 200)
    random = await transfer(read_bytes(0x11, 2))
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert memory.read_mem(0x0F, 4) == bytes([0x55, 0xDE, 0xAD, 0xBE])
    assert [rev8(r & 0xFF) for r in reports[1:]] == [0xDE, 0xAD, 0xBE], reports
    assert [rev8(r & 0xFF) for r in random[3:]] == [0xAD, 0xBE], random
    if sigrok.available():
        decoder = "i2c,eeprom24xx"
        named = lambda found: [t for t in texts(found) if "(addr=" in t]
        want = ["Page write (addr=10, 3 bytes): DE AD BE", "Byte write (addr=0F, 1 byte): 55",
                "Sequential random read (addr=11, 2 bytes): AD BE"]
        found = trace.decode(decoder, "eeprom24xx")
        assert named(found) == want, named(found)
        # One START in the session is a repeated one, and no STOP comes
        # between the pointer and the read.
        bus = texts(trace.decode("i2c"))
        assert bus.count("Start repeat") == 1 and bus.count("Stop") == 4, \
            [t for t in bus if t.startswith(("Start", "Stop"))]
        # The data line held low through the first data byte: not 0xDE.
        a, b = next((a, b) for a, b, text in found if text == "Data byte 10: DE")
        wrong = named(trace.forced("sda", a, b, 0).decode(decoder, "eeprom24xx"))
        assert wrong != want, wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_ds1307_clock(dut):
    """A DS1307 real-time clock on the I2C controller: the seven time
    registers are set and read back. sigrok's DS1307 decoder, on its I2C
    decoder, must read the date and time out of the bytes on the bus."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, write_bytes, read_bytes = await i2c_session(dut, 0x68, 64)
    # Seconds, minutes, hours, weekday, date, month, year, in BCD.
    await transfer(write_bytes([0x00, 0x56, 0x34, 0x12, 0x04, 0x19, 0x11, 0x26]))
    await ClockCycles(dut.clk, 200)
    reports = await transfer(read_bytes(0x00, 7))
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert [rev8(r & 0xFF) for r in reports[3:]] == [0x56, 0x34, 0x12, 0x04, 0x19, 0x11, 0x26]
    if sigrok.available():
        times = [t for t in texts(trace.decode("i2c,ds1307", "ds1307")) if "date/time" in t]
        assert len(times) == 2 and all(
            t.endswith("date/time: Wednesday, 19.11.2026 12:34:56") for t in times), times


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_lm75_thermometer(dut):
    """An LM75 temperature sensor on the I2C controller: the two-byte read
    every driver does. sigrok's LM75 decoder must make 25.5 degrees of it."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, _, _ = await i2c_session(dut, 0x48, 8)
    memory.write_mem(0, bytes([0x19, 0x80]))  # 25.5 degrees: 9 bits, 0.5 each
    reports = await transfer([i2c_write_word(0x91, False)] + [i2c_read_word(k == 1) for k in range(2)])
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert [rev8(r & 0xFF) for r in reports[1:]] == [0x19, 0x80], reports
    if sigrok.available():
        found = trace.decode("i2c,lm75", "lm75")
        assert "Temperature: 25.5 °C" in texts(found), texts(found)
        # The top data bit held high: a negative temperature.
        a, b, _ = found[0]
        wrong = texts(trace.forced("sda", a, a + 60, 1).decode("i2c,lm75", "lm75"))
        assert "Temperature: 25.5 °C" not in wrong, wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_rtc8564_clock(dut):
    """An RTC-8564 real-time clock on the I2C controller: the seven time
    registers are set, then read back through a repeated START, as the
    part's data sheet shows a read. sigrok's RTC-8564 decoder, on its I2C
    decoder, must read the time out of the bytes both ways."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, write_bytes, read_bytes = await i2c_session(dut, 0x51, 16)
    # From register 2: seconds, minutes, hours, day, weekday, month, year, in BCD.
    await transfer(write_bytes([0x02, 0x56, 0x34, 0x12, 0x21, 0x06, 0x11, 0x26]))
    await ClockCycles(dut.clk, 200)
    reports = await transfer(read_bytes(0x02, 7))
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert [rev8(r & 0xFF) for r in reports[3:]] == [0x56, 0x34, 0x12, 0x21, 0x06, 0x11, 0x26]
    if sigrok.available():
        decoder = "i2c,rtc8564"
        fields = lambda found: [t for t in texts(found) if t.startswith(
            ("Second: ", "Minute: ", "Hour: ", "Day: ", "Weekday: ", "Month: ", "Year: "))]
        want = ["Second: 56", "Minute: 34", "Hour: 12", "Day: 21", "Weekday: 6", "Month: 11", "Year: 26"]
        found = trace.decode(decoder, "rtc8564")
        assert fields(found) == want + want, fields(found)  # written, then read
        # The data line held low through the minutes as they are read back.
        a, b = [(a, b) for a, b, text in found if text == "Minute: 34"][1]
        wrong = fields(trace.forced("sda", a, b, 0).decode(decoder, "rtc8564"))
        assert wrong != want + want, wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_tca6408a_expander(dut):
    """A TCA6408A port expander on the I2C controller: its configuration
    and output registers are written, and its inputs read through a
    repeated START. sigrok's TCA6408A decoder must name each register and
    its value."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, write_bytes, read_bytes = await i2c_session(dut, 0x20, 8)
    memory.write_mem(0, bytes([0x5A]))  # what the pins read
    await transfer(write_bytes([0x03, 0x0F]))  # configuration: four inputs, four outputs
    await ClockCycles(dut.clk, 200)
    await transfer(write_bytes([0x01, 0xA0]))  # the output port
    await ClockCycles(dut.clk, 200)
    reports = await transfer(read_bytes(0x00, 1))  # the input port
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert rev8(reports[3] & 0xFF) == 0x5A, reports
    assert memory.read_mem(1, 1) == bytes([0xA0]) and memory.read_mem(3, 1) == bytes([0x0F])
    if sigrok.available():
        decoder = "i2c,tca6408a"
        values = lambda found: [t for t in texts(found) if re.search(r": [0-9A-F]{2}$", t)]
        want = ["Configuration: 0F", "Outputs set: A0", "State of inputs: 5A"]
        found = trace.decode(decoder, "tca6408a")
        assert values(found) == want, texts(found)
        assert not any("Warning" in t for t in texts(found)), texts(found)
        # The data line held low through the output value: not A0.
        a, b = next((a, b) for a, b, text in found if text == "Outputs set: A0")
        wrong = values(trace.forced("sda", a, b, 0).decode(decoder, "tca6408a"))
        assert wrong != want, wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_mxc6225xu_accelerometer(dut):
    """An MXC6225XU accelerometer on the I2C controller: its X and Y
    readings, read through a repeated START from register 0. sigrok's
    decoder for the part must make the same two numbers of them."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, _, read_bytes = await i2c_session(dut, 0x15, 8)
    memory.write_mem(0, bytes([0x2A, 0x60]))  # X = 42, Y = 96
    reports = await transfer(read_bytes(0x00, 2))
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert [rev8(r & 0xFF) for r in reports[3:]] == [0x2A, 0x60], reports
    if sigrok.available():
        decoder = "i2c,mxc6225xu"
        axes = lambda found: [t for t in texts(found) if t.startswith(("XOUT", "YOUT"))]
        found = trace.decode(decoder, "mxc6225xu")
        assert axes(found) == ["XOUT: 42", "YOUT: 96"], texts(found)
        # The data line held low through the X reading: not 42.
        a, b = next((a, b) for a, b, text in found if text == "XOUT: 42")
        wrong = axes(trace.forced("sda", a, b, 0).decode(decoder, "mxc6225xu"))
        assert "XOUT: 42" not in wrong, wrong


def edid_block():
    """A 128-byte EDID 1.3 block for a made-up 1024x768 monitor, with its
    checksum."""
    block = [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00]
    letters = [ord(c) - 64 for c in "PEM"]  # the maker's three letters, five bits each
    maker = (letters[0] << 10) | (letters[1] << 5) | letters[2]
    block += [maker >> 8, maker & 0xFF, 0x34, 0x12, 0x78, 0x56, 0x34, 0x12]  # product, serial
    block += [47, 36, 1, 3]  # week 47 of 2026; EDID 1.3
    block += [0x80, 32, 24, 120, 0x0A]  # digital; 32 x 24 cm; gamma 2.2
    block += [0xEE, 0x91, 0xA3, 0x54, 0x4C, 0x99, 0x26, 0x0F, 0x50, 0x54]  # chromaticity
    block += [0x00, 0x08, 0x00]  # established timings: 1024x768 at 60 Hz
    block += [0x01, 0x01] * 8  # no standard timings
    # 1024x768 at 60 Hz, 65 MHz pixel clock.
    block += [0x64, 0x19, 0x00, 0x40, 0x41, 0x00, 0x26, 0x30, 0x18, 0x88,
              0x36, 0x00, 0x40, 0xF0, 0x10, 0x00, 0x00, 0x18]
    name = b"PROTO-EMU\n   "
    block += [0, 0, 0, 0xFC, 0] + list(name[:13])
    block += [0, 0, 0, 0xFD, 0, 50, 75, 30, 80, 8, 0, 0x0A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20]
    block += [0, 0, 0, 0x10, 0] + [0] * 13
    block += [0]  # no extension blocks
    assert len(block) == 127, len(block)
    return block + [(-sum(block)) & 0xFF]


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_edid(dut):
    """A monitor's EDID read over DDC, which is I2C at address 0x50: the
    pointer set to 0, a repeated START, then all 128 bytes. sigrok's EDID
    decoder must find the header, the maker's letters and a checksum that
    adds up."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, _, read_bytes = await i2c_session(dut, 0x50, 256)
    block = edid_block()
    memory.write_mem(0, bytes(block))
    reports = await transfer(read_bytes(0x00, 128))
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert [rev8(r & 0xFF) for r in reports[3:]] == block, "the block as read"
    if sigrok.available():
        decoder = "i2c,edid"
        found = trace.decode(decoder, "edid")
        said = texts(found)
        assert any(t.startswith("Checksum: ") and t.endswith("(OK)") for t in said), said[-12:]
        assert any("PEM" in t for t in said), [t for t in said if "anufactur" in t or "endor" in t]
        # The data line held low through the last byte, the checksum.
        a, b = next((a, b) for a, b, text in found if text.startswith("Checksum: "))
        wrong = texts(trace.forced("sda", a, b, 0).decode(decoder, "edid"))
        assert not any(t.startswith("Checksum: ") and t.endswith("(OK)") for t in wrong), wrong[-6:]


def atsha_crc(data):
    """The ATSHA204A's CRC-16 as its data sheet gives it: polynomial 0x8005,
    each byte taken from its low bit, sent low byte first. The wake token
    04 11 checks to 33 43."""
    crc = 0
    for byte in data:
        for k in range(8):
            top = crc >> 15
            crc = (crc << 1) & 0xFFFF
            if (byte >> k) & 1 != top:
                crc ^= 0x8005
    return [crc & 0xFF, crc >> 8]


class Atsha204a(I2cDevice):
    """An ATSHA204A's I/O, written from its data sheet. Asleep it answers no
    address. SDA held low for 60 us or more wakes it, and 2.5 ms later it
    answers at 0x64 with the wake token (count 4, status 0x11, CRC). After
    word address 0x03 it takes a command packet, checks its count and CRC,
    and leaves the answer (count, data, CRC) for the next read; a packet
    that fails is answered with status 0xFF. Word address 0x01 puts it to
    sleep. Of the commands only Read of four configuration bytes is here."""

    def __init__(self, config, **pins):
        self.config, self.awake, self.packet, self.answer, self.at = list(config), False, [], [], 0
        super().__init__(**pins)
        cocotb.start_soon(self._wake())

    @property
    def addr(self):
        return 0x64 if self.awake else None

    def reply(self, data):
        self.answer, self.at = [len(data) + 3] + data + atsha_crc([len(data) + 3] + data), 0

    async def _wake(self):
        while True:
            await FallingEdge(self.sda)
            fell = get_sim_time("us")
            await RisingEdge(self.sda)
            if not self.awake and get_sim_time("us") - fell >= 60:  # tWLO
                await Timer(2500, "us")  # tWHI
                self.awake = True
                self.reply([0x11])

    def handle_start(self):
        self.packet = []

    async def handle_write(self, data):
        self.packet.append(data)

    def handle_stop(self):
        packet, self.packet = self.packet, []
        if not packet:
            return
        if packet[0] in (0x01, 0x02):  # sleep, idle
            self.awake = False
        elif packet[0] == 0x00:  # reset: read the answer from its start
            self.at = 0
        elif packet[0] == 0x03:  # command
            body = packet[1:]
            if len(body) < 7 or body[0] != len(body) or atsha_crc(body[:-2]) != body[-2:]:
                self.reply([0xFF])
            elif body[1] == 0x02 and body[2] == 0x00:  # Read, configuration zone, 4 bytes
                word = body[3] | (body[4] << 8)
                self.reply(self.config[4 * word:4 * word + 4])
            else:
                self.reply([0x03])  # parse error

    async def handle_read(self):
        data = self.answer[self.at] if self.at < len(self.answer) else 0xFF
        self.at += 1
        return data


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_atsha204a_crypto(dut):
    """A Microchip ATSHA204A crypto authentication chip on the I2C
    controller, its I/O written from the data sheet. The driver wakes it
    (address 0 sent at 98 kHz holds SDA low for 87 us), reads the wake
    token, sends a Read command for the first configuration word with its
    CRC, reads the answer, the first four bytes of the serial number, and
    puts the chip to sleep. sigrok's ATSHA204A decoder, on its I2C decoder,
    must name every field of the command and of the answer."""
    await reset(dut)
    trace = i2c_trace(dut)
    config = [0x01, 0x23, 0x9A, 0x4C]  # SN[0:3]; every part's serial number begins 01 23
    chip, transfer, write_bytes, _ = await i2c_session(
        dut, 0x64, device=lambda **pins: Atsha204a(config, **pins))
    read = lambda n: [i2c_write_word(0xC9, False)] + [i2c_read_word(k == n - 1) for k in range(n)]
    await write(dut, CLKDIV, 17)  # the wake: 98 kHz, so the zeros last past tWLO
    wake = await transfer([i2c_write_word(0x00, True)])
    await ClockCycles(dut.clk, 200)
    await write(dut, CLKDIV, 3)
    await Timer(2500, "us")  # tWHI
    token = await transfer(read(4))
    await ClockCycles(dut.clk, 200)
    command = [0x07, 0x02, 0x00, 0x00, 0x00]  # count, Read, 4 bytes of the configuration zone, word 0
    await transfer(write_bytes([0x03] + command + atsha_crc(command)))
    await ClockCycles(dut.clk, 200)
    answer = await transfer(read(7))
    await ClockCycles(dut.clk, 200)
    await transfer(write_bytes([0x01]))  # sleep
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    got = lambda reports: [rev8(r & 0xFF) for r in reports[1:]]
    assert rev8(wake[0] & 0xFF) == 0x00 and wake[0] & 0x100, wake  # nobody answers address 0
    assert got(token) == [0x04, 0x11, 0x33, 0x43], token
    assert got(answer) == [0x07] + config + atsha_crc([0x07] + config), answer
    assert not chip.awake
    if sigrok.available():
        decoder = "i2c,atsha204a"
        want = ["Count: 4",
                "Word addr: COMMAND", "Count: 7", "Opcode: Read",
                "Zone: CONFIG, Length: 4 bytes", "Address: 00 00", "CRC: 1E 2D",
                "Count: 7", "Data: 01 23 9a 4c", "CRC: C5 74",
                "Word addr: SLEEP"]
        found = trace.decode(decoder, "atsha204a")
        assert texts(found) == want, texts(found)
        # The data line held low through the command's count: 0, not 7.
        a, b = next((a, b) for a, b, text in found if text == "Count: 7")
        wrong = texts(trace.forced("sda", a, b, 0).decode(decoder, "atsha204a"))
        assert wrong != want and any(t.startswith("Warning: Invalid frame length") for t in wrong), wrong


class Pca9571(I2cDevice):
    """A PCA9571's one register, written from its data sheet: it answers at
    0x25 only, every byte written sets the eight outputs, and a read
    returns them. Outputs high at power-on."""

    def __init__(self, **pins):
        self.addr, self.port = 0x25, 0xFF
        super().__init__(**pins)

    async def handle_write(self, data):
        self.port = data

    async def handle_read(self):
        return self.port


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_pca9571_expander(dut):
    """An NXP PCA9571 8-bit output expander on the I2C controller, written
    from its data sheet: the driver sets the outputs, then reads them back
    to check them. sigrok's PCA9571 decoder must name the value set and the
    value read, and find them the same."""
    await reset(dut)
    trace = i2c_trace(dut)
    chip, transfer, write_bytes, _ = await i2c_session(dut, 0x25, device=Pca9571)
    await transfer(write_bytes([0x3C]))
    await ClockCycles(dut.clk, 200)
    reports = await transfer([i2c_write_word(0x4B, False), i2c_read_word(True)])
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert chip.port == 0x3C
    assert rev8(reports[1] & 0xFF) == 0x3C, reports
    if sigrok.available():
        decoder = "i2c,pca9571"
        want = ["Outputs set: 3C", "Outputs read: 3C"]
        found = trace.decode(decoder, "pca9571")
        assert texts(found) == want, texts(found)
        # The data line held low through the value set: the read no longer matches it.
        a, b = next((a, b) for a, b, text in found if text == "Outputs set: 3C")
        wrong = texts(trace.forced("sda", a, b, 0).decode(decoder, "pca9571"))
        assert wrong != want and any(t.startswith("Warning: read value") for t in wrong), wrong


def i2c_bit(trace, at, k):
    """The samples over which SDA carries bit k (0 the first, MSB) of the
    byte whose first bit SCL clocks in at sample [at]: from the fall of SCL
    before that bit's rising edge to the fall after it. Holding SDA there
    changes that one bit and makes no START or STOP."""
    scl = trace.level("scl")
    rise = [t for t, v in scl if v == 1 and t >= at][k]
    before = max(t for t, v in scl if v == 0 and t < rise)
    after = min(t for t, v in scl if v == 0 and t > rise)
    return before + 1, after


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_xfp_module(dut):
    """An XFP optical module's management interface on the I2C controller:
    at address 0x50 (0xA0 on the wire), as INF-8077i lays it out, the host
    reads from byte 0 the module identifier and the alarm and warning
    thresholds that follow it, through a repeated START, as a host does on
    finding a module. sigrok's XFP decoder, on its I2C decoder, must name
    the module and read each threshold in degrees and milliwatts;
    cocotbext-i2c's memory holds the module's lower memory."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, _, read_bytes = await i2c_session(dut, 0x50, 256)
    lower = [0x06, 0x00]  # identifier XFP; signal conditioner control
    word = lambda v: [(v >> 8) & 0xFF, v & 0xFF]
    lower += word(75 * 256) + word(-10 * 256) + word(70 * 256) + word(-5 * 256)  # 1/256 degree
    lower += [0] * 8  # reserved
    lower += [0] * 8  # bias current thresholds, not set
    lower += word(20000) + word(1000) + [0] * 4  # TX power alarms, 0.1 uW each
    lower += [0] * 24  # RX power and AUX thresholds, not set
    assert len(lower) == 58
    memory.write_mem(0, bytes(lower))
    reports = await transfer(read_bytes(0x00, len(lower)))
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert [rev8(r & 0xFF) for r in reports[3:]] == lower, reports
    if sigrok.available():
        decoder = "i2c,xfp"
        want = ["Module identifier: XFP", "Temp high alarm: 75.0 C", "Temp low alarm: -10.0 C",
                "Temp high warning: 70.0 C", "Temp low warning: -5.0 C",
                "TX power high alarm: 2.00 mW", "TX power low alarm: 0.10 mW"]
        found = trace.decode(decoder, "xfp=fieldnames-and-values")
        assert texts(found) == want, texts(found)
        # The identifier's last bit held high as it is read: 0x07, an XFF.
        a, b = i2c_bit(trace, found[0][0], 7)
        wrong = texts(trace.forced("sda", a, b, 1).decode(decoder, "xfp=fieldnames-and-values"))
        assert wrong == ["Module identifier: XFF"] + want[1:], wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_hdcp(dut):
    """HDCP 1.4 authentication as a source starts it over the HDMI DDC, which
    is I2C with the sink's HDCP port at 0x3A (0x74 on the wire): read Bcaps,
    write An and then Aksv, read Bksv, read Ri'. Each read sets the offset
    and turns round with a repeated START. The sink is cocotbext-i2c's
    memory holding a fixed Bksv, Bcaps and Ri'; no cipher runs, only the
    register traffic. sigrok's HDCP decoder, on its I2C decoder, must name
    each step."""
    await reset(dut)
    trace = i2c_trace(dut)
    memory, transfer, write_bytes, read_bytes = await i2c_session(dut, 0x3A, 256)
    bksv = [0x51, 0x1E, 0xF2, 0x1A, 0xCD]  # a KSV has twenty ones and twenty zeros
    aksv = [0x14, 0xF7, 0x61, 0x03, 0xB7]
    an = [0x34, 0x27, 0x1C, 0x13, 0x0A, 0x22, 0x13, 0x80]
    ri = [0x3E, 0x51]
    assert sum(bin(b).count("1") for b in bksv) == sum(bin(b).count("1") for b in aksv) == 20
    memory.write_mem(0x00, bytes(bksv))
    memory.write_mem(0x08, bytes(ri))
    memory.write_mem(0x40, bytes([0x80]))  # Bcaps: HDMI capable, not a repeater
    bcaps = await transfer(read_bytes(0x40, 1))
    await ClockCycles(dut.clk, 200)
    await transfer(write_bytes([0x18] + an))
    await ClockCycles(dut.clk, 200)
    await transfer(write_bytes([0x10] + aksv))
    await ClockCycles(dut.clk, 200)
    got_bksv = await transfer(read_bytes(0x00, 5))
    await ClockCycles(dut.clk, 200)
    got_ri = await transfer(read_bytes(0x08, 2))
    await ClockCycles(dut.clk, 2000)
    trace.stop()
    assert rev8(bcaps[3] & 0xFF) == 0x80, bcaps
    assert [rev8(r & 0xFF) for r in got_bksv[3:]] == bksv, got_bksv
    assert [rev8(r & 0xFF) for r in got_ri[3:]] == ri, got_ri
    assert memory.read_mem(0x18, 8) == bytes(an) and memory.read_mem(0x10, 5) == bytes(aksv)
    if sigrok.available():
        decoder = "i2c,hdcp"
        want = ["1.4 Bcaps", "1.4 An - Session random number", "1.4 Aksv - Transmitter KSV",
                "1.4 Bksv - Receiver KSV", "1.4 Ri' - Link Verification"]
        found = trace.decode(decoder, "hdcp")
        assert texts(found) == want, texts(found)
        # In the last session the offset's bit 3 held low: 0x00, not 0x08,
        # so the sink is asked for Bksv again instead of Ri'.
        at = [a for a, _, text in trace.decode("i2c") if text == "Data write: 08"][-1]
        a, b = i2c_bit(trace, at, 4)
        wrong = texts(trace.forced("sda", a, b, 0).decode(decoder, "hdcp"))
        assert wrong == want[:-1] + ["1.4 Bksv - Receiver KSV"], wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_spi_flash_commands(dut):
    """A SPI NOR flash on the SPI controller, driven by the board driver:
    release from power-down, then a read. sigrok's flash decoder, on its
    SPI decoder, must name the commands, the address and the data."""
    await reset(dut)
    address, data = 0x000100, [0x12, 0x34, 0x56]
    for k, b in enumerate(data):
        dut.flash.memory[address + k].value = b
    dut.dev_mode.value = 2
    trace = sigrok.Trace(dut, {"sck": lambda: int(dut.uio_out.value) & 1,
                               "mosi": lambda: (int(dut.uio_out.value) >> 1) & 1,
                               "miso": lambda: 0 if str(dut.flash_io1.value) == "0" else 1,
                               "cs": lambda: (int(dut.uio_out.value) >> 3) & 1})
    chip = pe.Chip(sim_port(dut))

    @bridge
    def read_flash():
        spi = pe.SpiController(chip, firmware("spi_fast"))
        spi.transfer([0xAB])
        return spi.transfer([0x03, 0x00, 0x01, 0x00, 0, 0, 0])[4:]

    assert await read_flash() == data
    await ClockCycles(dut.clk, 200)
    trace.stop()
    if sigrok.available():
        decoder = "spi:clk=sck:mosi=mosi:miso=miso:cs=cs,spiflash"
        found = trace.decode(decoder, "spiflash")
        got = texts(found)
        assert "Command: Release from deep powerdown / Read electronic ID (RDP/RES)" in got, got
        assert "Read data (addr 0x000100, 3 bytes): 12 34 56" in got, got
        # The data-out line held high through the middle address byte.
        a, b = next((a, b) for a, b, text in found if text == "Address bits 15..8: 0x01")
        wrong = texts(trace.forced("mosi", a - 20, b, 1).decode(decoder, "spiflash"))
        assert "Read data (addr 0x000100, 3 bytes): 12 34 56" not in wrong, wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_ws2801_leds(dut):
    """WS2801 LED pixels on the SPI controller: three bytes a pixel. sigrok's
    decoder for SPI LED strips must read the two colours."""
    await reset(dut)
    dut.dev_mode.value = 0
    trace = pin_trace(dut, sck=0, mosi=1, cs=3)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def light():
        pe.SpiController(chip, firmware("spi_fast")).transfer([0xFF, 0x80, 0x00, 0x00, 0x40, 0xFF])

    await light()
    await ClockCycles(dut.clk, 600)
    trace.stop()
    if sigrok.available():
        decoder = "spi:clk=sck:mosi=mosi:cs=cs,rgb_led_spi"
        found = trace.decode(decoder, "rgb_led_spi")
        assert texts(found) == ["#ff8000", "#0040ff"], texts(found)
        a, b, _ = found[1]
        wrong = texts(trace.forced("mosi", a - 20, a + 200, 1).decode(decoder, "rgb_led_spi"))
        assert wrong[0] == "#ff8000" and wrong[1] != "#0040ff", wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_modbus_rtu(dut):
    """A Modbus RTU request on the UART transmitter: the example in the
    Modbus specification (read three holding registers from 0x006B of
    server 17), whose bytes and CRC are copied from there. sigrok's Modbus
    decoder, on its UART decoder, must read the request and pass the CRC."""
    await reset(dut)
    dut.dev_mode.value = 0
    trace = pin_trace(dut, tx=0)
    chip = pe.Chip(sim_port(dut))
    frame = more.modbus_frame(0x11, 0x03, [0x00, 0x6B, 0x00, 0x03])
    assert frame == bytes([0x11, 0x03, 0x00, 0x6B, 0x00, 0x03, 0x76, 0x87]), frame.hex()

    @bridge
    def send():
        pe.UartTx(chip, firmware("uart_tx"), divisor=87).write(frame)  # 114,943 baud

    await send()
    await ClockCycles(dut.clk, 8000)  # the silence that ends a frame
    trace.stop()
    if sigrok.available():
        decoder = "uart:tx=tx:baudrate=114943,modbus"
        want = ["Slave ID: 17", "Function 3: Read Holding Registers",
                "Start at address 0x6B / 30108", "Read 3 units of data", "CRC correct"]
        found = trace.decode(decoder, "modbus")
        assert texts(found) == want, texts(found)
        # One data bit of the register count held high: the CRC no longer fits.
        a = found[3][0]
        wrong = texts(trace.forced("tx", a + 2 * 87, a + 3 * 87, 1).decode(decoder, "modbus"))
        assert "CRC correct" not in wrong, wrong


async def nes_pad_model(dut, state):
    """A gamepad's 4021 shift register, from its data sheet: while the latch
    (pin 0) is high it holds the eight buttons, A at the output; each rising
    edge of the clock (pin 1) moves the next one to the output (pin 2).
    [state]["held"] is the set of buttons down; a button down reads 0."""
    order = ("A", "B", "Select", "Start", "Up", "Down", "Left", "Right")
    register, was = [1] * 8, 1
    while True:
        await RisingEdge(dut.clk)
        pins = int(dut.uio_out.value)
        latch, clock = pins & 1, (pins >> 1) & 1
        if latch:
            register = [0 if name in state["held"] else 1 for name in order]
        elif clock and not was:
            register = register[1:] + [1]
        was = clock
        state["out"] = register[0]
        drive_pin(dut, 2, register[0])


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_nes_gamepad(dut):
    """An NES gamepad read as the console reads it, against a pad's shift
    register written from its data sheet. sigrok's gamepad decoder, on its
    SPI decoder, must name the buttons held in each reading."""
    await reset(dut)
    dut.dev_mode.value = 0  # an earlier test's device may still be wired to the pins
    dut.uio_in.value = 0xFF
    state = {"held": set(), "out": 1}
    cocotb.start_soon(nes_pad_model(dut, state))
    clock = lambda: (int(dut.uio_out.value) >> 1) & 1 if (int(dut.uio_oe.value) >> 1) & 1 else 1
    trace = sigrok.Trace(dut, {"clk": clock, "data": lambda: state["out"]})
    latch = pin_trace(dut, latch=0, clock=1)
    chip = pe.Chip(sim_port(dut))
    pad = []

    @bridge
    def start():
        pad.append(more.NesPad(chip, firmware("nes_pad")))

    @bridge
    def read():
        return set(pad[0].read())

    await start()
    readings = [set(), {"A"}, {"Start", "Right"}, {"B", "Select", "Up", "Down", "Left"}]
    for held in readings:
        state["held"] = held
        assert await read() == held
    await ClockCycles(dut.clk, 500)
    trace.stop()
    latch.stop()
    # The console's timing: latch 12 us; clock low 6 us, eight times a reading.
    lows = [b - a for a, b in latch.low_pulses("clock")]
    assert lows == [60] * (8 * len(readings)), lows
    if sigrok.available():
        decoder = "spi:clk=clk:miso=data:cpol=1:cpha=0,nes_gamepad"
        found = trace.decode(decoder, "nes_gamepad")
        want = ["No button is pressed", "A", "Start + East", "B + Select + North + South + West"]
        assert texts(found) == want, texts(found)
        # The data line held low for the second reading: every button down.
        a, b, _ = found[1]
        wrong = texts(trace.forced("data", a - 200, b + 200, 0).decode(decoder, "nes_gamepad"))
        assert wrong[1] != "A" and wrong[2:] == want[2:], wrong


@cocotb.test(timeout_time=200, timeout_unit="ms")
async def test_pwm(dut):
    """PWM: 30% of a 1 ms period, then a servo's 1.5 ms pulse every 20 ms,
    each exact to the clock cycle. sigrok's PWM decoder measures both."""
    await reset(dut)
    trace = pin_trace(dut, pwm=0)
    chip = pe.Chip(sim_port(dut))
    pwm = []

    @bridge
    def start():
        pwm.append(more.Pwm(chip, firmware("pwm")))
        pwm[0].set(300, 1000)

    @bridge
    def servo():
        pwm[0].servo(1500)

    await start()
    await ClockCycles(dut.clk, 60_000)
    changed = trace.n  # samples so far
    await servo()
    await ClockCycles(dut.clk, 3 * 200_000)
    trace.stop()
    edges = trace.level("pwm")
    rises = [t for t, v in edges if v == 1][1:]  # [0]: before the pin drives
    falls = [t for t, v in edges if v == 0]
    first = [(r, f) for r, f in zip(rises, falls[1:]) if f < changed]
    assert len(first) >= 4 and {f - r for r, f in first} == {3000}, first
    assert {b[0] - a[0] for a, b in zip(first, first[1:])} == {10_000}
    last = [(r, f) for r, f in zip(rises, falls[1:]) if r > changed + 1000]
    assert len(last) >= 2 and {f - r for r, f in last} == {15_000}, last
    assert {b[0] - a[0] for a, b in zip(last, last[1:])} == {200_000}
    if sigrok.available():
        found = texts(trace.decode("pwm"))
        assert found[:2] == ["30.000000%", "1000.0 μs"], found[:4]
        assert found[-2:] == ["7.500000%", "20.0 ms"], found[-4:]


# --- v2.1: Ethernet ----------------------------------------------------------------

def ethernet_receive(levels):
    """One 10BASE-T frame from the pair, a sample every 25 ns, written from
    IEEE 802.3's description of the wire and not from the firmware. Each
    sample is (TD+, TD-): the two at the same level is idle, no voltage
    across the pair. A bit is four samples: low then high is a 1, high then
    low a 0. The frame
    ends where the pair stays high, for 250 to 450 ns, and must then be
    idle. Returns the frame without preamble, delimiter and frame check
    sequence; the sequence is checked with zlib's CRC-32."""
    high, low = (1, 0), (0, 1)
    start = next(t for t, v in enumerate(levels) if v[0] != v[1])
    bits, t = [], start
    while True:
        cell = levels[t:t + 4]
        if cell == [low, low, high, high]:
            bits.append(1)
        elif cell == [high, high, low, low]:
            bits.append(0)
        else:
            break
        t += 4
    held = 0
    while levels[t + held] == high:
        held += 1
    idle_ns = 25 * (held + (2 if bits and bits[-1] else 0))
    assert held > 0, f"the pair broke the code at sample {t}: {levels[t:t + 4]}"
    assert 250 <= idle_ns <= 450, f"start of idle lasted {idle_ns} ns, after {len(bits)} bits"
    assert all(v[0] == v[1] for v in levels[t + held:]), "the pair is not idle after the frame"
    assert len(bits) % 8 == 0, f"{len(bits)} bits is not a whole number of bytes"
    data = bytes(sum(b << k for k, b in enumerate(bits[n:n + 8])) for n in range(0, len(bits), 8))
    assert data[:8] == bytes([0x55] * 7 + [0xD5]), "bad preamble or start-of-frame delimiter"
    frame, fcs = data[8:-4], data[-4:]
    assert len(frame) + 4 >= 64, f"a frame of {len(frame) + 4} bytes is shorter than 64"
    assert int.from_bytes(fcs, "little") == zlib.crc32(frame), "frame check sequence is wrong"
    return frame


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_ethernet(dut):
    """10BASE-T Ethernet transmit at a 40 MHz clock: whole frames from the
    packet buffer, with the preamble, the Manchester code, the CRC-32 and
    the idle signal made on the chip. An ARP request, the same with one
    more byte (an odd length), and a frame of the largest size. Then the
    link pulses the chip sends between frames, with the time between them
    cut from 16 ms to 100 us so that a few go by."""
    await reset(dut, period_ps=25_000)
    chip = pe.Chip(sim_port(dut))
    arp = bytes.fromhex(
        "ffffffffffff" "02004e455431" "0806"  # to everyone, from a local address, ARP
        "0001" "0800" "06" "04" "0001"        # Ethernet, IPv4, request
        "02004e455431" "c0a80102" "000000000000" "c0a80101")
    rng = random.Random(8023)
    frames = [arp, arp + bytes(18) + b"\x5a", bytes(rng.randrange(256) for _ in range(1514))]
    levels = []

    async def watch():
        while True:
            await RisingEdge(dut.clk)
            out, oe = int(dut.uio_out.value), int(dut.uio_oe.value)
            levels.append(((out & oe) & 1, ((out & oe) >> 1) & 1))

    eth = None
    for frame in frames:
        @bridge
        def send():
            nonlocal eth
            eth = eth or more.EthernetTx(chip, firmware("eth_tx"))
            eth.send(frame)

        @bridge
        def sent():
            return eth.sent()

        watcher = cocotb.start_soon(watch())
        await send()
        # 8 bytes of preamble, the frame padded to 60, 4 of FCS; 32 clocks a byte.
        await ClockCycles(dut.clk, 32 * (max(len(frame), 60) + 12) + 64)
        assert await sent(), "the thread is not where a finished frame leaves it"
        watcher.kill()
        got = ethernet_receive(levels)
        want = frame + bytes(max(0, 60 - len(frame)))
        assert got == want, f"{len(frame)} bytes sent, {len(got)} received"
        levels.clear()

    @bridge
    def link_only():
        more.EthernetTx(chip, firmware("eth_tx"), link_ticks=400)

    await link_only()
    watcher = cocotb.start_soon(watch())
    await ClockCycles(dut.clk, 4 * 4030)
    watcher.kill()
    # A link pulse is TD+ high and TD- low for 100 ns, four clocks; the
    # rest of the time the pair is idle.
    pulses, t = [], 0
    while t < len(levels):
        if levels[t] == (1, 0):
            length = 1
            while t + length < len(levels) and levels[t + length] == (1, 0):
                length += 1
            pulses.append((t, length))
            t += length
        else:
            assert levels[t][0] == levels[t][1], f"TD+ low and TD- high between frames, clock {t}"
            t += 1
    assert len(pulses) >= 3, f"{len(pulses)} link pulses in {len(levels)} clocks"
    assert all(length == 4 for _, length in pulses), f"link pulses not 4 clocks long: {pulses}"
    gaps = [b[0] - a[0] for a, b in zip(pulses, pulses[1:])]
    assert all(4000 <= gap <= 4060 for gap in gaps), f"link pulses not 10 waits of 400 apart: {gaps}"


def ethernet_line(frame, start_ps, bit_ps=100_000, jitter_ps=0, rng=None, bad_fcs=False):
    """The times, in ps, at which a 10BASE-T pair changes level for one
    frame, starting low, written from IEEE 802.3's description of the wire:
    the preamble and delimiter, the frame, its frame check sequence from
    zlib's CRC-32, each bit a Manchester cell (a 1 is low then high), then
    the pair held high for three bit times. [bit_ps] is the sender's bit
    time, which is not the chip's, and every change is moved by up to
    [jitter_ps] either way."""
    fcs = zlib.crc32(frame) ^ (0x80 if bad_fcs else 0)
    sent = bytes([0x55] * 7 + [0xD5]) + frame + fcs.to_bytes(4, "little")
    halves = []
    for byte in sent:
        for k in range(8):
            bit = (byte >> k) & 1
            halves += [1 - bit, bit]
    halves += [1] * 6 + [0]
    times, level = [], 0
    for k, v in enumerate(halves):
        if v != level:
            level = v
            j = rng.randint(-jitter_ps, jitter_ps) if jitter_ps else 0
            times.append(start_ps + k * bit_ps // 2 + j)
    return times


@cocotb.test(timeout_time=80, timeout_unit="ms")
async def test_ethernet_receive(dut):
    """10BASE-T Ethernet receive at a 40 MHz clock. The pair is driven on
    pin 2 at times that have nothing to do with the chip's clock, from a
    sender whose own clock is 100 ppm off and whose edges are each up to
    5 ns early or late. The chip recovers the clock with samples on both
    clock edges, decodes the Manchester code, finds the start of each
    frame, runs the CRC-32 and records the frames. Four of them, 9.6 us
    apart: an ARP request, an odd length, the largest size, and one whose
    frame check sequence is wrong, which must be told apart."""
    await reset(dut, period_ps=25_000)
    chip = pe.Chip(sim_port(dut))
    arp = bytes.fromhex(
        "ffffffffffff" "02004e455431" "0806"
        "0001" "0800" "06" "04" "0001"
        "02004e455431" "c0a80102" "000000000000" "c0a80101") + bytes(18)
    rng = random.Random(8024)
    frames = [arp, arp + b"\x5a", bytes(rng.randrange(256) for _ in range(1514)), arp[::-1]]

    eth = None

    @bridge
    def listen():
        nonlocal eth
        eth = more.EthernetRx(chip, firmware("eth_rx"))
        eth.listen()

    @bridge
    def waiting():
        return eth.waiting()

    @bridge
    def read_back():
        return eth.frames()

    await listen()
    now = get_sim_time("ps")
    start = now + 20_000 + 7_301  # not on a clock edge
    times = []
    for n, frame in enumerate(frames):
        bit_ps = 100_010 if n % 2 == 0 else 99_990  # 100 ppm slow, then fast
        line = ethernet_line(frame, start, bit_ps=bit_ps, jitter_ps=5_000, rng=rng,
                             bad_fcs=(n == 3))
        times += line
        start = line[-1] + 9_600_000

    async def pair():
        level = 0
        for t in times:
            await Timer(t - get_sim_time("ps"), unit="ps")
            level ^= 1
            dut.uio_in.value = (int(dut.uio_in.value) & ~4) | (level << 2)

    await cocotb.start_soon(pair())
    await ClockCycles(dut.clk, 40)
    assert await waiting(), "the thread is not waiting for another frame"
    got = await read_back()
    want = [(f + zlib.crc32(f).to_bytes(4, "little"), True) for f in frames[:3]]
    bad = frames[3] + (zlib.crc32(frames[3]) ^ 0x80).to_bytes(4, "little")
    want.append((bad, False))
    assert len(got) == len(want), f"{len(got)} frames read back, {len(want)} sent"
    for n, (g, w) in enumerate(zip(got, want)):
        assert g[1] == w[1], f"frame {n}: CRC {'good' if g[1] else 'bad'}, should be the other"
        assert g[0] == w[0], f"frame {n}: {len(w[0])} bytes sent, {len(g[0])} read back, or they differ"


async def spi_device(dut, replies):
    """A device on the SPI controller's pins that answers each selection
    with the next string of bytes from [replies], most significant bit
    first, the first bit as CS_N falls and each next one as SCK falls: what
    a mode-0 device does. High when it has nothing left to say."""
    selections, was_cs, was_sck, bits = 0, 1, 0, []
    while True:
        await FallingEdge(dut.clk)  # mid-cycle: chip outputs have settled
        out, oe = int(dut.uio_out.value), int(dut.uio_oe.value)
        sck = out & oe & 1
        cs = (out >> 3) & 1 if (oe >> 3) & 1 else 1  # not selected until the chip drives it
        step = False
        if was_cs and not cs:
            data = replies[selections] if selections < len(replies) else b""
            selections += 1
            bits = [(byte >> k) & 1 for byte in data for k in range(7, -1, -1)]
            step = True
        elif not cs and was_sck and not sck:
            step = True
        if step:
            dut.uio_in.value = (int(dut.uio_in.value) & ~4) | ((bits.pop(0) if bits else 1) << 2)
        was_cs, was_sck = cs, sck


async def spi_device_session(dut, transfers):
    """Runs [transfers], each (bytes sent, bytes the device answers), on the
    SPI controller against [spi_device]. Returns the recorded pins and what
    the controller read back in each."""
    await reset(dut)
    dut.dev_mode.value = 0
    trace = sigrok.Trace(dut, {
        "sck": lambda: int(dut.uio_out.value) & 1,
        "mosi": lambda: (int(dut.uio_out.value) >> 1) & 1,
        "miso": lambda: (int(dut.uio_in.value) >> 2) & 1,
        "cs": lambda: (int(dut.uio_out.value) >> 3) & 1 if (int(dut.uio_oe.value) >> 3) & 1 else 1,
    })
    device = cocotb.start_soon(spi_device(dut, [bytes(reply) for _, reply in transfers]))
    chip = pe.Chip(sim_port(dut))

    @bridge
    def run():
        spi = pe.SpiController(chip, firmware("spi_fast"))
        return [bytes(spi.transfer(list(sent))) for sent, _ in transfers]

    read = await run()
    await ClockCycles(dut.clk, 500)
    trace.stop()
    device.kill()
    for (sent, reply), got in zip(transfers, read):
        want = bytes(reply) + bytes([0xFF] * (len(sent) - len(reply)))
        assert got == want, f"sent {bytes(sent).hex()}: read {got.hex()}, the device answered {want.hex()}"
    return trace


SPI_BUS = "spi:clk=sck:mosi=mosi:miso=miso:cs=cs"


def spi_judged(trace, decoder, want, damage, line):
    """sigrok's [decoder], stacked on its SPI decoder, must read [want] in
    the recording: every text, in that order. Then, with [line] held high
    for as long as the text [damage] spans, that text must be gone."""
    stack = SPI_BUS + "," + decoder
    found = trace.decode(stack, decoder)
    read = iter(texts(found))
    assert all(text in read for text in want), texts(found)
    spans = [(a, b) for a, b, text in found if text == damage]
    assert len(spans) == 1, f"{damage!r} read {len(spans)} times"
    a, b = spans[0]
    assert damage not in texts(trace.forced(line, a, b, 1).decode(stack, decoder)), damage


H = bytes.fromhex


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_nrf24l01(dut):
    """An nRF24L01 radio on the SPI controller: two registers set, a
    payload queued, a register read back, the transmit FIFO flushed.
    sigrok's nRF24L01 decoder must read each command, and the register the
    device answered with."""
    trace = await spi_device_session(dut, [
        (H("200e"), H("0e")), (H("254c"), H("0e")), (H("a0deadbeef"), H("0e")),
        (H("05ff"), H("0e4c")), (H("e1"), H("0e"))])
    if sigrok.available():
        spi_judged(trace, "nrf24l01",
                   ['Cmd W_REGISTER: CONFIG = "0E"', 'Cmd W_REGISTER: RF_CH = "4C"', 'Cmd W_TX_PAYLOAD',
                    'Cmd R_REGISTER "RF_CH"', 'Reg RF_CH = "4C"', 'Cmd FLUSH_TX'],
                   damage='Reg RF_CH = "4C"', line="miso")


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_cc1101(dut):
    """A CC1101 sub-GHz radio on the SPI controller: a reset strobe, the
    channel register written and read back, a no-operation strobe. sigrok's
    CC1101 decoder must read all four, with the status byte the device
    returns each time."""
    trace = await spi_device_session(dut, [
        (H("30"), H("0f")), (H("0a05"), H("0f0f")), (H("8a00"), H("0f05")), (H("3d"), H("0f"))])
    if sigrok.available():
        spi_judged(trace, "cc1101",
                   ["Strobe SRES", "Status = 0F; STATE is IDLE, 15 bytes free in TX FIFO",
                    "Write: CHANNR (0A) = 05", "Read: CHANNR (0A) = 05", "Strobe SNOP"],
                   damage="Write: CHANNR (0A) = 05", line="mosi")


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_adf435x(dut):
    """An ADF4350 synthesiser on the SPI controller: 32-bit register
    writes, latched as the select line rises. sigrok's ADF435x decoder must
    read the fields of registers 5 and 4; it shows a write once the next
    one begins, so a third follows."""
    trace = await spi_device_session(dut, [(H("00580005"), b""), (H("008c803c"), b""), (H("000004b3"), b"")])
    if sigrok.available():
        spi_judged(trace, "adf435x",
                   ["Register: 5", "LD Pin Mode: Digital Lock Detect", "Register: 4", "Output Power: +5dBm",
                    "Output Enable: Enabled", "Band Select Clock Divider: 200", "RF Divider Select: ÷1"],
                   damage="Band Select Clock Divider: 200", line="mosi")


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_enc28j60(dut):
    """An ENC28J60 Ethernet controller on the SPI controller: a system
    reset, a control register written, read back, and one of its bits set.
    sigrok's ENC28J60 decoder must read each command and the value the
    device returned."""
    trace = await spi_device_session(dut, [
        (H("ff"), b""), (H("5f03"), b""), (H("1f00"), H("ff05")), (H("9f80"), b"")])
    if sigrok.available():
        spi_judged(trace, "enc28j60",
                   ["System Reset Command", "Write Control Register", "Reg ECON1", "Data 0x03",
                    "Read Control Register", "Reg ECON1", "Data 0x05", "Bit Field Set", "Reg ECON1",
                    "Data 0b10000000"],
                   damage="Data 0x05", line="miso")


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_mrf24j40(dut):
    """An MRF24J40 802.15.4 radio on the SPI controller: a short-address
    register written, another read, and a long-address register written.
    sigrok's MRF24J40 decoder must read all three, and what the status
    register's bits mean."""
    trace = await spi_device_session(dut, [(H("3701"), b""), (H("4800"), H("ff20")), (H("c01003"), b"")])
    if sigrok.available():
        spi_judged(trace, "mrf24j40",
                   ["TXNCON: 0x1", "TXSTAT: 0x20", "CCAFAIL (channel busy)", "RFCON0: 0x3"],
                   damage="TXSTAT: 0x20", line="miso")


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_sd_card(dut):
    """An SD card in SPI mode on the SPI controller: the first two commands
    of every initialisation, CMD0 and CMD8, each answered by the card with
    "idle". sigrok's SD card decoder must read the commands, their
    arguments and CRCs, and the card's answers."""
    trace = await spi_device_session(dut, [
        (H("400000000095ffff"), H("ffffffffffffff01")),
        (H("48000001aa87ffffffffffff"), H("ffffffffffffff01000001aa"))])
    if sigrok.available():
        spi_judged(trace, "sdcard_spi",
                   ["Command: CMD0 (GO_IDLE_STATE)", "CRC7: 0x4a", "R1: 0x01", "Card is in idle state",
                    "Command: CMD8 (SEND_IF_COND)", "Argument: 0x01aa", "CRC7: 0x43", "R1: 0x01"],
                   damage="Argument: 0x01aa", line="mosi")


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_rfm12(dut):
    """An RFM12 radio module on the SPI controller: its 16-bit
    configuration, power and frequency commands, and a status read.
    sigrok's RFM12 decoder must read the band and the crystal load the
    configuration command sets."""
    trace = await spi_device_session(dut, [
        (H("80e7"), b""), (H("8209"), b""), (H("a640"), b""), (H("0000"), H("4000"))])
    if sigrok.available():
        spi_judged(trace, "rfm12",
                   ["Configuration command", "Frequency: 868MHz", "Capacitance: 12.0pF", "Power management",
                    "Frequency setting"],
                   damage="Frequency: 868MHz", line="mosi")


class AvrIsp:
    """An ATmega168 at 16 MHz, as its serial programming interface is
    described in its datasheet. While RESET is low it takes MOSI as SCK
    rises and shifts MISO out as SCK falls, MSB first. Instructions are
    four bytes, counted from the fall of RESET. Its shift register echoes
    each byte one byte later, except that a read instruction's answer
    takes the place of the fourth. Programming Enable (AC 53) is taken only
    20 ms or more after RESET falls, and the other instructions only once
    programming is enabled. MISO floats (high here) while RESET is high."""

    SIGNATURE = (0x1E, 0x94, 0x06)
    FUSES = {(0x50, 0x00): 0x62, (0x58, 0x08): 0xDF, (0x50, 0x08): 0xF9}  # as shipped

    def __init__(self, dut):
        self.dut, self.miso, self.was_reset, self.was_sck = dut, 1, 1, 0
        self.log, self.widths = [], []  # instructions taken; SCK's high and low times, ns

    def _answer(self, cmd):
        """The byte that replaces the echo in a read instruction's fourth."""
        if not self.enabled:
            return None
        if cmd[0] == 0x30:
            return self.SIGNATURE[cmd[2] & 3]
        return self.FUSES.get((cmd[0], cmd[1]))

    async def run(self):
        """Watches the pins; nothing is lost if it is stopped while they
        stand still and started again."""
        dut = self.dut
        while True:
            await FallingEdge(dut.clk)  # mid-cycle: chip outputs have settled
            now = get_sim_time("ns")
            out, oe = int(dut.uio_out.value), int(dut.uio_oe.value)
            sck, mosi = out & oe & 1, (out & oe) >> 1 & 1
            reset = (out >> 4) & 1 if (oe >> 4) & 1 else 1  # a pull-up on RESET
            if self.was_reset and not reset:
                self.fell, self.enabled, self.edge = now, False, None
                self.cmd, self.shift, self.bits, self.out, self.started = [], 0, 0, 0x00, None
                self.miso = self.out >> 7
            if reset:
                self.miso = 1
            elif sck != self.was_sck:
                if self.edge is not None:
                    self.widths.append(now - self.edge)
                self.edge = now
                if sck:
                    self.shift, self.bits = ((self.shift << 1) | mosi) & 0xFF, self.bits + 1
                    if self.started is None:
                        self.started = now
                else:
                    if self.bits == 8:
                        self.cmd.append(self.shift)
                        self.out, self.bits = self.shift, 0
                        if len(self.cmd) == 3 and self._answer(self.cmd) is not None:
                            self.out = self._answer(self.cmd)
                        if len(self.cmd) == 4:
                            if self.cmd[:2] == [0xAC, 0x53]:
                                self.enabled = self.started - self.fell >= 20_000_000  # 20 ms
                            self.log.append((bytes(self.cmd).hex(), self.enabled))
                            self.cmd, self.started = [], None
                    self.miso = (self.out >> (7 - self.bits)) & 1
            dut.uio_in.value = (int(dut.uio_in.value) & ~4) | (self.miso << 2)
            self.was_reset, self.was_sck = reset, sck


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_avr_isp(dut):
    """An ATmega168 programmed in system over the SPI controller, as
    avrdude begins: RESET held low, 20 ms waited, Programming Enable, the
    three signature bytes and the three fuse bytes read. SCK runs at 900
    kHz on the controller with a half-period word, as a 16 MHz part needs
    SCK high and low for more than three of its clocks. RESET is pin 4,
    which every MOV of the firmware holds low once OUT spans four pins;
    letting it go ends the session. sigrok's AVR ISP decoder must name the
    part from its signature and read each fuse. (The 20 ms, in which the
    pins stand still, are left out of the recording.)"""
    clock = await reset(dut)
    dut.dev_mode.value = 0
    avr = AvrIsp(dut)
    running = cocotb.start_soon(avr.run())
    chip = pe.Chip(sim_port(dut))
    spi_pins = {0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 3: pe.PUSH_PULL}
    commands = [H("ac530000"), H("30000000"), H("30000100"), H("30000200"),
                H("50000000"), H("58080000"), H("50080000")]

    @bridge
    def hold_reset():
        chip.stop()
        chip.load(firmware("spi_controller"))
        # MOV writes pins 1 to 4: MOSI, MISO's unused output, CS_N, RESET.
        chip.configure(set_base=0, set_count=1, out_base=1, out_count=4, in_base=2)
        chip.set_pin_modes({**spi_pins, 4: pe.PUSH_PULL})
        chip.run()
        chip.push(1)  # H = 1: 11 cycles a bit, SCK high 5 and low 6

    @bridge
    def program():
        replies = []
        for cmd in commands:  # each its own selection; CS_N goes nowhere
            for i, b in enumerate(cmd):
                chip.push(pe.rev8(b) | (int(i == 3) << 8))
            replies.append(bytes(pe.rev8(chip.pop() & 0xFF) for _ in cmd))
        chip.set_pin_modes(spi_pins)  # RESET let go: the part runs again
        return replies

    await hold_reset()
    await ClockCycles(dut.clk, 20)
    assert avr.was_reset == 0, "RESET is not held low"
    # Nothing moves on the pins for 20 ms: the chip's clock is stopped
    # meanwhile, which only spares the simulator.
    running.cancel()
    clock.stop()
    await Timer(20, unit="ms")
    clock.start()
    running = cocotb.start_soon(avr.run())
    trace = sigrok.Trace(dut, {
        "sck": lambda: int(dut.uio_out.value) & int(dut.uio_oe.value) & 1,
        "mosi": lambda: (int(dut.uio_out.value) >> 1) & 1,
        "miso": lambda: (int(dut.uio_in.value) >> 2) & 1,
        "reset": lambda: (int(dut.uio_out.value) >> 4) & 1 if (int(dut.uio_oe.value) >> 4) & 1 else 1,
    })
    replies = await program()
    await ClockCycles(dut.clk, 200)
    trace.stop()
    running.cancel()
    assert avr.log == [(c.hex(), True) for c in commands], avr.log
    assert min(avr.widths) >= 200, min(avr.widths)  # ns: over three clocks at 16 MHz
    # The echo of each byte in the next, and the answers in the fourth.
    assert replies == [H("00ac5300"), H("0030001e"), H("00300094"), H("00300006"),
                       H("00500062"), H("005808df"), H("005008f9")], [r.hex() for r in replies]
    if sigrok.available():
        decoder = "spi:clk=sck:mosi=mosi:miso=miso:cs=reset,avr_isp"
        found = trace.decode(decoder, "avr_isp")
        want = ["Programming enable", "Vendor code: 0x1e (Atmel)", "Part family / memory size: 0x94",
                "Part number: 0x06", "Device: Atmel ATmega168", "Read fuse bits: 0x62",
                "Read fuse high bits: 0xdf", "Read extended fuse bits: 0xf9"]
        assert texts(found) == want, texts(found)
        # MISO held high through the low fuse's instruction: not 0x62.
        a, b = next((a, b) for a, b, text in found if text == "Read fuse bits: 0x62")
        wrong = texts(trace.forced("miso", a, b, 1).decode(decoder, "avr_isp"))
        assert "Read fuse bits: 0x62" not in wrong and "Read fuse bits: 0xff" in wrong, wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_ws2812(dut):
    """The WS2812 driver that was written blind (examples/ws2812), on the
    chip, with its own host-side encoder: two LEDs' colours. sigrok's WS281x
    decoder must read both from the pin."""
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "ws2812_host", os.path.join(os.path.dirname(__file__), "..", "examples", "ws2812", "host.py"))
    encoder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(encoder)
    await reset(dut)
    # The strip's data input has no pull-up: low until the chip drives it.
    trace = sigrok.Trace(dut, {"din": lambda: int(dut.uio_out.value) & int(dut.uio_oe.value) & 1})
    chip = pe.Chip(sim_port(dut))
    leds = [(0xFF, 0x80, 0x00), (0x00, 0x40, 0xFF)]  # red, green, blue each

    @bridge
    def light():
        chip.stop()
        chip.load(firmware("ws2812"))
        chip.configure(start=5, sideset_base=0, sideset_count=1, threshold=16, out_msb_first=True)
        # The whole frame queued before the thread starts, so no bit waits
        # on the host; the pin made an output once the thread holds it low.
        for word in encoder.encode([leds]):
            chip.push(word)
        chip.run()
        chip.set_pin_modes({0: pe.PUSH_PULL})

    await light()
    await ClockCycles(dut.clk, 8000)
    trace.stop()
    if sigrok.available():
        def colours(found):
            return [text for text in texts(found) if text.startswith("#")]

        found = trace.decode("rgb_led_ws281x:din=din", "rgb_led_ws281x")
        assert colours(found) == ["#ff8000", "#0040ff"], texts(found)
        # The line held high through one bit time of the second LED: not
        # its colour.
        a, b = next((a, b) for a, b, text in found if text == "#0040ff")
        wrong = colours(trace.forced("din", a + 26, a + 39, 1).decode("rgb_led_ws281x:din=din", "rgb_led_ws281x"))
        assert wrong[:1] == ["#ff8000"] and "#0040ff" not in wrong, wrong


# --- Step and direction, a sensor's pulse lengths, audio frames, a DAC ----------

@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_stepper_motor(dut):
    """Step and direction for a stepper driver: a ramp up to speed and back
    down, then a move the other way. Every step must be exactly its period
    after the last, STEP high for two ticks, and DIR settled before the
    first. sigrok's stepper motor decoder follows the position and the
    speed from the two wires."""
    await reset(dut)
    trace = pin_trace(dut, step=0, dir=1)
    chip = pe.Chip(sim_port(dut))
    moves = [(3, 400), (6, 100), (3, 400), (-5, 250)]  # steps, microseconds each

    @bridge
    def play():
        motor = extra.Stepper(chip, firmware("stepper"))
        motor.ramp(moves[:3])
        motor.move(*moves[3])
        return motor.position

    position = await play()
    await ClockCycles(dut.clk, 2_000)
    trace.stop()
    assert position == 7, position
    at = dict(trace.changes)
    step = trace.level("step")
    rises = [t for t, v in step if v == 1][1:]  # [0]: before the pin drives
    falls = [t for t, v in step if v == 0]
    assert {f - r for r, f in zip(rises, falls[1:])} == {20}, "STEP high for two ticks of 1 us"
    names = trace.names
    dirs = [dict(zip(names, at[max(k for k in at if k <= t)]))["dir"] for t in rises]
    assert dirs == [1] * 12 + [0] * 5, dirs
    # Each step its period after the last; a move's first comes six ticks
    # after the last period of the move before has run out.
    want = []
    for i, (n, period) in enumerate(moves):
        want += [period * 10] * (abs(n) - 1)
        if i < len(moves) - 1:
            want.append((period + 6) * 10)
    got = [b - a for a, b in zip(rises, rises[1:])]
    # The host fetches the report before it sends the last move: that gap
    # is the host's.
    assert got[:11] == want[:11] and got[12:] == want[12:], (got, want)
    assert got[11] >= want[11]
    dir_falls = [t for t, v in trace.level("dir") if v == 0]
    # DIR three ticks ahead of the first step, or more: the period comes
    # in the host's second word.
    assert rises[12] - dir_falls[-1] >= 30
    if sigrok.available():
        found = texts(trace.decode("stepper_motor", start=rises[0] - 100))
        positions = [t for t in found if t.endswith(" steps")]
        speeds = [t for t in found if t.endswith(" steps/s")]
        # The decoder writes the position reached at each step when the
        # next one comes.
        up = [f"{k} steps" for k in range(1, 13)]
        down = [f"{k} steps" for k in range(11, 7, -1)]
        assert positions == up + down, positions
        assert speeds[:2] == ["2500 steps/s"] * 2 and speeds[3:8] == ["10000 steps/s"] * 5, speeds
        assert speeds[-4:] == ["4000 steps/s"] * 4, speeds
        # DIR held the other way through the ramp: not those positions.
        wrong = texts(trace.forced("dir", rises[4] - 5, rises[8] - 5, 0)
                      .decode("stepper_motor", start=rises[0] - 100))
        assert [t for t in wrong if t.endswith(" steps")] != positions


class Am2302:
    """An AM2302 on pin 0, from its datasheet: after the host has held the
    line low for 0.8 ms or more and let go, it waits [go] us, answers with
    80 us low and 80 us high, and sends 40 bits, each 50 us low and then
    high for 26 us (a 0) or 70 us (a 1); 50 us low ends them. [present]
    False: it never answers."""

    def __init__(self, dut, humidity, temperature, go=30, present=True):
        self.dut, self.go, self.present = dut, go, present
        data = [humidity >> 8, humidity & 0xFF, temperature >> 8, temperature & 0xFF]
        data.append(sum(data) & 0xFF)
        self.bits = [(b >> k) & 1 for b in data for k in range(7, -1, -1)]
        self.low = 0  # whether the sensor holds the line low
        self.starts = []

    def line(self):
        chip_low = bool(int(self.dut.uio_oe.value) & 1) and not int(self.dut.uio_out.value) & 1
        return 0 if chip_low or self.low else 1

    async def _hold(self, low, us):
        self.low = low
        for _ in range(us):  # the chip reads its own pin: keep it right
            drive_pin(self.dut, 0, self.line())
            await ClockCycles(self.dut.clk, 10)

    async def run(self):
        dut = self.dut
        while True:
            low_for = 0
            while True:
                await ClockCycles(dut.clk, 10)
                now = self.line()
                drive_pin(dut, 0, now)
                if now:
                    if low_for:
                        break
                else:
                    low_for += 1
            self.starts.append(low_for)
            if low_for < 800 or not self.present:
                continue
            await self._hold(0, self.go)
            await self._hold(1, 80)
            await self._hold(0, 80)
            for b in self.bits:
                await self._hold(1, 50)
                await self._hold(0, 70 if b else 26)
            await self._hold(1, 50)
            await self._hold(0, 1)


@cocotb.test(timeout_time=100, timeout_unit="ms")
async def test_dht22_sensor(dut):
    """The AM2302 / DHT22 reader: a sensor written from the datasheet sends
    65.2 % and -10.1 degrees, and the host must get exactly those; then the
    sensor is taken away, and the host must be told so rather than given a
    reading. sigrok's AM230x decoder reads the same wire: the start pulse
    must be one it accepts, and it must find the same two values."""
    await reset(dut)
    dut.dev_mode.value = 0
    dut.uio_in.value = 0xFF
    sensor = Am2302(dut, humidity=652, temperature=0x8000 | 101)
    running = cocotb.start_soon(sensor.run())
    trace = sigrok.Trace(dut, {"sda": sensor.line})
    chip = pe.Chip(sim_port(dut))
    dht = []

    @bridge
    def read():
        dht.append(extra.Dht(chip, firmware("dht")))
        return dht[0].read()

    @bridge
    def read_again():
        try:
            return dht[0].read()
        except extra.DhtError as e:
            return str(e)

    got = await read()
    await ClockCycles(dut.clk, 5_000)
    sensor.present = False
    again = await read_again()
    trace.stop()
    running.cancel()
    assert got == (65.2, -10.1), got
    assert again == "the sensor stopped answering", again
    assert len(sensor.starts) == 2 and all(1250 <= s <= 1350 for s in sensor.starts), sensor.starts  # us
    if sigrok.available():
        found = trace.decode("am230x")
        results = lambda found: [t for t in texts(found)
                                 if t.startswith(("Humidity", "Temperature", "Checksum"))]
        want = ["Humidity: 65.2 %", "Temperature: -10.1 °C", "Checksum: OK"]
        assert results(found) == want, results(found)
        # A 1's high cut to 30 us on the wire: a different reading, and the
        # checksum says so.
        a, b = next((a, b) for a, b, text in found if text == "Bit: 1")
        wrong = results(trace.forced("sda", b - 400, b, 0).decode("am230x"))
        assert wrong != want and "Checksum: not OK" in wrong, wrong


@cocotb.test(timeout_time=300, timeout_unit="ms")
async def test_qi_packets(dut):
    """Qi: the packets a phone sends its charger, on the level stream
    sender: a signal strength packet and one of four bytes, which end with
    the line at different levels. Every time between changes of the line
    must be a half bit or a whole one, exactly; sigrok's Qi decoder reads
    the bytes, their parities and the checksums."""
    await reset(dut)
    trace = pin_trace(dut, qi=0)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        qi = extra.Qi(chip, firmware("bitstream"))
        qi.send(0x01, [0x80])
        qi.send(0x28, [0x12, 0x34])
        qi.flush()

    await play()
    await ClockCycles(dut.clk, 60_000)
    trace.stop()
    edges = [t for t, _ in trace.level("qi")][2:]  # [0], [1]: before the pin drives, and its first low
    gaps = [b - a for a, b in zip(edges, edges[1:])]
    # 250 us and 500 us; after each packet a rest of two bit times or more.
    assert {g for g in gaps if g < 10_000} == {2500, 5000}, sorted(set(gaps))
    assert len([g for g in gaps if g >= 10_000]) == 2, sorted(set(gaps))
    if sigrok.available():
        fields = lambda found: [t for t in texts(found) if len(t) > 2 and "bit" not in t]
        found = trace.decode("qi")
        want = ["01", "80", "81", "Signal Strength: 128", "Checksum OK",
                "28", "12", "34", "0e", "Proprietary", "Checksum OK"]
        assert [t for t in texts(found) if "err" in t.lower()] == [], texts(found)
        got = [t for t in texts(found) if t in want or "Checksum" in t or ":" in t]
        assert got == want, got
        # The line held low for one bit time of the message byte, across
        # the change that starts a bit: not that packet.
        a, b = next((a, b) for a, b, text in found if text == "80")
        wrong = texts(trace.forced("qi", a + 6250, a + 11_250, 0).decode("qi"))
        assert "Signal Strength: 128" not in wrong, wrong


@cocotb.test(timeout_time=300, timeout_unit="ms")
async def test_em4100_tag(dut):
    """An EM4100 tag's 64 bits, twice over, on the level stream sender, at
    64 periods of a 125 kHz field to a bit. sigrok's EM4100 decoder, like a
    reader, uses the first pass to find where a bit begins and reads the
    second: there it must find the header, every row and column parity
    right, and the tag's number."""
    await reset(dut)
    trace = pin_trace(dut, data=0)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        tag = extra.Em4100(chip, firmware("bitstream"))
        tag.send(0x06, 0x001259E3, repeats=2)
        tag.flush()

    await play()
    await ClockCycles(dut.clk, 60_000)
    trace.stop()
    edges = [t for t, _ in trace.level("data")][2:]
    gaps = {b - a for a, b in zip(edges, edges[1:])}
    assert gaps == {2560, 5120}, gaps  # half a bit and a whole one: 256 us, 512 us
    # From EM4100's rules, worked out here: nine ones, ten rows of four
    # bits and their parity, four column parities, a 0; a 1 high then low.
    rows = [[(n >> k) & 1 for k in (3, 2, 1, 0)] for n in (0, 6, 0, 0, 1, 2, 5, 9, 0xE, 3)]
    bits = ([1] * 9 + [b for r in rows for b in r + [sum(r) % 2]]
            + [sum(r[k] for r in rows) % 2 for k in range(4)] + [0])
    want = "".join("10" if b else "01" for b in bits) * 2
    changes = trace.level("data")
    level_at = lambda t: [v for at, v in changes if at <= t][-1]
    got = "".join(str(level_at(edges[0] + 1280 + 2560 * k)) for k in range(256))
    assert got == want
    if sigrok.available():
        found = trace.decode("em4100")
        tags = lambda found: [t for t in texts(found) if t.startswith("Tag")]
        assert tags(found) == ["Tag: 06001259E3"], tags(found)
        start = next(a for a, b, text in found if text.startswith("Tag"))
        assert [t for a, b, t in found if "ERROR" in t and a >= start] == [], texts(found)
        fields = [t for a, b, t in found if a >= start and t.startswith(("Version", "Data"))]
        assert fields == ["Version/customer: 0", "Version/customer: 6"] + [
            f"Data: {d}" for d in "001259E3"], fields
        # The line held low for two bit times of the number: no tag.
        a = next(a for a, b, t in found if a >= start and t == "Data: 5")
        wrong = trace.forced("data", a, a + 10_240, 0).decode("em4100")
        assert tags(wrong) == [], tags(wrong)


@cocotb.test(timeout_time=300, timeout_unit="ms")
async def test_morse(dut):
    """Morse code on the level stream sender, a dot of 0.5 ms: sigrok's
    Morse decoder must read the letters and the words."""
    await reset(dut)
    trace = pin_trace(dut, data=0)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        key = extra.Morse(chip, firmware("bitstream"), unit_ms=0.5)
        key.send("sos pe 73")
        key.flush()

    await play()
    await ClockCycles(dut.clk, 120_000)
    trace.stop()
    level = trace.level("data")[2:]  # [0], [1]: before the pin drives, and its first low
    marks = [(b[0] - a[0]) // 5000 for a, b in zip(level, level[1:]) if a[1] == 1]
    assert all((b[0] - a[0]) % 5000 == 0 for a, b in zip(level, level[1:]))
    # s o s  p e  7 3
    assert marks == [1, 1, 1, 3, 3, 3, 1, 1, 1, 1, 3, 3, 1, 1, 3, 3, 1, 1, 1, 1, 1, 1, 3, 3], marks
    if sigrok.available():
        decoder = "morse:timeunit=0.0005"
        found = texts(trace.decode(decoder, "morse=word"))
        assert found == ["sos", "pe", "73"], found
        # A dash of the o cut to a dot: not sos.
        start = level[6][0]  # the o's first dash
        assert level[6][1] == 1 and level[7][0] - start == 15_000
        wrong = texts(trace.forced("data", start + 5000, start + 15_000, 0).decode(decoder, "morse=word"))
        assert wrong and wrong[0] != "sos", wrong


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_tdm_audio(dut):
    """TDM audio: frames of four 16-bit samples on one data line, with a
    frame sync pulse one bit ahead of each frame. sigrok's TDM decoder
    reads the three wires and must give every sample to its slot."""
    await reset(dut)
    trace = pin_trace(dut, clock=0, frame=1, data=2)
    chip = pe.Chip(sim_port(dut))
    frames = [[0x8001, 0x1234, 0xFFFF, 0x0000], [0xA5A5, 0x5A5A, 0x7FFE, 0xC003]]

    @bridge
    def play():
        # A last frame of silence clocks out the one before.
        extra.TdmTx(chip, firmware("tdm_tx"), slots=4, clkdiv=4).write(frames + [[0] * 4])

    await play()
    await ClockCycles(dut.clk, 3_000)
    trace.stop()
    clock = trace.level("clock")
    rises = [t for t, v in clock if v == 1][1:]  # [0]: before the pin drives
    at = dict(trace.changes)
    seen = [dict(zip(trace.names, at[max(k for k in at if k <= t)])) for t in rises]
    syncs = [i for i, s in enumerate(seen) if s["frame"]]
    assert [b - a for a, b in zip(syncs, syncs[1:])] == [64, 64], syncs
    bits = [s["data"] for s in seen[syncs[0] + 1:]]
    words = [int("".join(map(str, bits[k:k + 16])), 2) for k in range(0, 128, 16)]
    assert words == frames[0] + frames[1], [hex(w) for w in words]
    if sigrok.available():
        decoder = "tdm_audio:bps=16:channels=4"
        found = trace.decode(decoder)
        want = [f"Channel {k + 1}: {s:04x}" for f in frames for k, s in enumerate(f)]
        assert texts(found)[:8] == want, texts(found)
        # A bit of the second sample held high on the wire: not that sample.
        a, b = found[1][0], found[1][1]
        wrong = texts(trace.forced("data", a, a + (b - a) // 4, 1).decode(decoder))
        assert wrong[1] != want[1] and wrong[0] == want[0], wrong[:3]


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_tlc5620_dac(dut):
    """The TLC5620 quad DAC: four writes whose outputs must change
    together, then one output changed by itself. sigrok's TLC5620 decoder
    reads CLK, DATA, LOAD and LDAC: it must name each DAC, gain and value,
    and report the voltages at each LDAC pulse."""
    await reset(dut)
    trace = pin_trace(dut, clk=0, data=1, load=2, ldac=3)
    chip = pe.Chip(sim_port(dut))
    writes = [(0, 64, False, False), (1, 128, True, False), (2, 255, False, False),
              (3, 1, True, True), (2, 0, False, True)]

    @bridge
    def play():
        dac = extra.Tlc5620(chip, firmware("tlc5620"), clkdiv=2)
        for d, value, double, update in writes:
            dac.write(d, value, double=double, update=update)

    await play()
    await ClockCycles(dut.clk, 500)
    trace.stop()
    # LOAD and LDAC low for three ticks, never together, never with CLK high.
    for name in ("load", "ldac"):
        level = trace.level(name)
        lows = [b[0] - a[0] for a, b in zip(level, level[1:]) if a[1] == 0]
        assert lows == [6] * (5 if name == "load" else 2), (name, lows)
    if sigrok.available():
        decoder = "tlc5620:clk=clk:data=data:load=load:ldac=ldac"
        found = trace.decode(decoder)
        volts = lambda value, double: "%.2fV" % (3.3 * (value / 256) * (2 if double else 1))
        want_fields, want_sets = [], []
        for d, value, double, update in writes:
            want_fields += [f"DAC select: DAC{'ABCD'[d]}", f"Gain: x{2 if double else 1}",
                            f"DAC value: {value}"]
            want_sets.append(f"Setting DAC{'ABCD'[d]} register value to {volts(value, double)}")
        fields = lambda found: [t for t in texts(found) if t.startswith(("DAC select", "Gain", "DAC value"))]
        assert fields(found) == want_fields, fields(found)
        assert [t for t in texts(found) if t.startswith("Setting")] == want_sets, texts(found)
        updates = [t for t in texts(found) if t.startswith("Updating")]
        assert updates == [
            "Updating voltages: DACA=%s DACB=%s DACC=%s DACD=%s"
            % (volts(64, False), volts(128, True), volts(255, False), volts(1, True)),
            "Updating voltages: DACA=%s DACB=%s DACC=%s DACD=%s"
            % (volts(64, False), volts(128, True), volts(0, False), volts(1, True)),
        ], updates
        assert [t for t in texts(found) if "too short" in t] == [], texts(found)
        # DATA held high through the first write: not DAC A at 64.
        a = next(a for a, b, text in found if text == "DAC select: DACA")
        wrong = fields(trace.forced("data", a - 50, a + 200, 1).decode(decoder))
        assert wrong[:3] != want_fields[:3], wrong[:3]
