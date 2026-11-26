# mcs48: out of reach

Decoder: sigrok `mcs48` (libsigrokdecode, as shipped with sigrok-cli 0.7.2),
"Intel MCS-48 external memory access protocol". No TASK.md was written and
no hidden test was built, as the examiner brief requires for a protocol
that cannot honestly be attempted.

## The reason: it needs at least 10 pins, the chip has 8

The protocol is the external program memory bus of the Intel 8048 family
(8035, 8039, 8048, 8049 and relatives). In a fetch from external program
memory the CPU:

1. puts the low 8 bits of the address on its 8-bit BUS (DB0 to DB7) and the
   high 4 bits on P20 to P23, and latches them with a falling edge of ALE;
2. floats BUS and pulls /PSEN low; the memory drives the instruction byte
   onto the same 8 lines, and the CPU takes it as /PSEN rises.

The decoder follows exactly this. Its source (`decoders/mcs48/pd.py`)
waits for `ALE` falling or `/PSEN` rising, reads D0 to D7 on both edges
(as the low address on the first, as the data byte on the second) and reads
A8 to A11 on the ALE edge. `sigrok-cli -P mcs48 --show` lists 14 required
channels: ALE, /PSEN, D0 to D7, A8 to A11 (A12 optional). Given only 8 of
them, sigrok-cli stops with "Required channel 'd6' (index 8) was not
specified" (checked in this session).

The count, whichever role the chip plays (the CPU side driving ALE, /PSEN
and the address, or the memory side answering on /PSEN):

| Signals | Lines |
|---|---|
| ALE strobe | 1 |
| /PSEN strobe | 1 |
| multiplexed address/data bus, sampled in parallel on one edge | 8 |
| high address A8 to A11 | 4 |
| Total the decoder requires | 14 |
| Least a real bus could use (only 256 bytes of program memory, A8 to A11 tied off) | 10 |
| Protocol pins on the chip (`isa.md`: "Pins: 8") | 8 |

Even in the smallest real system, with the high address lines tied to a
fixed level and so absent from the chip, the bus is two strobes plus eight
parallel data lines: 10 pins, 2 more than the chip has. The 8 bits are a
parallel byte captured on a single edge, so they cannot be sent over fewer
lines one after another. The only way to fit 8 pins would be to put a
strobe and a data bit on the same wire in the test harness, or to fake
data lines as constants in the capture, and neither is an instance of the
bus a real 8048 or its memory would accept. That would be the weakened
task the brief forbids.

Speed is not the obstacle. An 8048 at its usual 11 MHz crystal runs a
machine cycle of 15 oscillator periods, 1.36 us, with one ALE per cycle:
about 68 cycles of a 50 MHz core. A chip with 14 pins could plausibly
do it; this one has 8.

## A note for the census organiser

PREREG.md rule 4 ("Its required channels fit the chip's 8 protocol pins")
excluded `gpib` and `ieee488` but kept `mcs48`, whose decoder requires 14
channels, so by the rule as written `mcs48` should not have been eligible.
The same may apply to `z80` (wide address and data buses), which I have
not examined. PREREG's own prediction already named `mcs48` as likely out
of reach for its wide bus. Per PREREG, it is reported as out of reach with
this reason rather than dropped.
