# The demo board in emulation

This runs the chip's host driver the way it will really run: in MicroPython,
on the Tiny Tapeout demo board's RP2040, under Tiny Tapeout's own board
firmware. There is no board here, so the RP2040 is emulated, and its pins are
wired to the chip's RTL in a Verilator model, with a device on the protocol
pins for each protocol.

The cocotb tests run the same driver under CPython and clock the host port as
fast as the chip allows. MicroPython on the board is a different language
implementation and far slower, and this shows what each of those does.

## What runs

- **The board's MCU.** [rp2040js](https://github.com/wokwi/rp2040js)
  (Wokwi, MIT) emulates the RP2040. It boots Tiny Tapeout's
  [MicroPython firmware](https://github.com/TinyTapeout/tt-micropython-firmware)
  v2.0.4 (LGPL-2.1; MicroPython 1.24 with the TT SDK) for the TT06 to TT08
  boards, unmodified. The Makefile fetches it and checks its SHA-256.
- **The chip and its devices.** `board.v` is the chip's RTL
  (`src/project.v`, `src/protocol_emulator.v`) with the devices of
  `test/tb.v`, picked by `dev_mode` as there:
  - **Verilog models:** picosoc's SPI flash, the JTAG TAP and SWD target from
    `test/`, and usbhostslave's USB device behind a USB 1.1 transceiver.
  - **JavaScript models (`devices.mjs`):** a UART receiver, an I2C controller
    (fast mode, honouring clock stretching) and an SPI controller (mode 0).
    These are written for this project from the specifications, because
    cocotbext's Python models cannot run here. They test the driver, not the
    protocols; the cocotb suite tests the protocols against other people's
    models.

  Verilator compiles the Verilog, and `cosim.cpp` loads it into Node as an
  addon.
- **The wiring.** `board.mjs` connects them with the demo board's pin map:
  `ui_in` on GPIO 9 to 12 and 17 to 20, `uo_out` on GPIO 5 to 8 and 13 to 16.
  The chip runs at 10 MHz (12 MHz for USB, with the device at 48 MHz), on
  the same time line as the CPU.

## Which board

The emulated board is an RP2040 demo board (TT06 to TT08), because
rp2040js emulates only the RP2040. This chip is for the IHP shuttles, which
ship on demo board v3, built around an RP2350B and run by Tiny Tapeout's
SDK v3. Three differences matter to the driver:

- **Pins.** On the RP2350 board, `ui_in` is GPIO 17 to 24 and `uo_out` GPIO
  33 to 40. The driver reads the host port's pins from the SDK's map of the
  board it finds (`board_host_pins`), so the emulation runs the same lookup.
  Here it returns the SDK's default map: the firmware's `main.py` stops at
  its first write to the emulated flash (its boot log), before it detects
  the board, and the default map's host-port pins are the TT06 to TT08
  boards' (GPIO 9 to 11 and 5).
- **The PIO window.** PIO on the RP2350B reaches 32 GPIOs at a time, so
  MISO on GPIO 33 needs the window from GPIO 16 to 47. `PioPort` selects it
  (`rp2.PIO.gpio_base`), a line that cannot run here.
- **The PIO clock.** For a 10 or 12 MHz project clock the SDK runs the
  system clock at 120 MHz, where `PioPort` runs at 12 MHz rather than 12.5.
  `--pio-hz 12000000` runs the emulated port at that rate (results below).

The RP2350's Cortex-M33 is faster than the RP2040's Cortex-M0+, and the USB
result does not depend on the CPU's speed anyway (`--cpu-slowdown`, below).
What remains for the first real board: check that `board_host_pins()`
returns (17, 33), then read a descriptor with `UsbHost`.

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
    node run_compat.mjs                       # MicroPython and CPython agree
    node run_board.mjs                        # every protocol class
    node run_board.mjs swd --mutant cpython-only-call --expect-fail
    node run_usb.mjs                          # the USB driver as shipped (PioPort)
    node run_usb.mjs --cpu-slowdown 3         # with a CPU three times slower
    node run_usb.mjs --pio-hz 12000000        # the port at the RP2350 board's rate
    node run_usb.mjs --mutant push-after-start --expect-fail
    node run_usb.mjs --port bitbang --expect-fail

`run_board.mjs` runs the scenarios of the cocotb "host driver" tests, in
MicroPython, with the bit-banged host port:

- **UART:** a message out of `UartTx`.
- **SPI flash:** a read through `SpiController`.
- **I2C device:** the chip as an I2C device, read through a repeated START.
- **SPI device:** the chip as an SPI device.
- **JTAG:** a session through `JtagController`.
- **SWD:** a session through `SwdController`, including the error raised
  while the target is still silent.

Each must give the cocotb test's results. Running all six takes about two
minutes.

`run_usb.mjs` boots the board, loads `host/protocol_emulator.py` into
MicroPython and reads the device descriptor with `UsbHost.control_read`. It prints every
packet on the bus and the gap from each of the device's data packets to the
host's handshake. It passes only if:

- the descriptor is right;
- every handshake starts within the 16 bit times the device waits;
- the two ends never drive the bus at once.

A run takes one to three minutes of wall time.

## Results

The emulation is deterministic: CI on GitHub prints the same numbers to the
tenth of a microsecond.

**Every protocol class passes in MicroPython.** Each took this long on the
emulated board:

| Protocol | Run | Time |
|---|---|---:|
| UART | `UartTx` sending 12 bytes | 211 ms |
| SPI flash | read | 262 ms |
| JTAG | session | 479 ms |
| SWD | session | 851 ms |

These are slow but harmless. Each of those protocols is clocked by the chip,
which simply waits for the board.

**SWD's error path crashed.** It called `format`, which MicroPython lacks, so
a target that never answered raised `NameError` instead of `SwdError`. It is
fixed, and the planted bug `cpython-only-call` puts it back, to show
`run_board.mjs` catches it.

**The driver as it was (bit-banged port, one push at a time).** It never
decoded a packet. `int.bit_length` does not exist in MicroPython, so
`usb_decode` raised on the first data packet. `run_compat.mjs` now catches
that class of bug in seconds.

With that patched, the read still failed:

- **The writes were too slow.** Each register write took about 3.6 ms, so
  the handshake reached the bus 14.6 ms after the device's data, against the
  16 bit times (10.7 µs) a device waits.
- **The device never saw the handshake.** On the next IN it answered with
  DATA1 again (an empty packet) instead of advancing to DATA0.
- **The driver then rejected the packet**, raising "bad data packet".

**The driver now (PioPort, batches queued with the state machine
stopped).** The 18-byte descriptor reads back correctly.

- **Handshakes come at the engine's own pace.** Every one starts 4.08 bit
  times after the device's data, so the engine was waiting on nothing.
- **The handshake's last word has margin.** It reached the chip 52.6 and
  52.9 µs before the ends of the two 8-byte data packets, and 22.2 µs before
  the end of the 2-byte one. A zero-length packet ends 10.7 µs sooner than
  that, so it would still be on time.
- **The CPU's speed barely matters.** With the emulated CPU three times
  slower, the margins are 52.7, 52.9 and 21.9 µs, and the handshakes start
  after 4.10 to 4.12 bit times. The small differences are where the clocks'
  phases happen to fall, not the CPU's pace.
- **The RP2350 board's port rate holds too.** With the port at 12 MHz, the
  rate it runs at on the RP2350 board, the margins are 51.2, 51.2 and
  20.4 µs, so a zero-length packet's handshake would still have 9.7 µs to
  spare, and the handshakes start after 4.08 bit times.

**The planted bug (`--mutant push-after-start`).** This puts the
handshake's words in one at a time after the engine starts, each after a
status read, as the driver used to. The run must fail, and it does. Even on the PIO port, the handshake reached the
bus 1.1 ms (about 1,650 bit times) after the device's data, and the read
failed as the old driver's did.

**Two intermediate versions** of `PioPort` were tried and measured on the
way:

- **One SCK timing for reads and writes.** The handshake had 1.6 µs to spare
  on the short packet. From that slack, a zero-length packet's handshake
  would have come after about 17.7 bit times, too late.
- **Words fed one at a time from MicroPython.** That starved the state
  machine, so the short packet's handshake came after 9.95 bit times.

The test now fails any version whose zero-length handshake would come after
16 bit times.
