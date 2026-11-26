# Notes: OOK transmitter firmware

## What I read

- `TASK.md`, in full (one read of 144 lines).
- `isa.md`, in full, in four parts (lines 1 to 170, 170 to 339, 339 to 498, 499 to 644).
- `./pe_sim run x.s -help` (run 1 below).

Nothing outside this folder was opened, listed or searched.

## Design

Every pin change is a `set pins, v` on P0 (set_base 0, set_count 1)
executed on a half-bit boundary. A write made in cycle c shows at c+1, but
since every write has the same one-cycle lag only the spacing between
writes matters. I wrote each half bit's level at its boundary where needed;
where the level holds over a boundary (sync nibble, end of preamble) I
skipped the write and made the window 500 cycles instead. Between two
writes, the instructions on every possible path are counted to exactly 250
(or 500) cycles, using `set x, N` plus a loop `l: jmp x-- l [7]` (8(N+1)
cycles) or `[15]` (16(N+1)), and the delay fields of the other
instructions as fine padding. A conditional `jmp` costs 1 cycle whether
taken or not, so both branches of a test have the same length. All errors
are therefore exactly 0 and cannot add up.

Registers: X holds the data bit only until `jmp !x zero`; after that the
bit is in the PC and X is the delay counter. Y counts the 16 preamble
bits, then holds the "last byte" flag. The OSR holds the host word with
`out_msb_first=1`, `threshold=16`: `out null, 7` drops bits 15..9,
`out y, 1` takes bit 8 (last flag), then eight `out x, 1` give the byte
MSB first, after which the OSR counts as empty, so `jmp !osre` ends the
byte with no bit counter.

Flow:
1. `set pins, 0` in cycle 0 (P0 low from cycle 1).
2. `frame: pull` takes the first word of a frame (stalls forever, line low,
   once the words run out), then a gap of 12 x 514 cycles. The first rise
   lands at cycle 6173 of the run, and later frames start 6173 cycles after
   the end of the previous frame's last bit (limits 5000 to 20000).
3. Preamble loop, 16 times: high 250, low 250.
4. Sync: low until mid bit 16, then rise, fall, rise, fall 500 apart
   (unrolled), then 250 to the first data bit.
5. Data bits: `out x,1`, `jmp !x`, two halves. After each bit, `tail`
   decides: same byte (pad `nop [7]`), next byte (`pull`, drop 7, flag),
   or end of frame (`set pins, 0` exactly at the end of the last bit, which
   matters when it is a 0, then back to `frame`).

Path lengths checked by hand (cycles from one pin write to the next):
- A half (first half of any bit): 1 + 1 + 248 = 250.
- Preamble B half: 1 + 1 + 240 + 8 = 250.
- Data B half to same byte: 239 + 1 (`jmp !osre`) + 8 (`nop [7]`) + 2 = 250.
- Data B half to next byte: 239 + 2 + 1 (`pull`) + 2 + 4 (`jmp bit [3]`) + 2 = 250.
- Data B half to frame end: 239 + 2 + 9 (`nop [8]`) = 250.
- Last sync half: 1 + 1 + 232 + 8 (`jmp nb2 [7]`) + 8 = 250.
where 239 = `set pins` + `set x, 28` + 232 + 5 (`jmp tail [4]` or `nop [4]`).

`run_args.txt`: `-config out_msb_first=1,threshold=16,set_base=0,set_count=1 -mode 0=pp`
(set_base and set_count are the defaults; stated anyway).

## Program length

55 instructions (`pe_sim asm ook.s` prints 55 words), all in page 0, so no
page handling is needed.

## pe_sim runs (28 in total)

1. `pe_sim run x.s -help`: printed the flags (config names, -cycles,
   -inputs, -mode, -stimulus, -tx).
2. `pe_sim asm ook.s`: assembled without error, 55 words.
3. `pe_sim run` with the single word 0x01A5, 40000 cycles: P0 low at
   cycle 1, first rise at 6173, and every transition relative to it equal
   to the TASK.md table (8250, 8750, 9250, 9750, 10000, 10250, 10750,
   11250, 11750, 12000, 12250, 12750, 13250, 13750), 46 transitions, no
   errors. Checked by eye.
4. `pe_sim asm ook.s | head -3`: just to see the output format (c000,
   8100, c10b).
5 to 8. A small Python checker (described below) with four fixed runs:
   0xA5; 0x12 0x34 0xFF; six frames of 0x00; six frames of sizes
   16,16,1,1,16,16 (all 0xFF, all 0x00, 0x01, 0xFE, all 0x55, all 0xAA).
   All passed, maximum deviation 0 cycles.
9 to 28. The same checker on 20 runs of random frames (1 to 6 frames,
   1 to 16 random bytes each, seed 1). All passed, maximum deviation 0
   cycles.

The checker (a throwaway script, deleted before hand-in so that only the
asked-for files remain) wrote the words to a file, ran
`pe_sim run ook.s -tx FILE -cycles N` plus `run_args.txt` with N = 20000 +
20000 per frame + the frames' lengths, as TASK.md says, took P0 from the
`pins` lines, and checked: P0 low by cycle 100; first rise in 5000..20000;
each frame's transitions against an ideal list built from the Manchester
rules (direction and place within +-2 of the first rise); end of each
frame low at 500(20+8n); gaps 5000..20000; no transition after the last
frame; line low at the end. I verified its ideal list against the 0xA5
table in TASK.md (46 transitions, end 14000) and a frame ending in a 0
(ends with a fall at 14000) without using pe_sim.

Runs counted: 1 + 1 + 1 + 1 + 4 + 20 = 28 calls to pe_sim.

## Mistakes

- My first instruction count by hand was 52; the assembler gave 55. I had
  miscounted the source, the program was not wrong.
- No timing mistake showed in any run.

## Confusing or possibly wrong in isa.md

- `set_count` and `set_base` defaults: the `pe_sim` section says what is
  not set is 0 except `out_count` 1, `set_count` 1 and `threshold` 8. Clear
  enough, but the per-thread configuration table does not give defaults, so
  I set them explicitly to be safe.
- `out` with `out_msb_first`: "the bits come from bit 15 of the OSR
  downward, whatever `threshold` is". Clear, and it worked, but it means a
  host word's meaningful bits must be at the top; here bits 15..9 are zero,
  so I had to discard 7 bits first. Not a bug, just a cost.
- "When a thread is started ... the OSR is empty: its count stands at
  threshold". With a `pull` first this did not matter.
- The `pins CYCLE XX` output shows all 8 output bits; pins 1..7 show 1
  (the register's reset value) even though they are inputs. Expected from
  the text, but worth knowing when reading the output.
- I found nothing that the simulator contradicted.

## Rules

No rule broken that I know of. I used Python's `random` module and a
script inside this folder only.
