# Hidden test: Silicon Labs C2 debug interface master

This folder is the examiner's side of round 2, Part A, for the decoder `C2`
from DreamSourceLab's DSView (protocol: Silicon Labs C2 debug interface,
census folder name `c2`). The programmer gets only the kit
(`../../kits/c2/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees this
folder until the firmware is handed in. No firmware for the chip was
written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal C2 master as a waveform and rx-word generator, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the sheet's example, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `PORT.diff` | the one mechanical change made to the decoder so sigrok-cli 0.7.2 loads it |
| `README.md` | this file |

The judge sets `SIGROKDECODE_DIR` itself, to the round-2 decoder folder
(`C2_DECODERS` in the environment overrides it, for when the folder moves).

## Role chosen: both (the chip is the C2 master)

C2 is the two-wire debug and flash-programming interface of Silicon Labs'
8051 parts (C8051F, EFM8). A small host chip plays the master: the USB
debug adapter or production programmer side. The master drives C2CK and,
in its own fields, C2D; the device drives C2D in the ADDRESS field of an
Address Read, in every WAIT field and in the DATA field of a Data Read.
So the honest role is both: the chip sends Address Write, Address Read,
Data Write and Data Read frames and reads the device's answers back. The
device is scripted with `-stimulus`, so the task sheet fixes when every
strobe happens and the script lines up.

Protocol facts are from Silicon Labs AN127 (C2 interface specification and
flash programming): frames START, INS (Data Read 00b, Data Write 01b,
Address Read 10b, Address Write 11b), LENGTH (bytes minus one), ADDRESS,
DATA, WAIT (zero or more 0s ended by a 1, from the device), STOP; all
fields least significant bit first; data sampled on the rising edge of
C2CK; the device changes C2D (as an output) shortly after the rising edge
of C2CK, and its reference code strobes and then reads, so a device bit is
the device's answer to its own strobe; a reset is C2CK low for at least
20 us, and the first START at least 2 us after it; AN127's rule of thumb
"C2D set up before C2CK goes low, C2CK low time between 80 ns and 5 us, C2D
read at least 120 ns after C2CK rising"; tDS and tDH 10 ns, tDV 20 ns.
C2CK high time is at least 120 ns in older device datasheets (the current
AN127 table says 20 ns); the sheet uses the stricter figure.

## Clock, pins, schedule

- Core clock 50 MHz, one cycle 20 ns.
- P0 = C2CK, push-pull. P1 = C2D, open-drain with a pull-up (the chip
  writes 1 to release it). Both modes are required and checked in
  `run_args.txt`. P2 to P7 unused.
- The run starts with the device reset: C2CK falls by cycle 300, stays low
  at least 1100 cycles (22 us), rises by cycle 1800. The sheet says why
  it asks 22 us where the specification says 20: the decoder counts a low
  time as a reset only if it is strictly longer than 20 us.
- Slots of 50 cycles (1 us, a 1 MHz strobe rate). The strobe of slot s
  rises at cycle 2000 + 50s, within +-2 cycles. Frame 0's START is slot 0;
  each frame's strobes take consecutive slots; one idle slot (no strobe)
  after each STOP. Strobes low 4 to 40 cycles, C2CK high at least 6 cycles
  between them. No other C2CK edges.
- The device answers each of its strobes (slot s) by driving its bit from
  cycle 2000 + 50s + 3 to 3 cycles after the place of the next strobe
  (always in the same frame), so 60 ns after the ideal rising edge.
- The chip's bits: its C2D output must not change from the cycle C2CK
  falls to the cycle it rises, both included (AN127's "set up before C2CK
  goes low"; hold at least one cycle, 20 ns, against 10 ns asked), and
  its level in the rising-edge cycle is the bit.
- Ownership: the chip may pull C2D low only from the cycle after the START
  rises to the cycle before C2CK falls for the strobe after its last bit
  of that frame (the first device strobe, the WAIT, or the STOP). Its
  output must be 1 everywhere else, which covers every START, STOP, WAIT
  and device strobe, the idle slots, the reset and the end. That is
  measured on the actual edges, not the ideal places.
- The WAIT field: the scripted device is always ready and answers 1 at
  the first WAIT strobe, so every WAIT field is one strobe. That is a legal
  C2 WAIT ("zero or more 0s, terminated by a 1"). It is also the only WAIT
  the DSView decoder can read: its state machine takes exactly one strobe
  for WAIT in both Data Read and Data Write, so a busy device would make
  it misread the rest of the frame. A busy WAIT is therefore never
  exercised, and the sheet says so.
- Run length N = 2000 + 50(S + 2), S being the slot after the last frame's
  idle slot.

## The host interface

- Address Write: one word, 0x1000 + address.
- Address Read: one word, 0x2000.
- Data Write of n bytes (1 to 4): 0x3000 + n, then n words, one byte each
  (bits 7..0), in the order sent.
- Data Read of n bytes: 0x4000 + n.
- RX: one word per byte the device sends (the address byte of an Address
  Read, each byte of a Data Read), byte in bits 7..0, in order, nothing
  else.

The sheet says "The host sends only the words defined above. All line
coding, framing and timing must be done by the firmware." The words carry
neither the INS code nor the LENGTH field: the firmware maps the command
number to the instruction code and n to n - 1, and makes the reset,
strobes, idle slots, turnarounds and bit order itself.

## The decoder adjustment

The DSView decoder reads C2D in the very sample in which it sees C2CK rise.
That is right for the master's bits. For the device's bits it is right only
on a capture coarse enough that the device's change, which comes shortly
after the edge, falls into the same sample. On the judge's capture at one
sample per cycle the device's answer comes 3 cycles after the edge, so the
decoder reads every device bit one strobe late: the sheet's example, with
an ideal master and the sheet's own stimulus, decodes as `ReadData(1)=0x61`
instead of `0x30` (checked in `selftest.py`). So, as round 1's `lpc` judge
did for its decoder, this judge adjusts what it hands the decoder, and only
that: in the copy of the capture given to sigrok, through each of the
device's strobes (from the cycle C2CK falls to 6 cycles after it rises),
C2D shows the level of the line 6 cycles (120 ns, AN127's read point)
after that strobe's rising edge. C2CK, the master's bits and everything
outside the device's strobes are passed as they are, and the edges used
are the ones the chip made. The real line is checked separately, cycle by
cycle, against the sheet. The adjustment was in the judge before any
programmer started.

## The decoder port

DSView's `C2` decoder (folder `C2` in the round-2 decoder repository,
decoder id `C2`) did not load in sigrok-cli 0.7.2:

    srd: Protocol decoder C2 interface annotation 2 should be a tuple with two elements.
    srd: Failed to load decoder C2: cannot get annotations

DSView's library takes annotation classes as three strings (a DSView type
code, the id, the description); libsigrokdecode 0.5 takes two (id,
description). `PORT.diff` has the one hunk: the leading `'106'` type code
is removed from the first two annotation classes, leaving their id and
description unchanged (the third class already had two elements). That is
how the decoder registers its annotations and nothing else; the decoding
logic, the channel list and every annotation text are untouched. With it,
`sigrok-cli -P C2:c2ck=C2CK:c2d=C2D -A C2` runs. Nothing else was needed:
`api_version = 3`, `self.wait`, `self.put`, `has_channel` and the
samplerate metadata all work in 0.7.2 as written. (The decoder's
`__init__.py` docstring is SPI's, copied by DSView; harmless, left alone.)

## What the judge does

Six fixed cases (the sheet's example; one Address Read; all four
instructions with all-0 and all-1 values; four bytes each way; every
length 1 to 4 both ways; a flash-erase-like sequence of 10 frames) and
eight seeded random ones (1 to 3 or 1 to 10 frames of random kinds, bytes
and lengths). For each case:

- **The stimulus is checked first.** An ideal master (accept.py's own:
  strobes low 20 cycles before each place, each 0 bit pulled low from 10
  cycles after the rising edge before to 10 after its own) plus the
  scripted device must pass the waveform check and decode, through the
  same adjustment, to exactly the wanted frames, so the device is a real
  C2 device to this decoder. A failure here is a `judge:` fault, never the
  programmer's.
- It builds the TX words and the stimulus from the interface, runs
  `RUN_DIR/pe_sim` on `RUN_DIR/c2.s` with `RUN_DIR/run_args.txt` (one line,
  `-config` and `-mode` only, P0 pp and P1 od required; anything else is a
  setup failure).
- **Waveform check**, from the chip's outputs: the reset (fall by 300, low
  at least 1100, rise by 1800); exactly one strobe per scheduled slot after
  it, each rising edge within +-2 of its place, low 4 to 40 cycles, high at
  least 6 before it; C2CK high at the end; the chip's C2D output 0 only
  while the chip owns C2D; no change of it from F to E of each of the
  chip's strobes; and its level at E equal to the wanted bit for every
  strobe of the chip.
- **Decoder check.** C2CK (the chip's output) and C2D (the chip's output
  AND the device's, adjusted as above through the device's strobes)
  become a VCD at 50 MHz, one sample per cycle.
  `sigrok-cli -P C2:c2ck=C2CK:c2d=C2D -A C2` reads it. The frame
  annotations (`WriteAddress(0x..)`, `ReadAddress()=0x..`,
  `WriteData(0x..,n)`, `ReadData(n)=0x..`) must be exactly the wanted
  frames in order, and the field annotations exactly `Reset`, then per
  frame `Start`, the INS value, the length, every byte, `Wait` and `End`
  in the frame's order, nothing extra.
- **RX check.** The `rx` words must be exactly the device's bytes, in
  order, nothing extra, bits 15..8 zero.
- `RATE bytes=<payload bytes> cycles=<first to last pin change>` for the
  last passing case. Payload bytes count the address byte of each Address
  Write and Address Read and every data byte both ways. The span starts at
  the reset's fall, so it includes the 2000-cycle reset and start-up and
  every idle slot.

### Decoder behaviour the judge relies on, measured here

- The decoder samples C2D in the same sample as C2CK's rising edge. The
  judge's VCD has one sample per cycle, so that is the level in cycle E.
  The chip may not change C2D from F to E of its own strobes, so for the
  chip's bits the sample is unambiguous. For the device's bits see "The
  decoder adjustment".
- It calls a low phase longer than 20 us (strictly) a reset and needs one
  before the first frame. The sheet's 1100-cycle minimum (22 us) leaves a
  margin over the 20 us of the specification and the decoder.
- The device's 60 ns output delay (3 cycles after the ideal edge) is later
  than AN127's tDV of 20 ns. A scripted device cannot follow the chip's
  real edges, so its changes are placed after the latest allowed edge
  (ideal + 2): with +-2 allowed, the device always answers after the
  chip's actual rising edge, as a real device does.

## What the judge does not check

- A busy device (WAIT longer than one strobe): the decoder cannot read it,
  and the sheet says the device is always ready. A firmware that never
  looks at the WAIT bit passes.
- The read direction's timing inside the chip: the judge checks only that
  the bytes pushed are the device's. How and when the chip samples C2D is
  its own business, as long as the bytes are right.
- When the rx words are pushed, beyond their order: any time in the run.
- What the firmware does with words that break the interface: never sent.
- The levels the chip writes on P2 to P7 (inputs, they drive nothing).
- The judge runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs it must put
  the simulator into the run folder.
- `run_args.txt` may hold configuration constants (`clkdiv`, bases,
  shift directions and so on). That is the chip's hardware, not the
  instruction set; read the configuration line with `notes.md` when
  hand-ins are compared.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`).

- Interface: `tx_words` and `rx_words` give exactly the words printed in
  the sheet (0x1000, 0x4001 and the pushed 0x0030; 0x3002, 0x0012,
  0x0034), and the stand-in reads the judge's words back into the same
  frames with its own parser.
- Example: the sheet's table, slot by slot (29 slots, edges, bits, who
  drives), its stimulus file and N = 3550 equal the judge's schedule and
  stimulus. The ideal bus decodes as the example's frames with the
  adjustment, and as `ReadData(1)=0x61` without it (the decoder behaviour
  the adjustment exists for).
- Waveforms: 42 waveforms on 5 seeds, 210 verdicts, all as expected. The
  11 that must pass do: the ideal; rising edges alternately 2 early and 2
  late; every edge 2 late; strobes low 4 cycles; low 40 with jitter, so
  high only 6; reset from 300 to 1400 and from 300 to 1800; each chip bit
  put out in the cycle before C2CK falls, and in the cycle after the rising
  edge before; C2D released in the very cycle C2CK falls for the device's
  strobe; rx words pushed only at the end. The 31 broken ones all fail:
  one chip bit flipped, bytes MSB first, the INS code MSB first, LENGTH as
  n, one rx byte wrong, an rx word missing, an extra one, bits 15..8 set
  in rx words, the device's bits read at the rising edge (one strobe
  early, the classic C2 bug), one edge 3 late, one 3 early, 51-cycle
  slots, strobes low 3 and 41, reset of 1099, reset falling at 301,
  rising at 1801, no reset, a chip bit changed in the cycle of a rising
  edge, one changed in the cycle C2CK falls, C2D released one cycle after
  that fall, C2D pulled low inside START strobes, a strobe in an idle
  slot, no STOP, no WAIT, two idle slots, a frame dropped, a frame
  repeated, a one-cycle glitch on C2CK, C2CK left low at the end, C2D left
  low at the end. Timing faults are caught by the waveform check; coding
  faults by the decoder and the waveform check; reading faults by the rx
  check.
- RATE: for the ideal the line equals the span from the generator's own
  output on every seed (seed 1: `RATE bytes=16 cycles=11299`).
- Hand-in rules: 14 `run_args.txt` files; the 4 good ones are accepted;
  the 10 bad ones (P1 push-pull, P0 open-drain, P1 left as input, `-tx`,
  `-stimulus`, `-cycles`, `-inputs`, an ambiguous `-c`, two lines, a flag
  with no value) are setup failures.
- The real simulator: the kit's `pe_sim` with two programs that are not C2
  firmware (one loops and writes no pin; one drives C2CK low once and
  loops). The simulator accepted the command line, the word files and the
  stimulus files, and all 14 cases of each failed cleanly, with no RATE
  line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, with
care, and it is a fair test. A strobe slot is 50 cycles, so there are many
cycles per bit. With `clkdiv` 5 or 10 a write lands one cycle after a
tick, within the +-2 of every place, so the grid is reachable without
counting single cycles; a slot then has 10 or 5 ticks, enough to change
C2D after a rise and before the next fall, and to read the device's answer
(on the line 3 cycles after the place, seen 2 cycles later through the
synchroniser) before the next strobe. (`clkdiv` 25 or 50 is too coarse: C2D
could then only change in the cycle C2CK falls or rises.) Side-set can drive C2CK while
`out pins` puts C2D out least significant bit first (the default shift
direction is the C2 bit order), and `in pins` with `in_base` 1 collects the
device's bits least significant bit first, so `push` yields the byte
right-justified. The work is in keeping every path the same length: a
strobe of the chip's, a strobe of the device's, START, STOP and WAIT must
all take one slot, and the idle slot must cover pulling the command word,
a four-way dispatch on bits 15..12, turning n into the two LENGTH bits and
pulling the Data Write bytes. That likely needs more than one 64-word page
or a compact shared bit loop. The open-drain C2D also needs a released 1
written wherever the device or nobody drives, which a programmer who keeps
the last data bit on the pin will get wrong; the judge checks it directly.
