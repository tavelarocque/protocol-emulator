# Hidden judge, round two: ST7735 serial host

Kept from the firmware's author until the hand-in. The author's kit is
`../../kits2/st7735/` (isa.md, pe_sim, TASK.md). No firmware for the chip
was written for this test, not even as a check.

## Files

- `accept.py`: the acceptance test. `python3 accept.py RUN_DIR [seed]`,
  default seed 1. Prints one line per case, a RATE line, then
  `ACCEPT PASS` or `ACCEPT FAIL`; exit status 0 only when every case
  passes.
- `ideal.py`: an ideal ST7735 host waveform drawn in Python (not chip
  firmware), with 16 planted-fault variants. Also a stand-in for `pe_sim`.
- `validate.py`: checks the judge: the interface, every variant, the RATE
  line, the hand-in rules, and the real `pe_sim` with a program that does
  nothing.
- `selftest/`: the run directories `validate.py` builds, and
  `selftest/validation_output.txt`, its last output (seeds 1, 2, 3).

## Why there is a round two

In round one the task sheet let the programmer decide what the TX words
mean and hand in a `host.py` that produced them. That let the host work
out pin levels and the firmware merely play them back, which measures
nothing about the instruction set. In round two the task sheet fixes the
host interface and there is no `host.py`.

## The host interface, as the task sheet states it

One 16-bit word per byte on the wire, command and data bytes alike, in
order, transfer after transfer. Bits 7..0 are the byte. Bit 8 is 1 for a
command byte and 0 for a data byte. Bit 9 is 1 on the last byte of a
transfer (chip select must rise after it) and 0 otherwise. All other bits
are 0. The sheet's example: command 0x2A with data 0x00 0x7F, then command
0x29 with no data, are the words 0x012A, 0x0000, 0x027F, 0x0329.

The sheet says: "The host sends only the words defined above. All line
coding, framing and timing must be done by the firmware." The hand-in is
`st7735.s`, `run_args.txt` (one line, `-config` and `-mode` flags only)
and `notes.md`. Clock, pins, the display's rules, the timing table, the
cycle budget and the rules section are word for word those of round one.

## What accept.py does

The 14 cases and both judges (sigrok's `st7735` decoder and the direct
check of the pin changes) are round one's, unchanged, and
`../../hidden/st7735/README.md` describes them, with the table of limits
and where the numbers come from. Four things differ.

- The judge builds the TX words itself (`tx_words`), from the interface
  above. It never opens a `host.py`: one left in the run folder is ignored.
- `run_args.txt` must be one line holding only `-config` and `-mode`
  flags, each with a value. `-tx`, `-cycles`, `-inputs` and anything else
  fail every case. P0 to P3 must still be made push-pull there.
- After the case lines it prints, for the last case that passed,
  `RATE bytes=<bytes on the wire> cycles=<cycles from the first change of P0..P3 to the last>`.
  With all cases passing that is always the last case, "random 7", so two
  hand-ins judged with the same seed are compared on the same transfers.
  The span starts at the first change of any of the four lines, which is
  usually SCL being driven low before the first transfer, and ends at the
  last rise of CSX. P4 to P7 do not count. No case passed: no RATE line.
- An exception inside the judge is now caught and reported as a failed
  case. In round one it would have ended the run with a traceback.

## Validation (no chip firmware was written)

    python3 -B validate.py 1 2 3

Result: `VALIDATION OK`, nothing wrong (`selftest/validation_output.txt`).

The stand-in simulator (`ideal.py` under the name `pe_sim`) now receives
the judge's words and reads them back into transfers by the task sheet's
rules, in code written apart from the judge's `tx_words`. It stops with an
error if a word has a bit above bit 9 set, if bit 8 is not on exactly the
first word of each transfer, or if the last word does not end a transfer.
So the good variants pass only if the judge's words, the stand-in's
reading of the sheet, the judge's direct check and sigrok's decoder all
agree.

- Interface: `tx_words` gives exactly the words printed in the task
  sheet's example, and the sheet contains that text.
- Waveforms: 18 variants on 3 seeds, 54 verdicts, all as expected. `good`
  (every time at its minimum) and `good_relaxed` (slack, an uneven clock,
  noise while CSX is high and on P4 to P7) pass 14 of 14. The 16 broken
  ones all end in `ACCEPT FAIL`: a flipped bit, least significant bit
  first, data sent with D/CX low, an extra transfer, a missing byte, SCL
  high 25 ns, SCL low 25 ns, SDA changing with a rising edge, D/CX
  settling with an eighth rising edge, D/CX changing with the falling edge
  after an eighth bit, CSX high 25 ns between transfers, CSX pulsing high
  inside a transfer, CSX never returning high, CSX rising with the last
  falling edge of SCL, SCL not low before the first fall of CSX, and a
  correct waveform that is not finished in the budget. Which judge catches
  each is the same as in round one's table.
- RATE: for `good` the line equals the figure worked out from the ideal
  waveform's own list of changes, on every seed (seed 1:
  `RATE bytes=54 cycles=1745`).
- Hand-in rules: a `host.py` that would leave a marker file if loaded was
  put in a passing folder; the judge passed and no marker appeared. Five
  bad `run_args.txt` files (`-tx`, `-t`, `-cycles`, `-inputs`, two lines)
  were each refused, and one with an added `-config` was accepted.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin (not
  ST7735 firmware). The simulator accepted the command line and the word
  file, and all 14 cases failed cleanly with "sigrok decoded 0 bytes" and
  no RATE line.

## What is still not closed

- The judge runs `RUN_DIR/pe_sim`, whatever it is. A hand-in that replaced
  it with a script drawing the waveform would pass, exactly as the
  stand-in of the validation does. Whoever runs the judge must put the
  simulator into the run folder themselves.
- `run_args.txt` is the same for every case, so nothing that depends on
  the payload can be put there. It can still hold constants the host
  writes into the chip's configuration registers. That is the chip's own
  hardware, but it is not the instruction set.
- Bits 8 and 9 hand the firmware the D/CX level and the place where CSX
  rises. The firmware still has to drive both lines at the right moments,
  but it does not have to count bytes or know command codes. That is the
  interface the examiner chose, and it is the least a host can say.
- A slow host is never provoked: the simulator refills the FIFO at once.
- Everything in "What it does not check" of round one's README still
  holds.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, and
this is the easiest of the three. The budget is 200 cycles a byte against
a minimum of 32. `out_msb_first` takes bits from the top of the word, so
with the whole 16-bit word shifted out the two flags arrive before the
byte and the byte arrives most significant bit first, as the display wants
it. A flag shifted into X or Y becomes a branch, `set pins` can drive D/CX
and CSX, and side-set can make the clock. The one thing to get right is
the idle state: the output register resets to all ones, so SCL starts
high and has to be brought low before CSX first falls.
