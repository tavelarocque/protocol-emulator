# Protocol emulator ISA, v2.3

This document describes the instruction set in prose. The normative version
is the executable model in `model/isa.ml`: where the two disagree, the model
wins and this document is the bug. Every hardware implementation of the core
is checked against that model.

## Design goals

The core exists to bit-bang hardware protocols (UART, SPI, I2C, later JTAG,
SWD, PS/2) in firmware, loaded after fabrication. Three properties drive
every decision:

1. **Timing is visible in the source.** Every instruction takes exactly one
   clock cycle, unless it is explicitly waiting (on a pin, an empty FIFO,
   or a full FIFO). You can count cycles by reading the program.
2. **Protocol bugs fail safe.** Waits can time out instead of hanging the
   core forever when a bus wedges.
3. **The spec is executable and total.** Every 16-bit word decodes to a
   defined instruction, so the hardware can be differentially tested against
   the model on uniformly random program memory.

The architecture follows the RP2040's PIO, and departs from it where PIO is
weakest for this job:

| | RP2040 PIO | This core |
|---|---|---|
| Waiting on a pin | blocks forever | optional timeout from a dedicated per-thread counter, then a jump to a per-thread vector |
| I2C / open-drain | emulated by toggling pin direction | per-pin open-drain mode in hardware |
| Bit timing | fractional clock divider per state machine | integer clock divider per thread, or counter loops on X/Y with the count supplied by the host at run time |
| Program loading | host bus inside the RP2040 | SPI slave port, so an external host can load firmware |
| Undefined encodings | n/a | every word is defined; reserved encodings are NOP |
| Program memory | 32 words, shared by four state machines | 256 words per thread, in SRAM; jumps reach a 64-word page, chosen by a PAGE register |

## Machine state

- **Program memory:** 256 words of 16 bits for each thread, in four pages
  of 64. The host writes either memory or both at once; loading the same
  image into both is the default and gives two threads sharing one
  program. The memories are SRAM: reset does not clear them, and what they
  hold before the host loads them is undefined.
- **Threads:** 2. Each has its own PC, PAGE, configuration, registers,
  FIFOs and program memory, so both execute an instruction every cycle.
- **`PAGE`**, 2 bits per thread: the page a `jmp` lands in (see `jmp`).
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

| Mode | Pin's output bit = 0 | Pin's output bit = 1 |
|---|---|---|
| input | external level | external level |
| push-pull | 0 | 1 |
| open-drain | 0 | external level (released) |

For open-drain, writing 0 drives the line low and writing 1 releases it.
That is exactly I2C's wired-AND bus.

Because the output register resets to all ones, a push-pull pin is high
from the moment the host makes it push-pull until the firmware first writes
it. For a line that idles low (WS2812, for one), enable the thread before
making the pin push-pull, and have the firmware start by driving it low and
holding it there long enough to count as a reset.

### Input synchroniser

"External level" above means the level after the input synchroniser. A
signal from another device can change at any moment relative to the core
clock, and a flip-flop that samples it mid-change can hang between 0 and 1
for a while before settling (metastability), long enough for two parts of
the logic to read it differently. So every protocol pin's input passes
through two flip-flops in series before any logic uses it: a level that
arrives during cycle t is seen by the threads in cycle t + 2. The first
flop may go metastable; it has a whole cycle to settle before the second
samples it.

The host can bypass the synchroniser per pin (SYNC_BYPASS). That is only
safe for a signal known to be stable whenever it is sampled, and it is
needed only where two cycles of delay are too many: the side-set SPI
controller samples MISO one clock after SCK falls, so it bypasses MISO,
which the slave changes only after that falling edge. A thread's own
output, read back on a push-pull or open-drain pin, is never delayed.

### Per-thread configuration (written by the host)

| Field | Meaning |
|---|---|
| `start` | initial PC, anywhere in the thread's memory. While the thread is disabled, PAGE is the page `start` is in |
| `out_base`, `out_count` | first pin and pin count for `out pins` / `mov pins` |
| `set_base`, `set_count` | first pin and pin count for `set pins` |
| `in_base` | first pin for `in pins` |
| `threshold` | bits per word (1 to 16): when the OSR counts as empty and the ISR as full |
| `timeout_vector` | jump target when a `wait ... timeout` expires: a full address, so it can be in any page. PAGE is not changed by the jump |
| `timeout` | cycles (0 to 65535) a `wait ... timeout` may stall before it expires |
| `sideset_base`, `sideset_count` | first side-set pin, and how many of the `side` field's top bits (0 to 3) are side-set values |
| `clkdiv` | the thread runs one cycle in every `clkdiv` (0 and 1: every cycle). Between those ticks it does nothing at all, so wait timeouts count in ticks |
| `out_msb_first`, `in_msb_first` | shift direction (SHIFT register). OUT: take bits from the top of the OSR and shift it left. IN: shift the ISR left, new bits entering at the bottom. Off by default, which is least significant bit first |
| `autopull`, `autopush` | the OSR refills and the ISR empties by themselves (see `out` and `in`). Off by default |
| `crc_poly`, `crc_init` | the CRC register's polynomial, written low power first, and the value it starts from; 32 bits each |
| `crc_invert`, `crc_in` | the CRC register reads inverted; it follows the bits IN shifts, not OUT's |

Pin ranges wrap modulo 8.

## Cycle semantics

On every clock cycle:

1. All threads see the same snapshot of pin levels, taken at the start of
   the cycle.
2. Each thread then does one of two things:
   - stalls (stays on the same instruction), or
   - executes its instruction and moves its PC.
3. Pin writes take effect at the end of the cycle. If two threads write the
   same pin in the same cycle, the higher-numbered thread wins.

A thread with `clkdiv` above 1 takes step 2 only on its ticks, one cycle in
every `clkdiv`; on other cycles it holds its whole state. Its first tick is
the first cycle it is enabled.

### The CRC register

Each thread has a 32-bit CRC register. It takes one bit from every OUT the
thread executes (or every IN, with `crc_in`): the first bit that
instruction shifted. Protocols with a CRC shift one bit at a time, so that
is every bit. If the bit differs from the register's bit 0, the register
shifts right and the polynomial is added; otherwise it only shifts.

With the polynomial written low power first, that one rule is the CRC of
Ethernet (0xEDB88320, from all ones, sent inverted), USB (0xA001 for its
CRC-16) and CAN (its 15-bit polynomial reversed, from zero, with the bytes
shifted most significant bit first). A CRC narrower than 32 bits uses the
register's low bits. The register starts from `crc_init` whenever the
thread is disabled. `mov` reads it and restarts it (see `mov`).

### The packet buffer

A memory of 1024 words of 16 bits that can stand in for the host at one end
of one thread's FIFOs. The host fills it or reads it back while it is off.
Set to play, it is the source of one thread's TX FIFO: in any cycle that
starts with the pointer short of the end and that FIFO not full, one word
moves from the buffer into the FIFO and the pointer moves on. Set to
record, it is the sink of one thread's RX FIFO in the same way. The thread
cannot tell: it pulls and pushes as it always did, with a host that never
falls behind. That is what a protocol faster than the host port needs, and
10 Mbit Ethernet takes 625,000 words a second where the port can carry
260,000.

While the buffer plays into a FIFO the host cannot push to it, and while it
records from one the host cannot pop it. An end the chain owns (thread 1's
TX FIFO, thread 0's RX FIFO) is not the buffer's: it does nothing there.
The pointer wraps from 1023 to 0. Like the program memories the buffer is
SRAM: it answers a cycle after it is asked, and in a cycle in which it is
written it is not asked, so nothing is played in the cycle after a write.
Reset does not clear it.

### The bit sampler

One block of hardware in front of the threads, for line codes too fast for
a thread to follow edge by edge. Recovering a sender's clock means timing
its edges, and a thread that needs a few instructions per edge cannot do
that for a bit that lasts four clocks. The sampler does that one job, and
hands the threads bits; everything after that is still firmware.

It listens to one pin and looks at it twice per clock cycle, on the rising
edge and on the falling edge, so at 40 MHz it has a sample every 12.5 ns.
(The falling-edge sample is the only flip-flop in the chip clocked on that
edge. It passes through a second, rising-edge flip-flop before any logic
uses it, as every input does.) Its three timing numbers count samples.

The sampler keeps a phase: the number of samples since the last edge it
accepted. Each sample:

- If the level changed and the phase has reached `blank`, the edge is
  accepted and the phase starts again from 0. An edge before that is
  ignored.
- Otherwise, if the phase has reached `wrap`, a bit time has gone by with
  no edge. Up to `misses` times in a row the phase starts again from 0
  anyway, so the bits keep coming at the pace of the last edge; after that
  the carrier is lost, and nothing more is recovered until the next edge.
  With `misses` at 7 the carrier is never lost.
- Otherwise the phase moves on by one.

A sample that leaves the phase at `sample`, with the carrier there, is a
recovered bit (its opposite, with `invert`).

That is enough for the two common families of code. Manchester code has an
edge in the middle of every bit and sometimes one between bits: with
`blank` at about three quarters of a bit the sampler locks to the middle
edges and ignores the others, the level just after a middle edge is the
bit, and one bit time without an edge is the end of the transmission
(`misses` 0). NRZ code has edges only between bits and not between equal
ones: `blank` 0 so that every edge restarts the phase, `sample` half a bit,
`wrap` one sample short of a bit, and as many `misses` as the code allows
equal bits in a row.

While the carrier is there, the recovered bits shift through an 8-bit
history, first bit lowest. With the sync word on, bits are passed on to the
threads only after the history has held that word: for Ethernet 0xD5, the
last byte before a frame. So link pulses, noise, and a transmission joined
half way through reach no thread.

A bit that is passed on shows on two pins as the threads see them, whatever
those pins' modes and whatever is on them outside: the bit on the sampler's
own pin, held until the next one, and a pulse one cycle long on the pin
after it (pin 0 after pin 7). A thread takes the bits with instructions it
already has: `wait 1 pin` on the pulse, `in pins, 1` for the bit, and
`wait ... timeout` on the pulse to find the end. Two edges are never
accepted less than `blank` + 1 samples apart, so with `blank` 5 the pulses
are at least three cycles apart and a three-instruction loop always keeps
up.

Three more settings fit it to slower lines and to codes with stuff bits.
All three are 0 after reset, which is everything above.

- **A prescaler.** With `prescale` n, from 1 to 1023, a sample is n whole
  clock cycles: the sampler looks at its pin once every n cycles, at the
  rising edge only. The three timing numbers still count samples, so a bit
  can last up to 32 n cycles: CAN at 125 kbit/s on a 10 MHz clock is 20
  samples of 4 cycles. The pulse for a bit then lasts until the next
  sample, n cycles, so a thread whose clock divider is also n sees each
  pulse in exactly one of its ticks.
- **A shift.** With `shift` k the recovered bit shows k pins on from the
  sampler's own pin and the pulse on the pin after that (counting round
  from 7 to 0). The input pin then still shows the line itself, for a
  thread that has to read it as it is: a CAN transmitter, which must see
  what the bus is doing now and not what the last bit was.
- **Stuff bits.** Some codes never send more than n equal bits in a row:
  after n of them the sender puts in one bit of the opposite level, which
  carries nothing. With `stuff` n, from 1 to 7, the sampler counts the run
  of equal recovered bits, and a bit that follows a run of exactly n and
  is their opposite is taken out: it is not passed on, does not enter the
  history, and counts as the first bit of the next run. A bit that follows
  a run of n and is the same again was not stuffing (an idle line, an
  end-of-frame mark, an error flag): it is passed on like any other, and
  so is every bit after it up to and including the next one that differs,
  which starts a run of one. So a frame that begins after an idle line
  begins with a bit that is passed on.

How much jitter it stands is set by the sample spacing and nothing else.
Each edge resets the phase, so what matters is the distance between two
neighbouring edges. With the settings for 10 Mbit Manchester at 40 MHz
(`blank` 5, `sample` 1, `wrap` 11), the edge between two bits may show one
sample late and still be ignored, and a middle edge may show two samples
early and still be accepted: 12.5 ns one way and 25 ns the other. At
50 MHz (`blank` 7, `sample` 2, `wrap` 14) it is 20 ns both ways. IEEE 802.3
asks a 10BASE-T receiver to accept edges up to 13.5 ns from where they
belong, which is 27 ns between neighbours; this sampler does not meet that,
and no setting of it can, because a 12.5 ns or 10 ns sample is too coarse.
It receives from a sender with clean edges over a short cable.
`sim/test_ethernet_rx.ml` measures it: at 40 MHz every frame arrives with
each edge up to 6 ns off, at 50 MHz up to 10 ns.

### Chaining threads

With the host's CHAIN bit set, thread 0's RX FIFO feeds thread 1's TX FIFO:
in any cycle that starts with the first non-empty and the second not full,
one word moves across. Like every FIFO rule, this is judged at the start of
the cycle, so a word thread 0 pushes reaches thread 1 two cycles later at
the earliest. While chained, the host cannot pop thread 0's RX FIFO or push
to thread 1's TX FIFO. This is what lets one thread's protocol feed another
with no host in the data path (`Firmware.Bridge`: I2C reads in, SPI out).

## Encoding

```
 15  13 12   9 8                 0
+------+------+-------------------+
|  op  | side |     operands      |
+------+------+-------------------+
```

`side` holds side-set values. With side-set enabled (`sideset_count = n > 0`),
the top `n` bits of this field are side-set values. The other bits of the
field are reserved and must be 0: pe_sim will not assemble or run a program
in which one is set.

### Side-set

Side-set drives up to three pins as a side effect of any instruction, so a
clock edge costs no instruction of its own. With `sideset_count = n`, the
top `n` bits of the `side` field are written to `n` pins starting at
`sideset_base` (wrapping modulo 8) on every cycle the instruction executes,
including cycles where it stalls. If the instruction also writes those
pins, side-set wins.

In assembly, `.side_set n` before the first instruction makes the
assembler put side-set values in the `side` field, and from then on every
instruction must say `side V`. The thread only applies them if the host also
sets SIDESET (`sideset_count = n` and `sideset_base`); without that, the
thread takes those bits as reserved bits: the pins never change, and pe_sim
will not run a program whose side-set values are not all 0.

```
        .side_set 1
        out pins, 1   side 0   ; MOSI out, SCK low
        in pins, 1    side 1   ; SCK high, sample MISO
```

The encoding of the 16-bit word is unchanged; side-set only changes how the
thread interprets the `side` field, so with `sideset_count = 0` everything is
exactly v1.

| op | Mnemonic | Operand bits |
|---|---|---|
| 000 | `jmp cond, addr` | `[8:6]` cond, `[5:0]` addr |
| 001 | `wait pol pin n [timeout]` | `[8]` pol, `[7:5]` pin, `[4]` timeout |
| 010 | `in src, count` | `[8:7]` src, `[3:0]` count (0 means 16) |
| 011 | `out dst, count` | `[8:7]` dst, `[3:0]` count (0 means 16) |
| 100 | `push` / `pull` | `[8]` 0 = push, 1 = pull |
| 101 | `mov dst, src` | `[8:6]` dst, `[5:3]` src |
| 110 | `set dst, value` | `[8:7]` dst, `[4:0]` value |
| 111 | `nop` | |

Operand values: for `in` src and `out` dst, `pins` 0, `x` 1, `y` 2,
`null` 3; for `set` dst, `pins` 0, `x` 1, `y` 2; for `mov`, `x` 0, `y` 1,
`pins` 2, `isr` 3, `osr` 4, `null` 5. Conditions are numbered in the `jmp`
table below.

Unused operand bits are ignored. These reserved encodings decode as `nop`:

- `set` with destination 3
- `mov` with source or destination 6 or 7

## Instructions

**`jmp [cond] addr`** jumps if the condition holds, otherwise falls through
to the next instruction. `addr` is 6 bits, a place within a page; the jump
goes to word `addr` of page `PAGE`, that is to `PAGE × 64 + addr`.

`PAGE` is the page `start` is in when the thread starts, and after that
only `set page, n` changes it. Running off the end of one page into the
next does not, and neither does a wait timing out. So a program of up to 64
words placed in one page, with `start` in that page, never needs to think
about pages, and runs the same in any of them; that is every program
written before v2.0. A longer program crosses to another page by falling
into it or with `set page, n` then `jmp`, two instructions. The assembler
follows PAGE down the listing and rejects a jump to a label in any other
page. It follows the listing, not the flow of control, so two directives
say what it cannot see: `.page n` on a line of its own means the lines
below are reached with PAGE = n, and `.align` fills with `nop` to the next
page boundary and means the same of that page.

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
- With `timeout`, a hidden per-thread counter is the budget. It loads from
  the `timeout` register when the wait starts stalling and counts down each
  stalled cycle; when it is already 0 and the pin is still wrong, the thread
  jumps to `timeout_vector`. A wait with `timeout = T` therefore stalls
  for T cycles at most, and if the pin is still wrong, jumps on the cycle
  after (with T = 0, at once). X and Y are untouched, so firmware can keep using them for
  bit timing, and every timed wait starts with a fresh budget.

**`in src, count`** shifts `count` bits right into the ISR. `src` is one of:

- `pins`: from `in_base` up
- `x` or `y`
- `null`: zeros

Bits arrive least significant bit first by default; with `in_msb_first`
the ISR shifts left instead and new bits enter at the bottom.

With `autopush`, an `in` that brings the ISR's count to the threshold
pushes it in the same cycle, as `push` would, and clears it. If the RX FIFO
is full, that `in` stalls instead, with nothing shifted.

**`out dst, count`** shifts `count` bits out of the OSR, least significant
bit first by default; with `out_msb_first` it takes them from the top and
shifts the OSR left. `dst` is one of:

- `pins`: written from `out_base` up
- `x` or `y`
- `null`: discarded

With `autopull`, an `out` that empties the OSR refills it from the TX FIFO
in the same cycle, if the FIFO has a word, so a program can shift bits
without a gap and never execute a `pull`. An `out` that finds the OSR empty
spends that tick fetching a word instead (or waiting for one), and runs on
the next.

**`push`** sends the bits shifted in since the last push to the RX FIFO,
right-justified, then clears the ISR. It stalls while the RX FIFO is full.

**`pull`** loads the OSR from the TX FIFO and marks it full. It stalls while
the TX FIFO is empty.

**`mov dst, src`** copies a 16-bit value.

- Locations: `x`, `y`, `pins`, `isr`, `osr`, `null`, `crc`.
- Reading `pins` gives all 8 pin levels.
- Reading `crc` gives the CRC register's low 16 bits (inverted, with
  `crc_invert`). The register then holds its high 16 bits in its low half,
  so a second read gives those, and it stops following the data. Writing
  `crc`, from any source, starts it again from `crc_init`.
- Writing `pins` writes `out_count` pins from `out_base`.
- Writing `isr` or `osr` resets that register's shift count.

**`set dst, value`** writes a 5-bit immediate to `pins` (`set_count` pins
from `set_base`), `x`, `y` or `page` (the value modulo 4).

## Host interface

The host talks to the chip over a small SPI slave port on the dedicated
input/output pins: 3 inputs (SCK, CS, MOSI) and 1 output (MISO). Through it
the host:

- writes program memory, 64 words at a time: a LOAD register names the
  page and which threads' memories a write goes to (both, by default; the
  assembler can place each thread's program at its own origin in one
  image). A write to the memory of an enabled thread is ignored. After a
  write to a stopped thread's memory, that thread is held in its initial
  state for one more cycle even if the host enables it at once: the memory
  answers a cycle after it is asked, and in a cycle with a write it is not
  asked for the thread's first instruction
- writes each thread's configuration, in two identical register banks
- sets the pin modes, shared by both threads
- enables threads through one CTRL register, so a single write can start or
  stop both in the same cycle
- pushes to each thread's TX FIFO and pops from its RX FIFO
- fills the packet buffer and reads it back, a word at a time at its
  pointer, and sets it playing into a thread or recording from one
- sets the bit sampler's pin, timing and sync word, and reads whether it
  has a carrier
- reads status (FIFO levels, PCs)

The register map is in `docs/info.md` and `hw/top.ml`.

## Example: UART TX

`model/firmware.ml` contains a complete 8N1 transmitter in 16 instructions.

1. The host first sends `divisor - 4` (cycles per bit, minus the loop
   overhead).
2. Then it sends one byte per FIFO word.
3. Every bit is exactly `divisor` cycles.

The test suite checks this cycle for cycle against an ideal waveform, and
with an independent mid-bit-sampling receiver, over random bytes and baud
rates.

## Revision history

- **v1.** Program memory grew from 32 to 64 words, and the jump address
  field from 5 to 6 bits (bit 5 was unused in v0, so every v0 program
  encodes identically). The wait timeout moved from Y to a dedicated counter
  loaded from a new `timeout` register. Both changes came from writing the
  I2C controller: it did not fit in 32 words, and with the budget in Y it
  could never be longer than one half bit-period, far shorter than the
  milliseconds real I2C devices may stretch the clock.

- **v1.1.** Side-set, configured per thread through a new SIDESET register.
  The SPI controller written without it needs 9 cycles per bit at full
  speed; with it, 2 (`model/firmware.ml`, `spi_fast`). That is also what
  makes the low-speed USB stretch goal possible at all: at 10 MHz a USB
  low-speed bit is about 6.7 cycles.

- **Hardware: two threads.** Not an ISA change: the spec and model always
  had two threads. The chip now builds both, with per-thread register banks
  (thread 1's at 0x50), one read port per thread into the shared memory, and
  the pin rule above built structurally (thread 1's datapath starts from
  thread 0's result). Programs written for one thread run unchanged.

- **v1.2.** A clock divider per thread (CLKDIV) and CHAIN. Both came from
  trying to build an I2C-to-SPI bridge. The first I2C controller spent 16
  of its 49 words on delay loops, so it could not fit in memory beside the
  SPI controller and had no room for reads. With the divider, the new
  controller (`Firmware.i2c`) does reads and writes in 25 words, with the
  bit rate set by the divider (6 ticks a bit). CHAIN removes the host from
  the bridge's data path. With CLKDIV at 0 and CHAIN clear, everything
  behaves exactly as v1.1.

- **v1.3.** Input synchronisers on the protocol pins, with a per-pin bypass
  (SYNC_BYPASS). Found by reviewing the design for silicon rather than for
  simulation: the SPI host port was synchronised from the start, but the
  protocol pins went straight into the threads, which simulation can never
  show is a problem. Every pin read is now two cycles later unless bypassed.
  Existing firmware is unaffected except the side-set SPI controller, which
  bypasses MISO (a test shows it fails without the bypass).

- **v1.4.** Shift direction per thread (SHIFT register), for OUT and IN
  separately. Before it, OUT and IN both shifted right, so data always left
  least significant bit first and arrived that way: every MSB-first
  protocol (SPI, I2C) needed the host to bit-reverse every byte, and a
  thread could not bridge an MSB-first protocol into an LSB-first one. With
  SHIFT set, the side-set SPI controller takes and returns plain bytes. The
  last hardware change before the design freeze.

- **v2.0.** Program memory in SRAM, one memory of 256 words per thread,
  where v1.4 had 64 words of flip-flops shared by both. The flip-flop
  memory could not grow: on this process a design gets one horizontal
  routing layer, and the read multiplexers of a 128-word memory already
  would not route in the time allowed, a 256-word one not at all. An SRAM
  macro of 256 words takes 2% of the die. It can read one word a clock, so
  each thread has its own; it registers its address, so it is given the pc
  the thread will have next cycle, and each thread still executes one
  instruction every cycle. Three things changed for firmware and the host:
  - `jmp` still holds 6 bits, so a PAGE register per thread supplies the
    rest, and `set page, n` (until now a reserved encoding, a NOP) sets it.
    `start` and `timeout_vector` are full addresses.
  - A LOAD register says where program writes go. It resets to "both
    memories, page 0", so a host that never touches it loads and runs a
    v1.4 image exactly as before.
  - Memory is not cleared by reset, a write to a running thread's memory
    is ignored, and a thread is held for one cycle after a write to its
    memory.
  Every v1.4 program encodes and runs identically.

- **v2.1.** Three additions, each off unless the host turns it on, so
  every earlier program runs as before. They came from writing 10 Mbit
  Ethernet, which is 4 clocks a bit at 40 MHz:
  - Autopull and autopush. There is no clock in which to fetch a word, so
    the OSR has to refill itself.
  - The packet buffer. No host port can supply 625,000 words a second, so
    a third SRAM plays a frame into the FIFO, or records one from it.
  - A CRC register per thread, with the polynomial the host's to set, and
    `mov` to read it (location 6, until now reserved and a NOP). A CRC-32
    cannot be computed by firmware in 4 clocks a bit. The same register
    gives USB's and CAN's CRCs.
  The CRC register takes one bit an instruction. Sixteen, with a free
  polynomial, was more than the equivalence proof could finish.

- **v2.2.** The bit sampler: clock recovery in hardware, for 10 Mbit
  Ethernet receive. Off unless the host turns it on, and no instruction
  changed: what it recovers appears on two pins. It came from working out
  what a thread can do in the 4 clocks a bit lasts at 40 MHz. A thread can
  take a bit that is handed to it, with one IN, and still count it and run
  the CRC. It cannot find the bit: that needs the time of each edge to a
  fraction of a bit, and 4 samples a bit leave no margin at all at some
  alignments of the two clocks. So the sampler looks on both clock edges,
  8 samples a bit, and does only the timing. Its numbers are registers, in
  samples, so the same block recovers other Manchester and NRZ codes up to
  a quarter of the clock rate.

- **v2.3.** Three settings on the bit sampler, in one new register and all
  off after reset: a prescaler, a shift of the pins its bits show on, and
  the removal of stuff bits. No instruction changed. They came from
  writing a CAN node that acknowledges. Its receiver has to decode a frame
  as it arrives, on a clock recovered from the bus. v2.2's sampler
  recovers one, but only for bits of 16 clocks or less, where the host
  port cannot carry a frame's words: hence the prescaler. A transmitter
  needs the line as it is while the receiver needs the bits: hence the
  shift. And following stuff bits in firmware takes a run counter, a field
  counter, the last level and a scratch register at once, which is two
  more than a thread has: hence their removal, in the block that already
  does the line coding.

## Open questions for review

- **Fractional divider.** PIO's divider has 8 fractional bits; this one is
  an integer. UART baud rates that do not divide the clock still need the
  X/Y loop for fine timing.
- **IRQ / thread sync.** Not in v0. Full-duplex UART does not need it; SPI
  with separate RX and TX threads might.
