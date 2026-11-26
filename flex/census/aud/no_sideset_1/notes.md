# Notes: AUD branch trace receiver

## What I read

- `TASK.md`, in full (one read, 153 lines).
- `isa.md`, in full, in three parts (lines 1 to 200, 200 to 409, 410 to 607).
- The output of `./pe_sim run x.s -help` (run 1 below).
- I listed the folder once with `ls -la` and counted lines with `wc -l`.

Nothing outside the folder was opened, listed or searched. My test helper
(`gen.py`) and its stimulus files were written inside the folder and deleted
before hand-in, so the folder holds only the hand-in plus the given files.

## Design

Pins: P0 AUDCK, P1 nAUDSYNC, P2..P5 AUDATA0..3, all inputs. Config:
`start=16` (the `main` label), `in_base=2` (so `in pins, 4` reads the nibble
with AUDATA0 as bit 0), `threshold=16`. No `-mode` flags: every pin stays an
input, the default.

Edges: every nibble is taken with `wait 0 pin 0` then `wait 1 pin 0`; the
instruction after the second wait reads the lines one cycle after the rising
edge is seen. All lines go through the same 2-cycle synchroniser, so this
reads the value at the pin about 1 cycle after the real edge, well inside
the 25-cycle stable window. Starting with `wait 0` also skips the two cycles
after reset in which the synchroniser reads every pin as high.

State between addresses: the low half L of the previous destination is kept
in the ISR (16 bits, as left by the last `in x, 16`) and the high half H in
Y. At reset both are 0, which is the "previous address 0" the sheet asks for.

Decoding a sync-high edge: `mov osr, pins`, `out null, 2` drops AUDCK and
nAUDSYNC, `out x, 2` gives AUDATA1..0. For commands 10ww that is the width
code ww; a chain of `jmp !x` / `jmp x--` dispatches 0, 1, 2. Code 3 is
either 0xB or the idle 0x3, so one more `out x, 2` gives AUDATA3..2 (2 for
0xB, 0 for idle) and `jmp !x main` drops idles. I trust the sheet that only
0x3 and 0x8..0xB appear with nAUDSYNC high, and that the state machine
always knows when sync is low, so nAUDSYNC itself is never tested.

4, 8 and 16-bit addresses share one routine: X = nibbles - 1 (0, 1, 3),
OSR = old L, ISR cleared. Each nibble: `in pins, 4` into the ISR (it shifts
right, new bits at the top) and `out null, 4` drops the matching nibble of
old L from the OSR. Then a merge loop, while `!isrf`, moves 4 bits at a time
from the OSR to the ISR through X (`out x, 4`, `in x, 4`). The ISR then
holds the new L with count 16, and the tail does `mov x, isr`, `push` (bits
15..0), `in y, 16`, `push` (bits 31..16), `in x, 16` (L back in the ISR) and
falls into `main`.

32-bit addresses: read nibbles into a cleared ISR until it is full (`jmp
!isrf`, no counter needed), keep that L in X, clear the ISR, read four more,
put them in Y as the new H, clear the ISR, `in x, 16`, and join the tail.

Timing: the longest work after an edge is the 4-bit path (three merge steps
plus the tail), 22 cycles from the edge to the second push, so both words
are pushed within 22 cycles of the edge that carries the last nibble (limit
200) and the thread is back at `wait 0` well before the next edge 50 cycles
later, which can be the next command with no idle in between.

## pe_sim runs (29 in all)

1. `pe_sim run x.s -help`: printed the flags. The config list includes
   `sideset_base` and `sideset_count`, which `isa.md` never mentions.
2. `pe_sim asm aud.s`: 46 words, no errors. Checked a few encodings by hand
   (`wait 0 pin 0` = 0x2000, `wait 1 pin 0` = 0x2100).
3. Random test, seed 1, 3 addresses (stimulus from my helper): all 6 RX
   words right, worst push 22 cycles after the last nibble's edge. Showed
   that `rx` prints the word in decimal and that `pins 0 ff` is printed
   once (the output register's reset value; no pin is an output).
4. The exact example from `TASK.md`, first edge at cycle 30: RX 0x1234,
   0x0C00, 0x125A, 0x0C00, 0x1257, 0x0C00 at cycles 640/642, 796/798,
   1000/1002; all correct and inside the window (details below).
5. to 24. Twenty random runs, seeds 100 to 119 (1 to 40 addresses of
   random widths and values, 4 to 8 leading idles, 0 to 20 idles between,
   first edge 30 to 79): all OK, every word right, worst delay 22 cycles.
25. Seed 200, 40 addresses, first edge at 30, no idles between addresses:
    OK.
26. Seed 201, 40 addresses, first edge at 79, no idles between: OK.
27. Seed 202, 1 address, first edge at 30: OK.
28. Seed 203, 40 addresses, first edge at 55, 20 idles between each: OK.
29. Seed 204, 1 address, first edge at 79: OK.

In run 4 the edge times are 30 + 50 j; the three final nibbles are edges
12, 15 and 19, so cycles 630, 780 and 980. The pushes come 10 cycles after the edge for the
32-bit address, 16 after for the 8-bit one and 20 after for the 4-bit one.

No mistakes were found by the runs: the first version of the program passed
every test, so it was not changed after run 2 except for a comment (I first
wrote `start=17` in a comment, counted the words and corrected it to 16
before any run used it).

## Things in isa.md that were confusing or seem wrong

- `pe_sim run -help` lists `sideset_base` and `sideset_count` config
  fields that `isa.md` does not describe anywhere; there is no side-set
  field in the instruction encoding either.
- `push` "sends the bits shifted in since the last push, right-justified"
  does not say what happens after `mov isr, ...`, which resets the count to
  0: does a following `push` send 0 bits or the whole register? I avoided
  depending on it by only pushing an ISR filled by `in` to 16 bits.
- There is no jump on a pin level (no `jmp pin`), so testing nAUDSYNC or a
  nibble value means reading `pins` through the OSR and comparing in X/Y,
  with `set` limited to 5-bit immediates (the raw pin byte of a command,
  e.g. 0x23 for 0x8, cannot be loaded as a constant).
- With only X, Y, ISR and OSR, holding a 32-bit previous address plus a
  counter is tight; I used the ISR's own fill count (`!isrf`) as a loop
  condition to save a register. It works as documented.
- The note that `in src` with a right-shifting ISR puts new bits "at the
  top" is only implied ("shifts count bits right"); runs confirmed it.

## Program length

46 instructions (one page, no `.page` needed).
