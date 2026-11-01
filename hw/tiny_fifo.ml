(* 4-entry synchronous FIFO, 16 bits wide.

   Push into a full FIFO and pop from an empty one are ignored. [level],
   [full] and [empty] reflect the state at the start of the cycle, which is
   what makes the core's PULL/PUSH stall rules match the reference model. *)

open! Core
open! Hardcaml
open! Signal

let depth = 4

type t =
  { head : Signal.t
  ; level : Signal.t
  ; full : Signal.t
  ; empty : Signal.t
  }

let create spec ~push ~data ~pop =
  let open Always in
  let wr = Variable.reg spec ~width:2 in
  let rd = Variable.reg spec ~width:2 in
  let level = Variable.reg spec ~width:3 in
  let full = level.value ==:. depth in
  let empty = level.value ==:. 0 in
  let do_push = push &: ~:full in
  let do_pop = pop &: ~:empty in
  let mem =
    List.init depth ~f:(fun a -> reg spec ~enable:(do_push &: (wr.value ==:. a)) data)
  in
  compile
    [ when_ do_push [ wr <-- wr.value +:. 1 ]
    ; when_ do_pop [ rd <-- rd.value +:. 1 ]
    ; level <-- level.value +: uresize do_push 3 -: uresize do_pop 3
    ];
  { head = mux rd.value mem; level = level.value; full; empty }
;;
