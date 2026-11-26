# Notes: SDA 2506 host firmware

## What I read
- TASK.md, in full.
- isa.md, in full.
- `pe_sim run x.s -help` output (run 1).
Nothing outside this folder was opened, listed or searched.

## Design
Thread 0, `clkdiv=10`, so one tick is 10 cycles (1 us) and every edge of the schedule (all on multiples of 50 cycles) falls on a tick. An instruction executed on the tick at cycle c changes the pins at c+1, so every CLK and CE edge lands exactly 1 cycle after its place, with no drift.

Pins: CLK (P0) is side-set (`sideset_base=0, sideset_count=1`), so every instruction states the clock level. DATA (P1) and CE (P2) are written together by `set pins` (`set_base=1, set_count=2`: value 3 = DATA released + CE high, 1 = released + CE low, 2 = DATA low + CE high, 0 = both low). Command bits go out on DATA with `out pins, 1` (`out_base=1, out_count=1`), the read/erase control bit with `mov pins, x`, and read bits come in with `in pins, 1` (`in_base=1`).

Decoding a TX word: `pull`, copy it to Y, `out null, 15` then `out x, 1` gives bit 15, then `mov osr, y` restores it. A write sends all 16 bits of the word LSB first, which is exactly D0..D7, A0..A6, CB=1. A read or erase does `out x, 8` (X = 0 for read, 1 for erase), sends the 7 address bits from the OSR and then CB from X. X is then reused: after the shared start/first pulse slot, `jmp !x` sends a read (X=0) to the sampling loop; a write (X=1 from bit 15) or erase (X=1) falls into the 20 ms wait.

Each slot is 20 ticks: DATA written at tick 0, CLK rises at tick 5, falls at tick 15. Loops are padded with delays so each iteration is exactly 20 ticks. Pre-operation decoding takes 13 ticks after the previous CE rise (+2), so slot 0 lands 150 cycles after CE rises. Before the first operation: `set x, 22 [2]` and a 23-iteration 8-tick loop put the first `pull` at tick 187 (slot 0 at tick 200 = cycle 2000).

The 20 ms wait is one instruction: `wait 1 pin 0 timeout` on CLK, which the thread itself holds low, so it always times out; `timeout=19997`, `timeout_vector=36` (the CE-rise instruction). Measured: CE rises exactly at slot n+2 + 200000 (+1 cycle).

Read sampling: bit k is sampled at tick 2 of slot n+k+2 (cycle +20, seeing the level of cycle +18 after the 2-cycle synchroniser). The EEPROM drives bit k from cycle -40 to +160 of that slot (to +60 for bit 7), so the margins are 58 and 42 cycles. After bit 7, `push` (the ISR shifts right and push right-justifies, giving the byte LSB-correct with bits 15..8 = 0), then CE rises at tick 5. After the last operation the thread stalls on `pull` with CLK low, CE high, DATA released.

## pe_sim runs (12 in total)
1. `run -help`: flags list.
2. `asm sda2506.s`: 46 words, `tov` at address 36, wait encodes as 0x2110 as intended.
3. One erase of 0x12: every edge exactly where expected (+1 cycle): bits at 2001.., CE falls 3651, start pulse 3851/3951, CE rises 204001. Confirmed timeout=19997 is right and that `wait ... pin 0` looks at P0 (CLK) and not at in_base+0 (DATA, which was high, so a relative pin would have ended the wait at once).
4. Erase 0x12, write 0x3C, read 0x12 with a checker script I wrote (builds TX file, stimulus and expected waveform from TASK.md, compares every CLK/CE edge to +-2 cycles, DATA level outside the +-20 windows, and RX words). All timing passed but RX reported "0190" vs "003c". Two mistakes, both mine: (a) my stimulus builder dropped low bits when one low bit ended in the same cycle the next began; (b) I parsed the `rx` value as hex, but pe_sim prints it in decimal (190 = 0xBE, which was exactly what my buggy stimulus said).
5. Small probe program for `in`/`push` semantics: `rx` printed 1, 21, 21, 128, 1, confirming decimal printing and LSB-first right-justified push.
6. Same as 4 with both checker bugs fixed: all OK, RX 0x003C.
7. Eight reads (addresses 0, 0x7F, ...; bytes 0x00, 0xFF, 0xA5, 0x5A, 0x01, 0x80, 0x7E, 0x81): all OK.
8. Writes of 0xFF/0x00 at 0x7F/0x00, erases, reads, a write, an erase (8 ops): all OK.
9. to 12. Four random sequences (8, 4, 7 and 2 ops) with random addresses and data: all OK.
The checker, the probe program and the generated test files were deleted afterwards so the folder holds only the hand-in.

## Program length
46 instructions (one page).

## Confusing or possibly wrong in isa.md
- `pe_sim` prints `rx CYCLE WORD` with WORD in decimal, while `pins` is in hex. isa.md does not say which base; this cost me a false failure.
- `wait pol pin n`: isa.md does not say whether n is an absolute pin or relative to `in_base` (PIO's `wait pin` is relative). Run 3 shows it is absolute.
- Wait timeout counting: "stalls for T cycles at most, and if the pin is still wrong, jumps on the cycle after". Measured: the wait instruction occupies T+1 ticks in total and the vector's instruction runs on the next tick. Whether the first (executing) tick counts as one of the T stalled ones is not clear from the prose; the measurement settles it.
- Minor: the sheet says the timeout counts in ticks with clkdiv; that matched.
No rule was broken that I know of.
