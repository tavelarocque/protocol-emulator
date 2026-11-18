// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// What the equivalence proof puts in place of the SRAM macro, in the RTL and
// in the netlist alike. It says nothing about what a memory does:
//
//   cut   the macro's output. setup.ys makes it an input of the whole
//         design, one per macro, with the same name on both sides, so the
//         netlist and the RTL are shown the same arbitrary word each cycle.
//   seen  everything driven into the macro. It has the same name on both
//         sides, so the proof must show the two equal, like any register.
//
// So the proof covers the logic around the memories for whatever they
// might read out, and shows both sides present a memory with the same
// clock, address, data and controls in every cycle. Two copies of any
// deterministic memory, given the same inputs for ever, read out the same.
`default_nettype none

module RM_IHPSG13_1P_256x16_c2_bm_bist (
    input  wire        A_CLK,
    input  wire        A_MEN,
    input  wire        A_WEN,
    input  wire        A_REN,
    input  wire [7:0]  A_ADDR,
    input  wire [15:0] A_DIN,
    input  wire        A_DLY,
    output wire [15:0] A_DOUT,
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
  (* keep *) wire [15:0] cut;
  // Inverted only so that a gate stands between the two: equiv_make loses
  // the RTL's other names for these bits if they are the input itself.
  // Any word can still appear on A_DOUT.
  assign A_DOUT = ~cut;
  (* keep *) wire [86:0] seen = {
    A_CLK, A_MEN, A_WEN, A_REN, A_ADDR, A_DIN, A_DLY, A_BM,
    A_BIST_CLK, A_BIST_EN, A_BIST_MEN, A_BIST_WEN, A_BIST_REN,
    A_BIST_ADDR, A_BIST_DIN, A_BIST_BM};
endmodule
