# Submission summary

Tave La Rocque

The page to read first; every claim links to its evidence. The full report is
[`design-and-verification.md`](design-and-verification.md).

## The chip, and why it is flexible

The chip is a small two-thread CPU in the style of the RP2040's PIO. Its
instructions read pins, write pins and count clock cycles. Nothing in the
hardware knows what UART, SPI or I2C is: every protocol is a program, loaded
over an SPI port at run time, driving 8 protocol pins that are each input,
push-pull or open-drain. It is written in Hardcaml and designed for tapeout on
Tiny Tapeout's IHP 130 nm process, 8x4 tiles.

The hardware changed only when a protocol could not be done without it, and
then by a part that is not that protocol's. For 10 Mbit Ethernet, four clocks
a bit, v2.1 and v2.2 added a packet buffer, self-refilling shift registers, a
CRC register with any polynomial and a bit sampler that recovers a sender's
clock; the frame itself is still a program. The hardware has been frozen at
v2.3 since, and 58 of the 94 protocols in the repository came after that, as
firmware or host framing alone ([`firmware.md`](firmware.md) has the history).

## The census: protocols nobody here chose

Protocols this project chose cannot show whether the chip handles ones it was
not designed for. The census was built to answer that, under rules fixed and
pushed before it ran ([`flex/PREREG.md`](../flex/PREREG.md)). Twenty protocols
were drawn from sigrok's decoder list, which this project did not write,
leaving out those the chip already had; a public randomness beacon (drand) set
the order. Each went to an AI agent in a fresh session that had never seen the
project, with only a task sheet, the instruction set ([`isa.md`](isa.md)) and
the simulator. A hidden test it never saw gave the recorded pins to sigrok's
own decoder for that protocol and checked the timing limits the decoder does
not.

| Census ([`flex/RESULTS.md`](../flex/RESULTS.md)) | |
|---|---|
| Drawn | 20 |
| Out of reach: parallel buses of 11 and 14 lines (`z80`, `mcs48`) on 8 pins | 2 |
| Attempted, and passed on the first and only hand-in | 18 of 18 |
| Predicted before the draw | 12 to 16 of 20 |
| Mutants of the passing programs rejected by the hidden tests | 77 of 90; the 13 survivors traced, all inside their task sheets' limits |

FlexRay, LPC, AC'97 and the SD card's native bus, named in advance as the
likeliest to fail, all passed. A second question asked what two features are
worth: the first 8 passes were attempted again by new programmers, once on the
full chip and twice each on chips without the delay field and without
side-set. All 40 attempts passed. Without the delay field some programs
doubled (`rc_encode`: 20 and 29 instructions on the full chip, 51 and 55
without); without side-set, `maple_bus`, which moves two lines on nearly every
step, was 31 to 64 percent slower on the wire.

So the instruction set, as one document, was enough for programmers new to it
to implement every protocol chance gave them that fits on 8 pins, as judged by
tools this project did not write. The limits: the programmers were AI agents,
not people, who know PIO, which this chip resembles; it all ran on the
reference model, which the chip's own tests check against the RTL; and every
departure from the rules is listed in the results.

## What runs, and how it is judged

| In the repository's tests | |
|---|---|
| Protocols with firmware of their own | 45 |
| Framed by the driver on two senders that know no code (RC-6; Qi, EM4100, Morse) | 4 |
| Device protocols on those engines (MIDI, LIN, Modbus RTU and 42 devices) | 45 |
| Chip-level cocotb tests | 120 |
| Of those, judged by a protocol decoder this project did not write | 92 |
| Of the 92, with a fault forced on the wire that must change the verdict | 90 |

The 94 include UART, SPI and I2C in both roles and both stretch goals,
low-speed USB as a host and 10BASE-T Ethernet both ways. The decoders are
sigrok's, or for 27 protocols ones it does not ship, fetched at fixed commits
([`test/extra_decoders.sh`](../test/extra_decoders.sh)); device models by
other people are used where they exist. The
[README's protocol table](../README.md#protocols) gives every judge.

## Architecture in brief

![Block diagram of the chip](img/architecture.svg)

Each thread has 256 words of program memory in an SRAM macro; a 1024-word
packet buffer is in a third. The instruction set ([`isa.md`](isa.md)) departs
from PIO where PIO is weakest for protocols: a wait can time out, open-drain is
a pin mode, every 16-bit word is defined, and CHAIN feeds one thread into the
other. The v2.3 layout passes LVS and the Tiny Tapeout precheck, and timing
closes at 50 MHz at every corner ([`metrics.md`](metrics.md)). See it run in
[`demo.html`](demo.html), recorded runs of the reference model.

## How it was designed and verified

| Question | Evidence | Where |
|---|---|---|
| Does the RTL match the specification? | SAT proof that one clock of the whole chip equals an independent specification, from every state | `sim/test_formal.ml`, `ocaml` job |
| Does the gate netlist match the RTL? | Yosys proof after every layout: every output, all 1,107 flip-flops, every input to the memories | [`gl_equiv/`](../gl_equiv), `gl_equiv` job |
| Are the proofs' memories the chip's? | Yosys proof against IHP's models of the SRAM macros | [`formal/`](../formal), `ocaml` job |
| Does the RTL behave like the reference model? | 400 random two-thread programs compared every cycle; coverage that fails the build on any zero | `sim/lockstep.ml`, [`coverage-closure.md`](coverage-closure.md) |
| Do the protocols work on the gates? | The cocotb suite again on the post-layout netlist | `gl_test` job |
| Would the tests notice a bug? | 400 planted bugs, kept as code; the build fails if one survives | [`verification-layers.md`](verification-layers.md) |
| Does the real driver work? | The MicroPython driver, unchanged, in cocotb and on an emulated board | `test/board_emu`, `board` job |

Each revision of the instruction set came from a protocol that did not fit,
and each hardware change went in after its model, specifications, proofs and
planted bugs. The reference model ([`model/isa.ml`](../model/isa.ml)) does not
depend on the hardware, so the two cannot share a bug, and the protocols are
judged by the outside decoders above. Thirteen real bugs, and the layer that
found each, are told in [`bug-ledger.md`](bug-ledger.md).

## Limits

- Everything is simulation, formal proof and an emulated board. Nothing has
  run on an FPGA or on silicon, and 50 MHz rests on static timing analysis
  alone.
- The Ethernet receiver stands less jitter than the standard asks, so it needs
  a clean, short link; it has been tested only against a sender written here.
  The chip sends a frame or receives frames, not both.
- USB is low speed and host only; the CAN node sends no error frames; I3C
  keeps SDA open-drain, at 2 MHz. The rest: section 7 of the report.

## How AI was used

An AI model, working as an assistant in this repository, wrote most of the
RTL, firmware, tests and documents; the commits it co-wrote say so. The author
set the goals, chose what to build and what to leave out, and approved every
change before it was pushed. Among his decisions: freezing the hardware at
v2.3, so the remaining time went to verification and the write-up; repairing
the layout's slew and capacitance warnings before submitting; making the
pre-registered blind census the headline evidence; and the direction of the
demo page.

The census's examiners and programmers were AI agents, each in a fresh
session; the programmers never saw the repository. In coverage closure the
assistant wrote directed tests and the reference model judged them
([`coverage-closure.md`](coverage-closure.md)). Correctness rests on judges
written separately or by other people (section 6 of the report).

## Where to find everything

| Asked for | Where |
|---|---|
| RTL, tests, passing GDS and precheck | `hw/`, `sim/`, `test/`; the `gds` workflow |
| Architecture and instruction set | [`isa.md`](isa.md), [`info.md`](info.md), [`firmware.md`](firmware.md) |
| Assembler, simulator, example programs | `model/asm.ml`, `bin/pe_sim.ml`, [`examples/`](../examples) |
| Flexibility evidence | [`flex/RESULTS.md`](../flex/RESULTS.md), [`flex/census/`](../flex/census) |
| Host and program loading | [`info.md`](info.md); `host/protocol_emulator.py` and the other drivers in `host/` |
| Reproducing | `./reproduce.sh`; "Running" in the [README](../README.md#running) |
