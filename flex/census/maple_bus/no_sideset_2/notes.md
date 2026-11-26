# Notes: Maple bus transmitter

## What I read

- `TASK.md`, in full (187 lines, read in one pass).
- `isa.md`, in full, in three parts (lines 1-200, 200-400, 400-607).
- The help text of `pe_sim run` (run 1 below).
- Nothing outside this folder. I did not open `pe_sim` or `pe_sim.real` as files; I only ran `pe_sim`.

## Design

Files handed in: `maple_bus.s`, `run_args.txt`, this file. `check.py` and `tx_example.txt` are my test helpers, left in the folder.

Configuration (`run_args.txt`):
`-config set_base=0,set_count=2,threshold=16,out_msb_first=1,crc_poly=0x80,crc_init=0 -mode 0=pp -mode 1=pp`

**Driving the lines.** `set pins` with `set_base` 0 and `set_count` 2 writes both lines at once, value = A + 2B. The program always knows the level of both lines from its flow of control, so every step is a `set pins` of the full state. Every `set pins` carries delay `[11]`, so any two writes are at least 12 cycles apart; that meets both the 12-cycle same-line limit and the 7-cycle other-line limit without any further counting. A write that leaves a line at its level makes no change, so it is harmless.

**Bit coding.** Every host word is 16 bits and the checksum is 8, so each word starts on an even frame bit: a word is 8 pairs of (even bit clocked by A, odd bit clocked by B). The bit value comes from `out x, 1` (MSB first) and a `jmp !x`. I folded step 1 of each even bit ("A goes high") into the end of the preceding odd bit, which also is exactly the first step of the end pattern. Then:

- Even bit v, entered with A high: v=1 writes 3 (B up), 2 (A down); v=0 writes 1 (B down, only if it was high), 0 (A down). The v=0 path's first write is what makes bit 0 correct right after the start pattern, where B is still high.
- Odd bit v, entered with A low: writes 2 (B up); then v=1: 3 (A up), 1 (B down); v=0: 0 (B down), 1 (A up). Both paths end with the shared `set pins 1`.

Each write changes at most one line (checked for every transition by hand and by the test).

**Word counting.** `!osre` with threshold 16 ends each word, so no bit counter is needed. Y counts the words still to come after word 0, which is 2N + 1. There is no add instruction, so I build it in the ISR (which shifts right, new bits at the top): `set x,1; in x,1; in y,8; in null,7` gives 2N + 1, where Y = N came from `out y, 8` on a copy of word 0 (the OSR is then restored from X with `mov osr, x`, which resets its shift count).

**Checksum.** There is no XOR instruction. The CRC register does it: with polynomial 0x80 (x^8 + 1 written low power first) and init 0, each bit does R = (R >> 1) xor (0x80 if bit != R0), which is an 8-bit rotate with XOR. After whole bytes, R bit t is the XOR of every byte's bit (7 - t): the checksum bit-reversed. Every frame bit passes through `out x, 1`, which feeds the CRC; `mov crc, null` restarts it after the `out y, 8` used to read N. To un-reverse: `mov osr, crc` (0x00RR), `out null, 8`, then 8 times `out x,1; in x,1`; with OUT taking the MSB first and IN entering at the top, ISR[15:8] ends up as the checksum. `in null, 8` moves it to the low byte, `mov osr, isr; out null, 8` leaves exactly 8 bits for the same bit-pair loop.

**Phase flag.** After a word ends, the program must know whether it was a data word or the checksum. The ISR count does it: it is cleared to 0 for the data phase, and the checksum preparation leaves it at 16 (full). `jmp !isrf dataw` sends data-phase ends to the word counter and checksum ends to the end pattern.

**Framing and idle.** Start pattern: 10 writes (2, 0, 2, 0, 2, 0, 2, 0, 2, 3). End pattern from (A,B) = (1,0): 3, 1, 0, 1, 0, 1, 3. Before every frame an idle loop of 8 x 16 = 128 cycles (`jmp x-- idle [15]`), then `pull` waits for word 0, so after the last frame the thread stalls in `pull` with both lines high. No autopull, so a frame never reaches into the next frame's words.

**Program length: 61 instructions** (fits in page 0, so no page handling).

Measured timing (from the test runs): first change at cycle 142, largest gap inside a frame 60 cycles (across the checksum preparation), idle between frames 154 cycles, minimum spacings met everywhere. A bit takes about 25 to 50 cycles; a 1025-byte frame takes about 330,000 cycles.

## pe_sim runs (12 in total)

1. `./pe_sim run x.s -help`: printed the run flags and the config field names. Showed `sideset_base` and `sideset_count`, which isa.md never mentions (see below).
2. `./pe_sim asm maple_bus.s`: assembled with no error, 61 words.
3. Example frame from TASK.md (words 0x0000, 0x2001), 6000 cycles: 98 changes, identical to the table in TASK.md change for change (compared with my generator of the ideal sequence, which I also checked against the table's start and end rows). Largest gap 60 cycles.
4. to 9. `check.py SEED 4` for seeds 0 to 5: four frames each, N chosen from 0, 1, 255 and random, random bytes (seeds 1 and 4 with sender, command and all data 0xFF). Frame sizes up to 1025 bytes, up to 47,106 changes. All matched the ideal sequence exactly; no timing violation; max gap 60; idle 154; first change at 142.
10. `check.py 6 1`: one frame of 169 bytes, matched, no violation.
11. `check.py 7 2`: two short frames, matched, no violation.
12. `check.py 10 3 3`: three frames with N up to 3, matched, no violation.

`check.py` writes the words to a file, runs `pe_sim run maple_bus.s -tx FILE -cycles C` plus `run_args.txt` (one pe_sim run per call), turns the `pins` lines into a list of changes, compares it with the sequence built from the rules in TASK.md (start pattern, three steps per bit, end pattern, checksum computed in Python), and checks: no simultaneous changes, at least 7 cycles from the other line, at least 12 from the same line, at most 100 inside a frame, first change by 50,000, idle 100 to 50,000, and nothing extra after the last frame (any extra change would break the exact match).

## Mistakes

None found in testing: the first version passed every run. Before writing it I caught two things on paper: the even-bit step "A high, B low" would wrongly pull B down for bit 0 when that bit is 1 (fixed by writing 3 then 2 for v=1, which is a no-op on (1,1)), and a plain `jmp y--` loop counting N would have skipped word 1 (fixed by counting 2N + 1).

## Confusing or possibly wrong in isa.md

- The simulator's config list has `sideset_base` and `sideset_count`, but isa.md has no side-set anywhere: not in the encoding (the 4-bit delay field fills bits 12:9) nor in the assembler syntax. I did not use them.
- The encoding diagram labels bits "15 13 12 9 8 0": op is 3 bits [15:13], delay is 4 bits [12:9], operands [8:0]. Consistent, but the delay field being 4 bits leaves no room for side-set, which fits the point above.
- `in` says it "shifts count bits right into the ISR" and only says for `in_msb_first` that new bits enter at the bottom; that the default enters at the top I inferred (as on PIO). The checksum result confirms it.
- `mov` reading `crc` "stops following the data" until the next write; it is not said whether `out` instructions after that still change it. It did not matter here because I restart it with `mov crc, null` every frame.
- The CRC section does not say plainly in which order the bit enters or which way the register shifts for a polynomial narrower than 32 bits; I worked it out from the one-line rule, and the test confirmed it.
- It is not stated what `in` does when the ISR count is already at the threshold without autopush; I avoided relying on it by clearing the ISR first.

No rules broken: I read and wrote only inside the folder, used no em-dashes, and used 12 pe_sim runs.
