# Task: ST7735 display firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the ST7735 display
  controller and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the host of a Sitronix ST7735 TFT display
controller on the controller's 4-line serial interface, in the write
direction only: the chip sends commands and data bytes to the display and
never reads anything back. It runs on thread 0, with the chip's core clock
at 40 MHz (one cycle = 25 ns; the thread may run every cycle).

The four lines, all push-pull:

| Pin | Line | Meaning |
|---|---|---|
| P0 | SDA | serial data, host to display |
| P1 | SCL | serial clock |
| P2 | D/CX | low: the byte being sent is a command; high: it is data |
| P3 | CSX | chip select, active low |

P4 to P7 are yours to use or to leave alone; the test ignores them.

The display reads the lines as follows (ST7735 data sheet, 4-line serial
interface, write):

- Everything is sent as transfers. A transfer is one command byte followed
  by zero or more data bytes (the command's parameters, or pixel data).
- CSX is high when nothing is being sent. It goes low before the command
  byte, stays low through the last data byte of that transfer, and then goes
  high again: exactly one low pulse per transfer, holding a whole number of
  bytes. (The data sheet also lets a host hold CSX low across transfers or
  raise it between bytes. This test does not.) While CSX is high the
  display ignores the other three lines.
- A byte is 8 bits, most significant bit first. The display takes one bit
  from SDA at each rising edge of SCL.
- SCL idles low (SPI mode 0): it is low whenever CSX changes, in either
  direction, and inside a transfer it only pulses high once per bit.
- D/CX is read together with the eighth bit of each byte. It must be low
  for the command byte and high for every data byte.
- Bytes of one transfer may follow each other with or without a pause.

Timing limits. All are minimums; there is no maximum.

| Data sheet symbol | What | Min |
|---|---|---|
| TCSS | CSX falling edge to the first rising edge of SCL | 15 ns |
| TCSH | SCL low and unchanged before any edge of CSX, falling or rising | 15 ns |
| TCHW | CSX high between two transfers | 40 ns |
| TSCYCW | SCL period, rising edge to rising edge and falling edge to falling edge | 66 ns |
| TSHW | SCL high | 30 ns |
| TSLW | SCL low between two pulses of the same transfer | 30 ns |
| TSDS | SDA at its level before each rising edge of SCL | 10 ns |
| TSDH | SDA held after each rising edge of SCL | 10 ns |
| TDCS | D/CX at its level before the eighth rising edge of SCL in each byte | 10 ns |
| TDCH | D/CX held after the falling edge of SCL that ends that eighth pulse | 10 ns |

Two of these ask a little more than the data sheet: it counts TCSH and TDCH
from the last rising edge of SCL, and this test counts them from the
falling edge after it, as the table says.

Times are measured between the pin changes `pe_sim` prints. A change at
cycle c and a change at cycle d are (d - c) x 25 ns apart, and two changes
printed in the same cycle are 0 ns apart.

All of this holds from the first cycle of the run. The first transfer is
judged like any other, so before the first falling edge of CSX, CSX must
have been high and SCL must be low and have been low for 15 ns.

The chip must not dawdle. The test runs the simulator for 200 cycles per
byte asked for (command bytes and data bytes alike) plus 2000 cycles. By
then every transfer must have been sent and CSX must be high again. After
the last transfer nothing more may be sent.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet:

- One word per byte on the wire, command bytes and data bytes alike, in
  the order they are to be sent, transfer after transfer, with nothing
  between transfers.
- Bits 7..0 of the word are the byte.
- Bit 8 is 1 for a command byte and 0 for a data byte.
- Bit 9 is 1 on the last byte of a transfer (chip select must rise after
  it) and 0 otherwise.
- All other bits (15..10) are 0.

So command 0x2A with data 0x00 0x7F, followed by command 0x29 with no
data, arrives as the four words 0x012A, 0x0000, 0x027F, 0x0329. The first
word of a transfer is its command byte, and no other word of it has bit 8
set. A command with no data is one word, with bits 8 and 9 both set.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The clock, the chip select, the D/CX line and the order of the bits are
the firmware's to make from those words: no word holds a clock edge or a
count.

A run is one or more transfers, in the order they are to be sent. Each is
one command byte and 0 to 600 data bytes, and any byte value may appear in
either place. The test writes the run's words to a file, one per line, and
runs `./pe_sim run st7735.s -tx FILE -cycles N` followed by the arguments
in `run_args.txt`, once for each run. The chip is fresh from reset at cycle
0 with an empty TX FIFO, and the words are pushed from then on. Those
words, and nothing else, must make the chip send every transfer in order
and finish with CSX high. In the simulator, the TX FIFO is refilled as soon
as it has room, so you do not need to worry about the host being slow.
Nothing needs to be read back, and the test ignores the RX FIFO.

## What to hand in (all in this directory)

1. `st7735.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way a display
would, on transfers you have not seen.
