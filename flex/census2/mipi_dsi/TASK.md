# Task: MIPI DSI (Display Serial Interface) low-power transmitter firmware for the protocol emulator

You are writing firmware for a small programmable I/O chip, the protocol
emulator. You have never seen its source. Everything you may use is in this
directory:

- `isa.md`: the instruction set, its timing and the assembler syntax. It
  mentions files elsewhere in a repository (`model/...`, `hw/...`,
  `docs/info.md`); you do not have them and must not look for them.
- `pe_sim`: the assembler and a simulator of the chip (the reference model
  the hardware is checked against every cycle). `./pe_sim asm FILE.s`
  assembles; `./pe_sim run FILE.s -help` explains how to run a program on
  thread 0 with a configuration, pin modes and words pushed to the TX FIFO,
  and prints every change of the pins' outputs, with the cycle number.

Rules for this test, which is measuring how easy the chip is to program:
- Read only the files in this directory, and write only here. Do not open
  anything elsewhere on the machine (no repository, no other firmware, no
  searching the filesystem). Your general knowledge of MIPI DSI, MIPI D-PHY
  and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that sends commands to a display over MIPI DSI in low-power mode,
as the host processor's end of the link, on thread 0, with the chip's core
clock at 50 MHz (one cycle = 20 ns; the thread may run every cycle). The
chip only transmits: nothing is received, and the display never drives the
lane (there is no bus turnaround).

A DSI link has a clock lane and one or more data lanes, each a pair of
wires, Dp and Dn. At high speed a lane is a small differential signal, which
this chip does not make. But every lane also has a low-power (LP) mode in
which Dp and Dn are two separate single-ended lines, and in LP mode data
lane 0 can carry bytes in escape mode, by Low-Power Data Transmission
(LPDT). That is how a host sends DSI command packets to a display without
high speed, for example the commands that set a panel up before any video.
That is this firmware's job. (A real link's LP levels are 1.2 V; a level
shifter between the chip and the display is assumed, so here a 1 on a pin
is LP high.) The receiver is a logic analyser's MIPI DSI low-power decoder.
Everything you need to know about it is here.

Pins, all push-pull:

| Pin | Line |
|---|---|
| P0 | data lane 0, Dp |
| P1 | data lane 0, Dn |
| P2 | clock lane, Dp |
| P3 | clock lane, Dn |
| P4 to P7 | not used; the test ignores them |

A lane's state is written LP-xy, with x the level of Dp and y the level of
Dn: LP-11 is both high, LP-10 is Dp high and Dn low, LP-01 is Dp low and Dn
high, LP-00 is both low.

- The clock lane stays in the Stop state, LP-11 (P2 and P3 high), for the
  whole run. It never changes.
- Data lane 0 is in the Stop state, LP-11, whenever it is not transmitting.
  A push-pull pin is high when the run begins, so the run begins in the Stop
  state.

### One transmission

One transmission is one escape-mode LPDT sequence and carries one DSI
packet, n bytes on the wire (n from 4 to 32; the packet's format is below).
Starting from LP-11, data lane 0 goes through exactly these states, in this
order, with nothing else between:

1. Escape mode entry: LP-10, LP-00, LP-01, LP-00.
2. The entry command for Low-Power Data Transmission: the 8 bits 1, 1, 1,
   0, 0, 0, 0, 1, in that order of sending.
3. The packet's n bytes in order, each least significant bit first.
4. Exit: LP-10 (a Mark-1), then LP-11 (the Stop state). The transmission
   ends when the lane enters LP-11.

Every bit of parts 2 and 3 is sent in spaced-one-hot code, as two states,
a mark and then a space:

- a 1 is LP-10 (Mark-1) and then LP-00;
- a 0 is LP-01 (Mark-0) and then LP-00.

So from LP-10 at the start of a transmission to the LP-10 at its end, the
lane passes through LP-00 between any two marks, and from each state to the
next exactly one of Dp and Dn changes. Dp and Dn must never change in the
same cycle (no step straight from LP-10 to LP-01, or from LP-00 to LP-11):
a real receiver would see a false state between them.

A transmission of n bytes is 21 + 16n states between its two LP-11s, which
is 22 + 16n changes of the lane's state, the return to LP-11 included.

### Timing

All times are counted from the simulator's `pins` lines: a state that the
lane enters at `pins c` and leaves at `pins d` lasts d - c cycles.

- Every state of a transmission, from its first LP-10 to its last LP-10
  included, lasts at least 3 cycles (60 ns) and at most 50 cycles (1 us).
  The minimum is D-PHY's TLPX, 50 ns for any low-power state, rounded up to
  whole cycles. The maximum is this sheet's own, so that a transmission is
  not drawn out and the test knows how long to run. Within those limits the
  states need not all be the same length.
- Initialisation. After the run begins, data lane 0 stays in LP-11 for at
  least 100 us (D-PHY's T_INIT) before the first transmission: its first
  change (LP-11 to LP-10) comes no earlier than cycle 5000 and no later than
  cycle 10000 of the run.
- Between two transmissions the lane stays in LP-11 for at least 3 cycles
  (60 ns: like every low-power state, the Stop state lasts at least TLPX)
  and at most 20 us (1000 cycles), from the cycle it enters LP-11 to the
  next transmission's first change. The maximum is this sheet's, so that
  the test knows how long to run.
- After the last transmission the lane stays in LP-11. Nothing on P0 to P3
  may move: a stray change, between transmissions or after the last one, is
  a fault.

### An example

The DSI short packet "exit sleep mode" (DCS command 0x11 with no parameter)
is the four bytes 0x05, 0x11, 0x00, 0x36. Sent as one transmission, data
lane 0 goes, from LP-11:

| Part | Bits in the order sent | Lane states (xy of LP-xy) |
|---|---|---|
| Escape mode entry | | 10 00 01 00 |
| LPDT entry command | 1 1 1 0 0 0 0 1 | 10 00 10 00 10 00 01 00 01 00 01 00 01 00 10 00 |
| Byte 0x05 | 1 0 1 0 0 0 0 0 | 10 00 01 00 10 00 01 00 01 00 01 00 01 00 01 00 |
| Byte 0x11 | 1 0 0 0 1 0 0 0 | 10 00 01 00 01 00 01 00 10 00 01 00 01 00 01 00 |
| Byte 0x00 | 0 0 0 0 0 0 0 0 | 01 00 01 00 01 00 01 00 01 00 01 00 01 00 01 00 |
| Byte 0x36 | 0 1 1 0 1 1 0 0 | 01 00 10 00 10 00 01 00 10 00 10 00 01 00 01 00 |
| Exit | | 10 11 |

That is 85 states between the two LP-11s, and 86 changes. At 3 cycles a
state it lasts 255 cycles; at 50 cycles a state, 4250.

### The packets

Each transmission carries one DSI packet, which the firmware forms from the
content the host gives it (below). There are two kinds.

- A short packet is 4 bytes: the data identifier (DI), two parameter
  bytes, and the ECC.
- A long packet is 6 + WC bytes: the DI, the word count WC (the number of
  payload bytes) as two bytes, low byte first, the ECC, the WC payload
  bytes, and the 16-bit checksum, low byte first. DSI allows WC up to
  65535; this sheet and its test keep WC from 0 to 26, so that a packet is
  at most 32 bytes and a run stays short. Nothing in the coding changes
  with the length.

The DI's bits 7..6 are the virtual channel and bits 5..0 the data type. The
firmware does not interpret either: the host says which kind each packet
is.

The ECC is computed over the 24 header bits D23..D0 that come before it:
D7..D0 is the DI, D15..D8 the second byte and D23..D16 the third (the two
parameters of a short packet, or the two bytes of WC). Its bits 5..0 are the
parity bits P5..P0, and its bits 7..6 are 0. Each parity bit is the
exclusive or of these header bits:

| Parity bit | Exclusive or of |
|---|---|
| P0 | D0 D1 D2 D4 D5 D7 D10 D11 D13 D16 D20 D21 D22 D23 |
| P1 | D0 D1 D3 D4 D6 D8 D10 D12 D14 D17 D20 D21 D22 D23 |
| P2 | D0 D2 D3 D5 D6 D9 D11 D12 D15 D18 D20 D21 D22 |
| P3 | D1 D2 D3 D7 D8 D9 D13 D14 D15 D19 D20 D21 D23 |
| P4 | D4 D5 D6 D7 D8 D9 D16 D17 D18 D19 D20 D22 D23 |
| P5 | D10 D11 D12 D13 D14 D15 D16 D17 D18 D19 D21 D22 D23 |

The checksum of a long packet is a CRC-16 over the payload bytes only, with
the polynomial x^16 + x^12 + x^5 + 1, the register starting at 0xFFFF, the
payload's bits taken in the order they are sent (each byte least
significant bit first) and the register shifting the same way (the
reflected form, 0x8408), with no inversion at the end. Over the nine bytes
of the text `123456789` it is 0x6F91. Over an empty payload (WC = 0) it is
0xFFFF.

Two examples, as bytes on the wire:

- "exit sleep mode", a short packet with DI 0x05 (virtual channel 0, data
  type 0x05, DCS short write without parameter) and parameters 0x11, 0x00:
  0x05, 0x11, 0x00, 0x36.
- "column address set", a long packet with DI 0x39 (DCS long write) and the
  five payload bytes 0x2A, 0x00, 0x00, 0x00, 0xEF: 0x39, 0x05, 0x00, 0x36,
  0x2A, 0x00, 0x00, 0x00, 0xEF, 0x48, 0x03 (WC is 5; the checksum is
  0x0348).

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet. They carry each packet's content only, packet
after packet, with nothing between packets:

- The first word of a packet: bits 7..0 are the DI; bit 8 is 1 for a long
  packet and 0 for a short one; bits 15..9 are 0.
- The second word: for a short packet, the first parameter in bits 7..0
  and the second in bits 15..8; for a long packet, WC (0 to 26).
- For a long packet, WC more words, one per payload byte in order, the byte
  in bits 7..0 and bits 15..8 0. A long packet with WC = 0 has no more
  words.

So the two example packets above, in that order, arrive as the nine words
0x0005, 0x0011, 0x0139, 0x0005, 0x002A, 0x0000, 0x0000, 0x0000, 0x00EF.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The ECC, the checksum, the escape mode entry, the entry command, every mark
and space, the exit, the Stop state and every wait are the firmware's:
nothing in a word says what the lane does.

A run is 1 to 6 packets of any data types, virtual channels and contents,
one transmission each. The test writes the
run's words to a file, one per line, and runs
`./pe_sim run mipi_dsi.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 11000, plus, for each
packet of n bytes on the wire, 1000 + 50 x (21 + 16n). In the simulator, the TX
FIFO is refilled as soon as it has room, so you do not need to worry about
the host being slow. When the words have run out, the chip must leave data
lane 0 in LP-11.

## What to hand in (all in this directory)

1. `mipi_dsi.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. The
   `-mode` flags must make P0 to P3 push-pull. Not `-tx` or `-cycles`: the
   test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes data lane 0 the way the receiver
above would, checks every byte of every packet, the ECCs and checksums
included, and measures every state of both lanes, on packets you have not
seen.
