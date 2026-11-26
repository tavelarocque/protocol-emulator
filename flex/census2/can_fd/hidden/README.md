# Hidden test: CAN FD transmitting node (DSView decoder `can-fd`)

This folder is the examiner's side of round 2, Part A, for CAN FD. The
programmer gets only the kit (`../../kits/can_fd/`: `isa.md`, `pe_sim`,
`TASK.md`) and never sees this folder. No firmware for the chip was written
for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal CAN FD node as a waveform generator, standing in for `pe_sim`, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the sheet's example, the CRC, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `PORT.diff` | the mechanical port of DSView's decoder to sigrok-cli 0.7.2 (`git -C DECODERS diff -- can-fd`) |
| `README.md` | this file |

## The role, and why: BOTH

The chip is a CAN FD node that transmits. A CAN frame is not complete
without its acknowledgement: the transmitter sends the ACK slot recessive,
and another node pulls it dominant. A transmitter that ignores the ACK slot
is not a CAN node, so the chip also reads the line, once per frame, and
acts on it: on a missing ACK it must send an active error flag (6 dominant
bits from the ACK delimiter's place, then the 8-bit error delimiter), as
ISO 11898-1 requires, and report the outcome to the host. Automatic
retransmission is off (the single-shot mode CAN controllers offer, M_CAN's
DAR, the MCP2517FD's one-shot mode), so the run's schedule is fixed.

P0 is the bus line at logic level, open-drain, wired-AND: nodes on one
board without transceivers, or the logic side of a transceiver. The second
node is the scripted stimulus: it pulls P0 low for exactly the ideal ACK
slot of each frame it acknowledges. Because it cannot react, the sheet fixes
the schedule: first SOF at cycle 2000, each later SOF exactly 300 cycles
(the 3-bit intermission) after the previous frame's end. That is also what a
real node with a queue of frames does.

Clock 50 MHz (20 ns a cycle). Nominal rate 500 kbit/s (100 cycles), data
rate 2 Mbit/s (25 cycles), sample point 80 % in both, which is the common
CiA configuration. The rate switches at the BRS bit's sample point and back
at the CRC delimiter's, so the BRS bit is 85 cycles and the delimiter 40
when BRS is 1. Every chip edge must be within +-1 cycle of its ideal
absolute place.

## One restriction: CRC-17 frames only (DLC 0 to 10)

CAN FD uses CRC-17 for frames of up to 16 bytes and CRC-21 above. The chip's
CRC register takes one polynomial, `crc_poly`, which is per-thread
configuration written by the host; the census gives one `run_args.txt` for
every run and allows no host-side code. With one polynomial per hand-in, a
run mixing the two sizes would need the other CRC in software, and the ISA
has no XOR or AND: a bit-serial 17- or 21-bit CRC on 16-bit registers at 25
cycles a bit is not a fair ask. So the sheet fixes data lengths 0 to 16
bytes (DLC 0 to 10, every CRC a CRC-17), a real class of CAN FD node, and
says the other DLCs exist and are not sent. This is a finding about the
chip worth recording: a real host could rewrite `crc_poly` between frames,
but within the census rules a single hand-in cannot serve both CRC sizes.
The judge keeps the CRC-21 code (it is checked against its catalogue value)
but no case uses it.

## The host interface, as the sheet states it

Per frame: a header word (bit 15 IDE, bit 14 BRS, bits 3..0 DLC, rest 0);
the identifier, one word for base format (bits 10..0), two for extended
(identifier bits 28..16 in bits 12..0, then bits 15..0); the data bytes two
to a word, first byte in bits 15..8, an odd last byte with 0 below it. RX:
one word per frame, 0x0001 acknowledged, 0x0000 ACK error, pushed between
the start of the frame's ACK slot and the frame's end. The sheet's example:
the words 0x4001, 0x0020, 0xF000, 0x8003, 0x1ABC, 0xDE12, 0x1122, 0x3300,
and RX 0x0001, 0x0000. The sheet says "The host sends only the words defined
above. All line coding, framing and timing must be done by the firmware."
Stuffing, the stuff count, the CRC, fixed stuff bits, the rate switch, the
ACK check and the error flag are all the firmware's.

## Where the protocol facts come from

From ISO 11898-1:2015 as I know it, and checked where it matters against
the source of CTU CAN FD (an open-source ISO CAN FD controller,
`can_crc.vhd`, `bit_stuffing.vhd`, `trigger_mux.vhd`, `tx_shift_reg.vhd`,
`protocol_control_fsm.vhd`): the CRC-17/21 registers start with the top bit
1 (ISO), are fed the bit stream with dynamic stuff bits, include the stuff
count and parity, and exclude fixed stuff bits; the stuff count is the
number of dynamic stuff bits modulo 8 in the Gray code of the sheet's table,
with even parity; a dynamic stuff condition at the end of the data field is
taken by the first fixed stuff bit, which is not counted. The polynomials
and shift were checked against the CRC catalogue's check values
(CRC-17/CAN-FD 0x04F03, CRC-21/CAN-FD 0x0ED841, from a zero start).

## The decoder, its port, and what it does and does not check

DSView's `can-fd` at 2e9e2c8 did not load in sigrok-cli 0.7.2. `PORT.diff`
has two hunks, both mechanical:

1. `from common.srdhelper import bitpack_msb` failed: sigrok 0.7.2's
   `srdhelper` has `bitpack` (LSB first) but no `bitpack_msb`. The hunk
   imports `bitpack` and defines `bitpack_msb` in `pd.py` as a verbatim copy
   of DSView's own definition (`libsigrokdecode4DSL/decoders/common/
   srdhelper/mod.py` at 2e9e2c8). No other decoder's folder or `common` was
   touched.
2. `self.matched & (0b1 << 1)` and `& (0b1 << 0)`: DSView sets `matched` to
   an integer bitmask (`type_decoder.c` at 2e9e2c8, line 1118,
   `PyLong_FromUnsignedLongLong(di->match_array)`); sigrok 0.7.2 sets a
   tuple of booleans. The hunk reads `self.matched[1]` and
   `self.matched[0]`, the same bits.

Nothing that decides what a waveform decodes to was changed. The decoder
is run with `nominal_bitrate=500000:fast_bitrate=2000000` and its default
sample point (70 %).

Found by reading `pd.py` and running it on synthetic captures:

- It does not check the CRC (`is_valid_crc` returns True, "TODO"). It does
  print the CRC it read, so the judge requires that text to equal the CRC it
  computes itself. It does check the stuff count's Gray code against its own
  count of stuff bits, and the parity, with warnings; the judge requires
  their exact texts and no warning.
- It resynchronises only on falling edges, and after switching back to the
  nominal rate it measures the next bit from the last falling edge at the
  nominal width, so with no edge it samples the ACK slot far too late. With
  an ACK, the receiver's falling edge resynchronises it and the ACK, ACK
  delimiter and EOF decode correctly. Without one, the error flag's falling
  edge is taken as the ACK slot: it reports "ACK slot: ACK" and then
  warnings. So for an unacknowledged frame the judge compares the decoder's
  annotations only up to the CRC delimiter and requires it to end the frame;
  the ACK slot, the error flag and its delimiter are checked from the pins.
- It ignores where the edges fall within a bit, so all timing is the pin
  check's.
- DSView's library counts `skip` slightly differently after a match
  (`type_decoder.c` line 853); that could move a sample point by one sample
  against DSView itself. With samples 17 or more cycles from any edge it does
  not change a decode here.

## What the judge checks

Nine fixed cases (the sheet's example; the sheet's words; four frames with
no data, base and extended, both rates; 16 bytes of 0x00 at the data rate;
16 bytes of 0xFF extended at the nominal rate; DLC 8, 9, 10; DLC 1, 3, 5, 7
with an odd byte; an unacknowledged frame between two acknowledged ones; two
unacknowledged frames at both rates, the last one included) and eight seeded
random ones (1 to 6 frames, base or extended, BRS mostly 1, DLC 0 to 10,
random or run-heavy data, about one frame in five unacknowledged). For each:

- It builds the TX words and the stimulus itself, runs `RUN_DIR/pe_sim` on
  `RUN_DIR/can_fd.s` with `-tx`, `-stimulus`, `-cycles` (the last frame's
  end plus 2000) and `run_args.txt` (one line, `-config` and `-mode` only,
  and it must make P0 `od`; anything else is a setup failure).
- **Waveform**: the chip's P0 output (not the bus) against the ideal node,
  change by change: the same number of changes, each the right direction and
  within +-1 cycle of its ideal absolute place. This holds every bit time,
  the 85 and 40 cycle switch bits, the stuff and fixed stuff bits, the stuff
  count, parity and CRC values, the ACK slot left released, the error flag
  exactly on a missing ACK, the schedule, and silence before, between and
  after frames. P1 to P7 are ignored.
- **Decoder**: the bus (chip output AND stimulus) as a 50 MHz VCD, through
  the ported `can-fd`; per frame the exact annotation texts (SOF, identifier,
  IDE, extended and full identifier, SRR, FDF, RRS, reserved bit, BRS, ESI,
  DLC, every data byte, stuff count, parity, CRC sequence, CRC delimiter,
  and for acknowledged frames ACK, ACK delimiter, EOF), no warnings, the
  right number of frames, nothing before the first.
- **RX**: one word per frame, in order, 0x0001 or 0x0000 as the stimulus
  decided, each between the frame's ACK slot start and its end, no others.
- `RATE bytes=<data bytes> cycles=<P0's first change to its last>` for the
  last passing case (the first change is the first SOF, as P0 starts
  released).

## What the judge does not check

- Frames with more than 16 bytes (above), remote frames (none in FD),
  classic CAN frames, ESI recessive (the node stays error active: at most 6
  ACK errors, TEC at most 48).
- Arbitration loss, bit errors, bus-off, any reaction to a dominant level
  other than the ACK: the scripted bus never makes them.
- What the firmware does with words that break the interface, or with base
  identifiers whose bits 10..4 are all 1: never sent, because the decoder
  warns on them ("Identifier bits 10..4 must not be all recessive", ported
  `pd.py` line 580, the classic CAN rule), which the judge would count as a
  failure on a correct waveform. TASK.md states this reason.
- `run_args.txt` may set any configuration (`clkdiv`, `crc_poly`,
  `crc_init`, shifts, autopull): that is the chip's hardware. Read it with
  `notes.md` when hand-ins are compared.
- A slow host is never provoked: the simulator refills the FIFO at once.
- The judge runs `RUN_DIR/pe_sim`, whatever it is, and reads the decoders
  from DECODERS (the scratchpad path in `accept.py`, or `CANFD_DECODERS`).

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- Interface: `tx_words` gives exactly the words the sheet prints, and the
  sheet says so; DLC 0 has no data words; the extended split is 13 + 16.
- Example: the sheet's 64-row bit table (level, start, length) equals the
  judge's ideal frame; CRC-17 0x05DE7, stuff count 3 (010), parity 1, the
  ACK slot at 4950, the end at 5850, the error-flag variant (5050 to 5650,
  end 6450) and the printed stimulus file all match the sheet; the
  generator's edges for it equal the judge's.
- CRC: the judge's shift register and the generator's polynomial division,
  written separately, both give the catalogue check values from a zero start;
  every case holds DLC 0 to 10 only.
- Waveforms: 43 behaviours on 5 seeds, 215 verdicts, all as expected. The 6
  that must pass do: the ideal node; every edge 1 cycle late; 1 early;
  alternately late and early; RX words at the earliest and at the latest
  allowed cycle. The 37 broken ones all fail: a wrong data bit; a wrong CRC
  bit; the pre-ISO zero-start CRC; CRC without stuff bits; CRC without the
  stuff count; binary stuff count; wrong parity; a dynamic stuff bit before
  the fixed one; no dynamic stuffing in data; no fixed stuff bits; bytes LSB
  first; bytes of a word swapped; extended identifier split wrongly; ESI
  recessive; BRS bit 100 and 25 cycles; CRC delimiter 100 and 25 cycles;
  data bits of 26; nominal bits of 99; one edge 2 cycles late; first SOF at
  2002; intermission of 302; the chip acknowledging itself; the ACK ignored;
  error flags of 5 and 7 bits and one a bit late; RX 1 for an
  unacknowledged frame; an RX word missing, extra, 1 cycle late, 1 cycle
  early; a glitch between frames; a pulse after the last frame; the last
  frame dropped; P0 pulled low at the start. Every coding fault is caught by
  the decoder check as well as the waveform check; pure timing faults
  (2-cycle edge, delimiter of 25, schedule, self-ACK) by the waveform check
  only; RX faults by the RX check only, as intended.
- RATE: for the ideal node the line equals the figure from the generator's
  own edges on every seed.
- Hand-in rules: 13 `run_args.txt` files; the 3 good ones are accepted, the
  10 bad ones (P0 push-pull, P0 not set, `-tx`, `-t`, `-cycles`, `-inputs`,
  `-stimulus`, an ambiguous `-c`, two lines, a flag with no value) are setup
  failures.
- The real simulator: the kit's `pe_sim` with two programs that are not CAN
  FD firmware (one loops and never writes P0; one pulls P0 low once and
  loops). The simulator accepted the command line, word and stimulus files,
  and all 17 cases of each failed cleanly, with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view: possible but the hardest
Part A task, and the likeliest to fail, for one specific reason: the
register budget during the data phase. Each 25-cycle data bit needs the
next data bit (OSR with `out_msb_first` and autopull does that), the run
length of equal bits for stuffing, the last level (readable back from P0),
the count of remaining data bits, and a running count of stuff bits for the
stuff count, with only X, Y, ISR and OSR. `isa.md` itself says that
following stuff bits takes two registers more than a thread has (for
receive). The CRC is the easy part: `crc_poly` 0x1685B reversed with the
ISO start, and because the CRC must include the dynamic stuff bits, feeding
it from `in pins` (`crc_in`) gives exactly the transmitted bits; fixed stuff
bits must then be kept out of it, or the value read before they start. The
way through is to hold the run length in the program counter (code
unrolled per run state, 256 words allow it) and the stuff count in the ISR
or a spare pin, then Gray-code it with a jump table. Twenty-five cycles a
bit is enough for that if every path, word fetches included, is equalised,
and the BRS (85) and delimiter (40) bits, the ACK sample and the error flag
add little. It is a long program and easy to get one path a cycle wrong.
