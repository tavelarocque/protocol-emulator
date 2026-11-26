# Notes: ST7789V 4-line serial host on the protocol emulator

## What I read
- TASK.md, in full (one read, 155 lines).
- isa.md, in full, in four parts (lines 1-180, 180-360, 360-540, 540-699).
- `./pe_sim run st7789.s -help` (the flag list).
Nothing outside the task folder was opened, listed or searched.

## Design
Pin roles:
- P0 SDA: `out pins, 1` (out_base 0, out_count 1), OSR shifted MSB first (out_msb_first 1).
- P1 SCL: side-set, 1 bit (sideset_base 1, sideset_count 1). Every instruction says `side 0` except the one that makes the rising edge.
- P2 D/CX and P3 CSX: `set pins` with set_base 2, set_count 2 (value bit 0 = D/CX, bit 1 = CSX).

Word handling: threshold 16 and MSB-first out, so a pulled word gives bits 15..0 in order. `out null, 6` drops bits 15..10, `out y, 1` keeps bit 9 (last byte) in Y, `out null, 1` drops bit 8. The command flag is not needed by the firmware: the first word of every transfer is the command, all others are data, so D/CX is set low when a transfer starts and high for each following byte. The 8 data bits are then sent by a two-instruction loop that runs until the OSR is empty (`jmp !osre`), which needs no counter.

Bit timing (4 cycles = 80 ns per bit, the minimum since TSCYCW is 66 ns and 3 cycles would be 60 ns):
- `out pins, 1 side 0 [1]`: SDA changes with SCL low, held 2 cycles before the rise (TSDS 40 ns).
- `jmp !osre bit side 1 [1]`: SCL high 2 cycles (TSHW 40 ns). SDA next changes at the falling edge, 40 ns after the rise (TSDH 40 ns). TSLW 40 ns.

Framing:
- Cycle 0 drives SCL low and CSX, D/CX high (shows at cycle 1; the reset value of the output register has SCL high at cycle 0, which is harmless because CSX is high). CSX first falls at cycle 3, 40 ns after SCL went low.
- After the 8th rising edge, the next instruction (`jmp !y data side 0`) brings SCL low. For a data byte to follow, `pull` then `set pins, 1` (CSX low, D/CX high), so D/CX changes at least 40 ns after the falling edge (TDCH). For the last byte, `jmp idle`, then `set pins, 3` raises CSX 20 ns after SCL fell (TCSH) and D/CX goes high at the same moment, 20 ns after the falling edge (TDCH).
- CSX high between transfers: `set pins, 3` (rise), `pull`, `set pins, 0` (fall): 3 cycles = 60 ns >= 40 ns (TCHW), more if the FIFO is empty.
- TCSS: CSX falls, then `jmp byte`, three `out` instructions and one more `out` before the first rise: well over 15 ns.
- An empty TX FIFO mid-transfer stalls `pull` with CSX low and SCL low (side 0 applies while stalled), which the sheet allows as a pause between bytes.

Cost: 38 cycles per data byte, 39 per command byte, about 2 cycles more per transfer; the budget is 100 per byte plus 2000.

Program (13 instructions):
```
        .side_set 1
idle:   set pins, 3        side 0
        pull               side 0
        set pins, 0        side 0
        jmp byte           side 0
data:   pull               side 0
        set pins, 1        side 0
byte:   out null, 6        side 0
        out y, 1           side 0
        out null, 1        side 0
bit:    out pins, 1        side 0 [1]
        jmp !osre bit      side 1 [1]
        jmp !y data        side 0
        jmp idle           side 0
```
run_args.txt:
`-config out_base=0,out_count=1,set_base=2,set_count=2,sideset_base=1,sideset_count=1,threshold=16,out_msb_first=1 -mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp`

## Test method
I wrote a small Python checker (in this folder, deleted before hand-in along with the test word files and logs) that reads the `pins` lines, decodes every CSX low pulse as a transfer (bit taken at each SCL rise, byte and D/CX taken at the falling edge after the 8th rise), compares the transfers with the words, and checks every timing limit in the TASK.md table, SCL low at every CSX edge, no partial byte, and CSX high at the end. I checked the checker itself by hand-editing a log (moving an SDA level, deleting the final CSX rise): it reported the faults. I also wrote a generator of random runs (0 to 1000 data bytes per transfer, random byte values). Each test used `-cycles` = 100 x words + 2000, as the test does.

## pe_sim runs (13 in total)
1. `pe_sim asm st7789.s`: assembled to 13 words; checked the side and delay bits of `jmp !osre bit side 1 [1]` (0x1389) and `out pins, 1 side 0 [1]` (0x6201) by hand.
2. `pe_sim run st7789.s -help`: flag list, config field names match isa.md.
3. TASK.md example (0x012A, 0x0000 x3, 0x02EF, 0x0329), first 60 lines read by eye: SCL low at cycle 1, CSX and D/CX low at 3, first byte 0x2A bit by bit with 4-cycle bits, D/CX high 2 cycles after the 8th falling edge.
4. Same example through the checker, 2600 cycles: 2 transfers, 0 errors, last change at cycle 235.
5-9. Five random runs (seeds 1-5, 12 transfers each, 28 to 1773 words): all transfers decoded correctly, 0 errors; for example 1773 words finished at cycle 67411 of a 179300 budget.
10. One command with no data, 0x0300 (all-zero byte, SDA never toggles in it): correct, CSX high again at cycle 42.
11. One command 0x03FF: correct.
12. 40 commands with no data in a row: 40 transfers, 0 errors (checks TCHW on back-to-back transfers).
13. Two transfers with 1000 data bytes each, all 0xFF then all 0x00: 2002 bytes, 0 errors, done at cycle 76083 of 202200.

No mistakes were found in the program during testing; the first version passed every run.

## Program length
13 instructions (13 words, addresses 0 to 12, all in page 0).

## Confusing or possibly wrong in isa.md
- Nothing I found was wrong. The points I had to read twice:
- The output register resets to all ones, so with `-mode 1=pp` SCL is high at cycle 0 before the firmware runs. isa.md does say this (and suggests enabling the thread before making the pin push-pull), but pe_sim applies the modes from cycle 0, so the firmware cannot avoid one cycle of SCL high; it only matters that SCL is low before CSX first falls.
- The pin print rule ("a write made by the instruction that runs in cycle c shows as pins c+1") is essential for counting TASK.md's nanoseconds and is stated only in the pe_sim section, not in "Cycle semantics".
- isa.md mentions a one-cycle hold after a program write; pe_sim's `run` does not show it (the first instruction's write appears at cycle 1), which is consistent with the run starting after the load, but isa.md does not say how `pe_sim run` models loading.
- The bit sampler section mixes 40 MHz and 50 MHz examples; irrelevant here.
- With `.side_set 1` the delay field is 0 to 7; the assembler syntax section says so, but the side-set section only says "the low 4 - n bits are delay".

## Rule breaks
None that I know of.
