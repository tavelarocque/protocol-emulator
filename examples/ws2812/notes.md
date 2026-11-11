# Notes: WS2812 firmware for the protocol emulator

## What I read

1. `README.md`: task, rules, WS2812B timing (0: H 400 +-150 / L 850 +-150 ns;
   1: H 800 +-150 / L 450 +-150 ns; GRB, MSB first; latch >= 280 us low; idle
   low), 10 MHz core clock (100 ns/cycle), TX FIFO 4 x 16-bit, deliverables.
2. `isa.md` (whole file). Key points I took from it:
   - Every instruction is 1 cycle + delay field; side-set takes the top n bits
     of the 4-bit delay field, so with `.side_set 1` delays are 0..7.
   - Side-set is applied on execute cycles and stall cycles, not delay cycles
     (pin keeps its value through the delay anyway, it is a register).
   - Pin writes take effect at the end of the cycle.
   - `jmp y--` is taken if Y != 0 before the decrement, Y always decrements
     (so falling through leaves Y = 0xFFFF).
   - `jmp !osre`: OSR not empty, judged against `threshold`.
   - `pull` stalls on an empty TX FIFO and overwrites the OSR (marks full).
   - `out_msb_first` config: take bits from the top of the OSR.
   - Output register resets to all ones: P0 push-pull will be HIGH until the
     thread first writes it. That matters for "idle low before the first frame".
   - `set` immediate is only 5 bits (0..31), so long delays need nested loops.
3. `./pe_sim` top-level help and `./pe_sim run x.s -help` (flags: -config,
   -cycles, -inputs, -mode P=pp|od|in, -tx FILE). The config key names are not
   listed in the help; I assume they are the field names from isa.md's table.

## Design

Bit timing at 10 MHz, period 13 cycles:
- 1 bit: high 8 cycles (800 ns), low 5 cycles (500 ns)
- 0 bit: high 4 cycles (400 ns), low 9 cycles (900 ns)
All within +-50 ns of nominal, well inside +-150 ns.

Use side-set (1 pin, P0) so every instruction drives the line and the
bookkeeping (bit counter, OSR refill) can live inside the low phase with no
pin-write instructions. Classic PIO WS2812 structure (high phase, then a
data-dependent middle phase, then low phase), with the low phase doing:
`jmp y--` (more bits in this frame?), `jmp !osre` (need a refill?), and
`pull`/`out x,1`. The refill and no-refill paths are made the same length by
duplicating `out x,1`: the no-refill path is `out x,1 [2]` falling into the
high-phase instruction, the refill path is `pull; out x,1; jmp hi`.

Host word format:
- word 0 of a frame: number of bits in the frame (24 * LEDs), 0..65535
- then ceil(bits / 16) data words: the GRB byte stream, MSB first, packed
  two bytes per word (first byte in the high half). Unused low bits of the
  last word are ignored.
The chip then sends the latch on its own (about 310 us low). The latch code
is also the entry point, so at boot the line is driven low for ~310 us
before the first frame (cleans up the reset-high output register).

Latch: set x,11 / (set y,31 / jmp y-- [7] x32) / jmp x-- : 12 * 258 + 1 cycles.

## Program (ws2812.s, 16 instructions)

```
0  have:  out x,1        side 0 [2]   ; no-refill path: next bit, then fall into hi
1  hi:    jmp !x zero    side 1 [3]   ; high 4 cycles
2  one:   jmp low        side 1 [3]   ; 1: high 4 more
3  zero:  nop            side 0 [3]   ; 0: low
4  low:   jmp y-- cont   side 0       ; bits left in this frame?
5  latch: set x,11       side 0       ; START here (start=5): latch / boot idle
6  lx:    set y,31       side 0
7  ly:    jmp y-- ly     side 0 [7]
8         jmp x-- lx     side 0
9  frame: pull           side 0       ; count word
10        out y,16       side 0       ; Y = bit count, OSR now empty
11        jmp low        side 0
12 cont:  jmp !osre have side 0
13        pull           side 0       ; refill path
14        out x,1        side 0
15        jmp hi         side 0
```
I hand-checked every word of `pe_sim asm` output against the encoding table
(e.g. `jmp !x zero side 1 [3]` = 0x1643: op 000, delay field 1011 = side 1 +
delay 3, cond 001, addr 3). From the hex I inferred the operand numbering
pins=0, x=1, y=2 for out/set (isa.md does not give it).

Entering at `low` with Y = N sends exactly N bits (the `jmp y--` is taken N
times), so N = 0 (an empty frame) is just a latch.

## pe_sim invocations (all of them, in order)

1. `./pe_sim` (no args): subcommand list.
2. `./pe_sim run x.s -help`: run flags. Config keys not listed.
3. `./pe_sim asm ws2812.s`: assembled first try, 16 words; hand-checked.
4. `./pe_sim asm -help`: nothing new.
5. `run ... -config bogus=1`: "unknown key bogus", no list of valid keys.
   So I tried the isa.md field names next.
6. `run` with `start=5,sideset_base=0,sideset_count=1,threshold=16,
   out_msb_first=1 -mode 0=pp`, TX = 48, 0xAAAA, 0x5555, 0xFF00,
   4000 cycles. Keys accepted. Output: `pins 0 ff`, `pins 1 fe` (line
   high in cycle 0 from the reset value, low from cycle 1), first rising edge
   at 3106, then high 8 / low 5 (a 1), high 4 / low 9 (a 0), period 13.
   Matches the design. (TX file numbers: both decimal and 0x hex accepted.)
7. Same, 8000 cycles, tail: last falling edge at 3721, then low.
8. Same, piped to `wc -l`: 98 lines = 2 + 2*48, so exactly 48 bits.
9. `check.py 1 3 5` (frames of 1, 3, 4 LEDs): OK.
10. `check.py 2 6 4` (frames 0, 0, 0, 2, 3, 3 LEDs, i.e. empty frames): OK.
11. Negative test of the checker: host encoder with R and G swapped is caught
    (plus a synthetic-trace test of `decode` that needs no simulator).
12-19. `check.py` seeds 3..10, 5 frames of 0..40 LEDs each: all OK.
20. `check.py 11 3 300` (up to 300 LEDs): OK.
21. Edge cases in one run: 2730 LEDs (the maximum, 65520 bits), one LED of
    all ones, an empty frame, two LEDs of all zeros, (255,0,0): OK. Over the
    whole trace the only high widths are 1 (the cycle-0 reset pulse), 4 and 8
    cycles; the only low widths are 5, 9, 3105, 3110 and 6207 cycles
    (6207 = latch, empty frame, latch). So every refill boundary (every 16
    bits) has the same timing as the other bits.
22. `run` without `sideset_base/sideset_count`: the pin never changes from
    the reset `ff`. So `.side_set 1` in the source does not configure the
    thread; the host must set SIDESET too. My run_args.txt does.

That is 22 pe_sim invocations, 18 of them simulations (`run` with a program;
#5 aborted on the bad key).

`check.py` is my harness: it uses `host.encode`, runs pe_sim with
`run_args.txt`, rebuilds P0's level runs, and decodes like an LED with the
README limits (high 250-550 ns = 0, 650-950 ns = 1, low after each bit within
its limits, low >= 280 us ends a frame, anything else is an error), then
compares with the expected GRB bits. It allows the cycle-0 reset pulse only if
followed by >= 280 us low.

## Mistakes and slips

- Rules slip: in the call that ran #5 I also wrote a one-line throwaway file
  (`dummy`) into my session scratchpad directory, outside this directory. It
  was never used; I deleted it in the next command. Nothing else was read or
  written outside this directory.
- Design: I first thought of `mov y, osr` to take the count; rejected before
  running because `mov` does not mark the OSR empty, so the count word would
  then have been shifted out as pixel data. `out y, 16` with threshold 16
  empties it.
- First sketch (without side-set, set pins + out pins) had the refill path 2
  cycles longer than the normal one, putting some gaps at the edge of the
  tolerance. Replaced before writing code by the side-set version with the
  duplicated `out x,1` so both paths are exactly 13 cycles.
- Hand arithmetic: I predicted 3106 cycles from reset to the first rising
  edge's executing instruction; the sim shows the edge at 3106, i.e. `hi`
  executes in cycle 3105 (I had miscounted by one). Harmless, latch is
  >= 310.5 us either way.
- No bug was found in the firmware by simulation; it passed from the first
  run.

## Final summary

- Length: 16 instructions (of 64).
- Config (`run_args.txt`): `-config start=5,sideset_base=0,sideset_count=1,
  threshold=16,out_msb_first=1 -mode 0=pp`.
- Host word format, per frame: one word N = 24 * LEDs (0..65535, so up to
  2730 LEDs), then ceil(N/16) data words holding the G, R, B bytes of each LED
  in chain order, two bytes per word, first byte in bits 15..8, sent MSB
  first; an odd LED count leaves the last word's low byte as ignored padding.
  The chip adds the latch itself (low for ~310 us after the last bit) and runs
  the same latch at boot. Nothing is returned on the RX FIFO.
- Timing: 1 = 800 ns high / 500 ns low; 0 = 400 ns high / 900 ns low;
  latch >= 310.5 us.
- Known limitation: if the host cannot keep the TX FIFO fed, `pull` stalls
  with the line low and the LEDs would see an early latch (the README says to
  ignore this; at 1.3 us per bit a 16-bit word lasts 20.8 us).
- Unavoidable glitch: P0 is high during cycle 0 (100 ns) because the output
  register resets to all ones; the thread drives it low from cycle 1 and
  holds it low for 310 us before the first frame, which an LED treats as a
  reset.

### Confusing or wrong in isa.md

1. The pe_sim config key names are not documented anywhere I could read, and
   the unknown-key error does not list them. The isa.md field names happened
   to work.
2. `.side_set n` is described as "turns it on", but it only changes the
   assembler; the thread also needs `sideset_count` (and `sideset_base`) set
   by the host, or the side bits are silently read as delay (run #22).
3. The instruction descriptions were not updated for v1.4: `out` still says
   "least significant bit first" and `in` "shifts ... right" / "Bits arrive
   least significant bit first", while the config table says SHIFT can make
   both MSB first.
4. The numbering of `src`/`dst` values for `in`, `out`, `mov`, `set` is not
   given (I inferred pins=0, x=1, y=2 for out/set from the assembler).
5. The pin-level table's columns "Output register bit 0 / bit 1" read like
   bit indices; they mean the register bit's value being 0 or 1.
6. Resetting the output register to all ones means every push-pull pin is
   high at start until the firmware writes it. Good for UART, wrong for an
   idle-low protocol like WS2812, and firmware cannot avoid the first cycle.
   Worth stating explicitly next to push-pull.
7. Minor: the wait-timeout text says the counter loads T, counts down each
   stalled cycle and fires "when it is already 0", which reads like T + 1
   stalled cycles, but then says "at most T cycles". Not used here.
