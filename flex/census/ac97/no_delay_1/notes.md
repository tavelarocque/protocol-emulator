# Notes: AC '97 controller (output) firmware

## What I read
- `TASK.md`, in full (one read of all 199 lines).
- `isa.md`, in full, in four parts (lines 1-160, 160-320, 320-480, 480-638).
- `./pe_sim run -help` (counted as run 1 below).
Nothing outside this folder was opened, listed or searched. I wrote only in
this folder: `ac97.s`, `run_args.txt`, `notes.md`, and a test harness
`check.py` (plus temporary `stim_s*.txt` / `tx_s*.txt` files it generated,
which I deleted at the end). No rule was broken as far as I know.

## Design

Pins and configuration (`run_args.txt`):
`-config out_base=2,out_count=1,set_base=1,set_count=2,out_msb_first=1,threshold=16 -mode 1=pp -mode 2=pp`.
P0 stays an input (default). `out pins, 1` and `mov pins, x/isr/y` drive
SDATA_OUT (P2) only; `set pins, v` drives SYNC (bit 0 of v, P1) and SDATA_OUT
(bit 1 of v, P2) together, which is convenient for the tag's constant bits.
No side-set, clock divider, autopull or timeout is used.

Timing. BIT_CLK's high phase is always 2 cycles and the synchroniser delays
what the thread sees by 2 cycles. So `wait 1 pin 0` completes in cycle r+2
for a rising edge at r, which is exactly the cycle of the falling edge that
follows it. An instruction in cycle r+3 changes the pins from r+4, one in
r+4 from r+5; the next falling edge is at r+6 or r+7, so both are safe. A
third instruction (r+5) may run but must not change a line (r+6 can be a
falling edge). The next `wait 1 pin 0` then runs at r+4..r+6, when the
thread sees the clock low (it sees low from r+4 until the next rising edge
r' + 2 >= r+6), so it completes at exactly r'+2 again and nothing drifts.
Rule kept everywhere: between two waits there are 1 to 3 instructions, and
only the first two may write pins. (Two waits in a row would double-count,
since the thread sees the clock high for 2 cycles.) The level written in the
period after rising edge k is carried by falling edge k+1.

Start: `set pins, 0` in cycle 0 (both lines low from cycle 1),
`wait 0 pin 0` to get past the synchroniser's two reset cycles of 1,
`pull` the first CTRL and drop its bit 15. The first `wait 1 pin 0` sees the
codec's first rising edge (whose falling edge is edge 0), so SYNC rises at
falling edge 1.

Frame (e = edge where SYNC first is high):
- e: SYNC=1, SDATA=0; meanwhile drop CTRL bits 14..9, X = c8.
- e+1: tag bit 15 = 1; Y = c7, ISR = c7 (kept for slot 1 bit 19).
- e+2: tag bit 14 = X (c8). Then if c7 = 1 (a read) `jmp x--` makes X = 0,
  otherwise X stays c8; so X = c8 and not c7 = slot 2 valid.
- e+3: tag bit 13 = X. e+4: tag bit 12 = 1 (bit 11 is also 1, no change).
  e+6: tag bit 10 = 0. e+7..e+15: a 9-period counting loop.
- e+16: SYNC low, tag bit 0 = 0.
- e+17: slot 1 bit 19 = ISR (c7); X=18, Y=3.
- e+18..e+36: 19 `out pins, 1` from the OSR: CTRL bits 6..0, then zeros
  (the OSR shifts in zeros once its 16 bits are used).
- After the last bit of each slot, in the spare third slot, `pull` the next
  word. Then a period that outputs the new word's first bit, sets X=18 and
  `jmp y-- bits` runs 19 more bits: 16-bit word then 4 zeros. This repeats
  for DATA, LEFT, RIGHT (slots 2, 3, 4).
- After slot 4 the `pull` fetches the next frame's CTRL. If there is none it
  stalls for ever with SYNC and SDATA low, which is the required end state
  (no new SYNC pulse, SDATA low). Otherwise the same period outputs CTRL bit
  15 (always 0) as slot 5's first bit, and Y runs out.
- e+98..e+255: count 158 periods (1 + 1 + 6 x 26) with nested X/Y loops,
  then `jmp frame`: e+256 is the next frame's SYNC rise.

Tag cases: no command CTRL=0 gives X=0 (tag 0x9800); write c8=1,c7=0 gives
X=1 (0xF800); read c8=1,c7=1 gives X=0 (0xD800). Slot 1 = c7, then the 7
address bits, then 12 zeros, which is exactly CTRL bits 7..0 followed by 12
zeros, and all zeros for no command.

## Test harness
`check.py SEED FRAMES [r0] [phase]` writes a BIT_CLK stimulus (first rising
edge r0 in 200..299, then rising edges at r0 + floor(k x 4.069 + phase), high
2 cycles; or with a negative phase, random 4- or 5-cycle periods as a stress
test beyond the spec) and random frames of all three kinds, runs
`pe_sim run ac97.s -tx -stimulus -cycles 400+1042(F+2)` plus `run_args.txt`,
and checks: no change of SYNC or SDATA in any falling-edge cycle; both low by
cycle 40 and low before the clock; first SYNC at edge 1..255; SYNC exactly 16
edges high every 256 edges for F frames and low otherwise; every SDATA bit at
every falling edge against the expected 256-bit frames (and 0 outside
frames, to the end of the run); and SYNC changes exactly 1 + 2F times. A
sixth argument uses the TASK.md example words instead.

## pe_sim runs (37 in total)
1. `run -help`: lists the flags and config field names.
2. `asm ac97.s`: assembled, 48 words.
3. TASK.md example (2 frames, r0=250): OK, output inspected by hand: pins go
   ff -> f9 at cycle 1, SYNC up at 254 (first rising edge 250, seen 252).
4-23. 20 random runs, seeds 10..29, 1 to 12 frames, random r0 and phase:
   all OK.
24. Checker self-test with a deliberately wrong expected bit (FLIP=1): FAIL
   at the flipped bit, as it should.
25-26. Stress clocks (random 4/5 periods), 12 frames r0=200 and 7 frames
   r0=299: OK.
27. 1 frame, r0=200, phase 0: OK.
28-35. Stress clocks, seeds 50..57, 3 to 10 frames, r0 250..299: OK.
36-37. 12 frames, r0=299 phase 0.999 and r0=200 phase 0.5: OK.
No mistakes were found in the program; the first version passed every run.

## Program length
48 instructions (`ac97.s`, as reported by `pe_sim asm`).

## Confusing or possibly wrong in isa.md
- `pins CYCLE XX` prints the whole output register, not pin levels: input
  pins P0 and P3..P7 show as 1 (`f9`, `fd`) while BIT_CLK is low. isa.md says
  "the pins' output", which is right, but it is easy to read it as levels.
- The `in` instruction with the default (LSB-first) direction says bits are
  shifted "right into the ISR", but not at which bit the new bits enter when
  `threshold` is below 16. I did not need `in`.
- `out` cannot target the ISR (only pins, x, y, null), unlike PIO; I used
  `mov isr, y` to keep a bit in the ISR as a spare register. Not an error.
- Side-set is applied on every cycle an instruction stalls, so side-set on a
  `wait` would drive a line during the falling-edge cycle; that is stated,
  but it is the reason I did not use side-set for SYNC.
- There is no non-blocking way to test whether the TX FIFO is empty (no
  `!txe` condition, `pull` has no timeout). Here a pull that blocks for ever
  with the lines low is exactly the required end of a run, so it did not
  matter, but a protocol that must keep clocking when the host runs dry
  could not detect it.
