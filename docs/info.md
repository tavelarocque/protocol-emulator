## How it works

A protocol emulator: a small CPU whose instructions read pins, write pins
and count cycles, so hardware protocols (UART, SPI, I2C and others) are
implemented in firmware loaded after fabrication, instead of in fixed logic.
The instruction set is PIO-style (one instruction per clock, a delay field
on every instruction, shift registers feeding host FIFOs) with wait
timeouts and native open-drain pins added. The full specification is in
`docs/isa.md` in the repository. The hardware is written in Hardcaml (OCaml)
and verified cycle by cycle against an executable reference model.

The host talks to the chip over SPI (mode 0, MSB first, SCK at most 1/8 of
the core clock). Each transaction is 24 bits: a read/write bit, a 7-bit
register address, and 16 data bits. Through it the host loads the program
memories (256 words for each thread, in SRAM, written 64 words at a time),
configures each thread and the 8 protocol pins (each input, push-pull or
open-drain), enables the threads, and moves data through each thread's
4-deep TX and RX FIFOs. The two threads run at the same time, each
executing one instruction per clock; if both write the same pin in the
same cycle, thread 1 wins.

A program write goes to the page, and to the memories, that the LOAD
register names. LOAD resets to "page 0 of both memories", so loading one
image and never touching LOAD gives two threads that share a program, as
on v1.4. The memories are not cleared by reset: load a program before
enabling a thread. A write to the memory of an enabled thread is ignored.
A jump reaches the 64 words of the page in the thread's PAGE register,
which START sets and `set page, n` changes; START and TIMEOUT_VECTOR are
full 8-bit addresses.

Thread 0's registers are at 0x41-0x4F; thread 1 has an identical bank at
0x51-0x5F. CTRL, PIN_MODES, SYNC_BYPASS, LOAD and the packet buffer's four registers
are global. Every protocol
pin's input passes through a two-flip-flop synchroniser (two cycles of
delay) unless its SYNC_BYPASS bit is set; the side-set SPI controller needs
it set on MISO.

| Address | Register |
|---|---|
| 0x00-0x3F | program memory (write): word 0-63 of the page, in the memories, that LOAD names |
| 0x40 | CTRL: bit 0 enables thread 0, bit 1 thread 1; bit 2 CHAIN (thread 0's RX FIFO feeds thread 1's TX FIFO) |
| 0x41 | START address [7:0] |
| 0x42 | OUT pins: base [2:0], count [7:4] |
| 0x43 | SET pins: base [2:0], count [7:4] |
| 0x44 | IN base [2:0] |
| 0x45 | THRESHOLD (bits per FIFO word, 1-16) |
| 0x46 | TIMEOUT_VECTOR [7:0] |
| 0x47 | PIN_MODES, 2 bits per pin: 0 input, 1 push-pull, 2 open-drain |
| 0x48 | TX FIFO (write) |
| 0x49 | RX FIFO (read) |
| 0x4A | STATUS: pc [15:8], enable [7], RX level [6:4], TX level [2:0] |
| 0x4B | TIMEOUT: max cycles a timed wait stalls |
| 0x4C | SIDESET: base pin [2:0], count [5:4] |
| 0x4D | CLKDIV: the thread runs one cycle in every CLKDIV (0, 1: every cycle) |
| 0x4E | SYNC_BYPASS (global): 1 bit per pin; set to read that pin without the 2-cycle input synchroniser |
| 0x4F | SHIFT: bit 0 OUT most significant bit first, bit 1 IN most significant bit first; bit 2 autopull, bit 3 autopush; bit 4 the CRC register reads inverted, bit 5 it follows IN's bits, not OUT's |
| 0x50 | LOAD (global): page that program writes go to [1:0]; bit 4 write thread 0's memory, bit 5 thread 1's. Resets to 0x30 |
| 0x51-0x5F | thread 1: same layout as 0x41-0x4F (0x57 and 0x5E unused) |
| 0x61, 0x62 | CRC_POLY, low and high half: the CRC register's polynomial, low power first (thread 1: 0x71, 0x72) |
| 0x63, 0x64 | CRC_INIT, low and high half: what the CRC register starts from (thread 1: 0x73, 0x74) |
| 0x68 | BUF_CTRL (global): the packet buffer. Bits [1:0] = 1 play into a thread's TX FIFO, 2 record from its RX FIFO, 0 leave it to the host; bit 2 which thread |
| 0x69 | BUF_PTR (global): the buffer's pointer, 0 to 1023. A write sets it; it reads back as it stands |
| 0x6A | BUF_END (global): playing and recording stop when the pointer gets here |
| 0x6B | BUF_DATA (global): a write stores at the pointer, a read returns the word there, and each moves the pointer on; only while BUF_CTRL is 0 |
| 0x67 | SMP_PRE (global): three more settings of the bit sampler, all 0 after reset. [9:0] its prescaler: 0 for two samples a clock cycle, otherwise one sample every that many cycles, and the pulse lasts as long; [12:10] how many pins on from its own the threads see the recovered bit, with the pulse on the pin after that; [15:13] stuff bits: the opposite bit after a run of that many equal bits is taken out (0: off) |
| 0x6C | SMP_CTRL (global): the bit sampler. Bit 0 on; [3:1] its pin (the threads then see the recovered bit on that pin and a pulse for each bit on the next); bit 4 invert; bit 5 pass bits on only after SMP_SYNC has been seen; [8:6] bit times without an edge before the carrier is lost (7: never) |
| 0x6D | SMP_TIME (global), in samples, two to a clock cycle: [4:0] the phase from which an edge is accepted, [9:5] the phase at which a bit is taken, [14:10] the phase at which a bit time has gone by |
| 0x6E | SMP_SYNC (global): the sync word, 8 bits, first bit lowest |
| 0x6F | SMP_STATUS (read): bit 0 carrier, bit 1 sync word seen |

Status pins: uo[1] thread 0 running, uo[2] thread 0 RX data waiting, uo[3]
thread 0 TX FIFO full; uo[4]-uo[6] the same for thread 1.

## How to test

`host/protocol_emulator.py` is a MicroPython driver for the demo board
(the RP2350 board v3 for the IHP shuttles, or the older RP2040 boards; it
takes the pins from the Tiny Tapeout SDK's map of whichever board it finds):
copy it and the `.hex` images from `test/` to the board, enable the
project, clock it at 10 MHz (`tt.clock_project_PWM(10_000_000)`), and
`pe.Chip(pe.demo_board_port())` gives register access, firmware loading and
FIFO push/pop, with a class for each protocol: UART TX, the SPI controller,
the I2C and SPI device modes, JTAG, SWD, USB host, 1-Wire, PS/2 and CAN. The cocotb tests run this same file against the chip. The
register-level recipes below are what it does underneath. The UART, I2C,
SPI, JTAG, SWD and USB classes have also run in MicroPython on an emulated
demo board wired to the chip's RTL (`test/board_emu`), the closest thing to
the board short of one; the 1-Wire, PS/2 and CAN classes have run in cocotb
only.

The drivers for the protocols added on v2.0 (I2S, DMX512, Wiegand and NEC
infrared in both directions, RC-5 infrared, MDIO, DALI, LIN, PWM and
servo pulses, the NES gamepad) are in `host/more_protocols.py`: copy it too
if you use them. They are a second file because MicroPython compiles a
module whole, and on an RP2040 one file with every driver no longer fits
in memory.

With the demo board's microcontroller as SPI host: load a firmware image (for
example the 15-instruction UART transmitter in `test/uart_tx.hex`) into
addresses 0x00 upwards, set PIN_MODES to 0x0001 (P0 push-pull), write 1 to
CTRL (0x40), then write `divisor - 4` and then bytes to the TX FIFO. P0 outputs
8N1 UART at `clock / divisor` baud. `test/echo.hex` instead returns every TX
FIFO word on the RX FIFO.

Both threads at once: `test/two_protocols.hex` holds the side-set SPI
controller at address 0 and the UART transmitter at address 26. Configure
thread 0 for SPI (SIDESET 0x10, OUT 0x31, IN base 2) and thread 1 for UART
on P4 (START 26, OUT 0x14, SET 0x14 in its bank at 0x50), set PIN_MODES to
0x0145, SYNC_BYPASS to 0x04 (MISO), and write 3 to CTRL. SPI words go to 0x48, UART words to 0x58.

Full-duplex UART: `test/uart_duplex.hex` holds the transmitter at 0 and the
receiver at 15. Thread 0 sends on P0; thread 1 receives on P1 (bank at 0x50:
START 15, IN base 1, THRESHOLD 9, TIMEOUT 0, TIMEOUT_VECTOR 28). Push
`divisor - 4` to each thread, then `divisor/2 - 1` to thread 1; bytes pushed
to 0x48 go out on P0, bytes received on P1 come back from 0x59 with bit 8 set
for a good stop bit.

The I2C-to-SPI bridge: `test/bridge.hex` holds the I2C controller at 0 and
the side-set SPI controller at 30. Thread 0 runs I2C on P0 (SDA) and P1
(SCL), open-drain; thread 1 runs SPI on P2-P5 (SCK, MOSI, MISO, CS_N).
Writing 7 to CTRL starts both threads with CHAIN set: the host queues an
I2C read on thread 0 and each byte read comes out over SPI with no further
host involvement, one SPI transfer per I2C read. `test/test.py`
(`test_bridge`) has the full register setup.

JTAG controller: `test/jtag.hex` (11 words) drives TCK on P0 (side-set),
TMS on P1 and TDI on P2, and samples TDO on P3 (SIDESET 0x10, OUT 0x21, IN
base 3, THRESHOLD 16; P0-P2 push-pull). Each scan is one word holding the
number of clocks minus one, then one word per 8 clocks of (TMS, TDI) bit
pairs; TDO comes back 8 bits per word. The board driver's `JtagController`
wraps this as `reset()`, `shift_ir()` and `shift_dr()`.

SWD: `test/swd.hex` (11 words) clocks SWCLK on P0 (side-set) and drives and
samples SWDIO on P1, which must be open-drain with a pull-up (SIDESET 0x10,
OUT 0x11, IN base 1, THRESHOLD 16). Each batch is one word holding the
number of clocks minus one, then one word per 16 clocks of SWDIO bits (1
releases the line); the samples come back 16 per word. The board driver's
`SwdController` builds SWD on top: `connect()` (line reset, JTAG-to-SWD,
DPIDR), `read_dp`, `write_dp`, `read_ap`, `write_ap`.

1-Wire (DS18B20 temperature sensors and other 1-Wire devices, standard
speed): `test/onewire.hex` (25 words) drives DQ on P0, open-drain, with an
external pull-up (4.7 kohm is usual). Set CLKDIV to the core clock in MHz,
so the engine counts in microseconds. Each TX word is one exchange: 1 for a
reset pulse (the RX word's bit 0 reads 0 if a device answered), or N - 1 in
bits 3:1 and N bits to write in bits 11:4 for N time slots (1 to 8); the RX
word holds the line as sampled in each slot, so writing 1s reads. The board
driver's `OneWire` adds the ROM commands, the ROM search and CRC8, and reads
a DS18B20's temperature.

PS/2 (keyboards and mice): `test/ps2.hex` (32 words) is the host on both
threads, DATA on P0 and CLK on P1, open-drain, each with a pull-up; P2 is
used between the threads and must be left unconnected. Set CLKDIV on both
threads to the core clock in MHz. Thread 0 receives: each RX word is one
11-bit frame, start bit in bit 0, the byte in bits 8:1, odd parity in bit
9, the stop bit in bit 10. Thread 1 sends: one TX word a byte (the byte,
its odd parity in bit 8, a 1 in bit 9), and one RX word back, 0 if the
device acknowledged, 1 if not, 3 if it never clocked. The board driver's
`Ps2` has `read()` and `write()`.

CAN (classical, 11-bit identifiers): `test/can.hex` (187 words), RXD on P0
and TXD on P1 through a 3.3 V transceiver; P2 and P3 are taken by the bit
sampler. The chip is a node: it sends data frames and receives and
acknowledges other nodes'. The core clock must be 20 x the bit rate x a
whole number n, and n is CLKDIV for both threads and the sampler's
prescaler: 4 for 125 kbit/s at 10 MHz.

The sampler listens to P0 and shows the recovered bits on P2 with a pulse
for each on P3: SMP_PRE = n | 2 << 10 | 5 << 13 (prescaler n, two pins on,
stuff bits after 5 equal bits taken out), SMP_TIME 0x4DA0 (every edge
accepted, the bit taken 13 samples after one, 20 samples to a bit),
SMP_CTRL 0x1C1 (on, pin 0, the carrier never lost).

Thread 1, the transmitter, starts at 0: THRESHOLD 15, autopull, SET_CFG
and OUT_CFG on P1, TIMEOUT 0, TIMEOUT_VECTOR 36, CRC_POLY 0x4CD1,
CRC_INIT 0. It takes the number of bits less one, then the bits from the
identifier to the end of the data, 15 to a word, and makes the frame
itself: start bit, bit stuffing, CRC, arbitration. It reports 0 if a node
acknowledged the frame, 1 if none did, 2 if it lost arbitration and the
frame should be sent again. Send one frame at a time.

Thread 0, the receiver, starts at 128: IN_BASE 2, THRESHOLD 15, IN most
significant bit first, autopush, the CRC register following IN, SET_CFG
on P1, TIMEOUT 200, TIMEOUT_VECTOR 131, CRC_POLY 0x4CD1, CRC_INIT 0. For
each frame from another node it pushes the 14 bits identifier, RTR, IDE
and r0; then DLC, data and CRC in words of 15 bits, the last one short;
then 0xFFFF if the CRC was right, in which case it has acknowledged the
frame, or 0xFFFE if not. The board driver's `Can` does all of this
(`send`, `receive`).

It sends no error frames: a frame it finds wrong it does not acknowledge.
It does not receive or acknowledge frames with 29-bit identifiers. When it
is started it waits for the bus to be recessive for ten bit times before
it takes a frame, so a frame already under way, or one that starts sooner
than that, is not received. While
a frame arrives the host must take a word every 15 bit times; if it does
not, the receiver stops and the frame goes unacknowledged.

Low-speed USB host: `test/usb_host.hex` holds the USB engine (49 words, at
5) and the echo program (at 0), which relays to it through CHAIN so the two
threads' FIFOs buffer a whole transaction. The core clock must be 12 MHz
(8 clocks per bit at 1.5 Mbit/s). The chip drives a USB 1.1 transceiver in
VO/FSE0 mode, since firmware cannot release a push-pull pin: VP on P0 and
VM on P1 (the transceiver's single-ended receivers), VO on P2, FSE0 on P3
and OE_N on P4 (push-pull). The board driver's `UsbHost` sets it up and
offers `transaction()` (packets to send and one receive, with the engine
doing EOP, turnaround and clock recovery) and `control_read()` (SETUP, IN
data stages, OUT status). Commands go to thread 0 and results come from
thread 1, whichever thread the engine runs on. Give it `pe.Chip(pe.PioPort())`,
not the bit-banged port: an IN transaction's handshake must reach the chip
within about 100 us of the engine starting, and `PioPort` runs the host
port from one of the microcontroller's PIO state machines so it does
(SCK, CS_N and MOSI on ui_in[0] to [2], MISO on uo_out[0]: GPIO 17 to 19 and
33 on the RP2350 board, 9 to 11 and 5 on the RP2040 boards). Create it after
`clock_project_PWM`, which can change the system clock the port's timing
is derived from. Bit-banged from MicroPython, each register access takes
milliseconds (`test/board_emu`).

10BASE-T Ethernet transmit: `test/eth_tx.hex` (70 words, loaded with its
first at 51), TD+ on P0 and TD- on P1, push-pull. The core clock must be
40 MHz, 4 clocks a bit. The chip makes the preamble, the Manchester code,
the CRC-32 frame check sequence and the idle signal; the host stores the
frame in the packet buffer, sets the buffer playing into thread 0 and
starts the thread (SHIFT 0x14: autopull, CRC read inverted; CRC_POLY
0xEDB88320, CRC_INIT 0xFFFFFFFF; SIDESET 0x20; THRESHOLD 16; START 51, or
53 for a frame with an odd number of bytes, whose first word holds one
byte in its top half). After a frame, and from the start if the thread
is started at 113, it sends a link pulse, TD+ high for 100 ns, every ten
waits of TIMEOUT ticks (TIMEOUT 64000 for 16 ms; TIMEOUT_VECTOR 115).
`EthernetTx` in `host/more_protocols.py` does all of it: creating it
starts the link pulses, and `send(frame)` sends a frame.

10BASE-T Ethernet receive: `test/eth_rx.hex` (14 words), the pair on P2
through a line receiver; P3 is taken too. The bit sampler recovers the
sender's clock from samples on both clock edges and decodes the Manchester
code, and passes nothing on until the delimiter 0xD5 has gone by (at
40 MHz: SMP_TIME 0x2C25, SMP_SYNC 0xD5, SMP_CTRL 0x25; at 50 MHz SMP_TIME
0x3847). The thread shifts the bits in, 16 to a word, with the CRC register
following them, and the packet buffer records the words (SHIFT 0x28:
autopush, CRC follows IN; CRC_POLY 0xEDB88320, CRC_INIT 0xFFFFFFFF; IN base
2; THRESHOLD 16; TIMEOUT 8, TIMEOUT_VECTOR 7; BUF_END 1023, BUF_CTRL 2).
After each frame come three more words: 0x10000 minus the number of bits,
then what the CRC register ended at, low half first, which is 0xDEBB20E3
for a frame whose check sequence is right. An odd last byte has a word to
itself. `EthernetRx` in `host/more_protocols.py`: `listen()`, then
`frames()`. There is one buffer, so the chip sends a frame or receives
frames, not both at once. Each edge on the pair may be up to 6 ns from its
place at 40 MHz and 10 ns at 50 MHz; the standard allows a sender and a
long cable 13.5 ns, so use a short one.

## External hardware

None required. A logic analyser or USB-serial adapter on the protocol pins
shows what the firmware is doing. USB needs a USB 1.1 transceiver (VO/FSE0
mode, such as a TUSB1106 or MAX3349E) between the protocol pins and the USB
connector, the host's 15 kohm pull-downs on D+ and D-, and 5 V for the
device. Ethernet needs a 10BASE-T transformer (or a jack with magnetics)
and series resistors between P0, P1 and the transmit pair, and for
receive a differential line receiver or comparator with a 100 ohm
termination between the receive pair and P2. 1-Wire needs a pull-up on P0 (4.7 kohm to 3.3 V); I2C, SWD and the
other open-drain buses need one per line. A PS/2 device runs from 5 V: put
a bidirectional level shifter on DATA and CLK, with pull-ups on its 5 V
side. CAN needs a 3.3 V transceiver (an SN65HVD230, for one) and a
terminated bus.
