# Task: Ethernet auto-negotiation (fast link pulse) transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of Ethernet
  auto-negotiation and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that sends the link pulses of Ethernet auto-negotiation (IEEE
802.3 clause 28): fast link pulse (FLP) bursts, each carrying one 16-bit
link code word, on the transmit pair of a 10BASE-T port. It runs on thread
0, with the chip's core clock at 40 MHz (one cycle = 25 ns; the thread may
run every cycle).

### Pins

- P0 drives TD+ and P1 drives TD-, both push-pull, through the resistors
  and the transformer of an ordinary Ethernet magnetics module, which are
  outside the chip.
- With P0 and P1 both low there is no voltage across the pair: the line is
  idle. P0 high with P1 low puts TD+ above TD-: a positive pulse.
  Auto-negotiation sends only positive pulses, so P1 stays low all the
  time and P0 makes every pulse. P1 high (with P0 high or low) is never
  wanted.
- A push-pull pin is high when the run begins. P0 and P1 must both be
  driven low no later than cycle 100 of the run. After that P1 never
  changes again, and P0 is low except during the pulses below.
- No other pin is used. The chip only transmits: the link partner's pulses
  arrive on the other pair, which is not connected to it, and the host
  decides what to send (arbitration, acknowledging, next pages are the
  host's business).

### The pulses and the burst

- A pulse is P0 high for nominally 100 ns: 4 cycles. 3 to 5 cycles (75 to
  125 ns) are accepted. A pulse's place is the cycle at which P0 rises.
- An FLP burst carries one link code word, bits D0 to D15. It has 33 pulse
  positions, 62.5 us apart: a clock pulse, then the position of D0, a
  clock pulse, the position of D1, and so on, ending with the position of
  D15 and a last clock pulse. There are 17 clock pulses, and every one is
  always sent. A pulse in the position of Dk means Dk is 1; no pulse there
  means Dk is 0. D0 is sent first.
- Timing. The first clock pulse's rise is the burst's time zero. Clock
  pulse k (k = 0 to 16) belongs at 125 us x k = 5000k cycles after it, and
  the data pulse of Dk, when Dk is 1, at 5000k + 2500 cycles. Every pulse
  must rise within +-1 us (+-40 cycles) of its place, counted from that
  burst's first rise. The limit is on the place, not on the spacing, so an
  error must not add up along a burst. (The standard itself allows more:
  clock pulses 111 to 139 us apart, a data pulse 55.5 to 69.5 us after its
  clock pulse. This test holds the transmitter to the tighter limit
  because the analyser's decoder reads a data pulse only 60 to 70 us
  after its clock pulse, and a 0 only from clock pulses 120 to 140 us
  apart; +-1 us keeps every pulse well inside both windows.)
- A burst lasts 2 ms: its last clock pulse rises 80,000 cycles after its
  first. Outside the bursts nothing moves on either pin.

### The bursts

- Bursts are 8 to 24 ms apart (the standard's 16 ms +- 8 ms), measured
  from the first rise of one burst to the first rise of the next: 320,000
  to 960,000 cycles.
- The first burst's first rise must come no earlier than cycle 40,000
  (1 ms) of the run and no later than cycle 640,000 (16 ms).
- After the last burst the line stays idle until the end of the run. Any
  other pulse or change on P0 or P1, between bursts or after the last one,
  is a fault.

What the bits mean is the host's business and the chip must not depend on
it, but for reference, in a base page: D0 to D4 are the selector field
(1, 0, 0, 0, 0 for IEEE 802.3), D5 to D12 the technology ability field
(D5 10BASE-T, D6 10BASE-T full duplex, D7 100BASE-TX, D8 100BASE-TX full
duplex, D9 100BASE-T4, D10 pause, D11 asymmetric pause, D12 reserved), D13
remote fault, D14 acknowledge, D15 next page. Next pages use the bits
differently. Any 16-bit value may be sent.

An example. The base page 0x01E1 (IEEE 802.3; 10BASE-T and 100BASE-TX,
each half and full duplex) has D0 to D15 = 1, 0, 0, 0, 0, 1, 1, 1, 1, 0,
0, 0, 0, 0, 0, 0. Its burst has 17 clock pulses and 5 data pulses, 22 in
all, and they rise at these cycles after the first:
0, 2500, 5000, 10000, 15000, 20000, 25000, 27500, 30000, 32500, 35000,
37500, 40000, 42500, 45000, 50000, 55000, 60000, 65000, 70000, 75000,
80000.

### What the host sends

The host (a microcontroller) feeds the chip 16-bit words through the TX
FIFO (4 deep) and can read 16-bit words back from the RX FIFO. What the
words mean is fixed by this sheet:

- One word per FLP burst, in the order the bursts are to be sent.
- Bits 15..0 of the word are the link code word: bit k is Dk.
- The chip sends exactly one burst for each word, and nothing when there
  is no word.

So a host that advertises 10BASE-T and 100BASE-TX, half and full duplex,
twice and then acknowledges its link partner sends the three words 0x01E1,
0x01E1, 0x41E1, and the chip sends three bursts, the last with D14 set.
Nothing goes to the RX FIFO.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The clock pulses, the place of every pulse, the pulse width, the order of
the bits and the time between bursts are the firmware's: nothing in a word
says where the line changes.

A run is 1 to 8 words of any value. The test writes the run's words to a
file, one per line, and runs `./pe_sim run eth_an.s -tx FILE -cycles N`
followed by the arguments in `run_args.txt`, from reset, once for each run.
N is 960,000 times one more than the number of words. In the simulator,
the TX FIFO is refilled as soon as it has room, so you do not need to
worry about the host being slow. When the words have run out, the chip
must leave the line idle.

The test reads TD+ with a logic analyser's auto-negotiation decoder,
sampling at 1 MHz in a mode that catches pulses shorter than a sample.
Everything you need to know about it is in this sheet.

## What to hand in (all in this directory)

1. `eth_an.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those. The `-mode` flags must make P0
   and P1 push-pull and no other pin an output.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
analyser above would, and measures where every pulse falls, on words you
have not seen.
