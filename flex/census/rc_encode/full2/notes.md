# Notes: PT2262 encoder on the protocol emulator

## What I read

- `TASK.md`, all 137 lines.
- `isa.md`, all 644 lines, in four parts (lines 1-160, 160-330, 330-490,
  490-644).
- `pe_sim run x.s -help` (run 1 below).

Nothing outside this folder was opened, listed or searched. I broke no rule
that I know of.

## Design

The key idea is the per-thread clock divider. With `clkdiv=400` one thread
tick is exactly one alpha (400 cycles), and the thread's first tick is cycle
0. Every pin write therefore lands on a cycle 400k + 1, so every edge is at
an exact multiple of alpha from every other edge: no rounding error and no
drift, as long as each path through the program takes the right number of
ticks. All the PT2262 segments (4, 8, 12, 16 alpha) fit in one instruction
of 1 + delay ticks (delay up to 15), so the program is short.

Each 16-alpha pulse cycle is seen as 4 ticks high, an 8-tick "middle", then
4 ticks low; the middle is high for a long pulse cycle and low for a short
one. A trit arrives as two bits, b0 then b1 (LSB first, the default shift):
'0' = 00, '1' = b0 set, 'f' = b1 set. So the first middle is b0 and the
second middle is b0 OR b1. The program reads b0 into X (`out x, 1`) and
writes it with `mov pins, x`; for the second pulse cycle, if X is not 0 the
pin is simply left high (b1 is dropped with `out null, 1`), else `out pins,
1` writes b1. Both branches take the same number of ticks.

Words come in by autopull with `threshold=12`: the `out` that takes the
twelfth bit (b1 of the sixth trit) refills the OSR in the same tick, so no
`pull` instruction and no stall at word boundaries. Y counts the 12 trits of
a code word (`jmp y--`). The sync bit (4 high, 124 low) is set pins 1 / set
pins 0 followed by an X delay loop, which then jumps back to `next`, the
`out x, 1` that fetches the first bit of the next code word just before its
rise. When the words run out the last refill finds the TX FIFO empty, and
that `out x, 1` stalls forever after the last sync bit, with the line low.
This is the only place a stall can happen once the run has started.

Start: `set pins, 0` in tick 0 (shows at cycle 1), set Y to 11, then join
the sync bit's delay loop. The first `out` with an empty OSR spends one tick
fetching, and the first rise lands at tick 142, cycle 56801 (window 50000 to
100000).

Tick schedule of one trit (tick 0 = its rise): rise 0, first middle 4,
fall 12, rise 16, `jmp !x` 19, second middle 20, fall 28, `jmp y--` 29,
`out x, 1` 30-31, next rise 32. Sync path: rise at 32, fall at 36, delay
loop, next frame's rise at 160 (= 32 + 128). Frame = 12 x 32 + 128 = 512
ticks.

Config (`run_args.txt`): `-config clkdiv=400,threshold=12,autopull=1 -mode
0=pp`. out_base and set_base are left at 0 (P0), out_count and set_count at
their default 1.

`check.py` (my own test helper, in this folder) encodes code words into
words, runs `pe_sim` once with the arguments in `run_args.txt` and the
cycle count from TASK.md, and checks: first P0 change is to low by cycle
100, first rise in 50000..100000, exactly 50 edges per frame and none
after, every edge's level and place within 2 cycles of ideal relative to
its frame's first rise, and frame spacing 204800 +- 2.

## pe_sim runs

1. `pe_sim run x.s -help`: printed the flag list (config field names,
   -cycles, -inputs, -mode, -stimulus, -tx). Does not say the range of
   clkdiv.
2. `pe_sim asm rc_encode.s`: assembled, 20 words.
3. `pe_sim run` with the TASK.md example code word (0x0018, 0x0481), 324800
   cycles: P0 fell at cycle 1; first rise 56801; edges relative to it at 0,
   1600, 6400, 8000, 12800, 14400, 19200, 24000, 25600, 30400, 32000,
   36800, ..., trit 11 at 140800, 145600, 147200, 152000, sync at 153600,
   155200, then nothing to the end. Matches the TASK.md table exactly. This
   also showed that clkdiv=400 is accepted and that the autopull refill
   finding an empty FIFO does not stall the `out` that triggered it.
4. check.py seed 1, 8 code words (the example, twelve 1s, twelve fs,
   twelve 0s, 4 random): 400 edges, first rise 56801, worst offset 0, OK.
5. check.py seed 2, 1 random code word: 50 edges, worst offset 0, OK.
6. check.py seed 3, 3 random code words: 150 edges, worst offset 0, OK.
7. check.py seed 4, 8 random code words: 400 edges, worst offset 0, OK.
8. check.py seed 5, twelve 1s then 1 random: 100 edges, worst offset 0, OK.

Total: 8 runs of pe_sim. No mistakes found; the first version passed.

## Program length

20 instructions (20 words, from run 2).

## Confusing or possibly wrong in isa.md

- The range of `clkdiv` is not given anywhere (neither in isa.md nor in the
  `-help`). 400 worked in the simulator; whether the hardware register is
  wide enough is something I could only take on trust from the simulator.
- For autopull it says an `out` that empties the OSR refills it "if the
  FIFO has a word", but not what happens to that `out` if the FIFO is
  empty (stall or carry on). Run 3 showed it carries on and the OSR stays
  empty, so the next `out` waits.
- The `-config` syntax for the on/off fields (`autopull=1`) is not spelled
  out; `=1` worked.
- `pins CYCLE XX` prints all eight output bits; the seven unused pins read
  1 from the reset value of the output register. Not wrong, but worth
  knowing when reading the trace.
- Nothing that I found to be actually wrong.
