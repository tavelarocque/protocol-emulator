# Protocol emulator ISA, v0 (draft)

This document describes the instruction set in prose. The normative version
is the executable model in `model/isa.ml`: where the two disagree, the model
wins and this document is the bug. Every hardware implementation of the core
is checked against that model.

## Design goals

The core exists to bit-bang hardware protocols (UART, SPI, I2C, later JTAG,
SWD, PS/2) in firmware, loaded after fabrication. Three properties drive
every decision:

1. **Timing is visible in the source.** Every instruction takes exactly one
   clock cycle, plus its delay field, unless it is explicitly waiting (on a
   pin, an empty FIFO, or a full FIFO). You can count cycles by reading the
   program.
2. **Protocol bugs fail safe.** Waits can time out instead of hanging the
   core forever when a bus wedges.
3. **The spec is executable and total.** Every 16-bit word decodes to a
   defined instruction, so the hardware can be differentially tested against
   the model on uniformly random program memory.

The architecture follows the RP2040's PIO, and departs from it where PIO is
weakest for this job:

| | RP2040 PIO | This core |
|---|---|---|
| Waiting on a pin | blocks forever | optional timeout, jumps to a per-thread vector |
| I2C / open-drain | emulated by toggling pin direction | per-pin open-drain mode in hardware |
| Bit timing | fractional clock divider per state machine | counter loops on X/Y, value supplied by the host at run time |
| Program loading | host bus inside the RP2040 | SPI slave port, so an external host can load firmware |
| Undefined encodings | n/a | every word is defined; reserved encodings are NOP |

## Machine state

- **Program memory:** 32 words of 16 bits, shared by all threads. Resets to
  0, which decodes as `jmp 0`.
- **Threads:** 2 in the spec and model (1 in the first hardware build). Each
  has its own PC, configuration, registers and FIFOs.
- **Per-thread registers**, all 16 bits:
  - `X`, `Y`: scratch and loop counters.
  - `OSR` (output shift register), with a count of bits shifted out since
    the last refill.
  - `ISR` (input shift register), with a count of bits shifted in since the
    last push.
- **FIFOs**, 4 entries of 16 bits per thread:
  - TX FIFO: host to thread.
  - RX FIFO: thread to host.
- **Pins:** 8, each configured by the host as `input`, `push-pull`, or
  `open-drain`. A single shared output register drives them and resets to
  all ones, which is idle-high for UART and released for open-drain.

### Pin levels

| Mode | Output register bit 0 | Output register bit 1 |
|---|---|---|
| input | external level | external level |
| push-pull | 0 | 1 |
| open-drain | 0 | external level (released) |

For open-drain, writing 0 drives the line low and writing 1 releases it.
That is exactly I2C's wired-AND bus.

### Per-thread configuration (written by the host)

| Field | Meaning |
|---|---|
| `start` | initial PC |
| `out_base`, `out_count` | first pin and pin count for `out pins` / `mov pins` |
| `set_base`, `set_count` | first pin and pin count for `set pins` |
| `in_base` | first pin for `in pins` |
| `threshold` | bits per word (1 to 16): when the OSR counts as empty and the ISR as full |
| `timeout_vector` | jump target when a `wait ... timeout` expires |

Pin ranges wrap modulo 8.

## Cycle semantics

On every clock cycle:

1. All threads see the same snapshot of pin levels, taken at the start of
   the cycle.
2. Each thread then does one of three things:
   - counts down its remaining delay, or
   - stalls (stays on the same instruction, no delay applied), or
   - executes its instruction, moves its PC, and loads its delay counter from
     the instruction's delay field.
3. Pin writes take effect at the end of the cycle. If two threads write the
   same pin in the same cycle, the higher-numbered thread wins.

## Encoding

```
 15  13 12   9 8                 0
+------+------+-------------------+
|  op  | delay|     operands      |
+------+------+-------------------+
```

`delay` (0 to 15) is the number of extra idle cycles after the instruction
completes.

| op | Mnemonic | Operand bits |
|---|---|---|
| 000 | `jmp cond, addr` | `[8:6]` cond, `[4:0]` addr |
| 001 | `wait pol pin n [timeout]` | `[8]` pol, `[7:5]` pin, `[4]` timeout |
| 010 | `in src, count` | `[8:7]` src, `[3:0]` count (0 means 16) |
| 011 | `out dst, count` | `[8:7]` dst, `[3:0]` count (0 means 16) |
| 100 | `push` / `pull` | `[8]` 0 = push, 1 = pull |
| 101 | `mov dst, src` | `[8:6]` dst, `[5:3]` src |
| 110 | `set dst, value` | `[8:7]` dst, `[4:0]` value |
| 111 | `nop` | |

Unused operand bits are ignored. These reserved encodings decode as `nop`
(their delay field still applies):

- `set` with destination 3
- `mov` with source or destination 6 or 7

## Instructions

**`jmp [cond] addr`** jumps to `addr` if the condition holds, otherwise
falls through to the next instruction.

| cond | Syntax | Holds when |
|---|---|---|
| 0 | (none) | always |
| 1 | `!x` | X = 0 |
| 2 | `x--` | X ≠ 0 before the decrement; X is decremented either way (wrapping) |
| 3 | `!y` | Y = 0 |
| 4 | `y--` | as `x--`, on Y |
| 5 | `x!=y` | X ≠ Y |
| 6 | `!osre` | OSR not empty: bits shifted out < threshold |
| 7 | `!isrf` | ISR not full: bits shifted in < threshold |

A loop `l: jmp x-- l` entered with X = n takes exactly n + 1 cycles.

**`wait pol pin n [timeout]`** stalls until pin `n` reads `pol`.

- Without `timeout`, it can stall forever.
- With `timeout`, Y is the budget: each cycle the pin is wrong, the core
  checks Y.
  - If Y = 0, it jumps to `timeout_vector`.
  - Otherwise it decrements Y and keeps waiting.

**`in src, count`** shifts `count` bits right into the ISR. `src` is one of:

- `pins`: from `in_base` up
- `x` or `y`
- `null`: zeros

Bits arrive least significant bit first.

**`out dst, count`** shifts `count` bits out of the OSR, least significant
bit first. `dst` is one of:

- `pins`: written from `out_base` up
- `x` or `y`
- `null`: discarded

**`push`** sends the bits shifted in since the last push to the RX FIFO,
right-justified, then clears the ISR. It stalls while the RX FIFO is full.

**`pull`** loads the OSR from the TX FIFO and marks it full. It stalls while
the TX FIFO is empty.

**`mov dst, src`** copies a 16-bit value.

- Locations: `x`, `y`, `pins`, `isr`, `osr`, `null`.
- Reading `pins` gives all 8 pin levels.
- Writing `pins` writes `out_count` pins from `out_base`.
- Writing `isr` or `osr` resets that register's shift count.

**`set dst, value`** writes a 5-bit immediate to `pins` (`set_count` pins
from `set_base`), `x` or `y`.

## Host interface (planned)

The host talks to the chip over a small SPI slave port on the dedicated
input/output pins: 3 inputs (SCK, CS, MOSI) and 1 output (MISO). Through it
the host can:

- write program memory
- write thread configuration and pin modes
- enable or disable threads
- push to TX FIFOs and pop from RX FIFOs
- read status (FIFO levels, PCs)

The 8 bidirectional pins are the protocol pins. The register map comes with
the hardware design.

## Example: UART TX

`model/firmware.ml` contains a complete 8N1 transmitter in 15 instructions.

1. The host first sends `divisor - 4` (cycles per bit, minus the loop
   overhead).
2. Then it sends one byte per FIFO word.
3. Every bit is exactly `divisor` cycles.

The test suite checks this cycle for cycle against an ideal waveform, and
with an independent mid-bit-sampling receiver, over random bytes and baud
rates.

## Open questions for review

- **Program memory size.** 32 words matches PIO. With 2 threads sharing it,
  64 may be needed; that is mostly an area question for synthesis.
- **Autopush / autopull.** PIO has them. They save one instruction per word
  but complicate timing. Left out of v0.
- **Side-set.** PIO can drive a clock pin in the same cycle as another
  instruction, which matters for fast SPI. A candidate for v1, using some of
  the delay bits.
- **IRQ / thread sync.** Not in v0. Full-duplex UART does not need it; SPI
  with separate RX and TX threads might.
