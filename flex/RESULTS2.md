# Flexibility census, round 2: results

The rules for round 2 were fixed in [`PREREG2.md`](PREREG2.md) and pushed before any round-2 protocol was attempted. This file reports what happened under those rules, failures included, and every place where the run did not follow them exactly. The evidence is in [`census2/`](census2/), with the organiser's judging log in [`census2/census2-log.md`](census2/census2-log.md): every task sheet, every hidden test, every hand-in with its programmer's own notes, the review made before any attempt, the decoder ports, and scripts that rebuild the decoders and judge every hand-in again.

Part A is complete and reported below. Part B is drawn from the first drand round at or after 2026-11-28 00:00 UTC; its results will be added to this file.

## Part A in one paragraph

Part A attempted every protocol left on two larger outside decoder lists, sigrok's own at a newer commit and DreamSourceLab's DSView, that this project does not already run: 10 protocols, with no draw. One could not be attempted: its sigrok decoder calls a native library that sigrok-cli 0.7.2 does not have, so there is no judge that runs. Each of the other 9 was handed to a fresh AI agent that had never seen this project (CAN FD to a second one after the first was stopped before any hand-in), with nothing but a task sheet, the instruction-set document and the simulator. 8 of the 9 first hand-ins passed a hidden test built around the outside decoder for that protocol. The prediction, written before any attempt, was 6 to 9 of 10. The two protocols named in advance as likeliest to fail, IBM's FSI and CAN FD, both passed; CAN FD is the longest program in either round. The one failure, FrSky PXX1, has everything right except its checksum, which its programmer could not fit on this chip; the review written before any attempt had named a route through the chip's CRC register, untested in firmware, so the failure does not settle whether the chip can do PXX1.

## The list

PREREG2 fixes the list: every decoder in sigrok's libsigrokdecode at `71f45144` or in DSView at `2e9e2c8` that reads pins, decodes a protocol, needs at most 8 channels, and is not a protocol this repository already ran or round 1 used. That left 10, all attempted, so there was no draw.

When the first programmer started, every kit held `docs/isa.md` as it was at commit `771319c` (SHA-256 `97b80dc6...`), which wrote in what round 1's programmers found unclear, and the same simulator as round 1 (SHA-256 `82b00ea2...`). [`census2/TASK-hashes2.txt`](census2/TASK-hashes2.txt) holds the hash of every task sheet, recorded when its programmer was launched. Before each hand-in was judged, its kit was checked against these hashes, and none had changed.

## Part A

| Protocol | Decoder (source) | Kind | Clock | Result | Length | Words | Runs | Bytes / cycles |
|---|---|---|---|---|---|---|---|---|
| CAN FD | `can-fd` (DSView) | both | 50 MHz | pass | 247 | 254 | 39 | 16 / 14,660 |
| Silicon Labs C2 | `C2` (DSView) | both | 50 MHz | pass | 63 | 63 | 41 | 16 / 11,300 |
| Ethernet auto-negotiation | `eth_auto_negotiation` (DSView) | sends | 40 MHz | pass | 26 | 26 | 11 | 2 / 475,412 |
| IBM FSI | `fsi` (DSView) | both | 50 MHz | pass | 154 | 169 | 15 | 17 / 16,670 |
| MIPI DSI, low-power mode | `MIPI_DSI` (DSView) | sends | 50 MHz | pass | 225 | 234 | 13 | 29 / 3,015 |
| MIPI RFFE | `mipi_rffe` (DSView) | both | 50 MHz | pass | 138 | 190 | 29 | 7 / 2,789 |
| FrSky PXX1 | `pxx1` (DSView) | sends | 50 MHz | **fail** (CRC) | 157 | 238 | 4 | |
| Quad SPI | `qspi` and `smart_qspi` (DSView) | sends | 50 MHz | pass | 35 | 35 | 8 | 388 / 347,488 |
| Sitronix ST7789 | `st7789` (DSView) | sends | 50 MHz | pass | 13 | 13 | 13 | 22 / 845 |
| Infrared through IRMP | `ir_irmp` (sigrok) | | | out of reach (no runnable judge) | | | | |

The columns mean what they mean in round 1's table ([`RESULTS.md`](RESULTS.md)). "Kind" is what the chip does on the wire: **sends** is a transmitter driven by words from the host; **both** drives a bus and also reads replies from a scripted device (no Part A protocol was a pure receiver). "Length" is instructions the program runs; "words" is program memory used, larger when a program spans pages and pads to a page boundary, whether the assembler wrote the padding `nop`s or the programmer did. "Runs" is simulator runs, out of about 80 allowed. "Bytes / cycles" is payload bytes over the cycles from the first change on the line to the last, for the last case the hidden test ran; it includes idle time the task sheet leaves to the programmer, so it compares nothing across protocols. Every hand-in was judged again for this report, from the published files alone ([`census2/rejudge.py`](census2/rejudge.py)), with the same verdicts.

The 8 passing programmers needed between 8 and 41 simulator runs. Lengths ran from 13 instructions (the ST7789 display interface) to 247 (CAN FD, which stuffs bits, counts the stuffed bits for the ISO CAN FD stuff count, makes a 17-bit CRC on the chip's CRC register, switches between two bit rates inside a frame and reads the acknowledge bit back from the bus).

Four passes span more than one 64-word page: CAN FD, FSI, MIPI DSI and MIPI RFFE. Two of the passes used the chip's CRC register for something other than a CRC: MIPI DSI computes its error-correcting code, and MIPI RFFE its parity bits, as the parity of the bits fed into that register, because the chip has no exclusive-or instruction.

### Out of reach

`ir_irmp` is sigrok's infrared decoder that hands every sample to the IRMP library, a native C library loaded with `ctypes`. sigrok-cli 0.7.2's library (libsigrokdecode 0.5.3) neither contains nor installs it, so the decoder loads but fails at its first call. PREREG2 names this case in advance ("`ir_irmp` needs libirmp") and says it is reported as out of reach. The examiner's record, with the exact error, is in [`census2/ir_irmp/hidden/OUT_OF_REACH.md`](census2/ir_irmp/hidden/OUT_OF_REACH.md). No task sheet was written.

### The failure: FrSky PXX1

PXX1 is the serial protocol a FrSky radio uses to drive its transmitter module: 16 bytes of channels and flags, a 16-bit CRC, bit stuffing, and a line code in which every bit starts with an 8 us low pulse, one frame about every 9 ms. The hand-in gets everything right except the CRC: the header, the packing of the channels, the stuffing, the closing flag, the line code and the frame period all check out. In the CRC's place it sends 16 zero bits, on purpose, so 14 of the hidden test's 15 cases fail and only the all-zero frame, whose CRC is 0, passes.

FrSky's CRC is not a standard one. It is computed a byte at a time from a table, `crc = (crc << 8) XOR T[(crc >> 8) XOR byte]`, where `T` is the table of the reflected CCITT CRC used with a left shift, so it is not what a CRC register shifting one bit at a time computes. The programmer's notes explain why it stopped: the chip has no exclusive-or instruction, and its CRC register can be restarted and read but not loaded, and reading it freezes it, so the register cannot carry FrSky's byte step from one byte to the next by itself; a rebuild after each byte, which it worked out, needs more values held at once and more time than its bit loop leaves. It wrote that it could not fit a correct CRC on this chip and handed in the rest.

The review written before any attempt ([`census2/REVIEW2.md`](census2/REVIEW2.md), PXX1 item 5) had named a route: with the CRC polynomial set to 0x8000 and the register started from 0, the CRC register adds bits without carry, so it works as a 16-bit exclusive-or of the words fed into it (the reviewer checked this on 2,000 random pairs), and FrSky's table is the exclusive-or of eight one-bit columns. That route was not shown with firmware; nobody wrote a PXX1 program that uses it, and it does not answer the programmer's other objection, that the registers are too few to hold it beside the line coding. So PXX1 is a fail under PREREG2's rule. Whether it is a limit of the chip or of the document is open: a programmer, reading `isa.md`, did not find, or did not judge workable, a use of the CRC register that the document does not describe. It is not evidence that the chip cannot do PXX1, and it is not evidence that it can.

### How hard the judges are

As in round 1, the hidden tests were themselves tested. Before any firmware existed, each examiner showed its test passing a correct waveform and failing at least two broken ones (each `hidden/README.md` and `selftest_output.txt`), and the reviewer ran every self-test again. After Part A, each passing program was mutated with round 1's script: one number in one instruction moved by one, kept if the program still assembled, 5 mutants per protocol, 40 in all. The hidden tests rejected 35 of them (88 percent; round 1: 86 percent). Two of the 40 repeat another mutant of the same program, as round 1's script allows; of the 38 distinct mutants, 33 were rejected.

The 5 survivors were traced with round 1's tools ([`census2/mutants/SURVIVORS.md`](census2/mutants/SURVIVORS.md)). One changes a padding `nop` that never runs. Three move a clock edge by one cycle, inside the task sheets' tolerances (MIPI RFFE allows 2 cycles; ST7789's high, low and period limits all still hold). One moves an Ethernet burst by up to 0.8 ms inside a window of 16 ms. None breaks a rule of its task sheet, so no gap in a judge was found.

### The decoders, and what was changed to run them

Most Part A decoders come from DSView and are written for DSView's version of the decoder library. PREREG2 allows only mechanical changes for sigrok-cli 0.7.2 to load and run them. Six needed changes: `C2`, `MIPI_DSI`, `can-fd`, `mipi_rffe`, `qspi` and `smart_qspi`. Every change is one of three kinds: a DSView-only display-type string dropped from each annotation (the order, ids and texts of the annotations unchanged); `self.matched & (1 << i)` read as `self.matched[i]`, the same bit in sigrok's form; and, in `can-fd`, an import of sigrok's bit-packing helper plus a copy of DSView's own most-significant-bit-first version of it, which 0.7.2 lacks. The examiners worked in one shared copy of the decoders under git, so every change is one commit, published as [`census2/ports.diff`](census2/ports.diff) and, decoder by decoder, as each `hidden/PORT.diff`. The reviewer read every hunk and found nothing that changes what a waveform decodes to. `eth_auto_negotiation`, `fsi`, `pxx1` and `st7789` ran unchanged.

[`census2/fetch_decoders.sh`](census2/fetch_decoders.sh) rebuilds that folder from the public sources (sigrok-cli 0.7.2's own decoders, DSView at `2e9e2c8` and libsigrokdecode at `71f45144`) and applies the ports; the folder it builds is identical, file for file, to the one the hidden tests used.

### The review before any attempt

One agent that wrote nothing but its report reviewed all nine task sheets and hidden tests, and the out-of-reach note for `ir_irmp`, before any programmer started ([`census2/REVIEW2.md`](census2/REVIEW2.md), brief [`census2/REVIEWER.md`](census2/REVIEWER.md)). It found no protocol impossible on the documented chip and blocked none. It asked for fixes in six: four sheets were stricter than the specification and did not say why (C2, Ethernet auto-negotiation, MIPI DSI, ST7789); CAN FD's sheet narrowed the identifiers and MIPI DSI's the packet lengths without giving a reason; and PXX1's judge never checked that the line was push-pull, as its sheet requires. Every fix was made before that protocol's programmer started, and the task-sheet hashes were recorded after the fixes. Separately, MIPI DSI's first task sheet had the host send the packets' ECC and checksum already computed, which breaks the rule that host words carry payload only; it was sent back to its examiner before any attempt, and in the sheet the programmer got, the firmware computes both.

## Where the run did not follow the rules exactly

- **CAN FD's first attempt was stopped from outside and did not count.** Partway through, after two simulator runs and before any hand-in, the AI service's automated safety check stopped the programmer's session. Round 1 met the same case ([`RESULTS.md`](RESULTS.md): five attempts stopped by a machine restart before any hand-in did not count) and reported it as a departure; the same was done here: the folder was set aside unread, the kit was reset to its three given files with the hashes checked, and a new programmer attempted it. The result above is the second attempt's.
- **The workspace disk filled for a few minutes** on 26 November, at about 17:28 UTC, while the organiser was unpacking a large toolchain in the same workspace. The Ethernet programmer saw failed writes, retried, and lost two runs; no other programmer's notes mention it. ST7789's self-test record was overwritten, and its validation was run again (it passed) before its programmer started. Nothing in a kit changed.
- **Four programmers saw something outside their folder.** The MIPI RFFE programmer ran `which python3`, saw the interpreter's path outside its folder, and used that interpreter to run its own checking script. The CAN FD programmer was shown, unasked, an unrelated project-instruction file from outside its folder by the agent environment; its notes say it did not open, follow or use it. The Ethernet programmer's failed write (the full disk, above) printed paths outside its folder. And when the MIPI DSI programmer's program had an assembler error, `pe_sim` printed an internal stack trace naming the simulator's own source files (`model/asm.ml` and its library's), by relative name. The last three say they did not follow what they saw. None concerns this chip's firmware, but the stack trace is the frozen kit's behaviour, and it will happen in Part B too, where the firmware being rebuilt is in the repository; it names source files, not where they are. As in round 1, the instruction to stay in the folder is an instruction, not a sandbox, and each programmer's notes record what it read.
- **Three programmers left their own working files in the kit** (Quad SPI two scripts and their data files, CAN FD a folder of test scripts and programs, PXX1 thirty helper files, among them a model of the chip it wrote itself). The task sheets ask for exactly three files. The hidden tests read only those three, and `census2/<name>/handin/` publishes only those.
- **The organiser's saved copy of the programmer brief was not the one sent.** Each programmer was given round 1's brief with PREREG2's added sentence ("To avoid very long tool output, read them in parts rather than printing both at once"), but the copy kept beside the kits lacked it; the independent check of this report found the difference. [`census2/PROGRAMMER.md`](census2/PROGRAMMER.md) is the brief as sent, with its small differences of wording from round 1's.
- **The hidden tests name the decoder folder by its place in the organiser's workspace.** They are published byte for byte as they ran; `rejudge.py` changes that one line in a temporary copy. The examiner and reviewer briefs are published with that place written as `flex/census2`, as round 1's were.

## What the programmers found unclear

Every programmer listed what in `isa.md` was confusing. The main points raised by more than one:

- **The CRC register**, raised by five. It takes a bit from every `out`, including `out` used only to take a host word apart, so parsing disturbs a running CRC (MIPI RFFE, MIPI DSI, PXX1); with `crc_in` it is not said plainly that `out` stops feeding it (CAN FD); which bit of a multi-bit `in` or `out` it takes is not said (CAN FD); one programmer read the CRC section and the `mov` section as disagreeing about whether a read restarts it (FSI); and it can be restarted and read but never loaded, and a read freezes it, which rules out a CRC that is not a plain shift register over the data (PXX1).
- **How the assembler tracks pages**, raised by four: it follows `set page` down the listing rather than the program's flow, so a `.page` line is needed after a jump to another page (MIPI RFFE, MIPI DSI, CAN FD, PXX1).
- **When a run starts**, raised by four: which cycle the thread starts in, where the clock divider's first tick falls, and that a write made in cycle c shows as `pins c+1`, which is stated only in the simulator's section (Ethernet, Quad SPI, ST7789, C2).
- **`out pins, n`**, raised by three: whether it writes n pins or `out_count` pins (Quad SPI, MIPI DSI, CAN FD).
- **One side-set bit leaves a delay of 0 to 7**, raised by three: it is stated in the assembler section but not the side-set section (ST7789), and it makes cycle-exact loops long (MIPI RFFE, FSI).
- **Which bit of a multi-bit `in` or `out` lands where**, raised by two (C2, Quad SPI).
- **When a `wait` with a timeout jumps**, raised by two: the vector runs T + 1 cycles after the wait starts (CAN FD, PXX1).
- **`set` takes only 5 bits**, raised by two, with no example of building a larger constant (Ethernet, Quad SPI).
- **`mov isr, isr` and `mov osr, osr`**, raised by two: they reset a shift count and keep the contents, and are not described (MIPI DSI, PXX1).

Two programmers also named limits of the chip rather than of the document: no exclusive-or (PXX1) and no inverting move (FSI), and only two general registers, which leaves little room for bit stuffing, as `isa.md` itself says (PXX1). The document points go into `docs/isa.md` after round 2 ends, as PREREG2 requires, so all of round 2 runs on the document as it was frozen. The one possible inconsistency (FSI's reading of the CRC section against the `mov` section) is checked against the model before anything is written.

## Measured against the prediction

PREREG2 predicted 6 to 9 of the 10 would pass; 8 did. It named `ir_irmp` and `mipi_dsi` likeliest to be out of reach: `ir_irmp` was; for `mipi_dsi` it added that the low-power mode may be reachable, and that mode, which the specification defines for commands and which needs no differential lane, was attempted and passed. It named `fsi` and `can-fd` likeliest to fail if attempted; both passed. The failure came from a protocol the prediction did not name, though its own examiner called it hard and the reviewer listed it among the three hardest.

## What this does and does not show

It shows that programmers who had never seen this project implemented 8 of 9 attemptable protocols from two outside decoder lists, chosen by a rule rather than by anyone here, from the frozen instruction-set document alone, and that outside decoders accept the result. With round 1, 26 of the 27 protocols attempted passed, across protocols nobody on the project chose. The one failure leaves a question open: whether FrSky's CRC fits beside the line coding by using the CRC register as an exclusive-or, a use the document does not describe. The reviewer thought it does; the programmer thought the registers too few; no firmware settles it.

It does not show what a person would do. As in round 1, the programmers were AI agents, all running the same AI model as round 1, each in a fresh session, told to read nothing outside its folder (an instruction, not a sandbox: see above), and they know the RP2040's PIO, which this chip resembles. Five of the nine judges run decoders (six decoders in all) that needed mechanical changes to load in sigrok-cli 0.7.2. Everything ran on the reference model, which the chip's own tests check against the RTL; nothing here ran on hardware.
