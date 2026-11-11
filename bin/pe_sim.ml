(* Command-line tools for writing firmware without the rest of the project:

     pe_sim asm PROGRAM.s
       assembles PROGRAM.s and prints one hex word per line, as the
       firmware images in test/ are

     pe_sim run PROGRAM.s [-config k=v,...] [-mode P=pp|od|in ...]
                [-tx FILE] [-cycles N] [-inputs HEX]
       runs it on thread 0 of the reference model (model/isa.ml, the model
       the RTL is checked against every cycle). TX words (one per line,
       decimal or 0x hex) are pushed whenever the TX FIFO has room. Prints
       every change of the 8 protocol pins' output as "pins CYCLE XX" (bit
       k = pin Pk as driven; an open-drain 1 and an input read as 1), and
       every word the thread pushes as "rx CYCLE WORD". Pins that are inputs
       read [-inputs] (default 0xFF).

   -config keys are the thread configuration's fields, as in docs/isa.md:
   start, out_base, out_count, set_base, set_count, in_base, threshold,
   timeout_vector, timeout, sideset_base, sideset_count, clkdiv,
   out_msb_first, in_msb_first (0 or 1). *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm

let parse_int s = Int.of_string (String.strip s)

let config_of_string s =
  List.fold
    (String.split s ~on:',' |> List.filter ~f:(fun x -> not (String.is_empty x)))
    ~init:Isa.Thread_config.default
    ~f:(fun (c : Isa.Thread_config.t) kv ->
      match String.lsplit2 kv ~on:'=' with
      | None -> failwithf "-config: %s is not key=value" kv ()
      | Some (k, v) ->
        let n = parse_int v in
        (match String.strip k with
         | "start" -> { c with start = n }
         | "out_base" -> { c with out_base = n }
         | "out_count" -> { c with out_count = n }
         | "set_base" -> { c with set_base = n }
         | "set_count" -> { c with set_count = n }
         | "in_base" -> { c with in_base = n }
         | "threshold" -> { c with threshold = n }
         | "timeout_vector" -> { c with timeout_vector = n }
         | "timeout" -> { c with timeout = n }
         | "sideset_base" -> { c with sideset_base = n }
         | "sideset_count" -> { c with sideset_count = n }
         | "clkdiv" -> { c with clkdiv = n }
         | "out_msb_first" -> { c with out_msb_first = n <> 0 }
         | "in_msb_first" -> { c with in_msb_first = n <> 0 }
         | k ->
           failwithf
             "-config: unknown key %s (keys: start, out_base, out_count, set_base, \
              set_count, in_base, threshold, timeout_vector, timeout, sideset_base, \
              sideset_count, clkdiv, out_msb_first, in_msb_first)"
             k
             ()))
;;

let modes_of_flags flags =
  let modes = Array.create ~len:Isa.num_pins Isa.Pin_mode.Input in
  List.iter flags ~f:(fun f ->
    match String.lsplit2 f ~on:'=' with
    | Some (p, m) ->
      modes.(parse_int p)
      <- (match String.lowercase (String.strip m) with
          | "pp" -> Push_pull
          | "od" -> Open_drain
          | "in" -> Input
          | m -> failwithf "-mode: %s is not pp, od or in" m ())
    | None -> failwithf "-mode: %s is not P=pp|od|in" f ());
  modes
;;

let asm_cmd =
  Command.basic
    ~summary:"assemble a program; one hex word per line"
    (let%map_open.Command file = anon ("PROGRAM.s" %: string) in
     fun () ->
       Array.iter (Asm.assemble (In_channel.read_all file)) ~f:(fun i ->
         printf "%04x\n" (Isa.Instruction.encode i)))
;;

let run_cmd =
  Command.basic
    ~summary:"run a program on thread 0 of the reference model"
    (let%map_open.Command file = anon ("PROGRAM.s" %: string)
     and config =
       flag
         "-config"
         (optional_with_default "" string)
         ~doc:
           "k=v,... thread config: start out_base out_count set_base set_count in_base \
            threshold timeout_vector timeout sideset_base sideset_count clkdiv \
            out_msb_first in_msb_first"
     and modes = flag "-mode" (listed string) ~doc:"P=pp|od|in pin mode (default in)"
     and tx = flag "-tx" (optional string) ~doc:"FILE TX words, one per line"
     and cycles = flag "-cycles" (optional_with_default 100_000 int) ~doc:"N cycles to run"
     and inputs = flag "-inputs" (optional_with_default "0xFF" string) ~doc:"HEX input pin levels" in
     fun () ->
       let m =
         Isa.create
           ~program:(Asm.assemble (In_channel.read_all file))
           ~pin_modes:(modes_of_flags modes)
           ~threads:[ config_of_string config ]
       in
       let pending =
         Queue.of_list
           (match tx with
            | None -> []
            | Some f ->
              In_channel.read_lines f
              |> List.map ~f:String.strip
              |> List.filter ~f:(fun l -> not (String.is_empty l || String.is_prefix l ~prefix:"#"))
              |> List.map ~f:parse_int)
       in
       let inputs = parse_int inputs in
       let last = ref (-1) in
       for c = 0 to cycles - 1 do
         (match Queue.peek pending with
          | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
          | None -> ());
         let pins = Isa.pin_out m land 0xFF in
         if pins <> !last
         then (
           printf "pins %d %02x\n" c pins;
           last := pins);
         Isa.step m ~inputs;
         Option.iter (Isa.pop_rx m ~thread:0) ~f:(fun w -> printf "rx %d %d\n" c w)
       done)
;;

let () =
  Command_unix.run
    (Command.group ~summary:"protocol emulator firmware tools" [ "asm", asm_cmd; "run", run_cmd ])
;;
