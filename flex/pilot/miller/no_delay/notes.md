# Notes: Miller transmitter for the protocol emulator

## What I read
- `TASK.md` and `isa.md`, both in full, once each.
- The output of `./pe_sim run t0.s -help` (flag list only).
- Nothing else. I did not read `pe_sim` itself.

## Design
Configuration (in `run_args.txt`):
`-config out_base=0,out_count=1,threshold=8,clkdiv=5 -mode 0=pp`

- **Timing by the clock divider.** `set` only takes a 5-bit immediate, so a
  delay loop on X is at most 32 instructions long, and there is no
  per-instruction delay. With `clkdiv=5` one tick is 5 cycles, a bit is 20
  ticks and half a bit is 10 ticks, so every delay fits one `set x, n` /
  `jmp x--` loop and every transition lands on an exact multiple of 5
  cycles. No error accumulates: every path between two decision points was
  counted by hand to the tick (the counts are in the comments of
  `miller.s`).
- **Toggling P0.** There is no invert and no way to read-modify-write a
  pin, so Y holds the level in its bit 0. A transition is the pair
  `jmp y-- next` / `next: mov pins, y`: decrementing flips bit 0, and the
  jump targets the next instruction so it does not matter whether it is
  taken (it is not taken when Y was 0). Y just counts down and wraps, so
  this is good for any number of transitions. Y starts at 1 because P0
  resets high.
- **The previous bit lives in the PC.** Two blocks, O (inside a 1 bit) and
  Z (inside a 0 bit), each with its own copy of the fetch code. From the
  middle of the current bit (tick 0): next bit 1 gives a transition at tick
  20 and block O; next bit 0 from Z gives a transition at tick 10 and block
  Z; next bit 0 from O gives no transition and block Z.
- **Byte boundary and last-byte flag.** `threshold=8`, so `jmp !osre`
  falls through after 8 data bits. One more `out x, 1` then yields bit 8 of
  the word, the last-byte flag. Not last: `pull` and carry on. The boundary
  path costs 3 ticks more than the ordinary one, so the ordinary path is
  padded with `nop nop jmp` to make both exactly 5 ticks.
- **Start, end, gap.** Start: `pull`, toggle, then enter Z (the start bit is
  a 0). End bit after a 0: one toggle at tick 10; after a 1: none. Then a
  silence loop of 130 ticks and back to `pull`, which stalls for ever when
  the words run out, leaving the line as it is. Measured silence from the
  end of the end bit to the next start: 535 cycles after a final 1 bit,
  565 after a final 0 bit (400 to 20000 allowed).

## pe_sim runs (11 in total)
1. `./pe_sim run t0.s -help` (t0.s was a one-line `nop` file, since the
   help needs a file argument; deleted afterwards).
2. `./pe_sim asm miller.s`: assembled first time, 50 words.
3. `./pe_sim run miller.s -tx t1.txt -cycles 3000 ...` with the word
   0x0116. Edges at cycles 16, 116, 266, 366, 566, 716, 816, 916: exactly
   the table in TASK.md (0, 100, 250, 350, 550, 700, 800, 900).
4. to 7. `check.py` (my own checker, in this folder: it builds the expected
   edge list from the rules in TASK.md, runs pe_sim once and compares
   places, gaps, the first fall and stray edges) on: a fixed set (0x16;
   DE AD BE; FF; 00; 80; 01; 32 x 00; 32 x FF) and random seeds 1, 2, 3.
   All PASS, worst place error 0 cycles.
8. Hand run of FF / 00 / 00 01 to read the gaps myself: 535 and 565 cycles.
9. Hand run with the word written in decimal (`278`) instead of hex: same
   waveform, so pe_sim accepts both spellings in the -tx file.
10. and 11. After editing a comment in `miller.s` (no instruction changed):
   `check.py fixed` and seed 7 again, both PASS, worst error 0.

Scratch -tx files were deleted at the end; `check.py` is left here.

## Mistakes found
- Only one, in a comment: I first wrote the silence as 530 cycles because I
  forgot to count the `jmp msg` tick. Run 8 showed 535 and 565, and I
  corrected the comment. The code was right from the first assembly; no
  instruction was changed after run 2.
- My hand count of the program length was 49; the assembler says 50.

## What I have not tested
- A host that is slow to refill the FIFO. A `pull` in the middle of a
  message that has to wait would stretch that bit. TASK.md says not to
  worry about it.
- More than 65536 transitions in one run (Y wrapping). The 0 to 0xFFFF
  wrap is exercised on the second transition of every run, so I expect it
  to be fine, but I did not run that long.
- I cannot see the acceptance test or its exact -tx file format. My
  checker is my own reading of TASK.md.

## Rule slips, stated honestly
- No deliberate ones. Two things worth declaring:
  - My first command was `ls -la`, which printed the target path of the
    `pe_sim` symlink. I did not open, list or follow that path.
  - That same command also printed both documents, and the harness saved
    the oversized output to a file outside this folder on its own. I did
    not read that file; I re-read both documents from this folder instead.
- pe_sim was always run as `./pe_sim` from inside this folder (also from
  `check.py`). No web use.

## Program length
50 instructions (one page, no paging needed).

## Confusing or wrong in isa.md
1. **No assembler syntax.** TASK.md says isa.md gives the assembler syntax;
   it does not. Labels (`name:`), comments (`;`), number formats, and the
   exact spelling of operands are only visible in two tiny examples and the
   condition table. I guessed from RP2040 PIO conventions and it worked.
2. **`out` on an empty OSR without autopull is not defined.** The text only
   says what happens with autopull. I depend on it simply shifting on past
   the threshold (to read bit 8 of a word with threshold 8). It does, but
   the document should say so, and say what bits come after the 16th.
3. No way to toggle or invert a pin is described, and `mov` has no invert.
   The `jmp y--` to the next instruction idiom is not mentioned anywhere.
   This is the first thing every line code needs.
4. Reset values of X, Y, OSR, ISR and the shift counts are not stated. I
   set Y explicitly and never use the others before loading them.
5. `set` takes 5 bits while X and Y are 16 bits, and nothing says how to
   get a larger constant into a register (building it in the ISR is the
   only way I can see). For delays the practical answer is `clkdiv`, which
   the document presents mainly as an I2C convenience.
6. pe_sim's output is undocumented: the cycle printed for a pin change is
   the cycle after the instruction that wrote it (a `mov pins` executed in
   cycle 15 prints `pins 16`), which agrees with "pin writes take effect at
   the end of the cycle" but has to be worked out. The -tx number format
   and the defaults of each -config key are not stated either.
7. Default of `out_count` (and of `threshold`) is not stated; I set both.
