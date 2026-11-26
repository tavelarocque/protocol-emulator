# Notes: 7-segment driver for the protocol emulator

## What I read
- `ls -la` of this folder: TASK.md, isa.md, pe_sim.
- TASK.md in full.
- isa.md in full.
- Nothing else. One incident: my first command (`ls`, `cat TASK.md`, `cat isa.md` in one go)
  produced more output than the tool shows, and the tool harness saved that output to a file
  outside this folder and printed its path. I did not open that file; I re-read TASK.md and isa.md
  from this folder with a file reader instead. I mention it only because a path outside the
  folder appeared in my output.

## Design

All eight pins have to change in one cycle, so the only usable writes are `mov pins` / `out pins`
with `out_count = 8` (side-set cannot help: it has no "optional" bit, so every instruction would
drive its pins). I build the whole pin byte in the ISR and write it with one `mov pins, isr`.

Configuration: `start=64, out_base=0, out_count=8, out_msb_first=1, in_msb_first=1,
threshold=16`, all eight pins push-pull.

With `out_msb_first` the word comes out of the OSR from bit 15 down, which is the order I need:
`out null,9` (bits 15..7, all zero), `out x,1` = last, `out y,1` = blank, `out x,1` = dp,
`out x,4` = the digit as a plain number. With `in_msb_first` the ISR shifts left, so the ISR is
built in the order last, dp, (g,f), (e..a), giving

    ISR = last<<8 | dp_n<<7 | g_n<<6 | f_n<<5 | e_n d_n c_n b_n a_n

where `_n` are pin levels (0 = lit). `mov pins, isr` writes bits 7..0 to P7..P0; bit 8 is ignored.

- dp is the inverse of the word's bit 4. There is no invert, so I use `jmp x-- next` (X is 0 or
  1; X-1 flips bit 0) before `in x,1`.
- Digit decode: a linear chain `c_k: jmp x-- c_(k+1)` with leaf k inline after c_k (taken when X
  reaches 0). Digit d spends d+1 cycles in the chain (15 for d = 15); each leaf's delay field
  pads chain + leaf to exactly 17 cycles. A leaf is `set x, <a..e levels>` and `jmp` to one of
  four tails that `set y, <g,f levels>` (2 cycles each). `set` only has 5 bits, hence the split.
  Then `in y,2; in x,5`.
- Blank (bit 5) skips the chain with `set x,31 [15]; set y,3; jmp common [1]`, the same 19
  cycles as chain + leaf + tail.
- The chain, leaves and tails (58 words) live in page 0; the main loop lives in page 1
  (`start = 64`). `set page,0` before the dispatch, `set page,1` before jumping back. The blank
  path physically sits in page 1 but runs with PAGE = 0, so it jumps to `common` in page 0.
- Loop timing, every path the same, counted from the cycle `mov pins` executes (M):
  4 cycles to test last (`mov osr,isr; out null,7; out x,1; jmp !x top`), 12 in `top` (pull
  through `jmp !y c0`), 17 chain + leaf, 2 tail, 4 common (`in`, `in`, `set page`, `jmp pad`),
  then 960 cycles of padding (`set x,31 [14]` 15 + loop 512 + `set x,26` 1 + loop 432), so the
  next `mov pins` is at M + 1000 exactly. No error can build up along the run.
- The pull for word k+1 happens about 5 cycles after word k is shown; the FIFO is refilled long
  before then, so it never stalls after the first word. The first pull at cycle 0 did not stall
  in the simulator: T0 = 996.
- Equal neighbouring words rewrite the same byte, so the pins do not change.
- Last word: X = 1 after the test; `jmp x--` twice makes X = 0xFFFF (all pins dark), a padded
  wait on Y (16 + 512 + 1 + 464 cycles after the 3 test/decrement cycles), `mov pins, x` at
  M + 1000, then `halt: jmp halt`. Nothing changes after that.
- The last word is never followed by a `pull`, so the empty FIFO never stalls the timing.

Segment levels (a..e as X, g/f as Y, pin byte without dp):
0 X0 Y2 C0, 1 X25 Y3 F9, 2 X4 Y1 A4, 3 X16 Y1 B0, 4 X25 Y0 99, 5 X18 Y0 92, 6 X2 Y0 82,
7 X24 Y3 F8, 8 X0 Y0 80, 9 X16 Y0 90, A X8 Y0 88, b X3 Y0 83, C X6 Y2 C6, d X1 Y1 A1,
E X6 Y0 86, F X14 Y0 8E. I checked these bytes against the usual common-anode table by hand and
then in the simulator (run 4 shows every digit).

## pe_sim runs (20 in total)

1. `pe_sim run seven_segment.s -help`: the flag list (config keys, -mode, -tx, -cycles, ...).
2. `pe_sim asm seven_segment.s`: assembled with no error, 96 words. I checked a few encodings by
   hand: `jmp x-- dpn` = 0x0088 (cond 2, addr 8 = word 72), `jmp !y c0` = 0x00c0,
   `jmp common [1]` = 0x0236 (addr 54 in page 0), `jmp pad` = 0x000f (word 79). The assembler
   accepted the page-0 jump that follows `set page,0` in page-1 code, and `.page 1`.
3. Run of "3.14" (0x13, 0x01, 0x44) with run_args.txt: `pins 996 30`, `1996 f9`, `2996 99`,
   `3996 ff`. Exactly as TASK.md's example, T0 = 996.

For runs 4 to 20 I wrote a small Python checker in this folder (since deleted, with its word
files) that writes the words, runs `pe_sim run seven_segment.s -tx FILE -cycles N` with N =
20000 + 1000n + 5000 and run_args.txt, takes T0 from the first change, and compares the full
list of (cycle - T0, pin byte) with the ideal list: a change at 1000k whenever the pattern
differs from the one before, and blank at 1000n. It demands an exact match (zero cycles error)
and T0 <= 20000. Each check is one pe_sim run.

4. 64 words: every digit with and without dp, blanks with and without dp, repeated blanks,
   repeated digits, repeated digits with dp, ending 0x5E. OK, 43 changes, T0 = 996.
5.-10. Six random 64-word runs (blanks, repeats, dp mixed in). All OK, T0 = 996.
11.-12. Two random 1-word runs. OK.
13.-14. Two random 2-word runs. OK.
15. Random 17-word run. OK.
16. Random 5-word run. OK.
17. [0x70] (only a dp on a blank, last). OK: dp on at T0, all high at T0+1000.
18. [0x30, 0x20, 0x60] (ends in two equal blanks). OK: 2 changes only.
19. [0x0F, 0x0F, 0x4F] (one unbroken F for 3000 cycles). OK.
20. [0x40] (a single "0"). OK.

Every run matched to the exact cycle, so the error is 0 cycles everywhere (limit +-2).

## Mistakes found
None showed up in testing. While designing I caught on paper that the dp bit has the wrong
polarity for a common-anode pin (word bit 1 = lit, pin 0 = lit) and added the `jmp x--` flip
before the first run.

## Hand-in
- `seven_segment.s`
- `run_args.txt`: `-config start=64,out_base=0,out_count=8,out_msb_first=1,in_msb_first=1,threshold=16`
  and `-mode P=pp` for P = 0..7.
- this file.

## Program length
90 instructions (58 in page 0, 32 in page 1). The image is 96 words because `.align` fills the
rest of page 0 with 6 `nop`s.

## Confusing or possibly wrong in isa.md
- `in`: "shifts count bits right into the ISR" with no word on where the new bits enter by
  default, or what `mov x, isr` / `mov pins, isr` read (the raw register, or the right-justified
  value `push` gives). I avoided the question with `in_msb_first`, where new bits enter at the
  bottom, and confirmed it in the simulator.
- `in y, 2` / `out x, 4` with msb-first: the doc does not say outright that the n bits keep
  their natural order (value = ISR<<n | low n bits of the source; X = top n bits as a number). It
  behaved that way.
- The assembler's page tracking: the doc says it follows PAGE "down the listing", but not
  explicitly that it follows `set page, n` instructions as well as `.page`. It does (my
  `jmp common` after `set page, 0` in page-1 code was accepted).
- Side-set has no optional/enable bit (PIO has `.side_set n opt`), so with side-set on, every
  instruction drives those pins. That rules it out for anything but a clock; worth stating.
- There is no way to invert a bit or to load an 8-bit constant in one instruction (`set` is
  5 bits), so a 7-segment table costs two instructions per entry plus a dispatch. That is the
  main reason the program needs two pages. Not wrong, just costly for this job.
- Small: the simulator prints `pins 0 ff` at cycle 0 for the reset state; the doc only says it
  prints when the output changes.
