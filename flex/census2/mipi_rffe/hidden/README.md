# Hidden test: MIPI RFFE master (DSView decoder `mipi_rffe`)

This folder is the examiner's side of round 2, Part A, for the MIPI RF
Front-End Control Interface. The programmer gets only the kit
(`../../kits/mipi_rffe/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees
this folder. No firmware for the chip was written for this test, not even
as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal RFFE master as a waveform generator, standing in for `pe_sim`, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the sheet's example, the scripted slave, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `PORT.diff` | `git -C DECODERS diff -- mipi_rffe`: the mechanical port of DSView's decoder to sigrok-cli 0.7.2 |
| `README.md` | this file |

## The role, and why

BOTH: the chip is the RFFE master. It drives SCLK (P0, push-pull) and
SDATA (P1, open-drain) for its own frames, and a scripted slave, given to
the simulator as `-stimulus`, answers every read. The firmware pushes each
byte read to the host as an `rx` word.

The master is the role a small host chip plays on RFFE: the bus is
single-master, the master owns SCLK, and in a phone that master is the
radio chip setting up power amplifiers, switches and tuners. A slave would
have to follow an SCLK of up to 26 MHz with a 50 MHz core behind a two-flop
synchroniser, and a sniffer likewise. The master owns its clock, and RFFE
allows SCLK from 32 kHz to 26 MHz with static slaves, so a master at
2.5 MHz is a legal bus. Reads are part of normal use (product and
manufacturer ID, status, readback of settings), and the decoder knows all
seven command sequences, so all seven are in the task: Register 0 Write,
Register Write and Read, Extended Register Write and Read (1 to 16 bytes),
and their Long forms (16-bit address, 1 to 8 bytes). Transmit only would
have left out the turnaround and the slave's half of a read, which is the
part of RFFE where a bidirectional line has to be handed over.

Because the scripted slave cannot react, the sheet fixes the whole
schedule: sequence 0's SSC at cycle 400, each next one 20 x (L + 8) cycles
later (2 periods of SSC, L clocks, 6 idle periods), clock j at
S + 40 + 20j, every edge within +-2 cycles of its place, and the slave's
levels 4 cycles after the ideal rising edges.

Clock 50 MHz (20 ns a cycle), SCLK 2.5 MHz (20 cycles: 10 high, 10 low).
P0 SCLK `pp`, P1 SDATA `od`, P2 to P7 unused; the judge requires exactly
`-mode 0=pp -mode 1=od`.

### The one electrical stand-in

RFFE devices drive SDATA push-pull, let go of it at a turnaround, and a
weak bus holder keeps the last level. The chip cannot release a push-pull
pin, so SDATA is open-drain with a pull-up, and the slave drives it the
same way (pulls low for 0, lets go for 1). The pull-up makes a released
line high where a bus holder would keep it low, so the sheet asks the chip
to hold SDATA low wherever the protocol has it low and the slave is not
holding it. On the slave's side the stimulus does the bus holder's job: it
holds SDATA low from 12 cycles after the turnaround clock's place (just
after its falling edge) until its first data bit, and through its own bus
park until 14 cycles after the last clock's place. The chip must let go
inside the first window and take the line back inside the second; the
sheet gives both windows in cycles.

## The host interface, as the task sheet states it

Per sequence: a header word (bits 3..0 slave address, bits 7..4 kind 0 to
6, bits 12..8 the number of data bytes n, bits 15..13 zero), then an
address word for every kind but Register 0 Write, then for a write n data
words (the byte in bits 7..0; for Register 0 Write the 7-bit value). RX:
one word per byte read, the byte in bits 7..0. Kinds are numbers of the
sheet's own (0 to 6), not the command bits, and n is the byte count, not
the wire's n - 1 field. Example in the sheet: a Register Write of 0xA7 to
register 0x13 of slave 5 and a Register Read of register 0x1F of slave 7
are 0x0115, 0x0013, 0x00A7, 0x0127, 0x001F; the slave answers 0x3C and the
firmware pushes 0x003C. The sheet says "The host sends only the words
defined above. All line coding, framing and timing must be done by the
firmware." The SSC, command bytes, parity, byte count field, bus parks,
turnaround, clock and reading the slave are all the program's.

## The decoder and its port

The decoder is DSView's `mipi_rffe` (DreamSourceLab, `2e9e2c8`), in
`DECODERS/mipi_rffe`. sigrok-cli 0.7.2 would not load it. Two mechanical
changes, both in `pd.py`, are in `PORT.diff` (35 lines changed, nothing
else touched):

1. **Annotation tuples.** DSView's annotation entries carry a leading
   display-type code before the id and description (`('7', 'ssc',
   'Sequence Start Condition')`, `('1000', 'Parity warnings', ...)`). sigrok
   0.7.2 requires `(id, description)` pairs and refused the decoder:
   "annotation 19 should be a tuple with two elements". The hunk drops the
   first element of each of the 19 entries. Ids, descriptions and order are
   unchanged, so every annotation index the code and `annotation_rows` use
   is unchanged.
2. **`self.matched`.** DSView's library sets `self.matched` to an integer
   with bit i set when condition i of the last `wait()` matched; sigrok
   0.7.2 sets a tuple of booleans, one per condition. The decoder tested
   `(self.matched & (0b1 << i))`, which raised `TypeError` on the first
   wait under sigrok. All 16 such tests became `self.matched[i]`, which has
   the same truth value for every i. (Where both conditions match on one
   sample, both tests are still true, in the same order, as before.)

The channel and option entries also carry DSView-only keys (`type`, `idn`);
sigrok 0.7.2 ignores them, so they were left in. Nothing that decides what
a waveform decodes to changed. The port was confirmed by running: on every
case of every seed, the ideal bus decodes to exactly the annotations the
judge predicts (selftest check 3).

### A decoder quirk the judge allows for, measured here

The decoder's parity check of the command frame leaves out the slave
address: it forms the parity from the command byte alone (`Parity()` adds
the command's constant bits to the last field read, which by then has
overwritten the slave address). RFFE's parity covers all 12 bits, SA
included, and the sheet says so. So on a correct command frame whose slave
address has an odd number of ones (1, 2, 4, 7, 8, 11, 13, 14), the decoder
prints "Parity warnings" before the parity bit. `accept.decoder_wants`
expects exactly that warning there and nowhere else; the parity bit's
value, which the decoder prints as "Parity: d", must still be the correct
one. A firmware that computed the parity the decoder's way fails
(`cmdparity_nosa` below). This was found by reading `pd.py` and confirmed
by running the decoder: the self-test's 70 cases hold 111 such frames and
every one decoded as predicted. Data and address frame parity are checked
correctly by the decoder.

## What the judge checks

For each case it builds the TX words, the RX words wanted and the
stimulus from the sheet's rules, and first requires the decoder to read
the ideal bus (accept's own ideal master with the stimulus) as exactly the
wanted annotations, and that bus to pass its own wire checks: the
scripted slave is a real RFFE slave. Then it runs `RUN_DIR/pe_sim` with
`-tx`, `-stimulus`, `-cycles N` (N = S(R) + 100) and `run_args.txt`, works
out each cycle's levels (SCLK: the chip's output; SDATA: the chip's output
AND the slave's), and requires:

- SCLK low at every cycle from 100 to the first sequence; after cycle 100
  exactly the scheduled clocks, every rising and falling edge within +-2
  cycles of its place, nothing extra (so it stays low between sequences
  and after the last one).
- SDATA low on the line from cycle 100 to the first SSC. After cycle 100
  every change of the line is either an SSC edge (rise within +-2 of S,
  fall within +-2 of S + 20, SCLK low), or inside a high phase of SCLK
  from the rising edge's cycle to 3 cycles before the falling edge, at most
  one per clock. Every SSC must be present. So no change while SCLK is low,
  no glitches, and SDATA low in idle and after every bus park.
- The level in the cycle before every falling edge equals the bit of that
  clock: slave address, command byte, odd parity, address and data
  frames, bus parks, and the slave's bits.
- In a read, the chip's SDATA output 1 (let go) at every cycle while the
  slave drives (from 4 cycles after the place of the first slave clock to
  4 cycles after the place of the last clock), even where the line does not
  show it. Letting go too early or taking the line back too late shows as
  a change of the line while SCLK is low.
- The decoder's annotations equal, exactly and in order: SSC, slave
  address, the sequence's name, the command's field (7-bit data, 5-bit
  address or byte count), the predicted parity warning, every parity value,
  every address and data byte with the decoder's bit-range labels, and each
  bus park; no Illegal Jump Edge, BC or other warnings, nothing extra.
- The `rx` words equal the bytes the slave returned, in order, nothing
  extra.
- `run_args.txt`: one line, only `-config` and `-mode`, and exactly the pin
  modes above.

Cases: six fixed (the sheet's example; every kind once; Register 0 Writes
to the broadcast address and with 0x00, 0x7F, 0x40; a 16-byte extended
write and read; an 8-byte long write and read; five Register Reads with
slave addresses of both parities) and eight seeded random ones (1 to 3 or 1
to 8 sequences of random kind, slave, address, length and data). After the
case lines: `RATE bytes=<data bytes written and read> cycles=<first to last
change of P0 or P1>` for the last passing case. The schedule is fixed by
the sheet, so the rate is too; it varies only by a cycle or two with where
the firmware puts edges inside their tolerances.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must
  put the real simulator there.
- RFFE v2 features and corners: masked writes, multi-master and bus
  ownership transfer, interrupts, timed triggers, half-speed reads, no
  response frames, and what a slave does with the broadcast address. The
  decoder knows none of them. The task is the seven v1 command sequences.
- SCLK at 2.5 MHz, timing in whole 20 ns cycles; the electrical figures
  (VIO, output delay, setup and hold in ns, bus holder strength) are not
  modelled beyond "SDATA changes in the high phase, at least 3 cycles
  before the fall". SDATA is open-drain with a pull-up, not push-pull with
  a bus holder (above).
- When the `rx` words are pushed, as long as they are the right ones in
  the right order; and whether the firmware checks the slave's parity (the
  sheet says it need not).
- What the firmware does with words that break the interface: the judge
  never sends them.
- The output register bits of P2 to P7: those pins have no mode, so they
  drive nothing.
- `run_args.txt` may set configuration constants (`clkdiv`, side-set,
  shift directions, `crc_poly`, `crc_init`, `crc_in` and so on). That is
  the chip's hardware, not the instruction set; read the configuration
  line with `notes.md` when hand-ins are compared.
- A slow host is never provoked: the simulator refills the TX FIFO at
  once.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`). Of the waveform verdicts, 30 must-pass (6 waveforms x 5 seeds) all passed and 135 must-fail (27 x 5) all failed.

The stand-in (`ideal_wave.py` behind a wrapper named `pe_sim`) reads the
judge's TX words back into sequences by the sheet's rules in its own code,
codes command bytes from bit-string prefixes, paints per-cycle levels, and
does not know the bytes a read returns: it reads them off its own
open-drain output AND the judge's stimulus file in the cycle before each
falling edge, as a master would. Its ideal sits elsewhere in the allowed
windows than accept's (SDATA moved 1 cycle after each rise, let go 18
cycles after the turnaround clock's place, taken back 10 after the last
clock's place). So the ideal passes only if the words, the stimulus, the
judge's ideal bus and sigrok all agree.

- Interface: the judge's words, RX word, stimulus file and schedule for
  the sheet's example equal the text printed in the sheet; the sheet's two
  example tables (bits and rising edges per row) equal the judge's; the
  clock counts L for every kind and length and the turnaround clocks
  13, 22, 31 are the sheet's.
- Scripted slave: the decoder reads the ideal bus of all 70 cases (14 per
  seed) exactly as predicted, including every predicted command-parity
  warning.
- Waveforms: 6 that must pass (ideal; every SCLK and SSC edge 2 cycles off,
  alternately late and early; SDATA moved exactly 3 cycles before the fall;
  SDATA let go at the first and at the last allowed cycle and taken back at
  the first and at the last; both lines low only at cycle 100) and 27 that
  must fail (a data bit flipped; data least significant bit first; slave
  address least significant bit first; even parity on data and address
  frames; command parity without the slave address, as the decoder checks
  it; byte count n instead of n - 1; one RX bit wrong; an extra RX word;
  a missing RX word; one rising edge 3 cycles late; a 21-cycle SCLK
  period; SDATA moved while SCLK is low; SDATA moved 2 cycles before the
  fall; a glitch inside a high phase; SDATA never let go in a read; a 2
  cycle pull-down against a slave's 1; the chip holding SDATA low through
  a slave's 0, where the line does not change; letting go 1 cycle too
  early; taking it back 1 cycle too late; an SSC of 10 cycles; a missing
  SSC; 7 idle periods instead of 6; an extra SCLK pulse after the last
  sequence; writes without their bus park; SDATA released high between
  sequences; lines low only at cycle 101; the last sequence missing).
  Each verdict is printed per seed in `selftest_output.txt`, with which of
  the three checks (waveform, decoder, rx) objected. The timing faults are
  caught by the waveform check; the coding faults by the decoder and the
  waveform check together; the RX faults only by the rx check; and
  `hold_on_zero` only by the let-go check, as intended.
- RATE: equals the figure from the stand-in's own pin changes, every seed.
- Hand-in rules: 12 bad `run_args.txt` refused (`-tx`, `-stimulus`, `-s`,
  `-cycles`, `-inputs`, ambiguous `-c`, two lines, a flag without value,
  SDATA push-pull, SCLK open-drain, SDATA's mode missing, a mode for P2);
  2 good ones accepted.
- Real simulator: the kit's `pe_sim` with two programs that are not RFFE
  firmware (`idle: jmp idle`, which leaves both lines high; and one that
  drives P0 and P1 low once and loops) accepts the command line, word file
  and stimulus file, and every case fails cleanly on the waveform check,
  with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, but it is
one of the larger tasks. A bit is 20 cycles, so one side-set bit for SCLK
leaves a 3-bit delay and room for a few instructions per half period, and
`out_msb_first` gives every field most significant bit first from the
words. The parts that take care:

- Parity. No instruction exclusive-ors. The CRC register with a degree-1
  polynomial and `crc_init` 1 holds the odd parity bit of the bits it has
  seen, but it follows only OUT (or, with `crc_in`, IN), while the command
  byte's constant prefix (`010`, `0010`, `00111` ...) is most easily
  written with `set`. Either the prefixes are sent through the OSR or read
  back from the pin with `in pins, 1` and `crc_in` (an open-drain pin's own
  output reads back undelayed), or the parity is kept in the flow of
  control.
- Seven kinds from one header word, with the byte count turned into the
  wire's n - 1, a 5-, 8- or 16-bit address, and loops over 1 to 16 bytes.
- The fixed schedule: the next SSC is due exactly 120 cycles after the
  last clock period, for every kind and length, and every path (fetching
  and decoding the header, the read's turnaround) must keep SCLK on its
  20-cycle grid within +-2 cycles across a whole run.
- The read: let go of SDATA inside a 13-cycle window, sample the slave's
  bits after the two-cycle synchroniser, drop its parity bits, push each
  byte, and take the line back inside an 11-cycle window.

That is counting and program space (likely more than one 64-word page),
not missing hardware.
