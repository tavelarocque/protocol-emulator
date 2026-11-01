/*
 * Copyright (c) 2026 Tave La Rocque
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout top module.
 *
 * Week-1 bring-up: this wraps the fixed-function UART transmitter
 * (generated from hw/uart_tx.ml into src/uart_tx.v) so the full
 * RTL -> GDS flow is proven before the programmable core exists.
 * The core replaces this wiring later.
 */

`default_nettype none

module tt_um_tavelarocque_protocol_emulator (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // 10 MHz / 87 = 114,943 baud, within 0.3% of 115200.
  localparam [15:0] DIVISOR = 16'd87;

  wire tx;
  wire busy;

  uart_tx u_uart_tx (
      .clock  (clk),
      .clear  (~rst_n),
      .divisor(DIVISOR),
      .data   (ui_in),
      .start  (uio_in[0]),
      .tx     (tx),
      .busy   (busy)
  );

  assign uo_out  = {6'b0, busy, tx};
  assign uio_out = 8'b0;
  assign uio_oe  = 8'b0;  // all bidirectional pins are inputs

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:1], 1'b0};

endmodule
