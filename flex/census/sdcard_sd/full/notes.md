# Notes: SD card bus (SD mode) host firmware

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- The help text of `pe_sim run -help` and of `pe_sim` with no subcommand.

Nothing outside this folder was opened, listed or searched. I wrote a Python
test harness and some generated test files in this folder while working (see
below) and deleted them at the end, so the folder holds only the given files
plus the three hand-in files. Python itself was used as a tool to run the
harness; no other file on the machine was read for information.

## Design

Configuration (`run_args.txt`): `clkdiv=10`, one side-set pin (P0 = CLK),
`out_base=1`, `set_base=1`, `in_base=1` (P1 = CMD), `threshold=16`, both
shift directions MSB first, `autopush=1`, `crc_poly=0x48`, `crc_init=0x48`,
`timeout=0`, `timeout_vector=7`, `-mode 0=pp -mode 1=od`.

With `clkdiv=10` one thread tick is 10 cycles and one CLK period is exactly
4 ticks, so the clock is locked to the tick grid and an error can never add
up. In every clock the ticks are F (side 0, CLK falls), M (side 0, the only
tick where CMD is written), R (side 1, CLK rises, CMD is sampled here) and H
(side 1). Rising edge n has F at tick 18+4n. A write in tick t shows at cycle
10t+1, so every CLK edge is 1 cycle late (181, 201, ...), CMD changes at
191+40n (CLK low at the cycle before and the cycle itself), and samples at
tick 20+4n see CMD as it was at cycle 198+40n, in the middle of the card's
bit (it drives from 182+40n to 222+40n, seen 2 cycles later).

Every instruction carries a side-set value, so the clock costs nothing; the
program is a chain of 4-tick clocks in which each tick has exactly one
instruction or a delay tick.

Flow:

1. Reset: 17 ticks with CLK high build X = 79 in the ISR (`set x,19`,
   `in x,5`, `in x,2`, `mov x,isr`) and fall into the idle-clock loop, which
   runs 80 clocks (edges 0 to 79).
2. Idle-clock loop (`gH`, `gF`, `gR`): one clock per X+1. It ends with
   `pull` in the H tick of the last idle clock, so when the commands run out
   the thread stalls there with CLK high, after exactly 8 rising edges past
   the last end bit, and never restarts.
3. Command: `out y,8` gives Y = response type, `set pins,0` is the start bit,
   `out null,2`, `mov crc,null` restarts the CRC register, `set pins,1` is
   the transmission bit. The CRC register starts at 0x48, which is the state
   after feeding "0 1" from 0, so it only has to see the 38 index and argument
   bits, which `out pins,1` feeds it. The bit loop pulls word 2 and word 3
   when `!osre` says the OSR is empty (X counts the two refills), with equal
   timing on both paths.
4. CRC7: the register is a right-shifting (reflected) CRC, so after the 38
   bits its bit 0 is the CRC's most significant bit. `mov isr,crc` keeps the
   value; CRC bit 6 goes out with `mov pins,isr`, and each further bit i with
   `mov osr,isr`, `out null,15-i`, `out pins,1` (unrolled; there is no
   instruction that shifts right or reverses bits).
5. End bit with `set pins,1`, then `jmp y-- srch`: type 0 falls through to 8
   idle clocks; types 1 and 2 jump to the search with Y = type - 1.
6. Search: one clock per try, `wait 0 pin 1 timeout` with `timeout=0` at the
   R tick acts as "branch if CMD is high" to `vec`, which loops. It starts
   at edge e+1 (CMD is guaranteed high there), so it finds the first low
   edge from e+2 on.
7. Receive, with autopush at 16 bits, in a nested loop (`wnext`/`bR`): the
   inner count is reloaded from the OSR, the outer count is Y.
   - R1: before the search the ISR count is set to 9 (`in null,9`), so the
     7 bits after the start bit (transmission bit 0 and the 6 index bits)
     complete a 16-bit word whose value is the index, then the next 32 bits
     give the two content words. 10 groups of 5 = 50 bits are sampled; the
     last 11 sit in the ISR and are never pushed.
   - R2: the ISR is cleared, the 7 header clocks are skipped without
     sampling, then 16 groups of 8 = 128 bits give 8 words.
   - After the loop, `mov x,osr` reuses the inner count as the number of
     idle clocks still needed (R1: 5, R2: 8), which lands the `pull` on the
     H tick of edge r+8 and the next start bit on edge r+9 in both cases.

## Program length

64 instructions (exactly one page, so no `set page` is needed).

## pe_sim runs (26 in total)

1. `pe_sim run x.s -help`: help text for `run`.
2. `pe_sim` with no subcommand: list of subcommands.
3. Small test program: clkdiv=10, side-set toggling, `wait 0 pin 1 timeout`
   with timeout 0 and a stimulus pulling P1 low at cycle 200. Showed: ticks
   at cycles 0, 10, 20, ...; a write shows at the next cycle (pins 1, 11,
   21, ...); a timed-out wait with timeout 0 takes one tick and the vector
   runs in the next tick; `wait ... pin 1` watches P1 itself (absolute pin
   number), not in_base+1; the low level at cycle 200 was seen by the wait in
   tick 220 (tick 210 was the vector).
4. `pe_sim asm sdcard_sd.s | wc -l`: 64 words.
5. `pe_sim asm sdcard_sd.s | head`: checked the first words; `vec` is at
   address 7 (timeout_vector).
6. TASK.md's example (CMD0, then CMD8 0x1AA with d = 5) through my harness:
   all checks passed, RX words 0x0008, 0x0000, 0x01AA, edges all +1 cycle.
7. Same example for 100 cycles, to see the raw output format.
8. to 13. Six runs (seed 1): 10 random commands with random d; 10 commands
   with d = 2; 10 with d = 64; a single R2 command; a single no-response
   command; 10 R2 commands. All passed.
14. Rerun of run 8's case saving the output, then I injected faults into that
   saved output (moved a CMD change into a CLK high cycle, dropped an RX
   word, moved a CLK edge by 3 cycles, cut the clock short) and confirmed the
   harness flagged each one (no extra pe_sim runs for those).
15. to 20. Six runs (seed 7): four random runs of 1 to 10 commands; a run of
   bit patterns (arguments and contents 0, 0xFFFFFFFF, 0xAAAAAAAA,
   0x55555555, 0x80000001, an all-ones and an all-zeros R2 register, CMD63,
   an ACMD41-style response with index 111111, d at 2, 3, 7, 63, 64); 10
   no-response commands. All passed.
21. to 26. Six more runs like 8 to 13 with seed 3. All passed.

The harness (Python, in this folder, deleted at the end) built the TX file
and a card stimulus from the schedule in TASK.md (card bit n driven from
cycle 182+40n), computed CRC7 (it reproduces the three examples in TASK.md),
ran pe_sim with `run_args.txt`, and checked: every CLK edge at 180+40k and
200+40k within 2 cycles, no other CLK change, clock running through 8 rising
edges after the last end bit; every CMD output change has CLK low in that
cycle and the one before, at most one per low half, and only where the bit
changes; the line (chip output AND card) at every rising edge equals the
expected commands and responses and 1 elsewhere; the chip never pulls CMD
low while the card drives; P2 to P7 outputs never change; RX words equal the
expected ones.

## Mistakes found

None of the hand-in versions failed a test; the first full program passed
the first run. During the design (before any run) I caught several
placement problems on paper: two different paths both needing to fall
straight into the same instruction (solved with a `jmp` with delay as one of
the entries), a `pull` placed where a stall would stop the clock before the
8th rising edge, and an `autopull` design that would have pulled the next
command's first word into the OSR that the CRC code needed, which is why the
bit loop pulls explicitly with `!osre`.

## Confusing or possibly wrong in isa.md

- `wait pol pin n` does not say whether n is an absolute pin number or
  relative to `in_base` (in PIO, `wait pin` is relative). The test (run 3)
  showed it is absolute, while `in pins` is relative to `in_base`.
- The CRC register only shifts right, so it ends with the CRC's most
  significant bit in bit 0, while `out_msb_first` takes bits from bit 15.
  Sending CRC7 most significant bit first, as SD needs, takes a bit
  reversal, and the ISA has no right shift and no reverse, so it costs 3
  instructions per CRC bit. Not wrong, but costly; isa.md's CRC section
  does not mention this case.
- "With T = 0, at once": it was not clear whether the timed-out wait itself
  uses a tick before the jump. It does: the wait takes one tick and the
  vector instruction runs in the next.
- There is no `jmp pin` condition; the wait with timeout 0 serves as one,
  but only to the single `timeout_vector`.
- The `-config` field names and value syntax (hex accepted for `crc_poly`)
  are only listed, not described, in the `pe_sim` help; they worked as the
  per-thread configuration table names them.

## Rule breaks

None that I know of. No em-dashes were used in the files I wrote.
