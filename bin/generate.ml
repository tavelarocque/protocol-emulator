(* Emits the production (unmutated) UART transmitter as Verilog on stdout.
   `make verilog` writes it to src/uart_tx.v, which the Tiny Tapeout flow
   consumes. CI will regenerate it and fail if it differs from the committed
   file, so the OCaml source and the Verilog can never drift apart. *)

open! Core
open! Hardcaml
module Uart_tx = Pe_hw.Uart_tx
module C = Circuit.With_interface (Uart_tx.I) (Uart_tx.O)

let () =
  let circuit = C.create_exn ~name:"uart_tx" (fun i -> Uart_tx.create i) in
  Rtl.print Verilog circuit
;;
