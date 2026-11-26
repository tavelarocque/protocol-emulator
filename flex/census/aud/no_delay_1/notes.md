# Notes: AUD branch trace receiver

## What I read

- `TASK.md`, in full (one read of 153 lines).
- `isa.md`, in full, in four parts (lines 1-160, 160-320, 320-480, 480-638).
- `pe_sim run x.s -help` output (run 1 below).
- I did not open `pe_sim` (the wrapper script) or `pe_sim.real`, and nothing outside this folder.

## Design

The core runs every cycle at 50 MHz, and AUDCK is 1 MHz, so there are 50 cycles per nibble: timing is easy, and the hard part is register pressure. The previous destination address is 32 bits and the thread has four 16-bit places (X, Y, ISR, OSR), so I keep the previous address in OSR (low half, L) and Y (high half, H), use X as scratch and the ISR to assemble the new half.

Clock edges: `wait 0 pin 0` then `wait 1 pin 0`. The program starts with `wait 0`, so the synchroniser's two cycles of reading 1 after reset cannot be taken for an edge. The wait finishes 2 cycles after the edge on the pin, and the data on P2..P5 is stable from 25 cycles before to 25 cycles after the edge on the pin, so the instruction right after the wait reads it safely.

Telling commands from idle: I do not read nAUDSYNC at all. Outside an address the only nibbles are 0x3 (idle) and 0x8..0xB (commands), so AUDATA3 (P5) alone separates them, and the command gives exactly how many address nibbles follow, so the firmware knows when an address ends without looking at nAUDSYNC. The chip has no `jmp pin` condition, so the branch on P5 is `wait 1 pin 5 timeout` with `timeout = 0` and `timeout_vector` pointing back at the idle loop: if P5 is low the wait expires at once and jumps back to wait for the next edge.

Width dispatch: `in pins, 2` (in_base = 2, so AUDATA1..0), then `in null, 14` so the two bits end up right-justified whatever the ISR's internal layout is, then `mov x, isr`, and a `jmp !x` / `jmp x--` chain to four cases:

- 4 bits: `out null, 4; out x, 12` gives X = L >> 4 before the nibble arrives; at its edge `in pins, 4; in x, 12` builds the new L.
- 8 bits: `out null, 8; out x, 8`, then two nibbles and `in x, 8`.
- 16 bits: four nibbles in a loop.
- 32 bits: four nibbles, saved to OSR; four more, moved to Y; then L is copied back into the ISR through X.

Common tail: `mov osr, isr` (keep new L), `push` (bits 15..0), `in y, 16`, `push` (bits 31..16), back to idle. Both words are pushed 6 to 13 cycles after the rising edge on the pin that carried the last nibble, well inside the 0 to 200 window, and the loop is back waiting for AUDCK low long before the next edge (so back-to-back addresses with no idle work).

Configuration (`run_args.txt`): `-config in_base=2,threshold=16,timeout=0,timeout_vector=1`. No `-mode` flags: all pins stay inputs (the default). threshold is set to 16 because the simulator's default is 8 and I want full 16-bit pushes and shifts. Address 0 is `mov osr, null` (L = 0; Y is 0 at start), address 1 is the idle loop and the timeout vector.

## Program length

57 instructions (`pe_sim asm aud.s` prints 57 words). One page, so no page handling.

## pe_sim runs (22 in total)

1. `pe_sim run x.s -help`: printed the flags (config fields, -cycles, -inputs, -mode, -stimulus, -tx).
2. `pe_sim asm aud.s | wc -l`: 57 words.
3. `pe_sim asm aud.s | head -3`: a128, 2000, 2100 (checked by hand that `mov osr, null` encodes as 0xA128).
4. The example from TASK.md, hand-built stimulus with the first edge at cycle 30: rx 0x1234 @641, 0x0C00 @643, 0x125A @787, 0x0C00 @789, 0x1257 @986, 0x0C00 @988. Last nibble edges were 630, 780, 980, so all correct, latency 6 to 13. Also printed `pins 0 ff` (the output register at reset, no pin is an output).
5-16. Twelve random runs (seeds 1 to 12) from a Python generator I wrote in this folder: 1 to 40 addresses, random widths and values (with some all-ones and all-zero values), gaps of 0 to 20 idles, 4 to 8 idles at the start, 4 at the end, first edge 30 to 79. A checker compared every RX word with the expected address and checked 0 <= push cycle - last nibble edge <= 200 and that no pin changed. All 12 OK, 10 to 70 words each, maximum latency 13.
17. First edge 30, 40 addresses, random widths, all back to back: 80 words OK.
18. Same with first edge 79: 80 words OK.
19. First edge 30, exactly 4 idles, then only 4-bit addresses back to back: 38 words OK, max latency 8.
20. Same with first edge 79: 50 words OK.
21. First edge 55, one address: 2 words OK.
22. First edge 79, random: 28 words OK.

No run failed, so there were no bugs to find. I deleted the generator, the stimulus files and the outputs afterwards so that the folder holds only what TASK.md asks for.

## Mistakes and rule breaks

None that I know of. I ran pe_sim 22 times, under the limit of about 80.

## What was confusing or possibly wrong in isa.md

- The ISR's layout before it holds 16 bits is not stated. `push` is said to send the bits "right-justified", but `mov x, isr` is not described, and with default (right) shifting it is unclear whether a 2-bit `in` leaves the bits at the top or the bottom. I sidestepped it with `in null, 14`.
- Whether `push` after `mov isr, ...` (which resets the shift count) sends 16 bits or 0 bits is not said. I never relied on it: every push follows exactly 16 bits shifted in.
- What an `in` beyond `threshold` does without autopush (saturate, wrap, keep counting) is not said; `pe_sim` defaults threshold to 8, which a reader could easily miss and which would matter for 16-bit pushes. I set threshold to 16.
- The order of the pins within one `in pins, n` is not spelled out (I assumed in_base is the earliest, least significant bit; the tests confirm it).
- `wait ... timeout` with `timeout = 0`: "jumps on the cycle after (with T = 0, at once)" is a little ambiguous about whether the wait spends a cycle first. It did not matter here.
- There is no jump-on-pin condition (PIO has `jmp pin`), so branching on an input needs the timeout trick, which works only for one target per thread because there is one vector.
- `pe_sim run` prints `pins 0 ff` even when every pin is an input; this is the output register, not anything on the pins, which looked at first like the chip driving them.
