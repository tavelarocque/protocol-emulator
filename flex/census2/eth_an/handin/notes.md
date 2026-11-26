# Notes: Ethernet auto-negotiation FLP transmitter

## What I read

- TASK.md, in full (151 lines).
- isa.md, in full, in four parts (lines 1-180, 180-360, 360-540, 540-699).
- `./pe_sim run x.s -help` output (the flag list).
- Nothing outside this folder.

## Design

Configuration (run_args.txt):
`-config clkdiv=4,set_base=0,set_count=2,out_base=0,out_count=1,threshold=16 -mode 0=pp -mode 1=pp`

- `clkdiv=4`: the thread ticks once every 4 cycles (100 ns). A pulse is then
  simply one tick with P0 high: exactly 4 cycles, with no width bookkeeping.
  Every pulse place is a whole number of ticks (2500 cycles = 625 ticks),
  so the timing is exact, not approximate, and nothing accumulates.
- `set_base=0, set_count=2`: `set pins, 0` drives P0 and P1 low, `set pins, 1`
  drives P0 high and P1 low. So P1 is written low by the first instruction
  (visible at cycle 1) and every later write keeps it low.
- `out_base=0, out_count=1`: `out pins, 1` puts the next data bit straight on
  P0, so the data position needs no branch: a 1 is a pulse, a 0 leaves the
  line low. The OSR shifts LSB first by default, so D0 goes first.
- One `pull` per burst, no autopull. If the FIFO is empty the `pull` stalls
  with the line low, so there is exactly one burst per word and nothing after
  the last word.

Program flow (times in ticks):

1. `set pins, 0` at tick 0.
2. Gap: nested loop, Y = 31 outer, X = 31 inner over a 6-instruction body of
   16-tick instructions: 1 + 32 x (1 + 32 x 96 + 16) = 98,849 ticks.
3. `pull`, `set y, 15`.
4. Per bit (16 passes): `set pins,1` (clock rise at T), `set pins,0 [14]`,
   `set x,18`, a 2-instruction 32-tick loop run 19 times (608 ticks), then
   `out pins,1` at T+625 (data), `set pins,0 [13]`, `set x,18`, 608-tick loop,
   `jmp y-- bit` (1 tick), so the next clock rise is at T+1250.
5. Last clock pulse (`set pins,1`, `set pins,0`) at 32 x 625 = 20,000 ticks
   = 80,000 cycles after the first rise, then `jmp main` back to the gap.

Resulting timing (measured, see runs): first burst's first rise at cycle
395,409 (9.9 ms; limits 40,000 to 640,000), burst to burst 475,416 cycles
(11.9 ms; limits 320,000 to 960,000), every pulse exactly on its place
(error 0 cycles), width 4 cycles.

## pe_sim runs

1. `./pe_sim run x.s -help`: printed the flag list (config fields, -cycles,
   -inputs, -mode, -stimulus, -tx).
2. and 3. A command meant to run `pe_sim asm eth_an.s` and a first simulation
   hit a full disk: my Write of eth_an.s had failed with "no space left on
   device", so these two invocations ran on a missing file and their output
   was lost. I count them as runs anyway. (An `ls`/`df` of this folder in the
   next command also failed for the same reason and showed nothing.) Space
   came back on retry.
4. `pe_sim asm eth_an.s`: 26 words.
5. Run with one word 0x01E1, 1,920,000 cycles: `pins 1 fc` (P0, P1 low at
   cycle 1), then 22 rises at 395,409 + {0, 2500, 5000, 10000, 15000, 20000,
   25000, 27500, 30000, ..., 80000}, each falling 4 cycles later. Exactly the
   list in TASK.md.
6. Same run piped into my own checker (check.py, written here and deleted
   afterwards; it checks low by cycle 100, P1 never high, no other pin
   changes, width 3 to 5, every pulse within 40 cycles of its place, first
   burst window, burst spacing, no extra pulses): OK.
7. Eight words 0x0000, 0xFFFF, 0x01E1, 0x41E1, 0x8001, 0x5555, 0xAAAA,
   0x1234, 8,640,000 cycles: OK, 186 rises, spacing 475,416.
8. to 10. Random words, 3, 5 and 7 of them, N = 960,000 x (n + 1): all OK.
11. Tail of the one-word run: last change `pins 475413 fc`, so the line
    stays idle after the burst to the end of the run.

Total: 11 pe_sim invocations (2 of them lost to the full disk).

## Mistakes and rule notes

- No program bugs found; the first version passed.
- The full disk (see runs 2 and 3) was outside my control. The tool's error
  message mentioned locations outside the folder; I did not follow them or
  free space anywhere.
- I wrote helper files (w1.txt, w8.txt, wr.txt, check.py) in this folder for
  testing and deleted them at the end, so only the hand-in files remain.

## Program length

26 instructions (one page, no page handling needed).

## Confusing or possibly wrong in isa.md

- The `pins` lines show the whole output register, so with only P0 and P1
  written the other six bits stay 1 (`fc`, `fd`). isa.md says this (an input
  pin shows its register bit, driving nothing), but it is easy to misread
  `fd` as "P2 to P7 high".
- isa.md does not say in which cycle `pe_sim run` enables the thread, or
  that with `clkdiv` the first tick is cycle 0 in the simulator; I found it
  from the output (`pins 1 fc`).
- `set` takes only 5 bits (0 to 31), so any delay longer than about
  32 x 16 ticks needs nested loops or a longer loop body; isa.md is correct
  about this, just limiting. With only X and Y as counters, the 10 ms gap
  needed a 6-instruction loop body to reach the length with two levels.
- The loop timing statement ("`l: jmp x-- l` entered with X = n takes
  exactly n + 1 cycles") is in cycles; with `clkdiv` it is ticks. That
  follows from the clkdiv row, but the sentence could say so.
- Nothing I relied on turned out wrong: the measured timing matched my
  cycle count from isa.md exactly.
