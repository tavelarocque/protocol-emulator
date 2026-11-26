# Hidden test: AVR PDI programmer (`avr_pdi`)

The examiner's side of the census entry for sigrok's `avr_pdi` decoder. The
programmer gets only the kit (`../../kits/avr_pdi/`: `isa.md`, `pe_sim`,
`TASK.md`) and never sees this folder. No firmware for the chip was written
for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal PDI programmer as pin changes and rx lines, with named faults, standing in for `pe_sim`. Not chip firmware |
| `selftest.py` | checks the judge: the sheet's example, every ideal or broken result, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2 and 3 |

## The role: both directions

A small chip on the PDI bus is the programmer: it drives PDI_CLK and sends
instructions, and a programmer that cannot read (LDCS status, LDS, LD) is
of no use, so the chip also receives. The ATxmega is a scripted stimulus
on P1. A scripted device cannot react, so the task sheet fixes the whole
session as a schedule of 1 MHz bit slots: slot k falls at cycle
2000 + 50k and rises 25 cycles later (core clock 50 MHz, 20 ns a cycle);
16 idle slots to enable the PDI; the chip's frames back to back; after a
byte the host marks as answered, exactly 128 guard slots (the reset value
of the guard time), the ATxmega's frames, then exactly 2 idle slots; and
16 idle slots after the end word, after which the clock stops high. Frames
are 12 slots: start, 8 data bits LSB first, even parity, two stop bits.
P0 = RESET/PDI_CLK (push-pull), P1 = PDI_DATA (open-drain, pulled up).
The ATxmega changes P1 5 cycles after each ideal falling edge.

## The host interface

TX: one word per byte sent; bits 7..0 the byte, bits 11..8 the number of
bytes (0 to 15) the ATxmega answers after this byte, bits 15..12 zero; then
the end word 0x8000. RX: one word per answered byte, bits 7..0 the byte,
bits 15..8 zero, nothing else. "The host sends only the words defined
above. All line coding, framing and timing must be done by the firmware."
The answer length is the only thing the host tells the firmware beyond the
bytes; it is a property of the PDI instruction, not of the line.

## What the judge checks

Six fixed sessions (the sheet's example; enable and end with nothing sent;
KEY then two status reads; all-zero and all-one bytes both ways; a 15-byte
REPEAT/LD block read; two reads back to back with a 4-byte answer) and
eight seeded random sessions of valid PDI instructions (LDS, STS, LDCS,
STCS to status or reset, KEY, ST ptr, REPEAT, LD and ST through *(ptr++)),
each with at least one answer. For each:

1. It builds the TX words and the stimulus from the sheet's rules.
2. It has sigrok's `avr_pdi` decode an ideal capture of the session (ideal
   clock and programmer frames, plus the stimulus) and requires every
   byte, both ways, so the scripted device is real PDI on the schedule.
3. It runs `RUN_DIR/pe_sim run RUN_DIR/avr_pdi.s -tx -stimulus -cycles`
   with `run_args.txt`, which may hold only `-config` and `-mode` and must
   set `0=pp` and `1=od`.
4. Decoder: the capture is P0 as printed and P1 as the wired-AND of the
   chip's printed output and the stimulus. The decoder's byte stream must
   be the session's bytes both ways, in order, nothing extra, with no
   parity error, stop bit error or BREAK, and the same number of frames.
5. Waveform, from the pin changes: P0 high at cycle 0; exactly two PDI_CLK
   edges per slot, each within +-2 cycles of its place on the schedule
   (place, not spacing); nothing on P0 after the last rising edge; every
   change of the chip's P1 output from a slot's actual falling edge to 5
   cycles before its actual rising edge; the chip's P1 at every rising edge
   equal to the bit it sends or 1 (released) in every slot it does not
   own; no P1 change at all in a slot whose bit the chip does not send (so
   no pulse in a guard or answer slot that is gone by the rising edge),
   while in its own slots P1 may change more than once inside the window;
   P2..P7 never written. The task sheet states each of these.
6. RX: the rx words equal the answered bytes, in order, bits 15..8 zero,
   nothing extra. When they are pushed does not matter.

It prints one line per case, then `RATE bytes=<bytes both ways>
cycles=<first to last pin change>` for the last passing case, then the
verdict. A simulator error or an exception in the judge is a failure.

## What it does not check

- Whether the firmware samples the ATxmega's bits at the rising edge: the
  stimulus holds each bit for a whole slot, so a sample anywhere in it
  works. Only the RX words are judged.
- Parity or stop bits of the ATxmega's frames: they are always correct,
  and the sheet asks for no error report.
- A slow host or a full RX FIFO: the simulator refills and drains at once.
- Guard times other than 128, the PDI's own enable timing beyond the
  sheet's fixed numbers, collisions and BREAK handling.
- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must
  put the real simulator there. `run_args.txt` can still set configuration
  registers (`clkdiv`, `timeout`, CRC settings), which should be read when
  hand-ins are compared.

## Validation

    python3 -B selftest.py 1 2 3

Result: `SELFTEST PASS` (`selftest_output.txt`).

- Interface: the example's words (0x0180, 0x00C1, 0x0059, 0x8000), its
  stimulus cycles (9805, 9905, 9955, 10255) and its last edge (12475) are
  the ones printed in the sheet, and an answered last instruction is
  followed by 2 + 16 = 18 idle slots, as the sheet now says in so many
  words.
- 27 results on 3 seeds, 81 verdicts, all as expected. The 5 that must
  pass do: ideal; every falling edge 2 cycles late and rising edge 2
  early; P1 changing exactly 5 cycles before the rising edge; rx words
  pushed only at the end of the run; P1 released at every falling edge
  of a slot the chip sends and then written 3 cycles later. The 22 broken ones all fail: a
  flipped data bit, odd parity, one stop bit, MSB first, one clock edge 3
  cycles late, a 51-cycle period, the first edge at 2003, 127 and 129
  guard slots, 1 idle slot after an answer, P1 changing 4 cycles before a
  rise, P1 changing 1 cycle before a fall, the chip pulling P1 low in the
  ATxmega's stop bit, a short low pulse inside a guard slot, one rx word
  wrong, one missing, one extra, parity carried in bit 8 of rx words, 15
  and 17 idle slots at the end, P2 written, P1 low at cycle 0.
- RATE for the ideal result equals the schedule's figure on each seed
  (seed 1: `RATE bytes=12 cycles=21775`).
- `run_args.txt`: 2 good files accepted; 10 bad ones refused as setup
  failures (P1 push-pull, P0 not set, `-tx`, `-stimulus`, `-st`,
  `-inputs`, `-cycles`, ambiguous `-c`, two lines, a flag with no value).
- The real kit simulator with a one-instruction idle program (not PDI
  firmware) accepted the word and stimulus files; all 14 cases failed
  cleanly ("PDI_CLK has 0 edges"), no RATE line.

## Is a solution feasible on the full chip?

Not shown: no firmware was written. My view from `isa.md` is yes, with
work. A slot is 50 cycles, so side-set can make each clock edge free and
there is time for several instructions per bit. Parity has no instruction
of its own, but it can live in the control flow, or in the CRC register
set to a 1-bit polynomial. The guard time is a 128-iteration counter loop
that must still toggle the clock. The hard part is the fixed schedule:
every path (frame bits, word fetch, guard, answer, the two idle slots,
the end) must take exactly 50 cycles a slot, and the clock edges must stay
on the grid across the switch from sending to receiving. The program fits
easily in 256 words.

## Revision, 24 November 2026 (before any attempt)

A review found that the judge required P1 to change exactly as often as
the schedule's levels, which the sheet did not say. The judge was relaxed
to what the sheet says, which is also how a programmer may drive the
line: inside its own slots only the level at the rising edge matters,
and in every slot it does not own P1 must not move. The sheet now says
this explicitly, and spells out that an answered last instruction is
followed by 2 + 16 = 18 idle slots. The kit's new `isa.md` (both input
synchroniser flip-flops reset to 1) agrees with the sheet: the line is
released and high from cycle 0. Selftest rerun: `SELFTEST PASS`.
