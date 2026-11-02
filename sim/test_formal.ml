(* Formal verification of the core.

   1. The combinational spec (sim/spec_step.ml) is checked against the
      reference model (model/isa.ml) on every one of the 65,536 instruction
      words, each from a random state with random inputs and configuration.
      This anchors the spec to the model everything else is tested against.

   2. The equivalence proof. The two-thread core is built twice: once with
      its real datapath in both threads, once with the spec substituted in
      both, everything else identical. Hardcaml's sequential equivalence
      checker cuts both circuits at their registers, so every register
      becomes a free variable, and asks a SAT solver whether any state and
      any inputs make the next-state or outputs differ. UNSAT is a proof: one
      clock of the RTL equals one step of the spec in each thread, for every
      state of both threads, instruction word, pin input, FIFO state and
      configuration, including thread 1 starting from whatever pin value
      thread 0 just produced.

      What the proof does not cover: the code that composes the threads
      (shared memory read ports, pin priority, per-thread FIFOs) is the same
      in both builds. That part is checked by the differential test in
      test_core.ml against the reference model, which composes threads its
      own way.

   3. Test the proof: every planted RTL bug must make it SAT, with a
      counterexample. A proof that cannot fail proves nothing. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module P = Pe_hw.Pe_core
module Spec_bits = Spec_step.Make (Bits)
module Spec_signal = Spec_step.Make (Signal)
module Core_circuit = Circuit.With_interface (P.I) (P.O)

(* --- 1. Spec against the reference model ---------------------------------- *)

type sample =
  { word : int
  ; state : int P.Thread_state.t
  ; lines : int
  ; tx_head : int option (* None = TX FIFO empty *)
  ; rx_full : bool
  ; tick : bool (* false: between clock-divider ticks *)
  ; config : Isa.Thread_config.t
  }

let random_sample rs word =
  let r n = Random.State.int rs n in
  let config =
    { Isa.Thread_config.start = r 64
    ; out_base = r 8
    ; out_count = 1 + r 8
    ; set_base = r 8
    ; set_count = 1 + r 8
    ; in_base = r 8
    ; threshold = 1 + r 16
    ; timeout_vector = r 64
    ; timeout = (if r 2 = 0 then r 4 else r 65536)
    ; sideset_base = r 8
    ; sideset_count = r 4
    ; clkdiv = r 4
    }
  in
  let state =
    { P.Thread_state.pc = r 64
    ; x = (if r 4 = 0 then 0 else r 65536)
    ; y = (if r 4 = 0 then 0 else r 65536)
    ; isr = r 65536
    ; isr_count = r 17
    ; osr = r 65536
    ; osr_count = r 17
    ; delay_left = (if r 5 = 0 then r 16 else 0)
    ; waiting = r 2
    ; wait_count = (if r 2 = 0 then r 4 else r 65536)
    ; pin_out = r 256
    }
  in
  { word
  ; state
  ; lines = r 256
  ; tx_head = (if r 2 = 0 then None else Some (r 65536))
  ; rx_full = r 2 = 0
  ; tick = r 4 > 0
  ; config
  }
;;

type observed =
  { next : int P.Thread_state.t
  ; pull : bool
  ; push : int option
  }
[@@deriving sexp_of, equal]

let run_model s =
  let program =
    Array.init Isa.program_size ~f:(fun a ->
      Isa.Instruction.decode (if a = s.state.pc then s.word else 0))
  in
  (* All pins as inputs, so the pin levels the thread sees are exactly
     [s.lines]. *)
  let m =
    Isa.create
      ~program
      ~pin_modes:(Array.create ~len:Isa.num_pins Isa.Pin_mode.Input)
      ~threads:[ s.config ]
  in
  (* The spec is one step of a thread given the levels it sees, so read the
     pins directly, without the synchroniser in front. *)
  Isa.set_sync_bypass m 0xFF;
  let th = Isa.thread m 0 in
  th.pc <- s.state.pc;
  th.x <- s.state.x;
  th.y <- s.state.y;
  th.isr <- s.state.isr;
  th.isr_count <- s.state.isr_count;
  th.osr <- s.state.osr;
  th.osr_count <- s.state.osr_count;
  th.delay_left <- s.state.delay_left;
  th.waiting <- s.state.waiting = 1;
  th.wait_count <- s.state.wait_count;
  (* A thread is between ticks while its divider counter is non-zero. *)
  th.div_count <- (if s.tick then 0 else 1);
  m.pin_out <- s.state.pin_out;
  Option.iter s.tx_head ~f:(Queue.enqueue th.tx_fifo);
  if s.rx_full then for k = 1 to Isa.fifo_depth do Queue.enqueue th.rx_fifo k done;
  let tx_before = Queue.length th.tx_fifo
  and rx_before = Queue.length th.rx_fifo in
  Isa.step m ~inputs:s.lines;
  { next =
      { P.Thread_state.pc = th.pc
      ; x = th.x
      ; y = th.y
      ; isr = th.isr
      ; isr_count = th.isr_count
      ; osr = th.osr
      ; osr_count = th.osr_count
      ; delay_left = th.delay_left
      ; waiting = Bool.to_int th.waiting
      ; wait_count = th.wait_count
      ; pin_out = Isa.pin_out m
      }
  ; pull = Queue.length th.tx_fifo < tx_before
  ; push =
      (if Queue.length th.rx_fifo > rx_before
       then Some (Queue.to_list th.rx_fifo |> List.last_exn)
       else None)
  }
;;

let run_spec s =
  let b w v = Bits.of_int ~width:w v in
  let state = P.Thread_state.map2 P.Thread_state.port_widths s.state ~f:b in
  let c = s.config in
  let out =
    Spec_bits.step
      state
      { P.Step_in.enable = Bits.vdd
      ; tick = Bits.of_bool s.tick
      ; instr = b 16 s.word
      ; lines = b 8 s.lines
      ; tx_empty = Bits.of_bool (Option.is_none s.tx_head)
      ; tx_head = b 16 (Option.value s.tx_head ~default:0)
      ; rx_full = Bits.of_bool s.rx_full
      ; start = b 6 c.start
      ; out_base = b 3 c.out_base
      ; out_count = b 4 c.out_count
      ; set_base = b 3 c.set_base
      ; set_count = b 4 c.set_count
      ; in_base = b 3 c.in_base
      ; threshold = b 5 c.threshold
      ; timeout_vector = b 6 c.timeout_vector
      ; timeout = b 16 c.timeout
      ; sideset_base = b 3 c.sideset_base
      ; sideset_count = b 2 c.sideset_count
      }
  in
  { next = P.Thread_state.map out.next ~f:Bits.to_int
  ; pull = Bits.to_bool out.pull
  ; push = Option.some_if (Bits.to_bool out.push) (Bits.to_int out.push_value)
  }
;;

let%test_unit "spec equals the reference model on all 65,536 instruction words" =
  let rs = Random.State.make [| 2027 |] in
  for pass = 1 to 2 do
    for word = 0 to Isa.word_mask do
      let s = random_sample rs word in
      let model = run_model s
      and spec = run_spec s in
      if not (equal_observed model spec)
      then
        raise_s
          [%message
            "spec and model disagree"
              (pass : int)
              ~instruction:(Isa.Instruction.to_string (Isa.Instruction.decode word) : string)
              (word : int)
              (model : observed)
              (spec : observed)]
    done
  done
;;

(* --- 2. The proof ---------------------------------------------------------- *)

let rtl ?mutation () = Core_circuit.create_exn ~name:"core" (P.create ?mutation)
let spec () = Core_circuit.create_exn ~name:"core" (P.create ~datapath:Spec_signal.step)

let prove a b =
  let open Hardcaml_verify in
  let sec = Sec.create a b |> Or_error.ok_exn in
  match Sec.circuits_equivalent sec |> Or_error.ok_exn with
  | Unsat -> "UNSAT: equivalent"
  | Sat _ as r ->
    if Sys.getenv "PE_SHOW_CEX" |> Option.is_some
    then print_s [%sexp (r : Sec.Equivalence_result.t)];
    "SAT: counterexample found"
;;

let%expect_test "RTL core is equivalent to the spec (SAT proof)" =
  print_endline (prove (rtl ()) (spec ()));
  [%expect {| UNSAT: equivalent |}]
;;

(* --- 3. The proof can fail ------------------------------------------------- *)

let%expect_test "every planted RTL bug is refuted with a counterexample" =
  List.iter P.Mutation.all ~f:(fun mutation ->
    printf
      "%-28s %s\n"
      (Sexp.to_string (P.Mutation.sexp_of_t mutation))
      (prove (rtl ~mutation ()) (spec ())));
  [%expect {|
    Xdec_never_decrements        SAT: counterexample found
    Wait_timeout_ignores_budget  SAT: counterexample found
    Delay_field_ignored          SAT: counterexample found
    Set_pins_count_off_by_one    SAT: counterexample found
    Push_not_right_justified     SAT: counterexample found
    Pin_priority_inverted        SAT: counterexample found
    Fetch_port_crossed           SAT: counterexample found
    Chain_ignores_full           SAT: counterexample found
    Sync_bypass_inverted         SAT: counterexample found
    |}]
;;
