`timescale 1ns / 1ps
// A third-party SPI flash model (picosoc), compiled before default_nettype.
`include "spiflash.v"
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
  reg [2:0] dev_mode = 0;
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
  wire [7:0] uio_in_dut =
      dev_mode == 3'd1 ? {6'b111111, i2c_scl, i2c_sda} :
      dev_mode == 3'd2 ? {5'b11111, flash_io1, 2'b11} :
      dev_mode == 3'd3 ? {6'b111111, uart_rx, 1'b1} :
      dev_mode == 3'd4 ? {4'b1111, spi_cs, 1'b1, spi_mosi, spi_sclk} : uio_in;

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
