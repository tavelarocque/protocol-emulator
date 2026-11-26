# Task: CAN FD (CAN with flexible data rate) transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of CAN, CAN FD and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for thread 0 that makes the chip a CAN FD node that transmits the
frames the host gives it, as ISO 11898-1:2015 defines CAN FD (the version
called "ISO CAN FD", with the stuff count). The chip's core clock is 50 MHz:
one cycle is 20 ns, and the thread may run every cycle. The chip sends
frames; the one thing it reads back from the bus is each frame's
acknowledgement.

The receiver is a logic analyser's CAN FD decoder (DSView's `can-fd`) reading
the bus line, together with a test that checks the CRC and the timing
below. Everything you need to know is here.

### The bus and the pin

| Pin | Signal | Mode |
|---|---|---|
| P0 | the CAN bus line, at logic level | open-drain (`-mode 0=od`), required |
| P1 to P7 | not connected | anything; the test ignores them |

The bus is a wired-AND line with a pull-up, as CAN is when nodes on one
board share a line without transceivers (or at the logic side of a
transceiver). Released, the line is high: that is the recessive level, 1.
Pulled low by any node it is low: the dominant level, 0. The chip writing 0
to P0 pulls the line low; writing 1 releases it. "The chip sends a 1" means
it releases the line. A second node, the receiver, is on the same line; it
never transmits a frame, it only acknowledges (below).

No node other than the chip ever transmits, so the chip never loses
arbitration, and nothing on the bus goes wrong except, sometimes, a missing
acknowledgement. The chip does not need to check the line during its own
bits, except in the ACK slot.

### Bit timing

| | Bit rate | One bit | Sample point |
|---|---|---|---|
| Nominal (arbitration) phase | 500 kbit/s | 100 cycles (2 us) | 80 cycles after the bit starts (80 %) |
| Data phase | 2 Mbit/s | 25 cycles (500 ns) | 20 cycles after the bit starts (80 %) |

A frame is sent at the nominal rate, except when its BRS bit is 1: then the
rate switches to the data rate at the sample point of the BRS bit, and back
to the nominal rate at the sample point of the CRC delimiter. So, when BRS
is 1:

- every bit from SOF to the bit before BRS lasts 100 cycles;
- the BRS bit lasts 80 + 5 = 85 cycles (80 cycles at the nominal rate up to
  its sample point, then the 5 cycles a data-phase bit has after its sample
  point);
- every bit from ESI to the last bit of the CRC field lasts 25 cycles,
  stuff bits and fixed stuff bits included;
- the CRC delimiter lasts 20 + 20 = 40 cycles (20 cycles at the data rate up
  to its sample point, then the 20 cycles a nominal bit has after its
  sample point);
- every bit after the CRC delimiter lasts 100 cycles.

When BRS is 0, every bit of the frame lasts 100 cycles.

### The frame

Only CAN FD data frames are sent (FDF = 1). Every field is sent most
significant bit first. A frame in base format (11-bit identifier) is, before
stuffing:

| Field | Bits | Value |
|---|---|---|
| SOF | 1 | 0 |
| Identifier | 11 | ID bits 10..0 |
| RRS | 1 | 0 |
| IDE | 1 | 0 |
| FDF | 1 | 1 |
| res | 1 | 0 |
| BRS | 1 | from the host |
| ESI | 1 | 0 (the chip is error active) |
| DLC | 4 | from the host |
| Data | 8 x length | the data bytes, in order |

A frame in extended format (29-bit identifier) is:

| Field | Bits | Value |
|---|---|---|
| SOF | 1 | 0 |
| Base identifier | 11 | ID bits 28..18 |
| SRR | 1 | 1 |
| IDE | 1 | 1 |
| Identifier extension | 18 | ID bits 17..0 |
| RRS | 1 | 0 |
| FDF | 1 | 1 |
| res | 1 | 0 |
| BRS | 1 | from the host |
| ESI | 1 | 0 |
| DLC | 4 | from the host |
| Data | 8 x length | the data bytes, in order |

The DLC gives the number of data bytes:

| DLC | 0 to 8 | 9 | 10 |
|---|---|---|---|
| Bytes | the DLC | 12 | 16 |

CAN FD also has DLC 11 to 15 (20 to 64 bytes), which use a 21-bit CRC.
This test never sends them: every frame here has 0 to 16 data bytes, DLC 0
to 10, and so a 17-bit CRC.

**Dynamic stuffing.** From SOF to the last bit of the data field (the last
bit of the DLC when there are no data bytes), after five consecutive bits of
the same level the chip sends one stuff bit of the opposite level. Stuff
bits count in the runs: a stuff bit is the first bit of the next run, so
after 00000 1 (stuff) the run of 1s already has length one. No dynamic stuff
bit is ever sent after the last bit of the data field, even when that bit
ends a run of five: what follows it is the fixed stuff bit below. Count the
dynamic stuff bits of the frame; that number is used in the CRC field.

**The CRC field** follows the data field directly. It is, in order:

1. A fixed stuff bit: the opposite of the bit before it.
2. The stuff count: the number of dynamic stuff bits modulo 8, in Gray code,
   3 bits, most significant first:

   | Stuff bits modulo 8 | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
   |---|---|---|---|---|---|---|---|---|
   | Gray code | 000 | 001 | 011 | 010 | 110 | 111 | 101 | 100 |

3. A parity bit: even parity over the 3 Gray-code bits (1 if they hold an
   odd number of 1s, so that the four bits hold an even number).
4. The CRC-17, 17 bits, most significant bit first, with a fixed stuff
   bit before its 1st, 5th, 9th, 13th and 17th bit. Each fixed stuff bit is
   the opposite of the bit just before it.

So the CRC field is 1 + 4 + 17 + 5 = 27 bits. There is no dynamic stuffing
in it.

**The CRC** is computed over every bit sent from SOF up to and including the
parity bit, dynamic stuff bits included, fixed stuff bits not included, in
the order they are sent. Its polynomial is
x^17 + x^16 + x^14 + x^13 + x^11 + x^6 + x^4 + x^3 + x + 1
(0x3685B, or 0x1685B without the x^17 term).

As a shift register of 17 bits: it starts with its top bit (bit 16) 1 and
all others 0, that is 0x10000. For each bit b in turn, let t be the
register's top bit; shift the register left by one, dropping the old top
bit; if b differs from t, XOR in 0x1685B. After the parity bit the register
holds the CRC, and its top bit (bit 16) is the one sent first. (With a zero
start instead, this CRC of the bytes `123456789`, each most significant bit
first, is 0x04F03; the ISO start above is the one to use.)

**After the CRC field**, all at the nominal rate:

| Field | Bits | What the chip does |
|---|---|---|
| CRC delimiter | 1 | sends 1 (40 cycles when BRS is 1, as above) |
| ACK slot | 1 | sends 1, and looks at the line: the receiver acknowledges by pulling it low for this bit |
| ACK delimiter | 1 | sends 1 |
| EOF | 7 | sends 1 |

**A missing acknowledgement.** If the line is still high at the sample
point of the ACK slot, nobody acknowledged the frame: an ACK error. The chip
then sends an active error flag, 6 dominant bits (600 cycles), starting at
the end of the ACK slot (where the ACK delimiter would have been), followed
by the error delimiter, 8 recessive bits (800 cycles). Automatic
retransmission is off (the single-shot mode CAN controllers offer): the
frame is not sent again, and the chip goes on to the next frame.

The end of a frame is the end of its last EOF bit, or, after an ACK error,
the end of its error delimiter. For an acknowledged frame that is 900
cycles after its ACK slot starts; after an ACK error, 1500 cycles.

### When the frames go

The receiver is scripted in advance and cannot react to the chip, so the
sheet fixes when every frame is sent:

- The line is released from the start of the run until the first frame. The
  first frame's SOF begins at cycle 2000.
- After each frame come the 3 recessive bits of the intermission (300
  cycles); the next frame's SOF begins exactly then, 300 cycles after the end
  of the frame before.
- After the last frame the line stays released to the end of the run.

**Timing limits.** Every change of the chip's P0 output must be within
+-1 cycle (+-20 ns) of its ideal place, counted from cycle 0 of the run:
where the bits above, laid end to end from the first SOF at cycle 2000, put
it. An error must not add up. There must be no other change of P0 at any
time: the chip never pulls the line low except for the dominant bits of its
frames and its error flags. In `pe_sim`'s output a change of P0 is a `pins`
line whose bit 0 differs from the line before it.

**The receiver.** For each frame it acknowledges, it pulls the line low
from the ideal start of that frame's ACK slot to the ideal start of the
ACK delimiter (100 cycles), placed by the same rules; the chip, releasing
the line in the ACK slot, sees it low there. For a frame it does not
acknowledge it does nothing. The test chooses which frames are acknowledged;
the firmware must find out by looking at P0 during each ACK slot. Nothing
in the TX words says which.

### An example

A base-format frame with identifier 0x020, BRS 1, DLC 1 and the one data
byte 0xF0, sent as the first frame of a run and acknowledged. It has three
dynamic stuff bits (stuff count 3, Gray code 010, parity 1), its five last
data-field bits are equal (the stuff bit at 28 and four zeros) so the fixed
stuff bit follows with no dynamic stuff bit, and its CRC-17 is 0x05DE7:

| Bit | Field | Level | Starts at cycle | Lasts (cycles) |
|---|---|---|---|---|
| 0 | SOF | 0 | 2000 | 100 |
| 1 | ID bit 10 | 0 | 2100 | 100 |
| 2 | ID bit 9 | 0 | 2200 | 100 |
| 3 | ID bit 8 | 0 | 2300 | 100 |
| 4 | ID bit 7 | 0 | 2400 | 100 |
| 5 | stuff bit | 1 | 2500 | 100 |
| 6 | ID bit 6 | 0 | 2600 | 100 |
| 7 | ID bit 5 | 1 | 2700 | 100 |
| 8 | ID bit 4 | 0 | 2800 | 100 |
| 9 | ID bit 3 | 0 | 2900 | 100 |
| 10 | ID bit 2 | 0 | 3000 | 100 |
| 11 | ID bit 1 | 0 | 3100 | 100 |
| 12 | ID bit 0 | 0 | 3200 | 100 |
| 13 | stuff bit | 1 | 3300 | 100 |
| 14 | RRS | 0 | 3400 | 100 |
| 15 | IDE | 0 | 3500 | 100 |
| 16 | FDF | 1 | 3600 | 100 |
| 17 | res | 0 | 3700 | 100 |
| 18 | BRS | 1 | 3800 | 85 |
| 19 | ESI | 0 | 3885 | 25 |
| 20 | DLC bit 3 | 0 | 3910 | 25 |
| 21 | DLC bit 2 | 0 | 3935 | 25 |
| 22 | DLC bit 1 | 0 | 3960 | 25 |
| 23 | DLC bit 0 | 1 | 3985 | 25 |
| 24 | data bit 7 | 1 | 4010 | 25 |
| 25 | data bit 6 | 1 | 4035 | 25 |
| 26 | data bit 5 | 1 | 4060 | 25 |
| 27 | data bit 4 | 1 | 4085 | 25 |
| 28 | stuff bit | 0 | 4110 | 25 |
| 29 | data bit 3 | 0 | 4135 | 25 |
| 30 | data bit 2 | 0 | 4160 | 25 |
| 31 | data bit 1 | 0 | 4185 | 25 |
| 32 | data bit 0 | 0 | 4210 | 25 |
| 33 | fixed stuff bit | 1 | 4235 | 25 |
| 34 | stuff count bit 2 | 0 | 4260 | 25 |
| 35 | stuff count bit 1 | 1 | 4285 | 25 |
| 36 | stuff count bit 0 | 0 | 4310 | 25 |
| 37 | parity | 1 | 4335 | 25 |
| 38 | fixed stuff bit | 0 | 4360 | 25 |
| 39 | CRC bit 16 | 0 | 4385 | 25 |
| 40 | CRC bit 15 | 0 | 4410 | 25 |
| 41 | CRC bit 14 | 1 | 4435 | 25 |
| 42 | CRC bit 13 | 0 | 4460 | 25 |
| 43 | fixed stuff bit | 1 | 4485 | 25 |
| 44 | CRC bit 12 | 1 | 4510 | 25 |
| 45 | CRC bit 11 | 1 | 4535 | 25 |
| 46 | CRC bit 10 | 1 | 4560 | 25 |
| 47 | CRC bit 9 | 0 | 4585 | 25 |
| 48 | fixed stuff bit | 1 | 4610 | 25 |
| 49 | CRC bit 8 | 1 | 4635 | 25 |
| 50 | CRC bit 7 | 1 | 4660 | 25 |
| 51 | CRC bit 6 | 1 | 4685 | 25 |
| 52 | CRC bit 5 | 1 | 4710 | 25 |
| 53 | fixed stuff bit | 0 | 4735 | 25 |
| 54 | CRC bit 4 | 0 | 4760 | 25 |
| 55 | CRC bit 3 | 0 | 4785 | 25 |
| 56 | CRC bit 2 | 1 | 4810 | 25 |
| 57 | CRC bit 1 | 1 | 4835 | 25 |
| 58 | fixed stuff bit | 0 | 4860 | 25 |
| 59 | CRC bit 0 | 1 | 4885 | 25 |
| 60 | CRC delimiter | 1 | 4910 | 40 |
| 61 | ACK slot | 1 | 4950 | 100 |
| 62 | ACK delimiter | 1 | 5050 | 100 |
| 63 | EOF | 1 | 5150 | 700 |

The receiver pulls the line low from cycle 4950 to 5050. The frame ends at
cycle 5850, and the next frame's SOF, if there is one, begins at 6150. Had
the receiver not acknowledged, the chip would pull the line low from 5050 to
5650 (the error flag), release it, and the frame would end at 6450, with the
next SOF at 6750.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet. For each frame, in order:

1. A header word: bit 15 is IDE (1 for an extended, 29-bit identifier, 0
   for a base, 11-bit one), bit 14 is BRS, bits 3..0 are the DLC, and all
   other bits are 0.
2. The identifier. For a base-format frame, one word: the identifier in
   bits 10..0, bits 15..11 zero. For an extended-format frame, two words:
   identifier bits 28..16 in bits 12..0 (bits 15..13 zero), then identifier
   bits 15..0.
3. The data bytes, two to a word, the first of the two in bits 15..8 and
   the second in bits 7..0. When the number of bytes is odd, the last word
   holds the last byte in bits 15..8 and 0 in bits 7..0. A frame with DLC 0
   has no data words.

The words of one frame follow those of the frame before with nothing
between them.

For each frame the firmware pushes one word to the RX FIFO: 0x0001 if the
frame was acknowledged, 0x0000 if it ended in an ACK error. One word per
frame, in the order of the frames, and no other words. Each must be pushed
no earlier than the start of the frame's ACK slot and no later than the
frame's end.

So the base-format frame of the example (identifier 0x020, BRS 1, DLC 1,
byte 0xF0) followed by an extended-format frame with identifier 0x1ABCDE12,
BRS 0, DLC 3 and the bytes 0x11, 0x22, 0x33 arrive as the eight words
0x4001, 0x0020, 0xF000, 0x8003, 0x1ABC, 0xDE12, 0x1122, 0x3300. If the
receiver acknowledges the first and not the second, the firmware pushes
0x0001 and then 0x0000.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

SOF, RRS, SRR, IDE, FDF, res, ESI, every stuff bit, the stuff count, its
parity, the CRC, the fixed stuff bits, the delimiters, the ACK slot, the
error flag, the bit rate switch and every bit time are the firmware's:
nothing in a word says what the line does or when.

### How the test runs it

A run is 1 to 6 frames. Each may be base or extended format, with or
without the bit rate switch, with any DLC from 0 to 10, any identifier
(except that the test never sends one whose base identifier, ID bits 10..0
of a base-format frame or ID bits 28..18 of an extended one, has its bits
10..4 all 1, because the logic analyser's decoder reports such an
identifier as an error: classic CAN forbids seven recessive bits there), and
any data. The receiver acknowledges most frames and leaves
some unacknowledged, the last one included.

The test writes the run's words to one file, one per line, and the
receiver's levels to another, and runs
`./pe_sim run can_fd.s -tx FILE -stimulus FILE2 -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is the ideal
end of the last frame plus 2000 cycles. In the simulator, the TX FIFO is
refilled as soon as it has room, so you do not need to worry about the host
being slow. The stimulus file has lines `CYCLE HEX`, bit k of HEX being the
receiver's level on Pk (1 where it does not pull low; P1 to P7 always read
1); for a run that is only the frame of the example, acknowledged, it is

    0 ff
    4950 fe
    5050 ff

## What to hand in (all in this directory)

1. `can_fd.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs (`-mode 0=od` among
   them), and no other flag. Not `-tx`, `-stimulus`, `-inputs` or
   `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the bus line the way the receiver
above would, recomputes every CRC, and measures where every change of P0
falls, on frames you have not seen.
