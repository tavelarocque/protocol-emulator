# Task: FrSky PXX1 transmitter firmware for the protocol emulator

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
  searching the filesystem). Your general knowledge of FrSky PXX1, bit
  stuffing, CRCs and of similar programmable I/O blocks is fine.
- Keep `notes.md` as you go: what you read, your design, every run of
  `pe_sim`, every mistake you found and how. Be honest; the notes are part of
  the result.

## What to build

Firmware that does the job of a radio control transmitter's main processor
towards its RF module: it drives the PXX1 input of a FrSky RF module (an
XJT or an R9M in its module bay) on pin P0 (push-pull), on thread 0, with
the chip's core clock at 50 MHz (one cycle = 20 ns, so 1 us = 50 cycles; the
thread may run every cycle). The chip only transmits: nothing is received.

PXX1 has no published standard; the frame below is the one FrSky's modules
read and the open-source transmitter firmwares send. The receiving end is
the module, and the test also reads the line with a logic analyser's PXX1
decoder. Everything you need to know is here.

### The line

- P0 idles high. A push-pull pin is high from reset, which is the idle
  level, so the line must simply stay high until the first frame.
- Every bit starts with a falling edge. The line is then low for 8 us (400
  cycles) and goes back high until the falling edge of the next bit.
- A bit's value is its length from its falling edge to the next bit's
  falling edge: 16 us (800 cycles) for a 0, 24 us (1200 cycles) for a 1.
- Limits: every low pulse must last 400 cycles +-25 (+-0.5 us), and every
  bit 800 or 1200 cycles +-25, falling edge to falling edge. Each bit is
  measured on its own: the limit is on each pulse and each bit, not on the
  place of an edge counted from the start of the frame.
- The last bit of a frame (a 0, see below) has its 8 us low pulse like
  every other bit, and then the line stays high until the first falling
  edge of the next frame.

### The frame

Bytes are sent most significant bit first. A frame is, in order:

1. The header, the byte 0x7E (bits 0 1 1 1 1 1 1 0). It is not stuffed.
2. Sixteen bytes:
   - the receiver number (the model's receiver ID, 0 to 63 in use; send any
     value as given),
   - flag 1 (bits 7..6 the module's subtype, bit 5 range check, bit 4
     failsafe, bits 3..1 the country code, bit 0 bind),
   - flag 2 (0 in today's transmitters; send it as given),
   - twelve bytes carrying eight 12-bit channel values, two channels in
     three bytes: for channels a and b (1 and 2, then 3 and 4, 5 and 6,
     7 and 8) the bytes are
     - a & 0xFF (the low 8 bits of a),
     - ((b & 0x0F) << 4) | (a >> 8) (the low 4 bits of b, then the top 4
       bits of a),
     - b >> 4 (the top 8 bits of b),
   - the extra flags (bit 6 EU+, bit 5 S.Port off, bits 4..3 power level,
     bit 2 receiver's upper channels, bit 1 telemetry off, bit 0 external
     antenna; send it as given).
3. The CRC of those sixteen bytes, 16 bits, high byte first.
4. The byte 0x7E again, to close the frame. It is not stuffed.

**Bit stuffing.** In parts 2 and 3, after every five 1 bits in a row the
sender puts in one extra 0 bit, which carries nothing. The run of 1s is
counted from the first bit of the receiver number, across byte boundaries,
and starts again from zero at every 0, the stuffed 0s included. If the
CRC's last bit is the fifth 1 of a run, the stuffed 0 comes after it,
before the closing 0x7E. The header and the closing 0x7E are never stuffed
and do not count.

**The CRC** is FrSky's 16-bit CRC. It starts at 0 and takes the sixteen
bytes of part 2 in order (not the header, not the stuffed bits):

    crc = ((crc << 8) & 0xFFFF) XOR T[((crc >> 8) XOR byte) & 0xFF]

where T[v], for v from 0 to 255, is

    T[v] = M(0x1189, v & 0x0F) XOR M(0x1081, v >> 4)

and M(a, n), for a 4-bit n, is the XOR of (a << k) over every bit k set in n
(a carry-less product). The sixteen values T[0] to T[15] are 0x0000,
0x1189, 0x2312, 0x329B, 0x4624, 0x57AD, 0x6536, 0x74BF, 0x8C48, 0x9DC1,
0xAF5A, 0xBED3, 0xCA6C, 0xDBE5, 0xE97E, 0xF8F7; T[16 n] = M(0x1081, n), so
T[16] = 0x1081 and T[128] = 0x8408; and T[255] = 0xF8F7 XOR 0xF78F =
0x0F78. The same table is what
eight steps of `c = (c >> 1) XOR (0x8408 if c is odd else 0)`, starting
from c = v, give: it is the table of the reflected CRC-16 with polynomial
0x8408, used here with a left shift. The result is not CRC-16/KERMIT, nor
CRC-16/XMODEM, nor any other standard CRC; check yours against the examples
below.

A frame is therefore 8 + 128 + 16 + 8 = 160 bits plus its stuffed 0s.

### Frames in time

- A transmitter sends a frame every 9 ms. This sheet accepts any period
  from 8 ms to 10 ms: the first falling edge of each frame must come
  400,000 to 500,000 cycles after the first falling edge of the frame
  before it.
- The first frame's first falling edge must come no earlier than cycle
  5,000 and no later than cycle 500,000 of the run.
- Between frames, and after the last frame until the end of the run, the
  line stays high, with no edge at all.

### Two worked examples

Receiver 3, all flags 0, all eight channels at 1024 (the centre). The
sixteen bytes are

    03 00 00 00 04 40 00 04 40 00 04 40 00 04 40 00

and the CRC is 0x21A3. There is no run of five 1s, so nothing is stuffed:
the frame is these 160 bits,

    01111110 00000011 00000000 00000000 00000000 00000100 01000000 ...
    ... 00000000 00100001 10100011 01111110

(header, receiver number, flag 1, flag 2, the twelve channel bytes, the
extra flags 00, the CRC, the closing 0x7E). Its
first bit is a 0: a falling edge at the frame's time zero, a rise at cycle
400, the next falling edge at cycle 800. The second bit is a 1: its rise at
cycle 1200, the next fall at cycle 2000; and so on.

Receiver 0x1F, flag 1 0x11, flag 2 0, extra flags 0x04, channel 1 0x7FF,
channel 2 0xF81, channels 3 to 8 at 1024. The sixteen bytes are

    1F 11 00 FF 17 F8 00 04 40 00 04 40 00 04 40 04

and the CRC is 0xFF54. With the four stuffed 0s shown in brackets, the
frame's 164 bits are

    01111110
    00011111[0]00010001 00000000 11111[0]111 00010111 11[0]111000
    00000000 00000100 01000000 00000000 00000100 01000000 00000000
    00000100 01000000 00000100 11111[0]111 01010100
    01111110

(spaces only between bytes). The first stuffed 0 follows the five 1s that
end the receiver number; the third follows a run that starts in 0x17 and
ends in 0xF8; the fourth is inside the CRC's high byte.

### The host interface

The host (the transmitter's main microcontroller) feeds the chip 16-bit
words through the TX FIFO (4 deep) and can read 16-bit words back from the
RX FIFO. What the words mean is fixed by this sheet. Each frame is exactly
ten words, frame after frame, with nothing between frames:

- Word 0: bits 15..8 flag 1, bits 7..0 the receiver number.
- Word 1: bits 15..8 the extra flags, bits 7..0 flag 2.
- Words 2 to 9: channels 1 to 8 in order, the 12-bit value (0 to 4095) in
  bits 11..0, bits 15..12 zero.

So the two example frames above arrive as the twenty words 0x0003, 0x0000,
0x0400, 0x0400, 0x0400, 0x0400, 0x0400, 0x0400, 0x0400, 0x0400, 0x111F,
0x0400, 0x07FF, 0x0F81, 0x0400, 0x0400, 0x0400, 0x0400, 0x0400, 0x0400.

The host sends only the words defined above.
All line coding, framing and timing must be done by the firmware.

The header, the packing of the channels into bytes, the CRC, the bit
stuffing, the closing 0x7E, every edge and the frame period are the
firmware's: nothing in a word says where the line changes.

A run is 1 to 4 frames, with any values in the words' fields. The test
writes the run's words to a file, one per line, and runs
`./pe_sim run pxx1.s -tx FILE -cycles N` followed by the arguments in
`run_args.txt`, from reset, once for each run. N is 500,000 times (the
number of frames + 1). In the simulator, the TX FIFO is refilled as soon as
it has room, so you do not need to worry about the host being slow. When
the words have run out, the chip must leave the line high.

## What to hand in (all in this directory)

1. `pxx1.s`: the program.
2. `run_args.txt`: one line with the extra arguments for `pe_sim run`: the
   `-config` and `-mode` flags your program needs, and no other flag. Not
   `-tx` or `-cycles`: the test gives those.
3. `notes.md`, as above, ending with: the program's length in instructions,
   and anything about the chip that was confusing or that you think is
   wrong in `isa.md`.

Test your work with `pe_sim` until you are confident. Then stop: it will be
checked by a separate test that decodes the pin waveform the way the
receiving module would, and measures every pulse, on frames you have not
seen.
