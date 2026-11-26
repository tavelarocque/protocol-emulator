# Hidden test: Quad SPI controller (DSView decoders `qspi` and `smart_qspi`)

This folder is the examiner's side of round 2, Part A, for Quad SPI. The
programmer gets only the kit (`../../kits/qspi/`: `isa.md`, `pe_sim`,
`TASK.md`) and never sees this folder. No firmware for the chip was written
for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal Quad SPI controller as a waveform generator, standing in for `pe_sim`, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the sheet's example, the run length, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `PORT.diff` | `git diff -- qspi smart_qspi` in the census decoder folder: the mechanical port of both decoders |
| `README.md` | this file |

## Role chosen: TRANSMIT

A small chip on a Quad SPI bus is in practice the controller of a serial
NOR flash (or of a display or other peripheral that speaks the same
commands): it owns SCK and CS#. Both decoders judge such a bus, and
`smart_qspi` is specifically a flash command decoder. The task is the
write path: per page, Write Enable (0x06) and Quad Page Program (0x32, the
1-1-4 form: command and 24-bit address on IO0, data on IO0..IO3, two clocks
a byte, high nibble first, IO3 the nibble's top bit), then the flash's
program time. Reading the flash back would make it BOTH, but a scripted
flash cannot follow a clock whose edges the firmware places, and the status
poll that ends a real program wait needs a reply that depends on when the
chip asks; so the sheet waits the worst-case program time (tPP max 3 ms)
instead of polling, which is what simple drivers also do. Nothing is read.

Clock 50 MHz (20 ns a cycle). P0..P3 IO0..IO3, P4 SCK, P5 CS#, all
push-pull; `run_args.txt` must set exactly that (P6, P7 free). SPI mode 0.

## The host interface

One word per byte: bits 7..0 the byte, bit 8 set on the last byte of a
page, bits 15..9 zero. A page is its three address bytes (A23..A16 first)
then its 4 to 256 data bytes (a multiple of 4, not crossing a 256-byte
boundary). The sheet's example: pages 0x012300 {DE AD BE EF} and 0xABCD10
{01 23 45 67 89 AB CD EF} are the 18 words 0x0001, 0x0023, 0x0000, 0x00DE,
0x00AD, 0x00BE, 0x01EF, 0x00AB, 0x00CD, 0x0010, 0x0001, ..., 0x01EF. The
sheet says "The host sends only the words defined above. All line coding,
framing and timing must be done by the firmware." WREN, the command byte,
the switch from one line to four, every clock and every wait are the
program's.

## The decoders, and the port

Both come from DSView (`libsigrokdecode4DSL/decoders` at 2e9e2c8) and did
not load in sigrok-cli 0.7.2 ("annotation 1 should be a tuple with two
elements"). `PORT.diff` holds every change; there are two kinds, each
applied identically to both decoders, and neither touches how a waveform
decodes:

1. **Annotation tuples** (one hunk in `qspi/pd.py`, one in
   `smart_qspi/pd.py`). DSView's annotations are `(type code, id, desc)`,
   where the first field is a DSView display type ('106', '108', '6',
   '1000'); sigrok 0.7.2's library requires `(id, desc)`. The type code is
   dropped; ids, descriptions, order and the annotation rows are unchanged,
   so every annotation keeps its class number.
2. **`self.matched`** (two hunks in each file, in `find_clk_edge`). DSView's
   library gives `self.matched` as a bit mask, so the decoders test
   `self.matched & (0b1 << k)`; sigrok 0.7.2's gives a tuple of booleans,
   one per wait condition, on which `&` raises TypeError. Each test became
   `self.matched[k]`, the same question asked of the other form.

The extra `'type'` and `'idn'` keys in channel and option dictionaries are
DSView's and sigrok 0.7.2 ignores them, so they were left.

What the decoders do, found by reading `pd.py` and confirmed by running them
on the ideal waveforms:

- **`qspi`** reads every rising SCK edge (mode 0) as four bits, IO3 the
  top, two edges a byte, while CS# is low, and resets at every CS# edge. It
  has no notion of command phases, so it reads the single-line WREN,
  command and address as quad bytes too. The judge therefore compares
  those bytes on IO0's bits only (bits 4 and 0 of each byte, which hold
  IO0 at the two edges); IO1..IO3 are don't-care there, as for the flash.
  Data bytes are compared whole. A frame with an odd number of edges loses
  its last half byte silently.
- **`smart_qspi`** collects 8 edges at a time and interprets them by the
  flash command table: a group whose IO0 byte is a known command starts it,
  and 0x32 then takes a 24-bit address on IO0 and quad data bytes until
  CS# rises. Two properties shape the test:
  - With its default `twolinesmode=spi`, any 8-edge group in which IO1, IO2
    or IO3 is constant (all 0 or all 1, which is the normal case in the
    single-line phases) is handled as plain SPI, and in that branch the
    decoder annotates nothing at all: an ideal capture decoded to an empty
    list. With `twolinesmode=qspi` it decodes WREN, the command, the
    address and every data byte. The judge sets that option.
  - It only ever reports a full group of 8 edges, which in the data phase
    is 4 bytes; a page of 6 data bytes decoded as 4. So the sheet's pages
    have a multiple of 4 data bytes.
  - It writes the address width back into a module-level table entry the
    first time it is used; with 24-bit addresses throughout this has no
    effect.

## What the judge checks

For each case it builds the TX words from the sheet's interface, runs
`RUN_DIR/pe_sim run RUN_DIR/qspi.s -tx FILE -cycles N` plus `run_args.txt`
(one line, only `-config` and `-mode`, P0..P5 `pp`; anything else is a setup
failure), with N = 10000 + sum over pages of (201840 + 40 n), the sheet's
formula, which is the slowest waveform the sheet allows plus a 200000-cycle
tail. Then, from P0..P5's printed changes:

- **Waveform check** (every limit of the sheet): SCK low by cycle 100; from
  then on SCK low whenever CS# is high and in every cycle CS# changes; CS#
  low at the end of the run is a fault; exactly 2 frames per page; in each,
  the levels at every SCK rise equal the wanted bits (IO0 only in WREN,
  command and address; IO3..IO0 in data) and the number of rises is exact;
  no IO change in the cycle of an SCK rise inside a frame; at most 20 cycles
  from CS# fall to the first rise, between rises and from the last rise to
  CS# rise; CS# high 3 to 1000 cycles between WREN and QPP and 150000 to
  200000 between a QPP and the next WREN; first CS# fall by cycle 10000; at
  least 150000 cycles of run after the last frame.
- **Decoder check.** The changes become a VCD at 50 MHz (six wires IO0..IO3,
  SCK, CSN) and sigrok-cli 0.7.2 runs each decoder on it, with
  `SIGROKDECODE_DIR` set inside the script to the census decoder folder:
  - `qspi` (`cpol=0, cpha=0, msb-first, wordsize=8, active-low`): its byte
    list must have exactly the wanted length, each byte in order inside the
    wanted CS# frame (by start sample) and equal to the wanted value under
    the mask above.
  - `smart_qspi` (same, `twolinesmode=qspi`, `ads=24-Bit Address`), row
    `data-transfer` only: per page "Write Enable(0x06)" in the WREN frame,
    then "Quad Page Program(0x32)", "24-Bit Address : 0x..." with the page's
    address, and one "Write Data : 0x.." per byte, in the QPP frame, in
    order, with nothing else and no unparsed annotation.
  - Anything sigrok-cli writes to stderr, or a non-zero exit, is a failure.
- `RATE bytes=<data bytes of the case> cycles=<first to last change of
  P0..P5>` for the last passing case. The first change is SCK's fall from
  its reset level, and the span includes the start and the 3 ms program
  waits, so the figure is dominated by the sheet's waits; it compares hand-
  ins of this protocol only.

Cases: six fixed (the sheet's example; all zeros at address 0; all ones at
0xFFFFFC; every nibble on every line; a full 256-byte page; six pages of 4
bytes) and eight seeded random ones (1 to 4 pages, up to 32 or up to 256
data bytes, random address and data).

## What the judge does not check

- Levels between edges beyond what is listed: IO lines while CS# is high,
  and IO1..IO3 during the single-line phases, are free, as for the flash.
- The high and low times of SCK beyond one cycle each, which is the
  simulator's least; the flash's limits are all below 20 ns at 25 MHz.
- What the firmware does with words that break the interface: the judge
  never sends them. It never sends a page whose data length is not a
  multiple of 4, because `smart_qspi` could not judge it.
- That a real flash would be done after 3 ms: the wait is fixed by the
  sheet, not observed.
- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it puts the
  simulator into the run folder.
- `run_args.txt` may hold configuration constants (`clkdiv`, side-set, shift
  direction, autopull and so on): that is the chip's hardware.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- Interface: `tx_words` gives exactly the 18 words printed in the sheet's
  example, and the sheet contains that text.
- Example: the bits the judge wants for the sheet's first page are the ones
  in the sheet's table (WREN 00000110, command 00110010, the address bits,
  nibbles D E A D B E E F, 8 and 40 rises). On 50 random runs the generator,
  in its own code, wants the same bits and reads the judge's words back into
  the same pages.
- Run length: the judge's `-cycles` is the sheet's formula.
- Waveforms: 36 waveforms on 5 seeds, 180 verdicts, all as expected. The 12
  that must pass do: the ideal; SCK at 25 MHz with data changing as SCK
  falls; SCK period exactly 20 cycles with data set exactly 1 cycle before
  each rise; data changing exactly 1 cycle after each rise; CS# high exactly
  3 and exactly 1000 cycles between WREN and QPP; page waits of exactly
  150000 and 200000; first CS# fall at cycle 10000; SCK low at cycle 100;
  CS# rising in the cycle of the last SCK fall; IO1..IO3 random in the
  single-line phases and all IO lines moving while CS# is high. The 24
  broken ones all fail. Content faults are caught by the waveform check and
  by both decoders: one data bit, one address bit, low nibble first, IO
  lines in reverse order, command 0x02, the address on four lines, no WREN,
  WREN and QPP in one frame, the last 4 bytes missing, a CS# glitch inside
  the data, a page missing, a page repeated. Timing faults are caught by the
  waveform check only, as intended: a data change in the cycle of an SCK
  rise, CS# high 2 or 1001 cycles, page waits of 149999 and 200001, first
  CS# fall at 10001, SCK low only at 101, mode 3 (SCK idling high), CS#
  rising with SCK high, one rise 21 cycles after the last, one extra clock
  (which neither decoder reports, since both drop an incomplete word), and
  an SCK pulse after the last page.
- RATE: for the ideal waveform the line equals the figure from the
  generator's own events on every seed (seed 1: `RATE bytes=388
  cycles=325619`).
- Hand-in rules: 13 `run_args.txt` files; the three good ones are accepted,
  the ten bad ones (P5 without a mode, P4 open-drain, `-tx`, `-t`,
  `-cycles`, `-inputs`, `-stimulus`, an ambiguous `-c`, two lines, a flag
  with no value) are setup failures.
- The real simulator: the kit's `pe_sim` with two programs that are not
  Quad SPI firmware (one loops and never writes a pin; one drives SCK low
  once and loops). The simulator accepted the command line and the word
  files, and all 14 cases of each failed cleanly, with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes. With
side-set on SCK, `out pins, 4` from a most-significant-first OSR and a
second instruction raising SCK, a nibble costs two instructions, so even
25 MHz SCK is within reach, and the 20-cycle limit leaves room for the word
fetch and the last-byte test between bytes (`out` of the flag bit into X,
then `jmp !x`). The single-line phases are one-bit loops over the three
address words, plus the two constant bytes 0x06 and 0x32, which the program
has to make itself (in X or Y, or by straight-line code); that, with CS# on
a different instrument from IO and SCK (a `set pins` on P5, say), is the
fiddly part. The 150000-cycle wait needs nested loops, since `set`
gives at most 31; three levels with delays, or a constant built in the ISR,
reach it. The likeliest mistakes are an IO change in the cycle of an SCK
rise and a wrong count of clocks at a phase boundary.
