# Hidden test: SDA 2506 EEPROM host (sigrok `sda2506`)

This folder is the examiner's side. The programmer gets only the kit
(`../../kits/sda2506/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees this
folder until the firmware is handed in. No firmware for the chip was written
for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, `RATE` line, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal SDA 2506 host as pin changes and RX words, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: interface, scripted EEPROM, every result, RATE line, hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## The role: both directions

The SDA 2506 is a 128-byte serial EEPROM; the host's job is to write,
erase and read bytes. A host that only writes would leave out half of the
protocol's normal use, so the chip does both: it sends commands (CLK, DATA,
CE), and in a read it clocks the EEPROM's byte in on DATA and pushes it to
the host. The EEPROM is a scripted stimulus on P1 and cannot react, so the
task sheet fixes the cycle of every CLK and CE edge (+-2 cycles, on place,
not spacing) and the reply is placed by that schedule. That is the price of
a scripted device: the firmware has no freedom in timing, only in how it
gets there.

## The protocol facts and where they come from

From the Siemens SDA 2506-5 data sheet (text of the data sheet found on the
web; the AC table's text extraction did not make every min/max column
clear, so the sheet stays well inside every number):

- CE high: deselected, command bits are shifted in. CE high to low latches
  the command.
- Read: A0..A6 then CB = 0. Erase: A0..A6 then CB = 1. Write: D0..D7,
  A0..A6, CB = 1. Least significant bit first.
- DATA's level at CE's fall selects write (low) or erase (high). A start
  pulse on CLK follows; programming starts at its trailing edge and ends
  when CE rises. Erase or write time 10 to 20 ms.
- Read: the first CLK pulse after CE falls transfers the byte; on its
  trailing edge D0 appears; each further pulse puts out the next bit. D
  returns to high impedance when CE rises.
- CLK high 2.5 us to 60 us, CLK low 5 us, CE to CLK 5 us, data hold
  2.5 us, data delay 2.5 us.

The schedule in the sheet: slots of 20 us, CLK high 10 us and low 10 us,
every CE edge at least 10 us from any CLK edge (20 us before or after a rising one), DATA changes only within +-2 us of a slot
boundary (so at least 2.8 us of setup and hold even with CLK 2 cycles off),
CE low 20 ms plus 5 us after the start pulse falls, the EEPROM's output
1 us after CLK falls. Core clock 10 MHz (100 ns a cycle). P0 CLK
push-pull, P1 DATA open drain, P2 CE push-pull.

## The host interface, as the task sheet states it

TX, one word per operation: write `0x8000 | addr << 8 | data`; read
`addr << 8`; erase `addr << 8 | 0x01`. RX, one word per read: the byte, in
bits 7..0. The sheet's example: erase 0x12, write 0x3C there, read it back
is 0x1201, 0x923C, 0x1200, and the chip pushes 0x003C. The sheet says "The
host sends only the words defined above. All line coding, framing and
timing must be done by the firmware."

One thing to know when comparing hand-ins: with this natural packing
(address above data, the write flag on top) a write word shifted out least
significant bit first is exactly the 16 command bits on the wire, CB
included. A read word's high byte is likewise A0..A6 and CB = 0. An erase
is not: its CB is 1 while bit 15 is 0. I kept the packing because it is
what a host API would hand over (operation, address, data); it is payload,
not pre-coded line levels, but it does save the firmware a reordering.

## What the judge does

Seven fixed cases (one read, one write, one erase, the sheet's example,
reads of 0x00/0xFF/0x55/0x5A, writes at addresses 0 and 127 then reads,
eight reads) and eight seeded random ones (2 to 8 operations, the last
always 8, each with at least one read), each with its own EEPROM contents.
For each case:

1. It builds the TX words from the interface above, and the EEPROM's DATA
   waveform as a stimulus file. Read bytes follow a small memory model
   (erase gives 0xFF, write clears the zero bits of its data, as the data
   sheet says), which the chip never needs to know.
2. Before running anything it requires that sigrok's decoder, given the
   ideal host waveform and that stimulus, decodes exactly the case's
   operations and read bytes, and that the ideal waveform passes its own
   timing checks. So the input is a real instance of the protocol.
3. It runs `RUN_DIR/pe_sim run RUN_DIR/sda2506.s -tx ... -stimulus ...
   -cycles N` plus `run_args.txt`. N is the schedule's last CE rise plus
   2000.
4. Decoder check. It builds the bus: CLK and CE from the chip, DATA as the
   wired AND of the chip's open-drain output and the EEPROM's. It runs
   `sigrok-cli -P sda2506` and compares the command and data annotations
   (`Write to AA: DD`, `Erase: AA`, `read`, `addr:`, `CB:`, `data:`,
   `read:` and the read byte), grouped per operation, with the wanted ones,
   in order, nothing extra.
5. Waveform check, on the cycles pe_sim printed: CE high at cycle 0; CLK
   low by cycle 1000; every CLK and CE edge in the schedule, each the right
   direction and within +-2 cycles of its place, and no other edge; the
   chip's DATA at the right level outside the change windows (command bits,
   the write/erase select level from slot n to n + 1, released otherwise);
   no pin change after the last CE rise.
6. RX check: the RX words equal the read bytes, in order, nothing extra,
   with bits 15..8 zero.

`run_args.txt` must be one line of `-config` and `-mode` flags only, and
must make P0 and P2 push-pull and P1 open drain. After the cases it prints
`RATE bytes=<writes + reads> cycles=<first to last pin change>` for the
last passing case. The timing is fixed by the sheet, so RATE differs
between hand-ins only by when CLK first falls.

### A finding about sigrok's decoder

In a read, `sda2506` samples DATA `int(2.5 * (1e6 / samplerate))` samples
after CLK falls (the comment says it waits for the data to be ready) and
throws away the value it gets at the next CLK rise. At a 10 MHz capture
that is 0 samples: it reads every bit at the falling edge, before the
EEPROM has put it out, and every read comes out shifted by one bit. The
judge therefore hands sigrok a 1 MHz capture (one sample per microsecond,
a change at cycle c in sample c // 10), where the wait is 2 us, inside the
data sheet's 2.5 us data delay and after the EEPROM's 1 us. All timing
limits are checked on the cycles, not on this capture.

The decoder checks none of the timing: it only follows edges. Everything
in step 5 is the judge's own.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS` (`selftest_output.txt`).

- Interface: `tx_words` gives exactly the sheet's example words and RX
  word, and the schedule gives exactly the sheet's worked write (CLK
  2050..5150, CE fall 5250, start pulse 5450/5550, CE rise 205600).
- Scripted EEPROM: on all 75 cases of the five seeds, sigrok decodes the
  ideal host plus the stimulus to the payload. An EEPROM that puts its bits
  out 3 us after CLK falls (later than the data sheet allows) is refused.
- Results: 24 results on 5 seeds, 120 verdicts, all as expected. The 5 that
  must pass do: the ideal; every CLK and CE edge 2 cycles off, alternately;
  every DATA change at the very edge of its window; CLK low at cycle 1000;
  each read bit sampled at the last cycle it is valid. The 19 broken ones
  all fail: a flipped data bit (waveform and decoder), addresses MSB first,
  one CLK edge 3 late, one CE edge 3 early, one DATA change 21 cycles
  after its slot boundary (waveform only), 201-cycle slots, CE rising 3
  cycles early after programming, no start pulse, DATA high at CE's fall in
  a write (decoded as an erase), nine read pulses, DATA held low through a
  read, CLK low only at cycle 1001, a stray CLK pulse after the last
  operation, the last operation missing, the last operation twice, read
  bits sampled before the EEPROM puts them out (RX only), one RX bit
  flipped, an extra RX word, RX words with the address in the high byte.
- The stand-in simulator reads the judge's TX words back into operations
  in its own code, and takes the bytes it returns from the judge's
  stimulus file at the time a host would sample, so it agrees with the
  judge only if the words, the stimulus and the schedule are all right.
- RATE: equals the figure from the generator's own pin changes on every
  seed (seed 1: `RATE bytes=6 cycles=828040`).
- Hand-in rules: 12 `run_args.txt` files; the two good ones are accepted;
  `-tx`, `-stimulus`, `-s`, `-cycles`, `-inputs`, an ambiguous `-c`, two
  lines, a flag with no value, P1 push-pull and P2 missing are each refused
  as a setup failure.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops and drives no pin (not SDA 2506
  firmware). It accepted the command line, the word file and the stimulus
  file, and all 15 cases failed cleanly ("CLK is not low by cycle 1000"),
  with no RATE line. Runs are up to about 1.3 million cycles; the kit's
  simulator does 2 million in about 0.2 s.

## What the judge does not check

- It runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs the judge must
  put the real simulator there.
- The EEPROM is scripted. A real one would follow the chip's clock; this
  one only works for a chip on the schedule, which is why the schedule is
  exact. The judge cannot tell a firmware that samples DATA at a sound time
  from one that is lucky with these bytes, beyond the variety of the cases.
- When the RX words are pushed is not checked, only their values and
  order. The simulator drains the RX FIFO at once; a slow host is never
  provoked, and neither is a slow TX host.
- P3 to P7 are ignored. The pins' modes are checked only as flags in
  `run_args.txt`.
- The capture sigrok sees has 1 us resolution, so the decoder alone would
  miss a glitch shorter than that; the waveform check sees every cycle and
  catches it on CLK and CE (exact edge count) and on DATA (level intervals).
- `run_args.txt` may hold configuration constants (`clkdiv`, `timeout`,
  CRC settings). That is the chip's hardware, not the instruction set; read
  `notes.md` and the configuration line when comparing hand-ins.
- The data sheet's numbers come from a text extraction in which some
  min/max columns were unclear. The schedule is well inside all of them,
  but a real SDA 2506 was not consulted.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, and it is
harder than the pilot's protocols. Every edge the schedule sets is on a
multiple of 50 cycles, so a clock divider of 10 or 50 puts every edge on a
tick, and side-set can drive CLK while `out` drives DATA. The 20 ms wait is
a counted loop. Reading is an `in` from P1 at a fixed tick, well inside the
100-cycle window each bit is valid, with two cycles of synchroniser. The
hard part is that the three operations are different lengths (16 or 8
command bits, start pulse or 8 read pulses, 20 ms or not), the firmware
must tell read from erase by the low byte and write by bit 15 with only X
and Y to test, and every branch must still land each edge within 2 cycles
of an absolute schedule that runs for over a million cycles. The 150-cycle
gap after CE rises is short for the word fetch and decoding if they are
left until then, so a careful programmer will do them during the previous
operation's tail.
