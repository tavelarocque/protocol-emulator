(* Prints an assembled firmware image, one 16-bit word per line in hex.
   Used to generate the .hex files the cocotb testbench loads over SPI.

   Usage: firmware_hex.exe NAME, where NAME is one of Firmware.all. *)

open! Core
module Isa = Pe_model.Isa

let () =
  let name = (Sys.get_argv ()).(1) in
  let source = List.Assoc.find_exn Pe_model.Firmware.all name ~equal:String.equal in
  Array.iter (Pe_model.Asm.assemble source) ~f:(fun instr ->
    printf "%04x\n" (Isa.Instruction.encode instr))
;;
