(* The ARINC 429 transmitter ([Firmware.arinc429_tx]) against a receiver
   written here from ARINC Specification 429 Part 1: bipolar return to
   zero, a bit's first half at HI for a 1 or LO for a 0 and its second half
   at NULL; 32 bits a word, sent bit 1 first; the label in bits 1 to 8 with
   its most significant bit first, the SDI in 9 and 10, the data in 11 to
   29, the SSM in 30 and 31, all least significant bit first; odd parity in
   bit 32; and at least four bit times of NULL between words. The cocotb
   test runs the same firmware on the RTL and the gate netlist with two
   ARINC 429 decoders published by others reading the two lines. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

type word =
  { label : int (* the octal label's value *)
  ; sdi : int
  ; data : int (* bits 11 to 29, bit 11 lowest *)
  ; ssm : int
  }
[@@deriving sexp_of, equal, compare]

(* Send [words] with CLKDIV [clkdiv], the host keeping the FIFO fed, or
   from [late_at] not at all for [late_for] cycles. HI and LO, cycle by
   cycle, from the start. *)
let run ?(source = Firmware.arinc429_tx) ?late_at ?(late_for = 0) ~clkdiv words =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ { Firmware.arinc429_config with clkdiv } ]
  in
  let pending =
    Queue.of_list
      (List.concat_map words ~f:(fun w -> Firmware.arinc429_words ~label:w.label ~sdi:w.sdi ~data:w.data ~ssm:w.ssm))
  in
  let bit = 20 * max 1 clkdiv in
  let lines = Queue.create () in
  for cycle = 1 to ((List.length words + 2) * 40 * bit) + late_for do
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

(* A receiver. [bit] is the bit time in cycles. A word starts where the
   line leaves NULL after a rest; each of its 32 bits must start exactly a
   bit time after the one before, be HI or LO (never both) for exactly half
   of it and NULL for the rest. Returns the words and the rests between
   them, in bit times, or what was wrong. *)
module Receiver = struct
  let read ~bit (lines : (int * int) array) =
    let n = Array.length lines in
    let null t = [%equal: int * int] lines.(t) (0, 0) in
    let words = ref [] in
    let rests = ref [] in
    let error = ref None in
    let fail fmt = ksprintf (fun s -> if Option.is_none !error then error := Some s) fmt in
    (* The pins are high from reset until the program first writes them. *)
    let t = ref 0 in
    while !t < n && not (null !t) do
      incr t
    done;
    let last_end = ref None in
    while Option.is_none !error && !t < n do
      if null !t
      then incr t
      else (
        let start = !t in
        Option.iter !last_end ~f:(fun e ->
          let rest = start - e in
          if rest < 4 * bit then fail "a rest of %d cycles, under four bit times" rest;
          rests := rest :: !rests);
        if start + (32 * bit) > n
        then fail "a word cut short"
        else (
          let bits =
            List.init 32 ~f:(fun k ->
              let a = start + (k * bit) in
              let level = lines.(a) in
              let first_half_ok =
                List.for_all (List.range a (a + (bit / 2))) ~f:(fun u -> [%equal: int * int] lines.(u) level)
              in
              let second_half_ok = List.for_all (List.range (a + (bit / 2)) (a + bit)) ~f:null in
              if not (first_half_ok && second_half_ok) then fail "bit %d is not half a bit at HI or LO, then NULL" (k + 1);
              match level with
              | 1, 0 -> 1
              | 0, 1 -> 0
              | _ ->
                fail "bit %d is neither HI nor LO" (k + 1);
                0)
          in
          let field lo len = List.foldi (List.sub bits ~pos:lo ~len) ~init:0 ~f:(fun k acc b -> acc lor (b lsl k)) in
          let label = List.fold (List.take bits 8) ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b) in
          if List.sum (module Int) bits ~f:Fn.id % 2 <> 1 then fail "parity: the ones are even";
          words := { label; sdi = field 8 2; data = field 10 19; ssm = field 29 2 } :: !words;
          last_end := Some (start + (32 * bit));
          t := start + (32 * bit)))
    done;
    match !error with
    | Some e -> Error e
    | None -> Ok (List.rev !words, List.rev_map !rests ~f:(fun r -> Float.of_int r /. Float.of_int bit))
  ;;
end

let example =
  [ { label = 0o205; sdi = 1; data = 0x12345; ssm = 3 }
  ; { label = 0o310; sdi = 2; data = 0x7FFFF; ssm = 0 }
  ; { label = 0o001; sdi = 0; data = 0x00001; ssm = 2 }
  ; { label = 0o377; sdi = 3; data = 0x40000; ssm = 1 }
  ]
;;

let show r = print_s [%sexp (r : (word list * float list, string) Result.t)]

let%expect_test "four words at 100 kbit/s: as sent, every bit exact, rests of four bit times" =
  show (Receiver.read ~bit:100 (run ~clkdiv:5 example));
  [%expect {|
    (Ok
     ((((label 133) (sdi 1) (data 74565) (ssm 3))
       ((label 200) (sdi 2) (data 524287) (ssm 0))
       ((label 1) (sdi 0) (data 1) (ssm 2))
       ((label 255) (sdi 3) (data 262144) (ssm 1)))
      (4 4 4)))
    |}]
;;

let%expect_test "12.5 kbit/s: CLKDIV 40 at 10 MHz" =
  show (Receiver.read ~bit:800 (run ~clkdiv:40 (List.take example 2)));
  [%expect {|
    (Ok
     ((((label 133) (sdi 1) (data 74565) (ssm 3))
       ((label 200) (sdi 2) (data 524287) (ssm 0)))
      (4)))
    |}]
;;

let%expect_test "the first bits of label 205: 1, 0, 0, 0, 0, 1, 0, 1, as the standard sends it" =
  let lines = run ~clkdiv:1 (List.take example 1) in
  let null l = [%equal: int * int] l (0, 0) in
  (* The pins are high from reset until the program first writes them. *)
  let rest, _ = Array.findi_exn lines ~f:(fun _ l -> null l) in
  let at, _ = Array.findi_exn lines ~f:(fun t l -> t > rest && not (null l)) in
  print_s [%sexp (List.init 8 ~f:(fun k -> fst lines.(at + (20 * k)))  : int list)];
  [%expect {| (1 0 0 0 0 1 0 1) |}]
;;

let%expect_test "a host that is late: the rest grows, the words are still right" =
  show (Receiver.read ~bit:20 (run ~clkdiv:1 ~late_at:300 ~late_for:2000 example));
  [%expect {|
    (Ok
     ((((label 133) (sdi 1) (data 74565) (ssm 3))
       ((label 200) (sdi 2) (data 524287) (ssm 0))
       ((label 1) (sdi 0) (data 1) (ssm 2))
       ((label 255) (sdi 3) (data 262144) (ssm 1)))
      (4 4 10.9)))
    |}]
;;

let word_gen =
  let open Quickcheck.Generator.Let_syntax in
  let%map label = Int.gen_incl 0 255
  and sdi = Int.gen_incl 0 3
  and data = Int.gen_incl 0 0x7FFFF
  and ssm = Int.gen_incl 0 3 in
  { label; sdi; data; ssm }
;;

let%test_unit "random words at random dividers: read back, rests of four bit times" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2 (List.gen_with_length 3 word_gen) (Int.gen_incl 1 6))
    ~trials:60
    ~sexp_of:[%sexp_of: word list * int]
    ~f:(fun (words, clkdiv) ->
      [%test_result: (word list * float list, string) Result.t]
        (Receiver.read ~bit:(20 * clkdiv) (run ~clkdiv words))
        ~expect:(Ok (words, [ 4.; 4. ])))
;;

let%expect_test "planted bugs" =
  let words = example in
  let right = Ok (words, [ 4.; 4.; 4. ]) in
  let caught source =
    not ([%equal: (word list * float list, string) Result.t] (Receiver.read ~bit:20 (run ~source ~clkdiv:1 words)) right)
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.arinc429_tx ~pattern ~with_ in
    assert (not (String.equal s Firmware.arinc429_tx));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.arinc429_tx then "WRONG" else "right");
  List.iter
    [ "the label not turned round", fw ~pattern:"in x, 1                 ; into" ~with_:"in null, 1              ; into"
    ; "the label sent from bit 1 of it", fw ~pattern:"set y, 7" ~with_:"set y, 6"
    ; "the parity even", fw ~pattern:"jmp !x pone " ~with_:"jmp x-- pone"
    ; "the parity over the turning as well", fw ~pattern:"mov crc, null " ~with_:"nop           "
    ; "SDI and bits 11 to 16 lost", fw ~pattern:"in y, 8 " ~with_:"in null, 8"
    ; "word 2 not loaded", fw ~pattern:"mov osr, isr            ; after" ~with_:"nop                     ; after"
    ; "32 bits and the parity", fw ~pattern:"set y, 30" ~with_:"set y, 31"
    ; "a 1 sent on LO", fw ~pattern:"set pins, 1 [8]         ; a 1" ~with_:"set pins, 2 [8]         ; a 1"
    ; "HI a tick long", fw ~pattern:"set pins, 1 [8]         ; a 1" ~with_:"set pins, 1 [9]         ; a 1"
    ; "NULL a tick short", fw ~pattern:"set pins, 0 [4]" ~with_:"set pins, 0 [3]"
    ; "a rest of three bit times", fw ~pattern:"nop [15]\n        nop [15]" ~with_:"nop [15]"
    ; "the line left at the parity bit", fw ~pattern:"set pins, 0 [15]" ~with_:"nop [15]        "
    ]
    ~f:(fun (name, source) -> printf "%-36s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the label not turned round           caught
    the label sent from bit 1 of it      caught
    the parity even                      caught
    the parity over the turning as well  caught
    SDI and bits 11 to 16 lost           caught
    word 2 not loaded                    caught
    32 bits and the parity               caught
    a 1 sent on LO                       caught
    HI a tick long                       caught
    NULL a tick short                    caught
    a rest of three bit times            caught
    the line left at the parity bit      caught
    |}]
;;
