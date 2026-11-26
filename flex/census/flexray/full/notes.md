# Notes: FlexRay transmitter on the protocol emulator

## What I read

- `TASK.md`, in full.
- `isa.md`, in full (v2.3).
- `./pe_sim run x.s -help` output (the flag list).
- Nothing outside this folder. One accident to report: my very first shell command (`ls -la && cat TASK.md && cat isa.md`) produced more output than the tool shows, and the tool harness saved that output to a file outside this folder. I did not open that file; I read `TASK.md` and `isa.md` again directly from this folder instead. The `ls -la` listing also showed the `..` entry of the parent directory, which I did not follow.

## Design

Config (`run_args.txt`): `start=43, threshold=8, out_msb_first=1`, IN left at its default (shifts right, new bits enter at the top), `crc_poly=0xD3B6BA` (0x5D6DCB bit-reversed over 24 bits), `crc_init=0x5D3B7F` (0xFEDCBA bit-reversed), pin 0 push-pull. Constants passed in decimal because the help text did not say whether `-config` accepts hex.

Timing. A bit is 5 cycles. Every byte is BSS high, BSS low, 8 data bits. Data bits use a 2-instruction loop, `out pins,1 [3]` then `jmp !osre`, which is exactly 5 cycles per bit and ends after 8 bits because the threshold is 8. The loop's fall-through lands exactly on the next bit time, so the instruction after every byte loop is the next BSS high (or FES low). The 4 + 4 spare cycles of the two BSS bits are where all bookkeeping happens (pulls, building header pieces, dispatch). Every pin write is placed by counting cycles, so edges sit exactly at 5k cycles after the FSS edge with no drift (measured error 0 on every edge).

CRC. The hardware CRC register shifts right and compares with bit 0, so it computes the reflected form: with the polynomial and initial value bit-reversed over 24 bits, its register R is the FlexRay CRC C bit-reversed (checked in Python against the example, 0xFB7B75). It takes one bit from every OUT, so inside a frame the only OUT instructions are the 40 header bits and the payload bits (`out pins, 1`); everything else (shuffling, alignment) is done with IN, MOV and SET, which the CRC ignores. `mov crc, null` restarts it before each frame. Because C sent MSB first is R sent LSB first, the CRC bytes are sent from the ISR with `mov pins, isr` (P0 = ISR bit 0) then `in null, 1` (shift right), 3 instructions per bit. The first `mov isr, crc` gives R[15:0] (CRC bytes 0 and 1), a second read gives R[23:16] (byte 2).

Header. Word 0 is exactly header bits 39..24, so it goes out as a normal 16-bit word. Header bits 23..0 are L (7), header CRC w2 (11), cycle count w3 (6), which do not fall on byte boundaries. With a right-shifting ISR, `in r, n` puts r's low n bits at the top of the ISR, which is what an MSB-first OSR wants, so pieces are glued in the ISR and moved to the OSR:
- byte 2 setup: `in x,11` (w2) then `in y,7` (L) gives A = L<<9 | w2>>2 = header bytes 2 and 3.
- byte 3 setup: builds Y' = L<<9 | w2[1:0] (to free a register).
- byte 4 setup: pull w3, `in x,6` (w3) then `in y,2` (w2[1:0]) gives header byte 4 at the top; then L is recovered from Y' (`mov isr,y; in null,9; mov y,isr`) as the payload word counter.
The register pressure is the hard part: OSR is the only way in from the FIFO, IN can only read X and Y, and OSR shifting by OUT would corrupt the CRC, so composing everything before the frame was not possible (it needs five registers at once).

Sharing code. One "word" path (first byte loop `p0`, middle BSS with `mov osr, osr`, second byte loop `h4`) is used for header word 0 and every payload word; header byte 4 also uses `h4`. After `h4`, `next` writes BSS high (the next byte is always a header, payload or CRC byte, all starting with BSS high) and dispatches: `jmp !isrf hdr2` (ISR count is 0 only right after word 0, since the frame start does `mov isr, null`, and 9 after the header) then `jmp y-- pay`, else CRC. The three CRC bytes share one bit loop with a Y counter (2, 1, 0) choosing between "continue the first read" and "second read", and FES after the last.

Idle and TSS. FES high `[15]`, then `pull [15]`, `mov isr, null [15]`, `mov crc, null [15]` give 64 cycles between the FES rising edge and the next TSS (limit 60). The TSS is one `set pins, 0 [15]`, 16 cycles (allowed 15 to 75). When the words run out the thread stalls in `pull` with P0 high. The first TSS starts at cycle 49.

Program length: **64 instructions**, exactly one page, so no PAGE handling is needed.

## pe_sim runs (13 in total)

1. `run x.s -help`: printed the flag list (config field names, -mode, -tx, -cycles).
2. `asm flexray.s`: assembled, 64 words.
3. `asm flexray.s`: looked at word 43 (0x9F00 = `pull [15]`) to confirm `start=43` is the frame label.
4. Run of the TASK.md example (2 frames) through my checker: my checker reported a mismatch, but the bug was in the checker (it compared the FSS edge against the first expected edge after it). The simulator output itself was right.
5. Same example after fixing the checker: PASS, every edge exact, CRCs 0xFB7B75 and 0xE35697, 47 edges in frame 0 as listed in TASK.md. (I meant to reuse the saved output from run 4 but reran the simulator; one wasted run.)
6. Random, 5 frames, L up to 127 (115, 29, 76, 3, 42): PASS, max edge error 0.
7. Random, 5 frames, L 0 to 2: PASS.
8. Random, 5 frames, L up to 127: PASS.
9. One frame with L = 0: PASS.
10. Extremes, 5 frames: all indicators 1, ID 2047, header CRC 0x7FF, cycle 63, 127 words of 0xFFFF; all fields 0 with 127 words of 0x0000; the two all-ones / all-zeros headers with L = 0; alternating 0xAAAA/0x5555 with L = 127: PASS.
11. Random, 3 frames: PASS.
12. Random, 4 frames, L up to 10: PASS.
13. Random, 2 frames: PASS.

My checker (a Python script in this folder during testing, deleted before hand-in) built the TX words, ran `pe_sim run flexray.s -tx FILE -cycles N` plus `run_args.txt` with N from TASK.md, computed the expected line from an independent FlexRay CRC, and checked: P0 high until the first TSS (before cycle 10000), TSS length 15 to 75, every edge within 1 cycle of 5k after the FSS edge with the right level, idle gap 60 to 10000 cycles, no extra edges and P0 high at the end. On every run every edge was exactly on time.

## Mistakes

- The checker indexing bug in run 4 (described above).
- Rerunning the simulator in run 5 instead of reusing the saved output.
- Early in the design I counted 79 instructions for a straight-line version; getting to one page needed the shared word path, the `!isrf` dispatch, the shared CRC loop and placing the frame start so the FES falls into it.

## What was confusing or possibly wrong in isa.md

- `in` without `in_msb_first`: it says the ISR "shifts right", but not where the new bits enter. I assumed at bit 15 (PIO style, so `in r, n` top-aligns r's low n bits); the simulator agreed. It also says `push` sends the bits "right-justified", which for a right-shifting ISR means push and `mov x, isr` behave differently for a partly filled ISR; this is not said.
- Whether the shift counts saturate or wrap is not stated. I avoided depending on it (the dispatch only relies on a count of 0 or 9 straight after a reset).
- CRC register: "written low power first" for a 24-bit CRC is ambiguous (low power at bit 0 or at bit 23?). It works as: bit (23 - k) holds the coefficient of x^k, that is the normal polynomial bit-reversed over the CRC's width, and the same for `crc_init`. An example for a CRC narrower than 32 bits with a nonzero init would help.
- After a `mov` read the CRC "stops following the data"; it is not said explicitly that writing `crc` makes it follow again. It does (every frame's CRC was right).
- What a third read of `crc` returns is not specified.
- "The CRC register takes one bit from every OUT" includes `out null` and `out x`; this is the reason header alignment cannot use OUT inside a frame. Worth a sentence, since it is the main trap for MSB-first protocols with a CRC.
- The CRC is reflected (it shifts right), so any MSB-first CRC (FlexRay, CAN) comes out bit-reversed and has to be sent LSB first from the ISR. isa.md mentions CAN works "with the bytes shifted most significant bit first" but does not say how the result is sent.
- Help text does not say whether `-config` values may be hex, so I used decimal.
- Not wrong, just tight: there is no way to read the OSR into the ISR by IN, and IN only reads X and Y, so building 40 header bits from four words needs careful register juggling.
