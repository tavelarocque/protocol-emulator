# Hidden test, round two: Miller encoding transmitter

This folder is the examiner's side of the second round. The programmer gets
only the kit (`../../kits2/miller/`: `isa.md`, `pe_sim`, `TASK.md`) and
never sees this folder until the firmware is handed in. No firmware for the
chip was written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal Miller transmitter as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## Why there is a round two

In round one the task sheet let the programmer decide what the TX words
mean and hand in a `host.py` that produced them. Programmers moved the
Miller coding into `host.py` and handed in a program that only played back
pin levels, which says nothing about the instruction set. In round two the
task sheet fixes the host interface and there is no `host.py`.

## The host interface, as the task sheet states it

One 16-bit word per payload byte, in order, message after message. Bits
7..0 are the byte. Bit 8 is 1 on the last byte of a message and 0
otherwise. All other bits are 0. The sheet's example: the messages 0x16
and 0xDE 0xAD 0xBE are the words 0x0116, 0x00DE, 0x00AD, 0x01BE.

The sheet says: "The host sends only the words defined above. All line
coding, framing and timing must be done by the firmware." The start bit,
the end bit, every transition and the gap between messages now have to
come from the program. The hand-in is `miller.s`, `run_args.txt` (one
line, `-config` and `-mode` flags only) and `notes.md`. Clock, pin, bit
rate, framing, timing limits and the rules section are word for word those
of round one.

## What the judge does

The cases and the two checks are round one's, unchanged: seven fixed cases
and eight seeded random ones, each judged by sigrok's `miller` decoder and
by the direct waveform check. `../../hidden/miller/README.md` describes
both, and what sigrok's decoder does. Four things differ.

- The judge builds the TX words itself (`tx_words`), from the interface
  above. It never opens a `host.py`: one left in the run folder is ignored.
- `run_args.txt` must be one line holding only `-config` and `-mode`
  flags, each with a value. `-tx`, `-cycles`, `-inputs` and anything else
  are a setup failure. Flag names may be shortened as `pe_sim` allows.
- After the case lines it prints, for the last case that passed,
  `RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>`.
  With all cases passing that is always the last case, "random 7", so two
  hand-ins judged with the same seed are compared on the same messages.
  The span includes the gaps the firmware leaves between messages, so a
  firmware with long gaps shows as slower. No case passed: no RATE line.
- The final line is still `ACCEPT PASS` or `ACCEPT FAIL`, and the RATE
  line, when there is one, is the line before it.

A simulator error or an exception inside the judge is a failure, never a
pass.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

The stand-in simulator (`ideal_wave.py` behind a wrapper named `pe_sim`)
now receives the judge's words and reads them back into messages by the
task sheet's rules, in code written apart from the judge's `tx_words`. It
exits with an error if a word has a bit above bit 8 set or the last word
does not end a message. So the ideal waveform passes only if the judge's
words, the stand-in's reading of the sheet, the judge's own idea of the
ideal waveform and sigrok's decoder all agree.

- Interface: `tx_words` gives exactly the words printed in the task
  sheet's example, and the sheet contains that text.
- Waveforms: 21 waveforms on 5 seeds, 105 verdicts, all as expected. The
  four that must pass do (ideal; every transition 2 cycles off, the
  limit; gaps of exactly 20000 cycles; first start at cycle 20000). The 17
  broken ones all fail: a flipped data bit, most significant bit first, one
  transition 3 cycles late, one 3 cycles early, bits of 101 cycles, bits
  of 200 cycles, gaps of 399, 150 and 20001 cycles, a first start at cycle
  20001, P0 driven low before the first message, no end bit, no start bit,
  a stray transition after the last message, a one-cycle pulse, the last
  message missing, the last message sent twice. Which of the two checks
  objects to each is the same as in round one.
- RATE: for the ideal waveform the line equals the figure worked out from
  the generator's own transition list, on every seed (seed 1:
  `RATE bytes=82 cycles=68100`).
- Hand-in rules: a `host.py` that would leave a marker file if loaded was
  put in a passing folder; the judge passed and no marker appeared. Seven
  bad `run_args.txt` files (`-tx`, `-t`, `-cycles`, `-inputs`, an
  ambiguous `-c`, two lines, a flag with no value) were each refused as a
  setup failure, and two good ones were accepted.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin. It is
  not Miller firmware. The simulator accepted the command line and the
  word file, and all 15 cases failed cleanly ("0 separate bursts of
  transitions"), with no RATE line.

## What is still not closed

- The judge runs `RUN_DIR/pe_sim`, whatever it is. A hand-in that replaced
  it with a script drawing the waveform would pass, exactly as the
  stand-in of the self-test does. Whoever runs the judge must put the
  simulator into the run folder themselves.
- `run_args.txt` is the same for every case, so nothing that depends on
  the payload can be put there. It can still hold constants the host
  writes into the chip's configuration registers (`clkdiv`, `timeout`,
  `threshold`, the CRC register's settings). That is the chip's own
  hardware, but it is not the instruction set, so `notes.md` and the
  configuration line should be read when a hand-in is compared.
- Bit 8 tells the firmware which byte is the last. It still has to make
  the end bit and the gap, but it does not have to count bytes.
- A slow host is never provoked: the simulator refills the FIFO at once.
- Everything in "What the judge does not check" of round one's README
  still holds, except its first point, which was the hole this round
  closes.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes. A bit is
100 cycles and a half bit 50, which is more than the 4-bit delay field
holds, but `clkdiv` stretches every instruction alike, so with a divider
that divides 50 a half bit is a few ticks and every edge stays on an exact
grid, well inside the +-2 cycle limit on place. The awkward part is that
no instruction inverts a pin and Miller code is a code of toggles. The
level therefore has to live either in the control flow (the same code
twice, once for each level) or in the low bit of a counter register, and
the previous bit has to live in the control flow too, because a thread has
only X and Y to test and one of them is needed for the bit being sent. The
256-word memory has room for that. Fetching the next word must cost the
same number of ticks on every path, which the programmer has to count.
