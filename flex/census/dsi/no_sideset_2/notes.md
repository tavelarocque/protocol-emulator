# Notes: DSI transmitter

## What I read

- `TASK.md` in full (134 lines), first.
- `isa.md` in full, in three parts (lines 1 to 200, 200 to 399, 400 to 607).
- The help text of `pe_sim run` (run 1 below).
- Nothing outside this folder.

## Design

The line needs a half-bit of 8333.33 cycles, and every change must sit within
80 cycles of its ideal place counted from the frame's rise. The tolerance is
wide, so I used the integer clock divider rather than exact 8333/8333/8334
bookkeeping: `clkdiv=13` makes one tick 13 cycles, and 641 ticks are 8333
cycles. The error is -0.33 cycles per half-bit, so the worst place, half-bit
17, is 5.67 cycles early. Every pin write is made by an instruction, so all
writes in a frame share the same offset from the rise and only the tick count
between them matters.

Delays are built from `set y, 18 [15]` plus the two-instruction loop
`nop [15]; jmp y-- [15]`, which is 32 ticks a pass and 19 passes (608 ticks),
because `set` only loads 5 bits and a one-instruction loop of 16 ticks would
need a count of 38. The leftover ticks of each half-bit are made up with delay
fields on the surrounding instructions.

Data path: `out_msb_first=1` and `threshold=16`. `pull` loads the word, `out
null, 8` drops the zero top byte, then each data bit is `out x, 1`. Because the
OSR counts as empty at 16 bits shifted, `jmp !osre bitloop` runs the bit loop
exactly 8 times with no counter register, which leaves Y free for delays. The
first half of a bit is `mov pins, x` (X holds the bit right-justified, and
`out_count` 1 writes only P0). The second half needs the inverse, which no
instruction gives, so `jmp !x` picks `set pins 0` or `set pins 1`; both paths
take 2 ticks from that write to the shared code after it.

Tick budget per half-bit (all 641):
- rise to first W1: `set pins 1 [15]` 16 + `set y [15]` 16 + 608 + `out x` 1.
- W1 to W2: `mov pins [15]` 16 + `set y [15]` 16 + 608 + `jmp !x` 1.
- W2 to next W1: 2 + `set y [15]` 16 + 608 + `jmp !osre [13]` 14 + `out x` 1.
- W2 of D0 to the stop write: same, with `jmp stopw` (1) in place of `out x`.

The stop write `set pins 0` at half-bit 17 is a fall only when D0 = 0; for
D0 = 1 the line is already low and nothing changes. That same instruction is
the program's first (start = 0), so it also drives the line low in cycle 0.
After it comes the gap: `set x, 20` and 21 passes of (`set y, 31`, 512-tick
loop, `jmp x--`), then `pull` and `out null, 8`: 10798 ticks (140374 cycles)
from the stop write to the rise. So the first rise is at cycle 140375, and
rise to rise is 17 x 641 + 10798 = 21695 ticks = 282035 cycles, inside
225000 to 375000 (gap after the stop bits about 10.7 ms). When the words run
out, `pull` stalls with the line low.

## pe_sim runs

1. `pe_sim run x.s -help`: printed the flags. The config list includes
   `sideset_base` and `sideset_count`, which isa.md never mentions; I did not
   use them.
2. `pe_sim asm dsi.s`: 25 words, assembled with no errors.
3. `pe_sim run` with 0xA5, 0x00, 0xFF: P0 low at cycle 1, rises at 140375,
   422410, 704445. For 0xA5 the changes fell at +16666, +33332, +49998,
   +66664, +74997, +83330, +99996, +116662, +133328 cycles from the rise
   (ideal 16667, 33333, 50000, 66667, 75000, 83333, 100000, 116667, 133333).
   0x00 and 0xFF also matched by hand. Then I wrote `check.py`, which decodes
   P0's changes and checks the start, the first-rise window, rise spacing,
   each change's level and its place against k x 25000/3, and that no extra
   change occurs.
4. 0xA5, 0x00, 0xFF through `check.py`: OK, worst error 5.67 cycles.
5. 8 frames 0x01, 0x80, 0x00, 0xFE, 0x7F, 0x55, 0xAA, 0x00 (N = 3200000): OK,
   122 edges, worst 5.67.
6. One frame 0x00 (N = 575000): OK, worst 5.67.
7. to 9. Three random runs (seed 7: 6 frames, 1 frame, 1 frame): all OK,
   worst 5.67.

Total: 9 runs of pe_sim. No mistakes found in testing: the first program
version passed every check.

## Files

- `dsi.s`: the program. `run_args.txt`: `-config
  clkdiv=13,out_msb_first=1,threshold=16 -mode 0=pp`.
- `check.py`, `t1.txt`, `t2.txt`, `t3.txt`, `r0.txt` to `r2.txt`: my test
  checker and word files, not part of the hand-in.

## Program length

25 instructions.

## Confusing or possibly wrong in isa.md

- `pe_sim run -help` lists `sideset_base` and `sideset_count` config fields
  that isa.md does not describe at all (no side-set field in the encoding).
- The `out` text says that with `out_msb_first` bits come from bit 15
  "whatever threshold is", while the default threshold is 8: an MSB-first
  user with 8-bit host words must either have the host put the byte at the
  top or discard the top byte, as I did. Easy to miss.
- No way to invert a pin or a register, so Manchester's second half needs a
  branch per bit. isa.md says this plainly, it is just a cost.
- `pe_sim` prints all 8 output bits (`ff`/`fe`), including input pins whose
  register bits are 1; only bit 0 matters here. Not wrong, but worth knowing.

I broke no rules that I know of.
