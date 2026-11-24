# Notes: ST7735 host firmware

## What I read
- `TASK.md` and `isa.md`, both in full, once each.
- `./pe_sim run st7735.s -help` output (run 1).
- Nothing else. I did not open, list or search anything outside this folder, did not read `pe_sim`'s contents, and did not use the web.

## Files I wrote here
- `st7735.s`: the program.
- `run_args.txt`: the `-config` and `-mode` flags.
- `check.py`: my own checker. It builds a run, calls `./pe_sim` once, decodes the printed pin changes the way a display would and checks every row of the timing table. It is not the acceptance test, only my reading of TASK.md.
- `t1.txt`, `t2.txt`: two small hand-made word files.
- `notes.md`: this file.

## Design
Pins: P0 SDA through `out pins` (out_base 0, out_count 1), P1 SCL through side-set (sideset_base 1, sideset_count 1), P2 D/CX and P3 CSX through `set pins` (set_base 2, set_count 2, so the set value is CSX:D/CX). All four push-pull.

Config: `out_msb_first=1`, `threshold=16`, no autopull, clkdiv left at every cycle.

Each word is pulled whole. With MSB-first shifting the top six zero bits are thrown away, bit 9 (last byte) goes to X, bit 8 (command) goes to Y, and the remaining 8 bits are the byte, already in wire order. After those 8 bits exactly 16 have been shifted, so the OSR counts as empty and `jmp !osre` is the bit counter: no register is spent on counting.

Per byte:
1. `pull`, three `out`s to split the flags.
2. Branch on Y: command does `set pins, 0` (CSX low, D/CX low), data does `set pins, 1` (CSX low, D/CX high). For data bytes after the first this rewrites the same levels, so CSX stays low through the transfer.
3. Bit loop, 4 cycles a bit: `out pins, 1 side 0 [1]` then `jmp !osre, bitloop side 1 [1]`. SCL is low 2 cycles and high 2 cycles (50 ns each, period 100 ns), SDA changes on the falling edge, so setup and hold are both 50 ns.
4. `jmp !x, start side 0 [1]` drops SCL after the eighth pulse. If it was the last byte, `set pins, 3` raises CSX 50 ns later.

Measured from the traces: about 40 to 42 cycles per byte against a budget of 200. CSX fall to first SCL rise is 100 ns. CSX high between transfers is 175 ns. SCL fall to CSX rise is 50 ns. D/CX changes at the earliest 50 ns after the fall of an eighth pulse and at the latest 325 ns before the next eighth rise.

Start-up: the output register resets to all ones, so SCL is high at cycle 0. The first instruction is `pull side 0`, and side-set applies while it stalls, so SCL is low from cycle 1. The first CSX fall is at cycle 6, 125 ns later. I saw no way to make SCL low at cycle 0 itself in `pe_sim` (pin modes are fixed for the whole run), so there is one unavoidable SCL falling edge at cycle 1 while CSX is high.

After the last word the thread stalls in `pull` with SCL low and CSX high, and nothing more is sent.

One thing I chose not to do: `set pins, 3` at the end of a transfer also puts D/CX high, so after a command with no data D/CX rises in the same cycle as CSX. That is 50 ns after the SCL fall (TDCH needs 10 ns) and the display ignores the line once CSX is high. Keeping D/CX unchanged there would cost three more instructions.

## Every run of pe_sim (11 in total)
1. `./pe_sim run st7735.s -help`: learned the flags (`-config k=v,...`, `-mode P=pp|od|in`, `-tx`, `-cycles`, `-inputs`).
2. `./pe_sim asm st7735.s`: assembled first time, 13 words. My guessed syntax (`jmp !y, label`, `side 0 [1]`, `;` comments, labels with a colon) was accepted.
3. `./pe_sim run st7735.s -tx t1.txt -cycles 400 ...` with TASK.md's example (0x012A 0x0000 0x027F 0x0329). Decoded the trace by hand: 0x2A with D/CX low, 0x00 and 0x7F with D/CX high, CSX up, then 0x29 with D/CX low, CSX up. Correct on the first try.
4. `check.py example`: PASS.
5. `check.py single` (one command 0x00, no data): PASS.
6. `check.py allvals` (every value 0..255 as a lone command, then every value as data, 770 bytes): PASS.
7. `check.py long` (two transfers with 600 data bytes each, plus short ones, 1205 bytes): PASS, finished at cycle 48211 of 243000.
8. `check.py random 1`: PASS.
9. `check.py random 2`: PASS.
10. `check.py random 3`: PASS.
11. Raw run with `t2.txt` (0x03FF, 0x03A5, two commands with no data) to read the start and the gap between transfers by eye: correct.

## Mistakes found
- None in the firmware: the first version assembled and passed, and it is the version handed in.
- One misreading of my own, caught straight away: in run 3 I first took `pins 90 f6` (SCL rising with SDA still 0 from the previous byte) for a clock edge before the data bit. It was the correct first bit of 0x7F, which is 0, and SDA had no reason to change.
- A limit of my checking: `check.py` is written from the same reading of TASK.md as the firmware, so a misunderstanding of the sheet would pass both. The byte and D/CX decoding is independent of the firmware, and I also decoded two traces by hand.

## Rule slips
None that I know of. For full disclosure: I ran `python3` (the system interpreter, with `-I`) for `check.py`; the script reads and writes only files in this folder and calls `./pe_sim` from this folder. Every `pe_sim` call was made as `./pe_sim` after `cd` into this folder.

## Program length
13 instructions.

## Confusing or missing in isa.md
1. The assembler syntax is not described. The only assembly shown is two side-set lines. The delay syntax (`[n]`), whether `jmp` takes a comma after the condition, label and comment syntax and number formats are all absent. I guessed RP2040 pioasm style and it happened to work.
2. The timing of a pin write against the printed cycle and the start of the run is not pinned down. "Pin writes take effect at the end of the cycle" does not say which cycle the first instruction runs in or at which cycle number the simulator prints the change (it prints the cycle after). Linked to this, the advice for idle-low lines ("enable the thread before making the pin push-pull") cannot be followed in `pe_sim`, where modes are fixed, so SCL is high at cycle 0 whatever the firmware does.
3. The bit-to-pin mapping of `set pins` and `out pins` is never stated (value bit 0 to the base pin is what the simulator does), and nothing says that `out x, 1` leaves X as 0 or 1 with the upper bits cleared.
4. With side-set on, the reduced delay range (0 to 7 with one side-set bit) has to be worked out from the encoding paragraph. It is also not said whether `threshold=16` is written as 16 or 0 in `-config` (16 works).
5. `mov` lists `crc` as a location but the operand table gives no number for it; the revision history says it is 6, which the reserved-encoding list still calls a NOP. I did not need it.
6. The document refers throughout to `model/...`, `hw/...`, `docs/info.md` and `Firmware.*` examples that a reader of this file alone does not have, including the only complete example programs.
