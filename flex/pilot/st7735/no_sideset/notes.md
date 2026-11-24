# Notes: ST7735 host firmware

## What I read
- `TASK.md` and `isa.md` in this directory, in full. Nothing else.
- `./pe_sim run st7735.s -help` (the help text only). I did not open `pe_sim` itself.
- Not read: anything outside this directory. No web.
- I also wrote and ran my own `check.py` here with the system `python3` (it reads only files in this
  directory). Running the Python interpreter is the one thing I used that is not in the folder.

## Design
Pins: `out pins` drives P0 (SDA) only (`out_base=0, out_count=1`, MSB first). `set pins` drives
P1..P3 (`set_base=1, set_count=3`), value bit0 = SCL, bit1 = D/CX, bit2 = CSX.

Because `set pins` writes SCL, D/CX and CSX together, the clock pulses must know the D/CX level.
So there are two bit loops: one for the command byte (D/CX low) and one for data bytes (D/CX high).
Bit 8 of the word (the command flag) is not needed: the first word after CSX rises is always the
command, and every later word up to the one with bit 9 set is data. Only bit 9 ("last") is used.

Word parsing (OSR shifts left, 16-bit threshold):
- command: `out y, 7` gives Y = bits 15..9 = last flag (0/1), `out null, 1` drops bit 8, then 8 bits to SDA.
- data: `out y, 8` gives Y = bits 15..8 = 0 or 2 (bit 8 is 0 on data), then 8 bits to SDA.
- Both ends go through `tail: jmp !y data`, which falls into `fin: set pins, 4` (CSX high, D/CX low, SCL low).

The program starts at `fin` (`start=8`), so the first instruction drives SCL low with CSX high, then
blocks in `pull`. After the last transfer it blocks in the same `pull` with CSX high and sends nothing.

Timing per bit (25 ns cycles): SDA changes, 1 cycle later SCL rises, stays high 2 cycles (50 ns),
low at least 3 cycles (75 ns). Period 5 cycles = 125 ns. About 45 cycles a byte, well inside 200.
- TCSS: CSX falls, first SCL rise 2 cycles later (50 ns).
- TCSH: last SCL fall to CSX rise is 3 cycles after a data byte, 4 after a lone command (75/100 ns).
- TCHW: CSX high at least 5 cycles (125 ns) between transfers.
- TSDS 25 ns, TSDH 100 ns.
- D/CX rises together with the first SCL rise of the first data byte (bit 1 of 8, so TDCS for the
  eighth bit is far exceeded), and falls together with the CSX rising edge, 75 ns after the eighth
  falling edge (TDCH). It is already low when CSX falls for the next command.
- Reset: the output register is all ones, so SCL is high in cycle 0 and falls at cycle 1 while CSX
  is high. The first CSX falling edge is at cycle 6, so SCL has been low 125 ns.

`run_args.txt`:
`-config start=8,out_base=0,out_count=1,set_base=1,set_count=3,out_msb_first=1,threshold=16 -mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp`

## pe_sim runs (every invocation counted): 15 in total
1. `./pe_sim run st7735.s -help`: help text. Learned flag names; noticed `sideset_base`/`sideset_count`.
2. `run` v1 (20 instructions, start at 0) with the TASK.md example words (t1.txt), 400 cycles.
   Read the waveform by hand: bytes 0x2A / 0x00 0x7F / 0x29 correct, D/CX and CSX correct, timing as designed.
3-5. `run` v1 on generated runs seed 1, 2, 3 (613, 12 and 1205 bytes, including 600-data-byte
   transfers, lone commands, 0x00/0xFF), checked by `check.py`: OK.
6-7. `run` v1 on seeds 4 and 5: OK.
8. `./pe_sim asm st7735.s` (v1): 20 words.
9. `./pe_sim asm st7735.s` (v2, reordered, start=8): 19 words.
10. `run` v2 with t1.txt: same waveform start as v1.
11-15. `run` v2 on seeds 1 to 5 with `check.py`: all OK.

`check.py` decodes the printed pin changes as a display would (bit on each SCL rise while CSX is low,
D/CX at the eighth rise, one transfer per CSX low pulse), compares with the expected transfers, and
checks every timing row of the table in whole cycles, plus CSX high and quiet at the end. I checked
that it reports an error when a pin line is deleted from an output. It is my own reading of the
rules, not the acceptance test, which I have not seen.

## Mistakes found
- I miscounted v1 as 19 instructions in my head; the assembler printed 20 words. Reordering so the
  data loop falls through into `fin` and using `start=8` brought it to a real 19 (v1 kept as
  `st7735_v1_20instr.s`).
- No functional bug showed in any run. Everything that was a guess (below) happened to be right first time.

## Rule slips
None that I know of. I read and wrote only in this directory, ran `pe_sim` only as `./pe_sim` from
here, did not read `pe_sim`'s contents and did not use the web.

## Result
I believe it works: 5 generated runs plus the example decode correctly and meet every timing row
under my own checker.

Program length: **19 instructions**.

## Confusing or missing in isa.md
1. The assembler syntax is not described at all, although TASK.md says it is. Labels (`name:`),
   comments (`;`), the delay suffix (`[n]`), `jmp x-- label`, `out y, 7` and number formats were all
   guessed from RP2040 PIO conventions. So were the `-config` value formats (`out_msb_first=1`,
   `start=8`), the `-mode 0=pp` form and the `-tx` file format (I used `0x012A` per line).
2. `out` is under-specified: it does not say that bits moved to X/Y land right-justified (the whole
   register is replaced), that MSB-first takes from bit 15 whatever `threshold` is, or what
   `out pins, n` does when n differs from `out_count`. My word parsing depends on the first two.
3. `pe_sim -help` lists `sideset_base` and `sideset_count`, which isa.md never mentions. With a side-set
   on SCL the two bit loops could probably be one, but with no documentation I did not use it.
4. Nothing says how printed cycle numbers relate to instructions. Observed: the instruction executed
   in cycle c shows as a pin change printed at c+1, the first line is `pins 0 ff`, and the first
   `pull` at cycle 1 did not stall.
5. No way to invert a bit or write one pin without touching its neighbours in the `set` range. D/CX is
   the inverse of word bit 8 and sits between SCL and CSX, which is what forces the duplicated loop.
6. The defaults of the config fields (`threshold`, `out_count`, `set_count`, `start`) are not given,
   so I set all of them explicitly.
