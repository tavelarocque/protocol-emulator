# Task: Silicon Labs C2 debug interface master firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the Silicon Labs C2
  debug interface and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for thread 0 that makes the chip the master of a Silicon Labs C2
interface: the two-wire debug and programming interface of Silicon Labs
8051 microcontrollers (C8051F and EFM8 parts), the job a USB debug adapter
or a production programmer does. The chip resets the device, then runs the
four C2 instructions the host asks for (Address Write, Address Read, Data
Write, Data Read) and hands every byte the device sends to the host
microcontroller. The chip's core clock is 50 MHz: one cycle is 20 ns, and
the thread may run every cycle.

The receiver is a logic analyser's C2 decoder together with a test that
checks the timing below. Everything you need to know is here.

### Pins

| Pin | Signal | Mode | Driven by |
|---|---|---|---|
| P0 | C2CK, the clock (and the device's reset pin) | push-pull (`-mode 0=pp`) | chip |
| P1 | C2D, the data line | open-drain (`-mode 1=od`) | chip and device, in turn |
| P2 to P7 | unused | input (the default) | nobody |

The modes in the table are required. C2D has a pull-up resistor: when
nobody pulls it low it reads 1. The chip writing 1 to C2D releases it;
writing 0 pulls it low. C2CK idles high. A "strobe" is one low pulse on
C2CK: it falls, stays low briefly, and rises.

### Bits and frames

Each strobe carries one bit on C2D. A bit of the chip's is sampled by the
device at the rising edge of its strobe: the chip sets C2D up before C2CK
falls and holds it until after C2CK rises. A bit of the device's is the
device's answer to its strobe: the device puts it out just after the
rising edge of that strobe and holds it until just after the rising edge
of the next strobe, and the chip reads it in between. All fields go least
significant bit first.

A C2 frame is a row of fields:

- START: one strobe. Nobody drives C2D (the chip leaves it released).
- INS: two strobes, the chip's: the instruction code. Data Read is 00b,
  Data Write is 01b, Address Read is 10b, Address Write is 11b (written
  most significant bit on the left, as is usual, and sent least
  significant bit first: Address Read goes out as 0, then 1).
- LENGTH: two strobes, the chip's: the number of data bytes minus one, so
  00b for one byte and 11b for four.
- ADDRESS: eight strobes, one byte: the chip's in an Address Write, the
  device's in an Address Read.
- DATA: eight strobes per byte, the bytes in order: the chip's in a Data
  Write, the device's in a Data Read.
- WAIT: the device's. In C2 the device answers 0 while it is busy and 1
  when it is ready, and the field ends with the first 1. The device used
  here is always ready: it answers 1 at the first strobe, so every WAIT
  field in this test is exactly one strobe.
- STOP: one strobe. Nobody drives C2D.

The four instructions, with their number of strobes:

| Instruction | Fields, in order | Strobes |
|---|---|---|
| Address Write | START, INS (11b), ADDRESS (chip), STOP | 12 |
| Address Read | START, INS (10b), ADDRESS (device), STOP | 12 |
| Data Write of n bytes | START, INS (01b), LENGTH, DATA (chip), WAIT, STOP | 7 + 8n |
| Data Read of n bytes | START, INS (00b), LENGTH, WAIT, DATA (device), STOP | 7 + 8n |

n is 1 to 4.

### The device reset

C2CK is also the device's reset pin: held low for at least 20 us, it
resets the device, and C2 frames may begin 2 us after it rises. Every run
begins with this reset. C2CK is high when the run starts (the outputs reset
to 1). It must fall no later than cycle 300, stay low for at least 1100
cycles (22 us), and rise again no later than cycle 1800. The 22 us is
more than the 20 us of the specification on purpose: the receiver counts
a low time as a reset only if it is strictly longer than 20 us, and the
extra 2 us leaves a margin. C2D stays released throughout.

### When the strobes happen

The device is scripted in advance and cannot react to the chip: it does
not watch C2CK. So the sheet fixes when every strobe happens.

After the reset, time is divided into slots of 50 cycles (1 us), numbered
s = 0, 1, 2, ... The strobe of slot s rises at cycle 2000 + 50s; that is
its place. Frames are numbered n = 0, 1, 2, ... in the order the host asks
for them. Frame 0's START is the strobe of slot 0. The frame's strobes take
consecutive slots. After each frame's STOP comes one idle slot with no
strobe, and the next frame's START is the strobe of the slot after that.
So if a frame's START is in slot s and it has m strobes, the next frame's
START is in slot s + m + 1.

Timing limits, all checked:

1. Every rising edge of a strobe must be within +-2 cycles (+-40 ns) of its
   place, counted from cycle 0 of the run: an error must not add up.
2. Each strobe is low for at least 4 cycles and at most 40 cycles (80 ns to
   800 ns), and C2CK is high for at least 6 cycles (120 ns) between the
   reset and the first strobe and between two strobes.
3. C2CK has no other edges: the reset, then exactly one strobe in each slot
   of a frame, none in an idle slot, and none after the last frame's STOP.
   After it C2CK stays high until the run ends.
4. Setup and hold: in each of the chip's strobes (INS, LENGTH, the
   ADDRESS of an Address Write, the DATA of a Data Write), the chip's C2D
   output must not change from the cycle C2CK falls to the cycle it rises,
   both included. In `pe_sim`'s output: if C2CK first shows low at cycle F
   and then first shows high again at cycle E, no `pins` line at a cycle
   from F to E may show a change of P1. The chip's bit is the level of its
   C2D output in cycle E.
5. The chip may pull C2D low only while it owns the line. In each frame
   the chip owns C2D from the cycle after the rising edge of the strobe
   just before its first bit (the START) to the cycle before the falling
   edge of the strobe just after its last bit (the first strobe of the
   device's ADDRESS in an Address Read, the WAIT of a Data Read or a Data
   Write, the STOP of an Address Write). At every other cycle of the run,
   including the cycle in which C2CK falls for that strobe, the chip's C2D
   output must be 1, so that the device can drive the line.

### The device

In each strobe that is the device's (WAIT, the ADDRESS of an Address Read,
the DATA of a Data Read), the device drives C2D with its bit from 3 cycles
after the place of that strobe's rising edge until 3 cycles after the
place of the next strobe's rising edge (the next strobe is always in the
same frame: another of the device's, or the STOP). At all other times it
leaves C2D to the pull-up. The firmware must read every byte the device
sends from the C2D pin; nothing else carries it.

### An example

The host asks for an Address Write of address 0x00 (the device ID
register), then a Data Read of one byte, and the device answers 0x30. The
Address Write has 12 strobes, in slots 0 to 11; slot 12 is idle; the Data
Read has 15 strobes, in slots 13 to 27; slot 28 is idle.

| Slot | Rising edge at cycle | Frame, field | Bit | Driven by |
|---|---|---|---|---|
| 0 | 2000 | 0, START | 1 | nobody |
| 1, 2 | 2050, 2100 | 0, INS 11b | 1, 1 | chip (released) |
| 3 to 10 | 2150 to 2500 | 0, ADDRESS 0x00 | 0 each | chip |
| 11 | 2550 | 0, STOP | 1 | nobody |
| 12 | none | idle | 1 | nobody |
| 13 | 2650 | 1, START | 1 | nobody |
| 14, 15 | 2700, 2750 | 1, INS 00b | 0, 0 | chip |
| 16, 17 | 2800, 2850 | 1, LENGTH 00b | 0, 0 | chip |
| 18 | 2900 | 1, WAIT | 1 | device (ready) |
| 19 to 26 | 2950 to 3300 | 1, DATA 0x30 | 0, 0, 0, 0, 1, 1, 0, 0 | device |
| 27 | 3350 | 1, STOP | 1 | nobody |
| 28 | none | idle | 1 | nobody |

A bit of the chip's is the level C2D has when its strobe rises; a bit of
the device's is the level C2D has after its strobe rises. In frame 0 the
chip owns C2D from just after the START rises (cycle 2000 in a run with
every edge on its place) until just before C2CK falls for the STOP; in
frame 1, from just after its START rises (2650) until just before C2CK
falls for the WAIT. The device answers the WAIT with 1 from cycle 2903,
which is the pull-up's level already. It pulls C2D low from cycle 2953
(after the rising edge of slot 19, the first DATA strobe) until cycle 3153,
lets it go high for the two 1 bits, pulls it low again from cycle 3253,
and lets go at cycle 3353, just after the STOP rises.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet:

- An Address Write: one word, 0x1000 plus the address (bits 7..0).
- An Address Read: one word, 0x2000.
- A Data Write of n bytes (n from 1 to 4): the word 0x3000 plus n, then n
  words, one per byte in the order the bytes go out, each with the byte in
  bits 7..0 and bits 15..8 zero.
- A Data Read of n bytes (n from 1 to 4): one word, 0x4000 plus n.
- The words of one frame follow those of the frame before with nothing
  between them.
- For every byte the device sends (the address byte of an Address Read,
  each data byte of a Data Read), the firmware pushes one word to the RX
  FIFO: the byte in bits 7..0, bits 15..8 zero. One word per byte, in the
  order the device sent them, and no other words.

So the example above arrives as the two words 0x1000, 0x4001, and the
firmware pushes 0x0030. A Data Write of the bytes 0x12, 0x34 is the three
words 0x3002, 0x0012, 0x0034.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The reset, START, the instruction codes, the length field, every bit of
every field, releasing and reading C2D, the strobes, the idle slots and
putting the bytes together are the firmware's: nothing in a word says what
a line does or when.

A run is 1 to 10 frames, each any of the four instructions, with any
address or bytes, the device returning any bytes. The test writes the
run's words to one file, one per line, and the device's levels to another,
and runs `./pe_sim run c2.s -tx FILE -stimulus FILE2 -cycles N` followed by
the arguments in `run_args.txt`, from reset, once for each run. If the slot
in which another frame would start (the slot after the last frame's idle
slot) is S, then N is 2000 + 50 x (S + 2); for the example, S is 29 and N
is 3550. The stimulus file has lines `CYCLE HEX`, bit k of HEX being the
device's level on Pk (1 where it does not pull low); for the example it is

    0 ff
    2953 fd
    3153 ff
    3253 fd
    3353 ff

In the simulator, the TX FIFO is refilled as soon as it has room, so you
do not need to worry about the host being slow. When the words have run
out, the chip must leave C2CK high and C2D released.

## What to hand in (all in this directory)

1. `c2.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the bus the way the receiver above
would, measures where every edge falls, and compares the words you push
with the bytes the device sent, on runs you have not seen.
