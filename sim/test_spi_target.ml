(* Device mode: the chip as an SPI device ([Firmware.spi_target]).

   The controller is the reference mode-0 controller from [Spi_model]
   (written from the protocol definition), and the passive mode-0 checker
   judges both directions on every cycle. Also here: two model chips on one
   bus (the controller firmware on one, the device firmware on the other),
   recovery from a transfer cut in the middle of a byte, the whole chip over
   SPI, and planted firmware bugs. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Spi = Pe_model.Spi_model
module Top = Pe_hw.Top

(* P2 (MISO) push-pull, the rest inputs. *)
let mode_bits = 0b00_01_00_00

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    match (mode_bits lsr (2 * i)) land 3 with
    | 1 -> Isa.Pin_mode.Push_pull
    | _ -> Input)
;;

let idle = true, false, true (* cs_n, sck, mosi *)

type outcome =
  { events : Spi.Event.t list
  ; errors : string list
  ; rx : int list
  }

let run_model ?(source = Firmware.spi_target) ~replies wave =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ Firmware.spi_target_config ]
  in
  let pending = Queue.of_list (List.map replies ~f:Firmware.spi_target_reply_word) in
  let rx = Queue.create () in
  let checker = Spi.Checker.create () in
  for c = 0 to Array.length wave + 200 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    let cs_n, sck, mosi = if c < Array.length wave then wave.(c) else idle in
    let inputs =
      0xF4 lor Bool.to_int sck lor (Bool.to_int mosi lsl 1) lor (Bool.to_int cs_n lsl 3)
    in
    Isa.step m ~inputs;
    let miso = (Isa.lines m ~inputs lsr 2) land 1 = 1 in
    Spi.Checker.step checker ~sck ~mosi ~miso ~cs_n
  done;
  { events = Spi.Checker.events checker
  ; errors = Spi.Checker.errors checker
  ; rx = Queue.to_list rx
  }
;;

(* The replies are one stream across transfers: the n-th byte clocked, in
   whichever transfer, gets the n-th reply. *)
let expected_events transfers ~replies =
  let open Spi.Event in
  let replies = ref replies in
  List.concat_map transfers ~f:(fun bytes ->
    (Select
     :: List.map bytes ~f:(fun mosi ->
       let miso = List.hd_exn !replies in
       replies := List.tl_exn !replies;
       Byte { mosi; miso }))
    @ [ Deselect ])
;;

let expected_rx transfers =
  List.concat_map transfers ~f:(fun bytes -> bytes @ [ Firmware.spi_target_end_marker ])
;;

let works ?source ~half ~byte_gap transfers ~replies =
  let r = run_model ?source ~replies (Spi.Controller.waveform ~byte_gap ~half transfers) in
  List.is_empty r.errors
  && [%equal: Spi.Event.t list] r.events (expected_events transfers ~replies)
  && [%equal: int list] r.rx (expected_rx transfers)
;;

let%test_unit "program: 23 words, and the timeout vector is [desel]" =
  let program = Asm.assemble Firmware.spi_target in
  [%test_result: int] (Array.length program) ~expect:23;
  [%test_result: Isa.Instruction.op]
    program.(Firmware.spi_target_desel).op
    ~expect:(Mov { dst = Osr; src = Y })
;;

let gen_transfers =
  let open Quickcheck.Generator in
  list_non_empty (list_non_empty (Int.gen_incl 0 255))
;;

let%test_unit "model: transfers from the reference controller, 8 to 40 clocks per half bit" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       gen_transfers
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 8 40)
       (Int.gen_incl 0 30))
    ~trials:200
    ~sexp_of:[%sexp_of: int list list * int list * int * int]
    ~f:(fun (transfers, seed, half, byte_gap) ->
      let transfers = List.take (List.map transfers ~f:(fun t -> List.take t 5)) 3 in
      let n = List.sum (module Int) transfers ~f:List.length in
      (* one reply per byte, plus the one the firmware holds ahead *)
      let replies = List.init (n + 1) ~f:(fun i -> List.nth_exn seed (i mod List.length seed) lxor i) in
      let replies = List.map replies ~f:(fun b -> b land 0xFF) in
      let r = run_model ~replies (Spi.Controller.waveform ~byte_gap ~half transfers) in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: Spi.Event.t list] r.events ~expect:(expected_events transfers ~replies);
      [%test_result: int list] r.rx ~expect:(expected_rx transfers))
;;

let%expect_test "timing: the fastest controller the chip keeps up with" =
  let transfers = [ [ 0x9F; 0x00; 0xA5 ]; [ 0x5A; 0xFF ] ]
  and replies = [ 0x12; 0xEF; 0x00; 0x81; 0x7E; 0x33 ] in
  List.iter [ 0; 20 ] ~f:(fun byte_gap ->
    let fastest =
      List.find_exn (List.range 1 40) ~f:(fun half -> works ~half ~byte_gap transfers ~replies)
    in
    assert (
      List.for_all (List.range fastest 61) ~f:(fun half ->
        works ~half ~byte_gap transfers ~replies));
    printf
      "byte gap %2d: works from half = %d clocks (SCK up to %.0f kHz at 10 MHz)\n"
      byte_gap
      fastest
      (10_000. /. Float.of_int (2 * fastest)));
  [%expect
    {|
    byte gap  0: works from half = 8 clocks (SCK up to 625 kHz at 10 MHz)
    byte gap 20: works from half = 8 clocks (SCK up to 625 kHz at 10 MHz)
    |}]
;;

(* A transfer the controller abandons after 3 bits: the next transfer must
   still be framed correctly. *)
let%test_unit "model: a transfer cut mid-byte, then a normal one" =
  let half = 15 in
  let cut =
    let w = Spi.Controller.waveform ~gap:40 ~half [ [ 0xA5 ] ] in
    (* up to just before the fourth rising edge, then deselect *)
    let rises =
      List.filter (List.range 1 (Array.length w)) ~f:(fun i ->
        let _, a, _ = w.(i - 1)
        and _, b, _ = w.(i) in
        (not a) && b)
    in
    Array.append
      (Array.sub w ~pos:0 ~len:(List.nth_exn rises 3))
      (Array.create ~len:40 idle)
  in
  let next = [ 0x03; 0x10; 0x20 ] in
  let wave = Array.append cut (Spi.Controller.waveform ~half [ next ]) in
  let r = run_model ~replies:[ 1; 2; 3; 4; 5 ] wave in
  [%test_result: int list]
    r.rx
    ~expect:((Firmware.spi_target_end_marker :: next) @ [ Firmware.spi_target_end_marker ])
;;

(* --- Chip to chip -------------------------------------------------------- *)

(* [Firmware.spi_controller] on one model chip, [Firmware.spi_target] on
   another, on the same four wires. Each sees the other's pins one clock
   late. *)
let%test_unit "two chips: one is the controller, the other the device" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Quickcheck.Generator.of_list [ 8; 12; 20 ]))
    ~trials:30
    ~sexp_of:[%sexp_of: int list * int list * int]
    ~f:(fun (sent, seed, h) ->
      let sent = List.take sent 4 in
      let n = List.length sent in
      let replies = List.init (n + 1) ~f:(fun i -> List.nth_exn seed (i mod List.length seed)) in
      let controller_modes =
        Array.init Isa.num_pins ~f:(fun i ->
          if i = 0 || i = 1 || i = 3 then Isa.Pin_mode.Push_pull else Input)
      in
      let controller =
        Isa.create
          ~program:(Asm.assemble Firmware.spi_controller)
          ~pin_modes:controller_modes
          ~threads:
            [ { Isa.Thread_config.default with
                set_base = 0
              ; set_count = 1
              ; out_base = 1
              ; out_count = 3
              ; in_base = 2
              ; threshold = 8
              }
            ]
      in
      let device =
        Isa.create
          ~program:(Asm.assemble Firmware.spi_target)
          ~pin_modes:modes
          ~threads:[ Firmware.spi_target_config ]
      in
      let to_controller =
        Queue.of_list
          (h :: List.mapi sent ~f:(fun i b -> Firmware.spi_word ~last:(i = n - 1) b))
      and to_device = Queue.of_list (List.map replies ~f:Firmware.spi_target_reply_word) in
      let feed m q =
        match Queue.peek q with
        | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue q : int option)
        | None -> ()
      in
      let got = Queue.create ()
      and device_rx = Queue.create () in
      let checker = Spi.Checker.create () in
      for _ = 1 to 400 + (n * 8 * ((2 * h) + 9)) + 400 do
        feed controller to_controller;
        feed device to_device;
        let a = Isa.pin_out controller
        and b = Isa.pin_out device in
        Isa.step controller ~inputs:(0xFB lor (b land 0b100));
        Isa.step device ~inputs:(0xF4 lor (a land 0b1011));
        let a = Isa.pin_out controller
        and b = Isa.pin_out device in
        Spi.Checker.step
          checker
          ~sck:(a land 1 = 1)
          ~mosi:(a land 2 = 2)
          ~miso:(b land 4 = 4)
          ~cs_n:(a land 8 = 8);
        Option.iter (Isa.pop_rx controller ~thread:0) ~f:(Queue.enqueue got);
        Option.iter (Isa.pop_rx device ~thread:0) ~f:(Queue.enqueue device_rx)
      done;
      [%test_result: string list] (Spi.Checker.errors checker) ~expect:[];
      [%test_result: Spi.Event.t list]
        (Spi.Checker.events checker)
        ~expect:(expected_events [ sent ] ~replies);
      [%test_result: int list] (Queue.to_list device_rx) ~expect:(expected_rx [ sent ]);
      [%test_result: int list]
        (Queue.to_list got |> List.map ~f:Firmware.reverse_byte)
        ~expect:(List.take replies n))
;;

(* --- Planted firmware bugs --------------------------------------------- *)

let mutate ~pattern ~with_ =
  let m = String.substr_replace_first Firmware.spi_target ~pattern ~with_ in
  assert (not (String.equal m Firmware.spi_target));
  m
;;

let mutants =
  [ ( "MOSI sampled after SCK falls"
    , mutate
        ~pattern:
          "in pins, 1          ; sample MOSI\n        wait 0 pin 0        ; SCK falls"
        ~with_:"wait 0 pin 0        ; SCK falls\n        in pins, 1          ; sample MOSI" )
  ; ( "does not wait for SCK to fall"
    , mutate
        ~pattern:"wait 0 pin 0        ; SCK falls"
        ~with_:"nop                 ; SCK falls" )
  ; ( "deselect never seen"
    , mutate
        ~pattern:"wait 0 pin 3 timeout ; deselected"
        ~with_:"nop                 ; deselected" )
  ; ( "reply bits not restored after the poll"
    , mutate
        ~pattern:"mov osr, y          ; SCK rose"
        ~with_:"nop                 ; SCK rose" )
  ; ( "deselect drops the queued reply"
    , mutate
        ~pattern:"desel:  mov osr, y "
        ~with_:"desel:  nop        " )
  ]
;;

let%expect_test "planted firmware bugs: each is caught" =
  let transfers = [ [ 0x9F; 0x00; 0xA5 ]; [ 0x5A; 0xFF ] ]
  and replies = [ 0x12; 0xEF; 0x00; 0x81; 0x7E; 0x33 ] in
  assert (works ~half:12 ~byte_gap:0 transfers ~replies);
  List.iter mutants ~f:(fun (name, source) ->
    assert (Array.length (Asm.assemble source) = 23);
    let missed =
      List.for_all [ 0; 10 ] ~f:(fun byte_gap ->
        works ~source ~half:12 ~byte_gap transfers ~replies)
    in
    printf "%-40s %s\n" name (if missed then "MISSED" else "caught"));
  [%expect
    {|
    MOSI sampled after SCK falls             caught
    does not wait for SCK to fall            caught
    deselect never seen                      caught
    reply bits not restored after the poll   caught
    deselect drops the queued reply          caught
    |}]
;;

(* --- The whole chip, over SPI ------------------------------------------- *)

let%test_unit "chip: a transfer from the reference controller" =
  let sent = [ 0x9F; 0x00; 0x00; 0x00 ]
  and replies = [ 0x00; 0xEF; 0x40; 0x18; 0x77 ] in
  let h = Test_top.create ~half:4 () in
  Test_top.load_firmware h Firmware.spi_target;
  Test_top.configure h ~thread:0 Firmware.spi_target_config;
  Test_top.write h Top.Addr.pin_modes mode_bits;
  (* the bus idle (deselected) before the thread starts *)
  (Test_top.i h).uio_in := Bits.of_int ~width:8 0xFE;
  Test_top.write h Top.Addr.ctrl 1;
  List.iter replies ~f:(fun b -> Test_top.push h (Firmware.spi_target_reply_word b));
  let wave = Spi.Controller.waveform ~half:12 [ sent ] in
  let checker = Spi.Checker.create () in
  let cycle = ref 0 in
  h.Test_top.on_cycle
  <- (fun () ->
       let cs_n, sck, mosi = if !cycle < Array.length wave then wave.(!cycle) else idle in
       incr cycle;
       (Test_top.i h).uio_in
       := Bits.of_int
            ~width:8
            (0xF4 lor Bool.to_int sck lor (Bool.to_int mosi lsl 1) lor (Bool.to_int cs_n lsl 3));
       let miso = (Bits.to_int !((Test_top.o h).uio_out) lsr 2) land 1 = 1 in
       Spi.Checker.step checker ~sck ~mosi ~miso ~cs_n);
  let rx = List.map (List.range 0 (List.length sent + 1)) ~f:(fun _ -> Test_top.pop h) in
  [%test_result: string list] (Spi.Checker.errors checker) ~expect:[];
  [%test_result: Spi.Event.t list]
    (Spi.Checker.events checker)
    ~expect:(expected_events [ sent ] ~replies);
  [%test_result: int list] rx ~expect:(expected_rx [ sent ])
;;
