(* The SENT transmitter ([Firmware.sent_tx]) against a receiver written
   here from SAE J2716: it times each pulse from falling edge to falling
   edge, takes the tick from the calibration pulse (56 ticks), reads each
   nibble as the nearest whole number of ticks less 12, wants every pulse
   low for 4 ticks or more, and checks the CRC-4 nibble with a CRC of its
   own. The cocotb test runs the same firmware on the RTL and the gate
   netlist with a SENT decoder for sigrok reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* SAE J2716's CRC-4, the recommended way: x^4 + x^3 + x^2 + 1, seed
   0101, over the data nibbles most significant bit first and then a
   nibble of zeros. The status nibble is not in it. *)
let crc4 data =
  List.fold (data @ [ 0 ]) ~init:0b0101 ~f:(fun crc nibble ->
    List.fold [ 3; 2; 1; 0 ] ~init:crc ~f:(fun crc k ->
      let crc = (crc lsl 1) lor ((nibble lsr k) land 1) in
      if crc land 0x10 <> 0 then crc lxor 0b11101 else crc))
;;

module Receiver = struct
  type t =
    { nibbles : int (* data nibbles in a frame *)
    ; mutable now : int
    ; mutable line : bool
    ; mutable fell : int option
    ; mutable low : int (* how long the pulse in progress was low *)
    ; mutable tick : float option (* from the frame's calibration pulse *)
    ; mutable last_cal : int option (* the last calibration pulse, in cycles *)
    ; mutable got : int list (* this frame's nibbles, newest first *)
    ; mutable pause_next : bool (* the pulse after a frame is its pause *)
    ; mutable frames : (int * int list) list (* (status, data), newest first *)
    ; mutable errors : string list
    }

  let create ~nibbles =
    { nibbles
    ; now = 0
    ; line = true
    ; fell = None
    ; low = 0
    ; tick = None
    ; last_cal = None
    ; got = []
    ; pause_next = false
    ; frames = []
    ; errors = []
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  (* A pulse is over: [period] cycles from its falling edge to the next. *)
  let pulse t ~period =
    match t.tick with
    | None ->
      if t.pause_next
      then t.pause_next <- false
      else (
        (* Any tick from 3 us less 20% to 90 us more 20% at 10 MHz: a pulse
           of 56 of them is a calibration pulse. *)
        let tick = Float.of_int period /. 56. in
        if Float.(tick < 24. || tick > 1080.)
        then error t (sprintf "a pulse of %d cycles where a calibration pulse belongs" period)
        else (
          (* Successive calibration pulses may differ by 1/64 at most. *)
          Option.iter t.last_cal ~f:(fun last ->
            if 64 * Int.abs (period - last) > last
            then error t "calibration pulses differ by more than 1/64");
          t.last_cal <- Some period;
          t.tick <- Some tick;
          t.got <- []))
    | Some tick ->
      let ticks = Float.of_int period /. tick in
      let n = Float.iround_nearest_exn ticks in
      if Float.(abs (ticks - of_int n) > 0.25)
      then error t (sprintf "a nibble of %.2f ticks" ticks);
      if Float.(of_int t.low /. tick < 4.) then error t "a pulse low for less than 4 ticks";
      if n < 12 || n > 27
      then (
        error t (sprintf "a nibble of %d ticks" n);
        t.tick <- None)
      else (
        t.got <- (n - 12) :: t.got;
        if List.length t.got = t.nibbles + 2
        then (
          (match List.rev t.got with
           | status :: rest ->
             let data = List.take rest t.nibbles in
             let crc = List.last_exn rest in
             if crc <> crc4 data then error t "CRC" else t.frames <- (status, data) :: t.frames
           | [] -> assert false);
          t.tick <- None;
          t.pause_next <- true))
  ;;

  let step t ~line =
    t.now <- t.now + 1;
    (match t.line, line with
     | true, false ->
       Option.iter t.fell ~f:(fun fell ->
         if t.pause_next
         then (
           (* The pause pulse: 12 to 768 ticks of the frame before. *)
           match t.last_cal with
           | Some cal ->
             let ticks = Float.of_int (t.now - fell) *. 56. /. Float.of_int cal in
             if Float.(ticks < 12. || ticks > 768.5) then error t (sprintf "a pause of %.1f ticks" ticks)
           | None -> ());
         pulse t ~period:(t.now - fell));
       t.fell <- Some t.now
     | false, true -> Option.iter t.fell ~f:(fun fell -> t.low <- t.now - fell)
     | _ -> ());
    t.line <- line
  ;;
end

let clkdiv = 15 (* 10 MHz: a SENT tick of 3 us is 30 cycles *)

(* Send [frames] of [nibbles] data nibbles each, then run until the last
   one's pause has begun. *)
let run ?(source = Firmware.sent_tx) ?(config = Firmware.sent_tx_config ~clkdiv) ~nibbles frames =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ config ]
  in
  let r = Receiver.create ~nibbles in
  let words = (nibbles - 1) :: List.concat_map frames ~f:(fun (status, data) -> Firmware.sent_words ~status data) in
  let pending = Queue.of_list words in
  let tick = 2 * config.clkdiv in
  for _ = 1 to tick * (List.length frames * (56 + (28 * (nibbles + 2)) + 120) + 100) do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    Receiver.step r ~line:(Isa.lines m ~inputs:0xFF land 1 = 1)
  done;
  r
;;

let show r =
  printf !"errors: %{sexp:string list}\n" r.Receiver.errors;
  List.iter (List.rev r.frames) ~f:(fun (status, data) ->
    printf
      "status %x, data %s, CRC %x\n"
      status
      (String.concat (List.map data ~f:(sprintf "%x")))
      (crc4 data))
;;

let%expect_test "three frames of six data nibbles, every value in them" =
  let frames = [ 0x5, [ 0x0; 0xF; 0x8; 0x7; 0x1; 0xE ]; 0xA, [ 0x3; 0xC; 0x5; 0xA; 0x6; 0x9 ]; 0x0, [ 0x2; 0xB; 0x4; 0xD; 0x0; 0x0 ] ] in
  let r = run ~nibbles:6 frames in
  show r;
  [%test_result: (int * int list) list] (List.rev r.frames) ~expect:frames;
  [%expect {|
    errors: ()
    status 5, data 0f871e, CRC 9
    status a, data 3c5a69, CRC 3
    status 0, data 2b4d00, CRC a
    |}]
;;

let%test_unit "random frames of 1 to 6 data nibbles, at 3 us and at 90 us ticks" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 1 6)
       Bool.quickcheck_generator
       (Quickcheck.Generator.list_with_length 3 (Quickcheck.Generator.list_with_length 7 (Int.gen_incl 0 15))))
    ~trials:25
    ~sexp_of:[%sexp_of: int * bool * int list list]
    ~f:(fun (nibbles, slow, frames) ->
      let frames = List.map frames ~f:(fun f -> List.hd_exn f, List.take (List.tl_exn f) nibbles) in
      (* 90 us is the longest tick the standard has: CLKDIV 450 at 10 MHz. *)
      let config = Firmware.sent_tx_config ~clkdiv:(if slow then 450 else clkdiv) in
      let r = run ~config ~nibbles frames in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: (int * int list) list] (List.rev r.frames) ~expect:frames)
;;

let%expect_test "planted bugs" =
  let frames = [ 0x5, [ 0x0; 0xF; 0x8; 0x7; 0x1; 0xE ]; 0xA, [ 0x3; 0xC; 0x5; 0xA; 0x6; 0x9 ]; 0x9, [ 0xE; 0x1; 0x2; 0xB; 0x4; 0xD ] ] in
  let caught ?config source =
    let r = run ?config ~source ~nibbles:6 frames in
    not (List.is_empty r.errors && [%equal: (int * int list) list] (List.rev r.frames) frames)
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.sent_tx ~pattern ~with_ in
    assert (not (String.equal s Firmware.sent_tx));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.sent_tx then "WRONG" else "right");
  List.iter
    [ "calibration pulse of 55 ticks", fw ~pattern:"nop [7]                 ; 104" ~with_:"nop [5]                 ; 104"
    ; ( "the status nibble in the CRC"
      , fw ~pattern:"mov crc, null           ; 2" ~with_:"nop                     ; 2" )
    ; "a data bit worth 8 waits 7 ticks", fw ~pattern:"        nop [15]                ; 8" ~with_:"        nop [13]                ; 8"
    ; ( "a nibble low for 2.5 ticks"
      , fw
          ~pattern:"low:    nop [5]                 ; 4..9\n        set pins, 1             ; 10"
          ~with_:"low:    nop                     ; 4\n        set pins, 1 [4]         ; 5..9" )
    ; "no word fetched after four nibbles", fw ~pattern:"jmp !osre have" ~with_:"jmp have      "
    ; ( "the CRC's lowest bit worth 8 ticks"
      , fw ~pattern:"jmp !y c2               ; 12\n        nop [1]" ~with_:"jmp !y c2               ; 12\n        nop [15]" )
    ; "one data nibble short", fw ~pattern:"mov x, isr [10]" ~with_:"set x, 4 [10]  "
    ]
    ~f:(fun (name, source) -> printf "%-48s %s\n" name (if caught source then "caught" else "MISSED"));
  (* And in the configuration: the seed 0101 as it is, with no nibble of
     zeros folded into it. *)
  printf
    "%-48s %s\n"
    "the CRC from 0101, no nibble of zeros"
    (if caught ~config:{ (Firmware.sent_tx_config ~clkdiv) with crc_init = 0b1010 } Firmware.sent_tx then "caught" else "MISSED");
  [%expect {|
    the program as it is: right
    calibration pulse of 55 ticks                    caught
    the status nibble in the CRC                     caught
    a data bit worth 8 waits 7 ticks                 caught
    a nibble low for 2.5 ticks                       caught
    no word fetched after four nibbles               caught
    the CRC's lowest bit worth 8 ticks               caught
    one data nibble short                            caught
    the CRC from 0101, no nibble of zeros            caught
    |}]
;;
