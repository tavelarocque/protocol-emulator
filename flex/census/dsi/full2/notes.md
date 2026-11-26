# Notes: DSI transmitter on the protocol emulator

## What I read

- `TASK.md`, in full (one read of 134 lines).
- `isa.md`, in full, in four parts (lines 1-160, 160-330, 330-490, 490-644).
- `./pe_sim run x.s -help` output (run 1).
- Nothing outside this folder was opened, listed or searched. No rule was broken
  as far as I know.

## Design

Core clock 10 MHz, `clkdiv` left at 0 (thread runs every cycle). A half-bit is
8333.33 cycles. I make every half-bit exactly 8333 cycles, from one `set pins`
to the next. The error then grows by 1/3 cycle per half-bit and the latest
change in a frame (half-bit 17) is at most 17/3 = 5.67 cycles early, far
inside the +-80 cycle limit. Because the program writes the pin at every
half-bit boundary (even where the level does not change), every half-bit has
the same structure, and the time is counted from the frame's own rise, so no
error carries from one frame to the next.

Registers:
- ISR holds the delay constant K = 8327, built once at start with three
  `set x, n` / `in x, 5` pairs (`in_msb_first`, so 8<<10 | 4<<5 | 7). Each
  delay is `mov x, isr` then `l: jmp x-- l`, which takes K + 2 cycles.
- X is the delay counter and, briefly, the data bit (`out x, 1` then
  `jmp !x zero`).
- Y counts the 16 half-bit delays of stop bits plus gap.
- OSR holds the word. `out_msb_first` and `threshold=16`: `out null, 8` drops
  bits 15..8, then 8 `out x, 1` give D7..D0, and `jmp !osre bit` ends the
  byte after the eighth bit with no extra counter.

Flow: `set pins, 0` first (line low at cycle 1); build K; `main:` writes the
pin low (this is also the start of stop bit half-bit 17), waits 16 half-bits
(~13.3 ms), `pull` (stalls with the line low when the words have run out),
start bit high, then for each bit a "one" path (high then low) or a "zero"
path (low then high), then back to `main`.

Cycle budget per half-bit, set to next set, all = K + 6 = 8333:
- start bit: `set pins,1 [1]` (2) + mov (1) + loop (K+1) + `out` + `jmp !x` (2)
- first half: `set [3]` (4) + mov (1) + loop (K+1)
- second half: set (1) + mov (1) + loop (K+1) + `jmp !osre` (1) + `out` + `jmp !x` (2),
  or for the last bit: + `jmp main [1]` (2), reaching `main`'s `set pins, 0`.

Resulting timing: first rise at cycle 133292 (window 50000-200000), frames
rise-to-rise 274945 cycles, so the gap after the stop bits is 99945 cycles
(10 ms, window 5-20 ms).

Program length: 35 instructions (`pe_sim asm dsi.s` prints 35 words).

`run_args.txt`:
`-config threshold=16,out_msb_first=1,in_msb_first=1,set_base=0,set_count=1 -mode 0=pp`

## pe_sim runs (14 total)

1. `pe_sim run x.s -help`: printed the flags and config key names.
2. `run isrtest.s` (a throwaway test: build K in ISR with in_msb_first, push it,
   copy it to Y and push again): `rx 7 8327`, `rx 9 8327`. Confirmed the
   bit order of `in` with `in_msb_first`, that `=1` works for boolean config
   keys, and that rx words print in decimal.
3. `pe_sim asm dsi.s`: assembled, 35 words.
4. `run dsi.s` with 0x00A5, 0x0000, 0x00FF: low at cycle 1, frame 1 rise at
   133292 and changes at +16666, +33332, +49998, +66664, +74997, +83330,
   +99996, +116662, +133328, matching the TASK.md example within 5 cycles.
   Frames 2 and 3 at 408237 and 683182.
5-8. With `check.py` (a checker I wrote here: runs pe_sim, decodes P0,
   compares every change to k x 25000/3 from the frame's rise, checks the
   first-rise window, gaps, initial low within 1000 cycles, no extra changes,
   line low at end): A5 00 FF; 01 80 55 AA 7E 81 FE 00 (8 frames); 00; FF.
   All OK, worst error 5.67 cycles.
9-14. `check.py` on six random runs (seeded 1-6, 1 to 5 frames): all OK,
   worst error 5.67 cycles.

No mistakes found in the program after it was written; the first full run
was correct. Throwaway files (isrtest.s, tx files, output) were deleted;
`check.py` is left in the folder.

## Confusing or possibly wrong in isa.md

- `in` without `in_msb_first` is described as shifting "right into the ISR",
  but where the new bits enter (top or bottom) is not stated; only the
  msb-first case says "new bits enter at the bottom". I avoided the question
  by using `in_msb_first` and checking with a push.
- The value syntax for boolean config fields (`out_msb_first=1`) is not
  documented in isa.md or in `-help`; `=1` worked.
- isa.md says `pe_sim` prints `rx CYCLE WORD`, but not that WORD is decimal
  while `pins` prints hex.
- The `pins` lines show the output register (ff/fe here), so pins left as
  inputs show as 1, not their "external level"; the text says "the pins'
  output", which fits, but it is easy to misread as pin levels.
- `out_msb_first` taking bits from bit 15 regardless of `threshold` is
  clear, but means an 8-bit host word needs either the host to shift it up or
  an `out null, 8`, plus `threshold=16` so `!osre` counts the full word.
- isa.md refers to `model/...`, `hw/...`, `docs/info.md` and
  `model/firmware.ml`, which are not available here; nothing I needed was
  only there.
