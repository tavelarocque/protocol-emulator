# Notes: Maple bus transmitter

## What I read

- `TASK.md`, all 187 lines, in one read.
- `isa.md`, all 638 lines, in three parts (1-219, 220-439, 440-638).
- `pe_sim` and `pe_sim.real` were not opened, only run.
- Nothing outside this folder was opened, listed or searched.

## Design (first version)

Key facts I took from isa.md:
- No delay field in the encoding, every instruction is one tick. `clkdiv` slows the thread to one tick
  every `clkdiv` cycles. Side-set (up to 3 pins) is written on every executed tick, also while stalled.
- There is no ALU: no add, no xor. The only arithmetic is `jmp x--`/`y--` and shifts through ISR/OSR.
- The CRC register with polynomial 0x80 (8-bit, written low power first, i.e. G = x^8 + 1) is a rotate
  right of an 8-bit lane, with the input bit XORed in at bit 7. Fed with the frame bits MSB first, after
  every whole byte it holds r = bitreverse8(XOR of all bytes). So it computes the checksum, bit reversed.
- To un-reverse: read r into the OSR, restart the CRC, feed r's 8 bits MSB first through `out null, 1`
  (eight times). The CRC then holds bitreverse8(r) = checksum, in the natural order.

Timing choice: `clkdiv = 4`, so a tick is 80 ns. Then two changes of different lines need at least 2
ticks between them (8 cycles >= 7), two changes of the same line at least 3 ticks (12 cycles), and the
largest gap allowed inside a frame is 25 ticks (100 cycles). A bigger divider would need fewer padding
instructions, but the checksum preparation (about 14 instructions) has to fit between two changes of
the lines, and that needs a small divider.

Both lines are driven only by side-set (`sideset_base=0`, `sideset_count=2`, side value = A + 2B).
Every instruction states both levels, so the state of the lines is kept in the flow of control.

Per bit, with the bit read by `out y, 1` (OSR shifts MSB first, `threshold=16`) then `jmp !y`:
- even bit (clock A, data B): step 1 levels (A1,B0), step 2 (A1,B=v), step 3 (A0,B=v)
- odd bit (clock B, data A): step 1 (A0,B1), step 2 (A=v,B1), step 3 (A=v,B0)
Step 1 levels do not depend on the previous bit (except bit 0, which starts from both high and is
handled at the end of the start pattern). Each bit is 5 ticks (400 ns).

Word handling: a word ends after an odd bit (16 bits per word). The odd bit's last instruction is
`jmp !osre ev`; if the OSR is empty it falls to `wend`:
- `jmp !isrf fin`: a flag in the ISR shift count. During data the ISR is "full" (setup shifted 16 or
  more bits into it); the checksum preparation does `mov isr, null`, so after the checksum the ISR is
  not full and we go to the end pattern.
- `jmp x-- nx`: X counts the words still to pull (2N+1 after word 0); `nx` pulls and goes on.
- otherwise fall into `ck`, the checksum preparation, which loads the OSR with the checksum in bits
  15..8 and a shift count of 8, so exactly 8 more bits are sent through the same bit code.

Frame setup, after `pull` of word 0 (N in bits 15..8): `mov isr, osr; in null, 8` gives N (ISR shifts
right, `in_msb_first` off); `mov x, isr`; then `in pins, 1` (P0 reads 1 while idle), `in x, 8`,
`in null, 7` leaves ISR = 2N+1, moved to X in the start pattern's first instruction. The idle gap
before the start pattern is a `wait 0 pin 0 timeout` on P0 (high while idle, so it always times out),
whose timeout_vector is the start pattern.

### Timing worked out by hand (ticks of 4 cycles)

- Bit engine: every change is at least 2 ticks after a change of the other line and at least 3 ticks
  after the previous change of the same line, on every path (even/odd, bit 0/1, previous bit 0/1).
- The longest gap inside a frame is the checksum preparation: from the last data bit's B fall (or the
  A rise after it) to the first change of the checksum's first bit is 19 or 20 ticks (76 or 80 cycles).
- Bit 0 has its own entry at the end of the start pattern, because it starts with B high.
- End pattern: one pad tick so that B rises 3 ticks after it fell. The final B rise is the `pull` of
  the next frame's word 0, which also stalls there (idle, both high) after the last frame.
- Idle gap between frames: pull + 6 setup ticks + the wait (timeout 30, so 31 ticks) = 38 ticks =
  152 cycles from the end pattern's last change to the next start pattern's first change.

Register use: Y holds the current bit (and is the start pattern's loop counter), X counts words (and
is the end pattern's loop counter), the ISR is used for arithmetic in the setup and as the
"checksum sent" flag, the OSR holds the word being sent, the CRC computes the checksum.

## Testing

I wrote `check.py` (in this folder). It builds the TX words for a list of frames, runs pe_sim once,
turns the `pins` lines into a list of changes of A and B, and compares them change for change with a
reference encoder written from TASK.md (I checked the encoder offline against the 98-change table of
the example frame: identical). It also checks: no two lines in one cycle, >= 7 cycles after the other
line, >= 12 after the same line, <= 100 between changes inside a frame, first change <= 50000, idle
between frames 100..50000, nothing after the last frame, both lines high at the end. Each invocation
of check.py is exactly one pe_sim run.

## pe_sim runs

1. `pe_sim run maple_bus.s -help`: printed the run flags (config field names, -cycles, -inputs,
   -mode, -stimulus, -tx).
2. `pe_sim asm maple_bus.s`: assembled, 66 words. Confirmed `start` label is address 26 and `frame`
   is address 58 (used for timeout_vector and start). The wait encodes as 0x3810 as expected.
3. Raw run of the example frame (0x0000, 0x2001), 3000 cycles: output looked right by eye (start
   pattern at cycles 153..257, bit 0 = 0 as B- A-, word gap 32 cycles, checksum gap 80 cycles).
4. check.py example (both TASK.md frames): all 260 changes matched and all timing passed, but my
   checker reported "lines not both high at the end: 255". Bug in check.py (it compared the whole
   pin byte with 3 instead of masking the two lines), not in the firmware. Fixed the checker.
5. check.py example: PASS (first change 153, max gap 80, min gap 8, idle 152).
6. check.py seed 1, 4 frames, N = 0, 230, 1, 59: PASS, 18950 changes.
7. check.py seed 2, N = 0, 255, 95, 246: PASS, 38532 changes.
8. check.py seed 3, N = 1, 98, 255, 255: PASS, 39364 changes.
9. edge zeros: N = 0, 255 (all bytes 0), 2 (all 0): PASS.
10. edge ones: one frame N = 255, every byte 0xFF: PASS.
11. edge mixed: N = 128 (0xAA/0x55 data), 0 (all 0xFF header), 127, 3: PASS.
12. seed 11, small N (3, 0, 0, 1): PASS.
13. seed 12 (6, 0, 1, 4): PASS.
14. seed 13 (6, 6, 5, 6): PASS.
15. seed 14 (1, 5, 0, 0): PASS.
16. seed 15, a single frame N = 0: PASS.

Total: 16 pe_sim runs. Every run with the final program passed; the program was not changed after
run 2.

## Mistakes found

- Only the checker bug of run 4. No firmware bug showed up.

## Result

- `maple_bus.s`, `run_args.txt` (one line: `-config ...` and `-mode 0=pp -mode 1=pp`), this file.
  `check.py` is my test script, left in the folder.
- Program length: **66 instructions**. That is two more than a 64-word page: the last two
  instructions (`in null, 7` and the `wait`) sit at addresses 64 and 65 of page 1. They are reached
  only by falling through from address 63 (PAGE stays 0), contain no `jmp`, and the `wait` leaves
  through `timeout_vector`, a full address. So PAGE is 0 for the whole run and no `set page` is needed.
  The assembler accepted it.

## Things in isa.md that were confusing or seem incomplete

- No delay field: every padding tick costs an instruction, which is why I used `clkdiv`.
- The ISR shift count past `threshold` without autopush is not described. My setup shifts 24 bits
  into the ISR after resetting it, and I rely on `!isrf` then reading "full". The simulator agrees
  (otherwise every frame would have ended after word 1), but the document does not say whether the
  count saturates, keeps counting or wraps.
- For `in` with `in_msb_first` off it says only "shifts count bits right into the ISR"; it does not
  say that new bits enter at bit 15 of the 16-bit ISR (I assumed so, as on RP2040 with 32, and it
  worked), nor which bits of X an `in x, 8` takes (the low 8, it worked).
- CRC: "the polynomial, written low power first" plus "a CRC narrower than 32 bits uses the
  register's low bits" was enough, but it took working out by hand that the register is a right shift
  with the feedback XORed in at the polynomial's bits, so poly 0x80 is an 8-bit rotation and the XOR
  checksum comes out bit reversed for MSB-first data. That the CRC "stops following the data" after a
  read, and a write restarts it, was essential here and is stated only in the `mov` section.
- `wait ... timeout`: "stalls for T cycles at most, and ... jumps on the cycle after". With clkdiv
  these are ticks; measured idle gap (38 ticks) matches T stalled ticks plus one tick for the jump.
- The `-config` defaults (threshold 8, out_count 1, set_count 1) are only in the pe_sim section.
- Nothing I found was wrong; the points above are gaps rather than errors.

No rule was broken: I read and wrote only inside this folder, and used 16 of the about 80 runs.
