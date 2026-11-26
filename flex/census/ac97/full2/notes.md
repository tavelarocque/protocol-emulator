# Notes: AC '97 output firmware

## What I read
- `TASK.md`, in full (one read).
- `isa.md`, in full, in four parts (lines 1-170, 170-340, 340-500, 500-644).
- `./pe_sim run x.s -help` output (the flags list).
Nothing outside this folder was opened, listed or searched.

## Design

Configuration (`run_args.txt`): `out_base=2, out_count=1` (SDATA_OUT for `out pins` and
`mov pins`), `set_base=1, set_count=2` (`set pins` value bit 0 = SYNC, bit 1 = SDATA),
`threshold=16`, `out_msb_first=1`, `in_msb_first=1`; P1 and P2 push-pull, P0 left an input.
No side-set, no autopull, no clock divider.

Timing. The thread sees P0 two cycles late. BIT_CLK rises at r and falls at r+2, so a
`wait 1 pin 0` that is already stalling completes in cycle w = r+2, the very cycle of the
falling edge. A pin write in cycle w+1 or w+2 shows from w+2 or w+3, never a falling-edge
cycle (the next fall is at w+4 or w+5), and it is the level carried by the next falling
edge. The thread sees BIT_CLK high only in w and w+1, so the next `wait 1 pin 0` may be
reached anywhere from w+2 to w+4 and will complete exactly on the next falling edge.
So the whole program is a chain of blocks: one `wait 1 pin 0` (= one falling edge), then
at most 3 cycles of work, with pin writes only in the first two. No `wait 0` is needed
inside the stream (only once at start, to get past the two reset cycles that read high).
Loops of 2 instructions (`wait; jmp x--`) and 3 (`wait; out; jmp x--`) obey this.

Frame. Block B(t) waits for edge S+t-1 and sets the level for edge S+t (S = first SYNC-high
edge of the frame; frame bit t = 1..256 is carried by edge S+t).
- B(0): `set pins 1` (SYNC up, SDATA 0), then `out null 7` drops CTRL bits 15..9.
- B(1): `set pins 3` (tag 15), `out x 1` (x = command bit 8), `out y 1` (y = read bit 7).
- B(2): `mov pins, x` (tag 14). B(3): tag 13 = write = (x != y) because CTRL bits 8,7 are
  only 00, 10 or 11; in the write case SDATA is already 1, else `mov pins, null`.
- B(4): `set pins 3` (tag 12), B(5) nothing (tag 11), B(6) `set pins 1` (tag 10 = 0),
  10 waits, B(16) `set pins 0` (tag 0 and SYNC low). SYNC is high at edges S..S+15.
- B(17): `mov pins, y` (slot 1 bit 19 = read flag); B(18..25): 8 `out pins 1`, which give
  address bits 6..0 and then a 0 (an OSR with its 16 bits out gives zeros); `pull` DATA;
  11 waits for the rest of slot 1.
- Three 20-bit slots (DATA, LEFT, RIGHT) in one loop on y: 16 `out pins 1`, then pad bit 1
  (`out pins 1` gives 0, `pull` the next word, `set x 15`), pads 2 to 4 are bare waits.
  The pull in slot 4 takes the next frame's CTRL; after the last frame it stalls forever
  with both lines low, so no further SYNC pulse starts.
- Tail: 160 waits (x = 159, a constant built once in the ISR at start with
  `in x 3; in x 5`, since `set` only takes 0..31), then B(0) of the next frame.
- Start: `set pins 0` at cycle 0 (both low from cycle 1), build ISR = 159, `pull` CTRL,
  `wait 0 pin 0`, then 8 waits (edges 0..7), so the first SYNC is at edge 8.

## pe_sim runs (32 in total)
1. `run x.s -help`: printed the flag list.
2. `asm ac97.s | wc -l`: 55 words.
3. `asm ac97.s | head`: first words, assembler OK.
4. `check.py 1 2` (my harness: random words and a random BIT_CLK by TASK.md's rules, one
   pe_sim run, then checks every change against falling-edge cycles, low by cycle 40, SYNC
   and SDATA at every falling edge against the expected frames). Showed SYNC high for only
   15 edges and data one edge early from tag 0 on. Mistake: the tag 9..1 wait loop had 9
   waits, but B(16) needs its own wait too (10). Fixed `set x, 8` to `set x, 9`.
5. `check.py 1 2`: OK.
6-25. `check.py` seeds 2 to 21, 1 to 12 frames, random first rise and 5-cycle alignment:
   all OK (first SYNC at edge 8 each time).
26. `check.py -1 2`: the exact 8-word example of TASK.md, checked against its slot table: OK.
27. first rise at 299, phase 0.99, 12 frames: OK.
28. first rise at 200, phase 0.0, 12 frames: OK.
29. first rise 250, phase 0.93, 1 frame: OK.
30-32. stress with other mixes of 4 and 5-cycle periods (average 4.5, 4.93, and 4.0 i.e.
   never 5): OK.

Helper file left in the folder: `check.py` (my test harness), plus its last generated
`t_stim.txt` and `t_tx.txt`; they are not part of the program.

## Program length
55 instructions (55 words from `pe_sim asm`), all in page 0.

## Confusing or possibly wrong in isa.md
- `wait` timing is not stated exactly: whether a wait that sees the level in cycle t
  "executes" in t (so the next instruction runs in t+1). I assumed so and the runs agree.
- "Without autopull, an `out` past that point still shifts ... then zeros": I relied on
  this for the slot padding; it behaved as written.
- The `in` direction without `in_msb_first` ("shifts count bits right into the ISR") does
  not say where in a 16-bit ISR the bits land; I avoided the question with `in_msb_first`.
- isa.md mentions a 40 MHz clock in the sampler section while the task runs at 50 MHz; not
  relevant here.
- `pe_sim run` prints the output register, not pin levels (P0, an input, shows as 1 in
  `pins` lines); the doc says "pins' output", which is consistent but easy to misread.
No rule broken that I know of.
