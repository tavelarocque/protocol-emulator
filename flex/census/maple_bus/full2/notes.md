# Notes: Maple bus transmitter

## What I read

- `TASK.md`, all 187 lines, in one read.
- `isa.md`, all 644 lines, in three reads (lines 1-219, 220-439, 440-644).
- `./pe_sim run x.s -help` output (run 1 below).
- Nothing else. I ran `ls` and `file` on the folder itself. The `file` output named the
  system's dynamic loader path; I did not follow it. I ran my own Python helper scripts
  with the system `python3 -I`; they only read and write files in this folder.

## Design

Config: `set_base=0, set_count=2` (so `set pins, v` writes A = bit 0, B = bit 1),
`out_base=0, out_count=2` (for `mov pins, x`), `out_msb_first=1`, `threshold=16`,
`crc_poly=0x80`, `crc_init` 0. P0 and P1 push-pull.

**Bit coding.** Writing out the three steps for both kinds of bit shows that every step's
target levels depend only on the current bit, never on the previous one:

- even bit (A clocks, B data): step 1 `A=1,B=0`, step 2 `A=1,B=v`, step 3 `A=0,B=v`
- odd bit (B clocks, A data): step 1 `A=0,B=1`, step 2 `A=v,B=1`, step 3 `A=v,B=0`

So each step is one `set pins` with a constant, chosen by branching on the bit
(`out x, 1` then `jmp !x`). Odd step 3 is `mov pins, x` (x is 0 or 1, so A=v, B=0). Odd
step 2 is skipped for a 0 (no change). Even step 2 is always written because bit 0 of a
frame starts with B high (after the start pattern), where it is a real change for a 0.
Since every frame has a whole number of 16-bit units, the bit after an odd bit is always
an even bit, or the end pattern, whose first step "A goes high if low" is exactly an even
step 1. So even step 1 is done right after each odd bit, before any loop decision.

The changes alternate between lines, so I made every gap between consecutive pin writes at
least 8 cycles, and the one place two consecutive writes hit the same line (odd step 1 then
odd step 3 when the bit is 0) 13 cycles. Start and end pattern writes are 12 to 13 cycles
apart.

**Checksum.** The ISA has no XOR or shift on X/Y, so I used the CRC register. With
`crc_poly=0x80` and init 0, the rule "if the bit differs from bit 0, shift right and add
the polynomial, else shift" is an 8-bit ring: the new bit 7 is the input bit XOR the bit
that entered 8 bits earlier. Every `out x, 1` feeds it the bit sent. After the frame its
low byte is the checksum with the first-sent bit (checksum bit 7) at bit 0, so it is
bit-reversed. `mov osr, crc` reads it (and freezes the ring), then 8 rounds of
`out x,1 / in x,1` reverse it through the ISR (default shift right, new bits enter at
bit 15), `in null, 8` moves it to the low byte, and `mov osr, isr; out null, 8` leaves
exactly the 8 checksum bits in the OSR, MSB first, ending when the OSR count reaches 16.
`out y, 8` in the frame setup also feeds the ring, so `mov crc, null` restarts it after.

**Word and frame control.** Y = N (from `pull; mov x, osr; out y, 8; mov osr, x`). Words
go in pairs: (word 0, word 1), then N pairs of data words. The bit loop runs until
`!osre` fails (16 bits). A flag in the ISR says which boundary this is: ISR not full and
value 0 = end of the first word of a pair (then `in null, 16`, `pull`); ISR full = end
of the second (then `mov isr, null` and `jmp y--` to pull the next pair, or fall into the
checksum); ISR not full and value 1 (set by the checksum preparation) = end of the
checksum, go to the end pattern. After the end pattern a 128-cycle wait then `jmp frame`,
whose `pull` blocks with both lines high when the words run out.

Program length: **55 instructions** (one page, no page handling needed).

Timing measured (all runs): minimum gap between changes 8 cycles, maximum in-frame gap
59 cycles (at the checksum preparation), first change at cycle 7, idle between frames
152 cycles.

## pe_sim runs

1. `pe_sim run x.s -help`: listed the flags and the config field names.
2. `pe_sim asm maple_bus.s`: assembled, printed the tail of the listing.
3. `pe_sim asm maple_bus.s` again in the same shell command (my mistake: I counted lines
   with a second call instead of reusing the first). 55 words.
4. Example frame (words 0x0000, 0x2001): 98 changes, exactly the table in TASK.md
   (my checker `check.py` builds the expected sequence from the words; I separately
   confirmed its model reproduces the TASK.md table change for change). OK.
5. Four random frames, N = 1, 3, 0, 7: 1096 changes, sequence and all timing limits OK.
6. TASK.md's second example (0x0100, 0x0109, 0xDEAD, 0xBEEF, checksum 0x2B): 162 changes,
   OK.
7. Frames N=255 random, N=0 all-zero bytes, N=5 all 0xFF, N=255 all zero data: 33348
   changes, OK (400750 cycles).
8. 63 frames (mostly N 0 to 3, several large ones up to 255, plus 0xFF, 0xAA and 0x55
   fills): 85012 changes, OK, and no change after the last frame up to 6,000,000 cycles.

8 runs in total. No program changes were needed after the first version.

Helper files left in the folder: `check.py` (expected-sequence and timing checker) and
`gen.py` (test word generator). Test inputs and outputs were deleted.

## Mistakes

- Run 3 was a wasted duplicate `asm` call.
- No rule was broken that I know of.

## Confusing or possibly wrong in isa.md

- `in` without `in_msb_first`: "shifts count bits right into the ISR" does not say
  where the new bits enter in a 16-bit register (bit 15, or bit `threshold - 1`?). I
  assumed bit 15 and used threshold 16 so both readings agree; the correct checksums
  confirm it.
- What `in` does when the ISR count is already at the threshold without autopush is not
  stated. I avoided relying on it.
- "the polynomial, written low power first" is unclear about whether `crc_poly` is just
  the XOR mask applied after the right shift. Treating it as that mask (0x80) worked.
- The CRC takes a bit from every OUT, including OUTs used only to extract fields (`out y,
  8`); easy to miss. The statement that a read of `crc` freezes the register until it is
  written again was essential and turned out to hold.
- The chip has no XOR, shift or add on X/Y, so a byte checksum is only reachable through
  the CRC register; the document never mentions using it this way.
- `in null, 16` assembles to count field 0, matching "0 means 16"; fine, but the
  assembler's acceptance of 16 is not stated.
