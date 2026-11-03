// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// An SWD target for the testbench, written from Arm's ADIv5 debug interface
// architecture: a Serial Wire Debug Port with one Access Port.
//
// Wire protocol. The target samples SWDIO on SWCLK's rising edge and drives
// it just after a rising edge. It powers up in JTAG mode and answers nothing
// until it sees a line reset (50 or more clocks with SWDIO high), the
// 16-bit JTAG-to-SWD select sequence 0xE79E (LSB first), and another line
// reset. Then each transaction is:
//   host:   start(1) APnDP RnW A[2] A[3] parity stop(0) park(1)
//   either: one turnaround clock
//   target: ACK, 3 bits LSB first: OK = 1,0,0
//   read:   target sends 32 data bits LSB first and even parity, then one
//           turnaround clock
//   write:  one turnaround clock, then the host sends 32 data bits and
//           parity
// A request with bad parity, stop or park gets no answer (the line stays
// high), and so does anything before the select sequence. A write whose
// data parity is wrong is ignored and counted in [parity_errors].
//
// Registers:
//   DP 0x0 read  DPIDR = 0x2BA01477      write ABORT (ignored)
//   DP 0x4 r/w   CTRL/STAT: the power-up request bits CSYSPWRUPREQ (30) and
//                CDBGPWRUPREQ (28) are acknowledged in bits 31 and 29
//   DP 0x8 write SELECT: APSEL [31:24], APBANKSEL [7:4]
//   DP 0xC read  RDBUFF: the result of the last AP read
//   AP 0, bank 0x0, 0x4: a read/write 32-bit register (like a MEM-AP's TAR)
//   AP 0, bank 0xF, 0xC: IDR = 0x24770011
// AP reads are posted, as in ADIv5: an AP read returns the result of the
// previous AP read, and its own result appears in RDBUFF.

`default_nettype none

module swd_dp (
    input  wire swclk,
    input  wire swdio_in,   // the line as it is
    output reg  swdio_oe = 1'b0,
    output reg  swdio_out = 1'b1
);
  localparam [31:0] DPIDR = 32'h2BA0_1477, AP_IDR = 32'h2477_0011;

  // Mode: 0 = JTAG (deaf), 1 = SWD.
  reg swd_mode = 1'b0;
  reg [6:0] ones = 7'd0;  // consecutive high bits, saturating at 64
  reg [15:0] select_shift = 16'd0;
  reg seen_reset = 1'b0;  // a line reset since the last select sequence check

  // Transaction state.
  localparam [2:0] IDLE = 3'd0, REQUEST = 3'd1, ACK = 3'd2, READ = 3'd3,
      WRITE = 3'd4, TRN_BACK = 3'd5;
  reg [2:0] phase = IDLE;
  reg [5:0] count = 6'd0;
  reg [7:0] request = 8'd0;
  reg [32:0] data = 33'd0;  // 32 bits and parity

  reg [31:0] ctrl_stat = 32'd0, select = 32'd0, rdbuff = 32'd0, ap_tar = 32'd0;
  reg [31:0] parity_errors = 32'd0;

  wire apndp = request[1], rnw = request[2];
  wire [1:0] a = request[4:3];  // A[3:2]: register 0x0, 0x4, 0x8 or 0xC

  function [31:0] dp_read(input [1:0] addr);
    case (addr)
      2'd0: dp_read = DPIDR;
      2'd1: dp_read = {ctrl_stat[30], ctrl_stat[30], ctrl_stat[28], ctrl_stat[28], ctrl_stat[27:0]};
      2'd3: dp_read = rdbuff;
      default: dp_read = 32'd0;
    endcase
  endfunction

  function [31:0] ap_read(input [1:0] addr);
    if (select[31:24] != 8'd0) ap_read = 32'd0;
    else if (select[7:4] == 4'hF && addr == 2'd3) ap_read = AP_IDR;
    else if (select[7:4] == 4'h0 && addr == 2'd1) ap_read = ap_tar;
    else ap_read = 32'd0;
  endfunction

  wire reset_ends = (ones >= 7'd50) && !swdio_in;

  always @(posedge swclk) begin
    // Line reset and the JTAG-to-SWD select sequence, watched at all times.
    ones <= swdio_in ? (ones == 7'd64 ? ones : ones + 7'd1) : 7'd0;
    select_shift <= {swdio_in, select_shift[15:1]};
    if (reset_ends) seen_reset <= 1'b1;
    if (!swd_mode && seen_reset && {swdio_in, select_shift[15:1]} == 16'hE79E) begin
      swd_mode <= 1'b1;
      seen_reset <= 1'b0;
    end

    if (reset_ends) begin
      phase <= IDLE;
      swdio_oe <= 1'b0;
    end else if (swd_mode) begin
      // Rising edges are numbered from the start bit: request bits on 1-8,
      // turnaround on 9; the target drives each ACK bit just after edges 9,
      // 10 and 11, where the host samples it before the next edge.
      case (phase)
        IDLE:
        if (swdio_in) begin  // start bit
          request <= 8'd1;
          count <= 6'd1;
          phase <= REQUEST;
        end
        REQUEST: begin
          request[count] <= swdio_in;
          count <= count + 6'd1;
          if (count == 6'd7) begin
            // parity over APnDP, RnW, A2, A3; stop 0; park 1
            if ((^request[4:1]) == request[5] && request[6] == 1'b0 && swdio_in) begin
              phase <= ACK;
              count <= 6'd0;
            end else phase <= IDLE;
          end
        end
        ACK: begin
          swdio_oe <= 1'b1;
          swdio_out <= (count == 6'd0);  // OK = 1, 0, 0
          count <= count + 6'd1;
          if (count == 6'd2) begin
            count <= 6'd0;
            phase <= rnw ? READ : WRITE;
            if (rnw) begin
              // AP reads are posted: return the last AP result.
              data <= apndp ? {^rdbuff, rdbuff} : {^dp_read(a), dp_read(a)};
              if (apndp) rdbuff <= ap_read(a);
            end
          end
        end
        READ: begin
          // data bits just after edges 12 to 43, parity after 44, release
          // after 45
          if (count < 6'd33) swdio_out <= data[count];
          else swdio_oe <= 1'b0;
          count <= count + 6'd1;
          if (count == 6'd33) phase <= TRN_BACK;
        end
        TRN_BACK: phase <= IDLE;  // the host's turnaround clock after a read
        WRITE: begin
          // release after edge 12; edge 13 is the turnaround; data on edges
          // 14 to 45, parity on 46
          if (count == 6'd0) swdio_oe <= 1'b0;
          if (count >= 6'd2 && count <= 6'd33) data[count - 6'd2] <= swdio_in;
          count <= count + 6'd1;
          if (count == 6'd34) begin
            phase <= IDLE;
            if ((^data[31:0]) != swdio_in) parity_errors <= parity_errors + 32'd1;
            else if (!apndp) begin
              if (a == 2'd1) ctrl_stat <= data[31:0];
              else if (a == 2'd2) select <= data[31:0];
            end else if (select[31:24] == 8'd0 && select[7:4] == 4'h0 && a == 2'd1)
              ap_tar <= data[31:0];
          end
        end
        default: phase <= IDLE;
      endcase
    end
  end
endmodule
