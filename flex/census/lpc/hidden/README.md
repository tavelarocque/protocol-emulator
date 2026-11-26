# Hidden test: LPC host (sigrok decoder `lpc`)

This folder is the examiner's side. The programmer gets only the kit
(`../../kits/lpc/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees this
folder. No firmware for the chip was written for this test, not even as a
check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal LPC host as a waveform generator, standing in for `pe_sim`, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the stimulus, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## The role, and why

BOTH: the chip is the LPC host. It drives LCLK (P5), LFRAME# (P4) and LAD
during its part of each read (P0..P3, open-drain with pull-ups), and a
scripted peripheral, given to the simulator as `-stimulus`, answers each
read with SYNC, a data byte and TAR. The firmware pushes each byte to the
host as an `rx` word.

A small chip on an LPC bus is realistically one of two things: a host
running its own slow bus to reach a Super I/O, TPM or LPC flash (LPC flash
programmers built on microcontrollers do this), or a passive sniffer on a
motherboard. The sniffer has to follow a 33 MHz LCLK, which a 50 MHz core
behind a two-flop synchroniser cannot sample, so it would be out of reach.
The host owns its clock, and LPC devices (like PCI devices, whose clock
LPC shares) work from DC to 33 MHz, so a host at 2.5 MHz is a legal bus.
Pure TRANSMIT would have the chip drive the peripheral's half too, which is
not the protocol. Writes are left out because the 0.7.2 decoder cannot
decode them (below).

Because the scripted peripheral cannot react, the sheet fixes the whole
schedule: rising edge k of LCLK at cycle 100 + 20k (+-2), read n's START in
clock 4 + 24n, and the peripheral's nibbles 4 cycles after ideal rising
edges. A chip edge 2 cycles late still sees the peripheral change 2 cycles
after its edge, and one 2 early sees it 6 after.

Clock 50 MHz (20 ns a cycle), LCLK 2.5 MHz (20 cycles). Pins P0..P3 LAD[0..3]
`od`, P4 LFRAME# `pp`, P5 LCLK `pp`; the judge requires exactly these modes.

## The host interface, as the task sheet states it

Per read: a type word (0x0000 I/O read, 0x0001 memory read), then the
address: one word for I/O, two (bits 31..16 then 15..0) for memory. RX: one
word per read, the byte in bits 7..0. Example in the sheet: an I/O read of
0x0080 then a memory read of 0xFFC01234 are the words 0x0000, 0x0080,
0x0001, 0xFFC0, 0x1234; answers 0x5A, 0x07 give rx 0x005A, 0x0007. The
sheet says "The host sends only the words defined above. All line coding,
framing and timing must be done by the firmware."

## The decoder, and the one adjustment the judge makes

sigrok's `lpc` decoder (0.7.2) has three properties that shape the test,
found by reading `pd.py` and confirmed by running it on synthetic captures:

- It is off by one clock on a correct waveform. On the rising edge where
  it first sees LFRAME# high it labels the LAD value START, so it takes the
  CYCTYPE nibble as START, the first address nibble as CYCTYPE, and so on;
  on a memory-read capture sampled the honest way it decoded "Cycle type:
  Reserved" and then crashed with a negative shift. With LFRAME# presented
  one clock earlier than LAD it decodes every field correctly.
- It knows only the read order (address, TAR, SYNC, data, TAR). A write
  (address, data, TAR, SYNC, TAR) decodes as garbage. It takes exactly one
  SYNC clock, so wait-state SYNCs (0101, 0110) cannot be used.
- It needs at least one idle clock between two reads; back to back, it
  misses the second START. The schedule leaves 7 or 11.

So the judge does not hand sigrok the raw per-cycle wire. It samples the
wire one cycle before each actual rising edge of LCLK (the level a device
takes), and writes a capture of two samples per clock (LCLK low, high)
with those LAD values and with LFRAME# taken from the next clock. That is
the same fixed transformation for every hand-in. The position of LFRAME#
is then not the decoder's to check, so the judge checks it directly: low
exactly at each START edge, one fall per read, low nowhere else.

## What the judge checks

For each case it builds the TX words and the stimulus from the sheet's
rules, and first requires the decoder to read the ideal bus (ideal host
plus the stimulus) as exactly the wanted reads, so the scripted peripheral
is a real LPC peripheral. Then it runs `RUN_DIR/pe_sim` with `-tx`,
`-stimulus`, `-cycles N` and `run_args.txt`, works out every pin's wire
level in every cycle (pp: the output; od: output AND peripheral; input: the
peripheral), and requires:

- LCLK: every rising edge within +-2 cycles of 100 + 20k, no extra ones,
  all of them present through the last read's last clock (after it the
  clock may stop or keep its places); high and low at least 6 cycles each
  time; a fall before the first rise.
- Setup and hold: no change of the chip's LFRAME# or LAD outputs in the
  cycle of a rising edge or the cycle before it.
- LFRAME# low only between the rising edges around a START clock, and
  exactly one fall per read (so a glitch between edges fails).
- The chip's LAD outputs all 1 except strictly between the edge ending the
  clock before START and the edge ending the first TAR clock: no
  contention with the peripheral, no driving in idle clocks.
- The level sampled at every rising edge through the last clock equals the
  ideal bus (idle, START, CYCTYPE, address, TAR, SYNC, data, TAR).
- The decoder's annotations equal, exactly and in order, START, cycle
  type, address, TAR x2, SYNC 0000, DATA, TAR x2 per read, with no warning
  and nothing extra; a decoder error is a failure.
- The `rx` words equal the bytes the peripheral returned, in order,
  nothing extra.
- `run_args.txt`: one line, only `-config` and `-mode`, and the pin modes
  above.

Cases: five fixed (port 0x80 read, memory read of 0xFFFFFFFF, all zeros,
every nibble value, eight alternating reads) and eight seeded random ones
(1 to 3 or 1 to 8 reads of random type, address and byte). After the case
lines: `RATE bytes=<reads, one data byte each> cycles=<first to last pin change>`
for the last passing case. With the schedule fixed by the sheet the rate
is set by the sheet; only where the firmware stops the clock varies.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, 148 checks as expected and none wrong
(`selftest_output.txt`). Of the waveform verdicts, 30 must-pass (6
waveforms x 5 seeds) all passed and 90 must-fail (18 x 5) all failed.

The stand-in (`ideal_wave.py` behind a wrapper named `pe_sim`) reads the
judge's TX words by the sheet's rules in its own code and does not know
the data bytes: it reads them from the judge's stimulus file by sampling
its own open-drain output AND the peripheral one cycle before each rising
edge, as a chip would. It walks clocks and changes outputs on LCLK's
falling edges, where the judge lists sampled levels; so the ideal waveform
passes only if the words, the stimulus, the judge's ideal bus and sigrok
all agree.

- Interface: the judge's words, rx words and stimulus for the sheet's
  example are exactly the text printed in the sheet; N and L as stated.
- Stimulus: sigrok decodes the ideal bus of every case on every seed.
- Waveforms: 6 that must pass (ideal; clock running on to the end; rising
  edges alternately 2 late and 2 early; outputs changing 2 cycles before
  an edge; 1 cycle after; LCLK high only 6 cycles) and 18 that must fail
  (an address bit flipped; address least significant nibble first; memory
  reads with the I/O cycle type; one rx bit wrong; rx nibbles swapped; an
  extra rx word; one edge 3 cycles late; a 21-cycle period; LCLK high 5
  cycles; outputs changing 1 cycle before an edge; in the edge's cycle;
  LAD0 held low through the peripheral's clocks; LAD driven in idle;
  LFRAME# low two clocks; a one-cycle LFRAME# glitch between edges; every
  read one clock late; the clock stopping one clock early; the last read
  missing). Each verdict is printed per seed in `selftest_output.txt`.
- RATE: equals the figure from the stand-in's own pin changes, every seed.
- Hand-in rules: 11 bad `run_args.txt` refused (`-tx`, `-stimulus`, `-s`,
  `-cycles`, `-inputs`, ambiguous `-c`, two lines, a flag without value,
  LAD push-pull, LCLK open-drain, LFRAME# mode missing); 2 good ones
  accepted.
- Real simulator: the kit's `pe_sim` with `idle: jmp idle` (drives no pin;
  not LPC firmware) accepts the command line, word file and stimulus file,
  and every case fails cleanly on the waveform check, with no RATE line.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must
  put the real simulator there.
- Writes, DMA, firmware-memory cycles, wait-state SYNCs, aborts, LRESET#,
  CLKRUN# and LFRAME# held for several clocks: the decoder cannot read the
  first four, and the fixed schedule rules out the rest. The task is a
  subset of LPC: single-byte I/O and memory reads.
- LCLK at 2.5 MHz, not 33 MHz, and timing in whole 20 ns cycles; real
  setup, hold and valid-delay figures (7 ns, 0 ns, 2 to 11 ns) are not
  modelled beyond "not in the edge's cycle or the one before".
- LFRAME#'s position is checked by the judge, not the decoder (above).
- A peripheral that inserts waits, or a host that is slow: the TX FIFO is
  refilled at once.
- `run_args.txt` can set configuration constants (`clkdiv`, `timeout`,
  shift directions, side-set); that is the chip's hardware, not the
  instruction set, and should be read when hand-ins are compared.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, with
care. A clock is 20 cycles; one side-set bit for LCLK leaves a 3-bit
delay, enough for two or three instructions per clock. `out` with
`out_msb_first` gives the address most significant nibble first straight
from the TX words, a 5-pin `set` can put LFRAME# and LAD together, and the
open-drain LAD pins are read back with `in`. The data byte arrives low
nibble first, so the nibbles have to be put together through a register
(for example `in y, 4` after the second `in pins, 4`), and the two-cycle
synchroniser has to be allowed for, which the 20-cycle clock makes easy.
The hard part is that LCLK must stay on a fixed grid for the whole run:
every path (pulling words, the I/O or memory branch on the type word, the
address loop, the data read and push, the idle clocks to the next slot)
must take a whole number of 20-cycle clocks within +-2 cycles, and the
next pull must not come before the last read's last clock or it stalls
the clock early. That is counting, not missing hardware.
