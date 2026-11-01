(* Emits the chip's Verilog on stdout. The rule in src/dune runs this on
   every `dune build` and writes src/protocol_emulator.v, which the Tiny
   Tapeout flow consumes; CI fails if the committed copy is out of date. *)

open! Core
open! Hardcaml
module Top = Pe_hw.Top
module C = Circuit.With_interface (Top.I) (Top.O)

let () =
  let circuit = C.create_exn ~name:"protocol_emulator" Top.create in
  Rtl.print Verilog circuit
;;
