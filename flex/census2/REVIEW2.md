# Review of round 2 Part A's task sheets and judges, before any attempt

Reviewer: read only (this file is the one thing written). Paths below are
relative to the round-2 folder `flex2/` (C in the brief) unless they start
with `decoders/` (C/decoders) or name the repository. Line numbers are those
of the files as they stand.

What was checked, for every protocol: TASK.md against accept.py (every check
the judge makes and its numbers, and every promise of the sheet against the
judge or the README); host words against "payload only" and every narrowing
of the protocol with its reason; the opening, "Rules for this test" and the
hand-in section against round 1's `flex/census/ook/TASK.md` (origin/demo);
every hunk of decoder commit e44c5bd and every PORT.diff; every declared
judge adjustment; the self-tests, run here; kit integrity; and feasibility on
the documented instruction set (no firmware written, not even a sketch).

Also checked:

- Kits. Each of the nine kits holds exactly `TASK.md`, `isa.md`, `pe_sim`.
  Every `isa.md` has SHA-256 `97b80dc6...`, which is `docs/isa.md` at
  `771319c` (PREREG2 "What is frozen"; note that origin/demo's current
  `docs/isa.md` is `fdb385bd...`, a later version, as PREREG2 expects).
  Every `pe_sim` is `82b00ea2...`. `kits/ir_irmp/` exists with `isa.md` and
  `pe_sim` only and no TASK.md; harmless, but it must not be handed out.
- Opening and rules. Lines 1 to 24 of every sheet differ from ook's only in
  the title (line 1) and the "general knowledge of ..." clause (lines
  19-20), which names the protocol (pxx1 adds "bit stuffing, CRCs", as ook
  named "Manchester coding"). Every sheet has the two sentences "The host
  sends only the words defined above." / "All line coding, framing and
  timing must be done by the firmware." on lines of their own (c2 207-208,
  can_fd 335-336, eth_an 115-116, fsi 219-220, mipi_dsi 201-202, mipi_rffe
  194-195, pxx1 173-174, qspi 133-134, st7789 118-119). Every hand-in
  section matches ook's apart from the program's name, the flags the test
  gives (`-stimulus`, `-inputs` where a stimulus is used), a required-modes
  clause where the judge enforces modes, and the closing sentence describing
  the receiver.
- No sheet mentions side-set, autopull, the CRC register, clkdiv, the
  sampler, pages, the synchroniser or any instruction. Round 1's X1 (the
  synchroniser's reset value) is fixed in the frozen kit: `isa.md` lines
  91-94.
- Decoder ports. `git -C decoders show e44c5bd` touches six files: C2,
  MIPI_DSI, can-fd, mipi_rffe, qspi, smart_qspi. Every hunk is one of: the
  DSView display-type string dropped from annotation tuples (index order,
  ids and texts unchanged); `self.matched & (0b1 << i)` read as
  `self.matched[i]` (same bit, tuple instead of mask); and in can-fd an
  import of sigrok's `bitpack` plus a local `bitpack_msb` (copy, reverse,
  LSB-pack: the MSB-first pack, which 0.7.2's `common/srdhelper` lacks).
  Nothing changes what a waveform decodes to. Each PORT.diff equals the
  committed change for its decoder line for line (c2, can_fd, mipi_dsi,
  mipi_rffe; qspi's holds both qspi and smart_qspi), apart from git's
  commit header. Commit b12ee00 adds only `.gitignore` (`__pycache__/`) and
  untracks 244 bytecode files. `git status` of `decoders/` is clean after
  every run here. eth_an, fsi, pxx1 and st7789 run unported.
- Self-tests, run here in parallel with their default seed 1 (the
  `selftest_output.txt` files hold seeds 1, 2, 3, 7, 11): every one ends
  `SELFTEST PASS` (st7789: `VALIDATION OK`), with no verdict against its
  expectation. Broken waveforms failing / good ones passing on this seed:
  c2 31/11, can_fd 37/6, eth_an 25/9, fsi 24/5, mipi_dsi 30/5, mipi_rffe
  27/6, pxx1 26/7, qspi 24/12, st7789 19 variants x 3 seeds = 57 broken
  runs failed, 6 good runs passed. Each also drives the real kit `pe_sim`
  and fails cleanly. (st7789's `validate.py` rebuilds `hidden/st7789/selftest/`
  by design; no other file in `hidden/` or `kits/` changed.)

## Summary

| Protocol | Verdict |
|---|---|
| c2 | FIX (X2, wording only) |
| can_fd | FIX |
| eth_an | FIX (X2, wording only) |
| fsi | OK |
| mipi_dsi | FIX |
| mipi_rffe | OK |
| pxx1 | FIX |
| qspi | OK |
| st7789 | FIX (X2, wording only) |
| ir_irmp (out of reach) | reasoning correct |

No BLOCK: no sheet asks for something the documented chip cannot do. Three
are hard (can_fd, mipi_dsi, pxx1) and fsi is long; the reasons are below.

## X2 (cross-cutting): limits declared stricter than the specification, with no reason in the sheet

The brief allows a judge stricter than the specification only if the sheet
says so and gives a reason. In each case below the sheet says so, the README
has a reason that holds, and the sheet does not give it. Each fix is one
clause in TASK.md; no judge change.

- c2/TASK.md lines 94-98: the device needs 20 us of reset, the sheet asks
  1100 cycles (22 us). Reason (hidden/c2/README.md 191-193): the receiver's
  decoder counts only a low phase strictly longer than 20 us as a reset.
  Add after "(22 us)": "a little more than the 20 us, because the receiver
  needs strictly more than 20 us to see a reset".
- eth_an/TASK.md lines 66-68: "This test holds the transmitter to the
  tighter limit." Reason (hidden/eth_an/README.md 47-50, 96-97): the
  receiver's decoder takes a data pulse only 60 to 70 us after its clock
  pulse and a clock pulse only 120 to 140 us after the last, narrower than
  the standard's 55.5 to 69.5 and 111 to 139. Add: "because the receiver
  reads a data pulse only 60 to 70 us after its clock pulse, and a clock
  pulse only 120 to 140 us after the one before".
- mipi_dsi/TASK.md lines 109-111: the Stop state between transmissions must
  last at least 50 cycles, "this sheet's" limit; every other LP state needs
  only 3 (TLPX). No reason anywhere (README 46-51 explains the maxima only),
  and the decoder measures no time (README 132). Either give the reason in
  the sheet, or, if there is none, lower it to 3 cycles: accept.py line 63
  (`GAP_MIN`), the sheet line 109-110, and the self-test's 49-cycle fault
  (then 2 cycles), and rerun the self-test.
- st7789/TASK.md lines 82-84: TCSH and TDCH counted from the falling edge
  "ask a little more than the data sheet". Reason (hidden/st7789/README.md
  72-75; and the `bad_cs_early` variant, caught by sigrok too): the
  receiver's decoder ends each bit, and reads D/CX for the eighth, at the
  falling edge of SCL, so that edge must come before CSX or D/CX moves. Add
  that as the sheet's reason. The same sheet's lines 55-57 rule out holding
  CSX low across transfers and raising it between bytes, which the data
  sheet allows; add the reason there too ("so that the test can check that
  each transfer is framed as the host asked, by bit 9").

## c2: FIX (X2 only)

1. Fairness. Every check in hidden/c2/accept.py is in the sheet with the same
   numbers: the reset (accept 69-71, 297-310; sheet 96-98); one strobe per
   scheduled slot, rising edge +-2 from 2000 + 50s, low 4 to 40, high at
   least 6, no other edges, C2CK high at the end (accept 312-336; sheet
   106-124); no change of the chip's C2D from F to E inclusive and its level
   at E is the bit (accept 362-377; sheet 125-131); the chip's output 0 only
   from the cycle after the rise before its first bit to the cycle before
   the fall after its last (accept 342-361, measured on the actual edges;
   sheet 132-139); rx words exact (accept 518-519; sheet 198-201); N (accept
   134-135; sheet 220-222). The 4-to-40 low limit and the setup-before-fall
   rule are inside the 50-cycle slot the schedule fixes, and README 34-46
   sources them to AN127; the 22 us reset is X2.
2. Payload only. Command number plus address or n; the INS code, n - 1, the
   reset, strobes, idle slots, turnarounds and bit order are the firmware's
   (sheet 210-213). The one narrowing, a WAIT of exactly one strobe (sheet
   75-78), has its reason in README 74-80 (the decoder's state machine reads
   only a one-strobe WAIT); it holds, and a one-strobe WAIT is a legal C2
   WAIT.
3. Declared adjustment (README 101-119; accept 460-479): through each of the
   device's strobes the decoder is shown the level 6 cycles after the rise.
   Necessary (without it the sheet's own example decodes as `ReadData(1)=0x61`,
   checked in the self-test output), and it cannot pass a wrong waveform: it
   touches only device strobes, where the chip's output must be 1 (checked
   on the pins, accept 342-361), and the chip's reading of those bits is
   judged by the rx check. The stimulus is first checked against an ideal
   master (accept 488-515).
4. Feasible. 50 cycles a slot at 50 MHz; the work is equal-length paths and
   the four-way dispatch inside the idle slot, as README 265-286 says.

## can_fd: FIX

1. Fairness. The judge compares the chip's P0 output (not the bus) with the
   ideal node edge by edge, +-1 cycle, same count (accept 465-486); the sheet
   states +-1, absolute places, no other change (204-210) and every bit
   time (58-81), the frame (83-169), the ACK slot and error flag (171-190),
   the schedule (192-202). RX: one word per frame, value, window from the ACK
   slot's start to the frame's end (accept 489-504; sheet 322-326). Decoder
   texts (accept 393-421) follow from the sheet's frame. Nothing unstated.
2. **Fix: the identifier restriction has no reason.** TASK.md lines 345-349
   say the test never sends a base identifier with bits 10..4 all 1, and
   README 172-173 only says such identifiers are "never sent". The reason
   exists and holds: `decoders/can-fd/pd.py` lines 570-580 put out
   "Identifier bits 10..4 must not be all recessive" for them (classic
   CAN's rule), and the judge allows no warning (accept 423-454). Add one
   sentence to README.md giving that reason, and one clause to the sheet
   after "all 1" (lines 348-349): "(an old CAN rule that the receiver's
   decoder still enforces)". The narrowing only removes inputs, so no judge
   change.
3. The other narrowing, DLC 0 to 10 (CRC-17 only; sheet 125-127), has its
   reason in README 44-58: `crc_poly` is one value per hand-in and the
   CRC-21 frames would need a second polynomial. It holds.
4. Declared adjustments (README 109-130): for an unacknowledged frame the
   decoder is compared only up to the CRC delimiter, because it takes the
   error flag's falling edge for an ACK. Necessary, and it cannot pass a
   wrong waveform: the ACK slot, the error flag and its delimiter are in the
   edge-by-edge pin check, which covers every frame whole. The decoder's own
   CRC check is a stub, so the judge compares the CRC text with its own
   (accept 114-126, checked against the catalogue value); also correct.
5. Payload only: header (IDE, BRS, DLC), identifier, data. Stuffing, stuff
   count, parity, CRC, fixed stuff bits, rate switch, ACK and error flag are
   the firmware's (sheet 338-341).
6. Feasible, and the hardest sheet. The data phase is 25 cycles a bit and
   needs the next data bit, the run of equal bits, the last level, a bit
   count and the stuff count at once, with X, Y, ISR and OSR. It is not
   impossible: the run state can live in the program counter (256 words),
   the CRC can follow the transmitted bits with `crc_in` because a thread's
   own output reads back undelayed (`isa.md` 100-101), and P1 to P7 are
   free (sheet line 43, "the test ignores them") and readable back as spare
   bits. PREREG2 already predicts a fail here.

## eth_an: FIX (X2 only)

1. Fairness. Pins low by 100, P1 never changes again, P0 low at the end,
   pulses 3 to 5 cycles, 17 + ones pulses per burst each within +-40 of
   5000k or 5000k + 2500 from the burst's first rise, first burst 40,000 to
   640,000, bursts 320,000 to 960,000 apart (accept 157-214; sheet 43-81);
   no other pin an output (accept `args_problem`; sheet hand-in 139-140).
   Decoder: one page per word, bit row, one NLP per pulse (accept 285-314).
   The burst-splitting quiet of 20,000 (accept 63) is internal and cannot
   split a legal burst (largest legal gap 5080). All stated.
2. Payload only: the link code word itself.
3. Declared adjustment (README 80-87; sheet 130-132 tells the programmer):
   the decoder gets a 1 MHz capture in which a sample is high if P0 was high
   at any time in it. Necessary (the decoder counts only 1 to 10 us pulses;
   a real FLP pulse is 100 ns), and the pin check judges width and every
   place directly, so it cannot pass a wrong waveform.
4. Feasible, comfortably.
- FIX: X2 (lines 66-68).

## fsi: OK

1. Fairness. FSI_CLK high at 0, every edge +-2 of its place, no extra edge,
   present to rising edge N - 10 (accept 321-332; sheet 64-75, 236-238); the
   chip's DATA changes only with FSI_CLK high in the cycle before (accept
   338-342; sheet 79-86); the chip pulls DATA low only between rising edges
   S - 1 and c + 1 (accept 345-353; sheet 162-166); the bit at every rising
   edge equals the ideal link (accept 356-366; sheet 87-89, 143-160); rx
   words exact (sheet 207-213); modes (sheet 54). All stated.
2. Payload only. Inversion, START, ABS_ADR code, size encoding in the
   address (the host gives the plain aligned address, sheet 205-206), CRC,
   hunting the slave's START, idle clocks: the firmware's. The subset
   (ABS_ADR reads and writes, no BUSY) is stated (sheet 108, 132) with its
   scope in README 57-61; a master that always uses ABS_ADR is a correct
   master, so nothing is lost.
3. Declared judge behaviour (README 93-120): the decoder reads the slave ID
   least significant bit first, so the judge expects its swapped number
   for IDs 1 and 2; the ID's real order is held by the pin check (fault
   `idlsb` fails). No capture is altered. The decoder's falling-edge CRC
   sampling after the first response is why the sheet requires launch
   while the clock is high, which is also FSI's own rule (README 106-120).
   Both sound.
4. Feasible but long (README 228-252): inverted data with no inverting
   instruction, a CRC-4 through the CRC register, polling for the slave's
   START on a 20-cycle grid. 20 cycles a bit is room for it.

## mipi_dsi: FIX

1. Fairness. Clock lane LP-11 throughout, data lane starts in LP-11, never
   both lines in one cycle, one transmission per packet with exactly the
   sheet's state sequence, every state from the first LP-10 to the last 3 to
   50 cycles, first change 5000 to 10000, Stop 50 to 1000 between, still
   after the last (accept 293-365; sheet 59-114). The decoder list (escape
   entry, 0x87, the bytes with ECC and checksum, Stop) follows from the
   sheet. The "run ended too soon" check (accept 361-364) cannot fire for a
   waveform within the sheet's limits (N leaves at least 2000 cycles).
2. **Fix: WC 0 to 26 has no reason.** The sheet limits a long packet's
   payload to 26 bytes (lines 68, 142-143; accept 65-66); README 63-66
   explains why the host sends WC but not why it stops at 26. The reason
   that holds is run length: the firmware's work per payload byte is the
   same at any count, so a cap loses nothing. Add that sentence to README.md
   (and optionally "to keep a run short" in the sheet at line 143).
3. X2: the 50-cycle minimum Stop state (lines 109-111), above.
4. Payload only. Packet content, the long/short flag and WC; ECC, checksum,
   escape entry, LPDT command, marks, spaces and waits are the firmware's.
   The organiser's ruling that the ECC and checksum are the firmware's
   (README 55-59) is applied.
5. Port: annotation tuples and one `matched` test (README 89-118); no
   capture altered.
6. Feasible, hard; the ECC is why (README 249-283). It is not impossible,
   and there is a second route the README does not mention: the checksum's
   polynomial 0x8408 has an odd number of terms and its start 0xFFFF an
   even number of ones, so after the register is restarted and fed any set
   of bits, the parity of its 16 bits equals the parity of the bits fed
   (checked here on 2000 random sequences). So the same register, fed only
   the 13 or 14 header bits of one parity row, leaves that parity bit as
   the parity of a 16-bit read, without a second polynomial. Program space
   and the 1000-cycle gap allow either route. Optional note: lines 165-169
   name "the reflected form, 0x8408", which is how CRC-16 catalogues name
   this checksum but also matches `crc_poly`'s form (round 1 made the same
   optional note on usb_power_delivery).

## mipi_rffe: OK

1. Fairness. SCLK low from 100 to the first sequence, exactly the scheduled
   edges +-2, nothing else (accept 352-367; sheet 69-72, 116-132); SDATA low
   on the line from 100, every later change an SSC edge in place with SCLK
   low or inside a high phase from R to F - 3, at most one per clock (accept
   370-404; sheet 133-137); the bit at F - 1 (accept 405-414; sheet 138-139);
   the chip let go while the slave drives (accept 415-427; sheet 158-166,
   including "not even when the slave is sending a 0"); exactly
   `-mode 0=pp -mode 1=od` (sheet 51). Letting go early or taking the line
   back late shows as a line change with SCLK low, which the sheet's windows
   (159-166) say. All stated.
2. Payload only. Kind number (not command bits), n (not n - 1), address,
   data. The open-drain stand-in for push-pull plus bus holder is stated
   with its reason (sheet 53-65). The v1 command subset has its reason
   (README 179-182: the decoder knows no other) and holds.
3. Declared adjustment (README 109-124): the decoder's command-frame parity
   leaves out the slave address, so the judge expects its "Parity warnings"
   exactly where that happens. The parity value itself is still required
   right (decoder text and pin check), and a firmware computing parity the
   decoder's way fails (`cmdparity_nosa`). Sound.
4. Port: annotation tuples and 16 `matched` tests; mechanical.
5. Feasible: 20 cycles a bit; parity through the CRC register or control
   flow; long but nothing missing (README 260-287).

## pxx1: FIX

1. **Fix: the judge never checks that P0 is push-pull.** The sheet (line 29)
   says the firmware drives the module "on pin P0 (push-pull)", but
   hidden/pxx1/accept.py `args_problem` (lines 217-231) checks only which
   flags `run_args.txt` holds, never the modes, and nothing else in the
   judge reads them; README does not say so. `pe_sim` prints the output
   register even for an input pin, which "drives nothing" (`isa.md`
   417-418), so a hand-in that leaves P0 an input passes while driving
   nothing. Checked here: the ideal stand-in with `run_args.txt` holding
   only `-config clkdiv=1` gives `ACCEPT PASS` on seed 1. Change: make
   `args_problem` require that the `-mode` flags leave P0 push-pull (later
   flags win, as in the other judges), add a hand-in-rules case to
   `selftest.py` (no `-mode`, and `-mode 0=od`, both refused), say it in
   README's "What the judge does", and rerun the self-test. Optionally add
   "The `-mode` flags must make P0 push-pull" to the hand-in section, as
   eth_an, mipi_dsi and qspi do.
2. Fairness otherwise. Low pulses 400 +-25, bits 800 or 1200 +-25 each on
   its own, the frame bit for bit with stuffed 0s and a final 0, first frame
   5,000 to 500,000, frames 400,000 to 500,000 apart, line high and still
   between and after (accept 318-390; sheet 38-52, 109-118). All stated.
3. Payload only: receiver number, flags, channel values. Header, packing,
   CRC, stuffing, closing byte, edges and period are the firmware's.
4. Declared adjustments (README 122-145): one falling edge added at the end
   of the decoder's copy (the decoder ends the last bit only on the next
   frame's fall), the decoder's "Header error" after a stuffed 0 that
   follows the CRC, and its nibble-swapped channel text. Each is necessary,
   and the pin check reads the real line bit for bit with the stuffed 0
   required and the line high at the end, so none can pass a wrong
   waveform (faults `nocrcstuff`, `nibbles` fail).
5. Feasible, hard (README 212-240). Not impossible: with `crc_poly` 0x8000
   from 0 the CRC register is a 16-bit exclusive-or accumulator (16 bits fed
   in, then 16 more, read back as their XOR; checked here on 2000 random
   pairs), which with the table's eight one-bit columns gives FrSky's
   byte update, and a bit lasts 800 to 1200 cycles. The judge ignores
   P1 to P7, so spare pins are also available as bits. Optional note:
   lines 100-103 define the table a second time by "eight steps of
   c = (c >> 1) XOR (0x8408 if c is odd)", which is the CRC register's own
   step; it is also the standard way such tables are generated, so it can
   stay.

## qspi: OK

1. Fairness. SCK low by 100 and whenever CS# is high and in every CS# change
   cycle; CS# high at the end; two frames per page with exact rises and the
   wanted bits (IO0 only in single-line phases); no IO change in an SCK-rise
   cycle; at most 20 cycles between CS# fall, rises and CS# rise; 3 to 1000
   and 150,000 to 200,000 between frames; first fall by 10,000 (accept
   198-326; sheet 78-111). The marked maxima are the sheet's own and only
   bound when things happen. All stated.
2. Payload only: address and data bytes, the last-byte flag. The narrowing
   to multiples of 4 data bytes (sheet 159-161) has its reason in README
   92-94 and 149-150 (`smart_qspi` reports only whole 8-edge groups, so a
   page of 6 bytes decodes as 4); it holds. Write-only with a fixed
   worst-case wait is stated (sheet 67-71) with its reason (README 26-30).
3. Declared judge behaviour (README 74-98): `qspi` compared on IO0's bits in
   single-line phases, `smart_qspi` run with `twolinesmode=qspi`. Both
   decoders must pass, as PREREG2 requires. The pin check holds every bit
   separately. Sound.
4. Port: annotation tuples and `matched` tests in both decoders; mechanical.
5. Feasible: two instructions a nibble with side-set; 20-cycle budget for the
   byte fetch.

## st7789: FIX (X2 only)

1. Fairness. Decoder list and the direct check (hidden/st7789/README.md
   99-109): CSX high at 0 and at the end, one CSX pulse per transfer, whole
   SCL pulses in multiples of 8, every limit of the table in whole cycles
   (README 59-70; sheet 67-80), D/CX low for the command byte only, the
   budget of 100 cycles a byte plus 2000 (sheet 94-97). All stated.
2. Payload only, with one remark: bit 8 says "command byte", which sets
   D/CX's level, and bit 9 says where CSX rises. The firmware cannot know
   either from the byte values (any value may be a command), so both are
   content, not coding, and this is round 1's pilot st7735 interface on
   purpose (README 44-49). README line 209 calls bit 8 "the D/CX level";
   "which bytes are commands" would describe it better. Not a defect.
3. No decoder adjustment and no port (validate checks the folder is
   unchanged).
4. Feasible with room to spare (32 cycles a byte is the floor, 100 allowed).
- FIX: X2 (lines 82-84 and 55-57).

## Out of reach: ir_irmp

The note (hidden/ir_irmp/OUT_OF_REACH.md) is right. `decoders/ir_irmp/
irmp_library.py` loads `libirmp.so` with ctypes; `ldconfig -p` and a
filesystem search find no `libirmp`; the installed library is
libsigrokdecode4 0.5.3-4build3, whose `.so` exports no `irmp` symbol.
Run here on a 1 MHz capture,
`sigrok-cli -P ir_irmp:ir=0 -A ir_irmp` fails at `decode()` with
"libirmp.so: cannot open shared object file", exactly as the note quotes.
Building that native library is not a mechanical change, so PREREG2's
"Judges that do not run" rules it out. The protocol itself would have been
easy for the chip, as the note says; RESULTS2.md should count it as "no
runnable judge", not as a failure.

## Smaller notes

- Several protocols need an exclusive-or the instruction set does not have
  (can_fd stuff-count parity, fsi inverted bits and CRC-4, mipi_dsi ECC,
  mipi_rffe parity, pxx1 CRC). The CRC register is the only XOR, and its
  polynomial is one value per hand-in. As in round 1, a failure there is the
  instruction set being tested, not a sheet problem, and RESULTS2.md should
  say so.
- Every README's feasibility section says plainly that no firmware was
  written. The predictions in PREREG2 (fsi and can_fd likeliest to fail)
  should be read beside the examiners' own (can_fd, mipi_dsi and pxx1 the
  hardest).
