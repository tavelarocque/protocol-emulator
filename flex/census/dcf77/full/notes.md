# Notes: DCF77 receiver on the protocol emulator

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `pe_sim run x.s -help` and `pe_sim -help` (flag list for `run`, subcommand list).

Nothing outside this folder was opened. One thing to report: my very first
command printed TASK.md and isa.md with `cat`, and the tool harness saved that
long output to a file outside this folder on its own. I did not open that
file; I re-read TASK.md and isa.md with the file reader from this folder
instead.

## Design

Clock: 100 kHz core. I set `clkdiv=100`, so the thread ticks once per ms. That
makes all delays and the wait timeout count in milliseconds, and lets the
timeout register (max 65535) cover the 1.35 s budget I need. Edge detection is
quantised to 1 ms (plus the 2-cycle synchroniser), far inside every margin.

Key observation: the low time after a pulse (fall to next rise) is
730..970 ms between neighbouring seconds (960..1040 ms rise-to-rise minus a
70..230 ms pulse), and 1730..1970 ms across a 2 s gap. A threshold of 1350 ms
separates them with about 380 ms margin on each side. So the gap detector is
a single `wait 1 pin 0 timeout` with `timeout=1350`: if the next rise does
not come in time, the core jumps to `timeout_vector`, which is the "gap"
code. In the reporting loop the timed wait may start a little after the fall
(for a short pulse it starts at about 150 ms after the rise, when the pulse
has already ended), which only shortens the measured low time; normal still
reads at most about 890 ms and gaps at least about 1730 ms.

Bit decision: about 149 ms after the detected rise, P0 is read with
`in pins, 1`. A 0 pulse has ended by 130 ms, a 1 pulse lasts at least
170 ms, so still-high means 1. The word is pushed right then, so every word
is pushed about 151 ms after its rise (limit 500 ms).

The word: with `in_msb_first=1` the ISR shifts left and new bits enter at
the bottom. I shift in Y first (gap flag, 0 or 1) and then the pin bit, then
`push`, giving `gap<<1 | bit`, bits 15..2 zero.

State is held in the program counter:

- Phase A (addresses 0..4): wait for P0 low (this skips a pulse cut short at
  reset, and the synchroniser's reset value of 1), wait for a rise, then loop
  "wait fall, timed wait rise". Nothing is pushed. The only way out is a
  timeout, that is, the first gap.
- Phase B (address 5 onward, entered only through the timeout vector):
  `gap:` waits (untimed) for the rise of bit 0, sets Y=1, then `bit:` delays,
  shifts Y and the pin, pushes, clears Y, waits for the fall, timed-waits
  for the next rise, and loops to `bit`. A timeout jumps to `gap` again, so
  every pulse after a 2 s gap (minute marker or missed pulse) is flagged and
  the numbering is left to the host, as asked. Pulses are never counted.

After the last pulse the timed wait expires and `gap` waits forever for a
rise that never comes, so no extra word is pushed.

If the first rise comes in the first two cycles, the synchroniser's reset
value of 1 hides it and phase A starts on the second pulse instead. That is
harmless: at least three pulses come before the first marker and phase A
only needs the last one before the gap.

`run_args.txt`:
`-config clkdiv=100,timeout=1350,timeout_vector=5,in_base=0,in_msb_first=1`
(`timeout_vector=5` is the address of `gap:`; checked in the `asm` listing.)
P0 stays an input, the default, so no `-mode` flag.

Delay: `set x, 28` then `dly: jmp x-- dly [4]` is 29 iterations of 5 ticks,
145 ticks. Counting the instructions around it, `in pins, 1` executes 149
ticks after the wait that saw the rise, on both paths (gap path:
wait, set y, set x; normal path: wait, jmp bit, set x).

## Tests

`test_dcf77.py` generates random runs following TASK.md (random join point
with at least 3 pulses before the first marker, 1..3 whole minutes, 1..10
tail pulses, random bits, widths 70..130 / 170..230 ms, rise jitter within
20 ms of the grid while keeping neighbouring rises 960..1040 or
1960..2040 ms apart, occasional missed mid-minute pulses, optional pulse cut
short at cycle 0, first rise within the first second), computes the expected
words, runs `pe_sim` with `run_args.txt`, and checks every word, the count
and that each push is within [rise, rise + 50000 cycles]. The `extreme` mode
picks range endpoints much of the time. `edge_dcf77.py` adds three hand-made
runs: first rise at cycle 1 and cycle 2, exact boundary widths (7000, 13000,
17000, 23000) and intervals (96000, 104000, 196000, 204000), a missed pulse
as the first gap, a 23000-cycle pulse cut short at reset.

## pe_sim runs (numbered)

1. `pe_sim run x.s -help`: printed the run flags (config field names, -mode,
   -stimulus, -cycles, -tx, -inputs).
2. `pe_sim -help`: subcommands asm, run, version, help.
3. `pe_sim asm dcf77.s`: 16 words; `gap:` is at address 5. Decoded the words
   by hand against the encoding table; they match what I meant (for example
   `jmp x-- dly [4]` = 0x0888, `wait 1 pin 0 timeout` = 0x2110).
4. test_dcf77.py seed 1, one run, 23.5 M cycles: 174 words expected, 174
   got, all correct, worst latency 15100 cycles (151 ms). PASS.
5. Same stimulus run directly, first lines: `pins 0 ff` then `rx 5298100 3`
   etc. Confirms the output format and that the first word comes after the
   first marker. (The `rx` word radix is not stated in isa.md; values here are
   0..3 so it does not matter.)
6. Same stimulus again, counting words by value: 85 x 0, 80 x 1, 4 x 2, 5 x 3
   (the test bits are random, so bit 0 of a minute is sometimes 1).
7-21. test_dcf77.py seed 2, 15 random runs, 6.8 M to 22.5 M cycles, 59 to
   177 words each: all PASS, worst latency 15098 to 15101 cycles.
22-36. test_dcf77.py seed 3, 15 runs in extreme mode: all PASS, worst
   latency 15093 to 15101 cycles.
37-39. edge_dcf77.py, three hand-made runs (70, 67 and 60 words): all PASS,
   worst latency about 15100 cycles.

Total: 39 pe_sim invocations (under the budget of about 80).

## Mistakes found

None showed up in testing; the first version of the program passed every
run. In the test generator I rewrote the cut-short-pulse logic once before
the first run (it could have put a pulse end too close to the first rise);
that was a test bug, not a firmware one.

## Program length

16 instructions (addresses 0..15).

## Confusing or possibly wrong in isa.md

- `in` without `in_msb_first`: it says the ISR "shifts right" and that bits
  arrive LSB first, but not where a new bit enters, nor exactly how a
  partly filled ISR is "right-justified" on `push`. I sidestepped it with
  `in_msb_first`, whose description ("shift left, new bits at the bottom")
  is unambiguous.
- The `wait` section says the timeout counts "cycles", while the
  configuration table says that with `clkdiv` above 1 delays and wait
  timeouts count in ticks. The simulator counts ticks (a 1350-cycle timeout
  would have flagged every pulse as a gap, and it did not). The `wait`
  section could say "ticks".
- The register widths of `clkdiv` and `timeout_vector` are not given.
  `clkdiv=100` was accepted and worked.
- `timeout_vector` must be given as a number in `-config`, so `run_args.txt`
  depends on the program's layout (address 5 here); nothing in the
  assembler exports a label's address except reading the `asm` listing.
- The `pe_sim run` output section does not say whether the word in
  `rx CYCLE WORD` is hex or decimal.
- Not wrong but worth noting: the synchroniser reads 1 for the first two
  cycles after reset, so firmware that waits for an edge right at reset must
  first wait for low. isa.md documents this clearly.
