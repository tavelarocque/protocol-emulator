(* Writes docs/demo.html: the page in demo/page.html with recorded runs of
   the reference model (model/isa.ml) put where its DATA marker is.

   Every waveform the page shows is what the model's pins did, cycle by
   cycle, running the firmware in model/firmware.ml: nothing is drawn by
   hand. Each scene is also checked here before it is written (the UART
   line is decoded by the project's own receiver model, the stepper's
   steps are counted, the servo's pulses measured), so a change to the
   firmware either shows in the page or stops the build.

   The page is one file: the 3D library (demo/vendor/three.module.min.js,
   MIT) and the bench drawn with it (demo/bench.js) are put in as well.

   The type is IBM Plex (demo/vendor/plex.css, SIL OFL 1.1), carried inside the
   page as well.

   Usage: demo_traces.exe page.html three.module.min.js bench.js plex.css > demo.html *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Uart_model = Pe_model.Uart_model
module I2c = Pe_model.I2c_model
module Ethernet = Pe_test.Test_ethernet
module Can_test = Pe_test.Test_can
module Can = Firmware.Can

let clock_hz = 10_000_000

(* A little JSON, so the page needs no library and this needs no package. *)
module Json = struct
  type t =
    | S of string
    | I of int
    | L of t list
    | O of (string * t) list

  let escape s =
    String.concat_map s ~f:(function
      | '"' -> "\\\""
      | '\\' -> "\\\\"
      | '\n' -> "\\n"
      | '\t' -> "\\t"
      | '<' -> "\\u003c" (* so no text can close the page's script element *)
      | c when Char.to_int c < 0x20 -> sprintf "\\u%04x" (Char.to_int c)
      | c -> String.make 1 c)
  ;;

  let rec to_string = function
    | S s -> "\"" ^ escape s ^ "\""
    | I i -> Int.to_string i
    | L l -> "[" ^ String.concat ~sep:"," (List.map l ~f:to_string) ^ "]"
    | O o ->
      "{"
      ^ String.concat ~sep:"," (List.map o ~f:(fun (k, v) -> to_string (S k) ^ ":" ^ to_string v))
      ^ "}"
  ;;
end

open Json

type thread =
  { firmware : string (* its name in [Firmware.all] and in examples/ *)
  ; source : string
  ; origin : int (* where in program memory it is loaded *)
  ; config : Isa.Thread_config.t
  ; words : (int * string) list (* TX words in order, and what each means *)
  ; answer : int -> string (* what a word the thread sends back means *)
  }

type trace =
  { changes : (int * int) list (* cycle, and the level of the 8 pins from it on *)
  ; tx : (int * int * int * string) list (* cycle taken, thread, word, meaning *)
  ; rx : (int * int * int) list (* cycle, thread, word *)
  ; pcs : (int * int) list list (* for each thread: cycle, and its program counter from it on *)
  ; cycles : int
  }

(* Runs the threads for [cycles]. A TX word is pushed as soon as its FIFO
   has room, as the host driver does. [host] is called before every cycle
   with the model and the queues of words still to send, for what a host
   does besides: stopping a thread, changing a pin's mode. *)
let run ?(inputs = 0xFF) ?device ?(host = fun _ _ _ -> ()) ~threads ~pin_modes ~cycles () =
  let m =
    Isa.create_separate
      ~programs:(Array.of_list_map threads ~f:(fun t -> Asm.assemble t.source))
      ~pin_modes
      ~threads:(List.map threads ~f:(fun t -> t.config))
  in
  let pending = Array.of_list_map threads ~f:(fun t -> Queue.of_list t.words) in
  let changes = Queue.create () in
  let tx = Queue.create () in
  let rx = Queue.create () in
  let last = ref (-1) in
  let pcs = Array.map pending ~f:(fun _ -> Queue.create ()) in
  let last_pc = Array.map pending ~f:(fun _ -> -1) in
  for c = 0 to cycles - 1 do
    host m c pending;
    Array.iteri pcs ~f:(fun i q ->
      let pc = (Isa.thread m i).pc in
      if pc <> last_pc.(i)
      then (
        Queue.enqueue q (c, pc);
        last_pc.(i) <- pc));
    (* A device on the pins says what it drives this cycle, and afterwards
       is shown the lines as they then stand. *)
    let inputs =
      match device with
      | Some (drives, _) -> drives ()
      | None -> inputs
    in
    Array.iteri pending ~f:(fun i q ->
      match Queue.peek q with
      | Some (w, meaning) ->
        if Isa.push_tx m ~thread:i w
        then (
          ignore (Queue.dequeue q : (int * string) option);
          Queue.enqueue tx (c, i, w, meaning))
      | None -> ());
    let levels = Isa.lines m ~inputs land 0xFF in
    if levels <> !last
    then (
      Queue.enqueue changes (c, levels);
      last := levels);
    Isa.step m ~inputs;
    Option.iter device ~f:(fun (_, sees) -> sees c (Isa.lines m ~inputs land 0xFF));
    Array.iteri pending ~f:(fun i _ ->
      Option.iter (Isa.pop_rx m ~thread:i) ~f:(fun w -> Queue.enqueue rx (c, i, w)))
  done;
  { changes = Queue.to_list changes
  ; tx = Queue.to_list tx
  ; rx = Queue.to_list rx
  ; pcs = Array.to_list (Array.map pcs ~f:Queue.to_list)
  ; cycles
  }
;;

(* One pin's level on every cycle. *)
let samples trace ~pin =
  let a = Array.create ~len:trace.cycles false in
  let rec fill = function
    | [] -> ()
    | (c, levels) :: rest ->
      let stop =
        match rest with
        | (next, _) :: _ -> next
        | [] -> trace.cycles
      in
      for i = c to stop - 1 do
        a.(i) <- (levels lsr pin) land 1 = 1
      done;
      fill rest
  in
  fill trace.changes;
  a
;;

(* Where a pin rises and falls: (cycle it went high, cycle it went low). *)
let pulses trace ~pin =
  let a = samples trace ~pin in
  let out = Queue.create () in
  let rise = ref None in
  Array.iteri a ~f:(fun c high ->
    let before = c > 0 && a.(c - 1) in
    if high && not before
    then rise := Some c
    else if (not high) && before
    then
      Option.iter !rise ~f:(fun r ->
        Queue.enqueue out (r, c);
        rise := None));
  Queue.to_list out
;;

let fail scene what = failwithf "demo scene %s: %s" scene what ()

(* The host driver starts a thread first and makes its pins outputs after:
   a pin is high from reset, and the program's first instruction is what
   takes it low. Until then the line is where the device's own pull-down
   holds it, which the scene gives as [inputs]. *)
let outputs_from ~cycle pins (m : Isa.t) c _ =
  if c = cycle then List.iter pins ~f:(fun p -> m.pin_modes.(p) <- Isa.Pin_mode.Push_pull)
;;

(* The fields of a thread's configuration that are not the default, for the
   page to show beside the program. *)
let config_json (c : Isa.Thread_config.t) =
  let d = Isa.Thread_config.default in
  let int name v dv = if v <> dv then [ name, I v ] else [] in
  let flag name v dv = if Bool.( <> ) v dv then [ name, S (Bool.to_string v) ] else [] in
  O
    (List.concat
       [ int "out_base" c.out_base d.out_base
       ; int "out_count" c.out_count d.out_count
       ; int "set_base" c.set_base d.set_base
       ; int "set_count" c.set_count d.set_count
       ; int "in_base" c.in_base d.in_base
       ; int "threshold" c.threshold d.threshold
       ; int "sideset_base" c.sideset_base d.sideset_base
       ; int "sideset_count" c.sideset_count d.sideset_count
       ; int "clkdiv" c.clkdiv d.clkdiv
       ; flag "out_msb_first" c.out_msb_first d.out_msb_first
       ; flag "autopull" c.autopull d.autopull
       ])
;;

(* The program as the page lists it: no blank lines at either end. *)
let listing source =
  String.split_lines source
  |> List.map ~f:String.rstrip
  |> List.drop_while ~f:String.is_empty
  |> List.rev
  |> List.drop_while ~f:String.is_empty
  |> List.rev
  |> String.concat ~sep:"\n"
;;

(* For each instruction of a program, the line of its listing it is on: a
   line holds one if something other than a label, a directive or a comment
   is on it. Checked against the assembler's count. *)
let instruction_lines ~origin source =
  let lines = String.split_lines (listing source) in
  let holds line =
    let code = String.strip (List.hd_exn (String.split line ~on:';')) in
    let code =
      match String.lsplit2 code ~on:':' with
      | Some (label, rest) when String.for_all label ~f:(fun c -> Char.is_alphanum c || Char.equal c '_') ->
        String.strip rest
      | _ -> code
    in
    (not (String.is_empty code)) && not (Char.equal code.[0] '.')
  in
  let found = List.filter_mapi lines ~f:(fun i line -> if holds line then Some i else None) in
  if List.length found <> Array.length (Asm.assemble ~origin source)
  then failwith "demo: a listing's lines do not match its instructions";
  Array.of_list found
;;

type mark =
  { pin : int
  ; from : int
  ; until : int
  ; text : string
  }

let scene ?(hz = clock_hz) ~id ~title ~capture ~bench ~what ~claim ~pins ~threads ~trace ~marks ~device () =
  O
    [ "id", S id
    ; "clock_hz", I hz
    ; "capture", S capture
    ; "bench", S bench
    ; "title", S title
    ; "what", S what
    ; "checked", S claim
    ; "cycles", I trace.cycles
    ; ( "pins"
      , L (List.map pins ~f:(fun (pin, name, mode) -> O [ "pin", I pin; "name", S name; "mode", S mode ])) )
    ; ( "threads"
      , L
          (List.mapi threads ~f:(fun i t ->
             O
               [ "firmware", S t.firmware
               ; "source", S (listing t.source)
               ; "words", I (Array.length (Asm.assemble ~origin:t.origin t.source))
               ; "config", config_json t.config
               ; ( "pc"
                 , (* where the thread is in its listing, cycle by cycle *)
                   match List.nth trace.pcs i with
                   | None -> L []
                   | Some pcs ->
                     let lines = instruction_lines ~origin:t.origin t.source in
                     L
                       (List.filter_map pcs ~f:(fun (c, pc) ->
                          let k = pc - t.origin in
                          if k >= 0 && k < Array.length lines then Some (L [ I c; I lines.(k) ]) else None)) )
               ; ( "tx"
                 , L
                     (List.filter_map trace.tx ~f:(fun (c, th, w, meaning) ->
                        if th = i then Some (O [ "c", I c; "w", I w; "m", S meaning ]) else None)) )
               ; ( "rx"
                 , L
                     (List.filter_map trace.rx ~f:(fun (c, th, w) ->
                        if th = i then Some (O [ "c", I c; "w", I w; "m", S (t.answer w) ]) else None)) )
               ])) )
    ; "changes", L (List.map trace.changes ~f:(fun (c, v) -> L [ I c; I v ]))
    ; ( "marks"
      , L
          (List.map marks ~f:(fun m ->
             O [ "pin", I m.pin; "from", I m.from; "until", I m.until; "text", S m.text ])) )
    ; "device", O device
    ]
;;

let modes list =
  Array.init Isa.num_pins ~f:(fun i ->
    List.Assoc.find list i ~equal:Int.equal |> Option.value ~default:Isa.Pin_mode.Input)
;;

(* ------------------------------------------------------------------ UART *)

let uart_divisor = 87 (* 10 MHz / 87 = 114,943 baud, 0.2% from 115,200 *)

let uart_line =
  let baud = (clock_hz + (uart_divisor / 2)) / uart_divisor in
  sprintf "%d,%03d baud, 8N1" (baud / 1000) (baud % 1000)
;;

let uart_thread text =
  { firmware = "uart_tx"
  ; source = Firmware.uart_tx
  ; origin = 0
  ; config = Isa.Thread_config.default
  ; answer = (fun _ -> "")
  ; words =
      (uart_divisor - 4, sprintf "bit time: %d clocks, less 4" uart_divisor)
      :: List.map (String.to_list text) ~f:(fun ch ->
        Char.to_int ch, sprintf "'%s'" (Char.escaped ch))
  }
;;

(* The frames on a UART line, decoded by the project's receiver model, and
   where each one lies. *)
let uart_marks ~id trace ~pin ~text =
  let a = samples trace ~pin in
  (match Uart_model.decode ~divisor:uart_divisor (Array.to_list a) with
   | Ok bytes ->
     if not (List.equal Int.equal bytes (List.map (String.to_list text) ~f:Char.to_int))
     then fail id "the receiver model read different bytes"
   | Error _ -> fail id "the receiver model could not read the line");
  let frame = 10 * uart_divisor in
  let rec starts c acc =
    if c >= Array.length a
    then List.rev acc
    else if not a.(c)
    then starts (c + frame) (c :: acc)
    else starts (c + 1) acc
  in
  List.map2_exn (starts 0 []) (String.to_list text) ~f:(fun from ch ->
    { pin; from; until = from + frame; text = sprintf "%s 0x%02X" (Char.escaped ch) (Char.to_int ch) })
;;

let uart_scene () =
  let id = "uart" in
  let text = "Hi!" in
  let threads = [ uart_thread text ] in
  let trace =
    run ~threads ~pin_modes:(modes [ 0, Push_pull ]) ~cycles:(((String.length text * 10) + 6) * uart_divisor) ()
  in
  scene
    ~id
    ~title:"UART"
    ~capture:"TX while the chip sends the three bytes of \"Hi!\""
    ~bench:"a serial terminal"
    ~what:
      "Fifteen instructions send serial text. The host gives the bit time once, then a byte at a \
       time; the thread makes the start bit, eight data bits and the stop bit by counting clocks."
    ~claim:"The project's UART receiver model reads these bytes back from this line."
    ~pins:[ 0, "TX", "push-pull" ]
    ~threads
    ~trace
    ~marks:(uart_marks ~id trace ~pin:0 ~text)
    ~device:[ "kind", S "terminal"; "pin", I 0; "label", S uart_line; "line", S uart_line ]
    ()
;;

(* --------------------------------------------------------------- stepper *)

let stepper_tick = 10 (* clocks: a tick of 1 us *)

(* forwards, steps, ticks to a step *)
let stepper_moves = [ true, 4, 400; true, 6, 200; true, 10, 100; false, 8, 150 ]

let stepper_thread ~step_pin =
  { firmware = "stepper"
  ; source = Firmware.stepper
  ; origin = 0
  ; config =
      { (Firmware.stepper_config ~clkdiv:stepper_tick) with sideset_base = step_pin; out_base = step_pin + 1 }
  ; answer = (fun _ -> "the move is made")
  ; words =
      List.concat_map stepper_moves ~f:(fun (forwards, steps, period) ->
        match Firmware.stepper_words ~forwards ~steps ~period with
        | [ a; b ] ->
          [ a, sprintf "%d steps %s, less one" steps (if forwards then "forwards" else "back")
          ; b, sprintf "%d us a step, less four" period
          ]
        | _ -> assert false)
  }
;;

let stepper_cycles = (List.sum (module Int) stepper_moves ~f:(fun (_, s, p) -> s * p) + 200) * stepper_tick

(* Every step counted, and in the direction asked for. *)
let stepper_marks ~id trace ~step_pin =
  let steps = pulses trace ~pin:step_pin in
  let dir = samples trace ~pin:(step_pin + 1) in
  let total = List.sum (module Int) stepper_moves ~f:(fun (_, s, _) -> s) in
  if List.length steps <> total then fail id (sprintf "%d steps, not %d" (List.length steps) total);
  let rec go steps moves acc =
    match moves with
    | [] -> List.rev acc
    | (forwards, n, period) :: rest ->
      let mine, others = List.split_n steps n in
      List.iter mine ~f:(fun (rise, _) ->
        if Bool.( <> ) dir.(rise) forwards then fail id "a step in the wrong direction");
      let from = fst (List.hd_exn mine) in
      let until = fst (List.last_exn mine) + (period * stepper_tick) in
      let text = sprintf "%d %s at %d us" n (if forwards then "forwards" else "back") period in
      go others rest ({ pin = step_pin; from; until; text } :: acc)
  in
  go steps stepper_moves []
;;

let stepper_scene () =
  let id = "stepper" in
  let threads = [ stepper_thread ~step_pin:0 ] in
  let trace =
    run
      ~inputs:0xFC
      ~host:(outputs_from ~cycle:(3 * stepper_tick) [ 0; 1 ])
      ~threads
      ~pin_modes:(modes [])
      ~cycles:stepper_cycles
      ()
  in
  if List.length trace.rx <> List.length stepper_moves then fail id "a move was not reported";
  scene
    ~id
    ~title:"Step and direction"
    ~capture:"STEP and DIR during four moves: a ramp forwards, then back"
    ~bench:"a stepper motor and its driver"
    ~what:
      "Ten instructions drive a stepper motor driver such as a DRV8825. Each move is two words: \
       how many steps and which way, then the time for one step. The thread answers when the move \
       is made, so a ramp is a list of moves."
    ~claim:"Every step is counted here, and its direction compared with the move that asked for it."
    ~pins:[ 0, "STEP", "push-pull"; 1, "DIR", "push-pull" ]
    ~threads
    ~trace
    ~marks:(stepper_marks ~id trace ~step_pin:0)
    ~device:[ "kind", S "stepper"; "step", I 0; "dir", I 1; "label", S "1.8 degrees a step" ]
    ()
;;

(* ----------------------------------------------------------------- servo *)

let servo_period = 20_000 (* us *)
let servo_widths = [ 1000; 1500; 2000 ] (* us *)
let servo_repeats = 3

let servo_scene () =
  let id = "servo" in
  let words us =
    match Firmware.pwm_words ~high:us ~period:servo_period with
    | [ h; l ] -> [ h, sprintf "high %d us, less two" us; l, sprintf "low for the rest of 20 ms, less three" ]
    | _ -> assert false
  in
  let threads =
    [ { firmware = "pwm"
      ; source = Firmware.pwm
      ; origin = 0
      ; config = { Firmware.pwm_config with clkdiv = 10 }
      ; answer = (fun _ -> "")
      ; words = words (List.hd_exn servo_widths)
      }
    ]
  in
  let span = servo_repeats * servo_period * 10 in
  (* To change the pulse the host stops the thread while the pin is low,
     and starts it with two new words. *)
  let host m c pending =
    outputs_from ~cycle:30 [ 0 ] m c pending;
    List.iteri (List.tl_exn servo_widths) ~f:(fun k us ->
      let at = ((k + 1) * span) - 20_000 in
      if c = at then Isa.set_enabled m ~thread:0 false;
      if c = at + 2
      then (
        Isa.set_enabled m ~thread:0 true;
        List.iter (words us) ~f:(Queue.enqueue pending.(0))))
  in
  let trace =
    run ~inputs:0xFE ~host ~threads ~pin_modes:(modes []) ~cycles:(List.length servo_widths * span) ()
  in
  let high = pulses trace ~pin:0 in
  let expected = List.concat_map servo_widths ~f:(fun us -> List.init servo_repeats ~f:(fun _ -> us)) in
  let measured = List.map high ~f:(fun (rise, fall) -> (fall - rise) / 10) in
  if not (List.equal Int.equal measured expected)
  then fail id (sprintf "pulses of %s us" (String.concat ~sep:" " (List.map measured ~f:Int.to_string)));
  scene
    ~id
    ~title:"RC servo"
    ~capture:"PWM during nine pulses: three each of 1.0, 1.5 and 2.0 ms"
    ~bench:"an RC servo"
    ~what:
      "Nine instructions make a pulse train: high for one count, low for another, for as long as \
       the thread runs. A servo reads the width of the pulse as an angle: 1 ms one end, 2 ms the \
       other, every 20 ms."
    ~claim:"Every pulse is measured here: 1000, 1500 and 2000 us to the clock cycle."
    ~pins:[ 0, "PWM", "push-pull" ]
    ~threads
    ~trace
    ~marks:
      (List.map2_exn high expected ~f:(fun (rise, fall) us ->
         { pin = 0; from = rise; until = fall; text = sprintf "%d us" us }))
    ~device:[ "kind", S "servo"; "pin", I 0; "label", S "1 to 2 ms is 0 to 180 degrees" ]
    ()
;;

(* ----------------------------------------------------------------- Morse *)

let morse_text = "sos"
let morse_tick = 50_000 (* clocks: a cell is two ticks, 10 ms, so 120 words a minute *)

let morse_scene () =
  let id = "morse" in
  let cells = Firmware.morse_cells morse_text in
  let threads =
    [ { firmware = "bitstream"
      ; source = Firmware.bitstream
      ; origin = 0
      ; config = Firmware.bitstream_config ~clkdiv:morse_tick
      ; answer = (fun _ -> "")
      ; words =
          List.mapi (Firmware.bitstream_words cells) ~f:(fun i w ->
            w, sprintf "cells %d to %d, first cell in the top bit" (i * 16) ((i * 16) + 15))
      }
    ]
  in
  (* A pin is high from reset, so the driver leaves this one an input,
     held low by the lamp, until the program's first instruction has
     written a 0 to it. *)
  let host (m : Isa.t) _ _ =
    if (Isa.thread m 0).pc <> 0 then m.pin_modes.(0) <- Isa.Pin_mode.Push_pull
  in
  let cell = 2 * morse_tick in
  let cycles = (List.length cells + 20) * cell in
  let trace = run ~inputs:0xFE ~host ~threads ~pin_modes:(modes []) ~cycles () in
  let a = samples trace ~pin:0 in
  let first =
    match Array.findi a ~f:(fun _ high -> high) with
    | Some (c, _) -> c
    | None -> fail id "the lamp never lit"
  in
  List.iteri cells ~f:(fun i lit ->
    if Bool.( <> ) a.(first + (i * cell) + (cell / 2)) (lit = 1) then fail id (sprintf "cell %d is wrong" i));
  (* One mark to a letter. *)
  let marks =
    let at = ref 0 in
    List.map (String.to_list morse_text) ~f:(fun ch ->
      let code = List.Assoc.find_exn Firmware.morse_code ch ~equal:Char.equal in
      let length =
        String.sum (module Int) code ~f:(fun mark -> if Char.equal mark '-' then 3 else 1)
        + String.length code
        - 1
      in
      let from = first + (!at * cell) in
      at := !at + length + 3;
      { pin = 0; from; until = from + (length * cell); text = sprintf "%c  %s" (Char.uppercase ch) code })
  in
  scene
    ~id
    ~title:"Morse code"
    ~capture:"KEY while the chip sends SOS"
    ~bench:"a signal lamp"
    ~what:
      "Three instructions and no knowledge of Morse: the thread puts out whatever cells the host \
       sends, one bit to a cell. The same three send Qi wireless-charging packets and EM4100 \
       access-card frames, because the framing lives in the driver."
    ~claim:"Every cell is compared here with the Morse for the text."
    ~pins:[ 0, "KEY", "push-pull" ]
    ~threads
    ~trace
    ~marks
    ~device:[ "kind", S "lamp"; "pin", I 0; "label", S "10 ms a dot" ]
    ()
;;

(* ------------------------------------------------------------------- I2C *)

let i2c_address = 0x48
let i2c_reading = [ 0x19; 0x80 ] (* an LM75's two bytes for 25.5 degrees *)

let i2c_scene () =
  let id = "i2c" in
  let threads =
    [ { firmware = "i2c"
      ; source = Firmware.i2c
      ; origin = 0
      ; config = Firmware.i2c_config
      ; answer =
          (fun w ->
            if w = 0x200
            then "the bus is stuck"
            else
              sprintf
                "0x%02X on the bus, %s"
                (Firmware.reverse_byte (w land 0xFF))
                (if w land 0x100 = 0 then "acknowledged" else "not acknowledged"))
      ; words =
          [ ( Firmware.i2c_write_word ~stop:false (i2c_address lsl 1)
            , sprintf "START, then address 0x%02X to write" i2c_address )
          ; Firmware.i2c_write_word ~restart:true ~stop:false 0x00, "register 0, then a repeated START"
          ; ( Firmware.i2c_write_word ~stop:false ((i2c_address lsl 1) lor 1)
            , sprintf "address 0x%02X to read" i2c_address )
          ; Firmware.i2c_read_word ~last:false, "read a byte and acknowledge it"
          ; Firmware.i2c_read_word ~last:true, "read the last byte, do not acknowledge, STOP"
          ]
      }
    ]
  in
  (* The device is the project's I2C target model, and its bus checker
     watches every cycle: it names each START, byte and STOP, and reports
     anything I2C forbids. *)
  let target = I2c.Target.create ~to_send:i2c_reading ~address:i2c_address ~stretch:0 () in
  let checker = I2c.Checker.create () in
  let seen = Queue.create () in
  let drives () =
    let sda_low, scl_low = I2c.Target.drive target in
    0xFF land lnot (Bool.to_int sda_low lor (Bool.to_int scl_low lsl 1))
  in
  let sees c levels =
    let sda = levels land 1 = 1 and scl = levels land 2 = 2 in
    let before = List.length (I2c.Checker.events checker) in
    I2c.Checker.step checker ~sda ~scl;
    I2c.Target.step target ~sda ~scl;
    List.iter (List.drop (I2c.Checker.events checker) before) ~f:(fun e -> Queue.enqueue seen (c, e))
  in
  let trace =
    run
      ~device:(drives, sees)
      ~threads
      ~pin_modes:(modes [ 0, Open_drain; 1, Open_drain ])
      ~cycles:5_900
      ()
  in
  let expected : I2c.Event.t list =
    [ Start
    ; Byte { value = i2c_address lsl 1; ack = true }
    ; Byte { value = 0x00; ack = true }
    ; Start
    ; Byte { value = (i2c_address lsl 1) lor 1; ack = true }
    ; Byte { value = 0x19; ack = true }
    ; Byte { value = 0x80; ack = false }
    ; Stop
    ]
  in
  if not (List.is_empty (I2c.Checker.errors checker))
  then fail id (String.concat ~sep:"; " (I2c.Checker.errors checker));
  if not ([%equal: I2c.Event.t list] (I2c.Checker.events checker) expected)
  then fail id (Sexp.to_string [%sexp (I2c.Checker.events checker : I2c.Event.t list)]);
  if not (List.equal Int.equal (I2c.Target.received target) [ 0x00 ]) then fail id "the device was not written register 0";
  let events = Queue.to_list seen in
  let marks =
    List.mapi events ~f:(fun i (c, (e : I2c.Event.t)) ->
      let from = if i = 0 then c - 30 else fst (List.nth_exn events (i - 1)) in
      match e with
      | Start -> { pin = 0; from = Int.max 0 (c - 30); until = c + 30; text = "S" }
      | Stop -> { pin = 0; from = c - 30; until = c + 30; text = "P" }
      | Byte { value; ack } -> { pin = 0; from = from + 30; until = c; text = sprintf "0x%02X %s" value (if ack then "ACK" else "NACK") })
  in
  let said =
    let at n = fst (List.nth_exn events n) in
    [ at 1, sprintf "0x%02X: here" i2c_address; at 2, "register 0: temperature"; at 5, "sends 0x19"; at 6, "sends 0x80"; at 7, "0x1980 is 25.5 \xC2\xB0C" ]
  in
  scene
    ~id
    ~title:"I2C"
    ~capture:"SDA and SCL during one temperature read"
    ~bench:"a temperature sensor"
    ~what:
      "Thirty instructions are an I2C controller: START, bytes either way, the acknowledge bit, \
       a repeated START and STOP, on two open-drain wires that a device can also pull low. Here it \
       sets a temperature sensor's register and reads two bytes back. The clock divider makes it \
       about 100 kHz."
    ~claim:
      "The device is the project's I2C target model, and its bus checker names every START, byte \
       and STOP on these wires and finds nothing I2C forbids."
    ~pins:[ 0, "SDA", "open-drain"; 1, "SCL", "open-drain" ]
    ~threads
    ~trace
    ~marks
    ~device:
      [ "kind", S "sensor"
      ; "sda", I 0
      ; "scl", I 1
      ; "label", S (sprintf "a temperature sensor at address 0x%02X" i2c_address)
      ; "says", L (List.map said ~f:(fun (c, text) -> O [ "c", I c; "text", S text ]))
      ]
    ()
;;

(* ------------------------------------------------------------------- CAN *)

let can_chip_frame = 0x123, [ 0xCA; 0xFE ]
let can_node_frame = 0x321, [ 0x42 ]
let can_node_bit = 81 (* the other node's clock is 1.25% slow *)

let can_scene () =
  let id = "can" in
  let clkdiv = Can_test.clkdiv in
  let bit = 20 * clkdiv in
  (* The run is the test suite's own (sim/test_can.ml): the chip with its
     receiver on thread 0 and its transmitter on thread 1, and a CAN node
     written from ISO 11898-1 on the bus with it. [check] is the test's
     verdict on the run. *)
  let seen = Queue.create () in
  let watch ~cycle ~chip_tx ~bus =
    let levels = 0xFC lor Bool.to_int bus lor (Bool.to_int chip_tx lsl 1) in
    match Queue.last seen with
    | Some (_, last) when last = levels -> ()
    | _ -> Queue.enqueue seen (cycle, levels)
  in
  let cycles = ref 0 in
  let watch ~cycle ~chip_tx ~bus =
    cycles := cycle + 1;
    watch ~cycle ~chip_tx ~bus
  in
  let _, ok =
    Can_test.check
      ~watch
      ~bit:can_node_bit
      ~contend:false
      ~chip_frames:[ can_chip_frame ]
      ~node_frames:[ can_node_frame ]
      ()
  in
  if not ok then fail id "the test's check of the run did not pass";
  let trace = { changes = Queue.to_list seen; tx = []; rx = []; pcs = []; cycles = !cycles } in
  let bus = samples trace ~pin:0 and txd = samples trace ~pin:1 in
  (* A frame starts where the bus falls after eleven bits of rest. *)
  let starts =
    let rec go c rest acc =
      if c >= trace.cycles
      then List.rev acc
      else if bus.(c)
      then go (c + 1) (rest + 1) acc
      else go (c + 1) 0 (if rest >= 11 * bit || (c = 0 || List.is_empty acc && rest = c) then c :: acc else acc)
    in
    go 0 0 []
  in
  let hex data = String.concat ~sep:" " (List.map data ~f:(sprintf "%02X")) in
  let frames =
    List.map starts ~f:(fun start ->
      let ours = not txd.(start) in
      let fid, data = if ours then can_chip_frame else can_node_frame in
      let bit = if ours then bit else can_node_bit in
      let length = List.length (Can.frame_bits ~id:fid ~data ()) in
      (* [frame_bits] ends with the CRC's delimiter, the acknowledge slot and
         its delimiter; seven bits of end of frame follow *)
      let ack = start + ((length - 2) * bit) in
      let middle = ack + (bit / 2) in
      if ours
      then (if bus.(middle) || not txd.(middle) then fail id "the node did not acknowledge where expected")
      else if txd.(middle)
      then fail id "the chip did not acknowledge where expected";
      ours, fid, data, start, ack, ack + bit, start + ((length + 7) * bit))
  in
  if List.length frames <> 2 then fail id (sprintf "%d frames on the bus, not 2" (List.length frames));
  let marks =
    List.concat_map frames ~f:(fun (ours, fid, data, start, ack, ack_end, _) ->
      let text = sprintf "%s sends 0x%03X: %s" (if ours then "the chip" else "the node") fid (hex data) in
      [ { pin = (if ours then 1 else 0); from = start; until = ack - bit; text }
      ; { pin = (if ours then 0 else 1); from = ack; until = ack_end; text = (if ours then "node ACK" else "chip ACK") }
      ])
  in
  let said =
    List.concat_map frames ~f:(fun (ours, fid, data, start, _, ack_end, _) ->
      if ours
      then
        [ start, sprintf "hears a frame from 0x%03X" fid
        ; ack_end, sprintf "got 0x%03X: %s, CRC good, acknowledged" fid (hex data)
        ]
      else
        [ start, sprintf "sends 0x%03X: %s" fid (hex data); ack_end, "the chip acknowledged it, and has its data" ])
    |> List.sort ~compare:(fun (a, _) (b, _) -> Int.compare a b)
  in
  let cid, cdata = can_chip_frame in
  let threads =
    [ { firmware = "can_rx"
      ; source = Firmware.can_rx
      ; origin = Can.rx_origin
      ; config = Can.rx_config ~clkdiv
      ; answer = (fun _ -> "")
      ; words = []
      }
    ; { firmware = "can_tx"
      ; source = Firmware.can_tx
      ; origin = Can.tx_origin
      ; config = Can.tx_config ~clkdiv
      ; answer = (fun _ -> "")
      ; words = []
      }
    ]
  in
  let trace =
    { trace with
      tx =
        List.mapi (Can.tx_words ~id:cid ~data:cdata) ~f:(fun i w ->
          0, 1, w, sprintf "frame 0x%03X, word %d: the identifier and data, taken as the FIFO has room" cid i)
    }
  in
  scene
    ~id
    ~title:"CAN"
    ~capture:"The bus (RXD) and the chip's TXD while each node sends one frame"
    ~bench:"a CAN transceiver and a second node"
    ~what:
      "A CAN node on both threads at 125 kbit/s: one program receives, the other sends. Another \
       node, with a clock 1.25% slow, sends a frame first: the chip acknowledges it and hands over \
       its data. Then the chip sends a frame of its own, made from an identifier and two bytes, \
       adding the stuff bits and the CRC itself, and the other node acknowledges it."
    ~claim:
      "This is the test suite's own run and verdict: a CAN node written from ISO 11898-1 received the \
       chip's frame intact and acknowledged it, the chip acknowledged the node's, and every bit the \
       chip drove was exactly 80 clocks."
    ~pins:[ 0, "RXD", "input: the bus"; 1, "TXD", "push-pull" ]
    ~threads
    ~trace
    ~marks
    ~device:
      [ "kind", S "canbus"
      ; "pin", I 0
      ; "rxd", I 0
      ; "txd", I 1
      ; "label", S "125 kbit/s, two nodes"
      ; "says", L (List.map said ~f:(fun (c, text) -> O [ "c", I c; "text", S text ]))
      ]
    ()
;;

(* -------------------------------------------------------------- Ethernet *)

let eth_hz = 40_000_000 (* four clocks to a 100 ns bit *)

let eth_frame =
  let text = "Hello from a two-thread CPU. This frame is firmware." in
  let payload = List.map (String.to_list text) ~f:Char.to_int in
  List.concat
    [ List.init 6 ~f:(fun _ -> 0xFF) (* to everyone *)
    ; [ 0x02; 0x00; 0x00; 0x00; 0x00; 0x01 ] (* from a locally administered address *)
    ; [ 0x88; 0xB5 ] (* EtherType: IEEE 802 local experimental *)
    ; payload
    ]
;;

let eth_scene () =
  let id = "ethernet" in
  if List.length eth_frame < 60 then fail id "the frame is shorter than Ethernet allows";
  (* The run and the receiver are the test suite's own (sim/test_ethernet.ml):
     the host fills the packet buffer and starts the thread, and a receiver
     written from IEEE 802.3 reads the pair back, clock by clock. *)
  let wire = Ethernet.send eth_frame in
  (match Ethernet.receive wire ~from:0 with
   | Ok frame -> if not (List.equal Int.equal frame eth_frame) then fail id "the receiver read a different frame"
   | Error why -> fail id why);
  let levels v = v land 3 lor 0xFC in
  let changes =
    Array.foldi wire ~init:[] ~f:(fun c acc v ->
      match acc with
      | (_, last) :: _ when last = levels v -> acc
      | _ -> (c, levels v) :: acc)
    |> List.rev
  in
  let start =
    match Array.findi wire ~f:(fun _ v -> v land 3 <> 0) with
    | Some (c, _) -> c
    | None -> fail id "nothing was sent"
  in
  let words = Firmware.eth_tx_words eth_frame in
  let odd = List.length eth_frame % 2 = 1 in
  let threads =
    [ { firmware = "eth_tx"
      ; source = Firmware.eth_tx
      ; origin = Firmware.eth_tx_origin
      ; config = Firmware.eth_tx_config ~odd
      ; answer = (fun _ -> "")
      ; words = []
      }
    ]
  in
  let trace =
    { changes
    ; tx =
        List.mapi words ~f:(fun i w ->
          0, 0, w, sprintf "packet buffer word %d: bytes %d and %d of the frame" i (2 * i) ((2 * i) + 1))
    ; rx = []
    ; pcs = []
    ; cycles = Array.length wire
    }
  in
  let byte = 32 (* clocks *) in
  let marks =
    let field (at, acc) (bytes, text) =
      let from = start + (at * byte) in
      at + bytes, { pin = 0; from; until = from + (bytes * byte); text } :: acc
    in
    let n = List.length eth_frame in
    List.fold
      [ 7, "preamble"
      ; 1, "SFD"
      ; 6, "to: everyone"
      ; 6, "from: 02:00:00:00:00:01"
      ; 2, "type 88B5"
      ; n - 14, sprintf "%d bytes of payload" (n - 14)
      ; 4, "CRC-32, made on the chip"
      ]
      ~init:(0, [])
      ~f:field
    |> snd
    |> List.rev
  in
  let said =
    List.map marks ~f:(fun m -> m.from, "receiving: " ^ m.text)
    @ [ (start + ((List.length eth_frame + 12) * byte), sprintf "frame of %d bytes, CRC good" (List.length eth_frame + 4)) ]
  in
  scene
    ~hz:eth_hz
    ~id
    ~title:"Ethernet"
    ~capture:"TD+ and TD- at the start of one 70-byte frame"
    ~bench:"an RJ45 jack and a network switch"
    ~what:
      "A whole Ethernet frame at 10 Mbit/s, where a bit lasts four clocks: too fast for a host to \
       feed a word at a time. So the host writes the frame into the chip's packet buffer and \
       starts the thread. The program sends the preamble, turns every bit into its Manchester \
       pair on the two wires, and ends with a CRC-32 that the chip worked out as the bytes went \
       by. Sending only: the receiver is a second program."
    ~claim:
      "The test suite's Ethernet receiver, written from IEEE 802.3 and not from the firmware, reads \
       this frame back from these two wires, checks the cell timing and the idle signal, and finds \
       the CRC correct."
    ~pins:[ 0, "TD+", "push-pull"; 1, "TD-", "push-pull" ]
    ~threads
    ~trace
    ~marks
    ~device:
      [ "kind", S "network"
      ; "plus", I 0
      ; "minus", I 1
      ; "label", S "10BASE-T, 40 MHz clock"
      ; "says", L (List.map said ~f:(fun (c, text) -> O [ "c", I c; "text", S text ]))
      ]
    ()
;;

(* ------------------------------------------------------- two at the same time *)

let both_scene () =
  let id = "both" in
  let text = "Hi!" in
  let threads = [ uart_thread text; stepper_thread ~step_pin:2 ] in
  let trace =
    run
      ~inputs:0xF3
      ~host:(outputs_from ~cycle:(3 * stepper_tick) [ 2; 3 ])
      ~threads
      ~pin_modes:(modes [ 0, Push_pull ])
      ~cycles:stepper_cycles
      ()
  in
  scene
    ~id
    ~title:"Two at once"
    ~capture:"TX, STEP and DIR while both threads run"
    ~bench:"a serial terminal and a stepper motor"
    ~what:
      "The chip has two threads, each with its own program memory, FIFOs and clock divider. Here \
       one sends serial text while the other runs a motor. Neither knows the other is there: the \
       programs are the same two as in the scenes before, on different pins."
    ~claim:"Both checks from the two scenes before are made again on this run."
    ~pins:[ 0, "TX", "push-pull"; 2, "STEP", "push-pull"; 3, "DIR", "push-pull" ]
    ~threads
    ~trace
    ~marks:(uart_marks ~id trace ~pin:0 ~text @ stepper_marks ~id trace ~step_pin:2)
    ~device:
      [ "kind", S "both"; "pin", I 0; "step", I 2; "dir", I 3; "label", S "thread 0 and thread 1"; "line", S uart_line ]
    ()
;;

let () =
  let template = In_channel.read_all (Sys.get_argv ()).(1) in
  let data =
    O
      [ "clock_hz", I clock_hz
      ; "scenes", L
          [ uart_scene ()
          ; i2c_scene ()
          ; can_scene ()
          ; eth_scene ()
          ; stepper_scene ()
          ; servo_scene ()
          ; morse_scene ()
          ; both_scene ()
          ]
      ]
  in
  (* Nothing put inside a script element may close it. *)
  let inside_script s = String.substr_replace_all s ~pattern:"</script" ~with_:"<\\/script" in
  let fill page (marker, text) =
    if List.length (String.substr_index_all page ~may_overlap:false ~pattern:marker) <> 1
    then failwithf "demo/page.html must have the marker %s exactly once" marker ();
    String.substr_replace_first page ~pattern:marker ~with_:text
  in
  let file i = inside_script (In_channel.read_all (Sys.get_argv ()).(i)) in
  (* The library is published as a module. A page that must also work from a
     file, in a preview and inside a sandboxed frame cannot rely on importing
     one, so it goes in as an ordinary script: its body in a function, and
     its export list, "local as Name, ...", returned as the object THREE. *)
  let as_script source =
    let at =
      match List.last (String.substr_index_all source ~may_overlap:false ~pattern:"export{") with
      | Some at -> at
      | None -> failwith "three.module.min.js has no export list"
    in
    let names = String.drop_prefix source (at + String.length "export{") in
    let names = String.prefix names (String.index_exn names '}') in
    let fields =
      String.split names ~on:','
      |> List.map ~f:(fun item ->
        match String.substr_index item ~pattern:" as " with
        | Some i -> String.drop_prefix item (i + 4) ^ ":" ^ String.prefix item i
        | None -> item)
    in
    sprintf
      "window.THREE=(function(){\"use strict\";%sreturn{%s};})();"
      (String.prefix source at)
      (String.concat ~sep:"," fields)
  in
  print_string
    (List.fold
       [ "/*DATA*/null", Json.to_string data; "/*THREE*/", as_script (file 2); "/*BENCH*/", file 3 ]
       ~init:template
       ~f:fill
     |> fun page -> fill page ("/*FONTS*/", In_channel.read_all (Sys.get_argv ()).(4)))
;;
