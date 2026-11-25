(* The SLE 4442 card reader ([Firmware.sle4442]) against a card written
   here from the SLE 4432/4442 data sheet: the reset and answer to reset,
   commands between START and STOP, the read commands' output and the
   clock that ends it, and the data sheet's timing limits. The cocotb test
   runs the same firmware on the RTL and the gate netlist with sigrok's
   SLE44xx decoder reading the three wires. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let clkdiv = 50 (* 10 MHz: a tick of 5 us *)
let us n = 10 * n (* cycles of a 10 MHz clock *)

(* The card. Its I/O is open-drain: [drive] false pulls the line low. The
   clock that ends its output (the 33rd of an answer to reset, the one
   after a read's last bit) lets I/O go as it rises, and START and STOP
   are ignored until that clock pulse is over. *)
module Card = struct
  type mode =
    | Idle
    | Command of int list (* bits taken since START, newest first *)
    | Out of int list * int
        (* bits still to show; clocks (rises) left, the last one ending the mode as it falls *)

  type t =
    { mem : int array
    ; protection : int (* 32 bits *)
    ; mutable mode : mode
    ; mutable drive : bool
    ; mutable due : (int * bool) option (* the card's next level on I/O, and when *)
    ; mutable rst : bool
    ; mutable clk : bool
    ; mutable io : bool
    ; mutable reader : bool
    ; mutable clock_in_reset : bool
    ; mutable rst_changed : int
    ; mutable clk_changed : int
    ; mutable io_changed : int (* the reader's I/O changes *)
    ; mutable last_rise : int
    ; mutable now : int
    ; mutable commands : string list
    ; mutable errors : string list
    }

  let create () =
    { mem = Array.init 256 ~f:(fun a -> if a < 4 then [| 0xA2; 0x13; 0x10; 0x91 |].(a) else ((a * 37) + 11) land 0xFF)
    ; protection = 0xFFFF_FF00
    ; mode = Idle
    ; drive = true
    ; due = None
    ; rst = false
    ; clk = false
    ; io = true
    ; reader = true
    ; clock_in_reset = false
    ; rst_changed = -10_000
    ; clk_changed = -10_000
    ; io_changed = -10_000
    ; last_rise = -10_000
    ; now = 0
    ; commands = []
    ; errors = []
    }
  ;;

  let note t s = t.commands <- s :: t.commands
  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors
  let bits_of bytes = List.concat_map bytes ~f:(fun b -> List.init 8 ~f:(fun k -> (b lsr k) land 1))

  (* The card changes I/O at most 2.5 us after the edge that asks it to
     (t7, t8, t13): here 2 us. *)
  let show t level = t.due <- Some (t.now + us 2, level = 1)

  let execute t = function
    | [ control; address; _ ] when control = 0x30 ->
      note t (sprintf "read main memory from %02x" address);
      let b = bits_of (Array.to_list (Array.sub t.mem ~pos:address ~len:(256 - address))) in
      t.mode <- Out (b, List.length b + 1)
    | [ 0x34; _; _ ] ->
      note t "read protection memory";
      let b = bits_of (List.init 4 ~f:(fun k -> (t.protection lsr (8 * k)) land 0xFF)) in
      t.mode <- Out (b, List.length b + 1)
    | [ control; address; data ] ->
      note t (sprintf "command %02x %02x %02x, not modelled" control address data);
      t.mode <- Idle
    | _ -> assert false
  ;;

  (* One cycle of the wires: [io] is the line, [reader] what the reader
     drives on it (true: released). The limits are the data sheet's AC
     characteristics. *)
  let step t ~rst ~clk ~io ~reader =
    t.now <- t.now + 1;
    (match t.due with
     | Some (at, level) when at <= t.now ->
       t.drive <- level;
       t.due <- None
     | _ -> ());
    (* RST *)
    if rst && not t.rst
    then (
      t.rst_changed <- t.now;
      t.clock_in_reset <- false;
      t.mode <- Idle;
      t.drive <- true;
      t.due <- None);
    if t.rst && not rst
    then (
      if t.now - t.clk_changed < us 4 then error t "RST fell within 4 us of CLK falling (t11)";
      t.rst_changed <- t.now;
      if t.clock_in_reset
      then (
        (* The answer to reset: the first four bytes, the first bit at
           once and the rest on 31 falling edges; the 33rd clock ends it. *)
        note t "answer to reset";
        let b = bits_of (Array.to_list (Array.sub t.mem ~pos:0 ~len:4)) in
        show t (List.hd_exn b);
        t.mode <- Out (List.tl_exn b, 33))
      else error t "a reset with no clock pulse in it");
    (* CLK *)
    if clk && not t.clk
    then (
      if t.now - t.clk_changed < us 9 then error t "CLK low less than 9 us (t16)";
      if t.now - t.last_rise < us 20 then error t "CLK faster than 50 kHz";
      if rst && t.now - t.rst_changed < us 4 then error t "CLK rose within 4 us of RST rising (t10)";
      if (not rst) && t.now - t.rst_changed < us 4 then error t "CLK rose within 4 us of RST falling (t14)";
      if t.now - t.io_changed < us 1 then error t "I/O changed less than 1 us before CLK rose (t4)";
      t.clk_changed <- t.now;
      t.last_rise <- t.now;
      if rst
      then t.clock_in_reset <- true
      else (
        match t.mode with
        | Command taken -> t.mode <- Command (Bool.to_int io :: taken)
        | Out (bits, clocks) ->
          if clocks = 1
          then (
            (* The clock after the last bit lets go of I/O; once it is
               over, the card is ready for a command. *)
            t.drive <- true;
            t.due <- None);
          t.mode <- Out (bits, clocks - 1)
        | Idle -> ()));
    if t.clk && not clk
    then (
      if t.now - t.clk_changed < us 9 then error t "CLK high less than 9 us (t15)";
      (match t.mode with
       | Command [] when t.now - t.io_changed < us 4 -> error t "CLK fell within 4 us of START (t3)"
       | _ -> ());
      t.clk_changed <- t.now;
      match t.mode with
      | Out (_, 0) -> t.mode <- Idle
      | Out (b :: rest, clocks) when not rst ->
        show t b;
        t.mode <- Out (rest, clocks)
      | Out ([], _) -> show t 1
      | _ -> ());
    (* I/O as the reader drives it, and START and STOP on the line *)
    if Bool.( <> ) reader t.reader
    then (
      if (not clk) && t.now - t.clk_changed < us 1 then error t "I/O changed within 1 us of CLK falling (t5)";
      t.io_changed <- t.now);
    if Bool.( <> ) io t.io && t.clk && clk && not rst
    then (
      match t.mode, io with
      | Out _, _ -> () (* START and STOP are ignored while the card sends *)
      | _, false -> t.mode <- Command []
      | Command taken, true ->
        (match List.rev taken with
         | bits when List.length bits = 25 ->
           let byte k =
             List.foldi (List.sub bits ~pos:(8 * k) ~len:8) ~init:0 ~f:(fun i acc b -> acc lor (b lsl i))
           in
           execute t [ byte 0; byte 1; byte 2 ]
         | bits ->
           error t (sprintf "STOP after %d clocks, not 25" (List.length bits));
           t.mode <- Idle)
      | Idle, true -> ());
    t.rst <- rst;
    t.clk <- clk;
    t.io <- io;
    t.reader <- reader
  ;;
end

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    if i < 2 then Isa.Pin_mode.Push_pull else if i = 2 then Isa.Pin_mode.Open_drain else Input)
;;

(* Run the operations, each (reset, command, bytes); returns the card and
   the RX words, which the host takes as soon as they come. *)
let run ?(source = Firmware.sle4442) ?(card = Card.create ()) ops =
  let m = Isa.create ~program:(Asm.assemble source) ~pin_modes:modes ~threads:[ Firmware.sle4442_config ~clkdiv ] in
  let pending =
    Queue.of_list
      (List.concat_map ops ~f:(fun (reset, command, bytes) -> Firmware.sle4442_words ~reset ?command ~bytes ()))
  in
  let bytes = List.sum (module Int) ops ~f:(fun (_, _, b) -> b) in
  let read = Queue.create () in
  let inputs = ref 0xFF in
  for _ = 1 to (List.length ops * us 2000) + (bytes * us 400) do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:!inputs;
    let l = Isa.lines m ~inputs:!inputs in
    Card.step
      card
      ~rst:(l land 1 = 1)
      ~clk:((l lsr 1) land 1 = 1)
      ~io:((l lsr 2) land 1 = 1)
      ~reader:((Isa.pin_out m lsr 2) land 1 = 1);
    inputs := 0xFB lor (Bool.to_int card.drive lsl 2);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue read)
  done;
  card, Queue.to_list read
;;

let ops =
  [ true, None, 4 (* reset, and the four bytes of the answer *)
  ; false, Some (0x30, 0xF8, 0x00), 8 (* Read Main Memory from F8: 8 bytes *)
  ; false, Some (0x34, 0x00, 0x00), 4 (* Read Protection Memory *)
  ; false, Some (0x30, 0xC0, 0x00), 64
  ]
;;

let expected (card : Card.t) =
  [ 0xA2; 0x13; 0x10; 0x91 ]
  @ Array.to_list (Array.sub card.mem ~pos:0xF8 ~len:8)
  @ [ 0x00; 0xFF; 0xFF; 0xFF ]
  @ Array.to_list (Array.sub card.mem ~pos:0xC0 ~len:64)
;;

let%expect_test "a reset and three reads: what the card saw, and what the host got" =
  let card, read = run ops in
  printf !"card: %{sexp:string list}, errors %{sexp:string list}\n" (List.rev card.commands) card.errors;
  printf !"first 12 RX words: %s\n" (String.concat ~sep:" " (List.map (List.take read 12) ~f:(sprintf "%02x")));
  printf "all %d as the card holds them: %b\n" (List.length read) ([%equal: int list] read (expected card));
  [%expect {|
    card: ("answer to reset" "read main memory from f8" "read protection memory"
     "read main memory from c0"), errors ()
    first 12 RX words: a2 13 10 91 e3 08 2d 52 77 9c c1 e6
    all 80 as the card holds them: true
    |}]
;;

let%expect_test "planted bugs" =
  let caught source =
    let card, read = run ~source ops in
    not (List.is_empty card.errors && [%equal: int list] read (expected card))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.sle4442 ~pattern ~with_ in
    assert (not (String.equal s Firmware.sle4442));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.sle4442 then "WRONG" else "right");
  List.iter
    [ ( "no clock pulse during the reset"
      , fw ~pattern:"nop                 side 1 [1]  ; a clock pulse" ~with_:"nop                 side 0 [1]  ; a clock pulse" )
    ; "START with CLK low", fw ~pattern:"set pins, 0         side 1 [1]  ; I/O falls" ~with_:"set pins, 0         side 0 [1]  ; I/O falls"
    ; "a command bit changed as CLK rises", fw ~pattern:"out pins, 1         side 0 [1]" ~with_:"out pins, 1         side 1 [1]"
    ; "no 25th clock before STOP", fw ~pattern:"nop                 side 1 [1]  ; the 25th" ~with_:"nop                 side 0 [1]  ; the 25th"
    ; "the data byte never sent", fw ~pattern:"jmp !x stop         side 1" ~with_:"jmp stop            side 1"
    ; ( "no clock after the card's last bit"
      , fw ~pattern:"nop                 side 1 [1]\n        jmp next" ~with_:"nop                 side 0 [1]\n        jmp next" )
    ; ( "I/O read as CLK falls, before the card's next bit"
      , fw
          ~pattern:"bit:    nop                 side 0 [2]  ; CLK low 15 us: the card's next bit\n        in pins, 1          side 1"
          ~with_:"bit:    in pins, 1          side 0 [2]\n        nop                 side 1" )
    ; "CLK low only 5 us", fw ~pattern:"bit:    nop                 side 0 [2]" ~with_:"bit:    nop                 side 0    "
    ]
    ~f:(fun (name, source) -> printf "%-50s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    no clock pulse during the reset                    caught
    START with CLK low                                 caught
    a command bit changed as CLK rises                 caught
    no 25th clock before STOP                          caught
    the data byte never sent                           caught
    no clock after the card's last bit                 caught
    I/O read as CLK falls, before the card's next bit  caught
    CLK low only 5 us                                  caught
    |}]
;;
