(* DALI and RC-5 received through the bit sampler and its prescaler (v2.3):
   the same block that recovers 10 Mbit Ethernet, at 1200 and 562 bit/s.
   The senders here are written from each protocol's rules, with their own
   bit time, up to 15% off the chip's for DALI and 20% for RC-5. The cocotb tests run the same
   firmware on the RTL and the gate netlist with sigrok's decoders reading
   the same wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* Pin levels over time from (level of the eight pins, cycles) runs. *)
let waveform runs = Array.concat (List.map runs ~f:(fun (pins, n) -> Array.create ~len:n pins))

(* The RX words a receiver produces while its input pins follow [levels],
   one entry per cycle, the host taking each word as it comes. *)
let receive ~config ~sampler source levels =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.create ~len:Isa.num_pins Isa.Pin_mode.Input)
      ~threads:[ config ]
  in
  Isa.set_sampler m sampler;
  let read = ref [] in
  Array.iter levels ~f:(fun pins ->
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(fun v -> read := v :: !read);
    Isa.step m ~inputs:pins);
  List.rev !read
;;

(* --- DALI ------------------------------------------------------------------- *)

let dali_clkdiv = 417 (* 10 MHz: a sample is 41.7 us, a tenth of a half bit *)
let dali_half = 4167 (* cycles in half a bit at 1200 bit/s *)

(* The bus on pin 1 for one frame: the start bit, a 1, then [bits]; a 1 is
   low then high. [half]: the sender's half bit in cycles. Then the bus
   idle for [gap] half bits. *)
let dali_frame ?(half = dali_half) ?(gap = 12) bits =
  let low = 0xFD, half
  and high = 0xFF, half in
  waveform
    (List.concat_map (1 :: bits) ~f:(fun b -> if b = 1 then [ low; high ] else [ high; low ])
     @ [ 0xFF, gap * half ])
;;

let idle n = waveform [ 0xFF, n * dali_half ]

let dali_rx ?(source = Firmware.dali_rx) ?(sampler = Firmware.dali_rx_sampler ~clkdiv:dali_clkdiv) levels =
  receive ~config:(Firmware.dali_rx_config ~clkdiv:dali_clkdiv) ~sampler source levels
  |> Firmware.dali_rx_frames
;;

(* What the receiver makes of a bus that carries [frames] after being idle:
   the frames, without the one report of an idle bus it gives when the
   sampler is switched on. *)
let dali_received ?source ?sampler ?half ?gap frames =
  match dali_rx ?source ?sampler (Array.concat (idle 12 :: List.map frames ~f:(dali_frame ?half ?gap))) with
  | Error "no start bit" :: rest -> rest
  | other -> other
;;

let bits_of ~width v = List.init width ~f:(fun i -> (v lsr (width - 1 - i)) land 1)

let%expect_test "DALI receiver: what the host is given for a frame" =
  let words =
    receive
      ~config:(Firmware.dali_rx_config ~clkdiv:dali_clkdiv)
      ~sampler:(Firmware.dali_rx_sampler ~clkdiv:dali_clkdiv)
      Firmware.dali_rx
      (Array.concat [ idle 12; dali_frame (bits_of ~width:8 0xA5); dali_frame (bits_of ~width:8 0x5A) ])
  in
  List.iter words ~f:(printf "%04x ");
  [%expect {| 0007 fffd 59a6 0007 ffec 6659 0017 ffeb |}]
;;

let%test_unit "DALI receiver: answers of 8 bits, frames of 16 and of 24" =
  List.iter [ 8; 16; 24 ] ~f:(fun width ->
    List.iter [ 0x000000; 0xFFFFFF; 0x555555; 0xAAAAAA; 0xFF05A5; 0x02A5C3; 0x800001; 0x7FFFFE ] ~f:(fun v ->
      let bits = bits_of ~width (v land ((1 lsl width) - 1)) in
      [%test_result: (int list, string) Result.t list] (dali_received [ bits ]) ~expect:[ Ok bits ]))
;;

let%test_unit "DALI receiver: senders 15% fast to 15% slow, and frames one after another" =
  List.iter [ 3542; 3650; 3750; 3900; 4000; 4167; 4300; 4584; 4700; 4792 ] ~f:(fun half ->
    let frames = List.map [ 0xFF05; 0x0000; 0xFFFF; 0x5555; 0xAAAA; 0x02A5 ] ~f:(bits_of ~width:16) in
    [%test_result: (int list, string) Result.t list]
      (dali_received ~half frames)
      ~expect:(List.map frames ~f:(fun f -> Ok f)))
;;

let%test_unit "DALI receiver: a forward frame and its answer 2.9 ms later" =
  (* The shortest settling time DALI allows before a backward frame: 7 half
     bits. The stop bits are part of it. *)
  let forward = bits_of ~width:16 0xFF90
  and answer = bits_of ~width:8 0xC4 in
  [%test_result: (int list, string) Result.t list]
    (dali_rx (Array.concat [ idle 12; dali_frame ~gap:7 forward; dali_frame answer ]) |> List.tl_exn)
    ~expect:[ Ok forward; Ok answer ]
;;

let%expect_test "DALI receiver: a bus held low is not a frame, and the next frame is read" =
  let low n = waveform [ 0xFD, n * dali_half ] in
  let frame = bits_of ~width:8 0x3C in
  dali_rx (Array.concat [ idle 12; low 40; idle 12; dali_frame frame ])
  |> List.iter ~f:(fun r -> print_s [%sexp (r : (int list, string) Result.t)]);
  [%expect {|
    (Error "no start bit")
    (Error "low for a whole bit: not DALI's code")
    (Error "no start bit")
    (Ok (0 0 1 1 1 1 0 0))
    |}]
;;

let%expect_test "DALI receiver: planted bugs" =
  let frames = List.map [ 0xFF05; 0x02A5; 0x5555 ] ~f:(bits_of ~width:16) in
  let right = List.map frames ~f:(fun f -> Ok f) in
  let caught ?source ?sampler ?half () =
    not ([%equal: (int list, string) Result.t list] (dali_received ?source ?sampler ?half frames) right)
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.dali_rx ~pattern ~with_ in
    assert (not (String.equal s Firmware.dali_rx));
    s
  in
  let smp = Firmware.dali_rx_sampler ~clkdiv:dali_clkdiv in
  List.iter
    [ "the count starts a half bit out", caught ~source:(fw ~pattern:"jmp x-- first" ~with_:"nop") ()
    ; "the last word not sent", caught ~source:(fw ~pattern:"eof:    push" ~with_:"eof:    nop") ()
    ; ( "the end of a frame never looked for"
      , caught ~source:(fw ~pattern:"wait 1 pin 2 timeout" ~with_:"wait 1 pin 2        ") () )
    ; "sampled where the edges are", caught ~sampler:{ smp with sample = 9 } ~half:3750 ()
    ; "a half bit half as long again", caught ~sampler:{ smp with wrap = 14 } ()
    ; "the frame over after one half bit without an edge", caught ~sampler:{ smp with misses = 0 } ()
    ; "edges ignored for most of a half bit", caught ~sampler:{ smp with blank = 8 } ~half:3750 ()
    ]
    ~f:(fun (name, caught) -> printf "%-52s %s\n" name (if caught then "caught" else "MISSED"));
  [%expect {|
    the count starts a half bit out                      caught
    the last word not sent                               caught
    the end of a frame never looked for                  caught
    sampled where the edges are                          caught
    a half bit half as long again                        caught
    the frame over after one half bit without an edge    caught
    edges ignored for most of a half bit                 caught
    |}]
;;

(* --- RC-5 ------------------------------------------------------------------- *)

let rc5_clkdiv = 889 (* 10 MHz: a sample is 88.9 us, a twentieth of a bit *)
let rc5_half = 8890 (* cycles in half a bit *)

(* A receiver module's output on pin 0 for [bits]: low while it sees
   carrier. A 1 is silence then carrier, a 0 carrier then silence. Then
   silence for [gap] half bits. *)
let rc5_module_output ?(half = rc5_half) ?(gap = 12) bits =
  let carrier = 0xFE, half
  and silence = 0xFF, half in
  waveform
    (List.concat_map bits ~f:(fun b -> if b = 1 then [ silence; carrier ] else [ carrier; silence ])
     @ [ 0xFF, gap * half ])
;;

let rc5_frame ~toggle ~address ~command = bits_of ~width:14 (Firmware.rc5_word ~toggle ~address ~command lsr 2)

let rc5_rx ?(source = Firmware.rc5_rx) ?(sampler = Firmware.rc5_rx_sampler ~clkdiv:rc5_clkdiv) levels =
  receive ~config:(Firmware.rc5_rx_config ~clkdiv:rc5_clkdiv) ~sampler source levels
;;

let rc5_received ?source ?sampler ?half frames =
  rc5_rx ?source ?sampler (Array.concat (waveform [ 0xFF, 12 * rc5_half ] :: List.map frames ~f:(rc5_module_output ?half)))
;;

let rc5_cases =
  [ false, 0, 0; true, 31, 63; false, 5, 0x35; true, 21, 42; false, 10, 21; true, 0, 1; false, 31, 62; true, 16, 32 ]
;;

let%test_unit "RC-5 receiver: frames from remotes 20% fast to 20% slow" =
  List.iter [ 7112; 7600; 8000; 8500; 8890; 9300; 9800; 10_200; 10_668 ] ~f:(fun half ->
    let frames = List.map rc5_cases ~f:(fun (toggle, address, command) -> rc5_frame ~toggle ~address ~command) in
    [%test_result: int list]
      (rc5_received ~half frames)
      ~expect:(List.map rc5_cases ~f:(fun (toggle, address, command) -> Firmware.rc5_word ~toggle ~address ~command lsr 2)))
;;

let%test_unit "RC-5 receiver: a transmission cut short is dropped, and the next frame is read" =
  let whole = rc5_frame ~toggle:true ~address:5 ~command:0x35 in
  List.iter (List.range 1 14) ~f:(fun n ->
    [%test_result: int list]
      (rc5_received [ List.take whole n; whole ])
      ~expect:[ Firmware.rc5_word ~toggle:true ~address:5 ~command:0x35 lsr 2 ])
;;

let%expect_test "RC-5 receiver: planted bugs" =
  let frames = List.map rc5_cases ~f:(fun (toggle, address, command) -> rc5_frame ~toggle ~address ~command) in
  let right = List.map rc5_cases ~f:(fun (toggle, address, command) -> Firmware.rc5_word ~toggle ~address ~command lsr 2) in
  let caught ?source ?sampler ?half () = not ([%equal: int list] (rc5_received ?source ?sampler ?half frames) right) in
  (* A transmission of five bits, then a frame. *)
  let caught_after_a_short_one source =
    let whole = List.nth_exn frames 1 in
    not ([%equal: int list] (rc5_received ~source [ List.take whole 5; whole ]) [ List.nth_exn right 1 ])
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.rc5_rx ~pattern ~with_ in
    assert (not (String.equal s Firmware.rc5_rx));
    s
  in
  let smp = Firmware.rc5_rx_sampler ~clkdiv:rc5_clkdiv in
  List.iter
    [ "a frame of 15 bits", caught ~source:(fw ~pattern:"set y, 13" ~with_:"set y, 14") ()
    ; ( "bits left over from a frame cut short"
      , caught_after_a_short_one (fw ~pattern:"rx:     mov isr, null" ~with_:"rx:     nop") )
    ; "carrier read as a 0", caught ~sampler:{ smp with invert = false } ()
    ; "the edges between bits accepted", caught ~sampler:{ smp with blank = 8 } ()
    ; "the bit taken after the edge between bits", caught ~sampler:{ smp with sample = 12 } ()
    ; "the carrier given up before the next bit's edge", caught ~sampler:{ smp with wrap = 12 } ()
    ]
    ~f:(fun (name, caught) -> printf "%-52s %s\n" name (if caught then "caught" else "MISSED"));
  [%expect {|
    a frame of 15 bits                                   caught
    bits left over from a frame cut short                caught
    carrier read as a 0                                  caught
    the edges between bits accepted                      caught
    the bit taken after the edge between bits            caught
    the carrier given up before the next bit's edge      caught
    |}]
;;
