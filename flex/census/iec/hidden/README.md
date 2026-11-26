# Hidden test: IEC (Commodore serial bus) controller

The examiner's side for sigrok decoder `iec`. The programmer gets only the
kit (`../../kits/iec/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees this
folder. No firmware for the chip was written for this test, not even as a
check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal controller as a waveform generator that reacts to the stimulus file, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |

## The role chosen

Both directions on the wire, payload one way. The chip is the bus
controller and talker, the part a C64 plays: it addresses a device (LISTEN,
SECOND under ATN), sends it data bytes with EOI on the last, and lets it go
(UNLISTEN). That is the role a small host chip plays on this bus. The IEC
bus cannot be driven without a listener: every byte needs the listener's
"ready for data" release of DATA and its acknowledge, and the last byte
needs its EOI pulse. So the listener is a scripted `-stimulus` waveform on
DATA, and the task sheet fixes every chip action as a window after the
listener event it answers, with the listener's delays drawn after the
latest end of each chip window. The listener's delays are drawn at random
per event, within ranges the sheet states, so firmware that times itself
from the start of the run instead of from DATA fails (fault `blind`).

Clock 1 MHz (one cycle = 1 us). P0 DATA, P1 CLK, P2 ATN, all open-drain
(required in `run_args.txt`). SRQ is not used. The timing numbers are the
Commodore serial bus table of the C64 Programmer's Reference Guide: ATN
response at most 1000 us, non-EOI response to ready-for-data at most 200,
bit setup at least 20, data valid at least 20, frame handshake at most
1000, frame to ATN release at least 20, between bytes at least 100, EOI
response at least 200 (the listener uses 250 to 350), EOI hold at least 80
for an external listener (80 to 120), talker response after EOI at most 60.
The bit period window (40 to 100 us) and the other upper bounds are the
sheet's, chosen so that a scripted listener can line up and every
listener delay stays within the table.

## The host interface

A header word (device D in bits 4..0, 0 to 30; secondary address S in bits
11..8, 0 to 15) and one word per data byte (bits 7..0; bit 8 on the last).
The firmware has to make the command bytes 0x20 + D, 0x60 + S and 0x3F
itself, and ATN, EOI, the handshake and all timing. The sheet's example:
device 4, address 7, "HI" is 0x0704, 0x0048, 0x0149.

## What the judge checks

Fifteen cases per seed: seven fixed (one byte with the quickest and with
the slowest listener; "HELLO" CR; two transactions of 0x00, 0xFF, 0x55,
0xAA, 0x01, 0x80; 16 bytes with the quickest and with the slowest listener;
four one-byte transactions to devices 0 and 30 among others) and eight
seeded random ones (1 to 4 transactions, 1 to 16 data bytes, random device
timing).

- **Decoder.** The bus is rebuilt as on the wires (DATA is the AND of the
  chip's P0 and the listener's DATA) and written as a VCD at one sample a
  cycle. sigrok's `iec` decoder must give exactly the wanted bus bytes in
  order, nothing extra: each byte's value, its DAT/CMD text equal to what
  the decoder's own table gives for that byte with or without ATN, ATN low
  at the byte's start for commands and high for data (read from the bus),
  and EOI on the last data byte of each transaction and on no other.
- **Waveform**, from the chip's own pin changes, against the listener's
  actual event times: every ATN and CLK change of the sheet, in order, in
  its window (ATN start, CLK with ATN, ready to send, first fall with or
  without EOI, ATN release after SECOND, ATN before UNLISTEN, ATN and CLK
  release after UNLISTEN); per bit CLK low at least 20, high at least 20,
  fall to fall 40 to 100; DATA changes only while CLK is low and at least
  20 cycles before a rise, or within 20 after the 8th fall; DATA released
  outside the bits; no other change of ATN or CLK anywhere, including after
  the last transaction; all lines released at cycle 0.
- **Hand-in rules.** `run_args.txt` is one line of `-config` and `-mode`
  flags only, and must make P0, P1, P2 open-drain.
- `RATE bytes=<data bytes> cycles=<chip's first to last change on P0..P2>`
  for the last passing case. Most of that span is the listener's own
  delays, so it says little about the firmware's speed.

## What it does not check

- The listener never holds off longer than 950 us, never times out, and
  never signals an error; the chip's handling of a missing device (no
  answer to ATN within 1 ms) is not tested. Nor is turning the bus round
  (TALK), reading from a device, or SRQ.
- Pins P3 to P7 are ignored.
- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must
  put the real simulator there.
- `-config` may set the clock divider, timeout and so on: that is the
  chip's configuration, not the instruction set, and should be read when
  hand-ins are compared.
- A slow host is never provoked: the simulator refills the FIFO at once.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- Interface: `tx_words` gives the sheet's example words, the bus bytes are
  the sheet's, and the sheet's stimulus listing is exactly the script the
  judge writes for the quickest listener.
- Waveforms: 28 on 5 seeds, 140 verdicts, all as expected. The three that
  must pass do: the ideal; every action at the earliest the sheet allows
  (bits of 20 low and 20 high, setup exactly 20); every action at the
  latest (bits of 100, every window at its upper end). The 25 broken ones
  all fail: one wrong bit, most significant bit first, TALK instead of
  LISTEN, no wait for the EOI pulse, EOI wait on every byte, commands
  without ATN, ATN held through the data, no UNLISTEN, setup 19, DATA
  changed while CLK high, CLK high 19, bits of 101, ready-to-send at 99 and
  at 401, first fall at 201 after ready-for-data, first fall 61 after the
  EOI pulse, ATN released 19 after SECOND, ATN and CLK released 91 after
  UNLISTEN, ATN at 99 after the bus went free, CLK 21 after ATN, DATA
  released 21 after the 8th fall, firmware blind to the listener, a byte
  sent twice, a byte left out, a stray CLK pulse after the run.
- The ideal passes only if the judge's words, the stand-in's own reading
  of the sheet, the stand-in's own reaction to the stimulus file, the
  judge's windows and sigrok's decoder all agree; so it also shows sigrok
  decodes the scripted listener plus a correct controller as IEC.
- RATE: equal to the figure from the generator's own output on every seed
  (seed 1: `RATE bytes=7 cycles=19136`).
- Hand-in rules: two good `run_args.txt` accepted; nine bad ones refused
  (P2 or P0 not open-drain, `-tx`, `-s`, `-cycles`, `-inputs`, ambiguous
  `-c`, two lines, a flag with no value).
- The real simulator with a one-instruction program that drives no pin
  (not IEC firmware): all 15 cases fail cleanly, no RATE line.

## Is a solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, with
effort. Open-drain pins read back the listener, `wait` on DATA gives every
handshake, and the windows (20 to 400 cycles, at least 60 wide) are easy
to hit with delay fields, short X loops or a clock divider; the two-cycle
input synchroniser is small against them. The harder parts are state, not
speed: making the command bytes 0x20 + D and 0x60 + S from the header
(building them in the ISR, or sending their constant bits by `set`), and
reading bit 8 of a data word before its bits go out, with only X and Y,
so the byte's role (command, data, last data) has to live in the control
flow. The 256-word memory leaves room for that.
