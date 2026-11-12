`timescale 1ns / 1ps
// A third-party SPI flash model (picosoc), compiled before default_nettype.
`include "spiflash.v"
`include "jtag_tap.v"
`include "swd_dp.v"
// Iztok Jeras's 1-Wire slave model from sockit_owm (LGPL-3.0, test only;
// github.com/jeras/sockit_owm, hdl/onewire_slave_model.v, unmodified). It
// sets its own timescale (1 us), so this file's is set again after it.
`include "onewire_slave_model.v"
`timescale 1ns / 1ps
`default_nettype none

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // --- Third-party devices on the protocol pins (test.py, "Third-party
  // devices"). The chip's tests normally drive uio_in directly; dev_mode
  // instead connects the pins to real bus wires, so device models written
  // by other people can watch and drive them as they would on a board.
  //   0: uio_in from the test, as before
  //   1: I2C on P0 (SDA) and P1 (SCL): open-drain, pulled up, low if the
  //      chip or the device pulls
  //   2: picosoc's SPI flash on P0 (SCK), P1 (MOSI), P2 (MISO), P3 (CS_N)
  //   3: UART, chip TX on P0, chip RX on P1
  //   4: an SPI controller (cocotbext-spi) driving the chip as a device:
  //      SCK on P0, MOSI on P1, CS_N on P3; the chip's MISO on P2
  //   5: a JTAG device (jtag_tap.v) on the chip's TCK (P0), TMS (P1),
  //      TDI (P2) and TDO (P3); cocotbext-jtag's monitor watches the wires
  //   6: an SWD target (swd_dp.v) on the chip's SWCLK (P0) and SWDIO (P1,
  //      open-drain, pulled up here)
  //   7: low-speed USB: the chip drives a USB 1.1 transceiver in VO/FSE0
  //      mode (P2 VO, P3 FSE0, P4 OE_N) and reads its VP and VM receivers
  //      (P0, P1); on the other side of the bus is usbhostslave's usbDevice
  //      (test/usbhostslave), clocked at 48 MHz by usb_clk
  //   8: 1-Wire on P0 (open-drain, pulled up here), with three of Iztok
  //      Jeras's slave models on the wire, at the shortest, typical and
  //      longest timing the 1-Wire rules allow (time slot 15, 30, 60 us);
  //      onewire_ena connects each, onewire_dat_r is what each sends next
  reg [3:0] dev_mode = 0;
  reg i2c_sda_dev = 1;  // the device's drives, 1 = released
  reg i2c_scl_dev = 1;
  wire i2c_sda = !uio_oe[0] && i2c_sda_dev;
  wire i2c_scl = !uio_oe[1] && i2c_scl_dev;
  wire flash_csb = (dev_mode == 3'd2) ? uio_out[3] : 1'b1;
  wire flash_clk = (dev_mode == 3'd2) && uio_out[0];
  wire flash_io0 = uio_out[1];
  wire flash_io1, flash_io2, flash_io3;
  pullup (flash_io1);
  pullup (flash_io2);
  pullup (flash_io3);
  spiflash flash (
      .csb(flash_csb),
      .clk(flash_clk),
      .io0(flash_io0),
      .io1(flash_io1),
      .io2(flash_io2),
      .io3(flash_io3)
  );
  wire uart_tx = uio_out[0];
  reg uart_rx = 1;
  reg spi_sclk = 0;
  reg spi_mosi = 1;
  reg spi_cs = 1;  // active low
  wire spi_miso = uio_out[2];
  wire jtag_tck = (dev_mode == 3'd5) && uio_out[0];
  wire jtag_tms = uio_out[1];
  wire jtag_tdi = uio_out[2];
  wire jtag_tdo;
  wire swd_clk = (dev_mode == 3'd6) && uio_out[0];
  wire swd_oe, swd_out;
  wire swdio = !uio_oe[1] && (swd_oe ? swd_out : 1'b1);  // pull-up
  swd_dp dp (
      .swclk(swd_clk),
      .swdio_in(swdio),
      .swdio_oe(swd_oe),
      .swdio_out(swd_out)
  );
  jtag_tap tap (
      .tck(jtag_tck),
      .tms(jtag_tms),
      .tdi(jtag_tdi),
      .tdo(jtag_tdo)
  );
  // --- Low-speed USB (dev_mode 7) ----------------------------------------
  // The host side: a USB 1.1 transceiver in VO/FSE0 mode, driving D+ and D-
  // while OE_N is low (VO = 1 is D+ high; FSE0 forces both low).
  reg usb_clk = 0;  // 48 MHz, started by the test
  reg usb_rst = 1;
  wire host_oe = (dev_mode == 3'd7) && uio_oe[4] && !uio_out[4];
  wire host_dp = !uio_out[3] && uio_out[2];
  wire host_dm = !uio_out[3] && !uio_out[2];
  // The device side: its own transceiver, and its pull-up (D- at low speed);
  // the host's pull-downs hold an undriven line low.
  wire dev_vp_out, dev_vm_out, dev_oe_n, dev_dp_pullup, dev_dm_pullup;
  wire dev_oe = !dev_oe_n;
  // Both driving at once is a protocol error: the bus goes X so it shows.
  wire usb_dp = host_oe && dev_oe ? 1'bx : host_oe ? host_dp : dev_oe ? dev_vp_out : dev_dp_pullup;
  wire usb_dm = host_oe && dev_oe ? 1'bx : host_oe ? host_dm : dev_oe ? dev_vm_out : dev_dm_pullup;
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

  // --- CAN (dev_mode 9) --------------------------------------------------
  // The bus as a transceiver presents it: RXD (P0) is the wired-AND of the
  // chip's TXD (P1) and the other node's drive, can_dev (0 = dominant).
  reg can_dev = 1;
  wire can_bus = (uio_oe[1] ? uio_out[1] : 1'b1) & can_dev;

  // --- 1-Wire (dev_mode 8) -----------------------------------------------
  reg [2:0] onewire_ena = 0;
  reg [2:0] onewire_dat_r = 3'b111;
  wire [2:0] onewire_dat_w;
  wire onewire;
  pullup (onewire);
  assign onewire = (dev_mode == 4'd8) && uio_oe[0] ? 1'b0 : 1'bz;
  onewire_slave_model #(.TS(15.0)) onewire_min (
      .ena(dev_mode == 4'd8 && onewire_ena[0]),
      .ovd(1'b0),
      .dat_r(onewire_dat_r[0]),
      .dat_w(onewire_dat_w[0]),
      .owr(onewire)
  );
  onewire_slave_model #(.TS(30.0)) onewire_typ (
      .ena(dev_mode == 4'd8 && onewire_ena[1]),
      .ovd(1'b0),
      .dat_r(onewire_dat_r[1]),
      .dat_w(onewire_dat_w[1]),
      .owr(onewire)
  );
  onewire_slave_model #(.TS(60.0)) onewire_max (
      .ena(dev_mode == 4'd8 && onewire_ena[2]),
      .ovd(1'b0),
      .dat_r(onewire_dat_r[2]),
      .dat_w(onewire_dat_w[2]),
      .owr(onewire)
  );

  wire [7:0] uio_in_dut =
      dev_mode == 3'd1 ? {6'b111111, i2c_scl, i2c_sda} :
      dev_mode == 3'd2 ? {5'b11111, flash_io1, 2'b11} :
      dev_mode == 3'd3 ? {6'b111111, uart_rx, 1'b1} :
      dev_mode == 3'd4 ? {4'b1111, spi_cs, 1'b1, spi_mosi, spi_sclk} :
      dev_mode == 3'd5 ? {4'b1111, jtag_tdo, 3'b111} :
      dev_mode == 3'd6 ? {6'b111111, swdio, 1'b1} :
      dev_mode == 3'd7 ? {6'b111111, usb_dm, usb_dp} :
      dev_mode == 4'd8 ? {7'b1111111, onewire} :
      dev_mode == 4'd9 ? {7'b1111111, can_bus} : uio_in;

  // Replace tt_um_example with your module name:
  tt_um_tavelarocque_protocol_emulator user_project (
      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in_dut),  // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule
