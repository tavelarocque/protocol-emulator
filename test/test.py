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
from cocotb.triggers import ClockCycles, RisingEdge

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


async def push(dut, v):
    while (await read(dut, STATUS)) & 0x7 >= FIFO_DEPTH:
        pass
    await write(dut, TX_FIFO, v)


async def pop(dut):
    while ((await read(dut, STATUS)) >> 4) & 0x7 == 0:
        pass
    return await read(dut, RX_FIFO)


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
