# Notes: Miller transmitter

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- The output of `./pe_sim run miller.s -help`.
- Nothing else. I did not open, list or search anything outside this
  directory, did not read `pe_sim` itself, and did not use the web.

## Design

The firmware is a fixed-rate level streamer, and the Miller coding is done on
the host. I want to be plain about that: `miller.s` knows nothing about
Miller code. TASK.md says "You decide what the words mean", so I chose the
word format that makes the firmware trivially exact.

- Each TX word holds 16 line levels, one per half bit (5 us = 50 cycles),
  the first level in bit 0 (OUT shifts least significant bit first by
  default).
- The program is two instructions, `out pins, 1` then `jmp` back to it.
- `clkdiv = 25`, so the thread ticks once every 25 cycles and the loop is
  2 ticks = 50 cycles: exactly one half bit per `out`. This build has no
  delay field, and `set x, n` only reaches 31, so a counted loop would have
  needed two nested loops; the divider replaces all of that.
- `autopull = 1`, `threshold = 16`: the 16th `out` of a word refills the OSR
  from the TX FIFO in the same tick, so word boundaries cost no time.
- `out_base = 0`, `out_count = 1`, P0 push-pull.
- When the words run out, `out` stalls on the empty OSR and P0 keeps its
  level, which is what "leave the line as it is" asks for.

`host.py` builds the level stream:

- 16 half bits of high first (800 cycles of idle before the first fall).
- Per message: start bit 0, the bytes least significant bit first, end bit
  0. The level toggles at the start of bit 0 always, in the middle of every
  1, and at the start of a 0 that follows a 0.
- 16 half bits holding the level between messages (an 800 cycle gap; the
  task allows 400 to 20000).
- The last word is padded with the final level.

Because every transition comes from an `out` on a fixed 50-cycle grid, the
timing error is zero by construction and cannot add up along a message.

Cost of this choice: 266 words for the largest input (8 messages of 32
bytes), where a firmware-side encoder would need about 130. It also depends
on the host keeping the FIFO fed (12,500 words per second); TASK.md says not
to worry about that in this test. An underrun in a message would stretch a
level and corrupt it.

## pe_sim runs (14 in total)

1. `./pe_sim run miller.s -help`: learned the flags (`-config k=v,...`,
   `-mode P=pp|od|in`, `-tx FILE`, `-cycles N`).
2. `./pe_sim run miller.s -tx t1.txt -cycles 41000 -config clkdiv=25,autopull=1,threshold=16,out_base=0,out_count=1 -mode 0=pp`
   with `encode([[0x16]])`. Output: pin changes at 826, 926, 1076, 1176,
   1376, 1526, 1626, 1726. Relative to the first: 0, 100, 250, 350, 550,
   700, 800, 900, exactly the table in TASK.md. Worked first time.
3. to 13. Eleven runs through `check.py` (each logged in `runs.log`), all OK
   with a worst edge error of 0 cycles: `example16`, `ff`, `zeros_ones`
   (5 messages of all 0x00 or all 0xFF), `max:1` (8 random messages of 32
   bytes, 266 words), `max_zero`, `max_ff`, `lengths:2` (lengths 1 to 8),
   `random:3`, `random:4`, `one32:5`, `aa55`. N was computed as the task
   says (20000 + 20000 per message + message lengths).
14. `./pe_sim asm miller.s`: prints `6001`, `0000`, so 2 words.

`check.py` does not reuse the encoder. It takes the transition times pe_sim
prints, splits them into messages on silence, checks every edge is within 2
cycles of its 50-cycle slot counted from the message's first edge, rebuilds
the bits from where the edges are (middle = 1), checks the start-of-bit edges
follow the 0-after-0 rule, checks the bit count is 8n + 2, the gaps are 400
to 20000, P0 is high at cycle 0, the first fall is before 20000, there is no
edge after the last message, and the decoded bytes equal the input.

## Mistakes

None found in the firmware or the encoder: the first simulation matched the
example and every later case passed. Things I guessed that happened to be
right: the pin is named `0` in `-mode 0=pp`, and boolean config values are
written `autopull=1`.

What my testing does not cover: the real acceptance decoder (I only have my
own reading of the rules in TASK.md), and a slow host.

## Rule slips

None that I know of. I read only `TASK.md`, `isa.md` and pe_sim's own
printed output, wrote only in this directory, and ran pe_sim only as
`./pe_sim` from here. Extra files I created here: `check.py`, `runs.log`
(the log of runs 3 to 13), and three things I deleted afterwards: the scratch
TX files `t1.txt` and `tx_check.txt`, and Python's `__pycache__/`.

## Result

- Program length: 2 instructions.
- Run arguments: `-config clkdiv=25,autopull=1,threshold=16,out_base=0,out_count=1 -mode 0=pp`
- Host word format: each 16-bit word is 16 line levels for P0, one per half
  bit (50 cycles), bit 0 first. The stream is 16 half bits high, then the
  Miller-coded messages with 16 half bits of unchanged level between them,
  then the last level repeated to fill the last word.
- Observed timing: the first `out` executes at cycle 25 (the tick at cycle 0
  is spent fetching the first word), and its level shows from cycle 26. The
  first fall is at cycle 826 for every input.

## Confusing or missing in isa.md

- Its first line says this build has no per-instruction delay field, but the
  rest of the document never describes such a field, so a reader of this
  file alone cannot tell what was removed. The `side` field is described as
  holding only side-set values.
- The `-config` value syntax is not documented anywhere (how to write a
  boolean such as `autopull`, whether numbers may be hex), and neither is
  how to name a pin in `-mode`. The help text lists the keys only.
- The format of what `pe_sim run` prints (`pins CYCLE HEX`) is not
  documented, nor whether the cycle is the one in which the write executes
  or the one from which the new level shows. From the numbers it is the
  latter (execute at 825, printed 826), which fits "pin writes take effect
  at the end of the cycle".
- It does not say the OSR counts as empty at reset. It does, as observed:
  the first autopull `out` spent one tick fetching.
- It does not say outright that a stalled `out` (autopull, empty FIFO)
  leaves the pins alone. It does, as observed, and I rely on it.
- "An `out` that finds the OSR empty spends that tick fetching" says "tick",
  the autopull refill says "cycle". With `clkdiv` above 1 the two differ; I
  assumed both mean a tick of the thread, and the behaviour fits.
- Nothing I found to be wrong.
