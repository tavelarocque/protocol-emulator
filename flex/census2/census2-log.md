# Round 2 results log

Each hand-in judged by the organiser: kit hashes (isa.md 97b80dc6, pe_sim 82b00ea2, TASK.md as in TASK-hashes2.txt), then the hidden accept.py. Part A first.

Note: at about 17:28 UTC on 26 November the workspace disk filled for a few minutes (the organiser unpacking a large toolchain in the same workspace). The Ethernet programmer saw failed writes, retried, and recorded it in its notes; no other programmer's notes mention it. (This note first said "about 9:40 am Pacific" and "each affected programmer's notes"; both were corrected against the kit timestamps and the notes.)

| part | protocol | PASS | len | words | runs | notes |
|---|---|---|---|---|---|---|
| A | eth_an | PASS | 26 | 26 | 11 | clkdiv=4; every pulse exact; 2 runs lost to the full disk; RATE 2 bytes in 475412 cycles |
| A | qspi | PASS | 35 | 35 | 8 | both decoders agree; RATE 388 bytes in 347488 cycles (mostly the 3 ms program waits); left check.py |
| A | st7789 | PASS | 13 | 13 | 13 | 16 cases; 4 cycles a bit (80 ns, SCL limit 66 ns); RATE 22 bytes in 845 cycles; programmer deleted its own checker files before hand-in |
| A | c2 | PASS | 63 | 63 | 41 | clkdiv=5, side-set clock; fits one 64-word page; RATE 16 bytes in 11300 cycles; programmer deleted its own checker |
| A | mipi_rffe | PASS | 138 | 190 | 29 | three pages, 52 words of nop padding to start the bus code on page 2 (start=71); uses the CRC unit for parity; RATE 7 bytes in 2789 cycles; rule note: ran `which python3`, saw a path outside the folder, used that interpreter (recorded in notes.md) |
| A | mipi_dsi | PASS | 225 | 234 | 13 | low-power mode (LPDT); firmware forms ECC and checksum, ECC via the CRC register's parity (no XOR); 9 words of page padding; found and fixed its own ECC bug before hand-in; RATE 29 bytes in 3015 cycles |
| A | fsi | PASS | 154 | 169 | 15 | both directions with scripted slave replies; CRC-4 on the CRC unit (crc_in=1); 3 pages, 15 words of padding; RATE 17 bytes in 16670 cycles |
| A | can_fd | (interrupted) | - | - | 2 | first attempt stopped by a safety classifier interrupt before any hand-in; under round 1's rule (RESULTS.md: an attempt stopped from outside before hand-in does not count) folder set aside unread in interrupted/can_fd, kit reset to its three files with hashes checked, new programmer launched 2026-11-26T18:10:44Z |
| A | pxx1 | FAIL | 157 | 238 | 4 | everything but the CRC right (line coding, header, packing, stuffing, period); sends 16 zero bits as the CRC, by choice: the programmer judged FrSky's CRC impossible (no XOR, CRC register cannot be loaded, reading freezes it). The pre-attempt review (REVIEW2.md, pxx1 item 5) had found a route: crc_poly=0x8000 from 0 makes the CRC register a 16-bit XOR accumulator; not shown with firmware. 3.4 h; built its own Python and C model of the chip and left 30 helper files in the kit; 14 of 15 cases fail, all on the CRC (case 0, all zero, passes because its CRC is 0) |
| A | can_fd | PASS | 247 | 254 | 39 | second attempt (first stopped from outside before hand-in); 17-bit CRC on the chip's CRC unit (crc_poly=0x1B42D), both bit rates, base and extended, missing ACKs; 7 words of padding; RATE 16 bytes in 14660 cycles; notes: the environment showed it an unrelated project-instruction file from outside the folder, unasked, not used |
