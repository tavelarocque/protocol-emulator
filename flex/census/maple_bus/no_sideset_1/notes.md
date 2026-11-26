# Notes: Maple bus transmitter

## What I read

- `TASK.md`, in full (187 lines).
- `isa.md`, in full, in three parts (lines 1 to 200, 200 to 409, 410 to 607).
- The output of `./pe_sim run x.s -help` (run 1).

Nothing outside this folder was opened, listed or searched. No rule was broken as far as I know.

## Design

P0 is SDCKA (A), P1 is SDCKB (B). All pin writes are `set pins, k` with `set_base=0`, `set_count=2`, so k = A + 2B. No side-set is used.

The key observation is that the state between bits is always known except for one line, and that line is never needed. After an even bit (clocked by A), A is low and B holds the bit; after an odd bit (clocked by B), B is low and A holds the bit. So the even-bit steps are always the writes 1 (A high, B low), then 1 + 2v (B to the value), then 2v (A falls); the odd-bit steps are 2 (B high, A low), then 2 + v, then v. Every write is an immediate chosen by branching on the bit, which `out x, 1` takes from the OSR. A write that finds the line already there makes no change, as the protocol wants. Bit 0 is the exception (both lines high after the start pattern), so the program enters bit 0 just after the even step 1.

Every word (header word 0, header word 1, the data words) is 16 bits and starts on an even frame bit, so the bit loop is one even bit plus one odd bit, repeated while `!osre` holds (threshold 16, `out_msb_first`). After each word a dispatcher does `jmp y-- next_word` (pull, back into the loop). Y is the number of words still to pull in the frame, 2N + 1, computed with the ISR (default right shift, new bits entering at the top): `in` a 1 bit, `out y, 8` for N, `in y, 8`, `in null, 7` gives 2N + 1.

Checksum: there is no XOR instruction, so the CRC register does it. With `crc_poly=0x80` and `crc_init=0`, each OUT bit is XORed with bit 0 and the register rotates right within 8 bits, so after whole bytes bit k holds the parity of the stream bits at position k mod 8, which is the XOR checksum bit-reversed (bit 0 holds the parity of the MSBs). The OUT used to extract N also feeds the CRC, so `mov crc, null` restarts it after that. At the end of the data, `mov osr, crc`, `out null, 8`, then 8 rounds of `out y, 1` / `in y, 1` reverse the bits into ISR[15:8] (OUT takes from the top, IN enters at the top while shifting right). `in null, 8`, `mov osr, isr`, `out null, 8` leave the checksum at the top of the OSR with 8 bits left, and it goes through the same bit loop.

To tell "data done" from "checksum done" at the dispatcher (Y is 0 in both cases, and `jmp y--` decrements even when it does not jump, so a counter cannot serve), I use the ISR count as a flag: `mov isr, null` makes it 0 (not full) for header and data, and the checksum preparation shifts in exactly 16 bits, so it is full. `jmp !isrf cks` sends the checksum; otherwise the end pattern follows.

Timing: every pin write is at least 12 cycles after the previous write (delays chosen per path), so any two changes are at least 12 cycles apart, which covers both the 7 and the 12 cycle limits. The longest in-frame gap is at the checksum preparation: 71 cycles worst case (computed by hand and measured). After the end pattern a 128-cycle loop plus the next frame's setup gives an idle of 143 cycles between frames. The first change is at cycle 13. When the words run out, `pull` stalls with both lines high.

`run_args.txt`: `-config set_base=0,set_count=2,threshold=16,out_msb_first=1,crc_poly=0x80 -mode 0=pp -mode 1=pp`.

## pe_sim runs (18 in total)

1. `pe_sim run x.s -help`: list of flags and config field names (it also lists `sideset_base` and `sideset_count`, see below).
2. `pe_sim asm maple_bus.s`: assembled, 63 words.
3. Run of the TASK example (words 0x0000, 0x2001). I wrote a checker script in this folder that builds the expected change list from the words (it reproduces the 98-change table in TASK.md exactly, checked without the simulator) and checks order and every timing limit. Result: 98 changes, all match, first change cycle 13, max in-frame gap 71, PASS.
4. Second TASK example (0x0100, 0x0109, 0xDEAD, 0xBEEF): 162 changes, checksum 0x2B, PASS.
5. 4 frames, N = 255, 0, 3, 1, random bytes: 16966 changes, idle gaps 143, PASS, no change after the last frame.
6. 4 frames, N = 2 (all 0xFF), 1 (all 0x00), 255 (all 0xFF), 7: PASS, max gap 71.
7. 4 frames all N = 0: PASS.
8. 4 frames N = 128, 64, 5, 255: 29316 changes, PASS.
9 to 18. Ten random runs of 1 to 4 frames, N drawn from {0, 1, 2, 3, 17, random 0..255}, random bytes: all PASS, max in-frame gap 46 to 71.

The program worked on the first run; no bugs were found. Afterwards I deleted the checker and the test word and output files so that the folder holds only what TASK.md asks for.

## Program length

63 instructions (one 64-word page).

## Confusing or possibly wrong in isa.md

- `pe_sim run -help` lists `sideset_base` and `sideset_count` as config fields, but isa.md never mentions side-set, and the encoding table has no field for it. I did not use them.
- For the default IN direction isa.md says the bits are "shifted right into the ISR" and "least significant bit first", but only says where new bits enter for `in_msb_first` (the bottom). I assumed the default puts them at the top (bit 15), as PIO does; the passing runs confirm it.
- `threshold` is shared by the OSR and the ISR, and isa.md does not say what the ISR count does at or past the threshold without autopush. I relied on it reading as full at exactly 16; it worked.
- "Polynomial written low power first" is phrased for real CRCs; for this use the value is simply the mask XORed in after the right shift (0x80 here). Worth one sentence in the doc.
- Every OUT feeds the CRC, including `out null` and `out y`; that is stated, but it is easy to miss that an OUT used only to extract a field corrupts the CRC.
- `jmp x--`/`y--` decrement even when not taken, so a counter that ends a loop wraps to 0xFFFF and cannot also serve as a later flag; that is as documented, but it cost a flag (the ISR count).
- The bit sampler section reasons at 40 MHz while elsewhere the core runs at 50 MHz; not relevant here.
