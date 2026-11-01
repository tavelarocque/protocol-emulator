![](../../workflows/gds/badge.svg) ![](../../workflows/test/badge.svg)

# protocol-emulator

An open-source protocol emulator ASIC for the
[Jane Street protocol emulator competition](https://blog.janestreet.com/protocol-emulator-asic-competition/):
a tiny CPU whose instructions read pins, write pins and count cycles, so UART,
SPI and I2C are implemented in firmware rather than fixed logic. Written in
Hardcaml, taped out through [Tiny Tapeout](https://tinytapeout.com) on IHP
130nm CMOS5L (6x4 tiles).

**Status (week 1):** a fixed-function UART transmitter, used to prove the
pipeline end to end (Hardcaml, simulation, verification, Verilog, GDS) before
the programmable core exists.

## Verification approach

Verification is designed in from the first commit, not added at the end.

- **Independent reference models** (`model/`), written without looking at the
  hardware so they cannot share its bugs. UART has two: a cycle-exact ideal
  waveform, and a receiver that samples mid-bit the way real hardware does.
- **Constrained-random tests** with Quickcheck over data and timing parameters.
- **Mutation testing kept in the repo.** The design accepts planted bugs, and
  the suite asserts that every mutant is caught and reports which oracle caught
  it. A test suite that has never failed has not been shown to work.

  | Planted bug | Cycle-exact oracle | Receiver oracle |
  |---|---|---|
  | Stop bit one cycle short | 300/300 | 13/300 |
  | Bits sent MSB-first | 281/300 | 281/300 |
  | Every bit one cycle too long | 300/300 | 192/300 |

  The receiver alone misses most timing bugs, which is why both oracles exist.
  The 19 MSB-first survivors are bit-palindromic bytes (0x00, 0xFF, 0xA5, ...),
  where bit order is unobservable.
- **Waveform expect tests** that lock in exact timing as readable documentation.
- **Gate-level simulation.** The cocotb testbench (`test/`, a third independent
  receiver in Python) runs against both the RTL and the post-layout netlist.
- Planned: CI that regenerates the Verilog from Hardcaml and fails on drift,
  an executable ISA reference model with differential testing against the core
  on random programs, protocol checkers on the pins, and formal properties via
  Hardcaml Verify.

## Layout

```
hw/      Hardcaml RTL
model/   OCaml reference models (no dependency on hw/)
sim/     OCaml simulation tests (Quickcheck, mutation, waveforms)
bin/     Verilog generator
src/     Verilog consumed by Tiny Tapeout: project.v (top) + generated uart_tx.v
test/    Tiny Tapeout cocotb testbench (RTL and gate-level)
docs/    datasheet source
```

## Running

Uses a dedicated opam switch on OCaml 5.3.0 (Hardcaml's waveform viewer does
not build on 5.4 yet).

```
opam switch create hardcaml ocaml-base-compiler.5.3.0
opam switch link hardcaml          # run inside this folder
eval $(opam env)
opam install hardcaml hardcaml_waveterm ppx_hardcaml ppx_jane core dune
dune build      # build everything and regenerate src/uart_tx.v
dune runtest    # run the OCaml verification suite
dune promote    # accept expect-test output after checking the diff
```

The cocotb tests need Icarus Verilog and `pip install -r test/requirements.txt`,
then `cd test && make`.

## Metrics

Updated from the GDS build reports.

| Week | Design | Std cells | Utilisation (6x4) | Timing target | Setup slack | Hold slack |
|------|--------|-----------|-------------------|---------------|-------------|------------|
| 1    | uart_tx | 328 | 0.5% | 50 MHz (runs at 10 MHz) | +12.4 ns | +0.17 ns |
