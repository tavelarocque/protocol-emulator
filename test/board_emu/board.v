// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The chip as the demo board sees it, with devices on its protocol pins,
// for the board co-simulation (README.md here). The emulated RP2040 drives
// ui_in and reads uo_out; cosim.cpp drives the clocks, the resets and the
// pins of the devices that board.mjs models in JavaScript.
//
// dev_mode picks what is on the protocol pins, as in test/tb.v:
//   1: I2C on P0 (SDA) and P1 (SCL), open-drain and pulled up; a controller
//      in board.mjs pulls through i2c_sda_dev and i2c_scl_dev
//   2: picosoc's SPI flash on P0 (SCK), P1 (MOSI), P2 (MISO), P3 (CS_N)
//   3: UART: the chip's TX on P0, its RX (uart_rx) on P1
//   4: an SPI controller in board.mjs driving the chip as a device: SCK on
//      P0, MOSI on P1, CS_N on P3; the chip's MISO on P2
//   5: an IEEE 1149.1 TAP (test/jtag_tap.v) on TCK P0, TMS P1, TDI P2,
//      TDO P3
//   6: an SWD target (test/swd_dp.v) on SWCLK P0 and SWDIO P1 (open-drain,
//      pulled up)
//   7: low-speed USB through a USB 1.1 transceiver in VO/FSE0 mode (P2 VO,
//      P3 FSE0, P4 OE_N; VP and VM back on P0 and P1), to usbhostslave's
//      usbDevice

`default_nettype none

module board (
    input  wire       clk,       // the chip's clock
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire [2:0] dev_mode,
    // devices modelled in board.mjs
    input  wire       i2c_sda_dev,   // 1 = released
    input  wire       i2c_scl_dev,
    input  wire       uart_rx,
    input  wire       spi_sclk,
    input  wire       spi_mosi,
    input  wire       spi_cs_n,
    output wire       i2c_sda,       // the bus lines
    output wire       i2c_scl,
    output wire [31:0] swd_parity_errors,
    // USB
    input  wire       usb_clk,       // the device's clock (48 MHz)
    input  wire       usb_rst,
    output wire       usb_dp,
    output wire       usb_dm,
    output wire       host_driving,  // the chip's transceiver is driving
    output wire       bus_conflict,  // both ends driving at once
    output wire       dev_connected  // the device's pull-up on D-
);
  // --- I2C
  assign i2c_sda = !uio_oe[0] && i2c_sda_dev;
  assign i2c_scl = !uio_oe[1] && i2c_scl_dev;

  // --- SPI flash (picosoc)
  wire flash_csb = (dev_mode == 3'd2) ? uio_out[3] : 1'b1;
  wire flash_clk = (dev_mode == 3'd2) && uio_out[0];
  wire flash_io0 = uio_out[1];
  wire flash_io1;
  wire flash_io2 = 1'b1, flash_io3 = 1'b1;
  spiflash flash (
      .csb(flash_csb),
      .clk(flash_clk),
      .io0(flash_io0),
      .io1(flash_io1),
      .io2(flash_io2),
      .io3(flash_io3)
  );

  // --- JTAG and SWD
  wire jtag_tck = (dev_mode == 3'd5) && uio_out[0];
  wire jtag_tdo;
  jtag_tap tap (
      .tck(jtag_tck),
      .tms(uio_out[1]),
      .tdi(uio_out[2]),
      .tdo(jtag_tdo)
  );
  wire swd_clk = (dev_mode == 3'd6) && uio_out[0];
  wire swd_oe, swd_out;
  wire swdio = !uio_oe[1] && (swd_oe ? swd_out : 1'b1);
  swd_dp dp (
      .swclk(swd_clk),
      .swdio_in(swdio),
      .swdio_oe(swd_oe),
      .swdio_out(swd_out)
  );
  assign swd_parity_errors = dp.parity_errors;

  // --- USB: the chip's transceiver drives the bus while OE_N (P4) is low;
  // VO = 1 is D+ high, FSE0 forces both low. The device's pull-up is on D-
  // (low speed); the host's pull-downs hold an undriven line low.
  wire host_oe = (dev_mode == 3'd7) && uio_oe[4] && !uio_out[4];
  wire host_dp = !uio_out[3] && uio_out[2];
  wire host_dm = !uio_out[3] && !uio_out[2];
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

  wire [7:0] uio_in =
      dev_mode == 3'd1 ? {6'b111111, i2c_scl, i2c_sda} :
      dev_mode == 3'd2 ? {5'b11111, flash_io1, 2'b11} :
      dev_mode == 3'd3 ? {6'b111111, uart_rx, 1'b1} :
      dev_mode == 3'd4 ? {4'b1111, spi_cs_n, 1'b1, spi_mosi, spi_sclk} :
      dev_mode == 3'd5 ? {4'b1111, jtag_tdo, 3'b111} :
      dev_mode == 3'd6 ? {6'b111111, swdio, 1'b1} :
      dev_mode == 3'd7 ? {6'b111111, usb_dm, usb_dp} : 8'hFF;

  tt_um_tavelarocque_protocol_emulator chip (
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (1'b1),
      .clk    (clk),
      .rst_n  (rst_n)
  );
endmodule
