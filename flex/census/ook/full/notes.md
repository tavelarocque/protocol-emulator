# Notes: OOK Manchester transmitter

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `./pe_sim run x.s -help` (run 1 below).

Nothing else. One thing to report honestly: my very first command was
`ls -la && cat TASK.md && cat isa.md` in this folder. Its output was too long
for the tool, and the tool itself saved a copy of that output to a file
outside this folder and showed me its path. I did not open, list or follow
that path; I re-read `TASK.md` and `isa.md` directly from this folder instead.
I wrote nothing outside the folder on purpose.

## Design

The key choice is the clock divider: `clkdiv=25`, so one tick of the thread
is 25 cycles, half a bit (250 cycles) is exactly 10 ticks and a bit is 20
ticks. Every instruction boundary then lands on a multiple of 25 cycles, so
a transition is either exactly in place or off by at least 25 cycles; there
is no small drift to accumulate. It also means the per-bit code needs no
counter register, which matters because the thread only has X and Y.

Registers: X holds the current bit (from `out x, 1`), Y holds the
last-byte flag (bit 8 of the word). The bits left in the byte are counted by
the OSR itself: with `threshold=16` and `out_msb_first=1`, after a `pull`
the program does `out null, 7` (bits 15..9), `out y, 1` (bit 8), and then
eight `out x, 1` (bits 7..0, MSB first). After the eighth, the OSR count is
16, so `jmp !osre` stops being taken exactly at the end of a byte.

Line coding is done with `set pins` (P0, `set_base=0`, `set_count=1`): a 1 is
`set pins,1 [9]` then `set pins,0`; a 0 is `set pins,0 [9]` then
`set pins,1`. Writing a level the line already has is harmless, so the
boundary transitions come for free.

Cycle budget of one data bit, B = tick the bit starts:

- B: `set pins, b [9]` (10 ticks), B+10: `set pins, !b`.
- One path: `set pins,0` (1) + `jmp next` (1); zero path: `set pins,1 [1]`
  (2) and falls into `next`. Both reach `next` at B+12.
- Same byte: B+12 `jmp !osre getbit`, B+13 `getbit: jmp bitgo [4]`,
  B+18 `out x,1`, B+19 `jmp !x zero`, B+20 next bit's `set`.
- New byte of the same frame: B+12 `jmp !osre` (not taken), B+13
  `jmp y-- endframe` (not taken, Y was 0), B+14 `pull`, B+15 `out null,7`,
  B+16 `out y,1`, B+17 `jmp bitgo`, B+18 `out x,1`, B+19 `jmp !x`, B+20.
- End of frame: B+13 `jmp y--` taken, B+14 `jmp start [5]`, B+20
  `start: set pins, 0`, which is the fall exactly at the end of a last 0
  bit (and a no-op after a last 1).

Frame start: `start: set pins,0`, `set x,31`, `gap: jmp x--, gap [15]`
(32 x 16 = 512 ticks), `pull` (stalls with the line low when the host has
no more words, which is how the run ends), `out null,7`, `out y,1`,
`set x,15`, then the preamble loop `set pins,1 [9]`, `set pins,0 [8]`,
`jmp x--, pre` (20 ticks per bit, 16 bits). The sync nibble 0101 is written
straight-line (rises at S+10 and S+50, falls at S+30 and S+70, with S the
start of bit 16), then it falls into `bitgo` so `out x` runs at S+78 and the
first data bit starts at S+80, i.e. 400 ticks = 20 bits after the first rise.

Predicted timing: the run begins with the line low from cycle 1 (the
`set pins,0` at tick 0 shows as `pins 1`). The first rise is at tick 518 =
cycle 12950 (+1 for the print convention). The gap from the end of a frame's
last bit to the next first rise is also 518 ticks = 12950 cycles. Both are in
the 5000 to 20000 window.

`run_args.txt`:
`-config clkdiv=25,out_msb_first=1,threshold=16,set_base=0,set_count=1,start=0 -mode 0=pp`

## Test method

I wrote a small Python checker (kept in this folder during testing, deleted
before hand-in so only the asked files remain). It groups the host words
into frames, builds the ideal list of transitions from the TASK.md rules,
and compares it against the P0 bit of every `pins` line: P0 low by cycle
100, first rise in 5000..20000, every transition of the right direction
within +-2 cycles of its ideal place measured from the frame's first rise,
gaps in 5000..20000, and no transition after the last frame. I checked the
generator against the TASK.md example (0xA5: 46 transitions, frame ends at
14000) before using it, and checked that it does report errors by comparing
a waveform against the wrong word list (it reported 250-cycle errors and
stray transitions, as it should). Python runs are not pe_sim runs and are
not counted.

## pe_sim runs

1. `./pe_sim run x.s -help`: printed the flags (config keys, -cycles,
   -inputs, -mode, -stimulus, -tx).
2. `./pe_sim asm ook.s`: assembled without error, 33 words.
3. `run ook.s -tx (0x01A5) -cycles 54000` plus run_args: `pins 0 ff`,
   `pins 1 fe`, first rise `pins 12951`, as predicted. Checker: 1 frame,
   47 P0 changes (initial fall + 46), max error 0, no errors.
4. to 21. Eighteen runs from one script, each with N = 20000 + sum over
   frames of (20000 + frame length), as the test will use:
   - 4: frame 0x00 (last bit 0, fall at the end of the bit). OK, error 0.
   - 5: frame 0xFE (last bit 0). OK.
   - 6: frame 0xFF. OK.
   - 7: frames {0x12,0x34,0xFF},{0xA5}, the TASK.md word example. OK.
   - 8: six frames of sixteen 0x00. OK (1753 changes).
   - 9: six frames of sixteen 0xFF. OK.
   - 10: frames of sixteen 0x55 and sixteen 0xAA. OK.
   - 11 to 21: eleven random runs (seeded), 1 to 6 frames of 1 to 16 random
     bytes each, including 6-frame runs and 16-byte frames. All OK, max error
     0, no stray transitions.

Total: 21 pe_sim runs.

## Mistakes found

None showed up in testing; the first full run already matched. The design
was worked out on paper first (tick budget per bit for the three paths:
same byte, next byte, end of frame), and the tick counts in the comments of
`ook.s` are what the simulator showed.

## Program length

33 instructions (33 words, all in page 0).

## What was confusing, or may be wrong, in isa.md

- I found nothing that the simulator contradicted. The `pins c+1` print
  convention, the first tick being cycle 0 with `clkdiv`, `jmp x--` with a
  delay costing (n+1)(1+d) ticks, and `!osre` after threshold bits all
  behaved as described.
- There is no "OSR empty" condition, only `!osre`, and no plain "Y != 0"
  test: I used `jmp y--` for that, which also decrements Y. Both work, but
  the missing inverses forced the branch layout (which path falls through)
  and cost an extra jump in places.
- With `out_msb_first`, bits always come from bit 15 whatever `threshold`
  is. With the host's word format (byte in bits 7..0) that means discarding
  7 bits per word with `out null, 7`. It is stated clearly, but easy to miss
  if one assumes `threshold` picks the window.
- The `pins` lines print all 8 bits of the output register (`ff`/`fe`),
  including pins that are inputs, so the value is not "the pins' levels"
  for non-output pins; only P0 mattered here.
- Max delay is 15 (16 ticks), so a 10-tick half bit fits one instruction
  but a 20-tick span needs two; choosing `clkdiv` so the half bit is 10
  ticks while leaving 8 spare ticks for the byte change took some
  arithmetic, but the doc gave everything needed.
- Small point: isa.md says "jumps reach a 64-word page" and the assembler
  rejects cross-page labels; not relevant at 33 words.
