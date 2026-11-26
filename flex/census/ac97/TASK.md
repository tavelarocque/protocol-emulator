# Task: AC '97 controller (output) firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of AC '97 and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the controller end of an AC '97 link (Audio
Codec '97, revision 2.3), in the output direction only: the chip sends
frames to an audio codec and reads nothing back from SDATA_IN. It runs on
thread 0, with the chip's core clock at 50 MHz (one cycle = 20 ns; the
thread may run every cycle).

The three lines:

| Pin | Line | Direction | Meaning |
|---|---|---|---|
| P0 | BIT_CLK | input, driven by the codec | the bit clock, 12.288 MHz |
| P1 | SYNC | push-pull output | frame sync, from the controller |
| P2 | SDATA_OUT | push-pull output | serial data, controller to codec |

P3 to P7 are yours to use or to leave alone; the test ignores them. P0
must stay an input.

### The codec's clock

As in every AC '97 system, the codec makes BIT_CLK and the controller
follows it. In this test the codec's BIT_CLK is scripted in advance: it does
not depend on anything the chip does. In the simulator it is given with
`-stimulus`, and its edges fall on whole cycles:

- BIT_CLK is low from cycle 0 until its first rising edge, which comes at a
  cycle from 200 to 299 (the codec starting its clock).
- From then on it runs at 12.288 MHz, which is 4.069 cycles a period on
  average. Every period is 4 or 5 cycles, rising edge to rising edge, and
  every high phase is exactly 2 cycles, so the low phase is 2 or 3. The
  5-cycle periods come about once in 14 or 15, wherever the codec's clock
  happens to put them relative to the chip's; the test chooses that
  alignment differently in every run.
- A stimulus line `c 01` means BIT_CLK is high from cycle c on, and `c 00`
  low from cycle c on. `isa.md` says when a thread sees a change of an
  input pin.
- BIT_CLK keeps running until the end of the run.

Number the falling edges of BIT_CLK 0, 1, 2, ... from the first one on the
pin, which is the one after its first rising edge. As `isa.md` says under
"Input synchroniser", a thread reads every input high in the first two
cycles after reset, so it sees P0 fall in cycle 2 although the pin has
been low all along. That is not an edge of BIT_CLK: the codec made none,
and it is not counted here or by the test.

### The link

The codec reads SYNC and SDATA_OUT at every falling edge of BIT_CLK; the
level of each line at a falling edge is what that edge carries. (AC '97
controllers drive both lines on the rising edges of BIT_CLK. The codec only
cares about the falling edges, and so does this test.)

- **Setup and hold.** AC '97 asks for SYNC and SDATA_OUT to be stable for
  at least 10 ns before and 10 ns after each falling edge of BIT_CLK. On
  the simulator's 20 ns grid that means: neither line may change in the
  cycle in which BIT_CLK falls. A change printed as `pins c ..` is the new
  level from cycle c on, so it is forbidden exactly when BIT_CLK falls at
  cycle c (a stimulus line `c 00`). Every other cycle is allowed.
- **Frames.** A frame is 256 bits, one per falling edge, sent most
  significant bit first within each slot: slot 0 (the tag) of 16 bits,
  then slots 1 to 12 of 20 bits each. Frames follow each other with no
  gap, one every 256 falling edges (48 kHz).
- **SYNC.** SYNC is high at 16 falling edges in a row for each frame, and
  low at every other falling edge. If SYNC is first high at falling edge
  e, the frame's 256 bits are carried by falling edges e + 1 to e + 256,
  and SYNC is high at falling edges e to e + 15. That is: SYNC is high
  with the last bit of the previous frame (or the idle bit before the
  first frame) and with the first 15 bits of the tag, and low again for
  the tag's last bit. The next frame's SYNC is first high at falling edge
  e + 256. SYNC changes only to begin and end these pulses.
- **The first frame.** SYNC must first be high at one of falling edges 1
  to 255 (not 0: the codec must see it low before it rises).
- **Before, between and after.** SYNC and SDATA_OUT are high when the run
  starts (the chip's output register resets to all ones). Both must be low
  by cycle 40 at the latest (a high SYNC for 1 us with no BIT_CLK is an
  AC '97 warm reset), and stay low until the first frame. SDATA_OUT is low
  at every falling edge that carries no frame bit: before the first frame
  and after the last. Once the last frame has been sent, no further SYNC
  pulse may begin.

### What goes in a frame

Every frame in this test carries a stereo pair of 16-bit PCM samples for
the codec's DAC (slots 3 and 4) and, if the host asks, one register
command (slots 1 and 2). Slot by slot, most significant bit first:

- **Slot 0, the tag, 16 bits:**
  - bit 15: valid frame, always 1;
  - bit 14: slot 1 valid, 1 if the frame carries a command (read or write);
  - bit 13: slot 2 valid, 1 if the frame carries a write, 0 for a read and
    for no command;
  - bits 12 and 11: slots 3 and 4 valid, always 1;
  - bits 10 to 3: slots 5 to 12 valid, always 0;
  - bit 2: reserved, 0;
  - bits 1 and 0: codec ID, 00 (the primary codec).
  So the tag is 0xF800 for a write, 0xD800 for a read and 0x9800 for no
  command.
- **Slot 1, command address, 20 bits:** bit 19 is 1 for a read and 0 for a
  write, bits 18 to 12 are the 7-bit register address (always even),
  bits 11 to 0 are 0. All 20 bits are 0 in a frame without a command.
- **Slot 2, command data, 20 bits:** bits 19 to 4 are the 16-bit value to
  write, bits 3 to 0 are 0. All 20 bits are 0 for a read and in a frame
  without a command.
- **Slots 3 and 4, PCM left and right, 20 bits each:** the 16-bit sample in
  bits 19 to 4, bits 3 to 0 are 0.
- **Slots 5 to 12:** 20 bits of 0 each.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX
FIFO (4 deep). What the words mean is fixed by this sheet. Each frame is
exactly four words, in this order, frame after frame, with nothing between
frames:

1. **CTRL.** Bit 8 is 1 if the frame carries a command, 0 if not. Bit 7 is
   1 for a read and 0 for a write. Bits 6..0 are the register address
   (always even). Bits 15..9 are 0. In a frame without a command the whole
   word is 0.
2. **DATA.** The 16-bit value to write. It is 0 for a read and in a frame
   without a command.
3. **LEFT.** The left 16-bit sample.
4. **RIGHT.** The right 16-bit sample.

So a frame that writes 0x0808 to register 0x02 with samples 0x1234 and
0xEDCB, then a frame that reads register 0x7C with samples 0x7FFF and
0x8000, arrive as the eight words 0x0102, 0x0808, 0x1234, 0xEDCB, 0x01FC,
0x0000, 0x7FFF, 0x8000. Their slots, as a logic analyser reports them:

| Slot | First frame | Second frame |
|---|---|---|
| 0, tag | 0xF800 | 0xD800 |
| 1, command address | 0x02000 | 0xFC000 |
| 2, command data | 0x08080 | 0x00000 |
| 3, left | 0x12340 | 0x7FFF0 |
| 4, right | 0xEDCB0 | 0x80000 |
| 5 to 12 | 0x00000 each | 0x00000 each |

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The tag, the padding of every slot to its width, the empty slots, SYNC and
every bit's timing against BIT_CLK are the firmware's: nothing in a word
says where a line changes.

A run is 1 to 12 frames. The test writes the run's words to a file, one per
line, writes the codec's BIT_CLK to a stimulus file, and runs
`./pe_sim run ac97.s -tx FILE -stimulus FILE -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is
400 + 1042 × (F + 2) for a run of F frames. In the simulator, the TX FIFO is
refilled as soon as it has room, so you do not need to worry about the host
being slow. When the words have run out, the chip must send no more frames
and leave SYNC and SDATA_OUT low.

The receiver is a codec, and the test reads the lines as one would, with a
logic analyser's AC '97 decoder (sigrok's `ac97`) for the slot values, and
by measuring the levels and the changes of SYNC and SDATA_OUT against
BIT_CLK for everything this sheet states above.

## What to hand in (all in this directory)

1. `ac97.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those. It must make P1
   and P2 push-pull and leave P0 an input.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident (you will have to write
your own BIT_CLK stimulus files, by the rules above). Then stop: it will be
checked by a separate test that decodes the lines the way the codec would,
and checks every level and change against BIT_CLK, on frames and clock
alignments you have not seen.
