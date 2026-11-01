(* Reference models for UART, written with no reference to the hardware so
   they cannot share a bug with it. Two oracles, on purpose:

   [frame] is the cycle-exact ideal waveform. It catches timing bugs that a
   real receiver would tolerate (a stop bit one cycle short, say).

   [decode] behaves like a real receiver: it waits for a falling edge and
   samples the middle of each bit. It checks the protocol meaning, and it is
   the oracle we will reuse later when the line comes from firmware running
   on the protocol-emulator core instead of a fixed UART. *)

open! Core

(* Ideal line level on every clock cycle of one 8N1 frame. true = high. *)
let frame ~divisor byte =
  let bit level = List.init divisor ~f:(fun _ -> level) in
  let data = List.init 8 ~f:(fun k -> (byte lsr k) land 1 = 1) in
  List.concat ((bit false :: List.map data ~f:bit) @ [ bit true ])
;;

module Decode_error = struct
  type t =
    | Bad_start_bit of { cycle : int }
    | Bad_stop_bit of { cycle : int }
    | Truncated_frame of { cycle : int }
  [@@deriving sexp_of, compare, equal]
end

let decode ~divisor (samples : bool list) : (int list, Decode_error.t) Result.t =
  let samples = Array.of_list samples in
  let n = Array.length samples in
  let mid = divisor / 2 in
  let rec loop t prev acc =
    if t >= n
    then Ok (List.rev acc)
    else if prev && not samples.(t)
    then (
      (* Falling edge at [t]: a frame starts. Slot 0 is the start bit,
         slots 1..8 are data, slot 9 is the stop bit. *)
      let slot k =
        let at = t + (k * divisor) + mid in
        if at < n then Some samples.(at) else None
      in
      match Option.all (List.init 10 ~f:slot) with
      | None -> Error (Decode_error.Truncated_frame { cycle = t })
      | Some bits ->
        let bits = Array.of_list bits in
        if bits.(0)
        then Error (Bad_start_bit { cycle = t })
        else if not bits.(9)
        then Error (Bad_stop_bit { cycle = t })
        else (
          let byte =
            List.foldi (List.init 8 ~f:(fun k -> bits.(k + 1))) ~init:0 ~f:(fun k acc b ->
              if b then acc lor (1 lsl k) else acc)
          in
          (* Resume hunting for the next falling edge after the middle of the
             stop bit, as a real receiver does. *)
          let resume = t + (9 * divisor) + mid in
          loop (resume + 1) true (byte :: acc)))
    else loop (t + 1) samples.(t) acc
  in
  loop 0 true []
;;
