// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// A JTAG device for the testbench: a TAP controller written from IEEE
// 1149.1, with a 4-bit instruction register and three data registers:
//   IDCODE (instruction 0001, the one selected after reset): 32 bits, reads
//          IDCODE below
//   USER   (instruction 1000): 32 bits, read and write
//   BYPASS (instruction 1111, and any other): 1 bit, captures 0
// Instruction capture value 0101 (the standard requires the low bits 01).
// The state changes and all shifting happen on TCK's rising edge; TDO and
// the update of IR and USER happen on its falling edge. TDO is the low bit
// of the register being shifted while in Shift-IR or Shift-DR, and 1
// otherwise (released, as through a pull-up).

`default_nettype none

module jtag_tap #(
    parameter [31:0] IDCODE = 32'h1BAD_C0DE
) (
    input  wire tck,
    input  wire tms,
    input  wire tdi,
    output reg  tdo = 1'b1
);
  localparam [3:0] TEST_LOGIC_RESET = 4'd0, RUN_TEST_IDLE = 4'd1,
      SELECT_DR = 4'd2, CAPTURE_DR = 4'd3, SHIFT_DR = 4'd4, EXIT1_DR = 4'd5,
      PAUSE_DR = 4'd6, EXIT2_DR = 4'd7, UPDATE_DR = 4'd8, SELECT_IR = 4'd9,
      CAPTURE_IR = 4'd10, SHIFT_IR = 4'd11, EXIT1_IR = 4'd12, PAUSE_IR = 4'd13,
      EXIT2_IR = 4'd14, UPDATE_IR = 4'd15;
  localparam [3:0] I_IDCODE = 4'b0001, I_USER = 4'b1000;

  reg [3:0] state = TEST_LOGIC_RESET;
  reg [3:0] ir = I_IDCODE;
  reg [3:0] ir_shift = 4'd0;
  reg [31:0] dr_shift = 32'd0;
  reg [31:0] user = 32'd0;

  wire bypassed = !(ir == I_IDCODE || ir == I_USER);

  reg [3:0] next;
  always @(*) begin
    case (state)
      TEST_LOGIC_RESET: next = tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
      RUN_TEST_IDLE:    next = tms ? SELECT_DR : RUN_TEST_IDLE;
      SELECT_DR:        next = tms ? SELECT_IR : CAPTURE_DR;
      CAPTURE_DR:       next = tms ? EXIT1_DR : SHIFT_DR;
      SHIFT_DR:         next = tms ? EXIT1_DR : SHIFT_DR;
      EXIT1_DR:         next = tms ? UPDATE_DR : PAUSE_DR;
      PAUSE_DR:         next = tms ? EXIT2_DR : PAUSE_DR;
      EXIT2_DR:         next = tms ? UPDATE_DR : SHIFT_DR;
      UPDATE_DR:        next = tms ? SELECT_DR : RUN_TEST_IDLE;
      SELECT_IR:        next = tms ? TEST_LOGIC_RESET : CAPTURE_IR;
      CAPTURE_IR:       next = tms ? EXIT1_IR : SHIFT_IR;
      SHIFT_IR:         next = tms ? EXIT1_IR : SHIFT_IR;
      EXIT1_IR:         next = tms ? UPDATE_IR : PAUSE_IR;
      PAUSE_IR:         next = tms ? EXIT2_IR : PAUSE_IR;
      EXIT2_IR:         next = tms ? UPDATE_IR : SHIFT_IR;
      default:          next = tms ? SELECT_DR : RUN_TEST_IDLE;  // UPDATE_IR
    endcase
  end

  always @(posedge tck) begin
    case (state)
      CAPTURE_IR: ir_shift <= 4'b0101;
      SHIFT_IR:   ir_shift <= {tdi, ir_shift[3:1]};
      CAPTURE_DR:
        dr_shift <= (ir == I_IDCODE) ? IDCODE : (ir == I_USER) ? user : 32'd0;
      SHIFT_DR:
        if (bypassed) dr_shift <= {31'd0, tdi};
        else dr_shift <= {tdi, dr_shift[31:1]};
      default: ;
    endcase
    state <= next;
  end

  always @(negedge tck) begin
    tdo <= (state == SHIFT_IR) ? ir_shift[0] : (state == SHIFT_DR) ? dr_shift[0] : 1'b1;
    if (state == UPDATE_IR) ir <= ir_shift;
    if (state == UPDATE_DR && ir == I_USER) user <= dr_shift;
    if (state == TEST_LOGIC_RESET) ir <= I_IDCODE;
  end
endmodule
