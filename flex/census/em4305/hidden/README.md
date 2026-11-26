# Hidden test: EM4305 RFID reader (transmit)

This folder is the examiner's side for the census protocol `em4305`. The
programmer gets only the kit (`../../kits/em4305/`: `isa.md`, `pe_sim`,
`TASK.md`) and never sees this folder until the firmware is handed in. No
firmware for the chip was written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal EM4305 reader as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## The role: TRANSMIT

sigrok's `em4305` decoder reads only the reader-to-tag direction: Login and
Write word commands sent as gaps in the 125 kHz field. It has no decoding of
the tag's replies. So the chip is what a small microcontroller is in a real
EM4305 reader: it drives the coil (here P0, a 125 kHz square wave, held low
while the field is off) and gates the carrier to send commands. A scripted
tag reply would have nothing to be judged against, so BOTH was not chosen.

## What the decoder really does (read from its source)

The decoder looks only at the time between edges, never at levels, with
thresholds in field clocks (one carrier period, 80 samples at 10 MHz):

- A stretch of more than 40 periods with no edge, while it is searching, is
  the first field stop; then a stretch of more than 12 periods with no edge
  is a write gap.
- At each gap it measures the field-on time since the previous gap. Between
  15 and 27 periods: one 0. Between 32 and 300 periods: int(on / 32) ones,
  and then one 0 if the gap itself lasted between 15 and 27 periods. Anything
  else adds nothing.
- 300 periods without a gap ends write mode, and only then does it report
  the fields (command name, address, data bytes, parities, stop bit,
  password) of a 50-bit (Login) or 57-bit (Write word) command.

The task sheet's bit shapes are the ones that make every bit sequence decode
with these rules and the default options: a 1 is 32 periods of field, a 0
is 16 periods on then 16 off. Measured from edges, the on time of a 0 reads
15.5 periods and its gap 16.5, both inside 15 to 27. Two consequences are
written into the task sheet:

- Before each command the field must be on for at least 320 periods, or the
  field-on time before the field stop (under 300 periods) is read as ones,
  and the decoder never leaves write mode after the previous command. After
  the last command it must stay on for 320 whole pulses, or the last
  command's fields are never reported.
- Nine 1 bits in a row put 9 x 32 + 15.5 = 303.5 periods between gaps, over
  the decoder's 300: it drops out of write mode in the middle of a command.
  Real EM4305 tags accept such values; this decoder cannot. The judge never
  sends a value that puts nine 1 bits in a row on the line (`readable`),
  and the task sheet says so and says it needs nothing from the firmware.
  Random values that would are drawn again; fixed cases include runs of
  exactly eight.

The bit order is the decoder's: command code as `0011` (Login) and `0101`
(Write word), address bit 0 first, the value least significant byte first
with each byte most significant bit first, so that the decoder's "Data: XX"
lines and "Login password: XXXXXXXX" equal the host's bytes and value.

## The host interface, as the task sheet states it

Three 16-bit words per command: `0x0000` for a Login or `0x0100 | address`
for a Write word; then bits 15..0 of the 32-bit value; then bits 31..16.
The sheet's example: a Login with 0x12345678 then a Write word of 0xDEADBEEF
to address 4 are the words 0x0000, 0x5678, 0x1234, 0x0104, 0xBEEF, 0xDEAD.
The sheet says: "The host sends only the words defined above. All line
coding, framing and timing must be done by the firmware." The carrier, the
field stops, the command codes, every parity bit, the stop bit and the
field between commands come from the program. The hand-in is `em4305.s`,
`run_args.txt` (one line, `-config` and `-mode` flags only) and `notes.md`.

Clock 10 MHz (100 ns a cycle), so a carrier half period is 40 cycles, a
period 80, a bit 2560, the first field stop 4400.

## What the judge does

Seven fixed cases and eight seeded random ones, 1 to 6 commands each,
Logins and Write words to all 16 addresses (including 2, 4, 5 and 6, which
the decoder annotates further). For each it builds the TX words itself
(`tx_words`), runs `RUN_DIR/pe_sim run RUN_DIR/em4305.s -tx FILE -cycles N`
plus `run_args.txt`, turns P0's changes into a VCD at one sample per cycle,
and applies two checks.

**The decoder check** runs `sigrok-cli -P em4305:data=P0` (default
options) four times, once per group of annotation classes, so its texts
cannot be confused (the EM4100 nibble annotations can read "0" or "1"). It
requires exactly as many "First field stop" and "Write mode exit"
annotations as commands, and for each command, between the two: exactly
the command's bits (the bit annotations), the opcode row exactly (command
name, every "Row parity OK", "Zero bits" for a write, "Column parity OK",
"Stop bit"), the address row exactly ("Addr: n" for a write, then the four
"Data: XX"), and "Login password: X" for a Login ("Write password: X" for a
write to word 2). No bit annotation may fall outside a command.

**The waveform check** holds what the decoder does not:

- P0's first change is a fall by cycle 200, and the low after it lasts
  40 +-2 cycles like every other low between pulses (the reset-high
  stretch before it is not checked). Review on 24 November found the
  sheet did not say this; the sheet now states it.
- First field stops are lows of more than 3000 cycles; there must be one
  per command. Inside each command (the last pulse before its field stop,
  every pulse of its bits, the rise that ends the stop bit) every edge is
  within +-2 cycles of its ideal place counted from the rise ending the
  field stop. That also fixes the field stop at 55 periods, the 16/16 shape
  of a 0 and the carrier phase inside a command.
- Outside commands every high and every low between pulses lasts 40 +-2
  cycles: no stray gaps, glitches or missing pulses.
- The field is on 25600 to 102400 cycles (+-2) before each field stop,
  counted from the previous command's closing rise, or from P0's first
  rise.
- At least 320 complete pulses after the last command. After that P0 may
  stop at either level (a firmware stalled on `pull` when the words run
  out) or carry on.

It then prints `RATE bytes=<4 x commands> cycles=<from P0's first change
to the rise that ends the last command's stop bit>` for the last passing
case. This differs from the brief's "first to last pin change" on purpose:
the carrier may run on after the last command, so the last pin change can
be the end of the run and would say nothing about the firmware. The span
includes the field-on time the firmware chooses before each command.

A simulator error or an exception inside the judge is a failure, never a
pass.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`). Rerun on
24 November after the sheet was made to state the first low's limit and
after the kit's `isa.md` was replaced (input synchronisers now stated to
reset to 1, which does not touch a transmitter); same result.

- Interface: `tx_words` gives exactly the six words printed in the task
  sheet, and `frame_bits` gives exactly the 50 and 57 bits printed there;
  the stand-in reads the judge's words back into the same commands.
- Waveforms: 37 waveforms on 5 seeds, 185 verdicts, all as expected. The 8
  that must pass do: ideal; every edge inside commands 2 cycles off (the
  limit); carrier highs 42 and lows 38 outside commands (the limit);
  exactly 320 periods before each command and 320 pulses after the last;
  1280 periods before each command; first fall at cycle 200; carrier
  running on to the end; P0 stopping high. The 29 broken ones all fail: a
  flipped data bit with its parities made to match, a wrong row parity, a
  wrong column parity, bytes least significant bit first, bytes in the
  wrong order, the address most significant bit first, the command codes
  swapped, no leading 0, no stop bit, one edge 3 cycles late, one 3 early,
  one idle high of 43, one idle low of 37, 81-cycle carrier periods, field
  stops of 54 and of 56 periods, 0 bits shaped 15/17 and 17/15, 319 and
  1281 periods before a command, 319 pulses after the last, the field
  stopping at once after the last, first fall at 201, a first low of 160
  cycles before the carrier starts, no carrier until cycle 400, a one-cycle glitch in a 0's gap, two missing carrier pulses,
  the last command missing, the last command sent twice. The data, order
  and framing faults are caught by both checks; the timing faults by the
  waveform check alone (the decoder's windows are far wider than +-2
  cycles), as the table in `selftest_output.txt` shows.
- RATE: for the ideal waveform the line equals the figure worked out from
  the generator's own layout, on every seed (seed 1:
  `RATE bytes=4 cycles=164440`).
- Hand-in rules: eight bad `run_args.txt` files (`-tx`, `-t`, `-cycles`,
  `-inputs`, `-stimulus`, an ambiguous `-c`, two lines, a flag with no
  value) were each refused as a setup failure, and two good ones accepted.
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin. It is
  not EM4305 firmware. The simulator accepted the command line and the word
  file, and all 15 cases failed cleanly ("P0 never changes"), with no RATE
  line.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the simulator into the run folder themselves.
- `run_args.txt` can hold configuration constants (`clkdiv`, `timeout`,
  the CRC register's `crc_poly` and `crc_init`). They are the chip's own
  hardware, but a CRC polynomial chosen to fold the bytes into the column
  parity is worth noting when hand-ins are compared; `notes.md` and the
  configuration line should be read.
- Values with nine 1 bits in a row on the line are never sent, so a
  firmware that mishandled only those would pass.
- The carrier's phase is checked inside commands, but between commands only
  pulse by pulse: a carrier that drifts by 2 cycles a half period between
  commands passes.
- The tag's side (power-up, the replies after a command, the timing the tag
  needs before replying) is not modelled. Read word, Protect and Disable
  are not sent: the decoder reports fields only for 50- and 57-bit
  commands.
- A slow host is never provoked: the simulator refills the FIFO at once.
- Everything runs on the reference model, not on hardware.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, and that
it is harder than the pilot's `miller`. One thread has to keep a 125 kHz
carrier going without a break (an edge every 40 cycles, inside commands on
a grid with +-2 cycles of slack for the whole 146,000-cycle command) while
it pulls three words, sends the command code and address, works out four
row parities and an 8-bit column parity, and counts 16 or 32 periods a
bit. 40 cycles between edges is room for several instructions, so the work
can be spread over the half periods, but every path (a 0 or a 1, a parity
branch, a `pull`) must cost the same, which the programmer has to count.
Two things look awkward. The value arrives least significant byte first
but each byte goes out most significant bit first, which neither shift
direction gives directly; reversing a byte through the ISR (shifting in
the other way) or keeping the order in the control flow both seem to work.
And the column parity is an exclusive OR of four bytes on a machine with no
exclusive OR: the CRC register, set to x^8 + 1, folds a bit stream into
exactly that, or it can be done bit by bit in the control flow. With X, Y,
OSR and ISR all in use, the parity of the current row probably has to live
in the control flow (two copies of the row loop). 256 words of memory leave
room for that.
