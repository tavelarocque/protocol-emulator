# Notes: MIPI RFFE master on the protocol emulator

## What I read

- TASK.md, in full (two parts: lines 1 to 139, then 140 to the end).
- isa.md, in full (three parts: lines 1 to 179, 180 to 359, 360 to the end).
- `./pe_sim run x.s -help` (run 1 below).
- Nothing outside this folder.

## pe_sim runs

1. `./pe_sim run x.s -help`: lists the flags (-config fields, -cycles,
   -inputs, -mode, -stimulus, -tx). Matches isa.md.
2. `./pe_sim asm probe.s` (probe of my own): assembles; printed words.
3. `./pe_sim run probe.s ...` with one TX word 0x00A7: showed that the
   thread's first instruction runs in cycle 0 (its write shows as `pins 1`),
   that a pull at cycle 1 finds the host word already there, that side-set
   on P0 and `out pins,1` on P1 behave as described, that the CRC register
   with crc_poly=1, crc_init=1 gives the odd parity bit (0 after 0xA7's five
   ones, 1 again right after `mov crc, null`), that `push` right-justifies
   with in_msb_first, and that eight pushes three cycles apart never stall
   (the simulated host drains the RX FIFO).
4. `./pe_sim asm mipi_rffe.s` (first full program): assembly error at
   line 157, "jump to endx in page 2, but PAGE is 0 here". My mistake: the
   assembler follows PAGE down the listing, and after `set page, 0; jmp END`
   in the middle of the page-2 engine it believed the lines below ran with
   PAGE 0. Fixed by putting `.page 2` after that `jmp END`.
5. `./pe_sim asm mipi_rffe.s`: assembled, 190 words. From the listing,
   INIT is at address 71, so `start=71` in run_args.txt; 52 of the words are
   the `.align` padding (nop) before page 2.
6. TASK.md's example (Register Write 0xA7 to 0x13 of slave 5, Register Read
   of 0x1F of slave 7 answering 0x3C), through my checker (below). The
   stimulus file my generator wrote was exactly the one in TASK.md (0 ff,
   1332 fd, 1384 ff, 1464 fd, 1504 ff, 1524 fd, 1534 ff) and N was 1760.
   PASS: 94 SCLK edges, every one at its exact place (error 0), rx 0x3C,
   release at r(b)+18, SDATA taken back at r(e)+8.
7. One sequence of each kind 0 to 6 (n = 1,1,1,10,10,1,4): PASS, all 796
   edges exact, 15 bytes read back correctly. I also looked at the raw
   output by eye: SSC high at 400, low at 420, SCLK up at 440, down at 450,
   and so on.
8. Kinds 3,4,5,6 at their longest (n = 16,16,8,8): PASS (1088 edges, 24
   bytes).
9. Kinds 3,4,5,6,3,4,5,6 with n = 1,1,1,1,2,2,2,2 (8 sequences): PASS.
   (Then, without running pe_sim, I fed run 9's saved output back into the
   checker with a data byte, an address and a reply byte altered in the
   expectation: it reported FAIL each time, so the checker does catch
   wrong bits and wrong rx words.)
10. to 21. Twelve random runs (seeds 1 to 12: 1 to 8 sequences each, random
   kinds, n, slave addresses, register addresses, data and replies): all
   PASS, maximum edge error 0 in every run.
22. Extremes, all ones: kinds 0..6 then 0, slave 15, address 31/255/0xFFFF,
   data 0x7F/0xFF, n at its maximum, replies all 0xFF: PASS (25 rx words).
23. Extremes, all zeros: kinds 0..6 with slave 0 (1 for reads), address 0,
   data 0, replies 0, n = 1, then a kind 6 n=3 reading 0x80,0x01,0xAA: PASS.
   I checked the end of the saved outputs: the last pin change is both
   lines low, before S(R), so the lines stay low to the end of the run.
24. to 29. Six more random runs (seeds 101 to 606): all PASS.

Total: 29 runs of pe_sim (runs 2 and 4 to 5 were `asm`, 1 was `-help`).

## How I tested

I wrote a Python script (rffe_test.py, in this folder while I worked) that
builds a run from a list of sequences: the host words, the slave's stimulus
file exactly as TASK.md's table describes it, and N = S(R) + 100. It runs
`./pe_sim run mipi_rffe.s -tx ... -stimulus ... -cycles N` plus the
contents of run_args.txt, rebuilds P0, the chip's P1 and the slave's P1
cycle by cycle, takes the line as their AND, and checks: both lines low from
cycle 100 to the first SSC; the list of SCLK edges after cycle 100 against
the expected list (count and +-2 cycles); every SDATA change on the line is
an SSC edge or inside [R, F-3] of a clock, at most once per clock; SSC rise
and fall; the bit of every clock (line at F-1) against an independently
built bit list (command frame, parities, address frames, data, bus parks,
the slave's reply); for reads, the chip low at the turnaround, its release
inside [r(b)+12, r(b+1)+4], never pulling low in [r(b+1)+4, r(e)+4), and
taking SDATA back low inside [r(e)+4, r(e)+14] and holding it; idle low
between sequences; and the rx words against the reply bytes. I deleted the
script and all its temporary files (tx, stimulus, output, a probe program)
at the end so that the folder holds only what TASK.md asks for.

## Design

Configuration (run_args.txt): `start=71`, side-set 1 bit on P0
(sideset_base=0, sideset_count=1), out/set/in all on P1 (out_base=1,
out_count=1, set_base=1, set_count=1, in_base=1), threshold=16,
out_msb_first=1, in_msb_first=1, crc_poly=1, crc_init=1, clkdiv left at 1;
modes `-mode 0=pp -mode 1=od` only.

SCLK is the side-set bit, so every instruction says what SCLK is. SDATA is
written by `out pins,1` (data bits), `mov pins, crc` (parity bits) and
`set pins` (SSC, bus parks, the turnaround release). Each SCLK clock is a
block of exactly 20 cycles: the instruction that raises SCLK and puts the
bit on SDATA runs at r-1 (so both show at r), the one that lowers SCLK
runs 10 cycles later. Since a delay is at most 7 with one side-set bit,
each half clock is at least two instructions.

Parity costs nothing: with crc_poly=1 and crc_init=1 the CRC register's
bit 0 is 1 XOR (the OUT bits since the last restart), which is the odd
parity bit. `mov pins, crc` sends it; `mov crc, null` restarts it. Every
OUT feeds it one bit, so it is restarted after the header has been parsed;
the `out null, 8` that drops a data word's empty top byte feeds a 0, which
changes nothing.

The bits of a frame come from the OSR, most significant first; the ISR's
count says when the frame is over (the loop runs `in null,1` per bit and
`jmp !isrf`): the count starts at 8 for an 8-bit frame and at 4 for the
12-bit command frame, and 16 means done. Counting in the ISR instead of
the OSR lets the 16-bit address of kinds 5 and 6 be pulled once and sent as
two frames with no extra work: the first frame sends the top byte, the
second simply carries on shifting.

Between sequences (page 0, 1): after the last clock, a 96-cycle wait, then
`pull` the header, keep a copy in the ISR, take n into Y and the kind into
X, and branch on the kind (a chain of `jmp !x` / `jmp x--`). Each kind
shifts its 8 command-byte bits into the ISR behind the header (prefix bits
from `set`, then the 7-bit data, the 5-bit address or B = n-1), so the ISR
ends as kind:SA:command; each kind also sets X to the state to enter after
the command frame and Y to its count. Every path is padded to arrive at
the same cycle, S-1, where SDATA goes high (SSC); in the SSC the ISR is
copied to the OSR, the kind nibble dropped, the ISR count set to 4 and the
parity restarted; SDATA goes low at S+20 and the first clock rises at S+40.

The engine (page 2) is one frame loop and one parity clock shared by every
frame. In the parity clock, after the parity bit, the ISR count is set to 8
and X is decoded by a `jmp !x` / `jmp x--` chain into one of 8 states, each
padded so the next clock starts exactly 20 cycles later:

| X | state | does | then X |
|---|---|---|---|
| 0 | W | Y-- not 0: pull data word, frame; else bus park | 0 |
| 1 | HI_w | pull 16-bit address, frame (top byte) | 6 |
| 2 | HI_r | same | 5 |
| 3 | A_r | pull address word, frame | 7 |
| 4 | A_w | pull address word, frame | 0 |
| 5 | LO_r | frame (rest of the OSR) | 7 |
| 6 | LO_w | same | 0 |
| 7 | TA | turnaround and read | |

After the command frame: kind 0 is W with Y=0 (bus park at once), kind 1 W
with Y=1, kind 2 TA with Y=1, kind 3 A_w, kind 4 A_r, kind 5 HI_w, kind 6
HI_r, with Y = n for 3 to 6. Bus park (write): SDATA 0 at the rise. TA:
SDATA 0 at the rise of clock b, Y-- (bytes left after this one), let go at
r(b)+18 (window 12 to 24). Read clock: SCLK only, `in pins,1` at r+13 (the
slave's bit is on the line from r+4, seen by the thread from r+6 after the
two-flop synchroniser, until r+24). After 8 bits (ISR full) the slave's
parity clock pushes the byte (the ISR was 8 zero bits then the 8 data
bits, so bits 15..8 are 0), sets the count back to 8 and loops on Y.
Slave bus park: SDATA pulled low at r(e)+8 (window 4 to 14) and held.
Both end clocks go back to page 0 and the wait for the next sequence; when
the host's words run out, the `pull` of the next header stalls with both
lines low.

## Program length

138 instructions. The assembled image is 190 words: page 0 and the start
of page 1 hold the between-sequence code (76 words, start=71 is the start-up
code), then 52 `nop` words of `.align` padding, then the 62-word engine in
page 2. It does not fit in two pages; the engine alone fits in one.

## Mistakes I made

- Run 4: missing `.page 2` after a `set page, 0; jmp END` in the middle of
  page 2 (see run 4). No other mistakes showed up; the first program that
  assembled passed every test.

## Rules

- I read and wrote only inside the folder. I ran `which python3` once at
  the start, to see whether I could use Python for a checker; its output
  named the interpreter's path outside the folder, and I then ran that
  interpreter for my test script. I did not open or list anything outside
  the folder.
- No em-dashes in my files.

## Confusing or possibly wrong in isa.md

- The assembler follows PAGE "down the listing", which is documented, but
  it means any `set page, n` placed in the middle of a page's code (here,
  the jump home from the engine) silently changes the page assumed for all
  later lines until a `.page` directive; I only found it from the
  assembler's error. A sentence saying so next to `set page` would help.
- The CRC register takes a bit from every OUT, including `out null` and
  `out x` used only to parse a host word. That is what isa.md says, but it
  is easy to miss that parsing a word disturbs the CRC; I restart it after
  parsing.
- With one side-set bit the delay field is 0 to 7, so a half clock of 10
  cycles always needs two instructions; isa.md is right about this, it just
  makes clean bit loops longer than one might expect from "side-set makes a
  clock edge cost no instruction".
- `pe_sim run -help` names the config fields but not their defaults; isa.md
  gives them (out_count 1, set_count 1, threshold 8, the rest 0), which
  matched what I saw.
- I did not measure the input synchroniser's two-cycle delay directly; my
  sample point (r+13) has margin on both sides, and the reads came back
  right, so it is consistent with isa.md.
- I found nothing in isa.md that the simulator contradicted.
