# Submission summary

For a reader with ten minutes. Every claim links to where it is
shown; [`design-and-verification.md`](design-and-verification.md) is the
full report.

## The claim: protocols are programs

![Block diagram of the chip](img/architecture.svg)

A laid-out chip in 3D, with the reference model running firmware on it:
[`chip.html`](chip.html) (one self-contained file; download and open it, or
[view it here](https://htmlpreview.github.io/?https://github.com/tavelarocque/protocol-emulator/blob/main/docs/chip.html)).
It shows v1.4's layout; the layouts since, with the memories in SRAM
macros, have not been rendered yet.

The chip is a small CPU whose instructions read pins, write pins and count
clock cycles. A protocol is a program, loaded over SPI after fabrication;
the largest here is 70 instructions. Nothing in the hardware knows what
UART, SPI or I2C is.

The evidence that this is general is what happened after the hardware was
frozen at v1.4. Nine protocol engines were then added, each as firmware alone, with
no change to the RTL:

| Added after the freeze | What it needed from the hardware | Instructions |
|---|---|---|
| I2C target, with clock stretching and repeated START | nothing new | 63 |
| SPI device | nothing new | 23 |
| JTAG controller | nothing new | 11 |
| Arm SWD host | nothing new | 11 |
| Low-speed USB host, with clock recovery (a stretch goal) | nothing new; a 12 MHz clock | 49 |
| 1-Wire, with ROM search | nothing new | 25 |
| PS/2 host, receiving and sending on the two threads | nothing new | 11 + 21 |
| CAN transmitter and listen-only receiver, to 1 Mbit/s | nothing new | 19 + 27 (now a node, 59 + 89, on later hardware: see below) |
| WS2812 LEDs | nothing new | 16 |

The last was a blind test. A programmer who had never seen the project (an
AI agent in a fresh session) was given only [`isa.md`](isa.md) and the
simulator, and wrote the driver in about five minutes. A hidden test, which
decodes the pin the way the LED's data sheet says an LED does, passed on the
first submission. The seven things the programmer found unclear in the
document are fixed. Task, notes and hidden test:
[`examples/ws2812`](../examples/ws2812).

v2.0 then changed one thing in the hardware, the program memory: 256 words
for each thread in an SRAM macro, where v1.4 had 64 words of flip-flops
shared by both. Every v1.4 program runs on it unchanged. Eleven more
engines followed, again as firmware alone: I2S, DMX512, Wiegand and NEC
infrared in both directions, RC-5 infrared, MDIO, DALI, PWM and a NES
gamepad. Sixteen further protocols needed no firmware at all, only framing
in the host driver on an engine the chip already had: MIDI, LIN, Modbus
RTU, and thirteen devices on I2C and SPI, among them four radios, an SD
card and an Ethernet controller. That makes 35 protocols, every one with a
test judged by something this project did not write.

**Then Ethernet, where the hardware had to grow.** A 10 Mbit bit lasts
four clocks at 40 MHz. That is too few for a thread to fetch a word,
compute a CRC or time an edge, and the host port is too slow to supply a
frame. Two revisions added four parts, and none of them is Ethernet's:

| Added | What it is | Who else can use it |
|---|---|---|
| Packet buffer (v2.1) | a 1024-word SRAM the chip plays into a thread's FIFO or records from one | any protocol whose data outruns the host |
| Autopull, autopush (v2.1) | shift registers that refill and empty themselves | any engine short of cycles |
| CRC register (v2.1) | 32 bits, any polynomial, follows the bits shifted | CRC-16/USB and CRC-15/CAN give their published check values on it |
| Bit sampler (v2.2) | clock recovery for one pin from samples on both clock edges, timing in registers, with a sync word | other Manchester and NRZ codes up to a quarter of the clock |

The preamble, the Manchester code, where the CRC goes and where the frame
ends are still programs: 70 instructions to send, 14 to receive. Every
earlier program runs unchanged, and no instruction changed its meaning.
That makes 36 protocols, with both of the competition's stretch goals
among them. Three more have followed as firmware alone, each judged by a
sigrok decoder: Microwire with a 93C46 EEPROM, an HDMI-CEC initiator, and
RC-6 infrared on a burst sender that serves any remote control code.
And four more devices run on the I2C controller, read through the
repeated START it can now send: an RTC-8564 clock, a TCA6408A port
expander, an MXC6225XU accelerometer and a monitor's EDID. That is 43.

**Then CAN, from a transmitter to a node.** The v1.4 engine sent frames
the host had made and listened. On v2.1's CRC register the transmitter
makes the whole frame itself: bit stuffing, CRC-15, arbitration. A node
must also acknowledge the frames of others, which means deciding within
one bit time of a frame's last CRC bit whether the frame was good. v2.3
gave the bit sampler three settings for that, and again none is CAN's: a
prescaler (one sample every n clocks, so a slow line is sampled at a
thread's own tick), a pin shift (the recovered bit shown on a pin other
than the one it listens to) and stuff-bit removal (the bit after n equal
bits dropped). With them a 59-instruction receiver reads a frame a bit at
a time, checks the CRC on the CRC register and drives the ACK slot.

The prescaler also takes the sampler down to slow codes. DALI at 1200
bit/s and RC-5 infrared at 562 are received through the block that
recovers 10 Mbit Ethernet, with 9 instructions each: RC-5 locked to the
edge in the middle of each bit, as Ethernet is, and DALI, whose frames
begin on an edge between bits, sampled every half bit.

## What it is, and what is different

Two threads run at once, each from its own 256-word program memory, over 8
protocol pins that are each input, push-pull or open-drain, with a
1024-word packet buffer beside them. Every
instruction takes one clock plus a 0 to 15 clock delay. Written in
Hardcaml; laid out on IHP 130 nm CMOS5L, 8x4 Tiny Tapeout tiles.

The instruction set follows the RP2040's PIO and departs from it where PIO
is weakest for emulating protocols:

- **A wait can time out**, jumping to a per-thread vector. A device that
  never answers cannot hang the chip; I2C clock stretching and UART framing
  recovery are built on it.
- **Open-drain is a pin mode**, in hardware, not emulated by toggling
  direction.
- **Threads can signal each other through a pin.** A thread reads another's
  output with no delay; the PS/2 receiver uses a spare pin to tell the
  transmitter a frame is under way.
- **Every 16-bit word is a defined instruction.** No program can put the
  chip in an undefined state.
- **CHAIN** feeds one thread's output FIFO into the other's input, so the
  I2C-to-SPI bridge runs with no host in the data path.
- **Any host can load it**: the port is plain SPI.
- **The chip does the fast parts of a fast protocol itself**: a CRC
  register, a packet buffer and a bit sampler, each a general part set up
  by registers.

Each revision of the instruction set came from writing a protocol and
finding what was missing; [`firmware.md`](firmware.md) tells that story.

## What it runs

| Protocol | Role | Instructions |
|---|---|---|
| UART | TX and RX, full duplex on the two threads | 15 + 15 |
| SPI | controller (5 Mbit/s at 10 MHz) and device | 26, 23 |
| I2C | controller and target, clock stretching, timeouts, repeated START | 30, 63 |
| I2C-to-SPI bridge | both threads, no host in the data path | 30 + 26 |
| JTAG and SWD | controller, host | 11, 11 |
| Low-speed USB | host, with clock recovery | 49 |
| 1-Wire | bus controller, ROM search | 25 |
| PS/2 | host, both directions | 11 + 21 |
| CAN | a node: sends with bit stuffing, CRC and arbitration; receives, checks the CRC and acknowledges | 59 + 89 |
| 10BASE-T Ethernet, 10 Mbit/s | transmitter with link pulses; receiver with clock recovery | 70, 14 |
| WS2812 LEDs | driver | 16 |
| I2S | transmitter, 16-bit stereo | 11 |
| DMX512 | transmitter | 26 |
| Wiegand | transmitter and receiver | 17, 16 |
| NEC infrared | transmitter with its 38 kHz carrier; receiver | 25, 33 |
| RC-5 infrared | transmitter with its 36 kHz carrier; receiver through the bit sampler | 37, 9 |
| MDIO | controller, reads and writes | 7 |
| DALI | controller: transmitter on one thread, receiver through the bit sampler on the other | 17, 9 |
| PWM, RC servo | generator, exact to the cycle | 8 |
| Microwire | controller; a 93C46 EEPROM on it | 10 |
| HDMI-CEC | initiator, with each block's acknowledgement | 38 |
| RC-6 infrared | transmitter with its 36 kHz carrier, on a burst sender | 7 |
| NES gamepad | host | 7 |
| MIDI, Modbus RTU | on the UART transmitter | no new firmware |
| LIN | master frames, on the DMX512 transmitter | no new firmware |
| 24Cxx EEPROM, DS1307 clock, LM75 sensor | on the I2C controller | no new firmware |
| SPI NOR flash, WS2801 LEDs, MAX7219 | on the SPI controller | no new firmware |

![SPI controller waveform from the reference model](img/spi.svg)

Each is an assembly file in [`examples/`](../examples), generated from the
firmware the tests run. The toolchain is the assembler and `pe_sim`, which
runs a program on the reference model and prints the pins.

## Why to believe it works

1. **An executable specification.** A reference model with no dependency on
   the hardware; the RTL is compared with it every cycle over 400 random
   two-thread programs.
2. **Three formal proofs.** The whole chip's RTL, pins to pins, is proven
   equivalent to an independent specification (SAT, Z3). After every
   layout, the post-layout gate netlist is proven equal to the RTL (Yosys:
   every output pin, all 1,107 flip-flops and every pin of the three
   memories). And the memories those two proofs assume are proven equal to
   IHP's own models of the SRAM macros.
3. **Judges written by other people.** Every protocol except Ethernet is
   checked by something this project did not write. Device models:
   picosoc's SPI flash, cocotbext's I2C, SPI, UART and JTAG, usbhostslave's
   USB device, sockit_owm's 1-Wire slave. For USB, 1-Wire, WS2812, SWD, PS/2,
   CAN and every protocol added after them but Ethernet, the recorded pins
   go to sigrok's protocol decoders, 41 tests in all, 39 of them with a
   fault planted on the wire to show the decoder's verdict can change. Ethernet's sender and
   receiver are written here from IEEE 802.3, with `zlib`'s CRC-32; the
   sender has its own clock, 100 ppm off, and jitter on every edge.
4. **Tests that are themselves tested.** 176 bugs are planted in the RTL,
   firmware, drivers, specifications and netlist, kept in the repository,
   and the build fails if any survives. Functional coverage also fails the
   build on any zero.
5. **The gates, not only the RTL.** All 69 chip-level tests pass on the
   post-layout netlist, with IHP's models of the SRAMs in place of the
   macros. That includes Ethernet at a 40 MHz clock, both ways.
6. **The software that will run on the board.** The MicroPython driver is
   tested unchanged in cocotb, and in MicroPython on an emulated demo
   board, where a real timing bug in the USB handshake was found and
   fixed, and where the driver was found too large to compile on the
   board's microcontroller and was split.

## Layout

| | |
|---|---|
| Tiles | 8x4 |
| Standard cells | 14,837, and three SRAM macros; 23.8% utilisation |
| Flip-flops | 1,107 |
| Clock target | 20 ns (50 MHz); the firmware here runs the chip at 10 MHz, 12 MHz for USB and 40 MHz for Ethernet |
| Setup and hold, every corner | met |
| LVS, antenna | pass; Tiny Tapeout precheck (IHP's KLayout rule deck) passes |
| Layout time | under 40 minutes |

v2.0 was also laid out at 25 ns and at 16 ns and met timing at every
corner both times; 20 ns keeps a margin. v1.4, with its program in
flip-flops, was 17,925 cells and met 25 ns; v2.0 was 10,359. The
comparison is in [`metrics.md`](metrics.md).

## What is not shown

Stated here so nobody has to find it.

- **No silicon and no FPGA run yet.** Everything above is simulation, formal
  proof and an emulated board.
- **Signoff warnings, not yet explained.** Every layout since v2.0 has
  maximum-slew and maximum-capacitance warnings at all three corners.
  Setup and hold are met everywhere. The SRAM macros' pins are the
  suspect, and that is not confirmed ([`metrics.md`](metrics.md)).
- **Speed is static timing analysis only.** The Ethernet tests clock the
  chip at 40 MHz, but a simulation has no gate delays in it.
- **The Ethernet receiver needs a clean, short link.** It receives every
  frame with each edge up to 6 ns from its place at 40 MHz (10 ns at
  50 MHz); the standard asks a receiver for 13.5 ns, which samples
  12.5 ns apart cannot give. It has been tested only against a sender
  written here, never a real link.
- **Ethernet is one way at a time.** One packet buffer: the chip sends a
  frame or receives frames. It needs a transformer and a line receiver
  outside the chip.
- **The SRAM macros themselves are trusted.** The proofs and the tests use
  IHP's behavioural models of them. That the silicon macros behave as
  those models say is IHP's to guarantee.
- **USB is low speed, host only**, and needs a 12 MHz core clock.
- **CAN is a node with limits.** It sends data frames, and receives and
  acknowledges other nodes' data and remote frames with 11-bit
  identifiers. It sends no error frames (a frame it finds wrong it does
  not acknowledge), it neither receives nor acknowledges 29-bit
  identifiers, and it sends no remote frames. After losing arbitration
  the chip tells the host, and the driver sends the frame again. The host
  must take a word every 15 bit times while a frame arrives, or that frame
  goes unacknowledged.
- **One flip-flop's timing is shown by simulation, not proof.** The bit
  sampler's falling-edge flip-flop is in both proofs as a register like
  any other; that it samples half a cycle from the rest is exercised only
  by the Ethernet receive test, on the RTL and the gates.
- **Several of the v2.0 protocols transmit only:** I2S, DMX512, MIDI, LIN
  and Modbus RTU. Wiegand, NEC and RC-5 infrared and DALI go both ways:
  a DALI controller runs its transmitter and receiver together and reads
  a gear's answers.
- **The blind firmware test used an AI agent, not a person.**
- More in section 7 of the report, "What is not covered".

## How AI tools were used

The project was built with an AI assistant throughout: RTL, firmware, tests
and documents, with the commits marked. Three uses are part of the method,
not only of the typing:

- **Coverage closure.** The assistant read the coverage report and wrote
  directed tests for the 16 rarely reached cases and the planted bugs. It never judged them: the
  reference model did, every cycle, and a check rejected any test that
  missed its own target. One was rejected
  ([`coverage-closure.md`](coverage-closure.md)).
- **The blind firmware test** above, where not having seen the project was
  the point.
- **Planted bugs**, which test the tests.

What keeps one author's misreading from passing every layer: correctness
rests on artefacts written separately (the reference model, the formal
specifications), and on device models written by other people. Section 6 of
the report sets out the rules.

## Submission checklist

| Asked for | Where |
|---|---|
| RTL, tests, passing GDS and precheck | `hw/`, `sim/`, `test/`; the `gds` workflow |
| Architecture and instruction set | [`isa.md`](isa.md), [`info.md`](info.md), README |
| Assembler or toolchain, example programs | `model/asm.ml`, `bin/pe_sim.ml`, [`examples/`](../examples) |
| Verification write-up | [`design-and-verification.md`](design-and-verification.md) |
| Host and program loading | SPI port, [`info.md`](info.md); `host/protocol_emulator.py`, `host/more_protocols.py` |
| How AI tools were used | above, and section 6 of the report |

## Reproduce

`./reproduce.sh` runs all of the following and prints one line per claim.
`dune build && dune runtest` for the OCaml suite and the whole-chip proof;
`cd test && make` for cocotb. CI runs all of it, and the layout, on every
push. Details: "Running" in the [README](../README.md).
