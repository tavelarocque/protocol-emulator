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
program memory, configures the thread and the 8 protocol pins (each input,
push-pull or open-drain), enables the thread, and moves data through 4-deep
TX and RX FIFOs.

| Address | Register |
|---|---|
| 0x00-0x3F | program memory (write) |
| 0x40 | CTRL: bit 0 enables the thread |
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

## How to test

With the demo board's RP2040 as SPI host: load a firmware image (for
example the 15-instruction UART transmitter in `test/uart_tx.hex`) into
addresses 0x00 upwards, set PIN_MODES to 0x0001 (P0 push-pull), write 1 to
CTRL (0x40), then write `divisor - 4` and then bytes to the TX FIFO. P0 outputs
8N1 UART at `clock / divisor` baud. `test/echo.hex` instead returns every TX
FIFO word on the RX FIFO.

## External hardware

None required. A logic analyser or USB-serial adapter on the protocol pins
shows what the firmware is doing.
