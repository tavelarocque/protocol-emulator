# Task: Miller encoding transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of Miller encoding and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that transmits messages in Miller code (delay encoding) on pin P0
(push-pull), on thread 0, with the chip's core clock at 10 MHz (one cycle =
100 ns; the thread may run every cycle). The chip only transmits: nothing is
received.

The receiver is a logic analyser's Miller decoder (sigrok's `miller`, set to
100000 baud and to act on both edges). Everything you need to know about it
is here. It reads the line as follows:

- The bit rate is 100 kbit/s. One bit lasts 10 us = 100 cycles, and half a
  bit 5 us = 50 cycles.
- Only transitions carry information: a change of P0's level, in either
  direction. The level itself means nothing.
  - A 1 bit has one transition, in the middle of the bit.
  - A 0 bit has no transition in the middle. If the bit before it was also
    a 0, it has one transition, at its start (the boundary between the two
    bits). If the bit before it was a 1, it has no transition at all.
  - So two neighbouring transitions of a message are 1, 1.5 or 2 bit times
    apart (100, 150 or 200 cycles), never less and never more.
- A message of n bytes (n from 1 to 32) is 8n + 2 bits, sent without a
  break:
  1. A start bit, which is a 0 and begins with a transition whatever the
     line did before. The receiver locks to that transition: it is the
     message's time zero, and bit k of the message (the start bit is bit 0)
     lasts from cycle 100k to cycle 100k + 100 after it.
  2. The data bytes in order, each least significant bit first. The first
     data bit is coded with the start bit as the 0 before it.
  3. An end bit, which is a 0, coded by the same rule: a transition at its
     start if the last data bit was a 0, none if it was a 1.
- After the end bit the line must keep its level, with no transition, for
  at least 40 us (400 cycles, four bit times) before the next message's
  start bit. That silence is how the receiver finds the end of a message.
  The gap, from the end of the end bit to the next start transition, must
  also be no longer than 2 ms (20000 cycles), so that the test knows how
  long to run.
- P0 must be high from the first cycle of the run until the first message,
  so the first start bit begins with a fall. That fall must come within
  2 ms (20000 cycles) of the start of the run. After that the line is at
  whatever level its transitions have left it: a message may begin and end
  at either level, and nothing may move the line between messages or after
  the last one. Any stray transition is the start of a message to the
  receiver.
- Timing: every transition of a message must be within +-200 ns (2 cycles)
  of its ideal place, counted from that message's first transition: 100k
  cycles after it for a transition at the start of bit k, and 100k + 50 for
  one in the middle of bit k. The limit is on the place, not on the spacing,
  so an error must not add up along a message.

An example. The one-byte message 0x16 is the ten bits 0 (start), then
0 1 1 0 1 0 0 0 (0x16, least significant bit first), then 0 (end). Its
transitions are at these cycles after the first one:

| Bit | Value | Transition at | Why |
|---|---|---|---|
| 0, start | 0 | 0 | the start bit always begins with one |
| 1, data bit 0 | 0 | 100 | a 0 after a 0 |
| 2, data bit 1 | 1 | 250 | a 1 |
| 3, data bit 2 | 1 | 350 | a 1 |
| 4, data bit 3 | 0 | none | a 0 after a 1 |
| 5, data bit 4 | 1 | 550 | a 1 |
| 6, data bit 5 | 0 | none | a 0 after a 1 |
| 7, data bit 6 | 0 | 700 | a 0 after a 0 |
| 8, data bit 7 | 0 | 800 | a 0 after a 0 |
| 9, end | 0 | 900 | a 0 after a 0 |

The message ends at cycle 1000, so the next one may start at cycle 1400 at
the earliest. The message 0xFF has its last transition at cycle 850, in the
middle of data bit 7; its end bit, a 0 after a 1, has none, and it too ends
at cycle 1000.

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and can read 16-bit words back from the RX FIFO. What the words
mean is fixed by this sheet:

- One word per byte of a message, in the order the bytes are to be sent,
  message after message, with nothing between messages.
- Bits 7..0 of the word are the byte.
- Bit 8 is 1 on the last byte of a message and 0 otherwise.
- All other bits (15..9) are 0.

So the two messages 0x16 and 0xDE 0xAD 0xBE arrive as the four words
0x0116, 0x00DE, 0x00AD, 0x01BE. A message of one byte is one word, with
bit 8 set.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The start bit, the end bit, every transition and the gap between
messages are the firmware's: nothing in a word says where the line changes.

A run is 1 to 8 messages, each of 1 to 32 bytes of any value. The test
writes the run's words to a file, one per line, and runs
`./pe_sim run miller.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 20000, plus 20000 for
each message, plus the messages' own lengths in cycles. In the simulator,
the TX FIFO is refilled as soon as it has room, so you do not need to worry
about the host being slow. When the words have run out, the chip must leave
the line as it is.

## What to hand in (all in this directory)

1. `miller.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, and measures where every transition falls, on messages
you have not seen.
