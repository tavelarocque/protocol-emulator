# Notes: AUD branch trace receiver (aud.s)

## What I read
- `TASK.md`, all 153 lines, in one read.
- `isa.md`, all 638 lines, in four parts (lines 1-160, 160-329, 330-489, 490-638).
- The output of `./pe_sim run -help` (run 1).
- I did not open `pe_sim` or `pe_sim.real` as files, and nothing outside this folder. No rule was broken as far as I know.

## Design
Thread 0, `-config in_base=2,threshold=16`, no `-mode` flags (all pins stay inputs). With `in_base=2`, `in pins, 4` takes P2..P5, which is AUDATA0..3 with AUDATA0 lowest.

Clock edges are found with `wait 0 pin 0` followed by `wait 1 pin 0`. Starting with `wait 0` also skips the two reset cycles in which the synchroniser reads every pin high, so no false edge is seen before the first real one (the pin is low from cycle 0, so the synchronised level falls in cycle 2). The wait finishes 2 cycles after the pin's rising edge, and the data stays stable for about 23 more cycles as the thread sees it, so all reads are done within a few cycles of the edge. Every path returns to `wait 0 pin 0` well under 25 cycles after the edge, so no edge is ever missed.

Registers between addresses: the ISR holds the low half L of the previous destination address with its shift count reset to 0, Y holds the high half H. X and OSR are scratch. At start X, Y and ISR are 0, which is the "previous address 0" the sheet asks for.

Dispatch on an edge: `mov osr, pins`, drop 5 bits, `out x, 1` gives AUDATA3, which is 0 for the idle nibble 0x3 and 1 for every command 0x8..0xB. For a command the pins are read again into the OSR and AUDATA0 then AUDATA1 are tested with `jmp !x`, giving four paths. nAUDSYNC is never read: after a command the firmware knows how many data nibbles follow, and the sheet guarantees only idle and command nibbles appear with nAUDSYNC high.

The ISR shifts right, so each `in` puts its bits at the top and the nibbles, sent least significant first, land in place after 16 bits:
- 16 bits: clear ISR, 4 nibbles (loop on X), X = ISR.
- 32 bits: clear ISR, 4 nibbles, park the new L in OSR, clear ISR, 4 nibbles, Y = ISR, X = OSR.
- 8 bits: ISR = L. Two nibbles leave n1 n0 L[15:8] (top to bottom); `mov x, isr; in x, 8` shifts L[15:8] in again, which rotates the register to L[15:8] n1 n0.
- 4 bits: one nibble leaves n L[15:4]; `mov x, isr; in x, 12` rotates it to L[15:4] n.
Then a common tail (`emit`): `mov isr, null; in x, 16; push; in y, 16; push; mov isr, x`. The `in x, 16` is needed because a `push` right after `mov isr, x` pushes the zero bits counted since the write (run 2). The tail leaves ISR = L with a count of 0 for the next address.

Timing: both words are pushed 9 to 12 cycles after the pin edge that carries the last nibble (limit 0 to 200), measured by the checker over all test runs.

## Program length
61 instructions (`./pe_sim asm aud.s` prints 61 words), all in page 0, so no page handling is needed.

## pe_sim runs (23 in total)
1. `./pe_sim run -help`: flag list (config field names, -stimulus format).
2. `t1.s`, a probe of ISR behaviour, `-inputs 0x28`, in_base=2, threshold=16. Showed: (a) `mov x, isr` reads the raw ISR, not right-justified (the first `in pins, 4` read 0xF because of the reset-time synchroniser highs, giving 0xF000); (b) `push` right after `mov isr, x` pushes 0, since the count was reset; (c) `in` keeps shifting past the threshold without autopush, and `push` then gives all 16 bits (24 bits of 0xA gave 0xAAAA); (d) after a push, 4 bits in read back as 0xA000, so new bits enter at bit 15; (e) `mov osr, pins` + `out null, 5` + `out x, 1` gives P5.
3. `./pe_sim asm aud.s`: assembles, 61 words.
4. Random trace seed 1 (5 addresses) through `gen.py`/`check.py`: OK, worst latency 11.
5-16. Random traces, seeds 2-13 (6 to 35 addresses each): all OK, worst latency 12.
17. Seed 20, first edge at cycle 30: OK.
18. Seed 21, 40 addresses, first edge at 79, mostly back-to-back addresses: OK.
19-20. Seeds 22, 23, gaps mostly 0 (back-to-back commands): OK.
21. Seed 24, 40 addresses, first edge 79: OK.
22. Seed 25, first edge 30: OK.
23. The worked example from TASK.md (first edge at 55): RX words 0x1234 0x0C00 0x125A 0x0C00 0x1257 0x0C00, pushed 9 and 11 cycles after the last-nibble edge. Matches the sheet.

Test tools: `gen.py` writes a stimulus as TASK.md describes it (idle from cycle 0, first edge 30..79, 50-cycle period, data changing with the falling edge, at least 4 leading idles, 0 to 20 idles between addresses, all four widths with random, all-ones and zero values, 4 trailing idles, clock stopped low, cycles = last change + 1000) and the expected words with the cycle of each address's last-nibble edge. `check.py` compares the `rx` lines with those words and checks each push lies in [edge, edge + 200]. The generated stimulus/output files were deleted after use; `gen.py`, `check.py` and `t1.s` are left in the folder. These are my own model of the target, not the logic analyser's decoder, so a misreading of the sheet would be shared by both; the TASK.md example (run 23) is the one independent check.

## Mistakes found
None in the firmware during testing. The one thing I designed around before writing it was the `push` after a `mov isr`, confirmed by run 2.

## What was confusing or possibly wrong in isa.md
- `in` says it "shifts `count` bits right into the ISR" and "bits arrive least significant bit first", but not where new bits enter. Run 2 shows they enter at bit 15 (PIO style). Worth saying outright.
- It is not stated what `mov x, isr` returns when fewer than 16 bits have been shifted in: `push` right-justifies by the count, but `mov` returns the raw register. The difference matters for any firmware that mixes the two.
- `push` sends "the bits shifted in since the last push", but a `mov isr, ...` also resets that count, so `mov isr, x; push` pushes 0, not X. Implied by "Writing isr resets that register's shift count" but easy to miss.
- What `in` does once the count reaches `threshold` with autopush off (keeps shifting, count presumably saturates) is not stated.
- `pe_sim run` prints `pins 0 ff` even when every pin is an input; that line is the output register, not the pin levels, which could be misread.
