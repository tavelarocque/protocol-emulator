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

Thread 0's registers are at 0x41-0x4C; thread 1 has an identical bank at
0x51-0x5C. CTRL and PIN_MODES are global.

| Address | Register |
|---|---|
| 0x00-0x3F | program memory (write) |
| 0x40 | CTRL: bit 0 enables thread 0, bit 1 thread 1 |
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
| 0x51-0x5C | thread 1: same layout as 0x41-0x4C (0x57 unused) |

Status pins: uo[1] thread 0 running, uo[2] thread 0 RX data waiting, uo[3]
thread 0 TX FIFO full; uo[4]-uo[6] the same for thread 1.

## How to test

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
0x0145, and write 3 to CTRL. SPI words go to 0x48, UART words to 0x58.

## External hardware

None required. A logic analyser or USB-serial adapter on the protocol pins
shows what the firmware is doing.
