# Hidden test: OOK (on-off keying) transmitter

This folder is the examiner's side of the census for sigrok's `ook`
decoder. The programmer gets only the kit (`../../kits/ook/`: `isa.md`,
`pe_sim`, `TASK.md`) and never sees this folder until the firmware is
handed in. No firmware for the chip was written for this test, not even as
a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal OOK transmitter as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the sheet's example, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## Role chosen: transmitter

A small chip next to a 433 MHz OOK radio module drives the module's data
input: that is how wireless sensors and remote controls send. OOK is a
modulation, not one standard, and sigrok's `ook` decoder reads several line
codings. The task sheet fixes one frame in the style those sensors use and
the decoder reads: Manchester code (a 1 is high then low, the convention
the decoder reports as written), 2000 bit/s, a preamble of 16 ones, a sync
nibble 0101, payload bytes most significant bit first, line low between
frames. Core clock 1 MHz (one cycle = 1 us), so a bit is 500 cycles and a
half bit 250. Pin P0, push-pull.

## The host interface

One 16-bit word per payload byte, in order, frame after frame. Bits 7..0
are the byte, bit 8 is 1 on the last byte of a frame, all other bits 0.
The sheet's example: the frames 0xA5 and 0x12 0x34 0xFF are the words
0x01A5, 0x0012, 0x0034, 0x01FF. The sheet says "The host sends only the
words defined above. All line coding, framing and timing must be done by
the firmware." Preamble, sync, Manchester halves, the return to low and the
gaps all have to come from the program.

## What the judge does

Seven fixed cases (0x00; 0xFF; the sheet's example; the sheet's words;
0x55, 0xAA, 0x01, 0x80 as four frames, which end in both bit values; 16
bytes; six one-byte frames) and eight seeded random ones (1 to 6 frames,
up to 4 or up to 16 bytes each). Runs of `-cycles` 20000 plus, per frame,
its length and 20000, as the sheet says. For each case:

- It builds the TX words itself from the interface, runs `RUN_DIR/pe_sim`
  on `RUN_DIR/ook.s` with `RUN_DIR/run_args.txt` (one line, `-config` and
  `-mode` only; anything else is a setup failure).
- **Decoder check.** P0's printed changes, exactly as printed, become a VCD
  at 1 MHz. `sigrok-cli -P ook:data=P0:decodeas=Manchester:preamble=1111:preamlen=7:invert=no -A ook`
  reads it. Its bit annotations, split at its time-out marks `T`, must be
  exactly one string per frame, in order, nothing extra. No `E` bit, no
  error text ("Not Manchester encoded or wrong preamble"), and no `R`
  (preamble search reset) once the first frame has begun.
- **Waveform check**, for what the decoder does not hold to (it learns the
  bit rate from the preamble and allows wide pulse widths): P0 driven low
  by cycle 100; first frame's rise between cycle 5000 and 20000; transitions
  grouped into bursts (more than 1000 cycles of silence splits them), one
  burst per frame; every transition within +-2 cycles of its ideal place
  counted from the frame's first rise, and exactly the right number of
  them (so the line returns low at the end of a frame ending in 0, exactly
  on time); gaps from the end of a frame's last bit to the next rise of
  5000 to 20000 cycles; P0 low at the end of the run, no stray transition.
- `RATE bytes=<payload bytes> cycles=<P0's first change to its last>` for
  the last passing case. As the brief says, the first change counted: for
  this protocol it is the fall from the reset level (cycle 1 or so), so the
  span includes the wait before the first frame (at least 5000 cycles) and
  all the gaps.

### Two decoder quirks the judge allows for, both measured here

- A push-pull pin is high at reset (`isa.md`), so every hand-in shows a
  short high pulse before it drives P0 low. The decoder answers it with one
  `R` annotation and then decodes the first frame correctly. The judge
  feeds the real capture to the decoder and allows an `R` only before the
  first decoded bit; the waveform check limits that pulse to 100 cycles.
- When a frame's last bit is a 0, the decoder prints one more bit, a `1`,
  at its time-out (it reads the high second half of the final 0 as the start
  of another bit). `accept.decoder_wants` expects exactly that. This was
  checked against sigrok on 60 random runs with random +-2 cycle jitter
  before the judge was written, and is checked again by every passing
  ideal waveform in the self-test.

## What the judge does not check

- Anything between transitions: a pulse shorter than one cycle cannot
  exist in this simulator, and the levels are fully fixed by the
  transitions.
- What the firmware does with words that break the interface: the judge
  never sends them.
- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the simulator into the run folder themselves.
- `run_args.txt` may hold configuration constants (`clkdiv`, `set_base`,
  `out_msb_first` and so on). That is the chip's hardware, not the
  instruction set; read the configuration line with `notes.md` when hand-ins
  are compared.
- Bit 8 tells the firmware which byte is the last; it still must make the
  preamble, sync, return to low and the gap, but need not count bytes.
- A slow host is never provoked: the simulator refills the FIFO at once.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- Interface: `tx_words` gives exactly the words printed in the sheet's
  example, and the sheet contains that text.
- Example: the 46 transitions in the sheet's table for 0xA5 equal the
  judge's `ideal_offsets` and the generator's own transitions, which are
  computed differently (half-bit levels against a toggle rule).
- Waveforms: 31 waveforms on 5 seeds, 155 verdicts, all as expected. The 6
  that must pass do: the ideal; every transition 2 cycles off (the limit);
  gaps of exactly 20000; first frame at cycle 5000 and at 20000; P0 driven
  low at cycle 100. The 25 broken ones all fail: one data bit flipped,
  least significant bit first, the other Manchester convention, the whole
  line inverted, preambles of 15 and 24 bits, no sync, sync 1010, one
  transition 3 cycles late, one 3 early, bits of 501 cycles, bits of 400,
  gaps of 4999, 1500 and 20001, first frame at 4999 and at 20001, P0 low only
  at cycle 101, P0 left high until just before the first frame, no fall
  after a final 0, that fall 3 cycles late, a stray pulse after the last
  frame, a one-cycle glitch in a gap, a frame missing, a frame repeated.
  The decoder check alone catches the coding faults (bit, order,
  convention, inversion, preamble, sync, glitch, missing or extra frame);
  the timing faults are caught by the waveform check only, as intended.
- RATE: for the ideal waveform the line equals the figure from the
  generator's own transitions on every seed (seed 1:
  `RATE bytes=16 cycles=96999`).
- Hand-in rules: ten `run_args.txt` files; the two good ones are accepted,
  the eight bad ones (`-tx`, `-t`, `-cycles`, `-inputs`, `-stimulus`, an
  ambiguous `-c`, two lines, a flag with no value) are setup failures.
- The real simulator: the kit's `pe_sim` with two programs that are not OOK
  firmware (one loops and never writes P0; one drives P0 low once and
  loops). The simulator accepted the command line and the word files, and
  all 15 cases of each failed cleanly, with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, and
comfortably. Every event is on a 250-cycle grid, so `clkdiv` (for example
50 or 250) makes a half bit a handful of ticks and puts every edge exactly
on time. Manchester needs each bit and then its complement, and no
instruction inverts a pin, but branching on the bit (`out x, 1` then a
`jmp !x`) into two short paths of equal length, each writing the two
halves with `set pins`, does it. With `out_msb_first` the 16-bit word comes
out as seven zero bits, the last-byte flag, then the byte most significant
bit first, which is exactly the order needed. Preamble, sync and the 5000
cycle gap are constant loops on Y. The care needed is in equalising the
tick counts of the paths, including the word fetch between bytes.
