# notes.md: Miller transmitter

## What I read
- TASK.md and isa.md, both in full, before writing anything. Nothing outside this folder.
- `./pe_sim run miller.s -help` for the flag syntax (`-config k=v,...`, `-mode P=pp|od|in`).

## Design
- `clkdiv=5`: one tick is 5 cycles, a bit is 20 ticks, half a bit 10. Every wait then fits in
  one 4-bit delay field, and every transition lands on a tick, so there is no drift at all.
- Toggle without knowing the level: Y's bit 0 is the line level. `jmp y-- next` (decrement
  either way) followed by `mov pins, y` (out_count 1) toggles P0. `set y, 0` at reset, then one
  dummy toggle that writes 1 (no change), so the first real toggle is a fall.
- `threshold=8`, no autopull: `jmp !osre` says whether data bits are left in the byte; one more
  `out x, 1` then gives bit 8 (last byte flag); `pull` fetches the next byte.
- The previous bit lives in the PC: `f0`/`hk0` after a 0, `f1`/`hk1` after a 1. A 1 toggles at
  S+10 ticks; a 0 after a 0 toggles at S; a 0 after a 1 does nothing. The start bit is just the
  "0 after 0" toggle entered straight from the idle `pull`. The end bit after a 0 reuses the
  toggle at the top of the program and falls into the gap loop; after a 1 it goes to the gap.
- The byte-boundary path (out, jmp, pull) is 3 ticks longer than the mid-byte path, so the
  mid-byte path goes through a one-instruction delay stub (`d0`, `d1`); the pulls carry the
  rest of the delay themselves and fall through into the fetch.
- Gap: `set x, 6` + `jmp x-- g [15]` = 112 ticks. Measured gap (end of end bit to next start):
  480 cycles after a final 0, 450 after a final 1. First fall at cycle 591.
- run_args.txt: `-config clkdiv=5,threshold=8,out_base=0,out_count=1 -mode 0=pp`

## pe_sim runs: 16 in total
1. `run miller.s -help` (flags).
2. `asm miller.s` (assembled first time, 28 words).
3. `run` with the sheet's example 0x0116 0x00DE 0x00AD 0x01BE, 70000 cycles: checked both
   messages by hand against a table I worked out; all transitions exact, gap 480.
4-15. `check.py 1 7`: 12 runs (5 fixed: 0x16, 0xFF, 0x00, [0x80][0x01][32x00][32xFF], the sheet's
   pair; 7 random runs of 1 to 8 messages of 1 to 32 bytes). check.py builds the expected
   transition list from the sheet's rules, uses the test's own N, and checks: P0 high from cycle
   0, first fall <= 20000, every transition within 2 cycles of its place, gap 400..20000,
   no stray or missing transition, nothing after the last message. All pass, worst error 0.
16. One run of 8 messages of 32 random bytes each (1540 transitions): pass, worst error 0.

## Mistakes found
- None in the firmware: the first version assembled and passed. The tick schedule was worked
  out on paper first (comments in miller.s), which is where the effort went. One design error
  caught on paper before any run: a delay on `jmp !osre` applies whether or not the jump is
  taken, so it cannot equalise the two paths; hence the stubs.
- My checker is my own reading of the sheet, not the real acceptance test. It does not model
  sigrok's decoder, only where edges fall.

## Rule slips
- None that I know of. I read and wrote only in this folder and ran pe_sim only as `./pe_sim`
  from inside it. Judgment call to declare: I ran the system `python3` for check.py (it reads
  and writes only files in this folder: check.py, run_args.txt, tx_*.txt, since deleted).
  Extra files I left here: check.py. Deleted my own scratch t1.txt and tx_*.txt.

## Program length
28 instructions (one page, start 0).

## Confusing or possibly wrong in isa.md
1. Reset values of X, Y, OSR, ISR and their shift counts are never stated. I set Y explicitly
   because a wrong parity would lose the first fall. Likewise it is not said whether an `out`
   on an "empty" OSR without autopull still shifts (it does; I rely on it for bit 8) and what
   is shifted in behind.
2. The delay field on a conditional `jmp`, and on a stalling `pull`: the text says delay is
   loaded when the instruction executes, but never says outright that a not-taken jump also
   pays it, or that a pull's delay comes after the stall. Both matter for cycle counting.
3. There is no way to invert or toggle a pin, and no jump on a pin level; the document offers
   no idiom. The `jmp y--` / `mov pins, y` trick is not hinted at.
4. `out x, 1`: not stated that the destination gets the bits right-justified and zero-filled
   (vs. shifted into X). The `mov` operand table lists codes 0..5 but the text adds `crc` (6)
   while "mov with source or destination 6 or 7" is still listed as a reserved NOP.
5. Assembler syntax is only shown by two examples: the `[n]` delay syntax, label syntax,
   comments and number formats are nowhere described (I guessed `[n]` from PIO; it worked).
   The pin write shows one cycle after the `mov pins` executes (end of cycle): fine, but the
   simulator's printed cycle number convention is not documented.
6. `clkdiv` with a stalled `pull`: stated only indirectly that the stall is retried per tick.
