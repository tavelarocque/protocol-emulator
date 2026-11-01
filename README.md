![](../../workflows/gds/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/ocaml/badge.svg)

# protocol-emulator

An open-source protocol emulator ASIC for the
[Jane Street protocol emulator competition](https://blog.janestreet.com/protocol-emulator-asic-competition/):
a tiny CPU whose instructions read pins, write pins and count cycles, so UART,
SPI and I2C are implemented in firmware loaded after fabrication rather than in
fixed logic. Written in Hardcaml, taped out through
[Tiny Tapeout](https://tinytapeout.com) on IHP 130nm CMOS5L (6x4 tiles).

**Status:** a complete single-thread chip running all three required protocols.
An SPI host port loads firmware and configuration into a PIO-style core with 8
protocol pins (input, push-pull or open-drain each). UART TX, I2C controller
(with clock stretching and timeouts) and SPI controller firmware, loaded over
SPI, run on the RTL and on the post-layout gate-level netlist. The core is
formally proven equivalent to an independent specification.

## Architecture

The instruction set ([`docs/isa.md`](docs/isa.md)) follows the RP2040's PIO:

- every instruction takes one cycle, plus a 0-15 cycle delay field
- shift registers feed and drain 4-deep host FIFOs

It departs from PIO where PIO is weakest for protocol emulation:

| | RP2040 PIO | This core |
|---|---|---|
| Waiting on a pin | blocks forever | optional timeout, jumps to a per-thread vector |
| I2C / open-drain | emulated by toggling pin direction | per-pin open-drain mode in hardware |
| Bit timing | fractional clock divider | counter loops, value supplied by the host at run time |
| Program loading | internal bus | SPI port, so any external host can load firmware |
| Undefined encodings | n/a | none: every 16-bit word is a defined instruction |

Firmware ([`model/firmware.ml`](model/firmware.ml)): UART TX in 15
instructions, SPI controller in 27, I2C controller in 49 (program memory is 64
words). The ISA is at v1: writing the I2C controller showed that 32 words was
too small and that a wait timeout counted down in Y could never exceed one
half bit-period, so the memory doubled and timeouts got their own counter.

## Verification

The specification is executable: [`model/isa.ml`](model/isa.ml) is a reference
model written for clarity, with no dependency on the hardware, so the two
cannot share a bug. Everything else is checked against it or against
independent protocol oracles.

| Layer | What is checked | How |
|---|---|---|
| ISA encoding | all 65,536 instruction words | exhaustive encode/decode and disassemble/assemble round trips |
| Firmware | UART TX on the model | cycle-exact against an ideal waveform, plus a mid-bit-sampling receiver, over random bytes and baud rates |
| Core RTL | `hw/pe_core.ml` against the model | lockstep differential test: 400 random programs × 300 cycles, random config, pins and host traffic, full state compared every cycle |
| Whole chip | `hw/top.ml` through its pins only | bit-banged SPI host: register read-back, echo firmware through both FIFOs, UART firmware decoded on the pin |
| Protocols | UART, I2C, SPI firmware | independent protocol oracles on the pins: UART waveform + receiver; I2C bus checker + target device that ACKs and stretches SCL; SPI mode-0 checker + slave with scripted responses |
| Silicon netlist | post-layout gates | the same chip-level tests in cocotb, with separate Python protocol models, on RTL and gate-level netlist |
| **Formal** | core RTL against an independent spec | **SAT equivalence proof** (Hardcaml_verify + Z3): one clock of the RTL equals one step of [`sim/spec_step.ml`](sim/spec_step.ml) for every state, instruction word, input and configuration; the spec itself matches the reference model on all 65,536 instruction words |

Three practices run through all of it.

**Mutation testing, kept in the repo.** Every layer has deliberately planted
bugs, and the suite fails if any survives. A test suite that has never failed
has not been shown to work.

| Layer | Planted bugs | Caught |
|---|---|---|
| UART bring-up | 3 (short stop bit, MSB-first, slow bits) | 3, with the oracle that caught each |
| Core RTL | 5 (X never decrements, timeout ignores budget, delay ignored, SET ignores pin count, PUSH not right-justified) | 5, within 12 random programs |
| Firmware | start bit 1 cycle short, wrong loop condition | both |
| SPI port | MISO shifts one edge early | 3 of 4 system tests |
| Formal proof | the same 5 core bugs | all 5 refuted with SAT counterexamples |
| I2C firmware | SDA moved before SCL falls | caught by the bus checker |
| SPI firmware | MOSI moved after SCK rises | caught by the mode-0 checker |

Two oracles exist because each misses things alone. A start bit one cycle
short decodes fine at a real receiver and is caught only by the cycle-exact
check.

**Functional coverage that fails the build.** The differential test counts
what the random programs actually did: every instruction, every stall, every
timeout, and both full and empty FIFOs. Any zero fails the build. Its first
run found that "PUSH stalls on a full RX FIFO" had never occurred, because the
random host drained the FIFO too often. The fix was to the test (per-trial
host behaviour), not the design.

**Generated artifacts can't drift.** CI regenerates `src/protocol_emulator.v`
from Hardcaml and fails if the committed copy differs. Firmware images for
the Python tests are assembled from the same source the OCaml tests use.

The oracles have caught real bugs, in the firmware and in themselves: SCK
idling high after reset (pins reset high; SPI mode 0 needs it low), a slave
model that dropped a preloaded response on deselect, and an I2C checker too
strict about the clock edge before STOP. The first proof attempt failed on a
difference in the RX FIFO's data wires that never reaches behaviour; the spec
now matches. See [`docs/related-work.md`](docs/related-work.md) for the
literature this draws on.

Planned: side-set (SPI runs at 9 cycles per bit; side-set would make it 2),
a second thread, and proving the remaining surviving mutant equivalent.

## Layout

```
hw/      Hardcaml RTL: pe_core (thread), tiny_fifo, top (SPI port + registers)
model/   reference model, assembler, firmware, UART oracles (no dependency on hw/)
sim/     OCaml tests: ISA, differential core test, chip-level SPI tests
bin/     Verilog generator, firmware hex generator
src/     Verilog for Tiny Tapeout: project.v (pin map) + generated protocol_emulator.v
test/    cocotb testbench (RTL and gate-level) + generated firmware .hex
docs/    isa.md (instruction set), info.md (datasheet)
```

## Running

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
then `cd test && make`.

## Metrics

From the GDS build reports. Timing is checked at 50 MHz (20 ns); the chip is
specified for 10 MHz. +6.3 ns of setup slack puts the critical path near 14 ns,
about 73 MHz.

| Design | Std cells | Utilisation (6x4) | Setup slack | Hold slack |
|--------|-----------|-------------------|-------------|------------|
| UART bring-up | 328 | 0.5% | +12.4 ns | +0.17 ns |
| Full chip (SPI + 1-thread core) | 8,002 | 12.5% | +6.3 ns | +0.14 ns |
