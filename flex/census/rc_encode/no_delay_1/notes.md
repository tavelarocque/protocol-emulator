# Notes: PT2262 (rc_encode) encoder firmware

## What I read
- TASK.md, in full (137 lines).
- isa.md, in full, in four parts (lines 1-160, 160-320, 320-480, 480-638).
- `pe_sim run x.s -help` output (flag list).
Nothing outside this folder was opened, listed or searched.

## Design
Key choices:
- **clkdiv = 800.** One thread tick is 800 cycles = 2 alpha. Every length in
  the protocol is a whole number of ticks: short pulse = 2 H + 6 L, long
  pulse = 6 H + 2 L, trit = 16 ticks, sync = 2 H + 62 L = 64 ticks, frame =
  256 ticks = 204800 cycles. Since every instruction is exactly one tick, all
  edges fall exactly on the ideal grid (offset +1 cycle, because a write in
  cycle c shows at c+1), and nothing can drift.
- **Side-set on P0** (`.side_set 1`, sideset_base 0, sideset_count 1). Every
  instruction states the line level, so no instruction is spent on `set pins`
  and the level at each tick is visible in the source.
- **X = 1 permanently** (except in delay loops, after which it is restored),
  so `jmp x!=y` at trit tick 0 separates '1' (long first pulse) from '0'/'f'.
  At tick 8 `jmp !y` separates '0' (short second pulse) from '1'/'f'.
  Ticks 0 and 8 are high for every trit, so the branch instructions carry
  side 1 in all cases.
- **Data:** threshold 12 with autopull. `out y, 2` takes one trit; the sixth
  out of a word empties the OSR and autopull refills it in the same cycle, so
  word boundaries cost nothing. The value of trit k+1 is read during trit k
  (it must be known at tick 0 of trit k+1); trit 0 of a frame is read during
  the previous sync's low part, or during the start-up delay.
- **Trit counter:** the ISR. Each trit does `in null, 1`; with threshold 12,
  `!isrf` is false after the 12th trit. That flag (a) skips reading ahead in
  the last trit (`jmp !isrf` to the out, else a `jmp` of equal length), and
  (b) at tick 15 (low for every trit) `jmp !isrf top` either starts the next
  trit or falls into the sync. `mov isr, null` in the sync resets the count.
- **End of run:** the sync's `out y, 2` (side 0) finds the OSR empty and the
  FIFO empty, so it waits forever with the line low. No stray edge.
- **Start:** first instruction drives P0 low at cycle 1. Delay loops put the
  first rise at tick 91, cycle 72801 (window 50000 to 100000). The start-up
  `out` takes one extra tick to fetch the first word; that only shifts the
  first frame, which is fine.

Layout: start-up (9 words), trit tick 0 branch, long-first block (t1-t7),
short-first block (t1-t7), tick 8 branch, long-second block (t9-t15), sync
(placed so the long-second block falls into it), short-second block (ends
with `jmp sync1 side 1` as sync tick s0).

## pe_sim runs (38 in total)
1. `pe_sim run x.s -help`: flag list; confirmed `clkdiv`, `sideset_*`,
   `autopull`, `threshold` config names.
2. Example code word 0x0018, 0x0481, 324800 cycles: P0 low at cycle 1, first
   rise 72801, then edges at +1600, +6400, +8000, +12800, +14400, +19200,
   +24000, ... matching the TASK.md table exactly.
3-13. A Python checker (written in this folder, deleted before hand-in)
   running 11 cases (the example, twelve 1s, twelve fs, twelve 0s, 6 random
   runs, one 8-word mixed run). All "failed", but the bug was in my checker:
   it took pe_sim's `pins 0 ff` line (the initial state) as an edge. Fixed the
   checker to treat cycle 0 as the initial level.
14-24. Same 11 cases (seed 7): all OK, every edge at error 0, exact edge
   counts (so no stray edges after the last frame), frame spacing 204800,
   first rise 72801.
25-37. 13 cases (seed 99, 4 fixed + 8 random + 1 mixed, 1 to 8 code words):
   all OK, max error 0.
38. `pe_sim asm rc_encode.s`: 51 words.

## Mistakes
- Only the checker bug above (initial `pins 0` line read as an edge). The
  firmware itself passed on the first real test.

## Program length
51 instructions.

## Confusing or possibly wrong in isa.md
- "A loop `l: jmp x-- l` entered with X = n takes exactly n + 1 cycles": with
  clkdiv above 1 it is n + 1 ticks, not cycles. The clkdiv row does say waits
  count in ticks, so this is only wording.
- The autopull text does not say plainly what happens when an `out` empties
  the OSR and the FIFO is empty (I read it as: the out completes, the OSR
  stays empty, and the next out waits). The simulator behaved that way.
- `-config` default for `threshold` is 8 per isa.md; it is shared by the OSR
  and the ISR, which the config table implies but is easy to miss. I relied
  on it (12 for both).
- The `pins` print at cycle 0 shows the reset level (all ones) as if it were
  a change; TASK.md says it is not counted, but it is easy to misread.
- No em-dash or rule problem to report; no rule was broken.
