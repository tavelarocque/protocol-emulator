(* The DShot sender ([Firmware.dshot]) against an ESC's receiving side
   written here from the protocol as flight controller and ESC firmware
   describe it (Betaflight, BLHeli; "DSHOT, the missing handbook"): 16-bit
   frames, most significant bit first, every bit beginning with a rising
   edge, a 0 high for 37.5% of the bit and a 1 for 75%; the value in the
   top 11 bits, the telemetry request below it and a 4-bit checksum, the
   exclusive or of the nibbles of the 12 bits before it. The cocotb test
   runs the same firmware on the RTL and the gate netlist with a DShot
   decoder for sigrok, written by someone else, reading the line. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* The ESC. It times each high pulse against the bit it begins and calls it
   a 1 past half the bit; a frame ends when the line has been low for
   three bit times. Since the sender is the chip, its timing is exact, and
   the ESC holds it to that: every bit is [bit] cycles, a 0 high for
   [3/8] of it and a 1 for [6/8]. *)
module Esc = struct
  type t =
    { bit : int (* cycles *)
    ; mutable level : bool
    ; mutable rose : int option (* when the current bit began *)
    ; mutable fell : int option
    ; mutable bits : int list (* newest first *)
    ; mutable frames : (int * bool * bool) list (* value, telemetry, checksum right; newest first *)
    ; mutable last_end : int option (* the last frame's final fall *)
    ; mutable gaps : int list (* between frames, in cycles *)
    ; mutable errors : string list
    ; mutable now : int
    }

  let create ~bit =
    { bit
    ; level = false
    ; rose = None
    ; fell = None
    ; bits = []
    ; frames = []
    ; last_end = None
    ; gaps = []
    ; errors = []
    ; now = 0
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  (* A bit whose high part ran from [rose] to [fell]. *)
  let take t ~rose ~fell =
    let high = fell - rose in
    let b = 2 * high > t.bit in
    if high <> if b then 6 * t.bit / 8 else 3 * t.bit / 8
    then error t (sprintf "a %d high for %d cycles of %d" (Bool.to_int b) high t.bit);
    t.bits <- Bool.to_int b :: t.bits
  ;;

  let finish t =
    let bits = List.rev t.bits in
    t.bits <- [];
    if List.length bits <> 16
    then error t (sprintf "a frame of %d bits" (List.length bits))
    else (
      let word = List.fold bits ~init:0 ~f:(fun a b -> (a lsl 1) lor b) in
      let twelve = word lsr 4 in
      let sum = (twelve lxor (twelve lsr 4) lxor (twelve lsr 8)) land 0xF in
      t.frames <- (word lsr 5, (word lsr 4) land 1 = 1, sum = word land 0xF) :: t.frames)
  ;;

  let step t level =
    (match t.level, level with
     | false, true ->
       (match t.rose, t.fell with
        | Some r, Some f ->
          if t.now - r <> t.bit then error t (sprintf "a bit of %d cycles" (t.now - r));
          take t ~rose:r ~fell:f
        | _ ->
          Option.iter t.last_end ~f:(fun e -> t.gaps <- (t.now - e) :: t.gaps));
       t.rose <- Some t.now;
       t.fell <- None
     | true, false -> t.fell <- Some t.now
     | _ -> ());
    (* Three bit times low: the frame is over. *)
    (match level, t.rose, t.fell with
     | false, Some r, Some f when t.now - f >= 3 * t.bit ->
       take t ~rose:r ~fell:f;
       finish t;
       t.last_end <- Some f;
       t.rose <- None;
       t.fell <- None
     | _ -> ());
    t.level <- level;
    t.now <- t.now + 1
  ;;
end

let run ?(source = Firmware.dshot) ~clkdiv frames =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.dshot_config ~clkdiv ]
  in
  let esc = Esc.create ~bit:(8 * clkdiv) in
  let pending =
    Queue.of_list (List.map frames ~f:(fun (value, telemetry) -> Firmware.dshot_word ~value ~telemetry))
  in
  for _ = 1 to ((List.length frames * 200) + 100) * clkdiv do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0;
    Esc.step esc ((Isa.lines m ~inputs:0) land 1 = 1)
  done;
  esc
;;

let show (esc : Esc.t) =
  printf !"errors: %{sexp:string list}\n" esc.errors;
  List.iter (List.rev esc.frames) ~f:(fun (value, telemetry, ok) ->
    printf "value %4d telemetry %d checksum %s\n" value (Bool.to_int telemetry) (if ok then "right" else "WRONG"))
;;

let%expect_test "throttle 1046, the worked example of the DShot handbook, and two commands" =
  let esc = run ~clkdiv:2 [ 1046, false; 0, false; 13, true; 2047, true; 48, false ] in
  show esc;
  printf !"gaps between frames, bit times: %{sexp:int list}\n" (List.rev_map esc.gaps ~f:(fun g -> g / 16));
  [%expect {|
    errors: ()
    value 1046 telemetry 0 checksum right
    value    0 telemetry 0 checksum right
    value   13 telemetry 1 checksum right
    value 2047 telemetry 1 checksum right
    value   48 telemetry 0 checksum right
    gaps between frames, bit times: (6 6 6 5)
    |}]
;;

(* The frame the handbook works through: 1046 without telemetry is
   10000010110 0 0110 on the wire. *)
let%expect_test "the bits of that frame" =
  let m =
    Isa.create
      ~program:(Asm.assemble Firmware.dshot)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.dshot_config ~clkdiv:1 ]
  in
  ignore (Isa.push_tx m ~thread:0 (Firmware.dshot_word ~value:1046 ~telemetry:false) : bool);
  let levels =
    Array.to_list (Array.init 200 ~f:(fun _ -> Isa.step m ~inputs:0; (Isa.lines m ~inputs:0) land 1))
  in
  (* Each bit begins with a rise; its level 4 ticks in is the bit. *)
  let rises = List.filter_mapi levels ~f:(fun i v -> Option.some_if (i > 0 && v = 1 && List.nth_exn levels (i - 1) = 0) i) in
  print_endline (String.concat (List.map rises ~f:(fun r -> Int.to_string (List.nth_exn levels (r + 4)))));
  [%expect {| 1000001011000110 |}]
;;

let%test_unit "random frames at every DShot rate the clock divider gives" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2
       (Int.gen_incl 1 10)
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.tuple2 (Int.gen_incl 0 2047) Bool.quickcheck_generator)))
    ~trials:200
    ~sexp_of:[%sexp_of: int * (int * bool) list]
    ~f:(fun (clkdiv, frames) ->
      let frames = List.take frames 6 in
      let esc = run ~clkdiv frames in
      [%test_result: string list] esc.errors ~expect:[];
      [%test_result: (int * bool * bool) list]
        (List.rev esc.frames)
        ~expect:(List.map frames ~f:(fun (v, t) -> v, t, true));
      (* The ESC's three bit times, and the 47 ticks the firmware claims. *)
      List.iter esc.gaps ~f:(fun g -> assert (g >= 47 * clkdiv)))
;;

let%expect_test "planted bugs" =
  let frames = [ 1046, false; 13, true; 2047, true; 0, false; 1365, false ] in
  let caught source =
    List.exists [ 1; 3 ] ~f:(fun clkdiv ->
      let esc = run ~source ~clkdiv frames in
      not
        (List.is_empty esc.errors
         && [%equal: (int * bool * bool) list]
              (List.rev esc.frames)
              (List.map frames ~f:(fun (v, t) -> v, t, true))))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.dshot ~pattern ~with_ in
    assert (not (String.equal s Firmware.dshot));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.dshot then "WRONG" else "right");
  List.iter
    [ "checksum not started again", fw ~pattern:"mov crc, null " ~with_:"nop           "
    ; "checksum over 11 bits", fw ~pattern:"out null, 4 " ~with_:"out null, 5 "
    ; "checksum's first bit lost", fw ~pattern:"out null, 12" ~with_:"out null, 13"
    ; ( "checksum not turned round"
      , fw ~pattern:"rev:    out x, 1            side 0" ~with_:"rev:    out null, 1         side 0" )
    ; "telemetry bit lost", fw ~pattern:"in y, 12" ~with_:"in y, 11"
    ; "a 0 high for 2 ticks", fw ~pattern:"jmp !x zero         side 1 [2]" ~with_:"jmp !x zero         side 1 [1]"
    ; "a 1 high for 5 ticks", fw ~pattern:"jmp !osre bit       side 1 [2]" ~with_:"jmp !osre bit       side 1 [1]"
    ; "a bit of 7 ticks", fw ~pattern:"out x, 1            side 0 [1]" ~with_:"out x, 1            side 0    "
    ; "the line left high after a last 1", fw ~pattern:"jmp next            side 0" ~with_:"jmp next            side 1"
    ]
    ~f:(fun (name, source) -> printf "%-40s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    checksum not started again               caught
    checksum over 11 bits                    caught
    checksum's first bit lost                caught
    checksum not turned round                caught
    telemetry bit lost                       caught
    a 0 high for 2 ticks                     caught
    a 1 high for 5 ticks                     caught
    a bit of 7 ticks                         caught
    the line left high after a last 1        caught
    |}]
;;
