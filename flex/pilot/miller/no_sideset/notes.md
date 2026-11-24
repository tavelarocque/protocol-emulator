# Notes: Miller transmitter

## What I read
- `TASK.md` and `isa.md`, both in full, once each. Nothing else. I did not
  open `pe_sim`, did not look outside this directory, did not use the web.
- `./pe_sim run x.s -help` for the run flags.

## Files in this directory
- `miller.s`, `run_args.txt`, `notes.md`: the hand-in.
- `miller_v2.s`, `run_args_v2.txt`: identical copies of the hand-in.
- `miller_v1.s`, `run_args_v1.txt`: my first working version (39
  instructions, no timed wait). Kept as a fallback, also passes my checks.
- `check.py`: my own checker. It builds a run of messages, calls `pe_sim`
  exactly as TASK.md says the test will (`./pe_sim run PROG -tx FILE -cycles N`
  plus the run_args line, N by the TASK.md formula), reads the `pins` lines,
  and compares every P0 transition with the ideal Miller place, the gaps
  (400 to 20000 cycles), the first fall, and stray transitions.
- `runs.log`: one line per `pe_sim` run made after the first three.
- `t1.txt`, `tx_test.txt`: TX word files from testing.

## Design
Clock divider 5, so one tick is 5 cycles, a bit is 20 ticks and half a bit
is 10. Every delay then fits in the 4-bit delay field, and every transition
lands on a tick, so there is no error to add up. Measured error in every
test: 0 cycles.

The chip has no "toggle pin" instruction and no jump on a pin level. Two
ways round that:
- v1: keep the level in Y, `jmp !y` to choose `set pins, 0` or `set pins, 1`,
  and keep "the previous bit" in the program position (two copies of the
  fetch code, one for after a 0 and one for after a 1). 39 instructions.
- v2 (handed in): `wait 0 pin 0 timeout` with `timeout=0` is a jump on P0:
  it falls through when P0 reads low and jumps to `timeout_vector` at once
  when it reads high. That frees Y to hold the previous bit, so one copy of
  the fetch code serves. 27 instructions.

v2 in outline: `pull` the first word, force a transition (start bit, treated
as a 0 after a 0), then per bit: `out x, 1`; a 1 waits to mid-bit and
toggles; a 0 toggles at once if Y = 0, else does nothing. `jmp !osre`
(threshold 8) finds the end of a byte, the ninth `out x, 1` gives the
last-byte flag. With the flag set, the end bit is a 0 by the same rule, then
a delay loop of 112 ticks, then `pull` again, which stalls for ever when the
words run out, so nothing moves the line after the last message.
The start/end/data transitions all go through one toggle site, told apart
afterwards by (X, Y): X=0 a boundary transition, X=1,Y=1 a mid-bit one,
X=1,Y=0 the end bit's.
Code reached with Y=0 runs 2 ticks earlier than with Y=1, because after a
mid-bit transition there are only 10 ticks to the boundary and the
dispatch + fetch + decision path for a boundary transition needs more. The
`one` path evens this out (`jmp !y, o0`).

Gap between messages (end of end bit to next start): 495 or 505 cycles.
First fall: cycle 586.

## pe_sim runs: 30 in total
1. `run x.s -help` (flags).
2. `asm miller.s`: first draft assembled first time. I had guessed `;` for
   comments and `[n]` for the delay; both guesses were right.
3. `run` with the TASK.md example (0x0116, 0x00DE, 0x00AD, 0x01BE). Read the
   output by hand. **Mistake found:** the end bit's transition of message 1
   came at 905 instead of 900. I had a `nop [11]` after a `jmp`, one tick
   too many (the jump's own tick was not counted). Fixed by putting the
   delay on the jump and deleting the nop. Everything else was on time.
4. `asm` of the fixed v1 (39 instructions).
5. to 12. `check.py` on v1: seeds ex, ff, long, one, one1, 1, 2, 3. All OK,
   worst error 0.
13. `asm miller_v2.s` (27 instructions).
14. to 24. `check.py` on v2: ex, ff, long, one, one1, 1 to 6. All OK first
   time, worst error 0. This also confirmed the timeout behaviour I had
   assumed from isa.md: with timeout 0 the wait costs one tick on both
   outcomes.
25. to 30. `check.py` on the final `miller.s` + `run_args.txt`: ex, ff,
   long, 7, 8, 9. All OK.

Test sets: `ex` is the TASK.md example; `ff` is 0xFF, 0x00, 0xFF 0xFF,
0x00 0x00, 0x55, 0xAA, 0x01, 0x80 as eight messages; `long` is 8 messages of
32 random bytes; `one` a single 0x00; `one1` 32 bytes of 0xFF; numeric seeds
are 1 to 8 random messages of 1 to 32 bytes with extra 0x00 and 0xFF.

## Rule slips
None that I know of. All reads and writes were in this directory; `pe_sim`
was run only as `./pe_sim` from here.

## What I could not check
- The acceptance test itself. `check.py` is my own reading of TASK.md.
- The format of the test's `-tx` file. I used `0x0116` style lines; if the
  test writes another number format that is the simulator's business, not
  the program's.
- Behaviour with a slow host. TASK.md says the FIFO is always refilled. If a
  `pull` inside a message ever stalled, the bit after it would be late.

## Program length
27 instructions (`miller.s`). The fallback `miller_v1.s` is 39.

## Confusing or wrong in isa.md
1. **Assembler syntax is not given.** isa.md promises "the assembler syntax"
   (TASK.md says so) but never says how a delay is written (`[n]`), what the
   comment character is, how labels are written, or the exact form of
   `wait` (I guessed `wait 0 pin 0 timeout` from the table heading). The
   only examples are `l: jmp x-- l` (no comma) and prose. My PIO-style
   guesses worked, but it was luck.
2. **No way to toggle or branch on a pin is described**, and the one that
   works is not presented as such. A line code like Miller needs "invert the
   pin". There is no invert, no `jmp pin`. The `wait ... timeout` with
   `timeout = 0` does the job, but the text presents it only as a fail-safe.
   A sentence saying so, and stating plainly that the wait costs one tick
   whether it passes or times out at T = 0, would have saved the whole first
   version.
3. `pe_sim run -help` lists `sideset_base` and `sideset_count` in the thread
   configuration. isa.md never mentions side-set: no field in the encoding,
   no syntax. I did not use or probe it.
4. Whether an instruction's delay applies when a `jmp` is taken, not taken,
   or both is not said. I assumed both (it is "after the instruction
   completes") and the timing confirmed it.
5. Reset values of X, Y, OSR, its shift count and PC/`start` default are not
   stated. I set everything before use and rely on `start` defaulting to 0.
6. `out` without autopull on an "empty" OSR (count at threshold): not said
   whether it keeps shifting. It does (I use the ninth bit), but the text
   only describes the autopull case.
7. The `-mode` flag syntax (`0=pp`) and the meaning of the `pins CYCLE HEX`
   output lines (is CYCLE the first cycle of the new level?) are only in the
   help text or nowhere. It does not matter for relative timing.
8. The timeout sentence is hard to read: "stalls for T cycles at most, and
   if the pin is still wrong, jumps on the cycle after (with T = 0, at
   once)". With `clkdiv` these are ticks, which is said only in the config
   table.
