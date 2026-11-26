# Task: 7-segment display driver firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of 7-segment displays and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that drives one common-anode 7-segment LED display, with decimal
point, directly from the chip's eight pins, on thread 0, with the chip's
core clock at 10 MHz (one cycle = 100 ns; the thread may run every cycle).
The chip only transmits: nothing is received.

The receiver is a logic analyser's 7-segment decoder (sigrok's
`seven_segment`, set to common-anode, with the decimal point connected).
Everything you need to know about it is here.

Pins. All eight are push-pull outputs:

| Pin | P0 | P1 | P2 | P3 | P4 | P5 | P6 | P7 |
|---|---|---|---|---|---|---|---|---|
| Segment | a | b | c | d | e | f | g | dp |

The segments are named the usual way: a is the top bar, b the upper right,
c the lower right, d the bottom, e the lower left, f the upper left, g the
middle bar, dp the decimal point. The display is common-anode, so a segment
is lit while its pin is LOW (0) and dark while its pin is HIGH (1). A blank
display is all eight pins high.

Characters. The decoder recognises exactly these sixteen patterns, the
hexadecimal digits, and the blank display. A segment not listed is dark.
Any other pattern of a to g is not a character to it.

| Digit | Lit segments | Digit | Lit segments |
|---|---|---|---|
| 0 | a b c d e f | 8 | a b c d e f g |
| 1 | b c | 9 | a b c d f g |
| 2 | a b d e g | A | a b c e f g |
| 3 | a b c d g | b | c d e f g |
| 4 | b c f g | C | a d e f |
| 5 | a c d f g | d | b c d e g |
| 6 | a c d e f g | E | a d e f g |
| 7 | a b c | F | a e f g |

The decimal point (dp) is separate: any character, the blank included, may
be shown with or without it.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet. One word is one character to show:

- Bits 3..0: the hexadecimal digit, 0x0 to 0xF.
- Bit 4: 1 if the decimal point is lit with it.
- Bit 5: 1 for a blank (segments a to g all dark); bits 3..0 are then 0.
  The decimal point still follows bit 4.
- Bit 6: 1 on the last word of the run, 0 on every other.
- All other bits (15..7) are 0.

So showing "3.14" is the three words 0x0013, 0x0001, 0x0044, and showing
"A", then a blank, then "b" is 0x000A, 0x0020, 0x004B.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

Which segments to light, every pin level and every moment the pins change
are the firmware's: nothing in a word says which pins to drive.

Timing. The display shows the run's characters one after another, each for
exactly 100 us (1000 cycles):

- From the first cycle of the run until the first character, all eight
  pins are high (the display is blank). The pins' outputs are high from
  reset.
- The first character must appear within 2 ms (20000 cycles) of the start
  of the run. The cycle at which the pins first change is the run's time
  zero, T0. The test never starts a run with a blank without decimal point
  (0x20 or 0x60), so the first character is always a change.
- Character k of the run (the first is k = 0) is shown from T0 + 1000k to
  T0 + 1000(k + 1). After the last character, from T0 + 1000n for a run of
  n words, the display is blank (all eight pins high) and nothing changes
  any more.
- Every change of the pins must be within +-200 ns (2 cycles) of its ideal
  place, counted from T0. The limit is on the place, not on the spacing, so
  an error must not add up along a run.
- A change of character is one change of the pins: every pin that changes
  between two characters changes in the same cycle. The display must never
  show anything in between, not even for one cycle.
- Two neighbouring words that show the same pattern (the same digit and
  decimal point, or two equal blanks) give one unbroken display of
  2000 cycles: the pins do not change between them. Nothing else may move
  a pin: any other change is a stray character to the receiver.

An example. The run "3.14" (words 0x0013, 0x0001, 0x0044) with T0 at cycle
500: "3." from cycle 500 (pins a b c d g dp low), "1" from cycle 1500,
"4" from cycle 2500, blank from cycle 3500 on.

A run is 1 to 64 words. The test writes the run's words to a file, one per
line, and runs `./pe_sim run seven_segment.s -tx FILE -cycles N` followed
by the arguments in `run_args.txt`, from reset, once for each run. N is
20000, plus 1000 for each word, plus 5000. In the simulator, the TX FIFO is
refilled as soon as it has room, so you do not need to worry about the host
being slow.

## What to hand in (all in this directory)

1. `seven_segment.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every change falls, on runs you
have not seen.
