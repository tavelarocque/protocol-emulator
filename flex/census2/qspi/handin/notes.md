# Notes: Quad SPI page-program firmware

## What I read

- `TASK.md` in full (183 lines), in one read.
- `isa.md` in full (699 lines), in four reads of about 180 lines each.
- Nothing outside this folder. `pe_sim -help` text (run 1 below).

## Design

Pins: P0..P3 are IO0..IO3, written by `out pins` (out_base 0, out_count 4).
SCK (P4) and CS# (P5) are side-set (sideset_base 4, sideset_count 2, side
bit 0 = SCK, bit 1 = CS#), so every instruction states the bus control lines
and the remaining delay field is 2 bits (0 to 3). Side values used:
2 = idle (CS# high, SCK low), 0 = CS# low with SCK low, 1 = CS# low with SCK
high. The very first instruction has side 2, so SCK is low from cycle 1.

Each bit (or nibble) takes two instructions: an `out pins` with SCK low,
which changes the data, then an instruction with SCK high, which changes no
IO line. So data is stable one cycle before each rise and one cycle after
it, and IO lines only change in SCK-low cycles. The instruction after a
frame's last rise has side 2, so CS# rises one cycle after the last rise in
a cycle where SCK is low. The first `out pins` of a frame has side 0, so
CS# falls with SCK low and the first rise comes one cycle later.

The OSR shifts MSB first (out_msb_first=1), threshold 16, autopull off.
Autopull is off on purpose: with it, the out that empties the last data
word would prefetch the next page's first address word, and I need the OSR
free to send the constant bytes 0x06 and 0x32 (loaded with `mov osr, x`).
Every host word is fetched with an explicit `pull`, which costs nothing
that matters given the 20-cycle limit between rises.

Per page:
1. `pull` the A23..A16 word (this is where the thread idles forever, CS#
   high, SCK low, once the host's words have run out, so no extra WREN is
   ever sent), save it in Y.
2. WREN: `set x, 6; mov osr, x; out null, 8`, then 8 single-line bits.
3. 0x32: `set` only takes 5 bits, so `set x, 25; mov osr, x; out null, 9`
   leaves 0x3200 in the OSR (25 << 9), then 8 single-line bits (the 17th
   bit shifted is a zero filled in from below, as isa.md says an `out`
   past the threshold gives zeros). CS# is high 4 cycles between WREN and
   QPP.
4. Address: Y back into the OSR, then a 3-iteration loop (Y as counter):
   `out null, 8`, 8 single-line bits, `pull`. The third pull fetches the
   first data word.
5. Data: `out null, 7`, `out y, 1` (the last-byte flag), `out pins, 4`
   (bits 7..4 to IO3..IO0), rise, `out pins, 4` (bits 3..0), rise with
   `jmp !y more`; `more` pulls the next word and loops. On the last byte
   it falls through to `mov x, isr side 2`, which raises CS#.
6. Wait: the ISR was set once at start-up by `set x, 21; in x, 5`, which
   with the default right shift puts 21 in bits 15..11: 43008. The loop
   `jmp x-- wait [3]` with X = 43008 takes 43009 x 4 = 172036 cycles; with
   the instructions around it the measured CS# high time from the QPP's
   rise to the next WREN's fall is 172044 cycles (limits 150000 to 200000).

Timing measured: first WREN CS# falls at cycle 9; gap WREN to QPP 4 cycles;
gap between pages 172044 cycles; at most 6 cycles between neighbouring SCK
rises; SCK low from cycle 1.

## pe_sim runs (8 in total)

1. `./pe_sim run x.s -help`: printed the run flags (config field names,
   -cycles, -inputs, -mode, -stimulus, -tx).
2. `./pe_sim asm qspi.s`: assembled without errors, 35 words.
3. Run on the TASK.md example (2 pages, 4 and 8 bytes), 414160 cycles: 229
   lines. Decoded with my script `check.py` (my own decoder of frames,
   bits, gaps and the limits in TASK.md): all OK, 8 and 40 rises for page
   0, 8 and 48 for page 1, gaps 4 and 172044. I also read the data phase
   lines by eye: nibbles D E A D B E E F on IO3..IO0 at the rises, CS#
   rising one cycle after the last rise. It also showed that `out pins, 1`
   with out_count 4 writes only P0 (P1..P3 stayed at 1 from reset).
4. to 8. Five generated runs (`gen.py`, words in t1..t5.txt, outputs in
   o1..o5.txt), N computed by the TASK.md formula: 6 pages of 256 bytes at
   page-aligned addresses including 0xFFFF00 (1282480 cycles); 6 pages of 4
   bytes at 0xFFFFFC and 0x000000; 6 random pages; 1 random page; 3 random
   pages. Data mixes 0x00, 0xFF and random bytes. `check.py` reported OK for
   all five: right frame count, WREN bits, command, address, data nibbles,
   setup and hold, the 20-cycle limits, the gaps, and an idle bus (CS# high,
   SCK low) to the end of each run.

## Mistakes found

None in the program that I found; it passed on the first run. My only
uncertainty before running was whether `out pins, 1` writes one pin or
out_count pins and how a 4-bit `out pins` maps to P0..P3 with MSB-first
shifting; run 3 settled both (first bit shifted lands on the highest pin of
the group, i.e. the value's top bit is IO3, as hoped).

## Rules

I believe I kept every rule: only files in this folder were read or
written, no web, and no em-dashes. Helper files I wrote here: `check.py`,
`gen.py`, `ex.txt`, `t1..t5.txt`, `out1.txt`, `o1..o5.txt`.

## Confusing or possibly wrong in isa.md

- `out pins, N` does not say whether it writes N pins or `out_count` pins.
  The simulator writes N pins (with N = 1 only P0 changed).
- With `out_msb_first`, the doc says the bits come "from bit 15 of the OSR
  downward" but does not spell out which of them lands on `out_base`. The
  general rule (bit k of the value on pin base + k) plus "right-justified"
  for x/y implies the first bit shifted out is the top bit of the value and
  goes to the highest pin; the simulator agrees.
- The reset/start of `PAGE` and of the run itself: the doc says the first
  `pins 0 ff` line is the starting state, and the first instruction's write
  shows at `pins 1`, so the thread executes in cycle 0. Clear enough once
  run.
- `set` takes only 5 bits (0 to 31), so a constant such as 0x32 or a long
  delay count has to be built (here with a shift in the OSR, and in the ISR
  with `in x, 5`). Not wrong, but worth a sentence in the doc; there is no
  example of building a constant larger than 31.
- The default ISR direction (shift right, new bits at the top) is the
  opposite of what `mov x, isr` users may expect; the doc's example
  (0x5000) makes it clear.

## Hand-in

- `qspi.s`: 35 instructions.
- `run_args.txt`: `-config out_base=0,out_count=4,set_base=0,set_count=1,sideset_base=4,sideset_count=2,threshold=16,out_msb_first=1 -mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp -mode 4=pp -mode 5=pp`

Program length: 35 instructions.
