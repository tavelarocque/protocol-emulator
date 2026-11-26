# Flexibility census: results

The rules for this census were fixed in [`PREREG.md`](PREREG.md) and pushed before the order was drawn. This file reports what happened under those rules, including every place where the run did not follow them exactly. The evidence for each line is in [`census/`](census/): every task sheet, every hidden test, every hand-in with its programmer's own notes, and the scripts used to check them.

## In one paragraph

Twenty protocols were drawn at random from sigrok's decoder list, a list this project did not write. Two of them could not be attempted at all: they need a parallel bus of 11 and 14 lines, and the chip has 8 protocol pins. Each of the other 18 was handed to a fresh AI agent that had never seen this project, with nothing but a task sheet, the instruction-set document and the simulator. All 18 first hand-ins passed a hidden test built around sigrok's own decoder for that protocol. The prediction, written before the draw, was 12 to 16 of 20. Then the first 8 passes were attempted again on two cut-down chips, one without the per-instruction delay field and one without side-set, two new programmers per chip, plus one more on the full chip. All 40 of those passed too. Removing a feature never made a protocol impossible. It sometimes made the program twice as long, and in one protocol it made the line 31 to 64 percent slower.

## The draw

The order comes from drand, a public randomness beacon, as `PREREG.md` fixes it: round 6674006 of the default mainnet chain, the first round at or after 2026-11-26 00:00 UTC. Its randomness is `f8c9bf93e8dfd97013298435f853477a0bfd529ed777bfc8b669ebbf0f19c838`. It was read from two independent mirrors, which agreed, and the SHA-256 of the round's signature equals that randomness, as drand's scheme requires. Each name was hashed together with the randomness and the names were sorted by the hash. The full record, with every hash prefix, is in [`census/ORDER.md`](census/ORDER.md).

When the draw was made, every kit held the same `isa.md` as `docs/isa.md` on `main` at 0aa4814 (SHA-256 `f2f860f2...`) and the same simulator (SHA-256 `82b00ea2...`). [`census/TASK-hashes.txt`](census/TASK-hashes.txt) holds the hash of every task sheet. Before each hand-in was judged, its folder was checked against these hashes, and none had changed.

## The census

| # | Protocol | Kind | Clock | Result | Length | Words | Runs | Bytes / cycles |
|---|---|---|---|---|---|---|---|---|
| 1 | ac97 | both | 50 MHz | pass | 56 | 56 | 18 | 8 / 638 |
| 2 | ook | sends | 1 MHz | pass | 33 | 33 | 21 | 16 / 109900 |
| 3 | aud | receives | 50 MHz | pass | 63 | 63 | 23 | 104 / 17025 |
| 4 | rc_encode | sends | 10 MHz | pass | 29 | 29 | 6 | 9 / 640800 |
| 5 | lpc | both | 50 MHz | pass | 29 | 29 | 36 | 3 / 1590 |
| 6 | avr_pdi | both | 50 MHz | pass | 52 | 52 | 25 | 12 / 21775 |
| 7 | dsi | sends | 10 MHz | pass | 17 | 17 | 17 | 1 / 289732 |
| 8 | maple_bus | sends | 50 MHz | pass | 62 | 62 | 18 | 208 / 38330 |
| 9 | em4305 | sends | 10 MHz | pass | 122 | 122 | 42 | 4 / 159240 |
| 10 | seven_segment | sends | 10 MHz | pass | 90 | 96 | 20 | 40 / 39000 |
| 11 | iec | both | 1 MHz | pass | 62 | 62 | 39 | 7 / 19111 |
| 12 | flexray | sends | 50 MHz | pass | 64 | 64 | 13 | 68 / 4316 |
| 13 | usb_power_delivery | sends | 20 MHz | pass | 196 | 234 | 27 | 84 / 91270 |
| 14 | t55xx | sends | 10 MHz | pass | 53 | 53 | 18 | 16 / 667960 |
| 15 | dcf77 | receives | 100 kHz | pass | 16 | 16 | 39 | 16 / 14123695 |
| 16 | mcs48 | | | out of reach (14 lines) | | | | |
| 17 | swim | both | 40 MHz | pass | 176 | 191 | 12 | 14 / 282870 |
| 18 | z80 | | | out of reach (11 lines) | | | | |
| 19 | sda2506 | both | 10 MHz | pass | 46 | 46 | 12 | 6 / 828050 |
| 20 | sdcard_sd | both | 10 MHz | pass | 64 | 64 | 26 | 106 / 56300 |

"Kind" says what the chip does on the wire: **sends** is a transmitter driven by words from the host; **receives** reads the line and pushes what it decoded to the host; **both** drives a bus and also reads replies or follows a clock from the other side. "Length" is instructions; "words" is program memory used, which is larger when a program spans pages and pads to a page boundary. "Runs" is the number of simulator runs the programmer made, out of about 80 allowed. "Clock" is the simulated clock the task sheet fixed for that protocol, chosen by its examiner to suit the protocol's speed. "Bytes / cycles" is what the hidden test measured: bytes of payload over the cycles from the first change on the line to the last, for the last case the test ran. Those cycles include idle time between frames, which most task sheets let the programmer choose within a window, so the figure is a rough measure of speed and means something only within one protocol. Every hand-in was judged again for this report, and all 58 (18 census, 40 second question) passed.

Every hand-in passed on the first and only submission. The programmers needed between 6 and 42 simulator runs. Lengths ran from 16 instructions (the DCF77 time-signal receiver) to 196 (USB Power Delivery, which needs BMC line coding, 4b5b symbols and a CRC-32, and spans four pages).

### Out of reach

`mcs48` and `z80` are the external memory buses of the Intel 8048 and the Zilog Z80. sigrok's decoders for them require 14 and 11 channels and read the data bus in parallel on one edge, so they cannot be multiplexed onto 8 pins. The examiner said so before any programmer was involved, and its notes are in [`census/mcs48/hidden/OUT_OF_REACH.md`](census/mcs48/hidden/OUT_OF_REACH.md) and [`census/z80/hidden/OUT_OF_REACH.md`](census/z80/hidden/OUT_OF_REACH.md).

This exposed an error in the eligibility list. Rule 4 of `PREREG.md` says a decoder is eligible only if its required channels fit 8 pins. The list applied that rule to `gpib` and `ieee488` but missed these two. Applied correctly, the list would have had 21 names and the census 18. The two are kept in the order and reported here rather than redrawn, because the order was fixed before anyone knew it.

So, measured against the prediction: 18 of the 20 drawn passed, above the predicted 12 to 16; 18 of 18 attempted passed. The protocols named in advance as likeliest to fail were `flexray`, `lpc`, `ac97` and `sdcard_sd`, and all four passed. The other two named, `z80` and `mcs48`, were out of reach.

### How hard the judges are

A test that passes everything proves nothing, so the hidden tests were themselves tested. Before any firmware existed, each examiner showed its test passing a correct waveform and failing at least two broken ones; the record is in each `hidden/README.md`. After the census, each passing program was mutated: one number in one instruction was moved by one, and the change was kept only if the program still assembled. That made 90 mutants, 5 per protocol. The hidden tests rejected 77 of them (86 percent).

All 13 survivors were then traced. Each survivor and its original were run through the same judged cases with every simulator output saved, and the outputs were compared edge by edge against the task sheet's limits:

- Two make no change on the wire at all in any judged case (both in `dcf77`).
- Eleven move an edge by a cycle or more, or merge two edges into one cycle, and every one stays inside the task sheet's limits. Examples: a FlexRay edge moved by 1 cycle where the specification allows 1; a gap between packets cut from 556 to 540 cycles where at least 500 is required; a remote-control frame starting 9200 cycles earlier inside a window 50000 cycles wide.

None breaks a rule of its task sheet, so no gap in a judge was found. The details, survivor by survivor, are in [`census/mutants/SURVIVORS.md`](census/mutants/SURVIVORS.md).

### Notes on two judges

Two hidden tests adjust what they hand to sigrok's decoder, and their notes say so. For `lpc`, sigrok 0.7.2's decoder looks for the START field one clock later than the LPC specification puts it, so the test shifts LFRAME# by one clock inside its own copy of the capture; the chip's waveform is checked against the specification directly. For `sda2506`, the decoder needs a slower capture rate to read the device's read delay, so the test resamples to 1 MHz. Both were in the tests before any programmer started. An independent review of all 18 task sheets and tests ([`census/REVIEW.md`](census/REVIEW.md)) found them fair.

## The second question: what each feature is worth

The first 8 protocols in the order all passed, so those 8 were attempted again: once more on the full chip, and twice each on the two cut-down chips. A cut-down chip is the same simulator behind a wrapper that refuses any program using the removed feature, plus an `isa.md` that does not describe it ([`census/variants/`](census/variants/)). Each attempt was a new programmer with the same instructions as the census.

| Protocol | Full chip (census) | Full chip (again) | No delay, 1 | No delay, 2 | No side-set, 1 | No side-set, 2 |
|---|---|---|---|---|---|---|
| ac97 | 56; 638 | 55; 663 (+4%) | 48; 634 (-1%) | 62; 638 (+0%) | 51; 642 (+1%) | 49; 634 (-1%) |
| ook | 33; 109,900 | 55; 96,345 (-12%) | 58; 105,840 (-4%) | 51; 105,990 (-4%) | 31; 95,450 (-13%) | 34; 97,125 (-12%) |
| aud | 63; 17,025 | 55; 17,025 (+0%) | 57; 17,025 (+0%) | 61; 17,025 (+0%) | 46; 17,025 (+0%) | 37; 17,025 (+0%) |
| rc_encode | 29; 640,800 | 20; 621,600 (-3%) | 51; 637,600 (+0%) | 55; 624,000 (-3%) | 20; 633,600 (-1%) | 28; 640,300 (+0%) |
| lpc | 29; 1,590 | 31; 1,580 (-1%) | 35; 1,470 (-8%) | 41; 1,480 (-7%) | 49; 1,500 (-6%) | 46; 1,510 (-5%) |
| avr_pdi | 52; 21,775 | 58; 21,775 (+0%) | 58; 21,775 (+0%) | 111 [114]; 21,775 (+0%) | 59; 21,775 (+0%) | 60; 21,775 (+0%) |
| dsi | 17; 289,732 | 35; 266,619 (-8%) | 48; 266,620 (-8%) | 44; 266,620 (-8%) | 36; 233,298 (-19%) | 25; 273,702 (-6%) |
| maple_bus | 62; 38,330 | 55; 43,950 (+15%) | 104 [117]; 44,542 (+16%) | 66; 37,208 (-3%) | 63; 62,749 (+64%) | 61; 57,730 (+51%) |

Each cell is the length in instructions (memory words in brackets where they differ), then the cycles the hidden test measured for its last case, as in the census table: lower is faster. The percentage is against the census hand-in on the full chip.

All 40 passed, and every hand-in was also run through the wrapper for its removed feature, which confirmed that none of them used it.

What the numbers say, read with care because each cell is one or two programmers:

- **Neither feature is necessary for any of these 8 protocols.** Each one was built without delay and without side-set, on both tries.
- **Without the delay field, programs sometimes double.** rc_encode went from 20 instructions to 51 and 55. avr_pdi and maple_bus each doubled in one of their two tries (111 and 104 instructions) while the other try stayed close to the full chip. The cost depends on whether the programmer finds a way to time things with the clock divider or a counter instead.
- **Without side-set, maple_bus is slower on the wire.** maple_bus moves two lines on nearly every step; with side-set, the second line moves inside the same instruction. Without it, each change costs an instruction, and both tries took 57,730 and 62,749 cycles against 38,330 and 43,950 for the two full-chip hand-ins: 31 to 64 percent slower. That is the only clear speed cost in the table. Elsewhere the cut-down hand-ins fall within or close to the spread between the two full-chip ones, which is as wide as 12 percent (ook) because programmers choose different idle times.
- **Program length on the full chip varies about as much between programmers as between chips.** The two full-chip hand-ins for dsi were 17 and 35 instructions; for ook, 33 and 55. A single attempt is a loose measure of what a feature costs.

## Where the run did not follow the rules exactly

- **The eligibility list was wrong by two names** (above).
- **The cut-down wrapper had a hole, fixed during the run.** The wrapper did not recognise the simulator's `-stimulus` option, so a run that used it went to the simulator without the check. Two programmers reported it in their notes. It was fixed after the first ac97 attempts started, and the fixed wrapper was put into the 30 kits that had not started; four ac97 cut-down attempts ran with the old one. `PREREG.md` says nothing in the kit changes after the first attempt, so this is a departure. It cannot have helped a hand-in pass: every one of the 40 was checked afterwards with the fixed wrapper.
- **The programmer instructions for the second question gained one sentence.** In the census, most programmers printed `isa.md` and the task sheet at once, and the tool saved the overflow to a file outside their folder, which they did not open; they recorded this in their notes. The second-question instructions added: "To avoid very long tool output, read them in parts rather than printing both at once." Nothing else changed.
- **Five second-question attempts were stopped by a machine restart** before any of them handed in. Since none had handed in, none counted. Their folders were set aside unread, the kits were reset to their four given files with the hashes checked, and each was attempted again by a new programmer. The results above are those of the second attempts.
- **The cut-down chips were not fully blind.** The simulator's help text still lists the side-set settings, and the wrapper inside each folder says in its first lines what it refuses. Two programmers read it. They learned which feature was gone, not how to use it, since the wrapper refuses any use.

## What the programmers found unclear

Every programmer listed what in `isa.md` was confusing. The points raised by more than one:

- The simulator prints words pushed to the host in decimal and pin levels in hex, and `isa.md` does not say so. Four programmers lost runs to this.
- `-inputs` is described as hex but needs a `0x` prefix.
- Where `in` puts new bits by default, and what `mov` from the ISR does to its count.
- Whether a `wait` pin number counts from `in_base` (it does not).
- The width and range of `clkdiv`.
- What the CRC register reads back, and that its result is bit-reversed.
- That the simulator's `pins` lines show what the chip drives, not the line level, and that it prints the starting state at cycle 0 as if it were a change.

These go into `docs/isa.md` after this report, so the census ran on the document as it was.

## What this does and does not show

It shows that programmers who had never seen this project could implement 18 protocols chosen by a random draw from a list this project did not write, from the instruction-set document alone, and that sigrok's decoders accept the result. It shows that neither delay nor side-set is essential for the 8 protocols tried, and gives a first measure of what each costs.

It does not show what a person would do. The programmers were AI agents, all running the same AI model, of the same family as the assistant this project was built with (the pilot used another model of that family), each in a fresh session with no access to the repository. They were told to read nothing outside their folder; that was an instruction, not a sandbox, and each one's notes record what it read. Agents like these know the RP2040's PIO, which this chip resembles. Everything ran on the reference model, which the chip's own tests check against the RTL; nothing here ran on hardware.

## Files

- [`census/ORDER.md`](census/ORDER.md): the draw.
- `census/<protocol>/TASK.md`: the task sheet the programmer received.
- `census/<protocol>/full/`: the census hand-in (program, run arguments, notes).
- `census/<protocol>/hidden/`: the hidden test and its validation.
- `census/<protocol>/full2/`, `no_delay_1/`, `no_delay_2/`, `no_sideset_1/`, `no_sideset_2/`: the second-question hand-ins, for the first 8.
- [`census/variants/`](census/variants/): the cut-down wrappers and documents, as fixed.
- [`census/mutants/`](census/mutants/): the mutation check and the survivor tracing.
- [`census/EXAMINER.md`](census/EXAMINER.md), [`census/PROGRAMMER.md`](census/PROGRAMMER.md): the briefs each role received. [`census/REVIEW.md`](census/REVIEW.md): the review of the task sheets and tests.
- [`census/census-log.md`](census/census-log.md), [`census/ablation-log.md`](census/ablation-log.md): the organiser's running logs.
