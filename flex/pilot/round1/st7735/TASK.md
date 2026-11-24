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
(4 deep) and can read 16-bit words back from the RX FIFO. You decide what
the words mean. In the simulator, the TX FIFO is refilled as soon as it has
room, so you do not need to worry about the host being slow. Nothing needs
to be read back, and the test ignores the RX FIFO.

## What to hand in (all in this directory)

1. `st7735.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs.
3. `host.py`: a function `encode(transfers) -> list[int]`.
   - `transfers` is a list of one or more transfers, in the order they are
     to be sent. Each transfer is a tuple `(command, data)`: `command` is an
     int from 0 to 255, the command byte, and `data` is a list of 0 to 600
     ints from 0 to 255, the data bytes that follow it. `data` may be empty.
     Any byte value may appear in either place.
   - It returns the TX words, each an int from 0 to 65535, in the order the
     host pushes them. Those words, and nothing else, must make the chip
     send every transfer in order and finish with CSX high.
   - `encode` is called once per run. The chip is fresh from reset at cycle
     0 with an empty TX FIFO, and the words are pushed from then on.
   - Plain Python 3, no imports beyond the standard library.
4. `notes.md`, as above, ending with: the program's length in instructions,
   the host word format, and anything about the chip that was confusing or
   that you think is wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way a display
would, on transfers you have not seen.
