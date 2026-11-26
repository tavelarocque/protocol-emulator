# Task: SWIM host firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of SWIM and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the host (the debug probe) of an STM8
microcontroller over SWIM, ST's Single Wire Interface Module: it wakes the
target's SWIM interface, then sends it SRST (system reset), ROTF (read on
the fly) and WOTF (write on the fly) commands, and hands the bytes it reads
back to the host. It runs on thread 0, with the chip's core clock at
40 MHz (one cycle = 25 ns; the thread may run every cycle).

### The line

SWIM is one open-drain wire with a pull-up: it is high unless the chip or
the target pulls it low. It is pin P0, which must be open-drain (`-mode
0=od`). Give no other pin a mode; no other pin is connected.

The target is a scripted waveform, fed to the simulator with `-stimulus`.
It is written in advance from the timetable below and cannot react to
anything the chip does: it pulls the line low exactly when the timetable
says the target does, whether or not the chip did its part. The stimulus
file's cycle numbers and the cycle numbers of `pe_sim`'s `pins` lines are
on the same scale: at cycle c the wire is low if the chip's P0 output
printed for cycle c is 0, or if the stimulus has the target pulling low at
cycle c (P0's bit of the stimulus is 0); otherwise it is high. All other
input pins read 1 throughout.

The receiver of the whole conversation is a logic analyser's SWIM decoder
(sigrok's `swim`) reading the wire, plus a check of the chip's own edges
against the timetable.

### Times

The SWIM clock is 8 MHz: one SWIM clock period is 5 cycles. Every time
below is in cycles of the 40 MHz core clock.

### 1. The entry sequence (the chip alone)

P0 must be released (output 1) from the first cycle of the run. Then the
chip wakes the target's SWIM interface with the entry sequence:

1. The first falling edge, at a cycle E of the chip's choosing between 400
   and 4000 (10 to 100 us).
2. Low for 16 us: the rising edge at E + 640.
3. Four pulses at 1 kHz: four times, high for 500 us then low for 500 us.
   That is, each falling edge comes 20000 cycles after the rising edge
   before it, and each rising edge 40000 cycles after the rising edge
   before it.
4. Four pulses at 2 kHz: four times, high for 250 us then low for 250 us:
   each falling edge 10000 cycles after the rising edge before it, each
   rising edge 20000 cycles after the rising edge before it.
5. Released (high) after the last rising edge, nominally at E + 240640.

That is 18 edges. Limits: the first rising edge within +-2 cycles of
E + 640; after that, each falling edge within +-2 cycles, and each rising
edge within +-1 cycle, of its place counted from the actual rising edge
before it. (The decoder compares the pulse periods with one another to
within 2 cycles, which is why the rising edges are held to 1.) Nothing else
may move P0 until the first frame.

### 2. The synchronization frame (the target)

The target answers with a synchronization frame: it pulls the line low from
cycle 250000 to cycle 250640 (128 SWIM clocks, 16 us), then releases it.
This is at a fixed cycle, whatever E was.

### 3. Bits

Every bit lasts 22 SWIM clocks, 110 cycles, and begins with a falling edge
made by whoever sends the bit:

- a 1 is low for 2 SWIM clocks (10 cycles), then high for 100 cycles;
- a 0 is low for 20 SWIM clocks (100 cycles), then high for 10 cycles.

A bit that starts at cycle t therefore has its falling edge at t and its
rising edge at t + 10 (a 1) or t + 100 (a 0). The next bit of the same
frame starts at t + 110.

### 4. Frames

The chip sends three kinds of frame, the target one:

- Command frame (chip): a start bit 0, then the 3-bit command, most
  significant bit first (SRST = 000, ROTF = 001, WOTF = 010), then a
  parity bit. 5 bits.
- Byte frame (chip): a start bit 0, then 8 bits, most significant bit
  first, then a parity bit. 10 bits.
- Data frame (target): a start bit 1, then 8 bits, most significant bit
  first, then a parity bit. 10 bits.

The parity bit is the XOR of the frame's command or data bits (not the
start bit): 1 if they hold an odd number of ones.

Every frame is followed at once by an acknowledge bit from its receiver,
starting exactly where the frame's next bit would start (frame start +
5 x 110 = +550 for a command frame, + 10 x 110 = +1100 for the others):

- After a frame from the chip, the target sends it: a 1 (ACK, low for 10
  cycles) or a 0 (NACK, low for 100 cycles). After a NACK the chip must
  send the same frame again, unchanged, as the next frame. The target may
  NACK the same frame up to twice in a row; it ACKs the third try.
- After a data frame from the target, the chip sends it: always a 1 (ACK).
  The target's data frames always have correct parity, and are not
  resent.

The next frame, whoever sends it, starts exactly 220 cycles (two bit
times) after the falling edge that started the previous acknowledge bit.
The first frame starts 220 cycles after the end of the synchronization
frame, at cycle 250860.

The chip's edges in a frame or acknowledge bit must each be within +-2
cycles (+-50 ns) of their place. Because the target is exactly on the
timetable, every place is a fixed cycle number: the timetable never moves
with the chip's timing. The chip must not move P0 at any other time: it
releases the line whenever it is not sending a bit, and it never pulls the
line low while the target is sending.

### 5. Commands

- SRST: one command frame (000).
- WOTF (write N bytes, N from 1 to 255, starting at a 24-bit address):
  the command frame (010), a byte frame holding N, three byte frames
  holding the address (bits 23..16, then 15..8, then 7..0), then N byte
  frames holding the data, in order.
- ROTF (read N bytes, N from 1 to 255, starting at a 24-bit address): the
  command frame (001), a byte frame holding N, the three address byte
  frames, then the target sends N data frames, each acknowledged by the
  chip. The first data frame starts 220 cycles after the start of the
  acknowledge bit of the last address frame, by the rule above.

The target NACKs only command frames and WOTF data byte frames, never the
N or address frames. Each operation follows the one before with no extra
gap: its command frame is simply the next frame.

An example: a WOTF of one byte (0xA0 to address 0x007F80) right after the
synchronization frame, every frame ACKed. The command frame starts at
250860: bits 0 (start), 0, 1, 0, then parity 1.

| Bit | Value | Falling edge | Rising edge | Driven by |
|---|---|---|---|---|
| start | 0 | 250860 | 250960 | chip |
| command bit 2 | 0 | 250970 | 251070 | chip |
| command bit 1 | 1 | 251080 | 251090 | chip |
| command bit 0 | 0 | 251190 | 251290 | chip |
| parity | 1 | 251300 | 251310 | chip |
| ACK | 1 | 251410 | 251420 | target |

The next frame, the byte frame holding N = 1 (start 0, bits 00000001,
parity 1), starts at 251410 + 220 = 251630; its ACK starts at
251630 + 1100 = 252730; the next frame at 252950. Had the target sent a
NACK at 251410 (low until 251510), the command frame would have been sent
again from 251630.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet. For each operation, in order:

- One command word: bits 9..8 are the command (0 = SRST, 1 = ROTF,
  2 = WOTF), bits 7..0 the byte count N (0 for SRST).
- For ROTF and WOTF, two address words follow: the first holds address
  bits 23..16 in its bits 7..0; the second holds address bits 15..0.
- For WOTF, N data words follow, one per byte, the byte in bits 7..0.
- All other bits are 0.

So SRST, then a WOTF of the byte 0xA0 to 0x007F80, then a ROTF of 2 bytes
from 0x004800, arrive as the eight words 0x0000, 0x0201, 0x0000, 0x7F80,
0x00A0, 0x0102, 0x0000, 0x4800.

The chip pushes to the RX FIFO one word for every byte a ROTF reads, in the
order read, the byte in bits 7..0 and every other bit 0, and nothing else.
When it pushes them does not matter, as long as it is before the run ends.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The entry sequence, every start bit, parity bit and acknowledge bit, the
bit timing, the resending after a NACK and the place of every frame are
the firmware's: nothing in a word says where the line changes.

### A run

A run is the entry sequence, then 1 to 5 operations, each of them SRST,
ROTF or WOTF, with N from 1 to 255 and any address and data. The test
writes the run's words to one file, one per line, and the target's
waveform to another (lines `CYCLE HEX`, as `pe_sim run -help` describes),
and runs `./pe_sim run swim.s -tx FILE -stimulus FILE -cycles N` followed
by the arguments in `run_args.txt`, from reset, once for each run. N is
4400 cycles (40 bit times) after the place where one more frame would
start after the last acknowledge bit; P0 must stay released until then.
In the simulator, the TX FIFO is refilled as soon as it has room, so you
do not need to worry about the host being slow. When the words have run
out, the chip must leave the line released.

## What to hand in (all in this directory)

1. `swim.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those. It must include
   `-mode 0=od` and no other `-mode`.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident; you will have to
write your own stimulus files to stand in for the target. Then stop: it
will be checked by a separate test that decodes the wire the way the
receiver above would, measures where every edge of the chip falls, and
compares the words pushed to the host, on runs you have not seen.
