# Hidden test: T55xx reader downlink (sigrok `t55xx`)

The examiner's side of the census for `t55xx`. The programmer gets only the
kit (`../../kits/t55xx/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees
this folder. No firmware for the chip was written for this test, not even
as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal.py` | an ideal reader waveform generator, with named faults, called like `pe_sim`. Not chip firmware |
| `validate.py` | checks the judge end to end (interface, waveforms, RATE, hand-in rules, the real simulator) |
| `validate_output.txt` | its output on seeds 1, 2 and 3 |

## The role: TRANSMIT

sigrok's `t55xx` decoder reads one line and decodes the reader-to-tag
direction of a T5577 link: the reader writes to the tag by switching its
125 kHz field off for short gaps, and the field-on time between gaps is the
bit (about 24 field clocks for a 0, 56 for a 1). The decoder does not
decode the tag's answer at all. So the chip plays the reader, the small
host-side chip that really does this job: P0 drives the antenna driver,
toggling at 125 kHz while the field is on and held low in a gap. It sends
the three commands the decoder knows: standard write (38 bits), protected
write (70 bits) and reset (2 bits).

Clock 10 MHz (one cycle 100 ns): one field clock (FC) is 80 cycles and a
carrier half period 40.

## The host interface, as the task sheet states it

A header word per command: bits 1..0 opcode, bit 2 lock, bits 5..3
address, bit 6 protected write, bit 7 reset, the rest 0. Then for a
protected write the password's high and low halves, then for any write the
data's high and low halves. A reset is 0x0080 alone. The sheet's example:
protected write (opcode 10, password 0x12345678, lock 1, data 0x9ABCDEF0,
address 5), reset, standard write (opcode 11, lock 0, data 0xFFFF0001,
address 2) are the words 0x006E 0x1234 0x5678 0x9ABC 0xDEF0 0x0080 0x0013
0xFFFF 0x0001. The sheet says "The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware." The
words carry the command's fields in a register-like layout, not in line
order: the firmware has to send the opcode from the header, then the
password and data from later words, then the lock bit and address from the
header again.

## What the judge checks

Six fixed cases (writes of all zeros and all ones, the sheet's example, a
reset alone, alternating bits, eight mixed commands) and eight seeded random
cases of 1 to 5 commands (the last one 1 to 8), each command a reset (15%),
a protected write (40%) or a standard write, with random opcode (10 or 11),
lock, address, password and data. For each case:

- It builds the TX words itself from the interface above and runs
  `RUN_DIR/pe_sim run RUN_DIR/t55xx.s -tx FILE -cycles N` plus
  `run_args.txt`, which must be one line of `-config` and `-mode` flags
  only (shortened names resolved as `pe_sim` does; `-tx`, `-cycles`,
  `-inputs`, `-stimulus` and anything else are a setup failure). N is long
  enough for the slowest waveform the sheet allows plus 28000 cycles.
- **Decoder.** P0's changes become a VCD at 10 MHz. sigrok-cli runs
  `t55xx:data=P0:coilfreq=125000:start_gap=8:w_gap=8` (the T5577
  datasheet's minimum gaps; the decoder's other settings at their defaults,
  so a 0 is 16 to 31 FC and a 1 is 48 to 63 FC to it). The annotations of
  the classes start gap, bit value, write mode exit, opcode, password,
  lock, data and address must equal, as a list of texts in order, exactly
  those of the wanted commands: a start gap, every bit, the exit, then the
  fields. Nothing extra: a spurious start gap (for example from P0 sitting
  at its reset level too long), an extra bit or an extra command fails.
  Anything sigrok writes to stderr is a failure.
- **Waveform**, straight from the pin changes, the limits the decoder does
  not hold:
  - P0 first changes by cycle 400 (the decoder would take a longer wait as
    a start gap);
  - every interval between neighbouring changes is a carrier half period
    of 38 to 42 cycles, or a gap of 800 cycles or more with P0 low;
  - start gaps 800 to 4000 cycles, write gaps 800 to 2400, both edge to
    edge;
  - each bit's field-on time (rise ending a gap to fall beginning the next)
    is 1440 to 2320 cycles for a 0 and 4000 to 4880 for a 1, which is two
    FC inside the decoder's own windows at each end;
  - 8000 to 80000 cycles of field on before every start gap, counted from
    the first change or from the end of the previous command's last gap;
  - at least 8000 cycles of field on after the last command's last gap;
    after that the line may keep toggling or stop, but any later change
    must again be a half period or a valid command;
  - the bits read this way equal the wanted commands, in order, nothing
    extra.
- It prints `RATE bytes=<payload bytes> cycles=<cycles from P0's first
  change to its last>` for the last passing case. Payload bytes are 4 per
  32-bit field (data, password), 0 for a reset.

A simulator error or an exception inside the judge is a failure, never a
pass.

## Validation

    python3 -B validate.py 1 2 3

Result: `VALIDATE PASS`, 105 checks, nothing wrong (`validate_output.txt`).

- Interface: `tx_words` gives exactly the nine words printed in the sheet,
  the sheet holds the required host-interface sentence, and `ideal.py`'s
  own reader of the words (written apart from `tx_words`) turns them back
  into the bits `accept.py` expects, 70, 2 and 38 of them, with the opcode,
  lock and address bits in the places the sheet lists.
- Waveforms, each through the whole of `accept.py` on 3 seeds (75 runs):
  the 6 that must pass do (ideal; half periods all 42; all 38; every
  length at its shortest limit; every length at its longest limit; the
  line stopping after the last tail). The 19 broken ones all fail: a
  flipped data bit, data least significant bit first, the lock bit left
  out, half periods of 43 and of 37, a 10-cycle glitch, a 0 of 1439
  cycles, a 1 of 4881, write gaps of 799 and 2401, a start gap of 4001,
  gaps held high, a final tail of 7999, 7999 and 80001 cycles between
  commands, a first change at cycle 401, the last command missing, the
  last command sent twice, and no start gap.
- Which check objects (on the sheet's example): the decoder alone catches
  wrong content (flipped bit, bit order, missing lock bit, missing or extra
  command, missing start gap), and the waveform check catches those too.
  Every timing fault (carrier half period, glitch, the bit, gap, lead and
  tail lengths, a gap held high, a late start) passes sigrok's decoder and
  is caught only by the waveform check. So each half of the judge is
  needed.
- RATE: for the ideal waveform the line equals the figure worked out from
  the generator's own list of changes, on every seed.
- Hand-in rules: nine bad `run_args.txt` contents refused, a two-line file
  a setup failure end to end, three good ones accepted.
- The real simulator: the kit's `pe_sim` with a one-instruction program
  that loops and drives no pin (not T55xx firmware). It accepted the
  command line and the words, and all 14 cases failed cleanly ("P0 never
  changes"), with no RATE line.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must put
  the real simulator (or the census wrapper) there.
- Only P0 is looked at. Other pins may do anything.
- Commands sent in one run are at most 8; a slow host is never provoked
  (the simulator refills the FIFO at once), so what the firmware does to
  the field while waiting for a late word is not tested. A firmware that
  stops the carrier while it waits for the next command would make a
  spurious gap on a real host; here the words are always there.
- The tag's side is not modelled: no answer, no check that the commands
  make sense to a real T5577 (for example, writes to block 0 with silly
  configurations are sent like any other). The decoder decodes only the
  reader-to-tag direction, so neither can be judged by it.
- The judge's windows are tighter than the decoder's and than the T5577
  datasheet's in places (a carrier of 125 kHz +-5%; bits and gaps two FC
  inside the decoder's windows), and looser than a real tag's power budget
  in others (the 100 FC lead-in is shorter than some tags need to power
  up). They are stated in the sheet; the judge enforces those.
- RATE: when the firmware keeps the carrier running after the last command,
  as a reader would, the last change of P0 is near the end of the run, so
  the cycles figure then measures the run length the test chose, not the
  firmware's speed. It differs between hand-ins only in how long they
  make the lead-ins, gaps and bits within the limits, and only when the
  line is stopped after the last command. For comparing speed, the time
  from the first change to the end of the last command's last gap would
  be the fairer figure; the brief asks for first to last change, and that
  is what is printed.
- `run_args.txt` can hold any constants the host writes into the
  configuration (`clkdiv`, `timeout`, ...): that is the chip's own
  hardware, but should be read when hand-ins are compared.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, with
care. A half period is 40 cycles, more than one instruction's delay field
(16 ticks), so either several instructions make up each half period or
`clkdiv` stretches every tick alike (with `clkdiv` 5 a half period is 8
ticks, with 10 it is 4). No instruction toggles a pin, so the carrier's
level lives in the control flow: the natural shape is a loop whose body is
one full period, high then low, with the work for the next bit (an `out`,
a `pull`, a test) folded into the idle ticks of that period. The windows
are wide for bits and gaps (hundreds of cycles) but narrow for the carrier
(+-2 cycles per half), so every path through the loop, including the ones
that fetch a word or start a gap, must cost the same ticks per half
period. Counts run above the 5-bit `set` immediate (a 1 is about 56
periods, the lead-in at least 100), so the programmer needs nested loops
or counts shifted out of a word. The header is needed both before and after
the 32-bit fields, so it has to be parked (in the ISR or a spare register)
while the OSR carries the password and data. The 256-word memory is ample.
The hard part is the cycle accounting, not anything the chip lacks.
