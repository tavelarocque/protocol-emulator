(* What [pe_sim run] does, as a function: parse the options, run the
   reference model, and say what happened one line at a time.

   bin/pe_sim.ml calls this from the command line, and the playground
   (playground/pe_js.ml, docs/playground.html) calls the same code compiled
   to JavaScript, so a run in the browser prints what [pe_sim run] prints
   for the same program and options. playground/exact.js checks that, line
   for line. *)

open! Core

let parse_int s = Int.of_string (String.strip s)

let keys =
  "start, out_base, out_count, set_base, set_count, in_base, threshold, timeout_vector, \
   timeout, sideset_base, sideset_count, clkdiv, out_msb_first, in_msb_first, autopull, \
   autopush, crc_poly, crc_init, crc_invert, crc_in"
;;

let config_of_string s =
  List.fold
    (String.split s ~on:',' |> List.filter ~f:(fun x -> not (String.is_empty (String.strip x))))
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
         | "autopull" -> { c with autopull = n <> 0 }
         | "autopush" -> { c with autopush = n <> 0 }
         | "crc_poly" -> { c with crc_poly = n }
         | "crc_init" -> { c with crc_init = n }
         | "crc_invert" -> { c with crc_invert = n <> 0 }
         | "crc_in" -> { c with crc_in = n <> 0 }
         | k -> failwithf "-config: unknown key %s (keys: %s)" k keys ()))
;;

(* The fields that differ from the default, as [config_of_string] reads
   them. The CRC fields are written in hex: they are 32 bits, and a
   decimal number that large does not fit a JavaScript integer. *)
let config_to_string (c : Isa.Thread_config.t) =
  let d = Isa.Thread_config.default in
  let int name v dv = if v <> dv then [ sprintf "%s=%d" name v ] else [] in
  let hex name v dv = if v <> dv then [ sprintf "%s=0x%x" name (v land Isa.crc_mask) ] else [] in
  let flag name v dv = if Bool.( <> ) v dv then [ sprintf "%s=%d" name (Bool.to_int v) ] else [] in
  String.concat
    ~sep:","
    (List.concat
       [ int "start" c.start d.start
       ; int "out_base" c.out_base d.out_base
       ; int "out_count" c.out_count d.out_count
       ; int "set_base" c.set_base d.set_base
       ; int "set_count" c.set_count d.set_count
       ; int "in_base" c.in_base d.in_base
       ; int "threshold" c.threshold d.threshold
       ; int "timeout_vector" c.timeout_vector d.timeout_vector
       ; int "timeout" c.timeout d.timeout
       ; int "sideset_base" c.sideset_base d.sideset_base
       ; int "sideset_count" c.sideset_count d.sideset_count
       ; int "clkdiv" c.clkdiv d.clkdiv
       ; flag "out_msb_first" c.out_msb_first d.out_msb_first
       ; flag "in_msb_first" c.in_msb_first d.in_msb_first
       ; flag "autopull" c.autopull d.autopull
       ; flag "autopush" c.autopush d.autopush
       ; hex "crc_poly" c.crc_poly d.crc_poly
       ; hex "crc_init" c.crc_init d.crc_init
       ; flag "crc_invert" c.crc_invert d.crc_invert
       ; flag "crc_in" c.crc_in d.crc_in
       ])
;;

let modes_of_flags flags =
  let modes = Array.create ~len:Isa.num_pins Isa.Pin_mode.Input in
  List.iter flags ~f:(fun f ->
    match String.lsplit2 f ~on:'=' with
    | Some (p, m) ->
      let p = parse_int p in
      if p < 0 || p >= Isa.num_pins then failwithf "-mode: pin %d is not 0 to 7" p ();
      modes.(p)
      <- (match String.lowercase (String.strip m) with
          | "pp" -> Push_pull
          | "od" -> Open_drain
          | "in" -> Input
          | m -> failwithf "-mode: %s is not pp, od or in" m ())
    | None -> failwithf "-mode: %s is not P=pp|od|in" f ());
  modes
;;

let lines_of text =
  String.split_lines text
  |> List.map ~f:String.strip
  |> List.filter ~f:(fun l -> not (String.is_empty l || String.is_prefix l ~prefix:"#"))
;;

(* A TX file: one word per line, decimal or 0x hex. *)
let words_of_string text = lines_of text |> List.map ~f:parse_int

(* A stimulus file: "CYCLE HEX" lines, in increasing cycle order. *)
let stimulus_of_string text =
  let changes =
    lines_of text
    |> List.map ~f:(fun l ->
      match
        String.split_on_chars l ~on:[ ' '; '\t' ] |> List.filter ~f:(Fn.non String.is_empty)
      with
      | [ c; v ] ->
        let v = if String.is_prefix (String.lowercase v) ~prefix:"0x" then v else "0x" ^ v in
        parse_int c, parse_int v
      | _ -> failwithf "-stimulus: expected \"CYCLE HEX\", got %S" l ())
  in
  ignore
    (List.fold changes ~init:(-1) ~f:(fun prev (c, _) ->
       if c <= prev then failwithf "-stimulus: cycle %d is not after %d" c prev ();
       c)
     : int);
  changes
;;

type thread =
  { program : Isa.Instruction.t array
  ; config : Isa.Thread_config.t
  ; tx : int list
  }

(* Runs one or two threads, each from its own program memory, for [cycles]
   cycles. Each thread's TX words are pushed whenever its FIFO has room.
   [emit] is given, in order:
   - "pins CYCLE XX" when the output register changes (the first is the
     starting state), or with [lines] "lines CYCLE XX": the level on each
     wire, as a logic analyser sees it (inputs and open-drain pins
     included);
   - "rx CYCLE WORD" for a word thread 0 pushed, "rx1 CYCLE WORD" for
     thread 1. *)
let run ?(lines = false) ?(sync_bypass = 0) ~threads ~pin_modes ~cycles ~inputs ~stimulus ~emit () =
  let m =
    Isa.create_separate
      ~programs:(Array.of_list_map threads ~f:(fun t -> t.program))
      ~pin_modes
      ~threads:(List.map threads ~f:(fun t -> t.config))
  in
  Isa.set_sync_bypass m sync_bypass;
  let pending = Array.of_list_map threads ~f:(fun t -> Queue.of_list t.tx) in
  let inputs = ref inputs in
  let changes = Queue.of_list stimulus in
  let last = ref (-1) in
  let label = if lines then "lines" else "pins" in
  for c = 0 to cycles - 1 do
    Array.iteri pending ~f:(fun thread q ->
      match Queue.peek q with
      | Some v -> if Isa.push_tx m ~thread v then ignore (Queue.dequeue q : int option)
      | None -> ());
    (match Queue.peek changes with
     | Some (at, v) when at <= c ->
       inputs := v;
       ignore (Queue.dequeue changes : (int * int) option)
     | _ -> ());
    let pins = (if lines then Isa.lines m ~inputs:!inputs else Isa.pin_out m) land 0xFF in
    if pins <> !last
    then (
      emit (sprintf "%s %d %02x" label c pins);
      last := pins);
    Isa.step m ~inputs:!inputs;
    Array.iteri pending ~f:(fun thread _ ->
      Option.iter (Isa.pop_rx m ~thread) ~f:(fun w ->
        emit (sprintf "%s %d %d" (if thread = 0 then "rx" else "rx1") c w)))
  done
;;

(* For each line of [source] (numbered from 1), whether it holds an
   instruction: something other than a label, a directive or a comment. *)
let instruction_count source =
  String.split_lines source
  |> List.count ~f:(fun line ->
    let code = String.strip (List.hd_exn (String.split line ~on:';')) in
    let code =
      match String.lsplit2 code ~on:':' with
      | Some (label, rest)
        when String.for_all (String.strip label) ~f:(fun c -> Char.is_alphanum c || Char.equal c '_') ->
        String.strip rest
      | _ -> code
    in
    (not (String.is_empty code)) && not (Char.equal code.[0] '.'))
;;
