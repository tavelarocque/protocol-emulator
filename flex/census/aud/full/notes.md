# Notes: AUD branch trace receiver

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `./pe_sim run FILE -help` output (run 1).
- Nothing outside this folder. One slip to report: my first command printed
  TASK.md and isa.md with `cat` in one go, the output was too long and the
  tool saved it to a file outside the folder. I did not open that file; I
  re-read both documents from this folder with a file viewer instead.

## Design

Thread 0, every cycle (clkdiv 0). All pins stay inputs (no `-mode` needed).
Config: `in_base=2` (so `in pins` starts at AUDATA0), `threshold=16`,
`start=20` and `timeout_vector=20` (the `idle` label), `timeout=0`.

Register use. The previous destination address is 32 bits and has to
survive between addresses, so its low half lives in the OSR and its high
half in Y. Nothing ever pulls (the host sends no TX words), so the OSR is a
free 16-bit store, and `out` on it doubles as a right shifter. The ISR
assembles nibbles, and X is scratch.

Edge detection is `wait 0 pin 0` then `wait 1 pin 0`. Every line goes
through the same two-flop synchroniser, so the data the thread sees in the
cycle after it sees AUDCK high is the data of that rising edge, which on the
pins is stable 25 cycles either side of it. The first `wait 0 pin 0` also
absorbs the two cycles after reset in which every input reads high.

Idle against command. On each rising edge at the top level the nibble is
either the idle 0x3 or a command 0x8 to 0xB, so AUDATA3 alone tells them
apart. There is no jump-on-pin condition, so I used a timed wait as a
branch: `wait 1 pin 5 timeout` with `timeout=0` jumps straight to
`timeout_vector`, which is the top of the idle loop, when AUDATA3 is low.

Width. For a command, `in pins, 2` then `in null, 14` leaves AUDATA1..0
right-justified in the ISR (0 = 4 bits, 1 = 8, 2 = 16, 3 = 32); `mov x, isr`
and a chain of `jmp !x` / `jmp x--` picks the path; `mov isr, null` empties
the ISR again.

Merging with the previous address. The ISR shifts right, so nibbles sent
least significant first fill it from the top down in the right order. For
4 and 8 bits the remaining upper bits of the low word come from the
previous low word: before the nibbles arrive, `out null, 4k` and
`out x, 16-4k` on the OSR (which holds the previous low word) leave
`previous >> 4k` in X, and after the nibbles `in x, 16-4k` completes the
16-bit word. 16 bits is just four nibbles. 32 bits is four nibbles (low
word, saved in the OSR), then four more (high word, moved to Y). The 16 and
32 bit paths share the first four nibble reads: after the width chain X is
0 for 16 bits and 1 for 32 bits, and `jmp !x tail` separates them.

Tail: `mov osr, isr` (the new low word becomes "previous"), `push` (bits
15..0), `in y, 16`, `push` (bits 31..16), then falls into `idle`. Measured
latency from the rising edge of the last address nibble on the pins to the
second push is at most 11 cycles (limit 200), and the tail finishes well
inside the 25-cycle high phase, so a command right after an address (0
idle nibbles) is never missed.

Before the first address the previous address is 0: Y starts at 0 and the
OSR at reset holds 0 (checked in run 2).

## Program length

63 instructions (words 0 to 62, all in page 0).

## pe_sim runs (23 in all)

Test harness: I wrote a small Python script (gen.py, deleted at the end
since it is not part of the hand-in) that builds a stimulus file exactly as
TASK.md describes (first rising edge at a chosen or random cycle in 30..79,
exact 50-cycle period, lines changing with the falling edge, at least 4
leading idles, 0 to 20 idles between addresses, 4 trailing idles, then AUDCK
stopped low), runs `./pe_sim run aud.s -stimulus FILE -cycles N` plus
`run_args.txt` once, and checks every RX word against the expected
addresses and that each push is between the last-nibble rising edge and
200 cycles after it. Each check is one pe_sim run.

1. `run dummy.s -help`: the flag list.
2. Probe program (`in pins,4` then `mov x, isr`, then `out x,16` on the
   untouched OSR), `-inputs 14`: rx 0x3000, then 0. So `mov x, isr` reads
   the raw ISR (a partial shift-right leaves the bits at the top, not
   right-justified), and the OSR holds 0 at start. Also: `-inputs 14` was
   taken as decimal 14 (P1, P2, P3 high), although the docs call it HEX.
   I used `0x` in every stimulus from then on.
3. `asm aud.s`: 63 words, `idle` at word 20.
4. The example from TASK.md (0x0C001234, 0x5A, 0x7): 6 words, correct,
   PASS, latency max 11.
5. to 14. Random seeds 2..11 (1, 38, 1, 40, 40, 40, 40, 40, 40, 40
   addresses, mixed widths and gaps, random first edge): all PASS, latency
   max 11.
15. First edge at 30, no idle gaps, 40 addresses: PASS.
16. First edge at 79, no idle gaps, 40 addresses: PASS.
17. First edge 30, all 4-bit, no gaps (2 addresses): PASS.
18. First edge 79, one 8-bit address as the first: PASS.
19. All 32-bit, no gaps, 25 addresses: PASS.
20. One 16-bit address, first edge 31: PASS.
21. Negative control: the TASK.md example with `in_msb_first=1` added to
    the config, to make sure the checker can fail. It reported FAIL (wrong
    words, missing words, late timing), as it should. run_args.txt
    restored afterwards.
22. First edge 79, 4-bit addresses: PASS.
23. 40 addresses, all 32-bit, random gaps: PASS.

## Mistakes found

None in the firmware: it passed from the first run. The one surprise was
the `-inputs` number base (run 2), which only affected my probe.

## Confusing or possibly wrong in isa.md

- `-inputs HEX` (and the stimulus `CYCLE HEX`): a plain `14` was read as
  decimal, not hex. Either the doc or the parser is off; `0x` works.
- `in` says it "shifts count bits right into the ISR" but not where new
  bits enter. They enter at the top (bit 15) and move down, like PIO.
  `push` right-justifies, but `mov x, isr` gives the raw register, so a
  partially filled ISR reads differently through the two. The doc does not
  say this.
- The OSR's contents at thread start are not stated (only its count). It
  read as 0.
- `push` after `mov isr, ...` (shift count 0): the doc does not say whether
  it pushes the register or zero bits. I avoided relying on it.
- There is no jump on a pin level. A `wait ... timeout` with `timeout=0`
  works as one, but there is only one timeout vector per thread, so only
  one such branch target.
- The timeout wording, "stalls for T cycles at most, and if the pin is
  still wrong, jumps on the cycle after (with T = 0, at once)", left me
  unsure whether T = 0 costs one cycle or two; it did not matter here.
