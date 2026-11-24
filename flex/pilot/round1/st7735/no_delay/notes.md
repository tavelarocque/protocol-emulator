# Notes: ST7735 write-only host firmware

## What I read
- `TASK.md` and `isa.md`, both in full. Nothing else.
- `./pe_sim run st7735.s -help` for the simulator's flags.
- I did not open `pe_sim` or any file outside this directory.

## Design
Pins: P0 SDA through `out pins` (out_base 0, out_count 1), P1 SCL through
side-set (sideset_base 1, sideset_count 1), P2 D/CX and P3 CSX through
`set pins` (set_base 2, set_count 2, so the value is CSX:D/CX).

One TX word per byte sent. With `out_msb_first` and threshold 9, each word
is shifted from the top: first one flag bit into X ("more bytes follow in
this transfer"), then the 8 bits of the byte onto SDA. `jmp !osre` ends the
bit loop after exactly 8 bits, so no counter register is needed. D/CX needs
no flag: the first word after CSX falls is the command, everything after it
in the same transfer is data.

A bit is 4 cycles (100 ns): `out pins,1` (SCL low, SDA changes together with
the SCL fall), `nop` (SCL low), `nop` (SCL high), `jmp !osre` (SCL high).
So SCL high 50 ns, low 50 ns or more, SDA set up 50 ns and held 50 ns.
After the eighth pulse `jmp !x` drops SCL, and one cycle (25 ns) later a
`set pins` either raises D/CX for the data bytes (CSX stays low) or raises
CSX. That one cycle is the TDCH and TCSH margin (25 ns against 10 and 15).
CSX falls 4 cycles before the first rising edge of SCL (TCSS 100 ns) and is
high for at least 3 cycles between transfers (TCHW 75 ns against 40).
A byte costs 37 cycles, well inside the 200 allowed. If the FIFO runs dry
in the middle of a transfer the thread stalls in `pull` with SCL low and
CSX low, which the task allows. After the last transfer it stalls in the
`pull` at `next` with CSX high and sends nothing more.

At reset the output register is all ones, so SCL is high at cycle 0. The
first instruction drives it low (printed at cycle 1) and CSX first falls at
cycle 3, so SCL has been low for 50 ns by then.

## pe_sim runs: 26 in total
1. `./pe_sim run st7735.s -help`: flags.
2. `./pe_sim asm st7735.s`: assembled first time, 14 words.
3. `./pe_sim run ... -tx t1.tx -cycles 400` on three small transfers; read
   the pin trace by hand and decoded the first command (0x2A) bit by bit.
   Learned that a pin write made by the instruction of cycle c is printed
   at cycle c + 1, and that the trace starts with `pins 0 ff`.
4-13. `python3 check.py 1`: ten cases (10 runs), all pass. `check.py` is my
   own decoder and timing checker, written from the table in TASK.md. Cases:
   single command without data, command 0x00, command 0xFF, a small mix,
   12 empty-data transfers back to back, 0x00/0xFF extremes, 600 data
   bytes, 600 data bytes followed by more transfers, a random mix of 25
   transfers, and all 256 byte values as command and data.
14-16. Three deliberately broken copies of the program (deleted afterwards),
   to see that `check.py` can fail: one low cycle per bit (flagged TSLW),
   D/CX and CSX changed in the cycle SCL falls (flagged TDCH, TCSH), D/CX
   left low for data (flagged as wrong D/CX). All three were caught.
17-26. `python3 check.py 2`: the same ten cases with other random bytes
   (10 runs), all pass.
`runs.log` lists the 23 runs made through `check.py`.

## Mistakes found
None in the firmware: the first version assembled and passed, and I did not
change `st7735.s` after writing it. The only edit after the first run was to
`check.py` (letting it take another program file for the broken copies).
`check.py` is not the acceptance test and shares my reading of TASK.md, so a
misreading of the rules would pass it unnoticed.

## Rule slips
- My first shell command printed the directory listing together with both
  documents, and the tool saved that long output to a file outside this
  directory by itself. I did not open that file; I re-read both documents
  from this directory instead.
- That listing was `ls -la`, which showed the path `pe_sim` links to. I did
  not follow it or look at anything there.
- Python left a `__pycache__` folder here, which I removed. `check.py`,
  `mut.py` and `runs.log` are my own helper files, not deliverables.

## Result
- Program length: 14 instructions. The first, `set pins, 3`, only restates
  the reset state of the pins and could be dropped, giving 13.
- Host word format: one 16-bit word per byte, in sending order.
  bit 15 = 1 if another byte of the same transfer follows, 0 on the last
  byte of the transfer; bits 14..7 = the byte (MSB at bit 14); bits 6..0 = 0.
  The first word of a transfer is its command byte.
- Run arguments: threshold=9, out_msb_first=1, out_base=0, out_count=1,
  set_base=2, set_count=2, sideset_base=1, sideset_count=1; P0..P3 push-pull.

## About isa.md
Nothing in it turned out to be wrong for this job. What I had to guess or
find out by running:
- The `-mode P=pp` flag: whether P is a bare pin number. `0=pp` works.
- When a pin write shows up in the trace. "Pin writes take effect at the
  end of the cycle" is right, but it took a run to see that the trace
  prints them at cycle c + 1 and that side-set and `out`/`set` writes of
  one instruction land in the same printed cycle.
- With `out_msb_first`, a word shorter than 16 bits has to be left-aligned
  by the host (bits come from bit 15 whatever the threshold is). The text
  implies this ("take bits from the top of the OSR") but does not say it,
  and `push` being right-justified invites the opposite assumption.
- The side-set example has no `nop`; `nop side V` is accepted, which the
  document does not state. The encoding of the `side` field for one
  side-set pin (bit 12) is only given as "top n bits".
- The first line says this build has no per-instruction delay field, but
  the rest of the document never describes such a field, so the remark has
  nothing to refer to. Without it, SCL high and low times each cost a
  `nop`, which is 2 of the 14 instructions here.
- `set pins` with `set_count` 2 is described only as "set_count pins from
  set_base"; that value bit 0 goes to the lowest pin is an assumption that
  held.
