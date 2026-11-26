# Notes: LPC host firmware

## What I read

- `TASK.md`, in full, in two parts (lines 1-110, 110-220).
- `isa.md`, in full, in four parts (lines 1-160, 160-330, 330-490, 490-644).
- `pe_sim run -help` (run 1).
- Nothing outside this folder.

## Design

Everything rests on `clkdiv=10`: one thread tick is 10 core cycles, half an
LCLK period, and every instruction is exactly one tick (no delays are used
once the clock runs, because a delay would hold LCLK still). LCLK is P5 and is
driven by a 1-bit side-set on every instruction, so the program alternates
strictly between "A" instructions (`side 0`, the falling half) and "B"
instructions (`side 1`, the rising edge). Every path through the program keeps
that alternation, including both branch paths and every loop.

The thread starts at cycle 0, so ticks fall on cycles 0, 10, 20, ... A B
instruction runs at cycle 100+20k and its LCLK write shows at cycle 101+20k
(one cycle late, inside the +-2 limit; the error never adds up because the
divider is exact). A instructions run at 90+20k and their writes show at
91+20k. Only A instructions change LAD or LFRAME#, so every LAD/LFRAME# change
is 10 cycles away from a rising edge, well clear of the setup/hold rule.

Pins: `set pins` covers P0..P4 (`set_base=0, set_count=5`) for the constant
fields (START = 0x00 makes LFRAME# low and LAD 0000; CYCTYPE 0x10 or 0x14;
0x1F for TAR and release). `out pins, 4` (`out_base=0, out_count=4`,
`out_msb_first=1`) sends address nibbles most significant first. `in pins, 4`
(`in_base=0`, default right shift) takes the data nibbles; low nibble first,
then high, so after two INs a push gives `hi<<4 | lo` right-justified, which
is exactly the byte with bits 15..8 zero.

Host words: `autopull=1, threshold=16`. A `pull` in the preamble fills the OSR
with the first word; after that every OUT that empties the OSR refills it in
the same tick, so the OSR always already holds the next word: `out x, 16`
takes the type word and leaves the address word ready, and a memory read's 8
nibbles run straight across its two address words. When the words run out,
the OSR stays empty and the next `out x, 16` (a B instruction, at the rising
edge two clocks before the START that never comes) stalls for good. It keeps
applying `side 1`, so LCLK rises once on its proper place and then stays high:
no extra edge, and this is long after the last read's last clock.

Per read (S = START clock, t = first TAR clock):

| Clock | A (falling) | B (rising) |
|---|---|---|
| S-2 | nop | `out x,16` (type) |
| S-1 | `jmp !x io` | `set x,7` (mem) / `set x,3` (I/O) |
| S | `set pins 0x00` START | `set y,4` (mem) / `set y,8` (I/O) |
| S+1 | `set pins 0x14` / `0x10` | nop / `jmp addr` |
| S+2.. | `out pins,4` | `jmp x-- addr` (8 or 4 nibbles) |
| t | `set pins 0x1f` | `set x,1` |
| t+1, t+2 | nop | `jmp x--` (2 clocks) |
| t+3 | nop | `in pins,4` (low nibble) |
| t+4 | nop | `in pins,4` (high nibble) |
| t+5 | push | nop |
| t+6 | nop | `jmp pad` |
| idle | nop | `jmp y-- pad` (y+1 clocks) |

Idle after the read is 9 clocks for I/O and 5 for memory, so every read is
exactly 24 clocks and read n+1's START lands on clock 4+24(n+1). The preamble
(`set y,1 [3]`, `pull [4]`) takes ticks 0-8, drops LCLK at cycle 1 and enters
the idle loop at tick 9 (the falling half of clock 0) with y=1, which gives
clocks 0 and 1 idle, clock 2 the prefix, clock 4 the first START.

Sampling: the `in` of clock k runs at cycle 100+20k and sees the level that
arrived at cycle 98+20k (two-flop synchroniser). The peripheral drives clock
k's value from 84+20k to 104+20k, so the sample is 14 cycles after the value
appears and 6 before it goes.

## pe_sim runs

1. `pe_sim run x.s -help`: the flag list (config keys, -mode, -stimulus, -tx, -cycles, -inputs).
2. `pe_sim asm lpc.s`: assembled, 31 words.
3. Run on the TASK.md example (I/O read of 0x0080, peripheral 0x5A), 580 cycles. Pins: LCLK falls at 1, rises at 101, 121, ...; START (c0) at 171, LFRAME# back high at 191, nibble 8 shows as d8 (LAD3 set, so bit order is right), TAR release at 291. Printed `rx 390 90`. I misread this as 0x90, a wrong byte.
4. Debug copy (`dbg.s`, two `in pins, 8` each pushed). Printed `rx 370 218`, `rx 390 213`, which I could not explain as hex.
5. Diagnostic program (`diag.s`) with `-inputs a6`: pe_sim failed with `Int.of_string "a6"`. `-inputs` needs the `0x` prefix.
6. Same with `-inputs 0xa6`: rx 182, 6, 102, 182. 182 decimal is 0xB6, the expected pin byte. So `rx` lines are printed in **decimal** while `pins` lines are hex. Run 3's "90" was 0x5A, correct, and run 4's 218/213 were 0xDA/0xD5, also correct. No program change needed.
7. Checker (see below), 1 I/O read: failed with "bad drive at cycle 181". The fault was in my checker (it required LFRAME# high again by the rising edge of START, while the right rule is that it must be high by the next rising edge); the program was right.
8. Checker, 1 memory read: same checker false alarm.
9. Checker fixed, 1 I/O read: OK.
10. 1 memory read: OK.
11-16. Six random 8-read runs (mixes, one all I/O): all OK, all bytes back in order, 195 edges, LCLK stops high on a proper edge.
17. 8 memory reads: OK.
18-22. Five random runs of 3, 3, 3, 5 and 7 reads: all OK.
23. `pe_sim asm lpc.s` again to count words: 31.

Before run 23 I also fed the checker run 22's saved output with a different
seed's expectations (no pe_sim run) to make sure it reports mismatches; it
did (wrong address nibbles flagged).

The checker (`check.py`, a Python script I wrote in this folder and deleted
before hand-in, along with the scratch `.s`, `.tx`, `.stim` files) built the
tx and stimulus files the way TASK.md describes, ran
`pe_sim run lpc.s -tx -stimulus -cycles N` with `run_args.txt`, and checked:
every rising edge within +-2 of 100+20k and none extra; at least L+1 edges;
high and low at least 6 cycles; no P0-P4 change at E-1 or E; the chip's
LFRAME#/LAD at every edge up to L against START/CYCTYPE/address/TAR/idle; the
bus (chip AND peripheral) at SYNC and DATA; LAD driven low and LFRAME# low
only in the allowed windows; and the rx words against the bytes.

## Mistakes

- Reading `rx` values as hex (runs 3-4); found with a constant-input diagnostic (runs 5-6).
- `-inputs a6` without `0x` (run 5).
- Checker window for LFRAME# too strict (runs 7-8).

No rule broken that I know of: I read and wrote only inside this folder.

## Hand-in

- `lpc.s`: **31 instructions**.
- `run_args.txt`: `-config clkdiv=10,out_base=0,out_count=4,set_base=0,set_count=5,in_base=0,threshold=16,sideset_base=5,sideset_count=1,out_msb_first=1,autopull=1` and the six `-mode` flags (0-3 od, 4-5 pp).
- pe_sim runs used: 23.

## Confusing or possibly wrong in isa.md

- It says `pe_sim` "prints `rx CYCLE WORD`" next to `pins CYCLE XX` and calls `-inputs` "HEX", but `rx` words come out in decimal while `pins` are hex, and `-inputs` rejects bare hex (needs `0x`). The `-stimulus` file does accept bare hex (`324 f0`). This cost me two runs.
- `pins` lines show the chip's output register, not the line level: a peripheral pulling an open-drain line low does not appear. That is what TASK.md's rules need, but isa.md's "the levels being those at the start of that cycle" reads as if it were pin levels.
- `in` "shifts `count` bits right into the ISR" and push gives the bits "right-justified": it was not obvious which end new bits land at; the result (first IN ends in the low bits after the push) matches PIO.
- Which OSR bit reaches P0 with `out_msb_first` (the lowest of the bits taken, bit 12 for a nibble) is not stated; I confirmed it from run 3.
- The `.side_set` delay range sentence says "0 to 7, 3 or 1"; with clkdiv the delay counts ticks, and side-set is not applied during delay ticks. Both are stated, but only in separate places.
