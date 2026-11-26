# Notes: AC '97 output firmware

## What I read

- `TASK.md`, in full (two parts: lines 1 to 100, then 100 to 199).
- `isa.md`, in full (four parts: lines 1 to 150, 150 to 309, 310 to 459, 460 to 607).
- `./pe_sim run x.s -help` output (run 1 below).
- Nothing outside this folder. I listed the folder itself once (`ls -la`, `wc -l`).

## Timing analysis

BIT_CLK rises at cycle r, is high for exactly 2 cycles and falls at r+2;
the next rise is at r+4 or r+5, so the next fall is at r+6 or r+7. The
synchroniser delays everything 2 cycles, so a thread sees the pin high in
cycles r+2 and r+3 only, and low from r+4.

A `wait 1 pin 0` that is waiting therefore executes in cycle r+2 (the
cycle in which BIT_CLK falls on the pin). An instruction executed in cycle
c shows its pin write as `pins c+1`. Writes are forbidden in the fall
cycles r+2 and r+6 (when the period is 4), so a write must execute in
cycle r+2 .. r+4, which means the first or second instruction after the
wait (cycles r+3, r+4, showing at r+4, r+5). A third instruction after the
wait (cycle r+5) may run but must not write pins. The next `wait 1` must be
reached no earlier than r+4 (or it sees the same high phase again) and no
later than r+6 (to catch the next rise on time). So every bit is a
"group": wait + 1 to 3 instructions, pin writes only in the first two.

The group that sees the rise preceding falling edge k-1 sets the level
carried by falling edge k. For the first frame: the program waits for a
low reading first (to skip the reset-high synchroniser reads in cycles 0
and 1), then the first group sees the codec's first rise, whose fall is
edge 0, and so sets SYNC high for edge 1. Edge 1 is allowed (1 to 255).

## Design

Pins: `set pins` with set_base=1, set_count=2 writes SYNC (bit 0) and
SDATA (bit 1) together (0, 1 = SYNC only, 3 = both). `out pins, 1` and
`mov pins, x/y` with out_base=2, out_count=1 write SDATA alone. OUT is
MSB first, threshold 16, no autopull, so after a word's 16 bits further
`out`s give zeros: that is the 4-bit padding of slots 2, 3, 4 and the 12
zero bits of slot 1, for free.

Per frame, with e the edge where SYNC rises (groups e .. e+255):

- e: `pull` CTRL, then `set pins 1` (SYNC high, data 0), `out null 7`.
  The pull comes before SYNC is raised, so when the words have run out the
  thread stalls there forever with both lines low and no new pulse.
- e+1: tag bit 15 = 1 (`set pins 3`), `out y 1` (Y = c8), `out x 1` (X = c7).
- e+2: tag bit 14 = c8 (`mov pins y`), then a jump (third slot of the group).
- e+3: tag bit 13 = c8 and not c7: `jmp !x` to `mov pins y`, else
  `set pins 1` (read gives 0).
- e+4, e+5: 1, 1. e+6 .. e+15: 0 with SYNC high (loop on Y).
- e+16: `set pins 0` (SYNC low, tag bit 0).
- e+17: slot 1 bit 19 = c7 (`mov pins x`), X := 3.
- e+18 .. e+36: 19 `out pins 1` (address a6..a0 then zeros).
- slots 2, 3, 4: a group with `pull`, `out pins 1` (at r+4, shows r+5), then
  the shared 19-bit loop; X counts the slots.
- e+97 .. e+255: 159 zero edges: one group, then a nested loop
  (30 + 4 x 32), then back to group e of the next frame.

Tag cases: none (c8=0, c7=0) gives 1,0,0,1,1 = 0x9800; write gives
1,1,1,1,1 = 0xF800; read gives 1,1,0,1,1 = 0xD800.

`run_args.txt`:
`-config set_base=1,set_count=2,out_base=2,out_count=1,out_msb_first=1,threshold=16 -mode 1=pp -mode 2=pp`
(P0 stays an input by default.)

## Test tools

I wrote two Python scripts in a scratch subfolder `work/` (inside this
folder; deleted before hand-in so the folder holds only what TASK.md asks
for): `gen.py` makes random TX words (write, read or no-command frames) and
a BIT_CLK stimulus (first rise R in 200..299, rises at R + floor(phi +
k * 50/12.288), high 2 cycles, so periods of 4 with a 5 about every 14.5),
and N = 400 + 1042 (F+2). `check.py` samples SYNC and SDATA at every
falling edge (ignoring the reset artifact), checks no change of P1/P2 in a
fall cycle, both low by cycle 40, first SYNC at edge 1..255, 16-edge SYNC
pulses every 256 edges, exactly F pulses, SYNC changing only 1 + 2F times,
every frame bit against the expected slots and SDATA low elsewhere.

## pe_sim runs (25 in total)

1. `run x.s -help`: flag list. It lists `sideset_base` and `sideset_count`
   config fields that isa.md never mentions (see below). Not used.
2. `asm ac97.s`: assembled, 49 words.
3. `run`, 2 random frames (R=217): 56 errors. First bad bit was tag bit 11
   (edge e+5) and SYNC dropped one edge early. Cause: group e+5 was a bare
   `wait 1 pin 0` followed directly by the next `wait 1 pin 0`, which ran in
   cycle r+3 while the pin still read high, so it passed at once and the
   frame slipped one edge. Fix: `wait 1 pin 0 [1]` for that group.
4. Same test after the fix: 0 errors.
5. The TASK.md example words (R=299): 0 errors; an independent decode gave
   tags F800 / D800 and slots 02000 08080 12340 EDCB0 / FC000 00000 7FFF0
   80000, rest 00000, exactly as the table in TASK.md.
6. to 21. Sixteen random runs: F = 1, 12, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1,
   1, 12, 3; R including 200, 201, 298, 299; phases 0.0 to 0.999; all-write,
   all-read, all-no-command and mixed frames. All 0 errors.
22. to 24. Beyond the spec: every period 4, every period 5, and periods
   chosen at random (4, 4, 5), 4 frames each: 0 errors.
25. `asm ac97.s`: 49 words (final count).

## Mistakes

- The bare-wait group (run 3), described above. I had reasoned that a wait
  must be reached no earlier than r+4 and then wrote a group that broke it.

## Program length

49 instructions (words), all in page 0.

## Confusing or possibly wrong in isa.md

- `pe_sim run -help` lists `sideset_base` and `sideset_count` config fields,
  but isa.md describes no side-set anywhere (not in the encoding, the
  syntax or the instructions). I did not use them.
- `out pins, n`: the config table says `out_base, out_count` are for
  `out pins` and `mov pins`, but the `out` description says only "written
  from out_base up", so it is unclear whether `out pins, n` writes n pins or
  out_count pins. I sidestepped it by using `out pins, 1` with out_count=1.
- `threshold` defaults to 8 in pe_sim but the reset state says the OSR count
  "stands at threshold"; it matters little here, I set 16 explicitly.
- No non-blocking pull or "FIFO empty" test exists, so the only way to stop
  after the last frame is to block in `pull`. That works here because the
  pull is placed before SYNC is raised, but it is worth stating in the doc.

No rule was broken that I know of.
