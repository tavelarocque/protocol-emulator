# Round 2, Part A: the mutants the hidden tests let through

`run.py` is round 1's mutation script ([`../../census/mutants/run.py`](../../census/mutants/run.py)) with two lines changed: it reads the names from `census2-log.md` (Part A passes only) and the hand-ins from the round-2 kits. As in round 1, each of the 8 passing programs got up to 5 mutants, each changing one number in one instruction line by one (seeded by the protocol's name, so reproducible), kept only if the program still assembled. The hidden tests rejected 35 of the 40 (`results.json`).

Each survivor was traced with round 1's tools ([`../../census/mutants/classify/`](../../census/mutants/classify/)): the survivor and its original were run through every case the hidden test judges, with every simulator output saved, and the outputs compared edge by edge.

| Protocol | Line | Change | What it does on the wire | Within the task sheet? |
|---|---|---|---|---|
| fsi | 172 | `nop side 1` to `nop side 0` | Nothing, in any of the 14 judged runs. The line is one of 15 padding `nop`s the programmer wrote to reach a page boundary; they are never executed. | Yes: no change |
| mipi_rffe | 127 | `jmp x-- p3 side 1` to `side 0` | Four SCLK half periods become 9 and 11 cycles instead of 10 and 10; no edge moves by more than 1 cycle. | Yes: every SCLK edge must be within +-2 cycles of its place (TASK.md line 130) |
| mipi_rffe | 172 | delay `[3]` to `[4]` | One SCLK half period becomes 11 cycles; one edge moves by 1 cycle. The words read back are the same. | Yes: +-2 cycles |
| st7789 | 17 | `jmp !y data side 0` to `side 1` | SCL high and low times change by one cycle (20 ns) at byte ends; no edge moves by more than 1 cycle. | Yes: every high, low and period limit of the sheet (TSHW, TSLW, TSCYCW, TCSH) still holds, as the hidden test checks |
| eth_an | 15 | `nop [15]` to `nop [14]` | The gap before a burst is 4,096 cycles shorter per burst (up to 32,768 cycles, 0.8 ms, across a run); every pulse inside a burst is unchanged. | Yes: bursts may be 320,000 to 960,000 cycles apart (TASK.md lines 76-78) |

None breaks a rule of its task sheet, so, as in round 1, no gap in a judge was found.
