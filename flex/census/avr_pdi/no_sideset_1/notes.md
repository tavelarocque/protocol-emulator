# Notes: AVR PDI programmer on the protocol emulator

## What I read

- `TASK.md`, all 190 lines, in one read.
- `isa.md`, all 607 lines, in three reads (lines 1 to 200, 200 to 410, 410 to 607).
- The output of `./pe_sim run x.s -help` (run 1).
- Nothing outside this folder. I did not open the `model/`, `hw/` or `docs/` files the ISA mentions.

## Design

Configuration (`run_args.txt`):
`-config set_base=0,set_count=1,out_base=1,out_count=1,in_base=1,crc_poly=1,timeout_vector=1,timeout=1997 -mode 0=pp -mode 1=od`

Pins are split between the two write paths. `set pins` writes only P0 (the clock), so a clock edge never disturbs the data line. `out pins` and `mov pins` write only P1 (the data), so a data change never disturbs the clock. `in pins, 1` reads P1.

Every slot is 50 cycles, written out by hand with delay fields. Call t the cycle in which `set pins 0` runs; the falling edge shows at t+1, which is exactly `2000 + 50k`, and `set pins 1` runs at t+25 so the rising edge shows at t+26 = `2025 + 50k`. Every path through every slot was counted to exactly 50 cycles, so there is no drift: all edges land on the ideal cycle (0 error, checked by the harness against the exact list of expected edges).

Start-up: the first instruction is `wait 0 pin 0 timeout`. P0 is our own push-pull output and is high, so the wait always expires; with `timeout=1997` and `timeout_vector=1` the next instruction runs at cycle 1998 and the first `set pins 0` at 1999 (found by measurement: the first guess of 1997 was right).

Parity uses the CRC register as a one-bit CRC. With `crc_poly=1` and `crc_init=0`, the rule "if the bit differs from bit 0, shift right and add the polynomial, else only shift" keeps the register at 0 or 1, equal to the XOR of all bits shifted by OUT since the last restart. `mov crc, null` restarts it in the start slot, the eight `out pins, 1` of the data bits feed it, and `mov x, crc` then `mov pins, x` puts the even-parity bit on P1. Reading it stops it following, so the later `out y, 4` does not matter.

Host word decoding: `pull` (one cycle before the start slot's falling edge), `mov isr, osr`, `in null, 15`, `mov x, isr` gives bit 15, which is 1 only for the end word 0x8000. After the 8 data bits have been shifted out, `out y, 4` gives the answer length N (bits 11..8).

Program parts:
- `idle`: one idle slot, repeated X+1 times. At the end, if Y = 0 it goes to `fstart` (next host word), else it sets X = 7 and falls into `samp`. Both exits are exactly on time (the jump to `fstart` lands one cycle early on the `pull`, which is the cycle before the next falling edge).
- `fstart` / `notend`: start slot. Start bit is `mov pins, null` at t+5 (P1 changes 5 cycles after the falling edge, inside the window). On the end word the slot is instead the first of the 16 end slots: X = 14 and back to `idle` with Y = 0; after those 15 slots `idle` goes to `fstart`, whose `pull` stalls forever on the empty FIFO with P0 high and P1 released, so nothing moves after the last rising edge.
- `dbit`: 8 data slots, `out pins, 1` at t+9 (change at falling edge + 9).
- `par`: parity slot, also reads N into Y and builds the constant 129 in the ISR (`in x,1`, `in null,6`, `in x,1`, `in null,8` with X = 1).
- `s10`: first stop bit, `mov pins, x` with X = 1 at t+1. Then X = 0 if N = 0 (one more idle slot, the second stop bit) or X = 129 (130 idle slots: second stop bit, 128 guard slots, the ATxmega's start bit). Clears the ISR.
- `samp`: 8 slots, `in pins, 1` at t+16 (the ATxmega's level changes at t+6 and is seen from t+8 after the synchroniser).
- `post`: the ATxmega's parity slot; `push` (8 bits, right-justified), Y decremented, then X = 2 (stop, stop, next start bit) or, if that was the last answer byte, X = 3 (stop, stop, then the 2 idle slots), then back to `idle`.

Register roles: X loop counter and scratch, Y answer frames left, OSR host word, ISR decoding scratch, constant 129 and the received byte.

## Program length

59 instructions (addresses 0 to 58), all in page 0, so no page handling.

## pe_sim runs

1. `run x.s -help`: printed the flags. The config list includes `sideset_base` and `sideset_count`, which isa.md does not document; I did not use them.
2. `asm avr_pdi.s`: assembled, 59 words.
3. Example session from TASK.md, verbose: first falling edge at 2000, rising at 2025, so `timeout=1997` was right first time.
4. and 5. Same example again, twice in one command (I piped the same run twice to grep different parts; a wasted run). OK, `rx 10253 2`, last edge at 12475 as in TASK.md.
6. Example again after making the harness save the simulator output: OK. Showed `pins` prints the output register (starts `ff`), and the `rx` line format.
7. to 16. Random sessions, seeds 1 to 10. Waveform correct in all; seeds 2 to 10 were reported as RX mismatches, but only because my harness parsed the `rx` value as hex. The simulator prints it in decimal (238 = 0xee). I fixed the harness and re-parsed the saved output of seed 10 without a new run: correct.
17. to 24. example, empty session (only the end word), three bytes each answered with 15 bytes (0x00, 0xFF and mixed), one answered byte, 70 bytes with a final 15-byte answer, seeds 2, 3, 8 again: all OK.
25. to 34. Seeds 11 to 20: all OK.
35. Negative test of the harness: same program with `crc_poly=0`; the harness reported wrong parity bits, so it does check them. `run_args.txt` restored afterwards.

35 runs in all.

The harness `check.py` (kept in the folder) builds a session, the TX file and an ATxmega stimulus (changes at falling edge + 5), runs pe_sim once, and checks: every P0 edge exactly at `2000+50k` / `2025+50k` and no others; every P1 output change inside a chip-sent slot within falling edge + 0..20; P1 level at each rising edge of chip slots equal to the frame bit (start, data LSB first, even parity, two stops); P1 released at the end; RX words equal the answers.

## Mistakes found

- Harness parsed `rx` values as hex; they are decimal. Found from the pattern of mismatches (0x238 vs 0xee). Not a firmware bug.
- Runs 4 and 5 were one wasted duplicate run.

## Confusing or possibly wrong in isa.md

- `pe_sim run -help` lists `sideset_base` and `sideset_count`, but isa.md never describes side-set (no syntax, no encoding bits for it). Either the doc or the tool is out of step.
- `pe_sim run` prints `rx` words in decimal and `pins` values in hex; isa.md does not say which base each uses.
- `in src, count` says bits are shifted "right into the ISR" but does not say explicitly at which bit new bits enter for a 16-bit register, nor that `push` right-justifies only the bits shifted since the last push (it says so, but how the count behaves past 16 bits is not stated). My constant building relies on new bits entering at bit 15; it behaved that way.
- `out pins, count` says "written from `out_base` up" while `mov pins` writes `out_count` pins. It is not stated whether `out pins, n` writes n pins or `out_count` pins. I used n = out_count = 1 so it does not matter here.
- The `wait ... timeout` timing ("stalls for T cycles at most ... jumps on the cycle after") left the exact cycle of the vector's first instruction to measurement: with the wait at cycle 0 and T = 1997, the instruction at the vector ran at cycle 1998.
- The CRC section does not give the bit order for a 1-bit CRC; the update rule stated in prose was enough to use it as a parity accumulator with polynomial 1.

## Rules

I read and wrote only inside the folder. No rule broken that I know of, apart from counting runs 4 and 5 as two runs of the same thing.
