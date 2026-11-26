# Ablation results log

Each hand-in checked by the organiser: kit hashes (isa.md, pe_sim, pe_sim.real, TASK.md), the hidden accept.py, and the gate (fixed wrapper of the variant run on the hand-in with its run_args.txt). Length is assembled words.

Kit change during the run: the variant wrapper did not list the simulator's `-stimulus` flag, so any run with it was forwarded unchecked (reported by ac97 no_sideset_1). Fixed in variants3 (no_delay d02d2450..., no_sideset 4640889a...) and copied into the 30 kits not yet started; the four ac97 cut-down kits ran on the old wrapper (8cfb2370... / ef9b1bbd...). The gate uses the fixed wrapper, so every hand-in is judged the same way.

Kit note: pe_sim.real help still lists sideset_base and sideset_count, which the cut-down isa.md does not document (reported by ac97 no_sideset_2 and ook no_sideset_1). The wrapper refuses any use, so it reveals the name of the removed feature but gives no way to use it.

| protocol | variant | PASS | len | runs | gate | notes |
|---|---|---|---|---|---|---|
| ac97 | no_sideset_1 | PASS | 51 | 24 | ok | first try passed own harness; reported wrapper -stimulus gap |
| ac97 | full2 | PASS | 55 | 32 | ok | census attempt was 56; one SYNC-length bug fixed in own harness |
| ac97 | no_sideset_2 | PASS | 49 | 25 | ok | one double-catch of a clock pulse fixed with a 1-cycle delay; deleted its work/ |
| ac97 | no_delay_1 | PASS | 48 | 37 | ok | old wrapper kit; own checker checked by planting one wrong bit |
| ac97 | no_delay_2 | PASS | 62 | 26 | ok | old wrapper kit; also reported the -stimulus gap; margin 1 cycle from BIT_CLK fall; deleted its checker |
| ook | no_delay_2 | PASS | 51 | 43 | ok | clkdiv=10 used for timing in place of delay; RATE 16 bytes in 105990 cycles; left check.py and scratch files |
| ook | full2 | PASS | 55 | 28 | n/a | census attempt was 33; RATE 16 bytes in 96345 cycles; deleted its checker |
| ook | no_delay_1 | PASS | 58 | 29 | ok | clkdiv=10, 25 instructions per half bit; RATE 16 bytes in 105840 cycles; deleted its checker |
| ook | no_sideset_1 | PASS | 31 | 7 | ok | clkdiv=25, set pins only; RATE 16 bytes in 95450 cycles; shortest ook so far |
| ook | no_sideset_2 | PASS | 34 | 13 | ok | clkdiv=25; RATE 16 bytes in 97125 cycles; deleted then rewrote run_args.txt (in its notes) |
| aud | full2 | PASS | 55 | 27 | n/a | census attempt was 63; RATE 104 bytes in 17025 cycles; unrolled version overflowed page, rewritten as loops; left gen.py |
| aud | no_delay_1 | PASS | 57 | 22 | ok | RATE same as full2; ignores nAUDSYNC and tells command from idle by AUDATA3 alone (allowed by the task's stimulus rules, but a robustness caveat for the judge-gap discussion); deleted its generator |
| aud | no_delay_2 | PASS | 61 | 23 | ok | RATE same as full2; left gen.py and check.py; four ISR points unclear in isa.md |
| aud | no_sideset_1 | PASS | 46 | 29 | ok | start=16 (program not at word 0); RATE same as full2; deleted its helper |
| rc_encode | full2 | PASS | 20 | 8 | n/a | census attempt was 29; clkdiv=400 (one tick per alpha), autopull; RATE 9 bytes in 621600 cycles; left check.py |
| aud | no_sideset_2 | PASS | 37 | 44 | ok | RATE same as full2; read the wrapper docstring by accident (inside its folder, recorded in its notes: says the build has no side-set); left test_aud.py |
| rc_encode | no_delay_2 | PASS | 55 | 20 | ok | clkdiv=1600 (4 alpha per tick), side-set on every instruction; RATE 9 bytes in 624000 cycles; deleted its checker |
| rc_encode | no_delay_1 | PASS | 51 | 38 | ok | clkdiv=800 (2 alpha per instruction), side-set, autopull; RATE 9 bytes in 637600 cycles; 11 runs lost to its own checker bug; deleted its checker |
| rc_encode | no_sideset_1 | PASS | 20 | 14 | ok | clkdiv=400, autopull; RATE 9 bytes in 633600 cycles; noted pe_sim prints the starting pin state as a change |
| rc_encode | no_sideset_2 | PASS | 28 | 11 | ok | clkdiv=100; RATE 9 bytes in 640300 cycles; deleted its checker |
| lpc | no_delay_1 | PASS | 35 | 14 | ok | clkdiv=10, side-set drives LFRAME# and LCLK; rising edges at +1 cycle (limit 2); RATE 3 bytes in 1470 cycles; noted pe_sim prints rx in decimal, isa.md silent |
| lpc | full2 | PASS | 31 | 23 | n/a | census attempt was 29; side-set drives LCLK; RATE 3 bytes in 1580 cycles; isa.md: rx printed decimal, -inputs needs 0x, pins shows output register; deleted its checker |
| lpc | no_sideset_2 | PASS | 46 | 13 | ok | read the wrapper in its folder and learned the build lacks side-set (recorded in its notes); edges exact at 100+20k; RATE 3 bytes in 1510 cycles; deleted its checker |
| lpc | no_sideset_1 | PASS | 49 | 34 | ok | one LFRAME# timing bug fixed in own checker; RATE 3 bytes in 1500 cycles; deleted its checker |
| lpc | no_delay_2 | PASS | 41 | 17 | ok | clkdiv=10, side-set LCLK, edges +1 (limit 2); RATE 3 bytes in 1480 cycles; lost three runs to decimal rx output; deleted its checker |
| avr_pdi | full2 | PASS | 58 | 17 | n/a | census attempt was 52; clkdiv=5, side-set P0, parity by decrementing Y; edges +1 (limit 2); RATE 12 bytes in 21775 cycles; deleted its harness |
| avr_pdi | no_delay_2 | PASS | 111 (114 words) | 13 | ok | two pages; edges +1 (limit 2); RATE same as full2; left t/ subfolder with checker |
| avr_pdi | no_sideset_1 | PASS | 59 | 35 | ok | clock by set pins, parity from a 1-bit CRC, start delay by timed-out wait; edges exact; RATE same as full2; one run duplicated by mistake (in notes); left check.py |
| dsi | full2 | PASS | 35 | 14 | n/a | census attempt was 17; worst edge error 5.67 cycles (limit 80); RATE 1 byte in 266619 cycles; left check.py |
| dsi | no_delay_1 | PASS | 48 | 10 | ok | delay constant built in Y, nop padding; worst edge error 5.67 cycles (limit 80); RATE same as full2; deleted its checker |

Interrupted: at about 10:30 pm Pacific the container restarted and five running attempts were killed before reporting (avr_pdi no_delay_1 and no_sideset_2, dsi no_delay_2, no_sideset_1 and no_sideset_2). None had reported a hand-in, so none counts. Their partial folders are kept unread in `interrupted/`; each kit was reset to its four given files (hashes checked) and the attempt rerun by a fresh agent.
| dsi | no_sideset_1 (rerun) | PASS | 36 | 11 | ok | first version passed; worst edge error 5.67 cycles; RATE 1 byte in 233298 cycles; deleted its helpers |
| dsi | no_sideset_2 (rerun) | PASS | 25 | 9 | ok | clkdiv=13; worst edge error 5.67 cycles; RATE 1 byte in 273702 cycles; left check.py |
| dsi | no_delay_2 (rerun) | PASS | 44 | 7 | ok | delay constant built in ISR; worst edge error 5.67 cycles; RATE same as full2; left check.py |
| maple_bus | full2 | PASS | 55 | 8 | n/a | census attempt was 62; checksum via CRC unit (no XOR); RATE 208 bytes in 43950 cycles; left check.py and gen.py |
| avr_pdi | no_sideset_2 (rerun) | PASS | 60 | 36 | ok | clock and data by separate instructions, parity from CRC; edges exact; RATE same as full2; its checker misread decimal rx; deleted its scratch folder |
| avr_pdi | no_delay_1 (rerun) | PASS | 58 | 15 | ok | clkdiv=25, one instruction per half slot; edges +1 (limit 2); RATE same as full2; one pre-delay bug fixed; left check.py |
| maple_bus | no_sideset_1 | PASS | 63 | 18 | ok | checksum via CRC, bit-reversed back through ISR; worked on first run; RATE 208 bytes in 62749 cycles (43% slower than full2); deleted its checker |
| maple_bus | no_sideset_2 | PASS | 61 | 12 | ok | checksum via CRC poly 0x80, un-reversed through ISR; RATE 208 bytes in 57730 cycles (31% slower than full2); left check.py and tx_example.txt |
| maple_bus | no_delay_1 | PASS | 104 (117 words) | 16 | ok | two pages; longest in-frame gap 86 cycles (limit 100); RATE 208 bytes in 44542 cycles (1% slower than full2); deleted its checker |
| maple_bus | no_delay_2 | PASS | 66 | 16 | ok | side-set with clkdiv 4; last two words fall through into page 1; relies on ISR count reading full after 24 bits (not in isa.md, model agrees); longest in-frame gap 80 (limit 100); left check.py |
