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

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge, RisingEdge

HALF = 6  # core clocks per SCK phase (must be >= 4)

CTRL, PIN_MODES, TX_FIFO, RX_FIFO, STATUS = 0x40, 0x47, 0x48, 0x49, 0x4A
FIFO_DEPTH = 4

HERE = os.path.dirname(os.path.abspath(__file__))


def firmware(name):
    with open(os.path.join(HERE, name + ".hex")) as f:
        return [int(line, 16) for line in f if line.strip()]


def drive(dut, sck, cs_n, mosi):
    dut.ui_in.value = sck | (cs_n << 1) | (mosi << 2)


async def reset(dut):
    cocotb.start_soon(Clock(dut.clk, 100, unit="ns").start())  # 10 MHz
    dut.ena.value = 1
    drive(dut, 0, 1, 0)
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 4)


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
    def __init__(self, address, stretch):
        self.address, self.stretch = address, stretch
        self.state, self.bits, self.shift = "idle", 0, 0
        self.first = True
        self.stretch_left = 0
        self.prev = (1, 1)
        self.received = []

    def drive(self):
        """(pull SDA low, pull SCL low) for this cycle."""
        return self.state == "ack", self.stretch_left > 0

    def step(self, sda, scl):
        psda, pscl = self.prev
        if self.stretch_left:
            self.stretch_left -= 1
        if pscl and scl and sda != psda:
            if sda == 0:
                self.state, self.bits, self.shift, self.first = "rx", 0, 0, True
            else:
                self.state = "idle"
        elif self.state == "rx" and not pscl and scl:
            self.shift = ((self.shift << 1) | sda) & 0xFF
            self.bits += 1
        elif self.state == "rx" and self.bits == 8 and pscl and not scl:
            if self.first:
                ok = (self.shift >> 1) == self.address and not (self.shift & 1)
                self.state = "ack" if ok else "ignore"
            else:
                self.received.append(self.shift)
                self.state = "ack"
        elif self.state == "ack" and pscl and not scl:
            self.state, self.bits, self.shift, self.first = "rx", 0, 0, False
            self.stretch_left = self.stretch
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
