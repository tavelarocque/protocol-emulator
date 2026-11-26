# Review of the census task sheets, before any attempt

Reviewer: read only. Paths below are relative to
`flex/census/`
unless they start with `the repository`. Line numbers are those of the files
as they stand.

What was checked for every protocol: TASK.md against accept.py (every check
the judge makes, and its numbers), the host words and timing reference, hints
about the instruction set, payload-only words and run_args.txt, the opening
and "Rules for this test" against `flex/pilot/miller/TASK.md`, and
feasibility on the ISA as documented. Also checked: every kit's `isa.md` is
byte-identical to `docs/isa.md`, every kit's `pe_sim` is the
same binary, every TASK.md opening (lines 1 to 23) differs from the pilot's
only in the protocol's name, every sheet has the two required sentences
("The host sends only the words defined above." / "All line coding, framing
and timing must be done by the firmware.") and the pilot's hand-in section,
and every hidden selftest_output.txt ends `SELFTEST PASS`.

## Summary

| Protocol | Verdict |
|---|---|
| ac97 | FIX (X1) |
| aud | FIX (X1) |
| avr_pdi | FIX |
| dcf77 | OK (X1 noted) |
| dsi | OK |
| em4305 | FIX |
| flexray | OK |
| iec | OK |
| lpc | OK |
| maple_bus | OK |
| ook | OK |
| rc_encode | OK |
| sda2506 | OK |
| sdcard_sd | OK |
| seven_segment | OK |
| swim | OK |
| t55xx | OK |
| usb_power_delivery | OK |
| mcs48, z80 (out of reach) | reasoning correct |

No BLOCK: no sheet has a limit tighter than the chip can meet for a reason
other than difficulty.

## X1 (cross-cutting): the input synchroniser reads all ones for the first two cycles, and isa.md does not say so

`model/isa.ml` lines 708-709 reset both synchroniser stages
to all ones ("reset high, like the idle bus"). So in cycles 0 and 1 a thread
sees every input pin as 1, whatever the stimulus says. Checked with the kit's
`pe_sim`: `wait 1 pin 0` with `-inputs 0x00` passes in cycle 0 (the next
instruction's write shows as `pins 2`). `isa.md` lines 79-89 (the kit copy is
identical) say only that a level arriving in cycle t is seen in t + 2; it
never gives the reset value. A programmer cannot know this from the kit.

It matters wherever a receiver's input is low at cycle 0:

- ac97/TASK.md lines 51-52 say BIT_CLK is low from cycle 0, and lines 60-61
  send the programmer to isa.md for when a thread sees an input. The thread
  sees a rising edge of BIT_CLK at cycle 0. A firmware that counts edges
  from the first `wait 1` counts a phantom one, which can put SYNC's first
  high on real falling edge 0 (forbidden, line 91) or misalign slots.
- aud/TASK.md lines 91-93 say AUDCK is low at cycle 0 with the idle nibble,
  and lines 100-101 say only 0x8 to 0xB and 0x3 ever appear with nAUDSYNC
  high. The thread sees AUDCK high with nAUDSYNC = 1 and nibble 0xF at
  cycles 0-1: a phantom rising edge carrying a nibble the sheet says never
  occurs. A firmware that takes width from the low two bits of any
  sync-high non-idle nibble would decode a 32-bit command from it.
- dcf77/TASK.md lines 73-75: with P0 low at cycle 0 the thread sees a 2-cycle
  pulse at cycle 0, which breaks "No pulse has any other length" (line 46)
  and "No other gap occurs" (line 62). Probably harmless, because nothing is
  reported before the first marker, but it is still a phantom.
- The others are unaffected (their inputs are high at cycle 0, or they have
  no inputs).

Fix: one sentence in `isa.md` "Input synchroniser" (both stages reset to 1,
so every input reads 1 in the first two cycles of a run). This is a kit
document fault like the ones the pilot found, so PREREG ("What is frozen")
allows it before the first census attempt. Otherwise add a line to the
ac97, aud and dcf77 sheets.

## ac97: FIX

1. Fairness: every check in hidden/ac97/accept.py is stated with the same
   numbers: low by cycle 40 (accept 252-253, sheet 94-96), no change in the
   cycle BIT_CLK falls (256-260, sheet 74-79), SYNC at 16 falling edges per
   frame and first at edge 1-255 (265-286, sheet 84-92), SYNC change count
   1 + 2n (291-293, sheet 91 "SYNC changes only to begin and end these
   pulses"), SDATA_OUT low outside frames (287-290, sheet 96-98), clock
   model (126-137, sheet 51-62), N (147-150, sheet 168-169), modes (117-120,
   sheet 184-185). Nothing unstated.
2. Clarity: good. CTRL/DATA/LEFT/RIGHT bit positions, the example with both
   the words and the slot values, the reference point (falling edges
   numbered from the first).
3. No leaks. Line 60-61 points to isa.md for input timing; that is a chip
   fact, but see X1: the pointer leads to an incomplete statement.
4. Payload only. The tag, padding, SYNC and empty slots are firmware work.
5. Matches the pilot.
6. Feasible but the tightest sheet in the census: 4 or 5 cycles a bit, high
   phase exactly 2 cycles, 2-cycle input delay. A loop of `wait` plus up to
   three instructions per bit fits; no red flag. The stop condition (no more
   words) works by stalling on a pull during the all-zero slots 5-12, so it
   is achievable.
- FIX for X1 only.

## aud: FIX

1. Fairness: accept.py checks the words, their order, nothing extra, and
   each push between the last nibble's rising edge and +200 cycles
   (accept 196-214; sheet 108-115). P6, P7 read 0 (stimulus level() sets
   only bits 0-5; sheet 46). Modes P0-P5 input (accept 160-176; sheet
   132, 140). All stated.
2. Clarity: good. Low half first, then high half; 4/8/16-bit widths still
   give two words; the reference (stimulus rising-edge cycle vs `rx` cycle)
   is explicit.
3-5. No leaks; payload only (no TX words); matches the pilot.
6. Feasible: 50 cycles per nibble, 200-cycle deadline.
- FIX for X1: lines 91-93 and 100-101 are false as the thread sees the pins
  in cycles 0-1.

## avr_pdi: FIX

1. Fairness, one unstated check: hidden/avr_pdi/accept.py lines 350-354
   require the chip's P1 to change exactly as many times as the schedule's
   levels change ("no other P1 change", docstring line 37). TASK.md lines
   53-56 only say the chip may change P1 from a slot's falling edge to 5
   cycles before its rising edge, and must release it outside its frames.
   A firmware that, inside the allowed window, releases P1 and then writes
   the bit (two changes for two 0 bits in a row) meets the sheet and fails
   the judge. Add: "P1 changes at most once per slot, and only where the
   bit differs from the one before."
   Everything else matches: clock edges +-2 on fixed places (accept
   315-329; sheet 65-68), P1 window (335-340; sheet 55-56), P1 level at
   each rise (341-349), P2-P7 untouched (308-311; sheet 46), RX words
   (358-372; sheet 121-125), N (148-149; sheet 164-165).
2. Clarity, minor: after an answered last instruction, the judge
   (accept 94-95) puts 2 idle slots and then the 16 end slots, 18 in all.
   The sheet (83-89) can be read that way, but the example (141-150) does
   not show an answer followed by the end, and a reader could fold the 2
   into the 16. Add one sentence or an example row.
3-5. No leaks; payload only (bits 11..8 is the answer length, which the
   firmware needs to know when to turn the line round); matches the pilot.
6. Feasible: 50 cycles a slot; device data stable from +5 to the next +5.

## dcf77: OK

1. Fairness: words, order, nothing before the first marker, push between
   the rising edge and +500 ms (accept 316-331; sheet 90-107). Stimulus
   ranges match (accept 49-56, 145-166; sheet 43-63, 73-83).
2. Clarity good; the example (99-103) shows the bit-1 flag.
3-5. No leaks; nothing from the host; matches the pilot. Core clock 100 kHz
   is the examiner's choice and within PREREG.
6. Feasible. Counting 2 s needs more than 16 bits at 100 kHz, but clkdiv or
   nested loops handle it.
- Note X1 (phantom pulse at cycle 0; probably harmless).

## dsi: OK

All checks stated with the same numbers: low by cycle 1000, first rise
50000-200000, rest 5-20 ms from the end of the stop bits, every change
within +-80 of k x 25000/3 from the frame's rise, nothing else moves
(hidden/dsi/accept.py 192-241; TASK.md 53-66). N matches (accept 255-257;
sheet 116-117). The example's change list (83-93) checked by hand. No
leaks, payload only, matches the pilot. Feasible: 8333.33 cycles a half-bit
at 10 MHz, error must not add up but 16-bit counters reach it.

## em4305: FIX

1. Fairness, one unstated check: hidden/em4305/accept.py lines 274-311 treat
   the stretch from P0's first change to the first command as carrier, and
   check every interval in it, including the very first low (from the first
   fall, edges[0], to the first rise, edges[1]), against 40 +-2 cycles
   (305-312). TASK.md lines 88-90 say only that the first change is a fall
   by cycle 200 and that "from then on the field is on"; lines 98-99 speak
   of "every low between two pulses", and the reset-high stretch is not a
   pulse. A firmware that falls early and starts the carrier some cycles
   later fails. Add: "the first rise comes 40 +-2 cycles after that fall".
   The rest matches: command edges +-2 from the rise ending the field stop
   (286-294; sheet 91-97), 320-1280 periods before each command (296-299;
   sheet 100-105), at least 320 whole pulses after the last (313-317;
   sheet 106-110), N (334-337; sheet 162-165).
2. Clarity: good; both examples checked by hand (bits, parities, column
   parity 0x08 and 0x22).
3-5. No leaks; payload only; matches the pilot.
6. Feasible, with a note: there is no XOR instruction, so the column parity
   (sheet 82-83) needs the CRC register used as an 8-bit XOR accumulator
   (polynomial 0x80). That follows from isa.md lines 136-149 but is not
   obvious. Difficulty, not a defect.

## flexray: OK

1. Fairness: TSS 15-75, first TSS by 10000, edges +-1 from the FSS edge,
   60 to 10000 cycles from the FES edge to the next TSS, line high at
   start and after (hidden/flexray/accept.py 264-320; TASK.md 42-68). N
   matches (accept 331-333; sheet 165-166). The decoder's CRC "(OK)" and the
   judge's exact edge list cover the rest. All stated.
2. Clarity good: header bit table, word layout, worked example with the
   full edge list and CRC.
3. No leaks. The CRC is described as the protocol defines it (shift left,
   MSB first), not as the chip would do it.
4. Payload only. The header CRC comes from the host; FlexRay assigns it to
   the host and README.md justifies it. Acceptable.
5. Matches the pilot.
6. Feasible but hard, and PREREG already predicts a fail: 5 cycles a bit,
   +-1 cycle, a 24-bit MSB-first CRC on a shift-right CRC register (needs
   the reflected polynomial and a reversed read-out), and the CRC takes one
   bit from every OUT, so skipping the leading zeros of word 1-3 by
   `out null, n` would corrupt it unless the programmer works round it. No
   rule is impossible.

## iec: OK

Every limit in hidden/iec/accept.py 54-73 and check_waveform (303-406)
appears in TASK.md 75-131 with the same numbers, measured from the same
listener event: ATN 100-400 after bus free, CLK 0-20 after ATN, ready
100-400, first fall 0-200 (or 0-60 after the EOI pulse), bit periods
40-100, low and high at least 20, DATA setup 20, release within 20, ATN and
CLK turns 20-90, no other moves. The example stimulus (149-163) checked
against the listener's shortest delays. No leaks (lines 71-72 point to
isa.md for the 2-cycle input delay, a chip fact). Payload only. Matches the
pilot. Feasible: worst case 200 + 8 x 100 + 20 = 1020 cycles before the
earliest acknowledge at 1050 (910 vs 880 for EOI), so the windows nest.

## lpc: OK

All checks stated: rising edges +-2 on 100 + 20k, high and low at least 6,
no change of P0-P4 at E-1 or E, LFRAME# low only in START, LAD released
outside the chip's part, sampled bus equal to the ideal, RX words
(hidden/lpc/accept.py 243-321, 389-396; TASK.md 62-112, 166-174). N matches
(98-100; sheet 191-193). The judge shifts LFRAME# one clock for a 0.7.2
decoder quirk (324-335), internal only. No leaks, payload only, matches the
pilot. Feasible: 20 cycles a clock, peripheral data stable for 20 cycles.

## maple_bus: OK

1. Fairness: change order exact, never both lines in one cycle, 7 cycles
   across lines, 12 on one line, at most 100 inside a frame, first frame by
   50000, 100-50000 idle between frames, nothing after
   (hidden/maple_bus/accept.py 247-313; TASK.md 87-104). All stated.
2. Clarity good; the 98-change example checked in part by hand.
3-5. No leaks; payload only (the checksum is the firmware's); matches the
   pilot. N is given as "long enough" (line 167-168), not a formula; fine,
   the programmer does not need it.
6. Feasible, with the same note as em4305: the XOR checksum (line 53-54)
   needs the CRC register as an XOR accumulator; there is no other way to
   XOR on this ISA.

## ook: OK

Checks match (hidden/ook/accept.py 227-280; TASK.md 39-76): low by 100,
first rise 5000-20000, transitions +-2 from the frame's first rise, gap
5000-20000 from the end of the last bit, line low at the end, no strays.
The judge expects the decoder's extra '1' after a final 0 (86-92); that is
judge-internal. Example checked (46 transitions). No leaks, payload only,
matches the pilot. Feasible.

## rc_encode: OK

Checks match (hidden/rc_encode/accept.py check_waveform; TASK.md 64-80):
first fall by 100, first rise 50000-100000, 50 edges per frame +-2 from its
first rise, each frame 204800 +-2 after the one before, low after. N
matches. Word encoding and example checked (0x0018, 0x0481). No leaks,
payload only (trit values, not pulse lengths), matches the pilot. Feasible.

## sda2506: OK

1. Fairness: CLK and CE edges +-2 on the fixed schedule, nothing else on
   them, CLK low by 1000, DATA held outside the +-20 windows at the stated
   level, quiet after the last CE rise, RX words (hidden/sda2506/accept.py
   143-178, 376-424; TASK.md 81-128, 166-175). All stated.
2. Clarity good; the write example checked against the schedule.
3. No leaks (line 127-128 points to isa.md's synchroniser, a chip fact).
4. Payload only, one observation: the write word (line 147, bit 15 = 1,
   address in 14..8, data in 7..0) shifted out least significant bit first
   is exactly the 16 command bits (D0-D7, A0-A6, CB = 1), and a read word's
   high byte is exactly A0-A6, CB = 0. The firmware still makes CLK, CE,
   the start pulse, the 20 ms wait, erase's CB and the DATA level at CE's
   fall, so this is the natural packing, not pre-coding. Worth knowing when
   comparing program lengths.
5. Matches the pilot.
6. Feasible: 200-cycle slots, 200000-cycle waits need nested counters.

## sdcard_sd: OK

Checks match (hidden/sdcard_sd/accept.py 348-466; TASK.md 51-77, 113-138,
155-164): CLK edges +-2 on fixed places and no restart, CMD changes only
with CLK low at c-1 and c, at most once per low half and only where needed,
tokens bit for bit, RX words. N "at least 20 clocks after the last end bit"
matches run_cycles (239-240). Modes: the sheet (48-49) is stricter than the
judge (allows `-mode N=in`), harmless. No leaks; CRC7 described as the SD
spec does. Payload only (the response type in the word is what a host
knows). Matches the pilot. Feasible: 40 cycles a bit; CRC7 via the CRC
register.

## seven_segment: OK

Checks match (hidden/seven_segment/accept.py check_waveform and
check_decoder; TASK.md 86-109): pins high until T0, T0 by 20000, changes
+-2 at T0 + 1000k only where the character changes, one change per
character change, blank and still after the last. No leaks; payload only
(digits, not segments); matches the pilot. Feasible: no table instruction,
but a branch chain and building 8 bits in the ISR (or set plus side-set in
one instruction) fit in 1000 cycles and 256 words.

## swim: OK

Checks match (hidden/swim/accept.py 343-409; TASK.md 59-81, 128-138): first
fall 400-4000, first rise +-2 at +640, later entry falls +-2 and rises +-1
from the actual rise before, nothing before the sync frame, every frame
edge +-2 on the fixed timetable, no other edge; exactly one `-mode 0=od`
(accept 101-120; sheet 223-224). Example checked (250860, 251410, 251630).
No leaks, payload only, matches the pilot. Feasible: the NACK (100 low) vs
ACK (10 low) is read with 220 cycles to spare before the next frame.

## t55xx: OK

Checks match (hidden/t55xx/accept.py 212-291; TASK.md 41-77): half periods
38-42, gaps at least 800 and low, nothing in between, bit lengths, start and
write gap ranges, 8000-80000 lead-in, at least 8000 tail, first change by
400. N matches (305-310; sheet 130-131). Example words checked (0x006E,
0x0080, 0x0013). No leaks, payload only, matches the pilot. Feasible.

## usb_power_delivery: OK

1. Fairness: low by 100, first rise 500+ after going low and by 40000,
   transitions +-2 from the packet's first, the closing transition rule,
   500-40000 gap, still after (hidden/usb_power_delivery/accept.py
   264-317; TASK.md 101-127). N matches (335-337; sheet 177-178).
2. Clarity good. CRC examples verified with zlib (0x312C2EDA, 0xA8BB6CBB);
   4b5b symbols of the example checked.
3. Minor: line 93 "(0xEDB88320 written least significant power first)"
   repeats isa.md's wording for `crc_poly` (isa.md line 113), which steers
   toward the CRC register's configuration. It is also a standard protocol
   fact, so this is optional; dropping the parenthesis would be cleaner.
4-5. Payload only; matches the pilot.
6. Feasible: 66 cycles a bit; the 4b5b table is a branch chain; the CRC
   must be fed one bit per OUT (or per IN with crc_in), so nibbles cannot be
   taken with a single `out x, 4`.

## Out of reach: mcs48 and z80

Both notes are right. `sigrok-cli -P mcs48 --show` lists 14 required
channels (ALE, /PSEN, D0-D7, A8-A11); `-P z80 --show` lists 11 (D0-D7, /M1,
/RD, /WR), with 18 more optional (/MREQ, /IORQ, A0-A15). Both decoders read
the data bus in parallel on one edge or sample, so the lines cannot be time
multiplexed onto 8 pins. Both notes say correctly that PREREG rule 4
(`flex/PREREG.md` line 36, "Its required channels fit the
chip's 8 protocol pins") should have excluded them, so the list of 23
(line 39) should have been 21 and the census 18. The organiser should
record that in RESULTS.md rather than count them as census failures.

## Smaller cross-cutting notes

- Three sheets point at isa.md's input synchroniser (ac97 60-61, iec 71-72,
  sda2506 127-128) and the other receivers do not. These are chip facts,
  not instruction hints, but the help is uneven across protocols.
- Several protocols need a checksum or parity with no XOR instruction
  (em4305, maple_bus, swim, avr_pdi parity; flexray, sdcard_sd,
  usb_power_delivery CRCs). Row parity can live in control flow; XOR across
  bytes needs the CRC register. This is the ISA being tested, not a sheet
  fault, but RESULTS.md should not read a failure there as a sheet problem.
