# Task: USB Power Delivery transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of USB Power Delivery and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that transmits USB Power Delivery packets, as the physical layer
of a PD controller sends them on the CC wire, on pin P0 (push-pull), on
thread 0, with the chip's core clock at 20 MHz (one cycle = 50 ns; the
thread may run every cycle). The chip only transmits: nothing is received.
On a real board P0 would drive the CC wire through a small analogue driver;
here P0's logic level is the signal, low and high. No other pin is used and
the test looks at no other pin.

The receiver is a logic analyser's USB PD decoder (sigrok's
`usb_power_delivery`, with CC1 on P0), plus a direct check of where every
transition falls. Everything you need to know is here.

### The line code: biphase mark code (BMC)

- One bit (one unit interval, UI) lasts 66 cycles = 3.3 us, so the bit rate
  is 303.03 kbit/s (the specification allows 270 to 330). Half a bit is
  33 cycles.
- Every bit begins with a transition: a change of P0's level, either way.
- A 1 has a second transition in the middle of the bit, 33 cycles after its
  start. A 0 has none.
- The level itself means nothing; only where the transitions are.
- Between packets the line is low. So every packet begins with a rise.

### A packet

A packet is these bits, sent without a break, in this order:

1. **Preamble**: 64 bits, alternating, starting with 0 and ending with 1:
   0, 1, 0, 1, ..., 0, 1.
2. **Start of packet**: four K-codes (5-bit symbols, below). Which four
   depends on the packet's kind, chosen by the host:
   - kind 0, SOP: Sync-1, Sync-1, Sync-1, Sync-2
   - kind 1, SOP': Sync-1, Sync-1, Sync-3, Sync-3
   - kind 2, SOP'': Sync-1, Sync-3, Sync-1, Sync-3
3. **Header**: 16 bits, as 4 symbols.
4. **Data objects**: 0 to 7 of them, 32 bits each, 8 symbols each.
5. **CRC**: 32 bits, as 8 symbols.
6. **EOP**: the EOP K-code.

Every 16-bit or 32-bit value is cut into 4-bit nibbles, least significant
nibble first, and each nibble is sent as its 5-bit 4b5b code. Every 5-bit
code is sent bit 0 first. The codes (written bit 4 first, as in the
specification, then as a number):

| Nibble | Code b4..b0 | Value | | Nibble | Code b4..b0 | Value |
|---|---|---|---|---|---|---|
| 0 | 11110 | 0x1E | | 8 | 10010 | 0x12 |
| 1 | 01001 | 0x09 | | 9 | 10011 | 0x13 |
| 2 | 10100 | 0x14 | | A | 10110 | 0x16 |
| 3 | 10101 | 0x15 | | B | 10111 | 0x17 |
| 4 | 01010 | 0x0A | | C | 11010 | 0x1A |
| 5 | 01011 | 0x0B | | D | 11011 | 0x1B |
| 6 | 01110 | 0x0E | | E | 11100 | 0x1C |
| 7 | 01111 | 0x0F | | F | 11101 | 0x1D |

| K-code | Code b4..b0 | Value |
|---|---|---|
| Sync-1 | 11000 | 0x18 |
| Sync-2 | 10001 | 0x11 |
| Sync-3 | 00110 | 0x06 |
| EOP | 01101 | 0x0D |

So nibble 0 goes on the line as the bits 0, 1, 1, 1, 1, and Sync-1 as
0, 0, 0, 1, 1.

**The CRC** is the CRC-32 of Ethernet, over the header's 16 bits and then
each data object's 32 bits, taken in the order they are sent (each value
least significant bit first): the standard CRC-32 polynomial 0x04C11DB7,
initial value 0xFFFFFFFF, input and output reflected (it works on the bits
in the order sent, least significant first), final XOR 0xFFFFFFFF. It is the value `zlib.crc32` gives for the header and the data
objects laid out as little-endian bytes. It is then sent like any 32-bit
value: 8 symbols, least significant nibble first. For the header 0x0041 with
no data objects the CRC is 0xA8BB6CBB; the example below has its own.

### The end of a packet, and between packets

- After the last bit of the EOP there is one more transition, at the place
  where the next bit would begin (one UI after the start of the EOP's last
  bit). If that transition leaves the line high, the line falls again half
  a bit (33 cycles) later. Either way the line is then low, and stays low.
  This transition is what closes the EOP's last bit for the receiver.
- The silence between packets, from a packet's last transition to the next
  packet's first (its preamble's rise), must be at least 25 us (500 cycles,
  the specification's interframe gap) and at most 2 ms (40000 cycles, so
  that the test knows how long to run).
- At the start of a run P0 is high (the pins' reset level). The firmware
  must have it low by cycle 100 (5 us) and keep it low until the first
  packet. The first packet's first transition must come at least 500 cycles
  after P0 went low, and no later than cycle 40000.
- After the last packet nothing may move the line. Any stray transition is
  the start of a packet to the receiver.

### Timing

Every transition of a packet must be within +-100 ns (2 cycles) of its
ideal place, counted from that packet's first transition: 66k cycles after
it for the transition at the start of bit k (the first preamble bit is bit
0), 66k + 33 for the one in the middle of bit k when bit k is a 1, and for
the closing transitions 66n and 66n + 33, where n is the packet's number of
bits. The limit is on the place, not on the spacing, so an error must not
add up along a packet.

### An example

A Source_Capabilities message from a source offering 5 V at 3 A: kind 0
(SOP), header 0x11A1, one data object 0x0001912C. Its CRC is 0x312C2EDA. The
symbols after the preamble are:

    Sync-1 Sync-1 Sync-1 Sync-2              start of packet
    1 A 1 1                                  header 0x11A1
    C 2 1 9 1 0 0 0                          data object 0x0001912C
    A D E 2 C 2 1 3                          CRC 0x312C2EDA
    EOP

That is 64 + 20 + 20 + 40 + 40 + 5 = 189 bits. The packet's transitions are
at cycles 0, 66, 99, 132, 198, 231, ... after its first (preamble bits 0, 1,
2, 3 are 0, 1, 0, 1), its first symbol begins at cycle 64 x 66 = 4224, its
EOP begins at 184 x 66 = 12144, and the closing transition is at
189 x 66 = 12474. That one leaves the line low, so there is no fall after
it, and the next packet may begin at cycle 12974 at the earliest.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet. For each packet, in order, packet after
packet, with nothing between packets:

1. One word: bits 1..0 are the packet's kind (0 SOP, 1 SOP', 2 SOP''),
   bits 4..2 are its number of data objects (0 to 7), and all other bits
   (15..5) are 0.
2. One word: the 16-bit header. Its bits 14..12 always equal the number of
   data objects in the first word. The firmware need not look inside it.
3. For each data object, in order: two words, its low 16 bits and then its
   high 16 bits.

The CRC is not sent: the firmware computes it. So the example above
arrives as the four words 0x0004, 0x11A1, 0x912C, 0x0001, and a GoodCRC
message with header 0x0041 on SOP' as the two words 0x0001, 0x0041.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The preamble, the K-codes, the 4b5b coding, the CRC, every transition,
the closing transition and the gap between packets are the firmware's:
nothing in a word says where the line changes.

A run is 1 to 5 packets, each with 0 to 7 data objects of any value. The
test writes the run's words to a file, one per line, and runs
`./pe_sim run usb_power_delivery.s -tx FILE -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is 40000,
plus 40000 for each packet, plus the packets' own lengths in cycles. In the
simulator, the TX FIFO is refilled as soon as it has room, so you do not
need to worry about the host being slow. When the words have run out, the
chip must leave the line low and still.

## What to hand in (all in this directory)

1. `usb_power_delivery.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every transition falls, on packets
you have not seen.
