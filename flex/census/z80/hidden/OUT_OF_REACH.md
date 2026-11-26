# z80: out of reach

Examiner's finding, 23 November 2026. No TASK.md was written and no hidden
test exists for this protocol.

## The reason: pins

The chip has 8 protocol pins (docs/isa.md, "Pins: 8"). The Z80 bus cannot
be shown on 8 pins, in any role.

The sigrok decoder itself (`/usr/share/libsigrokdecode/decoders/z80/pd.py`)
declares 11 required channels: the data bus D0 to D7 and the three strobes
/M1, /RD and /WR. Its optional channels are /MREQ, /IORQ and the address
bus A0 to A15, 29 lines in all. It reads every line in the same sample: a
bus cycle is recognised from /M1, /RD and /WR (with /MREQ, /IORQ) and the
byte is taken from D0 to D7 while the strobe is low. So the 11 lines must
be distinct and simultaneous; they cannot be time-multiplexed onto fewer
pins.

Checked with sigrok-cli 0.7.2 on an 8-channel capture: mapping D0 to D7
fails with "Required channel 'm1' (index 8) was not specified", and mapping
D0 to D4 plus /M1, /RD, /WR fails with "Required channel 'd5' (index 5)
was not specified". No assignment of 8 pins satisfies the decoder.

The roles a small chip would really play on a Z80 bus need even more:

| Role | Lines needed in practice |
|---|---|
| Bus master (stand in for the CPU, or drive cycles at a peripheral) | 8 data + 16 address + /M1, /MREQ, /IORQ, /RD, /WR = 29 |
| I/O peripheral (answer IN/OUT on one port) | 8 data + at least A0 to A7 for port decode + /IORQ, /RD, /WR (and /M1 to reject interrupt acknowledge) = 19 to 20 |
| Bus monitor (receive and report cycles) | the decoder's 11 at minimum |

Every option is at least 11 lines against 8 pins.

## Not the reason: speed

Speed is no obstacle. A Z80 at 4 MHz has a 250 ns T-state and at 20 MHz
(Z80 at its fastest grades) 50 ns; at a 50 MHz core clock (20 ns per cycle)
that is 12.5 or 2.5 cycles per T-state. If the chip had 11 pins this would
be a fair test.

## Why not a weakened task

A task could tie three data lines to fixed levels outside the chip and let
the chip drive D0 to D4 and the three strobes, so the decoder sees only
bytes whose top three bits are fixed. That carries 5 bits per cycle, is not
how any Z80 system works, and is the kind of invented, weakened task the
brief rules out. The protocol is reported as out of reach with the reason
above, as flex/PREREG.md requires ("it needs more than 8 pins in
practice"). It also matches the prediction written there, which named z80
among the likeliest to be out of reach for its wide bus.

## A note on the eligibility rule

flex/PREREG.md rule 4 admits decoders whose "required channels fit the
chip's 8 protocol pins". The z80 decoder's required channels are 11, so by
that rule's own wording z80 should not have been on the list of 23. The
census organiser may wish to record this alongside the result.
