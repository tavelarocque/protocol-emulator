# Notes: LPC host firmware

## What I read

- `TASK.md`, in full (two parts: lines 1 to 110, then 110 to the end).
- `isa.md`, in full (four parts: lines 1 to 160, 160 to 330, 330 to 490, 490 to the end).
- `./pe_sim run x.s -help` output (run 1).
- Nothing outside this folder. No rule broken that I know of.

## Design

The thread runs with `clkdiv=10`, so one tick is 10 cycles, half an LCLK
period, and every LCLK clock is exactly two instructions. I call them F
(the tick at 100 + 20k - 10, where LCLK falls) and H (the tick at
100 + 20k, which raises LCLK: rising edge k). Only F instructions write
LAD or LFRAME#, so those lines change 9 cycles after an edge and 11 before
the next, far from the forbidden cycles E - 1 and E. Because a write in
cycle c shows at c + 1, every rising edge shows at 101 + 20k: a fixed +1
cycle offset inside the +-2 limit, and it cannot add up because the
divider is exact. LCLK is high 10 cycles and low 10 cycles.

LCLK (P5) and LFRAME# (P4) are side-set (`sideset_base=4, sideset_count=2`,
bit 0 = LFRAME#, bit 1 = LCLK), so every instruction states both and the
clock never costs an instruction. LAD is `set pins` (set_base 0, count 4)
for START, CYCTYPE and TAR, and `out pins, 4` for the address. The OSR is
MSB first with autopull at threshold 16: the address nibbles come out most
significant first, the second word of a memory address arrives without a
gap, and the out that ends the address loads the next read's type word.
`out y, 16` in the idle clocks takes the type word into Y (and autopull
loads the address word). Once the words run out, that `out` waits forever
with LCLK low, which happens in clock t + 7, after the last rising edge L.

Per read (START clock s): F s `set pins 0` side LFRAME# low; H s branch on
Y; clock s + 1 writes CYCTYPE (0000 or 0100) and, for memory, sets X = 7
(I/O keeps X = 3 from the idle code); the address loop is `out pins, 4` /
`jmp x-- addr`; first TAR clock `set pins 15` (release); the low nibble is
sampled with `in pins, 4` at H of t + 3 and the high nibble at H of t + 4
(the synchroniser shows the level from 2 cycles before, well inside the
peripheral's window); `push` at F of t + 5 gives 0x00HL (ISR shifts right,
push right-justifies). Then X is set to the idle wait (4 for memory, 8 for
I/O) and the idle code runs X + 3 clocks, making every read exactly 24
clocks. Boot holds LCLK low from cycle 1 to rising edge 0 at cycle 101,
does an explicit `pull` at tick 10 so the steady-state `out y, 16` is
always one tick, and enters the idle code with X = 0 so START 0 lands in
clock 4.

Registers: Y = type of the current read, X = loop counter. No ISR/OSR
tricks beyond the above.

## pe_sim runs (14 in total)

1. `run -help`: listed the flags and config field names.
2. `asm lpc.s`: assembled, 35 words.
3. `run` on the TASK.md example (I/O read of 0x0080, answer 0x5A),
   660 cycles: edges at 101, 121, ...; START at 171 (pins c0), address
   nibbles 0, 0, 8, 0, TAR release at 291, last edge 421, then LCLK low
   and the thread stalls. It printed `rx 390 90`, which I first took for
   0x90 and thought the data was wrong.
4. Debug copy that pushed `in pins, 8` every tick around SYNC/DATA: the
   values 240, 250, 213 showed that `rx` prints the word in decimal
   (0xF0, 0xFA, 0xD5). So run 3's 90 was 0x5A: correct. My mistake, not
   the program's.
5. Wrote a Python checker (my own, in this folder, since deleted) that
   builds the TX words and the stimulus file from TASK.md's table, runs
   pe_sim with `run_args.txt` and the N of TASK.md, and checks: edge
   places (+-2), no extra edges, high/low >= 6, low before edge 0, no P0
   to P4 change at E - 1 or E, the decoded LFRAME#/LAD value of every
   clock up to L against the expected fields, the chip's LAD outputs all
   1 outside the allowed window, LFRAME# low only around its START clock,
   and the RX words. Run 5: the TASK.md example through it: OK.
6. TASK.md's two-read example (I/O 0x0080 -> 0x5A, memory 0xFFC01234 ->
   0x07): OK, rx 0x5A then 0x07.
7. to 10. Four random runs of 8 mixed reads (seeds 1 to 4): all OK. This
   also shows the RX FIFO is drained by the simulator (8 pushes, no stall).
11. A mutant (I/O idle wait 7 instead of 8) through the checker, to see the
    checker can fail: it reported missing edges and wrong clocks, as it
    should.
12. One memory read of 0xFFFFFFFF answering 0xFF (run ends on a memory
    read): OK.
13. Eight memory reads (four 0xFFFFFFFF/0xFF, four 0/0x00): OK.
14. Eight I/O reads (four 0/0x00, four 0xFFFF/0xFF): OK.

Scratch files (debug copy, mutant, checker, TX and stimulus files) were
deleted after testing so the folder holds only the hand-in.

## Program length

35 instructions (`pe_sim asm lpc.s` prints 35 words).

## Confusing or possibly wrong in isa.md

- `pe_sim run` prints `rx CYCLE WORD` with the word in decimal, while
  `pins` lines are hex. isa.md does not say which base; I lost a run to it.
- The side-set section says the `side` field's unused bits are reserved,
  and the field is 4 bits ([12:9]) but side-set takes at most 3 of them;
  fine, but the table of `sideset_count` (0 to 3) and the 4-bit field
  could say outright that bit 9 is always reserved.
- It does not say in which cycle a thread first runs under `pe_sim run`
  (I found by experiment that the first tick is cycle 0, as "its first
  tick is the first cycle it is enabled" suggests) nor when the first TX
  word is available; I avoided depending on cycle 0 by pulling at tick 10.
- `in`: "shifts count bits right into the ISR" with right-justified push:
  correct as observed, but the exact bit placement of a multi-bit `in`
  with LSB-first shifting is left to the reader.
