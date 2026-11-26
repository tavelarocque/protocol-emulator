# Notes: CAN FD transmitter for the protocol emulator

## What I read

- `TASK.md`, all of it (twice: once at the start, once again after my working context was cut short and summarised).
- `isa.md`, all of it (also read again in parts after the summary: the CRC section, the per-thread configuration table, `in`/`out`/`push`/`mov`, the encoding, the assembler syntax and the page rules).
- The help text that `pe_sim` prints (runs 1, 2, 6 and 7 below), which lists the `-config` keys.
- Nothing outside this folder. My only other files are my own, in `t/` (test programs, a Python reference model and test drivers, and their outputs).

## pe_sim runs

I counted every invocation of `pe_sim`, assembler and help included. There were 39 in all.

1. `pe_sim run ... -help`: the run options and the `-config` keys (start, out_base, out_count, set_base, set_count, in_base, threshold, timeout_vector, timeout, sideset_base, sideset_count, clkdiv, out_msb_first, in_msb_first, autopull, autopush, crc_poly, crc_init, crc_invert, crc_in). There are no keys for the bit sampler or the packet buffer.
2. Bare `pe_sim`: the list of subcommands.
3. `t/t1.s`: wait timing. A `wait ... timeout` that expires with `timeout = T` runs the vector instruction at (cycle of the wait) + T + 1. A wait that passes takes 1 cycle. A pin write by the instruction in cycle c shows at c + 1. My CRC checks in the same program all pushed 0. That was my mistake: `mov isr, x` then `push` sends 0 bits, as `isa.md` says. I fixed it by using `in x, 16` then `push`.
4. `t/t2.s`: with `crc_poly=0x8000`, `crc_init=0`, `crc_in=1`, the instruction `in x, 12` with X = 1 gave CRC 0x8000. So the CRC takes bit 0 of the source. With X = 0x0800 it gave 0, and `in pins, 12` with P0 = 0 also gave 0. `mov osr, pins` followed by `out` gave the pin byte (254). `mov osr, osr` resets the shift count.
5. `t/t3.s`: `in pins, 12` with P0 = 1 and P3 = 0 gave 32768, so it feeds P0. After a first `mov x, crc`, an `in` did not change the second read, which was 0: the register really stops following the data. `mov pins, x` with `out_count=8` writes all eight pins. `set pins` with `set_count=4` wrote 01. `out pins, 1` from an empty OSR wrote 00; this does not show whether other pins are written.
6. Bare `pe_sim` again (the subcommand list; a wasted run).
7. `pe_sim asm -help`.
8. `pe_sim asm can_fd.s`: assembled without error into 254 words. I checked the label addresses with `t/labels.py` (LOOP = 11, START = 209; F ends at 191, so C0S lands on 192).
9. The `TASK.md` example (ID 0x020, BRS 1, DLC 1, data 0xF0, acknowledged): all 28 changes of P0 at exactly the cycles in the table. The model gives CRC 0x05DE7 and stuff count 3. One word, 1, was pushed at cycle 5003.
10. A hand-picked run of 6 frames: the example; the `TASK.md` extended frame 0x1ABCDE12 with BRS 0, DLC 3, not acknowledged; extended, all zeros, DLC 10 (30 stuff bits); base with BRS 0, DLC 9, all 0xFF; extended DLC 0, not acknowledged; base DLC 8 with stuff-heavy data, not acknowledged. Result: OK (every edge within 1 cycle, actually exact, the right edge count, and the right words in the right windows).
11. to 22. Twelve runs of 1 to 6 random frames (`t/batch.py 1 12`): all OK.
23. to 26. Four runs of 6 frames with data and identifiers biased towards long runs (`t/stress.py 7 4`): all OK. Between them they cover all eight stuff counts mod 8 (up to 18 stuff bits in one frame).
27. A run chosen so that dynamic stuff bits fall exactly on my segment boundaries: the end of the base header chunk, the end of the extended header chunk, the end of the second identifier word, the end of a data word, plus a frame whose last data bit ends a run of five (stuff suppressed). Result: OK. A stuff bit right after BRS, or right after the DLC with data following, cannot happen (res = 0 and ESI = 0 break the runs).
28. to 30. Three more stress runs (`t/stress.py 11 3`): all OK.
31. to 33. Three more random runs (`t/batch.py 5 3`): all OK.
34. A first attempt at worst-case stuffing. My greedy data generator was poor and the frames reached 28 to 31 stuff bits: OK.
35. A second attempt, also weak (26 to 30 stuff bits): OK. I stopped there: the counter cannot fail with more stuff bits, see the design.
36. to 39. Four more random runs (`t/batch.py 99 4`): all OK.

The checker (`t/model.py`) builds the ideal bit stream from `TASK.md` independently of the firmware. It covers SOF, the identifier fields, dynamic stuffing (with no stuff bit after the last data bit), the fixed stuff bit, the Gray stuff count and parity, CRC-17 from 0x10000, and the fixed stuff bits in the CRC. It also lays out the bit times: nominal 100, BRS 85, data rate 25, CRC delimiter 40 or 100, ACK, error flag, EOF and the 300-cycle intermission. It writes the TX words and the stimulus (the receiver pulls the line low for every acknowledged ACK slot), and runs `pe_sim` with `run_args.txt`. It then compares every P0 change (count and cycle, within 1) and every pushed word (value, and that it lands between the ACK slot start and the frame end). In every passing run all edges were exact, not just within 1.

## Design

Program length: **247 instructions**, occupying 254 words of memory. The other 7 words are `nop` padding that never runs: 6 come from `.align` and 1 places the CRC slot code so that it ends exactly at the page 2/3 boundary.

Configuration (`run_args.txt`): `start=209`, `timeout_vector=11` (LOOP), `timeout=75`, `out_base=0`, `out_count=8`, `set_base=0`, `set_count=1`, `in_base=0`, `threshold=16`, `out_msb_first=1`, `crc_in=1`, `crc_poly=0x1B42D`, `crc_init=1`. Pin modes: P0 open-drain, P1 to P7 push-pull. P1 to P7 are only used as storage; the test ignores them.

- **CRC**: the hardware CRC register, fed by every IN (`crc_in`). The polynomial 0x1685B (with the x^17 term) is written low power first, which gives 0x1B42D. The ISO start value 0x10000 becomes `crc_init` = 1. Every bit on the line from SOF to the parity bit is fed by exactly one IN, whose source has that bit in bit 0. All other INs happen either before the `mov crc, null` that restarts the register at SOF, or after the CRC has been read. A first read gives CRC bits 16..1, with bit 16 (sent first) in bit 0. A second read gives CRC bit 0.
- **Pins as storage**: P1 is the rate flag (1 = nominal). P7..P2 hold the dynamic stuff counter, which starts at 63 and loses 1 per stuff bit (`mov x, pins`, four `jmp x--`, `mov pins, x`). Its low 3 bits are then 7 - (count mod 8). It cannot underflow: at most about 42 stuff bits fit in a frame, and even a wrap would leave the low 3 bits right.
- **One bit loop for every dynamically stuffed bit**, header and data, at both rates. A slot writes the line at offset 5 and lasts 25 cycles. At its end, `wait 0 pin 1 timeout` (W) passes at once at the data rate, or adds exactly 75 cycles at the nominal rate. Its timeout vector is LOOP, the instruction after it.
  - The OSR holds the current segment, most significant bit first. Its emptiness (threshold 16) ends the segment.
  - The ISR is the run detector. Its count is 11 + the length of the current run: a new run starts with `mov isr, null` and then `in null, 12` or `in pins, 12`, and each repeat adds `in x, 1`. When it is full, the next slot is a stuff bit. Its value is 0 exactly when the run is of zeros, which tells the loop the previous level.
  - The stuff bit is written with `set pins`, and the counter is then decremented.
  - When a segment ends, a dispatcher runs inside the same slot. In the data phase (Y = number of bytes still to load) it `pull`s the next word, or does the one-byte trick for an odd last byte (`out x, 8`, `mov osr, x`, `out null, 8`), or goes to the CRC field.
  - In the header phase, Y is a control word: bits 15..12 are the RRS/IDE, FDF, res, BRS segment [0 1 0 BRS], bits 11..8 the DLC, and bits 1..0 a step counter k (3 or 2). Its bit 14 is always 1, which is how the loop tells the phases apart.
  - The header dispatcher (page 1) times itself to the slot end. For an extended frame it pulls the second identifier word. Next it loads the 4-bit [0 1 0 BRS] segment. After BRS it clears P1 if BRS = 1 and ends that slot at 85 cycles, or at 100 if BRS = 0. It also loads the [ESI DLC] segment and sets Y to the byte count (DLC 9 gives 12, DLC 10 gives 16).
- **Header segments**, composed in the ISR during setup, where these INs do not matter because the CRC is restarted afterwards:
  - base: [SOF ID10..0 RRS] (13 bits), then [IDE FDF res BRS];
  - extended: [SOF ID28..18 SRR IDE ID17 ID16] (16 bits), then the second identifier word as it comes, then [RRS FDF res BRS].
- **CRC field** (pages 2 and 3): all slots write at offset 2, and a slot is 20 + 5 (Y + 1) cycles, with Y = 0 at the data rate and 15 at the nominal rate.
  - The fixed stuff bits are the previous level inverted: `mov x, pins`, `jmp x--`, `mov pins, x`, since a decrement always flips bit 0.
  - The Gray code and parity come from a 3-level tree on the snapshot of the counter. The 4 bits go out of the OSR and are fed to the CRC with `in x, 1`.
  - The CRC is then read into the ISR and sent least significant bit first with `mov pins, isr` / `in null, 1`, with a fixed stuff bit every four. A second read gives CRC bit 0.
- **ACK and the rest**: the CRC delimiter lasts 4 (Y + 1) + 36 cycles, so 40 or 100. The line is sampled at ACK + 50 with `mov x, pins`; P1..P7 are 0 there. `jmp x--` turns the sample into the word to push (1 when acknowledged) with `in x, 1` / `push`. A missing acknowledgement gives the 6-bit error flag. Fixed delays then lead to the setup of the next frame, which starts 52 cycles before its SOF. The first SOF is at cycle 2000.

## Mistakes I made and found

- Run 3: I used `mov isr, x` then `push` to report CRC values and got 0. `isa.md` says this explicitly; I had missed it.
- Design: my first layout was over 256 words and did not fit the 64-word pages. I found this by counting before assembling, not with a run. I shrank it by moving the header state into the top bits of Y, sharing the CRC fixed-stuff slot tail, removing a CRC re-read path, and similar changes.
- Design: in my first draft the dispatcher was `jmp !y PHC` followed by a `jmp DD`, which cost a cycle. I caught it while checking cycle counts and reordered the code so it falls through.
- Runs 34 and 35: my worst-case stuffing generator did not produce the worst case. This was only a test-quality problem.
- Rules: I invoked bare `pe_sim` twice (runs 2 and 6); the second was wasted. During the work, the environment showed me, unasked, an unrelated project-instruction file from outside this folder. I did not open, follow or use it, and I mention it only because it appeared. I broke no rule on purpose, and I know of none I broke by accident.

## Confusing or possibly wrong in isa.md

- "The CRC register takes one bit from every OUT ... (or every IN, with crc_in): the first bit that instruction shifted." For a multi-bit IN or OUT it does not say which bit is "first". I measured bit 0 of the source for IN with the default (right) shift (runs 4 and 5). I did not check the left-shift or OUT cases.
- The text says the CRC follows "every IN, with crc_in" but does not say plainly that OUT then stops feeding it. My frames only come out right if OUT does not feed it, so that is how the simulator behaves.
- `out pins, n`: "written from out_base up" does not say whether n pins are written or `out_count` pins. I avoided relying on it.
- `wait ... timeout`: "stalls for T cycles at most, and if the pin is still wrong, jumps on the cycle after". I read this as the vector instruction running T + 1 cycles after the wait started, and run 3 confirmed it. A sentence giving the cycle of the vector instruction directly would help.
- Pages: the assembler follows `set page` down the listing. So every `set page, n` / `jmp` pair to another page needs a `.page` line after it, before the code that is reached with the old page. The text implies this but it is easy to miss. The rule that `.align` pads with `nop`s also means code cannot simply fall through a page end that `.align` padded. I had to pad the start of a page so that a slot loop ended exactly at the page boundary.
- Reading pins: "Reading pins gives all 8 pin levels" together with "a thread's own output, read back on a push-pull or open-drain pin, is never delayed". For an open-drain pin that has just been released (output 1), the level is the external one, which goes through the synchroniser. It is not stated whether such a read-back is delayed. It did not matter here, because the line was already high.
- `isa.md` describes the bit sampler, the packet buffer and CHAIN, but `pe_sim run` has no options for them. I am not sure whether that is intended; I did not need them.
- `push` clears the ISR, and a write of `isr` resets the count but keeps the value. I relied on `push` leaving an empty ISR at the start of setup. That worked, but the text only says "then clears the ISR".
