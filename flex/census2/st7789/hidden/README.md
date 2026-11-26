# Hidden judge: ST7789 serial host (census round 2, Part A)

Kept from the firmware's author until the hand-in. The author's kit is
`../../kits/st7789/` (isa.md, pe_sim, TASK.md). No firmware for the chip
was written for this test, not even as a check.

## Files

- `accept.py`: the acceptance test. `python3 accept.py RUN_DIR [seed]`,
  default seed 1. Prints one line per case (16 cases), a RATE line, then
  `ACCEPT PASS` or `ACCEPT FAIL`; exit status 0 only when every case
  passes. It sets `SIGROKDECODE_DIR` to the round-2 DECODERS folder itself.
- `ideal.py`: an ideal ST7789 host waveform drawn in Python (not chip
  firmware), with 19 planted-fault variants. Also a stand-in for `pe_sim`.
- `validate.py`: checks the judge (interface, every variant, the RATE line,
  the hand-in rules, the real `pe_sim` with a program that does nothing,
  and that the decoder folder is unchanged).
- `selftest/`: the run directories `validate.py` builds.
- `selftest_output.txt`: the last output of `python3 -B validate.py 1 2 3`.

There is no `PORT.diff`: no port was needed (below).

## Role, clock, pins

The chip is a **transmitter**: the host of an ST7789V display on its 4-line
serial interface, write only. That is what a small host chip does with this
controller in practice: almost every ST7789 driver only writes (commands,
parameters, pixels), and reading needs SDA turned around, which the 4-line
write interface does not use. The 8080 parallel modes need 8 to 18 data
lines plus four control lines, so the serial mode is the one that fits 8
pins, and it is a full mode of the part, not a weakened one.

Core clock 50 MHz (one cycle 20 ns). P0 SDA, P1 SCL (the data sheet's DCX
pin in serial mode), P2 D/CX (the data sheet's WRX pin), P3 CSX, all
push-pull. P4 to P7 are ignored.

## The host interface, as the task sheet states it

One 16-bit word per byte on the wire, command and data bytes alike, in
order, transfer after transfer. Bits 7..0 are the byte. Bit 8 is 1 for a
command byte and 0 for a data byte. Bit 9 is 1 on the last byte of a
transfer (chip select must rise after it) and 0 otherwise. All other bits
are 0. The sheet's example: CASET 0x2A with 0x00 0x00 0x00 0xEF, then
DISPON 0x29, are the words 0x012A, 0x0000, 0x0000, 0x0000, 0x02EF, 0x0329.
The sheet says: "The host sends only the words defined above. All line
coding, framing and timing must be done by the firmware." This is the same
interface as round 1's pilot `st7735` (flex/pilot/st7735), on purpose: it
is the least a host can say about a transfer, and it makes the two
comparable.

## The timing limits and where they come from

The ST7789V data sheet, section 7.4, 4-line serial interface, write. I
checked the numbers against a copy of the data sheet hosted by Espressif
(dl.espressif.com/dl/schematics/LCD_ST7789.pdf), read during this session;
the copy linked from the decoder itself (newhavendisplay.com) could not be
fetched. In whole 20 ns cycles:

| Symbol | Min | Whole cycles | What the direct check requires |
|---|---|---|---|
| TCSS | 15 ns | 1 | first SCL rise at least 1 cycle after CSX falls |
| TCSH | 15 ns | 1 | SCL low at the CSX edge and in the cycle before |
| TCHW | 40 ns | 2 | CSX high at least 2 cycles between transfers |
| TSCYCW | 66 ns | 4 | rise to rise and fall to fall at least 4 cycles |
| TSHW | 15 ns | 1 | SCL high at least 1 cycle |
| TSLW | 15 ns | 1 | SCL low at least 1 cycle between pulses |
| TSDS | 10 ns | 1 | SDA the same in the cycle before a rise |
| TSDH | 10 ns | 1 | SDA the same in the cycle of the rise (may change 1 cycle after) |
| TDCS | 10 ns | 1 | D/CX the same from 1 cycle before the 8th rise |
| TDCH | 10 ns | 1 | ... through the cycle of the falling edge that ends the 8th pulse |

TCSH and TDCH are counted from the falling edge after the last rise, which
asks a little more than the data sheet (it counts from the rise); the sheet
says so and gives the reason. sigrok's decoder finishes each bit at the
falling edge of SCL and reads D/CX there for the eighth bit, not at the
rising edge. So a byte is complete for the judge only once SCL is low
again: D/CX must still be at its level at that falling edge (TDCH), and a
CSX edge before it would cut the last bit off (TCSH).

The sheet also requires exactly one CSX low pulse per transfer, where the
data sheet allows CSX held low across transfers or raised between bytes.
It says why: one pulse per transfer lets the direct check read each
transfer's framing from the pins and compare it with what the host asked
for, and the decoder drops a byte cut short by CSX without a word, so a
rule that every pulse holds whole bytes keeps such a fault from hiding.

Some later variants of the part (ST7789VW and others) allow a faster
write clock; the sheet uses the ST7789V's 66 ns.

Because the capture has one sample per 20 ns cycle, three limits cannot be
broken on their own: any SCL high or low that shows in the capture lasts
at least 20 ns, more than TSHW and TSLW, and an SDA change after a rise
comes at least 20 ns after it, more than TSDH. They are checked anyway;
the period limit (4 cycles) is the one that bites.

Cycle budget: 100 cycles per byte asked for, plus 2000. The least a
correct waveform needs is 32 cycles a byte (8 bits of 4 cycles); the
`good` variant uses 32.

## What accept.py does

For each case it builds the TX words from the interface above
(`tx_words`), runs `RUN_DIR/pe_sim run RUN_DIR/st7789.s -tx FILE -cycles N`
plus the one line of `run_args.txt`, and turns the printed pin changes into
a capture of one byte per cycle (sigrok's `binary` input, 50 MHz). It
refuses a `run_args.txt` that is more than one line, that holds any flag
other than `-config` and `-mode` (pe_sim's prefixes included, so `-t`,
`-s`, `-i` are refused), or that does not make P0 to P3 push-pull.

1. **sigrok's `st7789` decoder** (`st7789:csx=3:dcx=1:sdo=0:wrx=2`),
   annotation classes `command` and `data`, merged in sample order, must
   give exactly the wanted list of (command or data, byte), nothing extra.
   Any error from sigrok-cli or line it prints that is not `NAME(XX)` or
   `Data(XX)` fails the case.
2. **The direct check** reads the capture itself: CSX high at cycle 0 and
   at the end; one CSX low pulse per transfer; inside each, whole SCL
   pulses only and a multiple of 8 of them; every limit in the table
   above; D/CX low on the first byte of each pulse and high on the rest;
   and the transfers it reads (command and data bytes per pulse) equal to
   those asked for.

Cases: 8 fixed (one command alone; the sheet's example; a CASET, RASET,
RAMWR window; bit patterns including commands 0x00, 0xFF, 0x80, 0x01, 0x7F,
0xFE; six commands back to back; data bytes equal to command codes; 255,
256 and 257 data bytes; 1000 data bytes) and 8 seeded random runs of 1 to
10 transfers with any command byte and 0 to 70 data bytes. Any command byte
is allowed because this decoder prints `Unknown(XX)` for codes it has no
name for (the round-1 `st7735` decoder raised an error instead).

RATE: `RATE bytes=<bytes on the wire> cycles=<first change of P0..P3 to
the last>` for the last case that passed, "random 7" when all pass.

An exception inside the judge is reported as a failed case, never a pass.

## The decoder: no port

DSView's `st7789` decoder (DECODERS/st7789, as fetched at d058999, the
same `pd.py` at the later b12ee00, which only ignores bytecode caches)
loads and runs under sigrok-cli 0.7.2 with no change: it is written to
api_version 3, and the extra `idn` keys in its channel list are ignored.
`validate.py` checks that `git diff -- st7789` is empty. The judge sets
`PYTHONDONTWRITEBYTECODE` so it leaves nothing in that folder.

What it does, read from its source, which the judge relies on and allows
for:

- Its channels carry the data sheet's serial-mode pin names: `dcx` is the
  clock and `wrx` is D/CX. The decoder's own description of `dcx` says
  "Clock signal".
- It waits for CSX to fall, then for CSX to rise or any edge of the clock.
  It takes SDA at a rising clock edge and finishes the bit at the falling
  edge. At the falling edge of the 8th pulse it reads `wrx` and calls the
  byte data (1) or command (0).
- Bits left over when CSX rises are dropped without a word. A transfer with
  stray clock pulses therefore decodes cleanly; the direct check catches
  it (`bad_stray_bits`).
- It does not check that a pulse begins with a command, any timing, or that
  CSX framing matches the transfers; the direct check does.

## Validation (no chip firmware was written)

    python3 -B validate.py 1 2 3

Result: `VALIDATION OK` (selftest_output.txt). The stand-in simulator
(`ideal.py` under the name `pe_sim`) reads the judge's words back into
transfers by the task sheet's rules, in code written apart from the
judge's `tx_words`, and stops with an error if the words break them. So the
good variants pass only if the judge's words, the stand-in's reading of
the sheet, the direct check and sigrok's decoder all agree.

- Interface: `tx_words` gives exactly the words printed in the sheet's
  example, and the sheet contains the two required sentences, the clock,
  the budget and the data-byte limit.
- Waveforms: 21 variants on 3 seeds, 63 verdicts, all as expected. `good`
  (every limit at its fewest whole cycles) and `good_relaxed` (slack, an
  uneven slower clock, noise on SCL, SDA and D/CX while CSX is high and on
  P4 to P7) pass 16 of 16 on every seed: 6 correct runs passed. All 19
  broken ones end in `ACCEPT FAIL` on every seed: 57 broken runs failed.
  Which judge caught each:

| Variant | Fault | Caught by |
|---|---|---|
| bad_bit | one data bit inverted | both |
| bad_lsb | least significant bit first | both |
| bad_dc_level | data bytes with D/CX low | both |
| bad_dc_cmd | the first command byte with D/CX high | both |
| bad_extra | an extra NOP transfer | both |
| bad_missing | the last byte left out | both |
| bad_stray_bits | 3 stray SCL pulses at the end of a transfer | direct only |
| bad_period_high | one SCL high of 1 cycle, period 60 ns | direct only |
| bad_period_low | one SCL low of 1 cycle, period 60 ns | direct only |
| bad_sda_setup | SDA changes with an SCL rise | direct only |
| bad_dc_setup | D/CX settles with an 8th rise | direct only |
| bad_dc_hold | D/CX changes with the falling edge after an 8th bit | both |
| bad_cs_high | CSX high 20 ns between transfers | direct only |
| bad_cs_split | CSX high between a command and its data | direct only |
| bad_cs_stuck | CSX never rises after the last transfer | direct only |
| bad_cs_early | CSX rises with the last SCL fall | both |
| bad_css | first SCL rise with the CSX fall | both |
| bad_scl_idle | SCL low only as CSX first falls | direct only |
| bad_late | not finished inside the budget | both |

- RATE: for `good` the line equals the figure worked out from the ideal
  waveform's own changes on every seed (seed 1: `RATE bytes=22
  cycles=709`).
- Hand-in rules: `-tx`, `-t`, `-cycles`, `-inputs`, `-stimulus` and a
  second line in `run_args.txt` were each refused, one with an added
  `-config` was accepted, and one making P3 open-drain was refused.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin (not
  ST7789 firmware). All 16 cases failed cleanly with "sigrok decoded 0
  bytes", no RATE line, nothing on stderr.

## What it does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the real simulator there.
- `run_args.txt` may set any configuration field: that is the chip's own
  hardware, set once, the same for every case.
- Bits 8 and 9 hand the firmware the D/CX level and where CSX rises; it
  does not have to count bytes or know command codes.
- Reads (RDDID and the like), the 3-line 9-bit mode, the parallel modes,
  holding CSX low across transfers and raising it between bytes, all of
  which the part allows: the sheet rules the last two out and the others
  are not asked for.
- A slow host: the simulator refills the FIFO at once.
- Anything after the budget, the RX FIFO, P4 to P7.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, with
room to spare. It is round 1's pilot `st7735` task with tighter numbers:
the same interface, framing and pins, and that pilot has a full-chip
hand-in on `demo`. Here the clock is 50 MHz and the period
must be at least 4 cycles, against a budget of 100 cycles a byte where 32
is the floor, so per-byte overhead of several instructions still fits. The
one trap is the same as before: the output register resets to all ones, so
SCL starts high and must be brought low at least one cycle before CSX
first falls.
