# Task: DSI transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of DSI and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that acts as a DSI controller: it sends dimming levels to lamp
ballasts over DSI (Digital Serial Interface, the Tridonic lighting bus that
came before DALI). It transmits on pin P0 (push-pull), on thread 0, with the
chip's core clock at 10 MHz (one cycle = 100 ns; the thread may run every
cycle). The chip only transmits: nothing is received.

The receiver is a logic analyser's DSI decoder (sigrok's `dsi`, polarity
set to active-high). Everything you need to know about the line is here:

- The line idles low. High is the active level.
- The line is divided into half-bits ("transmission bits") of 833.33 us,
  1200 of them a second. At 10 MHz that is 8333.33 cycles, so it is not a
  whole number of cycles; see the timing limit below.
- One frame is 21 half-bits (17.5 ms) and carries one byte, the dimming
  level:
  1. A start bit: one half-bit high (half-bit 0). It begins with the rise
     of the line from low: that rise is the frame's time zero.
  2. The 8 data bits, most significant bit (D7) first, each two half-bits,
     Manchester coded: a 1 is high for the first half and low for the
     second; a 0 is low for the first half and high for the second. Data
     bit D7 is half-bits 1 and 2, D6 half-bits 3 and 4, and so on to D0,
     half-bits 15 and 16.
  3. Four stop bits: the line low for half-bits 17 to 20.
- So the line can change only at a boundary between half-bits, and in
  each data bit it always changes in the middle. Half-bit k begins
  k x 833.33 us after the frame's rise.
- Between frames the line rests low. From the end of the stop bits (half-bit
  20's end, 17.5 ms after the frame's rise) to the next frame's rise there
  must be at least 5 ms and at most 20 ms.
- P0 is high when the run starts (the output register resets to ones). The
  firmware must drive it low within 100 us (1000 cycles) of the start of the
  run, and keep it low until the first frame. The first frame's rise must
  come no earlier than 5 ms (cycle 50000) and no later than 20 ms
  (cycle 200000) after the start of the run.
- After the last frame the line stays low. Nothing may move the line between
  frames or after the last one.
- Timing: every change of the line must be within +-8 us (80 cycles) of its
  ideal place, counted from that frame's rise: the start of half-bit k is
  ideally k x 25000/3 cycles after the rise. The limit is on the place, not
  on the spacing, so an error must not add up along a frame.

An example. The level 0xA5 is the bits 1 0 1 0 0 1 0 1, D7 first. Its frame:

| Half-bits | Meaning | Line |
|---|---|---|
| 0 | start bit | high |
| 1, 2 | D7 = 1 | high, low |
| 3, 4 | D6 = 0 | low, high |
| 5, 6 | D5 = 1 | high, low |
| 7, 8 | D4 = 0 | low, high |
| 9, 10 | D3 = 0 | low, high |
| 11, 12 | D2 = 1 | high, low |
| 13, 14 | D1 = 0 | low, high |
| 15, 16 | D0 = 1 | high, low |
| 17 to 20 | stop bits | low |

The line rises at half-bit 0 and then changes at the starts of half-bits 2,
4, 6, 8, 9, 10, 12, 14 and 16, ideally 16667, 33333, 50000, 66667, 75000,
83333, 100000, 116667 and 133333 cycles after the rise (rounded to the
nearest cycle). It changes in the middle of every data bit (the even
half-bits), and at the boundary between two neighbouring bits only when
they are equal: here D4 and D3, at half-bit 9. There is no change at
half-bit 1 because D7 = 1 continues the start bit's high. The last change,
at half-bit 16, is a fall, and the line then stays low; had D0 been 0, the
last change would have been a fall at half-bit 17. The next frame may rise 175000 + 50000 = 225000 cycles after
this frame's rise at the earliest, and 175000 + 200000 = 375000 at the
latest.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet:

- One word per frame, in the order the frames are to be sent.
- Bits 7..0 of the word are the dimming level, the frame's data byte.
- All other bits (15..8) are 0.

So the three frames 0xA5, 0x00 and 0xFF arrive as the three words 0x00A5,
0x0000, 0x00FF.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The start bit, every data bit's two halves, the stop bits and the gap
between frames are the firmware's: nothing in a word says where the line
changes.

A run is 1 to 8 frames, each of any level 0x00 to 0xFF. The test writes
the run's words to a file, one per line, and runs
`./pe_sim run dsi.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 200000 plus 375000 for
each frame. In the simulator, the TX FIFO is refilled as soon as it has
room, so you do not need to worry about the host being slow. When the words
have run out, the chip must leave the line low.

## What to hand in (all in this directory)

1. `dsi.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those. It must make P0 push-pull.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every change of the line falls, on
frames you have not seen.
