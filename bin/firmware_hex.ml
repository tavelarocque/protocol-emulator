(* Prints an assembled firmware image, one 16-bit word per line in hex.
   Used to generate the .hex files the cocotb testbench loads over SPI.

   Usage: firmware_hex.exe NAME, where NAME is one of Firmware.all, or
   two_protocols or bridge for the two-thread images. *)

open! Core
module Isa = Pe_model.Isa

let () =
  let name = (Sys.get_argv ()).(1) in
  let image =
    match name with
    | "two_protocols" -> Pe_model.Firmware.Two_protocols.image
    | "bridge" -> Pe_model.Firmware.Bridge.image
    | name ->
      Pe_model.Asm.assemble
        (List.Assoc.find_exn Pe_model.Firmware.all name ~equal:String.equal)
  in
  Array.iter image ~f:(fun instr ->
    printf "%04x\n" (Isa.Instruction.encode instr))
;;
