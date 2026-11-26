/*
 * Copyright (c) 2026 Tave La Rocque
 * SPDX-License-Identifier: Apache-2.0
 *
 * The chip's three SRAM macros for an FPGA build, under the macros' own
 * names, so src/protocol_emulator.v is used unchanged. Each is the
 * behaviour of IHP's model (test/sram_model) as the chip ties it off:
 * A_MEN high, A_DLY high, every bit of A_BM set, BIST off. On a clock
 * edge:
 *
 *   - a write (A_WEN) stores A_DIN; if A_REN is also high, the output
 *     register takes A_DIN too (IHP's write-through);
 *   - a read alone (A_REN) loads the output register from the word;
 *   - otherwise the output register holds.
 *
 * The output is registered, so a read gives its word from the next cycle
 * and holds it, as the macro does. fpga/sram_check.py proves with Yosys
 * that each module here and IHP's model, tied off this way, are the same
 * machine. The tie-offs are not checked here: the ports are kept only so
 * the instances in src/protocol_emulator.v connect.
 */

`default_nettype none

module RM_IHPSG13_1P_256x16_c2_bm_bist (
    input  wire        A_CLK,
    input  wire        A_MEN,
    input  wire        A_WEN,
    input  wire        A_REN,
    input  wire [7:0]  A_ADDR,
    input  wire [15:0] A_DIN,
    input  wire        A_DLY,
    output reg  [15:0] A_DOUT,
    input  wire [15:0] A_BM,
    input  wire        A_BIST_CLK,
    input  wire        A_BIST_EN,
    input  wire        A_BIST_MEN,
    input  wire        A_BIST_WEN,
    input  wire        A_BIST_REN,
    input  wire [7:0]  A_BIST_ADDR,
    input  wire [15:0] A_BIST_DIN,
    input  wire [15:0] A_BIST_BM
);
  (* ram_style = "block" *) reg [15:0] mem [0:255];
  always @(posedge A_CLK) begin
    if (A_WEN) begin
      mem[A_ADDR] <= A_DIN;
      if (A_REN) A_DOUT <= A_DIN;
    end else if (A_REN) begin
      A_DOUT <= mem[A_ADDR];
    end
  end
endmodule

module RM_IHPSG13_1P_1024x16_c2_bm_bist (
    input  wire        A_CLK,
    input  wire        A_MEN,
    input  wire        A_WEN,
    input  wire        A_REN,
    input  wire [9:0]  A_ADDR,
    input  wire [15:0] A_DIN,
    input  wire        A_DLY,
    output reg  [15:0] A_DOUT,
    input  wire [15:0] A_BM,
    input  wire        A_BIST_CLK,
    input  wire        A_BIST_EN,
    input  wire        A_BIST_MEN,
    input  wire        A_BIST_WEN,
    input  wire        A_BIST_REN,
    input  wire [9:0]  A_BIST_ADDR,
    input  wire [15:0] A_BIST_DIN,
    input  wire [15:0] A_BIST_BM
);
  (* ram_style = "block" *) reg [15:0] mem [0:1023];
  always @(posedge A_CLK) begin
    if (A_WEN) begin
      mem[A_ADDR] <= A_DIN;
      if (A_REN) A_DOUT <= A_DIN;
    end else if (A_REN) begin
      A_DOUT <= mem[A_ADDR];
    end
  end
endmodule
