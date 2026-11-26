# Brief: review round 2 Part A's task sheets and judges before any attempt

Never use em-dashes in anything you write. You are READ ONLY on every file
below except the one report you write.

## Context

A pre-registered "flexibility census" is testing whether a small
programmable I/O chip can be programmed, blind, for protocols nobody on the
project chose. Read `flex/PREREG2.md` (round 2's rules, Part A) and
`flex/PREREG.md` (round 1's rules, which round 2 follows) with
`git -C /home/claude/pe show origin/demo:PATH` (fetch first; never modify
/home/claude/pe). Round 1's review, which is your model, is
`flex/census/REVIEW.md` on origin/demo: read it first, then do the same
work for round 2.

With C = flex/census2 :

- `C/kits/<name>/` hold what a programmer will get: TASK.md, isa.md, pe_sim.
- `C/hidden/<name>/` hold each examiner's hidden test (accept.py), its
  ideal-waveform generator and self-test, README.md, selftest_output.txt and,
  where the decoder needed changes to run, PORT.diff.
- `C/decoders/` is a git repository of the decoders (sigrok-cli 0.7.2's,
  plus DSView's and one of sigrok's newer ones). Its history: the decoders
  as fetched (d058999), a commit that only stops tracking bytecode caches,
  then the examiners' ports (e44c5bd). `git -C C/decoders show e44c5bd`
  shows every port.

Nine protocols are ready: c2, can_fd, eth_an, fsi, mipi_dsi, mipi_rffe,
pxx1, qspi, st7789. A tenth, ir_irmp, is declared out of reach
(`C/hidden/ir_irmp/OUT_OF_REACH.md`): check that its reason holds.

## What to check, for every protocol

1. **TASK.md against accept.py.** Every check the judge makes is stated in
   the task sheet, with the same numbers; nothing the sheet promises is left
   unchecked without saying so in README.md. The judge is not stricter than
   the protocol's specification requires, unless the sheet says so and gives
   a reason (for example a fixed schedule so that a scripted device lines up).
2. **Host words carry payload only.** Never line levels, pre-coded bits, or
   anything the protocol computes (CRC, checksum, ECC, parity, stuffing).
   Every sheet has the two sentences "The host sends only the words defined
   above." and "All line coding, framing and timing must be done by the
   firmware." Any narrowing of the protocol (a subset of frame sizes,
   commands or modes) is stated with its reason; say whether the reason holds.
3. **No hints** about how to use the instruction set. The opening and the
   "Rules for this test" section match round 1's (`flex/census/ook/TASK.md`)
   apart from the protocol's name, and the hand-in section matches.
4. **Decoder ports are mechanical only.** Read each hunk of e44c5bd and each
   PORT.diff: imports, version or annotation-format fields, renamed library
   calls, the `self.matched` representation. Anything that could change what
   a waveform decodes to is a BLOCK. PORT.diff must equal the committed
   change for that decoder.
5. **Declared judge adjustments** (a decoder bug worked around, a capture
   altered before the decoder sees it, an expected decoder warning): each is
   stated in README.md, is necessary, cannot make a wrong waveform pass, and
   the pins are judged directly where the decoder is bypassed.
6. **Validation is real:** run each self-test yourself (`python3
   selftest.py` or `validate.py` in its folder; some take minutes, run them
   in the background and in parallel) and confirm it ends in PASS (or
   VALIDATION OK), with at least two broken waveforms failing.
7. **Kit integrity:** each kit holds exactly TASK.md, isa.md, pe_sim; every
   isa.md has SHA-256 starting 97b80dc6, every pe_sim 82b00ea2.
8. **Feasibility on the documented instruction set** (do NOT write firmware,
   not even a sketch): is there any reason a correct solution is impossible
   (a timing the chip cannot produce at the chosen clock, a register count
   that cannot hold the needed state, a requirement no instruction can meet)?
   Hard is fine; impossible is a BLOCK.

## Write

`C/REVIEW2.md`, in the form of round 1's REVIEW.md: what was checked, a
summary table (OK, FIX, or BLOCK per protocol), then for each protocol the
findings with file and line numbers. A FIX says exactly what to change. Do
not change any other file.

## Report back, under 250 words

The table, and the FIX and BLOCK items in one line each.
