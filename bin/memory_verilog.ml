(* Emits one program memory as Verilog, built either way [Pe_core] can
   build it: [model], the flip-flop description the tests and proofs use,
   or [macro], an instance of IHP's SRAM macro tied off as the chip ties
   it. formal/sram_equiv.sh proves the two equal, with IHP's behavioural
   model inside the macro. Both come from [Pe_core.program_memory], so the
   macro's tie-offs checked there are the chip's. *)

open! Core
open! Hardcaml
open! Signal
module P = Pe_hw.Pe_core

let () =
  let memory, name =
    match Sys.get_argv () with
    | [| _; "model" |] -> P.Memory.Model, "memory_model"
    | [| _; "macro" |] -> P.Memory.Macro, "memory_macro"
    | _ -> failwith "usage: memory_verilog (model|macro)"
  in
  let clock = input "clock" 1 in
  let dout =
    P.program_memory
      memory
      ~clock
      ~n:0
      ~we:(input "we" 1)
      ~addr:(input "addr" P.pc_bits)
      ~data:(input "data" 16)
  in
  Rtl.print Verilog (Circuit.create_exn ~name [ output "dout" dout ])
;;
