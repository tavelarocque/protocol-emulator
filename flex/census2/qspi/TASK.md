# Task: Quad SPI controller firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of Quad SPI, serial NOR
  flash and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the Quad SPI controller of a serial NOR flash
and writes data into the flash, page by page, with the flash's Write Enable
and Quad Page Program commands. It runs on thread 0, with the chip's core
clock at 50 MHz (one cycle = 20 ns; the thread may run every cycle). The
chip only drives the bus: nothing is read back from the flash.

### Pins

| Pin | Signal | |
|---|---|---|
| P0 | IO0 | data line 0 (the flash's DI in single-line phases) |
| P1 | IO1 | data line 1 |
| P2 | IO2 | data line 2 |
| P3 | IO3 | data line 3 |
| P4 | SCK | serial clock |
| P5 | CS# | chip select, active low |

All six are push-pull. P6 and P7 are not used. The flash's Quad Enable bit
is already set, so IO2 and IO3 are data lines, not write-protect or hold
inputs.

### The bus

SPI mode 0: SCK is low while the bus is idle, and the flash takes the level
of each IO line at every rising edge of SCK while CS# is low. A transfer (a
"frame") is everything from one fall of CS# to the next rise.

For every page the firmware sends exactly these two frames, then waits:

1. **Write Enable (WREN).** CS# falls, 8 SCK clocks carry the byte 0x06 on
   IO0, most significant bit first (one bit per rising edge), CS# rises.
2. **Quad Page Program (QPP), command 0x32, the 1-1-4 kind.** CS# falls,
   then, with no break and no dummy clocks:
   - 8 clocks: the byte 0x32 on IO0, most significant bit first;
   - 24 clocks: the page's 24-bit address on IO0, A23 first and A0 last;
   - 2 clocks for each data byte, in order, four bits per clock: at the
     first rising edge IO3, IO2, IO1, IO0 carry the byte's bits 7, 6, 5, 4,
     and at the second its bits 3, 2, 1, 0.

   Then CS# rises, right after the last data clock: no clock more.
3. **The wait.** After the QPP's CS# rises the flash is busy writing for up
   to 3 ms and ignores every command, Write Enable included. The chip does
   not read the flash's status, so it waits the worst case: CS# stays high
   for at least 150000 cycles (3 ms) and at most 200000 cycles (4 ms) from
   the QPP's CS# rise to the next page's WREN CS# fall.

In the WREN frame and in the command and address of the QPP frame only IO0
carries bits. The flash ignores IO1, IO2 and IO3 there, and so does the
test: they may hold any level. While CS# is high the IO lines may do
anything.

### Timing

The limits are those of a common 3 V quad SPI NOR flash, rounded up to
whole cycles of 20 ns, plus three of this sheet's own (marked). The test
reads the simulator's `pins` lines exactly as printed: a change printed at
cycle c is the line's level from cycle c on.

- **Start-up.** A push-pull pin is high when the run begins: CS# high is
  idle, but SCK high is not. SCK must be driven low no later than cycle 100
  of the run.
- **SCK idles low.** From then on SCK is low whenever CS# is high, and in
  every cycle in which CS# falls or rises. So SCK rises at least 1 cycle
  after CS# falls, and CS# rises at least 1 cycle after the last SCK rise
  (the flash needs 5 ns each).
- **Setup and hold.** While CS# is low, no IO line may change in a cycle in
  which SCK rises. So each bit is on its line for at least 1 cycle (20 ns)
  before the rising edge and stays at least 1 cycle after it (the flash
  needs 2 ns and 5 ns). The bit taken at a rising edge is the level in the
  cycle of that edge.
- **Clock speed.** SCK may be as fast as the chip can make it: one cycle
  high and one low (25 MHz) is fine, and the high and low times need not
  be equal. *This sheet's limit:* inside a frame SCK must not dawdle: at
  most 20 cycles (400 ns) from CS# falling to the first SCK rise, between
  two neighbouring SCK rises, and from the last SCK rise to CS# rising.
- **Between WREN and QPP** CS# stays high for at least 3 cycles (60 ns;
  the flash needs 50 ns between a write command and the next) and, *this
  sheet's limit*, at most 1000 cycles.
- **Between pages**, from a QPP's CS# rise to the next WREN's CS# fall:
  150000 to 200000 cycles, as above.
- *This sheet's limit:* the first WREN's CS# falls no later than cycle
  10000 of the run.
- **Nothing else.** Exactly two frames per page, in order, each with
  exactly the clocks above. After the last page CS# stays high and SCK low
  until the end of the run; any other clock or CS# pulse is a fault.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet:

- One word per byte of a page. A page is its three address bytes, A23..A16
  first, then A15..A8, then A7..A0, followed by its data bytes in order.
  Pages follow each other with nothing between them.
- Bits 7..0 of the word are the byte.
- Bit 8 is 1 on the last byte of a page (always a data byte) and 0
  otherwise.
- All other bits (15..9) are 0.

So a page at address 0x012300 with the data 0xDE 0xAD 0xBE 0xEF, followed
by a page at address 0xABCD10 with the data 0x01 0x23 0x45 0x67 0x89 0xAB
0xCD 0xEF, arrive as the 18 words 0x0001, 0x0023, 0x0000, 0x00DE, 0x00AD,
0x00BE, 0x01EF, 0x00AB, 0x00CD, 0x0010, 0x0001, 0x0023, 0x0045, 0x0067,
0x0089, 0x00AB, 0x00CD, 0x01EF.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The Write Enable, the command byte 0x32, the change from one line to four,
every clock, CS# and every wait are the firmware's: nothing in a word says
where a line changes.

### An example

The first page above is sent as these two frames. "Rise k" is the k-th
rising edge of SCK in the frame; a level written as 0 or 1 is IO0's, and a
hex digit is IO3..IO0 together (IO3 its top bit).

| Frame | Rises | What the lines carry |
|---|---|---|
| WREN | 1 to 8 | 0x06 on IO0: 0, 0, 0, 0, 0, 1, 1, 0 |
| QPP | 1 to 8 | 0x32 on IO0: 0, 0, 1, 1, 0, 0, 1, 0 |
| QPP | 9 to 32 | 0x012300 on IO0: 0000 0001 0010 0011 0000 0000 |
| QPP | 33 to 40 | D, E, A, D, B, E, E, F on IO3..IO0 |

That is 8 rises in the WREN frame and 40 in the QPP frame. The second page
starts with its WREN 150000 to 200000 cycles after the first page's QPP
ends.

### A run

A run is 1 to 6 pages. Each page has 4 to 256 data bytes, always a multiple
of 4, of any value, and never crosses a 256-byte boundary of the flash (A7..A0
plus the number of data bytes is at most 256); the address is otherwise any
24-bit value. The test writes the run's words to a file, one per line, and
runs `./pe_sim run qspi.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 10000 plus, for each
page of n data bytes, 201840 + 40n. In the simulator, the TX FIFO is
refilled as soon as it has room, so you do not need to worry about the host
being slow. When the words have run out, the chip must leave CS# high and
SCK low.

## What to hand in (all in this directory)

1. `qspi.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag, with
   P0 to P5 push-pull. Not `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pins the way a logic analyser's
Quad SPI decoders would, and checks every limit above, on pages you have not
seen.
