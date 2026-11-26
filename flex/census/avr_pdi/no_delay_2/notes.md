# Notes: AVR PDI programmer firmware

## What I read
- `TASK.md`, in full (one read of 190 lines).
- `isa.md`, in full, in four parts (lines 1-160, 160-320, 320-480, 480-638).
- `pe_sim run x.s -help` output (the flag list).
- Nothing outside this folder. I created a subfolder `t/` here for test inputs, outputs and a checker script (`t/check.py`).

## Design
Configuration (`run_args.txt`): `clkdiv=5, sideset_base=0, sideset_count=1, set_base=1, out_base=1, in_base=1, threshold=8, crc_poly=1`, modes `0=pp 1=od`. Everything else default (crc_init 0, LSB first, no autopull/autopush).

With `clkdiv=5` one tick is 5 cycles, so a 50-cycle PDI slot is exactly 10 ticks: 5 ticks with clock low (side 0) followed by 5 with clock high (side 1). Every instruction carries the clock level on side-set (P0), so the clock is correct by construction as long as every code path spends exactly 10 instructions per slot, which I counted by hand and annotated in the source (L0..L4, H0..H4). Short delays are `set y, k-2` followed by `l: jmp y-- l`, which takes k ticks. Ticks fall on cycles 5n and a write shows the next cycle, so every edge is exactly 1 cycle after its ideal place (2001 + 50k, 2026 + 50k). The error is fixed and never adds up; it is inside the +-2 limit. An exact 0 offset is not possible with clkdiv 5 because writes always appear at 5n+1.

The startup spends exactly 400 ticks (cycles 0 to 1999) with side 1, then 15 idle slots in a loop and a 16th idle slot, the "pre" slot.

The pre slot is the slot just before each of the chip's frames: the 16th enable slot, the second stop bit of the previous chip frame, or the second idle slot after an answer. In its low half it does `pull`, copies the word to X, shifts out 15 bits to null and bit 15 into Y, and restores the OSR from X (`mov osr, x`, which also resets the shift count). At H0, `jmp !y frame`. If bit 15 is set (end word), the rest of the slot plus 16 idle slots run and the program parks in `jmp done side 1` (P0 high, P1 released, no more changes).

The chip's frame: at H1 of the pre slot `mov crc, null` restarts the CRC register. With `crc_poly=1` and init 0, the CRC rule in isa.md ("if the bit differs from bit 0, shift right and add the polynomial") makes bit 0 the XOR of the bits shifted out, i.e. the even-parity bit. Start bit `set pins 0`, 8 data bits `out pins, 1` with `jmp !osre` (threshold 8), parity `mov pins, crc`, stop 1 `set pins 1`. All P1 writes are at the L0 tick, the same cycle as the falling edge. In stop 1, `mov x, osr` gives the word shifted right by 8, i.e. the answer length. `jmp !x pre` at stop 1's H4 makes stop 2 the next pre slot. Otherwise stop 2 runs, then `set page 1; jmp gentry` (page 1 holds the answer code).

Guard time (128 slots): 8 groups of one outer slot and 15 inner slots. The outer slot does `in null, 1` (the ISR is the outer counter) and `set x, 14`; the inner slot loops on `jmp x--`. The L0 of each outer slot is `jmp !isrf ocont`; after the 8th group the ISR is full, it falls through, and that slot is the ATxmega's first start bit. There `mov isr, null` empties the ISR, `mov x, osr` reloads the answer length (still in the OSR) and `jmp x--` makes it length - 1.

Answer bytes: each data slot samples `in pins, 1` at the H0 tick (rising edge; through the synchroniser it sees the level of 2 cycles earlier, about 18 cycles after the ATxmega changed it). `jmp !isrf` counts 8 bits, `push` in the parity slot sends the byte right-justified. Parity and stop slots are just timed. After stop 2, `jmp x-- rnext` goes to the next byte's start slot; otherwise one idle slot, `set page 0; jmp pre`, and the pre slot is the second idle slot. P1 is never written from the end of a chip frame until the next chip frame.

## pe_sim runs
1. `pe_sim run x.s -help`: printed the flag list (config field names, -mode, -stimulus, -tx, -cycles, -inputs).
2. `pe_sim asm avr_pdi.s` piped to a line count: 114 words, assembled without error.
3. `pe_sim asm avr_pdi.s | head -3` in the same command: first words d097 d10d 1102.
4. `pe_sim asm` again, showing words 59-65 and 113: confirmed page 0 ends at word 60, align nops fill 61-63, `gentry` is word 64.
5. The TASK.md example (words 0x0180 0x00C1 0x0059 0x8000, stimulus from the example). Edges at 2001/2026/..., rx 10250 value 2, last edge 12476 (ideal 12475). Looked right.
6. Same example through my checker `t/check.py` (which builds the words and stimulus itself, and checks every P0 edge against 2000+50k / 2025+50k within +-2, edge count, that P1 changes only in the chip's frame slots and no later than 20 cycles into the slot, P1's level at every rising edge, P2-P7 untouched, and the RX words). Generated stimulus identical to the hand-written one. PASS, max edge offset 1.
7. Random session seed 1 (72 words, 97 answer bytes): PASS, max offset 1. Saw that `rx` values print in decimal.
8. Edge cases: a 15-byte answer of 0xFF, answered instructions back to back, a 5-byte instruction answered, 0xFF/0x00 bytes, last instruction answered (2 + 16 idle): PASS.
9. Random seed 2: PASS.
10. Random seed 3: PASS.
11. Random seed 4: PASS.
12. Single unanswered byte then end: PASS.
13. Single answered byte then end: PASS.

Total: 13 runs of pe_sim (counting each asm call).

## Mistakes found
- While writing, I first gave the end path's H2..H4 delay `set y, 0` (2 ticks) instead of `set y, 1` (3 ticks), and left an unfinished guard section; I caught both by recounting ticks before the first assembly, so no run saw them.
- No bugs were found by the simulator; all runs passed first time.

## Program length
111 instructions (114 words in the image: page 0 holds 61 instructions plus 3 `nop`s from `.align`, page 1 holds 50).

## Confusing or possibly wrong in isa.md
- The CRC polynomial is "written low power first", which is hard to apply to a 1-bit CRC; I relied on the operational rule in the same section (shift right, XOR the polynomial if the bit differs from bit 0), and with poly 1 it gives parity, as the tests confirm.
- `in` "shifts count bits right into the ISR" does not say where the new bits enter or what `mov x, isr` would return; I avoided depending on it (push right-justifies). Likewise it is not said explicitly that `mov x, osr` returns the shifted (remaining) contents; I relied on it and the tests confirm it.
- The assembler's page tracking: the text says it "follows PAGE down the listing", but not explicitly that it tracks `set page` instructions. It accepted `set page, 1; jmp gentry` across pages, so it does. I put `.page 1` after `set page, 0; jmp pre` to be safe; I did not test whether it is needed.
- With `clkdiv` above 1, ticks are at cycles 0, clkdiv, 2*clkdiv..., and writes show one cycle later, so there is a fixed +1 cycle offset that cannot be removed. Not wrong, but worth stating next to `clkdiv`.
- The bit sampler section gives figures for 40 MHz while this task runs at 50 MHz; irrelevant here.
- The input pin default when no `-inputs`/stimulus line covers cycle 0 is not stated; my tests always give `0 FF`.

## Rules
No rule broken that I know of. I read and wrote only inside this folder (plus its `t/` subfolder), and used 13 pe_sim runs.
