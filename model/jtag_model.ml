(* A JTAG device (IEEE 1149.1), written from the standard with no reference
   to the firmware it judges: the 16-state TAP controller, a 4-bit
   instruction register, and IDCODE, USER (32-bit, read/write) and BYPASS
   data registers. Same register map as test/jtag_tap.v, the testbench's
   device, so the OCaml and cocotb tests expect the same answers.

   Stepped once per core clock with the levels on TCK, TMS and TDI. On TCK's
   rising edge the state advances and the selected register shifts; on its
   falling edge TDO moves and Update-IR / Update-DR take effect. *)

open! Core

type state =
  | Test_logic_reset
  | Run_test_idle
  | Select_dr
  | Capture_dr
  | Shift_dr
  | Exit1_dr
  | Pause_dr
  | Exit2_dr
  | Update_dr
  | Select_ir
  | Capture_ir
  | Shift_ir
  | Exit1_ir
  | Pause_ir
  | Exit2_ir
  | Update_ir
[@@deriving sexp_of, compare, equal]

(* The state diagram: where TMS takes each state on a rising edge. *)
let next state ~tms =
  match state, tms with
  | Test_logic_reset, true -> Test_logic_reset
  | Test_logic_reset, false -> Run_test_idle
  | Run_test_idle, true -> Select_dr
  | Run_test_idle, false -> Run_test_idle
  | Select_dr, true -> Select_ir
  | Select_dr, false -> Capture_dr
  | Capture_dr, true -> Exit1_dr
  | Capture_dr, false -> Shift_dr
  | Shift_dr, true -> Exit1_dr
  | Shift_dr, false -> Shift_dr
  | Exit1_dr, true -> Update_dr
  | Exit1_dr, false -> Pause_dr
  | Pause_dr, true -> Exit2_dr
  | Pause_dr, false -> Pause_dr
  | Exit2_dr, true -> Update_dr
  | Exit2_dr, false -> Shift_dr
  | Update_dr, true -> Select_dr
  | Update_dr, false -> Run_test_idle
  | Select_ir, true -> Test_logic_reset
  | Select_ir, false -> Capture_ir
  | Capture_ir, true -> Exit1_ir
  | Capture_ir, false -> Shift_ir
  | Shift_ir, true -> Exit1_ir
  | Shift_ir, false -> Shift_ir
  | Exit1_ir, true -> Update_ir
  | Exit1_ir, false -> Pause_ir
  | Pause_ir, true -> Exit2_ir
  | Pause_ir, false -> Pause_ir
  | Exit2_ir, true -> Update_ir
  | Exit2_ir, false -> Shift_ir
  | Update_ir, true -> Select_dr
  | Update_ir, false -> Run_test_idle
;;

let i_idcode = 0b0001
let i_user = 0b1000
let ir_capture = 0b0101

type t =
  { idcode : int
  ; mutable state : state
  ; mutable ir : int
  ; mutable ir_shift : int
  ; mutable dr_shift : int
  ; mutable user : int
  ; mutable tdo : bool
  ; mutable prev_tck : bool
  ; mutable rising_edges : int
  }

let create ?(idcode = 0x1BADC0DE) () =
  { idcode
  ; state = Test_logic_reset
  ; ir = i_idcode
  ; ir_shift = 0
  ; dr_shift = 0
  ; user = 0
  ; tdo = true
  ; prev_tck = false
  ; rising_edges = 0
  }
;;

let bypassed t = not (t.ir = i_idcode || t.ir = i_user)
let tdo t = t.tdo

let step t ~tck ~tms ~tdi =
  let tdi = Bool.to_int tdi in
  if tck && not t.prev_tck
  then (
    t.rising_edges <- t.rising_edges + 1;
    (match t.state with
     | Capture_ir -> t.ir_shift <- ir_capture
     | Shift_ir -> t.ir_shift <- (t.ir_shift lsr 1) lor (tdi lsl 3)
     | Capture_dr ->
       t.dr_shift <- (if t.ir = i_idcode then t.idcode else if t.ir = i_user then t.user else 0)
     | Shift_dr ->
       t.dr_shift <- (if bypassed t then tdi else (t.dr_shift lsr 1) lor (tdi lsl 31))
     | _ -> ());
    t.state <- next t.state ~tms)
  else if t.prev_tck && not tck
  then (
    t.tdo
    <- (match t.state with
        | Shift_ir -> t.ir_shift land 1 = 1
        | Shift_dr -> t.dr_shift land 1 = 1
        | _ -> true);
    (match t.state with
     | Update_ir -> t.ir <- t.ir_shift
     | Update_dr -> if t.ir = i_user then t.user <- t.dr_shift
     | Test_logic_reset -> t.ir <- i_idcode
     | _ -> ()));
  t.prev_tck <- tck
;;
