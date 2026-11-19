![](../../workflows/gds/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/ocaml/badge.svg)

# protocol-emulator

An open-source protocol emulator ASIC for the
[Jane Street protocol emulator competition](https://blog.janestreet.com/protocol-emulator-asic-competition/):
a tiny CPU whose instructions read pins, write pins and count cycles, so UART,
SPI and I2C are implemented in firmware loaded after fabrication rather than in
fixed logic. Written in Hardcaml, designed for tapeout through
[Tiny Tapeout](https://tinytapeout.com) on IHP 130nm CMOS5L (8x4 tiles).

> **This branch is v2.0, in progress.** The program memory moves from 64
> words of flip-flops shared by both threads to an SRAM macro of 256 words
> for each thread, with a PAGE register for jumps
> ([`docs/isa.md`](docs/isa.md), revision history). The model, the RTL, the
> proofs and every test are updated and pass. The text and numbers below
> still describe v1.4, the chip on `main`, until the v2 layout is
> characterised.

**In ten minutes:** [`docs/submission.md`](docs/submission.md) is the
one-page summary for judges. This page is the map.

## Status

- **Complete chip, laid out.** Two threads, 64 words of shared program
  memory, 8 protocol pins (input, push-pull or open-drain each), loaded
  over an SPI host port. 0 DRC, 0 LVS, timing met at every corner
  ([`docs/metrics.md`](docs/metrics.md)).
- **Ten protocols as firmware**, two running at a time. UART, SPI and I2C as
  required, in both roles for SPI and I2C; then JTAG, SWD, low-speed USB
  host (the stretch goal), 1-Wire, WS2812, PS/2 and CAN.
- **Nine engines added after the hardware froze**, with no RTL change. That
  is the evidence for flexibility.
- **Formally proven twice.** The whole chip, pins in to pins out, equals an
  independent specification; and after every layout the gate netlist
  equals the RTL.
- **The real driver, unchanged**, runs against the chip in simulation and
  in MicroPython on an emulated demo board.
- **Not yet done:** no FPGA or silicon run, and one slow-corner slew
  warning. The full list is "What is not shown" in
  [`docs/submission.md`](docs/submission.md).

## Architecture

![Block diagram: host, SPI port and registers, program memory, two threads with FIFOs, and the pins](docs/img/architecture.svg)

[`docs/chip.html`](docs/chip.html) is the laid-out chip in 3D: every one of
the 101,866 cells where the tools placed it (17,925 of logic; the rest are
the fill and decoupling cells that pack the empty rows), coloured by its block,
with the reference model running real firmware in the page and lighting
the flip-flops that hold a 1. It is one self-contained file with no network
access: download it and open it in a browser, or
[view it here](https://htmlpreview.github.io/?https://github.com/tavelarocque/protocol-emulator/blob/main/docs/chip.html).

The instruction set ([`docs/isa.md`](docs/isa.md)) follows the RP2040's PIO:

- every instruction takes one cycle, plus a 0-15 cycle delay field
- side-set: up to 3 pins driven from the delay field alongside any instruction
- shift registers feed and drain 4-deep host FIFOs
- two threads, each with its own PC, registers, FIFOs and configuration,
  running every cycle from one shared program memory; when both write a pin
  in the same cycle, thread 1 wins
- a clock divider per thread, and CHAIN, which feeds thread 0's output
  straight into thread 1
- a two-flip-flop synchroniser on every protocol pin input, bypassable per
  pin for protocols too fast for the delay
- shift direction per thread, so MSB-first protocols (SPI, I2C) take and
  return plain bytes

Three programs as the reference model runs them, drawn from its output by
[`docs/figures.py`](docs/figures.py), which CI re-runs so the pictures cannot
drift from the firmware:

![UART transmit waveform](docs/img/uart.svg)

![SPI controller waveform](docs/img/spi.svg)

![WS2812 waveform](docs/img/ws2812.svg)

It departs from PIO where PIO is weakest for protocol emulation:

| | RP2040 PIO | This core |
|---|---|---|
| Waiting on a pin | blocks forever | optional timeout, jumps to a per-thread vector |
| I2C / open-drain | emulated by toggling pin direction | per-pin open-drain mode in hardware |
| Bit timing | fractional clock divider | counter loops, value supplied by the host at run time |
| Program loading | internal bus | SPI port, so any external host can load firmware |
| Undefined encodings | n/a | none: every 16-bit word is a defined instruction |


Each revision of the instruction set came from writing a protocol and
finding what was missing; [`docs/firmware.md`](docs/firmware.md) has the
history.

## Protocols

Assembly for each is in [`examples/`](examples); descriptions and limits
are in [`docs/firmware.md`](docs/firmware.md).

| Protocol | Role | Instructions (of 64) | Checked against |
|---|---|---|---|
| UART | TX and RX, full duplex | 15 + 15 | cocotbext-uart |
| SPI | controller, to 5 Mbit/s | 26 | picosoc's SPI flash |
| SPI | device | 23 | cocotbext-spi's controller |
| I2C | controller, with stretching and timeouts | 25 | cocotbext-i2c's EEPROM |
| I2C | target | 63 | cocotbext-i2c's controller, 400 kHz |
| JTAG | controller | 11 | cocotbext-jtag and an IEEE 1149.1 device |
| Arm SWD | host | 11 | a target written from ADIv5; sigrok's SWD decoder |
| USB, low speed | host | 49 | usbhostslave's device core |
| 1-Wire | controller, with ROM search | 25 | sockit_owm's slave model, three on one wire |
| WS2812 | driver | 16 | a hidden data-sheet timing test |
| PS/2 | host, both directions | 11 + 21 | a device written from the protocol's rules; sigrok's PS/2 decoder |
| CAN | transmitter and listen-only receiver | 19 + 27 | a node written from ISO 11898-1; sigrok's CAN decoder |
| I2C to SPI | bridge, no host in the data path | 25 + 26 | the I2C and SPI oracles together |
| I2S | transmitter, 16-bit stereo | 11 | sigrok's I2S decoder |
| DMX512 | transmitter | 26 | sigrok's DMX512 decoder |
| Wiegand | transmitter | 17 | sigrok's Wiegand decoder |
| NEC infrared | transmitter, 38 kHz carrier included | 25 | sigrok's NEC decoder |
| MDIO | controller, reads and writes | 7 | a PHY written from IEEE 802.3 clause 22; sigrok's MDIO decoder |
| DALI | forward frame transmitter | 17 | sigrok's DALI decoder |
| RC-5 infrared | transmitter, 36 kHz carrier included | 37 | sigrok's RC-5 decoder |
| MIDI | on the UART transmitter | no new firmware | sigrok's MIDI decoder |
| LIN | master frames, on the DMX512 transmitter | no new firmware | sigrok's LIN decoder |
| MAX7219 | on the SPI controller | no new firmware | sigrok's MAX7219 decoder |

The "checked against" models are other people's wherever one exists. For
SWD, PS/2 and CAN the device model is written here from the standard, so
the pins are also recorded and handed to sigrok's protocol decoders, which
this project did not write ([`test/sigrok.py`](test/sigrok.py)). WS2812
has only its data-sheet timing test.

## Verification

[`docs/design-and-verification.md`](docs/design-and-verification.md) is the
report: design decisions and their alternatives, how the layers of evidence
chain into a claim about the chip, the real bugs found, and what is not
covered. [`docs/verification-layers.md`](docs/verification-layers.md) has
every layer and every planted bug, and [`docs/bug-ledger.md`](docs/bug-ledger.md)
tells seven real bugs and which layer found each.

The specification is executable: [`model/isa.ml`](model/isa.ml) is a
reference model with no dependency on the hardware, so the two cannot share
a bug.

| Question | Answer | How |
|---|---|---|
| Does the RTL match the specification? | Proven, for the whole chip | SAT equivalence (Hardcaml_verify + Z3) of one clock of the top level against an independent spec, for every state and every input |
| Does the silicon netlist match the RTL? | Proven, after every layout | Yosys equivalence over every output and all 1,796 flip-flops ([`gl_equiv/`](gl_equiv)) |
| Is every instruction defined? | Yes, all 65,536 words | exhaustive round trips, and the spec's datapath matched on every word |
| Do the protocols work? | Each judged by an independent oracle | third-party device models in cocotb, on the RTL and the gate netlist |
| Does the host driver work? | The same file, unchanged | in cocotb, then in MicroPython on an emulated board (rp2040js) wired to the RTL |
| Would the tests notice a bug? | 86 planted bugs, all caught | kept in the repo; the suite fails if one survives |
| Did the random tests reach everything? | Coverage is counted | any instruction, stall or timeout never seen fails the build |

Generated files cannot drift: CI regenerates the Verilog, the firmware
images, the example programs and the timing diagrams, and fails if a
committed copy differs.

The hardware is frozen at v1.4. Everything after it is firmware, testing
and documentation, none of which can put the chip at risk.

## Repository

```
hw/      Hardcaml RTL: pe_core (two threads), tiny_fifo, top (SPI port + registers)
model/   reference model, assembler, firmware, UART oracles (no dependency on hw/)
bin/     pe_sim: assemble a .s file, or run it on the reference model and print
         the pins as they change (`dune exec bin/pe_sim.exe -- run -help`);
         the Verilog, firmware-image and example generators
examples/ one assembly file per protocol, generated from model/firmware.ml;
         ws2812/: the blind firmware test, task, notes and hidden test
sim/     OCaml tests: ISA, lockstep harness, random and directed differential tests,
         formal proof, firmware, chip-level tests
host/    MicroPython driver for the demo board, RP2040 or RP2350 (tested in cocotb, unchanged,
         and in MicroPython on an emulated board: test/board_emu)
         more_protocols.py: the drivers for the protocols added on v2.0, a module of
         their own so that each fits the Pico's memory when compiled
src/     Verilog for Tiny Tapeout: project.v (pin map) + generated protocol_emulator.v
test/    cocotb testbench (RTL and gate-level) + generated firmware .hex;
         usbhostslave/ is a third-party USB device core and onewire_slave_model.v
         a third-party 1-Wire device model (both LGPL, test only)
gl_equiv/ Yosys proof that the post-layout netlist equals the RTL (run in CI)
docs/    submission.md (one-page summary), design-and-verification.md (the report),
         figures.py and img/ (diagrams drawn from the reference model),
         chip.html (the layout in 3D, one self-contained page),
         isa.md (instruction set), firmware.md (every engine),
         verification-layers.md, bug-ledger.md, metrics.md,
         info.md (datasheet), coverage-closure.md, related-work.md
```

## Running

With the tools below installed, `./reproduce.sh` re-runs every check that
needs no layout build and prints one pass or fail line per claim (about 15
minutes for the OCaml suite and proof, then the cocotb suite).

Uses a dedicated opam switch on OCaml 5.3.0 (Hardcaml's waveform viewer does
not build on 5.4 yet).

```
opam switch create hardcaml ocaml-base-compiler.5.3.0
opam switch link hardcaml          # run inside this folder
eval $(opam env)
opam install hardcaml hardcaml_waveterm hardcaml_verify ppx_hardcaml ppx_jane core dune
dune build      # build, regenerate src/protocol_emulator.v and test/*.hex
dune runtest    # run the OCaml verification suite (formal proof needs z3: brew install z3)
dune promote    # accept expect-test output after checking the diff
```

The cocotb tests need Icarus Verilog and `pip install -r test/requirements.txt`,
then `cd test && make`. The RTL-to-netlist proof needs Yosys
(`pip install yowasp-yosys`), the netlist from a layout build's
`tt_submission` artifact and IHP's standard-cell Liberty file:
`python3 gl_equiv/check.py --netlist <netlist.v> --lib <cells.lib> --mutants --yosys yowasp-yosys`.
The board emulation needs Verilator and Node 22: `make -C test/board_emu`,
then `node run_usb.mjs` there (see `test/board_emu/README.md`).

## Metrics

The submitted layout, on Tiny Tapeout's ttihp27a flow (8x4 tiles, 25 ns
target): 17,925 standard cells, 20.8% utilisation, 0.97 m of wire, setup
slack +6.85 ns at the slow corner, hold +0.12 ns, 0 DRC and 0 LVS errors.
The chip is specified for 10 MHz. One slew warning remains at the slow
corner. History, the warning and what was tried:
[`docs/metrics.md`](docs/metrics.md).
