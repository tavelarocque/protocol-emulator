(* The LTC sender ([Firmware.ltc]) against a reader written here from SMPTE
   12M's linear timecode: biphase mark code (an edge at every bit boundary,
   and one more in the middle of a 1), every edge on the half-bit grid
   counted from the first, the sync word 0011 1111 1111 1101 after each
   frame's 64 bits, the time read from its BCD fields and the user bits
   from theirs, and the polarity correction bit checked the way the
   standard states its purpose: every frame's 80 bits hold an even number
   of 1s, so every frame starts at the same level. The cocotb test runs
   the same firmware on the RTL and the gate netlist, read by sigrok's LTC
   decoder from an unmerged pull request. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

type frame =
  { time : int * int * int * int
  ; user : int list
  ; colour : bool
  ; ones_even : bool
  }
[@@deriving sexp_of, equal, compare]

let sync = [ 0; 0; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 1; 0; 1 ]

(* The bits on [line] (one level per clock) at [half] clocks a half bit, or
   an error. *)
let bits ~half (line : bool array) =
  let n = Array.length line in
  let edges = List.filter (List.range 1 n) ~f:(fun t -> Bool.( <> ) line.(t) line.(t - 1)) in
  match edges with
  | [] -> Ok []
  | e0 :: _ ->
    (match List.find edges ~f:(fun e -> (e - e0) % half <> 0) with
     | Some e -> Error (sprintf "an edge %d clocks off the half bits" ((e - e0) % half))
     | None ->
       let at = Hash_set.of_list (module Int) (List.map edges ~f:(fun e -> (e - e0) / half)) in
       let last = (List.last_exn edges - e0) / half in
       let rec go h acc =
         if h >= last
         then Ok (List.rev acc)
         else if Hash_set.mem at (h + 1)
         then if Hash_set.mem at (h + 2) then go (h + 2) (1 :: acc) else Error (sprintf "half bit %d" h)
         else if Hash_set.mem at (h + 2)
         then go (h + 2) (0 :: acc)
         else Error (sprintf "no edge after half bit %d" h)
       in
       go 0 [])
;;

let field bits ~pos ~len = List.foldi (List.sub bits ~pos ~len) ~init:0 ~f:(fun k a b -> a lor (b lsl k))

(* The frames: the 64 bits before each sync word. *)
let frames bits =
  let a = Array.of_list bits in
  List.filter_map (List.range 64 (Array.length a - 15)) ~f:(fun i ->
    if List.equal Int.equal (Array.to_list (Array.sub a ~pos:i ~len:16)) sync
    then (
      let f = Array.to_list (Array.sub a ~pos:(i - 64) ~len:80) in
      let bcd units tens tens_len = field f ~pos:units ~len:4 + (10 * field f ~pos:tens ~len:tens_len) in
      Some
        { time = bcd 48 56 2, bcd 32 40 3, bcd 16 24 3, bcd 0 8 2
        ; user = List.init 8 ~f:(fun k -> field f ~pos:(4 + (8 * k)) ~len:4)
        ; colour = List.nth_exn f 11 = 1
        ; ones_even = List.count f ~f:(fun b -> b = 1) % 2 = 0
        })
    else None)
;;

(* The chip sending [frames_] (each the host's four words), at [clkdiv]
   clocks a tick. *)
let run ?(source = Firmware.ltc) ?(clkdiv = 1) words =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.ltc_config ~clkdiv ]
  in
  let pending = Queue.of_list (List.concat words) in
  let total = ((List.length words * 80) + 4) * 200 * clkdiv in
  let line = Array.create ~len:total false in
  for t = 0 to total - 1 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0;
    line.(t) <- Isa.lines m ~inputs:0 land 1 = 1
  done;
  Result.map (bits ~half:(100 * clkdiv) line) ~f:frames
;;

let words ?user ?colour (h, mi, s, f) = Firmware.ltc_words ?user ?colour ~hours:h ~minutes:mi ~seconds:s ~frames:f ()
let user = [ 1; 2; 3; 4; 0xA; 0xB; 0xC; 0xD ]
let times = [ 23, 59, 59, 22; 23, 59, 59, 23; 23, 59, 59, 24 ]
let session = List.map times ~f:(words ~user)
let expect ?(user = user) ?(colour = false) times = Ok (List.map times ~f:(fun time -> { time; user; colour; ones_even = true }))

let%test_unit "program: 79 words" = [%test_result: int] (Array.length (Asm.assemble Firmware.ltc)) ~expect:79

let%expect_test "three frames, at 25 frames a second with a 10 MHz clock" =
  let r = run ~clkdiv:25 session in
  [%test_result: (frame list, string) Result.t] r ~expect:(expect times);
  print_s [%sexp (r : (frame list, string) Result.t)];
  [%expect {|
    (Ok
     (((time (23 59 59 22)) (user (1 2 3 4 10 11 12 13)) (colour false)
       (ones_even true))
      ((time (23 59 59 23)) (user (1 2 3 4 10 11 12 13)) (colour false)
       (ones_even true))
      ((time (23 59 59 24)) (user (1 2 3 4 10 11 12 13)) (colour false)
       (ones_even true))))
    |}]
;;

let%test_unit "random times, user bits and host polarity bits" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Quickcheck.Generator.list_with_length 4 (Int.gen_incl 0 1000))
       (Quickcheck.Generator.list_with_length 8 (Int.gen_incl 0 15))
       Bool.quickcheck_generator
       Bool.quickcheck_generator)
    ~trials:25
    ~sexp_of:[%sexp_of: int list * int list * bool * bool]
    ~f:(fun (r, user, colour, host_bit) ->
      let time = List.nth_exn r 0 % 24, List.nth_exn r 1 % 60, List.nth_exn r 2 % 60, List.nth_exn r 3 % 25 in
      let w = words ~user ~colour time in
      let w = if host_bit then List.mapi w ~f:(fun i v -> if i = 3 then v lor 0x800 else v) else w in
      [%test_result: (frame list, string) Result.t] (run [ w; w ]) ~expect:(expect ~user ~colour [ time; time ]))
;;

let%expect_test "planted bugs" =
  let good = Firmware.ltc in
  let caught source = not ([%equal: (frame list, string) Result.t] (run ~source session) (expect times)) in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first good ~pattern ~with_ in
    assert (not (String.equal s good));
    s
  in
  printf "the program as it is: %s\n" (if caught good then "WRONG" else "right");
  List.iter
    [ "a 1 without its middle edge", fw ~pattern:"mid:    mov pins, y" ~with_:"mid:    nop        "
    ; "a 1's middle edge a tick late", fw ~pattern:"set x, 22 [1]" ~with_:"set x, 22 [2]"
    ; "the sync word one 1 short", fw ~pattern:"in x, 2                 ; 117" ~with_:"in x, 1                 ; 117"
    ; "the polarity bit always 0", fw ~pattern:"in x, 1                 ; 155" ~with_:"in null, 1              ; 155"
    ; "bit 48 counted once", fw ~pattern:"out null, 1             ; 114" ~with_:"nop                     ; 114"
    ; "bits 60 to 63 left out of the parity", fw ~pattern:"set x, 15               ; 116" ~with_:"set x, 11               ; 116"
    ; "the parity not restarted", fw ~pattern:"frame:  mov crc, null" ~with_:"frame:  nop          "
    ; "the fourth word sent as it came", fw ~pattern:"mov osr, isr            ; 158" ~with_:"nop                     ; 158"
    ; "the words counted from four", fw ~pattern:"set x, 5                ; 109" ~with_:"set x, 4                ; 109"
    ]
    ~f:(fun (name, source) -> printf "%-42s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    a 1 without its middle edge                caught
    a 1's middle edge a tick late              caught
    the sync word one 1 short                  caught
    the polarity bit always 0                  caught
    bit 48 counted once                        caught
    bits 60 to 63 left out of the parity       caught
    the parity not restarted                   caught
    the fourth word sent as it came            caught
    the words counted from four                caught
    |}]
;;
