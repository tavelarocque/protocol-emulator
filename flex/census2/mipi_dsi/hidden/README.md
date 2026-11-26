# Hidden test: MIPI DSI low-power transmitter (decoder `MIPI_DSI`, from DSView)

This folder is the examiner's side of round 2, Part A, for the MIPI Display
Serial Interface. The programmer gets only the kit (`../../kits/mipi_dsi/`:
`isa.md`, `pe_sim`, `TASK.md`) and never sees this folder. No firmware for
the chip was written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal DSI escape-mode transmitter as a waveform generator, standing in for `pe_sim`, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the packets, the interface, the sheet's example, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `PORT.diff` | `git -C DECODERS diff -- MIPI_DSI`: the mechanical port of the decoder to sigrok-cli 0.7.2 |
| `README.md` | this file |

## Role chosen: transmitter, in low-power escape mode

The chip is the host processor's end of a DSI link and sends command packets
to a display by Low-Power Data Transmission (LPDT) in escape mode on data
lane 0. Nothing is received and there is no bus turnaround.

DSI's high-speed mode cannot be done here: it is a differential low-swing
signal (about 200 mV) at 80 Mbit/s and up per lane, which needs differential
drivers this chip does not have. But every D-PHY lane also has a low-power
mode with two single-ended lines, and LPDT in escape mode is part of the
DSI and D-PHY specifications, not a test mode: it is how hosts send DCS
commands (sleep out, display on, panel setup) before or between video, and
many panels are set up this way. It is also exactly what
the decoder reads: its own description is "MIPI Display Serial Interface low
power communication", and it decodes nothing of high speed. The chip plays
the D-PHY lane in LP mode; the real link's 1.2 V levels are assumed to come
from a level shifter, which the sheet says.

Clock 50 MHz, one cycle = 20 ns. Pins, all push-pull: P0 = lane 0 Dp, P1 =
lane 0 Dn, P2/P3 = clock lane Dp/Dn (held in LP-11, the Stop state, for the
whole run), P4 to P7 unused. The judge requires `-mode` to make P0 to P3
push-pull (later flags win, as in pe_sim).

The protocol facts the sheet gives, from the D-PHY specification as I know
it: escape entry LP-11, LP-10, LP-00, LP-01, LP-00; the LPDT entry command
1,1,1,0,0,0,0,1 in sending order; bytes least significant bit first;
spaced-one-hot code (Mark-1 = LP-10, Mark-0 = LP-01, each followed by the
space LP-00); exit Mark-1 then LP-11; TLPX at least 50 ns (the sheet rounds
it to 3 cycles); T_INIT at least 100 us of Stop state before the first
transmission. The sheet's own limits, stated as such in it: every state at
most 50 cycles (1 us), the first transmission by cycle 10000, Stop state
between transmissions at most 1000 cycles, and WC at most 26 (DSI allows
65535; a packet of at most 32 bytes keeps runs short and loses nothing of
the coding). The Stop state between transmissions has the specification's
minimum only, TLPX, so 3 cycles like every other state (the review of
round 2 asked for a reason for the earlier 50-cycle minimum, which had
none, and it was lowered). The maxima bound the run and keep a
transmission from being dribbled out, and leave the timing otherwise free,
since escape mode is clocked by the receiver from Dp XOR Dn and the
specification gives minima only.

## The host interface

The words carry each packet's content only (first version of this test let
the host form the ECC and checksum; the census organiser ruled that a
CRC, checksum or ECC is part of the protocol's coding, which the firmware
must do, as round 1's USB-PD firmware computed its CRC-32, and the sheet was
changed before any programmer saw it). Per packet:

- first word: the data identifier (virtual channel in bits 7..6, data type
  in 5..0) in bits 7..0, bit 8 = 1 for a long packet; bits 15..9 0;
- second word: a short packet's two parameters (first in bits 7..0, second
  in 15..8), or a long packet's word count WC (0 to 26). The host sends WC
  because the firmware must put it on the wire before the payload and could
  not count a payload it has not yet read;
- then, for a long packet, WC words, one payload byte each in bits 7..0.

The firmware forms the packet: DI, the two header bytes, the ECC (P5..P0 as
the DSI specification defines them over the 24 header bits, bits 7..6 zero),
then for a long packet the payload and the checksum (CRC-16, x^16 + x^12 +
x^5 + 1, reflected, from 0xFFFF, no final inversion), low byte first. Each
packet is one LPDT transmission. The sheet gives the parity table, the CRC's
parameters and check value, and two packets as bytes on the wire: "exit
sleep mode" 05 11 00 36 and "column address set" 39 05 00 36 2A 00 00 00 EF
48 03. Its word example is those two packets: 0x0005, 0x0011, 0x0139,
0x0005, 0x002A, 0x0000, 0x0000, 0x0000, 0x00EF. The sheet says "The host
sends only the words defined above. All line coding, framing and timing must
be done by the firmware." The firmware is told the packet's kind by bit 8,
so it need not know DSI's table of data types, and half the random cases use
any of the 64 data types.

The judge's ECC gives the widely published 05 11 00 36 and 05 29 00 1C, and
its checksum's check value over `123456789` is 0x6F91. The ideal generator
computes both differently (the specification's parity equations, and a
non-reflected CRC on bit-reversed bytes), and the self-test checks that the
two agree on every packet of every case.

## The decoder port (`PORT.diff`)

The decoder is DSView's `MIPI_DSI` (folder `MIPI_DSI` in DECODERS, from
DSView 2e9e2c8). As fetched, sigrok-cli 0.7.2 refuses to load it:

    srd: Protocol decoder MIPI_DSI annotation 13 should be a tuple with two elements.
    srd: Failed to load decoder MIPI_DSI: cannot get annotations

Two hunks, both in `pd.py`, both mechanical:

1. **Annotations.** DSView's annotation entries are three strings, a
   colour-type number first, then the id and the description, for example
   `('111', 'LP-00', 'LP-00')`. sigrok 0.7.2 takes two, id and description.
   The port drops the first string of each of the 13 entries and changes
   nothing else; the annotation rows still refer to the same indices, and
   the decoder's code never reads the type numbers. This is how a decoder
   registers its annotations, which PREREG2 allows.
2. **`self.matched`.** After `wait` with a list of conditions, DSView sets
   `self.matched` to an integer bit mask; sigrok 0.7.2 sets a tuple of
   booleans, one per condition. With only hunk 1 the decoder printed its
   first "Escape mode entry" and then died:
   `TypeError: unsupported operand type(s) for &: 'tuple' and 'int'` at
   `if (self.matched & (0b1 << 0)):`. The port reads the same condition,
   number 0, as `if self.matched[0]:`. Same meaning, different API.

No other line changed. In particular the state machine, the conditions it
waits for, the bit order and the byte assembly are as fetched. The decoder
calls `self.put` on `OUTPUT_BINARY` with `['DATA', None]`, which is not valid
binary output in 0.7.2, but sigrok-cli only converts binary output when
asked for it (`-B`), and the judge never asks, so that line was left alone.

## What the decoder does, found by reading `pd.py` and running it

- It waits for Dn falling while Dp is high (LP-11 to LP-10), then LP-00,
  then LP-01 or LP-10, then LP-00, and says "Escape mode entry" (LP-01) or
  "Bi-directional Data Lane Turnaround" (LP-10).
- Then for every mark (LP-10 or LP-01) followed by LP-00 it takes one bit,
  1 for LP-10, least significant bit first, and prints a byte every eight
  bits, as `0x%02X`. A mark followed by LP-11 is the exit: "Stop". It does
  not know entry commands, so LPDT's 1,1,1,0,0,0,0,1 prints as `0x87`, the
  first "byte". A part byte before the exit is dropped without a word.
- It measures no time at all.
- A one-cycle excursion from LP-11 (a glitch on Dn) puts it into its entry
  search early, and it then reads the next real transmission correctly, so
  it does not see such a glitch.

So the judge requires, per packet, exactly `Escape mode entry`, `0x87`,
the packet's bytes as the judge forms them (DI, header bytes, ECC, payload,
checksum), `Stop`, in order, nothing else. That checks the firmware's ECC
and checksum byte for byte, and a mismatch is reported by field ("packet 1,
checksum"). The waveform check compares the lane's states with the same
bytes, so it checks them a second time from the pin changes. Time, state
order and the clock lane are the judge's own checks.

## What the judge checks

For 6 fixed cases (the sheet's example, a short packet; the sheet's words, a
short and a long packet; four short packets with header bits all 1, all 0
and alternating; a 32-byte DCS long write, 26 payload bytes; six packets of
different types on virtual channels 0 to 3, including a long packet with no
payload; long packets of 26 bytes 0xFF, 26 bytes 0x00 and one byte 0x80) and
8 seeded random cases (1 to 6 packets each, short or long, payload 0 to 26
bytes; even-numbered cases use any of the 64 data types, odd ones the types
a host sends in LPDT). `-cycles` is the sheet's N. For each case:

- It builds the TX words itself from the interface, runs `RUN_DIR/pe_sim`
  on `RUN_DIR/mipi_dsi.s` with `RUN_DIR/run_args.txt` (one line, `-config`
  and `-mode` only, P0 to P3 push-pull; anything else is a setup failure).
- **Decoder check.** P0 and P1's printed changes, exactly as printed, become
  a VCD at 50 MHz (timescale 20 ns, one sample per cycle).
  `SIGROKDECODE_DIR=DECODERS sigrok-cli -P MIPI_DSI:D0N=P1:D0P=P0 -A MIPI_DSI`
  reads it; its annotations must be exactly the wanted list above. Any
  `srd:` error or traceback from sigrok is a judge failure, never a pass.
- **Waveform check**, everything the decoder does not hold to: the clock
  lane (P2, P3) in LP-11 from cycle 0 to the end, never changing; data lane
  0 starts in LP-11; no change moves Dp and Dn in the same cycle; the lane,
  cut at its Stop states into transmissions, has exactly one per wanted
  transmission, each with exactly the state sequence of the sheet (entry,
  command, marks and spaces, Mark-1, LP-11); every state from the first
  LP-10 to the last LP-10 lasts 3 to 50 cycles; the first transmission's
  first change at cycle 5000 to 10000; Stop state between transmissions of
  3 to 1000 cycles; the lane back in LP-11 at the end and nothing on P0 to
  P3 moving after the last transmission.
- `RATE bytes=<packet bytes on the wire, ECC and checksum included>
  cycles=<first change on P0..P3 to the last>` for the last passing case. The first change is the first
  transmission's LP-11 to LP-10 (the pins idle high from reset), so unlike
  OOK's the span does not include the 5000-cycle start.

## What the judge does not check

- Anything analog: levels, slew rates, the 1.2 V swing, contention
  detection. The chip drives logic levels; the sheet assumes a level
  shifter.
- High-speed mode, the clock lane's own HS clock, ULPS, triggers and bus
  turnaround: not part of the task.
- Whether a data type is short or long in DSI's table: the host says so in
  bit 8, and the judge pairs any data type with either kind.
- P4 to P7, which the sheet leaves unused: the judge ignores them (the
  `spare` waveform toggles P4 and passes).
- What the firmware does with words that break the interface: the judge
  never sends them. A slow host is never provoked: the simulator refills
  the FIFO at once.
- `run_args.txt` may hold configuration constants (`clkdiv`, `set_base`,
  `set_count` and so on). That is the chip's hardware, not the instruction
  set; read it with `notes.md` when hand-ins are compared.
- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the simulator into the run folder.
- The decoder's location is fixed in `accept.py` (the DECODERS folder of
  this round), overridable with the environment variable
  `MIPI_DSI_DECODERS`, and must hold the port in `PORT.diff`.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- Packets and interface: the judge's ECC gives 05 11 00 36 and 05 29 00
  1C; its checksum's check value is 0x6F91; `tx_words` gives exactly the
  words printed in the sheet, and the sheet contains that text; the wire
  bytes the sheet prints for its long example are the judge's; an empty
  long packet is two words and ends in checksum 0xFFFF; the generator, which
  reads the words back and forms the packets in its own code, gives the
  judge's wire bytes in every case.
- Example: the bits and lane states in the sheet's table for "exit sleep
  mode" equal the judge's `lane_states`, 86 changes (22 + 16n), and the
  generator's own, which it computes differently (rises and falls of single
  lines, against the judge's list of states).
- Waveforms: 35 waveforms on 5 seeds, 175 verdicts, all as expected. The 5
  that must pass do: the ideal (5-cycle states); every state at the 3-cycle
  minimum with the earliest start and the shortest Stop states; every state
  at the 50-cycle maximum with the latest start and the longest Stop states;
  state lengths scattered from 3 to 50; P4 toggling. The 30 broken ones all
  fail. Nine break the packet layer: ECC bit P2 inverted, the ECC's six
  bits reversed, ECC bits 6 and 7 set, the checksum left out, one checksum
  bit inverted, the checksum high byte first, the CRC started from 0, the
  checksum inverted, a long packet's word count left out. The others: one
  bit on the wire flipped, bytes most significant bit first, the LPDT
  command reversed, the ULPS command, a turnaround entry instead of escape
  entry, exit with no Mark-1, a missing space (Dp and Dn changing
  together), all packets in one transmission, the last bit missing, one
  state of 2 cycles, one of 51, first transmission at 4999 and at 10001,
  Stop states of 2 and 1001, a 10-cycle low pulse on the clock lane, the
  whole lane idling low, a one-cycle glitch in a Stop state, a stray pulse
  after the last transmission, a packet missing, one repeated. The decoder
  check catches every coding and packet fault; the timing, clock lane and
  glitch faults are caught by the waveform check only, as intended.
- RATE: for the ideal waveform the line equals the figure from the
  generator's own transitions on every seed (seed 1:
  `RATE bytes=29 cycles=2425`).
- Hand-in rules: fourteen `run_args.txt` files; the two good ones are
  accepted, the twelve bad ones (P3 not given, P1 open-drain, P3 given as
  pp then overridden as an input, a comma list pe_sim does not take, `-tx`,
  `-t`, `-cycles`, `-inputs`, `-stimulus`, an ambiguous `-c`, two lines, a
  flag with no value) are setup failures.
- The real simulator: the kit's `pe_sim` with two programs that are not DSI
  firmware (one loops and never writes a pin; one drives P0 low once and
  loops). The simulator accepted four `-mode` flags, the command line and
  the word files, and all 14 cases of each failed cleanly with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md`: probably yes,
but this is now a hard task, and the ECC is why.

The lane itself is easy. With `set_base` 0 and `set_count` 2 one `set pins`
puts the lane in any state (1 is LP-10, 2 is LP-01, 0 is LP-00, 3 is
LP-11), the delay field covers the 3 to 50 cycles a state may last, and
`out x, 1` then `jmp !x` sends a bit least significant first. The checksum
is easy too: it is exactly what the CRC register does with `crc_poly`
0x8408 and `crc_init` 0xFFFF, fed one bit per OUT as the payload goes out,
and its low 16 bits are already in sending order; write `crc` before each
payload to restart it.

The ECC is the hard part. It is six parities, each over 13 or 14 of the 24
header bits. There is no exclusive or, and the one CRC register cannot
serve: its polynomial is fixed for the run and the checksum needs 0x8408
(I checked by brute force that no bit of a 0x8408 CRC over the 24 header
bits, with up to 63 trailing zero bits, in either order, equals any ECC
parity). So a parity has to come from control flow: count the set bits a
mask selects, by decrementing a register (`jmp !x` then `jmp y--`), and
take the count's low bit, or keep the parity in which copy of a loop is
running. The masks must live in the code (`out null, k` skips the bits a
parity leaves out, which unrolls to 2 or 3 instructions per selected bit,
about 80 selected bits in all), and the 24 header bits must be kept across
six passes while X, Y, ISR and OSR also hold the stream, the count and a
bit under test. That is tight: a programmer will probably need a spare pin
(P4 to P7, which the judge ignores and run_args may make push-pull) as a
bit register through `out pins`/`in pins`, or counters packed beside data
in one register. My estimate is 120 to 220 instructions over several pages
of the 256 words, with the ECC done in the Stop state before each packet
(about 6 x 24 bit steps of a few cycles each, inside the 1000-cycle gap).
It fits, but only a careful programmer will find a layout that does, and
the risk of a failed first hand-in is real. The time limits are not the
risk; the register budget and program size are.
