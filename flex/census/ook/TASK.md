# Task: OOK (on-off keying) transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of on-off keying,
  Manchester coding and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that drives the data input of a 433 MHz on-off keying (OOK) radio
transmitter module, of the kind used by wireless sensors and remote
controls, on pin P0 (push-pull), on thread 0, with the chip's core clock at
1 MHz (one cycle = 1000 ns = 1 us; the thread may run every cycle). P0 high
switches the carrier on, P0 low switches it off. The chip only transmits:
nothing is received.

OOK is a modulation, not one standard; this sheet fixes the frame, in the
style of the Manchester-coded frames such sensors send. The receiver is a
logic analyser's OOK decoder (sigrok's `ook`, set to Manchester decoding
with a preamble of ones). Everything you need to know about it is here.

- The bit rate is 2000 bit/s. One bit lasts 500 us = 500 cycles, and half a
  bit 250 us = 250 cycles.
- Manchester code. Every bit is two halves of opposite level:
  - a 1 is high for the first half and low for the second;
  - a 0 is low for the first half and high for the second.
  So every bit has a transition in its middle, and there is also a
  transition at the boundary between two bits that are equal (1 then 1, or
  0 then 0). Two neighbouring transitions of a frame are 250 or 500 cycles
  apart, never less and never more.
- A frame carrying n payload bytes (n from 1 to 16) is 20 + 8n bits, sent
  without a break:
  1. A preamble of 16 bits, all 1.
  2. A sync nibble of 4 bits: 0, 1, 0, 1, in that order.
  3. The payload bytes in order, each most significant bit first.
- The line is low before a frame, so the first preamble bit begins with a
  rise. That rise is the frame's time zero: bit k of the frame (the first
  preamble bit is bit 0) lasts from cycle 500k to cycle 500k + 500 after it.
- At the end of the frame's last bit (cycle 500(20 + 8n) after its time
  zero) the line must be low and stay low: if the last bit is a 1 the line
  is already low from the middle of that bit; if it is a 0 the line falls
  exactly at the end of the bit.
- Between frames the line stays low, with no transition, for at least 5 ms
  (5000 cycles, ten bit times), measured from the end of one frame's last
  bit to the next frame's first rise. That silence is how the receiver finds
  the end of a frame. The gap must also be no longer than 20 ms (20000
  cycles), so that the test knows how long to run.
- The start of the run. A push-pull pin is high when the run begins, which
  here would be a carrier burst. P0 must be driven low no later than cycle
  100 of the run, and then stay low until the first frame. The first frame's
  first rise must come no earlier than cycle 5000 and no later than cycle
  20000 of the run.
- After the last frame the line stays low; nothing may move it. Any stray
  transition, between frames or after the last one, is a fault.
- Timing: every transition of a frame must be within +-2 us (2 cycles) of
  its ideal place, counted from that frame's first rise: 500k cycles after
  it for a transition at the start of bit k (or at the end of the last
  bit), and 500k + 250 for one in the middle of bit k. The limit is on the
  place, not on the spacing, so an error must not add up along a frame.

An example. The one-byte frame 0xA5 is the 28 bits 1111111111111111 (the
preamble), 0101 (sync), 10100101 (0xA5, most significant bit first). Its
transitions, in cycles after the first one:

| Bits | Value | Transitions at | Why |
|---|---|---|---|
| 0 to 15, preamble | 1 each | 500k (rise) and 500k + 250 (fall), k = 0 to 15 | each 1 starts high, ends low; the line is low before each |
| 16, sync | 0 | 8250 (rise) | starts low, already low after a 1 |
| 17, sync | 1 | 8750 (fall) | starts high, already high after a 0 |
| 18, sync | 0 | 9250 (rise) | |
| 19, sync | 1 | 9750 (fall) | |
| 20, data bit 7 | 1 | 10000 (rise), 10250 (fall) | a 1 after a 1: a rise at its start |
| 21, data bit 6 | 0 | 10750 (rise) | |
| 22, data bit 5 | 1 | 11250 (fall) | |
| 23, data bit 4 | 0 | 11750 (rise) | |
| 24, data bit 3 | 0 | 12000 (fall), 12250 (rise) | a 0 after a 0: a fall at its start |
| 25, data bit 2 | 1 | 12750 (fall) | |
| 26, data bit 1 | 0 | 13250 (rise) | |
| 27, data bit 0 | 1 | 13750 (fall) | the line is now low: the frame is over |

That is 46 transitions. The frame ends at cycle 14000, so the next frame may
start at cycle 19000 at the earliest. A frame whose last bit is a 0 ends
with a fall exactly at the end of that bit.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet:

- One word per payload byte of a frame, in the order the bytes are to be
  sent, frame after frame, with nothing between frames.
- Bits 7..0 of the word are the byte.
- Bit 8 is 1 on the last byte of a frame and 0 otherwise.
- All other bits (15..9) are 0.

So the frames 0xA5 and 0x12 0x34 0xFF arrive as the four words 0x01A5,
0x0012, 0x0034, 0x01FF. A frame of one byte is one word, with bit 8 set.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The preamble, the sync nibble, every transition, the return to low and the
gap between frames are the firmware's: nothing in a word says where the
line changes.

A run is 1 to 6 frames, each of 1 to 16 bytes of any value. The test writes
the run's words to a file, one per line, and runs
`./pe_sim run ook.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 20000, plus 20000 for
each frame, plus the frames' own lengths in cycles. In the simulator, the TX
FIFO is refilled as soon as it has room, so you do not need to worry about
the host being slow. When the words have run out, the chip must leave the
line low.

## What to hand in (all in this directory)

1. `ook.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every transition falls, on frames
you have not seen.
