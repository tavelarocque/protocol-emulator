# usbhostslave (third-party, test only)

A low-speed USB device for the testbench: the `usbDevice` example (an
emulated USB mouse with its own endpoint-0 control logic and descriptor ROM)
from Steve Fielding's usbhostslave, a USB 1.1 host and device controller in
Verilog. It judges the chip's USB host firmware the way picosoc's SPI flash
judges the SPI firmware: it was written by someone else, from the USB
specification, and it validates every packet (PID check, bit stuffing,
CRC5/CRC16) before it answers.

- Source: https://opencores.org/projects/usbhostslave, via the freecores
  GitHub mirror, commit 3508a22f1c3df7cd3c86fd2e6e6a12e025c90305.
- License: GNU LGPL 2.1 or later (see each file's header). Used only in the
  testbench; nothing here is part of the chip.
- Files: the device-mode controller (`RTL/buffers`, `busInterface`,
  `hostSlaveMux/hostSlaveMuxBI.v`, `serialInterfaceEngine`,
  `slaveController`, `wrapper/usbSlave.v`) and `usbDevice/RTL`, flattened
  into this folder; the includes in `include/`.

## Changes

Each is marked `protocol-emulator:` in the source. Three lines make the
device connect at low speed (1.5 Mbit/s), which the core supports, instead
of the example's full speed:

- `EP0.v`: the control register write `8'h71` (enable, connect, full-speed
  rate and polarity) becomes `8'h41` (enable, connect, low speed).
- `EP0.v`: it waits for `LOW_SPEED_CONNECT` instead of `FULL_SPEED_CONNECT`.
- `include/usbDevice_define.v`: `MAX_RESP_SIZE` (the device descriptor's
  bMaxPacketSize0, and its control-read packet size) is 8, the low-speed
  maximum, instead of 64.

And one bug fix, found by the chip's host driver:

- `EP0.v`: after the host ACKs an IN data packet, the endpoint advanced to
  the next data but never toggled DATA0/DATA1 (it toggled only on OUT), so
  every IN packet of a control read was DATA1. USB 1.1 (8.6) requires the
  toggle, and a host must treat a repeated PID as a retransmission. At full
  speed the example's descriptors fit one 64-byte packet, so it never
  showed; at low speed, with 8-byte packets, the second packet of the device
  descriptor was DATA1 again, and the driver rejected it. Two lines toggle
  the sequence bit on an ACKed IN.
