# Notes: OOK transmitter for the protocol emulator

## What I read
- TASK.md in full (144 lines, one read).
- isa.md in full, in four parts (lines 1-160, 160-320, 320-480, 480-638).
- `./pe_sim run ook.s -help` output (run 3 below).
- Nothing outside this folder was opened, listed or searched. No rule broken that I know of.

## Key facts taken from the docs
- 1 MHz core, 2000 bit/s, half bit = 250 cycles. Manchester: 1 = high then low, 0 = low then high.
- Frame = 16 preamble ones, sync 0 1 0 1, payload bytes MSB first. Line low before and after.
- Gap 5000..20000 cycles from end of last bit to next first rise. First rise of the run in 5000..20000. P0 low by cycle 100.
- Host word: bits 7..0 byte, bit 8 = last byte of frame, bits 15..9 zero.
- Every instruction is one tick; with `clkdiv` the thread runs one cycle in every `clkdiv`, first tick on the first enabled cycle.
- `set` takes a 5-bit immediate, so a delay loop counts at most 32 iterations.
- `jmp x-- l` loop entered with X = n takes n + 1 ticks.
- `out_msb_first` takes bits from bit 15 down; `threshold` decides `!osre`.
- `mov pins, x` writes `out_count` pins from `out_base` (pe_sim defaults 1 and 0); `set pins` uses `set_count`/`set_base` (defaults 1 and 0).
- pe_sim prints `pins c+1` for a write made in cycle c.

## Design
Configuration (run_args.txt): `-config clkdiv=10,threshold=16,out_msb_first=1 -mode 0=pp`.

- `clkdiv=10`: one tick = 10 cycles, so a half bit is exactly 25 ticks and a bit 50 ticks. Every
  pin write lands on a tick, so as long as each half bit is exactly 25 ticks of code, every
  transition sits exactly on its ideal place (no drift, error 0). Delays are `set r,k` plus
  `l: jmp r-- l`, which take k+2 ticks; a 48-tick delay uses a two-instruction loop body.
- Line level is written only by `set pins` / `mov pins, x`, so decision instructions never
  disturb the line.
- `threshold=16` with `out_msb_first=1`: after `pull`, `out null,7` drops bits 15..9,
  `out y,1` takes the last-byte flag (bit 8), and 8 `out x,1` take the byte MSB first. After
  the 8th data bit the OSR count reaches 16, so `jmp !osre` falls through exactly at byte end.
- The flag is parked in the ISR (`mov isr, y`) so Y is free as the delay counter during data
  bits; at byte end `mov y, isr` / `jmp !y` decides "next byte" or "end of frame".
- Flow: `start: set pins 0` (tick 0 of the run, and also the end-of-frame fall at t50 of the
  last bit), `pull` (stalls forever after the last frame, with the line low), a fixed gap loop
  (32 x 34 ticks), then a dedicated preamble loop (16 x [rise t0, fall t25]), straight-line sync
  code (rise s25, fall s75, rise s125, fall s175), then the shared byte-start code and the data
  bit loop. The first word of a frame is pulled before the preamble, so no preamble is ever sent
  without data, and the OSR keeps the word untouched through preamble and sync (they use only
  X, Y and immediates).
- Data bit: t0 `mov pins, x` (first half = bit), delay, t24 `jmp !x`, t25 `set pins 0` or
  `set pins 1` (second half), then t27..t49 fetch the next bit or handle byte end, back to t0.
- Timing: from the end of a frame (and from run start) to the next first rise is 1092 ticks =
  10920 cycles, inside 5000..20000. P0 goes low at cycle 1.

## pe_sim runs (29 in total)
1. `pe_sim asm ook.s | wc -l`: assembled without errors, 58 words.
2. `pe_sim asm ook.s | head -3`: first words c000, 8100, c09f (sanity look).
3. `pe_sim run ook.s -help`: list of flags and config field names.
4. Manual run, one frame 0xA5 (word 0x01A5), 50000 cycles: P0 low at cycle 1, first rise at
   10921; all 46 transitions at exactly the offsets of the table in TASK.md (8250, 8750, 9250,
   9750, 10000, 10250, 10750, 11250, 11750, 12000, 12250, 12750, 13250, 13750 checked by hand).
   Note: pe_sim prints the whole 8-bit output register (ff/fe), not just P0.

For runs 5 to 29 I wrote a throwaway Python checker (in this folder, deleted afterwards so that
only the hand-in files remain). For each run it wrote the words to a TX file, ran
`pe_sim run ook.s -tx FILE -cycles N` plus run_args.txt with N computed as TASK.md says, and
checked: P0 low by cycle 100; first rise in 5000..20000; every transition of every frame at
its ideal offset from that frame's first rise (+-2), with the right direction; the low after
each frame; gap 5000..20000; no transitions after the last frame or inside gaps.

5. Frame A5: OK, 46 transitions, worst error 0.
6. Frame 12 34 FF: OK, worst 0.
7. Two frames A5 / 12 34 FF: OK, worst 0.
8. Six frames 00 / FF / sixteen 00 / sixteen FF / 01 / FE (max frames, max size, last bit 0
   and 1): OK, 790 transitions, worst 0.
9. Frames 80 7F 55 AA / 0F F0: OK, worst 0.
10 to 29. Twenty random runs (seeds 10..29, 1 to 6 frames of 1 to 16 random bytes): all OK,
   worst error 0 in every run.

No mistakes were found during testing; the first version of the program passed every check.

## Program length
58 instructions (one page, addresses 0..57).

## Things in isa.md that were confusing or seem wrong
- pe_sim's `pins CYCLE XX` lines show the whole output register (ff/fe here), including pins
  that are inputs; isa.md says it prints "the pins' output" and "levels", which made me expect
  pin levels. Harmless, but I masked bit 0.
- "Every instruction takes exactly one clock cycle" in the design goals is only true with
  clkdiv 0 or 1; with a divider it is one tick. The clkdiv row does say this, so it is just
  loose wording.
- `wait pol pin n`: isa.md does not say whether n is an absolute pin number or relative to
  `in_base` (PIO's `wait pin` is relative). I did not need `wait`.
- `in`: "shifts count bits right into the ISR" does not say where new bits enter for a 16-bit
  ISR (top, as in PIO, presumably). Not used.
- The defaults (`out_count` 1, `set_count` 1, `threshold` 8) are given for pe_sim; isa.md does
  not say whether the hardware's configuration registers reset to the same values. My
  run_args.txt sets threshold explicitly and relies on out/set count 1 and base 0.
- isa.md refers to files (`model/isa.ml`, `model/firmware.ml`, `docs/info.md`) that are not
  here, so the "normative" model could not be consulted.
