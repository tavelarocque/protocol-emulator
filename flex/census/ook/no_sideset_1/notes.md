# Notes: OOK transmitter

## What I read
- TASK.md in full (144 lines), in one read.
- isa.md in full (607 lines), in three parts (lines 1 to 149, 150 to 378, 379 to 607).
- The help text of `pe_sim run` (run 1).
- Nothing outside this folder. I did not open the `pe_sim` wrapper script or `pe_sim.real`; I only ran them.

## Design
Clock divider: `clkdiv=25`, so one tick is 25 cycles and half a bit (250 cycles) is exactly 10 ticks. Every
place in a frame is a multiple of 250 cycles, so with every instruction path counted in ticks all transitions land
exactly (0 cycles error), and nothing can drift along a frame. Delays and stalls (pull) also count in ticks, so the
tick grid is never lost.

No side-set (the ISA has none). P0 is written with `set pins` (set_base 0, set_count 1, the defaults). Writing a
level the line already has makes no transition, so each bit is simply two writes: its first-half level at the start
of the bit and the opposite level in the middle.

Words: `out_msb_first=1`, `threshold=16`. After `pull`, `out x, 8` takes bits 15..8 (seven zeros and the flag), so X
is the "last byte" flag and the byte sits at the top of the OSR. Eight `out y, 1` then give the bits MSB first and
leave the OSR count at 16, so `jmp !osre` falls through exactly when the byte is done. Y is the bit for `jmp !y`.

Structure (ticks relative to t, the first-half write of a data bit, m = t + 10 the middle write):
- `endz` (address 0, also the program start): `set pins, 0`. At start of run this drives P0 low in cycle 0 (shows at
  cycle 1). At end of frame it is reached exactly at the end of the last bit (needed when the last bit is a 0).
- Gap: `set y, 31` and `jmp y--, gapw [6]` (224 ticks), then `pull` (stalls with the line low when the host has no more
  words, which is how the run ends), `out x, 8`, `set y, 15`. First rise 229 ticks = 5725 cycles after the end of the
  previous frame (or after cycle 0), inside 5000..20000.
- Preamble: loop of `set pins,1 [9]`, `set pins,0 [8]`, `jmp y--` = 20 ticks per bit, 16 times.
- Sync 0101: unrolled `nop [9]`, then the four middle transitions at T+10, T+30, T+50, T+70 (set with delay 15 plus
  `nop [3]` pads), then `jmp bitloop` so that the first data write is at T+80.
- Data bit: `out y,1` (t-2), `jmp !y zero` (t-1); a 1 is `set pins,1 [9]`, `set pins,0 [2]`, `jmp common`; a 0 is
  `set pins,0 [9]`, `set pins,1 [3]`; both reach `common` at m+4. `common: jmp !osre cont` (m+4):
  - more bits: `cont: jmp bitloop [2]` gives the next write at m+10;
  - byte done, not last (`jmp !x nextbyte` at m+5): `pull` (m+6), `out x,8` (m+7), fall into bitloop, write at m+10;
  - byte done and last: `jmp endz [3]` (m+6), `set pins,0` at m+10, the end of the bit.
  The TX FIFO is always refilled in the test, so the mid-frame `pull` never stalls.

## Program length
31 instructions (`pe_sim asm` printed 31 words).

## run_args.txt
`-config clkdiv=25,out_msb_first=1,threshold=16 -mode 0=pp`

## pe_sim runs (7 in total)
I wrote a small checker (check.py, Python, in this folder) that reads pe_sim's output and the words file, builds the
ideal transition list from TASK.md's rules (start low by cycle 100, first rise in 5000..20000, gaps 5000..20000 from
the end of the last bit, every transition within 2 cycles of its ideal place from the frame's first rise, no extra
transitions). Its numbers are pe_sim's printed cycles, which are one cycle after the instruction that wrote.
1. `./pe_sim run x.s -help`: printed the flags. The config list includes `sideset_base` and `sideset_count`.
2. `./pe_sim asm ook.s`: assembled, 31 words, no errors.
3. One frame 0xA5, 54000 cycles: P0 low at cycle 1, first rise at 5726, 46 transitions exactly as in TASK.md's
   table, worst error 0, line low from 19476 to the end. OK.
4. Frames [12 34 FF], [00], [FE], N = 130000: all three exact (74, 52, 52 transitions), gaps 5725, no stray edges. OK.
5. Six frames of 16, 1, 7, 16, 3, 16 random bytes (one of them 0x00, one ending 0x55), N = 436000: all exact, worst 0,
   gaps 5725, line low after the last frame. OK.
6. Frames of 16 x 0x00, 16 x 0xFF, and 1 x 0xFF (longest frames, all-equal bits), N = 300000: all exact. OK.
7. Empty TX file, 60000 cycles: P0 goes low at cycle 1 and never moves again. OK.

No mistakes were found by the runs; the tick counts worked out on paper first time. One paper mistake before
run 2: I first counted the `nextbyte` path with a `jmp bitloop` in it, then moved `nextbyte` to fall into
`bitloop` and recomputed the delays (a+b = 2, cont delay 2, end delay 3).

After the runs I deleted my test files (check.py, t*.txt, o*.txt) so that the folder holds only the hand-in and
the given files.

## Rules
I believe I kept to every rule: I read and wrote only inside the folder and used 7 of the about 80 pe_sim runs.

## Confusing or possibly wrong in isa.md
- `pe_sim run -help` lists `sideset_base` and `sideset_count` config fields, but isa.md never mentions side-set:
  the encoding table has no side-set bits and no instruction uses it. Either the doc or the tool is out of date.
- `in` direction: "shifts count bits right into the ISR" then "with `in_msb_first` the ISR shifts left instead and
  new bits enter at the bottom" does not say where new bits enter by default (presumably the top). Not needed here.
- The `pins` lines print all 8 output-register bits, including input-mode pins (they show 1, the reset value), so
  P0 low reads as `fe`, not `00`. isa.md says it prints "the pins' output", which is right but easy to misread.
- isa.md says a push-pull pin is high "from the moment the host makes it push-pull"; in pe_sim the pin is push-pull
  from cycle 0 (`pins 0 ff`), so the firmware's first write is what matters, as TASK.md says.
- With `clkdiv`, the first tick is the first enabled cycle (cycle 0), so writes land on cycles 25k + 1 in the
  printout. This matched isa.md.
