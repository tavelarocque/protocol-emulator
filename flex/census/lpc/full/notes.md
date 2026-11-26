# Notes: LPC host firmware

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `pe_sim run x.s -help` (the flag list).
- Nothing outside this folder. One slip to report: my very first shell command
  did `ls`, `cat TASK.md` and `cat isa.md` together, and the tool saved the long
  output to a file outside the folder and showed me only a 2 KB preview. I did
  not open that file; I re-read both documents with the file reader from this
  folder instead. No other path outside the folder was touched.

## Design

The key choice is `clkdiv=10`: one thread tick is 10 cycles, half an LCLK
period. Every instruction then takes exactly one tick and side-sets LCLK, so the
program is a strict alternation of an "L" tick (LCLK low, the only place LAD or
LFRAME# change) and an "H" tick (LCLK high, the rising edge, nothing else
changes). The L tick of clock k executes at cycle 90 + 20k and shows at
91 + 20k; the H tick executes at 100 + 20k and the rising edge shows at
101 + 20k, one cycle late, inside the +-2 limit and never accumulating. Data
changes are always 10 cycles from an edge, so setup and hold are met with room.
No `[delay]` is used anywhere (a delay tick does not side-set, and the clock
has to toggle every tick anyway).

Side-set is 2 bits from P4: bit 0 is LFRAME#, bit 1 is LCLK. So `side 1` is
idle low phase, `side 3` idle high phase, `side 0` and `side 2` are the two
halves of START with LFRAME# low. LFRAME# goes low at the falling edge before
START's rising edge and back high at the next falling edge: low for exactly 20
cycles, sampled low only at the START edge.

LAD: `set pins` (set_base 0, set_count 4) writes START 0000, CYCTYPE 0100 and
the TAR 1111; `out pins, 4` (out_base 0, out_count 4) writes address nibbles.
The OSR runs msb first with threshold 16 and autopull, so every host word
streams through the OSR: `out x, 16` takes the type word and autopull loads the
address word in the same tick; the 4th address nibble of a memory read
autopulls the low address word; the last nibble of every read autopulls the
next read's type word. One explicit `pull` in the preamble (tick 8, well after
the host has filled the FIFO) primes it so no `out` ever finds the OSR empty
during a run. After the last read, `out x, 16` finds the OSR and FIFO empty and
stalls forever with LCLK low; that happens in the clock before the next START
place, after the last read's last clock, which TASK.md allows.

Read schedule (c = clocks from START, t = first TAR clock):

- c0: START (`set pins, 0 side 0`, then `set y, 7 or 3 side 2`).
- c1: CYCTYPE. Memory writes `set pins, 4`; I/O leaves LAD at 0000 and uses the
  L tick for `set x, 10`. The H tick sets X (memory, X=6) or jumps to the
  shared address loop (I/O).
- Address loop: `out pins, 4 side 1` / `jmp y-- addr side 3`, Y+1 nibbles.
- Shared tail from t: `set pins, 15` (TAR 1111), a 2-clock wait loop (t+1, t+2),
  `in pins, 4` on the H ticks of t+3 and t+4 (the peripheral's nibble is valid
  in the thread's synchronised view from cycle 86 to 106 of that clock's
  window, the H tick samples at 100), `push` at t+5 L, `jmp pad` at t+5 H.
- Idle: `pad` loop of X+1 clocks, then `out x, 16` (next type) and `jmp !x io`
  on the last H tick before the next START. X is 6 after a memory read and 10
  after an I/O read, which makes both kinds exactly 24 clocks (48 ticks).
- Preamble: ticks 0 to 9 LCLK low (falls at cycle 1, 100 cycles low), `pull`,
  `set x, 1`, `jmp pad` on rising edge 0, so the first START lands on clock 4.

`in pins, 4` twice with the default right shift leaves high:low in ISR bits
15..8; `push` sends the 8 bits right-justified, so the word is the byte with
bits 15..8 zero.

Registers: X = type, then idle count. Y = loop counters. ISR = data byte.

## pe_sim runs

1. `pe_sim run x.s -help`: flag list (config field names, `-inputs`, etc).
2. `pe_sim asm lpc.s`: 29 words, assembled clean.
3. `run` with the TASK.md example (I/O read 0x0080, answer 0x5A): every edge at
   101 + 20k, START 0000 with LFRAME# low at clock 4, CYCTYPE 0000, address
   0,0,8,0, TAR, and `rx 390 90`. I first read 90 as hex and thought the byte
   was wrong.
4. `run ... -inputs c3`: crashed, `Int.of_string "c3"`. `-inputs` needs `0x`.
5. `run ... -inputs 0xc3`: `rx 390 51`. 51 is 0x33, which is exactly right for
   a constant nibble 3, so the `rx` line prints the word in decimal while the
   `pins` lines print hex. Run 3 was correct after all (90 = 0x5A).
6. to 10. My checker `check.py` (see below), runs for 1 I/O, 1 memory, 8 memory,
   8 I/O, 8 mixed: all failed on one rule, "LFRAME low at 182". That was my
   checker being too strict: it allowed LFRAME# low only up to the START edge,
   but the firmware (like a real LPC host, which changes after the edge) keeps
   it low until the falling edge 10 cycles after START's rising edge. It is low
   for exactly one clock (20 cycles) and high at every other rising edge, which
   is what TASK.md asks. Everything else passed. I relaxed the checker to allow
   the pulse to run until just before the setup window of the next edge.
11. to 15. Same five runs: all OK.
16. Negative test of the checker: `clkdiv=11` in a temporary copy of the args.
    The checker reported every edge drifting (111, 133, 155...), so it does
    catch timing faults. Args restored.
17. to 36. Twenty random runs, seeds 100 to 119, 1 to 8 reads each, random
    types, addresses (including 0 and all ones) and bytes (including 0x00 and
    0xFF): all OK.

Total: 36 runs of pe_sim.

The checker (written from TASK.md only, since deleted so the folder holds just
the hand-in) generated the TX words and the stimulus file exactly as the task
describes, ran `pe_sim run lpc.s -tx -stimulus -cycles N` plus `run_args.txt`
with N = 100 + 20(4 + 24R), and checked: every rising edge within +-2 of
100 + 20k and none else; high and low phases at least 6 cycles; a fall at least
6 cycles before edge 0; LCLK running through edge L; no change of P0 to P4 at
E-1 or E; the decoded (LFRAME#, LAD) at E-1 of every clock 0..L, with LAD the
AND of the chip's outputs and the peripheral's levels, against the expected
fields and idle; LFRAME# never low outside a START pulse; the chip's LAD
outputs all 1 outside (edge s-1, edge t - 2]; and the RX words equal to the
bytes, one per read, in order.

## Mistakes found

- Reading `rx` values as hex (runs 3 to 5). Not a firmware bug.
- `-inputs` without `0x` (run 4).
- Checker's LFRAME# window too narrow (runs 6 to 10). Not a firmware bug.

No firmware change was needed after the first version.

## Hand-in

- `lpc.s`: the program.
- `run_args.txt`: `-config clkdiv=10,out_base=0,out_count=4,set_base=0,set_count=4,in_base=0,threshold=16,sideset_base=4,sideset_count=2,out_msb_first=1,autopull=1`
  and the six `-mode` flags of the pin table.

## Program length

29 instructions (`pe_sim asm` prints 29 words), all in page 0.

## Confusing or possibly wrong in isa.md

- `pe_sim run` prints `rx CYCLE WORD` with the word in decimal, while `pins`
  is hex. isa.md does not say which base either uses; I lost two runs to it.
- `-inputs HEX` says HEX but rejects a bare hex number; it needs `0x`. The
  stimulus file, also described as `CYCLE HEX`, does accept bare hex (`f0`).
- `in` "shifts count bits right into the ISR" does not say where the new bits
  enter or how `push` right-justifies them; I had to rely on PIO knowledge
  (new bits at the top, push gives the last `count` bits right-justified),
  which the simulator confirmed.
- The side-set bit order is only implied by the general rule that bit k of a
  multi-pin write goes to pin base + k; an explicit sentence for `side V`
  would help.
- The `pins` lines show only the chip's output register, not the line levels
  with the peripheral's pull-downs; that is consistent with "pins' output" but
  easy to misread.
- "After a write to a stopped thread's memory, that thread is held in its
  initial state for one more cycle": the simulator does not show this delay
  (the first instruction runs in cycle 0), presumably because `pe_sim run` does
  not model the load. Worth saying, since a program timed to the cycle depends
  on it.
