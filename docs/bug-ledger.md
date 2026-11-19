# Bug ledger

Every real bug the verification found is in the table in
[`design-and-verification.md`](design-and-verification.md), section 5.
This page tells eleven of them in full, chosen because each was found by a
different layer and would have been missed by the others. The last four
are from v2.0. A check that has
found nothing has not been shown to work; these are what the checks found.

## 1. A handshake over a thousand times too late, visible only on the emulated board

Low-speed USB gives a host 16 bit times, 10.7 us, to acknowledge a device's
data. In cocotb the driver read a whole device descriptor without fault,
on the RTL and on the gates.

The same driver, unchanged, then ran in MicroPython on an emulated demo
board (rp2040js running Tiny Tapeout's firmware) wired to the RTL. The read
failed. Timing the bus showed why: the handshake arrived 14.6 ms after the
device's data. MicroPython, bit-banging the host port one pin write at a
time, was the slow part. The device never saw an acknowledgement and sent
DATA1 again.

cocotb could not have shown this. It clocks the host port as fast as the
chip allows, which no real board does. The fix moved the host port into an
RP2040 PIO state machine. The first version of that still missed: fed one
word at a time, a short packet's handshake came 9.95 bit times after the
data, inside the limit, but a zero-length packet's would have come after
33. Each batch is now queued with the state machine stopped and then
started, and the test measures the slack on every handshake.

*Found by:* the emulated board. *Lesson:* a testbench that drives the chip
at the chip's speed says nothing about the host.

## 2. A bug in someone else's USB device

The USB tests use usbhostslave's device core as an oracle because the
project did not write it. Reading an 18-byte descriptor at low speed takes
three 8-byte packets, which must alternate DATA0 and DATA1. The chip's
driver rejected the second packet: it was DATA1 again.

The driver was right. The device example never toggled on IN packets. As
published it runs at full speed, where the descriptor fits one packet, so
the fault never showed. It is fixed in the vendored copy, with the change
marked and documented.

*Found by:* the driver's own toggle check, required by USB 1.1 section 8.6.
*Lesson:* a third-party oracle is independent, which is its value, and
unverified outside the use its author had.

## 3. The planted bug that was not a bug

To show the whole-chip proof is not vacuous, bugs are planted in the
specification and the proof must fail on each. Three did. The fourth, an
empty RX FIFO popped by a host read, came back proven equal: with the
"bug" in place, the spec still matched the chip on every state and input.

The proof was right. The FIFO ignores a pop when empty, so the planted
change altered nothing observable. A simulation would have left this as
"not caught, reason unknown". The proof settled it, and the candidate is
recorded as a non-bug rather than dropped.

*Found by:* the SAT equivalence proof. *Lesson:* a mutant that survives is
either a hole in the tests or not a bug, and only a proof tells which.

## 4. A test that had never tested what it claimed

The lockstep test runs random programs on the RTL and the reference model
and compares every cycle. It also counts what those programs did, and any
count of zero fails the build. On its first run, "PUSH stalls on a full RX
FIFO" was zero. The random host was draining the FIFO too often for it
ever to fill.

The design was fine. The test had been passing while never reaching a
whole class of behaviour. The fix was to the test: the host's behaviour is
now drawn per trial, so some trials have a slow host.

*Found by:* functional coverage. *Lesson:* 400 passing random programs
are evidence only for what they were counted doing.

## 5. PS/2: a frame the keyboard believed it had sent

PS/2 lets the host cut in by holding the clock low. The first transmitter
checked that the bus was idle and then inhibited. Against a device model
with its timing drawn at random from the legal range, some bytes arrived
twice.

A device counts its frame as sent once its eleventh clock pulse has
fallen; inhibited before that, it must send the frame again. A transmitter
that looks only for an idle bus can inhibit close to that line, too late
for the device to notice, and the two sides then disagree about whether
the byte was delivered. The fix
needed no hardware: the receiver drives a spare pin low for the length of
a frame, and the transmitter waits on that pin before inhibiting. Two
threads signalling through a pin is an ordinary use of the instruction
set.

The same tests found that the receiver's record of the host's own byte
could be wrong: the transmitter changed DATA in the clock cycle the
receiver sampled it. The transmitter now changes DATA 3 us after the clock
falls.

*Found by:* a device model with randomised legal timing. *Lesson:* a
device at typical timing would have passed every run.

## 6. CAN: words left behind after losing arbitration

A CAN transmitter that loses arbitration must stop at once and try again.
The first transmitter did stop. The next frame it sent was garbage: the
words of the lost frame were still in the FIFO and were sent as the start
of the next one.

It showed only when the chip and the model node began a frame in the same
bit and the chip lost, which the test forces in half its runs. The
transmitter now drains the rest of a lost frame before it reports the
loss. The same runs showed the receiver could correct its timing in one
direction only, so a node whose clock was off the other way drifted out of
the bit; the
receiver was redesigned to wait for an edge straight after each sample.

*Found by:* random runs against a node whose clock is up to 1.25% off and
which arbitrates. *Lesson:* the failure was in the frame after the one
that went wrong.

## 7. The pins had no synchronisers

Every test passed, and the protocol pins went straight from the pad into
the logic. In simulation an input changes cleanly on a clock edge. On
silicon an outside signal changes whenever it likes, and a flip-flop that
samples it mid-change can settle late or to either value.

No simulation in the project could have shown this. It was found by
reading the design and asking what silicon does that the simulator does
not. Each pin got a two-flip-flop synchroniser. That delayed MISO by two
clocks and broke the 2-cycles-per-bit SPI, which a test did catch, so the
synchroniser is bypassable per pin.

*Found by:* review. *Lesson:* some bugs are outside what the tests can
express, and the report says which ([section 7](design-and-verification.md)).

## 8. The proof that passed without running

v2.0 moved the program memory into SRAM macros, and the first layout came
back with every check green, the netlist proof among them. That job had
taken 20 seconds. On v1.4 it took minutes.

The log showed a Python traceback. One of the planted netlist bugs picked
"flip-flop 900", a choice made when the netlist had 1,796 flip-flops; v2.0
has 796. The script crashed before proving anything. The workflow piped
its output through `tee` to keep a copy, and a shell pipeline reports the
exit status of its last command, so the step reported `tee`'s success. An
earlier trial layout had "passed" the same way.

The step now sets `pipefail`, the planted bugs take their positions from
the netlist they are given, and a proof that ends with no verdict counts
as a failure whichever outcome was wanted.

*Found by:* reading the log of a job that had passed, because it was too
fast. *Lesson:* a check that cannot report its own crash is not a check.
A green result should be read at least once.

## 9. The solver that ran out of stack

With the crash fixed, half of the netlist proof still gave nothing on the
real netlist: the induction step proved all 1,082 pairs, and the base case
ended with neither "proved" nor a counterexample. On a small stand-in
netlist, synthesised here, both halves passed.

The new diagnostic showed the log stopping inside one Yosys pass,
`equiv_miter`, with "wasm trap: call stack exhausted". That pass walks the
circuit by recursion, CI runs the WebAssembly build of Yosys, whose stack
is small and fixed, and the layout netlist was deep enough to exhaust it
where the stand-in was not. Adding a chain of 4,000 flip-flops to the
stand-in reproduced it exactly: same log, same place.

The base case now builds the same comparison from ordinary passes that do
not recurse, and it proves on the real netlist. The planted wrong reset
value is still found.

*Found by:* making the check say why it had no answer, then reproducing
the failure on something small. *Lesson:* a tool can fail on size alone,
and the real netlist is the only input of its size.

## 10. The receiver that only a fast remote could break

The NEC infrared receiver read frames correctly in every test with a
remote at the nominal speed. The model test then swept the remote from 23%
slow to 23% fast, since real remotes run from ceramic resonators and
drift. Fast remotes failed: from the 17th bit on, every bit arrived one
place early.

The receiver sent its first 16 bits to the host straight after reading
the 16th. Those two extra clock ticks were enough, with the remote running
fast and the next bit a 0, to miss the start of the next burst. The word
is now sent during the silence before a read, and the path that sends and
the path that does not take exactly the same time.

*Found by:* a source with its speed swept across the range real devices
have. *Lesson:* the same one as the PS/2 story. At typical timing the bug
does not exist.

## 11. The driver that outgrew the board

The driver is tested unchanged in cocotb, which runs it in ordinary
Python on a laptop. Eight protocol classes were added to it for v2.0 and
every cocotb test passed.

The board check then failed before running anything: "MemoryError: memory
allocation failed, allocating 12520 bytes". MicroPython compiles a module
whole, in the microcontroller's own memory, and on an RP2040 the one file
no longer fitted. On a real board the driver would not have loaded at
all.

The v2.0 protocols' drivers are now a second file,
`host/more_protocols.py`, loaded after the first. The board check runs
every class in it under MicroPython and under ordinary Python and
requires the two to ask the chip for exactly the same things.

*Found by:* MicroPython on the emulated board. *Lesson:* "the same file,
unchanged" is only a claim about the board if the file is also run where
the board runs it.
