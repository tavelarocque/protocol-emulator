![](../../workflows/gds/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/ocaml/badge.svg)

# protocol-emulator

An open-source protocol emulator ASIC for the
[Jane Street protocol emulator competition](https://blog.janestreet.com/protocol-emulator-asic-competition/):
a tiny CPU whose instructions read pins, write pins and count cycles, so UART,
SPI and I2C are implemented in firmware loaded after fabrication rather than in
fixed logic. Written in Hardcaml, designed for tapeout through
[Tiny Tapeout](https://tinytapeout.com) on IHP 130nm CMOS5L (6x4 tiles).

**Status:** a complete two-thread chip running all three required protocols,
two at a time, including an I2C-to-SPI bridge that runs with no host in the
data path. An SPI host port loads firmware and configuration into a
PIO-style core: two threads sharing a 64-word program memory and 8 protocol
pins (input, push-pull or open-drain each). UART TX, I2C controller (with clock
stretching and timeouts) and SPI controller firmware, loaded over SPI, run on
the RTL and on the post-layout gate-level netlist; side-set SPI at 5 Mbit/s
and a UART run side by side from one memory image. The chip can also be the
device rather than the controller: as an I2C target it answers an outside
controller (cocotbext-i2c's, at 400 kHz) with writes, register reads through a
repeated START, and clock stretching; as an SPI device it answers an outside
mode-0 controller (cocotbext-spi's, at 500 kHz) full duplex. It is also a
low-speed USB host (the competition's stretch goal): at a 12 MHz core clock
it reads a device descriptor from a third-party USB device core with a full
control transfer, receiving with its own clock recovery. The whole chip, from the Tiny Tapeout
pins in to the pins out (SPI host port, register file, both threads and the
logic joining them), is formally proven equivalent to an independent
specification, and after every layout the post-layout gate netlist is
formally proven equal to the RTL.

## Architecture

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

It departs from PIO where PIO is weakest for protocol emulation:

| | RP2040 PIO | This core |
|---|---|---|
| Waiting on a pin | blocks forever | optional timeout, jumps to a per-thread vector |
| I2C / open-drain | emulated by toggling pin direction | per-pin open-drain mode in hardware |
| Bit timing | fractional clock divider | counter loops, value supplied by the host at run time |
| Program loading | internal bus | SPI port, so any external host can load firmware |
| Undefined encodings | n/a | none: every 16-bit word is a defined instruction |

Firmware ([`model/firmware.ml`](model/firmware.ml)): UART TX in 15
instructions, UART RX in 15 (tolerates the sender's baud rate off by about
5%, the limit for a mid-bit sampler), SPI controller in 27 (9 cycles per bit), side-set SPI in 26 (2
cycles per bit, 5 Mbit/s at 10 MHz), I2C controller in 49 (writes only, timed
by loops), I2C controller with reads in 25 (timed by the clock divider), and
I2C target in 63 (the chip as a 7-bit-address device: address match, ACK,
STOP and repeated START detection, stretching while either FIFO waits on the
host), SPI device in 23 (mode 0 up to 625 kHz at 10 MHz, deselect seen
even mid-byte), JTAG controller in 11 (any TMS/TDI sequence the host asks
for, TDO back, TCK at 2 MHz), and an Arm SWD clock engine in 11 (the board
driver adds the SWD framing: line reset, the JTAG-to-SWD switch, parity, ACK,
turnaround, posted AP reads), and a low-speed USB engine in 49 (send a packet
at exactly 8 clocks per bit with EOP, or receive one with clock recovery
that re-aligns on every edge and detects EOP; the board driver builds and
checks packets, CRCs and the control-transfer logic), and a 1-Wire bus engine
in 25 (reset and presence, read and write time slots at standard speed; the
board driver adds the ROM commands, the ROM search and CRC8; written after
the hardware was finished, as firmware alone), and a WS2812 LED driver in 16,
written blind: by a programmer (an AI agent) given only `docs/isa.md` and the
simulator, which passed a hidden test of the LEDs' data-sheet timing on its
first submission, in about five minutes (`examples/ws2812`); program memory
is 64 words. The assembler places a program at any origin, so
two fit in one image: full-duplex UART (TX and RX on the two threads),
side-set SPI beside UART, and the bridge, divider I2C
beside side-set SPI with CHAIN carrying every byte read over I2C out over SPI.
The ISA is at v1.4, and each revision came from building something:
writing the I2C controller showed that 32 words was too small and that a wait
timeout counted down in Y could never exceed one half bit-period, so the memory
doubled and timeouts got their own counter; writing SPI showed that toggling a
clock with a separate instruction costs most of the bit time, so side-set
followed; building the bridge showed that the I2C controller's delay loops
were a third of its size, so the clock divider followed; reviewing the design
for silicon rather than simulation showed the protocol pins had no input
synchronisers, so they got them; and making every SPI host bit-reverse its
bytes was an interface wart, so threads got a shift direction.

## Verification

[`docs/design-and-verification.md`](docs/design-and-verification.md) is the
report: the design decisions and their alternatives, how the layers of
evidence chain into a claim about the chip, which layer catches which class
of bug, the real bugs found, and what is not covered. This section lists
the layers.

The specification is executable: [`model/isa.ml`](model/isa.ml) is a reference
model written for clarity, with no dependency on the hardware, so the two
cannot share a bug. Everything else is checked against it or against
independent protocol oracles.

| Layer | What is checked | How |
|---|---|---|
| ISA encoding | all 65,536 instruction words | exhaustive encode/decode and disassemble/assemble round trips |
| Firmware | UART TX on the model | cycle-exact against an ideal waveform, plus a mid-bit-sampling receiver, over random bytes and baud rates |
| Core RTL | `hw/pe_core.ml` against the model | lockstep differential test: 400 random programs × 300 cycles, both threads with random configs, random pins, host traffic on both threads and threads enabled and disabled at random; the full state of both threads and the pins compared every cycle |
| Two threads | demo images on the model and the chip | SPI and UART running together, each judged by its own oracle; isolation: the SPI waveform is identical, cycle for cycle, whether or not the UART thread runs; the bridge: an I2C read (checked by the I2C oracles) comes out as one SPI transfer (checked by the SPI oracles), with the host never touching the data |
| Whole chip | `hw/top.ml` through its pins only | bit-banged SPI host: register read-back, echo firmware through both FIFOs, UART firmware decoded on the pin |
| Protocols | UART, I2C, SPI firmware | independent protocol oracles on the pins: UART waveform + receiver, and an off-rate frame generator (fractional bit times) driving the UART receiver; I2C bus checker + target device that ACKs and stretches SCL; SPI mode-0 checker + slave with scripted responses |
| Coverage closure | 16 cross bins random testing reaches rarely | AI-written directed scenarios, each judged by the same lockstep comparison and required to hit its own targets; they close every cross bin and catch every planted bug ([`docs/coverage-closure.md`](docs/coverage-closure.md)) |
| Device mode | the I2C and SPI device firmware, on the model and the chip | the spec-derived reference controller (with one clock of data hold time and with none, 7 to 62 clocks of SCL low) writing, reading and register-reading through a repeated START, judged by the bus checker; a shared bus where the chip must ignore a model device at another address; the host late on both FIFOs so the chip must stretch; two model chips talking, the controller firmware on one and the target on the other; the whole chip over SPI. For SPI, the same with a spec-derived mode-0 controller, with and without gaps between bytes, a transfer abandoned mid-byte, and two chips (controller and device firmware) on four wires |
| Host driver | `host/protocol_emulator.py`, the MicroPython code the demo board runs | the same file, unchanged, run against the chip in cocotb (on the RTL and the gate-level netlist): it loads firmware and configures threads over the bit-banged host port, sends UART to cocotbext-uart's receiver, reads picosoc's SPI flash, and serves cocotbext-i2c's and cocotbext-spi's controllers as an I2C and an SPI device. Then in MicroPython itself, on an emulated demo board (rp2040js running Tiny Tapeout's firmware) wired to the RTL: every protocol class against the same devices, and the USB descriptor read with every handshake timed on the bus (`test/board_emu`) |
| SWD | the clock engine and the driver's framing | an SWD target written from Arm's ADIv5 (`test/swd_dp.v`), in cocotb on the RTL and the gate-level netlist: silent until the JTAG-to-SWD switch, then DPIDR, a power-up request acknowledged, an AP's IDR through a posted read and RDBUFF, an AP register written and read back; on the model, 300 random sequences checked against the engine's contract |
| 1-Wire | the bus engine and the driver's ROM layer | on the model: 360 random runs of resets and time slots with zero to three devices, each drawing its timing at random from the range the 1-Wire rules allow (sample point, how long a 0 is held, the presence pulse's delay and length), checking the bits both ways and the host's own pulse timing against the rules. In cocotb, against three copies of Iztok Jeras's 1-Wire slave model (sockit_owm, third-party, LGPL, test only) at the shortest, typical and longest legal timing, with a DS18B20's ROM and function layers above them: each device's ROM code and temperature alone, and with all three on one wire the ROM search finds every device and MATCH ROM reaches each. In MicroPython, the driver's search and CRC on a simulated bus agree with CPython's |
| USB | the low-speed engine and the driver's packets | on the model: the encoder reproduces captured USB packets; 150 random batches of sent packets decode at a reference receiver written from the USB 1.1 spec and match the ideal waveform to the clock; 300 received packets from a device whose clock is up to 1.5% off either way; whole IN transactions with the ACK 2 to 7.5 bit times after the data, as the spec requires. In cocotb, against usbhostslave's USB device (third-party, LGPL, test only): SETUP acknowledged, a corrupted CRC16 ignored, and a full GET_DESCRIPTOR control transfer whose 18 bytes match the device's ROM |
| Third-party devices | the chip against device models written by other people from real datasheets | picosoc's Verilog SPI flash (wake, then a 0x03 read at a 24-bit address), cocotbext-i2c's I2C EEPROM (write, pointer set, read back), cocotbext-uart's UART sender and receiver, and, with the roles reversed, cocotbext-i2c's I2C controller driving the chip as a device at 400 kHz (probe, a write that makes it stretch the clock, a register read through a repeated START), cocotbext-spi's SPI controller reading the chip as a device (a JEDEC ID read and a command), and cocotbext-jtag's monitor decoding every scan while the chip, as a JTAG controller, reads an IEEE 1149.1 device's IDCODE, writes and reads back a register and goes through BYPASS; on the RTL and the gate-level netlist |
| Silicon netlist | post-layout gates | the same chip-level tests in cocotb, with separate Python protocol models, on RTL and gate-level netlist |
| **Formal, RTL to gates** | the post-layout netlist against the generated Verilog | **Yosys equivalence proof** in CI after every layout ([`gl_equiv/`](gl_equiv)): 1,840 signals paired by name (every output pin and all 1,796 flip-flops), a base case from any state through one reset cycle, and an induction step, so the netlist and the RTL agree on every pin from the first cycle after reset; cells modelled from IHP's Liberty file. Four bugs planted in the netlist each break it |
| **Formal** | the whole chip RTL against an independent spec | **SAT equivalence proof** (Hardcaml_verify + Z3): one clock of the chip's top level equals one clock of [`sim/spec_top.ml`](sim/spec_top.ml), for every state of every register and every input on the pins. The spec is a second description of everything: the SPI host port and register file (written from the protocol and register map in `hw/top.ml`'s header, with the map as a table and reads as one-hot terms), around [`sim/spec_core.ml`](sim/spec_core.ml) (program memory, input synchronisers, pin levels, clock dividers, FIFOs, CHAIN, pin priority, pads, from the ISA document and the reference model), with [`sim/spec_step.ml`](sim/spec_step.ml) as each thread's datapath, which itself matches the reference model on all 65,536 instruction words. The two sides share only register names, widths, reset values and the FIFO's state encoding, which the checker needs to pair registers. Bugs planted on the spec's side break the proof, so it is not vacuous |

Three practices run through all of it.

**Mutation testing, kept in the repo.** Every layer has deliberately planted
bugs, 66 in all, kept as code, and the suite fails if any survives. A test
suite that has never failed has not been shown to work.

| Layer | Planted bugs | Caught |
|---|---|---|
| UART bring-up | 3 (short stop bit, MSB-first, slow bits) | 3, with the oracle that caught each |
| Core RTL | 10: six datapath bugs planted in thread 1 only (X never decrements, timeout ignores budget, delay ignored, SET ignores pin count, PUSH not right-justified, PUSH ignoring the shift direction), three in how the threads are joined (pin priority inverted, thread 1 fetching from thread 0's PC, CHAIN moving a word into a full FIFO), and the synchroniser bypass read with inverted polarity | all 10, within 16 random programs |
| UART TX firmware | start bit one clock short, wrong loop condition | both, by the cycle-exact check; a real receiver misses the short start bit in all 300 cases |
| SPI host port | MISO shifts one edge early (`Top.Mutation`) | refuted by the whole-chip proof, and caught through the pins by register read-back and echo |
| Formal proof | the same 10 core bugs, plus 3 planted in the specs themselves (CHAIN ignoring a full FIFO; STATUS levels swapped; RX popped by a write) | all 13 refuted with SAT counterexamples. A fourth spec-side candidate (an empty RX FIFO popped by a read) came back UNSAT: the proof showed it was not a bug, since the FIFO ignores that pop |
| I2C firmware | SDA moved before SCL falls; STOP raised with SCL low (divider version) | both, by the bus checker |
| I2C target firmware | 6: never ACKs, answers every address, repeated START missed, STOP missed, no stretching on a full RX FIFO, and SCL checked before SDA when watching for STOP and repeated START | all 6; the last only by a controller with zero data hold time (legal in the spec) swept across speeds |
| JTAG firmware | 3 (plus 1 in the driver): TCK left high after the edge, TDO never sampled, a scan's last TDO bits never pushed; TMS and TDI swapped in the driver | all 4 |
| SWD | 3 in the firmware (SWDIO never driven, SWDIO moving in the same clock as SWCLK rises, last samples never pushed), 2 in the driver's framing (request parity inverted, write turnaround missing) | all 5: the firmware ones by random tests against the engine's contract, the driver ones by an ADIv5 target |
| SPI device firmware | 5: MOSI sampled after SCK falls, no wait for SCK to fall, deselect never seen, reply bits lost to the poll, deselect dropping the queued reply | all 5 |
| SPI firmware | MOSI moved after SCK rises | caught by the mode-0 checker |
| 1-Wire | 6 in the firmware (reset pulse 16 us short, presence sampled 16 us early, slot sampled 1 us late, a 0 held 16 us too briefly, too little rest after a reset, slots ignoring the bits written), 2 in the driver (bytes sent most significant bit first, a search that never revisits a fork) | all 8: the firmware ones by the model's timing rules and its devices at the edges of the legal range, the driver ones against the slave models in cocotb |
| Host driver | pin modes packed one bit per pin | caught. All six driver bugs (this one, the JTAG swap, the two SWD ones and the two 1-Wire ones) are planted by one cocotb test, which also checks each scenario passes with the real driver |
| USB | 7 in the firmware (4 sending: a word boundary one clock short, SE0 one bit time, drivers released during EOP's J, no idle gap between packets; 3 receiving: waiting on the wrong pin, no end marker, sampling late after an edge), 2 in the driver (CRC16 not inverted, received levels read inverted) | all 9; the short word boundary only by the cycle-exact check, the released drivers and missing gap only by the timing checks, since a receiver forgives them |
| Gate netlist | 4: a NAND turned NOR, a flip-flop stuck in reset, two flip-flops' inputs crossed, a wrong reset value | all 4, by the RTL-to-netlist proof (the first three break its induction step, the last its base case) |

Two oracles exist because each misses things alone. A start bit one clock
short decodes fine at a real receiver in all 300 test cases and is caught
only by the cycle-exact check.

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

The hardware is frozen at v1.4: everything after it is firmware, testing
and documentation, none of which can put the chip at risk.

## Layout

```
hw/      Hardcaml RTL: pe_core (two threads), tiny_fifo, top (SPI port + registers)
model/   reference model, assembler, firmware, UART oracles (no dependency on hw/)
bin/     pe_sim: assemble a .s file, or run it on the reference model and print
         the pins as they change (`dune exec bin/pe_sim.exe -- run -help`)
examples/ws2812: the blind firmware test, task, notes and hidden test
sim/     OCaml tests: ISA, lockstep harness, random and directed differential tests,
         formal proof, firmware, chip-level tests
bin/     Verilog generator, firmware hex generator
host/    MicroPython driver for the demo board, RP2040 or RP2350 (tested in cocotb, unchanged,
         and in MicroPython on an emulated board: test/board_emu)
src/     Verilog for Tiny Tapeout: project.v (pin map) + generated protocol_emulator.v
test/    cocotb testbench (RTL and gate-level) + generated firmware .hex;
         usbhostslave/ is a third-party USB device core and onewire_slave_model.v
         a third-party 1-Wire device model (both LGPL, test only)
gl_equiv/ Yosys proof that the post-layout netlist equals the RTL (run in CI)
docs/    design-and-verification.md (the report), isa.md (instruction set),
         info.md (datasheet), coverage-closure.md, related-work.md
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
then `cd test && make`. The RTL-to-netlist proof needs Yosys
(`pip install yowasp-yosys`), the netlist from a layout build's
`tt_submission` artifact and IHP's standard-cell Liberty file:
`python3 gl_equiv/check.py --netlist <netlist.v> --lib <cells.lib> --mutants --yosys yowasp-yosys`.
The board emulation needs Verilator and Node 22: `make -C test/board_emu`,
then `node run_usb.mjs` there (see `test/board_emu/README.md`).

## Metrics

From the GDS build reports. Timing is checked at the flow's target clock,
50 MHz (20 ns) for the builds below and 40 MHz (25 ns) from the ttihp27a
flow on, at the worst (slow, hot) corner; the chip is specified for 10 MHz.

| Design | Std cells | Utilisation (6x4) | Setup slack | Hold slack |
|--------|-----------|-------------------|-------------|------------|
| UART bring-up | 328 | 0.5% | +12.4 ns | +0.17 ns |
| Full chip v0 (SPI + 1-thread core, 32 words) | 8,002 | 12.5% | +6.3 ns | +0.14 ns |
| Full chip v1.1 (1 thread, 64 words, side-set) | 11,838 | 19.1% | +3.87 ns | +0.13 ns |
| Full chip v1.3 (2 threads, divider, CHAIN, input synchronisers) | 17,665 | 27.2% | +0.77 ns | +0.12 ns |
| Full chip v1.4 (adds shift direction), first build | 18,830 | 28.3% | **−0.14 ns** | +0.12 ns |
| Full chip v1.4, current build (same logic; registers named for the formal proofs) | 18,817 | 28.3% | +1.19 ns | +0.12 ns |

The first v1.4 build missed 50 MHz by 0.14 ns on one path, at the slow
corner only (1.08 V, 125 °C). The current build, the same logic with its
registers named for the formal proofs, meets 50 MHz at every corner with
1.19 ns to spare at the slow one. A 1.3 ns swing with no logic change is
placement varying from one layout run to the next, so 50 MHz is not claimed:
the chip is specified for 10 MHz (100 ns, about 80 ns of slack in every
build). The 20 ns target was left as it was rather than relaxed to make the
report clean, until the move to Tiny Tapeout's ttihp27a flow, the one the
IHP shuttle uses. Its default LibreLane (3.1.0.dev4) synthesised the same
RTL into 18,426 cells rather than 14,316, about 2,600 of them buffers the
earlier builds never used (they had 23), and routed, that needed 4.4 m of
wire rather than 1.5 m. The first build failed setup at 20 ns; the second,
with the cells spread out, was still detail-routing when GitHub stopped it
at 6 hours. Builds now pin LibreLane 3.1.0.dev3, which every earlier build
used, and the target is 25 ns (40 MHz, still more than three times the
12 MHz USB needs) for margin. Every v1.4 build has 0 DRC and 0 LVS errors and passes the
Tiny Tapeout precheck and the cocotb suite on the gate-level netlist,
including the third-party controller tests that drive the chip as an I2C and
an SPI device; from the current build on, the netlist is also formally
proven equal to the RTL. Two-thread layouts take
about 4 to 5 hours, most of it detailed routing (v1.1 took 91 minutes).
