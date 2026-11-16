(* Emits the chip's Verilog on stdout, with its program memories as IHP's
   SRAM macro (the tests and proofs build the same circuit with the macro's
   behaviour in flip-flops; see [Pe_core.Memory]). The rule in src/dune runs this on
   every `dune build` and writes src/protocol_emulator.v, which the Tiny
   Tapeout flow consumes; CI fails if the committed copy is out of date. *)

open! Core
open! Hardcaml
module Top = Pe_hw.Top
module C = Circuit.With_interface (Top.I) (Top.O)

let () =
  let circuit = C.create_exn ~name:"protocol_emulator" (Top.create ~memory:Macro) in
  Rtl.print Verilog circuit
;;
