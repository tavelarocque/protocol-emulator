# Notes: LPC host firmware

## What I read
- TASK.md, in full (two parts: lines 1-110, 110-220).
- isa.md, in full (four parts: 1-150, 150-310, 310-460, 460-607).
- The first ~80 lines of the `pe_sim` wrapper (a Python script in this
  folder). It says this build of the chip lacks side-set and refuses
  programs that use it. isa.md never mentions side-set, so I lost nothing:
  LCLK is written with `set pins`.
- Nothing outside this folder.

## Design
Configuration (`run_args.txt`): `out_base=0, out_count=4` (LAD for
`out pins` / `mov pins`), `set_base=4, set_count=2` (bit 0 LFRAME#, bit 1
LCLK for `set pins`), `in_base=0`, `out_msb_first=1` (address nibbles most
significant first), `in_msb_first` off (the first nibble read ends up in
bits 3..0), `threshold=16` (so `jmp !osre` ends a 4-nibble loop). Pin
modes as the table in TASK.md requires.

Every LCLK period is 20 cycles laid out the same way. In the cycle F the
falling-edge instruction runs (`set pins, 1`, or `set pins, 0` for START,
which also pulls LFRAME# low). The LAD value of the clock is written in the
low phase, at F+1 to F+5. The rising edge (`set pins, 3`, or `2` during
START) runs at F+10, so its pins line is at F+11, which I placed at exactly
100 + 20k. So LAD and LFRAME# only change 5 to 10 cycles after a rising
edge and never at E-1 or E, LCLK is low 10 cycles and high 10 cycles, and
the edges are exactly on their places (no drift: every path through the
program was counted to 20 cycles per clock, using the delay field).

Flow:
- init: LCLK stays high from reset; a Y loop waits until cycle 89, where
  the idle loop's first fall runs (pins line at 90, 10 cycles low before
  rising edge 0 at cycle 100). X = 2 gives clocks 0..2 in the idle loop.
- idle loop: release clocks, X+1 of them.
- lastidle (the clock before each START): after the rising edge it pulls
  the type word, copies it into Y, and shifts the OSR left 14 so that type
  bits 1..0 sit at the top. If no words are left, the pull stalls here with
  LCLK high, which is after the last read's last clock, as allowed.
- START clock: LFRAME# low, `mov pins, null` puts 0000 on LAD, X = 11.
- CYCTYPE clock: `out pins, 4` from the shifted type word gives 0000 for
  type 0 and 0100 for type 1 (the bits b1 b0 0 0). Then pull the first
  address word.
- nib loop: one address nibble per clock until the OSR is empty.
- post: on the clock after the 4th nibble, Y = 1 (memory) loads the low
  address word, sets Y = 0 and X = 7, outputs nibble 4 and jumps back into
  the nib loop for the other 3; Y = 0 goes to the tail.
- tail: first TAR clock writes 1111 to LAD (`set y, 31; mov pins, y`), then
  TAR, SYNC (not checked: the sheet says it is always ready), then two DATA
  clocks, each sampled with `in pins, 4` at F+6, i.e. 5 cycles before the
  rising edge; the synchronised window for that clock's value is F-3 to
  F+16, so there are 9 and 10 cycles of margin. Then `push` and back to
  the idle loop. X+1 idle clocks plus lastidle make each read exactly 24
  clocks: 12 + 1 after an I/O read, 8 + 1 after a memory read.

## pe_sim runs (13 in total)
To test I wrote a small Python bench (check.py, deleted before handing in
so that only the asked-for files remain). Per call it built a random run
(TX words and the stimulus file exactly as TASK.md describes), ran pe_sim
once with `-tx -stimulus -cycles N` plus run_args.txt, and checked: every
rising edge within +-2 of 100 + 20k and enough of them up to L; every
high and low at least 6 cycles (including the high from reset); no change
of P0..P4 at E-1 or E; decoding every clock (chip output AND peripheral
level at E-1) against the expected START/CYCTYPE/ADDR/TAR/SYNC/DATA/TAR
nibbles and 1111 when idle; LFRAME# low only at START clocks and only
inside the START window; the chip's LAD outputs all 1 outside its window;
the RX words equal the peripheral's bytes.

1. `pe_sim run lpc.s -help`: the flag list (matches isa.md; it also lists
   sideset_base and sideset_count, which isa.md does not describe).
2. One I/O read of 0x0080 answering 0x5A (the TASK.md example), verbose.
   Every pins line as planned: rises at 100, 120, ...; START at 170/171;
   address nibble 8 at 251; release at 293; rx word 90 (decimal, = 0x5A).
   All checks OK. This also showed that the thread runs its first
   instruction in cycle 0 and that `rx` words are printed in decimal.
   Before this run I had changed init so LCLK no longer falls at cycle 1
   (a high of only 1 cycle after reset might count against the 6-cycle
   rule), and stays high until cycle 90.
3. One memory read: OK (CYCTYPE 0100 and 8 address nibbles decode right).
   My parser first treated rx words as maybe-hex; fixed to decimal.
4-9. Seeds 1-6, 8 random reads each, mixed types: all OK.
10. 8 memory reads: OK.
11. 8 I/O reads: OK.
12. Deliberately wrong config (`in_msb_first=1`) to make sure the bench
    catches mistakes: it failed with swapped nibbles (0xfb for 0xbf), as it
    should. run_args.txt restored afterwards.
13. `pe_sim asm lpc.s`: 46 words.

## Mistakes found
- None in the firmware's behaviour; it passed on the first run. The only
  change made before testing was the init (see run 2). One bench bug (rx
  parsing), fixed at run 3.

## Program length
46 instructions.

## Confusing or possibly wrong in isa.md
- It does not say how a multi-bit `out pins, n` with `out_msb_first` maps
  the bits onto pins (is bit 15 put on the highest pin or the lowest?). I
  assumed the n bits form a number with OSR bit 15 as its top bit, put on
  pins as "bit k of the value on pin base + k", and pe_sim agreed.
- `in` with LSB-first says bits are "shifted right into the ISR" but not
  where the new bits enter; together with "push ... right-justified" it
  worked out as expected (first nibble in bits 3..0).
- The `pe_sim run -help` flag list has `sideset_base` and `sideset_count`,
  which isa.md never mentions (and this build refuses side-set anyway).
- isa.md does not say which cycle a thread runs its first instruction in
  after the run starts; pe_sim shows cycle 0. The paragraph about the one
  extra cycle a thread is held after a memory write suggests the hardware
  may differ from that by one cycle; my timing has a +-2 margin only on the
  edge placement, so a fixed one-cycle shift would still pass.
- The `rx` lines print the word in decimal while TASK.md writes words in
  hex; isa.md does not say which.
- Not exactly wrong, but there is no way to write all ones to the LAD pins
  without a register holding them (no invert, `set` cannot reach them in
  this pin layout); I used `set y, 31` then `mov pins, y`.

## Rules
I believe I kept every rule: only this folder was read or written, 13
pe_sim runs, no em-dashes.
