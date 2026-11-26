# FPGA bench: the chip on a Tang Nano 20K

The chip's RTL, unchanged, as a bitstream for a Sipeed Tang Nano 20K, so its firmware can drive real wires before there is silicon. A Raspberry Pi Pico plays the part of the Tiny Tapeout demo board's RP2350: it clocks the chip, holds it in reset, and talks to it over the SPI host port, so `host/protocol_emulator.py` and every host driver run as they would on the demo board. A logic analyser records the protocol pins, and the recording goes to the same sigrok decoders the chip-level tests use.

Status: the bitstream is built and timed in CI (`.github/workflows/fpga.yaml`). It has not yet been run on a board.

## What is in the bitstream

| File | What it is |
| --- | --- |
| `src/project.v`, `src/protocol_emulator.v` | the chip, exactly as it goes to the foundry |
| `fpga/sram_fpga.v` | the three SRAM macros, as FPGA block RAM under the macros' own names |
| `fpga/tangnano20k/board.v` | the board's pins around the chip |
| `fpga/tangnano20k/pins.cst` | which FPGA pin is which |

The only part that is not the chip is the memory. `fpga/sram_check.py` proves with Yosys that each FPGA memory and IHP's behavioural model of the macro, tied off as the chip ties it, are the same machine, and that a planted bug in the FPGA memory makes the proof fail. CI runs it before building.

## Building

`fpga/build.sh` needs Yosys, nextpnr-himbaechel and gowin_pack, all in the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build); CI uses the release of 2026-11-01. It writes `fpga/build/pe_tangnano20k.fs` (clock from the Pico) and, with `fpga/build.sh clk27`, a version clocked by the board's 27 MHz crystal. The CI run uploads both, with the place-and-route log that gives the logic used and the clock's maximum frequency.

Load a bitstream with [openFPGALoader](https://github.com/trabucayre/openFPGALoader):

    openFPGALoader -b tangnano20k fpga/build/pe_tangnano20k.fs

## Wiring

Every signal is 3.3 V. Connect the grounds.

| Chip signal | Tang Nano 20K pin | Pico pin |
| --- | --- | --- |
| clk | 77 | GP7 (PWM, 10 MHz) |
| rst_n | 76 | GP6 |
| SCK (ui_in[0]) | 73 | GP2 |
| CS_N (ui_in[1]) | 74 | GP3 |
| MOSI (ui_in[2]) | 27 | GP4 |
| MISO (uo_out[0]) | 28 | GP5 |
| P0 to P7 (uio[0] to [7]) | 75, 42, 41, 48, 49, 86, 72, 71 | to the device, and to the logic analyser's channels 0 to 7 |
| status (uo_out[1] to [6]) | 15 to 20, also LED0 to LED5 (lit when low) | optional |
| GND | GND | GND |

SCK, CS_N and MOSI sit on three consecutive Pico GPIOs, as the host driver's PIO port needs. The reset pin is pulled low inside the FPGA, so the chip stays in reset until the Pico releases it. The protocol pins have the FPGA's weak pull-ups; open-drain buses such as I2C still want their own pull-up resistors.

Pins kept free because the board uses them: 80 and 85 (TF card), 79 (RGB LED), 52 and 53 (HDMI), 51, 54, 55 and 56 (audio amplifier), 25 and 26 (HDMI CEC and hot plug).
