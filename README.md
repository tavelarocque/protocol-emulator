# protocol-emulator

An open-source protocol emulator ASIC for the
[Jane Street protocol emulator competition](https://blog.janestreet.com/protocol-emulator-asic-competition/):
a tiny CPU whose instructions read pins, write pins and count cycles, so UART,
SPI and I2C are implemented in firmware rather than fixed logic. Built in
Hardcaml, taped out through Tiny Tapeout on IHP 130nm (6x4 tiles).

**Status (week 1):** a fixed-function UART transmitter, used to prove the
pipeline end to end before the programmable core exists.

## Verification approach

Verification is designed in from the first commit, not added at the end.

- **Independent reference models** (`model/`), written without looking at the
  hardware so they cannot share its bugs. UART has two: a cycle-exact ideal
  waveform, and a receiver that samples mid-bit the way real hardware does.
- **Constrained-random tests** with Quickcheck over data and timing parameters.
- **Mutation testing kept in the repo.** The design accepts planted bugs, and
  the suite asserts that every mutant is caught, and reports which oracle
  caught it. A test suite that has never failed has not been shown to work.
- **Waveform expect tests** that lock in exact timing as readable documentation.
- Planned: an executable ISA reference model with differential testing against
  the core on random programs, protocol checkers on the pins, and formal
  properties via Hardcaml Verify.

## Layout

```
hw/      Hardcaml RTL
model/   OCaml reference models (no dependency on hw/)
test/    simulation testbenches
bin/     Verilog generator
src/     generated Verilog consumed by the Tiny Tapeout flow
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
dune runtest    # run all tests
dune promote    # accept expect-test output after checking the diff
```

## Metrics

Updated weekly from the hardening reports.

| Week | Design | Cells | Utilisation | Clock | Worst slack |
|------|--------|-------|-------------|-------|-------------|
| 1    | uart_tx | | | | |
