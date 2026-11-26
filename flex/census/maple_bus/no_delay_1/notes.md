# Notes: Maple bus transmitter

## What I read

- TASK.md in full (one read).
- isa.md in full, in four parts (lines 1-160, 160-320, 320-480, 480-638).
- Nothing outside this folder. No other files, repositories or web.

## Design

Config (run_args.txt): `set_base=0, set_count=2, threshold=16, out_msb_first=1,
clkdiv=2, crc_poly=0x80, crc_init=0`, pins 0 and 1 push-pull.

- **Pins.** Every line change is a `set pins, v` writing both lines at once
  (v = A + 2B). The program always knows both levels from its flow of control,
  so no read-back is needed.
- **Clock divider 2.** One instruction is 2 cycles (40 ns). The instruction set
  has no delay field, so waits are `nop`s or `set x, k` / `jmp x-- self` loops
  (k + 2 instructions).
- **Bit coding.** Bits come in pairs: an A-clocked bit (data on B) then a
  B-clocked bit (data on A); every word is 16 bits and the checksum 8, so pairs
  never split. The A bit's step 1 (A rises) is done at the end of the previous
  B bit (write "T"), because before the first bit of a frame A is already high
  and B must stay high. So the writes per pair are: A bit step 2, step 3; B bit
  step 1, 2, 3; then T (or the end pattern's first step, which is the same
  write). These writes alternate A, B, A, B, A, B. Each is at least 4
  instructions (8 cycles) after the previous write, so a cross-line change is
  at least 8 cycles after the other line's last change and a same-line change
  at least 16 cycles after its own. Data bits are read with `out x, 1` and
  branched on with `jmp !x`; each branch has its own copy of the writes.
- **Word count.** At frame start word 0 is pulled, copied to the ISR and
  `in null, 8` leaves N. Then `in y, 1` (Y = 1) puts a 1 in ISR bit 15 and
  `in x, 15` (X = N) makes ISR = 2N + 1 = words still to send after word 0, held
  in Y; `jmp y--` at each word end pulls the next word.
- **Checksum.** With poly 0x80 the CRC register is an 8-bit ring fed by every
  `out` (the transmitted bits): after whole bytes it holds the XOR of all bytes,
  bit-reversed (bit 0 = checksum bit 7). After the last data word: `mov osr,
  crc` (which also stops the CRC), `out null, 8`, then 8 rounds of `out x, 1;
  in x, 1` reverse it into the ISR (which shifts right, new bit at the top);
  `in null, 8`, `mov osr, isr`, `out null, 8` leave the checksum at the top of
  the OSR with 8 bits to go. The same bit loop sends it.
- **Data phase vs checksum phase.** The ISR's bit count is the flag: 0 during
  data (cleared at frame start), 16 after the checksum is set up. At a word end:
  `jmp !osre` (more bits), else `jmp !isrf` (data phase: next word or checksum),
  else end pattern.
- **Start pattern** uses Y as a 4-pulse counter before Y is loaded with the
  word count. **End pattern** is straight-line writes with delay loops, then an
  idle wait of two 33-instruction loops (about 140 cycles of idle before the
  next frame's first change), then back to `pull`, which stalls with both lines
  high when the words run out.
- **Pages.** The program does not fit in 64 words: page 0 holds frame start,
  start pattern and end pattern; page 1 the bit loop, word handling and
  checksum. Crossings use `set page, n` + `jmp`, with `.page` directives.
- **Timing measured** (by my checker over all tests): smallest cross-line gap 8
  cycles, smallest same-line gap 14 cycles (12 before I widened the start/end
  pattern delays), largest gap inside a frame 86 cycles (the checksum setup
  between the last data bit and the checksum's first bit), first change at
  cycle 5.

## pe_sim runs (16 in total)

1. `run x.s -help`: printed the flags list (config field names, -mode, -tx,
   -cycles, -inputs, -stimulus).
2. and 3. One command ran `asm` twice: assembly error at line 44, "jump to e1
   ... in page 0, but PAGE is 1 here". The assembler follows `set page` down the
   listing, so after my `set page, 1` the page 0 lines below it counted as page
   1. Fixed with `.page 0` / `.page 1` directives.
4. `asm`: assembled, 117 words including `.align` padding.
5. Example frames from TASK.md (0x0000 0x2001, then 0x0100 0x0109 0xDEAD
   0xBEEF) checked by my script: change sequence exactly as expected (98 changes
   for the first frame), all timing limits met, max gap 86, min cross 8, min
   same 12. Worked first time.
6. to 13. Eight random tests (fixed seeds): N = 255,255,255,255; 0,0,0,0; four
   random; 1,2,3,0; one random (130); 255; 0; two random. All OK: exact change
   sequences, timing limits, idle between frames in range, nothing after the
   last frame.
14. to 16. After widening the start/end pattern same-line delays (12 to 14
   cycles, for margin): random N = 0,255,228,25; random 242; the example. All
   OK, min same-line gap 14.

The checker (my own Python script, check.py, deleted at the end along with the
temporary tx file) built the expected change sequence from the bytes with the
three-step rule, start and end patterns, compared it change for change, and
checked every timing limit in TASK.md.

## Mistakes found

- Page directives (run 2/3), as above.
- First plan had the end pattern in page 1; page 1 overflowed 64 words, so I
  moved it to page 0 before assembling.
- Earlier, on paper: a design with clkdiv 3 or 4 and no delay loops would have
  broken the 100-cycle limit during the checksum reversal (about 30
  instructions), which is why the clock divider is 2.

## Program length

104 instructions (117-word image including the `.align` padding of page 0).

## Confusing or possibly wrong in isa.md

- `in` without `in_msb_first`: the text says "shifts count bits right into the
  ISR" but does not say where new bits go; I assumed the top (as in PIO), and
  the tests confirm it.
- The assembler tracking `set page` down the listing (not only `.page`) was
  clear only from the error message; the doc mentions it, but it is easy to
  miss that page 0 lines after a `set page, 1` need `.page 0`.
- No delay field and no bit-reverse in `mov`, so delays and the checksum
  reversal cost instructions. With poly 0x80 the CRC gives an XOR checksum, but
  reversed for an MSB-first line; the doc does not say this, it is my
  derivation.
- Threshold is shared by OSR and ISR, which I used as a flag; the doc is clear.
- Nothing I found was wrong; I broke no rule that I know of.
