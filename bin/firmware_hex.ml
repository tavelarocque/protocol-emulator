(* Prints an assembled firmware image, one 16-bit word per line in hex.
   Used to generate the .hex files the cocotb testbench loads over SPI.

   Usage: firmware_hex.exe NAME, where NAME is one of Firmware.all, or
   two_protocols, bridge, uart_duplex, usb_host, ps2 or can for the two-thread
   images, or eth_tx, which is placed at its own origin. *)

open! Core
module Isa = Pe_model.Isa

let () =
  let name = (Sys.get_argv ()).(1) in
  let image =
    match name with
    | "two_protocols" -> Pe_model.Firmware.Two_protocols.image
    | "bridge" -> Pe_model.Firmware.Bridge.image
    | "uart_duplex" -> Pe_model.Firmware.Uart_duplex.image
    | "usb_host" -> Pe_model.Firmware.Usb_host.image
    | "ps2" -> Pe_model.Firmware.Ps2.image
    | "can" -> Pe_model.Firmware.Can.image
    | "eth_tx" -> Pe_model.Firmware.eth_tx_image ()
    | name ->
      Pe_model.Asm.assemble
        (List.Assoc.find_exn Pe_model.Firmware.all name ~equal:String.equal)
  in
  Array.iter image ~f:(fun instr ->
    printf "%04x\n" (Isa.Instruction.encode instr))
;;
