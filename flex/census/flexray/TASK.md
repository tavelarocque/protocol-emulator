# Task: FlexRay transmitter firmware for the protocol emulator

You are writing firmware for a small programmable I/O chip, the protocol
emulator. You have never seen its source. Everything you may use is in this
directory:

- `isa.md`: the instruction set, its timing and the assembler syntax. It
  mentions files elsewhere in a repository (`model/...`, `hw/...`,
  `docs/info.md`); you do not have them and must not look for them.
- `pe_sim`: the assembler and a simulator of the chip (the reference model
  the hardware is checked against every cycle). `./pe_sim asm FILE.s`
  assembles; `./pe_sim run FILE.s -help` explains how to run a program on
  thread 0 with a configuration, pin modes and words pushed to the TX FIFO,
  and prints every change of the pins' outputs, with the cycle number.

Rules for this test, which is measuring how easy the chip is to program:
- Read only the files in this directory, and write only here. Do not open
  anything elsewhere on the machine (no repository, no other firmware, no
  searching the filesystem). Your general knowledge of FlexRay and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for the transmit side of a FlexRay communication controller, on
channel A at 10 Mbit/s: it sends static-segment frames on pin P0
(push-pull), on thread 0, with the chip's core clock at 50 MHz (one cycle =
20 ns; the thread may run every cycle). P0 is the TxD line to the bus
driver, read directly as the bus level: 1 is idle (and a 1 bit), 0 is a
0 bit. The chip only transmits: nothing is received.

The receiver is a logic analyser's FlexRay decoder (sigrok's `flexray`, set
to channel A and 10000000 bit/s). Everything you need to know about it is
here. It waits for P0 to go low (the TSS), then for it to go high (the FSS),
and from that rising edge it samples P0 in the middle of every bit; every
falling edge it sees re-times its sampling.

### Timing

- One bit lasts 100 ns = 5 cycles.
- P0 must be high from the first cycle of the run until the first frame.
  The first frame's TSS must begin within 10000 cycles (200 us) of the
  start of the run.
- Every edge of a frame after its TSS must be within +-1 cycle (20 ns) of
  its ideal place: 5k cycles after the frame's FSS edge (the rising edge
  that ends the TSS) for an edge at the start of bit k after it. The limit
  is on the place, not on the spacing, so an error must not add up along a
  frame.

### One frame on the line, in order

1. **TSS** (transmission start sequence): P0 low for 3 to 15 bits, that is
   15 to 75 cycles, your choice (it need not be the same for every frame).
2. **FSS** (frame start sequence): one bit of 1. Its rising edge is bit
   time zero of the frame.
3. **The bytes**: the 5 header bytes, then the payload bytes, then the 3
   bytes of the frame CRC. Every one of these bytes is sent as a **BSS**
   (byte start sequence: one bit of 1, then one bit of 0) followed by the
   byte's 8 bits, most significant bit first. Bits are NRZ: the level is
   the bit for the whole 5 cycles.
4. **FES** (frame end sequence): one bit of 0, then one bit of 1.
5. Then P0 stays high (idle). There is no dynamic trailing sequence: these
   are static-segment frames. The **channel idle delimiter** is the 11 bits
   of idle after the FES; the next frame's TSS may begin no sooner than
   60 cycles (12 bits) after the FES's rising edge, and must begin no later
   than 10000 cycles (200 us) after it.

A frame with L payload words (2L bytes) is therefore 1 + 10 x (8 + 2L) + 2
= 83 + 20L bits after its TSS.

### The header, 40 bits, most significant first

| Bits | Field | Width |
|---|---|---|
| 39 | reserved bit, always 0 | 1 |
| 38 | payload preamble indicator | 1 |
| 37 | null frame indicator (0 = null frame, 1 = data frame) | 1 |
| 36 | sync frame indicator | 1 |
| 35 | startup frame indicator | 1 |
| 34..24 | frame ID | 11 |
| 23..17 | payload length, in two-byte words (0 to 127) | 7 |
| 16..6 | header CRC | 11 |
| 5..0 | cycle count | 6 |

As FlexRay specifies, the header CRC is calculated by the host, not by the
communication controller: it arrives in a TX word and is sent as given.

### The frame CRC, 24 bits

The frame CRC covers the 40 header bits and then the payload bytes'
bits, in the order they are sent (not the TSS, FSS, BSS or FES bits). It
is FlexRay's CRC: the polynomial x^24 + x^22 + x^20 + x^19 + x^18 + x^16 +
x^14 + x^13 + x^11 + x^10 + x^8 + x^7 + x^6 + x^3 + x + 1 (0x5D6DCB), a
24-bit register that starts at 0xFEDCBA (channel A's initial value), data
taken most significant bit first, no final inversion. For each data bit:
take the register's bit 23 exclusive-or the data bit; shift the register
left by one (keeping 24 bits); if the result of the exclusive-or was 1,
exclusive-or the register with 0x5D6DCB. The register after the last bit
is the CRC, sent as three bytes, most significant byte first, each in a
BSS and most significant bit first.

### An example

Frame ID 1, cycle count 0, all indicators 0 except the null frame
indicator (1, a data frame), one payload word: the bytes 0x12, 0x34. Its
payload length is 1, its header CRC 0x51A, its frame CRC 0xFB7B75. After
the TSS the line carries these 103 bits (BSS shown apart from each byte):

| What | Bits |
|---|---|
| FSS | 1 |
| header byte 0 | 10 00100000 |
| header byte 1 | 10 00000001 |
| header byte 2 | 10 00000011 |
| header byte 3 | 10 01000110 |
| header byte 4 | 10 10000000 |
| payload byte 0x12 | 10 00010010 |
| payload byte 0x34 | 10 00110100 |
| CRC byte 0xFB | 10 11111011 |
| CRC byte 0x7B | 10 01111011 |
| CRC byte 0x75 | 10 01110101 |
| FES | 01 |

So its edges are at these cycles after the FSS edge: 0, 10, 25, 30, 55,
60, 100, 110, 145, 160, 170, 175, 190, 200, 205, 210, 215, 220, 255, 260,
280, 285, 295, 300, 305, 310, 325, 335, 340, 345, 355, 360, 365, 390, 395,
410, 420, 440, 445, 460, 470, 485, 490, 495, 500, 505, 510; the last is the
FES's rising edge.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet. For each frame, in order, frame after frame
with nothing between frames:

- Word 0: bit 14 the payload preamble indicator, bit 13 the null frame
  indicator, bit 12 the sync frame indicator, bit 11 the startup frame
  indicator, bits 10..0 the frame ID (1 to 2047). Bit 15 is 0.
- Word 1: the payload length L in two-byte words (0 to 127), in bits 6..0.
  All other bits 0.
- Word 2: the header CRC, in bits 10..0. All other bits 0.
- Word 3: the cycle count (0 to 63), in bits 5..0. All other bits 0.
- Then L words of payload, two bytes each: bits 15..8 the byte sent first,
  bits 7..0 the byte sent second.

So the example frame above, followed by a frame with ID 3, cycle count 1,
and the payload bytes 0xDE 0xAD 0xBE 0xEF (header CRC 0x27F), arrive as
the eleven words 0x2001, 0x0001, 0x051A, 0x0000, 0x1234, 0x2003, 0x0002,
0x027F, 0x0001, 0xDEAD, 0xBEEF.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The TSS, FSS, every BSS, the frame CRC, the FES, the idle time between
frames and every bit's timing are the firmware's: nothing in a word says
where the line changes.

A run is 1 to 5 frames, each with a payload of 0 to 127 words of any value,
any frame ID from 1 to 2047, any cycle count, and any indicators FlexRay
allows. The test writes the run's words to a file, one per line, and runs
`./pe_sim run flexray.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 10000, plus, for each
frame, 75 + 10000 + 5 x (83 + 20L) cycles. In the simulator, the TX FIFO is
refilled as soon as it has room, so you do not need to worry about the host
being slow. When the words have run out, the chip must leave the line high.

## What to hand in (all in this directory)

1. `flexray.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every edge falls, on frames you
have not seen.
