# Notes: Miller transmitter for the protocol emulator

## What I read

- `TASK.md`, whole.
- `isa.md`, whole.
- `./pe_sim run x.s -help` output (the flag list).
- Nothing outside this directory. No web. The files `isa.md` points at
  (`model/...`, `hw/...`, `docs/info.md`) were not looked for.

## Design

Two designs were considered.

1. Host does the line coding and the chip plays levels: `out pins, 1` every
   50 cycles with autopull. Two instructions, but then the firmware is not a
   Miller encoder at all, the host has to track the line level, and a
   message costs twice as many words. Rejected as beside the point of the
   task, kept in mind as a fallback. Never built or run.
2. Chip does the Miller coding, host sends plain bytes. Chosen.

Chosen design, in `miller.s`:

- `clkdiv=5`, so a tick is 5 cycles, a bit 20 ticks, half a bit 10 ticks.
  A delay field (up to 15) then covers any wait inside a bit, and every
  transition is made by the same instruction (`mov pins, y`) on a tick, so
  all transitions are on one 5-cycle grid: no jitter and nothing to add up.
- Toggling. The ISA has no invert, so the pin is toggled with
  `jmp y-- next` then `mov pins, y`, with `out_count=1`: each decrement flips
  Y's bit 0 and only that bit is written to P0. Y starts at 1 so the first
  toggle writes 0 (P0 resets high).
- Previous bit. Not stored in a register: it is the place in the program.
  `b0` handles a bit after a 0, `b1` a bit after a 1.
- Framing. One word per byte, `threshold=8`, explicit `pull`. `jmp !osre`
  counts the 8 data bits; a ninth `out x, 1` reads bit 8 of the word, the
  last-byte flag. The chip makes the start bit (toggle, then enter `b0`),
  the end bit (toggle only if the last data bit was 0) and the gap (a
  160-tick counter loop), then waits in `pull` for the next message. When
  the words run out it sits in that `pull`, line untouched.
- Timing bookkeeping: with B the tick of the transition slot at a bit's
  start, each data bit is fetched by `out x, 1` at B-3, the start transition
  is at B and the middle one at B+10. Every path from one `out x, 1` to the
  next is 20 ticks, including the paths through the flag test and `pull`.
  The per-instruction tick numbers are in the comments of `miller.s`.

Config: `out_base=0,out_count=1,threshold=8,clkdiv=5`, pin 0 push-pull.

## Every run of pe_sim (20 in total)

| # | Command | Result |
|---|---|---|
| 1 | `./pe_sim run x.s -help` | flag list |
| 2 | `./pe_sim asm miller.s` | assembled first time, 32 words |
| 3 | `./pe_sim run miller.s -tx tx_ex.txt -cycles 41000 -config ... -mode 0=pp`, one word 278 (0x116) | transitions at 821 + 0, 100, 250, 350, 550, 700, 800, 900: the table in TASK.md exactly |
| 4 to 7 | `python3 check.py basic` (4 runs: 0x16; 0xFF; eight short edge messages; eight 32-byte messages) | all OK, error 0 cycles, gaps 685 and 725 cycles |
| 8 to 19 | `python3 check.py random 20261123 12` (12 runs, 1 to 8 random messages each, 1 to 32 bytes) | all OK, error 0 cycles, gaps 685 and 725 |
| 20 | negative test: sent `[0x17, 0x80]` while the checker expected `[0x16, 0x80]` | checker reported FAIL, as it must |

Every run was `./pe_sim` started from inside this directory (by hand, or by
`check.py` through `subprocess` with this directory as the working
directory). Budget was about 80; used 20.

`check.py` is my own test tool, not part of the hand-in. It runs the test's
command line (`-tx FILE -cycles N` plus `run_args.txt`, N computed as
TASK.md says), reads the `pins CYCLE HEX` lines, splits the transitions into
messages at silences, decodes them by the rules in TASK.md, and checks: P0
high until the first fall, first fall within 20000 cycles, only P0 moves,
every transition within 2 cycles of its ideal place counted from the
message's first transition, the frame (start 0, 8n data bits, end 0), the
data, the gap (400 to 20000 cycles from the end of the end bit), the number
of messages (so a stray transition after the last one would fail), and that
the last message ends inside the run.

Measured: first fall at cycle 821 in every run. Gap between messages 685
cycles when the last data bit is 1, 725 when it is 0. Worst timing error 0.

## Mistakes, and how they were found

- On paper, before any run: my first plan used `clkdiv=10` (10 ticks a bit).
  Counting ticks showed that after a mid-bit transition there were only two
  ticks left, not enough for the flag test and `pull` at a byte boundary.
  Changed to `clkdiv=5`.
- On paper, before any run: in the first layout the `b1` path reached the
  shared `one` code through a `jmp`, one tick late. Fixed by making `b0`
  leave with `jmp x-- one` and letting `b1` fall through into `one`.
- A prediction slip, not a firmware bug: I predicted a 690-cycle gap after a
  final 1 and the simulator showed 685. I had counted a `jmp msg` that I had
  already removed by letting the gap loop fall into `msg`. Recounted: 685.
- No bug was found by simulation. The first assembled version is the one
  handed in.

## Rule slips

None that I know of. I read and wrote only in this directory, did not list
or open anything else, did not use the web, and ran `pe_sim` only as
`./pe_sim` from here. Temporary files I made here and deleted: `tx_ex.txt`,
`tx_test.txt`, `__pycache__/`. `check.py` is left here as evidence.

## Result

- Program length: 32 instructions (one page, start 0).
- Host word format: one 16-bit word per data byte. Bits 7..0 are the byte
  (sent least significant bit first), bit 8 is 1 on the last byte of a
  message and 0 otherwise, bits 15..9 are 0. A message of n bytes is n
  words. No length word, no separate start, end or gap words.
- `run_args.txt`: `-config out_base=0,out_count=1,threshold=8,clkdiv=5 -mode 0=pp`
- I believe it works: 16 simulated cases (75 messages in all, including
  32-byte ones and the all-0 and all-1 extremes) decode correctly with zero
  timing error.

Known limits, by design: a host that fails to supply the next byte of a
message in time would stretch that bit (the `pull` stalls). TASK.md says not
to worry about this. Between messages a slow host is harmless.

## What was confusing or missing in isa.md

- The delay syntax is never shown. The Encoding section describes the delay
  field but no example writes one. I guessed PIO's `[n]` after the operands
  and it worked. The same goes for the comment character (`;` appears only
  inside the side-set example) and for labels.
- `jmp` syntax is given two ways: the table says `jmp cond, addr`, the prose
  example is `jmp x-- l` with no comma. I used the form without a comma. I
  did not test the comma form.
- Reset values of X, Y, OSR and ISR are not stated. I set Y explicitly and
  did not rely on any of them.
- It is not stated that `out` may keep shifting past `threshold` when
  autopull is off. I relied on it (8 data bits counted by `!osre`, then one
  more `out x, 1` for the flag) and it works in the model.
- There is no way to invert a register or toggle a pin, and the document
  does not say so or suggest an idiom. For a transition code this is the
  first thing one needs. `jmp y-- next` plus `mov pins, y` with
  `out_count=1` does it, at the cost of Y.
- With X and Y both taken (bit and toggle counter) there is no register for
  a bit or byte count, so the message length had to be a flag in each word
  and the previous bit had to be code position, which doubles the bit
  handler.
- The operand list for `mov` stops at `null` 5, while the `mov` text lists
  `crc` and the history says it is location 6. The same list says source or
  destination 6 or 7 decode as `nop`, which contradicts `crc` being 6.
- `pe_sim run -help` does not say what number format the `-tx` file takes
  (decimal worked), what the output lines mean (`pins CYCLE HEX`), or
  whether the cycle printed is the one in which the write executes or the
  one in which the new level is first seen. From the first fall at 821
  (the `mov` executes in cycle 820) it is the latter.
- TASK.md's "the thread may run every cycle" could be read as forbidding
  `clkdiv`. I read it as permission, not a requirement, since `clkdiv` is a
  `-config` field and `run_args.txt` exists to carry those.
- I found nothing in isa.md that the simulator contradicted.
