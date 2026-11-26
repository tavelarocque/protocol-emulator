# Hidden test: Maple bus transmitter (`maple_bus`)

The examiner's side of the census for sigrok's `maple_bus` decoder (SEGA
Dreamcast Maple bus). The programmer gets only the kit
(`../../kits/maple_bus/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees this
folder until the firmware is handed in. No firmware for the chip was written
for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal Maple bus host as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the sheet's example, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## The role chosen: transmit

The chip is the host end of the bus, the Dreamcast's side, and sends
frames. That is what a small host chip does on a Maple bus, and a
transmitted frame exercises everything the decoder knows: start pattern,
the alternating clock and data roles, the header, the data words, the
checksum and the end pattern. A real host also receives the device's reply
on the same two lines; a receive task would be a second, separate task and
is not attempted here.

## What the task sheet fixes

- Clock 50 MHz, one cycle 20 ns. P0 = SDCKA, P1 = SDCKB, both push-pull
  (`-mode 0=pp -mode 1=pp` required in `run_args.txt`). Idle high.
- Frame on the wire: N, sender, recipient, command, 4N data bytes, then the
  checksum (XOR of every byte before it). Bytes most significant bit first.
  Bit j of the frame is clocked by SDCKA (data on SDCKB) when j is even, by
  SDCKB (data on SDCKA) when odd, in three steps: clock up if low, data to
  the bit if different, clock down. Start pattern: A down, four low pulses
  on B, A up. End pattern: A up if low, B up, B down, two low pulses on A,
  B up. These follow the Maple bus description at dreamcast.wiki and the
  decoder's source; the field order (size first) is the decoder's and the
  wiki's (32-bit words little-endian on the wire).
- Timing limits: never both lines in one cycle; at least 7 cycles (140 ns)
  between changes on different lines (the bus asks about 125 ns); at least
  12 cycles (240 ns) between changes of the same line (about 225 ns); at
  most 100 cycles (2 us) between neighbouring changes inside a frame; first
  frame by cycle 50000; 100 to 50000 cycles of idle between frames;
  nothing after the last frame. A Dreamcast's own pace is about 8 cycles a
  step; the sheet says that is for reference only.
- Host words, payload only: per frame, `N << 8 | sender`,
  `recipient << 8 | command`, then the 4N data bytes two to a word, the
  earlier in bits 15..8. No checksum, nothing about the lines. The sheet's
  examples: `0x0000, 0x2001` and `0x0100, 0x0109, 0xDEAD, 0xBEEF`. The
  sheet states: "The host sends only the words defined above. All line
  coding, framing and timing must be done by the firmware."
- A run is 1 to 4 frames, N from 0 to 255.

## What the judge does

For each case it builds the TX words itself (`tx_words`), runs
`RUN_DIR/pe_sim run RUN_DIR/maple_bus.s -tx FILE -cycles C` plus the flags
of `run_args.txt`, and judges the printed changes of P0 and P1 in two ways.

1. **Decoder.** The changes become a VCD capture at 100 MHz (two samples a
   core cycle) and sigrok-cli 0.7.2 runs `maple_bus` on it. Its
   annotations, the bit row left out, must equal exactly, per frame:
   `Start pattern`, `Size: NN`, `SrcAP: NN`, `DstAP: NN`, `Cmd: NN`,
   `Data: NN` for every data byte, `Cksum: NN` (the XOR), `End pattern`.
   Any frame, size or checksum error, a start-with-CRC, occupancy or reset
   pattern, an extra or missing byte or frame, is a mismatch.
2. **Waveform.** From the pin changes directly: both lines high at cycle 0;
   the sequence of changes (which line, which way) equal, change for
   change, to the ideal sequence built from the sheet's rules; never both
   lines in one cycle; the 7, 12 and 100 cycle spacing rules; first frame
   by 50000; idle between frames 100 to 50000; the run long enough after
   the last change to see the idle. The decoder checks none of the timing,
   and it accepts two orderings the sheet forbids (an end pattern without
   B's up and down, data set before the clock rises): the waveform check
   catches those.

Cases: eight fixed (device info request with N = 0; the sheet's second
example; all zeros; all ones; alternating bits; four frames of N = 0 to 3;
N = 128; N = 255) and eight seeded random ones (1 to 4 frames, N up to 6
or up to 40, random addresses, commands and data). After the case lines it
prints `RATE bytes=<host bytes> cycles=<first change to last change>` for
the last passing case (host bytes are 4 + 4N per frame, the checksum not
counted), then `ACCEPT PASS` or `ACCEPT FAIL`. A simulator error or an
exception inside the judge is a failure, never a pass. `-cycles` is
50000 + per frame (100 x its number of changes + 50000), enough for the
slowest timing the sheet allows.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`, about four
minutes).

- Interface: `tx_words` gives exactly the words printed in both of the
  sheet's examples, the sheet holds that text, the checksums are 0x21 and
  0x2B, and the sheet's table of 98 changes equals `ideal_changes` of the
  first example change for change.
- The stand-in simulator is `ideal_wave.py` behind a wrapper named
  `pe_sim`. It reads the judge's words back into frames in its own code
  and walks a real host's phases (8 cycles each, a phase that changes
  nothing still takes its time, a line never changes in two phases
  running), where the judge lists changes and measures them. So the ideal
  passes only if the judge's words, the stand-in's reading of the sheet,
  the judge's ideal sequence and sigrok's decoder all agree.
- Waveforms: 27 waveforms on 5 seeds, 135 verdicts, all as expected. The 5
  that must pass do: ideal; every change at the earliest the rules allow
  (7 and 12 cycles); every change inside a frame exactly 100 cycles after
  the last; idle of exactly 100; first frame at 50000 with idle of 50000.
  The 22 broken ones all fail: one data bit flipped; checksum as a sum;
  no checksum; least significant bit first; bytes of a word swapped; a
  data word missing; start with 3 pulses; start with 6 pulses; an end
  pattern without B's up and down; data before clock; a change 6 cycles
  after the other line; two changes of a line 11 cycles apart; both lines
  in one cycle; a 101-cycle wait inside a frame; idle 99; idle 50001;
  first frame at 50001; SDCKB low at cycle 0; SDCKB left low at the end; a
  stray pulse after the last frame; the last frame missing; the last
  frame twice. The waveform check objects to all 22. The decoder check
  objects to 13 of them; it does not object to the end-pattern variant,
  data before clock, any of the spacing faults, the idle and start limits,
  or SDCKB low at cycle 0, which is why the waveform check exists.
- RATE: for the ideal waveform it equals the figure worked out from the
  generator's own list of changes, on every seed (seed 1:
  `RATE bytes=208 cycles=49600`).
- Hand-in rules: two good `run_args.txt` files accepted; eleven bad ones
  refused as a setup failure (P1 not given, P1 open-drain, P1 made an
  input after pp, `-tx`, `-t`, `-cycles`, `-inputs`, `-stimulus`, the
  ambiguous `-c`, two lines, a flag with no value).
- The real simulator: the kit's `pe_sim` behind a wrapper, with a
  one-instruction program that loops on itself and drives no pin. It is
  not Maple bus firmware. The simulator accepted the command line and the
  word file, and all 16 cases failed cleanly ("0 changes on the lines"),
  with no RATE line.

## What the judge does not check

- It runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs the judge must put
  the real simulator in the run folder.
- Pins other than P0 and P1 are ignored.
- `run_args.txt` may set configuration registers (`clkdiv`, the CRC
  register's polynomial and start value, and so on). That is the chip's
  hardware, not the instruction set, so `notes.md` and the configuration
  line should be read when hand-ins are compared.
- A slow host is never provoked: the simulator refills the FIFO at once.
- N is tested at 0, 1, 2, 3, 128, 255 and random values up to 40; not
  every value from 0 to 255.
- Only transmission. The device's reply, and the bus turnaround, are not
  part of this task.
- The 7 and 12 cycle limits are this sheet's rounding up of the bus's
  "about 125 ns" and "about 225 ns", and the 100-cycle and idle limits are
  this sheet's own bounds (the bus states no maximum); a real Dreamcast
  peripheral may be more or less tolerant.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, but this
is harder than it looks, for one specific reason: the checksum. The timing
is easy: at 50 MHz each step has at least 7 cycles, room for several
instructions, and `set pins` over two pins can write both lines exactly as
the steps need, without side-set. The difficulty is that the instruction
set has no XOR. The only way to XOR bytes is the CRC register: with the
polynomial x^8 + 1 (written low power first, 0x80) from 0, it folds the
bits it is fed into the XOR of the bytes, but in the order the bits were
shifted, so for bytes sent most significant bit first it holds the checksum
bit-reversed, and OUT's direction is fixed per thread. The programmer must
see that, feed the CRC exactly the frame's bits (an `out` used to pull N
into a counter also feeds it a bit, unless the register is restarted or
`crc_in` is used), and reverse the result, for instance through the ISR,
before sending it. Counting 2N words with N taken out of the first word,
while X tests bits and Y counts, is the other tight spot. 256 words of
memory are ample. I expect a careful programmer to pass, and the likeliest
failure to be a wrong checksum.
