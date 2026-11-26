# EM4305 reader TX firmware: notes

## What I read
- TASK.md and isa.md, both in full. Nothing else outside this folder.
- Rule slip (accidental, minor): my very first command printed both files with `cat`. The output
  was too long, so the tool saved it to a file outside this folder and printed that path. I did
  not open that file or follow the path; I re-read TASK.md and isa.md with the file reader.

## Files handed in
- `em4305.s` (the program), `run_args.txt`, this file.
- Helper files I also left in the folder: `t1.s` (semantics test) and `check.py` (my own checker,
  which builds the expected bits from the words, runs pe_sim and checks every edge).

## Design
Clock and pin: `clkdiv=40`, so one tick of the thread is 40 cycles, half a carrier period.
Side-set with one bit on P0 means every instruction drives P0. In carrier-on stretches the code
alternates `side 1` and `side 0` with no delays; in field-off stretches every instruction is
`side 0` and delays are free. Because every instruction is exactly one tick, all edges land on
exact multiples of 40 cycles (cycle 40k+1), so the ±2 cycle limit is met with no error at all, as
long as the tick counting is right. Each bit is 64 ticks: ticks 0..31 always carrier, ticks 32..63
carrier for a 1 and low for a 0.

Line structure. I noticed the code bits can be cut so that every piece ends with a parity bit:
Login is `[0 0 0 1] P [byte0] P [byte1] P [byte2] P [byte3] P [col] stop`, since the parity of
0001 is 1, which is the fifth code bit. Write is `[0 0 1 0] P [A0 A1 A2 A3 0 0] P [byte0] P ...`,
since the parity of 0010 is 1 (the fifth code bit) and the address parity then covers exactly
A0..A3 0 0. So the engine only knows "data rows followed by a parity bit", plus the column row and
the stop bit.

Registers. OSR holds data, shifted MSB first, with `threshold=8`, so the OSR reads empty at the end
of each row (`jmp !osre`). Y is the running parity of the current row (toggled on each 1 bit,
cleared by each parity bit). The ISR value is a phase code F that says what the next row-end
event does. X is scratch and the loop counter. The CRC register (`crc_poly=0x80`, init 0) is an
8-bit rotate-and-xor ring, which after the 32 data bits holds the column parity bit-reversed.

Per bit (t = tick in the bit): `bit:` tests `!osre`. Data bit: `out x,1`, branch on X, toggle Y
for a 1, preset X and enter a carrier fill loop that ends exactly at t31, then a one-tail (16 more
carrier periods) or an off-tail (32 low ticks). Row end (OSR empty): `mov x,isr` and a chain of
`jmp x--` tests dispatch on F; the first decrement is written back (`mov isr,x`), so F counts down
by itself. Each handler does its work, presets X for the time left, and jumps to `par`, which sends
Y as the bit and clears Y. Handlers by F: 6 Write prefix row end (`mov osr,osr; out null,2`);
5 pull lo, byte swap (`mov x,osr; in x,16; in x,8; mov osr,isr`), restart CRC; 4 and 2 row end
inside a word (`mov osr,osr`); 3 pull hi and swap; 1 read CRC, reverse it through the ISR with
8x(`out x,1; in x,1`), load it; 0 stop bit (forced 0), set F=9; F>=7 back to the gap.

Gap and setup (page 1): from reset the first instruction is `side 0` (fall at cycle 1, rise at 41).
A 10 x 33 period carrier loop, then `pull` the command word on a low tick (after the last command
the thread stalls there with P0 low, after 337 whole pulses). The first OSR word is built in the
ISR: Login 0x0100, Write [0 0 1 0][0 0][A0 A1 A2 A3 0 0] (the address bits are reversed one at a
time), then `out null,4` so the first row is 4 bits. Then 111 low ticks (the last pulse's low plus
the 55-period field stop) and a jump to `bit`. Measured field-on before a command: 335 periods
(Login first command), up to 347 between commands; limit 320 to 1280.

Pages. Jumps reach only one 64-word page. Page 0 holds the bit engine. The column handler is
straight-line and runs off the end of page 0 into page 1 with PAGE still 0, ending in a jump back
to page 0. Gap, setup and the pull-hi handler run with PAGE=1 (`set page` before the jump in, and
before the jump out). `start=80` is the gap entry.

## Program length
122 instructions (122 words, addresses 0..121, no padding).

## pe_sim runs (42 in all)
1. `pe_sim run x.s -help`: list of flags and config field names.
2. `pe_sim` alone: list of subcommands.
3. t1.s v1: byte swap gave 0x3412 (right). Other pushes read 0 or 1. Cause: `push` sends only
   the bits shifted since the last push, right-justified, and `mov isr,...` resets that count.
4. t1.s v2: CRC ring after 0x8001 fed MSB first = 0x81 (my model of poly 0x80 confirmed); raw
   ISR after `in x,10` with x=1 is 0x40 (bits enter at the top); `out null,4; out x,4` leaves the
   OSR empty with x=5; `mov osr,osr` resets the count; second CRC read gives 0; RX is drained.
5. `pe_sim asm em4305.s`: assembled with no errors, 122 words; gap at address 80.
6. check.py on the example (Login 0x12345678, Write 4 0xDEADBEEF): Login correct, Write reported
   as short. Mistake was in my checker: it ran too few cycles (bits counted as 80 cycles, not
   2560), so the simulation ended mid-command.
7. Decoded the Write by hand from the same kind of run: bits matched up to where the run ended.
8. Fixed checker, example: no errors.
9. Checker sanity test: with one expected bit flipped on purpose it reports the error, so it is
   really checking edges.
10. Single Login: first fall at cycle 1, rise at 41; field on 335 periods before the stop; 337
    pulses after the command, then P0 stays low.
11. Example again (start of the random batch): no errors.
12-41. 30 random runs, 1 to 6 commands each, random Login/Write, address, value (skipping values
    with nine 1s in a row): all passed, every edge exactly on its ideal cycle.
42. Edge cases in one 6-command run (zero data, address 0 and 15, 0x7F7F7F7F, 0x80808080,
    0x80000001, 0x3CC3A55A): no errors.

## Mistakes found
- Push semantics (run 3), see above: a misunderstanding in my test, not in the firmware.
- Checker cycle-count bug (run 6), as above.
- No firmware bug showed up in testing. All tick counts were worked out on paper before the
  first run.

## Confusing or possibly wrong in isa.md
- `in`: "shifts count bits right into the ISR" and "bits arrive least significant bit first" does
  not say plainly where new bits go. They enter at bit 15 and move down (run 4).
- `push` sends only the bits shifted in since the last push, and `mov isr` resets that count, so
  a value moved into the ISR cannot be pushed as it is. It follows from the text but is easy to miss.
- One `threshold` serves both the OSR and the ISR, which rules out using the two counts for
  different lengths.
- The assembler also follows `set page` in the listing (after `set page,1` it accepted a jump to a
  page-1 label), and `.page n` works in the middle of a page. isa.md only mentions `.page` and
  `.align`.
- There is no call/return, no XOR and no bit inversion, so parity has to come from the CRC register
  or from branches. Most of the program's size comes from that, not from timing.
- Not wrong, but worth stating: side-set holds through a stall, which is what lets `pull` stall with
  P0 low after the last command.
