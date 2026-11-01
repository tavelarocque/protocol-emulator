# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Tiny Tapeout testbench. Runs twice in CI: against the RTL, and against the
# gate-level netlist produced by the GDS flow, so it checks that synthesis
# and place-and-route preserved behaviour.
#
# The UART receiver here is a third independent implementation (alongside the
# two OCaml oracles in model/), written in Python, sampling mid-bit like real
# hardware would.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

DIVISOR = 87  # must match DIVISOR in src/project.v
TX = 0  # uo_out bit
BUSY = 1  # uo_out bit


def pin(dut, bit):
    return (int(dut.uo_out.value) >> bit) & 1


async def reset(dut):
    clock = Clock(dut.clk, 100, unit="ns")  # 10 MHz
    cocotb.start_soon(clock.start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


async def send(dut, byte):
    dut.ui_in.value = byte
    dut.uio_in.value = 1
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0


async def receive(dut):
    for _ in range(4 * DIVISOR):
        await RisingEdge(dut.clk)
        if pin(dut, TX) == 0:
            break
    else:
        raise AssertionError("no start bit seen")
    await ClockCycles(dut.clk, DIVISOR // 2)
    assert pin(dut, TX) == 0, "start bit not low at its midpoint"
    byte = 0
    for k in range(8):
        await ClockCycles(dut.clk, DIVISOR)
        byte |= pin(dut, TX) << k
    await ClockCycles(dut.clk, DIVISOR)
    assert pin(dut, TX) == 1, "stop bit not high at its midpoint"
    return byte


@cocotb.test()
async def test_idle_line_is_high(dut):
    await reset(dut)
    for _ in range(3 * DIVISOR):
        await RisingEdge(dut.clk)
        assert pin(dut, TX) == 1
        assert pin(dut, BUSY) == 0


@cocotb.test()
async def test_bytes_round_trip(dut):
    await reset(dut)
    for byte in [0x55, 0x00, 0xFF, 0x4D, 0x80, 0x01]:
        await send(dut, byte)
        got = await receive(dut)
        assert got == byte, f"sent {byte:#04x}, received {got:#04x}"
        # let the stop bit finish before the next frame
        await ClockCycles(dut.clk, DIVISOR)
