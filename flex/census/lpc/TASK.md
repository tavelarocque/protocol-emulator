# Task: LPC host firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the LPC bus and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for thread 0 that makes the chip the host of an LPC (Low Pin
Count) bus, the bus PC chipsets use to reach a Super I/O chip, a TPM or a
firmware flash. The chip runs the bus and performs read cycles: I/O reads
and memory reads. A peripheral on the bus answers each read with one data
byte, and the firmware hands each byte to the host microcontroller. The
chip's core clock is 50 MHz: one cycle is 20 ns, and the thread may run
every cycle.

LPC normally runs LCLK at 33 MHz, but the bus is synchronous and its
devices work at any clock rate from DC up to that, so here LCLK runs at
2.5 MHz: one LCLK period is 20 cycles.

The receiver is a logic analyser's LPC decoder (sigrok's `lpc`) together
with a test that checks the timing below. Everything you need to know is
here.

### Pins

| Pin | Signal | Mode | Driven by |
|---|---|---|---|
| P0 | LAD[0] | open-drain (`-mode 0=od`) | chip and peripheral, shared |
| P1 | LAD[1] | open-drain (`-mode 1=od`) | chip and peripheral, shared |
| P2 | LAD[2] | open-drain (`-mode 2=od`) | chip and peripheral, shared |
| P3 | LAD[3] | open-drain (`-mode 3=od`) | chip and peripheral, shared |
| P4 | LFRAME# (active low) | push-pull (`-mode 4=pp`) | chip |
| P5 | LCLK | push-pull (`-mode 5=pp`) | chip |
| P6, P7 | unused | input (the default) | nobody |

The modes in the table are required. LAD[3:0] carries one 4-bit value
(a nibble) per LCLK clock, with LAD[0] its least significant bit. The LAD
lines have pull-up resistors: a line nobody pulls low reads 1. The chip
writing 1 to a LAD pin releases it; writing 0 pulls it low. When this
sheet says the chip "drives 1111" it means the chip writes 1 to all four,
which is the same as releasing them.

### Clocks and sampling

LCLK's rising edges are the bus's clock. Number them k = 0, 1, 2, ...
Rising edge k belongs at cycle 100 + 20k. "Clock k" is the LCLK period that
ends with rising edge k. Every device samples LFRAME# and LAD at each
rising edge, and takes the level they had in the cycle just before it: in
`pe_sim`'s output, if the first `pins` line showing LCLK high is at cycle
E, the value of clock k is the level at cycle E - 1.

Timing limits, all checked:

1. Every rising edge of LCLK must be within +-2 cycles (+-40 ns) of its
   place, 100 + 20k, counted from cycle 0 of the run: an error must not add
   up. There must be no other rising edges.
2. LCLK must stay high for at least 6 cycles and low for at least 6 cycles
   each time. It is high when the run starts (the outputs reset to 1), so it
   must fall, and stay low at least 6 cycles, before rising edge 0.
3. LCLK must keep running, on those places, at least until rising edge
   number L, where L is the last clock of the last read (see below). After
   rising edge L it may stop, at either level, or keep running on its
   places.
4. Setup and hold: LFRAME# and the chip's LAD outputs must not change in
   the cycle of a rising edge of LCLK, nor in the cycle before it. In
   `pe_sim`'s output: if LCLK first shows high at cycle E, no `pins` line
   at cycle E - 1 or E may show a change of P0 to P4.

### A read cycle

Each read takes a fixed number of clocks, one nibble per clock:

| Clocks | Field | Driven by | LFRAME# | LAD[3:0] |
|---|---|---|---|---|
| 1 | START | chip | low | 0000 |
| 1 | CYCTYPE + DIR | chip | high | 0000 for an I/O read, 0100 for a memory read |
| 4 (I/O) or 8 (memory) | ADDR | chip | high | the address, most significant nibble first |
| 2 | TAR | chip, then nobody | high | 1111, 1111 |
| 1 | SYNC | peripheral | high | 0000 (ready) |
| 2 | DATA | peripheral | high | the byte, least significant nibble first |
| 2 | TAR | peripheral, then nobody | high | 1111, 1111 |

An I/O read has a 16-bit address and lasts 13 clocks; a memory read has a
32-bit address and lasts 17. LFRAME# is low for exactly one clock per read
(its START clock) and high at every other rising edge; it must not go low
at any other time, not even briefly between two rising edges. In the clocks
between reads LFRAME# is high and the chip leaves LAD released.

The chip must not pull any LAD line low except during its own part of a
read: from just after the rising edge that ends the clock before START
until the rising edge that ends the first TAR clock (where the lines must
already read 1111). At every other cycle of the run all four of the chip's
LAD outputs must be 1, so that the peripheral can drive the lines.

### When the reads happen

The peripheral is scripted in advance and cannot react to the chip: it
does not watch LCLK or LFRAME#. So the sheet fixes when every read
happens. Reads are numbered n = 0, 1, 2, ... in the order the host asks
for them. Read n has its START in clock 4 + 24n. If its first TAR clock is
clock t (t = 4 + 24n + 6 for an I/O read, 4 + 24n + 10 for a memory read),
the peripheral drives LAD as follows, each value from 4 cycles after the
ideal place of a rising edge to 4 cycles after the next:

| From cycle | Until cycle | Peripheral drives | Is the value of clock |
|---|---|---|---|
| 100 + 20(t+1) + 4 | 100 + 20(t+2) + 4 | 0000 (SYNC, ready) | t+2 |
| 100 + 20(t+2) + 4 | 100 + 20(t+3) + 4 | the low nibble of the byte | t+3 |
| 100 + 20(t+3) + 4 | 100 + 20(t+4) + 4 | the high nibble of the byte | t+4 |
| 100 + 20(t+4) + 4 | on | nothing (1111 by the pull-ups) | t+5, t+6, ... |

At all other times the peripheral leaves LAD alone. The read's last clock
is t + 6. The firmware must read the byte from the LAD pins; nothing else
carries it.

An example. Read 0 is an I/O read of address 0x0080, and the peripheral
answers 0x5A. Its START is clock 4, so:

| Clock | Rising edge at cycle | Field | LFRAME# | LAD[3:0] | Driven by |
|---|---|---|---|---|---|
| 0 to 3 | 100 to 160 | idle | high | 1111 | nobody |
| 4 | 180 | START | low | 0000 | chip |
| 5 | 200 | CYCTYPE + DIR | high | 0000 | chip |
| 6 | 220 | ADDR | high | 0000 (0) | chip |
| 7 | 240 | ADDR | high | 0000 (0) | chip |
| 8 | 260 | ADDR | high | 1000 (8) | chip |
| 9 | 280 | ADDR | high | 0000 (0) | chip |
| 10 | 300 | TAR | high | 1111 | chip |
| 11 | 320 | TAR | high | 1111 | nobody |
| 12 | 340 | SYNC | high | 0000 | peripheral, from cycle 324 |
| 13 | 360 | DATA | high | 1010 (0xA) | peripheral, from cycle 344 |
| 14 | 380 | DATA | high | 0101 (0x5) | peripheral, from cycle 364 |
| 15 | 400 | TAR | high | 1111 | peripheral lets go at cycle 384 |
| 16 | 420 | TAR | high | 1111 | nobody |
| 17 to 27 | 440 to 640 | idle | high | 1111 | nobody |

Read 1, if there is one, has its START in clock 28 (rising edge at cycle
660). If read 0 is the last read, L is 16, and LCLK may stop after its
rising edge at cycle 420.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet:

- For each read, in order: first a type word, 0x0000 for an I/O read or
  0x0001 for a memory read; then the address: for an I/O read one word,
  the 16-bit address; for a memory read two words, address bits 31..16 and
  then bits 15..0.
- The words of one read follow those of the read before with nothing
  between them.
- For each read, the firmware pushes one word to the RX FIFO: the byte the
  peripheral returned in bits 7..0, bits 15..8 zero. One word per read, in
  the order of the reads, and no other words.

So an I/O read of 0x0080 followed by a memory read of 0xFFC01234 arrive as
the five words 0x0000, 0x0080, 0x0001, 0xFFC0, 0x1234. If the peripheral
answers 0x5A and then 0x07, the firmware pushes 0x005A and then 0x0007.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The clock, START, the cycle type, every address nibble, the turnaround,
reading the peripheral's nibbles and putting the byte together are the
firmware's: nothing in a word says what a line does or when.

A run is 1 to 8 reads, each an I/O read or a memory read, to any address,
returning any byte. The test writes the run's words to one file, one per
line, and the peripheral's levels to another, and runs
`./pe_sim run lpc.s -tx FILE -stimulus FILE2 -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is
100 + 20 x (4 + 24 x R), with R the number of reads: the run ends at the
place of the START of a read that does not come. The stimulus file has
lines `CYCLE HEX`, bit k of HEX being the peripheral's level on Pk (1
where it does not pull low); for the example above it is

    0 ff
    324 f0
    344 fa
    364 f5
    384 ff

In the simulator, the TX FIFO is refilled as soon as it has room, so you
do not need to worry about the host being slow. When the words have run
out, the chip may stop, but only after the last read's last clock.

## What to hand in (all in this directory)

1. `lpc.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the bus the way the receiver above
would, measures where every edge falls, and compares the words you push
with the bytes the peripheral sent, on reads you have not seen.
