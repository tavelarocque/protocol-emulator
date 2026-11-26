# Hidden test: 7-segment display driver (`seven_segment`)

This folder is the examiner's side of the census entry for sigrok's
`seven_segment` decoder. The programmer gets only the kit
(`../../kits/seven_segment/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees
this folder until the firmware is handed in. No firmware for the chip was
written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal display driver as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## Role, and why

TRANSMIT. A 7-segment display is a passive output: a host chip drives its
segment lines and nothing comes back. sigrok's decoder reads seven segment
lines and an optional decimal point, so the task uses all eight pins: P0 to
P6 are segments a to g, P7 is dp, all push-pull. The display is
common-anode (a segment is lit while its pin is low), which is the
decoder's `polarity=common-anode` option and also means the chip's reset
state, all pins high, is a dark display. Core clock 10 MHz, one cycle 100 ns.

## The host interface, as the task sheet states it

One 16-bit word per character, in order. Bits 3..0 the hexadecimal digit,
bit 4 the decimal point, bit 5 blank (bits 3..0 then 0), bit 6 set on the
last word of the run, bits 15..7 zero. The sheet's examples: "3.14" is
0x0013, 0x0001, 0x0044; "A", blank, "b" is 0x000A, 0x0020, 0x004B. The
sheet says: "The host sends only the words defined above. All line coding,
framing and timing must be done by the firmware." So the firmware must turn
a 4-bit digit into the right segment pattern (the sheet gives the decoder's
table of lit segments, the public standard one), invert it for
common-anode, add the point, and time it. Bit 6 exists because the chip has
no way to see that the TX FIFO has run dry, and the display must go dark
after the last character.

## What the judge does

For each case it builds the TX words itself, runs `RUN_DIR/pe_sim run
RUN_DIR/seven_segment.s -tx FILE -cycles N` plus `run_args.txt`, with N =
20000 + 1000 per word + 5000, and applies two checks.

- **Decoder.** The eight pins' changes become a VCD (one sample per cycle,
  channels P0..P7) and sigrok-cli runs `seven_segment` with
  `polarity=common-anode`, a..g on P0..P6 and dp on P7. The decoder writes
  one annotation for each stretch of a recognised pattern that ends with a
  change. The judge works out, from the words alone, the stretches the
  display should show (the blank before the first character, then each run
  of equal characters merged, then the final blank, which is never
  annotated because nothing changes after it) and requires the decoded
  texts to equal them exactly, in order, nothing extra. It also requires
  each stretch other than the first to last its number of 1000-cycle slots,
  +-4 cycles. Any pattern that is not a hex digit or blank vanishes from
  the decoder's output, which makes the texts differ.
- **Waveform**, from the pin changes, the limits the decoder does not
  hold: all pins high at cycle 0 and until the first change; the first
  change (T0) by cycle 20000; exactly one change at T0 and one at each slot
  boundary T0 + 1000k where the character differs from the one before (the
  last followed by blank), each within +-2 cycles of its place counted from
  T0, and no other change (which catches a change of character split over
  two cycles, a glitch between equal characters, and anything after the
  end); the last level all high (blank).

The judge does not look at the segment patterns itself: what each pattern
means is left to sigrok's decoder. The waveform check only needs to know
whether two neighbouring words show the same thing, which follows from the
words.

`run_args.txt` must be one line of `-config` and `-mode` flags only, each
with a value, and must make all eight pins push-pull: the simulator prints
the output register whatever the pin modes, so without this check a
hand-in could pass with pins left as inputs. Cases: nine fixed (the sheet's
example, all sixteen digits, all sixteen with point, one character, a
repeated digit, only the point changing, blanks with and without point and
a plain blank last, a blank with point first, 64 words) and eight seeded
random runs (1 to 12 or 1 to 64 words, a quarter repeats, about one in
eight blanks, points at random, never a plain blank first). After the case
lines it prints `RATE bytes=<characters> cycles=<first pin change to last>`
for the last passing case. The rate is fixed by the sheet (1000 cycles a
character), so RATE only shows whether the firmware kept to it; a plain
blank at the end merges with the final blank and shortens the span by one
slot.

A simulator error or an exception inside the judge is a failure, never a
pass.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- Interface: `tx_words` gives exactly the words printed in both of the
  sheet's examples, and the sheet contains that text. Every case of every
  seed keeps to the sheet's limits.
- Waveforms: 19 waveforms on 5 seeds, 95 verdicts, all as expected. The
  stand-in reads the judge's words back by the sheet's rules in its own code
  (and refuses words with stray bits, a misplaced last flag, or a plain
  blank first), and draws the pins from its own segment table, so the ideal
  passes only if the judge's words, the stand-in's reading of the sheet,
  the sheet's segment table and sigrok's decoder all agree.
  - Must pass, and do: ideal; every change 2 cycles off (the limit); first
    character at cycle 20000.
  - Must fail, and do (16): one digit with a bit flipped; 7 drawn with
    segment f; common-cathode levels; decimal point never lit; one change 3
    cycles late; one 3 cycles early; slots of 1001 cycles; first character
    at cycle 20001; dp changing one cycle after a..g; the pins changing in
    two halves a cycle apart; a one-cycle blank between equal characters;
    no blank after the last character; the display lit before the first
    character; the last character dropped; the last character shown twice;
    a stray character after the end. Wrong content is caught by the
    decoder check (7 with f by it alone), timing by the waveform check
    (late3, early3, start20001 by it alone), the rest by both.
- RATE: for the ideal waveform the line equals the figure from the
  generator's own change list on every seed (seed 1: `RATE bytes=40
  cycles=39000`).
- Hand-in rules: thirteen `run_args.txt` files; the two good ones are
  accepted, and `-tx`, `-t`, `-cycles`, `-inputs`, `-stimulus`, an
  ambiguous `-c`, two lines, a flag with no value, P7 open-drain, P3
  missing, and P2 set back to input are each refused as a setup failure.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin (not
  display firmware). It accepted the command line, the eight `-mode` flags
  and the word file, and all 17 cases failed cleanly ("the pins never
  change"), with no RATE line.

## What is not checked

- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs the judge
  must put the real simulator into the run folder.
- `run_args.txt` may hold configuration constants (`clkdiv`, `out_count`,
  `threshold` and so on). That is the chip's hardware, not the instruction
  set; read the configuration line when comparing hand-ins.
- Segment patterns outside the decoder's table are judged only by their
  absence from its output; the judge has no table of its own.
- A slow host is never provoked: the simulator refills the FIFO at once.
- Real displays care about brightness, multiplexing and refresh, none of
  which a single static digit has; the 100 us slot is the sheet's own
  timing rule, not one from a display's datasheet.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, with
moderate effort. The chip has no table lookup and no instruction that
inverts or masks, so the 16 patterns must come from the control flow: a
four-level branch tree on the digit's bits (each bit shifted into X and
tested), and at each leaf an 8-bit pattern assembled from 5-bit `set`
immediates into the ISR and written to all eight pins at once with one
`mov pins` (out_count 8), which also makes every change of character a
single change. Every path through the tree must cost the same, and the
1000-cycle slot is a counted loop or `clkdiv`. Sixteen leaves of a few
words each plus the dp and blank branches is likely more than one 64-word
page, so the programmer will probably meet `set page`. Repeats need no
special care, since writing the same value changes no pin.
