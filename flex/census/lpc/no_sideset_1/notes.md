# Notes: LPC host firmware

## What I read

- `TASK.md`, in full (two parts: lines 1 to 110, then 110 to the end).
- `isa.md`, in full (three parts: lines 1 to 200, 200 to 400, 400 to the end).
- The help text of `pe_sim run` (run 1).
- Nothing outside this folder. No rule broken that I know of.

## Design

Pin mapping, all in `run_args.txt`:
`-config set_base=4,set_count=2,out_base=0,out_count=4,in_base=0,threshold=16,out_msb_first=1`
and modes P0 to P3 `od`, P4 and P5 `pp`.

With `set_base=4,set_count=2`, one `set pins, v` writes LFRAME# (bit 0) and
LCLK (bit 1) together: 0 = clock low/frame low, 1 = clock low/frame high,
2 = clock high/frame low, 3 = clock high/frame high. LAD is written with
`out pins, 4` (address nibbles, MSB first thanks to `out_msb_first`) or
`mov pins, x|y|null` (`out_count=4`), and read with `in pins, 4`.

Every LCLK period is exactly 20 cycles of straight-line or looped code. I call
"rel 0" the cycle in which the falling-edge `set pins` runs (rising edge + 9);
the rising-edge `set pins` runs at rel 10 and shows at rel 11 = the edge E.
Changes to LAD or LFRAME# may not show at E-1 or E, so they come only from
instructions at rel 0..8 (and rel 11 for LFRAME#, see below). The rising-edge
`set pins` also rewrites LFRAME#, but always with its current value, so no
change shows. LAD is changed at rel 1..3 of a period, about the falling edge.

Program flow (49 instructions, one page, no `set page` needed):

1. Prelude: LCLK stays high (reset level) until cycle 89 (a `jmp y--` delay
   loop), then the idle loop runs 3 periods (clocks 0, 1, 2), first fall
   shows at cycle 90, first rising edge at 100.
2. Idle loop: `set pins,1 [9]; set pins,3 [8]; jmp x-- idle`, x+1 periods.
3. Read slot of 24 periods, P0 = clock s-1 (idle) to P23:
   - P0: `pull` the type word, `out x, 16` (this also leaves the OSR empty),
     branch: memory sets y=7 (8 nibbles) and x=4 (CYCTYPE 0100); I/O sets
     y=3, x stays 0. Both branches take the same number of cycles.
   - P1 (START): LFRAME# low and LAD 0000 from the falling edge; at rel 10
     LCLK rises, and at rel 11 LFRAME# goes high, so it shows high from E+1
     (it is low only through clock s and at the edge itself).
   - P2 (CYCTYPE): `mov pins, x`, then x becomes the idle count after the
     read (11 for I/O, 7 for memory), again with balanced branches.
   - Address loop, y+1 periods: `jmp !osre` decides whether the OSR needs a
     new word; if so `pull` then `out pins,4`, else `out pins,4` with one more
     cycle of delay, plus a `jmp` to keep both paths at 10 cycles. The first
     iteration always pulls (after `out x,16`), and for memory the fifth does.
   - TAR1: `mov pins, y`: y has wrapped to 0xFFFF after the loop, so LAD is
     released (1111) from rel 2 of the first TAR clock.
   - TAR2, SYNC: plain clocks (SYNC is not checked; the sheet says the
     peripheral is scripted and always ready).
   - DATA low and high: `in pins, 4` at rel 5, which sees the level of rel 3
     (two-cycle synchroniser), i.e. 12 cycles after the edge before, well
     inside the window in which the peripheral holds the nibble (+4 to +24).
     Default right shift, so after two `in`s `push` gives high<<4 | low with
     bits 15..8 zero.
   - Then `jmp idle` with x+1 = 12 (I/O) or 8 (memory) idle periods, which
     ends at P0 of the next slot, so the next START is exactly 24 clocks on.
4. After the last read the next slot's `pull` stalls with LCLK low, after the
   last read's last clock, which the sheet allows.

Program length: 49 instructions (49 words from `pe_sim asm`).

## pe_sim runs (34 in total)

1. `pe_sim run x.s -help`: flag list. It shows `sideset_base` and
   `sideset_count` config fields that `isa.md` does not document. I did not
   use them.
2. `pe_sim asm lpc.s | wc -l`: 48 words (first version).
3. Example from TASK.md (I/O read of 0x0080, peripheral answers 0x5A):
   address nibbles 0,0,8,0 and CYCTYPE correct, edges at 100+20k, but
   `rx 375 90`. I first thought the byte was wrong.
4. `pe_sim asm lpc.s | head -3`: checked the encoding of `set y, 4` (c104).
5. Same read with byte 0x12: `rx 375 18`. 90 and 18 are the decimal values of
   0x5A and 0x12: `pe_sim` prints `rx` words in decimal, while `pins` values
   are hex. No bug in the program.
6. to 10. I wrote `check.py` (a checker that generates random runs in the
   test's format, runs pe_sim once each with `-cycles 100+20(4+24R)`, and
   checks every rule of TASK.md: edge positions within +-2, no extra edges,
   edges up to L, high/low >= 6 cycles, no P0-P4 change at E-1 or E, decoded
   bus values for every clock, chip LAD outputs 1111 outside the allowed
   window, LFRAME# low only within clock s up to and including its edge, rx
   words). Seeds 1 to 5: all failed on "LFRAME low at 181": the first version
   raised LFRAME# at the falling edge of the CYCTYPE clock, so it stayed low
   for half a clock after the START edge. My checker is stricter than the
   sampling decoder needs, but "low for exactly one clock" can be read that
   strictly, so I changed the program to raise LFRAME# one cycle after the
   START edge (the earliest rule 4 allows).
11. to 16. Seeds 1 to 6 after the fix: all OK (1 to 5 reads, mixed types).
17. to 21. Fixed cases: the TASK.md example; 8 memory reads at 0xFFFFFFFF and
   0 with bytes 0x00/0xFF; 8 I/O reads at 0xFFFF/0; 8 mixed reads; one memory
   read of 0xFFC01234 answering 0x07. All OK (also shows the RX FIFO does not
   block past 4 words in the simulator).
22. and 23. The single memory read printed and read by hand: START at 180,
   CYCTYPE 0100 at 200, address F,F,C,0,1,2,3,4 at 220..360, TAR 1111 at 380,
   `rx 455 7`, LCLK stops low at 630 after edge 26 (L = 20).
24. `pe_sim asm lpc.s | wc -l`: 49 words.
25. to 34. Seeds 11 to 20 (1 to 8 reads): all OK.

The checker, its generated files and my early test files were scratch work;
I deleted them before handing in so that the folder holds only what TASK.md
asks for plus the given files.

## Mistakes found

- LFRAME# held low until the falling edge after START (found by my checker,
  runs 6 to 10); fixed as above.
- I misread `rx` output as hex (runs 3 and 5); it is decimal.

## Confusing or possibly wrong in isa.md

- `isa.md` says `pe_sim run` "prints `rx CYCLE WORD`" but not that WORD is
  decimal while `pins` values are hex. That cost me a run.
- `pe_sim run -help` lists `sideset_base` and `sideset_count`, which
  `isa.md` never mentions (no side-set field in the encoding). Either the
  document or the tool is out of date.
- The meaning of "right-justified" for `push` with the default right shift
  (new bits enter at the top) is only implied; it worked as PIO does: two
  `in pins, 4` give high<<4 | low.
- `out pins, n` is described as "written from out_base up"; it is not said
  whether n or `out_count` pins are written. I set both to 4 so it does not
  matter.
- Without side-set every pin change costs its own instruction and the
  clock and data cannot be written in one instruction unless they share a
  `set` or `mov` range; putting LFRAME# and LCLK next to each other (P4, P5)
  is what made `set pins` able to drive both.
- It is not said whether the RX FIFO in `pe_sim` is drained by a simulated
  host; it is (8 pushes did not stall).
