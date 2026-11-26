# Notes: DSI transmitter

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `./pe_sim run x.s -help` output (run 1 below).

Nothing outside this folder was opened, listed or searched.

## Design

The half-bit is 8333.33 cycles. Instead of building large loop constants
from 5-bit immediates, I used the per-thread clock divider. 8333 = 13 x 641,
so with `clkdiv=641` one tick is 641 cycles and a half-bit is exactly 13
ticks (8333 cycles). Every line change then sits at k x 8333 cycles after
the rise, which is 0.33 x k cycles early compared with the ideal k x 8333.33.
The worst case is half-bit 17: 5.67 cycles early, far inside the +-80 limit.
Because all changes are whole tick counts from the rise, there is no drift
beyond that, and every frame's timing is identical.

Program flow (tick numbers relative to the frame's rise, t0):

- `stop` (address 0, also the reset entry): `set pins, 0 [15]`. At reset it
  drives P0 low in cycle 0 (visible at cycle 1). After a frame it is the
  stop-bit write at t221 (half-bit 17); it only changes the line when D0 = 0.
- Gap: `set x, 31` then `jmp x--, gap [6]`, 32 x 7 = 224 ticks.
- `main`: `pull` (stalls forever when the host has no more words, leaving the
  line low), `out null, 8` (drop bits 15..8; `out_msb_first=1` so the level's
  D7 comes out next), `set y, 7`.
- Rise: `set pins, 1 [10]` at t0, 11 ticks.
- Bit loop: `out x, 1` and `jmp !x, zero` take 2 ticks, so the first-half
  write lands at t13 + 26i. Each branch writes the first half with 13 ticks,
  the second half with `[9]`, then `jmp y--, bit`, so the next first-half
  write is again exactly 26 ticks later. Both branches write their halves
  even when the level does not change, which is harmless.
- After bit 0 each branch does `jmp stop [1]` (t219, 2 ticks), so `stop`
  executes at t221 = 17 x 13.

Frame period: rise to rise is 465 ticks = 298065 cycles, so the gap after the
stop bits is 298065 - 175000 = 123065 cycles (12.3 ms, limits 5 to 20 ms).
First rise: tick 244 = cycle 156405 (limits 50000 to 200000).

Configuration (`run_args.txt`):
`-config clkdiv=641,out_msb_first=1,threshold=16,set_base=0,set_count=1 -mode 0=pp`.
`set_base`/`set_count` are the defaults but stated for clarity; `threshold=16`
is not needed (no autopull, no `!osre`) but makes the OSR's 16-bit word explicit.

Program length: **17 instructions**.

## pe_sim runs

1. `pe_sim run x.s -help`: printed the flag list. It does not say how wide
   `clkdiv` is.
2. `pe_sim asm dsi.s`: assembled to 17 words, no errors.
3. `pe_sim run` with words 0x00A5, 0x0000, 0x00FF, 1325000 cycles: P0 high at
   cycle 0, low at cycle 1. Rises at 156405, 454470, 752535. 0xA5 changes at
   +16666, 33332, 49998, 66664, 74997, 83330, 99996, 116662, 133328, matching
   the TASK.md example to within 5 cycles, with the right levels. 0x00 ends
   with the fall at half-bit 17 (+141661). 0xFF ends low at half-bit 16. No
   change after the last frame. This confirmed clkdiv=641 is accepted and the
   first tick is cycle 0.
4. to 7. Using a small Python checker I wrote (decodes P0 edges, rebuilds the
   ideal Manchester waveform per level, checks each edge's level and its
   position against rise + k x 25000/3 within 80 cycles, gaps of 50000 to
   200000 cycles, low within 1000 cycles, and no extra edges), with the
   cycle budget 200000 + 375000 x frames: runs {A5,00,FF}, {00}, {FF},
   {01,80,7F,FE,55,AA,0F,F0}. All passed, worst edge error 5.67 cycles.
8. to 17. Ten random runs (seeded, 1 to 8 frames, random levels) with the
   same checker. All passed, worst error 5.67 cycles.

Total: 17 pe_sim invocations (1 help, 1 asm, 15 runs). The checker script
and its temporary word files were deleted before hand-in so the folder
holds only what TASK.md asks for.

## Mistakes found

None showed in simulation. Before running I checked the tick arithmetic by
hand: the branch to the stop write needed 2 ticks (`jmp stop [1]`) so that
the D0 = 0 fall lands on half-bit 17 and not 2 ticks (1282 cycles) early.

## Things in isa.md that were confusing or seem wrong

- The width of `clkdiv` is not given anywhere (neither in isa.md nor in the
  `-help`). I had to try 641 to find it was accepted.
- isa.md says that for a line that idles low you should enable the thread
  before making the pin push-pull. In `pe_sim` the `-mode` is applied from
  the start, so P0 is high in cycle 0 and only goes low at cycle 1; the task
  allows this, but the simulator gives no way to follow isa.md's advice.
- isa.md says configuration fields not set are "0 or off" with the
  exceptions listed; `threshold` defaulting to 8 is stated, but it is easy to
  miss that `out_msb_first` with threshold 8 still reads from bit 15, so a
  byte-in-low-bits word needs `out null, 8` first. The text does explain this
  under `out`, but the layout of the host word (level in bits 7..0) and the
  MSB-first shifter are at odds.
- The `in` description says it "shifts `count` bits right into the ISR" and
  then that `in_msb_first` shifts left; "right" only applies by default.
- isa.md mentions `docs/info.md`, `model/...` and `hw/...`, which are not
  available here; nothing I needed depended on them.

No rule was broken that I know of.
