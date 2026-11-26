(* The reference model and the assembler in JavaScript, for the playground
   (docs/playground.html) and for exact.js, which checks it against the
   native pe_sim. Everything here is a wrapper: the run is
   Pe_model.Sim_run, the same code bin/pe_sim.ml runs.

   It defines one global object, peModel, with one function:

     peModel.run(job) -> result
     peModel.assemble(source) -> { ok: true, words: ["04f1", ...] } or as run

   job: { threads: [{ source, config, tx }]  (one or two; config as
          pe_sim's -config, tx as its -tx file's text),
          modes: ["0=pp", ...], cycles, inputs: "0xFF", stimulus: text,
          bypass: "0", lines: bool }
   result: { ok: true, output: text, words: [..], instructions: [..] }
        or { ok: false, thread, line (0 when none), message } *)

open! Core
open Js_of_ocaml
module Asm = Pe_model.Asm
module Sim_run = Pe_model.Sim_run

exception Failed of int * int * string

let get o k = Js.Unsafe.get o (Js.string k)
let str o k = Js.to_string (get o k)
let opt_str o k ~default = Js.Optdef.case (get o k) (fun () -> default) Js.to_string

(* The assembler's errors are [("assembly error" (line N) (msg M))]. *)
let assembly_error = function
  | Sexp.List [ Atom "assembly error"; List [ Atom "line"; Atom line ]; List [ Atom "msg"; Atom msg ] ] ->
    Some (Int.of_string line, msg)
  | _ -> None
;;

let message exn =
  match exn with
  | Failure s -> s
  | exn ->
    (match Exn.sexp_of_t exn with
     | Sexp.List [ Atom what; rest ] when not (String.is_empty what) ->
       what ^ ": " ^ Sexp.to_string_hum rest
     | s -> Sexp.to_string_hum s)
;;

(* Runs [f], blaming thread [thread] for what goes wrong. *)
let blame thread f =
  try f () with
  | Failed _ as e -> raise e
  | exn ->
    (match assembly_error (Exn.sexp_of_t exn) with
     | Some (line, msg) -> raise (Failed (thread, line, msg))
     | None -> raise (Failed (thread, 0, message exn)))
;;

let run job =
  let job = Js.Unsafe.coerce job in
  try
    let threads = Js.to_array (get job "threads") |> Array.to_list in
    let sources = List.map threads ~f:(fun t -> str t "source") in
    let parsed =
      List.mapi threads ~f:(fun i t ->
        blame i (fun () ->
          { Sim_run.program = Asm.assemble (str t "source")
          ; config = Sim_run.config_of_string (opt_str t "config" ~default:"")
          ; tx = Sim_run.words_of_string (opt_str t "tx" ~default:"")
          }))
    in
    let out = Buffer.create 4096 in
    blame (-1) (fun () ->
      let modes = Js.to_array (get job "modes") |> Array.to_list |> List.map ~f:Js.to_string in
      Sim_run.run
        ~lines:(Js.to_bool (get job "lines"))
        ~sync_bypass:(Sim_run.parse_int (opt_str job "bypass" ~default:"0"))
        ~threads:parsed
        ~pin_modes:(Sim_run.modes_of_flags modes)
        ~cycles:(Float.to_int (Js.float_of_number (get job "cycles")))
        ~inputs:(Sim_run.parse_int (opt_str job "inputs" ~default:"0xFF"))
        ~stimulus:(Sim_run.stimulus_of_string (opt_str job "stimulus" ~default:""))
        ~emit:(fun line ->
          Buffer.add_string out line;
          Buffer.add_char out '\n')
        ());
    let ints l = Js.array (Array.of_list_map l ~f:(fun n -> Js.number_of_float (Float.of_int n))) in
    Js.Unsafe.obj
      [| "ok", Js.Unsafe.inject Js._true
       ; "output", Js.Unsafe.inject (Js.string (Buffer.contents out))
       ; "words", Js.Unsafe.inject (ints (List.map parsed ~f:(fun t -> Array.length t.program)))
       ; "instructions", Js.Unsafe.inject (ints (List.map sources ~f:Sim_run.instruction_count))
      |]
  with
  | Failed (thread, line, msg) ->
    Js.Unsafe.obj
      [| "ok", Js.Unsafe.inject Js._false
       ; "thread", Js.Unsafe.inject (Js.number_of_float (Float.of_int thread))
       ; "line", Js.Unsafe.inject (Js.number_of_float (Float.of_int line))
       ; "message", Js.Unsafe.inject (Js.string msg)
      |]
;;

(* [pe_sim asm]: the program's words in hex, as it prints them. *)
let assemble source =
  try
    let program = blame 0 (fun () -> Asm.assemble (Js.to_string source)) in
    Js.Unsafe.obj
      [| "ok", Js.Unsafe.inject Js._true
       ; ( "words"
         , Js.Unsafe.inject
             (Js.array
                (Array.map program ~f:(fun i ->
                   Js.string (sprintf "%04x" (Pe_model.Isa.Instruction.encode i))))) )
      |]
  with
  | Failed (thread, line, msg) ->
    Js.Unsafe.obj
      [| "ok", Js.Unsafe.inject Js._false
       ; "thread", Js.Unsafe.inject (Js.number_of_float (Float.of_int thread))
       ; "line", Js.Unsafe.inject (Js.number_of_float (Float.of_int line))
       ; "message", Js.Unsafe.inject (Js.string msg)
      |]
;;

let () =
  Js.export
    "peModel"
    (Js.Unsafe.obj
       [| "run", Js.Unsafe.inject (Js.wrap_callback run)
        ; "assemble", Js.Unsafe.inject (Js.wrap_callback assemble)
       |])
;;
