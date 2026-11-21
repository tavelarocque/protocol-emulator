# Firmware

Every protocol engine, what it does and what it cost. The assembly is in
[`examples/`](../examples), one file per engine, generated from the source
the tests run: [`model/firmware.ml`](../model/firmware.ml). Each thread
has 256 words of program memory, in four pages of 64; every engine here
fits in one page except the Ethernet transmitter, which crosses into a
second. The two Ethernet programs are placed at addresses of their own, so
they are not in `examples/`; their source is in `model/firmware.ml` with
the rest.

## Engines

| Engine | Instructions | What it does |
|---|---|---|
| UART TX | 15 | 8N1, bit time set by the host at run time |
| UART RX | 15 | mid-bit sampler; tolerates the sender's baud rate off by about 5%, the limit for that method; recovers from framing errors |
| SPI controller | 26 | mode 0, 9 cycles per bit, any speed |
| SPI controller, side-set | 26 | 2 cycles per bit: 5 Mbit/s at 10 MHz |
| SPI device | 23 | mode 0 up to 625 kHz at 10 MHz; deselect seen even mid-byte |
| I2C controller, loops | 49 | writes only, timed by counter loops |
| I2C controller, divider | 30 | reads and writes, timed by the clock divider; clock stretching and timeouts; a repeated START where the host asks for one, as a register read needs |
| I2C target | 63 | the chip as a 7-bit-address device: address match, ACK, STOP and repeated START detection, stretching while either FIFO waits on the host |
| JTAG controller | 11 | any TMS/TDI sequence the host asks for, TDO back, TCK at 2 MHz |
| Arm SWD | 11 | a clock engine; the driver adds the SWD framing: line reset, the JTAG-to-SWD switch, parity, ACK, turnaround, posted AP reads |
| Low-speed USB host | 49 | sends a packet at exactly 8 clocks per bit with EOP, or receives one with clock recovery that re-aligns on every edge and detects EOP; the driver builds and checks packets, CRCs and the control-transfer logic |
| 1-Wire | 25 | reset and presence, read and write time slots at standard speed; the driver adds the ROM commands, the ROM search and CRC8 |
| WS2812 LEDs | 16 | written blind, see below |
| PS/2 host | 11 + 21 | a receiver on one thread that never stops listening and a transmitter on the other; the receiver tells the transmitter through a spare pin when a frame is under way, so a host byte never cuts one off too late for the device to notice |
| CAN | 89 + 59 | a node: it sends data frames, making each from the identifier and the data (bit stuffing, CRC-15 on the CRC register, arbitration, the ACK slot), and receives every other node's on the bit sampler (clock recovery, stuff bits taken out), checks the CRC and acknowledges, up to 1 Mbit/s (the core clock is 20 times the bit rate, or a multiple of that). It sends no error frames, and leaves frames with 29-bit identifiers alone |
| I2S transmitter | 11 | 16-bit stereo, bit clock and word select made by the chip, 2.5 MHz bit clock at 10 MHz; the next sample is fetched inside the last bit, so the clock never stretches while the host keeps up |
| DMX512 transmitter | 26 | break, mark after break, start code and slots at 250 kbit/s, two stop bits; the break is counted in the input shift register's bit counter, the only counter left free |
| Wiegand transmitter | 17 | any frame length; 50 us pulses exactly 1 ms apart, also across word boundaries |
| NEC infrared transmitter | 25 | the 38 kHz carrier included, so the pin drives an IR LED; leader, 32 bits by pulse distance, final burst |
| MDIO controller | 7 | clause 22 reads and writes, MDC up to 2.5 MHz; the data line is open-drain, and each word shifted out comes back as the word read meanwhile, so one loop serves both directions |
| DALI forward frame transmitter | 17 | 1200 bit/s Manchester code with every half bit exactly the same length; the bit loop exists twice, once for each level the bus may be holding while the next bit is fetched |
| RC-5 infrared transmitter | 37 | the 36 kHz carrier included; looks one bit ahead so that where a 1 meets a 0 their two bursts are one unbroken burst |
| Wiegand receiver | 16 | any frame length; looks at both lines at once by copying all eight pins and peeling off the first two, so pulses down to a microsecond are seen |
| NEC infrared receiver | 33 | on an IR receiver module's output; reads each bit once, 1.3 units after its burst; tolerates a remote 20% fast or slow, ignores repeat codes, and never lets a frame cut short put the host's pairs of words out of step |
| DALI receiver | 9 | through the bit sampler and its prescaler (v2.3): every edge taken and a sample every half bit, since a frame begins on an edge between bits; frames of any length, an answer 2.9 ms after a forward frame; a sender 15% fast or slow. With the transmitter on the other thread it makes a controller: the driver checks each frame it sends against what the receiver heard, then reads the answer |
| RC-5 infrared receiver | 9 | through the bit sampler as Ethernet uses it, at a five-thousandth of the speed; a remote 20% fast or slow; a transmission cut short is dropped |
| Microwire controller | 10 | chip select active high, a transfer of any number of bits, one bit each way on every clock; the divider must be 3 or more, since the device's answer passes the input synchroniser |
| HDMI-CEC initiator | 38 | start bit, blocks of ten bits, the follower's acknowledgement read in each ACK bit; a block that fails ends the message and the rest of it is dropped from the FIFO; seven bit times off the bus after a message. It does not listen before sending or give way to another initiator |
| Infrared burst sender | 7 | bursts of carrier and the silences between, each a whole number of carrier periods, as the host's words say; RC-6 is sent with it, framed by the driver |
| Step and direction | 10 | for stepper motor drivers (A4988, DRV8825): a direction level and a pulse for each step, STEP high for two ticks of an exact period; a move is up to 32,768 steps at one speed, a ramp is moves one after another, and each is reported when its last step is made |
| AM2302 / DHT22 and DHT11 reader | 27 | the start pulse, as long as the host asks; then 40 bits, each read 40 to 45 us after the line rises, where a 0 is over and a 1 is not. Any level that lasts 300 us ends the reading: the host gets zeros for the bits not read and a flag, always four words |
| Level stream sender | 3 | each bit of each word is the pin's level for one cell, sixteen cells to a word with no gap between words; the line holds its level when the host has no more. Qi packets, EM4100 tags and Morse are sent with it, framed by the driver |
| TDM audio transmitter | 18 | frames of any number of 16-bit slots on one data line, most significant bit first; frame sync high for the one bit before a frame's first; the clock pauses, low, when the host has no more |
| TLC5620 writer | 12 | 11 bits clocked into the DAC, a pulse on LOAD, and on request a pulse on LDAC, so several outputs can change together; a tick must be 100 ns or more |
| PWM, and RC servo pulses | 8 | high time and period each exact to the tick; the two counts live in the two shift registers, which leaves X free to count |
| NES gamepad | 7 | read as the console reads it: latch, then eight clocks, a button read as each clock falls |
| 10BASE-T Ethernet transmitter | 70 | a whole frame at 10 Mbit/s with a 40 MHz clock, 4 clocks a bit: preamble, start-of-frame delimiter, the frame played from the packet buffer, its CRC-32 from the CRC register, the idle signal. Frames up to the full 1514 bytes. Between frames, a link pulse of 100 ns every 16 ms, timed by ten waits that run out. The first program longer than a page |
| 10BASE-T Ethernet receiver | 14 | frames at 10 Mbit/s with a 40 or 50 MHz clock. The bit sampler recovers the sender's clock and decodes the Manchester code; the program takes each bit with one IN, counts it, lets the CRC register follow it, and at the end of the frame pushes the count and the CRC for the host to check. The packet buffer records the frame. Frames up to the full 1518 bytes with the check sequence |

Everything from the I2C target down to CAN was written after the hardware
was frozen at v1.4, as firmware alone.

The last eleven were written on v2.0, whose only hardware change is the
program memory; they too needed no change to the RTL. The transmitters are each tested by
handing the recorded pins to sigrok's decoder for that protocol; the two
receivers by sources written from the protocol's rules, with remotes off
speed, frames cut short and, for NEC, repeat codes. MDIO also reads from a PHY
model written from the standard, one that takes the full 300 ns it is
allowed to answer.

The Ethernet transmitter is the first engine on v2.1, which added what it
needed and nothing about Ethernet: automatic refill of the OSR, the packet
buffer and a CRC register with the polynomial the host's to set
([`isa.md`](isa.md), revision history). On the reference model its frames
are taken by a receiver written from IEEE 802.3, and at chip level by one
whose CRC-32 is Python's `zlib`. Between frames it sends the link pulses
that tell a switch or a network card someone is there: the 16 ms between
them is ten waits on the thread's own TD+ pin, which it holds low, so
each wait runs out and lands on the timeout vector that counts it. The
chip's own receiver, listening to the same pin, takes none of them for
data.

The receiver is the first engine on v2.2, which added the bit sampler: the
one thing a thread could not do at 4 clocks a bit was find the bit, so
hardware does that and only that. The program is 14 instructions and has
nothing about Manchester code in it. On the reference model it takes
frames from a sender written from IEEE 802.3 whose clock is not the chip's
and whose edges are jittered, and thread 1 receives what thread 0 sends;
at chip level the sender is in the test bench, 100 ppm off and with 5 ns
of jitter on every edge, and its CRC-32 is `zlib`'s. The chip has one
packet buffer, so it sends a frame or receives frames, not both at once.

**Protocols that need no engine of their own.** Some protocols are an
existing engine at particular settings plus framing on the host, and are
tested the same way, with sigrok's decoder for the device stacked on its
decoder for the bus:

| Protocol | Engine | Judged by |
|---|---|---|
| MIDI | UART transmitter, 320 clocks per bit (31,250 baud) | sigrok's MIDI decoder reads the notes |
| MAX7219 LED driver | SPI controller, 16-bit frames | sigrok's MAX7219 decoder reads each register write |
| LIN, master frames | DMX512 transmitter (a UART that can send a break), 19,200 baud | sigrok's LIN decoder reads break, sync, identifier, data and checksum, and checks the parity and the checksum |
| Modbus RTU requests | UART transmitter; the CRC is the host's | sigrok's Modbus decoder reads the request and checks the CRC; the frame is the example in the Modbus specification |
| 24Cxx EEPROM | I2C controller | sigrok's 24xx decoder names a page write and a byte write; cocotbext-i2c's memory holds and returns the data |
| DS1307 real-time clock | I2C controller | sigrok's DS1307 decoder reads the date and time out of the bytes written and read |
| LM75 temperature sensor | I2C controller | sigrok's LM75 decoder reads the temperature |
| RTC-8564 real-time clock | I2C controller, read through a repeated START | sigrok's RTC-8564 decoder reads the time out of the bytes written and of the bytes read back |
| TCA6408A port expander | I2C controller, read through a repeated START | sigrok's TCA6408A decoder names the configuration, the outputs set and the inputs read, and has no warning |
| MXC6225XU accelerometer | I2C controller, read through a repeated START | sigrok's decoder for the part reads the X and Y values |
| A monitor's EDID, over DDC | I2C controller: the pointer, a repeated START, 128 bytes | sigrok's EDID decoder finds the header and the maker's letters, and the checksum adds up |
| SPI NOR flash commands | SPI controller | sigrok's flash decoder names the commands, the address and the data; picosoc's flash model answers |
| WS2801 LED pixels | SPI controller | sigrok's decoder for SPI LED strips reads the colours |
| nRF24L01 radio | SPI controller | sigrok's nRF24L01 decoder names each command and reads the register the device answered with |
| CC1101 radio | SPI controller | sigrok's CC1101 decoder reads the strobes, a register write and read, and the status byte |
| RFM12 radio | SPI controller, 16-bit commands | sigrok's RFM12 decoder reads the band and crystal load the configuration sets |
| MRF24J40 802.15.4 radio | SPI controller | sigrok's MRF24J40 decoder reads short- and long-address register accesses |
| ENC28J60 Ethernet controller | SPI controller | sigrok's ENC28J60 decoder reads a reset, a register write, a read and a bit set |
| ADF435x synthesiser | SPI controller, 32-bit writes | sigrok's ADF435x decoder reads the fields of each register |
| SD card, SPI mode | SPI controller | sigrok's SD card decoder reads CMD0 and CMD8 with their arguments and CRCs, and the card's answers |

One limit these tests turned up: the I2C controller started a transfer
only after a STOP, so it could not send the repeated START some devices
ask for between setting a register pointer and reading. It can now: a bit
in the host's word asks for one after a byte, and the three device tests
above read their registers that way.

For the last seven rows the device is a script of the bytes the part would
answer, not a model of the part. The drivers for them are the SPI
controller's `transfer`; nothing is added to the host library.

**The blind test.** The WS2812 driver was written by a programmer (an AI
agent) given only [`isa.md`](isa.md) and the simulator. It passed a hidden
test of the LEDs' data-sheet timing on its first submission, in about five
minutes. Loaded on the chip with its own encoder, it is also read by
sigrok's WS281x decoder. Task, notes and the hidden test:
[`examples/ws2812`](../examples/ws2812).

## Two programs at once

On v1.4 the two threads shared one memory of 64 words, so two programs
had to fit in it together. On v2.0 each thread has 256 words of its own,
and the host chooses with the LOAD register which memory a program is
written to. Left alone, LOAD writes both, so a v1.4 image with two
programs at different origins loads and runs as it always did. These are
such images:

- full-duplex UART, TX and RX on the two threads
- side-set SPI beside UART
- the bridge: divider I2C beside side-set SPI, with CHAIN carrying every
  byte read over I2C out over SPI, no host in the data path
- the USB host, PS/2 and CAN, each a pair of programs

## How the instruction set got here

Each revision came from building something.

| Building this | showed that | so |
|---|---|---|
| the I2C controller | 32 words was too small, and a wait timeout counted down in Y could never exceed one half bit-period | the memory doubled and timeouts got their own counter |
| SPI | toggling a clock with a separate instruction costs most of the bit time | side-set |
| the I2C-to-SPI bridge | the I2C controller's delay loops were a third of its size | a clock divider per thread |
| a review for silicon rather than simulation | the protocol pins had no input synchronisers | a two-flip-flop synchroniser per pin, bypassable |
| every SPI host | bit-reversing bytes was an interface wart | a shift direction per thread |
| the I2C target, and a CAN node that acknowledges | 64 shared words held one large program and nothing beside it, and a flip-flop memory could not be made larger | 256 words per thread in SRAM, and a PAGE register for jumps (v2.0) |
