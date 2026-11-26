# Hidden test: DCF77 receiver

The examiner's side of the census for sigrok's `dcf77` decoder. The
programmer gets only the kit (`../../kits/dcf77/`: `isa.md`, `pe_sim`,
`TASK.md`) and never sees this folder until the firmware is handed in. No
firmware for the chip was written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_rx.py` | an ideal DCF77 receiver in Python that reads a stimulus file and prints "rx" lines, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every result, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## The role, and why

RECEIVE. DCF77 is a broadcast time signal: the only thing a small chip does
with it in practice is decode the demodulated output of a receiver module
(a 77.5 kHz carrier is demodulated by the module, not the chip). Making
DCF77-like pulses to set radio clocks exists, but it is a niche. The
signal is one pin, so the 8-pin limit is no issue, and the line rate (one
bit a second, pulses of 100 and 200 ms) is far below what a 50 MHz clock
can follow: the protocol is not out of reach.

## Clock, pins and host words, as TASK.md states them

- Core clock 100 kHz, one cycle 10 us (1 ms = 100 cycles). Chosen for the
  simulator, not the chip: a run is up to about 250 s of signal, which is
  25 million cycles at 100 kHz (about 4 s of simulation) and would be 12.5
  billion at 50 MHz. With the 16-bit `clkdiv` the program would behave the
  same at a higher clock with a proportionally larger divider, so nothing
  is made easier by the choice beyond the simulator's run time.
- P0 is the input, high during a pulse. Nothing is driven; there are no TX
  words.
- RX words: one per pulse after the first minute marker, in order. Bit 0
  is the bit (long pulse = 1), bit 1 is 1 on the first pulse after a gap of
  1960 to 2040 ms (bit 0 of a minute), bits 15..2 are 0. The sheet's
  example (a run joined at second 57) gives 0x0002, 0x0001, 0x0000, 0x0000.
- Each word is due between its pulse's rising edge and 500 ms after it.
- The sheet says: "The host sends only the words defined above. All line
  coding, framing and timing must be done by the firmware." Here that
  means: measuring the pulses, the 0/1 decision, finding the markers and
  staying quiet until the first one.

Payload only: the words carry the bits and the minute boundary, nothing
else. The flag in bit 1 is framing the firmware has to find from the gap,
the same thing sigrok's decoder does when it numbers a bit 0. Bit numbers
are not asked for: this core can only count down, and asking for an
up-count would test that rather than DCF77. The host counts the bits.

## What the judge does

For each of 15 cases (seven fixed, eight from the seed) it:

1. Builds the signal a module would give: real DCF77 minute frames (start
   bit 0, 14 random weather bits, call bit, summer time bits A1, Z1, Z2,
   leap second bit 0, bit 20 = 1, minute, hour, day, weekday, month, year
   in BCD with the three even parity bits), each frame encoding the minute
   that follows it. The run joins part way through a minute (bit 0 to 56,
   so at least three pulses come before the first marker), then 1 to 3
   whole minutes, then 1 to 10 pulses of a minute the run does not finish.
   Every rising edge is up to 20 ms from an exact one-second grid of random
   phase; a 0 lasts 70 to 130 ms, a 1 170 to 230 ms. Some runs start with
   P0 high in a pulse cut short; some have a pulse missed in the middle of a
   minute (bit 1 to 57), which leaves a gap the sheet says to treat as a
   marker.
2. Writes the same signal as a VCD (one sample per cycle, 100 kHz) and runs
   `sigrok-cli -P dcf77:data=P0 -A dcf77`. It requires sigrok's numbered
   bits ("Bit n: v") to be exactly the expected words, in order, each at
   the same sample as its pulse's rising edge, with number 0 exactly where
   bit 1 of the word is set; and for every whole minute, the minute, hour,
   day, weekday, month and year the test put in, minute and hour parity
   OK, start-of-minute and start-of-time OK, and no warning. So the input
   is a real instance of DCF77 as an independent decoder reads it. (One
   exception: sigrok clears its list of date bits only at bit 58, so after
   a missed pulse past bit 36 its date parity for the next minute also
   counts bits of the broken one. Date parity is not required for the
   minute after a broken minute.)
3. Runs `RUN_DIR/pe_sim run RUN_DIR/dcf77.s -stimulus FILE -cycles N` and
   the flags of `run_args.txt`. N is the last rising edge plus 1500 ms.
4. Requires the "rx" words to equal the expected words, in order, with
   nothing extra and none missing, and each pushed no earlier than its
   pulse's rising edge and no later than 500 ms after it.

The fixed cases: joined at bit 50; P0 high at the start (a pulse cut short);
a whole minute before the first marker (which must not be reported); the
shortest and longest pulses with edges 20 ms off both ways, alternating;
three minutes across a new year (23:59, 00:00, 00:01, with day, month and
year changing); a missed pulse at bit 30 of the first whole minute; ten
pulses after the last whole minute.

`run_args.txt` must be one line (empty is allowed) of `-config` and
`-mode` flags with values; `-stimulus`, `-inputs`, `-tx`, `-cycles` or
anything else is a setup failure. Flag names may be shortened as `pe_sim`
allows. After the case lines it prints, for the last case that passed,
`RATE bytes=<payload bits / 8, rounded up> cycles=<cycles from P0's first
change to its last in the stimulus>`. The payload here is bits, one word
each, and the rate is the protocol's own (one bit a second), so the RATE
line only says how long the last case was; it measures nothing about the
firmware. A simulator error or an exception inside the judge is a failure,
never a pass.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`, about five
minutes).

The stand-in simulator (`ideal_rx.py` behind a wrapper named `pe_sim`)
reads the judge's stimulus file and decodes it from the edges alone, in
code written apart from the judge: it never sees the bits the judge put in.
So a correct result passes only if the judge's signal, the judge's expected
words, the stand-in's reading of the sheet and sigrok's decoder all agree.

- Interface: `accept.word` gives the words of the sheet's example, and the
  sheet prints them and the host-words sentence.
- Results: 15 results on 5 seeds, 75 verdicts, all as expected. The three
  that must pass do: words 1 cycle after each falling edge (the ideal);
  every word at its rising edge (the earliest allowed); every word 500 ms
  after its rising edge (the latest allowed). The 12 broken ones all fail:
  one word 501 ms late; one bit inverted; the first-of-minute flag missing
  once; the flag also on the next pulse; the pulses before the first
  marker reported; a 1 only from 200 ms; a 1 from 120 ms; minutes found by
  counting 59 pulses instead of by the gap (fails the missed-pulse cases
  only, 2 or 3 of 15, as it should); the last word dropped; one word extra;
  one word twice; two neighbouring words swapped. No verdict came from the
  stimulus check: sigrok agreed with the signal in every case. Separately,
  the stimulus check alone passed on every case of seeds 1 to 59.
- RATE: for the ideal result the line equals the figure worked out from the
  last case's own stimulus, on every seed (seed 1: `RATE bytes=16
  cycles=14123695`).
- Hand-in rules: three good `run_args.txt` files (with `-config`, empty,
  `-mo` shortened) were accepted, eight bad ones (`-stimulus`, `-s`,
  `-cycles`, `-inputs`, `-tx`, an ambiguous `-c`, two lines, a flag with no
  value) were each refused as a setup failure.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself (not DCF77 firmware). It
  accepted the command line and the stimulus file, and all 15 cases failed
  cleanly ("0 words pushed"), with no RATE line.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the real simulator into the run folder themselves.
- `run_args.txt` may set configuration registers (`clkdiv`, `timeout`,
  `timeout_vector` and so on). Those are the chip's hardware, not the
  instruction set; read `notes.md` and the line when hand-ins are compared.
- A clean signal only: no glitches or noise spikes, no leap second (a
  61-second minute), no outage longer than one missed pulse, no gaps other
  than about 1 s and about 2 s, no drift of the grid. A real module gives
  all of those; the sheet promises none of them, so a firmware that
  breaks on them still passes.
- The bit decision is tested only on the ranges the sheet gives (70 to
  130 ms, 170 to 230 ms); any threshold between 130 and 170 ms passes.
- Pins the firmware drives are not looked at.
- The host is never slow: the simulator pops the RX FIFO every cycle.
- The words are not checked against the time content beyond the bits:
  parity and field decoding are the host's.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, and
comfortably. The work is two measurements and a little state. A pulse's
length against a threshold near 150 ms (15000 cycles at 100 kHz, which fits
both a 16-bit X or Y count-down and the 16-bit wait timeout), and the time
since the last rising edge against a threshold near 1.5 s (150000 cycles,
which does not fit 16 bits; `clkdiv` set to, say, 100 makes a tick 1 ms and
every number small, or the programmer nests two loops). The state is
whether a marker has been seen yet and whether the current pulse follows a
gap, which can live in the flow of control or in Y. The word is one of
four values, built with `set` and moved to the ISR before a `push`. The
awkward points are that one `timeout` value and one `timeout_vector` serve
every timed wait, so the two measurements cannot both be timed waits with
different budgets unless the program counts ticks itself, and that a
counting loop has to sample the pin each pass to see the edge. Program size
should be a few tens of instructions, well inside one 64-word page.
