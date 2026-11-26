# Notes: DSI transmitter

## What I read

- `TASK.md`, in full (134 lines).
- `isa.md`, in full, in three parts (lines 1 to 160, 160 to 330, 330 to 638).
- `./pe_sim run x.s -help` (run 1 below).

Nothing outside this folder was opened, listed or searched.

## Design

Configuration (`run_args.txt`): `out_base=0, out_count=1, set_base=0,
set_count=1, threshold=16, out_msb_first=1, in_msb_first=1`, and
`-mode 0=pp`. `clkdiv` is left at 0, so the thread runs every cycle.

Timing. A half-bit is 8333.33 cycles. I use exactly 8333 cycles between
every two pin writes inside a frame. The shortfall is 1/3 cycle per
half-bit, so the last change (half-bit 17 at most) is at most 5.67 cycles
early, well inside the +-80 limit. No fractional schedule was needed.

Delay constant. `set` takes only 5 bits, so the program builds
Y = 8326 = 8<<10 | 4<<5 | 6 once at start with `set x` and `in x` (ISR
shifting left, `in_msb_first`) and `mov y, isr`. Every delay is
`mov x, y` followed by `l: jmp x-- l`, which takes D + 2 = 8328 cycles. Each
path from one pin write to the next has 5 more cycles of real work or `nop`
padding, so every half-bit is 8333 cycles whichever bit values come.

Bit counting. The OSR count does it for free: with `threshold=16` and
`out_msb_first`, `pull` then `out null, 8` throws away bits 15..8, then
`out x, 1` gives D7 down to D0 and `jmp !osre bit` loops while bits remain.

Manchester. `out x, 1` puts the bit in X, `jmp !x zero` splits into two
paths, each of which writes the first half and then the second half with
`set pins`. After the jump X is free for the delay loop.

Gap. After the half-bit 17 write (line low), the program pulls the next
word (if there is none it stalls there forever, line low), then waits
16 x (D + 4) = 133280 cycles, counting the 16 iterations in the ISR's
shift count with `in null, 1` and `jmp !isrf` (then `mov isr, null` resets
it). So the next rise is 274946 cycles after the previous one (allowed
225000 to 375000), and the gap after the stop bits is about 99950 cycles
(10 ms; allowed 5 to 20 ms). The first `set pins, 0` runs in cycle 0 (pin
low from cycle 1) and the first rise is at cycle 133293 (allowed 50000 to
200000).

Program length: 48 instructions (48 words from `pe_sim asm`).

## pe_sim runs (10 in total)

1. `run x.s -help`: lists the flags and config field names.
2. `asm dsi.s | wc -l`: 48 words, assembled with no error.
3. `asm dsi.s | head -3` (same shell line as run 2): first words c000, c088, 4084.
4. `run dsi.s` with 0x00A5, 0x0000, 0x00FF, 1325000 cycles, raw output: P0
   low at cycle 1; rises at 133293, 408239, 683185; for 0xA5 the changes
   fall at half-bits 2,4,6,8,9,10,12,14,16, each step a multiple of 8333
   cycles, matching the table in TASK.md; 0x00 ends with a fall at half-bit
   17, 0xFF with a fall at 16.
5. to 10. I wrote a small Python checker (in this folder, deleted before
   hand-in together with its scratch TX files) that runs pe_sim once,
   builds the ideal edge list for each level, and checks the early fall,
   first-rise window, rise-to-rise window, every edge's level and its
   distance from k x 25000/3, no extra edges and the line low at the end.
   5. 0xA5 0x00 0xFF: OK, max error 5.67 cycles.
   6. 0x01: OK, max error 5.33.
   7. 0x80 0x7F 0x55 0xAA 0x01 0xFE 0x00 0xFF (8 frames): OK, max 5.67.
   8. random 0x20 0x82 0x3C: OK, max 5.67.
   9. random 0x2E: OK.
   10. random 0x42 0xBD 0xF2 0x21: OK.

The program worked on the first run; no mistakes were found in testing.

## Confusing or possibly wrong in isa.md

- `in` without `in_msb_first` is described as shifting bits "right into
  the ISR", but where the new bits enter (top or bottom) is not said; I
  avoided the question by setting `in_msb_first`, which is described
  precisely. It also does not say which bits of the source `in x, n` takes;
  I assumed the low n bits, and the timing in run 4 confirms Y came out as
  8326.
- `!isrf` and `!osre` share the single `threshold`, which is not obvious
  from the condition table; it worked as I read it.
- The `timeout_vector` text says the jump happens "on the cycle after (with
  T = 0, at once)", which mixes "stalls T cycles" with "when it is already
  0", slightly unclear; I did not use waits.
- There is no inverting `mov` and no subroutine call, so Manchester's
  second half needs a branch per bit; not wrong, just a cost.

No rules were broken as far as I know.
