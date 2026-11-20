(* Emits one program memory, or with [buffer] the packet buffer, as Verilog, built either way [Pe_core] can
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
  let usage () = failwith "usage: memory_verilog (model|macro) [buffer]" in
  let args = Array.to_list (Sys.get_argv ()) |> List.tl_exn in
  let memory, name =
    match List.hd args with
    | Some "model" -> P.Memory.Model, "memory_model"
    | Some "macro" -> P.Memory.Macro, "memory_macro"
    | _ -> usage ()
  in
  let clock = input "clock" 1 in
  let we = input "we" 1 in
  let data = input "data" 16 in
  let dout =
    match List.tl_exn args with
    | [] -> P.program_memory memory ~clock ~n:0 ~we ~addr:(input "addr" P.pc_bits) ~data
    | [ "buffer" ] ->
      (* The packet buffer: the same construction, 1024 words. *)
      P.memory_block
        memory
        ~clock
        ~words:P.buffer_size
        ~prefix:"buf"
        ~instance:"sram_buf"
        ~we
        ~addr:(input "addr" P.buffer_bits)
        ~data
    | _ -> usage ()
  in
  Rtl.print Verilog (Circuit.create_exn ~name [ output "dout" dout ])
;;
