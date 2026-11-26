# Task: DCF77 receiver firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of DCF77 and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that receives the DCF77 time signal, on thread 0, with the chip's
core clock at 100 kHz (one cycle = 10 us = 0.01 ms; 1 ms = 100 cycles; the
thread may run every cycle). The chip only receives: it drives no pin and
the host sends it nothing.

DCF77 is the German long-wave time transmitter (77.5 kHz). A receiver module
in front of the chip demodulates it and gives a logic signal on pin P0 (an
input; no other pin is used). The chip's job is the line layer: find the
bits and the minute boundaries, and hand each bit to the host. The host
does everything after that (the time and date fields, the parity bits).

The signal on P0:

- The transmitter marks every second by reducing its carrier for a while at
  the start of the second. The module shows that reduction as a pulse: P0
  is high during it and low the rest of the time.
- A pulse carries one bit by its length. A short pulse, nominally 100 ms,
  is a 0; a long pulse, nominally 200 ms, is a 1. As the module delivers
  them, a 0 lasts 70 to 130 ms (7000 to 13000 cycles) and a 1 lasts 170 to
  230 ms (17000 to 23000 cycles). No pulse has any other length.
- Pulses begin (P0 rises) once a second, nominally 1000 ms apart. The
  module delays each rising edge by a varying amount: each one is within
  20 ms of its place on an exact one-second grid, so two neighbouring
  rising edges are 960 to 1040 ms apart (96000 to 104000 cycles).
- A minute holds 60 seconds, numbered 0 to 59, and the pulses of seconds 0
  to 58 carry the minute's bits 0 to 58. Second 59 has no pulse. That
  missing pulse is the minute marker: the rising edge of second 58 and the
  rising edge of the next minute's second 0 are 1960 to 2040 ms apart
  (196000 to 204000 cycles). The pulse after such a gap is bit 0 of a
  minute.
- The module sometimes misses a pulse in the middle of a minute. That too
  leaves a gap of 1960 to 2040 ms between two rising edges, and nothing on
  the line tells it from a minute marker. Treat it exactly as one: the
  pulse after any such gap is reported as bit 0 of a minute, and the bits
  after it are numbered from there. Do not count 59 pulses to find the
  next minute; only gaps mark minutes. No other gap occurs: neighbouring
  rising edges are always either 960 to 1040 ms or 1960 to 2040 ms apart.
- What the bits mean (bit 0 always 0, weather bits, summer time, bit 20
  always 1, minutes, hours, date, year in BCD, even parity) is the host's
  business. The test sends real DCF77 minutes, but the firmware must not
  rely on any bit's value.

The device is scripted: the test writes the whole signal in advance and
plays it in with `-stimulus`. It cannot react to anything the chip does.
A run starts at an arbitrary point of a minute:

- At cycle 0, P0 may be low, or high in the middle of a pulse whose start
  came before the run (that pulse is cut short and carries nothing). The
  first rising edge comes within the first 1000 ms of the run.
- At least three pulses come before the first minute marker. These are
  the end of a minute that was joined part way through (or a whole minute
  whose start was before the run): the chip cannot know their numbers, and
  must not report them. Nothing at all is reported before the first marker.
- After the first marker come one to three whole minutes, each followed by
  its marker, and then 1 to 10 pulses of one more minute, which the run
  does not finish. Those pulses are reported like any others. After the
  last pulse the line stays low until the end of the run.

### What the chip sends to the host

The host reads 16-bit words from the RX FIFO, as soon as each arrives. The
words are fixed by this sheet:

- One word for each pulse that comes after the first minute marker (the
  first marker in the run included: the pulse after it is the first to
  report), in the order the pulses come, and no other word.
- Bit 0 of the word is the pulse's bit: 0 for a short pulse, 1 for a long
  one.
- Bit 1 is 1 if the pulse comes after a gap of 1960 to 2040 ms (it is bit 0
  of a minute) and 0 otherwise.
- All other bits (15..2) are 0.

So a minute's first pulse, which is always a 0 in real DCF77, is the word
0x0002, and each of its other 58 pulses is 0x0000 or 0x0001. If a run
joined at second 57 of a minute shows pulses of 100 ms and 200 ms, then a
gap, then pulses of 100, 200, 100 and 100 ms, the words are 0x0002,
0x0001, 0x0000, 0x0000: the two pulses before the gap are not reported.

Timing: each word must be pushed no earlier than its pulse's rising edge
and no later than 500 ms (50000 cycles) after it. A word pushed later, or
a word for the wrong pulse, fails.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

Here the host sends nothing at all, and does nothing with the words but
record them: measuring the pulses, telling a 0 from a 1, finding the
minute markers and keeping quiet until the first one are the firmware's.

### How the test runs it

The test writes the signal to a file of `CYCLE HEX` lines (bit 0 of HEX is
P0; all other inputs are 0) and runs
`./pe_sim run dcf77.s -stimulus FILE -cycles N` followed by the arguments
in `run_args.txt`, from reset, once for each run. N is the cycle of the
last rising edge plus 1500 ms (150000 cycles). A run is up to about
250 seconds, 25 million cycles; the simulator does several million cycles
a second. To build your own test signals, write such a file yourself.

## What to hand in (all in this directory)

1. `dcf77.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-stimulus`, `-inputs`, `-tx` or `-cycles`: the test gives those. The
   line may be empty if you need no flag.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that plays in signals you have not seen, checks
that a logic analyser's DCF77 decoder reads those signals as the same bits,
and compares every word the chip pushes, and when, with what the signal
carries.
