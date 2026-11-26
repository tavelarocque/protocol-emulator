# Hidden test: DSI transmitter

The examiner's side of the census entry for sigrok decoder `dsi` (Tridonic's
Digital Serial Interface lighting bus). The programmer gets only the kit
(`../../kits/dsi/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees this
folder. No firmware for the chip was written for this test, not even as a
check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal DSI transmitter as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the sheet, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3 and 7 |

## Role: transmit

A DSI controller sends one-byte dimming levels to ballasts; the ballasts
never answer (DSI has no backward channel in its specification, and the
sigrok decoder's 17-bit "forward" branch, copied from its DALI decoder,
produces no data annotation). So the chip is the controller and only
transmits.

## The protocol as the sheet states it

From the DSI specification v2.0 (Tridonic): 1200 transmission bits a
second (half-bits of 833.33 us), idle low. A frame is 21 half-bits
(17.5 ms): a start bit of one half-bit high, 8 data bits D7 first, each two
half-bits with the second the inverse of the first (1 = high-low, 0 =
low-high), and four low stop half-bits; at least 5 ms between frames.

sigrok's `dsi` decoder with `polarity=active-high` (its default) reads
exactly this. Checked by experiment before writing anything: it takes the
rise from idle as the middle of a start cell, decodes each data bit as the
inverse of its second half, D7 first, and ends a frame on a whole bit cell
of low line. Its raw row then shows `Startbit: 0` and `Data: XX`.

Clock 10 MHz (100 ns). A half-bit is 25000/3 cycles, not a whole number,
so the sheet gives ideal places rounded and a tolerance.

Host interface: one 16-bit word per frame, bits 7..0 the level, bits 15..8
zero. Example in the sheet: frames 0xA5, 0x00, 0xFF are words 0x00A5,
0x0000, 0x00FF. "The host sends only the words defined above. All line
coding, framing and timing must be done by the firmware."

## What the judge does

For 5 fixed cases (0x00; 0xFF; the sheet's 0xA5; 0x55 0xAA 0x01 0x80;
eight frames 0x00 0xFF 0x7F 0xFE 0x33 0xCC 0x81 0x18) and 8 seeded random
ones (1 to 3 or 1 to 8 frames of random levels) it builds the TX words,
runs `RUN_DIR/pe_sim run RUN_DIR/dsi.s -tx F -cycles N` plus
`run_args.txt` (one line, only `-config` and `-mode`, must contain `0=pp`),
with N = 200000 + 375000 per frame, and applies two checks.

- Decoder: P0's changes become a VCD sampled at 1 MHz (each change on the
  nearest microsecond; the decoder reads every sample in Python, and 10 MHz
  would make it ten times slower with no gain at 1200 baud). sigrok-cli runs
  `dsi:polarity=active-high` and the raw annotations must be exactly
  `Startbit: 0`, `Data: XX` per wanted frame, in order, nothing else, and
  sigrok must print nothing on stderr.
- Waveform, from the exact pin changes: P0 low by cycle 1000 (it is high at
  reset) and low until the first frame; the first rise between cycles 50000
  and 200000; changes grouped into frames by silences longer than three
  half-bits; each frame's changes exactly those the coding needs, in the
  right directions, each within +-80 cycles (8 us, about 1% of a half-bit)
  of rise + round(k x 25000/3), measured from the frame's rise so an error
  cannot add up; the rest from the end of the stop bits (rise + 175000) to
  the next rise between 50000 and 200000 cycles; no change after the last
  frame, and the run long enough after it to see that.

RATE: `RATE bytes=<frames> cycles=<P0's first change to its last>` for the
last passing case, as the brief asks. The first change is the firmware
driving P0 low out of reset, so the span includes the firmware's chosen
delay before the first frame and its chosen rests; the line rate itself is
fixed by the protocol.

## Validation

    python3 -B selftest.py 1 2 3 7

Result `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- The sheet: `tx_words` gives the words printed in the sheet, and the
  judge's ideal changes for 0xA5 are exactly the nine cycle numbers the
  sheet prints; the last change is at half-bit 17 for D0 = 0 and 16 for
  D0 = 1, as the sheet says.
- Waveforms: 28 waveforms on 4 seeds, 112 verdicts, all as expected. The 8
  that must pass do: ideal; every change 80 cycles off alternately (the
  limit); whole 8333-cycle half-bits (drifts 5.7 cycles, what a simple
  integer firmware would do); P0 low at cycle 1000; first rise at 50000 and
  at 200000; rests of exactly 50000 and 200000. The 20 broken ones all
  fail: one wrong data bit, D0 first, Manchester inverted, one change 81
  cycles late, one 81 early, half-bits of 8400 cycles, double rate, rests
  of 49999 and 200001, first rise at 49999 and 200001, low only at cycle
  1001, never driven low, the whole line inverted, no start bit, a start
  bit of two half-bits, a stray pulse after the last frame, a one-cycle
  glitch in a rest, a frame missing, a frame repeated. The decoder check
  objects too (beside the waveform check) to the wrong bit, D0 first, inverted coding, double rate,
  idle high, no start, long start, and the missing and extra frame.
- RATE equals the figure from the generator's own change list on every
  seed (seed 1: `RATE bytes=1 cycles=193313`).
- Hand-in rules: `-tx`, `-cycles`, `-inputs`, `-stimulus`, an ambiguous
  `-c`, two lines, a flag with no value, `0=od`, and no `-mode` at all are
  refused as setup failures; two good lines are accepted.
- The real simulator behind a wrapper, with a one-instruction program that
  loops and drives no pin (not DSI firmware): all 13 cases fail cleanly
  ("P0 is not driven low by cycle 1000"), no RATE line.

## What the judge does not check

- It runs `RUN_DIR/pe_sim`, whatever it is; whoever runs the judge must put
  the real simulator there.
- `run_args.txt` may hold configuration constants (`clkdiv` and so on).
  That is chip hardware, not the instruction set; read it with the notes.
- Rise and fall times, voltage levels and the +-10% tolerance of the real
  specification are not modelled; the judge's +-8 us is far tighter.
- A slow host is never provoked: the simulator refills the FIFO at once.
- The decoder sees only 1 us samples; sub-microsecond glitches are caught
  by the waveform check, not by sigrok.
- The periodic refresh a real controller sends (the spec suggests every 1
  to 20 s) is not asked for: one frame per word.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view: clearly yes. The rate is
1200 half-bits a second against a 10 MHz clock, so timing is loose; the
+-80 cycle tolerance absorbs a whole-cycle half-bit of 8333 (drift under 6
cycles over a frame), and `clkdiv` or a counted loop gives the 8333-cycle
half-bit. Data go out D7 first, which `out_msb_first` or shifting by hand
covers, and a Manchester bit is just "write b, wait, write not b, wait", no
toggle state needed. The parts that take care are the long waits (5 ms
and more) built from loops in a 16-bit counter, driving P0 low straight
out of reset, and leaving the line low and still once the FIFO is empty.
