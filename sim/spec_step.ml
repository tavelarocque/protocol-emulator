(* An executable, combinational specification of one step of a thread.

   This is the formal counterpart of model/isa.ml: the same semantics,
   written as a pure function from (state, inputs) to next state, generic
   over Hardcaml's [Comb.S] so it can be evaluated three ways:

   - on [Bits], to check it against the OCaml reference model;
   - on [Signal], to build a circuit the equivalence checker compares with
     the RTL in hw/pe_core.ml;
   - (via the checker) on SAT variables, for the proof itself.

   It is deliberately written in a different style from the RTL. The RTL
   builds one shared datapath and an imperative [Always] block; this computes
   the complete next state separately for each opcode (as Arm's ISA-Formal
   does) and selects by opcode, and uses different formulations where it can
   (pin writes by rotate-and-mask rather than per-pin muxes). *)

open! Core
open! Hardcaml
module P = Pe_hw.Pe_core

module Make (C : Comb.S) = struct
  open C

  type result =
    { st : C.t P.Thread_state.t
    ; pull : C.t
    ; push : C.t
    ; push_value : C.t
    }

  let pick c (a : result) (b : result) =
    { st = P.Thread_state.map2 a.st b.st ~f:(fun a b -> mux2 c a b)
    ; pull = mux2 c a.pull b.pull
    ; push = mux2 c a.push b.push
    ; push_value = mux2 c a.push_value b.push_value
    }
  ;;

  let mask32 n = log_shift sll (ones 32) n |> ( ~: )
  let low16 x = select x 15 0

  (* min(16, a + b) *)
  let sat16 a b =
    let s = uresize a 6 +: uresize b 6 in
    mux2 (s >:. 16) (of_int ~width:5 16) (uresize s 5)
  ;;

  (* Bits [0, count) of an 8-bit field, as a mask. *)
  let mask8 count =
    concat_lsb (List.init 8 ~f:(fun k -> of_int ~width:5 k <: uresize count 5))
  ;;

  (* Write the low bits of [v] to [count] pins from [base], wrapping. *)
  let write_pins cur ~base ~count v =
    let m = log_shift rotl (mask8 count) base in
    let d = log_shift rotl (select v 7 0) base in
    cur &: ~:m |: (d &: m)
  ;;

  let read_pins lines ~base ~count =
    uresize (log_shift rotr lines base &: mask8 count) 16
  ;;

  let step (s : C.t P.Thread_state.t) (i : C.t P.Step_in.t) : C.t P.Step_out.t =
    let ins = i.instr in
    (* Side-set splits the 4-bit delay field: with n side-set bits the
       value is field[3:4-n] and the delay is field[3-n:0]. Written as a
       per-n case split rather than the RTL's shifts. *)
    let field = select ins 12 9 in
    let n = i.sideset_count in
    let delay =
      mux n [ field; uresize (select field 2 0) 4; uresize (select field 1 0) 4; uresize (select field 0 0) 4 ]
    in
    let side =
      mux n [ zero 8; uresize (select field 3 3) 8; uresize (select field 3 2) 8; uresize (select field 3 1) 8 ]
    in
    let count =
      let c = select ins 3 0 in
      mux2 (c ==:. 0) (of_int ~width:5 16) (uresize c 5)
    in
    let none = { st = s; pull = gnd; push = gnd; push_value = zero 16 } in
    (* Complete the instruction: go to [pc], load the delay field. *)
    let finish ?(st = s) ?(pc = s.pc +:. 1) ?(pull = gnd) ?(push = gnd) ?(push_value = zero 16) () =
      { st = { st with pc; delay_left = delay; waiting = gnd }; pull; push; push_value }
    in
    let stall ?(st = s) () = { none with st } in
    (* --- JMP --- *)
    let r_jmp =
      let cond = select ins 8 6 in
      let taken =
        mux
          cond
          [ vdd
          ; s.x ==:. 0
          ; s.x <>:. 0
          ; s.y ==:. 0
          ; s.y <>:. 0
          ; s.x <>: s.y
          ; s.osr_count <: i.threshold
          ; s.isr_count <: i.threshold
          ]
      in
      let st =
        { s with
          x = mux2 (cond ==:. 2) (s.x -:. 1) s.x
        ; y = mux2 (cond ==:. 4) (s.y -:. 1) s.y
        }
      in
      finish ~st ~pc:(mux2 taken (select ins 5 0) (s.pc +:. 1)) ()
    in
    (* --- WAIT --- *)
    let r_wait =
      let level = mux (select ins 7 5) (bits_lsb i.lines) in
      let met = level ==: select ins 8 8 in
      let timed = select ins 4 4 in
      let budget = mux2 s.waiting s.wait_count i.timeout in
      pick
        met
        (finish ())
        (pick
           (~:timed)
           (stall ())
           (pick
              (budget ==:. 0)
              (finish ~pc:i.timeout_vector ())
              (stall ~st:{ s with waiting = vdd; wait_count = budget -:. 1 } ())))
    in
    (* --- IN --- *)
    let r_in =
      let v =
        mux
          (select ins 8 7)
          [ read_pins i.lines ~base:i.in_base ~count; s.x; s.y; zero 16 ]
      in
      let kept = log_shift srl (uresize s.isr 32) count in
      let incoming =
        log_shift sll (uresize (v &: low16 (mask32 count)) 32) (of_int ~width:5 16 -: count)
      in
      finish
        ~st:{ s with isr = low16 (kept |: incoming); isr_count = sat16 s.isr_count count }
        ()
    in
    (* --- OUT --- *)
    let r_out =
      let data = s.osr &: low16 (mask32 count) in
      let st =
        { s with
          osr = low16 (log_shift srl (uresize s.osr 32) count)
        ; osr_count = sat16 s.osr_count count
        }
      in
      let dst = select ins 8 7 in
      finish
        ~st:
          { st with
            pin_out =
              mux2
                (dst ==:. 0)
                (write_pins s.pin_out ~base:i.out_base ~count data)
                s.pin_out
          ; x = mux2 (dst ==:. 1) data s.x
          ; y = mux2 (dst ==:. 2) data s.y
          }
        ()
    in
    (* --- PUSH / PULL --- *)
    let r_pushpull =
      let is_pull = select ins 8 8 in
      pick
        is_pull
        (pick
           i.tx_empty
           (stall ())
           (finish ~st:{ s with osr = i.tx_head; osr_count = zero 5 } ~pull:vdd ()))
        (pick
           i.rx_full
           (stall ())
           (finish
              ~st:{ s with isr = zero 16; isr_count = zero 5 }
              ~push:vdd
              ~push_value:
                (low16
                   (log_shift srl (uresize s.isr 32) (of_int ~width:5 16 -: s.isr_count)))
              ()))
    in
    (* --- MOV --- *)
    let r_mov =
      let dst = select ins 8 6
      and src = select ins 5 3 in
      let v = mux src [ s.x; s.y; uresize i.lines 16; s.isr; s.osr; zero 16 ] in
      let valid = (dst <:. 6) &: (src <:. 6) in
      let st =
        { s with
          x = mux2 (dst ==:. 0) v s.x
        ; y = mux2 (dst ==:. 1) v s.y
        ; pin_out =
            mux2
              (dst ==:. 2)
              (write_pins s.pin_out ~base:i.out_base ~count:i.out_count v)
              s.pin_out
        ; isr = mux2 (dst ==:. 3) v s.isr
        ; isr_count = mux2 (dst ==:. 3) (zero 5) s.isr_count
        ; osr = mux2 (dst ==:. 4) v s.osr
        ; osr_count = mux2 (dst ==:. 4) (zero 5) s.osr_count
        }
      in
      finish ~st:(P.Thread_state.map2 st s ~f:(fun a b -> mux2 valid a b)) ()
    in
    (* --- SET --- *)
    let r_set =
      let dst = select ins 8 7 in
      let v = uresize (select ins 4 0) 16 in
      finish
        ~st:
          { s with
            pin_out =
              mux2
                (dst ==:. 0)
                (write_pins s.pin_out ~base:i.set_base ~count:i.set_count v)
                s.pin_out
          ; x = mux2 (dst ==:. 1) v s.x
          ; y = mux2 (dst ==:. 2) v s.y
          }
        ()
    in
    let r_nop = finish () in
    let executed =
      List.fold_right
        (List.mapi
           [ r_jmp; r_wait; r_in; r_out; r_pushpull; r_mov; r_set; r_nop ]
           ~f:(fun n r -> n, r))
        ~init:r_nop
        ~f:(fun (n, r) acc -> pick (select ins 15 13 ==:. n) r acc)
    in
    (* Side-set is driven on every executing cycle, stalled or not, over
       whatever the instruction wrote. *)
    let executed =
      { executed with
        st =
          { executed.st with
            pin_out = write_pins executed.st.pin_out ~base:i.sideset_base ~count:n side
          }
      }
    in
    let counting_down =
      { none with st = { s with delay_left = s.delay_left -:. 1 } }
    in
    let held =
      { none with
        st =
          { s with
            pc = i.start
          ; x = zero 16
          ; y = zero 16
          ; isr = zero 16
          ; isr_count = zero 5
          ; osr = zero 16
          ; osr_count = i.threshold
          ; delay_left = zero 4
          ; waiting = gnd
          ; wait_count = zero 16
          }
      }
    in
    let r =
      pick (~:(i.enable)) held (pick (s.delay_left <>:. 0) counting_down executed)
    in
    (* The value offered to the RX FIFO is always the right-justified ISR; the
       FIFO only takes it when [push] is high. (Defining it as zero when not
       pushing gives identical behaviour, but the equivalence checker compares
       the FIFO's data input as a function, enabled or not.) *)
    let justified_isr =
      low16 (log_shift srl (uresize s.isr 32) (of_int ~width:5 16 -: s.isr_count))
    in
    ignore (r.push_value : C.t);
    { P.Step_out.next = r.st; pull = r.pull; push = r.push; push_value = justified_isr }
  ;;
end
