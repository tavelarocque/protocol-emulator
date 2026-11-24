# Hidden acceptance test, round two: S/PDIF transmitter

This folder is the examiner's side of the second round. The programmer
sees only the kit (`../../kits2/spdif/`: `isa.md`, `pe_sim`, `TASK.md`) and
never this folder. No firmware for the chip was written to make it, not
even as a check: the judge was validated against a Python model of the
line.

## Why there is a round two

In round one the task sheet let the programmer decide what the TX words
mean and hand in a `host.py` that produced them. That let the host do the
biphase-mark coding, the preambles, the status bits and the parity, and
send line levels for the firmware to play back, which measures nothing
about the instruction set. In round two the task sheet fixes the host
interface and there is no `host.py`.

## The host interface, as the task sheet states it

Four 16-bit words per frame, in this order: the left sample's bits 15..0;
the left sample's bits 23..16, in bits 7..0 of the word; the right
sample's bits 15..0; the right sample's bits 23..16, in bits 7..0 of the
word. Bits 15..8 of the second and fourth words are 0. Frames follow one
another with nothing between them and nothing to mark the last: the words
simply stop. The sheet's example: left 0x123456 and right 0xABCDEF are the
words 0x3456, 0x0012, 0xCDEF, 0x00AB.

The sheet says: "The host sends only the words defined above. All line
coding, framing and timing must be done by the firmware." So the firmware
has to make every preamble and choose between B, M and W, do the
biphase-mark coding, send V = 0 and U = 0, put the channel status bit at 1
in frames 2 and 24 of each 192-frame block, and work out the parity bit.
Nothing in the task was weakened to make that easier.

The programmer still chooses the cell length, 2 to 48 cycles. It is now
declared in `run_args.txt`, which has two lines: `cell_cycles=N`, then the
`-config` and `-mode` flags for `pe_sim`. The hand-in is `spdif.s`,
`run_args.txt` and `notes.md`. Clock, pin, the description of the line,
the timing limits, the start and end of a run and the rules section are
word for word those of round one.

## Running it

    python3 accept.py RUN_DIR [seed]

`RUN_DIR` holds `spdif.s`, `run_args.txt` and `pe_sim` (run as exactly
`RUN_DIR/pe_sim`, so it may be a wrapper). Exit status 0 only if all
eleven cases pass. Output: a header line, one line per case, an `info:`
line, a `RATE` line, then `ACCEPT PASS` or `ACCEPT FAIL`.

The eleven cases, the direct check and the check by sigrok's `spdif`
decoder are round one's, unchanged, and `../../hidden/spdif/README.md`
describes them, with the lead-in subframe and the closing edge the judge
adds for the decoder. Four things differ.

- The judge builds the TX words itself (`tx_words`), from the interface
  above. It never opens a `host.py`: one left in the run folder is ignored.
- The cell length is read from the first line of `run_args.txt`, which
  must be exactly `cell_cycles=N` with N a whole number from 2 to 48. The
  second line must hold only `-config` and `-mode` flags, each with a
  value; `-tx`, `-cycles`, `-inputs` and anything else are refused. A
  missing first line, a third line or a value out of range ends the run
  with `cannot load the hand-in` and `ACCEPT FAIL`.
- The `info:` line now always says 4 TX words a frame, with the words a
  second that makes at the declared rate. At 48 kHz it is 192,000, inside
  the 260,000 the host port carries; a cell of 5 cycles or less is not.
- After it the judge prints, for the last case that passed,
  `RATE frames=<frames> cycles=<cycles from P0's first change to its last>`.
  With all cases passing that is always the last case, so two hand-ins
  judged with the same seed are compared on the same samples. The span
  counts every change of P0, so a start-up edge and the steady stretch
  after it are included; without one it is 128 x frames x cell, less the
  last cells of the run in which the line does not change. No case
  passed: no RATE line.

An exception inside the judge is now caught and reported as a failed case.

## Validation of the judge

    python3 -B validate.py 1     # about a minute; exit 0 = judge validated

Result on seeds 1 and 3: `JUDGE VALIDATED`, nothing wrong
(`validation_seed1.txt`, `validation_seed3.txt`).

`selftest/fake_run/pe_sim` is a stand-in that prints the ideal waveform of
`ideal.py` (unchanged from round one, and sharing no code with
`accept.py`). It now receives the judge's words and reads them back into
samples by the task sheet's rules, in its own code, and stops with an
error if the words are not four a frame or a high word is above 0xFF. So
the ideal waveform passes only if the judge's words, the stand-in's
reading of the sheet, the judge's direct check and sigrok's decoder all
agree.

- Interface: `tx_words` gives exactly the words printed in the task
  sheet's example, and the sheet contains that text.
- Correct waveforms, 10 rows, all pass 11 of 11: the ideal at cells of 8,
  2, 3, 12 and 48 cycles; a start-up edge with 70 steady cells at 8 and
  48; the allowed closing edge at 8 and 2; jitter of exactly 5% at 40.
- Broken waveforms, 22 rows, all fail: one audio bit flipped with parity
  kept even (cells 8 and 2), a wrong parity bit, one cell too long (cells
  8, 2 and 48), one cell long and the next short (cells 8 and 19), jitter
  over 5% at cell 40, an 8-cell gap between subframes, no B after the
  first block, channel status all zero, channels swapped, most significant
  bit first, the low four bits sent as zero, biphase-space, M and W
  exchanged, validity set, the last subframe missing, an extra edge after
  the end, a start at cycle 10500, and a start-up edge with only 10 steady
  cells. The table of verdicts, of which half of the judge objects and of
  first complaints is line for line the same as round one's.
- The declared cell length: the ideal waveform drawn with 9 cycles a cell
  under `cell_cycles=8`, with 8 under `cell_cycles=9`, and with 16 under
  `cell_cycles=8` fails every case.
- RATE: for the ideal waveform at cells of 8 and 48 the line equals the
  figure worked out from the waveform's own changes (seed 1, 280 frames:
  `RATE frames=280 cycles=286712` at 8 cycles a cell).
- Hand-in rules: a `host.py` that declares another cell length and would
  leave a marker file if loaded was put in the passing folder; the judge
  passed and no marker appeared. Eleven bad `run_args.txt` files were each
  refused (no `cell_cycles` line, the two lines in the wrong order, no
  flags line, N of 1, 49 and 8.0, round one's `CELL_CYCLES = 8`, a third
  line, `-tx`, `-cy`, `-inputs`), and two good ones were accepted.
- The real simulator: the kit's `pe_sim` behind a wrapper
  (`selftest/real_pe_sim_idle/`), with a one-instruction program that
  loops on itself and drives no pin. It is not S/PDIF firmware. The
  simulator accepted the command line and the word file, and all 11 cases
  failed cleanly with "P0 never changes" and no RATE line.

The weakness named in round one still stands: the direct check and
`ideal.py` were written by the same examiner from the same reading of
IEC 60958, and sigrok's decoder is an independent witness for the preamble
shapes, the bit order, the slots of V, U, C and P and biphase-mark itself,
but not for parity being even, for which frames carry B, or for timing.

## What is still not closed

- The judge runs `RUN_DIR/pe_sim`, whatever it is. A hand-in that replaced
  it with a script drawing the waveform would pass, exactly as the
  stand-in of the validation does. Whoever runs the judge must put the
  simulator into the run folder themselves.
- `run_args.txt` is the same for every case, so nothing that depends on
  the samples can be put there. It can still hold constants the host
  writes into the chip's configuration registers, and one of those
  registers is a piece of hardware that does arithmetic: the CRC register,
  whose polynomial and start value are the host's to set and which `mov`
  can read. A firmware that gets its parity bit from it has used the chip,
  not cheated, but it has not used the instruction set for that step.
  Read the configuration line when hand-ins are compared.
- The cell length is free up to 48 cycles. A long cell buys instructions
  per bit at the price of the sample rate (48 cycles is 8 kHz). The RATE
  line and the header line show it.
- Bits 15..8 of the second and fourth words are 0, and V and U are 0. A
  firmware may send those two bits by shifting on into the empty half of
  the word. That is two bits of the framing for free.
- A slow host is never provoked: the simulator refills the FIFO at once.
- Everything in "What it does not check" of round one's README still
  holds.

## Is a fully on-chip transmitter feasible? (not solved here)

No firmware was written, so this is a judgement from `isa.md` only. I
think it is feasible, at a cell clearly longer than the minimum, and that
it is the hardest of the three by a wide margin. The reasons for and
against, each from the document:

- No instruction inverts a pin, and biphase-mark is a code of toggles. But
  the level does not need a register. It can live in the control flow (the
  bit code written twice, once for each level), and the task sheet's own
  remark does the rest: with even parity the line is at the same level
  before every preamble. So the preambles are fixed level patterns, and
  the parity bit is simply "whatever brings the line back to that level",
  which the control flow already knows. No arithmetic is needed for
  parity.
- A thread has two registers that a `jmp` can test, X and Y. Testing a
  data bit takes one. The other has to count 192 frames and find frames 2
  and 24, and `set` loads only 5 bits, so 191 and the two frame numbers
  have to be built by shifting through the ISR or the block has to be cut
  into counted stretches. The ISR and OSR can hold a value but cannot be
  tested. This is where I expect most of the difficulty.
- One `threshold` serves every word, but the words carry 16 bits and then
  8, followed by four bits that are not in any word. The 8-bit half needs
  a second way of counting.
- Every path through a bit must take exactly two cells, including the
  paths that fetch a word, and the delay field pads at most 15 cycles. A
  program that crosses 64 words also pays two instructions per jump to
  another page. Both push the cell length up. I would not expect the
  2-cycle cell to be reachable, and would not be surprised by 8 to 16.
- Nothing marks the last frame. `pull` stalls on an empty FIFO, so a
  firmware that fetches the next frame's first word before it starts that
  frame's preamble stops by itself with the line steady.

If a programmer reports that it cannot be done, the second and third
points are where to look first.
