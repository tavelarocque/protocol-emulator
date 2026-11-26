# Task: FSI master firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of FSI (IBM's Flexible
  Service Interface) and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for thread 0 that makes the chip the master of an FSI link. FSI
(Flexible Service Interface) is the two-wire serial link IBM POWER systems
use to reach the service logic of their processors and memory buffers: a
service processor (a BMC) is the master, and each chip on the far end holds
an FSI slave with registers at 21-bit addresses. BMCs without an FSI master
in hardware drive the link from GPIO pins or a small coprocessor, which is
what this chip does here. The master performs reads and writes of 1, 2 or 4
bytes; the slave answers each one, and the firmware hands the answer to the
host microcontroller. The chip's core clock is 50 MHz: one cycle is 20 ns,
and the thread may run every cycle.

FSI hardware runs its clock at up to 166 MHz, but the master owns the clock
and the slave works at any lower rate, so here FSI_CLK runs at 2.5 MHz: one
clock period is 20 cycles.

The receiver is a logic analyser's FSI decoder (DSView's `fsi`) together
with a test that checks the timing below. Everything you need to know is
here.

### Pins and levels

| Pin | Signal | Mode | Driven by |
|---|---|---|---|
| P0 | FSI_DAT | open-drain (`-mode 0=od`) | chip and slave, shared |
| P1 | FSI_CLK | push-pull (`-mode 1=pp`) | chip |
| P2 to P7 | unused | input (the default) | nobody |

The modes of P0 and P1 are required. FSI_DAT has a pull-up resistor: a line
nobody pulls low reads high. The chip writing 1 to P0 releases it; writing
0 pulls it low.

**FSI data is inverted on the wire: a bit is 1 when FSI_DAT is low and 0
when it is high.** Everywhere below, "bit" means this logical value. So a
released line is a 0, and to send a 1 the chip pulls P0 low.

### Clocks

The clock is high when the run starts (the outputs reset to 1). Number the
clocks k = 0, 1, 2, ... Clock k begins with a falling edge of FSI_CLK at
cycle 100 + 20k and ends with a rising edge at cycle 110 + 20k. "Rising
edge k" is the one that ends clock k.

1. Every edge of FSI_CLK, falling and rising, must be within +-2 cycles
   (+-40 ns) of its place, counted from cycle 0 of the run: an error must
   not add up. There must be no other edges. The first change of FSI_CLK
   is falling edge 0, at cycle 100 (+-2).
2. FSI_CLK must keep running on those places to the end of the run (see
   "The run" below). It may keep running after that.

Each clock carries one bit on FSI_DAT, sent either by the chip or by the
slave:

3. **The chip's bits.** The master sends its bit of clock k at the falling
   edge that begins clock k, and the slave takes it at rising edge k. So
   the chip changes its DATA output only while FSI_CLK is high: after
   rising edge k - 1, and at the latest in the same cycle as falling edge k
   (the two pins may change in the same cycle). The bit then stays on the
   line through the whole low half of the clock. In `pe_sim`'s output: a
   `pins` line at cycle c that shows a change of P0 must have FSI_CLK high
   at cycle c - 1.
   The bit of clock k is the level of FSI_DAT in the cycle just before
   rising edge k: if the first `pins` line showing FSI_CLK high is at cycle
   E, the level at cycle E - 1.
4. **The slave's bits.** The slave puts its bit of clock k on the line from
   cycle 94 + 20k to cycle 114 + 20k, that is from 4 cycles after the ideal
   place of rising edge k - 1 to 4 cycles after the ideal place of rising
   edge k. A master reads it at the falling edge of clock k (cycle
   100 + 20k), as FSI masters do.

### A transaction

Every transaction is a command from the chip and a response from the slave,
each a run of bits on consecutive clocks, most significant bit first in
every field.

The command (chip to slave):

| Bits | Field | Value |
|---|---|---|
| 1 | START | 1 |
| 2 | slave ID | 0 to 3, most significant bit first |
| 3 | command | 1, 0, 0 (ABS_ADR: absolute address) |
| 1 | read/write | 1 for a read, 0 for a write |
| 21 | address | bits 20 to 0 (see below) |
| 1 | data size | 0 for 1 byte, 1 for 2 or 4 bytes |
| 0, 8, 16 or 32 | data | writes only: the value written, most significant bit first |
| 4 | CRC | see below |

A read command is 33 bits; a write is 41, 49 or 65. The address is the
byte address of the access, and accesses are naturally aligned: a 2-byte
access has an even address, a 4-byte access an address that is a multiple
of 4. FSI encodes the size in the address's low bits: a 1-byte or 2-byte
access sends its address as it is, and a 4-byte access sends its address
with bits 1 and 0 set to 0 and 1 (address 0x001000 is sent as 0x001001).

The response (slave to chip):

| Bits | Field | Value |
|---|---|---|
| 1 | START | 1 |
| 2 | slave ID | the command's |
| 2 | response code | 0, 0 for ACK; 1, 0 for ERR_A; 1, 1 for ERR_C |
| 0, 8, 16 or 32 | data | only for a read answered ACK: the value read, most significant bit first |
| 4 | CRC | see below |

(FSI also has the code 0, 1 for BUSY; this slave never sends it.) The
slave's ID and CRC are always right; the firmware need not check them.

**The CRC** is 4 bits, over every bit of the command (or response) from its
START up to the last bit before the CRC, START included: the polynomial
x^4 + x^2 + x + 1, starting from 0, bits taken in the order sent. As a
procedure: keep a 4-bit register c = 0; for each bit b, let f = b XOR (bit
3 of c), shift c left by one place (dropping bit 3, bit 0 becomes 0), and
if f is 1, flip bits 2, 1 and 0 of c. After the last bit, send bit 3 of c
first, then bits 2, 1 and 0.

### When everything happens

The slave is scripted in advance and cannot react to the chip: it does not
watch FSI_CLK or FSI_DAT. So the sheet fixes the clocks on which the chip
sends, and the slave's answers line up with them.

- Transactions are numbered n = 0, 1, 2, ... in the order the host asks
  for them. Transaction 0's START is the bit of clock 4. Clocks 0 to 3 are
  idle.
- If the command's last CRC bit is the bit of clock c, the slave's START is
  the bit of clock c + D, where D is from 17 to 80. **The firmware does not
  know D**, which differs from one transaction to the next: it must find
  the slave's START by reading FSI_DAT in every clock after its command, as
  an FSI master does. The bit of every clock between the command and the
  slave's START is 0.
- If the response's last CRC bit is the bit of clock e, the clocks e + 1 to
  e + 20 are idle (20 bits of 0), and the next transaction's START is the
  bit of clock e + 21, exactly.

The chip must not pull FSI_DAT low except during its own commands: from
just after rising edge S - 1 (S the command's START clock) until just
before rising edge c + 1 (c the clock of its last CRC bit). At every other
cycle of the run the chip's P0 output must be 1, so that the slave can
drive the line, and every bit the chip does not send reads 0.

An example. Transaction 0 writes the byte 0xA5 to address 0x000C10 of the
slave with ID 0, and the slave answers ACK with D = 17. Transaction 1 reads
2 bytes at address 0x1FFFFE of the slave with ID 3, and the slave answers
ACK with the value 0x5AC3 and D = 23.

| Clocks | Sent by | Bits | Fields |
|---|---|---|---|
| 0 to 3 | nobody | 0000 | idle |
| 4 to 44 | chip | 1 00 100 0 000000000110000010000 0 10100101 0001 | START, ID 0, ABS_ADR, write, address 0x000C10, 1 byte, 0xA5, CRC |
| 45 to 60 | nobody | 0 each | the slave's delay: 16 clocks of 0, then its START in clock 44 + 17 |
| 61 to 69 | slave | 1 00 00 0010 | START, ID 0, ACK, CRC |
| 70 to 89 | nobody | 0 each | 20 idle clocks |
| 90 to 122 | chip | 1 11 100 1 111111111111111111110 1 0011 | START, ID 3, ABS_ADR, read, address 0x1FFFFE, 2 bytes, CRC |
| 123 to 144 | nobody | 0 each | the slave's delay: START in clock 122 + 23 |
| 145 to 169 | slave | 1 11 00 0101101011000011 0010 | START, ID 3, ACK, 0x5AC3, CRC |
| 170 to 189 | nobody | 0 each | 20 idle clocks; a third START would be clock 190 |

So the chip pulls FSI_DAT low (pulls P0 low) for every 1 in clocks 4 to 44
and 90 to 122, and leaves it released everywhere else. The slave pulls it
low for its first START from cycle 94 + 20 x 61 = 1314 to cycle
114 + 20 x 61 = 1334.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet:

- For each transaction, in order:
  1. An operation word: bits 1..0 the size (0 for 1 byte, 1 for 2 bytes, 2
     for 4 bytes), bit 2 is 1 for a read and 0 for a write, bits 4..3 the
     slave ID; all other bits 0.
  2. A word holding address bits 20..16 in its bits 4..0, all other bits 0.
  3. A word holding address bits 15..0.
  4. For a write only, the data: for 1 byte one word with the byte in bits
     7..0 (bits 15..8 zero); for 2 bytes one word; for 4 bytes two words,
     bits 31..16 of the value and then bits 15..0.
- The words of one transaction follow those of the one before with nothing
  between them. The address is the byte address, already aligned as above.
- For each transaction the firmware pushes to the RX FIFO, in order:
  1. one word with the response code in bits 1..0 (0 for ACK, 2 for ERR_A,
     3 for ERR_C), all other bits 0;
  2. for a read answered ACK only, the data read: for 1 byte one word with
     the byte in bits 7..0 (bits 15..8 zero); for 2 bytes one word; for 4
     bytes two words, bits 31..16 and then bits 15..0.
  No other words.

So the example's two transactions arrive as the seven words 0x0000, 0x0000,
0x0C10, 0x00A5, 0x001D, 0x001F, 0xFFFE, and the firmware pushes 0x0000 (the
write's ACK), then 0x0000 (the read's ACK) and 0x5AC3.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The clock, the inversion of the data, START, the command code, every
address and data bit, the size encoding in the address, the CRC, finding
the slave's START, reading its code and data, and the idle clocks are the
firmware's: nothing in a word says what a line does or when.

### The run

A run is 1 to 8 transactions, each a read or a write of 1, 2 or 4 bytes,
to any slave ID and any aligned address, answered ACK or (now and then)
ERR_A or ERR_C, with any D from 17 to 80. The test writes the run's words
to one file, one per line, and the slave's levels to another, and runs
`./pe_sim run fsi.s -tx FILE -stimulus FILE2 -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is
100 + 20 x (e + 21), with e the clock of the last response's last CRC bit:
the run ends at the falling edge where a further transaction's START clock
would begin. FSI_CLK must be on its places up to and including the last
rising edge before that, at cycle N - 10. The stimulus file has lines
`CYCLE HEX`, bit 0 of HEX being the slave's level on P0 (1 where it does not
pull low), every other bit 1; for the example above (N = 3900) it is

    0 ff
    1314 fe
    1334 ff
    1454 fe
    1474 ff
    2994 fe
    3054 ff
    3114 fe
    3134 ff
    3154 fe
    3194 ff
    3214 fe
    3234 ff
    3254 fe
    3294 ff
    3374 fe
    3414 ff
    3454 fe
    3474 ff

In the simulator, the TX FIFO is refilled as soon as it has room, so you
do not need to worry about the host being slow. When the words have run
out, the chip may stop, but only after the end of the run as defined above.

## What to hand in (all in this directory)

1. `fsi.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the link the way the receiver above
would, measures where every edge falls, and compares the words you push
with what the slave sent, on transactions you have not seen.
