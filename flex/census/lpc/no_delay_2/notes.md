# Notes: LPC host firmware

## What I read

- `TASK.md`, all 220 lines, in two parts (lines 1 to 110, 110 to 220).
- `isa.md`, all 638 lines, in four parts (1 to 160, 160 to 330, 330 to 490, 490 to 638).
- `./pe_sim run x.s -help` (the flag list).
- Nothing outside this folder. I did not open `pe_sim` (the wrapper script) or `pe_sim.real`.

## Design

**Clocking.** `clkdiv=10`: the thread executes once every 10 core cycles, at cycles 0, 10, 20, and so on. One LCLK period (20 cycles) is then exactly two instructions. LCLK (P5) is a 1-bit side-set (`sideset_base=5, sideset_count=1`). Every instruction executed at cycle 100+20k ("slot 0") says `side 1`. Its write shows at cycle 101+20k, which is rising edge k, one cycle late and inside the +-2 limit. Every instruction at cycle 110+20k ("slot 1") says `side 0`, so LCLK falls at 111+20k. LCLK is high 10 cycles and low 10 cycles. Because the program strictly alternates side 1 and side 0, every jump has to land on an instruction of the opposite slot. I checked that by hand for every path and annotated each line of `lpc.s` with its clock and slot.

**Pins.** `set pins` covers P0..P4 (`set_base=0, set_count=5`), so one `set` writes LAD[3:0] and LFRAME# together: 0x00 is START, 0x10 and 0x14 are the I/O and memory CYCTYPE, and 0x1F is TAR or idle. `out pins, 4` (`out_base=0, out_count=4`) writes only LAD for the address nibbles. All LAD and LFRAME# changes happen in slot 1, so they show at 111+20k, 10 cycles away from any rising edge (setup/hold rule 4). START is written just after rising edge S-1, and LAD is released (`set pins 0x1f`) during the first TAR clock, before rising edge t.

**Host words.** I used autopull with `threshold=16` and `out_msb_first=1`, so the host's words stream through the OSR. `out y, 16` takes the type word, and the autopull in the same cycle loads the first address word. The address nibbles come out MSB first, and for a memory read the second address word is autopulled after the fourth nibble with no gap. One address loop (`al`) serves both read types: X=3 gives 4 nibbles and X=7 gives 8.

**Reading the byte.** `in pins, 4` (`in_base=0`) runs at the tick of rising edge t+3 and again at the tick of rising edge t+4. Each one reads the level from 2 cycles earlier (the synchroniser), which is 14 cycles after the peripheral set the nibble and 6 cycles before it changes. The ISR shifts right, so after the low nibble and then the high nibble, `push` gives 0x00HL.

**Schedule.** Every read takes exactly 24 LCLK periods = 48 ticks. After rising edge t+6 (the last clock, L), `jmp !y` uses the current read's type, still in Y. After an I/O read, a 4-period loop (`iox`/`il`) makes up for its shorter address. Both paths reach `join` at clock S'-6 of the next read. There, `out y, 16` takes the next type, a wait loop runs, and `jmp !y` at S'-1 picks the I/O or memory start sequence. After the last read, `out y, 16` at `join` finds the OSR and FIFO empty and stalls forever. It does so at a slot-0 tick, so LCLK makes one last rising edge on its place and then stays high. That is after edge L, which is allowed. LAD is released and LFRAME# is high.

**Prologue.** From cycle 0, ten ticks with `side 0`: LCLK falls at cycle 1, the first type word is fetched (the first `out` spends a tick fetching), and the program jumps into the wait loop so that the first `side 1` instruction runs at cycle 100 (edge 0 at 101). That puts START of read 0 at clock 4.

**Length:** 41 instructions (`pe_sim asm` prints 41 words), all in page 0.

`run_args.txt`: `-config start=0,out_base=0,out_count=4,set_base=0,set_count=5,in_base=0,threshold=16,sideset_base=5,sideset_count=1,clkdiv=10,out_msb_first=1,autopull=1` plus the required pin modes (0 to 3 od, 4 and 5 pp).

## Test harness

I wrote a Python checker, `work/check.py`, and deleted it at the end so that only the hand-in remains. For each run it generated the TX words and the peripheral stimulus exactly as TASK.md describes, called `pe_sim run lpc.s -tx -stimulus -cycles N` with `run_args.txt`, and checked:

- edge places (+-2) and the number of edges up to L;
- high and low widths of at least 6, including the initial fall;
- no P0..P4 change at E-1 or E;
- the bus value at E-1 for every clock of every read (chip output AND peripheral level);
- that LFRAME# is low exactly once per read, at the right clocks;
- that the chip pulls LAD low only inside its window and is 1111 at the end of the first TAR clock;
- that the RX words equal the bytes.

Each checker call is one pe_sim run.

## pe_sim runs

1. `run x.s -help`: the flag list.
2. `asm lpc.s`: assembled, 41 words.
3. `asm lpc.s | wc -l` (second asm call, to count words): 41.
4. Check: the TASK example (I/O read 0x0080, byte 0x5A). The waveform was right (edges at 101+20k, START at clock 4, address 0 0 8 0, TAR). It reported two failures, and both were checker bugs. First, it flagged the initial high period as too short (the rule has no minimum there). Second, `rx 390 90` looked like 0x90 instead of 0x5A.
5. Diagnostic: the same program with constant peripheral input 0xF3 gave `rx 390 51`, which still puzzled me.
6. Diagnostic with a small program `work/diag.s` (`in x,4` twice with X=3, then `in pins`): it failed because `-inputs f3` is rejected. `-inputs` needs a `0x` prefix (`Int.of_string` failure).
7. The same with `-inputs 0xf3`: `rx 51`, `rx 51`, `rx 243`. 243 = 0xF3 and 51 = 0x33, so **pe_sim prints rx words in decimal**. Run 4's `90` was 0x5A, which was correct all along. I fixed the checker to parse rx in decimal and to skip the initial high period.
8. Check, example I/O read: PASS.
9. Check, the TASK's two-read example (I/O 0x0080 -> 0x5A, memory 0xFFC01234 -> 0x07): PASS.
10. Check, 8 random reads (seed 3), mixed types: PASS.
11. Check, a single memory read: PASS.
12. Check, 8 memory reads with edge addresses and bytes (all ones, all zeros, alternating): PASS.
13. Check, 8 I/O reads with edge addresses and bytes: PASS.
14. Verbose view of run 9 to eyeball the memory read: START at 651, CYCTYPE 4, nibbles F F C 0 1 2 3 4, TAR at 851, rx 7 at 950, last edge at 1001, then LCLK held high. PASS.
15. Check, 8 random reads (seed 11): PASS.
16. Check, 5 random reads (seed 12): PASS.
17. Check, 3 random reads (seed 13): PASS.

Total: 17 pe_sim runs.

## Mistakes found

- My checker parsed `rx` as hex. It is decimal (runs 4 to 7). The firmware did not change.
- My checker wrongly applied the 6-cycle minimum to LCLK's initial high period.
- `-inputs f3` without `0x` is rejected (run 6).

No firmware bug was found. The program passed from its first version.

## Confusing or possibly wrong in isa.md

- isa.md says `pe_sim run` prints `rx CYCLE WORD` but does not say the word is in decimal, while `pins CYCLE XX` is hex. That cost me three runs.
- `-inputs HEX` (and "bit k of HEX" for the stimulus) suggests bare hex. `-inputs` actually needs `0x` (bare `f3` fails with `Int.of_string`). The stimulus file accepted bare hex such as `f0`.
- It is not stated directly whether `out pins, n` writes n pins or `out_count` pins. I set `out_count=4` so both readings agree.
- The ISR shift direction is described only briefly ("shifts count bits right into the ISR", "right-justified" on push). It behaved like PIO: the first nibble in ends up least significant after push.
- With `clkdiv`, an instruction can run only at cycles that are a multiple of `clkdiv` from enable, and a write shows one cycle later. So edges can never be exactly on 100+20k here; they are 1 cycle late, which is inside the +-2 limit. That is not wrong, just worth knowing.
- isa.md's note that side-set "is applied on cycles where it stalls" was useful: the final stall on `out y, 16` holds LCLK at its last level.

I broke no rule that I know of. All reads and writes stayed inside this folder.
