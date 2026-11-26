# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""The bench's judging, shown to be the chip-level tests' judging, with no
hardware.

Each test runs one demo from fpga/bench/demos.py against the RTL (test/tb.v,
the chip-level testbench), with the host driver unchanged, as the Pico runs
it. It records the eight protocol pins as the logic analyser's channels D0
to D7 would see them (a pin the chip does not drive is high, as the FPGA's
pull-up holds it; I2C's two pins are the bus wires), turns that into a
sigrok session file sampled at 24 MHz, as the analyser records, and hands
it to run_bench.py's decode-and-compare step. That must pass. Then the
fault the chip-level test plants on the wire is planted in the 24 MHz
recording, and the same step must fail.

Run from this folder with make (see the Makefile); one demo with
make COCOTB_TEST_FILTER=test_bench_nec. The recordings are kept in
fpga/bench/captures/sim/.
"""

import os
import sys

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

HERE = os.path.dirname(os.path.abspath(__file__))
BENCH = os.path.dirname(HERE)
ROOT = os.path.dirname(os.path.dirname(BENCH))
for path in (BENCH, os.path.join(ROOT, "host"), os.path.join(ROOT, "test")):
    if path not in sys.path:
        sys.path.insert(0, path)

import protocol_emulator as pe  # noqa: E402
import sigrok  # noqa: E402  test/sigrok.py
import demos  # noqa: E402
import run_bench  # noqa: E402
from cocotbext.i2c import I2cMemory  # noqa: E402

try:
    from cocotb import bridge, resume  # noqa: E402
except ImportError:  # cocotb 2.0 exposes them only inside a running simulation
    from cocotb._bridge import bridge, resume  # noqa: E402

HALF = 6  # core clocks per SCK phase, as test/test.py
SIM_CAPTURES = os.path.join(BENCH, "captures", "sim")


def drive(dut, sck, cs_n, mosi):
    dut.ui_in.value = sck | (cs_n << 1) | (mosi << 2)


async def reset(dut):
    """test/test.py's reset: a 10 MHz clock, reset for 10 clocks."""
    Clock(dut.clk, 100_000, unit="ps").start()
    dut.ena.value = 1
    drive(dut, 0, 1, 0)
    dut.uio_in.value = 0xFF  # nothing drives the pins: the FPGA's pull-ups
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 4)


def sim_port(dut):
    """test/test.py's sim_port: the host driver's BitBangPort on the chip's
    host port, HALF clocks a pin change."""
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
        if state["write"] and not miso.is_resolvable:
            return 0
        return int(miso)

    return pe.BitBangPort(set_pins, read_miso)


def analyser(dut, i2c=False):
    """The protocol pins as the analyser's D0 to D7."""
    def level(k):
        if i2c and k < 2:
            return int((dut.i2c_sda if k == 0 else dut.i2c_scl).value)
        if (int(dut.uio_oe.value) >> k) & 1:
            return (int(dut.uio_out.value) >> k) & 1
        return 1
    return sigrok.Trace(dut, {"D%d" % k: (lambda k=k: level(k)) for k in range(8)})


def load(name):
    return pe.load_hex(os.path.join(ROOT, "test", name + ".hex"))


async def bench(dut, name, tail_clocks):
    """Run demo [name], record, judge; plant the test's fault, judge again."""
    await reset(dut)
    i2c = name == "i2c"
    if i2c:  # test_eeprom_24xx's bus and memory
        dut.dev_mode.value = 1
        memory = I2cMemory(sda=dut.i2c_sda, sda_o=dut.i2c_sda_dev, scl=dut.i2c_scl,
                           scl_o=dut.i2c_scl_dev, addr=demos.EEPROM_ADDRESS, size=256)
    else:
        dut.dev_mode.value = 0
    trace = analyser(dut, i2c)
    chip = pe.Chip(sim_port(dut))

    @bridge
    def play():
        return demos.PLAY[name](chip, load)

    got = await play()
    await ClockCycles(dut.clk, tail_clocks)
    trace.stop()
    if i2c:
        assert memory.read_mem(0x0F, 4) == bytes([0x55, 0xDE, 0xAD, 0xBE])
        assert [pe.rev8(w & 0xFF) for w in got[-2:]] == [0xAD, 0xBE], got

    os.makedirs(SIM_CAPTURES, exist_ok=True)
    path = os.path.join(SIM_CAPTURES, name + ".sr")
    run_bench.Capture.from_changes(trace.changes, trace.names, trace.clock_hz, trace.n).write(path)
    demo = run_bench.DEMOS[name]
    cap = run_bench.prepare(run_bench.Capture.read(path), demo)  # as the bench reads a capture
    assert cap.rate == 24_000_000
    ok, log = run_bench.judge(name, cap)
    dut._log.info("\n".join(log))
    assert ok, "\n".join(log)

    fault = demo.fault(cap)
    bad, forced_log = run_bench.judge(name, cap.forced(*fault))
    forced_log.insert(0, "With %s held at %d from sample %d to %d:" % (
        fault[0], fault[3], fault[1], fault[2]))
    dut._log.info("\n".join(forced_log))
    with open(os.path.join(SIM_CAPTURES, name + ".txt"), "w") as f:
        f.write("\n".join(log + [""] + forced_log) + "\n")
    assert not bad, "the forced fault went unnoticed"


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_bench_uart(dut):
    await bench(dut, "uart", 8000)  # test_modbus_rtu's silence after the frame


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_bench_spi(dut):
    await bench(dut, "spi", 500)


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_bench_i2c(dut):
    await bench(dut, "i2c", 2000)


@cocotb.test(timeout_time=400, timeout_unit="ms")
async def test_bench_nec(dut):
    await bench(dut, "nec", 760_000)  # test_nec_infrared's wait: the 67.5 ms frame


@cocotb.test(timeout_time=60, timeout_unit="ms")
async def test_bench_dmx(dut):
    await bench(dut, "dmx", 3000)
