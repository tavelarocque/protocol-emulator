# Notes: AVR PDI programmer firmware

## What I read

- `TASK.md`, in full (two parts: lines 1-100, then 100-190).
- `isa.md`, in full (four parts: 1-150, 150-300, 300-460, 460-607).
- `./pe_sim run x.s -help` output (run 1 below).
- Nothing outside this folder. I wrote only in this folder (the program, `run_args.txt`,
  these notes, and a scratch test folder `t/` that I deleted before handing in).

## Design

Pins and configuration (`run_args.txt`):
`-config out_base=1,out_count=1,set_base=0,set_count=1,in_base=1,threshold=8,crc_poly=1,crc_init=0,timeout=1996,timeout_vector=2 -mode 0=pp -mode 1=od`

- P0 (PDI_CLK) is written only by `set pins` (set_base 0, set_count 1), so a clock
  edge never touches P1.
- P1 (PDI_DATA) is written only by `out pins, 1` (data bits) and `mov pins, src`
  (start bit from `null`, parity from `crc`, stop bit from X = 1), with out_base 1,
  out_count 1. It is read with `in pins, 1` (in_base 1).
- There is no side-set in isa.md, so clock and data are separate instructions. Every
  data change is made 4 or 9 cycles after the falling edge, inside the allowed window
  (edge to 5 cycles before the rising edge). In every other slot P1 is never written
  (its output stays 1, released).
- Parity: the CRC register takes the first bit of every OUT. With crc_poly = 1 and
  crc_init = 0 the rule in isa.md ("if the bit differs from bit 0, shift right and add
  the polynomial, else shift") makes bit 0 the running XOR of the bits. I restart it with
  `mov crc, null` before the 8 data OUTs and put it on P1 with `mov pins, crc`, which is
  exactly the even-parity bit. Verified by the sessions below (every parity bit checked).

Timing: clkdiv 1 (every cycle). Every slot is coded as exactly 50 cycles: the
instruction that makes the falling edge runs at slot-local t0 (cycle 1999 + 50k, shown
at 2000 + 50k), the rising-edge instruction at t25. Code is stitched together at fixed
slot-local times (most hand-offs at t49 or t0), so the edges land on the ideal cycles
with no drift: the harness measured 0 cycles of deviation on every edge of every run.

Flow:
1. `set y, 15`, then `wait 0 pin 0 timeout` (P0 is high, so it always times out) is the
   40 us start delay: timeout 1996 lands in IDLE_ at cycle 1998, first falling edge at
   2000 (measured).
2. IDLE: Y + 1 idle slots, leaves at t49 into W. Used for the 16 enable slots, the end
   (16 slots), the 2nd stop bit of an unanswered instruction, and the 2 idle slots after
   an answer.
3. W (t49): `pull`, falling edge, `out x, 12` (byte and answer length), `out y, 4`
   (8 for the end word, else 0). End word: this slot plus 15 more idle slots via IDLE,
   then W again, whose `pull` stalls for ever on the empty TX FIFO: the clock stops high
   after the 16th rising edge, P1 released.
4. Frame: start bit (`mov pins, null`), `mov osr, x`, `mov crc, null`; 8 data slots with
   `out pins, 1` looping on `jmp !osre` (threshold 8); parity slot (`mov pins, crc`, then
   `out y, 4` = answer length, `set x, 1`); stop 1 (`mov pins, x`). Y = 0: the 2nd stop is
   one IDLE slot and back to W, so the next frame follows with no gap.
5. Answered: the length is kept in the OSR (`mov osr, y`), and loop G (X inner, Y outer,
   X = 1 and Y = 4 at entry: 2 + 4 x 32 = 130 slots) covers the 2nd stop bit, the 128
   guard slots and the ATxmega's start bit, then restores Y from the OSR.
6. AB: 8 slots, `in pins, 1` at t26 (one cycle after the rising edge, 20 cycles after the
   ATxmega's level is visible through the synchroniser), looping on `jmp !isrf`. Then the
   parity slot: `push` (the byte lands in bits 7..0), decrement Y, store it in the OSR.
   More bytes: X = 2, Y = 0 and back into G for 4 slots (parity, 2 stops, next start bit).
   Last byte: Y = 3 and IDLE for parity, 2 stops and the 2 idle slots, then W.

## pe_sim runs

1. `run x.s -help`: flag list. Showed config fields `sideset_base`/`sideset_count`,
   which isa.md does not describe; I did not use them.
2. `asm avr_pdi.s`: assembled, 60 words, IDLE_ at address 2 (my timeout_vector).
3. `run` on the TASK.md example (tx 0x0180, 0x00C1, 0x0059, 0x8000, stimulus from the
   example): first edge at 2000, last edge (rising) at 12475 as TASK.md says, rx 2.
   Learned that `pins` shows the output register (the ATxmega's levels do not appear).
4. Same example through my harness `t/check.py` (generates tx and stimulus, checks every
   P0 edge against 2000+50k / 2025+50k, every P1 change against the chip's sending
   windows, P1 at every rising edge against the expected bit, the end state, and the RX
   words): OK, max edge deviation 0.
5-8. Harness edge cases: one byte, one answered byte, a 15-byte answer followed by
   another answered instruction, three answered instructions back to back. The harness
   reported RX mismatches, which turned out to be my harness's bug: pe_sim prints rx
   words in decimal and I parsed them as hex. Fixed the parser and re-checked the saved
   outputs without re-running pe_sim: all 4 OK. I confirmed the checker catches errors by
   editing a saved output (a P1 change outside its window, a P0 edge 3 cycles late, a
   wrong RX word): each was reported.
9-23. 15 random sessions (seed 1, up to 70 bytes, answers 0 to 15 bytes, bytes 0x00 and
   0xFF favoured): all OK, deviation 0.
24. Example with a stimulus file with no cycle-0 line: output identical to run 3.
25. Example with `-inputs 00` and no stimulus (P1 held low by the outside the whole run):
   pin output identical to run 3, rx 0. This shows `wait 0 pin 0` watches P0, not
   pin 0 counted from in_base (which would be P1 and would have ended the wait at once),
   so the start delay does not depend on the ATxmega's line.
26. Empty session (only the end word): OK (16 enable + 16 end slots).
27-36. 10 answer-heavy sessions (5 to 12 instructions, many 15-byte answers, up to 2758
   slots and 91 answer bytes): all OK, deviation 0.

Total: 36 runs of pe_sim (one attempted batch failed in my own Python before calling
pe_sim, so it ran nothing).

## Mistakes found

- First layout ideas (branching on each data bit with `set pins` writing both pins, then
  a version with separate slot code everywhere) came to about 100 instructions, over the
  64-word page; I redesigned on paper before writing any code (CLK by `set`, DATA by
  `out`/`mov`, parity by the CRC register, a shared guard/answer loop) to get 60.
- The harness parsed rx words as hex (they are decimal). Firmware was right.
- No firmware bug was found by any run.

## Program length

60 instructions (60 words, one page, addresses 0 to 59).

## Things in isa.md that were confusing or seem wrong

- `wait pol pin n`: isa.md does not say whether n is an absolute pin or counted from
  `in_base` (PIO's `wait pin` is relative). Run 25 shows it is absolute here (or at
  least not relative to in_base = 1). Worth stating.
- `pe_sim run -help` lists `sideset_base` and `sideset_count` config fields, but isa.md
  has no side-set at all (no encoding bits for it, no syntax). Either the doc or the
  tool is out of date.
- The `rx` lines of `pe_sim run` print the word in decimal while `pins` prints hex, and
  isa.md does not say which; easy to misread.
- `pins` shows the output register, not the pin level, for open-drain pins; isa.md says
  "the pins' output", which is right but easy to read as the line level.
- The ISR's internal layout for right shifts (where new bits enter) is not stated, only
  that `push` is right-justified; I avoided depending on it (only `push`).
- `mov dst, crc` freezes the CRC until the next write ("stops following the data"): fine,
  but it means the read is destructive, which is easy to miss.

No rule broken that I know of.
