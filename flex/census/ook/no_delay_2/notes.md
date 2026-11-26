# Notes: OOK transmitter firmware

## What I read

- `TASK.md`, in full (144 lines, one read).
- `isa.md`, in full, in four parts (lines 1-160, 160-320, 320-480, 480-638).
- `./pe_sim run x.s -help` (run 1 below) for the flag names.
- Nothing outside this folder. No rule broken that I know of.

## Design

Configuration (`run_args.txt`): `clkdiv=10, out_msb_first=1, threshold=16,
set_base=0, set_count=1`, and `-mode 0=pp`. With clkdiv 10 one tick is 10
cycles, so half a bit is 25 ticks and a bit 50 ticks. Every instruction is one
tick and every path was counted, so all transitions land exactly on their
ideal cycle (error 0). The delay loops `set x, k` then `l: jmp x-- l` take
k + 1 ticks, which keeps every count within the 5-bit `set` immediate.

The pin is written only with `set pins` (no side-set). A bit is sent by one
routine (`next`): `out x, 1` at tick -2, `jmp !x zero` at tick -1, the
first-half level at tick 0, a 23-tick loop, the second-half level at tick 25,
then a common tail. The tail checks `!osre`; if bits remain it waits so that
the next `out x, 1` is at tick 48. All 20 + 8n bits of a frame go through this
one routine, so the preamble and sync are timed exactly like data:

- Preamble: X is made 0xFFFF (`set x, 0` then `jmp x--`, which wraps) and
  moved into the OSR: 16 ones.
- Sync: `set x, 5; mov osr, x; out null, 12` leaves 0101 at the top of the
  OSR with 4 bits to go before it counts as empty.
- Bytes: with `out_msb_first`, `out null, 7` drops bits 15..9, `out y, 1` puts
  the last-byte flag in Y, and the 8 data bits follow MSB first.

When the OSR runs empty, the boundary path (ticks 28 to 47 of the last bit)
uses Y as state: 3 = preamble done (load sync, Y becomes 2), 2 = sync done
(restore the first word, Y becomes the flag), 0 = byte done and more follow
(`pull`, read the flag), 1 = last byte done (wait to tick 50, `set pins, 0`,
which is the fall for a final 0 and no change for a final 1). Each path loads
X and jumps into the shared delay loop just before `next`, so `next` runs at
tick 48 on every path.

Frame start: `pull` blocks until the frame's first word exists, so after the
last frame the thread sits in `pull` with the line low and nothing moves. The
word is saved in the ISR (`mov isr, osr`), a nested loop waits 32 x 34 ticks,
then Y = 3, OSR = 0xFFFF, and the bit routine starts. The very first
instruction is `set pins, 0`, which shows at cycle 1. First rise of the first
frame: cycle 10991; gap from the end of one frame to the next first rise:
about 10990 cycles (inside 5000 to 20000).

Program length: **51 instructions** (one page, no page handling needed).

## pe_sim runs

1. `run x.s -help`: printed the flags and config field names.
2. `asm ook.s`: assembled, 51 words.
3. `run ook.s -tx t1.txt (0x01A5) -cycles 40000`: P0 high at 0, low at 1,
   first rise at 10991, 46 transitions, last fall at 24741 = 10991 + 13750,
   matching the table in TASK.md.
4-28. `check.py 1 20`: 25 runs (the TASK examples, all-0x00, all-0xFF 16-byte
   frames, six 1-byte frames, and 20 random runs of 1 to 6 frames of 1 to 16
   bytes), each run with the test's cycle count. The script rebuilds the
   ideal transition list per frame and checks levels, place error (max 2
   cycles), low by cycle 100, first rise in 5000..20000, gaps in 5000..20000,
   no stray transitions, line low at the end. Result: 25 of 25 pass, every
   transition exactly on its ideal cycle.
   (One attempt to run the checker through `python -c exec(...)` crashed in
   Python before calling pe_sim, so it is not counted as a run.)
29-43. `check.py 7 10`: 15 more runs, a different random seed. 15 of 15 pass.

Total: 43 runs of pe_sim.

## Mistakes found

None showed up in simulation. On paper I first had the `zero` path falling
straight into the tail, which would have reached it one tick earlier than the
`one` path (which needs a `jmp`); I gave both paths a `jmp tail` before
writing the file. I also first planned to loop the sync nibble with Y, but
the loop's entry instruction (`set y, 1`) put the first iteration one tick
out of step with the second; running the sync through the common bit routine
avoided that.

## Confusing or possibly wrong in isa.md

- `out` with `out_msb_first`: "the bits come from bit 15 of the OSR downward,
  whatever threshold is". Clear, and it worked, but it is easy to misread
  `threshold` as also choosing where the data sits.
- The `jmp x--` wrap ("decremented either way (wrapping)") is the only way I
  found to make 0xFFFF with a 5-bit `set`; it is a useful trick that the
  document mentions only in passing.
- The `pins` print shows all 8 bits; unused input pins read 1 (`ff`/`fe`),
  which the document does not say for the simulator's default `-inputs`.
- Nothing I found contradicted the simulator. The document points at files
  (`model/isa.ml`, `model/firmware.ml`, `docs/info.md`) that are not here,
  which is fine for this test but means the UART example cannot be read.
- There is no per-instruction delay field, so every wait costs a register
  loop; with only X and Y, the counter for the frame state had to share Y
  with the last-byte flag.
