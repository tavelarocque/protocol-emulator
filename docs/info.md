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
register address, and 16 data bits. Through it the host loads the 64-word
program memory (shared by the two threads), configures each thread and the 8
protocol pins (each input, push-pull or open-drain), enables the threads,
and moves data through each thread's 4-deep TX and RX FIFOs. The two threads
run at the same time, each executing one instruction per clock; if both
write the same pin in the same cycle, thread 1 wins.

Thread 0's registers are at 0x41-0x4F; thread 1 has an identical bank at
0x51-0x5F. CTRL, PIN_MODES and SYNC_BYPASS are global. Every protocol
pin's input passes through a two-flip-flop synchroniser (two cycles of
delay) unless its SYNC_BYPASS bit is set; the side-set SPI controller needs
it set on MISO.

| Address | Register |
|---|---|
| 0x00-0x3F | program memory (write) |
| 0x40 | CTRL: bit 0 enables thread 0, bit 1 thread 1; bit 2 CHAIN (thread 0's RX FIFO feeds thread 1's TX FIFO) |
| 0x41 | START address |
| 0x42 | OUT pins: base [2:0], count [7:4] |
| 0x43 | SET pins: base [2:0], count [7:4] |
| 0x44 | IN base [2:0] |
| 0x45 | THRESHOLD (bits per FIFO word, 1-16) |
| 0x46 | TIMEOUT_VECTOR |
| 0x47 | PIN_MODES, 2 bits per pin: 0 input, 1 push-pull, 2 open-drain |
| 0x48 | TX FIFO (write) |
| 0x49 | RX FIFO (read) |
| 0x4A | STATUS: pc [13:8], enable [7], RX level [6:4], TX level [2:0] |
| 0x4B | TIMEOUT: max cycles a timed wait stalls |
| 0x4C | SIDESET: base pin [2:0], count [5:4] |
| 0x4D | CLKDIV: the thread runs one cycle in every CLKDIV (0, 1: every cycle) |
| 0x4E | SYNC_BYPASS (global): 1 bit per pin; set to read that pin without the 2-cycle input synchroniser |
| 0x4F | SHIFT: bit 0 OUT most significant bit first, bit 1 IN most significant bit first |
| 0x51-0x5F | thread 1: same layout as 0x41-0x4F (0x57 and 0x5E unused) |

Status pins: uo[1] thread 0 running, uo[2] thread 0 RX data waiting, uo[3]
thread 0 TX FIFO full; uo[4]-uo[6] the same for thread 1.

## How to test

`host/protocol_emulator.py` is a MicroPython driver for the demo board's
RP2040: copy it and the `.hex` images from `test/` to the board, enable the
project, clock it at 10 MHz (`tt.clock_project_PWM(10_000_000)`), and
`pe.Chip(pe.demo_board_port())` gives register access, firmware loading and
FIFO push/pop, with helpers for UART TX, the SPI controller, and the I2C and
SPI device modes. The cocotb tests run this same file against the chip. The
register-level recipes below are what it does underneath.

With the demo board's RP2040 as SPI host: load a firmware image (for
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
the side-set SPI controller at 25. Thread 0 runs I2C on P0 (SDA) and P1
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
thread 1, whichever thread the engine runs on.

## External hardware

None required. A logic analyser or USB-serial adapter on the protocol pins
shows what the firmware is doing. USB needs a USB 1.1 transceiver (VO/FSE0
mode, such as a TUSB1106 or MAX3349E) between the protocol pins and the USB
connector, the host's 15 kohm pull-downs on D+ and D-, and 5 V for the
device.
