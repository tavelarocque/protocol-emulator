# Notes: PT2262 encoder on the protocol emulator

## What I read
- `TASK.md`, all 137 lines, in one read.
- `isa.md`, all 607 lines, in four parts (lines 1-150, 150-300, 300-460, 460-607).
- The help text of `pe_sim run` (run 1 below).
Nothing outside this folder was opened, listed or searched. (The first `ls -la` of the folder also printed the `..` entry, which is just the listing of this folder; I did not follow it.)

## Design
The key observation is that every edge of the PT2262 line falls on a multiple of 4 alpha = 1600 cycles. So I run thread 0 with `clkdiv=100` (one tick = 100 cycles = alpha/4), which makes one 4-alpha unit exactly 16 ticks, the most one instruction can take (1 + delay 15). Every instruction is then placed on an exact tick, and since nothing ever waits except `pull`, the edges land exactly where they belong with no error to accumulate.

A pulse cycle is four units: high, d, d, low, where d is 1 for a long pulse and 0 for a short one. For a trit with value bits b1 b0 (0 = 00, 1 = 01, f = 10), the first pulse's d is b0 and the second pulse's d is b0 OR b1 (since 3 never occurs). So each pulse is: `set pins 1` at t, `mov pins, x` at t+16 (falls here only if short), `set pins 0` at t+48 (falls here only if long). The first pulse takes X from `out x, 1` (b0). Between the pulses one `jmp !x` chooses: if b0 = 0, `out x, 1` makes X = b1; if b0 = 1, `out null, 1` drops b1 and X stays 1. Both branches are padded with delays to the same 14 ticks so the second rise is on tick 64.

Words: no autopull, `threshold=12`, LSB first (default). Three ticks before every rise, `jmp !osre skip` / `pull [1]` (or `skip: jmp rise [1]`, same length) fetches a new word when 12 bits (6 trits) have been used. So the first word of a frame is pulled at the end of the previous sync low (or the initial wait), and the second between trits 5 and 6. When the words run out, that `pull` stalls with the line low, so the line stays low to the end of the run with no stray edge. Y counts the 12 trits (`set y, 11`, `jmp y-- chk`). After trit 11 the code falls into the sync bit: high 16 ticks, then low, with an X loop of 30 x 16 ticks, `set y, 11`, `jmp chk [9]`, so the next frame's first rise is exactly 512 ticks after the sync's rise, and frames start 12 x 128 + 512 = 2048 ticks (204800 cycles) apart.

Start: `set pins 0` is the first instruction (tick 0, pin low from cycle 1), then a 256-tick X loop and a jump into the sync bit's low part, so the first rise comes at tick 755 = cycle 75500 (printed as `pins 75501`), in the middle of the 50000 to 100000 window.

`run_args.txt`: `-config clkdiv=100,threshold=12 -mode 0=pp`. All other fields keep their defaults (set_base 0, set_count 1, out_base 0, out_count 1, start 0).

## pe_sim runs
1. `./pe_sim run x -help`: printed the flag list. It lists config fields `sideset_base` and `sideset_count`, which `isa.md` never mentions (see below). I did not use them.
2. `./pe_sim asm rc_encode.s`: assembled without errors, 28 words.
3. `./pe_sim run` with the example code word 0 f 1 0 0 0 1 0 0 f 0 1 (0x0018, 0x0481), 324800 cycles: `pins 1 fe` (low at cycle 1), first rise at 75501, and every edge matches the table in TASK.md exactly (offsets 0, 1600, 6400, 8000, 12800, ..., trit 11 at 140800/145600/147200/152000, sync 153600/155200), then no change to the end.
4. to 11. Eight runs through a small checker script (`check.py`, written here, since deleted) that built the words, ran `pe_sim run rc_encode.s -tx FILE -cycles N $(run_args)` with N = 100000 + 204800 per code word + 20000, and compared every edge with the ideal one (level, place relative to the frame's first rise, frame spacing, low by cycle 100, first rise in the window, no edges after the last frame):
   4. 1 random code word: PASS, 50 edges, max error 0.
   5. 8 random code words: PASS, 400 edges, max error 0.
   6. 3 random: PASS, 150 edges, max error 0.
   7. 1 word of all '1': PASS, max error 0.
   8. 8 words of all 'f': PASS, max error 0.
   9. 8 words of all '0': PASS, max error 0.
   10. 2 words, all '1' then all '0': PASS, max error 0.
   11. 5 random: PASS, 250 edges, max error 0.

Total: 11 pe_sim runs. No mistakes were found; the first version passed every test.

## Program length
28 instructions.

## Confusing or possibly wrong in isa.md
- `pe_sim run -help` lists `sideset_base` and `sideset_count` as config fields, but `isa.md` describes no side-set at all (the encoding table has no side-set bits; the 4-bit delay field takes bits 12:9). Either the tool accepts leftover fields or the document is missing a feature.
- The encoding diagram shows `delay` at bits 12..9 under a header labelled `15 13 12 9 8 0`, which is consistent, but it leaves no room for side-set, which fits the point above.
- `clkdiv` has no stated width in `isa.md`; I assumed 100 fits (it did).
- The `pins` lines print the whole 8-bit output register (`ff`/`fe`), and since the register resets to all ones the first line is `pins 0 ff`. That matches the text, but is worth knowing when reading the output.
- "marks it full" for `pull` means the shift count goes to 0; the wording "full" vs the `!osre` threshold rule took a second read.

## Rules
I believe I kept every rule. The checker script and the temporary word files were written inside this folder and deleted before hand-in.
