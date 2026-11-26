# Notes: AVR PDI programmer firmware

## What I read
- TASK.md in full (190 lines).
- isa.md in full (638 lines), read in four parts of about 160 lines each.
- Nothing outside this folder. I wrote only inside it: avr_pdi.s, run_args.txt,
  notes.md, a test helper check.py, and two temporary session files
  (sess_tx.txt, sess_stim.txt) that check.py wrote and that I deleted at the end.

## Design

### Main idea: clkdiv 25, one instruction per half slot
A PDI slot is 50 cycles, low for 25 then high for 25. With `clkdiv=25` every
instruction lasts exactly one half slot, so a slot is exactly two instructions:
the first with `side 0` (PDI_CLK low, "L tick") and the second with `side 1`
(PDI_CLK high, "H tick"). PDI_CLK is P0 driven by side-set (sideset_base 0,
count 1). No delay loops are needed anywhere and the clock can never drift,
because every instruction takes one tick and nothing stalls (the TX FIFO always
holds the next word in the simulator, and RX is drained at once).

P1 (PDI_DATA, open drain) is written only by L-tick instructions (`set pins`,
`out pins`, `mov pins`, with set/out base 1, count 1). An L instruction runs in
the cycle before the falling edge shows, so P1 changes in the same cycle as the
falling edge, which the task allows. H ticks never write P1.

The ATxmega's bits are read with `in pins, 1` (in_base 1) on an H tick, which
runs 24 cycles after the falling edge we produce, i.e. just at the rising edge;
the ATxmega's level (changed at ideal falling edge + 5, seen 2 cycles later
through the synchroniser) has long settled by then.

### Timing offset
The thread starts at cycle 0, so ticks fall on cycles 0, 25, 50, ... and a pin
write shows one cycle later. Every PDI_CLK edge is therefore exactly +1 cycle
from its ideal place (the checker reported offset set {1} on every run). This is
inside the +-2 limit and does not accumulate. With an integer divider there is
no way to shift the tick phase by one cycle, so I accepted the constant +1.

### Parity from the CRC register
With `crc_poly=1, crc_init=0` the CRC rule ("if the bit differs from bit 0,
shift right and add the polynomial, else shift right") keeps the register at
0 or 1 and makes it the XOR of all bits shifted by OUT. So after the 8 `out
pins, 1` of a byte, `mov pins, crc` puts the even-parity bit on P1. Reading the
CRC stops it following the data, so `mov crc, null` restarts it at stop bit 2;
no other OUT runs before the next byte's data bits.

### Words and lookahead
- `autopull=1`, `threshold=8`: the 8th data `out` refills the OSR with the next
  word in the same tick, so no `pull` is needed during a session.
- Answer length of the current word: while its data bits go out, the OSR holds
  `word >> i`. At s1 H `mov isr, osr` (word >> 1), at s2 H `in null, 7` (word >> 8,
  the ISR shifts right with zeros), at s3 H `mov y, isr`: Y = answer length.
- End flag of the next word (bit 15): at s8 H `mov isr, osr`, s9 H `in null, 15`,
  s10 H `mov x, isr`: X = 1 for the end word, 0 otherwise.
- Next frame's start bit is `mov pins, x`: 0 (start bit) for a normal word, 1
  (released, no change at all) for the end word, and the H tick `jmp x-- endp`
  leaves for the end sequence. So that slot is the first of the 16 end slots.

### Schedule (ticks)
- Before slot 0: `wait 0 pin 0 timeout` with P0 high times out after
  timeout + 1 = 75 ticks and jumps (timeout_vector 1) to `pre`, then 5
  instructions (pull, end flag of the first word, `set y, 15`) make 80 ticks, so
  slot 0's L tick runs at cycle 2000.
- Enable: `en: nop side 0 / jmp y-- en side 1`, 16 slots.
- Frame: 24 instructions, unrolled (s0..s11 as above), ending at s11 H with
  `jmp !y nf` (no answer: next frame or end).
- Guard (answer case): `set x, 31` on guard slot 1 L, then a loop of 8 ticks
  that starts on an H tick and ends with `jmp x-- g` on an L tick: 1 + 32 * 8 =
  257 ticks, i.e. the 128 guard slots plus the L tick of the answer's first start
  bit slot. Y (answer length) is untouched.
- Answer: start-bit H resets the ISR; data slot 1 L does `jmp y-- ai` (counts
  the byte); `ai: in pins, 1 (H) / jmp !isrf ai (L)` takes 8 bits and falls out
  at the parity slot's L; `push` on parity H. Stop 1 L sets X = 0, then the next
  word's end flag is recomputed into the ISR during the stop slots. At the next
  slot's L, `jmp x!=y ash` goes to the next byte's start-bit H while Y != 0;
  otherwise this is idle 1: X = end flag, idle 2, `jmp nf` on idle 2 H.
- End: `endp` on end slot 2 L, a loop that runs to the L tick of end slot 16,
  then `hang: jmp hang side 1` keeps P0 high and P1 released forever.

### Registers
X: end flag / guard counter / 0 for the compare. Y: answer length, then bytes
left. OSR: current word, then the next word. ISR: scratch for shifts, then the
received byte. CRC: parity.

## run_args.txt
`-config clkdiv=25,sideset_base=0,sideset_count=1,set_base=1,set_count=1,out_base=1,out_count=1,in_base=1,threshold=8,autopull=1,crc_poly=1,crc_init=0,timeout=74,timeout_vector=1 -mode 0=pp -mode 1=od`

## Test helper
check.py builds a session (given bytes and answers, or random valid PDI
instructions: LDS, STS, LD, ST, LDCS, STCS, REPEAT, KEY, 60+ bytes), writes the
TX words and an ATxmega stimulus (changes at ideal falling edge + 5), runs
`pe_sim run avr_pdi.s -tx -stimulus -cycles N` with run_args.txt (N = 3000
after the falling edge following the last slot), and checks: number of PDI_CLK
edges equals 2 * slots, each edge within +-2 of its ideal cycle, every P1
change inside a chip-sent slot between its falling edge and 5 cycles before its
rising edge, P1's level at each rising edge equals the frame bit, P2..P7 never
written, and RX words equal the answers. Each check.py call is one pe_sim run.

## pe_sim runs (15 in all)
1. `./pe_sim run -help`: lists the flags and -config keys.
2. `./pe_sim asm avr_pdi.s`: assembled, 58 words, no errors.
3. check.py, TASK.md example (80/02; C1,59) with timeout=73: every edge exactly
   24 cycles early (offset -24): the wait took 74 ticks, one tick short. This
   showed the thread starts at cycle 0 and that the timed wait lasts
   timeout + 1 ticks. Waveform otherwise consistent, RX right.
4. Example again with timeout=74: PASS, edge offset +1 everywhere.
5. random:1: waveform PASS, but RX reported wrong.
6. random:2: same.
7. random:3: same. Cause: my checker parsed pe_sim's `rx` value as hex, but it
   is printed in decimal (in run 4 the value 2 looks the same either way). I
   checked offline that every reported value read as decimal equals the expected
   byte, then fixed the parser. The firmware was right in runs 5 to 7.
8. Edge cases: LD answered with 15 bytes (FF, 00, AA, ...), LDCS answered 00,
   a lone 00 byte, a lone FF byte, and an answered instruction as the last before
   the end word: PASS.
9. random:4: PASS.
10. Example with the ATxmega line held low from cycle 0 to 1500: PASS, so
    `wait 0 pin 0` reads absolute pin P0 (our own clock output), not
    in_base + 0, and the pre-delay does not depend on P1.
11. Empty session (only 0x8000): PASS (32 idle slots, no P1 change).
12. random:5: PASS.
13. random:6: PASS.
14. random:7: PASS.
15. random:8: PASS (76 answer bytes).

## Mistakes found
- Pre-delay one tick short (run 3), fixed by timeout 73 -> 74.
- Checker bug (decimal RX), runs 5 to 7; firmware unaffected.

## Program length
58 instructions (one page, words 0 to 57).

## Confusing or possibly wrong in isa.md
- `wait pol pin n`: isa.md does not say whether n is an absolute pin or relative
  to in_base. Run 10 indicates it is absolute.
- The timed wait: "stalls for T cycles at most, and if the pin is still wrong,
  jumps on the cycle after". With clkdiv 25 the whole instruction took T + 1
  ticks before the target ran (not T + 2, as "T stalls then a jump on the cycle
  after" could be read). Counting the first stalled tick as one of the T would
  explain it, but the text is ambiguous.
- `mov` from ISR/OSR: isa.md does not say that it gives the raw 16-bit value
  (as opposed to something right-justified like push). My count and flag
  extraction rely on raw values and work, so it is raw.
- The `rx` lines of `pe_sim run` print the word in decimal while `pins` lines
  print hex; isa.md does not say which.
- isa.md says a pin write by the instruction of cycle c shows as `pins c+1`; with
  a clock divider this means edges land 1 cycle after a multiple of clkdiv, so a
  divided thread can never place an edge on a multiple of its divider. Not
  wrong, but worth stating.
- No rules were broken that I know of.
