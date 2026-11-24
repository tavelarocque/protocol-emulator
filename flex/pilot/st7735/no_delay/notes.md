# Notes: ST7735 host firmware

## What I read
- `TASK.md` (all), `isa.md` (all), and the output of `./pe_sim run x.s -help`.
- Nothing outside this directory was opened. See "Rule slips" for one accident.

## Design
Pins: P0 SDA via `out pins` (out_base 0, out_count 1), P1 SCL via side-set
(sideset_base 1, sideset_count 1), P2 D/CX and P3 CSX via `set pins`
(set_base 2, set_count 2; value bit 0 = D/CX, bit 1 = CSX).
OSR shifts MSB first, threshold 16, no autopull.

Per word: `pull`, drop 6 unused bits, `out y,1` (last flag, bit 9),
`out x,1` (command flag, bit 8). Command: `set pins,0` (D/CX low, CSX low).
Data: `set pins,1` (D/CX high, CSX stays low). Then a 4-cycle bit loop:
`out pins,1 side 0` / `nop side 0` / `nop side 1` / `jmp !osre bit side 1`,
so SCL is low 50 ns, high 50 ns, period 100 ns, and SDA changes on the
falling edge (50 ns setup, 50 ns hold). After the eighth bit, `jmp !y top
side 0` makes the last falling edge; if the word was the last of its
transfer, CSX is raised 2 cycles later with D/CX left where it was
(`set pins,2` after a command, `set pins,3` after data).

Start-up: the output register resets to all ones, so SCL (push-pull) is high
at cycle 0. The first instruction is `pull side 0`, which drives SCL low at
once (visible at cycle 1), with CSX still high from reset. First CSX fall is
at cycle 6, so SCL has been low 125 ns by then.

Measured margins (from the simulator output, 25 ns per cycle):
- TCSS: 100 ns (CSX fall at 6, first SCL rise at 10).
- TCSH: 50 ns before CSX rise; at least 125 ns before CSX fall.
- TCHW: 175 ns (7 cycles) between back-to-back transfers.
- TSCYCW 100 ns, TSHW 50 ns, TSLW 50 ns, TSDS 50 ns, TSDH 50 ns.
- TDCS: D/CX is set before the first bit of each byte, about 800 ns before
  the eighth rise. TDCH: D/CX never changes sooner than 150 ns after the
  eighth fall while CSX is low.
- Speed: about 39 to 41 cycles per byte, against a budget of 200.

## pe_sim runs (8 total)
1. `./pe_sim run x.s -help`: flags list.
2. `./pe_sim asm st7735.s`: assembled first time, 18 words.
3. `./pe_sim run st7735.s -tx t1.txt -cycles 2800 <run_args>`: the TASK.md
   example (0x012A 0x0000 0x027F 0x0329). Read the waveform by hand: correct
   bytes, D/CX, CSX framing.
4. Same run again, output saved to `t1.out` for my checker: 0 errors.
5. `t2`: 12 transfers with 0,0,1,0,2,3,0,0,16,1,1,0 data bytes: 0 errors.
6. `t3`: one transfer of 600 data bytes: 0 errors, done at cycle 23442.
7. `t4`: one command with no data: 0 errors, done at cycle 42.
8. `t5`: 600,0,600,5,0,0,600 data bytes (1812 words): 0 errors, done at
   cycle 70695 of 364400 allowed.

`check.py` is my own decoder (samples SDA on SCL rises while CSX is low,
D/CX on the eighth rise, checks every row of the timing table and compares
the decoded transfers with the words). `gen.py` makes random words. I checked
that the timing checks are not vacuous by shrinking the checker's cycle time
to 14 ns and 7 ns: it then reports TSHW, TSLW, TSCYCW failures. That used no
simulator run. The checker is mine, not the acceptance test, so it can share
a misreading of TASK.md with the firmware.

## Mistakes found
None in the firmware: the first version assembled and passed. Things I
guessed and then confirmed from the simulator output rather than from
`isa.md`: `set pins` puts value bit 0 on `set_base`; the `-mode 0=pp`
syntax; a pin write by an instruction that executes in cycle c is printed
as a change at cycle c + 1.

## Rule slips
- I ran `ls -la` in this directory, which printed the path that the
  `pe_sim` symlink points to (outside this directory). I did not open, list
  or follow that path.
- No other slip. No web use.

## Known limits and doubts
- SCL is high at cycle 0 (reset value of the output register) and falls at
  cycle 1 while CSX is high. I cannot avoid this from firmware: `run_args.txt`
  may only hold `-config` and `-mode`, and the pin is push-pull from cycle 0.
  TASK.md only asks that SCL be low for 15 ns before the first CSX fall,
  which holds.
- D/CX falls in the same cycle as CSX at the start of a transfer. The
  timing table constrains D/CX only around the eighth pulse, so I believe
  this is fine.

## Result
Program length: 18 instructions. pe_sim runs: 8.

## Confusing or missing in isa.md
1. Pin mapping of multi-bit fields is never stated: which bit of a `set
   pins` value, of an `out pins, n` group, or of a multi-pin `side` value
   goes to the base pin. Also not stated: what `out pins, n` does when n
   differs from `out_count`.
2. The reset state against an idle-low clock. The output register resets
   to all ones and the advice given ("enable the thread before making the
   pin push-pull") is not something `pe_sim run` lets me do, so an
   idle-low line always starts high for one cycle.
3. Assembler syntax is shown only by one two-line example. Labels, comments,
   number formats, `nop`, and the `jmp` condition spelling have to be
   guessed. The UART example it points to is in a file I do not have.
4. The comparison table with RP2040 PIO does not say that there is no
   per-instruction delay field, so a held clock phase costs a `nop`.
5. `out x, 1` leaving X equal to the single bit (zero-extended) and
   "pull marks the OSR full" resetting the shift count are implied, not said.
6. pe_sim's printed cycle number (a write in cycle c shows at c + 1) is
   not documented in `isa.md` or the help text.
