# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""The Pico's side of the FPGA bench (MicroPython, Raspberry Pi Pico 2).

Clocks the chip on GP7, holds it in reset on GP6 and lets it go, talks to it
through host/protocol_emulator.py's PioPort (SCK GP2, CS_N GP3, MOSI GP4,
MISO GP5), runs one demo from demos.py, and puts the chip back into reset
once the demo is off the wire. Not yet run on a board.

    import pico_main; pico_main.main("uart")

or put the demo's name in demo.txt on the Pico and run this file
(mpremote run fpga/bench/pico_main.py). run_bench.py does the first.

The files it needs on the Pico's file system: this one, demos.py,
protocol_emulator.py, more_protocols.py and the demo's .hex file.

The clock. MicroPython's PWM on the RP2350 (ports/rp2/machine_pwm.c) uses
a divider of 1 and a period of round(sys_hz / hz) cycles whenever that fits
16 bits, so at the Pico 2's 150 MHz system clock 10 MHz is 15 cycles a
period: exactly 10 MHz, as exact as the Pico's 12 MHz crystal. A duty of
half is 7 of the 15 cycles high (or 8, as the rounding falls). On a Pico
(RP2040, 125 MHz) the same call gives 13 cycles, 9.615 MHz, 3.8% slow, and
every protocol is slow by as much; main() says so when it happens.

The host port's pace. PioPort runs its state machine at the system clock
divided by the whole number nearest 12.5 MHz, so 12.5 MHz at 150 MHz,
which against a 10 MHz chip gives SCK phases of exactly 4 chip clocks
(the chip's minimum) and a read's low phases 5.6 (the cocotb tests give
MISO 6). Here the state machine runs at 10 MHz instead (150 / 15), so the
phases are 5 and 7 chip clocks; a write takes 26 us, a read 31 us.
"""

import time

import machine
from machine import Pin, PWM

import protocol_emulator as pe
import demos

CLK_PIN, RST_PIN = 7, 6
SCK_PIN, MISO_PIN = 2, 5  # CS_N and MOSI are GP3 and GP4
CHIP_HZ = 10_000_000
PIO_HZ = 10_000_000

# The demos' devices on the Pico. The I2C demo's EEPROM is the Pico's own
# I2C0 as a target with a 256-byte memory (machine.I2CTarget, MicroPython
# 1.26 or later): SDA on GP0, SCL on GP1, wired to P0 and P1.
I2C_SDA_PIN, I2C_SCL_PIN = 0, 1


def pwm_hz(sys_hz, hz):
    """The frequency MicroPython's rp2 PWM makes for [hz] with a divider of
    1: sys_hz over round(sys_hz / hz) cycles."""
    return sys_hz / ((sys_hz + hz // 2) // hz)


def start_clock(hz=CHIP_HZ):
    pwm = PWM(Pin(CLK_PIN))
    pwm.freq(hz)
    pwm.duty_u16(32768)
    return pwm


def bring_up():
    """Clock on, reset held for 1 ms (10,000 chip clocks) and let go, the
    host port on PIO. Returns the Chip and the clock's real frequency."""
    rst = Pin(RST_PIN, Pin.OUT, value=0)
    pwm = start_clock()
    sys_hz = machine.freq()
    hz = pwm.freq()
    print("system clock %d Hz, chip clock %d Hz (%+.3f%%)" % (sys_hz, hz, 100 * (hz - CHIP_HZ) / CHIP_HZ))
    if hz != CHIP_HZ:
        print("warning: the chip clock is not 10 MHz; every protocol's rate is off by as much")
    time.sleep_ms(1)
    rst.value(1)
    time.sleep_ms(1)
    pio_hz = sys_hz // max(1, (sys_hz + PIO_HZ - 1) // PIO_HZ)
    chip = pe.Chip(pe.PioPort(sck_pin=SCK_PIN, miso_pin=MISO_PIN, pio_hz=pio_hz))
    out_cfg = chip.read(pe.OUT_CFG)
    if out_cfg != 0x10:  # OUT_CFG's value after reset (test_registers)
        raise RuntimeError("OUT_CFG reads 0x%04x, not 0x0010: check the bitstream, "
                           "the clock, reset and the host port wiring" % out_cfg)
    return chip, hz


def eeprom():
    """The I2C demo's EEPROM, or None if this MicroPython has no I2CTarget."""
    try:
        from machine import I2CTarget
    except ImportError:
        print("warning: no machine.I2CTarget (MicroPython 1.26 or later); "
              "nothing on the bus will ACK and the demo will fail")
        return None, None
    mem = bytearray(256)
    target = I2CTarget(0, demos.EEPROM_ADDRESS, mem=mem,
                       scl=Pin(I2C_SCL_PIN), sda=Pin(I2C_SDA_PIN))
    return target, mem


def load(name):
    return pe.load_hex(name + ".hex")


def main(name=None):
    if name is None:
        with open("demo.txt") as f:
            name = f.read().strip()
    play = demos.PLAY[name]
    target, mem = eeprom() if name == "i2c" else (None, None)
    chip, _ = bring_up()
    print("demo", name)
    got = play(chip, load)
    time.sleep_ms(demos.TAIL_MS[name])
    # Back into reset: the pins let go (high, on the FPGA's pull-ups), so the
    # next demo's recording starts from quiet lines.
    Pin(RST_PIN, Pin.OUT, value=0)
    if name == "i2c":
        acks = ["N" if w & 0x100 else "A" for w in got]
        print("ACK slots", "".join(acks))
        if mem is not None:
            print("EEPROM 0x0f to 0x12:", " ".join("%02x" % b for b in mem[0x0F:0x13]))
        if target is not None:
            target.deinit()
    elif got is not None:
        print("sent", " ".join("%02x" % b for b in got) if name == "uart" else got)
    print("done")


if __name__ == "__main__":
    main()
