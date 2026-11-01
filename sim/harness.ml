open! Core
open! Hardcaml
module Uart_tx = Pe_hw.Uart_tx
module Uart_model = Pe_model.Uart_model
module Sim = Cyclesim.With_interface (Uart_tx.I) (Uart_tx.O)

let create_sim ?mutation () = Sim.create (Uart_tx.create ?mutation)

(* Reset, send one byte, and record the line level on every cycle while the
   transmitter reports busy. Returns None if it never finishes (a hung design
   must fail the test, not hang the test run). *)
let transmit sim ~divisor ~byte =
  let inputs : _ Uart_tx.I.t = Cyclesim.inputs sim in
  let outputs : _ Uart_tx.O.t = Cyclesim.outputs sim in
  inputs.clear := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.clear := Bits.gnd;
  inputs.divisor := Bits.of_int ~width:Uart_tx.divisor_width divisor;
  inputs.data := Bits.of_int ~width:8 byte;
  inputs.start := Bits.vdd;
  Cyclesim.cycle sim;
  inputs.start := Bits.gnd;
  let limit = (10 * (divisor + 1)) + 16 in
  let rec go n acc =
    if not (Bits.to_bool !(outputs.busy))
    then Some (List.rev acc)
    else if n >= limit
    then None
    else (
      let level = Bits.to_bool !(outputs.tx) in
      Cyclesim.cycle sim;
      go (n + 1) (level :: acc))
  in
  go 0 []
;;

type verdict =
  { exact_ok : bool (* cycle-exact match with the ideal frame *)
  ; receiver_ok : bool (* a real receiver decodes exactly [byte] *)
  }

let check ?mutation ~divisor ~byte () =
  let sim = create_sim ?mutation () in
  match transmit sim ~divisor ~byte with
  | None -> { exact_ok = false; receiver_ok = false }
  | Some samples ->
    let exact_ok =
      List.equal Bool.equal samples (Uart_model.frame ~divisor byte)
    in
    (* The line idles high after the frame, so give the receiver some idle
       time to sample a stop bit that ends early. *)
    let line = samples @ List.init (2 * divisor) ~f:(fun _ -> true) in
    let receiver_ok =
      match Uart_model.decode ~divisor line with
      | Ok [ b ] -> b = byte
      | Ok _ | Error _ -> false
    in
    { exact_ok; receiver_ok }
;;
