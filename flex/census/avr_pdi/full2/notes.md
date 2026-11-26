# Notes: AVR PDI programmer firmware

## What I read
- TASK.md, in full (190 lines), in one read.
- isa.md, in full (644 lines), in three parts (1-220, 220-439, 440-644).
- Nothing outside this folder.

## pe_sim runs
1. `./pe_sim run x.s -help`: printed the run flags (config keys, -cycles, -inputs, -mode, -stimulus, -tx).
2. `./pe_sim` with no subcommand (same command line as run 1): printed the subcommand list (asm, run, version, help).
3. Phase test `t1.s` (nop side 0 / nop side 1 [1] / jmp side 1, clkdiv=5): pins changes at cycles 1, 6, 21, 26, 41, 46. So the thread is enabled at cycle 0, its ticks fall on cycles 0, 5, 10, ..., and a write in tick cycle c shows at c+1.
4. `./pe_sim asm avr_pdi.s` (first version): assembled to 58 words.
5. TASK.md example (0x0180, 0x00C1, 0x0059, 0x8000, answer 0x02) through my harness `check.py`: PASS. 210 slots, 420 PDI_CLK edges each 1 cycle after its ideal place, P1 levels right at every rising edge, P1 changes only inside the chip's windows, RX = [0x02]. The stimulus my harness generated has the same cycles as TASK.md (9805 fd, 9905 ff, 9955 fd, 10255 ff).
6-17. Twelve sessions through `check.py`, one pe_sim run each, all PASS (P0 edge count right, every edge exactly +1 cycle from ideal, P1 levels right at every rising edge, P1 changes only inside chip windows, no pin change after the last rising edge, RX words equal to the answers):
   - `end_only`: just the end word (32 slots: 16 enable + 16 end).
   - `ld15_last`: one LD answered with 15 bytes (0xFF/0x00 alternating, 0x55) as the last instruction, so 18 idle slots after it.
   - `ans_ans`: three answered instructions in a row (answers of 1, 3, 1 bytes).
   - `zeros`: bytes 0x00 (word 0x0000 must not be taken for the end word), answer 0x00.
   - `ffs`: bytes 0xFF, a 15-byte answer of 0xFF.
   - `r0`..`r6`: random sessions of 10, 25, 40, 55, 70, 70, 70 bytes built from LDS, STS, LDCS, STCS, KEY, REPEAT, LD, ST shapes with random answers of 1 to 15 bytes (up to 2462 slots, 72 words, 39 answer bytes).
   I also looked at one saved output by hand: RX lines print in decimal (`rx 10250 0`), P1 shows only the chip's own output bit (the ATxmega's pulls do not appear in the `pins` lines), and the last line is the final rising edge.

Total pe_sim runs: 17 (2 of them help text, 1 assemble, 1 phase test, 13 sessions).

## Test harness (deleted before hand-in)
`check.py` (Python) built a session from a list of instructions, wrote the TX words and a stimulus file (P1 low from 5 cycles after each ideal falling edge of the ATxmega's 0 bits, high otherwise, 0xFF/0xFD), ran `pe_sim run avr_pdi.s -tx ... -stimulus ... -cycles N <run_args.txt>` with N = 3000 cycles after the falling edge that would follow the last slot, and compared the printed pins and rx lines with the ideal waveform derived from TASK.md. I removed it, its generated files and `t1.s` so the folder holds only what TASK.md asks for. It shares my own reading of TASK.md, so it cannot catch a misreading of the spec.

## Design
- `run_args.txt`: `-config clkdiv=5,sideset_base=0,sideset_count=1,out_base=1,out_count=1,set_base=1,set_count=1,in_base=1,threshold=8 -mode 0=pp -mode 1=od`.
- Clock divider 5: one tick is 5 cycles, one PDI slot is 10 ticks, half a slot 5 ticks. Ticks fall on cycles 0, 5, 10, ... and a write shows one cycle later, so every PDI_CLK edge is at its ideal cycle + 1 (within the +-2 allowed, and it never adds up). I chose this over clkdiv 1 because with side-set the delay field holds only 0 to 7, and at clkdiv 1 a half slot of 25 cycles would need at least 4 instructions; at clkdiv 5 each half slot fits in 1 to 5 instructions and the program fits in one 64-word page. The cost is the constant +1 cycle offset.
- P0 (PDI_CLK) is driven by side-set on every instruction: tick 0 of each slot has `side 0` (falling edge), tick 5 has `side 1` (rising edge). Every path through every slot was counted to exactly 10 ticks.
- P1 (PDI_DATA) is written only at tick 0 of a slot the chip sends (shows at ideal edge + 1, well inside the window that closes 5 cycles before the rise): `set pins, 0` for the start bit, `mov pins, x` for data bits, `mov pins, y` for parity, `set pins, 1` for the first stop bit. Nothing writes P1 anywhere else, so it never changes in idle, guard or ATxmega slots.
- Start: Y loops wait until tick 400 (cycle 2000). Slots 0 to 14 are an idle loop; slot 15 is the dispatch slot D.
- D (a generic idle slot, always the slot just before the chip's next frame): `pull`, copy the word to X, `out null,15` / `out y,1` puts bit 15 in Y, `mov osr, x` restores the word with its shift count reset. Y = 0: frame follows. Y = 1 (end word 0x8000): 16 idle slots, then `jmp halt` with P0 high and P1 released.
- Frame: data bits leave the OSR LSB first with `out x, 1`; the OSR shift count with threshold 8 and `jmp !osre` ends the 8-bit loop. Parity without XOR: Y starts at 0 and `jmp y--` runs once per 1 bit, so bit 0 of Y is the parity of the byte, written with `mov pins, y`. Both branches of the 1/0 test take the same ticks.
- First stop bit: after 8 `out`s the OSR holds word >> 8, so `mov x, osr` gives the answer length (bits 15..12 are 0). Zero: jump into the idle loop with X = Y = 0 so the second stop bit becomes D. Nonzero: X = 3, Y = 31, the second stop bit is idle, then a nested guard loop of 4 x 32 = 128 idle slots. The answer length stays in the OSR through the guard.
- Answer: the first answer start bit slot reads X = n from the OSR and decrements it. Per byte: 8 slots each sampling P1 with `in pins, 1` at the rising-edge tick (25 cycles after the ideal fall, 20 after the ATxmega changes the line), `jmp !isrf` (threshold 8) ends the byte, `push` at the parity slot, then 4 idle slots counted in Y (parity, stop, stop, next start bit). After the last byte the 4th idle slot is the first of the 2 idle slots, and the second is D, which the same loop falls into when X = 0. So the 2 idle slots after an answer are never folded into the 16 end slots.

## Mistakes found
None showed up in testing: the first assembled version passed the TASK.md example and all 12 sessions. The cycle budgets were worked out on paper per slot before writing.

## Program length
58 instructions (58 words from `pe_sim asm`), all in page 0, no `set page`.

## Confusing or possibly wrong in isa.md
- `in` is described as shifting bits "right into the ISR", while `push` sends the bits "right-justified". Where the bits sit inside the ISR before a push is not stated. I relied only on `push` giving the first bit in bit 0, which the runs confirmed.
- `out` without autopull: "it gives what is left of the 16-bit word, then zeros". I read this as the OSR shifting right with zero fill, so `mov x, osr` after 8 `out`s gives word >> 8. The answer lengths came out right, which confirms it, but isa.md does not say outright what `mov x, osr` reads part way through a word.
- The `pins CYCLE XX` lines: isa.md says they show the pins' output with "the levels being those at the start of that cycle". For an open-drain pin they show the output register bit, not the line level: the ATxmega pulling P1 low never appears. Worth saying explicitly.
- With `clkdiv` above 1, every write appears one cycle after a tick, so edges can only land on (tick cycle + 1). Not wrong, but it means a clock divider of 5 can never put an edge on a multiple of 5; isa.md could say so next to `clkdiv`.
- `mov osr, x` "resets that register's shift count": I took this to mean the OSR counts as full again (count 0), which the `!osre` loop confirmed.

## Rules
I read and wrote only inside the folder, used no web, and did not look for the `model/`, `hw/` or `docs/` files isa.md mentions. No rule broken that I know of. I used 17 of the allowed ~80 pe_sim runs.
