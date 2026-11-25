(* The SpaceWire transmitter ([Firmware.spacewire_chars] on thread 0 making
   the characters, [Firmware.spacewire_ds] on thread 1 putting them on D
   and S) against a receiver written here from ECSS-E-ST-50-12C: a bit at
   every change of D or S, never both at once, the bit being D's new
   level; a character is a parity bit, a flag, then 8 data bits least
   significant first (flag 0) or two control bits (flag 1: FCT 00, EOP 01,
   EEP 10, ESC 11 in the order sent); the parity bit makes the ones odd
   over itself, the flag and the data bits of the character before; NULL
   is ESC then FCT. The cocotb test runs the same firmware on the RTL and
   the gate netlist with SpaceWire's sigrok decoder (an unmerged pull
   request) reading D and S. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

type char_ =
  | Null
  | Fct
  | Eop
  | Eep
  | Esc
  | Data of int
[@@deriving sexp_of, equal, compare]

let words chars =
  List.map chars ~f:(function
    | `Nulls n -> Firmware.Spacewire.nulls n
    | `Eop -> Firmware.Spacewire.eop
    | `Byte b -> b)
;;

(* Run the two threads with CLKDIV [clkdiv] on thread 1, the host pushing
   [host_words] to thread 0 as fast as it takes them, or from [late_at] not
   at all for [late_for] cycles. D and S, cycle by cycle. *)
let run ?(chars = Firmware.spacewire_chars) ?(ds = Firmware.spacewire_ds) ?late_at ?(late_for = 0) ~clkdiv host_words =
  let m =
    Isa.create_separate
      ~programs:[| Asm.assemble chars; Asm.assemble ds |]
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.spacewire_chars_config; Firmware.spacewire_ds_config ~clkdiv ]
  in
  Isa.set_chain m true;
  let pending = Queue.of_list host_words in
  let lines = Queue.create () in
  let bits = List.length host_words * 10 * 255 in
  for cycle = 1 to (bits * 5 * max 1 clkdiv / 10) + 2000 + late_for do
    let late = match late_at with Some at -> cycle >= at && cycle < at + late_for | None -> false in
    (match Queue.peek pending with
     | Some v when not late -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | _ -> ());
    Isa.step m ~inputs:0;
    let l = Isa.lines m ~inputs:0 in
    Queue.enqueue lines (l land 1, (l lsr 1) land 1)
  done;
  Queue.to_array lines
;;

module Receiver = struct
  (* The bits, and the cycles between one and the next. The lines are
     high from reset until the program first writes them, and must then
     both be low before the first bit, as after a link's reset. *)
  let bits (lines : (int * int) array) =
    let n = Array.length lines in
    match Array.findi lines ~f:(fun _ l -> [%equal: int * int] l (0, 0)) with
    | None -> Error "D and S never both low"
    | Some (first, _) ->
      let out = ref [] in
      let error = ref None in
      for t = first + 1 to n - 1 do
        let (d0, s0), (d1, s1) = lines.(t - 1), lines.(t) in
        if d0 <> d1 && s0 <> s1 && Option.is_none !error
        then error := Some (sprintf "D and S changed together at %d" t)
        else if d0 <> d1 || s0 <> s1
        then out := (t, d1) :: !out
      done;
      (match !error with
       | Some e -> Error e
       | None -> Ok (List.rev !out))
  ;;

  (* The characters, from the first bit, which must start a NULL. *)
  let chars bits =
    let bits = Array.of_list bits in
    let n = Array.length bits in
    let out = ref [] in
    let error = ref None in
    let prev_data = ref [] in
    let i = ref 0 in
    let first = ref true in
    while Option.is_none !error && !i + 4 <= n do
      let p = bits.(!i) and flag = bits.(!i + 1) in
      let len = if flag = 1 then 2 else 8 in
      if !i + 2 + len > n
      then i := n (* a character cut short at the end: not counted *)
      else (
        let data = List.init len ~f:(fun k -> bits.(!i + 2 + k)) in
        let ones = List.sum (module Int) !prev_data ~f:Fn.id + p + flag in
        if ones % 2 <> 1
        then error := Some (sprintf "parity error at character %d" (List.length !out))
        else (
          let c =
            if flag = 0
            then Data (List.foldi data ~init:0 ~f:(fun k acc b -> acc lor (b lsl k)))
            else (
              match data with
              | [ 0; 0 ] -> Fct
              | [ 0; 1 ] -> Eop
              | [ 1; 0 ] -> Eep
              | _ -> Esc)
          in
          (match c, !out with
           | Fct, Esc :: rest -> out := Null :: rest
           | _ -> out := c :: !out);
          if !first && not (equal_char_ c Esc) then error := Some "the first character is not a NULL";
          first := false;
          prev_data := data;
          i := !i + 2 + len))
    done;
    match !error with
    | Some e -> Error e
    | None -> Ok (List.rev !out)
  ;;

  let read lines =
    let%bind.Result bits = bits lines in
    let%map.Result chars = chars (List.map bits ~f:snd) in
    let times = List.map bits ~f:fst in
    let periods =
      List.map2_exn (List.drop_last_exn times) (List.tl_exn times) ~f:(fun a b -> b - a)
      |> List.dedup_and_sort ~compare:Int.compare
    in
    chars, periods
  ;;
end

let example = [ `Nulls 3; `Byte 0x00; `Byte 0x5B; `Byte 0xFF; `Byte 0x80; `Eop; `Nulls 2 ]

let show r = print_s [%sexp (r : (char_ list * int list, string) Result.t)]

let%expect_test "NULLs, a packet of four bytes, EOP and NULLs: 5 ticks a bit, every bit" =
  show (Receiver.read (run ~clkdiv:1 (words example)));
  [%expect {|
    (Ok
     ((Null Null Null (Data 0) (Data 91) (Data 255) (Data 128) Eop Null Null)
      (5)))
    |}]
;;

let%expect_test "CLKDIV 5: a bit of 25 cycles (2 Mbit/s at 50 MHz)" =
  show (Receiver.read (run ~clkdiv:5 (words example)));
  [%expect {|
    (Ok
     ((Null Null Null (Data 0) (Data 91) (Data 255) (Data 128) Eop Null Null)
      (25)))
    |}]
;;

let%expect_test "the first NULL's bits: 0 1 1 1 0 1 0 0, as the standard draws it" =
  match Receiver.bits (run ~clkdiv:1 (words [ `Nulls 1 ])) with
  | Ok bits ->
    print_s [%sexp (List.map bits ~f:snd : int list)];
    [%expect {| (0 1 1 1 0 1 0 0) |}]
  | Error e -> print_endline e
;;

let%expect_test "a host that is late: the lines stop, then the characters go on" =
  show (Receiver.read (run ~clkdiv:1 ~late_at:3 ~late_for:1000 (words example)));
  [%expect {|
    (Ok
     ((Null Null Null (Data 0) (Data 91) (Data 255) (Data 128) Eop Null Null)
      (5 6 834)))
    |}]
;;

let%test_unit "random packets at random rates: every character, every bit 5 ticks" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (List.gen_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 1 40)
       (Int.gen_incl 1 4))
    ~trials:40
    ~sexp_of:[%sexp_of: int list * int * int]
    ~f:(fun (bytes, nulls, clkdiv) ->
      let bytes = List.take bytes 20 in
      let chars = (`Nulls nulls :: List.map bytes ~f:(fun b -> `Byte b)) @ [ `Eop; `Nulls 1 ] in
      [%test_result: (char_ list * int list, string) Result.t]
        (Receiver.read (run ~clkdiv (words chars)))
        ~expect:
          (Ok
             ( List.init nulls ~f:(fun _ -> Null) @ List.map bytes ~f:(fun b -> Data b) @ [ Eop; Null ]
             , [ 5 * clkdiv ] )))
;;

let%expect_test "planted bugs" =
  let host = words example in
  let right = Receiver.read (run ~clkdiv:1 host) in
  let caught ?chars ?ds () =
    not ([%equal: (char_ list * int list, string) Result.t] (Receiver.read (run ?chars ?ds ~clkdiv:1 host)) right)
  in
  let fw program ~pattern ~with_ =
    let s = String.substr_replace_first program ~pattern ~with_ in
    assert (not (String.equal s program));
    s
  in
  let c = fw Firmware.spacewire_chars and d = fw Firmware.spacewire_ds in
  printf "the programs as they are: %s\n" (if caught () then "WRONG" else "right");
  List.iter
    [ "the data parity not turned over", `C (c ~pattern:"jmp x-- dpar" ~with_:"nop         ")
    ; "the parity never started again", `C (c ~pattern:"mov crc, null\n        mov osr, y" ~with_:"mov osr, y")
    ; "a data character's flag 1", `C (c ~pattern:"in null, 1              ; the flag 0" ~with_:"in x, 1")
    ; "EOP sent as EEP", `C (c ~pattern:"in null, 1              ; then 0, 1\n        in x, 1" ~with_:"in x, 1\n        in null, 1")
    ; "FCT's bits 1, 0", `C (c ~pattern:"in null, 1              ; 0, 0" ~with_:"in x, 1")
    ; "a byte sent from bit 1", `C (c ~pattern:"set y, 7" ~with_:"set y, 6")
    ; "a NULL too many", `C (c ~pattern:"nulls:  jmp y-- null\n        jmp next" ~with_:"nulls:  jmp y-- null\n        jmp null")
    ; "D and S start high", `D (d ~pattern:"set pins, 0             ; D and S low" ~with_:"set pins, 3")
    ; "an even bit's S as D", `D (d ~pattern:"set pins, 1 [1]" ~with_:"set pins, 3 [1]")
    ; "an odd bit's S turned over", `D (d ~pattern:"set pins, 0 [1]" ~with_:"set pins, 2 [1]")
    ; "an even 1 a tick long", `D (d ~pattern:"set pins, 1 [1]" ~with_:"set pins, 1 [2]")
    ; "an odd 0 a tick short", `D (d ~pattern:"set pins, 0 [1]" ~with_:"set pins, 0    ")
    ]
    ~f:(fun (name, which) ->
      let bug = match which with `C chars -> caught ~chars () | `D ds -> caught ~ds () in
      printf "%-36s %s\n" name (if bug then "caught" else "MISSED"));
  [%expect {|
    the programs as they are: right
    the data parity not turned over      caught
    the parity never started again       caught
    a data character's flag 1            caught
    EOP sent as EEP                      caught
    FCT's bits 1, 0                      caught
    a byte sent from bit 1               caught
    a NULL too many                      caught
    D and S start high                   caught
    an even bit's S as D                 caught
    an odd bit's S turned over           caught
    an even 1 a tick long                caught
    an odd 0 a tick short                caught
    |}]
;;
