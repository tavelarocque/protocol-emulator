# Notes: AC '97 output firmware

## What I read

- `TASK.md`, all 199 lines.
- `isa.md`, all 638 lines, in four parts (1-160, 160-330, 330-489, 489-638).
- `pe_sim`, the whole file. It is a Python wrapper around `pe_sim.real`.
  Its docstring says this build lacks one feature, `FEATURE = "delay"`:
  any program whose words have nonzero delay bits is refused. I did not
  read `pe_sim.real` (a binary).
- `./pe_sim run x.s -help` (run 1).

Nothing outside the folder was opened. The wrapper makes a temporary
directory with Python's `tempfile`; to keep every write inside the folder I
ran it with `TMPDIR` pointing at a `tmp/` subfolder here, removed at the end.

## Design

Config (`run_args.txt`): `out_base=2,out_count=1` so `out pins` and
`mov pins` drive SDATA_OUT only; `set_base=1,set_count=2` so `set pins v`
drives SYNC from bit 0 and SDATA from bit 1 in one write;
`out_msb_first=1`, `threshold=16`, no autopull, no side-set. P1 and P2
push-pull, P0 left an input.

Timing. BIT_CLK's high phase is exactly 2 cycles and the synchroniser
delays it 2 cycles, so the thread first sees BIT_CLK high in cycle F, the
cycle in which the pin falls, and sees it high in F and F+1 only. The next
falls are at F+4 or F+5. A pin write made in instruction cycle c shows at
c+1, so writes in cycles F+1 and F+2 (showing at F+2, F+3) never touch a
falling edge, and what they write is carried by the next falling edge.

Every falling edge is one step: `wait 1 pin 0`, then A (at most two
instructions; pin writes only here), then `wait 0 pin 0`, then B
(bookkeeping). Let l be how late the `wait 1` is reached (0 = in or before
F, 1 = in F+1; 2 would miss the edge). Assuming the worst case, a run of
4-cycle periods:
- a write at position i of A needs l + i <= 2;
- A needs l + a <= 2 (else `wait 0` arrives when the next high is seen);
- the next step's lateness is max(0, b - 1) if l + a <= 1, else b.
So a step may hold up to 2 non-wait instructions in steady state, 3 once
if it then runs a cycle late. I checked every step of the program against
this by hand, and 5-cycle
periods only add slack.

Frame. Step W(j) writes frame bit j (W(-1) is the bit before the tag):
- W(-1): `set pins 1` (SYNC up, SDATA 0). W(0): `set pins 3`.
- W(1): `out pins 1` gives CTRL bit 8 (command) as tag bit 14, after
  `out null 7` in the previous step; then `out x 1` puts CTRL bit 7 (read)
  in X.
- W(2): tag bit 13 is command and not read. SDATA already holds the command
  bit, so only a read has to clear it: `jmp !x` over `set pins 1`.
- W(3): `set pins 3`; W(4): nothing; W(5): `set pins 1`; W(6..14): a
  counted loop; W(15): `set pins 0` (SYNC down).
- W(16): `mov pins x` (slot 1 bit 19 = read).
- One loop does slots 1 to 4: `out pins 1` per bit (without autopull, an
  out past 16 bits gives zeros, which pads every slot), then two idle steps
  that `pull` the next word and reload the counter. Slot 1 makes 17 outs
  (7 address bits, 10 zeros), slots 2 to 4 make 18 (16 bits, 2 zeros); the
  two idle steps carry the last two zeros with no write.
- The pull after slot 4 fetches the next frame's CTRL at W(94). With no
  words left it stalls forever with both lines low: no further SYNC pulse.
- W(96..253): nested idle loop, 18 + 5 x 28 = 158 steps; W(254) does
  `out null 7` and jumps to W(-1) of the next frame.

Start: `set pins 0` in cycle 0 (both lines low from cycle 1), `pull` the
first CTRL, `wait 0 pin 0` (passes in cycle 2, past the synchroniser's
reset-high), then jump to the W(254) step. Falling edge 0 is that step,
edge 1 the W(-1) step, so SYNC is first high at falling edge 2.

## pe_sim runs

1. `run x.s -help`: the run flags (config field names, `-stimulus`).
2. `asm ac97.s`: 62 words, assembled cleanly.
3. `asm ac97.s` again in the same command line (I piped it twice by
   accident; counted). Encodings looked right (`wait 1 pin 0` = 2100,
   `mov pins, x` = a080, `out null, 7` = 6187).
4. TASK.md's two example frames, random BIT_CLK alignment: OK. Decoding
   the lines myself gave tag F800, slots 02000 08080 12340 EDCB0, then
   D800, FC000 00000 7FFF0 80000, all other slots 0, SYNC high at
   relative edges 0 to 15: exactly the table in TASK.md.
5. to 16. Twelve random runs (1, 12, 3, 5, 7, 2, 9, 11, 4, 6, 8, 10
   frames, random write/read/no-command frames and samples, random first
   rise and 5-period alignment): all OK.
17. 12 frames, every period 4 cycles (stricter than the spec): OK.
18. 3 frames, every period 4 cycles: OK.
19. 12 frames, a 5-cycle period every 14th: OK.
20. 12 frames, a 5-cycle period every 15th, other phase: OK.
21. 6 frames, every other period 5 cycles: OK.
22. 6 frames, every period 5 cycles: OK.
23. to 26. Four more random runs (12, 1, 7, 12 frames; first rise at 274,
   297, 204, 211): all OK.

26 runs in all. The smallest distance between a change of SYNC or SDATA
and a falling edge, over all runs, was 1 cycle, as the design expects.

To check runs I wrote a helper, `check.py`, in the folder: it generated
BIT_CLK by the TASK.md rules (rising edges at floor(r0 + k x 4.069 +
phase), high for 2 cycles) and random frames, then from pe_sim's `pins`
lines checked: no change of P1/P2 in a cycle where BIT_CLK falls, both low
by cycle 40, the first SYNC edge in 1..255, SYNC high at exactly edges e to
e+15 of each frame and nowhere else, SDATA equal to the expected 256 bits
of each frame and 0 at every other edge, and SYNC changing exactly 1 + 2F
times. I tested the checker by hand-editing a run's output (moving one
change onto a falling edge, deleting one change): it reported both. I
deleted it and all test files at the end so the folder holds only what
TASK.md asks for.

## Mistakes

- None found in the program by any run. The only slip was running
  `pe_sim asm` twice in one command (run 3).
- No rule broken that I know of.

## Program length

62 instructions (one page, so no `set page` or `.page` is needed).

## Confusing or possibly wrong in isa.md

- isa.md never mentions a delay field: it says the bits of `side` not used
  by side-set are reserved and must be 0. The `pe_sim` wrapper's docstring
  describes those low bits as "delay", and this build refuses them. So the
  document and the tool disagree on what those bits are (my program does
  not use them either way).
- The wrapper's flag table for `run` does not list `-stimulus`, so a
  command line with `-stimulus` is forwarded to `pe_sim.real` untouched
  and the delay check is skipped. Harmless here, but the check is not
  applied to the very runs the test makes.
- `wait pol pin n`: it is not said whether n is an absolute pin or counted
  from `in_base`. I left `in_base` at 0 so both readings agree.
- `in`: "shifts count bits right into the ISR" and "Bits arrive least
  significant bit first" are hard to picture together (where a new bit
  lands). I did not use `in`.
- "What is not set is 0 or off, except ... threshold 8": with
  `out_msb_first` and no autopull the threshold does not affect what `out`
  gives, but I set 16 to be explicit.
- Everything I relied on (2-cycle synchroniser with reset-high, writes
  showing at c+1, `out` past the word giving zeros, `pull` stalling on an
  empty FIFO) behaved as written.
