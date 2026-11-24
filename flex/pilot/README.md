# Pilot for the flexibility census, 23 November 2026

A trial run of the method in [`../PREREG.md`](../PREREG.md), made to find
faults in the rules before they were fixed. It found one. These three
protocols are reported here and are not part of the census count.

## What was tried

Three protocols this project had never targeted, the first three of
sigrok's eligible decoders when sorted by the SHA-256 of `main`'s commit at
the time (`b64055ffe2f678f2dd9fded450df2afb19c275a3`), a colon, and the
decoder's name:

- `st7735`: the serial interface of the Sitronix ST7735 display controller
  (clock, data, data/command and chip select; the chip is the host).
- `spdif`: S/PDIF digital audio on one pin, biphase-mark coded, with
  preambles, channel status and parity.
- `miller`: Miller (delay) coding on one pin, in framed messages.

All three are transmitters: the simulator could not change input pins over
time when the pilot ran.

Each was attempted on three versions of the chip: the full instruction
set, the chip without the per-instruction delay field, and the chip without
side-set. The cut-down versions are the same simulator behind a wrapper
that refuses programs using the removed feature
([`variants/`](variants/README.md)), with an instruction-set document that
does not describe it.

## Who did what

- An **examiner** (an AI agent with the repository) wrote each task sheet
  and a hidden test, and showed the test passing a correct waveform and
  failing broken ones before any firmware existed. It wrote no firmware.
  The validation is recorded in each `hidden/README.md`.
- A **programmer** (a fresh AI agent session) was given a folder with the
  task sheet, the instruction-set document and the simulator, and told to
  read nothing else. It ran on the same machine as the repository, so that
  was an instruction and not a sandbox. Each `notes.md` is the programmer's
  own account. None reports opening anything outside its folder; the slips
  they report are a directory listing that showed where the simulator link
  pointed, and long tool output saved outside the folder and not opened.
- The **hidden test** hands the pins to sigrok's decoder and checks the
  timing limits the decoder does not. Every result below was run again by
  the session that organised the pilot, after checking the simulators were
  unchanged.

## Round one, and the fault it found

Six attempts (`st7735` and `miller` on the three chips). All six passed.
But the round-one task sheets let the programmer decide what the host's
words meant, and two of the three `miller` programmers moved the line
coding into the host: a two-instruction program that replays pin levels.
That passes any transmit test and measures nothing about the instruction
set. The round-one hand-ins are kept in [`round1/`](round1/).

Round two fixed the host interface in the task sheet: the host sends
payload words only, and there is no host-side code.

## Round two

Nine attempts, one programmer each. All nine passed the hidden test on the
first hand-in.

Program length in instructions:

| Protocol | Full chip | No delay field | No side-set |
|---|---|---|---|
| `st7735` | 13 | 18 | 19 |
| `miller` | 28 | 50 | 27 |
| `spdif`, 48 kHz | 61 | 86 | 59 |

- The `spdif` program without the delay field spans two pages of program
  memory: 104 words with padding.
- `st7735` line rate, clock cycles per byte in the test's last case: 40.5
  on the full chip, 39.6 without the delay field, 44.7 without side-set.
  `miller` and `spdif` run at the rate the task sets.
- Simulator runs before handing in: 8 to 30.

## What it shows, and what it does not

- Programmers who had never seen the chip made it speak three protocols it
  was not designed for, first time, as judged by a decoder this project did
  not write.
- Neither feature was necessary for these protocols. Removing the delay
  field cost 38% to 79% more instructions. Removing side-set cost 46% on
  the protocol with a clock pin and nothing on the two one-pin protocols.
- There is one programmer per cell, so a difference of one or two
  instructions means nothing.
- No receiver was tried.
- The programmers are AI agents that know the RP2040's PIO, and several
  guessed this chip's assembler syntax from it.

## What the programmers found wrong

Their notes agree on these, and each was fixed before the census:

- `docs/isa.md` gave no assembler syntax: labels, comments, the `[n]`
  delay, where `side V` goes.
- It gave no reset state for the registers, and did not say which bit of a
  multi-pin write lands on which pin.
- Its encoding section said `set` with destination 3 and `mov` with
  location 6 do nothing. They are `set page` and `crc`.
- The assembler rejected a jump to a label written with a capital letter.

## Files

- `<protocol>/TASK.md`: the round-two task sheet.
- `<protocol>/hidden/`: the hidden test (`accept.py RUN_DIR [seed]`), its
  ideal-waveform generator and its validation.
- `<protocol>/<chip>/`: the hand-in: the program, `run_args.txt` and the
  programmer's `notes.md`. To run a hidden test again, put the simulator in
  the hand-in's folder as `pe_sim` (for a cut-down chip, the wrapper, with
  the real simulator beside it as `pe_sim.real`).
- `variants/`: the two cut-down instruction-set documents and the wrappers
  (`pe_sim.py`; each expects the real simulator beside it as `pe_sim.real`).
- `round1/`: the round-one task sheets and hand-ins.
