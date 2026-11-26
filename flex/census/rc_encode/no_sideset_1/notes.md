# Notes: PT2262 encoder on the protocol emulator

## What I read

- `TASK.md`, in full (137 lines, one read).
- `isa.md`, in full, in four parts (lines 1-160, 160-320, 320-470, 470-607).
- The help text of `pe_sim run` (run 1 below).
- Nothing outside this folder. I did not open `pe_sim` or `pe_sim.real` as text.

## Design

Configuration (`run_args.txt`): `-config clkdiv=400,autopull=1,threshold=12 -mode 0=pp`.

- `clkdiv=400` makes one thread tick exactly one alpha (40 us). Every time
  in the protocol is a whole number of alpha, and every edge is written by
  one `set pins` or `mov pins` whose tick is fixed by the listing, so every
  edge lands exactly where it belongs (zero error, measured) and errors cannot
  add up. All edges appear at cycle 400k + 1; only offsets matter.
- `threshold=12` with `autopull`: each host word carries 12 useful bits (6
  trits), so the OSR counts as empty after 6 trits and refills from the TX
  FIFO in the same tick as the `out` that empties it. No `pull` instruction
  and no gap. Bits 15..12 are never shifted out.
- Each trit is read with `out x, 2`, so X = 0 ('0'), 1 ('1') or 2 ('f').
  Every pulse cycle is: rise at 0, a "middle" level for alpha 4..11, fall at
  12. The middle level is 1 for a long pulse cycle and 0 for a short one. So:
  - pulse cycle 1 is long only for '1': middle level = bit 0 of X, written
    with `mov pins, x` (out_count 1, so only P0, bit 0);
  - pulse cycle 2 is long for '1' and 'f', that is X != 0: done with
    `jmp !x short` and two branch paths of equal length (8 ticks each).
- Y counts the 12 trits of a frame (`jmp y-- trit` entered with Y = 11).
- The `out x, 2` is the first instruction of the trit, one tick before the
  rise. So when the host's words run out, the thread stalls in that `out`
  (autopull waiting for a word) with the line low, after the last frame's
  complete sync bit, and nothing more ever changes on P0.
- Sync bit: rise at frame alpha 384, fall at 388, then a loop
  `jmp x-- low [14]` with X = 7 (8 x 15 = 120 ticks), then `jmp trit`
  at 510, the `out` at 511, and the next frame's rise at 512 exactly.
- Start: `set pins, 0` in tick 0 (P0 goes low at cycle 1), Y = 11, X = 10,
  then the same wait loop (11 x 15 ticks). The first `out` spends one extra
  tick fetching the first word (the OSR starts empty), so the first rise is
  at tick 172, cycle 68801, inside the 50000..100000 window with margin on
  both sides.

Tick budget of one trit (t = ticks from its first rise): out at t-1, rise
t0, middle t4, fall t12, rise t16, branch t19, middle 2 at t20, fall t28,
`jmp y--` at t30, next `out` at t31, next rise at t32.

## Program length

20 instructions (20 words from `pe_sim asm`).

## pe_sim runs (14 in total)

1. `pe_sim run x.s -help`: printed the flags. The config list includes
   `sideset_base` and `sideset_count`, which `isa.md` does not mention.
2. `pe_sim asm rc_encode.s`: assembled to 20 words, no errors.
3. `pe_sim run` with the TASK.md example (0x0018, 0x0481), 324800 cycles,
   first 20 lines: P0 low at cycle 1, first rise 68801, then edges at
   +1600, +6400, +8000, +12800, +14400, +19200, +24000, +25600, +30400,
   +32000, +36800: exactly the table in TASK.md.
4-6. My checker (`check.py`, which runs `pe_sim` once per word file with the
   cycle count TASK.md gives and compares every P0 edge with the ideal
   waveform) on t1 (the example), t2 (8 random code words), t3 (4 code
   words: all '1', all 'f', all '0', the example). All "BAD", but the bug
   was in my checker: it took pe_sim's first output line (`pins 0 ff`, the
   reset state of the output register) as a rise. Fixed the checker.
7-9. Same three files with the fixed checker: all OK, 50 edges per frame,
   no extra edges, max error 0 cycles, frames exactly 204800 apart, first
   rise 68801, last edge about 100000 cycles before the end of the run.
10-14. t4 (8 x all '1'), t5 (8 x all 'f'), t6 (1 x all '0'), t7 (5 random),
   t8 (2 random): all OK, max error 0.

## Mistakes found

- First draft of the start code forgot to load Y = 11 (Y starts at 0, so
  the first frame would have had one trit). Found by reading the listing
  before any run; fixed by adding `set y, 11` to the start.
- Checker bug described under runs 4-6.
- I started writing a variant that counts trits with the ISR (`in null, 1`
  and `jmp !isrf`) and abandoned it before running it; Y is simpler.

No rule was broken, as far as I know. Files I wrote here besides the
hand-in: `check.py`, `t1.txt` .. `t8.txt` (test words).

## Things in isa.md that were confusing or seem wrong

- `pe_sim run -help` lists `sideset_base` and `sideset_count` config fields
  that `isa.md` never describes (no side-set field in the encoding either).
  I did not use them.
- `isa.md` says `pe_sim` prints `pins CYCLE XX` "whenever the pins' output
  changes", but it also prints the reset state at cycle 0 (`pins 0 ff`),
  which is not a change. This is what fooled my checker.
- The width of `clkdiv` is not stated anywhere; 400 was accepted and
  behaved as documented (one tick in 400 cycles, first tick at cycle 0).
- With `clkdiv` above 1 it is not said explicitly whether the extra
  autopull "fetch" tick of the first `out` counts as a thread tick; the
  measured first rise (tick 172) shows it does, as one tick.
- How boolean config fields are written (`autopull=1`) is not stated; `1`
  worked.
