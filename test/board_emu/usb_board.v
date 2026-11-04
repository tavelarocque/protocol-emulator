// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The chip as the demo board sees it, with a low-speed USB device on the
// bidirectional pins: the same transceiver and bus model as test/tb.v
// (dev_mode 7), for the board co-simulation (see README.md here). The
// emulated RP2040 drives ui_in and reads uo_out; cosim.cpp drives the two
// clocks and the resets.

`default_nettype none

module usb_board (
    input  wire       clk,       // the chip's clock (12 MHz)
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire       usb_clk,   // the device's clock (48 MHz)
    input  wire       usb_rst,
    output wire       usb_dp,
    output wire       usb_dm,
    output wire       host_driving,  // the chip's transceiver is driving
    output wire       bus_conflict,  // both ends driving at once
    output wire       dev_connected  // the device's pull-up on D-
);
  wire [7:0] uio_out, uio_oe;

  // Host side: a USB 1.1 transceiver in VO/FSE0 mode, driving the bus while
  // OE_N (P4) is low; VO = 1 is D+ high, FSE0 forces both low.
  wire host_oe = uio_oe[4] && !uio_out[4];
  wire host_dp = !uio_out[3] && uio_out[2];
  wire host_dm = !uio_out[3] && !uio_out[2];
  // Device side: its transceiver and its pull-up; the host's pull-downs
  // hold an undriven line low.
  wire dev_vp_out, dev_vm_out, dev_oe_n, dev_dp_pullup, dev_dm_pullup;
  wire dev_oe = !dev_oe_n;
  assign host_driving = host_oe;
  assign bus_conflict = host_oe && dev_oe;
  assign usb_dp = host_oe ? host_dp : dev_oe ? dev_vp_out : dev_dp_pullup;
  assign usb_dm = host_oe ? host_dm : dev_oe ? dev_vm_out : dev_dm_pullup;
  assign dev_connected = dev_dm_pullup;

  usbDevice usb_dev (
      .clk(usb_clk),
      .rst(usb_rst),
      .usbSlaveVP_in(usb_dp),
      .usbSlaveVM_in(usb_dm),
      .usbSlaveVP_out(dev_vp_out),
      .usbSlaveVM_out(dev_vm_out),
      .usbSlaveOE_n(dev_oe_n),
      .USBFullSpeed(),
      .usbDPlusPullup(dev_dp_pullup),
      .usbDMinusPullup(dev_dm_pullup),
      .vBusDetect(1'b1)
  );

  tt_um_tavelarocque_protocol_emulator chip (
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in ({6'b111111, usb_dm, usb_dp}),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (1'b1),
      .clk    (clk),
      .rst_n  (rst_n)
  );
endmodule
