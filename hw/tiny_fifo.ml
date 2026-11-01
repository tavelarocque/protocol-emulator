(* 4-entry synchronous FIFO, 16 bits wide.

   Push into a full FIFO and pop from an empty one are ignored. [level],
   [full] and [empty] reflect the state at the start of the cycle, which is
   what makes the core's PULL/PUSH stall rules match the reference model.
   Registers are named after [name] so two builds of the chip can be
   compared register by register. *)

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

let create ?(name = "fifo") spec ~push ~data ~pop =
  let open Always in
  let wr = Variable.reg spec ~width:2 in
  let rd = Variable.reg spec ~width:2 in
  let level = Variable.reg spec ~width:3 in
  ignore (wr.value -- (name ^ "_wr") : Signal.t);
  ignore (rd.value -- (name ^ "_rd") : Signal.t);
  ignore (level.value -- (name ^ "_level") : Signal.t);
  let full = level.value ==:. depth in
  let empty = level.value ==:. 0 in
  let do_push = push &: ~:full in
  let do_pop = pop &: ~:empty in
  let mem =
    List.init depth ~f:(fun a ->
      reg spec ~enable:(do_push &: (wr.value ==:. a)) data -- sprintf "%s_mem_%d" name a)
  in
  compile
    [ when_ do_push [ wr <-- wr.value +:. 1 ]
    ; when_ do_pop [ rd <-- rd.value +:. 1 ]
    ; level <-- level.value +: uresize do_push 3 -: uresize do_pop 3
    ];
  { head = mux rd.value mem; level = level.value; full; empty }
;;
