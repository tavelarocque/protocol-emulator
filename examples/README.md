# Example programs

One assembly file per protocol engine. Each is generated from
[`model/firmware.ml`](../model/firmware.ml), the firmware the test suite
runs, and opens with that firmware's documentation: pins, thread
configuration, and what the host's FIFO words mean. `dune build` regenerates
them, so they cannot drift.

| File | Protocol | Instructions |
|---|---|---|
| [`uart_tx.s`](uart_tx.s) | UART transmitter, 8N1 | 15 |
| [`uart_rx.s`](uart_rx.s) | UART receiver, with framing-error recovery | 15 |
| [`spi_controller.s`](spi_controller.s) | SPI controller, mode 0, any speed | 26 |
| [`spi_fast.s`](spi_fast.s) | SPI controller, side-set, 2 cycles per bit | 26 |
| [`spi_target.s`](spi_target.s) | SPI device, mode 0 | 23 |
| [`i2c_controller.s`](i2c_controller.s) | I2C controller, writes, timed by loops | 49 |
| [`i2c.s`](i2c.s) | I2C controller, reads and writes, timed by the clock divider | 30 |
| [`i2c_target.s`](i2c_target.s) | I2C target, 7-bit address, clock stretching | 63 |
| [`jtag.s`](jtag.s) | JTAG controller | 11 |
| [`swd.s`](swd.s) | Arm SWD clock engine | 11 |
| [`usb.s`](usb.s) | Low-speed USB: send, and receive with clock recovery | 49 |
| [`onewire.s`](onewire.s) | 1-Wire bus engine | 25 |
| [`ps2_rx.s`](ps2_rx.s), [`ps2_tx.s`](ps2_tx.s) | PS/2 host: receiver and transmitter, one on each thread | 11 + 21 |
| [`can_rx.s`](can_rx.s), [`can_tx.s`](can_tx.s) | CAN node: a receiver that checks the CRC and acknowledges, behind the bit sampler, and a transmitter that stuffs the bits and makes the CRC, one on each thread | 59 + 89 |
| [`i2s_tx.s`](i2s_tx.s) | I2S transmitter, 16-bit stereo | 11 |
| [`dmx_tx.s`](dmx_tx.s) | DMX512 transmitter | 26 |
| [`wiegand_tx.s`](wiegand_tx.s) | Wiegand transmitter | 17 |
| [`nec_tx.s`](nec_tx.s) | NEC infrared transmitter, with carrier | 25 |
| [`mdio.s`](mdio.s) | MDIO controller (Ethernet PHY management) | 7 |
| [`dali_tx.s`](dali_tx.s) | DALI forward frame transmitter | 17 |
| [`rc5_tx.s`](rc5_tx.s) | RC-5 infrared transmitter, with carrier | 37 |
| [`wiegand_rx.s`](wiegand_rx.s) | Wiegand receiver | 16 |
| [`nec_rx.s`](nec_rx.s) | NEC infrared receiver | 33 |
| [`dali_rx.s`](dali_rx.s) | DALI receiver, through the bit sampler | 9 |
| [`rc5_rx.s`](rc5_rx.s) | RC-5 infrared receiver, through the bit sampler | 9 |
| [`microwire.s`](microwire.s) | Microwire controller | 10 |
| [`cec.s`](cec.s) | HDMI-CEC initiator | 38 |
| [`ir_tx.s`](ir_tx.s) | Infrared burst sender (RC-6 is sent with it) | 7 |
| [`stepper.s`](stepper.s) | Step and direction, for stepper motor drivers | 10 |
| [`dht.s`](dht.s) | AM2302 / DHT22 and DHT11 sensor reader | 27 |
| [`bitstream.s`](bitstream.s) | Levels at a fixed rate (Qi, EM4100 and Morse are sent with it) | 3 |
| [`tdm_tx.s`](tdm_tx.s) | TDM audio transmitter | 18 |
| [`tlc5620.s`](tlc5620.s) | TLC5620 DAC writer | 12 |
| [`pwm.s`](pwm.s) | PWM, RC servo pulses | 8 |
| [`nes_pad.s`](nes_pad.s) | NES gamepad | 7 |
| [`sbus_tx.s`](sbus_tx.s) | SBUS transmitter, inverted characters made on the chip | 22 |
| [`dshot.s`](dshot.s) | DShot, the checksum made on the chip | 19 |
| [`xy2_x.s`](xy2_x.s), [`xy2_y.s`](xy2_y.s) | XY2-100 galvanometer scanner, one axis on each thread | 17 + 20 |
| [`caliper.s`](caliper.s) | A digital caliper's data port | 21 |
| [`i3c.s`](i3c.s) | MIPI I3C controller, SDR, with ENTDAA | 63 |
| [`sent_tx.s`](sent_tx.s) | SAE J2716 SENT transmitter | 59 |
| [`j1850_tx.s`](j1850_tx.s) | SAE J1850 VPW transmitter | 55 |
| [`sirc_tx.s`](sirc_tx.s) | Sony SIRC infrared transmitter, with carrier | 40 |
| [`sle4442.s`](sle4442.s) | SLE 4442 memory card reader | 40 |
| [`cjtag.s`](cjtag.s) | Compact JTAG (IEEE 1149.7), OScan1 | 55 |
| [`pjdl.s`](pjdl.s) | PJON over PJDL, sending | 56 |
| [`lfast.s`](lfast.s) | NXP LFAST with SIPI frames, sending | 33 |
| [`echo.s`](echo.s) | TX FIFO to RX FIFO, for bring-up | 5 |
| [`ws2812/`](ws2812) | WS2812 LEDs: the blind firmware test, with its task and hidden test | 16 |

Two-thread images (full-duplex UART, SPI beside UART, the I2C-to-SPI
bridge, the USB host, PS/2, CAN) place two of these in one image; see
`Two_protocols`, `Bridge`, `Uart_duplex`, `Usb_host`, `Ps2` and `Can` in
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
`JtagController`, `SwdController`, `UsbHost`, `OneWire`, `Ps2`, `Can`).
