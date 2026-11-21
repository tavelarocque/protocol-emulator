(* The level stream sender ([Firmware.bitstream]) and the three codes sent
   with it, each against a receiver written here from the code's own
   rules: a Qi charger's demodulator, an EM4100 reader and a Morse
   listener. The cocotb tests run the same firmware on the RTL and the
   gate netlist with sigrok's Qi, EM4100 and Morse decoders reading the
   wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* Send [words] at [clkdiv], the host keeping the FIFO fed, or from
   [late_at] not at all for [late_for] cycles. The line, cycle by cycle. *)
let run ?(source = Firmware.bitstream) ?late_at ?(late_for = 0) ~clkdiv words =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.bitstream_config ~clkdiv ]
  in
  let pending = Queue.of_list words in
  let line = Queue.create () in
  for cycle = 1 to ((List.length words * 32) + 72) * clkdiv + late_for do
    let late = match late_at with Some at -> cycle >= at && cycle < at + late_for | None -> false in
    (match Queue.peek pending with
     | Some v when not late -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | _ -> ());
    Isa.step m ~inputs:0xFF;
    Queue.enqueue line (Isa.lines m ~inputs:0xFF land 1)
  done;
  Queue.to_list line
;;

(* Runs of one level: (level, cycles), from the line's first rise on (a
   pin is high from reset until the program's first instruction), the last
   left out, since it runs to the end of the recording. *)
let runs line =
  List.group line ~break:( <> )
  |> List.map ~f:(fun g -> List.hd_exn g, List.length g)
  |> List.drop_while ~f:(fun (level, _) -> level = 1)
  |> fun l -> List.drop_last_exn (List.tl_exn l)
;;

(* The cells a receiver sampling in the middle of each would see, from the
   first rising edge on. *)
let cells ~clkdiv line =
  let cell = 2 * clkdiv in
  let low = fst (List.findi_exn line ~f:(fun _ l -> l = 0)) in
  let first = fst (List.findi_exn line ~f:(fun i l -> i > low && l = 1)) in
  List.filteri line ~f:(fun i _ -> i >= first && (i - first) % cell = cell / 2)
;;

let%expect_test "cells are exact and words follow one another with no gap" =
  let words = [ 0xA5C3; 0x0001; 0xFFFE; 0x8001 ] in
  let line = run ~clkdiv:7 words in
  printf !"%{sexp:(int * int) list}\n" (runs line);
  let words = words @ words @ words in
  let line = run ~clkdiv:7 words in
  let bits = List.concat_map words ~f:(fun w -> List.init 16 ~f:(fun i -> (w lsr (15 - i)) land 1)) in
  printf "twelve words as sent: %b\n" ([%equal: int list] (List.take (cells ~clkdiv:7 line) 192) bits);
  (* A host that is late: the line holds, and nothing is lost. *)
  let late = run ~clkdiv:7 ~late_at:200 ~late_for:1000 words in
  let length l = List.sum (module Int) (runs l) ~f:snd in
  printf
    "a host that stops for 1000 cycles: the line holds for %d ticks, then the same levels in the same order: %b\n"
    ((length late - length line) / 7)
    ([%equal: int list] (List.map (runs late) ~f:fst) (List.map (runs line) ~f:fst));
  [%expect {|
    ((1 14) (0 14) (1 14) (0 28) (1 14) (0 14) (1 42) (0 56) (1 28) (0 210)
     (1 224) (0 14) (1 14) (0 196))
    twelve words as sent: true
    a host that stops for 1000 cycles: the line holds for 11 ticks, then the same levels in the same order: true
    |}]
;;

(* A Qi charger's demodulator: it measures the time between changes of
   the line. A bit is 500 us; a change half way through makes it a 1. It
   wants four ones of preamble or more, then bytes of a start bit 0, eight
   bits least significant first, odd parity and a stop bit 1, and checks
   the packet's length against its header and its checksum. *)
let qi_receive ~clkdiv line =
  let bit = 4 * clkdiv in
  let near a b = Float.(abs (of_int a - of_int b) < 0.25 * of_int bit) in
  let rec bits = function
    | a :: b :: rest when near (a + b) bit && not (near a bit) -> 1 :: bits rest
    | a :: rest when near a bit -> 0 :: bits rest
    | _ -> []
  in
  let all = bits (List.map (runs line) ~f:snd) in
  let ones, rest = List.split_while all ~f:(fun b -> b = 1) in
  let rec bytes = function
    | 0 :: rest when List.length rest >= 10 ->
      let data = List.take rest 8 in
      let parity = List.nth_exn rest 8
      and stop = List.nth_exn rest 9 in
      if parity <> 1 lxor List.fold data ~init:0 ~f:( lxor ) || stop <> 1
      then [ -1 ]
      else List.foldi data ~init:0 ~f:(fun i acc b -> acc lor (b lsl i)) :: bytes (List.drop rest 10)
    | _ -> []
  in
  let packet = bytes rest in
  match packet with
  | header :: _
    when List.length ones >= 4
         && List.length packet = Firmware.qi_message_length header + 2
         && List.fold packet ~init:0 ~f:( lxor ) = 0 -> Ok (header, List.drop_last_exn (List.tl_exn packet))
  | _ -> Error (sprintf !"%d ones, then %{sexp:int list}" (List.length ones) packet)
;;

let qi_clkdiv = 1250 (* 10 MHz: a cell is 250 us *)

(* The host is a little late with the first word: the line waits low. *)
let qi_send ?source packets =
  run
    ?source
    ~late_at:1
    ~late_for:(5 * qi_clkdiv)
    ~clkdiv:qi_clkdiv
    (Firmware.bitstream_words
       (List.concat_map packets ~f:(fun (header, message) -> Firmware.qi_cells ~header message)))
;;

(* The line up to the end of the first packet's rest, and after it. *)
let%expect_test "Qi: packets that end with the line high and with it low, as the charger hears them" =
  List.iter [ 0x01, [ 0x80 ]; 0x28, [ 0x12; 0x34 ] ] ~f:(fun packet ->
    let line = qi_send [ packet ] in
    printf
      !"%{sexp:(int * int list, string) Result.t}, then the line %{sexp:(int * int) list}\n"
      (qi_receive ~clkdiv:qi_clkdiv line)
      (List.map (List.take (List.rev (runs line)) 1) ~f:(fun (l, c) -> l, c / 10)));
  let line = qi_send [ 0x01, [ 0x80 ] ] in
  printf
    !"times between changes, us: %{sexp:int list}\n"
    (List.dedup_and_sort ~compare (List.map (runs line) ~f:(fun (_, c) -> c / 10)));
  [%expect {|
    (Ok (1 (128))), then the line ((1 250))
    (Ok (40 (18 52))), then the line ((1 1000))
    times between changes, us: (250 500)
    |}]
;;

let%test_unit "Qi: random packets of every length class" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2 (Int.gen_incl 0 255) (Int.gen_incl 0 1_000_000))
    ~trials:40
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (header, seed) ->
      let rand = Random.State.make [| seed |] in
      let message = List.init (Firmware.qi_message_length header) ~f:(fun _ -> Random.State.int rand 256) in
      [%test_result: (int * int list, string) Result.t]
        (qi_receive ~clkdiv:qi_clkdiv (qi_send [ header, message ]))
        ~expect:(Ok (header, message)))
;;

(* An EM4100 reader: it samples each half of every 512 us bit, finds the
   nine ones that begin a tag's 64 bits (nine ones in a row occur nowhere
   else in them), and checks every row's parity, every column's, and the
   stop bit. *)
let em4100_read ~clkdiv line =
  let halves = cells ~clkdiv line in
  let rec pairs = function
    | 1 :: 0 :: rest -> 1 :: pairs rest
    | 0 :: 1 :: rest -> 0 :: pairs rest
    | _ -> []
  in
  let bits = pairs halves in
  let parity l = List.fold l ~init:0 ~f:( lxor ) in
  let rec tags bits =
    if List.length bits < 64
    then []
    else if not (List.for_all (List.take bits 9) ~f:(fun b -> b = 1))
    then tags (List.tl_exn bits)
    else (
      let rows = List.chunks_of (List.sub bits ~pos:9 ~len:50) ~length:5 in
      let columns = List.sub bits ~pos:59 ~len:4 in
      let ok =
        List.for_all rows ~f:(fun r -> parity r = 0)
        && List.for_alli columns ~f:(fun i c -> parity (List.map rows ~f:(fun r -> List.nth_exn r i)) = c)
        && List.nth_exn bits 63 = 0
      in
      if not ok
      then tags (List.tl_exn bits)
      else (
        let value = List.fold rows ~init:0 ~f:(fun acc r -> (acc lsl 4) lor List.fold (List.take r 4) ~init:0 ~f:(fun a b -> (a lsl 1) lor b)) in
        (value lsr 32, value land 0xFFFF_FFFF) :: tags (List.drop bits 64)))
  in
  tags bits
;;

let em_clkdiv = 1280 (* 10 MHz: a cell is 256 us, 32 periods of 125 kHz *)

let%expect_test "EM4100: a tag sent three times over, as a reader sees it" =
  let line =
    run ~clkdiv:em_clkdiv (Firmware.bitstream_words (Firmware.em4100_cells ~repeats:3 ~version:0x06 ~id:0x001259E3 ()))
  in
  List.iter (em4100_read ~clkdiv:em_clkdiv line) ~f:(fun (version, id) -> printf "tag %02X %08X\n" version id);
  [%expect {|
    tag 06 001259E3
    tag 06 001259E3
    tag 06 001259E3
    |}]
;;

let%test_unit "EM4100: random tags" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2 (Int.gen_incl 0 255) (Int.gen_incl 0 0xFFFF_FFFF))
    ~trials:40
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (version, id) ->
      let line = run ~clkdiv:em_clkdiv (Firmware.bitstream_words (Firmware.em4100_cells ~repeats:2 ~version ~id ())) in
      [%test_result: (int * int) list] (em4100_read ~clkdiv:em_clkdiv line) ~expect:[ version, id; version, id ])
;;

(* A Morse listener: marks of one unit are dots and of three dashes; a
   silence of three units ends a letter and of seven a word. *)
let morse_listen ~clkdiv line =
  let unit = 2 * clkdiv in
  let letter marks =
    match List.find Firmware.morse_code ~f:(fun (_, code) -> String.equal code (String.of_char_list (List.rev marks))) with
    | Some (c, _) -> c
    | None -> '?'
  in
  let text, marks =
    List.fold (runs line) ~init:([], []) ~f:(fun (text, marks) (level, cycles) ->
      match level, cycles / unit, cycles % unit with
      | 1, 1, 0 -> text, '.' :: marks
      | 1, 3, 0 -> text, '-' :: marks
      | 0, 1, 0 -> text, marks
      | 0, 3, 0 -> letter marks :: text, []
      | 0, 7, 0 -> ' ' :: letter marks :: text, []
      | _ -> '!' :: text, marks)
  in
  String.of_char_list (List.rev (if List.is_empty marks then text else letter marks :: text))
;;

let%expect_test "Morse" =
  let clkdiv = 500 in
  let listen text = morse_listen ~clkdiv (run ~clkdiv (Firmware.bitstream_words (Firmware.morse_cells text))) in
  print_endline (listen "sos");
  print_endline (listen "The quick brown fox jumps over the lazy dog 0123456789");
  [%expect {|
    sos
    the quick brown fox jumps over the lazy dog 0123456789
    |}]
;;

let%expect_test "planted bugs" =
  let caught source =
    let qi = qi_send ~source [ 0x03, [ 0x7F ] ] in
    let tag = run ~source ~clkdiv:em_clkdiv (Firmware.bitstream_words (Firmware.em4100_cells ~version:0xA5 ~id:0xDEADBEEF ())) in
    not
      (List.nth_exn qi (3 * qi_clkdiv) = 0
       && [%equal: (int * int list, string) Result.t] (qi_receive ~clkdiv:qi_clkdiv qi) (Ok (0x03, [ 0x7F ]))
       && [%equal: (int * int) list] (em4100_read ~clkdiv:em_clkdiv tag) [ 0xA5, 0xDEADBEEF ])
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.bitstream ~pattern ~with_ in
    assert (not (String.equal s Firmware.bitstream));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.bitstream then "WRONG" else "right");
  List.iter
    [ "two bits of the word spent on each cell", fw ~pattern:"out pins, 1" ~with_:"out pins, 2"
    ; "the line left high before the first word", fw ~pattern:"set pins, 0" ~with_:"nop        "
    ; "a cell three ticks long", fw ~pattern:"jmp cell" ~with_:"nop\n        jmp cell"
    ]
    ~f:(fun (name, source) -> printf "%-46s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    two bits of the word spent on each cell        caught
    the line left high before the first word       caught
    a cell three ticks long                        caught
    |}]
;;
