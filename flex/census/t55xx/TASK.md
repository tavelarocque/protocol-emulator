# Task: T55xx RFID reader (write commands) firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the T55xx RFID
  protocol and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for the reader side of a 125 kHz RFID link to a T5577 (T55xx)
tag: it sends the tag write and reset commands by switching the reader's
field on and off. Pin P0 (push-pull) drives the reader's antenna driver.
Thread 0, core clock 10 MHz (one cycle = 100 ns; the thread may run every
cycle). The chip only transmits: nothing is received.

The receiver is a logic analyser's T55xx decoder (sigrok's `t55xx`, set to
a coil frequency of 125000 Hz, a minimum start gap of 8 and a minimum write
gap of 8 field clocks, its other settings at their defaults). Everything you
need to know about it is here.

Units. One field clock (FC) is one period of the 125 kHz carrier: 8 us =
80 cycles. Every limit below is given in cycles, with FC beside it.

The line:

- **Field on** is the carrier: P0 toggles, high and low in turn, every
  half period. Every half period (the time between two neighbouring changes
  of P0 while the field is on) must be 38 to 42 cycles; 40 is nominal.
- **A gap** is the field switched off: P0 low and not changing. A gap is
  measured from the change that begins it (P0 falls) to the change that ends
  it (P0 rises, and the carrier starts again). Any time between two
  neighbouring changes of P0 must be either a half period (38 to 42 cycles)
  or a gap (800 cycles or more, with P0 low); nothing in between, and no
  gap with P0 high.
- **A bit** is the field-on time between two gaps, measured from the rise
  that ends one gap to the fall that begins the next:
  - a 0 is 1440 to 2320 cycles (18 to 29 FC; nominal 24 FC),
  - a 1 is 4000 to 4880 cycles (50 to 61 FC; nominal 56 FC).

A command is sent as:

1. At least 8000 and at most 80000 cycles (100 to 1000 FC) of field on, so
   that the tag is powered. For the first command this is counted from P0's
   first change, which must come by cycle 400 of the run; for every later
   command, from the end of the previous command's last gap.
2. A start gap of 800 to 4000 cycles (10 to 50 FC).
3. The command's bits in order, each bit being its field-on time followed by
   a write gap of 800 to 2400 cycles (10 to 30 FC). So a command of n bits
   has the start gap and n write gaps, and its last bit ends with a write
   gap like every other.
4. At least 8000 cycles (100 FC) of field on after that last write gap.
   This is when the tag writes its memory, and it is how the receiver
   knows the command has ended (it ends a command once the field has been
   on for more than 64 FC since the last gap). For every command but the
   last, this stretch is also the next command's step 1, so it is 8000 to
   80000 cycles long.

After the last command's 8000 cycles the line may go on with the carrier or
stop changing at either level, until the run ends. If it stops, it must not
change again.

The commands and their bits, in the order they are sent:

| Command | Bits |
|---|---|
| Standard write | opcode (2 bits), lock bit (1), data (32), address (3): 38 bits |
| Protected write | opcode (2), password (32), lock bit (1), data (32), address (3): 70 bits |
| Reset | opcode 00 (2 bits) |

The opcode of a write is 10 (page 0) or 11 (page 1); its first bit, the 1,
goes first. The password, the data and the address go most significant bit
first.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet. Each command begins with a header word:

- bits 1..0: the opcode (bit 1 is the opcode's first bit),
- bit 2: the lock bit,
- bits 5..3: the address (bit 5 is its most significant bit),
- bit 6: 1 for a protected write, 0 otherwise,
- bit 7: 1 for a reset, 0 otherwise,
- bits 15..8: 0.

After the header come, for a protected write, two words of password (its
bits 31..16, then its bits 15..0), and then, for either write, two words of
data (bits 31..16, then bits 15..0). A reset is the header 0x0080 alone.
Commands follow one another with nothing between them.

An example. The three commands

- protected write, opcode 10, password 0x12345678, lock 1, data
  0x9ABCDEF0, address 5,
- reset,
- standard write, opcode 11, lock 0, data 0xFFFF0001, address 2,

arrive as the nine words 0x006E, 0x1234, 0x5678, 0x9ABC, 0xDEF0, 0x0080,
0x0013, 0xFFFF, 0x0001. The first is sent as 70 bits (1 0, then the 32
bits of 0x12345678, then 1, then the 32 bits of 0x9ABCDEF0, then 1 0 1),
the second as the two bits 0 0, the third as 38 bits (1 1, 0, the 32 bits
of 0xFFFF0001, 0 1 0).

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The carrier, every gap, every bit's length, and the field-on time before
and after each command are the firmware's: nothing in a word says where the
line changes.

A run is 1 to 8 commands of any of the three kinds, with any values. The
test writes the run's words to a file, one per line, and runs
`./pe_sim run t55xx.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 400, plus 84000 for
each command, plus 7280 for each bit of each command, plus 28000. In the
simulator, the TX FIFO is refilled as soon as it has room, so you do not
need to worry about the host being slow.

## What to hand in (all in this directory)

1. `t55xx.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures every half period, gap and bit, on
commands you have not seen.
