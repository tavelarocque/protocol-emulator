# Hidden test: SWIM host (sigrok decoder `swim`)

The examiner's side of the census attempt for `swim`, ST's Single Wire
Interface Module for STM8 debugging. The programmer gets only the kit
(`../../kits/swim/`: `isa.md`, `pe_sim`, `TASK.md`) and never sees this
folder. No firmware for the chip was written for this test, not even as a
check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal SWIM host as a waveform generator that listens to the stimulus, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the interface, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2 and 3 |
| `README.md` | this file |

## The role: both directions

A small chip on a SWIM line is the host, the debug probe; the STM8 is the
target. That role cannot be played as a pure transmitter: the target
answers every frame with an acknowledge bit (and sigrok's decoder only
reports frames that were ACKed), it opens the conversation with a
synchronization frame, and a ROTF read is data from the target. So the
chip transmits and receives, and the target is a scripted `-stimulus`
waveform. Because the stimulus cannot react, the task sheet fixes the whole
timetable: the target's sync frame at cycle 250000, and every frame 220
cycles after the falling edge of the previous acknowledge bit. The chip has
to listen to the line to stay on it: a target NACK (scripted, unknown to
the firmware) means the frame must be sent again, and ROTF data must be
read off the wire.

- Clock 40 MHz (25 ns a cycle). SWIM clock 8 MHz = 5 cycles; a low-speed
  bit is 22 SWIM clocks = 110 cycles, a 1 low for 10, a 0 low for 100.
- P0, open-drain, the only pin. The wire is the AND of the chip's output and
  the target's stimulus.
- Entry sequence (16 us low, 4 pulses at 1 kHz, 4 at 2 kHz), starting at a
  cycle of the chip's choosing between 400 and 4000.
- Commands SRST, ROTF and WOTF, N from 1 to 255, 24-bit addresses, as in
  ST's UM0470.

## The host interface

Per operation: a command word (bits 9..8 the command, 0 SRST, 1 ROTF,
2 WOTF; bits 7..0 N, 0 for SRST); for ROTF and WOTF two address words
(address bits 23..16 in bits 7..0, then address bits 15..0); for WOTF, N
data words, the byte in bits 7..0. Every other bit 0. The sheet's example:
SRST, WOTF 0xA0 to 0x007F80, ROTF 2 bytes from 0x004800 are the words
0x0000, 0x0201, 0x0000, 0x7F80, 0x00A0, 0x0102, 0x0000, 0x4800. The chip
pushes one RX word per byte read, the byte in bits 7..0. The sheet says:
"The host sends only the words defined above. All line coding, framing and
timing must be done by the firmware."

## What the judge does

Fifteen cases per seed: seven fixed (SRST alone; the real start-up write of
0xA0 to SWIM_CSR; the sheet's example; write 4 and read 4; a case full of
NACKs, including two in a row on a command and on a data byte; a ROTF of
255 bytes; a WOTF of 64) and eight seeded random ones (1 to 5 operations,
N up to 6 or 40, NACKs on command and WOTF data frames with probability
2/7, one or two in a row). For each it:

1. builds the TX words from the interface above, and the target's stimulus
   and the chip's ideal edges from the timetable (`Timetable`);
2. first checks the stimulus is real SWIM: the stimulus together with an
   ideal host's edges is decoded by sigrok, and must give exactly the
   wanted content (otherwise the case is a judge failure, never a pass);
3. runs `RUN_DIR/pe_sim run RUN_DIR/swim.s -tx F -stimulus S -cycles N`
   plus `run_args.txt`, which may hold only `-config` and `-mode`, and must
   hold exactly one mode, `0=od`;
4. decoder check: makes the wire (chip AND target) into a sigrok session
   file, one sample per cycle, and runs sigrok-cli's `swim` decoder.
   From the decoder's "enter sequence" on, the protocol row must be exactly:
   the enter sequence, the target's synchronization frame, then per
   operation the command, "byte count", "address" and the data bytes
   (data-write or data-read), in order, nothing else. NACKed frames do not
   reach that row; the decoder only passes ACKed ones;
5. edge check, from the chip's own output: released at cycle 0; the entry
   sequence's 18 edges (start in 400..4000, first low 640 +-2, then each
   fall +-2 and each rise +-1 from the actual rise before it); nothing until
   the sync frame; then exactly the timetable's edges, each within +-2
   cycles of its place, and no other edge. This is what holds the bit
   timing, the parity bits, MSB-first order, the resends, the chip's ACK
   bits for target frames, and that the chip never drives the line while
   the target does: the decoder checks none of those directly (it does not
   check parity at all, and accepts any timing it can split into bits);
6. rx check: the rx words must be the bytes the target sent to ROTFs, in
   order, nothing extra.

It prints a line per case, then `RATE bytes=<payload bytes>
cycles=<P0's first change to its last>` for the last passing case, then
`ACCEPT PASS` or `ACCEPT FAIL`. Payload bytes are ROTF plus WOTF data
bytes. The rate is set almost entirely by the timetable (the entry
sequence alone is 240640 cycles), so it says little about the firmware.

sigrok-cli 0.7.2 starts the `swim` decoder before it hands on the sample
rate of a VCD or binary input file, and the decoder then stops with an
error; a sigrok session file (`.sr`) carries the rate, so the judge writes
one. sigrok's decoder also reports the 16 us low that opens the entry
sequence as a "synchronization frame"; the content check therefore starts
at the decoder's "enter sequence".

## Validation

    python3 -B selftest.py 1 2 3

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`): 69
waveform verdicts (23 waveforms on 3 seeds), all as expected, plus the
interface, RATE, hand-in and real-simulator checks.

The stand-in simulator (`ideal_wave.py` behind a wrapper named `pe_sim`)
does not share the judge's timetable code. It reads the judge's words back
into operations by the sheet's rules, in its own code, and exits with an
error on words that break them. It then behaves as a host would: it finds
the sync frame in the stimulus, times every frame from the target edges it
has found, tells ACK from NACK by the length of the target's low and
resends, and reads the target's data frames from their low times. So the
ideal waveform passes only if the judge's words, its stimulus, its own
idea of the host's edges and sigrok's decoder all agree.

- Interface: `tx_words` gives exactly the words printed in the sheet, and
  the judge's timetable puts the sheet's example table where the sheet does
  (command frame from 250860, ACK at 251410, next frame at 251630, its ACK
  at 252730).
- Waveforms: 23 waveforms, 5 that must pass and 18 broken ones, on 3 seeds.
  Must pass: ideal; entry from cycle 400; entry from cycle 4000; the entry
  sequence at its limits (periods alternately 1 cycle long and short, falls
  2 off); every frame edge 2 cycles off, alternately early and late. Must
  fail: one wrong data bit; a wrong parity bit; LSB first; one edge 3
  cycles late; the first frame 3 cycles early; entry at 399; entry at
  4001; one entry rise 2 cycles late; no entry sequence; a NACK ignored; no
  ACK from the chip for a target frame; a NACK from the chip instead; the
  chip pulling the line low during a target bit; a stray bit after the
  last operation; one wrong rx word; an extra rx word; rx bytes in the
  wrong half of the word; the last operation dropped. The self-test also
  requires that no verdict came from a judge or simulator error.
- RATE: for the ideal waveform it equals the span of the stand-in's own
  edges on the last case.
- Hand-in rules: 10 bad `run_args.txt` files (`-mode 0=pp`, no mode, a
  second pin's mode, `-tx`, `-s`, `-cycles`, `-inputs`, an ambiguous `-c`,
  two lines, a flag with no value) refused as setup failures; two good ones
  accepted.
- The real simulator: the kit's `pe_sim` with a one-instruction program
  that drives no pin (not SWIM firmware) accepts the word and stimulus
  files, and all 15 cases fail cleanly ("the chip never moves P0").

The self-test takes about 3.5 minutes a seed; the judge alone, on one
hand-in, about 10 seconds.

## What the judge does not check

- The chip never has to NACK: the target's data frames always have correct
  parity, so a chip that does not check parity is not caught.
- The target never NACKs the N or address frames, never waits (no wait
  states, no late answers), and never uses high-speed mode or a
  communication reset. The NRST pin is not modelled.
- What the target does with the commands (that SRST resets it only with
  SWIM_DM set, that SWIM_CSR must be written first) is not modelled: any
  sequence of operations is accepted.
- The timetable is fixed to the cycle, which a real target, with its 5% RC
  oscillator, would not be. Real hosts must wait for the target; this chip
  may instead count cycles from the sync frame, and that passes. A NACK in
  the stimulus still forces it to read the line.
- `run_args.txt` may set configuration registers (`clkdiv`, `timeout`,
  and so on): that is the chip's hardware, but should be read with the
  notes when hand-ins are compared.
- As in the pilot, the judge runs whatever `RUN_DIR/pe_sim` is: whoever
  runs it must put the real simulator there.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, but it
is the hardest kind of task in the census so far, a host that must both
send and listen on one open-drain wire, cycle-exact. Every scheduled edge
falls on a multiple of 5 cycles from cycle 0, so with a divider of 5 one
tick is one SWIM clock: a bit is 22 ticks, and a 1's low (2 ticks) and a
0's (20) fit the delay field and short loops. The entry sequence needs
delays of 20000 cycles, which nested X/Y loops or the wait timeout can
make. The firmware can resynchronise on every target falling edge (the
sync frame, each ACK, each target data frame) with a wait on P0, allowing
for the two-cycle input synchroniser, so errors do not add up. The tight
parts are registers and memory: the frame being sent must be kept for a
resend after a NACK while it is shifted out, parity has to be counted
along the way (in the control flow, or with the CRC register), and N must
be counted for WOTF and ROTF while bytes are read in and pushed. With X, Y,
OSR and ISR and 256 words, that fits, but the programmer has to count
every path's ticks, including the TX FIFO pulls, against a timetable that
does not move.
