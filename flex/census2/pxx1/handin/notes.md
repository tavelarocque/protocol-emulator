# Notes: PXX1 transmitter on the protocol emulator

## Result in one paragraph

`pxx1.s` with `run_args.txt` produces correct PXX1 line coding, header, field packing, bit stuffing, closing flag, frame period and idle behaviour, checked by pe_sim against my own decoder. **The CRC is not computed.** The program sends 16 zero bits in the CRC position, so every frame carries a wrong CRC unless the true CRC happens to be 0x0000 (for example all-zero data). A real module will reject those frames. I could not find a way to compute FrSky's CRC on this chip within its registers and program memory. The reasons are below.

## What I read
- TASK.md, in full (in two parts).
- isa.md, in full (in parts). I read it once before a context reset and again afterwards.
- The `./pe_sim run x -help` output (pe_sim run 1).
- Nothing outside this folder.

## pe_sim runs (4 in total)
1. `./pe_sim run x -help`: printed the run flags (config fields, -cycles, -inputs, -mode, -stimulus, -tx).
2. `run pxx1.s -tx ex2.txt -cycles 1500000` + run_args. This was the two worked-example frames from TASK.md. Output had 647 lines and was identical, line for line, to my Python model of the chip (`model.py`). That confirmed the model's timeout timing and the assembler syntax I used (`wait 0 pin 0 timeout`, `in y, 16`, `mov isr, isr`, numeric jump targets, `.page`, `.align`). My decoder (`check.py`) read both frames, with:
   - header and closing correct,
   - the 16 bytes correct,
   - every low pulse 400 cycles and every bit 800 or 1200 cycles,
   - first edge at cycle 277,876 and period 414,300.
   The only errors were the CRC values (0x0000 sent; 0x21A3 and 0xFF54 expected).
3. `run pxx1.s -tx t4.txt -cycles 2500000`. Four frames: random fields, all ones (0xFFFF, 0xFFFF, 0x0FFF ...), all zeros, and alternating bits. Output was identical to the model (1331 lines). All frames decoded correctly except the CRC; the all-zero frame's true CRC is 0x0000, so that frame was fully correct. The all-ones frame has 185 bits on the line (25 stuffed zeros).
4. `run pxx1.s -tx t1.txt -cycles 1000000`. One random frame. Output was identical to the model, decoded correctly, with only the CRC wrong.

Besides these runs, I ran the model on 40 random runs of 1 to 4 frames, mixing random, all-ones, all-zeros and alternating frames (`rtest.py`). None showed timing, stuffing, header, closing or byte errors. Model periods: 410,300 cycles (shortest possible frame) to 481,500 (longest possible with a zero CRC field). The first edge is at cycle 277,876.

## Design
The thread runs with `clkdiv=25`, so one tick is 0.5 us. A low pulse is 16 ticks, a 0 bit is 32 ticks and a 1 bit is 48 ticks, all exact. The line is P0 (push-pull). Every edge is either a `set pins` or the single `out pins, 1` that decides a bit.

The bit loop uses the line itself as the branch condition. At tick 32 of each bit, `out pins, 1` writes the data bit to P0:
- **A 0** is the next bit's falling edge. The `wait 0 pin 0 timeout` that follows passes at once.
- **A 1** leaves P0 high. The wait (timeout 14) then jumps to the timeout vector at tick 48, which pulls P0 low.

This needs no register for the bit value. X counts the 1s still allowed (5 after any 0). The vector's `jmp x--` decrements it. When X reaches 0, the next bit is sent as a stuffed 0 without consuming data, and X is set back to 5.

The OSR holds the current chunk, sent MSB first, with threshold 16. Chunks shorter than 16 bits are pre-shifted (`out null, 8` or `out null, 12`) so that `!osre` goes false exactly at the chunk's end. At tick 3 of every bit, `jmp !osre` either continues or falls into a loader for the next chunk. The loader has ticks 4 to 28 and places the rise at tick 16 itself.

**Paging.** Loaders differ, and there is no call or return, so the same 11-word bit loop is copied at offsets 0 to 10 of all four pages. Jumps into the loop use numeric offsets (`jmp 5`, `jmp 10`), so they land in whichever page PAGE selects. The timeout vector is a full address, and its `jmp x-- 10` returns to the current page's copy. Each page's loader is a two-way branch on `!isrf`, the ISR's shift count, which the previous loader leaves either below 16 (`mov isr, isr` resets it) or at 16. That gives eight loader slots: one per chunk end.

**Chunks.** The header and the closing 0x7E are straight-line code with a Y loop, outside the stuffing logic. The data chunks are:
- word 0 byte-swapped (16 bits),
- flag 2 (8),
- for each channel pair:
  - a & 0xFF (8),
  - b & 0xF (4),
  - a >> 8 (4),
  - b >> 4 (8),
- extra flags (8),
- CRC (16, zeros).

**ISR as storage.** From word 1 onwards the ISR holds [extra flags | pair counter | a >> 8] as three fields. It is only ever rotated with `mov y, isr; in y, k`, or has a nibble inserted at the top, so nothing is lost. The pair counter starts at 3 and is decremented after each pair's last chunk. Y is the scratch register, and it carries b >> 4 across two chunks.

**Idle and start.** After the closing flag the line stays high. A nested X/Y loop then waits (about 277,000 cycles in all, counting the start of the next frame) before `pull` fetches the next word 0. When the words run out, `pull` blocks with the line high. The program starts in that idle loop, so the first edge comes at cycle 277,876.

**Program length.** 157 instructions. With `.align` padding the image spans addresses 0 to 237: page 0 holds 28 words, page 1 holds 59, page 2 holds 24 and page 3 holds 46.

## Why there is no CRC
FrSky's CRC is `crc = (crc << 8) ^ T[(crc >> 8) ^ byte]`, where T is the reflected 0x8408 table. In polynomial form, with Q = x^16 + x^11 + x^4 + 1:
- T[v] = v·x^-8 mod Q,
- one byte step is crc' = L·x^8 + (H ^ b)·x^-8, where H and L are the CRC's high and low bytes.

The chip's CRC register, with `crc_poly=0x8408`, multiplies its state by x^-1 per fed bit. It therefore computes the byte step exactly if, before the byte is fed LSB first, the 32-bit register holds L in bits 16 to 23 and H in bits 0 to 7.

The problem is reloading that layout after each byte. The register cannot be loaded. Writing it restarts it from `crc_init`, and fed bits can only reach the low half with this polynomial. Reading it freezes it.

What I established:
- **The per-byte map has rank 15** (minimal polynomial x^3(x^13+1)), so no single LFSR with any 32-bit polynomial and any fixed feeding pattern reproduces it. The linear complexity of the per-bit contribution sequences is about 64. Exhaustive searches over polynomials and feeding schedules found nothing; these were `srch.c`, `s2.c` to `s4.c`, `lin.py`, `rb.py`, `st.py`, `rep.py` and `up.c`.
- **A per-byte read-and-rebuild does work mathematically**, but the rebuild needs the previous CRC's bytes fed several times: three blocks for L, three for H, then the data byte. That uses minimum-weight multiples of Q; for example, x^-10 + x^-24 + x^-32 ≡ 1. It also needs a 16-bit backup copy of the read value, a rotation temporary and the data byte, all at once, besides the stuffing counter, the extra-flags byte and the pending channel nibble. It needs on the order of 150 to 250 instruction ticks per byte in one block.
- **The transmitter already uses every register.** X is the stuffing counter, Y is the scratch register, the ISR holds the extra flags, pair counter and nibble, and the OSR holds the chunk. At `clkdiv=25` there is no time window that long, and the bit loop cannot be interleaved with a session that is not uniform per bit.
- **The ISA has no XOR, no way to load the CRC register, and no way to read it without freezing it**, so a software CRC has the same register problem.

I judged that a correct transmitter with a known-wrong CRC was the best I could hand in, rather than an unfinished attempt that might break the timing.

## Mistakes and dead ends, and how I found them
- Early in the CRC analysis I computed the modulus as 0x10911. Checking it against all 256 table values showed the correct value is 0x10811.
- Several transmitter designs ran out of registers on paper before I wrote any code. The extra-flags byte has to survive 13 bytes, and the a >> 8 nibble has to survive one byte. The page-copied loop with the pin-branch freed Y and solved this.
- No mistakes showed up in pe_sim runs. The model was written first, and pe_sim's output matched it exactly on all three program runs.

## Files
- **Hand-in:** `pxx1.s`, `run_args.txt`, `notes.md`.
- **Model and checks:** `model.py` (my model of the chip), `check.py` (decoder and checker), `ref.py` (reference CRC and packing; it reproduces both worked examples), `cmp.py`, `rtest.py` and `per.py` (test drivers).
- **Inputs and outputs of the pe_sim runs:** `ex2.txt`, `t4.txt`, `t1.txt` and their `out*.txt`.
- **CRC analysis:** `ana*.py`, `c13.py`, `lin.py`, `search.py`, `rb.py`, `st.py`, `sp.py`, `rep.py`, `*.c`, `tgt.h`. I deleted their compiled binaries.

## Things in isa.md that were confusing or that I think are wrong or missing
- **Wait timeout timing.** The text says a wait "stalls for T cycles at most, and if the pin is still wrong, jumps on the cycle after". Measured (run 2): the vector instruction executes T+1 ticks after the tick in which the wait first executes. Saying so explicitly would help.
- **`mov isr, isr` and `mov osr, osr`** are not mentioned. They are useful: they reset the shift count and keep the contents, and pe_sim accepts them and behaves that way.
- **Assembler page tracking.** The text says the assembler "follows PAGE down the listing", but not whether a `set page` instruction changes what it assumes for the following lines. I avoided the question with numeric jump targets and `.page` lines.
- **The CRC register** can be restarted and read, but never loaded, and a read freezes it. That rules out any CRC that is not a plain LFSR over the data bits, such as FrSky's. The register also takes a bit from every OUT, so a program using OUT for other data must use `crc_in` or ignore it. A "load" or "unfreeze" would make it far more general.
- **There is no XOR** or other bitwise combine except through the CRC register. Together with four registers, that makes per-byte table CRCs impractical.
- **Register pressure in general.** isa.md's own v2.3 note says stuff-bit handling needs two more registers than a thread has, and that was my experience. PXX1 also needs one byte held for the whole frame.
- **Threshold.** isa.md says the threshold is 1 to 16; 16 works.

## Rules
I worked only inside this folder, used 4 pe_sim runs, and used no em-dashes. I know of no rule broken.
