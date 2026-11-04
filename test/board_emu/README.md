# The demo board in emulation

This runs the chip's host driver the way it will really run: in MicroPython,
on the Tiny Tapeout demo board's RP2040, under Tiny Tapeout's own board
firmware. There is no board here, so the RP2040 is emulated, and its pins are
wired to the chip's RTL and a low-speed USB device in a Verilator model.

The point is timing. The cocotb tests run the driver under CPython and can
clock the host port as fast as the chip allows. MicroPython on the board is
far slower, and this shows what that does.

## What runs

- **The board's MCU.** [rp2040js](https://github.com/wokwi/rp2040js)
  (Wokwi, MIT) emulates the RP2040. It boots Tiny Tapeout's
  [MicroPython firmware](https://github.com/TinyTapeout/tt-micropython-firmware)
  v2.0.4 (LGPL-2.1; MicroPython 1.24 with the TT SDK) for the TT06 to TT08
  boards, unmodified. The Makefile fetches it and checks its SHA-256.
- **The chip and the device.** `usb_board.v` is the chip's RTL
  (`src/project.v`, `src/protocol_emulator.v`) with the same transceiver, bus
  and usbhostslave device as `test/tb.v`'s USB mode. Verilator compiles it,
  and `cosim.cpp` loads it into Node as an addon.
- **The wiring.** `board.mjs` connects them with the demo board's pin map:
  `ui_in` on GPIO 9 to 12 and 17 to 20, `uo_out` on GPIO 5 to 8 and 13 to 16.
  The chip runs at 12 MHz and the device at 48 MHz, on the same time line as
  the CPU.

## How time is kept

rp2040js charges each instruction its ARMv6-M cycle count at 125 MHz. It
treats flash as zero-wait, and it leaves PIO untimed (its state machines run
from a host timer). Two things are added here:

1. **PIO runs on its own clock.** Each state machine runs at system clock /
   CLKDIV, and each instruction takes its delay cycles.
2. **Pins are kept in step.** The hardware advances to the current time
   whenever a chip input changes, and at least every 40 ns otherwise.

**Calibration.** In this emulator, a bare MicroPython `for` loop iteration
takes 10.0 µs. Cornell's ECE 4760 notes measured about 5.2 µs on a real Pico
at 125 MHz (an older MicroPython). So the emulated CPU reads about 2x slow,
partly because the emulated USB serial link interrupts more often than a real
one. The CPU's speed is not what decides the USB result, though. With
`PioPort`, the timed part runs in PIO, which is emulated to the cycle. The
`--cpu-slowdown` option slows only the CPU further, to show the margin.

## Running

    make            # Verilator model, addon, firmware, boot ROM, rp2040js
    node run_usb.mjs                          # the driver as shipped (PioPort)
    node run_usb.mjs --cpu-slowdown 3         # with a CPU three times slower
    node run_usb.mjs --mutant push-after-start --expect-fail
    node run_usb.mjs --port bitbang --expect-fail

Each run boots the board, loads `host/protocol_emulator.py` into MicroPython
and reads the device descriptor with `UsbHost.control_read`. It prints every
packet on the bus and the gap from each of the device's data packets to the
host's handshake. It passes only if:

- the descriptor is right;
- every handshake starts within the 16 bit times the device waits;
- the two ends never drive the bus at once.

A run takes a few minutes of wall time.

## Results

RESULTS
