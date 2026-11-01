## How it works

The goal is a protocol emulator: a small CPU whose instructions read pins,
write pins and count cycles, so UART, SPI and I2C are implemented in firmware
instead of fixed logic. The hardware is written in Hardcaml (OCaml) and
compiled to Verilog.

The current build is a bring-up design: a fixed-function 8N1 UART
transmitter at 115200 baud (10 MHz clock, divisor 87). It exists to prove
the toolchain end to end, and will be replaced by the programmable core.

## How to test

Run at 10 MHz. Set the byte to send on `ui_in[7:0]`, then pulse `uio_in[0]`
(START) high for one clock. The byte appears on `uo_out[0]` (TX) as one start
bit, eight data bits LSB first, and one stop bit. `uo_out[1]` (BUSY) is high
while a frame is being sent, and START is ignored while busy. Connect TX to
any USB-serial adapter at 115200 8N1 to read it.

## External hardware

A USB-serial adapter (or the demo board's RP2040) to receive the UART output.
