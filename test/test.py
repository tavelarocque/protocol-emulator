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


async def reset(dut, period_ps=100_000):
    cocotb.start_soon(Clock(dut.clk, period_ps, unit="ps").start())  # 10 MHz by default
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
I2C_STUCK = 18  # Firmware.i2c_stuck; checked by the OCaml tests


async def configure_i2c(dut, bank=0, clkdiv=3):
    await write(dut, OUT_CFG + bank, 0x10)  # OUT: SDA (P0), 1 pin
    await write(dut, SET_CFG + bank, 0x10)  # SET: SDA (P0), 1 pin
    await write(dut, IN_BASE + bank, 0)
    await write(dut, SIDESET + bank, 0x11)  # side-set: SCL (P1), 1 bit
    await write(dut, TIMEOUT_VECTOR + bank, I2C_STUCK)
    await write(dut, TIMEOUT + bank, 10000)
    await write(dut, CLKDIV + bank, clkdiv)


def i2c_write_word(b, stop):
    return rev8(b) | (1 << 8) | (int(stop) << 9)


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

BRIDGE_SPI_ORIGIN = 25  # Firmware.Bridge.spi_origin; checked by the OCaml tests


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

from cocotbext.i2c import I2cMaster, I2cMemory
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
import protocol_emulator as pe  # noqa: E402

try:
    from cocotb import bridge, resume  # noqa: E402
except ImportError:  # cocotb 2.0 exposes them only inside a running simulation
    from cocotb._bridge import bridge, resume  # noqa: E402


def sim_port(dut):
    @resume
    async def set_pins(sck, cs_n, mosi):
        drive(dut, sck, cs_n, mosi)
        await ClockCycles(dut.clk, HALF)

    @resume
    async def read_miso():
        return int(dut.uo_out.value) & 1

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
    assert silent, "the target answered before the JTAG-to-SWD switch"
    assert dpidr == SWD_DPIDR, f"DPIDR {dpidr:#x}"
    assert ctrl == 0xF0000000, f"CTRL/STAT {ctrl:#x}"  # both requests acknowledged
    assert idr == SWD_AP_IDR, f"AP IDR {idr:#x}"
    assert (posted, tar) == (SWD_AP_IDR, 0xDEADBEEF), f"posted {posted:#x}, RDBUFF {tar:#x}"
    assert int(dut.dp.parity_errors.value) == 0


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


DRIVER_BUGS = [
    ("pin modes packed one bit per pin", pe.Chip, "set_pin_modes",
     lambda _: _pin_modes_one_bit_per_pin, _flash_read_ok),
    ("JTAG TMS and TDI swapped", pe.JtagController, "scan",
     _make_scan_swapped, _jtag_idcode_ok),
    ("SWD request parity inverted", pe.SwdController, "_request",
     lambda _: _make_request_bad_parity(pe.SwdController._request), _swd_power_up_ok),
    ("SWD write turnaround missing", pe.SwdController, "_transfer",
     lambda _: _transfer_no_write_turnaround, _swd_power_up_ok),
]


@cocotb.test(timeout_time=300, timeout_unit="ms")
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


async def usb_start(dut):
    """Chip at 12 MHz, the device at 48 MHz on the bus; returns once the
    device has connected (its pull-up on D-)."""
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


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_usb_device_acks_setup(dut):
    """The chip, as a low-speed USB host driven by the board driver, sends a
    SETUP token and GET_DESCRIPTOR's DATA0 to usbhostslave's USB device,
    which checks PID, bit stuffing, CRC5 and CRC16 before it answers ACK.
    The same transaction with one CRC16 bit flipped must get no answer."""
    await usb_start(dut)
    trace = []
    cocotb.start_soon(usb_monitor(dut, trace))
    chip = pe.Chip(sim_port(dut))
    setup = pe.usb_token(pe.USB_SETUP, 0, 0)
    get_descriptor = pe.usb_data(pe.USB_DATA0, [0x80, 0x06, 0x00, 0x01, 0x00, 0x00, 0x12, 0x00])
    corrupt = get_descriptor[:-1] + [get_descriptor[-1] ^ 0x01]

    @bridge
    def send(packets):
        usb = pe.UsbHost(chip, firmware("usb_host"))
        usb.transaction(packets)

    await send([setup, corrupt])
    await ClockCycles(dut.clk, 2000)
    bad = usb_packets(trace)
    trace.clear()
    await send([setup, get_descriptor])
    await ClockCycles(dut.clk, 2000)
    good = usb_packets(trace)
    assert bad == [("host", setup), ("host", corrupt)], f"corrupted CRC: {bad}"
    assert good == [("host", setup), ("host", get_descriptor), ("dev", [0xD2])], f"bus saw {good}"
