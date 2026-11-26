# Notes: USB PD BMC transmitter

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- `./pe_sim run FILE -help` output (run 1).
- Nothing outside this folder. No web, no repository.

Files I wrote here: `usb_power_delivery.s`, `run_args.txt`, `notes.md`, plus two helpers I kept:
`ref.py` (my own reference encoder and waveform checker, in Python) and `probe1.s` (the probe from run 2).
Temporary `tx_*.txt` / `out_*.txt` files from test runs were deleted at the end.

## pe_sim runs (27 in total)

1. `pe_sim run t0.s -help`: flag list (config names, `-inputs`, `-mode`, `-tx`, `-cycles`).
2. `probe1.s` with tx 0x0041, config threshold=16, crc_in, poly 0xEDB88320, init 0xFFFFFFFF, invert.
   Showed: rotating a word through the ISR with `mov osr,isr` + 16 x (`out x,1`; `in x,1`) gives the word back
   (rx 65 = 0x0041) and feeds the CRC in the right order: `mov x,crc` gave 0x6CBB then 0xA8BB, i.e. the
   expected CRC 0xA8BB6CBB. The toggle `mov x,pins; jmp x--,+1; mov pins,x` flips P0 both ways. Also showed
   that `mov x,pins` read 0xFF (P1..P7, inputs with no `-inputs`, read as 1), so testing the level with
   `jmp !x` after `mov x,pins` would have been wrong; the decrement trick only depends on bit 0.
3. `pe_sim asm usb_power_delivery.s`: assembled, 234 words with padding. Checked words 64 (ser), 120-121,
   127/128 (the page 1 to page 2 fall-through lands on the planned `in x,1` / `out x,1`) and 192 (page 3).
4. Example from TASK (Source_Capabilities 0x11A1 / 0x0001912C, then GoodCRC 0x0041 on SOP'): 0 errors,
   every transition exactly on its ideal cycle, 520 transitions.
5-9. Coverage: kinds 0,1,2 x N = 0..7 (24 packets, 5 runs of up to 5 packets, random data): all exact.
10-19. Ten random runs (seeds 100-109, 1 to 5 packets, random kind/N/data): all exact.
20-22. Edge data: all-zero words, all-ones words, every nibble value 0..F, 0x5555/0xAAAA patterns: all exact.
23-27. After lengthening the gap by 15 cycles: 5 x N=7 (longest run), a single GoodCRC (shortest),
   and three more random runs (seeds 300-302): all exact. Gaps 557..593 cycles.

For every run my checker (`ref.py`) built the expected bit stream itself (preamble, SOP by kind, 4b5b,
zlib.crc32, EOP), the ideal transition list including the closing transition and the fall after it,
and compared each P0 transition with the ideal place counted from that packet's first transition
(max error found: 0 cycles in every run). It also checked P0 low by cycle 100, first packet >= 500 cycles
after the line went low, every gap in [500, 40000], no stray transitions, line low at the end.
I tested the checker itself against corrupted copies of a saved output (shifted edge, dropped edges,
wrong data, wrong kind); it flagged each one.

## Design

Config (`run_args.txt`): `-config threshold=16,crc_in=1,crc_poly=0xEDB88320,crc_init=0xFFFFFFFF,crc_invert=1 -mode 0=pp`.
clkdiv 1: every cycle, all timing by counting instructions and delay fields.

Toggling P0 without knowing its level: `mov x,pins` / `jmp x--,next` / `mov pins,x`. Decrementing always flips
bit 0, so P0 gets the opposite of what it was, whatever the other pins read. Three cycles, the edge on the third.

Registers during the data part:
- ISR holds the current 16-bit word. Each symbol, `mov osr,isr` and 4 x (`out x,1`; `in x,1`) feed the
  nibble's bits to the CRC (crc_in) in sending order and rotate the ISR right by 4, so the next nibble
  comes to the bottom and after 4 symbols the word is back. The ISR shift count (threshold 16) is the
  nibble counter: "full" means the word is done.
- OSR holds the current symbol's bits c1..c4 with a sentinel 1 above them (a 5-bit `set` value).
  The serializer loop stops when OSR == 1 (`mov x,osr; jmp x--; jmp !x`).
- Y: 8N+3 after the header; each data word subtracts 4; 3,2,1,0 then select CRC low, CRC high, EOP,
  closing. The dispatch is a chain of `jmp !y` / `jmp y--`, with `set y` to put back what the chain took.
- X is scratch.

Symbol = head + serializer. Bit c0 of every data code equals the nibble's bit 0, so the data head
emits c0 itself (edge at the start, mid edge if n0 = 1), meanwhile feeds the CRC, then decodes n1..n3
with a 3-level tree into one of the code' values (nibbles 0 and 1 also look at n0 again). code' =
(4b5b code >> 1) | 16. The serializer emits the remaining 4 bits. The EOP has its own small head (c0 = 1)
and uses the same serializer. The CRC words are loaded with `mov x,crc` (first read freezes the
register and gives the low half, the second the high half) and go through the same data head.

Packet start: pull the kind word, build 8N+3 and the SOP chunk (K2's c1..c4, K3, K4, sentinel: 15 bits)
with `in` into the ISR. Preamble: 32 x (0,1) with X's bit 0 as the level (one `jmp x--` per edge), then
Sync-1 and K2's c0 the same way, unrolled. Then the header is pulled into the ISR, the SOP chunk goes to
the OSR, the CRC is restarted (`mov crc,null`) and the serializer runs the chunk; its end falls into the
header's first data head because the ISR count is 0.

Closing: one more edge at the next bit start, then `set pins,0` 33 cycles later (no edge if already low),
then about 530 cycles of silence (`set x,31 [15]`, `jmp x--,self [15]`) and `pull` for the next kind
word, which stalls forever when the words run out, with the line low. The same silence loop runs once
at reset after `set pins,0`.

Every path between two edges is balanced with delay fields so that each edge falls exactly on 66k or
66k+33 cycles from the packet's first edge (all dispatch paths after a symbol take 13 cycles; the
serializer's continue path has the matching `nop [12]`).

Pages: the program is 196 instructions, so it spans 4 pages. Page 0: reset, gap, packet setup.
Page 3: preamble and Sync-1. Page 1: serializer, dispatch, EOP, closing and the start of the data
head; the data head falls through from page 1 into page 2 in a stretch with no jumps, after
`set page, 2`. Every jump to another page is preceded by `set page, n`; `.page`/`.align` keep the
assembler's page check in step.

## Program length

196 instructions (234 words including the `.align` padding).

## Mistakes and how I found them

- First design idea kept the line level in the flow of control; dropped before writing code because it
  doubles the decode tree. Several other register plans were worked through on paper and dropped (one
  register short each time) before settling on the ISR rotation.
- No test failures happened; the first full run (run 4) was already exact. I lengthened the gap by
  15 cycles afterwards only for margin (543 to about 558 cycles, against the 500 minimum).

## What was confusing or looks wrong in isa.md

- The CRC section says "`mov` reads it and restarts it (see `mov`)", but the `mov` section says reading
  freezes it (and a second read gives the high half) and only writing restarts it. The simulator
  behaves like the `mov` section.
- The default of `-inputs` is not stated. Input pins read as 1 here (`mov x,pins` gave 0xFF with only
  P0 push-pull), so `mov x,pins` + `jmp !x` cannot test P0 alone.
- Multi-bit `in` and `out` bit placement (which end the source bits land in the ISR) is only implied; I
  relied on "first bit in ends lowest after the word is complete", which the probe confirmed.
- Whether the assembler follows `set page, n` instructions or only the `.page` directive is not said. I
  put a `.page` directive after every `set page` so either reading works.
- "push sends the bits shifted in since the last push": what happens when the count was reset by
  `mov isr` is not said. I avoided relying on it.
- Not wrong, but worth saying: with threshold shared by the OSR and the ISR, and only 16-bit registers,
  a 4b5b transmitter has no free register for both a word counter and a bit counter; the sentinel trick
  and the ISR rotation were needed to fit.

## Rules

I believe I kept every rule: read and wrote only inside the folder, 27 pe_sim runs (under 80), no
em-dashes.
