# Notes: Miller transmitter for the protocol emulator

## What I read

- `TASK.md`, in full.
- `isa.md`, in full. The parts I used: machine state (OSR, TX FIFO, output
  register resets to all ones), per-thread configuration (`out_base`,
  `out_count`, `threshold`, `clkdiv`, `autopull`), cycle semantics (pin writes
  take effect at the end of the cycle, `clkdiv` ticks), `out` with autopull,
  `jmp`.
- `./pe_sim run miller.s -help` for the flags.
- Nothing else. I did not read `pe_sim` itself.

## Design

The chip has no instruction that toggles a pin, and Miller code needs "the
previous bit" as state, so I put the whole line coding in the host and made
the chip a plain level shifter with exact timing.

- Each TX word is 16 line levels for P0, least significant bit first, one
  level per half bit (50 cycles).
- The program is `loop: out pins, 1` / `jmp loop`. With `clkdiv=25` those two
  instructions are 2 ticks = exactly 50 cycles, so one level every half bit.
- `autopull=1`, `threshold=16`: the `out` that takes the 16th level refills
  the OSR from the TX FIFO in the same tick, so there is no gap between
  words and no error can add up along a message.
- When the words run out, `out` finds the OSR empty and stalls for ever. P0
  keeps its last level. The host pads the last word with that same level, so
  there is no stray transition.
- Host stream: 8 half bits of high (lead-in, 400 cycles), then per message the
  2 x (8n + 2) half-bit levels followed by 12 half bits of the unchanged level
  (600 cycles of silence, above the 400 minimum and far below the 20000
  maximum). The level carries over from one message to the next.
- A 32-byte message is 516 half bits, about 33 words. Eight of them with gaps
  are 265 words.

Why `clkdiv` and not delay fields: a 50-cycle loop without the divider needs
four instructions (`out [15]`, `nop [15]`, `nop [15]`, `jmp [1]`). TASK.md
says the thread "may" run every cycle, and `run_args.txt` is allowed any
`-config` flag, so I took the divider. If the divider were not allowed, the
four-instruction form with `clkdiv` removed should give the same waveform; I
did not simulate that variant.

## pe_sim runs (17 in total)

1. `./pe_sim run miller.s -help` to see the flags. (A two-line draft of
   `miller.s` existed only so that the command had a file to name.)
2. `./pe_sim run miller.s -tx t1.txt -cycles 21000 <run_args>` with the words
   for the one-byte message 0x16. Output: P0 high at cycle 0, first fall at
   426, then changes at 526, 676, 776, 976, 1126, 1226, 1326. Relative to the
   first: 0, 100, 250, 350, 550, 700, 800, 900, which is the table in
   TASK.md exactly. Nothing after 1326.
3. to 16. `python3 selftest.py`, 14 runs, each with N computed as the test
   will compute it (20000 + 20000 per message + message lengths). The script
   derives the ideal transition times straight from the rules in TASK.md
   (not from `host.py`'s level stream), and checks: P0 high at cycle 0, first
   fall within 20000, every transition within 2 cycles of its place counted
   from the message's first transition, gaps between 400 and 20000, and no
   transition left over. Cases: 0x16, 0xFF (last transition at 850, as
   TASK.md says), 0x00, 8 x 32 bytes of 0xFF, 8 x 32 bytes of 0x00, four
   single-byte messages (0x55, 0xAA, 0x01, 0x80), and 8 random sets of 1 to 8
   messages of 1 to 32 random bytes. All passed with a worst error of 0
   cycles. Gap as built is 600 cycles.
17. `./pe_sim asm miller.s`: two words, `6001` and `0000`.

## Mistakes found

None by simulation: the first version passed every check and I changed
nothing after run 2. That also means the check is only as good as my reading
of TASK.md. `selftest.py` and `host.py` are both mine, so a shared
misunderstanding of the code (rather than of the chip) would not show. The
one outside anchor is the worked 0x16 table and the 0xFF remark in TASK.md,
both of which the waveform matches.

Not tested: the real sigrok decoder; a slow host (TASK.md says not to worry);
the four-instruction variant without `clkdiv`.

## Rule slips

- My first command was `ls -la` on this directory, which printed the path
  that the `pe_sim` symlink points to. I did not open, list or follow that
  path, and ran the simulator only as `./pe_sim` from here.
- The same first command also printed `TASK.md` and `isa.md` with `cat`; the
  tool I work through saved that long output to a file of its own outside
  this directory. I did not ask for that and did not open that file; I read
  the two documents again from this directory instead.
- No web use, no other files read or written. `selftest.py` wrote
  `selftest_tx.txt` and run 2 wrote `t1.txt`, both here; I deleted both, and
  a `__pycache__` directory Python made here.

## Result

- Program length: **2 instructions** (`out pins, 1`; `jmp loop`).
- `run_args.txt`:
  `-config out_base=0,out_count=1,threshold=16,autopull=1,clkdiv=25 -mode 0=pp`
- Host word format: each 16-bit TX word is 16 consecutive levels of P0, bit 0
  first, each level held for one half bit (50 cycles). The stream is 8 high
  half bits, then for every message its Miller-coded levels (two per bit:
  start bit, data bytes LSB first, end bit) and 12 half bits of silence at
  the level the message ended on; the last word is padded with that level.
  The chip does no coding at all.
- Files: `miller.s`, `run_args.txt`, `host.py`, `notes.md`, and `selftest.py`
  (my own check, not asked for).

## What was confusing or missing in isa.md

Nothing I found to be wrong. Things I had to guess or find out by running:

- The first line says this build has no side-set, but side-set is described
  nowhere in the document, while `pe_sim run -help` still lists
  `sideset_base` and `sideset_count` as config keys. A reader cannot tell
  what was removed.
- The assembler syntax is never written down, although TASK.md says isa.md
  holds it: labels (`name:`), comments (`;` worked), and above all how to
  write the delay field. I avoided delays partly for that reason.
- Reset values are not given for `threshold`, for the OSR (is it empty at
  start?) or for `out_count`. I set all the config explicitly. The waveform
  shows the OSR does start empty: the first `out` spent one tick fetching.
- Autopull says the refill happens "in the same cycle"; with `clkdiv` I read
  that as "the same tick", and the simulation agrees (no slip across 265
  words).
- There is no instruction to toggle or invert a pin or a register, and no
  carry of state besides X and Y. A transition code such as Miller would
  take a lot of firmware on the chip, which is why the coding went to the
  host. The document could say so, or point at the intended idiom.
- pe_sim's own formats are undocumented: `-mode P=pp` takes a pin number
  (`0=pp`), the `-tx` file took decimal numbers, and the output lines are
  `pins CYCLE HEX` where a write made in cycle c shows as a change at c + 1.
