# Task: SDA 2506 EEPROM host firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the SDA 2506 serial
  EEPROM and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the host of a Siemens SDA 2506 serial EEPROM
(1 Kbit: 128 bytes, addresses 0 to 127). The chip writes bytes, erases
bytes and reads bytes back, on thread 0, with the chip's core clock at
10 MHz (one cycle = 100 ns; the thread may run every cycle). It both sends
and receives: in a read, the EEPROM drives the data line and the chip must
hand the byte it reads to the host.

### Pins

| Pin | Line | Mode | Meaning |
|---|---|---|---|
| P0 | CLK | push-pull | shift clock, driven by the chip |
| P1 | DATA | open-drain | data, both directions. A pull-up holds it high when nobody pulls it low; the chip and the EEPROM each either pull it low or let go. The line is low if either pulls it low |
| P2 | CE | push-pull | chip enable, driven by the chip. High: the EEPROM is deselected and takes command bits. Low: it acts on the command |

P3 to P7 are yours to use or to leave alone; the test ignores them.

When the run starts all three outputs are high (CLK high, DATA released, CE
high). CLK must be brought low by cycle 1000 and stay low until the first
operation. CE stays high and DATA released until then.

### The EEPROM's interface (SDA 2506 data sheet)

- **Command bits** are shifted in while CE is high, one bit per CLK pulse.
  The EEPROM takes DATA's level during each pulse: DATA must be at the
  bit's level from at least 2.5 us before CLK rises until at least 2.5 us
  after CLK falls.
- **Bit order.** Every field is sent least significant bit first.
  - Read: 8 bits. The address A0 to A6, then the control bit CB = 0.
  - Erase: 8 bits. The address A0 to A6, then CB = 1.
  - Write: 16 bits. The data D0 to D7, then the address A0 to A6, then
    CB = 1.
- **CE falling** ends the command and latches it. For a write or an erase,
  DATA's level at that moment says which: low for a write, high for an
  erase. (A write only programs zeros: an erase sets a byte to 0xFF, and a
  write then clears the bits that are 0 in its data. The test does not
  care; the host asks for each operation separately.)
- **Write and erase:** after CE falls, one more CLK pulse, the start
  pulse, with DATA still at the level it had when CE fell, until at least
  2.5 us after the start pulse falls. Programming starts as the start pulse
  falls and lasts up to 20 ms; CE must stay low for all of it and then
  rise, which ends the operation.
- **Read:** after CE falls, 8 CLK pulses. On the falling edge of the first
  one the EEPROM puts D0 on DATA, on the falling edge of the second D1, and
  so on: bit k of the byte (least significant first) is put out as pulse
  k + 1 falls. The EEPROM changes DATA 1 us after CLK falls. The chip must
  let DATA go (output 1) for the whole read, so that the EEPROM can drive
  it. CE rises after the eighth pulse, and the EEPROM lets go of DATA 1 us
  after CE rises.
- Data sheet limits, all met by the schedule below: CLK high 2.5 us to
  60 us, CLK low at least 5 us, CE edge to CLK rising at least 5 us, data
  setup and hold 2.5 us, the EEPROM's data delay at most 2.5 us, erase or
  write time at most 20 ms.

### The schedule: every edge has a fixed place

The EEPROM in this test is a scripted waveform: it is written before the
run, from the operations the test asks for and this schedule, and it
cannot react to what the chip does. So the place of every CLK and CE edge
is fixed, and each must come within +-2 cycles of it. The limit is on the
place, counted from cycle 0 of the run, not on the spacing, so an error
must not add up. Every cycle in this sheet is the one `pe_sim` prints: a
change printed as `pins c XX` happens at cycle c.

Time is cut into slots of 200 cycles (20 us). In a slot that has a CLK
pulse, CLK rises 50 cycles into the slot and falls 150 cycles into it
(10 us high, 10 us low between pulses). The first operation's first slot
begins at cycle 2000. An operation with n command bits (n = 16 for a write,
8 for a read or an erase), whose first slot begins at cycle s:

| Slot | Begins at | What happens in it |
|---|---|---|
| 0 to n - 1 | s + 200 j | command bit j: one CLK pulse, CE high |
| n | s + 200 n | CE falls at s + 200 n + 50 (no CLK pulse) |
| write, erase: n + 1 | s + 200 (n + 1) | the start pulse |
| write, erase: n + 2 | s + 200 (n + 2) | CE rises at s + 200 (n + 2) + 200000, after 20 ms with no CLK pulse |
| read: n + 1 to n + 8 | s + 200 (n + i) | read pulse i (1 to 8) |
| read: n + 9 | s + 200 (n + 9) | CE rises at s + 200 (n + 9) + 50 (no CLK pulse) |

The next operation's first slot begins 150 cycles after CE rises. So a
read takes 3600 cycles from its first slot to the next operation's, and
a write or an erase 200 (n + 2) + 200150 cycles. There are no other CLK
pulses and no other CE edges, at any time in the run.

DATA, as the chip drives it, may change only within 20 cycles either side
of a slot's beginning (cycles s + 200 j - 20 to s + 200 j + 20, both
included). Outside those windows it must be:

- in slot j of a command (from the window at its beginning to the window at
  the next slot's beginning): command bit j;
- write and erase, in slots n and n + 1: low for a write, high for an
  erase;
- at all other times (before the first operation, in a read from slot n
  on, in a write or an erase from slot n + 2 on, between operations and
  after the last): released, output 1.

The EEPROM's reply in a read is placed by the same schedule: with read
pulse i falling at cycle f_i = s + 200 (n + i) + 150, bit k of the byte is
on DATA from cycle f_(k+1) + 10 until cycle f_(k+2) + 10 (for k = 7, until
s + 200 (n + 9) + 60, 10 cycles after CE's place). At all other times the
EEPROM lets DATA go. A level on a pin arrives in a thread two cycles later
(see `isa.md`, input synchroniser).

An example. A write of 0x3C to address 0x12 sends the 16 bits 0 0 1 1 1 1
0 0 (0x3C, least significant bit first), 0 1 0 0 1 0 0 (0x12), 1 (CB). If
it is the first operation (s = 2000), CLK rises at cycles 2050, 2250, ...,
5050 and falls at 2150, ..., 5150; DATA goes low at cycle 2000 (the window
is 1980 to 2020) for D0; CE falls at 5250 with DATA low (it went low in the
window around 5200, after CB = 1); the start pulse rises at 5450 and falls
at 5550; DATA is let go in the window around 5600; CE rises at 205600; and
the next operation's first slot begins at 205750.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet.

TX: one word per operation, in the order the operations are to be done.

- Write: bit 15 = 1, bits 14..8 the address, bits 7..0 the data byte.
- Read: bit 15 = 0, bits 14..8 the address, bits 7..0 = 0x00.
- Erase: bit 15 = 0, bits 14..8 the address, bits 7..0 = 0x01.

RX: one word per read, in the order of the reads: bits 7..0 the byte read,
bits 15..8 = 0. Nothing is pushed for a write or an erase.

So erasing address 0x12, writing 0x3C there and reading it back arrive as
the three words 0x1201, 0x923C, 0x1200, and the chip pushes one word,
0x003C.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The clock pulses, chip enable, the command bits and their order, the level
of DATA at CE's fall, the start pulse, the 20 ms wait and the sampling of
the reply are the firmware's to make from those words: no word holds a pin
level, a bit order or a count.

A run is 1 to 8 operations, each a read, a write or an erase of any
address, and any data byte. The test writes the run's TX words to a file,
one per line, and the EEPROM's waveform to a stimulus file (P1's level over
time; the other pins' bits are 1), and runs
`./pe_sim run sda2506.s -tx FILE -stimulus FILE -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is the cycle
at which the last operation's CE rises, plus 2000. Nothing may change on
CLK, DATA or CE after that last CE rise. In the simulator, the TX FIFO is
refilled as soon as it has room, so you do not need to worry about the
host being slow, and the RX FIFO is read as soon as a word is in it.

You can make your own stimulus files from this sheet to test reads: the
EEPROM's DATA is the only input, on P1, so a line `CYCLE fd` pulls DATA
low from that cycle and `CYCLE ff` lets it go.

## What to hand in (all in this directory)

1. `sda2506.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those. P0 and P2 must be
   push-pull and P1 open-drain.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the bus the way a logic analyser's
SDA 2506 decoder would, measures where every edge falls, and compares the
words you push with the bytes the EEPROM gave, on operations you have not
seen.
