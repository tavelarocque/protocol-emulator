# Task: Maple bus transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the Maple bus and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the host end of a SEGA Dreamcast Maple bus and
transmits frames on it, on thread 0, with the chip's core clock at 50 MHz
(one cycle = 20 ns; the thread may run every cycle). The chip only
transmits: nothing is received, and no device answers.

The receiver is a logic analyser's Maple bus decoder (sigrok's
`maple_bus`), together with a direct measurement of the two lines.
Everything you need to know is here.

### Pins and levels

- P0 is SDCKA and P1 is SDCKB. Both must be push-pull: `run_args.txt` must
  hold `-mode 0=pp -mode 1=pp`. No other pin is looked at.
- Both lines are high when the bus is idle. They must be high from the
  first cycle of the run until the first frame, between frames, and after
  the last frame.

### A frame on the wire

A frame is a sequence of bytes, sent in this order:

1. N, the number of 32-bit data words that follow the header, 0 to 255.
2. The sender's address.
3. The recipient's address.
4. The command.
5. The 4N data bytes.
6. The checksum: the XOR of every byte before it in the frame (N, the
   sender, the recipient, the command and all the data bytes).

So a frame is 4N + 5 bytes. Each byte is sent most significant bit first.
Number the bits of the whole frame from 0 (bit 7 of N) to 8(4N + 5) - 1
(bit 0 of the checksum), straight across the byte boundaries.

The two lines take turns as clock and data. Bit j with j even is clocked
by SDCKA, with its value on SDCKB; bit j with j odd is clocked by SDCKB,
with its value on SDCKA. The receiver reads the data line at the moment
the clock line falls. Each bit is sent in three steps, in this order:

1. The clock line goes high, if it is low.
2. The data line goes to the bit's value, if it is not already there.
3. The clock line falls.

A step that finds its line already at that level makes no change. Apart
from those steps, the start pattern and the end pattern, nothing may
change either line.

A frame is the start pattern, the bits, then the end pattern:

- **Start pattern**, from idle (both high): SDCKA falls; SDCKB falls and
  rises four times (four low pulses); SDCKA rises. Both lines are then
  high, and bit 0 follows (its step 1 makes no change).
- **End pattern**, after the last bit (which SDCKB clocks, so SDCKB is low):
  SDCKA goes high if it is low; SDCKB rises; SDCKB falls; SDCKA falls,
  rises, falls and rises (two low pulses); SDCKB rises. Both lines are then
  high: the bus is idle.

Every one of those is a separate change, in that order. The test requires
the order of changes on the two lines to be exactly this, change for
change.

### Timing limits

Every change below means a change of level of SDCKA or SDCKB, as the
simulator prints it.

- The two lines never change in the same cycle.
- A change of one line comes at least 7 cycles (140 ns) after the latest
  change of the other line. (The bus asks about 125 ns.)
- A change of a line comes at least 12 cycles (240 ns) after that same
  line's previous change. (The bus asks about 225 ns.)
- Inside a frame, from the start pattern's first change to the end
  pattern's last, no more than 100 cycles (2 us) pass between one change
  and the next, on either line.
- The first frame's first change comes no later than cycle 50000 (1 ms).
- Between two frames both lines stay high for at least 100 cycles (2 us)
  and at most 50000 cycles (1 ms), counted from the last change of one
  frame to the first change of the next.
- After the last frame nothing changes.

For reference only: a Dreamcast itself spends about 160 ns (8 cycles) on
each step, so a bit takes about 480 ns. Any timing within the limits above
is accepted, faster or slower than that.

### An example

The frame "device information request" from the host (address 0x00) to the
main device on port A (address 0x20) has N = 0, command 0x01 and no data.
Its bytes are 0x00, 0x00, 0x20, 0x01 and the checksum 0x21. These are its
98 changes, in order (A is SDCKA, B is SDCKB, + a rise, - a fall):

| Part | Changes |
|---|---|
| start pattern | A- B- B+ B- B+ B- B+ B- B+ A+ |
| N = 0x00, bit 7 (bit 0 of the frame, clocked by A) | B- A- |
| N, bit 6 (clocked by B) | B+ B- |
| N, bit 5 | A+ A- |
| N, bits 4 to 0 | B+ B- A+ A- B+ B- A+ A- B+ B- |
| sender 0x00, bits 7 to 0 | A+ A- B+ B- A+ A- B+ B- A+ A- B+ B- A+ A- B+ B- |
| recipient 0x20, bits 7 and 6 | A+ A- B+ B- |
| recipient, bit 5 (a 1, clocked by A) | A+ B+ A- |
| recipient, bit 4 (a 0, clocked by B: B is already high and A already low) | B- |
| recipient, bits 3 to 0 | A+ A- B+ B- A+ A- B+ B- |
| command 0x01, bits 7 to 1 | A+ A- B+ B- A+ A- B+ B- A+ A- B+ B- A+ A- |
| command, bit 0 (a 1, clocked by B) | B+ A+ B- |
| checksum 0x21, bit 7 (a 0: A is already high and B already low) | A- |
| checksum, bit 6 | B+ B- |
| checksum, bit 5 (a 1) | A+ B+ A- |
| checksum, bit 4 (a 0) | B- |
| checksum, bits 3 to 1 | A+ A- B+ B- A+ A- |
| checksum, bit 0 (a 1) | B+ A+ B- |
| end pattern (A is already high) | B+ B- A- A+ A- A+ B+ |

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet. For each frame, in order, the host sends:

- Word 0: bits 15..8 are N, bits 7..0 are the sender's address.
- Word 1: bits 15..8 are the recipient's address, bits 7..0 are the
  command.
- Then 2N words, holding the 4N data bytes in the order they are sent, two
  to a word: the earlier byte in bits 15..8, the later in bits 7..0.

The frames follow one another with nothing between them. The host never
sends the checksum. So the example frame above is the two words 0x0000,
0x2001, and the frame from address 0x00 to address 0x01 with command 0x09
and the one data word whose bytes are 0xDE, 0xAD, 0xBE, 0xEF (checksum
0x2B) is the four words 0x0100, 0x0109, 0xDEAD, 0xBEEF.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The checksum, the start and end patterns, every change of the lines, the
count of data words and the idle between frames are the firmware's: nothing
in a word says where a line changes.

A run is 1 to 4 frames, each with N from 0 to 255 and bytes of any value.
The test writes the run's words to a file, one per line, and runs
`./pe_sim run maple_bus.s -tx FILE -cycles C` followed by the arguments in
`run_args.txt`, from reset, once for each run. C is long enough for the
latest start, the slowest frames and the longest idle the limits allow. In
the simulator, the TX FIFO is refilled as soon as it has room, so you do not
need to worry about the host being slow. When the words have run out, the
chip must leave both lines high.

## What to hand in (all in this directory)

1. `maple_bus.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those. It must make P0 and P1
   push-pull.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the two lines the way the receiver
above would, and measures every change on them, on frames you have not
seen.
