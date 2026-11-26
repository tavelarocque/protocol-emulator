# Notes: AC '97 output firmware

## What I read

- `TASK.md`, in two parts (lines 1 to 100, 100 to 199).
- `isa.md`, in four parts (1 to 150, 150 to 310, 310 to 460, 460 to 607).
- `pe_sim` itself: it is a Python wrapper (about 400 lines) around `pe_sim.real`.
  Its docstring says this build of the chip lacks side-set: a program that
  declares `.side_set n` with n > 0, or a `-config` with `sideset_count` above
  0, is refused. I read the whole wrapper to learn that. I did not open
  `pe_sim.real` (a binary), and nothing outside the folder.

## Design

Pins: P0 BIT_CLK input (default mode), P1 SYNC and P2 SDATA_OUT push-pull.
`set pins` covers P1 and P2 (`set_base=1, set_count=2`, value bit 0 = SYNC,
bit 1 = SDATA), so one instruction sets both lines where SYNC changes.
`out pins` and `mov pins` cover P2 only (`out_base=2, out_count=1`). OUT is
MSB first, threshold 16, no autopull.

Timing. The thread sees P0 two cycles late. BIT_CLK high phases are exactly 2
cycles, so a falling edge comes 2 cycles after each rising edge and the next
falling edge 6 or 7 cycles after it. Reacting to a falling edge is too late
(seen 2 cycles later, and with a 4-cycle period the earliest possible write
would land exactly on the next falling edge). So every bit is one "block":
`wait 1 pin 0` (completes in cycle R+2 for a rise at R) followed by 1 to 3
instructions. A write by the 1st or 2nd instruction after the wait shows at
R+4 or R+5: after the falling edge at R+2, before the next at R+6 or R+7. So
each block sets the level for the next falling edge, with at least one
cycle of margin on each side, whatever the 4/5 pattern. The next wait must be
2 to 4 instructions after the previous one (it must see the low phase first,
and must be waiting by the time the next high is seen). Every block in the
program obeys this; branches were checked on both paths.

Frame, in blocks (e = edge where SYNC first is high in the frame):
- P1, P2 (edges e-2, e-1): `pull` CTRL, `out null,7`, `out x,1` (x = command
  bit), `out y,1` (y = read bit). If the host has no more words the pull
  waits forever with SYNC and SDATA low, so no further SYNC pulse begins.
- e: `set pins 1` (SYNC up, SDATA 0). e+1: tag 15 = 1. e+2: `mov pins, x`
  (tag 14 = command). e+3: tag 13 = write, which is exactly `x != y`
  (none 0/0, read 1/1, write 1/0), via `jmp x!=y`. e+4: tag 12 = 1, e+5 held,
  e+6: SDATA 0, e+7..e+15 held by a 9-pass loop, e+16: `set pins 0` (SYNC
  down, tag bit 0).
- Slot 1: bit 19 = `mov pins, y`, then 19 `out pins,1`: address bits 6..0 left
  in the OSR, then zeros, since an `out` past the end of the word shifts zeros.
- Slots 2 to 4: loop of 3: `pull` then 20 `out pins,1` (16 bits then 4 zeros).
- Slots 5 to 12: SDATA already 0; one block + a 12 x 13 nested wait loop
  (156 blocks) cover e+97..e+253, then `jmp P1`; P1 and P2 are e+254 and
  e+255, and the next frame's SYNC rises at e+256.
- Start: `set pins 0` in cycle 0 (both lines low from cycle 1), then
  `wait 0 pin 0` to get past the two cycles in which P0 reads high after
  reset. The first rising edge is then consumed by P1, so the first SYNC is
  high at falling edge 3.

Program length: **51 instructions** (one page, no `.page` needed). No
side-set, delays are not used either.

`run_args.txt`: `-config set_base=1,set_count=2,out_base=2,out_count=1,out_msb_first=1,threshold=16 -mode 1=pp -mode 2=pp`

## Test harness

`work/check.py` (my own helper, kept in `work/` beside the hand-in) writes a
BIT_CLK stimulus (`0 00`, first rise at 200 to 299, rises at
floor(c0 + (k + phase) x 4.069) minus a constant, so periods are 4 or 5 with
5 about one in 14.5, high for exactly 2 cycles), writes random frames (none,
read, write, random even addresses and data), runs
`pe_sim run ac97.s -tx ... -stimulus ... -cycles 400+1042(F+2)` plus
`run_args.txt`, and checks: no SYNC/SDATA change in a falling-edge cycle;
both low by cycle 40; first SYNC at edge 1..255; SYNC high exactly at
e+256i .. e+256i+15 for each frame and low elsewhere; SDATA low at every edge
that carries no frame bit; all 13 slots of every frame decoded MSB first
against the expected values; SYNC changed exactly 1 + 2F times (so no
glitches between edges).

## pe_sim runs

1. `asm ac97.s`: 51 words, assembled fine.
2. `asm ac97.s` again (same command line, piped to `wc -l`): 51.
3. `run ac97.s -help`: flag list (includes `-stimulus`, and config names
   `sideset_base`, `sideset_count`, which isa.md never mentions).
4. Harness, TASK.md's two example frames: OK, first SYNC at edge 3.
5. Raw `run` of 400 cycles to eyeball output format against the stimulus:
   `pins 0 ff`, `pins 1 f9` (both low from cycle 1), SYNC up at 229 with
   rises at 217, 221, 225 (shows R2+4, between falls 227 and 231), as designed.
6. to 17. Harness, random frames, F = 1 to 12 (seeds 101 to 112): all OK.
18. Harness on a deliberately broken copy (`work/mut.s`, tag-12 write replaced
    by `nop`): FAIL reported with the wrong tag, so the harness does catch
    errors.
19. to 24. Harness at edge alignments: c0 = 200 / 299 / 200 / 299 / 250 / 213
    with phases 0, 0.999, 0.5, 0, 0.93, 0.07, F = 12, 12, 12, 1, 12, 3: all OK.

Total: 24 runs of pe_sim. No mistakes found in the program; it passed every
check from the first run.

## Confusing or possibly wrong

- The `pe_sim` wrapper's flag table for `run` lists `-config -cycles -inputs
  -mode -tx -help` but not `-stimulus`. Any command line with `-stimulus` is
  therefore treated as unparseable and forwarded to `pe_sim.real` untouched,
  so the side-set check is skipped exactly in the runs the test makes. I did
  not rely on this: the program uses no side-set and the config sets no
  `sideset_count`.
- isa.md never mentions side-set, yet `pe_sim run -help` lists
  `sideset_base` and `sideset_count`, and the wrapper describes the delay field
  as shared with side-set bits. isa.md's encoding table calls bits 12:9 delay
  only.
- isa.md does not say how boolean config fields are written (`out_msb_first=1`
  worked).
- The default `threshold` is 8, which surprised me for a 16-bit word; with
  `out_msb_first` it does not change which bits `out` takes, but I set 16.
- isa.md does not say whether `pull` with an empty FIFO in the test could
  delay a frame; I rely on TASK.md's statement that the simulator refills the
  FIFO at once. With a slow host the frame timing would break (the pull sits
  inside the bit timing), which is a limitation of this design.

No rule broken that I know of. I wrote only inside the folder (`ac97.s`,
`run_args.txt`, `notes.md`, and `work/` with the harness, stimulus, TX file
and the mutated test copy).
