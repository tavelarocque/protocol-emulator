# Task: AUD branch trace receiver firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of AUD branch trace and
  of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that receives branch trace from a Renesas/Hitachi microcontroller's
AUD (Advanced User Debugger) port and hands every branch destination
address to the host, on thread 0, with the chip's core clock at 50 MHz (one
cycle = 20 ns; the thread may run every cycle). The chip only receives: it
drives no pin.

In branch trace mode the microcontroller (the "target") reports each branch
it takes by sending the branch's destination address over six lines it
drives. The chip is the trace probe. The lines, all inputs to the chip:

| Pin | Line | Meaning |
|---|---|---|
| P0 | AUDCK | the target's trace clock |
| P1 | nAUDSYNC | high for idle and command nibbles, low for address nibbles |
| P2 | AUDATA0 | nibble bit 0 (least significant) |
| P3 | AUDATA1 | nibble bit 1 |
| P4 | AUDATA2 | nibble bit 2 |
| P5 | AUDATA3 | nibble bit 3 (most significant) |

P6 and P7 are not connected and are held low. Levels are logic levels: 1 is high.

How the target sends, as the logic analyser's AUD decoder (sigrok's `aud`)
reads it:

- AUDCK is a free-running clock of 1 MHz: a period of 1 us = 50 cycles,
  high for 25 cycles and low for 25. Every line is read at the rising edge
  of AUDCK. nAUDSYNC and AUDATA3..0 change only together with the falling
  edge of AUDCK, so each value is stable for 25 cycles before and 25 cycles
  after the rising edge that reads it.
- Each rising edge carries one nibble on AUDATA3..0 (AUDATA3 the most
  significant bit), together with the level of nAUDSYNC.
- While nothing is being sent the target sends the idle nibble 0011 (0x3)
  with nAUDSYNC high, once per clock.
- To send an address the target sends, on consecutive rising edges:
  1. one command nibble with nAUDSYNC high, which gives how many address
     bits follow: 1000 (0x8) for 4 bits, 1001 (0x9) for 8 bits, 1010 (0xA)
     for 16 bits, 1011 (0xB) for 32 bits;
  2. that many bits as 1, 2, 4 or 8 nibbles with nAUDSYNC low, least
     significant nibble first.
  The next rising edge has nAUDSYNC high again: an idle nibble, or the
  command nibble of the next address straight away.
- The target sends only the low bits of the address that it needs to. The
  destination address is the previous destination address with its lowest
  4, 8, 16 or 32 bits replaced by the bits sent. Before the first address
  of a run, the previous destination address counts as 0x00000000.

For example, the edges below (nAUDSYNC, then the nibble) send three
addresses:

| nAUDSYNC | Nibbles | Meaning | Destination |
|---|---|---|---|
| 1 | 0xB | 32 bits follow | |
| 0 | 4, 3, 2, 1, 0, 0, C, 0 | 0x0C001234, least significant nibble first | 0x0C001234 |
| 1 | 0x9 | 8 bits follow (no idle in between) | |
| 0 | A, 5 | 0x5A | 0x0C00125A |
| 1 | 0x3 | idle | |
| 1 | 0x3 | idle | |
| 1 | 0x8 | 4 bits follow | |
| 0 | 7 | 0x7 | 0x0C001257 |
| 1 | 0x3 | idle | |

What the target will present in every run, scripted in advance (it cannot
react to anything the chip does):

- From cycle 0 on the pins, AUDCK is low, nAUDSYNC high and AUDATA the
  idle nibble. The first rising edge of AUDCK on the pin comes between
  cycle 30 and cycle 79, and the clock runs on with an exact 50-cycle
  period from then on. The pin levels in this sheet are those on the pins.
  As the threads see them, they come through the input synchroniser
  described in `isa.md` ("Input synchroniser"), including what it reads in
  the first cycles after reset.
- At least 4 idle nibbles come before the first command nibble.
- Between the end of one address and the next command nibble there are 0
  to 20 idle nibbles.
- After the last address come 4 idle nibbles; then AUDCK stops, low, with
  nAUDSYNC high and AUDATA idle, and the run goes on for 1000 more cycles.
- A run holds 1 to 40 addresses, each of any of the four widths and any
  value. On the pins, the only nibbles that appear with nAUDSYNC high are
  the command nibbles 0x8 to 0xB and the idle nibble 0x3.

The host (a microcontroller) can push 16-bit words into the chip's TX FIFO
and reads 16-bit words from the RX FIFO (4 deep). What the words mean is
fixed by this sheet:

- The host pushes no TX words at all in this test.
- For every address the target sends, the firmware pushes two RX words:
  first bits 15..0 of the full 32-bit destination address, then bits
  31..16. Addresses are pushed in the order they were sent, and nothing
  else is ever pushed.
- Both words of an address must be pushed no earlier than the rising edge
  of AUDCK that carries the address's last nibble, and no later than 200
  cycles (4 AUDCK periods) after that edge. The cycle of a push is the
  cycle `pe_sim` prints on its `rx` line.

So the example above gives the six RX words 0x1234, 0x0C00, 0x125A, 0x0C00,
0x1257, 0x0C00. A 4-bit, 8-bit or 16-bit address still gives two words:
the full address, with the bits not sent taken from the previous one.

The host sends only the words defined above (here, none at all).
All line coding, framing and timing must be done by the firmware.

Finding the clock edges, telling commands from address nibbles, counting
nibbles, assembling them and keeping the previous address are the
firmware's: the host does nothing but read the RX words.

The test writes each run's input levels to a stimulus file and runs
`./pe_sim run aud.s -stimulus FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 1000 more than the
cycle of the stimulus's last change. In the simulator, the host reads each
RX word as soon as it is pushed. P0 to P5 must stay inputs.

## What to hand in (all in this directory)

1. `aud.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-stimulus`, `-inputs`, `-tx` or `-cycles`: the test gives what it
   needs. No `-mode` that makes any of P0 to P5 an output.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that presents trace from the target as described
above, decodes the same waveform with the logic analyser's AUD decoder, and
compares the RX words and their timing with the addresses, on runs you have
not seen.
