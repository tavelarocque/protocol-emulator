# Hidden test: AUD branch trace receiver

This folder is the examiner's side of the census for sigrok's `aud`
decoder. The programmer gets only the kit (`../../kits/aud/`: `isa.md`,
`pe_sim`, `TASK.md`) and never sees this folder. No firmware for the chip
was written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_rx.py` | a stand-in for `pe_sim run` that prints what an ideal receiver would push, with named faults. It decodes the stimulus in its own code. Not chip firmware |
| `selftest.py` | checks the judge: the interface, the stimulus against sigrok, every result, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

## The role, and why

RECEIVE. AUD branch trace is output by the target microcontroller: it
drives AUDCK, nAUDSYNC and AUDATA3..0, and a debugger or trace probe
captures them. A small I/O chip sitting on that port is the probe, which is
the job a host-side chip really does here. The trace is one-way, so a
scripted stimulus that cannot react is an honest stand-in for the target.
(sigrok's decoder handles only branch trace, not AUD's RAM monitor mode,
where the debugger drives the clock and commands; that mode is not tested.)

## The interface, as the task sheet states it

- Core clock 50 MHz (20 ns a cycle). AUDCK on P0 at 1 MHz (50 cycles, 25
  high, 25 low), nAUDSYNC on P1, AUDATA0..3 on P2..P5. P6, P7 are held low. The
  chip drives no pin; `run_args.txt` may not make P0..P5 outputs.
- Every level in the sheet is the level on the pin. Since a review on
  24 November 2026 the sheet also says that the threads see the pins
  through the input synchroniser of `isa.md`, which reads every input as 1
  in the first two cycles after reset. So the firmware sees AUDCK high and
  the nibble 0xF with nAUDSYNC high in cycles 0 and 1, then a fall of
  AUDCK in cycle 2. The sheet's earlier wording (cycle 0 levels, and which
  nibbles "ever appear" with nAUDSYNC high) was false as the threads see
  it and now speaks of the pins only. The judge was not changed: its
  stimulus, sigrok's capture and the stand-in all work on pin levels, and
  the first rising edge (cycle 30 at the earliest) is long after reset.
- nAUDSYNC and AUDATA change with AUDCK's falling edge; the rising edge
  reads them. Idle is nibble 0x3 with nAUDSYNC high. An address is a
  command nibble (0x8, 0x9, 0xA, 0xB for 4, 8, 16, 32 bits) with nAUDSYNC
  high, then 1, 2, 4 or 8 nibbles with nAUDSYNC low, least significant
  first. The destination is the previous one (0 at reset) with its low
  bits replaced. These are exactly the rules of sigrok's `aud` decoder.
- The host pushes no TX words. The firmware pushes two RX words per
  address: bits 15..0 of the full 32-bit destination, then bits 31..16.
  Payload only. The sheet's example (0x0C001234 in 32 bits, 0x5A in 8,
  0x7 in 4) gives 0x1234, 0x0C00, 0x125A, 0x0C00, 0x1257, 0x0C00.
- Latency: both words of an address are pushed no earlier than the rising
  edge carrying its last nibble and no later than 200 cycles after it.
- Stimulus: first rising edge between cycles 30 and 79, exact 50-cycle
  period, at least 4 idle nibbles first, 0 to 20 idle nibbles between
  addresses (0 means the next command comes on the very next edge), 4
  after the last, then the clock stops low; the run lasts 1000 cycles
  more. 1 to 40 addresses a run.

## What the judge does

For each of 14 cases (6 fixed: one 32-bit address, each width in turn,
short addresses from reset, eight back to back with no idle, all zeros and
all ones, 40 addresses with gaps of 0 to 3; and 8 seeded random cases of 1
to 30 addresses with random widths, values, gaps 0 to 20, lead 4 to 40 and
phase 30 to 79) it:

1. builds the stimulus from the sheet's rules (`stimulus`), writes it as a
   six-channel VCD at one sample per cycle, and requires sigrok-cli's `aud`
   decoder to read it as exactly the wanted addresses. If not, the judge
   itself is broken and the case fails as "judge:", never passes;
2. runs `RUN_DIR/pe_sim run RUN_DIR/aud.s -stimulus FILE -cycles N` plus
   `run_args.txt` (one line, `-config` and `-mode` only, with no mode other
   than `in` on P0..P5; anything else is a setup failure);
3. requires the `rx` words to equal `rx_words` (two per address, low then
   high, in order, nothing extra);
4. checks the latency window of every word.

It prints `RATE bytes=<4 x addresses> cycles=<first to last stimulus change>`
for the last passing case. For a receiver this is set by the scripted
target, not by the firmware: it is the same for every hand-in that passes
and shows only the line rate the test asks for (one nibble per 50 cycles).

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`), rerun on
24 November 2026 after the task sheet's correction, with the same result.

- Interface: `rx_words` on the sheet's example gives the six words printed
  in the sheet, and the sheet contains that text.
- Stimulus: on all 5 seeds, sigrok's decoder reads every one of the 14
  cases' stimulus as exactly the wanted addresses (70 of 70).
- Results: 13 results on 5 seeds, 65 verdicts, all as expected. The 3 that
  must pass do: the ideal receiver (words 5 and 6 cycles after the last
  nibble's edge), words at 199 and 200 cycles (the limit), and words pushed
  only at the next nAUDSYNC-high edge, where sigrok annotates. The 10
  broken ones all fail: a high word at 201 cycles (timing), words 2 and 1
  cycles before the last nibble's edge (timing), one flipped bit, halves
  swapped, short addresses not merged with the previous one, nibbles taken
  most significant first, AUDATA pins in the wrong order, the last address
  missing, one extra word, the first address pushed twice.
- RATE: equals the figure from the stimulus on every seed (seed 1:
  `RATE bytes=104 cycles=17025`).
- Hand-in rules: 4 good `run_args.txt` accepted; 9 bad ones refused as a
  setup failure (`-mode 0=pp`, `-mode 5=od`, `-stimulus`, `-tx`,
  `-inputs`, `-cycles`, ambiguous `-c`, two lines, a flag with no value).
- The real simulator: the kit's `pe_sim` behind a wrapper with a
  one-instruction program that loops on itself (not AUD firmware). It
  accepted the command line and the stimulus file, and all 14 cases failed
  cleanly ("0 rx words"), with no RATE line.

## What the judge does not check

- It runs `RUN_DIR/pe_sim`, whatever it is. Whoever runs the judge must put
  the real simulator into the run folder.
- The stimulus is ideal: exact period, no jitter, no skew between lines,
  only one clock rate (1 MHz). A real AUDCK runs much faster (often half the
  CPU clock); the sheet sets 1 MHz so that the test is about the
  instruction set and not raw speed.
- The command nibbles and the merge rule are sigrok's reading of AUD. Where
  a Renesas manual differs in detail, the sheet follows the decoder.
- No undefined command nibble, no nAUDSYNC glitch, no trace cut off half
  way, no clock that stops mid-address: the firmware's behaviour on bad
  input is not tested.
- The host reads RX words at once, so the 4-deep RX FIFO never fills.
- `run_args.txt` may set thread configuration constants (`in_base`,
  `clkdiv`, `timeout`, `timeout_vector`, shift direction). That is the
  chip's own hardware, not the instruction set: read `notes.md` and that
  line when hand-ins are compared.
- What the firmware does on P6, P7 and pin outputs is not looked at.

## Is a fully on-chip solution feasible?

Not shown: no firmware was written. My view from `isa.md` is yes, but it is
the tightest of the register budgets I would expect in this census. Each
nibble gives 50 cycles, and catching a rising edge and taking four
adjacent pins into the ISR is a handful of instructions, so speed is not
the problem, and unrolling one path per width avoids a nibble counter. The
hard part is state: the previous 32-bit address must survive between
addresses, which fills both X and Y, yet there is no jump on a pin, so
telling nAUDSYNC and the command bits apart needs pin values moved into a
register that can be tested, and merging a 4, 8 or 16-bit field into the
old low half needs shifting through the OSR and ISR. With X and Y holding
the address, only the OSR and ISR are free for that, plus `wait ...
timeout` as a branch on a pin. I believe it fits in 256 words with care;
a programmer who does not see that the shift registers can hold state is
likely to fail on the merge.
