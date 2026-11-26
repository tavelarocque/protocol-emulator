# Task: EM4305 RFID reader (transmit) firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of EM4305 RFID and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

The chip is the reader of a 125 kHz RFID system, talking to an EM4305 (or
EM4205) tag. Firmware on thread 0 drives the reader's coil on pin P0
(push-pull) and sends the tag Login and Write word commands, by switching
the field off for short gaps. The core clock is 10 MHz (one cycle =
100 ns; the thread may run every cycle). The chip only transmits: the
tag's replies are not part of this task, and nothing is received.

The receiver is a logic analyser's EM4305 decoder (sigrok's `em4305`, with
its default options: 125 kHz coil). Everything you need to know about it is
here.

### The carrier

- **Field on** means a 125 kHz square wave on P0: one carrier period is
  8 us = 80 cycles, P0 high for its first 40 cycles and low for the next
  40. Every period starts with a rise of P0.
- **Field off** means P0 held low, for a whole number of carrier periods.
- So the line is a row of carrier periods, each either a pulse (on) or
  80 cycles of low (off). The decoder sees only edges: a stretch with no
  edges is the field being off.

### A command

A command is a first field stop followed by its bits, at RF/32: one bit
lasts 32 carrier periods (256 us = 2560 cycles).

1. **First field stop**: the field off for exactly 55 carrier periods
   (4400 cycles).
2. **The bits**, back to back, starting with the first period after the
   field stop:
   - a **1** is the field on for all 32 periods of the bit;
   - a **0** is the field on for the first 16 periods of the bit and off
     for the last 16.
3. After the last bit (always a 0) the field comes back on: the period
   after it starts with a rise, and the field stays on until the next
   command.

These shapes are the ones the decoder reads. A real EM4305 accepts a range
of gap lengths; this sheet fixes one.

The bits of a command, in the order they are sent:

| Field | Login (50 bits) | Write word (57 bits) |
|---|---|---|
| leading 0 | 0 | 0 |
| command code | 0 0 1 1 | 0 1 0 1 |
| address | (none) | A0 A1 A2 A3 (address bit 0 first), then 0 0, then the parity of A0..A3 |
| data rows | four rows of 9 bits | four rows of 9 bits |
| column parity | 8 bits | 8 bits |
| stop bit | 0 | 0 |

The 32-bit value (the password of a Login, the data of a Write word) is
sent as four bytes, least significant byte first (bits 7..0 of the value,
then 15..8, then 23..16, then 31..24). Each byte is a row: its 8 bits most
significant bit first, then one parity bit that makes the number of 1 bits
in the row's 9 bits even. The column parity is the exclusive OR of the four
bytes, sent most significant bit first. The address parity bit also makes
the number of 1 bits among A0..A3 and itself even.

### Timing limits

- P0 is high at cycle 0 (the output register resets high). Its first
  change must be a fall, at cycle 200 or earlier, and the first rise must
  come 40 +-2 cycles after that fall: the low after the first fall counts
  as a low between pulses. From then on the field is on, and P0 must carry
  the carrier, until the first command.
- Inside a command, every edge must be within +-200 ns (2 cycles) of its
  ideal place, counted from the rise that ends the first field stop (the
  start of the leading 0 bit). This covers the last pulse before the field
  stop (its rise ideally 4480 cycles and its fall 4440 cycles before that
  rise), every pulse of the bits, and the rise that ends the stop bit
  (ideally 2560 x number of bits cycles after it). The limit is on the
  place, not on the spacing, so an error must not add up along a command.
- Outside commands, every high pulse of P0 must last 40 +-2 cycles, and
  every low between two pulses 40 +-2 cycles. No other gaps.
- Before each command's first field stop, the field must have been on for
  at least 320 and at most 1280 carrier periods (25600 to 102400 cycles,
  give or take 2), counted from the rise that ends the previous command's
  stop bit, or for the first command from P0's first rise. The tag needs
  that long to power up and to see the end of the previous command; the
  upper limit is so the test knows how long to run.
- After the last command the field must stay on for at least 320 whole
  pulses (counting the rise that ends the stop bit as the first). After
  that, when no more words come, P0 may stop at either level, or the
  carrier may carry on; every edge it still makes must be carrier, as
  above.

### An example

A Login with the password 0x12345678 is these 50 bits (spaces only for
reading):

    0  0011  01111000 0  01010110 0  00110100 1  00010010 0  00001000  0

The rows are the bytes 0x78, 0x56, 0x34, 0x12; their parity bits are 0, 0,
1, 0; the column parity is 0x78 ^ 0x56 ^ 0x34 ^ 0x12 = 0x08, sent as
00001000. With R the rise that ends its field stop, bit k lasts from
R + 2560k to R + 2560k + 2560. The leading 0 (bit 0) is pulses with rises
at R, R + 80, ..., R + 1200, then low until R + 2560. Bit 1, also a 0, is
the same from R + 2560. Bit 3, a 1, is 32 pulses with rises at R + 7680,
R + 7760, ..., R + 10160. The stop bit (bit 49) ends at R + 128000 with the
rise that begins the carrier after the command.

A Write word to address 4 with the data 0xDEADBEEF is these 57 bits:

    0  0101  0010 00 1  11101111 1  10111110 0  10101101 1  11011110 0  00100010  0

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX
FIFO (4 deep) and can read 16-bit words back from the RX FIFO. What the
words mean is fixed by this sheet. Every command is exactly three words:

1. The command: `0x0000` for a Login; `0x0100 | address` for a Write word,
   with the address (0 to 15) in bits 3..0. All other bits are 0.
2. Bits 15..0 of the 32-bit value.
3. Bits 31..16 of the 32-bit value.

So the two commands of the example, a Login with 0x12345678 and then a
Write word of 0xDEADBEEF to address 4, arrive as the six words 0x0000,
0x5678, 0x1234, 0x0104, 0xBEEF, 0xDEAD.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The carrier, the field stops, the command codes, the parity bits, the
stop bit and the field between commands are the firmware's: nothing in a
word says where the line changes.

A run is 1 to 6 commands; each is a Login or a Write word with any 32-bit
value and, for a Write word, any address from 0 to 15. (One thing about the
decoder: it gives up after 300 carrier periods without a gap, so it cannot
read nine 1 bits in a row. The test never sends a value that puts nine 1
bits in a row on the line. This needs nothing from your firmware.)

The test writes the run's words to a file, one per line, and runs
`./pe_sim run em4305.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is long enough for the
slowest timing allowed above, with room to spare: 200, plus for each
command 1280 + 55 periods and its bits, plus 400 periods, in cycles. In
the simulator, the TX FIFO is refilled as soon as it has room, so you do
not need to worry about the host being slow.

## What to hand in (all in this directory)

1. `em4305.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every edge falls, on commands you
have not seen.
