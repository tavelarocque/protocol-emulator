# Hidden test: SD card bus (SD mode) host, CMD line

The examiner's side for `sdcard_sd`. The programmer gets only the kit
(`../../kits/sdcard_sd/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees
this folder. No firmware for the chip was written for this protocol, not
even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, one line per case, then `RATE ...` and `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal.py` | an ideal SD host as a waveform generator with named faults, standing in for `pe_sim`. Not chip firmware |
| `validate.py` | checks the judge: the interface against the sheet, every waveform of `ideal.py`, the RATE line, the hand-in rules, the real simulator |
| `validate_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |

## The role: both (host that transmits and receives)

sigrok's `sdcard_sd` decoder follows the CMD line on CLK's rising edges as
a state machine: after every command except CMD0 it expects the card's
response (48 or 136 bits, by command), and it reads whatever comes next as
that response. A transmit-only task would therefore have to put the card's
responses on the chip's own pins, which no real host does. The chip plays
what a small controller really is on this bus, the SD host: it drives CLK
and sends commands, and reads the card's responses off the same
open-drain CMD line and hands them to the host. The card is a script
(`pe_sim -stimulus`) that cannot react, so the task sheet fixes the clock
and the schedule exactly: 80 initialisation clocks, exactly 8 clocks
between a token's end bit and the next command. The card's response delay
(NCR, 2 to 64 clocks in the SD specification) varies from command to
command and the firmware has to find each start bit.

Clock and pins: core 10 MHz (100 ns a cycle), CLK 250 kHz (40 cycles,
inside the specification's 100 to 400 kHz identification-mode range), P0
CLK push-pull, P1 CMD open-drain. DAT0 to DAT3 are not used. The card
changes CMD 2 cycles after each ideal falling edge.

Host interface: three TX words per command (index and response type 0/1/2
in bits 5..0 and 9..8; argument high half; argument low half). RX words:
for a 48-bit response its bits 45..40, 39..24, 23..8 (three words); for a
136-bit response bits 127..0 (eight words). The response type is what a
real host controller's command register carries (SDHCI has the same
field); it says nothing about the line. Start, transmission and end bits,
CRC7, the clock, and finding each response are the firmware's.

## What the judge does

For each of 6 fixed cases (CMD0 alone; the sheet's example; a ten-command
card start-up CMD0, CMD8, CMD55, ACMD41, CMD2, CMD3, CMD9, CMD7, CMD16,
CMD17; NCR 64 then 2 with all-ones and all-zeros arguments; two R2s back to
back; CMD0 three times) and 8 seeded random ones (1 to 10 commands, random
indexes, arguments, contents and NCR), it:

1. builds the TX words, the card's script and the wanted RX words itself,
   from the interface in TASK.md;
2. checks its own script: the ideal bus (ideal clock and host bits ANDed
   with the script) must decode with sigrok-cli's `sdcard_sd` into exactly
   the wanted tokens, so the card's waveform is a real SD exchange;
3. runs `RUN_DIR/pe_sim run RUN_DIR/sdcard_sd.s -tx ... -stimulus ...
   -cycles N` plus `run_args.txt`, which may hold only `-config` and
   `-mode`, must make P0 push-pull and P1 open-drain, and may give no other
   pin a mode but `in`;
4. checks from the chip's own pin changes: every CLK edge within +-2
   cycles of 180 + 20k, CLK high until cycle 180, the clock running at
   least to 8 rising edges after the last end bit and never restarting;
   every change of P1 happening with CLK low in the cycle before and the
   cycle of it, at most one per low half, and exactly the changes the
   wanted host bits need (so the chip never pulls CMD low while the card
   sends, and adds nothing before, between or after tokens);
5. decodes the bus (CLK, and CMD = chip output AND card script) with
   `sdcard_sd` and requires the tokens, bit for bit, to be the wanted ones
   in order with nothing extra. The decoder does not check CRC,
   transmission or end bits; this bit comparison does;
6. requires the RX words to be exactly the wanted ones, in order.

The random command picker avoids sequences that crash this decoder
version (plain CMD41 or CMD51; an ACMD other than 6, 13, 41, 51 or an
unlisted index after CMD55): those are decoder bugs, not protocol rules,
and the firmware never sees the difference.

`RATE bytes=<payload> cycles=<first to last change of P0 or P1>`: payload
is 5 bytes a command (index and argument) plus 5 per 48-bit response and
16 per 136-bit one. The schedule is fixed by the sheet, so the only freedom
in the figure is how long the firmware keeps the clock running at the end.

## Validation

    python3 -B validate.py 1 2 3 7 11      ->  VALIDATE PASS (validate_output.txt)

- Interface: the sheet's example run gives exactly the TX and RX words
  printed in the sheet, the schedule it states (edges 80, 136, 188; edge
  80 at cycle 3400), and the four 6-byte examples (CMD0 `...95`, CMD8
  `...87`, CMD17 `...55`, R7 `...13`) are what `accept.py` computes. The
  CRC7 of `accept.py` (an LFSR) and of `ideal.py` (long division) agree.
- Waveforms: 26 waveforms on 5 seeds, 130 verdicts, all as expected. The 6
  that must pass do: ideal; every CLK edge 2 cycles off (the limit); CMD
  changing 1 cycle after the falling edge and 1 before the rising edge
  (the limits); the clock running to the end; the clock stopping on the
  8th rising edge after the last end bit. The 20 broken ones all fail: an
  argument bit flipped, a CRC bit wrong, transmission bit 0, end bit 0,
  one CLK edge 3 cycles late, a 41-cycle period, CMD changing in the cycle
  CLK falls, in the cycle it rises, 74 initialisation clocks, gaps of 7
  and of 9 clocks, the clock stopping 7 clocks after the last end bit, a
  3-cycle pull-down of CMD inside a low half, a flipped RX bit, a missing
  RX word, an extra RX word, a host that assumes NCR = 2 instead of looking
  for the start bit, the last command missing, a CMD pulse after the clock
  stopped, an extra CLK pulse after it stopped. The decoder check objects
  to the flipped argument bit, the wrong CRC and transmission bit 0 on its
  own; the timing faults (CMD at an edge, the glitch) are caught only by
  the direct pin checks, as intended.
- RATE: equals the stand-in's own first and last pin change on every seed
  (seed 1: `RATE bytes=106 cycles=56440`).
- Hand-in rules: 3 good `run_args.txt` accepted; 11 bad ones refused as a
  setup failure (CMD push-pull, no mode for CMD, P2 push-pull, `-tx`,
  `-stimulus`, `-s`, `-cycles`, `-inputs`, ambiguous `-c`, two lines, a
  flag with no value).
- Real simulator: the kit's `pe_sim` with a one-instruction loop that
  drives no pin (not SD firmware). It accepted the command line, words and
  script, and all 14 cases failed cleanly ("CLK stopped after 0 rising
  edges"), no RATE line.

Before writing the judge the examiner ran the kit's `pe_sim` on two
one-line throwaway programs (a loop, and a loop that pushes) to learn that
`pins` lines show the output register, not the line (so the judge forms
CMD as the AND of P1's output and the card's script), and that the
simulator empties the RX FIFO at once. Those programs were deleted.

## What the judge does not check

- It runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must supply
  the real simulator.
- Nothing after the run's last cycle is seen (N is 20 clocks past the last
  end bit), so a stray edge later than that is invisible.
- The firmware's sampling of the card's bits is judged only by the RX
  words, not by when it samples.
- No response timeout, no missing response, no busy signal (R1b), no
  data lines, no clock speed change: the card always answers, and only
  CLK and CMD exist.
- Response CRCs are always correct and the firmware need not check them.
- `run_args.txt` may set configuration registers (`clkdiv`, `timeout`,
  `crc_poly`, `crc_init` and the like). That is the chip's hardware and
  allowed, but it should be read when hand-ins are compared.
- A slow host is never provoked: the simulator refills TX and drains RX at
  once.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, but it
is the hardest kind of task in the census so far. The budget is generous
(40 cycles a clock, 256 words), side-set can make the clock edges, the open
-drain pin and `wait ... timeout` or polling can find the start bit, and
the CRC register can follow the 40 command bits. The hard parts are three.
The CRC register is reflected (it shifts right), so its 7-bit result comes
out in the opposite order from the MSB-first argument and must be reversed
or the data shifted the other way, with only X, Y, OSR and ISR to work in.
The clock must never miss an edge across pulls, pushes, the response-type
decision and the change between sending and receiving, so every path must
be counted to the cycle. And the schedule (80 clocks, then exactly 8 between
tokens, NCR found on the fly) leaves no slack for an off-by-one.
