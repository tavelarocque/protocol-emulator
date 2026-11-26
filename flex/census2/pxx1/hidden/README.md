# Hidden test: FrSky PXX1 transmitter

This folder is the examiner's side of round 2, Part A, for DSView's `pxx1`
decoder. The programmer gets only the kit (`../../kits/pxx1/`: `isa.md`,
`pe_sim`, `TASK.md`) and never sees this folder until the firmware is
handed in. No firmware for the chip was written for this test, not even as
a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal PXX1 transmitter as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the CRC, the sheet's examples, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## Role chosen: transmitter

PXX1 is the link from a radio control transmitter's main processor to its
FrSky RF module (XJT, R9M): the processor sends a frame of eight channels
every 9 ms and the module puts it on the air. Open-source transmitter
firmwares (OpenTX, Deviation) generate it from a timer; a small programmable
I/O chip doing the same job for a host microcontroller is the natural use.
The decoder reads that direction. The module side (receiving PXX1) is also
real, but the transmitter is the canonical role and the one the decoder was
written for.

Core clock 50 MHz (one cycle 20 ns). Pin P0, push-pull, idle high (the
reset level, so there is no start-up pulse to deal with). Every bit is a
falling edge, 8 us low, then high until the next bit's falling edge; a 0
lasts 16 us and a 1 24 us, fall to fall. Limits enforced: every low pulse
400 cycles +-25, every bit 800 or 1200 cycles +-25, each measured on its own;
first frame's first fall at cycle 5,000 to 500,000; frames 8 to 10 ms apart
(nominal 9 ms), first fall to first fall; line high and still between frames
and after the last.

Frame: 0x7E (raw), receiver number, flag 1, flag 2, twelve bytes of eight
12-bit channels packed two to three bytes (OpenTX's packing), extra flags,
CRC-16 high byte first, 0x7E (raw). Bit stuffing (a 0 after five 1s) over
the sixteen bytes and the CRC, the count running across bytes. The CRC is
FrSky's: `crc = (crc << 8) ^ T[(crc >> 8) ^ byte]` from 0, where T is the
reflected CCITT (0x8408) table used with a left shift (OpenTX's `CRC_1189`
table; Multiprotocol's `CRC_Short` with `0x1081 * (v >> 4)`). The sheet
defines it by carry-less products and by the 0x8408 register, gives T[0..15]
and two worked frames with their CRCs (0x21A3, 0xFF54).

The sheet takes the 8 us low pulse and 16/24 us periods from the
open-source transmitter firmwares as I know them (a 2 MHz timer, periods of
32 and 48 half-microseconds). Some firmware versions may use a 9 us low
pulse; the decoder does not read the pulse width, and the sheet fixes 8 us.
The +-0.5 us limit is mine: the decoder accepts +-1 us, and the module's own
limits are not published. The 8 to 10 ms window around the 9 ms period is
also mine: as far as I know an external module does not lock to the frame
rate (Deviation sends PXX unsynchronised), and the window lets a
fixed idle gap after each frame pass (frames last 2.6 to 4.3 ms depending on
their content), so the firmware need not count the frame's length.

The web pages I tried to fetch to confirm the transport details
(`opentx/radio/src/pulses/pxx.h` and EdgeTX's `pxx1_transport.h` on
raw.githubusercontent.com) were blocked in this session;
`opentx/radio/src/pulses/pxx1.cpp` and `pxx1.h` were read and confirm the
frame layout, the field bits, the channel packing, the unstuffed header and
closing byte, the stuffing rule and the CRC high byte first. The CRC table
and the pulse timings are from memory, cross-checked against the decoder
(16 and 24 us windows) and against the table's known first entries.

## The host interface

Ten 16-bit words per frame: word 0 is flag 1 << 8 | receiver number, word 1
is extra flags << 8 | flag 2, words 2 to 9 are channels 1 to 8 (12 bits,
bits 15..12 zero). The sheet's example: its two frames are the twenty words
0x0003, 0x0000, 0x0400 x 8, 0x111F, 0x0400, 0x07FF, 0x0F81, 0x0400 x 6. The
sheet says "The host sends only the words defined above. All line coding,
framing and timing must be done by the firmware." Header, packing, CRC,
stuffing, closing byte, every edge and the frame period have to come from
the program.

## The decoder: no port

`decoders/pxx1` (DSView 2e9e2c8) loads and runs in sigrok-cli 0.7.2 exactly
as fetched (`sigrok-cli -P pxx1 --show` lists it, and every ideal waveform
decodes). Nothing was changed, so there is no `PORT.diff`;
`git -C decoders status -- pxx1` is clean. The judge runs sigrok-cli with
`SIGROKDECODE_DIR` set to the decoders folder and `PYTHONDONTWRITEBYTECODE=1`
so it writes nothing there.

## What the judge does

Seven fixed cases (all zero; all ones, which stuffs everywhere; a typical
centred frame; bytes 0x7E and 0x7D in the payload; every flag set; a frame
whose CRC ends in five 1s so a stuffed 0 follows the CRC directly; four
frames in a row, including upper-channel values above 2048) and eight
seeded random ones (1 to 4 frames, every field random). Runs of `-cycles`
500,000 x (frames + 1), as the sheet says. For each case:

- It builds the TX words itself from the interface, runs `RUN_DIR/pe_sim`
  on `RUN_DIR/pxx1.s` with `RUN_DIR/run_args.txt` (one line, `-config` and
  `-mode` only, and it must make P0 push-pull with `-mode 0=pp`, as the
  sheet says; anything else is a setup failure). The mode rule was added
  after the independent review found that the ideal waveform passed with
  no `-mode` at all: pe_sim's default is input, and its printed outputs
  would then drive nothing.
- **Decoder check.** P0's printed changes become a VCD at 50 MHz, and
  `sigrok-cli -P pxx1:data=P0 -A pxx1` reads it. All three of its rows must
  be exactly what the wanted frames give, in order, nothing extra: every bit
  (0, 1, and S for each stuffed bit the decoder removes), every byte (header,
  sixteen bytes, CRC, closing byte), and every field (Start Header, Model ID,
  Type, Range Check, FailSafe, CountryCode, Bind, Flag2, the channel list,
  the six extra flags, CRC, Stop Header). The rows are told apart by the
  length of the text (bits one character, bytes two, fields more).
- **Waveform check**, for what the decoder does not hold to (its bit
  windows are +-1 us and it ignores the pulse width, the frame timing, a
  low line at the end and any period that fits neither window): P0 high at
  cycle 0; pulses grouped into frames (a fall more than 40 us after the last
  one starts a new frame), exactly one group per frame; every low pulse
  400 +-25 cycles; every period 800 or 1200 +-25; the bits so read, with the
  last bit of each frame a 0, equal to the whole wanted frame bit for bit,
  stuffed 0s included; first frame's start 5,000 to 500,000; frame starts
  400,000 to 500,000 cycles apart; P0 high at the end, with at least 40 us
  of quiet after the last pulse.
- `RATE bytes=<16 per frame> cycles=<P0's first change to its last>` for
  the last passing case. P0 does not move before the first frame, so the
  span runs from the first frame's first fall to the last frame's last rise,
  gaps included.

### What the judge adjusts, and two decoder quirks it allows for

- **One added edge.** The decoder reads a bit from its falling edge to the
  next falling edge, and decodes a frame's last bit only when the next
  frame's first fall arrives (any period of 40 us or more is "last bit, a 0,
  end of frame"). In a real link the next frame always comes; in a test run
  the last frame has none. So the judge adds one falling edge at the end of
  its own copy of the capture, when the line is high there. The firmware's
  waveform is checked as printed by the waveform check, which requires the
  line high and quiet to the end.
- **The stuffed 0 after the CRC.** The decoder stops removing stuffed bits
  after its 19th byte (the CRC's low byte), so when the CRC's last bit is
  the fifth 1 of a run, it reads the stuffed 0 that a correct transmitter
  sends next as data: its closing byte reads 0x3F and it says "Header
  error" instead of "Stop Header". `accept.decoder_wants` expects exactly
  that for such frames (about one in 32), and the waveform check requires
  the stuffed 0 to be there. A fixed case triggers it. A transmitter that
  leaves that 0 out would please the decoder and break the protocol; the
  fault `nocrcstuff` shows the judge fails it.
- **The channel list.** The decoder prints the first channel of each pair
  with the two nibbles of its low byte swapped (it combines nibbles 3, 1, 0
  where the packing puts 3, 0, 1). `decoder_wants` expects the decoder's
  text; the bytes row and the waveform check hold the true packing, and the
  fault `nibbles` shows a wrong packing fails.

Both quirks are confirmed by sigrok itself: every ideal waveform in the
self-test, on five seeds, decodes to exactly what `decoder_wants` predicts.

## What the judge does not check

- Anything between edges: the levels are fully fixed by the edges.
- What the firmware does with words that break the interface: the judge
  never sends them.
- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the simulator into the run folder themselves.
- `run_args.txt` may hold configuration constants (`clkdiv`, `crc_poly`,
  `out_msb_first` and so on). That is the chip's hardware, not the
  instruction set; read the configuration line with `notes.md` when
  hand-ins are compared.
- Cumulative drift inside a frame: each pulse and bit is held to +-0.5 us on
  its own, as the module reads them, not to a grid from the frame's start.
- A frame period of exactly 9 ms: 8 to 10 ms is accepted (see above).
- A slow host is never provoked: the simulator refills the FIFO at once.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`): 33 checks
ok and 165 waveform verdicts (33 waveforms x 5 seeds), every one as
expected.

- Interface: `tx_words` gives exactly the twenty words the sheet prints,
  and the sheet holds the payload-only sentence.
- CRC: the judge's table (the 0x8408 register run bit by bit) equals the
  sheet's carry-less definition on all 256 values and the values the sheet
  prints; the table is CRC-16/KERMIT's (check value 0x2189 when used the
  reflected way), and PXX1's CRC of `123456789` is not that.
- Examples: both frames' bytes and CRCs, and both printed bit strings (the
  second with its four stuffed 0s), equal the judge's; the generator puts
  the first example's edges where the sheet says.
- Waveforms: 33 waveforms on 5 seeds. The 7 that must pass do: the ideal;
  every pulse and every bit 25 cycles off, alternately long and short (the
  limit); frames every 8 ms and every 10 ms (the limits); a fixed 5.5 ms
  idle gap after each frame instead of a fixed period; first frame at cycle
  5,000 and at 500,000. The 26 broken ones all fail: one channel bit
  flipped; one channel value changed with a CRC to match; the CRC-16/KERMIT
  CRC instead of PXX1's; CRC bytes swapped; no stuffing; stuffing after six
  1s; header and closing byte stuffed too; no stuffed 0 after a CRC that
  ends in five 1s; the run of 1s restarted at every byte; bytes LSB first;
  the shared channel byte's nibbles swapped; no closing byte; the line
  inverted; one period 26 cycles long, one 26 short; pulses of 9 us; one
  pulse of 7 us; zeros of 17 us; frames every 7.99 ms and every 10.0002 ms;
  first frame at 4,999 and at 500,001; a 1-cycle glitch after the last
  frame; the line driven low after the last frame; a frame missing; a frame
  repeated. The decoder check alone catches the coding faults; the timing
  faults (the periods 26 cycles off, the pulse widths, the 17 us zeros,
  which the decoder still reads, the frame period, the start, the line left
  low) are caught by the waveform check only, as intended.
- RATE: for the ideal waveform the line equals the figure from the
  generator's own edges on every seed (seed 1: `RATE bytes=16
  cycles=168400`).
- Hand-in rules: fourteen `run_args.txt` files; the two good ones are
  accepted, the twelve bad ones (`-tx`, `-t`, `-cycles`, `-inputs`,
  `-stimulus`, an ambiguous `-c`, two lines, a flag with no value, no
  `-mode` for P0, `-mode 0=od`, `-mode 1=pp` only, and `-mode 0=pp` undone
  by a later `-mode 0=in`) are setup failures. Each of the four mode cases
  runs the ideal waveform, which would pass if the mode were not checked.
- The real simulator: the kit's `pe_sim` with two programs that are not
  PXX1 firmware (one loops and never writes P0; one drives P0 low once and
  loops). The simulator accepted the command line and the word files, and
  all 15 cases of each failed cleanly, with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md`: yes in
principle, but this is a hard one, and the CRC is the reason.

The line itself is easy for this chip: two edges a bit, 400 cycles apart
and then 400 or 800 more, stuffing as a run counter, packing as a matter of
shifting the right number of bits out of two channel words. Time is ample:
a bit is 800 or 1200 cycles at 50 MHz.

The CRC is not a CRC the chip's CRC register can produce by being fed the
data. The register is a reflected LFSR (shift right, add the polynomial when
the bit in differs from bit 0). PXX1's CRC uses a reflected table with a
left shift; I checked that the 128 contributions of the frame's data bits
to it satisfy no linear recurrence shorter than the frame (a Hankel matrix
of the contributions has full rank, 88 of 88, whether the bits are fed MSB
or LSB first), so no polynomial of 32 bits or fewer gives it, and also that
no 32-bit polynomial even gives its byte table with the halves in the right
places. What the register can do is part of the work: with polynomial
0x8408, restarted and fed a byte v, it holds T[v], one table lookup a byte;
or, with polynomial 0x8000, it is a 16-bit rotate-and-XOR accumulator. Either
way some 8-bit XORs (h XOR byte, then the low byte XOR the table's high
byte) are left for the firmware, and the instruction set has no XOR: they
have to be done bit by bit through branches, with only X, Y, the ISR and the
OSR to hold the CRC state, the channel words and the bit being sent, while
the edges keep their 25-cycle limits. The sixteen bytes cannot be stored, so
this has to happen while the frame goes out. I expect it to fit in 256
words and in the time, but it is a register-allocation puzzle, and I would
put this protocol among the likeliest of Part A to fail.
