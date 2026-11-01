(* Fixed-function UART transmitter, 8N1, LSB first.

   This is deliberately NOT programmable yet. It exists to prove the whole
   pipeline (Hardcaml -> simulation -> verification -> Verilog -> GDS) on
   something small before the protocol-emulator core is designed.

   Timing contract (the tests check this cycle-exactly):
   - [divisor] is the number of clock cycles per bit. It must be >= 1.
   - When idle and [start] is high on a clock edge, [data] is latched.
   - From the next cycle, [tx] drives: 1 start bit (low), 8 data bits
     (LSB first), 1 stop bit (high). Each bit lasts exactly [divisor] cycles,
     so a frame is exactly 10 * divisor cycles, during which [busy] is high.
   - [start] is ignored while busy. *)

open! Core
open! Hardcaml
open! Signal

let divisor_width = 16

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; divisor : 'a [@bits 16]
    ; data : 'a [@bits 8]
    ; start : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { tx : 'a
    ; busy : 'a
    }
  [@@deriving hardcaml]
end

(* Deliberately planted bugs. The production circuit is built with no
   mutation; the test suite builds each mutant and asserts that it fails.
   This is the "test the tests" check, kept in the repo permanently. *)
module Mutation = struct
  type t =
    | Stop_bit_short (* stop bit lasts divisor - 1 cycles *)
    | Msb_first (* data bits sent in the wrong order *)
    | Divisor_off_by_one (* every bit lasts divisor + 1 cycles *)
  [@@deriving sexp_of, enumerate, equal]
end

(* State encoding: a 2-bit register. *)
let idle = 0
let start_bit = 1
let data_bits = 2
let stop_bit = 3

let create ?mutation (i : _ I.t) : _ O.t =
  let is m =
    match mutation with
    | Some m' -> Mutation.equal m m'
    | None -> false
  in
  (* Every register below updates on the rising clock edge, all at once.
     [clear] synchronously resets them to zero. *)
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let open Always in
  let state = Variable.reg spec ~width:2 in
  let count = Variable.reg spec ~width:divisor_width in
  let bit_index = Variable.reg spec ~width:3 in
  let shift = Variable.reg spec ~width:8 in
  (* Combinational: true on the last cycle of the current bit period. *)
  let bit_period_end =
    if is Divisor_off_by_one
    then count.value ==: i.divisor
    else count.value ==: i.divisor -:. 1
  in
  let stop_period_end =
    if is Stop_bit_short then count.value ==: i.divisor -:. 2 else bit_period_end
  in
  let st n = of_int ~width:2 n in
  let tick = count <-- count.value +:. 1 in
  (* Which bit of the shift register is on the wire, and how the register
     moves on to the next bit. *)
  let current_bit, shifted =
    if is Msb_first
    then msb shift.value, lsbs shift.value @: gnd
    else lsb shift.value, gnd @: msbs shift.value
  in
  compile
    [ switch
        state.value
        [ ( st idle
          , [ when_ i.start [ shift <-- i.data; count <--. 0; state <-- st start_bit ] ] )
        ; ( st start_bit
          , [ if_
                bit_period_end
                [ count <--. 0; bit_index <--. 0; state <-- st data_bits ]
                [ tick ]
            ] )
        ; ( st data_bits
          , [ if_
                bit_period_end
                [ count <--. 0
                ; shift <-- shifted
                ; bit_index <-- bit_index.value +:. 1
                ; when_ (bit_index.value ==:. 7) [ state <-- st stop_bit ]
                ]
                [ tick ]
            ] )
        ; ( st stop_bit
          , [ if_ stop_period_end [ count <--. 0; state <-- st idle ] [ tick ] ] )
        ]
    ];
  (* The line level is a mux over the state: idle high, start low, data bit,
     stop high. Later improvement: register this output so it cannot glitch
     on state transitions. *)
  let tx = mux state.value [ vdd; gnd; current_bit; vdd ] in
  { O.tx; busy = state.value <>:. idle }
;;
