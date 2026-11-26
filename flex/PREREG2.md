# Flexibility census, round 2: rules set before it runs

This file is committed and pushed before any round-2 protocol is attempted
and before its order is drawn. It follows the rules of round 1
([`PREREG.md`](PREREG.md)) except where it says otherwise, and its results
go in `flex/RESULTS2.md`, failures included.

Round 2 has two parts that answer two different questions.

- **Part A, the rest of the outside lists.** Round 1 used up the decoder
  list it was drawn from. Part A attempts every protocol left on two larger
  lists this project did not write. It asks the same question as round 1:
  can the chip be programmed for protocols nobody here chose?
- **Part B, the chip's own protocols, rebuilt blind.** Twenty of the
  protocols this repository already runs, drawn at random, are rebuilt by
  programmers who have never seen their firmware. It asks a different
  question: is the chip's flexibility a property of the chip and its
  documentation, or of the people who wrote its firmware?

## Part A: the list

The sources are the protocol decoders shipped in two places, at fixed
commits:

- sigrok's own decoders, libsigrokdecode at commit
  `71f451443029322d57376214c330b518efd84f88` (the commit
  `test/extra_decoders.sh` already fetches), which has 23 decoders more
  than the sigrok-cli 0.7.2 list round 1 used;
- DreamSourceLab's decoders for DSView, `libsigrokdecode4DSL/decoders` in
  https://github.com/DreamSourceLab/DSView at commit `2e9e2c8` (5 November
  2024), which adds decoders sigrok does not have.

A decoder is eligible under round 1's rules 1, 2 and 4 (it reads pins, it
decodes a protocol rather than measuring, its required channels fit 8
pins), and under rule 3 as it stands now: its protocol is not one this
repository already runs (the README's protocol table at the commit this
file is pushed in) or one round 1 used. Two decoders of the same protocol
count as one protocol, and both must pass. Variants of a protocol already
run here (DSView's `0-i2c`, `1-spi`, `0-uart` and so on, `dmx512`, and
`cjtag-oscan0`, which is the cJTAG OScan1 already run) are out.

That leaves 10, all attempted, so there is no draw and no order:

| Protocol | Decoder | From |
|---|---|---|
| CAN FD | `can-fd` | DSView |
| Silicon Labs C2 debug interface | `c2` | DSView |
| Ethernet auto-negotiation (IEEE 802.3 clause 28 fast link pulses) | `eth_an` | DSView |
| IBM Flexible Service Interface | `fsi` | DSView |
| MIPI Display Serial Interface | `mipi_dsi` | DSView |
| MIPI RF Front-End Control Interface | `mipi_rffe` | DSView |
| FrSky PXX1 radio control | `pxx1` | DSView |
| Quad SPI | `qspi` and `smart qspi` | DSView |
| Sitronix ST7789 display controller | `st7789` | DSView |
| Infrared, through the IRMP library | `ir_irmp` | sigrok |

**Judges that do not run.** The census judges with sigrok-cli 0.7.2.
DSView's decoders are written for DSView's version of the decoder library.
The examiner may make only the mechanical changes needed for sigrok-cli
0.7.2 to load and run a decoder (imports, version fields, renamed library
calls), and must publish them as a diff beside the hidden test; nothing
that decides what a waveform decodes to may change. If more than that is
needed, or the decoder needs a native library sigrok-cli 0.7.2 does not
have (`ir_irmp` needs libirmp), the protocol is reported as out of reach,
"no runnable judge", with the reason.

## Part B: the list and the draw

The population is every protocol in the README's protocol table (at the
commit this file is pushed in) that has firmware of its own, apart from
four: 10BASE-T Ethernet (no decoder this project did not write can judge
it), the I2C to SPI bridge (two engines already in the list), and RC-6 and
Qi (their framing is in the host driver). Each is attempted in the role
the table gives it:

1. UART: TX and RX, full duplex
2. SPI: controller, to 5 Mbit/s
3. SPI: device
4. I2C: controller, with stretching, timeouts and repeated START
5. I2C: target
6. JTAG: controller
7. Arm SWD: host
8. USB, low speed: host
9. 1-Wire: controller, with ROM search
10. WS2812: driver
11. PS/2: host, both directions
12. CAN: a node that stuffs the bits, makes the CRC and arbitrates, and a receiver that checks the CRC and acknowledges
13. I2S: transmitter, 16-bit stereo
14. DMX512: transmitter
15. Wiegand: transmitter and receiver
16. NEC infrared: transmitter, 38 kHz carrier included; receiver
17. MDIO: controller, reads and writes
18. DALI: controller, forward frames on one thread, and a receiver that reads the gear's answers on the other
19. RC-5 infrared: transmitter, 36 kHz carrier included; receiver
20. PWM, RC servo: generator
21. NES gamepad: host
22. Microwire: controller, any number of bits; a 93C46 EEPROM on it
23. HDMI-CEC: initiator, reading each block's acknowledgement
24. Step and direction: moves and ramps, every step exact to the tick
25. AM2302 / DHT22, DHT11: reader
26. TDM audio: transmitter, any number of 16-bit slots to a frame
27. TLC5620 DAC: clocked data, LOAD and LDAC
28. SBUS: transmitter, the line inverted
29. DShot: transmitter, DShot600
30. XY2-100: controller, both axes at 2 MHz
31. Digital caliper data port: the caliper
32. MIPI I3C, SDR: controller with ENTDAA
33. SAE J2716 SENT: transmitter, 3 us tick
34. SAE J1850 VPW: transmitter, 10.4 kbit/s
35. Sony SIRC infrared: transmitter, with carrier
36. SLE 4442 memory card: reader
37. Compact JTAG (IEEE 1149.7): probe, OScan1
38. PJON over PJDL: sender
39. NXP LFAST with SIPI: sender
40. MIL-STD-1553B: bus controller, with a second thread reading every word back
41. ARINC 429: sender, 100 kbit/s
42. SpaceWire: sender, data and strobe
43. ISO 7816-3 smart card: reader, with the card's clock on the other thread
44. KNX TP1: sender that reads the receiver's ACK
45. MVB (IEC 61375 train bus): master and slave frames
46. SMPTE linear timecode: sender, 25 frames a second

Twenty are drawn. The draw uses the randomness of the first round of
drand's default mainnet chain published at or after 2026-11-28 00:00 UTC.
The 46 lines above, each exactly as written after its number, are sorted
by the SHA-256 of that value in hex, a colon, and the line; the first 20
are attempted, in that order.

The examiner of a Part B protocol writes its task sheet and hidden test
from the protocol's public specification and the decoder that judges the
repository's own chip-level test for it, as in round 1. It does not copy
the repository's firmware, test stimulus or host driver into the task
sheet; the task sheet may fix the same pins, clock and line rate the table
gives, so the result can be compared with the repository's firmware.

Reported for each Part B protocol, as well as pass or fail: the blind
program's length beside the repository firmware's.

## What is frozen

The chip is v2.3. The kit is `docs/isa.md` and `pe_sim` as on `demo` at
commit `771319c`, which wrote in what round 1's programmers found unclear;
this is a change from round 1's kit, and both are recorded. Nothing in the
kit changes after the first round-2 attempt. If a fault is found in the
kit during round 2, it is reported and fixed only after round 2 ends.

The programmers get round 1's brief ([`census/PROGRAMMER.md`](census/PROGRAMMER.md))
with the one sentence added in round 1's second question ("To avoid very
long tool output, read them in parts rather than printing both at once").
They run on the same AI model as round 1. The kit folder lives outside the
repository, as in round 1. This matters more in Part B, where the
firmware being rebuilt is in the repository: the instruction not to read
outside the folder is not a sandbox, and each programmer's notes record
what it read and ran.

## What counts

As round 1: a protocol passes if the first and only hand-in passes the
hidden test on the full chip. There is no second question in round 2.

## Prediction

Written before the draw:

- Part A: 6 to 9 of the 10 pass. Likeliest out of reach: `ir_irmp` (no
  runnable judge) and `mipi_dsi` (its high-speed mode needs differential
  lanes the chip does not have; the low-power mode may be reachable).
  Likeliest to fail if attempted: `fsi` and `can-fd`.
- Part B: 17 to 20 of the 20 pass. These protocols are known to fit the
  chip, so a failure is about the documentation or the programmer.

## What this cannot show

Everything in round 1's list holds: the programmers are AI agents, they
know the RP2040's PIO, and everything runs on the reference model. Part B
adds one: the programmers may have seen these protocols' public
specifications and other implementations in training, and the
repository's own firmware is reachable on the same machine.
