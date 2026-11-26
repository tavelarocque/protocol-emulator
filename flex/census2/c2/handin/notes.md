# Notes: C2 master firmware

## What I read

- `TASK.md`, in full (two parts: lines 1 to 129, then 130 to the end).
- `isa.md`, in full (four parts: lines 1 to 179, 180 to 359, 360 to 529, 530 to 699).
- `./pe_sim run -help` (run 1 below) for the `-config` field names.
- Nothing outside this folder. I did not look for the `model/`, `hw/` or `docs/` files that isa.md mentions.

## Design

Clock and pins. `clkdiv=5`, so the thread has one tick every 5 cycles and 10 ticks per 50-cycle slot. C2CK (P0, push-pull) is driven only by side-set (`sideset_base=0`, `sideset_count=1`, so every instruction states the clock level and the delay field keeps 3 bits, up to [7]). C2D (P1, open-drain) is written by `out pins, 1` and `set pins, 1` (`out_base=1`, `set_base=1`, counts 1) and read by `in pins, 1` (`in_base=1`). Threshold stays at its default of 8. The thread's first tick is cycle 0 and a write in tick n shows at cycle 5n+1, so the rising edge of slot s is the instruction executed at tick 400 + 10s and appears at cycle 2000 + 50s + 1, one cycle after its place, with no drift because every path is counted exactly.

Inside a slot I number the ticks t0 to t9. C2CK rises at t0, the chip changes C2D at t3 (or releases it at t1), the chip samples C2D at t5 (cycle place + 25, well inside the window place + 5 to next place + 5 in which the synchronised device bit is valid), and C2CK falls at t8 and stays low through t9. So each strobe is low for 10 cycles and high for 40 cycles. The chip never writes C2D in the tick of a fall or a rise, so setup and hold hold by construction.

Reset. C2CK goes low at tick 0 (cycle 1) and a 32-iteration loop of 8 ticks keeps it low until tick 257 (cycle 1286), 1285 cycles. A second loop keeps it high until tick 381, which is the frame entry point for the first frame. C2D is never written during the reset.

Frame entry. The frame code starts at tick -19 relative to the START strobe's rise, which is t1 of the previous frame's STOP slot (and tick 381 for the first frame). It pulls the header, puts the low byte in X (address or n), and branches on bits 12 and 13 into four set-up blocks, each arriving at tick -12. Each set-up block makes the START strobe (fall at -2, rise at 0) and leaves the chip's bits C in the OSR, their number minus one in Y, and a mode in X, then enters the bit loop `wbit` at tick 3.

The trick that keeps the program small is that every strobe in which nobody drives C2D (START, STOP, WAIT, the released 1 bits) is the same thing as the chip sending a 1, since writing 1 to an open-drain pin releases it. So:

- Address Write: C = INS 1, 1, the 8 address bits, then the STOP as a 1; 11 bits, X = 0xFFFF. When the loop runs out of bits it sees X = 0xFFFF (that is X = Y after Y has wrapped) and makes the last strobe (the STOP) itself, then jumps to the frame entry.
- Data Write: C = INS 1, 0, LENGTH (n-1, made with one `jmp y--` used only to decrement); X = n. Each time the loop runs out of bits with X not 0 and not 0xFFFF it pulls the next data word during the strobe of the last bit, sets Y = 7 and decrements X. With X = 0 it goes to `dtail`.
- Address Read: C = INS bit 0 only (0); X = 0. `dtail` makes the strobe for that bit, releases C2D, then makes one plain strobe, which is the INS bit 1 (a released 1).
- Data Read: C = INS 0, 0, LENGTH, and above those 4 bits the OSR also holds n-1 again; X = 0. `dtail` as for Address Read; its plain strobe is the WAIT. `dtail` reads the OSR's remaining value into X, which for Data Read is n-1 and for Address Read is 0.
- `dtail` makes the last chip bit's strobe, releases C2D at t1 after it rises, clears the ISR, sets Y = 7, makes one plain strobe (WAIT for Data Write and Data Read, INS bit 1 for Address Read), and then tells the cases apart with `jmp !osre`: after a data byte the OSR has shifted 8 bits (empty at threshold 8), after a read's header it has shifted 1 or 4 (not empty). Data Write then makes the STOP strobe; the reads go to the read loop.
- Read loop: samples at t5 of every device slot, pushes after 8 bits in the tick that C2CK falls for the next strobe, counts bytes down in X, and the strobe after the last byte is the STOP.

Data Write and Data Read share their set-up code from the `jmp y--` on (Data Read jumps in with X cleared first; both are padded to reach it at the same tick).

Ownership of C2D (rule 5): the chip writes C2D only with `out` at t3 of the START slot and later, and `dtail` releases it at t1 of the slot of the last chip bit, before the next strobe falls at t8. Address Write ends on its STOP bit of 1, which is a release at t3 before the STOP falls. When the words run out, the thread stalls in `pull` with side-set 1 and C2D released.

Program length: 63 instructions (one page of 64, so no page switching).

## pe_sim runs

1. `./pe_sim run -help`: listed the config fields (start, out_base, out_count, set_base, set_count, in_base, threshold, timeout_vector, timeout, sideset_base, sideset_count, clkdiv, the shift, autopull/push and CRC fields) and flags.
2. `./pe_sim asm c2.s`: assembled without errors, 63 words.
3. The example from TASK.md (0x1000, 0x4001, the stimulus given): reset fall at cycle 1, rise at 1286, first strobe low 1991 to 2001, rises at place + 1 throughout, one rx word 48 (0x30). Showed that a thread's first tick is cycle 0 and that a write in tick n shows at cycle 5n+1.
4. The same example through my checker script (see below): OK.
5 to 14. Ten random runs (seed 1) of 1 to 10 frames of random kinds, addresses, lengths and bytes: all OK. One had 13 device bytes, so the RX FIFO of the simulator does not fill up and stall the push.
15. Data Write of 0x12, 0x34 then Address Read returning 0xA5, with the raw output printed: checked by hand, slot by slot, every chip bit (INS 1,0, LENGTH 1,0, the data bits LSB first), the release at cycle 3006 (t1 of the last data slot), WAIT, STOP, the idle slot with no edge, the Address Read's INS 0 then release at 3256, eight device strobes, STOP, and rx 165 (0xA5). Matches the checker's OK.
16 to 35. Twenty random runs (seed 2): 20 OK.
36. A fixed 10-frame run with every kind and the extreme values 0x00 and 0xFF in addresses and data, lengths 1 to 4: OK.
37 to 41. I noticed my checker ran for 2000 + 50(S+1) cycles instead of TASK's 2000 + 50(S+2); fixed it and ran five random runs (seed 3): all OK, and C2CK stays high to the end.

Total: 41 runs of pe_sim.

The checker was a Python script I wrote in this folder (`check.py`, with its temporary `t_tx.txt`, `t_st.txt`, and the example files `ex_tx.txt`, `ex_stim.txt`, `out3.txt`). It built the host words, the device stimulus (device low from place + 3 to the next place + 3 for each 0 bit) and the expected strobe plan from the frame list, ran pe_sim with `run_args.txt`, and checked: the reset window (fall by 300, low at least 1100, rise by 1800), the number of strobes, every rise within 2 cycles of its place, low 4 to 40 cycles, high at least 6, no C2D change from F to E in the chip's strobes and the chip's bit at E, C2D low only inside the ownership windows of rule 5, the rx words against the device's bytes, and both lines high and released at the end. I deleted these helper files before handing in, so that only the requested files remain.

## Mistakes found on the way (all on paper, before any run)

- My first loop sketch put the delay on the `jmp y--` and assumed the fall-through path started right after the jump; isa.md says the delay applies whether or not the jump is taken, so I moved the delay to the out side and rebuilt the loop so the last-bit path runs during the strobe.
- I first planned to write C2D at the rising-edge tick; that change would show in cycle E, which rule 4 forbids, so all C2D writes are at t1 or t3.
- Address Read first used the header's leftover OSR (value 0), but its shift count would have been 16, which makes `!osre` say empty; it uses `mov osr, null` to reset the count.

## Anything confusing or wrong in isa.md

- Nothing I found was wrong: every behaviour I relied on (side-set on every executed instruction, delay after a jump either way, `in` shifting right with new bits at the top, `push` right-justifying, `out` past the threshold still shifting without autopull, `mov osr` resetting the count, one threshold shared by `!osre` and `!isrf`, pins lines showing the value one cycle after the instruction) behaved as described.
- Slightly unclear: for a multi-bit `in`, which bit of the source lands where is only implied by "the first bit in ends lowest once pushed"; I assumed bit 0 of the source goes in first, which the runs confirm.
- The clock divider's phase ("its first tick is the first cycle it is enabled") does not say which cycle of a `pe_sim run` that is; it turned out to be cycle 0 (run 3).
- The input synchroniser's 2-cycle delay matters for when a device bit is seen; isa.md is clear, but it is easy to miss when reading the C2 timing in TASK.md.
- The bit sampler section speaks of a 40 MHz clock while TASK.md uses 50 MHz; not an error, just a different example.

## Rules

I read and wrote only inside this folder. I used no em-dashes. I broke no rule that I know of.
