# Task: PT2262 remote control encoder firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the PT2262 remote
  control encoder and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip stand in for a PT2262 remote control encoder
(also sold as HX2262 and SC5262): the chip found in 433 MHz remote controls
and wireless doorbells, whose one output pin keys a radio transmitter. It
sends code words on pin P0 (push-pull), on thread 0, with the chip's core
clock at 10 MHz (one cycle = 100 ns; the thread may run every cycle). The
chip only transmits: nothing is received.

The receiver is a logic analyser's PT2262 decoder (sigrok's `rc_encode`).
Everything you need to know about it is here. The line reads as follows.

- The line idles low. A high level is "carrier on".
- All timing is counted in one unit, called alpha here (the PT2262 counts
  periods of its own oscillator). Here alpha = 40 us = 400 cycles.
- A code word is twelve tri-state bits ("trits"), each '0', '1' or 'f'
  (floating), followed by one sync bit. The twelve trits are sent in order:
  trit 0 (the PT2262's pin A0) first, trit 11 (its pin A11/D0) last.
- Every trit lasts 32 alpha (12800 cycles) and is two pulse cycles of 16
  alpha (6400 cycles) each. Every pulse cycle is a high followed by a low:
  - a short pulse cycle: high for 4 alpha (1600 cycles), then low for 12
    alpha (4800 cycles);
  - a long pulse cycle: high for 12 alpha (4800 cycles), then low for 4
    alpha (1600 cycles).
- The trits are coded:
  - '0': short, short;
  - '1': long, long;
  - 'f': short, long.
- The sync bit lasts 128 alpha (51200 cycles): high for 4 alpha (1600
  cycles), then low for 124 alpha (49600 cycles).
- A frame is a code word and its sync bit: 12 x 32 + 128 = 512 alpha
  (204800 cycles, 20.48 ms). It has exactly 50 edges: 4 per trit, then the
  sync bit's rise and fall.
- The host sends 1 to 8 code words in a run (a remote control repeats the
  same code word while its button is held, so they may be equal or not).
  They are sent as frames back to back, with no break: each frame's first
  rise comes exactly 512 alpha after the previous frame's first rise, that
  is, right at the end of the previous sync bit's low part.

Start and end of a run:

- P0 must be driven low by cycle 100 of the run. The host makes P0 an
  output only once the firmware has had time to drive it low, so the test
  does not count P0's level before its first change; that first change
  must be to low.
- The first frame's first rise must come between cycle 50000 and cycle
  100000 of the run (inclusive). Until then P0 stays low.
- After the last frame's sync bit, P0 stays low, with no change, until the
  end of the run. Any stray edge is the start of a code word to the
  receiver.

Timing: every edge of a frame must be within +-200 ns (2 cycles) of its
ideal place, counted from that frame's first rise. The limit is on the
place, not on the spacing, so an error must not add up along a frame. Each
frame's first rise must also be within +-2 cycles of 204800 cycles after
the previous frame's first rise.

An example. The code word 0 f 1 0 0 0 1 0 0 f 0 1 begins like this (cycles
after the frame's first rise):

| Trit | Value | Pulse cycles | Rise, fall, rise, fall at |
|---|---|---|---|
| 0 | 0 | short, short | 0, 1600, 6400, 8000 |
| 1 | f | short, long | 12800, 14400, 19200, 24000 |
| 2 | 1 | long, long | 25600, 30400, 32000, 36800 |
| ... | | | |
| 11 | 1 | long, long | 140800, 145600, 147200, 152000 |
| sync | | | 153600, 155200 |

The next frame's first rise is at 204800.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet:

- Two words per code word, in the order the code words are to be sent,
  code word after code word, with nothing between them.
- The first word holds trits 0 to 5, the second trits 6 to 11.
- In each word, its k-th trit (k = 0 to 5, in sending order) is in bits
  2k+1..2k: 0 for '0', 1 for '1', 2 for 'f'. The value 3 never occurs.
- Bits 15..12 are 0.

So the code word 0 f 1 0 0 0 1 0 0 f 0 1 arrives as the two words 0x0018,
0x0481. The code word of twelve '1's is 0x0555, 0x0555, and twelve 'f's
are 0x0AAA, 0x0AAA.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

Every pulse, its length, the sync bit and the place of every frame are the
firmware's: nothing in a word says where the line changes.

The test writes the run's words to a file, one per line, and runs
`./pe_sim run rc_encode.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 100000, plus 204800 for
each code word, plus 20000. In the simulator, the TX FIFO is refilled as
soon as it has room, so you do not need to worry about the host being slow.
When the words have run out, the chip must leave the line low.

## What to hand in (all in this directory)

1. `rc_encode.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every edge falls, on code words
you have not seen.
