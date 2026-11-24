# Notes: ST7735 host firmware, build without side-set

## What I read
- `TASK.md` and `isa.md`, both in full, once each.
- The output of `./pe_sim run x.s -help` (run 1).
- Nothing else. I did not open, list or search anything outside this folder, did not
  read `pe_sim`'s contents, and did not use the web. Files I wrote here: `st7735.s`,
  `run_args.txt`, `host.py`, `notes.md`, plus two helpers that are not part of the
  hand-in (`check.py`, `t.sh`). Scratch files (TX word lists, simulator outputs, two
  mutated programs, `__pycache__`) were created here and deleted here at the end.

## Design
Pins: SDA is the only `out pins` pin (`out_base=0, out_count=1`). SCL, D/CX and CSX
are the three `set pins` pins (`set_base=1, set_count=3`), so a `set pins, v` writes
SCL = bit 0, D/CX = bit 1, CSX = bit 2 in one go. With no side-set, every SCL edge is
its own `set`, and because the `set` also rewrites D/CX, there are two bit loops: one
for the command byte (D/CX low) and one for data bytes (D/CX high).

Config: `threshold=8`, `out_msb_first=1`, no autopull. One TX word per byte. The byte
sits in bits 15..8, so eight `out pins, 1` send it MSB first and `jmp !osre` ends the
loop with no counter. Bit 7 is then at the top of the OSR; `out x, 1` takes it as a
"more" flag: 1 means another data byte of the same transfer follows, 0 means raise
CSX. That avoids a length word (600 data bytes plus a command do not fit one word).

Timing per bit, 5 cycles = 125 ns: `out pins,1` (SDA changes), `set` SCL high with
delay 1 (high 2 cycles = 50 ns), `set` SCL low, `jmp` (low 3 cycles = 75 ns).
SDA setup 25 ns, hold 100 ns. CSX falls 2 cycles (50 ns) before the first SCL rise;
SCL has been low 4 cycles or more before CSX rises; CSX stays high 3 cycles (75 ns)
between transfers. D/CX goes low together with CSX falling, goes high 4 cycles after
the command byte's last SCL fall and 3 cycles before the first data bit, and is
steady through all 8 bits of every byte. About 45 cycles per byte against a budget of
200.

Start-up: the output register resets to all ones, so SCL is high at cycle 0. The
first instruction (`set pins, 6`) pulls SCL low at cycle 1 with CSX still high; the
first CSX fall is at cycle 4, so SCL has been low 75 ns by then.

End: after the last word the program is back at `pull` with CSX high and stalls
there, so nothing more is sent.

## Runs of pe_sim (25 in total)
1. `./pe_sim run x.s -help` to see the flags (x.s does not exist; only help printed).
2. `asm` of the first draft (16 words). Assembled first time: PIO-style syntax guessed
   right (`label:`, `;` comments, `[n]` delay).
3. `run` of the first draft on 3 hand-made transfers, 400 cycles. Read the pin trace
   by hand: bits of 0x2A correct, MSB first, 5-cycle period, D/CX and CSX as planned.
4. `asm` after reordering to drop one `jmp` (15 words).
5. `./t.sh 0` (the same 3 transfers through `host.py`, checked by `check.py`): OK.
6 to 13. Seeds 1, 2, 3, 4, 11, 12, 13, 14: edge bytes and empty data, one transfer of
   600 data bytes, a single command, every byte value as command and as data, four
   random mixes (up to 1011 bytes). Each run for exactly 200 x bytes + 2000 cycles.
   All OK.
14, 15. Two deliberately broken programs, to see that `check.py` is not vacuous:
   SCL high delay removed (reported TSHW 25 ns) and data D/CX dropped on the SCL fall
   (reported TDCS, wrong D/CX, TDCH). Both caught.
16. `asm` after adding `set pins, 2` before the data `pull` (16 words, final).
17 to 21. Seeds 0 to 4 again on the final program: all OK.
22 to 25. Seeds 11 to 14 again on the final program: all OK.

`check.py` decodes the trace the way TASK.md describes the display (sample SDA on SCL
rising edges while CSX is low, D/CX at the 8th bit), compares with the transfers asked
for, and checks TCSS, TCSH, TCHW, TSCYCW (both ways), TSHW, TSLW, TSDS, TSDH, TDCS,
TDCH, no SCL rise outside a transfer, CSX high at the end, and that the last pin
change is inside the cycle budget. It is my own reading of the rules, not the
acceptance test, so it can share a misreading with the firmware.

## Mistakes and changes
- No functional bug showed up in the simulator; the first draft already decoded
  correctly.
- Change 1 (run 4): reordered the blocks so the command loop falls into `more`,
  saving one `jmp` (16 to 15 words).
- Change 2 (run 16): in the 15-word version D/CX rose in the same cycle as the first
  SCL rise of the first data byte. That meets TASK.md (D/CX is only read with the 8th
  bit), but it is 0 ns of setup if a reader were to look at D/CX on every bit, so I
  spent one instruction to raise D/CX before the byte. This is a judgment call, not a
  fix for a failure I observed. If length matters more, delete `set pins, 2` before
  the second `pull`: the 15-word version passed the same checks in runs 5 to 13.
- Rule slips: none that I know of. `t.sh` does `cd` into this folder and calls
  `./pe_sim`, so every run was `./pe_sim` from inside the folder.

## Result
- Program length: 16 instructions (one page, no `set page`).
- `run_args.txt`: `-config start=0,out_base=0,out_count=1,set_base=1,set_count=3,threshold=8,out_msb_first=1 -mode 0=pp -mode 1=pp -mode 2=pp -mode 3=pp`
- Host word format, one 16-bit word per byte, in sending order:
  - bits 15..8: the byte (command or data), sent MSB first
  - bit 7: 1 if another data byte of the same transfer follows, 0 if this is the
    last byte of its transfer (CSX rises after it)
  - bits 6..0: 0
  - the first word of each transfer is the command byte; `encode` emits
    `1 + len(data)` words per transfer.
- I believe it works: 21 simulations, 9 distinct test sets, all clean under my
  checker, and the trace of the first one was also read by hand.

## What was confusing or missing in isa.md
- TASK.md says isa.md gives the assembler syntax. It does not: labels, comments, the
  `[n]` delay notation and number formats are nowhere stated. I guessed RP2040 PIO
  syntax and it happened to be right.
- The first line says this build has no side-set, but side-set is not described
  anywhere else in the document, while `pe_sim run -help` still lists
  `sideset_base` and `sideset_count`. A reader cannot tell what is missing.
- `out` without autopull on an OSR that already counts as empty (bits shifted out >=
  threshold) is not specified; only the autopull case is. My program depends on it
  simply continuing to shift (`out x, 1` after 8 bits with threshold 8). The model
  does that.
- With `out_msb_first`, "the top of the OSR" is bit 15 whatever the threshold, so
  with threshold 8 the byte must be in bits 15..8. That follows from the text but is
  easy to get wrong; a sentence or an example would help.
- Which immediate bit of `set pins` goes to which pin (bit 0 to `set_base`) is not
  stated, and neither is what `out pins, n` does to the pins of the out range beyond
  the n bits shifted. I avoided the second by using `out_count=1`.
- The output register resets to all ones and the advice for idle-low lines is to
  enable the thread before making the pin push-pull. `pe_sim run` cannot do that
  (modes are fixed for the whole run), so SCL is unavoidably high at cycle 0.
- Pin changes are printed one cycle after the instruction that makes them (an
  instruction at cycle 0 shows at cycle 1). Consistent with "writes take effect at
  the end of the cycle", but the print convention is not stated.
- The `-tx` file's number format and the defaults of `-config` are not in the help
  text. `0x....` hex worked.
- Nothing in isa.md looked wrong against the model's behaviour in what I exercised.
