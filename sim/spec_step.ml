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

  (* "What a push sends: the bits shifted in since the last one,
     right-justified." *)
  let justify ~msb_first isr isr_count =
    mux2
      msb_first
      (isr &: low16 (mask32 isr_count))
      (low16 (log_shift srl (uresize isr 32) (of_int ~width:5 16 -: isr_count)))
  ;;

  (* "The CRC register takes one bit: the first bit that instruction
     shifted. If the bit differs from the register's bit 0 the register
     shifts right and the polynomial is added, otherwise it only shifts." *)
  let crc_take crc ~poly ~first =
    let shifted = concat_msb [ gnd; select crc 31 1 ] in
    mux2 (select crc 0 0 <>: first) (shifted ^: poly) shifted
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
      (* "A jump goes to PAGE x 64 + addr." *)
      finish ~st ~pc:(mux2 taken (concat_msb [ s.page; select ins 5 0 ]) (s.pc +:. 1)) ()
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
      let m = low16 (mask32 count) in
      let lsb_first =
        let kept = log_shift srl (uresize s.isr 32) count in
        let incoming =
          log_shift sll (uresize (v &: m) 32) (of_int ~width:5 16 -: count)
        in
        low16 (kept |: incoming)
      in
      (* MSB first, by rotation: rotate the ISR left by [count] (rotating by
         16 is the identity) and replace the bits that wrapped round with
         the new ones. *)
      let msb_first = (log_shift rotl s.isr count &: ~:m) |: (v &: m) in
      let isr = mux2 i.in_msb_first msb_first lsb_first in
      let isr_count = sat16 s.isr_count count in
      let crc =
        mux2
          (i.crc_in &: s.crc_run)
          (crc_take
             s.crc
             ~poly:i.crc_poly
             ~first:
               (* MSB first, the first bit in is the highest of the [count]
                  taken: bring it down to bit 0. *)
               (mux2
                  i.in_msb_first
                  (select (log_shift srl (v &: m) (count -:. 1)) 0 0)
                  (select v 0 0)))
          s.crc
      in
      (* "Autopush: an IN that fills the ISR pushes it in the same cycle, and
         waits instead while the RX FIFO is full." It fills it when the bits
         it has and the bits it takes reach the threshold. *)
      let fills =
        i.autopush &: (uresize s.isr_count 6 +: uresize count 6 >=: uresize i.threshold 6)
      in
      let word = justify ~msb_first:i.in_msb_first isr isr_count in
      ( word
      , pick
          fills
          (pick
             i.rx_full
             (stall ())
             (finish ~st:{ s with isr = zero 16; isr_count = zero 5; crc } ~push:vdd ()))
          (finish ~st:{ s with isr; isr_count; crc } ()) )
    in
    let in_word, r_in = r_in in
    (* --- OUT --- *)
    let r_out =
      let m = low16 (mask32 count) in
      (* MSB first, by rotation: rotating the OSR left by [count] brings its
         top [count] bits round to the bottom, which is the data; what is
         left above them is the rest of the OSR. *)
      let rotated = log_shift rotl s.osr count in
      let data = mux2 i.out_msb_first (rotated &: m) (s.osr &: m) in
      let st =
        { s with
          osr =
            mux2
              i.out_msb_first
              (rotated &: ~:m)
              (low16 (log_shift srl (uresize s.osr 32) count))
        ; osr_count = sat16 s.osr_count count
        }
      in
      let dst = select ins 8 7 in
      let st =
        { st with
          pin_out =
            mux2 (dst ==:. 0) (write_pins s.pin_out ~base:i.out_base ~count data) s.pin_out
        ; x = mux2 (dst ==:. 1) data s.x
        ; y = mux2 (dst ==:. 2) data s.y
        ; crc =
            mux2
              (~:(i.crc_in) &: s.crc_run)
              (crc_take
                 s.crc
                 ~poly:i.crc_poly
                 ~first:
                   (* The first bit out is the OSR's lowest, or its highest
                      when shifting MSB first. *)
                   (mux2 i.out_msb_first (select s.osr 15 15) (select s.osr 0 0)))
              s.crc
        }
      in
      (* "Autopull: an OUT that empties the OSR refills it from the TX FIFO
         in the same cycle, and an OUT that finds it empty waits for a
         word": that tick takes the word if there is one, and the OUT
         itself runs on the next. *)
      let word = { st with osr = i.tx_head; osr_count = zero 5 } in
      let emptied = st.osr_count >=: i.threshold in
      let has = ~:(i.tx_empty) in
      pick
        (i.autopull &: (s.osr_count >=: i.threshold))
        (pick has { none with st = { s with osr = i.tx_head; osr_count = zero 5 }; pull = vdd } (stall ()))
        (pick (i.autopull &: emptied &: has) (finish ~st:word ~pull:vdd ()) (finish ~st ()))
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
           (finish ~st:{ s with isr = zero 16; isr_count = zero 5 } ~push:vdd ()))
    in
    (* --- MOV --- *)
    let r_mov =
      let dst = select ins 8 6
      and src = select ins 5 3 in
      (* "As a source: its low 16 bits, after which it holds its high 16
         and stops following the data. As a destination: it starts again
         from its initial value, whatever the source." *)
      let crc_low = low16 (mux2 i.crc_invert ~:(s.crc) s.crc) in
      let v = mux src [ s.x; s.y; uresize i.lines 16; s.isr; s.osr; zero 16; crc_low ] in
      let valid = (dst <>:. 7) &: (src <>:. 7) in
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
        ; crc =
            mux2
              (dst ==:. 6)
              i.crc_init
              (mux2 (src ==:. 6) (uresize (select s.crc 31 16) 32) s.crc)
        ; crc_run = mux2 (dst ==:. 6) vdd (mux2 (src ==:. 6) gnd s.crc_run)
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
          ; (* "set page, n": n modulo the number of pages *)
            page = mux2 (dst ==:. 3) (select ins (P.page_bits - 1) 0) s.page
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
          ; (* "PAGE starts as the page START is in" *)
            page = select i.start (P.pc_bits - 1) (P.pc_bits - P.page_bits)
          ; x = zero 16
          ; y = zero 16
          ; isr = zero 16
          ; isr_count = zero 5
          ; osr = zero 16
          ; osr_count = i.threshold
          ; delay_left = zero 4
          ; waiting = gnd
          ; wait_count = zero 16
          ; crc = i.crc_init
          ; crc_run = vdd
          }
      }
    in
    (* Between clock-divider ticks the thread is frozen: [none] is the
       current state with no FIFO strobes. *)
    let r =
      pick
        (~:(i.enable))
        held
        (pick (~:(i.tick)) none (pick (s.delay_left <>:. 0) counting_down executed))
    in
    (* The value offered to the RX FIFO is always the right-justified ISR; the
       FIFO only takes it when [push] is high. (Defining it as zero when not
       pushing gives identical behaviour, but the equivalence checker compares
       the FIFO's data input as a function, enabled or not.) *)
    (* An IN that pushes sends the ISR as that IN leaves it. *)
    let justified_isr =
      mux2
        (select ins 15 13 ==:. 2)
        in_word
        (justify ~msb_first:i.in_msb_first s.isr s.isr_count)
    in
    ignore (r.push_value : C.t);
    { P.Step_out.next = r.st; pull = r.pull; push = r.push; push_value = justified_isr }
  ;;
end
