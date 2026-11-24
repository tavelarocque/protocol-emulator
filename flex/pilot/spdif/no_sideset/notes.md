# Notes: S/PDIF transmitter for the protocol emulator

## What I read

- `TASK.md` and `isa.md`, both in full, once each.
- The output of `./pe_sim run x.s -help`.
- Nothing else. I did not open, list or search anything outside this folder,
  did not read `pe_sim`'s contents, and did not use the web.

## Design

Cell length 8 cycles, so 48 kHz. P0 push-pull, rests high (the output
register resets to ones), so every preamble comes out inverted relative to
the table (first three cells low). P0 never changes before the first
preamble. Config: `start=12, set_base=0, set_count=1, autopull=1,
threshold=16`, `-mode 0=pp`.

Where the state lives:

- **Line level: in the program counter.** There is no toggle or invert, so
  the bit loop and the C/P tail each exist in an H copy and an L copy. A
  0 bit crosses to the other copy, a 1 bit stays. This also gives parity
  for free: even parity is the same thing as "the line is back at its rest
  level at the end of the subframe", so the P slot sends 1 from the copy
  where the line is at rest level and 0 from the other.
- **Slot counter: Y.** `set y,26`, and each slot starts with
  `set pins; jmp y-- cont`. The 26 slots taken are the 24 data bits plus V
  and U, which come out as zeros for free because bits 8 and 9 of the
  second word are zero by the host format. On the 27th pass Y is 0, the
  `set pins` already executed is the first edge of the C slot, and the
  fall-through is the tail.
- **Frame counter: ISR value.** c = 24 in frame 0 of a block, minus one per
  frame, reloaded to 191 after it reaches 0. So B is c = 24, C = 1 is
  c = 22 (frame 2) or c = 0 (frame 24). All compares fit `set x` (5 bits)
  plus `jmp x!=y`, or `jmp !y`. The reload constant 191 is built from the
  Y that just wrapped to 0xFFFF: `in y,6; in null,1; in y,1; in null,8`.
- **Left/right flag: ISR shift count.** `in y,16` writes the ISR and leaves
  it full; `mov isr,y` writes it and leaves it not full; `jmp !isrf` tests
  it. Autopush stays off.
- **Data: OSR with autopull.** 16 + 10 single-bit `out x,1`, then
  `out null,6` throws away the rest of the second word, which refills the
  OSR with the next subframe's first word in the same cycle.
- **End of run.** After `out null,6`, `jmp !osre pre`. If no word was
  there, it falls into the `pull` at `start`, which stalls for ever with
  the line at rest. No pin change after the last subframe.

Two small tricks that removed instructions: a 0 bit jumps to the other
copy's mid-bit `set pins`, which rewrites the level the line already has
(no change on the pin), and the same for C = 0 in the tail. The three
preambles share their first two edges (cycles 0 and 24), and the frame
bookkeeping happens in the 23 idle cycles between them.

Cycle counts, relative to the first edge of each section:

- Bit slot: `set pins` 0, `jmp y--` 1, `out x,1` 2, `jmp !x [4]` 3 to 7,
  mid `set pins` 8, `jmp [6]` 9 to 15.
- Tail (C and P slots): edge 0, compute C in 2 to 7, mid edge 8, P edge 16,
  P mid edge 24, `out null,6` 30, `jmp !osre` 31, next preamble 32.
- Preamble: edge 0, edge 24, then B 32/40, W 40/48, M 48/56, `set y,26`
  at 63, first data edge 64.

## Simulator runs (17 in total)

1. `./pe_sim run x.s -help`: the flags.
2. `asm spdif.s`: failed, "expected a number, got "contl"". Labels with
   capital letters do not resolve (the reference is lower-cased). Renamed
   every label to lower case.
3. `asm spdif.s`: 59 words.
4. `run`, the sheet's example frame (0x123456, 0xABCDEF), 3000 cycles, to
   see the output format (`pins CYCLE HEX`).
5. to 7. 1 frame (sheet example), 3 frames random, 30 frames random: OK.
8. to 13. 400 random, 193 random, 192 all zero, 200 all ones, 27
   alternating 0x555555/0xAAAAAA, 2 random: OK.
14. to 17. With the flags read from `run_args.txt`: 385 random, 1 all
   ones, 1 all zero, 400 random: OK.

Every `run` after number 4 was checked by `check.py`, which I wrote here.
It rebuilds the cells from P0's changes and checks: first edge by cycle
10 000, every gap 8, 16 or 24 cycles exactly, every change on the cell
grid, preamble B/M/W per position (B at frames 0, 192, 384), a change at
the start of every slot, the 24 data bits against the words sent, V = 0,
U = 0, C = 1 only in frames 2 and 24 of a block, even parity, and no
change after the last subframe. I also fed it the wrong words against a
good waveform, without running the simulator, and it failed as it should.

`gen.py` makes the words, `t.sh` does one run and the check. `tx.txt` and
`out.txt` are left over from the last run.

## Mistakes

- Mixed-case labels (run 2), found from the assembler's error.
- None in the firmware itself: the first version that assembled passed.
  The design changed several times on paper before that (first plan had
  explicit V and U slots, separate "zero bit" jumps and a 5-instruction
  reload, and came to 68 instructions, over one page).

## Rule slips

None that I know of. Everything read and written is in this folder, the
simulator was only run as `./pe_sim` from here, no web.

## Not tested

- Only cell length 8. A host slower than the simulator's (the FIFO empty
  in mid-run) would end the stream early or stretch a bit; the sheet says
  not to worry about it.
- I cannot see the acceptance test, so "works" means it passes my own
  receiver-style check on 14 runs.

## Result

- Program length: **59 instructions** (one page, `start=12`).
- Cell length: **8 cycles, 48 kHz**.

## Confusing or missing in `isa.md`

1. **No assembler syntax at all**, although `TASK.md` says it is there.
   I guessed from RP2040 PIO: `label:`, `;` comments, `[n]` for delay,
   `in y, 16` for a count of 16. That labels must be lower case I found
   only from an error. Only `.page` and `.align` are described.
2. **`pe_sim run -help` lists `sideset_base` and `sideset_count`**, and
   `isa.md` never mentions side-set. I did not use them. If the chip has
   side-set, the document is missing a whole feature (and the encoding
   table would have to change, since the delay field is shown as 4 full
   bits).
3. Reset state is not given: values of X, Y, ISR, whether the OSR starts
   empty, the shift counts. I assumed nothing and began with `pull` and
   `mov isr,y`.
4. Shift-count details are thin: whether `jmp !osre` right after an
   autopull refill sees a full OSR (it does), whether the ISR count
   saturates past 16, what `pull` does when autopull is on and the OSR is
   not empty, whether `in x,n` takes the low n bits of X (it does).
5. The operand table gives `set` destinations pins 0, x 1, y 2 and calls
   destination 3 a reserved NOP, while the text says `set page, n` exists.
   Likewise `mov` lists codes 0 to 5 and calls 6 and 7 reserved, while
   `crc` is a location.
6. That a jump's delay is spent whether or not the jump is taken is only
   implied by the cycle rules. It decides how every branch here is timed.
7. Defaults of the config fields (`threshold`, `set_count`) are not
   stated, so I set them all explicitly.
8. There is no way to invert or toggle a pin, which is what forces the two
   copies of the code for a biphase-mark line. Worth saying in the text.
