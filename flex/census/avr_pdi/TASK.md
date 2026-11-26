# Task: AVR PDI programmer firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of AVR PDI and of
  similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the programmer side of Atmel's Program and
Debug Interface (PDI), the two-wire interface of the ATxmega
microcontrollers, on thread 0, with the chip's core clock at 50 MHz (one
cycle = 20 ns; the thread may run every cycle). The chip both sends and
receives: it sends the bytes of PDI instructions, and reads back the bytes
the ATxmega answers. The ATxmega is scripted: its answers are fixed in
advance, so the whole session runs on a fixed schedule, set out below.

The receiver of what the chip sends is a logic analyser's PDI decoder
(sigrok's `avr_pdi`). Everything you need to know is here.

### Pins

- **P0 is RESET / PDI_CLK**, push-pull, driven by the chip. It idles high.
- **P1 is PDI_DATA**, open-drain, with a pull-up: the line is high unless
  the chip or the ATxmega pulls it low. The chip drives it while it sends
  and must release it (output 1) at every other time, including while the
  ATxmega answers. While released, P1 reads what the ATxmega puts on it.
- `run_args.txt` must make P0 push-pull and P1 open-drain
  (`-mode 0=pp -mode 1=od`). Do not write P2 to P7.

### Bits, frames and the clock

- Every bit occupies one **slot**: one period of PDI_CLK, from a falling
  edge to the next falling edge. PDI_CLK runs at 1 MHz: a slot lasts 1 us,
  50 cycles, low for the first 25 cycles and high for the last 25.
- Whoever drives PDI_DATA changes it only while PDI_CLK is low, and the
  other side samples it on the rising edge.
- The chip may change P1 only from the falling edge of a slot (the same
  cycle as that edge counts) up to 5 cycles before that slot's rising edge.
  In a slot whose bit the chip sends, P1 may change more than once inside
  that window; only its level at the rising edge counts. In every other
  slot (idle, guard time, the ATxmega's bits), and before the first slot
  and after the last, P1 must stay released and not change at all.
- Every byte, in both directions, is one **frame** of 12 slots: a start
  bit (0), the 8 data bits least significant bit first, a parity bit that
  makes the number of 1s among the data and parity bits even, and two stop
  bits (1).
- A slot with no frame bit in it is an **idle** slot: PDI_DATA high.

### The fixed schedule

Slot k has its falling edge at cycle `2000 + 50k` and its rising edge at
cycle `2025 + 50k`, counted from the start of the run. Every PDI_CLK edge
must be within +-2 cycles (+-40 ns) of that place. The limit is on the
place, not on the spacing, so an error must not add up. The slots follow
one another in this order, without any other slots:

1. **Enable.** From cycle 0, P0 is high and P1 released. PDI_CLK starts
   with the falling edge of slot 0 at cycle 2000 (40 us later, within the
   100 us the ATxmega allows after its RESET function is disabled). Slots
   0 to 15 are idle: PDI_DATA stays high for the first 16 PDI_CLK cycles,
   which enables the PDI.
2. **The chip's frames**, the bytes it is given, one after another with no
   idle slot between them.
3. **An answer.** After the last frame of an instruction that the
   ATxmega answers (the host says which, below), the chip releases P1 for
   the ATxmega's guard time: exactly 128 idle slots, the reset value of
   the guard time, which the sessions never change. The ATxmega then sends
   its frames, one after another with no idle slot between them. After the
   last stop bit of its last frame come exactly 2 idle slots; then the
   chip's next frame begins (or the end, below).
4. Steps 2 and 3 repeat as the host's words say.
5. **The end.** After the end word (below) and the last slot before it,
   exactly 16 idle slots. If the last instruction was answered, the last
   slot before the end word is the second of the 2 idle slots after the
   answer, so the answer is followed by 2 + 16 = 18 idle slots in all;
   the 2 are never folded into the 16. Then PDI_CLK stops: after the
   rising edge of the 16th of those slots, P0 stays high and P1 released until the run
   ends. Nothing moves after that.

PDI_CLK never stops or pauses between cycle 2000 and the end: an
ATxmega disables its PDI when the clock stays still for too long.

### How the ATxmega answers

The ATxmega is a scripted waveform on P1 (`-stimulus` in the test): it
cannot react to what the chip does, and it drives P1 exactly when the
schedule above says it should. It changes PDI_DATA 5 cycles (100 ns) after
the ideal place of the falling edge that begins each of its slots, and
holds the level for the whole slot. Outside its own frames it leaves the
line released. Its frames have correct parity and two stop bits. If the
chip's clock is late or early, the ATxmega does not notice.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep) and reads 16-bit words back from the RX FIFO. What the words mean
is fixed by this sheet.

TX words, from the host to the chip:

- One word per byte the chip is to send, in order. Bits 7..0 are the byte.
- Bits 11..8 are the number of bytes, 0 to 15, the ATxmega answers after
  this byte. They are 0 except on the last byte of an instruction that is
  answered; on that byte they are the length of the answer, and the guard
  time and answer of step 3 follow this byte's frame.
- Bits 15..12 are 0.
- The session ends with one word **0x8000**, the end word, which carries no
  byte. It is always the last word of a run.

RX words, from the chip to the host:

- One word per byte the ATxmega answers, in order. Bits 7..0 are the byte;
  bits 15..8 are 0. Nothing else is pushed.
- They may be pushed at any time before the run ends.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The start bit, the parity bit, the stop bits, every idle slot, the guard
time, every PDI_CLK edge and the reading of the ATxmega's bits are the
firmware's: nothing in a word says where a line changes.

### An example

The session "LDCS status, which the ATxmega answers with 0x02; then STCS
reset, 0x59" is the PDI bytes 0x80 (answered with one byte), then 0xC1,
0x59. The host's words are 0x0180, 0x00C1, 0x0059, 0x8000. The chip pushes
one RX word, 0x0002.

| Slots | What | PDI_DATA, slot by slot |
|---|---|---|
| 0 to 15 | enable, idle | 1 x 16 |
| 16 to 27 | the chip's frame 0x80 | 0, 0 0 0 0 0 0 0 1, 1, 1 1 |
| 28 to 155 | guard time, idle, P1 released | 1 x 128 |
| 156 to 167 | the ATxmega's frame 0x02 | 0, 0 1 0 0 0 0 0 0, 1, 1 1 |
| 168 to 169 | idle | 1 1 |
| 170 to 181 | the chip's frame 0xC1 | 0, 1 0 0 0 0 0 1 1, 1, 1 1 |
| 182 to 193 | the chip's frame 0x59 | 0, 1 0 0 1 1 0 1 0, 0, 1 1 |
| 194 to 209 | end, idle | 1 x 16 |

The ATxmega's stimulus for it pulls P1 low at cycle 9805 (slot 156, its
start bit), releases it at 9905, pulls it low at 9955 and releases it at
10255 (its parity bit). The last PDI_CLK edge is the rising edge of slot
209, at cycle 12475.

### Runs

A run is one session: the enable, up to about 70 bytes sent in valid PDI
instructions (LDS, STS, LD, ST, LDCS, STCS, REPEAT, KEY), answers of 1 to
15 bytes of any value, and the end. The test writes the run's words to a
file, one per line, and the ATxmega's levels to another, and runs
`./pe_sim run avr_pdi.s -tx FILE -stimulus FILE -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is 3000
cycles after the falling edge that would follow the last slot. In the
simulator, the TX FIFO is refilled as soon as it has room, so you do not
need to worry about the host being slow, and the RX FIFO is emptied as
soon as a word is in it.

## What to hand in (all in this directory)

1. `avr_pdi.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus`, `-inputs` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiver above would, measures where every edge falls, and compares the
RX words with the ATxmega's answers, on sessions you have not seen.
