# Notes: DSI transmitter

## What I read
- TASK.md, in full (134 lines).
- isa.md, in full, in four parts (lines 1-160, 160-330, 330-490, 490-638).
- Nothing outside this folder.

## Design (written before the first run)

Timing budget. A half-bit is 8333.33 cycles and the limit is +-80 cycles on
the place of every change, counted from the frame's rise. If every half-bit
is exactly 8333 cycles, the error at half-bit k is -k/3 cycles, at most about
-5.7 cycles at half-bit 17. That is far inside the limit, so no fractional
correction is needed: every half-bit in the program is made exactly 8333
cycles long.

Registers:
- ISR holds the delay constant C. The host words only carry data, so the
  constant is built by the firmware: with `in_msb_first` the ISR shifts left
  and new bits enter at the bottom, so `set x, a / in x, 5` three times gives
  a 15-bit number. C = 8327 = 8*1024 + 4*32 + 7.
- X is the delay counter: `mov x, isr` then `l: jmp x-- l` takes 1 + (C+1)
  = C+2 cycles (isa.md: a loop entered with X = n takes n + 1 cycles).
- OSR holds the word. `out_msb_first` takes bits from bit 15 down, so after
  `pull`, `out null, 8` throws away bits 15..8 and the next 8 `out y, 1` give
  D7 first. With `threshold=16` and no autopull, the OSR counts as empty
  exactly after the 8th data bit, so `jmp !osre` is the bit counter.
- Y holds the current bit (`out y, 1`, then `jmp !y zero`), and in the gap
  it is the loop counter for the 16 half-bit delays.

Every half-bit is one `set pins` followed by exactly D+4 = C+6 = 8333 cycles
before the next `set pins` (the 4 extra cycles are nops in the first half and
`jmp !osre / out / jmp !y` in the second half and in the start bit). After
the last data bit, `jmp tail / nop / set pins 0` lands exactly on half-bit
17, so a frame ending in D0 = 0 falls at half-bit 17.

Gap: after `set pins 0` at half-bit 17, 16 iterations of (mov, delay loop,
`jmp y--`) of 8330 cycles each, then `pull`, `out null 8`, `set pins 1`. The
next rise is then at 17*8333 + 133284 = 274945 cycles after the previous
rise (allowed 225000 to 375000). The same gap code runs once before the
first frame: the program drives P0 low in cycle 0 (shown at cycle 1), builds
the constant, and enters the gap, so the first rise is at about cycle 133293
(allowed 50000 to 200000). When the words run out, the thread stalls in
`pull` with the line low, forever.

Config: `in_msb_first=1, out_msb_first=1, threshold=16`, set_base 0 and
set_count 1 by default; P0 push-pull.

## pe_sim runs
I wrote `check.py` (left in the folder) to decode a trace the way TASK.md
describes: it takes bit 0 of every `pins` line, checks the line goes low
within 1000 cycles, the first rise in [50000, 200000], each later rise
225000 to 375000 after the one before, every expected change of every frame
(start bit, Manchester data D7 first, stop bits) within 80 cycles of
k x 25000/3 after that frame's rise, and no extra changes after the last
frame. The test word files and traces were scratch files and I deleted them.

1. `pe_sim asm dsi.s`: assembled without complaint, 44 words.
2. `pe_sim run dsi.s -help`: lists the flags; config keys are the field
   names (`in_msb_first`, `out_msb_first`, `threshold`, ...), `-mode P=pp`.
3. Run with words 0x00A5, 0x0000, 0x00FF, `-cycles 1325000` and the
   arguments in run_args.txt: `pins 0 ff`, `pins 1 fe` (low at cycle 1),
   first rise at cycle 133293, exactly as computed; 0xA5's changes at
   +16666, 33332, 49998, 66664, 74997, 83330, 99996, 116662, 133328, the
   places listed in TASK.md's example minus k/3 cycles. Second rise at
   408238 = 133293 + 274945, as computed. check.py: PASS, max error 5.67
   cycles. This also confirmed two things isa.md does not say outright:
   `in x, 5` takes X's low 5 bits, and `mov x, isr` leaves the ISR as it
   was (every delay came out the same length).
4. Run with one frame 0x0001: PASS, 16 changes, max error 5.33, last change
   a fall at half-bit 16 (266621), nothing after.
5. Run with 8 frames 0x80, 0xFE, 0x01, 0x7F, 0x55, 0xAA, 0x00, 0xFF: PASS,
   118 changes, max error 5.67.
6. Run with 8 random levels (seed 7): 0xA5, 0x4D, 0xCA, 0x18, 0x25, 0x30,
   0xBB, 0x1D: PASS, 104 changes, max error 5.67. Last frame ends in D0 = 1
   (fall at half-bit 16); frame 0x18 etc. end with D0 = 0 (fall at 17).
7. Run with 5 random levels: 0x6D, 0x13, 0x2C, 0xDE, 0xD6: PASS, 66
   changes, max error 5.67.

Seven pe_sim runs in all (counting the assemble and the help). No mistakes
found: the first version of the program is the one handed in.

## Result
- `dsi.s`: 44 instructions.
- `run_args.txt`: `-config in_msb_first=1,out_msb_first=1,threshold=16 -mode 0=pp`
- Timing: every half-bit is 8333 cycles; worst error -5.67 cycles (half-bit
  17); frame-to-frame rise spacing 274945 cycles; first rise at 133293.

## Confusing or possibly wrong in isa.md
- `in src, count`: the default direction is described only as "shifts count
  bits right into the ISR" and "least significant bit first"; it does not
  say where the new bits enter or which bits of the source are taken. I
  used `in_msb_first`, whose description is clear, and the simulator showed
  the source's low bits are taken.
- `mov dst, src` does not say whether reading `isr` (or `osr`) changes it or
  its count. In the simulator it does not.
- There is no way to load a constant wider than 5 bits except building it
  through the ISR (or taking it from the host), and no `jmp pin` and no
  inverted write: a Manchester encoder has to keep the level in its flow of
  control. Not wrong, but worth a sentence in the document.
- The note about enabling the thread before making a pin push-pull is about
  the host; in pe_sim the pin is push-pull from cycle 0, so P0 shows high at
  cycle 0 and the firmware's first `set pins, 0` shows at cycle 1.
- Nothing I found contradicted the simulator.

## Rules
I read and wrote only inside this folder. No rule broken that I know of.
No em-dashes used.
