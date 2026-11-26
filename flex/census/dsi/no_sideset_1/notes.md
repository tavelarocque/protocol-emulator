# Notes: DSI transmitter firmware

## What I read
- `TASK.md`, in full (one read).
- `isa.md`, in full, in four parts (lines 1-160, 160-320, 320-470, 470-607).
- The output of `pe_sim run x.s -help` (run 1 below).
Nothing outside this folder was opened, listed or searched.

## Design
Thread 0, clkdiv 1 (every cycle), P0 push-pull, written only with `set pins`
(set_base 0, set_count 1, the defaults). Config: `out_msb_first=1` so data
leaves D7 first, `threshold=16` so `jmp !osre` counts the 16 bits of a word
(8 discarded zero bits plus 8 data bits) and serves as the bit counter for
free, and `in_msb_first=1` so the ISR shifts left and a constant can be built
in it 5 bits at a time.

Timing: a half-bit is 8333.33 cycles. I use a constant H = 8333 cycles for
every half-bit. The error then grows by 1/3 cycle per half-bit, at most
17/3 = 5.7 cycles at the last change (half-bit 17), far inside the 80-cycle
limit, so no fractional 8333/8334 pattern is needed. The delay is
`mov x, isr` plus a `jmp x-- l` loop (N + 1 cycles), with N = 8327 built
once at start in the ISR (`set x,8; in x,5; set x,4; in x,5; set x,7; in x,5`,
since 8327 = 01000 00100 00111 in 5-bit groups). The ISR is never touched
again, so X is the loop counter and Y holds the data bit or the gap count.

Each data bit: `out y,1`, `jmp !y zero`, then one of two mirror-image blocks
(set level, delay, set opposite level, delay, `jmp !osre bit`). Delay fields
pad every interval between two consecutive `set pins` in a frame to exactly
N + 6 = 8333 cycles: the rise has [1], the first-half `mov` has [3], and the
fall at half-bit 17 after a D0 = 0 is preceded by `nop [1]`. The two branches
have the same instruction counts, so both are cycle-exact.

Framing: at start, `set pins,0` (line low from cycle 1), then a gap of
12 x (N + 3) = 99960 cycles, then `pull`, `out null,8`, rise. After a frame
(the line is low from half-bit 16 or 17) the program jumps back to the same
gap, so rise-to-rise is about 241623 cycles (gap after the stop bits about
6.66 ms) and the first rise is at about cycle 99971. When the words run
out, the thread stalls on `pull` with the line low.

## pe_sim runs
1. `pe_sim run x.s -help`: listed the run flags and config names. It lists
   `sideset_base` and `sideset_count`, which isa.md never mentions.
2. `pe_sim asm dsi.s`: assembled, 36 words.
3. `pe_sim run dsi.s` with 0x00A5, 0x0000, 0x00FF: low at cycle 1, first
   rise 99971; frame 0xA5 changes at +16666, 33332, 49998, 66664, 74997,
   83330, 99996, 116662, 133328 (ideal 16667 ... 133333); rise-to-rise
   241623 and 241626; 0x00 ends with a fall at +141661 (half-bit 17), 0xFF
   ends at +133328 (half-bit 16). All correct.
4-11. A throwaway Python checker (deleted afterwards so the folder holds only
   the hand-in) ran pe_sim 8 times: one run of 0x00, 0xFF, 0x55, and seven
   random runs of 1 to 8 random frames (seed 1), with -cycles 200000 +
   375000 per frame and the flags from run_args.txt. It decoded the P0
   changes, compared every change with k x 25000/3 from its frame's rise,
   and checked the low-within-1000 rule, first-rise window, rise-to-rise
   window and that nothing moves after the last frame. All 8 passed; worst
   placement error 5.67 cycles.

Total: 11 pe_sim invocations. No mistakes found in testing; the first
version passed.

## Rules
No rule broken as far as I know. I deleted my own helper files (t1.txt,
tx_tmp.txt, check.py) inside this folder.

## Program length
36 instructions (36 words from `pe_sim asm`).

## Confusing or possibly wrong in isa.md
- `pe_sim run -help` lists `sideset_base` and `sideset_count` config fields,
  but isa.md describes no side-set anywhere (not in the encoding, the
  config table or the syntax). Either the doc is missing a feature or the
  tool has leftover fields. I did not use them.
- The default `in` direction says "shifts right into the ISR" but not where
  new bits enter in a 16-bit register or how a later `mov x, isr` relates to
  the right-justified value `push` gives. I sidestepped this with
  `in_msb_first`, where bits enter at the bottom.
- `in x, n` does not say which n bits of X are taken (I assumed the low n,
  which the timing confirmed).
- The run-flag text says unset config is 0 "except out_count 1, set_count 1
  and threshold 8", while the start-of-thread text says the OSR count
  "stands at threshold": both fine, but whether `out null, 8` on a freshly
  pulled word counts toward `!osre` with threshold 16 had to be inferred
  (it does).
