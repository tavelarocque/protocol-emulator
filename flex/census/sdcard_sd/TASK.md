# Task: SD card bus (SD mode) host firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of the SD card bus (SD
  mode) and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware for the host side of an SD memory card's command channel in SD
mode (not SPI mode): the chip clocks the card, sends it commands on the CMD
line, reads the card's responses from the same line, and hands them to the
host microcontroller. Only CLK and CMD are used; the data lines DAT0 to
DAT3 are not connected and no data blocks are moved. Thread 0 only, with
the chip's core clock at 10 MHz (one cycle = 100 ns; the thread may run
every cycle).

The receiver of your commands is a logic analyser's SD decoder (sigrok's
`sdcard_sd`), and the card is a scripted waveform played into the chip.
Everything you need to know about both is here.

### Pins

- P0 is CLK, push-pull. The card samples CMD on CLK's rising edges.
- P1 is CMD, open-drain, with a pull-up: it reads high unless the chip or
  the card pulls it low. The host drives CMD while it sends a command; the
  card drives it while it sends a response; at all other times the chip
  must leave it released (its output 1). The chip must never pull CMD low
  while the card is sending.
- P2 to P7 are not connected and must stay inputs.
- So `run_args.txt` must contain `-mode 0=pp -mode 1=od`, and no `-mode`
  for any other pin.

### The clock

CLK runs at 250 kHz: a period of 40 cycles, 20 high and 20 low. It is high
from the first cycle of the run (the pin's reset level) until its first
falling edge, at cycle 180. After that the falling edges belong at cycles
180 + 40k and the rising edges at 200 + 40k (k = 0, 1, 2, ...). Rising edge
number n (counting from 0) is at cycle 200 + 40n; everything below is
counted in these edges. Every edge of CLK must be within +-200 ns (2
cycles) of its place. The limit is on the place, not on the spacing, so
an error must not add up. CLK has no other changes.

The clock must run without a break, on that schedule, until at least 8
rising edges after the end bit of the run's last token (command or
response). After that the chip may stop the clock (leave CLK at either
level for the rest of the run), but if it stops, it must not start again.
In practice it may stop when it runs out of commands.

### CMD timing

"The bit on edge n" is CMD's level at rising edge n. The chip may change
its CMD output only while CLK is low: if P1's output changes at cycle c
(`pe_sim` prints it as `pins c ...`), CLK must already be low at cycle
c - 1 and still low at cycle c. So CMD never changes in the cycle CLK falls
or in the cycle it rises, and is steady for at least one cycle (100 ns) on
both sides of every rising edge. CMD changes at most once in each low half
of the clock, and only where the bit on the next edge differs from the bit
on the edge before. CMD is released (1) from the start of the run.

### Tokens

Commands and responses are tokens, sent one bit per clock, most
significant bit first. Bits are numbered from the last one sent, bit 0,
which is always the end bit.

A command (host to card) is 48 bits:

| Bits | Field |
|---|---|
| 47 | start bit, 0 |
| 46 | transmission bit, 1 (host) |
| 45..40 | command index, 0 to 63 |
| 39..8 | argument, 32 bits |
| 7..1 | CRC7 of bits 47..8 |
| 0 | end bit, 1 |

CRC7 is the SD card's: generator polynomial x^7 + x^3 + 1, register
starting at 0, over the 40 bits from the start bit to the end of the
argument in the order they are sent, the result sent most significant bit
first. Examples, as the 6 bytes on the line: CMD0 with argument 0 is
`40 00 00 00 00 95`; CMD8 with argument 0x000001AA is `48 00 00 01 AA 87`;
CMD17 with argument 0 is `51 00 00 00 00 55`.

A response (card to host) is 48 or 136 bits, depending on the command; the
host is told which (see the TX words). It starts with a start bit 0 and a
transmission bit 0 and ends with an end bit 1. A 48-bit response's bits
45..40 are usually the command index it answers (111111 for the answer to
ACMD41), bits 39..8 its 32-bit content, then a CRC7 and the end bit. A
136-bit response has 111111 in bits 133..128 and a 128-bit register (CID or
CSD, whose own bit 0 is the token's end bit) in bits 127..0. The firmware
does not have to check a response's CRC or its fixed bits: the test's card
always sends correct ones.

### The schedule

The card is a scripted waveform (`pe_sim -stimulus`). It was written in
advance from this schedule and cannot react to what the chip does, so the
schedule is exact:

1. Initialisation: on rising edges 0 to 79 (80 clocks) CMD is released (1).
   The first command's start bit is on edge 80.
2. A command occupies 48 consecutive edges: if its start bit is on edge s,
   its end bit is on edge s + 47.
3. A command with no response: the next command's start bit is on the 9th
   edge after the end bit (end bit on edge e, next start bit on edge e + 9:
   exactly 8 clocks with CMD released between them).
4. A command with a response: the chip releases CMD after the end bit, on
   edge e. The card's start bit is on edge e + d, where d is between 2 and
   64 and differs from command to command: the chip must find it, as the
   first edge from e + 2 on where CMD reads 0. CMD is high on every edge
   from e + 1 up to that one. The response then occupies 48 or 136
   consecutive edges; if its end bit is on edge r, the next command's
   start bit is on edge r + 9 (exactly 8 clocks between them).
5. After the last token, CMD stays released for the rest of the run.

The card drives each bit of a response from 2 cycles after the ideal
falling edge before that bit's rising edge (cycle 182 + 40n for the bit on
edge n) until the same point one clock later; between and after responses
its script leaves CMD released, and P1 reads high.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX
FIFO (4 deep) and reads 16-bit words from the RX FIFO. What the words mean
is fixed by this sheet.

TX words, three per command, command after command, in the order the
commands are to be sent:

1. Bits 5..0: the command index. Bits 9..8: the response type: 0 for no
   response, 1 for a 48-bit response, 2 for a 136-bit response. All other
   bits are 0.
2. The argument's bits 31..16.
3. The argument's bits 15..0.

RX words, pushed by the firmware for each response, in the order the
responses arrive; nothing for a command without a response:

- A 48-bit response: three words: its bits 45..40 in bits 5..0 of the
  first word (the rest of that word 0), then its bits 39..24, then its
  bits 23..8. The CRC and the fixed bits are not pushed.
- A 136-bit response: eight words: its bits 127..112, then 111..96, and so
  on down to bits 15..0 (the end bit is bit 0 of the last word).

Nothing else is pushed.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The clock, the start, transmission and end bits, the CRC7, the waiting
for and finding of each response, and every gap of the schedule are the
firmware's: nothing in a word says where the line changes.

An example. The run "CMD0 (no response), then CMD8 with argument
0x000001AA (48-bit response)" is the six TX words 0x0000, 0x0000, 0x0000,
0x0108, 0x0000, 0x01AA. CMD0 is on edges 80 to 127 (edge 80 is at cycle
3400). CMD8 is on edges 136 to 183. Say the card answers with d = 5: its
start bit is on edge 188, and it sends `08 00 00 01 AA 13` (an R7
response echoing the argument) on edges 188 to 235. The firmware pushes the
three RX words 0x0008, 0x0000, 0x01AA. A third command would start on edge
244.

A run is 1 to 10 commands, with many different indexes and arguments, each with the
response type the SD specification gives it. The test writes the run's TX
words to a file, one per line, and the card's script to another, and runs
`./pe_sim run sdcard_sd.s -tx FILE -stimulus FILE -cycles N` followed by
the arguments in `run_args.txt`, from reset, once for each run. N runs to
at least 20 clocks after the last end bit. In the simulator, the TX FIFO is
refilled as soon as it has room and the RX FIFO is emptied as soon as a
word arrives, so you do not need to worry about the host being slow. When
the commands run out, the firmware may wait for more words forever.

## What to hand in (all in this directory)

1. `sdcard_sd.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the bus the way the receiver above
would, measures where every edge falls, and compares the RX words with the
card's responses, on runs you have not seen.
