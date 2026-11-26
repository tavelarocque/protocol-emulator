# Task: MIPI RFFE master firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the MIPI RFFE bus and
  of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for thread 0 that makes the chip the master of a MIPI RF Front-End
Control Interface (RFFE) bus: the two-wire bus a phone's radio chip uses to
set up the parts of its RF front end (power amplifiers, antenna switches,
low-noise amplifiers, antenna tuners). The chip runs the bus, writes the
registers of slave devices and reads them back, and hands every byte it
reads to the host microcontroller. The chip's core clock is 50 MHz: one
cycle is 20 ns, and the thread may run every cycle.

RFFE allows SCLK frequencies from 32 kHz up to 26 MHz, and its slaves are
static, so a slow clock is a legal bus. Here SCLK runs at 2.5 MHz: one SCLK
period is 20 cycles.

The receiver is a logic analyser's RFFE decoder (DreamSourceLab's
`mipi_rffe`, run under sigrok) together with a test that checks the timing
below. Everything you need to know is here.

### Pins

| Pin | Signal | Mode | Driven by |
|---|---|---|---|
| P0 | SCLK | push-pull (`-mode 0=pp`) | chip |
| P1 | SDATA | open-drain (`-mode 1=od`) | chip and slave, shared |
| P2 to P7 | unused | input (the default) | nobody |

These modes are required, and no other pin may be given a mode.

A real RFFE device drives SDATA push-pull, lets go of it when it is the
other side's turn, and a weak bus holder keeps the last level while nobody
drives. This chip cannot stop driving a push-pull pin, so here SDATA is
wired open-drain with a pull-up resistor, and the slave drives it the same
way: it pulls it low for a 0 and lets go for a 1. The chip writing 0 to P1
pulls SDATA low; writing 1 lets go of it. The level on the line is the
chip's level AND the slave's.

One rule follows that a real bus holder would keep for you: a line nobody
pulls low is high here, so wherever the protocol has SDATA low and the
slave is not holding it, the chip must hold it low. That is before the
first sequence, between sequences, during and after every bus park, and
whenever the chip sends a 0.

### The bus

The idle bus has SCLK low and SDATA low. The run starts with both of the
chip's outputs at 1 (the output register resets to all ones: SCLK high,
SDATA let go and so pulled high). Both lines must be low at cycle 100, and
stay low until the first sequence.

Every command is one sequence: a Sequence Start Condition (SSC), then a
number of SCLK clocks, one bit per clock, ending with a bus park clock.

- **SSC.** With SCLK low, SDATA goes high for one SCLK period (20 cycles),
  then low for one SCLK period (20 cycles). Then SCLK's first rising edge.
- **Clocks.** SCLK rises, stays high 10 cycles, falls, and stays low 10
  cycles. The device that sends a bit puts it on SDATA at the rising edge;
  the device that receives it takes it at the falling edge. SDATA must not
  change while SCLK is low, except in the SSC.
- **Frames**, sent most significant bit first. A command frame is the
  4-bit slave address (SA3 to SA0), an 8-bit command and a parity bit. An
  address frame or a data frame is 8 bits and a parity bit. Parity is odd:
  the number of ones in the frame, the parity bit included, is odd. So the
  parity bit is 1 when the frame's other bits hold an even number of ones.
- **Bus park.** One clock in which SDATA is 0, driven by the device that
  sent the bit before it. After the last bus park of a sequence SCLK stays
  low and SDATA stays low.

The sequences, by the kind number the host uses for them (n is the number
of data bytes, B the 3- or 4-bit field n - 1, A the register address, D
the data):

| Kind | Sequence | Command byte | After the command frame | Clocks L |
|---|---|---|---|---|
| 0 | Register 0 Write | `1 D6..D0` | bus park | 14 |
| 1 | Register Write | `0 1 0 A4..A0` | data frame, bus park | 23 |
| 2 | Register Read | `0 1 1 A4..A0` | bus park, data frame from the slave, bus park by the slave | 24 |
| 3 | Extended Register Write | `0 0 0 0 B3..B0` | address frame A7..A0, n data frames, bus park | 23 + 9n |
| 4 | Extended Register Read | `0 0 1 0 B3..B0` | address frame A7..A0, bus park, n data frames from the slave, bus park by the slave | 24 + 9n |
| 5 | Extended Register Write Long | `0 0 1 1 0 B2..B0` | address frames A15..A8 then A7..A0, n data frames, bus park | 32 + 9n |
| 6 | Extended Register Read Long | `0 0 1 1 1 B2..B0` | address frames A15..A8 then A7..A0, bus park, n data frames from the slave, bus park by the slave | 33 + 9n |

A Register 0 Write carries its 7-bit value in the command byte and has no
other frame. Extended reads and writes carry 1 to 16 bytes, the long ones 1
to 8. In a read, the bus park right after the master's last frame is the
chip's (it drives the 0 and then hands SDATA to the slave), and the last
bus park is the slave's. "Clocks L" counts every SCLK clock of the
sequence, both bus parks included.

### When everything happens

The slave is scripted in advance and cannot react to the chip: it does not
watch SCLK. So this sheet fixes the place of every edge. Sequences are
numbered s = 0, 1, 2, ... in the order the host asks for them. Sequence s
starts at cycle S(s):

- S(0) = 400.
- S(s + 1) = S(s) + 20 x (L(s) + 8), with L(s) the clocks of sequence s:
  two SCLK periods of SSC, L(s) clocks, and six idle SCLK periods.

Within a sequence starting at S, SDATA rises at cycle S and falls at
S + 20 (the SSC), and clock j (j = 0 to L - 1) rises at r(j) = S + 40 + 20j
and falls at r(j) + 10.

Timing limits, all checked, read off `pe_sim`'s output:

1. Every SCLK edge, and both edges of every SSC, must be within +-2 cycles
   of its place, counted from cycle 0 of the run: an error must not add
   up. After cycle 100 there must be no other SCLK edges.
2. After cycle 100, SDATA may change on the line only in the SSC (its rise
   and its fall, with SCLK low), or while SCLK is high, at most once per clock, from the
   cycle of the rising edge to 3 cycles before the falling edge: if P0
   first shows high at cycle R and low again at cycle F, the line may
   change at a cycle c with R <= c <= F - 3. Never anywhere else.
3. The bit of a clock is the level of SDATA on the line in the cycle
   before SCLK's falling edge (the cycle F - 1).

### Reads: the slave's part

In a read, call b the turnaround clock (the chip's bus park right after its
last frame: b = 13 for kind 2, 22 for kind 4, 31 for kind 6) and e = L - 1
the last clock (the slave's bus park). The slave's reply is 9n bits: each
byte most significant bit first, then its parity bit. The slave does this,
with r(j) the place of rising edge j:

| From cycle | Until cycle | Slave on SDATA |
|---|---|---|
| r(b) + 12 | r(b + 1) + 4 | pulls low (its bus holder) |
| r(b + 1 + k) + 4 | r(b + 2 + k) + 4 | bit k of the reply, k = 0 to 9n - 1 (0: pulls low, 1: lets go) |
| r(e) + 4 | r(e) + 14 | pulls low (its bus park) |
| r(e) + 14 | on | lets go |

At all other times the slave leaves SDATA alone. The chip:

- drives its turnaround bus park: SDATA 0 at the falling edge of clock b;
- then lets go of SDATA (writes 1 to P1) at a cycle from r(b) + 12 to
  r(b + 1) + 4: not earlier, because before r(b) + 12 nobody else holds
  the line low and the pull-up would raise it while SCLK is low;
- keeps it let go at every cycle from r(b + 1) + 4 until r(e) + 4, while
  the slave drives it: the chip must not pull SDATA low there at all, not
  even for a cycle, not even when the slave is sending a 0;
- pulls SDATA low again at a cycle from r(e) + 4 to r(e) + 14, and holds it
  low.

The firmware must read each byte from P1; nothing else carries it. The
slave's parity bits are always right, and the firmware need not check them.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet. For each sequence, in order:

1. A header word: bits 3..0 the slave address (0 to 15; 1 to 15 for a
   read, because 0 is the broadcast address), bits 7..4 the kind (0 to 6,
   from the table above), bits 12..8 the number of data bytes n (always 1
   for kinds 0, 1 and 2; 1 to 16 for kinds 3 and 4; 1 to 8 for kinds 5 and
   6), bits 15..13 zero.
2. For every kind but 0, an address word: the register address in the low
   bits, 0 to 31 for kinds 1 and 2, 0 to 255 for kinds 3 and 4, 0 to 65535
   for kinds 5 and 6.
3. For a write (kinds 0, 1, 3 and 5), n data words, one per byte in the
   order they are sent, the byte in bits 7..0 (for kind 0, the 7-bit value
   in bits 6..0), every other bit 0. A read has no data words.

The words of one sequence follow those of the one before with nothing
between them. For every byte a read returns, the firmware pushes one word
to the RX FIFO: the byte in bits 7..0, bits 15..8 zero. One word per byte,
in the order the bytes came off the bus, and no other words.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The SSC, the command byte, every parity bit, the byte count field, the bus
parks, the turnaround, the clock and reading the slave's bits are the
firmware's: nothing in a word says what a line does or when.

### An example

A Register Write of 0xA7 to register 0x13 of slave 5, then a Register Read
of register 0x1F of slave 7, which answers 0x3C. The host's words are
0x0115, 0x0013, 0x00A7, 0x0127, 0x001F, and the firmware pushes 0x003C
(`pe_sim` prints it as `rx CYCLE 60`).

Sequence 0 is a Register Write: L = 23, S = 400.

| Clocks | Rising edges at | Field | Bits | Driven by |
|---|---|---|---|---|
| SSC | | SDATA high from 400 to 420, low from 420 | | chip |
| 0 to 3 | 440 to 500 | slave address 5 | 0101 | chip |
| 4 to 11 | 520 to 660 | command: Register Write, register 0x13 | 01010011 | chip |
| 12 | 680 | parity (6 ones before it) | 1 | chip |
| 13 to 20 | 700 to 840 | data 0xA7 | 10100111 | chip |
| 21 | 860 | parity (5 ones before it) | 0 | chip |
| 22 | 880 | bus park | 0 | chip |

SCLK falls for the last time at 890. Sequence 1 starts at
400 + 20 x (23 + 8) = 1020. It is a Register Read: L = 24, b = 13, e = 23.

| Clocks | Rising edges at | Field | Bits | Driven by |
|---|---|---|---|---|
| SSC | | SDATA high from 1020 to 1040, low from 1040 | | chip |
| 0 to 3 | 1060 to 1120 | slave address 7 | 0111 | chip |
| 4 to 11 | 1140 to 1280 | command: Register Read, register 0x1F | 01111111 | chip |
| 12 | 1300 | parity (10 ones before it) | 1 | chip |
| 13 | 1320 | turnaround bus park | 0 | chip; the slave holds SDATA low from 1332, and the chip lets go at a cycle from 1332 to 1344 |
| 14 to 21 | 1340 to 1480 | data 0x3C | 00111100 | slave, each bit from 4 cycles after its edge's place (1344, 1364, ..., 1484) |
| 22 | 1500 | parity (4 ones before it) | 1 | slave, from 1504 |
| 23 | 1520 | bus park | 0 | slave, from 1524 to 1534; the chip pulls SDATA low again at a cycle from 1524 to 1534 |

A third sequence would start at 1020 + 20 x (24 + 8) = 1660.

### How the test runs it

A run is 1 to 8 sequences, of any kinds, to any slave and register, with
any data. The test writes the run's words to one file, one per line, and
the slave's levels to another, and runs
`./pe_sim run mipi_rffe.s -tx FILE -stimulus FILE2 -cycles N` followed by
the arguments in `run_args.txt`, from reset, once for each run. N is
S(R) + 100, where R is the number of sequences: the run ends 100 cycles
after the place of the SSC of a sequence that does not come. The stimulus
file has lines `CYCLE HEX`, bit k of HEX being the slave's level on Pk (1
where it lets go); for the example above it is

    0 ff
    1332 fd
    1384 ff
    1464 fd
    1504 ff
    1524 fd
    1534 ff

and N is 1760. In the simulator, the TX FIFO is refilled as soon as it has
room, so you do not need to worry about the host being slow. When the words
have run out, SCLK and SDATA must stay low to the end of the run.

## What to hand in (all in this directory)

1. `mipi_rffe.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the bus the way the receiver above
would, measures where every edge falls, and compares the words you push
with the bytes the slave sent, on sequences you have not seen.
