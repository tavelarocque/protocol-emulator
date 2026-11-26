# Hidden test: AC '97 controller, output direction

Kept from the firmware's author until the hand-in. The author's kit is
`../../kits/ac97/` (isa.md, pe_sim, TASK.md). No firmware for the chip was
written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal AC '97 controller output as a waveform generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2 and 3 |

## The role, and why

The chip is the **controller** end of an AC '97 link, output direction:
it drives SYNC (P1) and SDATA_OUT (P2) and follows BIT_CLK (P0), which the
codec drives. That is what a small host chip does for AC '97: the codec is
always the clock master, so the codec's BIT_CLK comes in as a scripted
`-stimulus` (a free-running clock, which really does not react to the
controller). It is TRANSMIT in the census's sense: the chip drives the
protocol's data lines and sigrok decodes them. SDATA_IN (codec to
controller) is left out: playback needs only the output direction, and
the brief allows BOTH only where normal use needs it.

Core clock 50 MHz (20 ns). BIT_CLK is 12.288 MHz, 4.069 cycles a period:
low until a seeded cycle from 200 to 299, then rising edge k at
`R0 + floor(k * 4.0690104 + phase)` with a seeded phase in [0, 1), every
high phase 2 cycles. Periods are 4 or 5 cycles; where the 5s fall changes
with the seed, so a firmware that counts cycles instead of following the
clock fails.

The synchroniser resets to 1 (isa.md, "Input synchroniser", added
24 November 2026), so a thread sees P0 fall in cycle 2 although BIT_CLK is
low from cycle 0. The sheet now says this phantom fall is not a BIT_CLK
edge and is not counted; it does not say how firmware should treat it. The
judge was never affected: it numbers falling edges from its own stimulus
(rise + 2 for each scripted rise), so the first counted fall is at least
cycle 202. Selftest rerun after the change: still `SELFTEST PASS`.

## The host interface, as the task sheet states it

Four words a frame: CTRL (bit 8 command present, bit 7 read, bits 6..0 even
register address, all 0 without a command), DATA (value for a write, else
0), LEFT, RIGHT (16-bit samples). The firmware must build the tag (0xF800
write, 0xD800 read, 0x9800 none), shift the command fields and samples into
their 20-bit slots, MSB first, pad with zeros, send slots 5 to 12 as zeros,
make SYNC, and time every bit against BIT_CLK. Sheet example: words
0x0102, 0x0808, 0x1234, 0xEDCB, 0x01FC, 0x0000, 0x7FFF, 0x8000; the
self-test checks the judge's `tx_words` and `slot_values` against both the
words and the slot table printed in the sheet.

## What the judge checks

Five fixed cases (silence, the sheet's example, every bit set, alternating
bits, twelve frames) and eight seeded random ones (1 to 4 or 1 to 12
frames, each frame a random choice of no command, read or write, random
even address, data and samples). Each case gets its own BIT_CLK start and
phase. For each it runs `RUN_DIR/pe_sim run RUN_DIR/ac97.s -tx ... -stimulus
... -cycles N` plus `run_args.txt`, N = 400 + 1042 * (F + 2).

- **sigrok** (`ac97:sync=1:clk=0:out=2`, binary capture at 50 MHz, BIT_CLK
  from the judge's own stimulus, SYNC and SDATA_OUT from the printed pin
  changes): the `slot-out-raw` annotations must be exactly the wanted 13
  values a frame, in order, nothing extra; any `error` or `warning`
  annotation fails (reserved bits set, odd register address).
- **From the pins**, what the decoder does not check: both lines low by
  cycle 40; neither line changes in a cycle in which BIT_CLK falls (the
  10 ns setup and hold on a 20 ns grid); SYNC high at exactly falling edges
  e..e+15 of each frame, frames every 256 falling edges back to back, the
  first e from 1 to 255; SYNC changes exactly 1 + 2F times; SDATA_OUT low
  at every falling edge that carries no frame bit (before the first frame
  and after the last, to the end of the run, which is one frame time past
  the last frame).
- `run_args.txt`: one line, only `-config` and `-mode` flags with values;
  P1 and P2 must be `pp`, P0 must not be made an output. Anything else is a
  setup failure.
- `RATE bytes=<8 * frames> cycles=<first change of P1 or P2 to the last>`
  for the last passing case. Note: the line rate is fixed by the codec's
  clock, so RATE mostly measures how soon the firmware starts after BIT_CLK
  does; it does not compare programs' speed.

## What it does not check

- Glitches on SDATA_OUT between two falling edges are allowed (the codec
  never samples them); a glitch on SYNC is caught only by the change count.
- Where between two falling edges a line changes: the sheet's "driven on
  the rising edge" is stated but not enforced; only setup and hold are.
- SDATA_IN, RESET#, cold and warm reset, codec ready, slot request bits,
  and variable-rate audio are not part of the task.
- A slow host is never provoked: the simulator refills the TX FIFO at once.
- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must
  supply the real simulator.

## Validation

    python3 -B selftest.py 1 2 3

Result: `SELFTEST PASS` (`selftest_output.txt`). 24 waveforms on 3 seeds,
72 verdicts, all as expected.

- 6 must pass and do: ideal (changes on rising edges); every change 1 cycle
  after the previous falling edge (hold limit); every change 1 cycle before
  the sampling falling edge (setup limit); first SYNC at falling edge 255;
  lines driven low only at cycle 40; a one-cycle SDATA_OUT glitch between
  falling edges.
- 18 broken ones all fail: one flipped sample bit, LSB first, 16-bit
  values not shifted into the top of their slots, read marking slot 2
  valid, no-command frame marking slots 1 and 2 valid (decoder objects);
  one SDATA_OUT change in a falling-edge cycle, SYNC rising in a
  falling-edge cycle, SYNC 15 or 17 bit times, a 257-bit frame period,
  first SYNC at falling edge 256 or 0, lines low only at cycle 41,
  SDATA_OUT high before the first frame or after the last, a one-cycle SYNC
  glitch (pin check objects); an extra all-zero frame, the last frame
  dropped (both object).
- RATE equals the figure from the stand-in's own output on every seed.
- 14 `run_args.txt` variants: 3 good accepted, 11 bad refused.
- The real `pe_sim` with a one-instruction idle program (not AC '97
  firmware) accepted the command line, words and stimulus, and all 13 cases
  failed cleanly with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view is yes, but tight, and the
hardest task of its kind so far. A bit lasts 4 or 5 cycles and the thread
sees BIT_CLK 2 cycles late (no synchroniser bypass is reachable through
`-config`). Seeing a rising edge, the earliest output change shows 2 cycles
after the falling edge that edge precedes, so the firmware must run one bit
ahead: drive bit n+1 on seeing rise n, which lands 2 cycles after one fall
and 2 or more before the next, inside setup and hold. That leaves a loop of
about 4 instructions a bit, one of them the wait on BIT_CLK and one the
`out`, so 2 spare instructions per bit for counting slots, SYNC (side-set
suits it) and the zero padding. Autopull keeps words coming without a
`pull`. The tag depends on two bits of CTRL, so CTRL must be read and
tested before slot 0 starts, during the previous frame's 160 zero bits,
and the firmware must stop before raising SYNC when no next CTRL arrives.
Program memory (256 words) allows unrolling. A loop of 5 cycles a bit would
fall behind the clock, so every path must be counted.
