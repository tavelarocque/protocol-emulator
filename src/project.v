/*
 * Copyright (c) 2026 Tave La Rocque
 * SPDX-License-Identifier: Apache-2.0
 *
 * Tiny Tapeout top module. All logic is generated from Hardcaml
 * (hw/top.ml -> src/protocol_emulator.v); this file only maps pins.
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

  protocol_emulator u_protocol_emulator (
      .clock  (clk),
      .clear  (~rst_n),
      .ui_in  (ui_in),
      .uio_in (uio_in),
      .uo_out (uo_out),
      .uio_out(uio_out),
      .uio_oe (uio_oe)
  );

  wire _unused = &{ena, 1'b0};

endmodule
