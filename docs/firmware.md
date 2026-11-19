# Firmware

Every protocol engine, what it does and what it cost. The assembly is in
[`examples/`](../examples), one file per engine, generated from the source
the tests run: [`model/firmware.ml`](../model/firmware.ml). Program memory
is 64 words.

## Engines

| Engine | Instructions | What it does |
|---|---|---|
| UART TX | 15 | 8N1, bit time set by the host at run time |
| UART RX | 15 | mid-bit sampler; tolerates the sender's baud rate off by about 5%, the limit for that method; recovers from framing errors |
| SPI controller | 26 | mode 0, 9 cycles per bit, any speed |
| SPI controller, side-set | 26 | 2 cycles per bit: 5 Mbit/s at 10 MHz |
| SPI device | 23 | mode 0 up to 625 kHz at 10 MHz; deselect seen even mid-byte |
| I2C controller, loops | 49 | writes only, timed by counter loops |
| I2C controller, divider | 25 | reads and writes, timed by the clock divider; clock stretching and timeouts |
| I2C target | 63 | the chip as a 7-bit-address device: address match, ACK, STOP and repeated START detection, stretching while either FIFO waits on the host |
| JTAG controller | 11 | any TMS/TDI sequence the host asks for, TDO back, TCK at 2 MHz |
| Arm SWD | 11 | a clock engine; the driver adds the SWD framing: line reset, the JTAG-to-SWD switch, parity, ACK, turnaround, posted AP reads |
| Low-speed USB host | 49 | sends a packet at exactly 8 clocks per bit with EOP, or receives one with clock recovery that re-aligns on every edge and detects EOP; the driver builds and checks packets, CRCs and the control-transfer logic |
| 1-Wire | 25 | reset and presence, read and write time slots at standard speed; the driver adds the ROM commands, the ROM search and CRC8 |
| WS2812 LEDs | 16 | written blind, see below |
| PS/2 host | 11 + 21 | a receiver on one thread that never stops listening and a transmitter on the other; the receiver tells the transmitter through a spare pin when a frame is under way, so a host byte never cuts one off too late for the device to notice |
| CAN | 19 + 27 | a transmitter that arbitrates and reads the ACK slot, and a listen-only receiver that resynchronises on every falling edge, up to 1 Mbit/s. Not a full node: it does not acknowledge other nodes' frames |
| I2S transmitter | 11 | 16-bit stereo, bit clock and word select made by the chip, 2.5 MHz bit clock at 10 MHz; the next sample is fetched inside the last bit, so the clock never stretches while the host keeps up |
| DMX512 transmitter | 26 | break, mark after break, start code and slots at 250 kbit/s, two stop bits; the break is counted in the input shift register's bit counter, the only counter left free |
| Wiegand transmitter | 17 | any frame length; 50 us pulses exactly 1 ms apart, also across word boundaries |
| NEC infrared transmitter | 25 | the 38 kHz carrier included, so the pin drives an IR LED; leader, 32 bits by pulse distance, final burst |
| MDIO controller | 7 | clause 22 reads and writes, MDC up to 2.5 MHz; the data line is open-drain, and each word shifted out comes back as the word read meanwhile, so one loop serves both directions |
| DALI forward frame transmitter | 17 | 1200 bit/s Manchester code with every half bit exactly the same length; the bit loop exists twice, once for each level the bus may be holding while the next bit is fetched |
| RC-5 infrared transmitter | 37 | the 36 kHz carrier included; looks one bit ahead so that where a 1 meets a 0 their two bursts are one unbroken burst |

Everything from the I2C target down was written after the hardware was
frozen at v1.4, as firmware alone.

The last seven were written on v2.0, each tested by handing the recorded
pins to sigrok's decoder for that protocol. MDIO also reads from a PHY
model written from the standard, one that takes the full 300 ns it is
allowed to answer.

**Protocols that need no engine of their own.** Some protocols are an
existing engine at particular settings plus framing on the host, and are
tested the same way, with sigrok's decoder for the device stacked on its
decoder for the bus:

| Protocol | Engine | Judged by |
|---|---|---|
| MIDI | UART transmitter, 320 clocks per bit (31,250 baud) | sigrok's MIDI decoder reads the notes |
| MAX7219 LED driver | SPI controller, 16-bit frames | sigrok's MAX7219 decoder reads each register write |
| LIN, master frames | DMX512 transmitter (a UART that can send a break), 19,200 baud | sigrok's LIN decoder reads break, sync, identifier, data and checksum, and checks the parity and the checksum |

**The blind test.** The WS2812 driver was written by a programmer (an AI
agent) given only [`isa.md`](isa.md) and the simulator. It passed a hidden
test of the LEDs' data-sheet timing on its first submission, in about five
minutes. Task, notes and the hidden test:
[`examples/ws2812`](../examples/ws2812).

## Two programs in one memory

The assembler places a program at any origin, so two fit in one image:

- full-duplex UART, TX and RX on the two threads
- side-set SPI beside UART
- the bridge: divider I2C beside side-set SPI, with CHAIN carrying every
  byte read over I2C out over SPI, no host in the data path
- the USB host, PS/2 and CAN, each a pair of programs

## How the instruction set got to v1.4

Each revision came from building something.

| Building this | showed that | so |
|---|---|---|
| the I2C controller | 32 words was too small, and a wait timeout counted down in Y could never exceed one half bit-period | the memory doubled and timeouts got their own counter |
| SPI | toggling a clock with a separate instruction costs most of the bit time | side-set |
| the I2C-to-SPI bridge | the I2C controller's delay loops were a third of its size | a clock divider per thread |
| a review for silicon rather than simulation | the protocol pins had no input synchronisers | a two-flip-flop synchroniser per pin, bypassable |
| every SPI host | bit-reversing bytes was an interface wart | a shift direction per thread |
