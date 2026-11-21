(* The infrared burst sender ([Firmware.ir_tx]) sending RC-6, against a
   receiver written here from RC-6's rules. The cocotb test runs the same
   firmware on the RTL and the gate netlist with sigrok's RC-6 decoder on
   what a receiver module would make of the LED. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let clkdiv = 139 (* 10 MHz: a tick is half a period of 36 kHz *)
let period = 2 * clkdiv
let unit_ = 16 * period (* RC-6's unit: 444 us *)

(* The LED, cycle by cycle, while [words] are sent with the host keeping
   the FIFO fed. *)
let led ?(source = Firmware.ir_tx) words =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.ir_tx_config ~clkdiv ]
  in
  let pending = Queue.of_list words in
  Array.init (unit_ * 70) ~f:(fun _ ->
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    Isa.lines m ~inputs:0xFF land 1 = 1)
;;

(* Bursts and the silences after them, in cycles: a burst runs from its
   first rise to one period after its last, and every rise in it must be
   exactly one period after the one before. *)
let bursts trace =
  let rises =
    List.filter (List.range 1 (Array.length trace)) ~f:(fun i -> trace.(i) && not trace.(i - 1))
  in
  let errors = ref [] in
  let groups =
    List.group rises ~break:(fun a b ->
      if b - a < period then errors := sprintf "carrier period of %d cycles" (b - a) :: !errors;
      b - a > period)
  in
  let runs =
    List.mapi groups ~f:(fun i g ->
      let first = List.hd_exn g in
      let stop = List.last_exn g + period in
      let next = Option.map (List.nth groups (i + 1)) ~f:List.hd_exn in
      (* After the last burst, the silence runs to the end of the trace. *)
      stop - first, Some (Option.value next ~default:(Array.length trace) - stop))
  in
  let high =
    (* The LED is lit for half of every period. *)
    Array.count trace ~f:Fn.id
  in
  if high <> List.length rises * clkdiv then errors := "the LED is not lit for half a period" :: !errors;
  runs, !errors
;;

(* A receiver from RC-6's rules: a leader lit for 6 units and dark for 2,
   then 22 bits in which a 1 is lit and then dark and a 0 the other way,
   the fifth of them, the toggle bit, twice the length. Every burst and
   silence must be a whole number of units to within a quarter. *)
let receive trace =
  let runs, errors = bursts trace in
  let units cycles =
    let n = Float.iround_nearest_exn (Float.of_int cycles /. Float.of_int unit_) in
    if abs (cycles - (n * unit_)) > unit_ / 4 then None else Some n
  in
  let levels =
    List.concat_map runs ~f:(fun (mark, space) ->
      (* A burst is at least a unit: a stray flash of light is not RC-6. *)
      let lit =
        Option.bind (units mark) ~f:(fun n -> if n = 0 then None else Some (List.init n ~f:(fun _ -> 1)))
      in
      let dark = Option.bind space ~f:(fun s -> Option.map (units s) ~f:(fun n -> List.init n ~f:(fun _ -> 0))) in
      match lit, dark with
      | Some a, Some b -> a @ b
      | _ -> [ 9 ])
  in
  if not (List.is_empty errors)
  then Error (String.concat ~sep:"; " errors)
  else if List.mem levels 9 ~equal:Int.equal
  then Error "a burst or a silence that is not a whole number of units"
  else (
    match List.split_n levels 8 with
    | [ 1; 1; 1; 1; 1; 1; 0; 0 ], rest ->
      let rec bits acc k = function
        | rest when k = 21 -> Ok (List.rev acc, rest)
        | 1 :: 1 :: 0 :: 0 :: rest when k = 4 -> bits (1 :: acc) (k + 1) rest
        | 0 :: 0 :: 1 :: 1 :: rest when k = 4 -> bits (0 :: acc) (k + 1) rest
        | 1 :: 0 :: rest when k <> 4 -> bits (1 :: acc) (k + 1) rest
        | 0 :: 1 :: rest when k <> 4 -> bits (0 :: acc) (k + 1) rest
        | _ -> Error (sprintf "bit %d is not RC-6's code" k)
      in
      (match bits [] 0 rest with
       | Error _ as e -> e
       | Ok (bits, rest) ->
         let value l = List.fold l ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b) in
         if List.exists rest ~f:(fun l -> l = 1)
         then Error "light after the frame"
         else if List.length rest < 6
         then Error "less than 6 units dark after the frame"
         else (
           match bits with
           | 1 :: 0 :: 0 :: 0 :: toggle :: data ->
             Ok (toggle = 1, value (List.take data 8), value (List.drop data 8))
           | _ -> Error "not a start bit and mode 0"))
    | _ -> Error "no leader")
;;

let cases = [ false, 0x00, 0x00; true, 0xFF, 0xFF; false, 0x04, 0x0C; true, 0xA5, 0x5A; false, 0x55, 0xAA; true, 0x80, 0x01 ]

let%expect_test "RC-6: the words for a frame, and what a receiver makes of the LED" =
  let words = Firmware.rc6_words ~toggle:true ~address:0x04 ~command:0x0C in
  printf "%d words: %s\n" (List.length words) (String.concat ~sep:" " (List.map words ~f:(sprintf "%04x")));
  let runs, errors = bursts (led words) in
  printf
    !"bursts and silences, in carrier periods: %s\n"
    (String.concat
       ~sep:" "
       (List.map runs ~f:(fun (mark, space) ->
          sprintf "%d/%s" (mark / period) (Option.value_map space ~default:"?" ~f:(fun s -> Int.to_string (s / period))))));
  printf !"errors: %{sexp:string list}\n" errors;
  print_s [%sexp (receive (led words) : (bool * int * int, string) Result.t)];
  [%expect {|
    19 words: 5f1d 0f1d 0f0d 0f0d 2f2d 0f0d 0f0d 0f0d 0f0d 1f1d 0f0d 0f0d 0f0d 0f0d 0f0d 1f0d 0f1d 0f0d 0f5d
    bursts and silences, in carrier periods: 96/32 16/32 16/16 16/16 48/48 16/16 16/16 16/16 16/16 32/32 16/16 16/16 16/16 16/16 16/16 32/16 16/32 16/16 16/286
    errors: ()
    (Ok (true 4 12))
    |}]
;;

let%test_unit "RC-6: frames reach the receiver, bit for bit" =
  List.iter cases ~f:(fun (toggle, address, command) ->
    [%test_result: (bool * int * int, string) Result.t]
      (receive (led (Firmware.rc6_words ~toggle ~address ~command)))
      ~expect:(Ok (toggle, address, command)))
;;

let%test_unit "RC-6: two frames one after the other" =
  let words =
    Firmware.rc6_words ~toggle:false ~address:0x12 ~command:0x34
    @ Firmware.rc6_words ~toggle:true ~address:0x12 ~command:0x34
  in
  let trace = led words in
  (* The second frame starts where the first one's 6 dark units end. *)
  let runs, errors = bursts trace in
  [%test_result: string list] errors ~expect:[];
  [%test_result: int]
    (List.count runs ~f:(fun (mark, _) -> mark = 6 * unit_))
    ~expect:2
;;

let%expect_test "planted bugs" =
  let caught source =
    List.exists cases ~f:(fun (toggle, address, command) ->
      not
        ([%equal: (bool * int * int, string) Result.t]
           (receive (led ~source (Firmware.rc6_words ~toggle ~address ~command)))
           (Ok (toggle, address, command))))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.ir_tx ~pattern ~with_ in
    assert (not (String.equal s Firmware.ir_tx));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.ir_tx then "WRONG" else "right");
  List.iter
    [ "the LED lit through the silences", fw ~pattern:"jmp y-- space       side 0 [1]" ~with_:"jmp y-- space       side 1 [1]"
    ; "a silence three ticks to the period", fw ~pattern:"jmp y-- space       side 0 [1]" ~with_:"jmp y-- space       side 0 [2]"
    ; "the carrier at two thirds of its rate", fw ~pattern:"mark:   nop                 side 1    " ~with_:"mark:   nop                 side 1 [1]"
    ; "the LED lit while the next word is fetched", fw ~pattern:"jmp next            side 0" ~with_:"jmp next            side 1"
    ; "the silence taken from the wrong bits", fw ~pattern:"out y, 8 " ~with_:"out y, 7 "
    ]
    ~f:(fun (name, source) -> printf "%-46s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the LED lit through the silences               caught
    a silence three ticks to the period            caught
    the carrier at two thirds of its rate          caught
    the LED lit while the next word is fetched     caught
    the silence taken from the wrong bits          caught
    |}]
;;
