# Task: S/PDIF transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of S/PDIF and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip an S/PDIF transmitter (IEC 60958 consumer
digital audio: two channels of linear PCM on one wire) on pin P0
(push-pull), on thread 0, with the chip's core clock at 49.152 MHz (one
cycle = 20.345 ns; the thread may run every cycle). Transmit only: nothing
is received.

A receiver decodes the line as follows (IEC 60958):

- **Cells.** Time on the line is divided into cells of equal length (a cell
  is half a bit; the standard calls it a unit interval). You choose the
  cell length: a whole number of core-clock cycles from 2 to 48, the same
  for every cell of a run. A subframe is 64 cells and a frame is two
  subframes, so the sample rate is 49 152 000 / (128 x cell length) Hz:
  8 cycles a cell is 48 kHz, 12 is 32 kHz, 4 is 96 kHz. Any whole number
  from 2 to 48 is accepted; state the one you chose and its sample rate in
  `notes.md`.
- **Biphase-mark coding.** Every bit takes two cells. The line always
  changes level at the start of a bit. A 1 changes level again between its
  two cells; a 0 does not. Only the changes carry information, not which
  level is high.
- **Subframe.** One audio sample of one channel: 32 time slots of two cells
  each.

  | Time slots | Cells | Content |
  |---|---|---|
  | 0 to 3 | 0 to 7 | preamble (not biphase-mark coded; see below) |
  | 4 to 27 | 8 to 55 | the audio sample, 24 bits, least significant bit first. (Slots 4 to 7 are the standard's auxiliary bits and 8 to 27 its audio bits; here the auxiliary bits are the low 4 bits of a 24-bit sample, which the standard allows) |
  | 28 | 56, 57 | validity, V: always 0 (the sample is valid) |
  | 29 | 58, 59 | user data, U: always 0 |
  | 30 | 60, 61 | channel status, C: see below |
  | 31 | 62, 63 | parity, P: chosen so that time slots 4 to 31 together hold an even number of ones |

- **Preambles.** Eight cells that break the coding rule, so that a receiver
  can find where a subframe starts. Like a bit, a preamble starts with a
  change of level. There are three, given here as the level of the line in
  each of the eight cells when the line was low in the cell before the
  preamble (all eight are inverted when it was high):

  | Preamble | Cells 0 to 7 |
  |---|---|
  | B | 1 1 1 0 1 0 0 0 |
  | M | 1 1 1 0 0 0 1 0 |
  | W | 1 1 1 0 0 1 0 0 |

  Because parity is even, the line is at the same level before every
  preamble of a transmission, so all of them come out the same way up.
- **Frames and blocks.** A frame is the left channel's subframe followed
  by the right channel's. 192 consecutive frames are a block. The left
  subframe of the first frame of a block starts with B; the left subframe
  of the other 191 frames starts with M; every right subframe starts with
  W. The first frame of a run is the first frame of a block, and blocks
  follow one another without a break: counting frames from 0, frames 0,
  192 and 384 start with B.
- **Channel status.** The C bit is the same in both subframes of a frame,
  and the 192 C bits of a block, one per frame, are the channel status
  word. Here it must be: 1 in frames 2 and 24 of every block (counting the
  block's frames from 0), and 0 in the other 190. (In the consumer format
  that reads: linear PCM audio, copying permitted, sample rate not
  indicated.)
- **Timing.** The stream is continuous. From the first change of level of
  the first preamble to the end of the last subframe:
  - the time between two consecutive changes of level is always 1, 2 or 3
    cells, each within +-5% of one cell (the standard's limit on a
    transmitter's jitter, 0.05 unit intervals);
  - every subframe, measured from the first change of its preamble to the
    first change of the next preamble, is 64 cells within +-5% of one cell;
  - so there are no gaps, between bits, subframes, frames or blocks.

  With a cell shorter than 20 cycles, 5% of a cell is less than one cycle,
  and all of this is exact to the cycle.
- **Start and end of a run.** A run sends its frames once, in order, and
  then stops.
  - The first preamble must start (its first change of level) no later
    than cycle 10 000 of the run.
  - Before that P0 may rest at either level, and the first preamble, like
    every other, starts with a change away from the level before it. If
    your firmware changes P0
    before the stream starts (for example to choose the level it rests
    at), P0 must then stay steady for at least 64 cells before the first
    preamble. If P0 does not change before the first preamble, there is
    nothing to wait for.
  - After the last subframe P0 must not change again for the rest of the
    run: its last cell simply lasts. One change exactly at the end of the
    last subframe, where the next preamble would have started, is allowed.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet. Each frame is four words, in this order:

1. the left sample's bits 15..0;
2. the left sample's bits 23..16, in bits 7..0 of the word;
3. the right sample's bits 15..0;
4. the right sample's bits 23..16, in bits 7..0 of the word.

Bits 15..8 of the second and fourth words are 0. A sample is an integer
from 0 to 0xFFFFFF: its 24 bits exactly as they go on the wire, bit 0 in
time slot 4 and bit 23 in time slot 27. So the frame with left sample
0x123456 and right sample 0xABCDEF arrives as the four words 0x3456,
0x0012, 0xCDEF, 0x00AB. The frames follow one another in the order they
are to be sent, with nothing between them and nothing to mark the last
one: after it the words stop.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

That is every preamble and the choice between B, M and W, the
biphase-mark coding, the validity, user and channel status bits, and the
parity bit, all as described above: no word holds a line level, a coded
bit, a status bit or a count.

In the simulator, the TX FIFO is refilled as soon as it has room, so you
do not need to worry about the host being slow.

A run is between 1 and 400 frames. The test includes runs longer than 192
frames, so the block structure matters. Every run starts from reset, with
the words of its frames and nothing else. They are pushed to thread 0's TX
FIFO in order, from the first cycle, each as soon as the FIFO has room.

## What to hand in (all in this directory)

1. `spdif.s`: the program.
2. `run_args.txt`: two lines.
   - The first line is `cell_cycles=N`, with N an integer from 2 to 48:
     the length of one cell in core-clock cycles (cycles of the 49.152 MHz
     clock, whatever clock divider your thread uses).
   - The second line holds the extra arguments for `pe_sim run`: the
     `-config` and `-mode` flags your program needs, and no other flag.
     (`-tx` and `-cycles` are added by whoever runs it.)
3. `notes.md`, as above, ending with: the program's length in instructions,
   the cell length and sample rate you chose, and anything about the chip
   that was confusing or that you think is wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way an S/PDIF
receiver would, on samples you have not seen.
