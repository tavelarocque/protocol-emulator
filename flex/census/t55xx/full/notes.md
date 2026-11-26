# Notes: T55xx write/reset firmware

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `pe_sim run -help` output (run 1) and the bare `pe_sim` subcommand list (run 2).

Nothing else. One accident to report: my very first command was `ls -la && cat TASK.md && cat isa.md` in one go. Its output was too long, so the tool harness saved it to a file outside this folder and showed me only the first 2 KB (the listing and the start of TASK.md). I did not open that saved file; I re-read TASK.md and isa.md from this folder instead. The `ls -la` listing also showed the `..` entry's metadata line, which is outside the folder, but nothing beyond that line.

## Design

The whole program runs with `clkdiv=40`, so one thread tick is 40 cycles, exactly half a carrier period. P0 is driven only by side-set (`.side_set 1`, `sideset_base=0`, `sideset_count=1`). While the field is on, every executed instruction carries the opposite side value from the one before it, so P0 changes every 40 cycles whatever the instruction does. Every branch is laid out so that both the taken target and the fall-through keep that alternation. While the field is off (a gap), every instruction is `side 0` and delays are allowed, so all the bookkeeping (pulling words, picking the next bit, deciding what comes next) is done inside gaps, where its cost only lengthens a gap that has to be at least 20 ticks anyway.

Bit timing in ticks: a 0 is 47 ticks of field on (1880 cycles, the middle of 1440 to 2320); a 1 is 111 ticks (4440 cycles, the middle of 4000 to 4880). Both are odd so the bit starts with a rise and ends with a fall. The send loops are `set x, N side 1` then `nop side 0 / jmp x-- side 1` pairs; the 1 loop falls into the 0 loop, and the 0 loop falls into the gap code, whose first instruction (side 0) is the fall.

Gaps: every gap path ends in a common block (`have`) of 35 ticks (a 32-tick delay loop, `out x, 1`, and the branch on the bit). Write gaps come out as 36 ticks (next bit in the same word), 43 (pull a password or data word), 45 (address) or 47 (lock bit): 1440 to 1880 cycles, inside 800 to 2400. Start gaps are 41 (standard), 44 (protected) or 45 (reset) ticks: 1640 to 1800 cycles. The gap after the last bit is 36 ticks.

Carrier before each command: 267 ticks from the rise to the start-gap fall (10680 cycles; for the first command 10640 counted from the first change at cycle 41). It is a nested loop (Y 4 times, X 32 times, 2 ticks each) ending with `pull side 1`. That pull is the only place the program waits on the FIFO: after the last command it stalls, P0 has just risen, and with the stalled pull applying side 1 every tick P0 stays high for the rest of the run, after 266 ticks (10640 cycles) of carrier following the last write gap.

Data path (`out_msb_first=1`, `threshold=16`): the header is pulled into the OSR and copied to the ISR (`mov isr, osr`). From the OSR: drop 8 zero bits, `out x, 2` takes the reset and protected flags, drop 4 more so that only the two opcode bits remain (opcode bit 1 first). Y is set to the number of segments still to send after the opcode: 6 for protected (pwd hi, pwd lo, lock, data hi, data lo, address), 4 for standard (lock, data hi, data lo, address), 0 for reset (the reset header's opcode bits are already 00). The standard sequence is the tail of the protected one, so one countdown serves both. In each gap, `jmp !osre` sends the next bit of the current word; when the word is used up, Y is decremented and dispatched: 0 means done, the value 3 means lock, the value 0 after the decrement means address, anything else means pull a FIFO word. The lock bit and the address come from the header copy in the ISR: `mov osr, isr`, shift up to the field, `out x, n`, `mov osr, x`, then drop `16 - n` bits so the OSR counts as empty exactly after the field. That keeps `!osre` as the only bit counter.

Registers: OSR (word being sent), X (bit value and loop counter), Y (segment countdown, also the outer carrier counter), ISR (header copy).

## pe_sim runs

1. `pe_sim run x.s -help`: printed the run flags (config field names, `-mode`, `-tx`, `-cycles`, `-inputs`, `-stimulus`).
2. `pe_sim` with no subcommand: printed the subcommand list (asm, run, version, help).
3. `pe_sim asm t55xx.s`: assembled without errors, 53 words.
4. `pe_sim run` on the TASK.md example (9 words, N = 1081200): first change at cycle 41, all half periods 40, gaps 1440 to 1880, ends high at cycle 559721. My checker `check.py` (which decodes the waveform with the TASK.md limits and compares to bits built from the words) said OK. On-times seen: 1880 and 4440 only, plus 10680 for the carriers between commands.
5. to 18. Fourteen runs from `gen.py`, each checked with `check.py`, all OK, all half periods 40, all gaps 1440 to 1880:
   - 5: one reset; 6: one standard write; 7: one protected write;
   - 8: eight resets; 9: eight protected writes; 10: mixed s r p s r p s p;
   - 11 to 18: random runs of 1 to 8 random commands (seeds 7 to 14), with some data words forced to all zeros or all ones.

18 runs in total. No mistakes found in the program; it passed on the first simulated run, so nothing had to be fixed.

## Files

- `t55xx.s`: the program. `run_args.txt`: `-config clkdiv=40,sideset_base=0,sideset_count=1,out_msb_first=1,threshold=16 -mode 0=pp`.
- `check.py`, `gen.py`: my test helpers. `ex.txt`, `ex.out`, `w*.txt`, `o*.txt`: test inputs and simulator outputs.

## Program length

53 instructions (53 words, all in page 0).

## Confusing or possibly wrong in isa.md

- The width and range of `clkdiv` are not given anywhere. 40 worked, but I had to assume it would.
- `in` direction is described loosely ("shifts count bits right into the ISR" by default; with `in_msb_first` "new bits entering at the bottom"). Where new bits enter in the default mode is not stated. I avoided `in` entirely because of this.
- `out x, n` with `out_msb_first`: the text says the bits "arrive right-justified", but not which of them ends up most significant. I assumed the first bit shifted out lands highest, which the address bits confirmed in simulation.
- The pin output register resets to all ones, so a push-pull P0 starts high and the first change of any carrier is a fall. That is stated, but it is easy to miss for a line that should idle low.
- No instruction inverts a value, so toggling a pin has to live in the control flow. With side-set and `clkdiv` set to a half period, that is easy, but the doc does not suggest it; the side-set section only shows clock edges.
- With `.side_set 1` the delay field drops to 0 to 7. This is stated in the assembler section but not next to the side-set description.
- I found nothing that looked wrong; the simulator behaved as the text describes in every case I relied on (side-set applied while a `pull` stalls, `mov osr, x` resetting the shift count, `!osre` with threshold 16).
