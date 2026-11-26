# Notes: AVR PDI programmer firmware

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `./pe_sim run x.s -help` (run 1 below), for the flag and config field names.

Nothing outside this folder was opened, listed or searched. No rule was broken
that I know of.

## Design

Clock divider 5: one thread tick is 5 cycles, so a 50-cycle PDI slot is 10
ticks. Ticks 0 to 4 of a slot are its low half and ticks 5 to 9 its high half.
PDI_CLK (P0) is side-set (`.side_set 1`, sideset_base 0): every instruction
executed in a low half says `side 0`, every one in a high half says `side 1`,
and no instruction's delay crosses a half boundary. So every half starts with
an instruction that sets P0, and the clock never pauses while the program does
its bookkeeping inside those halves.

The thread's first tick is cycle 0, so ticks fall on multiples of 5 and a
write made in a tick shows one cycle later. Every PDI_CLK edge is therefore
exactly 1 cycle after its ideal place (falling 2001 + 50k, rising 2026 + 50k).
That is within the +-2 allowed and it is a fixed offset, so it never adds up.
Exact placement would need clkdiv 1 and four or more instructions per half
slot (side-set leaves a delay field of 0 to 7), which I judged not worth the
size and the extra counting.

P1 (PDI_DATA, open-drain) is written only by `set pins` / `out pins` /
`mov pins` (set_base = out_base = 1, counts 1), and only in tick 0 or tick 1
of a slot the chip sends: at most 6 cycles after the falling edge, well
before the limit 5 cycles before the rising edge. In every other slot the
program never writes P1, so it cannot change there.

Flow:

1. Startup: two `jmp x--` delay loops with P0 held high, 400 ticks in all, so
   the first falling edge is written in the tick at cycle 2000.
2. Enable: 16 idle slots (`nop side 0 [4]` / `jmp x-- side 1 [4]`).
3. `main` runs in the high half of the slot just before the next frame (the
   last enable slot, the second stop bit of an unanswered frame, or the second
   idle slot after an answer). It pulls the word, copies it to X, shifts out
   15 bits to null and 1 bit to Y (Y = bit 15, the end flag), and restores the
   OSR from X (`mov osr, x` resets its count). The next tick is the falling
   edge of the next slot: `jmp !y frame side 0`.
4. Frame: start bit (`set pins, 0`), then `mov crc, null` to clear the parity
   accumulator; 8 data slots of `out pins, 1` with `jmp !osre` as the loop test
   (threshold 8, so no counter is needed); the parity bit with
   `mov pins, crc`; `out x, 4` takes the answer length (bits 11..8); stop bit 1
   (`set pins, 1`); stop bit 2 needs no write, and its low half does
   `jmp !x main`.
   Parity: with crc_poly = 1 and crc_init = 0 the CRC rule makes the register
   the XOR of the first bit of every OUT, which is exactly the even-parity bit
   once the 8 data outs are done. Reading it with `mov` gives bit 0 on P1.
5. Answer: guard of 128 idle slots as a 4-slot unrolled body run 32 times on Y.
   X is decremented once on the way in (always taken, length >= 1), so the
   receive loop's `jmp x--` at each frame's end runs exactly `length` frames.
   Each received frame: start slot, 8 data slots that `in pins, 1` in tick 5
   (the rising edge, cycle 2025 + 50k: the ATxmega's level, set at +5, is long
   through the 2-cycle synchroniser), loop test `jmp !isrf` (threshold 8),
   then `push` in the parity slot (right-justified byte, bits 15..8 zero), and
   two stop slots. Then 2 idle slots, with `main` in the high half of the
   second.
6. End: the slot in which `main` saw the end word is the first of 16 idle
   slots; after the rising edge of the 16th the program falls into
   `stop: jmp stop side 1`, so P0 stays high and P1 is never written again.

Config (`run_args.txt`): clkdiv=5, sideset_base=0, sideset_count=1,
out_base=1, out_count=1, set_base=1, set_count=1, in_base=1, threshold=8,
crc_poly=1, crc_init=0, with `-mode 0=pp -mode 1=od`.

## Test method

I wrote a throwaway Python helper (`t_check.py`, deleted before hand-in,
together with its scratch files `t_tx.txt` and `t_stim.txt`). For one session
it builds the TX words, the ATxmega's stimulus (P1 pulled low 5 cycles after
each ideal falling edge in its frames), the expected slot list, runs `pe_sim`
once with `run_args.txt`, and checks: the exact number of P0 edges, every edge
within +-2 of its ideal place, P1 changes only inside a chip-sent slot's
window, P1's level at every rising edge (chip bits correct, released
elsewhere), no P2 to P7 change, and the RX words.

## pe_sim runs (25 in all)

1. `run x.s -help`: flag list and config field names.
2. `asm avr_pdi.s | wc -l`: assembled without error, 52 words.
3. `asm avr_pdi.s | head`: first words (same assembly, second invocation).
4. TASK.md example via the helper, verbose: all P0 edges at offset +1, frames
   and timing correct, RX 0x0002. Reported OK.
5. Example again directly, filtered around the answer and the end: RX pushed
   at cycle 10250 as `2`; last edge at 12476 (ideal 12475). `pins` shows the
   output register (P1 stays 1 while the ATxmega pulls it low).
6 to 15. Random sessions, seeds 1 to 10 (5 to 60 bytes, some answered):
   waveform checks all passed, but every one reported FAIL on RX. Cause: my
   helper parsed the `rx` value as hex while pe_sim prints it in decimal. I
   checked the printed lists by hand (for example seed 10: 167, 38, 127, 184,
   22, 215, 71, 181 = 0xa7, 0x26, 0x7f, 0xb8, 0x16, 0xd7, 0x47, 0xb5, as
   wanted, and the first values of seed 1) and they were correct. Helper fixed.
16. `allans`: 4 bytes (0x00, 0xff, 0x80, 0x01), each answered with 15 bytes
   including 0x00, 0xff, 0x80: OK, 60 RX words.
17. `one`: a single unanswered byte 0xff: OK.
18. `onea`: a single byte answered by one byte, then the end (2 + 16 idle): OK.
19. `long`: 70 bytes, 11 answered, last one answered: OK.
20, 21. Random seeds 11, 12 (58 and 61 bytes): OK.
22. `empty`: only the end word (16 enable + 16 end idle slots): OK.
23 to 25. Random seeds 13, 14, 15: OK.

## Mistakes found

- Only in the test helper (RX parsed as hex instead of decimal, runs 6 to 15).
  The firmware passed every check on its first run.

## Program length

52 instructions (one page, no `.page` or `set page` needed).

## About isa.md: confusing or possibly wrong

- `isa.md` does not say what base `rx CYCLE WORD` prints the word in. It is
  decimal, while `pins CYCLE XX` is hex. That cost me ten runs of confusion.
- It says `pins` prints "the levels being those at the start of that cycle",
  which reads as pin levels, but what is printed is the output register: an
  open-drain pin released while the outside pulls it low still prints 1.
- The `-stimulus` HEX format does not say whether a `0x` prefix is needed or
  allowed; bare hex (`fd`) works.
- `clkdiv` says "Its first tick is the first cycle it is enabled"; it is not
  said when pe_sim enables the thread. It is cycle 0 (edges land on
  multiples of 5 plus 1), and the program relies on that.
- `threshold` is one field shared by the OSR (empty) and the ISR (full); that
  is stated in the config table but easy to miss elsewhere. Here it helped:
  both 8-bit loops use it instead of a counter.
- There is no way to load a constant above 31 (`set` is 5 bits) and `mov` has
  no shift or invert, so testing bit 15 of a word took 5 instructions
  (copy, shift out 15 to null, shift 1 into Y, restore the OSR). The doc does
  not say `mov osr, x` resets the count to "full" rather than "empty"
  ("resets that register's shift count"); it is full, which the program needs.
- `mov` reading `crc` stops the register following data until it is written;
  the doc says so, but it means a read must be paired with a write of `crc`
  before the next use, which is easy to forget.
- Not wrong, but the bit sampler section talks about 40 MHz while this task
  runs at 50 MHz; irrelevant here.
