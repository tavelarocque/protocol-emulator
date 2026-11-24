# Notes: ST7735 write-only host on the protocol emulator

## What I read

Only files in this directory: `TASK.md` (whole), `isa.md` (whole), and the
output of `./pe_sim run ... -help`. Nothing else on the machine, no web.
The files `isa.md` points to (`model/...`, `hw/...`, `docs/info.md`) were
not looked for. General knowledge used: the RP2040 PIO (side-set, delay
written as `[n]`, `out`/`pull`) and the ST7735 4-line serial interface.

## Design

One TX word per byte sent. The host does all the thinking about transfer
boundaries, so the firmware has no data-dependent branch at all: every word
is played the same way.

Config: `out_base=0 out_count=4` (P0 SDA, P1 SCL, P2 D/CX, P3 CSX),
`sideset_base=1 sideset_count=1` (SCL is driven by side-set, which wins over
the SCL position of any `out`), `out_msb_first=1`. P0 to P3 push-pull.
Threshold, autopull and set pins are not used.

Per word, 37 cycles (925 ns per byte, against the 200 cycles allowed):

1. `pull` (stalls here with SCL low when there is nothing to send).
2. `out pins, 4`: writes CSX, D/CX, (SCL, ignored), SDA in one cycle. CSX
   goes low (or stays low), D/CX takes its level for the byte, SDA = bit 7.
3. Eight clock pulses, 2 cycles low and 2 cycles high each (100 ns period).
   Bits 6 to 0 follow with `out pins, 1`, changing SDA on the falling edge.
4. `nop side 0 [1]`: SCL low for 2 cycles after the eighth pulse.
5. `out pins, 4` again: the pin state after the byte. The host puts CSX = 1
   here on the last byte of a transfer and CSX = 0 otherwise, and repeats
   D/CX and bit 0 so that neither line moves.

A leading `nop side 0 [1]` outside the loop takes SCL low at once after
reset, because the output register resets to all ones.

Measured margins (my checker, minima over all runs, in ns): TCSS 50,
TCSH 50, TCHW 75, SCL period 100, TSHW 50, TSLW 50, TSDS 50, TSDH 50,
TDCS 750, TDCH 125.

## Every run of pe_sim (19 in total)

1. `./pe_sim run t0.s -help` (t0.s was a one-line `nop`, since deleted):
   read the flags.
2. `./pe_sim asm st7735.s`: first draft assembled first time. This told me
   the delay syntax `[n]` (a guess from PIO, not in isa.md) is accepted, and
   the hex showed side and delay landing in the delay field as expected.
3. `./pe_sim run st7735.s <run_args> -tx tx1.txt -cycles 400` on three small
   transfers. Read the printed pin changes by hand, bit by bit, for
   0xA5, 0x3C, 0x81, 0x00, 0xFF, 0xFF. All correct. This run answered my
   three open questions (see "confusing" below).
4. `python3 check.py small` (each check.py call is exactly one `pe_sim run`
   with `-cycles 200*bytes+2000`): PASS, but TCSH was 25 ns, one cycle.
   I then added one delay cycle to the `nop` after the eighth pulse for
   margin (36 to 37 cycles per byte).
5. to 9. check.py `small`, `one_empty`, `allvalues` (every byte value as a
   command with no data, as a command with one data byte, and as data),
   `big` (three 600-byte transfers plus an empty one), `init` (a realistic
   init sequence with a 600-byte pixel burst): all PASS.
10. to 14. check.py random seeds `1`, `2`, `3`, `4`, and `small` again (to
   save its raw output for the mutation test): all PASS.
15. `./pe_sim asm st7735.s | wc -l`: 9 words.
16. and 17. `./pe_sim asm` before and after adding comments to the source,
   compared with `cmp`: identical code.
18. and 19. check.py seed `5` and `one_empty` on the final file: PASS.

`mutate_test.py` runs no simulator. It breaks the saved output of the
`small` case in seven ways (CSX left low, a flipped data bit, D/CX wrong, a
short SCL pulse, CSX rising with SCL, SDA moving on a rising edge, CSX high
for one cycle) and confirms my decoder reports each one.

## Mistakes and near misses

- No functional bug was found: the first draft decoded correctly on its
  first run. I did not have to change the logic.
- The first draft had only one cycle (25 ns) between the last falling edge
  of SCL and the rising edge of CSX. That meets the 15 ns limit as the test
  measures it, but I widened it to two cycles.
- The design rests on a behaviour isa.md does not state: `out pins, 1` with
  `out_count=4` writes one pin and leaves the other three alone. I had a
  fallback ready (D/CX and CSX on `set pins` with two flag bits and
  branches, about 13 instructions) in case it zero-filled the other pins
  as RP2040 PIO does. Run 3 showed it does not, so the fallback was not
  needed. If the real model differs from pe_sim here, this firmware breaks.
- Rule slips: none that I know of. I read and wrote only in this
  directory and ran pe_sim only as `./pe_sim` from inside it. I did run the
  system `python3` for host.py and my checker. Scratch files left here:
  `check.py`, `mutate_test.py`, `tx_check.txt`, `out_check.txt`.

## Limits I know about

- SCL is high for the first cycle of the run (reset state, all ones) and
  falls at cycle 1 with CSX high. The first CSX falling edge is at cycle 4,
  so SCL has been low for 75 ns by then. I cannot avoid the initial high in
  `pe_sim run`, where the pin is push-pull from cycle 0.
- If the host were slow, the chip would wait in `pull` between bytes with
  CSX low and SCL low, which the protocol allows.
- My checker is my own reading of TASK.md, not the acceptance test.

## Result

- Program length: 9 instructions (one start-up `nop`, 8 in the loop).
- Host word format: one 16-bit word per byte, sent from bit 15 down.
  - bits 15..12: pins before the first clock: CSX (always 0), D/CX, 0, bit 7
  - bits 11..5: bits 6..0 of the byte
  - bits 4..1: pins after the eighth clock: CSX (1 only on the last byte
    of a transfer), D/CX, 0, bit 0
  - bit 0: unused, 0
  - D/CX is 0 for the command byte, 1 for data bytes.
  - `word = d<<14 | (b>>7)<<12 | (b&0x7F)<<5 | last<<4 | d<<3 | (b&1)<<1`
- run_args: `-config out_base=0,out_count=4,sideset_base=1,sideset_count=1,out_msb_first=1 -mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp`

## Confusing or missing in isa.md

1. `out pins, n` with n smaller than `out_count`: isa.md says only "written
   from `out_base` up". The simulator writes n pins and leaves the rest of
   the `out_count` range untouched. PIO users will expect the opposite
   (zero fill), and the difference decides whether a design like this one
   works. `mov pins` is documented as writing `out_count` pins, which makes
   the silence on `out` more noticeable.
2. With `out_msb_first`, which bit of an n-bit `out pins, n` goes to which
   pin is not stated. In the simulator the first bit shifted goes to the
   highest pin and the last to `out_base` (the group is right-justified).
3. The assembler's delay syntax (`[n]` after `side V`) appears nowhere.
   The document promises "the assembler syntax" but shows only two lines.
   There is no complete example program in the file itself; the examples
   are in files the reader may not have.
4. The simulator's output is undocumented: `pins CYCLE HEX` prints all 8
   pins, and a write made by the instruction executing in cycle n shows as
   a change at cycle n + 1. The `-tx` file takes decimal numbers; the help
   does not say which base. Input-mode pins read 1 by default.
5. Default values of config fields (threshold in particular) are not in
   the help or in isa.md. I avoided depending on them.
6. The advice for idle-low lines ("enable the thread before making the pin
   push-pull") cannot be followed in `pe_sim run`, so an idle-low clock
   always starts with one high cycle there.
7. I found nothing in isa.md that the simulator contradicts.
