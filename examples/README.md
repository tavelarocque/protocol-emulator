# Example programs

One assembly file per protocol engine. Each is generated from
[`model/firmware.ml`](../model/firmware.ml), the firmware the test suite
runs, and opens with that firmware's documentation: pins, thread
configuration, and what the host's FIFO words mean. `dune build` regenerates
them, so they cannot drift.

| File | Protocol | Instructions (of 64) |
|---|---|---|
| [`uart_tx.s`](uart_tx.s) | UART transmitter, 8N1 | 15 |
| [`uart_rx.s`](uart_rx.s) | UART receiver, with framing-error recovery | 15 |
| [`spi_controller.s`](spi_controller.s) | SPI controller, mode 0, any speed | 26 |
| [`spi_fast.s`](spi_fast.s) | SPI controller, side-set, 2 cycles per bit | 26 |
| [`spi_target.s`](spi_target.s) | SPI device, mode 0 | 23 |
| [`i2c_controller.s`](i2c_controller.s) | I2C controller, writes, timed by loops | 49 |
| [`i2c.s`](i2c.s) | I2C controller, reads and writes, timed by the clock divider | 25 |
| [`i2c_target.s`](i2c_target.s) | I2C target, 7-bit address, clock stretching | 63 |
| [`jtag.s`](jtag.s) | JTAG controller | 11 |
| [`swd.s`](swd.s) | Arm SWD clock engine | 11 |
| [`usb.s`](usb.s) | Low-speed USB: send, and receive with clock recovery | 49 |
| [`onewire.s`](onewire.s) | 1-Wire bus engine | 25 |
| [`ps2_rx.s`](ps2_rx.s), [`ps2_tx.s`](ps2_tx.s) | PS/2 host: receiver and transmitter, one on each thread | 11 + 21 |
| [`echo.s`](echo.s) | TX FIFO to RX FIFO, for bring-up | 5 |
| [`ws2812/`](ws2812) | WS2812 LEDs: the blind firmware test, with its task and hidden test | 16 |

Two-thread images (full-duplex UART, SPI beside UART, the I2C-to-SPI
bridge, the USB host, PS/2) place two of these in one memory; see
`Two_protocols`, `Bridge`, `Uart_duplex`, `Usb_host` and `Ps2` in
`model/firmware.ml`.

## Try one

`pe_sim` assembles a program, or runs it on the reference model (the model
the RTL is checked against every cycle) and prints the pins whenever they
change.

    dune build bin/pe_sim.exe
    alias pe_sim=_build/default/bin/pe_sim.exe

    pe_sim asm examples/jtag.s          # 11 hex words, as loaded over SPI

    printf '6\n0x55\n' > uart.tx        # divisor - 4 (10 cycles per bit), then a byte
    pe_sim run examples/uart_tx.s -mode 0=pp -tx uart.tx -cycles 140 \
      -config out_base=0,out_count=1,set_base=0,set_count=1,threshold=8

The UART run prints P0 (bit 0 of the hex byte) changing every 10 cycles: a
start bit, 0x55 least significant bit first, and the stop bit.

    pins 0 ff
    pins 5 fe
    pins 15 ff
    pins 25 fe
    ...
    pins 95 ff

On the chip, `host/protocol_emulator.py` does the loading and the FIFO
words (`UartTx`, `SpiController`, `SpiDevice`, `I2cDevice`,
`JtagController`, `SwdController`, `UsbHost`, `OneWire`).
