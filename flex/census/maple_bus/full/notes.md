# Notes: Maple bus transmitter

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `./pe_sim run ... -help` output (run 1).
- Nothing outside this folder. One accident to report: my first shell command
  printed TASK.md and isa.md with `cat`, and the tool saved the long output to
  a file outside the folder and showed me only its first 2 KB. I did not open
  that saved file; I read the two documents again with the file reader, from
  this folder.

## Design

Pins: P0 = SDCKA (A), P1 = SDCKB (B), both push-pull.

The trick that makes the code short is giving each line its own way of being
written, so that no write ever has to know the other line's level:

- `set pins` writes A only (`set_base=0, set_count=1`).
- `out pins` and `mov pins` write B only (`out_base=1, out_count=1`).

An even bit (clock A, data B) is then branch free: `set pins,1` (A high),
`out pins,1` (B = the bit, straight from the OSR), `set pins,0` (A falls). An
odd bit (clock B, data A) needs B high, A = bit, B low. B low is
`mov pins, null`. B high needs a register whose bit 0 is 1; I keep the ISR at
the constant 1 for that (`mov pins, isr`). A = bit takes `out x,1` and
`jmp !x`, skipping `set pins,1` when the bit is 0 (A is already low there,
since it just fell). Writing a level a line already has prints no change, which
is exactly the "a step that finds its line at that level makes no change" rule.

Timing: consecutive steps are 7 cycles apart (two steps on the same line are
then at least 14 apart), set with delay fields. The odd-bit branch is padded
so that B's fall is at least 12 cycles after B's rise on both paths. A pair of
bits takes 40 cycles (odd bit 0) or 47 (odd bit 1). Extra instructions at word
boundaries (pull, loop jumps, checksum preparation) only lengthen gaps, which
can never break a lower limit; the longest gap inside a frame measured was 52
cycles (limit 100).

Shifting: `out_msb_first=1`, `threshold=16`, no autopull. The pair loop runs
until `!osre` fails, i.e. 16 bits (8 passes). Word 0 is pulled first, copied
to X, `out y, 8` takes N into Y, then `mov osr, x` restores word 0 (count 0,
full) and `mov crc, null` restarts the CRC, so the one garbage bit that the
`out y, 8` fed to the CRC is discarded. The frame body is two copies of the
pair loop (first and second 16-bit word of a 32-bit unit) inside a
`jmp y-- wl` loop that runs N + 1 times: the first pass is the header (word 0
already in the OSR, so the first pass jumps past the `pull`), the rest are the
data words.

Checksum: there is no XOR instruction, so I use the CRC register. With
`crc_poly = 0x80` and `crc_init = 0`, each OUT's first bit b gives
reg = (reg >> 1) ^ (0x80 if b != reg[0]). That is an 8-bit rotate with the
input XORed in, so after whole bytes fed MSB first the low byte is the XOR of
all bytes, bit reversed (checked by hand on 0x80 then 0x80). Every bit sent is
sent by an OUT of one bit (`out pins,1` or `out x,1`), so the CRC sees every
frame bit exactly once. To undo the reversal: `mov osr, crc`, `out null, 8`,
then 8 times `out x,1` / `in x,1` (IN shifts right, `in_msb_first=0`, the bit
enters at the top), `in null, 8` moves the checksum to ISR[7:0], `mov osr, isr`
and `out null, 8` leave it in OSR[15:8] with the count at 8, so the third copy
of the pair loop sends exactly 8 bits. Since the ISR is now used up, that copy
and the end pattern use Y = 1 as the "B high" source.

Start pattern: A-, then a 4-pass loop of B- / B+, then A+. End pattern: A
high (no change if already high), B+, B-, A-, A+, A-, A+, B+, all as separate
single-line writes 7 or 12 cycles apart. Idle: the last B+ and the `jmp`
carry delay 15, and each of the 7 instructions before the next start pattern
carries delay 15, so the idle between frames is 144 cycles (limit 100 to
50000). When the words run out the thread stalls on `pull` with both lines
high. The first change is at cycle 113 (limit 50000).

Configuration (`run_args.txt`):
`-config set_base=0,set_count=1,out_base=1,out_count=1,out_msb_first=1,threshold=16,crc_poly=0x80 -mode 0=pp -mode 1=pp`

## pe_sim runs

To check runs I wrote a small Python script in this folder (now deleted, so
that only the hand-in remains). It built the TX word file for a set of frames,
ran `./pe_sim run maple_bus.s -tx FILE -cycles C` plus `run_args.txt`, turned
the `pins` lines into a list of A/B changes, and compared it change for change
with the list generated from the TASK.md rules (its generator reproduces the
98-change table of the example exactly). It also checked: no two lines in one
cycle, 7 cycles to the other line, 12 to the same line, at most 100 inside a
frame, first change by 50000, idle between frames 100 to 50000, and nothing
after the last frame (cycles ran well past the end). Each check is one pe_sim
run.

1. `./pe_sim run t0.s -help`: flag list (config field names match isa.md).
2. `./pe_sim asm maple_bus.s`: assembles, 62 words.
3. Example frame (0x0000, 0x2001): 98 changes, all in the expected order;
   min same-line gap 12, min other-line gap 7, max gap in frame 52, first
   change at cycle 113. OK.
4. Same run printed raw, to check my parsing: starts `pins 0 ff`, then
   `pins 113 fe` (A-), `121 fc` (B-), ... as expected.
5. Example frame then the 0xDEAD/0xBEEF frame (checksum 0x2B): 260 changes,
   idle 144. OK.
6. to 11. Six random runs (seeds 1 to 6: 1 to 4 frames, N from 0, 1, 2, random,
   255, random bytes): all OK, including a 3-frame run with 35296 changes.
12. Four frames with N = 255: 65664 changes, all OK, last change at cycle
    717605.
13. Four frames with N = 0: OK.
14. to 17. Four more random runs (seeds 9 to 12): all OK.
18. Edge cases: N=3 all 0xFF, N=2 all 0x00, N=1 alternating 0xAA/0x55,
    N=255 all 0xFF data: 17094 changes, all OK.

Total: 18 pe_sim runs (one `-help`, one `asm`, 16 simulations). No run
showed a failure, so there were no bugs to fix after the first version.
Mistakes during design (caught on paper, before any run): my first idea used
`set pins` on both lines with branches for every bit, which needed far more
instructions; and I first tried a single shared pair loop with a phase flag,
but there is no free register for the flag, so I used three copies of the
loop instead.

## Program length

62 instructions (all in page 0, so no page handling is needed).

## What was confusing or possibly wrong in isa.md

- `in` with the default (right) shift: isa.md says only "shifts count bits
  right into the ISR". It does not say where the new bits enter (bit 15, or
  bit threshold-1 as a PIO-like 16-bit view would suggest) nor which bits of
  the source are taken (I assumed the low `count` bits). My checksum reversal
  relies on bits entering at bit 15 with threshold 16; the runs confirm it.
- The CRC register "stops following the data" after a `mov` reads it.
  isa.md says writing `crc` restarts it from `crc_init`, but not explicitly
  that it then follows the data again. Multi-frame runs show it does.
- There is no XOR or bit-test instruction, so a checksum needs the CRC
  register used as an XOR accumulator; the reflected (LSB-first) CRC then
  hands back the checksum bit reversed relative to an MSB-first OSR. Worth a
  sentence in isa.md, since any MSB-first protocol with an XOR or CRC trailer
  will hit it.
- `pe_sim run` prints a `pins 0 ff` line for the initial state at cycle 0,
  which isa.md does not mention ("prints whenever the pins' output changes").
- `mov` has no invert or bit-reverse source operation (PIO has both), which
  is why a constant-1 register and a reversal loop are needed.
- Minor: the side-set delay field note says delays are "0 to 15, or 0 to 7, 3
  or 1"; that is consistent, just dense.
