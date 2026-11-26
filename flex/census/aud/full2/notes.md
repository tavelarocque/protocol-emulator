# Notes: AUD branch trace receiver

## What I read

- `TASK.md`, all 153 lines, in one read.
- `isa.md`, all 644 lines, in four parts (1-159, 160-329, 330-489, 490-644).
- `pe_sim run x.s -help` output (run 1 below).

I opened nothing outside this folder. One accidental rule-adjacent thing: my second shell command ran `pe_sim asm` twice in one line (once piped to `wc`, once to `head`), so it counts as two runs; both are listed.

## Design

Config (`run_args.txt`): `-config in_base=2,timeout=0,timeout_vector=0`. No `-mode` flags: every pin stays an input.

The thread keeps the previous destination address in X (bits 15..0) and Y (bits 31..16). It finds each rising edge of AUDCK with `wait 0 pin 0` then `wait 1 pin 0`. Starting with `wait 0` matters: the synchroniser reads every pin high for the first two cycles, which would otherwise look like a clock edge and a command nibble. Everything is read in the synchronised domain, so clock and data have the same 2 cycle delay; data is read at most about 3 cycles after the edge is seen, far inside the 25 cycles it is stable.

In the idle state each edge is classified by AUDATA3 alone: `wait 1 pin 5 timeout` with `timeout = 0` jumps straight to `timeout_vector` (the idle loop) when AUDATA3 is 0, the idle nibble 0x3. Otherwise it is a command 0x8 to 0xB: the thread copies X into the ISR (`in x, 16`), reads the pins with `mov osr, pins`, drops 2 bits and takes AUDATA1..0 into X with `out x, 2`, and branches four ways with `jmp !x` and `jmp x--`. nAUDSYNC is never read: the command nibble says how many nibbles follow, and the sheet guarantees the framing.

Each address nibble is shifted in with `in pins, 4` (P2..P5), using X as the loop counter. Because the ISR shifts right with new bits entering at the top, and it starts as a copy of the old low half, after k nibbles it holds the k new nibbles on top and the old bits 15..4k below. A rotate puts that back in order: `mov x, isr` then `in x, 16 - 4k` (12 for 4 bits, 8 for 8 bits; 16 bits needs no rotate). For 32 bits the first four nibbles give the new low half (parked in Y, since the old high half is being replaced), the next four the new high half, and X and Y are swapped through the OSR. Then `in x, 16; push; in y, 16; push` sends bits 15..0 then 31..16, and the thread returns to idle.

Timing: the words are pushed 8 to 13 cycles after the rising edge on the pin that carries the last nibble (limit is 0 to 200), and the thread is back at its idle `wait` well before the next edge, so a command straight after an address (no idle) is caught.

## Test harness

`gen.py` (left in the folder) builds a stimulus file exactly as the sheet describes (first rising edge at 30..79, at least 4 idles, 0..20 idles between addresses, 4 after, then AUDCK stopped low; 1..40 addresses of random width and value) and checks the `rx` lines: words, order, and that each push lies in [edge, edge + 200]. `gen.py SEED FILE fixed` builds the TASK.md example. The env var FIRST forces the first edge cycle. It is my own model of the sheet, so a misreading of the sheet would be shared by program and checker; the TASK.md example is the independent check.

## pe_sim runs (27 in total)

1. `pe_sim run x.s -help`: listed the flags (config field names, -cycles, -inputs, -mode, -stimulus, -tx).
2. `pe_sim asm aud.s` (first version, fully unrolled, 69+ words): assembly error, jump to `emit` at word 69 in page 1 while PAGE is 0.
3. Same command a second time in the same shell line: same error.
4. `pe_sim asm aud.s` after rewriting the nibble receives as loops: 55 words, assembled.
5. TASK.md example: rx 0x1234 @649, 0x0C00 @651, 0x125A @798, 0x0C00 @800, 0x1257 @996, 0x0C00 @998. All correct, latency 8 to 13 cycles. This also showed that `wait ... pin n` takes an absolute pin number, not one relative to `in_base` (with in_base 2 a relative pin 5 would be P7, held low, and nothing would ever decode).
6. to 25. Twenty random runs, seeds 100 to 119 (2 to 40 addresses each): all OK, every word right, latency 8 to 13 cycles.
26. Seed 730 with first edge forced to cycle 30: OK (8 addresses).
27. Seed 779 with first edge forced to cycle 79: OK (35 addresses).

## Mistakes found

- First version unrolled every nibble receive and did not fit in one 64-word page (found by run 2, the assembler's page check). Rewrote the receives as `jmp x--` loops.

## Program length

55 instructions (one page, start 0).

## Confusing or possibly wrong in isa.md

- `wait pol pin n` does not say whether `n` is absolute or relative to `in_base` (in RP2040 PIO, `wait pin` is relative). The simulator treats it as absolute. The doc should say so.
- The ISR is described as shifting "right" with bits arriving "least significant bit first", and `push` sends the bits "right-justified", but it does not say what `mov dst, isr` returns (raw 16 bits, or right-justified by the count) or what happens to the count past 16. My program relies on `mov x, isr` giving the raw register and on a push after `in x, 16` giving all 16 bits; both hold in the simulator.
- With `timeout = 0`, the text says a timed wait jumps "on the cycle after (with T = 0, at once)". It worked as an immediate conditional branch on a pin, but whether "at once" means in the same cycle is only implied.
- `pe_sim run` has no flag for SYNC_BYPASS; fine here, just noted.
