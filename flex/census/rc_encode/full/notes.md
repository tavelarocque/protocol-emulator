# Notes: PT2262 encoder firmware (rc_encode.s)

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- The output of `./pe_sim run x.s -help` (run 1).
- Nothing outside this folder.

## Design

The key choice is `clkdiv=400`: thread 0 then takes one tick every 400
cycles, so one tick is exactly one alpha (40 us). Every PT2262 time is a
whole number of alpha, so every edge falls exactly on a tick and there is no
rounding error that could add up along a frame. Delays and loops count ticks.

Data: `threshold=12` and `autopull=1`. Each 16-bit word gives six trits of 2
bits, least significant first (the default shift direction), via
`out x, 2`. After the sixth `out` the OSR has shifted 12 bits, counts as
empty, and autopull refills it in the same tick, so there is never a gap
between words or between frames. A frame is counted as 12 trits with `y`
(`set y, 11` then `jmp y--`), so the firmware never has to know which word
it is in. When the host's words run out, the next `out x, 2` (at the start
of what would be the next frame) waits for a word forever with the line
low, so no stray edge follows the last sync bit.

Trit decode without a second register: `jmp x--, nz` falls through for
'0' (x = 0). For '1' (x = 1) and 'f' (x = 2) it jumps and leaves x = 0 or 1,
so `jmp !x, one` then separates '1' from 'f'.

Per trit, ticks relative to the rise of its first pulse (a `set pins` that
runs at tick k makes the edge at tick k, plus the constant 1-cycle
write delay the simulator shows):

- tick -2: `out x, 2`; tick -1: `jmp x--, nz`
- '0': rise 0, fall 4, rise 16, fall 20, then low with delay to 28
- 'f': rise 0, `jmp !x` at 1, `nop [1]`, fall 4, rise 16, fall 28
- '1': rise 0, `jmp !x` at 1, `nop [9]`, fall 12, jump at 15 to the shared
  second long pulse of 'f' (rise 16, fall 28)
- every path: tick 29 `jmp y--, trit` (lands on `out` at 30 = next trit's
  -2), tick 30 `jmp sync` when the frame's 12 trits are done.

Sync bit (frame ticks): `set y, 11` at 383, rise at 384, fall at 388
(`set pins, 0 [15]`), `set x, 12` at 404, loop `jmp x-- [7]` 13 times
(405..508), `jmp trit` at 509, so the next frame's `out` is at 510 and its
first rise at 512.

Start: `set pins, 0` in tick 0 (P0 low at cycle 1), `set y, 11`, `set x, 22`
and a 23 x 8 tick wait. The first `out` spends one extra tick fetching the
first word (the OSR starts empty), so the first rise is at tick 190, cycle
76001, the middle of the allowed 50000..100000 window.

`run_args.txt`: `-config clkdiv=400,threshold=12,autopull=1 -mode 0=pp`
(set_base 0 and set_count 1 are the defaults).

## pe_sim runs (6 in total)

1. `pe_sim run x.s -help`: listed the flags and config field names
   (`clkdiv`, `threshold`, `autopull` among them).
2. `pe_sim asm rc_encode.s`: assembled without error, 29 words. (Before
   this I had fixed by reading, not by a run, an off-by-one I wrote in the
   sync tail: a `set x, 12 [1]` plus a `jmp trit` would have put the next
   frame one tick late; changed to `set x, 12` with no delay.)
3. `pe_sim run` on the TASK.md example 0x0018, 0x0481, 324800 cycles:
   `pins 0 ff` (reset level), `pins 1 fe` (P0 low at cycle 1), first rise
   76001, then rises and falls at +1600, +6400, +8000, +12800, +14400,
   +19200, +24000, matching the example table.
4. `check.py t1.txt` (example word, one code word): 50 edges, worst error
   0 cycles, OK.
5. `check.py t2.txt` (8 random code words, 16 words): 400 edges, worst
   error 0, last edge 1664801, nothing after it up to the end of the run,
   OK.
6. `check.py t3.txt` (twelve '1's, twelve 'f's, twelve '0's, the
   example): 200 edges, worst error 0, OK.

`check.py` (in this folder) runs pe_sim once with the task's cycle count
and `run_args.txt`, checks that the first change is to low by cycle 100,
that the first rise is in 50000..100000, then compares every edge with
the ideal waveform placed from the first rise and frames exactly 204800
cycles apart (so it also checks frame spacing and the count of edges, which
catches stray edges). The test files t1.txt, t2.txt, t3.txt are also left
here.

## Mistakes found

- The off-by-one in the sync tail described under run 2, found by
  re-counting ticks before the first run.

## Program length

29 instructions.

## Confusing or possibly wrong in isa.md

- The width of `clkdiv` is not stated anywhere. I relied on 400 fitting;
  the simulator accepted it and the timing came out exact, but on the
  hardware it depends on the register width, which isa.md does not give.
- isa.md says `pe_sim run` prints `pins CYCLE XX` "whenever the pins'
  output changes", but it also prints a line at cycle 0 (`pins 0 ff`, the
  reset value) that is not a change.
- How long the first `out` with autopull takes on an empty OSR ("spends
  that tick fetching a word") is clear only on a careful read; the run
  confirmed it costs exactly one extra tick.
- The default `threshold` is 8 in the simulator (stated) but isa.md's
  machine-state section speaks of the OSR "count stands at threshold" at
  start without saying a default; not wrong, just spread over two places.

No rule broken that I know of: I read and wrote only inside this folder.
