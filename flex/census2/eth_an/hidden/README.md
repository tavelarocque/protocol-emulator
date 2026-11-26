# Hidden test: Ethernet auto-negotiation, fast link pulse transmitter (DSView decoder `eth_auto_negotiation`)

This folder is the examiner's side of round 2, Part A, for Ethernet
auto-negotiation (IEEE 802.3 clause 28), judged by DSView's decoder
`eth_auto_negotiation` (DSView folder `eth_an`). The programmer gets only
the kit (`../../kits/eth_an/`: `isa.md`, `pe_sim`, `TASK.md`) and never
sees this folder. No firmware for the chip was written for this test, not
even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal FLP transmitter as a waveform generator standing in for `pe_sim`, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the sheet's example, the decoder on the ideal waveform, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

There is no `PORT.diff`: the decoder runs under sigrok-cli 0.7.2 exactly
as fetched (below).

## Role chosen: transmitter

The chip is the transmit side of auto-negotiation for a 10BASE-T port:
it sends FLP bursts carrying the link code words its host gives it. This
is the part of auto-negotiation a small chip next to the magnetics really
does. The repository already runs 10BASE-T on this chip with TD+ on P0 and
TD- on P1 (push-pull, through resistors and the transformer), and sends
normal link pulses that way; FLP bursts are the same positive pulses,
placed to carry a word, and they are how such a port tells a switch what
it can do. The decoder reads one line, TX+, so it judges a transmitter.

Receiving the partner's bursts was left out on purpose. Arbitration
(matching the partner's word, setting Acknowledge, next pages) is host
logic, and the decoder cannot judge a receiver's output except by
decoding the stimulus; a BOTH task would also have one thread time its own
bursts and the partner's at once, which the protocol does not need from
the chip (the two pairs are independent).

## Clock, pins, timing

Clock 40 MHz, one cycle 25 ns, the clock the repository's own Ethernet
runs at. P0 TD+, P1 TD-, both push-pull; the judge requires exactly
`-mode 0=pp -mode 1=pp` and no other pin as an output. A pulse is P0 high
for 3 to 5 cycles (nominal 100 ns, clause 14's link pulse, 4 cycles).
Clause 28's figures (Table 28-1): clock pulses 125 us apart (111 to 139),
data pulse 62.5 us after its clock pulse (55.5 to 69.5), 17 clock pulses,
D0 first, bursts 16 ms apart start to start (8 to 24). The sheet keeps 8
to 24 ms for the bursts but holds every pulse to +-1 us (+-40 cycles) of
its nominal place counted from the burst's first rise, a subset of the
standard chosen to sit well inside the decoder's own windows: a data
pulse 60 to 70 us after its clock pulse, clock pulses 120 to 140 us apart
for a 0 (below). The sheet gives this reason in its timing paragraph. Both
pins low by cycle 100; TD- never moves after that. First burst between
1 ms and 16 ms of the run. `-cycles` is 960,000 x (words + 1), which leaves
at least 32 ms of silence after the latest last burst the sheet allows, so
a burst the firmware should not have sent would show.

## The host interface

One 16-bit word per FLP burst, the link code word itself, bit k = Dk.
Example in the sheet: 0x01E1, 0x01E1, 0x41E1 (advertise 10/100 half and
full duplex twice, then acknowledge). Nothing comes back. The sheet says
"The host sends only the words defined above. All line coding, framing
and timing must be done by the firmware." The clock pulses, the data pulse
placement, the pulse width, the bit order and the burst interval are all
the program's.

## The decoder, and the one adjustment the judge makes

Read from `pd.py` and confirmed by running it. On each rising edge it
measures the pulse width and the time since the last reference pulse:

- It counts a pulse (annotation `NLP`) only if it lasts **1 to 10 us**.
- 60 to 70 us after the reference: a 1, and the reference is cleared.
  120 to 140 us: a 0. Anything else: no bit; the pulse becomes the
  reference.
- Every 16 bits it prints the page (`base page:0x..` or `next page:0x..`,
  the label chosen by a small state machine on the acknowledge bits of
  successive different pages), 16 bit annotations `0x0`/`0x1`, and field
  descriptions.

A real FLP pulse lasts 100 ns, so on an honest capture the decoder counts
no pulse at all: it was written for captures at about 1 MHz, where a pulse
is one sample. So the judge does not hand it the per-cycle wire. It writes
a capture of P0 at 1 MHz in which a sample is high if P0 was high at any
time in that microsecond (what a logic analyser's glitch capture does).
That is the same fixed transformation for every hand-in, and it was in the
judge before any programmer started. The pulse width is then not the
decoder's to check, so the judge checks it directly (3 to 5 cycles).

Other properties found and allowed for:

- The decoder's first reference is sample 0, so a first pulse 60 to 70 or
  120 to 140 us into the run would be misread as a bit. The sheet's first
  burst comes at 1 ms or later.
- The 17th clock pulse matters to the decoder only when D15 is 0 (it ends
  that bit); the judge's own pulse count requires it always.
- With the sheet's +-1 us limit, data spacing on the capture is 61 to 65
  us and clock spacing 122 to 128 us, inside 60 to 70 and 120 to 140.

**No port.** `sigrok-cli -P eth_auto_negotiation --show` loads it and it
decodes the ideal waveform of every case on every seed. The `idn` channel
key and `tags` are accepted (tags shows empty); nothing was changed, so
`git -C decoders diff -- eth_auto_negotiation` is empty. (The judge runs
sigrok with `PYTHONDONTWRITEBYTECODE=1`, so it leaves no bytecode there.)

## What the judge checks

For each case it builds the TX words from the sheet's rule, runs
`RUN_DIR/pe_sim run RUN_DIR/eth_an.s -tx FILE -cycles N` plus
`run_args.txt` (one line, only `-config` and `-mode`, P0 and P1
push-pull, no other output), and requires:

- Waveform, from the printed pin changes: P0 and P1 low by cycle 100; P1
  never changes again; P0 low at the end; every pulse 3 to 5 cycles wide;
  pulses grouped into bursts (a quiet of more than 20,000 cycles splits
  them), one burst per word; in each burst exactly 17 + (number of 1 bits)
  pulses, each rising within +-40 cycles of its nominal place from the
  burst's first rise; first burst at cycle 40,000 to 640,000; bursts
  320,000 to 960,000 cycles apart start to start. Any extra pulse,
  glitch or tail makes an extra burst or a wrong count.
- Decoder, on the 1 MHz capture: the `data` row, exactly one page per
  word, values equal and in order, nothing extra (the base/next label is
  ignored: it is the decoder's guess from the sequence, not the line);
  the `bit` row equal to the words, D0 first; one `NLP` per pulse.
  A sigrok error is a failure.
- `RATE bytes=<2 per word> cycles=<first change of P0 or P1 to the last>`
  for the last passing case. The first change is the reset fall, so the
  span includes the wait before the first burst and the gaps; the burst
  interval the firmware chooses sets it.

Cases: seven fixed (0x0000; 0xFFFF; the sheet's three words; a next page
exchange 0x81E1, 0xC1E1, 0xA008, 0xE008, 0x0300; 0x5555, 0xAAAA; 0x0001,
0x8000; eight mixed words) and eight seeded random ones (1 to 3 or 1 to 8
random words).

## What the judge does not check

- Anything analog: the pulse shape and voltage of clause 14's template,
  the transformer, TD- as a separate line driver. The pins are what the
  chip drives into a resistor network.
- Receiving, arbitration, link_fail_inhibit and break_link timers, and
  NLPs: the host's or out of the task.
- What the firmware does with a slow host: the simulator refills the TX
  FIFO at once, so a burst is never late for want of a word.
- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must
  put the real simulator there.
- `run_args.txt` may set configuration constants (`clkdiv`, bases, shift
  direction, side-set); that is the chip's hardware, not the instruction
  set, and should be read when hand-ins are compared.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`), in about
four minutes.

- Interface: the sheet's example words and its "host sends only" sentence
  are in the sheet; N as stated.
- Example: the 22 rises the sheet lists for 0x01E1 equal the judge's
  `ideal_offsets` and the generator's rises, which are computed
  differently (33 positions walked against clock and data lists sorted);
  the two also agree on eight more words.
- Decoder: sigrok reads every word of the ideal waveform in all 15 cases
  on all 5 seeds.
- Waveforms: 34 waveforms x 5 seeds = 170 verdicts, all as expected. The
  9 that must pass (45 verdicts) do: ideal; every pulse +-40 cycles off
  (the limit); widths 3 and 5; bursts 8 ms and 24 ms apart; first burst
  at 1 ms and 16 ms; pins low at cycle 100. The 25 broken ones (125
  verdicts) all fail: one bit flipped, D15 first, pulses for 0s instead of
  1s, no 17th clock pulse, an 18th, one pulse 41 late, 41 early, clock
  pulses 5003 cycles apart (accumulating), data pulses 1.5 us late, widths
  2, 6 and 40, bursts 319,999 and 960,001 apart, first burst at 39,999
  and 640,001, P0 low at 101, P1 low at 101, P1 left high, a pulse on P1,
  a one-cycle glitch, a pulse after the last burst, P0 left high, a word
  dropped, a burst repeated. The decoder check alone catches the content
  faults (bit, order, inversion, missing or extra clock, glitch, tail,
  missing or extra burst); the timing and width faults are caught by the
  waveform check only, as intended.
- RATE: equals the generator's own figure on every seed (seed 1:
  `RATE bytes=2 cycles=280003`).
- Hand-in rules: 11 bad `run_args.txt` refused (`-tx`, `-cycles`,
  `-stimulus`, `-inputs`, ambiguous `-c`, two lines, a flag with no value,
  P1 not push-pull, P0 open-drain, P2 an output, pin 9); 2 good accepted.
- Real simulator: the kit's `pe_sim` with `idle: jmp idle` (drives no pin;
  not FLP firmware) accepts the command line and word file, and all 15
  cases fail cleanly on the waveform check, with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, and
comfortably. Everything is slow next to the clock: a pulse is 4 cycles,
pulse positions are 2500 cycles apart, bursts 640,000 at the nominal
16 ms, and the limit is +-40 cycles, so instruction counts barely matter
as long as they do not add up. A clock divider (for example 4, one tick
100 ns, so a pulse is one tick) turns 62.5 us into 625 ticks and 16 ms
into 160,000, which needs a loop inside a loop or a constant built in a
register, since `set` holds only 5 bits; the delay field and nested
`jmp x--` loops cover it. `out x, 1` least significant bit first gives D0
first straight from the word, and a branch on X chooses pulse or no pulse
in each data position with paths of equal length. The care needed is that
the 33 positions keep their places across the branch and the word fetch,
and that P1 is driven low once at the start (two-pin `set` or a separate
`set`) and never touched again.
