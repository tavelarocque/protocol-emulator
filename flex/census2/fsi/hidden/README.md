# Hidden test: FSI master (DSView decoder `fsi`)

This folder is the examiner's side of round 2, Part A, for IBM's Flexible
Service Interface. The programmer gets only the kit (`../../kits/fsi/`:
`isa.md`, `pe_sim`, `TASK.md`) and never sees this folder. No firmware for
the chip was written for this test, not even as a check.

| File | What it is |
|---|---|
| `accept.py` | the judge. `accept.py RUN_DIR [seed]`, exit status 0 only on a full pass, last line `ACCEPT PASS` or `ACCEPT FAIL` |
| `ideal_wave.py` | an ideal FSI master as a waveform generator, standing in for `pe_sim`, with named faults. Not chip firmware |
| `selftest.py` | checks the judge: the sheet's example, the CRC, the stimulus, every waveform, the RATE line, the hand-in rules, the real simulator |
| `selftest_output.txt` | its output on seeds 1, 2, 3, 7 and 11 |
| `README.md` | this file |

There is no `PORT.diff`: the decoder runs in sigrok-cli 0.7.2 exactly as
fetched (below). There is no `OUT_OF_REACH.md`.

## The role, and why

BOTH: the chip is the FSI master. It drives FSI_CLK (P1, push-pull) and,
during its own command, FSI_DAT (P0, open-drain with a pull-up); a scripted
slave, given to the simulator as `-stimulus`, answers every command with
START, its ID, a response code, the data of a read, and a CRC. The firmware
pushes each response code, and the data of each read, to the host as `rx`
words.

That is the role a small chip really plays on this link. FSI's master is
the service processor (BMC) of an IBM POWER system; BMCs without a hardware
FSI master drive the link from GPIO pins (Linux's `fsi-master-gpio`) or
from a coprocessor (`fsi-master-ast-cf` on the AST2500's ColdFire), which
is what this chip would be. A slave or a passive sniffer would have to
follow the master's clock at up to 166 MHz, which the chip cannot. The
master owns the clock, the link is synchronous, and the slave works at any
lower rate (the GPIO master runs it at a few MHz and stops it between
transactions), so 2.5 MHz is a real use of the protocol. Pure TRANSMIT
would leave out the slave's half and the turnaround, which is most of what
makes an FSI master; RECEIVE alone is not a role a host chip has.

Clock 50 MHz (20 ns a cycle). FSI_CLK 2.5 MHz: clock k is falling edge
100 + 20k then rising edge 110 + 20k, each +-2 cycles, no drift. P0 FSI_DAT
`od`, P1 FSI_CLK `pp`; the judge requires exactly these two modes. FSI data
is inverted on the wire (a 1 is the line low), as the decoder and Linux's
master (`~cmd->msg`) both have it.

Because the slave is scripted it cannot react, so the sheet fixes the
schedule: transaction 0's START in clock 4, the slave's START D clocks
after the command's last CRC bit, and the next START exactly 21 clocks
after the response's last CRC bit (20 idle clocks; Linux's GPIO master
also clocks a run of zeros after each response before the next command). D is drawn from 17 to 80 for every
transaction and the firmware is told only the range, so it has to hunt for
the slave's START clock by clock, as a real FSI master does (Linux's
`read_one_response` polls clock by clock up to a time-out). The lower bound
17 stands for the slave's send delay, which Linux sets to 16 clocks by
default, as I recall it.

The task is a subset of FSI: absolute-address (ABS_ADR) reads and writes of
1, 2 and 4 bytes, answered ACK, ERR_A or ERR_C. Left out, and said so in the
sheet or here: BREAK and link setup, the relative and same-address
commands, BUSY with D_POLL and E_POLL, I_POLL, TERM, and checking the
response's ID and CRC (the scripted slave always gets them right).

## The host interface, as the task sheet states it

TX, per transaction: an operation word (bits 1..0 size code 0/1/2 for
1/2/4 bytes, bit 2 read, bits 4..3 slave ID), a word with address bits
20..16, a word with address bits 15..0, and for a write the data (one word,
or two for 4 bytes, high half first). RX, per transaction: the response
code (0 ACK, 2 ERR_A, 3 ERR_C), then for a read answered ACK the data in
the same form. The address is the plain byte address; putting the size
into its low bits on the wire (01 for a 4-byte access) is the firmware's
job. The sheet's example, a 1-byte write of 0xA5 to 0x000C10 on slave 0
and a 2-byte read at 0x1FFFFE on slave 3 answered 0x5AC3, is the words
0x0000, 0x0000, 0x0C10, 0x00A5, 0x001D, 0x001F, 0xFFFE and the rx words
0x0000, 0x0000, 0x5AC3. The sheet says "The host sends only the words
defined above. All line coding, framing and timing must be done by the
firmware." The clock, the inversion, START, the command code, the size
encoding, the CRC, finding the slave's START and reading it are all the
program's.

## The decoder

DSView's `fsi` (Raptor Engineering, 2020) loads and runs in sigrok-cli 0.7.2
with no change at all: `git -C ../../decoders status -- fsi` is clean, and
the judge only points `SIGROKDECODE_DIR` at that folder (and sets
`PYTHONDONTWRITEBYTECODE` so nothing is written there). It takes
`data` and `clock`, waits on either clock edge, inverts the data, samples
the master's bits on rising edges and the slave's on falling edges, checks
both CRCs and decodes ABS_ADR, REL_ADR, SAME_ADR, TERM, the polls, BREAK and
the four response codes. Reading `pd.py` and running it on synthetic
captures found two properties that shape the test:

- **It reads the slave ID least significant bit first** (`pd.py` line 185:
  `id = (id >> 1) | (bit << 1)`). Linux's `fsi-master-gpio`, which talks to
  real POWER9 hardware, sends every field most significant bit first
  (`msg_push_bits` then `serial_out` from the top bit), the ID included.
  The sheet follows Linux. The decoder compares the command's ID with the
  response's, both read the same way, so its decoding is self-consistent;
  only the number it prints for IDs 1 and 2 is swapped. The judge
  therefore expects `Slave ID: 0x2` for ID 1 and `0x1` for ID 2. This is
  the one place the judge reads a decoder annotation other than literally,
  it changes nothing the decoder is given, and it was in the judge before
  any programmer started. A hand-in that sends the ID least significant bit
  first fails the judge's own bit-by-bit check of the line (fault `idlsb`
  below), so the ID's order is still judged.
- **After the first response, it samples the master's command CRC on
  falling edges.** Its `valid_response` flag is set by a response and
  cleared only by a BREAK or the next response, and the state test that
  picks the sampling edge includes `CRC and valid_response`. So in every
  command after the first, CRC bits 1 to 3 are read at the falling edge
  that begins their clock. A master that launches each bit at the falling
  edge or earlier, while the clock is high, and holds it through the low
  half, is read correctly; one that changes data in the low half is not
  (fault `afterfall` below fails the decoder as well as the waveform
  check). That launch is what the FSI specification describes ("clocked
  out on the falling edge and latched in on the rising edge", as the
  decoder's own comment quotes it) and what Linux's GPIO master does (set
  the data, then drive the clock low, then high). So the sheet states it as
  the rule, the judge checks it directly from the pins on every bit, and no
  waveform is adjusted for the decoder.

Neither property needed a change to the decoder. The capture given to the
decoder is the wire itself, one sample per 20 ns cycle (VCD, P0 and P1).

## What the judge checks

For each case it builds the TX words and the stimulus from the sheet's
rules, and first requires the decoder to read the ideal link (the judge's
own ideal master plus that stimulus) as exactly the wanted transactions,
so the scripted slave is a real FSI slave. Then it runs `RUN_DIR/pe_sim`
with `-tx`, `-stimulus`, `-cycles N` and `run_args.txt`, works out the wire
level of both pins in every cycle (pp: the output; od: output AND slave),
and requires:

- FSI_CLK high at cycle 0, then every edge, falling and rising in turn,
  within +-2 cycles of its place, with no extra edge, and all of them
  present to the end of the run (rising edge N - 10); after that it may stop
  or keep its places. High and low at least 6 cycles each follows.
- The chip's DATA output changes only in a cycle after one in which FSI_CLK
  was high: never in the low half, never in a rising edge's cycle.
- The chip pulls DATA low only strictly between the rising edge before its
  START clock and the rising edge after its last CRC bit.
- The line's bit at every rising edge through the end of the run equals the
  ideal link: idle zeros, the command bit for bit (START, ID most
  significant bit first, 100, R/W, the address with the size encoding, the
  size bit, write data, CRC), the turnaround zeros, the slave's response,
  the 20 idle clocks, the next START on its exact clock.
- The decoder's annotations equal, exactly and in order, START, slave ID,
  `Command: ABS_ADR (0x04/3)`, direction, address, data size, write data,
  `CRC: 0x? (GOOD)`, TAR, then START, slave ID, response, read data,
  `CRC: 0x? (GOOD)`, TAR, per transaction, with no warning and nothing
  extra; a decoder error is a failure.
- The `rx` words equal the sheet's, in order, nothing extra.
- `run_args.txt`: one line, only `-config` and `-mode`, P0 `od`, P1 `pp`.

Cases: six fixed (the sheet's example; a 4-byte read of all ones at the top
address with the slowest answer, D = 80; all zeros with the fastest answer,
D = 17; every size both ways on every slave ID; four error answers mixed with
an ACK; eight transactions) and eight seeded random ones (1 to 3 or 1 to 8
transactions of random kind, size, ID, aligned address, data, code (ACK 8
times in 10) and D). After the case lines: `RATE bytes=<data bytes written
and read> cycles=<first to last pin change>` for the last passing case.
With the schedule fixed by the sheet, the rate is set by the sheet and the
slave's delays; only where the firmware stops the clock varies.

## What the judge does not check

- The judge runs `RUN_DIR/pe_sim`, whatever it is; whoever runs it must
  put the real simulator there. The decoders' place is fixed in
  `accept.py` (`FSI_DECODERS` overrides it).
- BREAK, link initialisation, REL_ADR, SAME_ADR, TERM, BUSY and the polls,
  and a master that checks the response's ID and CRC or times out: not in
  the task (above).
- Pins P2 to P7: the sheet calls them unused and the judge ignores their
  modes and outputs.
- Real FSI electrical timing (the clock at 2.5 MHz, edges in whole 20 ns
  cycles); setup and hold are modelled as "change only while the clock is
  high".
- A slow host: the TX FIFO is refilled at once.
- `run_args.txt` can set configuration constants (`clkdiv`, side-set,
  shift directions, `crc_poly`, `crc_init`); that is the chip's hardware,
  not the instruction set, and should be read when hand-ins are compared.

## Validation

    python3 -B selftest.py 1 2 3 7 11

Result: `SELFTEST PASS`, nothing wrong (`selftest_output.txt`): 29 checks
as expected, and of the waveform verdicts 25 must-pass (5 waveforms x 5
seeds) all passed and 120 must-fail (24 x 5) all failed. It checks:

- Interface and example: the judge's TX words, rx words, the table of bits
  and clocks (both commands and both responses, CRCs included), N = 3900,
  the next START at clock 190 and the 19-line stimulus file are exactly the
  text printed in the sheet.
- CRC: the judge's bit-by-bit CRC equals the stand-in's, which is Linux's
  `lib/crc4.c` nibble table, on 2000 random messages; the stand-in's command
  bits equal the judge's for every transaction of every case.
- Stimulus: the decoder reads the ideal link of all 14 cases on every seed
  as wanted.
- Waveforms: the stand-in (`ideal_wave.py` behind a wrapper named
  `pe_sim`) reads the judge's words by the sheet's rules in its own code and
  does not know the slave's answers or delays: it reads the stimulus file
  at each falling edge as a master would, hunts for the slave's START and
  reads the code and data. 5 waveforms must pass (ideal; falling edges 2
  late with rising 2 early; the reverse; data changed 1 cycle after the
  rising edge before; the clock running on; with the ideal changing data in
  the falling edge's own cycle, the latest allowed) and 24 must fail (an
  address bit flipped; address least significant bit first; slave ID least
  significant bit first; data not inverted; CRC without START; 4-byte
  address sent with 00; size bit 1 for a byte; one rx bit wrong; a 4-byte
  read's rx words swapped; no response-code word; an extra rx word; every
  response read as ACK; the slave assumed at D = 17; every command a clock
  late; 19 idle clocks; one rising edge 3 late; a 21-cycle period; data
  changed 1 cycle after each falling edge; the first START changed in the
  cycle before its rising edge; in its cycle; a one-cycle pull while the
  clock is high in the turnaround; the clock falling first at cycle 5; the
  clock stopping 6 clocks after the last response; the last transaction
  missing). Each verdict is printed per seed, with which checks objected.
- RATE: equals the figure from the stand-in's own pin changes, every seed.
- Hand-in rules: 11 bad `run_args.txt` refused (`-tx`, `-stimulus`, `-s`,
  `-cycles`, `-inputs`, ambiguous `-c`, two lines, a flag without value,
  P0 push-pull, P1 open-drain, P1's mode missing); 2 good ones accepted.
- Real simulator: the kit's `pe_sim` with `idle: jmp idle` (drives no pin;
  not FSI firmware) accepts the command line, word file and stimulus file,
  and every case fails cleanly on the waveform check, with no RATE line.

## Is a solution feasible on the full instruction set?

Not shown: no firmware was written. My view from `isa.md` is yes, but this
is the most demanding of the Part A sheets I would expect, for four
reasons that stack. First, the data is inverted on the wire and no
instruction inverts, so every bit sent and every bit read goes through a
branch (`out x, 1` then `jmp !x` into two equal paths that `set pins` 0 or
1; and a read of P0 into X with `mov x, pins` or `in`, compared with `jmp
x!=y` or `!x`, then `in` of a constant 1 or 0). Second, the CRC: there is no
XOR, so it has to come from the CRC register (`crc_poly` 0xE, the
polynomial 0x7 written low power first, from 0), which follows only the
first bit of each `out`; so every command bit from START on, the START,
ID and command constants included, has to pass through one-bit `out`s, and
the register reads back bit-reversed, which happens to be the order to
send with least-significant-first `out`s. Third, the slave's START comes
at an unknown clock, so the master polls the line once per clock without
losing the clock's grid, and only then knows when the 20 idle clocks end.
Fourth, the response's length depends on the code and on the read's size,
which the program must still hold (in the flow of control, or the ISR or
OSR) after the command's bits have used up X, Y and the OSR. Each clock is
20 cycles, which leaves room for four or five instructions per bit with
side-set driving FSI_CLK, and 256 words leave room for separate code paths
per size. None of this needs a feature the chip lacks; it needs a lot of
careful cycle counting, which is where I would expect a first hand-in to
fail if it does.
