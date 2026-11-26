# Hidden test: FlexRay transmitter

The examiner's side of the census for sigrok's `flexray` decoder. The
programmer gets only the kit (`../../kits/flexray/`: `isa.md`, `pe_sim`,
`TASK.md`) and never sees this folder until the firmware is handed in. No
firmware for the chip was written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal FlexRay transmitter as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |

## The role, and why

TRANSMIT. The chip is the transmit side of a FlexRay communication
controller on channel A: it drives TxD (P0) and sigrok decodes it. That is
the part of FlexRay a small host chip would do, and the part a scripted
stimulus cannot replace. A receiver would also be honest, but a census
entry needs one role and the transmitter is where the line coding and the
frame CRC live.

FlexRay is not out of reach: at the protocol's usual 10 Mbit/s a bit is
100 ns, 5 cycles of a 50 MHz clock, an exact whole number of cycles, and
it needs one pin. The task sheet uses 10 Mbit/s, not the slower 5 or
2.5 Mbit/s the decoder also accepts, because 10 Mbit/s is FlexRay's normal
rate; the census's preregistration names `flexray (10 Mbit/s)` as likely
to fail, and lowering the rate would be the weakened task the brief forbids.

## The host interface, as the task sheet states it

Per frame: word 0 = PPI<<14 | null frame indicator<<13 | sync<<12 |
startup<<11 | frame ID; word 1 = payload length in two-byte words; word 2
= header CRC; word 3 = cycle count; then one word per two payload bytes,
the first byte in bits 15..8. The sheet's example is the eleven words
0x2001, 0x0001, 0x051A, 0x0000, 0x1234, 0x2003, 0x0002, 0x027F, 0x0001,
0xDEAD, 0xBEEF.

The header CRC comes from the host. That is not a hole: FlexRay itself
assigns the header CRC to the host (the controller sends it as configured,
which is why the Bosch E-Ray takes it in a message buffer's header
register). Everything else that is coding is the firmware's: the TSS, FSS,
every BSS, NRZ bit timing at 5 cycles a bit, the 24-bit frame CRC over
header and payload, the FES and the idle between frames. The sheet says
"The host sends only the words defined above. All line coding, framing and
timing must be done by the firmware." The header fields arrive as values,
right-justified in their own words, not as line bits.

## What the judge does

Fixed cases (the sheet's example; no payload; all zeros; all ones with
every indicator set and ID 2047; a null frame; three frames; the longest
payload, 127 words) and eight seeded random cases of 1 to 5 frames, with
payloads up to 6 or up to 40 words and random valid indicators. For each:

1. It builds the TX words itself (`tx_words`) and runs `RUN_DIR/pe_sim run
   RUN_DIR/flexray.s -tx FILE -cycles N` plus `run_args.txt`, which must be
   one line holding only `-config` and `-mode` flags with values (prefixes
   resolved as `pe_sim` resolves them). N is the sheet's formula.
2. Decoder check. P0's changes become a VCD (timescale 10 ns, two samples
   per 20 ns cycle, so the decoder sees 100 MHz and 10 samples a bit), and
   `sigrok-cli -P flexray:channel_type=A:bitrate=10000000` must produce
   exactly, frame by frame and nothing else: TSS, FSS, reserved bit 0, the
   four indicators, frame ID, payload length, header CRC with "(OK)", cycle
   count, every payload byte, frame CRC with "(OK)", FES, channel idle
   delimiter. A collision avoidance symbol or a "(bad)" CRC is reported by
   name. The decoder's own CRC code is the third, independent check of the
   CRCs (after the judge's and the generator's).
3. Waveform check, from the pin changes, for what the decoder does not
   hold to: P0 high at cycle 0 and until the first TSS, which begins by
   cycle 10000; every TSS 15 to 75 cycles (3 to 15 bits); every edge after
   the TSS within +-1 cycle of 5k cycles after the FSS edge, with exactly
   the edges the ideal bit stream has (this checks the BSS and FES values,
   which the decoder skips, and that there is no DTS); from each FES rising
   edge to the next TSS at least 60 and at most 10000 cycles; and the line
   still for at least 60 cycles at the end of the run. Bursts are split
   where the line has been high for more than 53 cycles (a frame never
   has more than 10 high bits in a row).
4. After the case lines, for the last passing case,
   `RATE bytes=<payload bytes> cycles=<cycles from P0's first change to its last>`.

A simulator error or an exception inside the judge is a failure, never a
pass.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

The stand-in simulator (`ideal_wave.py` behind a wrapper named `pe_sim`)
reads the judge's words back into frames by the sheet's rules in its own
code, refuses words with bits outside their fields, computes the frame CRC
its own way (least significant bit first on the reflected polynomial,
which is the form of the chip's CRC register), and emits levels bit by
bit. The judge lists edge places from a most-significant-first CRC. So the
ideal waveform passes only if the judge's words, the stand-in's reading of
the sheet, both CRC implementations and sigrok's decoder all agree.

- Interface: `tx_words` gives the sheet's eleven example words; the
  sheet's header CRC 0x51A, frame CRC 0xFB7B75 and edge list are the
  judge's; the run length is the sheet's formula.
- Waveforms: 31 waveforms on 5 seeds, 155 verdicts, all as expected, and
  none of them reached through a judge exception or a simulator error.
  The 7 that must pass do: ideal; TSS of 3 bits; TSS of 15 bits; every edge
  1 cycle off, alternately early and late (the limit); gaps of exactly 60
  and exactly 10000 cycles; first TSS at cycle 10000. The 24 broken ones
  all fail on every seed: one payload bit flipped; one frame CRC bit
  flipped; header CRC 0; channel B's CRC initial value; payload least
  significant bit first; payload bytes swapped; the cycle count off by one;
  one edge 2 cycles late; one 2 cycles early; bits of 6 cycles; TSS of 2
  bits; TSS of 16 bits; a BSS left out; a BSS sent as 1 1; no FES; an FES
  two bits low; a DTS; gaps of 59 and 10001 cycles; first TSS at cycle
  10001; P0 low at cycle 0; a stray pulse after the last frame; the last
  frame missing; the last frame sent twice. The table in
  `selftest_output.txt` shows which check objected to each; several
  (timing faults, BSS 1 1, FES faults, idle faults) are caught only by the
  waveform check.
- RATE: for the ideal waveform it equals the figure from the generator's
  own edge list on every seed (seed 1: `RATE bytes=68 cycles=4335`).
- Hand-in rules: ten `run_args.txt` files; the two good ones accepted, the
  eight bad ones (`-tx`, `-t`, `-cycles`, `-inputs`, `-stimulus`, an
  ambiguous `-c`, two lines, a flag with no value) refused as a setup
  failure.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin (not
  FlexRay firmware). All 15 cases failed cleanly ("0 separate bursts"),
  with no RATE line and nothing on stderr.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the real simulator into the run folder.
- `run_args.txt` may set configuration registers, including the CRC
  register's polynomial and initial value. That is the chip's own hardware,
  configured by the host with constants, and fine; it is still worth
  reading when hand-ins are compared.
- Only the static segment: no dynamic frames, no DTS, no TxEN pin, no
  symbols (CAS/MTS, WUS), no channel B, no 5 or 2.5 Mbit/s.
- The bus is not modelled: P0 is read as the bus level, with no driver
  delay or asymmetry, so +-1 cycle is a limit on the controller's output,
  not on a bus.
- The header CRC is the host's, so a firmware that sent a wrong one is
  impossible to write except by changing the word; the judge still checks
  it through the decoder.
- Indicator combinations FlexRay forbids are never sent, and a null
  frame's payload is always zeros, so the firmware is never asked to
  handle them.
- A slow host is never provoked: the simulator refills the FIFO at once.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, but it is
the hardest of the transmit tasks so far. NRZ at 5 cycles a bit fits the
delay field, and BSS bits can come from `set pins`, which does not feed the
CRC register, while header and payload bits go out with `out pins, 1`,
which does. The chip's CRC register computes FlexRay's frame CRC directly
in its reflected form (polynomial 0x5D6DCB reflected, initial value
0xFEDCBA reflected), with no time cost, and reading it twice gives the 24
bits least significant first, which is the CRC most significant first, so
they can be sent with `mov pins` and an `in null, 1` shift without feeding
the CRC again. The tight spots are where the header's fields change word
in the middle of a byte (length to header CRC, header CRC to cycle count),
which leave 5 cycles to switch words and drop the unused high bits
without an `out` that would feed a spurious bit to the CRC; the TSS of up
to 75 cycles is the natural place to pull and pre-shift the header words,
with X, Y, ISR and OSR the only storage.
