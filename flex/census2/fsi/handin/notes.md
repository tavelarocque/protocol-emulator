# Notes: FSI master firmware

## What I read

- TASK.md, in full (two reads of about 140 lines each).
- isa.md, in full (four reads: lines 1-180, 180-360, 360-530, 530-699).
- The output of `./pe_sim run -help` (run 1 below).

Nothing outside this folder was opened, listed or searched. Besides pe_sim I ran
Python (on files in this folder only) for a CRC model and a test harness, and
small shell commands (`cat`, `wc`, `awk`, `grep`) on files in this folder.

## pe_sim runs (15 in total)

Every invocation of pe_sim is counted, including `asm` and `-help`.

1. `pe_sim run -help`: lists the flags. It says nothing about whether the
   simulated host drains the RX FIFO.
2. Probe program `probe/p1.s` (config: side-set on P1, `set pins` on P0,
   MSB-first in and out, threshold 16, crc_poly 0xE, crc_init 0xE, crc_in 1;
   P0 od, P1 pp; a stimulus pulling P0 low from cycle 20 to 40; two TX words).
   It showed:
   - the thread runs its first instruction in cycle 0, and a write made in
     cycle c shows as `pins c+1`;
   - `mov x, pins` reads all 8 pins zero-extended to 16 bits: 0xFC with P0
     driven low and the clock low, 0xFE with the line low and the clock high;
     a driven-low open-drain pin reads low at once (own output not delayed);
   - a line level that changes at cycle 20 is first seen by the thread at
     cycle 22 (two-cycle synchroniser), as isa.md says;
   - the CRC register with poly 0xE and init 0xE, fed 4 zeros by `in null, 1`,
     reads 4 (0b0100), which matches my Python model of the TASK.md CRC (the
     model reproduces all four CRCs in the TASK.md example, checked before any
     run);
   - `out x, 4` with MSB-first takes the top nibble (0xA of 0xABCD);
   - 7 pushes in a row all came out: the simulated host drains the RX FIFO, so
     `push` does not stall.
3. `pe_sim asm fsi.s`: assembled without error, 169 words. Spot checks of the
   hex: `start` is word 21, `set page, 1` is word 63, `LCD` is word 64,
   `FOUND` is words 124-127 and `RQ` is word 128, as planned.
4. The TASK.md example (two transactions, N = 3900) through my harness (below):
   PASS. Every clock edge exactly on its place (deviation 0), the command bits
   right, P0 released everywhere else, RX words 0x0000, 0x0000, 0x5AC3. The
   last `pins` line is the rising edge at 3890.
5. Random run, seed 1, 8 transactions (reads of 1, 2 and 4 bytes, ERR_C on a
   read and on a 4-byte write, D from 17 to 77): PASS, 15 RX words.
6. Random run, seed 2, 8 transactions (includes 4-byte write ACK, 2-byte write
   ERR_C): PASS, 14 RX words.
7. Random run, seed 3, 8 transactions (includes ERR_A on reads, 4-byte writes):
   PASS, 9 RX words.
8. Edge run of 8 transactions chosen so that the command CRCs are 0000, 0001,
   1000, 0100 and 1111, with D at 17 or 80, one of each size and direction,
   ERR_A and ERR_C, read data 0xFF and 0xFFFFFFFF: PASS. This covers the case
   where the firmware stops sending CRC bits early because the rest are 0 (see
   design), including a CRC of 0000.
9. Random, seed 4, 1 transaction (1-byte write, ERR_C): PASS.
10. Random, seed 5, 1 transaction (4-byte write, ERR_C): PASS.
11. Random, seed 6, 3 transactions: PASS.
12. Random, seed 7, 8 transactions: PASS.
13. Eight 4-byte reads, all ACK, data 0, 0xFFFFFFFF, 0x80000001, 0x7FFFFFFE,
    0x0000FFFF, 0xFFFF0000, 0x12345678, 0xA5A5A5A5, addresses 0 and 0x1FFFFC,
    all four slave IDs, D 17 to 80: PASS, 24 RX words.
14. Four transactions at extreme addresses (1-byte read of 0x1FFFFF with D 80,
    2-byte write to 0, 2-byte read ERR_A with D 17, 1-byte write of 0xFF to
    0x1FFFFF): PASS.
15. The example's files run directly with `-cycles 4500` (past N = 3900): the
    last `pins` line is still 3890, so after the last transaction the thread
    stops at `pull` with FSI_CLK high and no further edges.

No run failed, so no mistakes were found by pe_sim. Mistakes I caught on paper
before the first run are listed under "Mistakes".

### The harness

`probe/harness.py` (deleted at the end, with the rest of `probe/`, so that the
folder holds only what TASK.md asks for) built a run from a list of
transactions: the TX words, the slave's stimulus file exactly as TASK.md
describes (low from 94 + 20k to 114 + 20k for each slave 1 bit), and N. I
checked its output against the TASK.md example before using it: the seven words,
N = 3900 and the 19 stimulus lines all matched. It then ran
`pe_sim run fsi.s -tx ... -stimulus ... -cycles N` followed by `run_args.txt`,
and checked: every FSI_CLK edge up to N - 10 within 2 cycles of 100 + 20k /
110 + 20k and no other edges; every change of P0 has FSI_CLK high in the cycle
before; the chip's bit in every clock (P0 in the cycle before the rising edge)
equals the command bit, or 0 outside commands; P0 is never low outside
(rising edge S - 1, rising edge c + 1); the RX words equal the expected ones. I
also fed it a saved output with deliberately wrong expectations (a flipped data
bit, a flipped address bit, D + 1, an edge moved 3 cycles) to see each check
fail, without running pe_sim.

## Design

The run's configuration is in `run_args.txt`: `start=21, set_base=0,
set_count=1, sideset_base=1, sideset_count=1, out_msb_first=1, in_msb_first=1,
threshold=16, crc_poly=0xE, crc_init=0xE, crc_in=1`, P0 open-drain, P1
push-pull. The clock divider is left at 1, so one FSI clock is 20 instructions'
worth of cycles.

FSI_CLK is driven only by side-set, so every instruction says which half of the
clock it belongs to. In a clock whose falling edge shows at cycle F, the
instruction executed at F - 1 carries side 0 and the one executed at F + 9
carries side 1; everything executed in between carries the level of that half.
Each block of the program is written against this 20-cycle grid with delays,
and the comments in `fsi.s` give the cycle of every instruction. This keeps all
edges exactly on their places (the harness measured a deviation of 0 in every
run), and the error cannot add up because every path through every loop is 20
cycles a clock.

Data is inverted on the wire and the chip has no inverting instruction, so each
bit is sent by a branch: `out x, 1` takes the bit, `jmp !x` picks `set pins, 0`
(a 1, pull low) or `set pins, 1` (a 0, release), and that `set` is the same
instruction that makes the falling edge. Received bits are decided the same
way: `mov x, pins` at F + 5 (the slave's bit is visible to the thread from F - 4
to F + 15), compared with Y, which holds the pin snapshot of a released line
with FSI_CLK low, taken by `mov y, pins` in the first clock after each command;
a difference means the line is low, a logical 1, and `in y, 1` shifts in a 1
(Y's bit 0 is 1), otherwise `in null, 1` a 0.

The CRC is the hardware register: polynomial x^4 + x^2 + x + 1 written low power
first is 0xE, and with `crc_in` the register follows the bits that IN shifts, so
each send loop feeds it with `in x, 1`, and OUT can be used freely to skip and
extract bits. `crc_init` is 0xE, the state after the START bit from zero, so
START never has to be fed, and `mov crc, null` restarts it just before the
first bit after START. The register holds the CRC bit-reversed, first bit to
send in bit 0, and MSB-first OUT cannot reach that end, so the CRC loop keeps
the register value in Y and per clock takes Y's bit 0 (`mov osr, y; out null,
15; out x, 1`) and shifts Y right (`mov osr, y; out y, 15`). It stops when Y is
0: the remaining CRC bits are then 0, and a 0 is a released line, the same as
not sending; the firmware just starts listening for the slave a clock or more
earlier.

A command is sent as fields, each held bottom-justified in the OSR with its
shift count set so that the field ends exactly when the OSR is empty
(threshold 16); the send loop runs until `!osre` fails. The fields are: the
header (ID, 100, R/W and address bits 20..16, 11 bits, built in the ISR from
the operation word and the second word before the CRC restarts); the address
low word (16 bits, or for a 4-byte access bits 15..1, made by `out x, 15`); then
one size field: for a 1-byte write bits 8..0 of the data word, which are the
size bit 0 and the byte; for a 1-byte read or a 2-byte access the size bit S0
(0 or 1) taken from the type; for a 4-byte access "11" (address bit 0 sent as 1,
then the size bit); then up to two 16-bit data words for writes; then the CRC.
Y holds the type (R/W, size) from the operation word throughout the command; at
each field end the next field is chosen by branching on Y, decoded through the
empty OSR (`mov osr, y; out null, ...; out x, 1`), and the write-data count is
kept by decrementing Y (4-byte write 2 -> 1 -> 0). The header and address
fields share one loop: the ISR count is set to 0 before the header, the header
adds 11 to it and the address fills it, so `!isrf` tells which field just
ended. The size and data fields share a second loop, the CRC has its own.

Receiving: after the command the type moves into the OSR, at the top. A wait
loop samples every clock until the line is low (the slave's START). The next
four bits (ID, ID, code, code) go into the ISR, preset with 12 zeros so it fills
after them; the code is cut out (`in x, 2` of the four bits into a cleared ISR)
and pushed. If it is not ACK, or the access was a write, nothing more is read.
Otherwise the data loop reads until the ISR is full (preset with 8 zeros for 1
byte) and pushes; S1 of the type says whether a second 16-bit word follows.
Then a single idle loop covers the 4 response CRC clocks and the 20 idle
clocks, and in the high half of the last idle clock the next operation word is
pulled, 10 cycles before the next START. That is also where the firmware stops
when the host has no more words: `pull` stalls with side 1, so FSI_CLK stays
high after the last rising edge at N - 10, which TASK.md allows. (There is no
way for a thread to ask whether the TX FIFO is empty without autopull, and
autopull would break the field loops, so the `pull` had to be placed this late.)
The four idle clocks before the first transaction are the same idle loop,
entered at cycle 99 after a 99-cycle wait with FSI_CLK high.

The program needs more than 64 words, so it spans three pages. Each crossing is
a fall-through from the last word of one page into the next, with a `set page`
in a cycle that was padding anyway (words 63 and 127), plus `set page, 0; jmp`
to return to the idle loop. To make the second crossing a fall-through, page 1
has 15 `nop` words that are never executed.

## Program length

169 words: 154 instructions that run, plus 15 padding `nop`s that are never
executed (words 109 to 123). Pages: 0 to 63 (idle loop, header and address),
64 to 127 (size and data, CRC, waiting for the slave), 128 to 168 (code, data,
return).

## Mistakes

pe_sim found none (every run passed). On paper, while timing the blocks, I
caught: a `jmp CS [3]` that would have reached the CRC block one cycle late
(fixed to `[2]`); the return to the idle loop from the "no data" path arriving
one cycle too late for an entry at F - 1, fixed by entering the idle loop at F
with the falling edge made by the `jmp` itself; and an early plan to pull the
next operation word during the response, which would have stalled the clock
mid-run after the last transaction. I did not break any of the test's rules
that I know of.

## Things in isa.md that were confusing or seem wrong

- The CRC section says "`mov` reads it and restarts it", but the `mov` section
  says a read leaves the high half in the low half and stops it following the
  data, and that a write restarts it from `crc_init`. I took the `mov` section
  as right (reading does not restart); my firmware does not depend on the
  difference, because it restarts the register by a write before each command.
- `jmp !osre` "can tell first whether a word came" only with autopull. Without
  autopull a thread has no way to see whether the TX FIFO is empty, so firmware
  that must stop cleanly when the host runs out of words has to place its
  `pull` where a stall is harmless. This is worth a sentence in the document.
- The CRC register is a right-shifting (reflected) register, so for an
  MSB-first protocol its result comes out bit-reversed with the first bit in
  bit 0, and MSB-first OUT cannot reach bit 0 first. The document says this and
  shows a reversal through the ISR, but that needs IN and OUT to shift in
  opposite directions, which an MSB-first receiver (IN shifting left) cannot
  have. A small CRC can be sent bit by bit from a register as I did.
- Side-set is not optional per instruction (`side V` on every line once
  `.side_set` is used), and delays drop to 0..7 with one side-set bit, which
  makes cycle-exact code long; an "opt" form as in PIO would help.
- Inverted line coding (FSI, and others) has no help in the ISA: no inverting
  `mov`, and the only per-bit way is a branch. An invert option on a pin or on
  `mov` would shorten every send and receive loop.
