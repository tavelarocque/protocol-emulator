# notes.md: MIPI DSI LPDT transmitter

## What I read
- TASK.md, in full (lines 1-120, then 120-238).
- isa.md, in full, in four parts (1-180, 180-360, 360-530, 530-699).
- Nothing outside this folder.

## pe_sim runs
(numbered as they happen)
1. `./pe_sim run x.s -help`: printed the run flags (-config keys, -cycles, -inputs, -mode, -stimulus, -tx). No program was run.
2. and 3. `./pe_sim asm mipi_dsi.s` (I ran it twice in one command by mistake, so this counts as two runs): assembly error, "jump to bg ... in page 3, but PAGE is 0 here". The assembler follows PAGE down the listing; my `bg2:` block came after `set page, 0; jmp pkt`. Fixed with a `.page 3` line.
4. `./pe_sim asm mipi_dsi.s`: assembled, 234 words including the `.align` padding (225 real instructions: 64 + 58 + 61 + 42 in pages 0 to 3).
5. First real run, the two example packets of TASK.md (exit sleep mode, column address set). Timing all inside limits (first change at 6912, LP-11 gap 725), CRC 0x0348 correct, but the ECC was 0x2F in both packets where 0x36 was expected (P0, P3, P4 wrong). Cause, found by modelling my own program in Python: the dispatcher's `out null, 4` and `out x, 3` (reading the round number from the pins) ran after `mov crc, null` and so fed two extra bits into the fresh CRC register. The errors then spread through the rounds that reuse earlier parity bits, which explains exactly which three bits were wrong. Fix: restart the CRC register after those OUTs, in the dispatcher, instead of at the end of the extraction.
6. Same two packets: all bytes, ECCs and checksums right, every state 3 to 50 cycles, first change at 6931, LP-11 gap 702 cycles.
7. Six random short packets: all OK. First change 6927, LP-11 gaps 701 to 713.
8. Six long packets with WC = 26 (the maximum, 32 bytes each): all OK, gaps 693 to 717.
9. Edge cases: short 0xFF 0xFF 0xFF, long WC = 0 with DI 0xFF, long 26 x 0xFF, short all zero, long DI 0xC0 with 26 zeros, short 0xFF 0x00 0xFF: all OK, gaps 672 to 721.
10. to 12. Three random mixes (2, 2 and 5 packets, short and long): all OK, gaps 693 to 722.
13. A single long packet with WC = 0: OK.

How runs 5 to 13 were checked: a Python script (my own, in a scratch subfolder, deleted at the end) wrote the TX words, ran `./pe_sim run mipi_dsi.s -tx FILE -cycles N` plus run_args.txt with N from the TASK.md formula, and decoded the `pins` lines the way TASK.md describes the receiver: P2 and P3 high at every event; only one of P0/P1 changes per change; escape entry 10 00 01 00; entry command 1,1,1,0,0,0,0,1; spaced-one-hot bits; exit 10 then 11; every state of a transmission 3 to 50 cycles; first change in [5000, 10000]; every LP-11 gap 3 to 1000; nothing after the last transmission; and every byte against bytes computed independently in Python (ECC from the parity table, CRC-16 0x8408 from 0xFFFF; the Python reference reproduces 0x6F91 for "123456789", 0x0348 for the example payload and ECC 0x36 for both example headers).

Total: 13 pe_sim runs (3 of them assembler or help only).

## Design

Configuration (run_args.txt): set_base=0, set_count=2 (P0 = Dp, P1 = Dn of data lane 0, so `set pins, v` writes the lane state: 3 = LP-11, 1 = LP-10, 2 = LP-01, 0 = LP-00); out_base=4, out_count=3 (scratch pins P4..P6, which the test ignores); threshold=8; in_msb_first=1; crc_poly=0x8408, crc_init=0xFFFF; P0..P6 push-pull. The clock lane pins P2, P3 are never written, so they stay at their reset level 1 (LP-11) for the whole run.

Start: a nested delay loop of about 6200 cycles in LP-11, then the packet loop. The first change comes at about cycle 6700 to 6930 (the ECC work of the first packet follows the delay).

Per packet: pull word 1 into the ISR, pull word 2 into Y, compute the ECC (below), transmit, return to LP-11, loop. When the host has no more words the `pull` stalls with the lane in LP-11.

The ECC. The chip has no XOR, but the CRC register is an XOR engine: each OUT feeds it one bit, and because the polynomial 0x8408 has an odd number of terms, the parity of the 16-bit register flips exactly when the fed bit is 1 (parity(R') = parity(R) xor b; the register's high half stays 0). The start value 0xFFFF has even parity. So the parity of the register equals the XOR of every bit fed since the last restart, wherever and in whatever order they were fed. One parity bit P_j is then: restart the register, feed exactly the header bits of P_j's row, read the register, take its parity. Feeding a selected set of bits from a word costs one instruction per bit, `out null, g`, which feeds the bit under the OSR's position 0 and skips g bits to the next wanted one; runs of 5 or more bits use a two-instruction loop. Two refinements, found with a small search in Python: (a) a round may also feed parity bits computed in earlier rounds (they sit in the ISR below word 1), so it feeds the symmetric difference of rows when that is shorter; P0, for example, is P1 xor ... xor P5 xor all 24 header bits, because every column of the ECC table has odd weight; (b) when a load's position 0 is a bit the round does not want (it is always fed by the first OUT), it is fed twice, which cancels. Rounds run in the order P5, P4, ..., P0; each result is shifted into the ISR with `in x, 1` (left shift, new bit at the bottom), so at the end the ISR holds word1 << 6 | ECC, with P0 at bit 0 and the long-packet flag at bit 14.

The parity of the register is taken by a shared 11-instruction loop that shifts the register value out of the OSR one bit at a time and keeps even/odd in the program counter, stopping as soon as the rest of the OSR is 0. Since there is no call/return, each round writes its number to P4..P6 (`set x, r; mov pins, x`) and a dispatcher after the parity loop reads it back (`mov osr, pins; out null, 4; out x, 3`) and jumps to the next round with a chain of `jmp !x` / `jmp x--`. After round 5 it goes to the transmitter.

Transmission (all byte sends use one 7-instruction bit loop, copied per phase: `out x, 1`; Mark-1 `set pins, 1 [4]` or Mark-0 `set pins, 2 [5]`; space `set pins, 0 [2]`; `jmp !osre`): marks last 6 cycles and spaces 6 cycles inside a byte, a little longer between phases (all observed states are 3 to 50 cycles). Escape entry plus the first six command bits are one byte, 29 = bits 1,0,1,1,1,0,0,0 (escape entry LP-10, LP-00, LP-01, LP-00 is exactly a 1 then a 0 in spaced-one-hot code), the last two command bits (0, 1) are four explicit `set` instructions. Then DI (ISR >> 6), word 2 low and high byte (from Y; the second half after `mov osr, osr` resets the shift count), the ECC byte (`out x, 6` from the ISR into X, then `mov osr, x`, so bits 6 and 7 are 0), then the flag (ISR bit 14). Short: exit. Long: `mov crc, null`, then WC times `pull` and 8 bits (each `out x, 1` feeds the CRC register with exactly the payload bits, LSB first), then `mov osr, crc` and its two bytes. Exit: `set pins, 1 [4]` (Mark-1), `set pins, 3` (Stop), back to the packet loop. Between two transmissions the lane is in LP-11 about 670 to 725 cycles (mostly the ECC rounds), under the 1000 maximum.

Pages: the program is longer than 64 words, so it is laid out in four pages with `.align`, `.page` and `set page, n` before every jump into another page: page 0 start, packet entry, rounds P5, P4, P0 and the parity loop; page 1 the dispatcher, three trampolines and rounds P3, P2; page 2 round P1 and the transmitter up to word 2; page 3 the ECC byte, payload, checksum and exit.

## Program length

225 instructions (234 words as assembled, including 9 `nop` words of `.align` padding at the ends of pages 0, 1 and 2).

## Mistakes
- Ran the assembler twice in one shell command (runs 2 and 3); harmless, but it used a run.
- The CRC restart placed before the dispatcher's two OUTs (run 5); described above.

## About isa.md: what was confusing or may be wrong
- The CRC register takes a bit from every OUT, including OUTs that only move data around (here, picking the round number out of a copy of the pins). isa.md says so ("one bit from every OUT the thread executes"), so it is not wrong, but it is an easy trap: nothing in the instruction text shows that `out null, 4` touches the CRC. It cost me one run.
- isa.md does not say whether `out pins, n` writes n pins or out_count pins (`mov pins` is stated to write out_count pins). I avoided `out pins`.
- `mov osr, osr` (re-reading the shifted OSR to reset its count) is not described as a case, but follows from the `mov` rules; it worked as expected.
- Falling from one page into the next does not change PAGE, so any jump after a fall-through goes back to the old page; together with the assembler tracking PAGE down the listing (not the flow), a program over 64 words needs careful `.page` lines. The error message was clear. When it reported the error, the assembler also printed an internal stack trace naming source files elsewhere in a repository; I did not look for them.
- isa.md says "`jmp` ... `addr` is 6 bits, a place within a page" while the encoding table gives `[5:0]` addr and `[8:6]` cond, consistent; I found nothing that I believe is wrong in isa.md for what this program uses.

## Rules
I read and wrote only inside this folder (my scratch scripts lived in a `work/` subfolder of it and were deleted before hand-in). 13 pe_sim runs. No em-dashes used.
