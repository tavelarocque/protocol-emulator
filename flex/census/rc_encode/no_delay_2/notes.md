# Notes: PT2262 encoder firmware

## What I read

- `TASK.md`, in full (137 lines, one read).
- `isa.md`, in full, in four parts (lines 1-160, 160-330, 330-490, 490-638).
- `./pe_sim run x.s -help` (run 1 below) for the flag list.
- Nothing outside this folder. I did not open the `pe_sim` wrapper script
  or `pe_sim.real`, only ran them.

## Design

The whole PT2262 code is built from quarters of 4 alpha (1600 cycles): a
pulse cycle is H, b, b, L with b = 1 for long and 0 for short; a trit is
two pulse cycles (8 quarters); the sync bit is H and 31 L (32 quarters); a
frame is 12 x 8 + 32 = 128 quarters = 204800 cycles. So I set
`clkdiv=1600`: one thread tick is one quarter, every instruction takes one
tick, and P0 is driven by side-set (`sideset_base=0`, `sideset_count=1`) on
every instruction, so each quarter's level is simply the `side` value of the
instruction run in it. Every edge then lands exactly on a multiple of 1600
cycles from the frame's first rise, with no error to add up, and the frame
period is exactly 128 ticks in every path. All counts fit `set`'s 5-bit
immediate, so no host-supplied constants are needed.

Data: `threshold=12`, LSB first (default), no autopull. Each trit is read
as two one-bit outs, X = bit0 and Y = bit1 (0 = '0', 1 = '1', 2 = 'f').
First pulse cycle is long iff bit0 = 1; the second is long iff bit0 or
bit1 is 1. The first pulse's rise instruction branches on X (`jmp !x`); the
short path does `mov x, y`, the long path leaves X = 1, and the second
pulse's rise branches on X again. The next trit's two outs happen in the
second pulse's spare ticks.

Word boundaries: after a trit's outs, the OSR is empty (12 bits shifted)
exactly when it was the sixth trit of the word, which `jmp !osre` tests
in the first pulse cycle. The trit loop exists in two copies. Copy A sends
word 1 (trits 0-5); at its word end it pulls word 2 at once (the host always
sends both words of a code word, so no stall can happen mid-frame) and its
second pulse jumps into copy B. Copy B sends word 2 (trits 6-11); at its
word end it goes to the sync bit. The sync bit is `set x, 27` (side 1, the
rise), a 28-tick `jmp x--` loop (side 0), then `pull`, `out x, 1`,
`out y, 1` (side 0): 1 + 28 + 3 = 32 ticks, falling straight into the first
trit of the next frame. When the host's words run out that `pull` stalls,
and side-set keeps applying side 0 while it stalls, so P0 stays low with no
further edge.

Start-up: `set x, 31` side 0 in tick 0 (P0 low from cycle 1), `jmp` into
the sync loop, so the first rise is tick 37 = cycle 59201 in the printout,
inside the 50000-100000 window.

The file `run_args.txt` holds:
`-config clkdiv=1600,sideset_base=0,sideset_count=1,threshold=12 -mode 0=pp`

## pe_sim runs (20 in total)

1. `./pe_sim run x.s -help`: listed the run flags and config field names
   (clkdiv, sideset_base, sideset_count, threshold and so on).
2. `./pe_sim asm rc_encode.s`: assembled without error, 55 words.
3. `./pe_sim asm rc_encode.s | wc -l`: the same assembly again to count
   lines: 55. (Two invocations in one command; I count both.)
4. Run of the TASK.md example (0x0018, 0x0481), 324800 cycles, raw output:
   `pins 0 ff` (initial state), `pins 1 fe` (P0 low), first rise at 59201,
   then 1600, 6400, 8000, 12800, 14400, 19200, 24000 after it as in the
   example table; sync rise 153600 and fall 155200 after the first rise
   (212801, 214401); nothing after. 52 lines.
5. Same example through a small Python checker I wrote in this folder
   (builds the ideal edges from the words, checks the first change is to
   low by cycle 100, the first rise in 50000-100000, every edge within 2
   cycles of its place from its frame's first rise, frame spacing 204800,
   and the exact edge count, so no stray edges up to the end of the run).
   My first version of the checker counted pe_sim's `pins 0 ff` line (the
   initial level, not a change) as an edge and would have failed; I fixed
   the checker before this run. Result: OK, 50 edges.
6. 8 code words: all '1', all 'f', all '0', the example, and mixes of
   0x0AAA/0x0555/0: OK, 400 edges, last edge 1648001, nothing after.
7. One code word of twelve '0's: OK, 50 edges.
8. One code word of twelve '1's: OK, 50 edges.
9-20. Twelve random runs (1 to 8 random code words each, seed 7): all OK,
   edge counts 50 to 400, every first rise at 59201, every edge exactly on
   its ideal place (error 0 cycles).

After testing I deleted the checker script (and its cache folder) so the
folder holds only what TASK.md asks for plus the given files.

## Mistakes found

- Only the checker bug above (treating pe_sim's cycle-0 `pins` line as an
  edge). The firmware passed on its first assembly and first run.

## Program length

55 instructions (one 64-word page, `start` = 0).

## Things in isa.md that were confusing or seem wrong

- `pe_sim run` prints a `pins 0 XX` line at cycle 0 that is the initial
  state, not a change; isa.md says it prints "whenever the pins' output
  changes", so this line is a small surprise.
- The `-config` description says what is not set is 0 or off except
  `out_count`, `set_count` and `threshold`; it is not stated whether
  `clkdiv` has an upper limit (16 bits?). 1600 worked.
- `threshold` is one field for both OSR and ISR; the table says so only
  implicitly ("when the OSR counts as empty and the ISR as full").
- The machine-state section says the OSR count "stands at threshold" at
  start; I did not rely on it (I always `pull` first), so I did not check it.
- Not wrong, but worth noting: side-set is applied on stalled cycles too,
  which is what keeps P0 low while the final `pull` waits forever. I relied
  on that sentence and the runs confirm it (no edge after the last sync).
- No rule broken that I know of.
