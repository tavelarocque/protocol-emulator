# Verification layers and planted bugs

The full tables behind the summary in the [README](../README.md).
[`design-and-verification.md`](design-and-verification.md) is the argument
that joins them.

## Layers

The specification is executable: [`model/isa.ml`](../model/isa.ml) is a reference
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
| Coverage closure | 16 cross bins random testing reaches rarely | AI-written directed scenarios, each judged by the same lockstep comparison and required to hit its own targets; they close every cross bin and catch every planted bug ([`docs/coverage-closure.md`](coverage-closure.md)) |
| Device mode | the I2C and SPI device firmware, on the model and the chip | the spec-derived reference controller (with one clock of data hold time and with none, 7 to 62 clocks of SCL low) writing, reading and register-reading through a repeated START, judged by the bus checker; a shared bus where the chip must ignore a model device at another address; the host late on both FIFOs so the chip must stretch; two model chips talking, the controller firmware on one and the target on the other; the whole chip over SPI. For SPI, the same with a spec-derived mode-0 controller, with and without gaps between bytes, a transfer abandoned mid-byte, and two chips (controller and device firmware) on four wires |
| Host driver | `host/protocol_emulator.py`, the MicroPython code the demo board runs | the same file, unchanged, run against the chip in cocotb (on the RTL and the gate-level netlist): it loads firmware and configures threads over the bit-banged host port, sends UART to cocotbext-uart's receiver, reads picosoc's SPI flash, and serves cocotbext-i2c's and cocotbext-spi's controllers as an I2C and an SPI device. Then in MicroPython itself, on an emulated demo board (rp2040js running Tiny Tapeout's firmware) wired to the RTL: UART, I2C, SPI, JTAG, SWD and USB against the same devices (1-Wire's driver runs there on a simulated bus; PS/2 and CAN do not run there yet), and the USB descriptor read with every handshake timed on the bus (`test/board_emu`) |
| SWD | the clock engine and the driver's framing | an SWD target written from Arm's ADIv5 (`test/swd_dp.v`), in cocotb on the RTL and the gate-level netlist: silent until the JTAG-to-SWD switch, then DPIDR, a power-up request acknowledged, an AP's IDR through a posted read and RDBUFF, an AP register written and read back; on the model, 300 random sequences checked against the engine's contract |
| 1-Wire | the bus engine and the driver's ROM layer | on the model: 360 random runs of resets and time slots with zero to three devices, each drawing its timing at random from the range the 1-Wire rules allow (sample point, how long a 0 is held, the presence pulse's delay and length), checking the bits both ways and the host's own pulse timing against the rules. In cocotb, against three copies of Iztok Jeras's 1-Wire slave model (sockit_owm, third-party, LGPL, test only) at the shortest, typical and longest legal timing, with a DS18B20's ROM and function layers above them: each device's ROM code and temperature alone, and with all three on one wire the ROM search finds every device and MATCH ROM reaches each. In MicroPython, the driver's search and CRC on a simulated bus agree with CPython's |
| PS/2 | the host firmware on both threads, and the driver | on the model: 150 random runs of traffic both ways against a device written from the protocol's rules, with its timing drawn at random from the legal range (clock phases, data setup, the delay before it clocks a host byte) and the host cutting in at the start of the device's frames and in the middle of them; every byte arrives exactly once each way, the receiver's record of the host's own byte matches, and the host's pulses meet the rules (100 us of CLK low to inhibit, DATA changed only while CLK is low). A device that does not acknowledge, and no device at all, are reported. In cocotb, on the RTL and the gate-level netlist, the driver resets and identifies a keyboard, sets its LEDs and reads a key press and release |
| CAN | the transmitter and listen-only receiver, and the driver | on the model: 120 random runs against a node written from ISO 11898-1's rules, with its own clock up to 1.25% off, which hard-synchronises and resynchronises, removes stuff bits as they come, checks the CRC, acknowledges good frames and sends frames of its own; in half the runs it starts in the same bit as the chip, so the two arbitrate. Every frame reaches the other side intact, the chip's are acknowledged, the loser of each arbitration stops without disturbing a bit and sends again, every bit the chip sends is exactly one bit time, and with no node the chip reports that nobody acknowledged. The CRC is checked against CRC-15/CAN's catalogued check value. In cocotb, on the RTL and the gate-level netlist, the driver sends a frame a node acknowledges and hears the node's own |
| Outside decoders | SWD, PS/2 and CAN, whose device models are this project's own | in cocotb, the pins are recorded and handed to sigrok's protocol decoders (`test/sigrok.py`): the whole SWD session, request by request with every ACK and data word; both CAN frames with identifier, data, CRC and ACK slot (the node's frame shows NACK, since the chip only listens); every PS/2 frame both ways. In each, one bit is then forced on the recorded wire and the decoder's verdict must change. The transmitters added on v2.0 (I2S, DMX512, Wiegand, NEC infrared) and the device protocols on existing engines (MIDI, MAX7219) have no device model at all: sigrok's decoder must read back exactly what the host asked for, and again the recording is damaged once and the reading must change |
| USB | the low-speed engine and the driver's packets | on the model: the encoder reproduces captured USB packets; 150 random batches of sent packets decode at a reference receiver written from the USB 1.1 spec and match the ideal waveform to the clock; 300 received packets from a device whose clock is up to 1.5% off either way; whole IN transactions with the ACK 2 to 7.5 bit times after the data, as the spec requires. In cocotb, against usbhostslave's USB device (third-party, LGPL, test only): SETUP acknowledged, a corrupted CRC16 ignored, and a full GET_DESCRIPTOR control transfer whose 18 bytes match the device's ROM |
| Third-party devices | the chip against device models written by other people from real datasheets | picosoc's Verilog SPI flash (wake, then a 0x03 read at a 24-bit address), cocotbext-i2c's I2C EEPROM (write, pointer set, read back), cocotbext-uart's UART sender and receiver, and, with the roles reversed, cocotbext-i2c's I2C controller driving the chip as a device at 400 kHz (probe, a write that makes it stretch the clock, a register read through a repeated START), cocotbext-spi's SPI controller reading the chip as a device (a JEDEC ID read and a command), and cocotbext-jtag's monitor decoding every scan while the chip, as a JTAG controller, reads an IEEE 1149.1 device's IDCODE, writes and reads back a register and goes through BYPASS; on the RTL and the gate-level netlist |
| Silicon netlist | post-layout gates | the same chip-level tests in cocotb, with separate Python protocol models, on RTL and gate-level netlist |
| **Formal, RTL to gates** | the post-layout netlist against the generated Verilog | **Yosys equivalence proof** in CI after every layout ([`gl_equiv/`](../gl_equiv)): 1,840 signals paired by name (every output pin and all 1,796 flip-flops), a base case from any state through one reset cycle, and an induction step, so the netlist and the RTL agree on every pin from the first cycle after reset; cells modelled from IHP's Liberty file. Four bugs planted in the netlist each break it |
| **Formal** | the whole chip RTL against an independent spec | **SAT equivalence proof** (Hardcaml_verify + Z3): one clock of the chip's top level equals one clock of [`sim/spec_top.ml`](../sim/spec_top.ml), for every state of every register and every input on the pins. The spec is a second description of everything: the SPI host port and register file (written from the protocol and register map in `hw/top.ml`'s header, with the map as a table and reads as one-hot terms), around [`sim/spec_core.ml`](../sim/spec_core.ml) (program memory, input synchronisers, pin levels, clock dividers, FIFOs, CHAIN, pin priority, pads, from the ISA document and the reference model), with [`sim/spec_step.ml`](../sim/spec_step.ml) as each thread's datapath, which itself matches the reference model on all 65,536 instruction words. The two sides share only register names, widths, reset values and the FIFO's state encoding, which the checker needs to pair registers. Bugs planted on the spec's side break the proof, so it is not vacuous |

Three practices run through all of it.

**Mutation testing, kept in the repo.** Every layer has deliberately planted
bugs, 86 in all, kept as code, and the suite fails if any survives. A test
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
| PS/2 | 9 in the firmware (the receiver never abandoning a frame, sampling as CLK rises, keeping an abandoned frame's bits; the transmitter inhibiting mid-frame, inhibiting for under 100 us, releasing CLK before DATA is low, changing DATA as CLK rises or before the receiver's sample, never reading the ACK), 1 in the driver (even parity) | all 10 |
| CAN | 9 in the firmware (the receiver never resynchronising, never resetting its count of recessive bits, ending a frame after 4, a tick short when no word is pushed; the transmitter's bits 11 ticks long, never checking the bus, not waiting for an idle bus, leaving a stopped frame's words in the FIFO, misreporting the ACK), 1 in the driver (a stuff bit after six equal bits) | all 10 |
| Host driver | pin modes packed one bit per pin | caught. All eight driver bugs (this one, the JTAG swap, the two SWD ones, the two 1-Wire ones, the PS/2 one and the CAN one) are planted by one cocotb test, which also checks each scenario passes with the real driver |
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
now matches. See [`docs/related-work.md`](related-work.md) for the
literature this draws on.

The hardware is frozen at v1.4: everything after it is firmware, testing
and documentation, none of which can put the chip at risk.
