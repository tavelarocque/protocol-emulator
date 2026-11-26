# Hidden test: PT2262 remote control encoder (`rc_encode`)

This folder is the examiner's side of the census for sigrok's `rc_encode`
decoder. The programmer gets only the kit (`../../kits/rc_encode/`:
`isa.md`, `pe_sim`, `TASK.md`) and never sees this folder until the
firmware is handed in. No firmware for the chip was written for this test,
not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal PT2262 encoder as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## Role: transmitter

The PT2262 (HX2262, SC5262) is an encoder: in a 433 MHz remote control it
drives the radio transmitter's keying input, and nothing comes back. A
small host chip standing in for it transmits, so the role is TRANSMIT. The
receive side would be the PT2272 decoder, a different chip that sigrok
does not decode.

## The protocol as the task sheet fixes it

Core clock 10 MHz (one cycle 100 ns). P0 push-pull, idling low. The unit
alpha is 40 us = 400 cycles. A trit is two pulse cycles of 16 alpha, each
a high then a low; a short pulse cycle is 4 alpha high and 12 low, a long
one 12 high and 4 low; '0' is short-short, '1' long-long, 'f' short-long.
A code word is twelve trits (A0 first) then a sync bit of 4 alpha high and
124 alpha low: a frame of 512 alpha, 204800 cycles, 50 edges. Frames
follow each other with no break. P0 must go low by cycle 100 (its reset
level before that is not shown to the decoder: the sheet says the host
makes the pin an output only after that), the first frame starts between
cycles 50000 and 100000, and the line stays low after the last sync bit.

## The host interface, as the task sheet states it

Two 16-bit words per code word, code word after code word: the first holds
trits 0 to 5, the second trits 6 to 11. In each word the k-th trit is in
bits 2k+1..2k, coded 0 for '0', 1 for '1', 2 for 'f'; bits 15..12 are 0.
The sheet's examples: 0 f 1 0 0 0 1 0 0 f 0 1 is 0x0018, 0x0481; twelve
'1's are 0x0555, 0x0555; twelve 'f's are 0x0AAA, 0x0AAA. The sheet says:
"The host sends only the words defined above. All line coding, framing and
timing must be done by the firmware." The trit codes are the trits'
values, not the pulse pattern: the firmware has to turn each into two
pulse cycles of the right lengths, and make the sync bit and the frame
spacing itself.

## What the judge does

Seven fixed cases (all '0', all '1', all 'f', the sheet's example, every
trit after every trit, one code word four times as a held button does,
eight different code words) and eight seeded random ones (1 to 8 code
words, some a repeated code word). For each:

1. It builds the TX words itself (`tx_words`) and runs `RUN_DIR/pe_sim run
   RUN_DIR/rc_encode.s -tx FILE -cycles N` plus `run_args.txt`, which must
   be one line of `-config` and `-mode` flags only (any other flag,
   including `-inputs` and `-stimulus`, is a setup failure). N = 100000 +
   204800 per code word + 20000.
2. Decoder check. P0's changes become a VCD capture at 10 MHz, with the
   line low from cycle 0 (P0's reset-high level before its first change is
   left out). `sigrok-cli -P rc_encode:data=P0 -A rc_encode=bits` must give
   exactly the wanted trits, each code word's twelve followed by `Sync`, in
   order, nothing extra, no `U`.
3. Waveform check, from the pin changes, for what the decoder does not
   hold to. The decoder only compares pulse lengths with each other
   (a long pulse 2 to 5 times a short one, equal ones within 0.5 to 1.5
   times) and never looks at absolute time or at the sync bit's length.
   The judge requires: P0's first change is to low, by cycle 100; exactly
   50 edges per code word after it; the first frame's first rise between
   cycles 50000 and 100000; every edge of a frame the right way and within
   +-2 cycles of its ideal place counted from the frame's first rise (so
   errors cannot add up); every frame's first rise 204800 +-2 cycles after
   the previous one's; and P0 low at the end.

After the case lines it prints `RATE bytes=<3 per code word> cycles=<P0's
first change to its last>` for the last case that passed. A code word is
counted as 3 bytes (twelve trits of two bits). The span starts at P0's
first fall, so it includes the required lead-in of 50000 to 100000 cycles;
since the protocol's timing is fixed, the RATE line only varies with that
lead-in. A simulator error or an exception inside the judge is a failure,
never a pass.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

The stand-in simulator (`ideal_wave.py` behind a wrapper named `pe_sim`)
receives the judge's words and reads them back into code words by the
sheet's rules, in code written apart from `tx_words`. It exits with an
error on an odd number of words, a trit code of 3 or a bit above bit 11.
It walks pulses and adds up time, where the judge lists edge places. So the
ideal waveform passes only if the judge's words, the stand-in's reading of
the sheet, the judge's idea of the ideal waveform and sigrok's decoder all
agree.

- Interface: `tx_words` gives exactly the three word pairs printed in the
  sheet, and the sheet's example table of edge places equals the judge's
  `ideal_offsets`. The sheet has no em-dash.
- Waveforms: 26 waveforms on 5 seeds, 130 verdicts, all as expected.
  - The 5 that must pass do: ideal; every edge 2 cycles off, alternately
    late and early (the limit); first fall at cycle 100; first frame at
    cycle 50000; first frame at cycle 100000.
  - The 21 broken ones all fail: first fall at 101; first frame at 49999
    and at 100001; frames sent idling high; one trit '0' sent as 'f'; '1'
    and 'f' swapped; trits in reverse order; one edge 3 cycles late; one 3
    cycles early; alpha of 401 and of 399 cycles; short highs of 3 alpha;
    long highs of 10 alpha; the sync low one alpha long and one short; a
    sync high of 8 alpha; no sync bit; the last code word missing; the last
    code word twice; a stray rise after the last frame; a one-cycle pulse
    inside a sync bit.
  - Several of them are passed by the decoder and caught only by the
    waveform check: the timing faults, short highs of 3 alpha (ratio still
    within 2 to 5), the sync length faults, the start and fall limits, and
    a stray edge after the end (the decoder then waits for more edges and
    prints nothing). That is the reason for the second check.
- RATE: for the ideal waveform the line equals the figure worked out from
  the generator's own edge list on every seed (seed 1: `RATE bytes=9
  cycles=624799`).
- Hand-in rules: eight bad `run_args.txt` files (`-tx`, `-t`, `-cycles`,
  `-inputs`, `-stimulus`, an ambiguous `-c`, two lines, a flag with no
  value) were each refused as a setup failure, and two good ones accepted.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin (not
  rc_encode firmware). The command line and word file were accepted, and
  all 15 cases failed cleanly ("P0 never changes"), with no RATE line.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the real simulator into the run folder.
- `run_args.txt` is the same for every case, so nothing payload-dependent
  can go there, but it can set configuration constants (`clkdiv`,
  `threshold`, `timeout`). With `clkdiv` 400, one tick is one alpha; that
  is the chip's own hardware, and it is allowed.
- P0's level before its first change is not judged (it is high from
  reset in the simulator). Only P0 is examined: other pins are ignored.
- A slow host is never provoked: the simulator refills the FIFO at once.
- The model-specific annotations of the decoder (`remote=maplin_l95ar`)
  are not used; they only relabel the same trits.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, and
comfortably. Every length in the protocol is a whole number of alpha, and
with `clkdiv` 400 one tick is one alpha, so a short high (4 ticks) and a
long one (12) fit the 4-bit delay field with room for the instructions
around them, and every edge lands on an exact grid. The sync bit's 124
alpha low and the lead-in need a counter loop on X or Y (`set` loads only
5 bits, so a short nested loop or a few delayed instructions). Each trit
is two bits from the OSR into X, a three-way branch (`jmp !x`, then
`jmp x--` to test for 1), and the work is to make each of the three paths
and the word fetch every six trits take the same number of ticks; a trit
counter in Y, or the `!osre` condition with a 12-bit threshold, keeps the
place in the code word. When the words run out the thread stalls on `pull`
with the line low, which is what the sheet asks for.
