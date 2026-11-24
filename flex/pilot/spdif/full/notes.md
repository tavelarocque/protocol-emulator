# Notes: S/PDIF transmitter for the protocol emulator

## What I read

- `TASK.md`, once, in full.
- `isa.md`, once, in full.
- The output of `./pe_sim run FILE.s -help` (flag list only).
- Nothing else. I did not open, list or search anything outside this
  directory, did not use the web, and did not look inside `pe_sim`.
  One assembler error printed an OCaml stack trace naming source files
  (`model/asm.ml`, `bin/pe_sim.ml`); I read the error message and did not
  follow those paths.

## Files here

- `spdif.s`: the program (61 instructions, one page).
- `run_args.txt`: `cell_cycles=8` and the `-config` / `-mode` flags.
- `check.py`: my own test tool. `gen` writes a TX word file; `chk` decodes
  the `pins CYCLE HEX` lines the way a receiver would (cell grid from the
  first change, preamble B/M/W by position, biphase-mark bits, sample
  value, V, U, C per frame of the block, even parity, intervals of exactly
  1, 2 or 3 cells, no change after the end, no change on other pins). It is
  not the acceptance test, which I cannot see.
- `notes.md`: this file.

## Design

Cell = 8 core-clock cycles, so a bit is 16 cycles and the sample rate is
49 152 000 / (128 x 8) = 48 000 Hz. Thread runs every cycle (no clkdiv).
All pin changes are `set pins` on P0 (`set_base=0, set_count=1`), so every
edge is placed by counting cycles and delay fields.

Line level. There is no way to invert a pin, so the line level is kept in
the program counter: the bit loop exists twice, `h_bit` (line high before
the bit) and `l_bit` (line low before the bit). A zero bit hands over to
the other copy, a one bit stays. The output register resets to ones, so the
line rests high and I never touch it before the first preamble; every
preamble is the inverted form (low, low, low, high, ...).

Parity for free. Because the level is known from the program counter, the
parity bit needs no computation: after the C bit, if the line is high send
P = 1 (two changes), if it is low send P = 0 (one change). Either way the
line is high again before the next preamble, which is exactly even parity.

Data. Autopull with threshold 16 joins the two words of a sample into one
stream. The loop shifts 26 bits: 24 data bits, then bits 8 and 9 of the
second word, which the task guarantees are 0 and which serve as V = 0 and
U = 0. One loop of 26 with X as the counter and Y as the bit, shared by
both subframes and all frames.

Loop exit. The last bit of the loop (U) is always 0, so the loop can only
end on the zero path. That leaves two exits (line low, line high) instead
of four, which is what made the program fit in one 64-word page.

C bit. The start-of-bit change of C is the same for C = 0 and C = 1, so it
is written first (t = 16) and the frame counter is tested afterwards, in
the 8 cycles before the middle of the bit. The C = 0 path falls into the
other level's `set pins` (which re-writes the level the pin already has,
so nothing changes) to save two jumps.

Frame counter. ISR holds c: 24 in frame 0 of a block, minus one a frame,
reloaded with 191 after 0. So all three tests are against 5-bit constants:
c = 24 means preamble B, c = 22 (frame 2) and c = 0 (frame 24) mean C = 1.
191 does not fit `set`, so it is built in the ISR when c is 0 (ISR is then
0): `set y,31; in y,5; set y,5; in y,5; in null,6` gives 31 + 5 x 32 = 191.
This happens during cells 0 to 2 of the preamble, where there is spare time.

Left or right. The shared loop has to know which subframe it is in. I keep
that in the ISR's shift count: `in y, 16` loads c and leaves the ISR full
(left subframe), `mov isr, y` loads c with the count reset (right
subframe). `jmp !isrf` at the end of a subframe picks preamble W or the
next frame. The 191 reload shifts exactly 16 bits, so it also ends full.

End of the run. At the end of every subframe (t = 42, line high, 6 cycles
before the next preamble) an explicit `pull` drops the 6 unused bits of the
second word and takes the next word. After the last frame the FIFO is
empty, so that `pull` waits for ever and P0 stays high: no change after the
last subframe. The same `pull` at `start` waits for the first word.

Timing table (cycles, t = 0 is the start of the last loop bit): C at 16,
P at 32, preamble cell 0 at 48, cell 3 at 72, B pulse 80 to 88, W pulse 88
to 96, M pulse 96 to 104, first data bit at 112. Each instruction's time is
in the comments of `spdif.s`.

Limit I know about: if a host broke the word format and put ones in bits
9..8 of a second or fourth word, V or U would be 1 and, if U were 1, the
loop would run off its one-path exit. The task says those bits are 0.

## Every run of pe_sim (15 in total)

1. `./pe_sim asm t0.s` on a one-line `nop` file: printed `e000`. (File
   deleted afterwards.)
2. `./pe_sim run t0.s -help`: the flag list.
3. `./pe_sim asm spdif.s`: failed, `expected a number, got "stora"`.
   Mistake 1 below.
4. `./pe_sim asm spdif.s` after making labels lowercase: 61 words.
5. `run` with 2 frames (0x123456 / 0xABCDEF, then 0x000000 / 0xFFFFFF),
   3000 cycles. Learned the output format (`pins CYCLE HEX`). First change
   at cycle 3, B preamble edges at +24, +32, +40, first data bit at +64.
   Decoded with `check.py`: PASS.
6. to 12. Seven runs, each decoded with `check.py`, all PASS: 400 random
   frames; 1 frame; 400 frames all 0xFFFFFF; 400 frames all 0; 193 frames
   of 0x555555 / 0xAAAAAA / 0x000001 / 0x800000 / 0xFFFFFE / 0x7FFFFF;
   25 random; 3 random. Each ran 6000 cycles past the end to see that P0
   stays still.
13. to 15. Three runs with the flags taken from line 2 of `run_args.txt`,
   20 000 cycles past the end, all PASS: 400 random frames (other seed),
   exactly 192 random frames, 2 frames of the fixed patterns.

The 400-frame runs cover blocks starting at frames 0, 192 and 384, C = 1 at
frames 2, 24, 194, 216 and 386, and the 191 reload.

I also checked the checker without the simulator: a wrong expected sample,
one edge moved by a cycle, and an extra change after the end are each
reported as FAIL.

## Mistakes and how I found them

1. Labels with capital letters (`storA`, `H_bit`). The assembler rejected
   the first jump with `expected a number, got "stora"`: it lowercases the
   operand but not the label definition. Fixed by using lowercase labels.
   Found by the assembler error on run 3.
2. No functional bug showed up in simulation: the first version that
   assembled passed every run. The things I had to guess, and that the runs
   confirmed, are listed in the next section. Design errors I caught on
   paper before the first run: a first layout was 74 words (two pages),
   then 68; noticing that U = 0 forces the loop to end on the zero path,
   and letting the C = 0 path fall into a harmless repeated `set pins`,
   brought it to 61. I also first planned the 191 reload with
   `in_msb_first`, then saw that it would leave the ISR shift count at 10
   (not full), which would have marked the left subframe as a right one;
   the default shift direction with `in null, 6` ends at exactly 16.

## Rule slips

None that I know of. Reads and writes stayed in this directory, `pe_sim`
was run only as `./pe_sim` from here, 15 runs against a budget of 80. I
deleted my own temporary files here (`t0.s`, the TX and output files of the
test runs); `check.py` is kept.

## Result

- Program length: 61 instructions.
- Cell length: 8 core-clock cycles; sample rate 48 000 Hz.
- I believe it works: 13 simulated streams, up to 400 frames, decode
  correctly with exact timing in my own receiver. The acceptance test is
  unseen, so this is my evidence, not a guarantee.

## What was confusing or looks wrong in isa.md

Things I had to guess (1 to 3 and 6 confirmed by running; 4 and 5 I
worked around and did not test):

1. Assembler syntax is not described. The delay field is written `[n]`
   after the operands; isa.md never says so (it shows only `side V`). I
   guessed it from RP2040 pioasm. Label rules (lowercase only, see mistake
   1), comment character, and whether `jmp` takes a comma (the encoding
   table says `jmp cond, addr`, the text writes `jmp x-- l`) are also
   unstated.
2. `pull` when autopull is on. isa.md says `pull` "loads the OSR from the
   TX FIFO and marks it full", with no condition. On the RP2040, which the
   document says it follows, `pull` with autopull does nothing unless the
   OSR is empty. My design depends on it being unconditional; it is, but
   the document should say so.
3. Whether a `jmp`'s delay applies when the jump is taken, when it is not,
   or both. It applies both ways. The document says only "extra idle
   cycles after the instruction completes".
4. The state of the registers and shift counts after reset (is the OSR
   empty or full of zeros, is the ISR count 0), and whether the ISR count
   stops at the threshold or keeps counting. I avoided depending on the
   OSR's reset state by pulling first.
5. Defaults of the configuration fields (`threshold`, `set_count`,
   `start`) are not given. I set the ones I need explicitly.
6. The format of the `-tx` file and of the simulator's output is not in
   isa.md or in `-help` (hex with `0x` works; output is `pins CYCLE HEX`).

Things that look wrong or stale:

7. "Reserved encodings decode as nop: `set` with destination 3; `mov` with
   source or destination 6 or 7." But the revision history says `set page`
   uses `set` destination 3 since v2.0 and `mov` location 6 is `crc` since
   v2.1, and the `mov` text lists `crc` as a location. The operand table
   (`mov`: x 0 ... null 5; `set`: pins 0, x 1, y 2) also omits `page` and
   `crc`.
8. "Open questions: IRQ / thread sync. Not in v0" is stale for a v2.3
   document.
9. No way to invert or toggle a pin, and no instruction that tests a pin
   without a timeout vector. For a line code where only changes matter
   this forces the level into the program counter (two copies of the
   code). Worth one sentence in the document, since PIO has `mov pins, !x`
   and readers will look for it.
10. Timing is "one cycle plus delay", but the longest delay (15) is short
    next to a 24-cycle gap, so I had to spread waits over neighbouring
    instructions. Not wrong, only worth saying.
