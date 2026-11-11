# Task: WS2812 LED firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of WS2812 LEDs and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that drives a chain of WS2812B addressable RGB LEDs from pin P0
(push-pull), on thread 0, with the chip's core clock at 10 MHz (one cycle =
100 ns; the thread may run every cycle).

The receiving LEDs decode the data line as follows (WS2812B data sheet):

- Each bit is a high pulse followed by a low gap.
  - A 0 bit: high 400 ns +- 150 ns, then low 850 ns +- 150 ns.
  - A 1 bit: high 800 ns +- 150 ns, then low 450 ns +- 150 ns.
- Each LED takes 24 bits: green, red, blue, 8 bits each, most significant bit
  first, and passes the rest of the stream on.
- A frame ends with the line held low for at least 280 us (the latch). The
  line must stay low between frames and idle low before the first one.
- Inside a frame there must be no other gaps: every low gap must be within
  the limits above.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. You decide what
the words mean. In the simulator, the TX FIFO is refilled as soon as it has
room, so you do not need to worry about the host being slow.

## What to hand in (all in this directory)

1. `ws2812.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs.
3. `host.py`: a function `encode(frames) -> list[int]` taking a list of
   frames, each a list of (r, g, b) tuples of 0..255, and returning the TX
   words that make the chip send those frames, each followed by its latch.
   Plain Python 3, no imports beyond the standard library.
4. `notes.md`, as above, ending with: the program's length in instructions,
   the host word format, and anything about the chip that was confusing or
   that you think is wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way an LED
would, on frames you have not seen.
