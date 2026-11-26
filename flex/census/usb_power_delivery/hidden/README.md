# Hidden test: USB Power Delivery transmitter (`usb_power_delivery`)

The examiner's side of one census protocol. The programmer gets only the kit
(`../../kits/usb_power_delivery/`: `isa.md`, `pe_sim`, `TASK.md`) and never
sees this folder. No firmware for the chip was written for this test, not
even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, then `RATE ...`, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal USB PD (BMC) transmitter as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the sheet's numbers, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## The role chosen: TRANSMIT

A PD controller's physical layer both sends and receives, and every message
is answered by a GoodCRC within about a millisecond. A scripted stimulus
cannot react, and a reply that has to line up with a firmware-chosen send
time would make the test about the script rather than the chip. The
transmit half carries everything that makes PD what it is (BMC line code,
64-bit preamble, K-code ordered sets for SOP, SOP' and SOP'', 4b5b coding,
CRC-32, EOP and the closing edge), and sigrok's decoder reads exactly that
half from one pin. So the chip transmits, which is what a small chip would
do as the TX side of a PD PHY: a source sending Source_Capabilities, Accept
and PS_RDY.

## The task as the sheet sets it

- P0 push-pull is CC1 (logic level; a real board adds an analogue driver).
  Core clock 20 MHz, one cycle 50 ns. Thread 0, transmit only.
- BMC at 66 cycles a bit (3.3 us, 303.03 kbit/s; the specification allows
  270 to 330 kbit/s). A transition at the start of every bit, another 33
  cycles in for a 1. The line idles low, so a packet starts with a rise.
- Packet: 64-bit preamble 0101...01; four K-codes for SOP (S1 S1 S1 S2),
  SOP' (S1 S1 S3 S3) or SOP'' (S1 S3 S1 S3); header (4 symbols); 0 to 7
  data objects (8 symbols each); CRC-32 (8 symbols); EOP. Values least
  significant nibble first, each 5-bit code bit 0 first. The full 4b5b table
  is in the sheet.
- CRC: Ethernet's CRC-32 (reflected 0xEDB88320, from all ones, inverted)
  over header and data objects as sent; equal to `zlib.crc32` of them as
  little-endian bytes, which is what the decoder computes.
- After the EOP's last bit, one more transition at the next bit boundary;
  if that leaves the line high, a fall 33 cycles later. Then low and still.
  The decoder needs that closing edge: it only records a bit when the edge
  that ends it arrives, so without it the EOP loses its last bit and the
  decoder reports "No EOP" (shown by the `noclose` waveform).
- Every transition within +-2 cycles of its ideal place, counted from the
  packet's first transition (an error must not add up).
- Gap between packets, last transition to next first: 500 to 40000 cycles
  (25 us is the specification's tInterFrameGap). P0 starts high (the
  output register's reset value); it must be low by cycle 100 and stay low,
  and the first preamble starts at least 500 cycles after that fall and by
  cycle 40000. Nothing moves after the last packet.

## The host interface

Per packet: one word `(objects << 2) | kind` (kind 0 SOP, 1 SOP', 2 SOP'';
bits 15..5 zero), then the 16-bit header, then each data object as its low
16 bits and then its high 16 bits. The CRC is not sent; the firmware
computes it. The sheet's example (Source_Capabilities, 5 V 3 A) is the words
0x0004, 0x11A1, 0x912C, 0x0001, CRC 0x312C2EDA. The sheet says: "The host
sends only the words defined above. All line coding, framing and timing must
be done by the firmware." The object count in the first word duplicates the
header's bits 14..12, as a PD PHY's transmit FIFO is usually told a length;
the firmware does not have to parse the header.

## What the judge checks

Six fixed cases (GoodCRC alone; the sheet's example; SOP' and SOP''
control messages; all-zero and all-one objects; seven objects; a source
caps, request, accept, PS_RDY exchange) and eight seeded random runs of 1 to
5 packets, with random kinds and 0 to 7 random objects, 14 cases in all.

- **Decoder check.** P0's changes become a VCD capture at one sample a
  cycle (20 MHz), padded with 3 ms of silence after the last edge so the
  decoder closes the last packet (it wakes at least once a millisecond).
  `sigrok-cli -P usb_power_delivery:cc1=P0` with the classes preamble, sop,
  header, data, crc, eop and warnings. Per packet, in order, with nothing
  extra: the right SOP name, the header, every data object, the CRC equal
  to the one the judge computes, an EOP, and no warning at all (bad CRC,
  no EOP, truncated, no start of packet).
- **Waveform check**, for what the decoder does not hold to: the decoder
  accepts any number of preamble bits, any bit rate inside its thresholds
  (a 0 is any spacing above 2.5 us, up to 5 us), silently records an
  invalid BMC sequence as a 0, does not care what happens after the EOP,
  and needs only 5 us between packets. So the judge also requires P0 low by
  cycle 100 and still until the first preamble, every transition of each
  packet (preamble included, closing transitions included) within +-2
  cycles of its ideal place counted from the packet's first transition, the
  right number of transitions, the gap limits, the first start within
  40000 cycles, and silence after the last packet.
- `run_args.txt` must be one line of `-config` and `-mode` flags only, each
  with a value (`-tx`, `-cycles`, `-inputs`, `-stimulus`, ambiguous
  prefixes and anything else are a setup failure).
- `RATE bytes=<payload bytes> cycles=<span>`: payload bytes are the header
  and data objects (2 + 4n per packet); the span runs from the first
  packet's first transition to the last packet's last transition. The
  initial fall of P0 near cycle 0 is left out on purpose: it is a reset
  artefact, and counting it would reward starting late less than the gaps
  do. With all cases passing it is the last case, "random 7".

## What it does not check

- It runs `RUN_DIR/pe_sim`, whatever that is. Whoever runs the judge must
  put the real simulator there.
- Only P0 is looked at. Other pins may do anything.
- Pin mode is not checked; the judge reads the output register as the
  simulator prints it, as the pilot judges did.
- Bit rate is fixed at 66 cycles; the sheet allows no other rate, though
  the specification allows a range. The +-2 cycle limit is much tighter
  than the specification's own jitter and eye limits.
- Hard Reset, Cable Reset, SOP' Debug, SOP'' Debug, extended messages and
  BIST carrier mode are not asked for. Headers are random but plausible and
  always agree with the object count.
- Configuration constants in `run_args.txt` (clkdiv, the CRC register's
  polynomial and init, and so on) are the chip's hardware, not the
  instruction set; they should be read when hand-ins are compared.
- The host never runs slow: the simulator refills the FIFO at once.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`, about 90 s).

- The sheet: the judge's words for the two examples are the words printed
  in the sheet; the two CRCs printed there (0x312C2EDA, 0xA8BB6CBB) are the
  judge's (zlib) and the generator's (bit-serial shift register); the
  example's 189 bits, first transitions 0, 66, 99, 132, 198, 231 and
  closing transition at 12474 are the judge's; the judge's 4b5b values match
  the specification's bit strings typed into the generator.
- Waveforms: 26 waveforms on 5 seeds, 130 verdicts, all as expected. The 5
  that must pass do: ideal; every transition 2 cycles off (the limit); gaps
  of exactly 40000; first preamble at cycle 40000; P0 low only at cycle 100
  and the preamble 500 cycles later. The 21 broken ones all fail: a flipped
  data bit, a wrong CRC bit, a CRC computed the non-reflected way, nibbles
  swapped within each byte, one transition 3 cycles late, one 3 cycles
  early, bits of 67 cycles, preambles of 62 and 66 bits, SOP' sent for SOP,
  no EOP, no closing transition, a closing rise left high, gaps of 499 and
  40001, a first preamble at 40001, P0 low only at cycle 101, P0 never
  driven low, a stray pulse after the last packet, the last packet missing,
  the last packet twice. The waveform check objects to all 21; the decoder
  check also objects to the 9 that change what is decoded (data bit, CRC
  twice, nibble order, SOP, no EOP, no closing transition, packet missing
  or doubled), and to none of the timing, preamble-length, idle-level, gap
  or line-left-high faults, which is why the waveform check is there.
- RATE: for the ideal waveform it equals the figure from the generator's
  own transition list on every seed (seed 1: `RATE bytes=84 cycles=90996`).
- Hand-in rules: ten `run_args.txt` files, two good and accepted, eight
  bad and refused as setup failures.
- The real simulator: the kit's `pe_sim` behind a wrapper with a
  one-instruction program that loops on itself (not PD firmware). The
  command line and word file were accepted and all 14 cases failed cleanly
  ("P0 is still high at cycle 100"), with no RATE line.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, and it is
the hardest of the transmit tasks I would expect in the census short of the
wide buses. A bit is 66 cycles and a half bit 33, so timing is generous:
`clkdiv` 3 or 11 puts both on an exact grid. The CRC is the decisive piece,
and the chip has it: the per-thread CRC register with the Ethernet
polynomial, all-ones init and `crc_invert` gives PD's CRC-32 exactly, and
`mov` reads it out in two 16-bit halves and then stops following the data.
The trap is that the register follows every OUT (or, with `crc_in`, every
IN), so only the data bits may pass through that path while the CRC is
running; 4b5b symbols and preamble bits must come from `set` immediates
(a 5-bit code fits `set x`), the line from `set pins` or side-set. 4b5b needs
a 16-way choice per nibble with only `!x`, `x--` and `x!=y` to branch on, so
a bit-by-bit decision tree of about 30 words, or 16 entry points. BMC is a
code of toggles and nothing inverts a pin, so the level lives in the control
flow (two copies of the bit routine) or in a register. Register pressure is
the real difficulty: X, Y, OSR and ISR must hold the nibble, the symbol, a
bit count, the object count and the level between them. 256 words of memory
are ample. I expect a solution of 80 to 200 instructions, and a fair chance
that a first hand-in fails on an off-by-a-few-cycles path or on the CRC
picking up a non-data OUT.
