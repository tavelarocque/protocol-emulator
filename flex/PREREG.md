# Flexibility census: rules set before it runs

This file is committed and pushed before any census protocol is attempted.
It fixes what will be tried, in what order, who writes what, how each
attempt is judged, and what will be counted. The results go in
`flex/RESULTS.md` afterwards, failures included.

## The question

The competition asks whether the chip can be reprogrammed for protocols it
was not designed for. The 50 protocols in the README were chosen by this
project, so they cannot answer that. The census takes protocols from a list
this project did not write, has them programmed by someone who has never
seen the project, and has them judged by a decoder this project did not
write.

A second question rides on the first: what is each feature of the
instruction set worth? Some protocols are attempted again on a chip with
one feature removed.

## The list

The source is the decoder list of sigrok-cli 0.7.2 (111 decoders). A
decoder is eligible if all of these hold:

1. It reads pins (its input is `logic`), not the output of another decoder.
   60 decoders.
2. It decodes a protocol. Measuring tools are out: `counter`, `graycode`,
   `guess_bitrate`, `jitter`, `signature`, `timing`, `parallel`.
3. Its protocol is not already one of the 50 in the README: `am230x`,
   `can`, `cec`, `dali`, `dmx512`, `em4100`, `i2c`, `i2s`, `ir_nec`,
   `ir_rc5`, `ir_rc6`, `jtag`, `mdio`, `microwire`, `morse`,
   `onewire_link`, `ps2`, `pwm`, `qi`, `rgb_led_ws281x`, `spi`,
   `stepper_motor`, `swd`, `tdm_audio`, `tlc5620`, `uart`,
   `usb_signalling`, `wiegand`.
4. Its required channels fit the chip's 8 protocol pins: `gpib` and
   `ieee488` are out.

That leaves 23: `ac97`, `aud`, `avr_pdi`, `dcf77`, `dsi`, `em4305`,
`flexray`, `iec`, `lpc`, `maple_bus`, `mcs48`, `miller`, `ook`,
`rc_encode`, `sda2506`, `sdcard_sd`, `seven_segment`, `spdif`, `st7735`,
`swim`, `t55xx`, `usb_power_delivery`, `z80`.

Three of them, `st7735`, `spdif` and `miller`, were used in a pilot on
23 November 2026 to find faults in these rules (it found one: see "Host
interface"). They are reported separately as the pilot and are not part of
the census count. The census is the other 20.

## The order

The order is set by a value nobody can know when this file is pushed: the
randomness of the first round of drand's default mainnet chain published at
or after 2026-11-26 00:00 UTC. The 20 decoder names are sorted by the
SHA-256 of that value in hex, a colon, and the name. The round number and
value are recorded in `flex/RESULTS.md`. The order decides which protocols
are used for the second question, and which are left out if time runs out;
every protocol attempted is reported.

## Who writes what

Three roles, never the same session:

- **The examiner** has the repository. For one protocol it writes the task
  sheet (the protocol's rules and timing limits from its public
  specification, the clock, the pins, the exact words the host will send)
  and a hidden test. The hidden test hands the recorded pins to sigrok's
  decoder and requires the decoded content to equal what was sent; it also
  checks, from the pins, the timing limits the decoder does not. Before any
  firmware exists, the test must pass a correct waveform and fail at least
  two broken ones. The examiner writes no firmware.
- **The programmer** is a fresh AI agent session given a folder holding
  only the task sheet, `docs/isa.md` and the simulator `pe_sim`. It is told
  to read and write nothing else. It runs on the same machine as the
  repository, so this is an instruction and not a sandbox; its notes record
  everything it read and ran. It may run the simulator up to about 80
  times. It never sees the hidden test.
- **The judge** is the hidden test, run once on the hand-in, and run again
  by the session that organises the census.

If the examiner finds that a protocol cannot be attempted at all (it needs
more than 8 pins in practice, or a line rate above what a 50 MHz clock can
produce), it says why, and the protocol is reported as out of reach, with
the reason. It is not dropped from the report.

## Host interface

The task sheet fixes the words the host sends, and they carry payload
only. There is no host-side code. The pilot's first round let the
programmer choose what the words meant; two programmers then moved the
line coding into the host and handed in a two-instruction program that
replayed pin levels. That passes any transmit test and says nothing about
the instruction set.

## What counts

- A protocol **passes** if the first hand-in passes the hidden test on the
  full chip. There is no second hand-in.
- Passes are added to the README's count only with this file and the
  results beside them, under the label "written blind".
- Receivers are attempted as well as transmitters. The simulator gains an
  option to change input pins over time before the census starts; nothing
  in the chip changes.

## The second question

The first 8 protocols in the order that pass on the full chip are attempted
again, by new programmers, on two cut-down chips: one without the
per-instruction delay field, one without side-set. Each of the three
versions gets two programmers per protocol. The cut-down chips are the same
simulator behind a check that refuses programs using the removed feature,
and an instruction-set document that does not describe it.

Reported for each: pass or fail, program length in instructions, memory
words used, and line rate.

## What is frozen

The chip is v2.3 as on `main`. Before the census starts, `docs/isa.md` and
the assembler are corrected for the faults the pilot's programmers
reported, and that commit is recorded in `flex/RESULTS.md`. Nothing in the
kit changes after the first census attempt.

## Prediction

Written before the order is known: 12 to 16 of the 20 pass on the full
chip. Likeliest to be out of reach or to fail: `flexray` (10 Mbit/s),
`z80`, `mcs48` and `lpc` (wide buses), `ac97` and `sdcard_sd` (fast
clocked buses with replies).

## What this cannot show

- The programmers are AI agents, of the same family as the assistant this
  project was built with. A person is the better test.
- They know the RP2040's PIO, and several pilot programmers guessed this
  chip's syntax from it. The result is about programmers who know that
  kind of chip.
- Everything runs on the reference model, not on hardware.
