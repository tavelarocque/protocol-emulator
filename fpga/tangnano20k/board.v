/*
 * Copyright (c) 2026 Tave La Rocque
 * SPDX-License-Identifier: Apache-2.0
 *
 * The chip on a Sipeed Tang Nano 20K, wired like a Tiny Tapeout demo
 * board: a Raspberry Pi Pico drives the clock, reset and the SPI host
 * port, as the demo board's RP2350 does, so host/protocol_emulator.py runs
 * unchanged. The chip itself is src/project.v and src/protocol_emulator.v
 * as they go to the foundry, with fpga/sram_fpga.v in place of the SRAM
 * macros. Pins are in pins.cst.
 *
 * Only the chip's used pins come out: the host port (ui_in[0] to [2],
 * uo_out[0]), the six status outputs (uo_out[1] to [6], on the board's
 * LEDs too, lit when low) and the eight protocol pins (uio). ui_in[3] to
 * [7] are unused by the chip and held low.
 *
 * Define CLK27 to clock the chip from the board's 27 MHz crystal instead
 * of the Pico.
 */

`default_nettype none

module pe_tangnano20k (
`ifdef CLK27
    input  wire       clk27,    // the board's crystal
`else
    input  wire       clk,      // from the Pico
`endif
    input  wire       rst_n,    // from the Pico; pulled low, so the chip waits in reset
    input  wire       sck,
    input  wire       cs_n,
    input  wire       mosi,
    output wire       miso,
    output wire [5:0] status,   // uo_out[1] to [6]
    inout  wire [7:0] p         // the protocol pins P0 to P7
);

`ifdef CLK27
  wire clk = clk27;
`endif

  wire [7:0] uo_out, uio_in, uio_out, uio_oe;

  tt_um_tavelarocque_protocol_emulator chip (
      .ui_in  ({5'b0, mosi, cs_n, sck}),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (1'b1),
      .clk    (clk),
      .rst_n  (rst_n)
  );

  assign miso   = uo_out[0];
  assign status = uo_out[6:1];

  // Each protocol pin is a Gowin IOBUF, named outright: Yosys's inference
  // of tri-states left these pins out of the first build entirely.
  // OEN is active low.
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin : pad
      wire from_pad;
      IOBUF buf_i (.O(from_pad), .IO(p[i]), .I(uio_out[i]), .OEN(~uio_oe[i]));
      assign uio_in[i] = from_pad;
    end
  endgenerate

endmodule
