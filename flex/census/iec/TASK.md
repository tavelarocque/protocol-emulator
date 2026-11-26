# Task: IEC (Commodore serial bus) controller firmware for the protocol emulator

You are writing firmware for a small programmable I/O chip, the protocol
emulator. You have never seen its source. Everything you may use is in this
directory:

- `isa.md`: the instruction set, its timing and the assembler syntax. It
  mentions files elsewhere in a repository (`model/...`, `hw/...`,
  `docs/info.md`); you do not have them and must not look for them.
- `pe_sim`: the assembler and a simulator of the chip (the reference model
  the hardware is checked against every cycle). `./pe_sim asm FILE.s`
  assembles; `./pe_sim run FILE.s -help` explains how to run a program on
  thread 0 with a configuration, pin modes and words pushed to the TX FIFO,
  and prints every change of the pins' outputs, with the cycle number.

Rules for this test, which is measuring how easy the chip is to program:
- Read only the files in this directory, and write only here. Do not open
  anything elsewhere on the machine (no repository, no other firmware, no
  searching the filesystem). Your general knowledge of the Commodore serial
  bus and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that makes the chip the controller of a Commodore serial bus (the
IEC bus of the C64 and its disk drives and printers), on thread 0, with the
chip's core clock at 1 MHz (one cycle = 1 us; the thread may run every
cycle). The chip plays the computer's part: it addresses one device, sends
it bytes, and lets it go. The device is a listener; it is scripted, and is
described below. The chip never receives data bytes and pushes nothing to
the host.

The receiver of what you send is a logic analyser's IEC decoder (sigrok's
`iec`), reading the three wires as they are on the bus. Everything you need
to know is here.

### The wires

| Pin | Line | Mode |
|---|---|---|
| P0 | DATA | open-drain |
| P1 | CLK | open-drain |
| P2 | ATN | open-drain |

All three are open collector with pull-ups: a line is low if anyone pulls it
low, and high ("released") only when nobody does. `run_args.txt` must make
P0, P1 and P2 open-drain (`-mode 0=od -mode 1=od -mode 2=od`). The other
pins are not used. In the simulator the device's side of the bus is the
input level the stimulus file sets (see below): the device pulls DATA (P0)
and nothing else, and never touches CLK or ATN. All three lines must be
released from the start of the run until the chip begins its first
transaction. A bit on DATA is the line's level: released (high) is 1, low
is 0.

### A transaction

For each transaction the host asks for (device number D from 0 to 30,
secondary address S from 0 to 15, and 1 to 16 data bytes), the chip puts
these bytes on the bus, in this order:

1. LISTEN, the byte 0x20 + D, under ATN,
2. SECOND, the byte 0x60 + S, under ATN,
3. the data bytes, in order, with ATN released, the last one marked EOI,
4. UNLISTEN, the byte 0x3F, under ATN.

So a transaction of n data bytes is n + 3 bytes on the bus. Each byte is
sent with the handshake below. Everything the chip does is timed from the
last thing the device did, and every limit is given in cycles after that
event (the event's own cycle, in the stimulus file, counts as 0; your
inputs show it two cycles later, as `isa.md` explains). Limits are
inclusive.

**Starting a transaction.** The bus is "free" from cycle 0 of the run, and
again whenever the device releases DATA at the end of a transaction.

- The chip pulls ATN low 100 to 400 cycles after the bus went free, and
  pulls CLK low 0 to 20 cycles after ATN (it may be the same cycle). DATA
  stays released.
- The device answers by pulling DATA low ("I am here"), 450 to 950 cycles
  after the bus went free.

**Sending one byte** (all n + 3 bytes the same way):

1. Ready to send: CLK is low and the device holds DATA low. The chip
   releases CLK 100 to 400 cycles after the device pulled DATA low (for the
   first byte that is the "I am here" above, for the others the
   acknowledge of the byte before).
2. Ready for data: the device releases DATA, 450 to 950 cycles after it
   pulled DATA low.
3. a. For every byte except the last data byte of the transaction: the
      chip pulls CLK low 0 to 200 cycles after the device released DATA.
   b. For the last data byte (EOI): the chip keeps CLK released and waits.
      250 to 350 cycles after it released DATA, the device pulls DATA low
      for 80 to 120 cycles and releases it again (the EOI acknowledge). The
      chip pulls CLK low 0 to 60 cycles after the device released DATA
      that second time.
4. Eight bits, least significant first. For each bit, starting from the
   CLK fall of step 3: the chip sets DATA to the bit (releases it for 1,
   pulls it low for 0) while CLK is low, releases CLK, and pulls CLK low
   again. Limits:
   - CLK low for at least 20 cycles before each rise,
   - CLK high for at least 20 cycles (the device reads DATA while CLK is
     high),
   - 40 to 100 cycles from each CLK fall to the next, counting from the
     fall of step 3, so the 8th bit ends with the 8th fall after it,
   - DATA may change only while CLK is low, and must then stay unchanged
     for at least 20 cycles before CLK rises. (DATA may change in the same
     cycle as a CLK fall.)
5. After the 8th CLK fall the chip releases DATA within 20 cycles (at once
   if the last bit was a 1), and keeps CLK low.
6. Acknowledge: the device pulls DATA low, 1050 to 1320 cycles after it
   released DATA in step 2, or for the EOI byte 910 to 1320 cycles after
   the end of its EOI pulse. That is the next byte's step 1.

The chip pulls DATA low only during step 4 and the 20 cycles of step 5,
and moves CLK and ATN only as described here.

**ATN.**

- After SECOND is acknowledged, the chip releases ATN 20 to 90 cycles
  after the device pulled DATA low (CLK stays low). The data bytes follow.
- After the last data byte is acknowledged, the chip pulls ATN low again
  20 to 90 cycles after the device pulled DATA low. UNLISTEN follows,
  with CLK released as step 1 says.
- After UNLISTEN is acknowledged, the chip releases both ATN and CLK, each
  20 to 90 cycles after the device pulled DATA low. The device then
  releases DATA, 150 to 250 cycles after it pulled it low: the bus is free
  and the next transaction may start (100 to 400 cycles after that, as
  above). After the run's last transaction nothing moves again.

### The device

The device's DATA level is a script written before the run, in the
simulator's `-stimulus` format (`CYCLE HEX` per line; bit 0 of HEX is the
device's DATA, every other bit is always 1). It cannot react to what the
chip does: each of its delays is drawn at random, within the ranges above,
before the run starts, and every run draws them anew (some runs use every
shortest delay, some every longest). It always follows the sequence above,
so the chip must follow it too, and must time every action from the
device's DATA changes, not from the start of the run.

An example of one transaction, device 4, secondary address 7, data "HI":
the bus carries 0x24 (LISTEN 4), 0x67 (SECOND 7), 0x48, 0x49 (EOI), 0x3F
(UNLISTEN). With a device that always took its shortest delays, the
stimulus file would read

    0 ff
    450 fe
    900 ff
    1950 fe
    2400 ff
    3450 fe
    3900 ff
    4950 fe
    5400 ff
    5650 fe
    5730 ff
    6640 fe
    7090 ff
    8140 fe
    8290 ff

and the chip's ATN would fall at cycle 100 to 400, its CLK release for the
first byte come at cycle 550 to 850, and so on.

### The host interface

The host (a microcontroller) feeds the chip 16-bit words through the TX FIFO
(4 deep). What the words mean is fixed by this sheet:

- A transaction is a header word followed by one word per data byte.
- Header: bits 4..0 are the device number D (0 to 30), bits 11..8 the
  secondary address S (0 to 15), all other bits 0.
- Data word: bits 7..0 are the byte, bit 8 is 1 on the last data byte of
  the transaction and 0 otherwise, all other bits 0.
- Transactions follow one another with nothing between them.

So the example above arrives as the three words 0x0704, 0x0048, 0x0149,
and a transaction of one data byte is two words.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The command bytes (LISTEN, SECOND, UNLISTEN), ATN, EOI, the handshake and
every delay are the firmware's: nothing in a word says what a line does.

A run is 1 to 4 transactions. The test writes the run's words to a file,
one per line, and the device's script to another, and runs
`./pe_sim run iec.s -tx FILE -stimulus FILE -cycles N` followed by the
arguments in `run_args.txt`, from reset, once for each run. N is 2000
cycles more than the time at which the device frees the bus after the last
transaction. In the simulator, the TX FIFO is refilled as soon as it has
room, so you do not need to worry about the host being slow. When the words
have run out, the chip must leave every line released.

## What to hand in (all in this directory)

1. `iec.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx`, `-stimulus` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that builds the bus from your pins and the
device's script, decodes it the way the receiver above would, and measures
every limit above, on transactions and device timings you have not seen.
