# Notes: AC '97 output firmware

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `./pe_sim run x.s -help` (counted as a pe_sim run below).

Nothing outside this folder was opened, listed or searched. One honest
remark: my very first shell command (`ls -la && cat TASK.md && cat isa.md`)
produced more output than the tool shows inline, and the tool harness saved
that output to a file outside the folder on its own. I did not open that
file; I re-read both documents from this folder with the file reader instead.

## Design

Config (`run_args.txt`): `set_base=1, set_count=2` so `set pins, v` writes
SYNC (bit 0, P1) and SDATA_OUT (bit 1, P2) together; `out_base=2,
out_count=1` so `out pins` and `mov pins` drive SDATA_OUT alone;
`out_msb_first=1`; `threshold=16` (not actually relied on: no autopull and
no `!osre`). P1 and P2 push-pull, P0 left an input.

Timing. A rising edge of BIT_CLK at cycle r is seen by the thread at r+2,
which is exactly the cycle of the falling edge that follows it (high phase
is always 2 cycles). So every bit slot is `wait 1 pin 0` followed by 1 to 3
instructions, and the pin write, when there is one, is always the first of
them: it executes at r+3 and shows as `pins r+4`. The next falling edge is
at r+6 or r+7, the one before was at r+2, so the change never lands on a
falling edge and the new level is carried by the NEXT falling edge. At
least 1 instruction between waits stops a wait from seeing the same 2-cycle
high phase twice; at most 3 keeps up with a 4-cycle period (the next high
is seen 4 cycles after the last). A 5-cycle period just makes the wait stall
one cycle longer. Re-syncing on every bit means the 4/5 pattern and its
alignment do not matter.

Start: `set pins, 0` in cycle 0 (both lines low from cycle 1), `wait 0 pin
0` to get past the two reset cycles that read high, `pull` the first CTRL,
then one wait for rising edge 0 (falling edge 1 stays low). The first SYNC
is at falling edge e = 2.

Frame, by falling edge relative to e:
- e: `set pins, 1` (SYNC up, SDATA 0), then `out null, 7`, `out x, 1` (x = command bit).
- e+1: `set pins, 3` (tag bit 15), `out y, 1` (y = read bit), `jmp loop`.
- e+2: `mov pins, x` (bit 14); then slot-2-valid = x and not y, computed as
  `jmp x!=y wr; mov x, null` (the read-without-command case cannot occur).
- e+3: `mov pins, x` (bit 13). e+4: `set pins, 3`. e+5: no change.
- e+6: `set pins, 1`, e+7..e+15 zero loop, e+16: `set pins, 0` (SYNC down).
- e+17: `mov pins, y` (slot 1 bit 19). e+18..e+25: 8 x `out pins, 1`
  (7 address bits, then a 0 since the OSR is spent and an `out` past the
  word gives zeros). Then `pull` DATA.
- e+26..e+36: zeros (11 bits).
- Slots 2, 3, 4 share one loop: 19 x `out pins, 1` (16 bits then 3 zeros),
  then the slot's last bit slot does `pull; set x, 18; jmp y-- wb`. The
  third pass pulls the next frame's CTRL. After the last frame that pull
  stalls forever, with SYNC and SDATA already low, so no further SYNC pulse
  and SDATA stays low: that is how "words have run out" is handled.
- e+97..e+255: 159 zeros (1 + 30 + 4 x 32, nested x/y loop), falling into
  `fstart`, whose wait is edge e+256 = next frame's e.

## Program length

56 instructions (`pe_sim asm` gives 56 words), all in page 0.

## Test harness

`check.py SEED F [first_rise] [phase]` writes `t_stim.txt` (BIT_CLK: first
rise at 200..299, rises at r0 + floor(n x 4.069 + phase), high 2 cycles, so
periods of 4 or 5) and `t_tx.txt` (random write/read/no-command frames; seed
0 uses the two example frames from TASK.md), runs pe_sim once with
`run_args.txt` and N = 400 + 1042 x (F + 2), and checks: no change of P1/P2
in a falling-edge cycle; both low by cycle 40 and until the first SYNC; first
SYNC at edge 1..255; SYNC high exactly at e..e+15 of every frame and nowhere
else; SDATA at every falling edge equal to the expected frame bits and 0
outside frames, to the end of the run.

## pe_sim runs (18 in total)

1. `pe_sim run x.s -help`: printed the flags (config field names, -mode, -tx, -stimulus, -cycles).
2. `pe_sim asm ac97.s` (piped to a line count): 56 words.
3. `pe_sim asm ac97.s | head`: first words c000, 2000, 8100, as expected for set pins 0, wait 0 pin 0, pull.
4. check.py 0 2 (TASK.md example frames, r0 249): OK, first SYNC at edge 2, 42 pin changes.
5. Raw run of the same files: `pins 1 f9` (both low after cycle 0), SYNC up at `pins 257`, two cycles after falling edge 1 at 255, before falling edge 2 at 259. Output format confirmed: the value is the whole output register in hex.
6. check.py 1 1: OK.
7. check.py 2 12: OK.
8. check.py 3 5 200 0.0: OK.
9. check.py 4 12 299 0.999: OK.
10. check.py 5 3 250 0.5: OK.
11. check.py 6 7: OK.
12. check.py 7 1 299 0.93: OK.
13. check.py 8 12: OK.
14. check.py 9 4: OK.
15. check.py 10 6 200 0.07: OK.
16. check.py 11 3 211 0.95 (first period is 5 cycles): OK.
17. check.py 12 12 288 0.45: OK.
18. Deliberate fault to see the checker bite: run_args without `out_msb_first`. Result FAIL, "SDATA wrong at edge 59 (frame 0 bit 56)". Restored run_args.txt afterwards.

No bug was found in the firmware during testing; it passed on the first run.
The one mistake I caught was on paper, before writing code: I first assumed
the write after seeing rising edge n sets the level for falling edge n, but
the rise is seen at the very cycle of that falling edge, so the write is for
falling edge n+1. That only shifted the first SYNC from edge 1 to edge 2. I
also fixed a range in my own checker (the "low until the first frame" check
ended one bit too late) before its first use.

## Confusing or possibly wrong in isa.md

- `pe_sim run` prints `pins CYCLE XX`, which is the output register, not the
  pin levels: input pins show as 1 (`ff` at cycle 0) whatever is on them.
  isa.md says "whenever the pins' output changes", which is right, but the
  name `pins` and the "Pin levels" table near it make it easy to expect P0's
  level there.
- isa.md does not say in so many words that a `wait` whose condition already
  holds takes one cycle and that the instruction after it runs in the next
  cycle; I inferred it from "every instruction takes exactly one clock cycle
  ... unless it is explicitly waiting", and the simulation agreed.
- `in` is described as shifting "right into the ISR" and then, with
  `in_msb_first`, as shifting left; the first sentence is only the default
  case. Not used here.
- With `set_count = 2`, which bit goes to which pin is stated only in the
  general rule near the end ("bit k of the value on pin base + k"). It is
  correct; worth repeating under `set`.
- Nothing I found looked wrong.
