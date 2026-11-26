# Notes: IEC bus controller for the protocol emulator

## What I read

- `TASK.md`, in full.
- `isa.md`, in full.
- The output of `pe_sim run x.s -help` and of `pe_sim` with no subcommand (runs 1 and 2 below).

I opened nothing outside this folder. Every file I wrote is in this folder: `iec.s`, `run_args.txt`, `notes.md`, `check.py` (my test harness), `runs.log` (written by `check.py`, one line per run it made), `ex_tx.txt`, `ex_stim.txt` and `ex_out.txt` (the TASK.md example and its output), and `tmp_tx.txt` and `tmp_stim.txt` (left over from the last harness run).

## Design

### Pins
DATA, CLK and ATN each get their own way of being written, so no instruction ever has to know the state of a line it is not changing.

- CLK (P1) is driven by side-set (`sideset_base=1, sideset_count=1`). Every instruction says `side 0` (CLK low) or `side 1` (CLK released). Within one transaction, whether CLK is low depends only on where the program is, so this costs no extra instructions. It also lets the bit loop toggle CLK without separate `set` instructions. The price is that delays can be at most 7, so long delays are `jmp x--` loops with `[7]` (8 cycles per pass).
- ATN (P2) is written with `set pins` (`set_base=2, set_count=1`).
- DATA (P0) is written with `out pins, 1` for the bits and `mov pins, x` to release it (`out_base=0, out_count=1`, the defaults).
- `in_msb_first=1` makes the ISR shift left, so I can build command bytes from the top down.
- `threshold` stays at 8, so `!osre` counts the 8 bits of a byte.

`run_args.txt`:
`-config set_base=2,set_count=1,sideset_base=1,sideset_count=1,in_msb_first=1 -mode 0=od -mode 1=od -mode 2=od`

### Registers
- OSR holds the byte being sent. Only its low 8 bits are ever shifted out, so bits above them do not matter. That saves clearing the ISR before each build.
- Y says what the byte is: 0 is a data byte, 1 the last data byte (EOI), 2 SECOND, 3 LISTEN, 4 UNLISTEN. One shared send routine uses Y twice. Before the bits, `x!=y` with X=1 picks the EOI path. After the acknowledge, a chain of `jmp !y` and `jmp y--` picks what comes next.
- X is the loop counter and the scratch register.
- The ISR builds LISTEN (`in x,3` with X=1, then `in x,5` with X=D, giving 0x20+D) and then SECOND (`in x,4` with X=6, then `in y,4` with Y=S, giving 0x60+S). SECOND stays in the ISR until LISTEN has been sent. UNLISTEN is built the same way (`in null,2`, then `in x,5` and `in x,1` with X=31, giving 0x3F).
- A data word is split with `out y,8` (the byte) and `out x,1` (the EOI flag). Then `mov osr,y` reloads the byte and `mov y,x` gives a state of 0 or 1 directly.

### Flow and timing
Times below are cycles after the device event. An input change at cycle t is seen at t+2, and a write made in cycle c shows at c+1. All of the measured values below come from the example run (run 5).

| Step | Measured | Limit |
|---|---|---|
| bus free to ATN low | 246 to 248 | 100 to 400 |
| ATN low to CLK low | 1 | 0 to 20 |
| step 1, CLK release after the first byte's "I am here" | about 206 | 100 to 400 |
| step 1, CLK release after an acknowledge | about 228 to 233 | 100 to 400 |
| step 3a, CLK fall after the device releases DATA | about 21 (a 16-cycle loop, X=1) | 0 to 200 |
| step 3b, CLK fall after the EOI pulse ends | about 20 (the same loop) | 0 to 60 |

The step 3b fall shares the 16-cycle loop with step 3a: the EOI path falls into it after its two waits, also with X=1.

In the bit loop, `out pins,1 side 0` is both the CLK fall and the DATA change for the first bit. For each later bit, the fall is `jmp !osre bit side 0` and DATA changes one cycle after it. Each bit has CLK low for 35 cycles and high for 33, with 32 to 34 cycles from the DATA change to the rise. Falls are 67 to 68 cycles apart, against a limit of 40 to 100.

For step 5, after the 8th fall, `mov pins, x` releases DATA 1 to 4 cycles later. X is 0xFFFF there, because the `hi` delay loop wraps it, and bit 0 of 0xFFFF is 1. I then wait 7 more cycles before waiting for the acknowledge. That way the program never reads its own DATA low by mistake, whichever way the open-drain read-back works.

After the acknowledge there is a common 48-cycle delay, then the dispatch:
- After SECOND, ATN is released at about +58.
- After the last data byte, ATN is pulled low at about +56.
- After UNLISTEN, ATN is released at about +60 and CLK at about +61. The program then goes back to `idle`, which waits for DATA high (bus free) and then pulls the next header.

When the words run out, the `pull` in `idle` stalls with all three lines released.

### Program length
**62 instructions** (`pe_sim asm` prints 62 words). It fits in page 0, so no paging is needed.

## pe_sim runs (39 in total)

1. `pe_sim run x.s -help`: printed the flags and config field names.
2. `pe_sim` with no subcommand: printed the subcommand list. This was an accidental extra run.
3. `pe_sim asm iec.s | wc -l`: 62 words, assembled with no errors.
4. `pe_sim asm iec.s`: the hex listing. It was the same program; I ran asm twice only to print it.
5. The TASK.md example (words 0x0704, 0x0048, 0x0149, and the shortest-delay script from TASK.md, run for 10290 cycles). The output looked right by eye: ATN at 246, CLK at 247, the CLK release at 656 (206 after "I am here"), LISTEN 0x24 bits 0,0,1,0,0,1,0,0, the EOI fall at 5750 (20 after the pulse ended at 5730), UNLISTEN bits 1,1,1,1,1,1,0,0, and ATN and CLK released at 8200 and 8201. This run also showed that `pins` prints the chip's output register, not the level on the line.
6. to 8. `check.py` (seeds 1 min, 2 max and 3 rand): all OK. `check.py` generates the words and a device script within every range of TASK.md (all shortest delays, all longest, or random), runs pe_sim once, decodes the bus (chip AND device) at each CLK rise, and checks every limit in the TASK.md list. It also checks that there are no extra line changes and that all lines end released.
9. Mutation test of the checker: I temporarily changed the idle delay to `set x, 8`, so ATN would fall too early. The checker reported "ATN->0 at 86, want [100,400]". I then restored `iec.s` exactly, and `grep` confirmed the restore.
10. to 33. `check.py` with seeds 10 to 15, each with the modes min, max, mix (each delay either its shortest or its longest) and rand, and 4 transactions each: 24 runs, all OK. Up to 48 bytes per run.
34. to 39. `check.py` with seeds 20 to 25, rand, with 1 to 4 transactions: all OK.

## Mistakes and problems found
- None in the program showed up in testing. The first assembled version passed every check.
- Run 2, `pe_sim` with no arguments, was a wasted run.

## Things in isa.md that were confusing or seem wrong
- **`out pins, n` and `out_count`.** For `mov pins`, isa.md says it writes `out_count` pins. For `out pins, n`, it only says "written from out_base up", so it does not say whether `n` or `out_count` pins are written. I designed so that it does not matter (`out_count=1`, `n=1`).
- **Where `in` puts bits by default.** The default shift-right `in` "shifts count bits right into the ISR", but it does not say at which end the new bits enter. `push` then says the result is right-justified. I used `in_msb_first` instead, whose wording is clear.
- **Reading back an open-drain pin.** For a released open-drain pin, "a thread's own output, read back ... is never delayed" leaves open whether the level read is the chip's own output combined with the synchronised outside level, or the whole line synchronised. I avoided the question by waiting a few cycles after releasing DATA before testing it.
- **Inputs printed by `pins`.** `pins CYCLE XX` prints only the output register, not the levels on input pins. "Whenever the pins' output changes" does say that, but it is easy to misread.
- **The help text.** The `-help` text lists the config fields but not how to write a boolean. `in_msb_first=1` worked, because the command bytes decoded correctly.
- **`out` past the threshold.** I relied on "an out past that point still shifts" (`out y, 4` after 8 bits, without autopull). The SECOND bytes decoded correctly, so it behaves as documented.
- **The wrap of `jmp x--`.** I relied on `jmp x--` leaving X at 0xFFFF when a loop ends. isa.md says the decrement wraps, and the decoded bytes and DATA release confirm it. It is a subtle thing to depend on, though.

## Rules
I broke no rule that I know of. All reads and writes stayed in this folder. I used 39 pe_sim runs out of about 80. Run 2 was unintended but harmless. I used no em-dashes.
