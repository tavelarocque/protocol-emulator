# Notes: SWIM host firmware

## What I read

- TASK.md, in full.
- isa.md, in full.
- `pe_sim run -help` (run 1 below).

Nothing outside this folder was opened.

## pe_sim runs

1. `./pe_sim run -help`: lists flags `-config` (start out_base out_count set_base set_count in_base threshold timeout_vector timeout sideset_base sideset_count clkdiv out_msb_first in_msb_first autopull autopush crc_poly crc_init crc_invert crc_in), `-cycles`, `-inputs`, `-mode`, `-stimulus`, `-tx`.
2. `./pe_sim asm t/p1.s` (probe program, first 3 words shown): `set pins,0` = 0xc000, `set pins,1` = 0xc001, `wait 0 pin 0` = 0x2000. Assembler works.
3. `run t/p1.s` (clkdiv 1, P0 od, stimulus low 100..109): first instruction runs in cycle 0 (its write shows as `pins 1`); `wait 0 pin 0` on a stimulus fall at 100 completes in cycle 102 (next write shows at 104), as isa.md says (2-cycle synchroniser). The chip's own low drive is read back at once, and after the chip releases P0 a `wait 1 pin 0` passes at once (own output is not seen through the synchroniser). The three `rx` words were 0: my mistake, `mov isr, crc` resets the ISR shift count, so `push` pushed zero bits.
4. `run t/p2.s ... -inputs FF`: crashed, `Int.of_string "FF"`. `-inputs` wants `0xFF` (isa.md says `-inputs HEX`; the stimulus file accepts bare hex like `FE`, the flag does not).
5. Same with `-inputs 0xFF`, `crc_poly=1`: CRC bit 0 is the running parity of the first bit of every OUT (out x / out null / out pins all count): parities 1,1,0 as expected, and a 4-bit `out null,4` counts only its first bit. `mov crc, null` restarts it and it follows again.
6. `./pe_sim asm swim.s`: assembles, 191 words (176 instructions plus `.align` padding). The assembler accepted `set page, n` followed by a `jmp` to a label in page n, and needed a `.page n` line after such a pair before jumps back into the listing's own page.
7. Harness, scenario sc1 = the TASK.md example (SRST; WOTF 0xA0 to 0x007F80; ROTF 2 bytes from 0x004800, target sends 0x12, 0xFE), no NACKs: PASS. E = 651, last entry rise 241291 = E + 240640, all 214 frame edges matched, worst offset +1 cycle, rx 0x12, 0xFE.
8. sc2: SRST NACKed twice; WOTF of 6 bytes, command NACKed once, bytes NACKed 0,2,1,0,2,0 times; ROTF of 7 bytes (command NACKed once); WOTF of 1 byte to 0x000000 (command and byte each NACKed twice); ROTF of 1 byte at 0x010001 (command NACKed twice): PASS, 746 edges, worst +1, 8 rx words right. This also showed the simulator's RX FIFO does not fill up (7 pushes in a row, no stall).
9. sc3: WOTF of 255 random bytes with random 0/1/2 NACKs, ROTF of 255 random bytes, SRST NACKed once (1,119,750 cycles): PASS, 8500 edges, worst +1, 255 rx words right.
10. to 12. sc11, sc12, sc13: random runs of 4, 4 and 3 operations (random kinds, N in {1,2,3,4,5,9,17}, random addresses, data and NACK counts): all PASS, worst offset +1 cycle.

Total: 12 runs of pe_sim (1 help, 1 asm of a probe, 3 probe runs of which one crashed on a bad flag, 1 asm of swim.s, 6 full tests).

## Test harness (deleted before hand-in)

I wrote `t/harness.py` (Python) in a subfolder here. From a scenario (ops, NACK counts, bytes the target returns) it built the TX word file and the target's stimulus file (sync frame 250000..250640, the target's ACK/NACK bits and data frames, each frame 220 cycles after the previous acknowledge bit), ran `pe_sim run swim.s -tx ... -stimulus ... -cycles N` plus `run_args.txt`, with N = 4400 after the place of the next frame, then checked: the 18 entry edges against the limits in TASK.md (E in 400..4000, first rise +-2 of E+640, falls +-2 and rises +-1 from the previous actual rise); every later chip edge against the timetable (+-2 cycles, same count, so no extra edges and the line released to the end); no chip low overlapping a target low; the rx words. It did not run sigrok itself. I deleted `t/` (harness, probes, scenario files) so the folder holds only what TASK.md asks for.

## Design

Config: `clkdiv=5,out_msb_first=1,in_msb_first=1,threshold=16,crc_poly=1`, P0 open-drain. With clkdiv 5 one thread tick is one SWIM clock (5 cycles) and ticks fall on cycles 5k (the thread's first tick is cycle 0), so a write in tick k shows on P0 at 5k+1. Every time in the task is a multiple of 5 cycles, so every chip edge lands exactly 1 cycle after its nominal place, inside the +-2 limit, and relative times in the entry sequence are exact. A bit is 22 ticks: `set pins,0` at t, `out pins,1` at t+2 writes the bit value (a 0 just stays low), `set pins,1` at t+20. That makes the bit loop 4 instructions with no branch on the bit value.

Entry sequence: fall in tick 130 (cycle 651), rise 128 ticks later; then two loops of four pulses, each half period a nested X/Y delay loop whose lengths are counted exactly (3997/3999 ticks and 1996/1999 ticks plus the loop overhead). The pulse counter is the OSR shift count: `out null,4` per pulse and `jmp !osre` until 16. Then `wait 0 pin 0`, `wait 1 pin 0` on the synchronisation frame (the rise is seen in tick 50129). That is the only time the program waits on the line: from there every frame and every sample is placed by counting ticks, since the target is exactly on the timetable. Every path between two frames (ACK, NACK, SRST done, more bytes, last byte, ROTF/WOTF branch) was padded with delay fields so it reaches the next frame's tick exactly; the tick of each instruction is written in the comments of `swim.s`.

Frames: the payload goes into the OSR right-justified so the bit before it is a 0, and an `out null` skip leaves exactly the start bit and the payload: `out null,4` on the command word sends bits 11..8 = start 0, 0, c1, c0 (a counted loop of 4, since the command word's own bits 7..0 follow); for a byte, `out null,7` on 0x00bb sends bit 8 (start 0) and bits 7..0, and the loop runs `jmp !osre` until 16 bits are gone, with threshold 16. Parity: `mov crc, null` restarts the CRC register before each frame; with poly 1 and init 0 its bit 0 is the XOR of the first bit of every OUT, the skip's first bit and the start bit are both 0, so after the payload `mov pins, crc` writes the parity bit straight to P0.

Acknowledge bits from the target are sampled 11 ticks (55 cycles) after they start: `mov osr, pins`, `out null,15`, `out x,1` puts P0 in X and `jmp !x` branches (there is no jump-on-pin, and the OSR is free between frames). A NACK sends the same frame again 220 cycles after the NACK started: the command frame is rebuilt from the command word kept in Y, a WOTF data byte from the copy kept in the ISR. N and address frames are not checked, as TASK.md says they are never NACKed.

Operation flow: `pull` the command word into Y (stalls with P0 released when the words run out); command frame; if Y = 0 it was SRST and the next operation starts; else the N frame (from Y), address word 1 (byte frame), address word 2 kept in the ISR for two byte frames; then bit 9 of Y picks ROTF or WOTF and Y becomes N-1 as the byte counter (`jmp y--`). WOTF: pull, send, check ACK per byte. ROTF: per target frame sample the 8 data bits at the middle of each bit (`in pins,1`, MSB first) into the ISR, `push`, then drive the chip's ACK (low 2 ticks) at frame start + 1100 cycles.

Layout: page 0 entry sequence and ROTF receive, page 1 command, N and first address frame, page 2 the other two address frames and WOTF data; page changes by `set page, n` + `jmp`, inside the delay padding.

## Program length

176 instructions (191 words of program memory including 15 `nop`s that `.align` puts at page ends; pages 0/1/2 hold 54/59/63 instructions).

## Confusing or possibly wrong in isa.md

- `-inputs HEX` needs a `0x` prefix (`-inputs FF` crashes with `Int.of_string`), while the stimulus file takes bare hex such as `FE`. isa.md calls both HEX.
- Nothing in isa.md or TASK.md says whether the simulator drains the RX FIFO; a ROTF of more than 4 bytes depends on it. In my runs it never stalled (255 pushes in a row).
- `mov isr, x` (or any write of the ISR) resets the shift count, so a following `push` pushes zero bits. isa.md does say writes reset the count, but it is easy to miss that `push` then sends nothing; it cost me a probe run.
- There is no jump on a pin level; a pin can only be tested by copying it into X or Y (I used `mov osr, pins` then `out null,15` / `out x,1`) or through a wait timeout and its single global vector.
- isa.md says the CRC takes "the first bit that instruction shifted" from every OUT, including `out null`; that is true (probe run 5) and is worth stating more loudly, because skip instructions feed the CRC too.
- I did not find anything in isa.md that the simulator contradicted, for the features I used (timing, synchroniser delay, own readback, clkdiv ticks, paging, CRC).

## Rules

I read and wrote only inside this folder. I used no em-dashes. No rule was broken that I know of.
