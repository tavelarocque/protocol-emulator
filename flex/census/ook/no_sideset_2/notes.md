# Notes: OOK transmitter for the protocol emulator

## What I read

- `TASK.md` in full (144 lines), in one read.
- `isa.md` in full (607 lines), in three reads (lines 1 to 200, 200 to 400, 400 to 607).
- The output of `./pe_sim run x.s -help` (run 1 below).
- Nothing outside this folder. I did not look for the `model/`, `hw/` or `docs/` files isa.md mentions.

## Design

Configuration (`run_args.txt`): `-config clkdiv=25,out_msb_first=1,threshold=16 -mode 0=pp`.

The thread runs one tick every 25 cycles, so half a bit (250 cycles) is exactly 10 ticks and a bit is 20 ticks. Every pin write is made by a `set pins` on a tick, so every transition lands on a multiple of 25 cycles (plus the fixed one-cycle offset the simulator prints), and its place relative to the frame's first rise is exact: zero error, nothing accumulates. All timing is counted in ticks with instruction delays, no runtime counters except X for the preamble and gap loops.

With `out_msb_first` and `threshold` 16, a host word 0b0000000F_DDDDDDDD comes out of the OSR top first: `out null, 7` drops bits 15..9, `out y, 1` puts the last-byte flag in Y, and then eight `out x, 1` give the data bits MSB first. After those eight the OSR has shifted 16 bits and counts as empty, so `jmp !osre` tells the bit loop whether the byte is finished; no bit counter is needed.

Flow:
1. `set pins, 0` at tick 0 (the pin shows low from cycle 1).
2. Gap: `set x, 15` and `jmp x--, gap [15]`, 256 ticks (6400 cycles), then `pull` (blocks with the line low if the host has no more words, which is how the run ends), `out null, 7`, `out y, 1`.
3. Preamble: 16 iterations of `set pins 1 [9]`, `set pins 0 [8]`, `jmp x--` (20 ticks each).
4. Sync 0101: straight-line code, rises and falls in the middles of bits 16 to 19 (delays split because 15 is the maximum delay), ending with `jmp bitout` so that the first data bit's `out x, 1` executes 2 ticks before the bit starts.
5. Data bit loop. `bitout: out x, 1` at s-2 and `jmp x--, one` at s-1 (X = 1 jumps, X = 0 falls into `zero`; the decrement does not matter). Each path writes the first-half level at s and the opposite level at s+10, then reaches `tail` at s+13. `tail`: `jmp !osre more` (more bits: `jmp bitout [3]` to land at s+18); otherwise `jmp !y getword` (`pull`, `out null 7`, `out y 1`, falling into `bitout` at s+18); otherwise the frame is over: `jmp fin [4]` lands `fin: set pins, 0` exactly at s+20, the end of the last bit, which is the required fall if the last bit was 0 and a no-op if it was 1. Then the gap loop again.

Writing a level the pin already has makes no transition, so each bit simply writes both of its halves; the transitions between equal bits come out by themselves.

Timing results: first frame's first rise at cycle 6576 (needs 5000 to 20000), gap from end of a frame to the next rise 6550 cycles (needs 5000 to 20000), line low from cycle 1 (needs by 100).

The pull for a frame's first word is done before the preamble, where a stall cannot break timing. The pulls for later bytes are inside a bit; in the simulator the FIFO is always refilled at once, as TASK.md says, so they never stall there.

## Program length

34 instructions (`pe_sim asm ook.s` printed 34 words). It fits in one 64-word page, so no paging is needed.

## pe_sim runs (13 in total)

1. `./pe_sim run x.s -help`: printed the flags. The config list includes `sideset_base` and `sideset_count`, which isa.md never mentions.
2. `./pe_sim asm ook.s`: assembled cleanly, 34 words.
3. Run of the TASK.md example words (0x01A5, 0x0012, 0x0034, 0x01FF), 100000 cycles: low at cycle 1, first rise at 6576, 0xA5 frame transitions exactly at the table's offsets (last fall at +13750), second frame rise at 27126 (gap 6550). My checker script (below) said OK.
4. to 11. Eight random runs (seeds 1 to 8: 1 to 6 frames, 1 or 16 or random bytes, values biased to 0x00, 0xFF, 0x80, 0x01), each with the test's cycle count N. All OK: every transition at exactly its ideal place, gaps 6550, no stray transitions after the last frame.
12. A handmade 6-frame run (0x00; 0xFF 0xFE; 0x55; 0xAA 0x00 0x00; 0x01; 0x80), N = 236000, covering frames that end with a 0 bit (fall exactly at the end of the bit). OK. I also fed the checker a wrong word list against this trace to make sure it can fail; it did.
13. A last smoke run (one frame 0xA5, 41000 cycles) after restoring `run_args.txt` (see mistakes): first rise 6576, last fall 20326, nothing after.

The checker was a small Python script I wrote in this folder (`check.py`, with `gen.py` for random runs). It parsed the `pins` lines, built the ideal transition list for each frame from the words, and compared every transition (level and place within +-2 cycles of the frame's first rise), the start (low by cycle 100), the gaps and stray transitions. I deleted the helper scripts and test files afterwards so that the folder holds only the hand-in.

## Mistakes

- While cleaning up the test files I ran `rm -f ... r*.txt`, which also deleted `run_args.txt`. I noticed it in the `ls` straight after, wrote it again with the same contents, and checked it with run 13. No other mistakes: the program passed on its first run.
- No rule was broken that I know of. All reads and writes were inside this folder.

## Confusing or possibly wrong in isa.md

- `pe_sim run -help` lists `sideset_base` and `sideset_count` config fields, but isa.md has no side-set anywhere: not in the encoding (the 4-bit delay field takes all of bits 12..9), not in the syntax, not in the config table. Either the doc dropped a feature or the tool has leftover fields. I did not use them.
- The "start of run" rule that the thread's first tick is "the first cycle it is enabled" is stated for clkdiv, but it is not said at which cycle `pe_sim run` enables the thread or makes the pin push-pull. In practice the thread runs at cycle 0 and its first write shows at `pins 1`.
- `clkdiv`'s range (field width) is not given anywhere; 25 worked.
- `out_msb_first` is described clearly, but it took a careful read to see that with threshold 16 the 7 unused high bits come out first; that is what makes the last-byte flag easy to read.
- Minor: the `jmp` condition table has `!osre` but no `osre`, so a "byte finished" test always needs the branch the other way round; not a bug, just a layout constraint.
