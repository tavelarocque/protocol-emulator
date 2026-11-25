(* The KNX TP1 sender ([Firmware.knx_tx]) against a bus written here from
   the KNX TP1 rules: a bit is 104 us; a logical 0 is the bus pulled low
   for 35 us at the start of its bit, a logical 1 no pulse; a character is
   a start bit (0), 8 data bits least significant first, an even parity
   bit and a stop bit (1); the characters of a telegram start 13 bit times
   apart; the last byte of a telegram is the checksum, the exclusive or of
   the others inverted, and the length field (the low four bits of the
   sixth byte) gives the bytes between it and the checksum less one. Every
   pulse must start exactly on a bit time and last exactly 35 us. A device
   on the same bus acknowledges a good telegram as KNX's receivers do: a
   character 0xCC, 15 bit times after the telegram's last stop bit. The
   cocotb test runs the same firmware on the RTL and the gate netlist,
   judged by two KNX decoders for sigrok written by others. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let bit_us = 104
let pulse_us = 35

type seen =
  | Telegram of int list
  | Bad of string
[@@deriving sexp_of, equal, compare]

(* The characters on [line] (one level per clock, [us] clocks a
   microsecond): (start, byte) or an error. *)
let characters ~us (line : bool array) =
  let n = Array.length line in
  let bit = bit_us * us
  and pulse = pulse_us * us in
  let low t = t < n && not line.(t) in
  let rec scan t acc =
    if t >= n
    then List.rev acc
    else if low t && (t = 0 || not (low (t - 1)))
    then (
      (* A start bit. Each of the 11 bits is a pulse of exactly [pulse]
         from its start, or no low at all. *)
      let bits =
        List.init 11 ~f:(fun k ->
          let s = t + (k * bit) in
          let lows = List.filter (List.range s (s + bit)) ~f:low in
          if List.is_empty lows
          then Ok 1
          else if List.equal Int.equal lows (List.range s (s + pulse))
          then Ok 0
          else Error (sprintf "bit %d of the character at %d: low at %d..%d" k t (List.hd_exn lows) (List.last_exn lows)))
      in
      match Result.all bits with
      | Error e -> scan (t + (11 * bit)) ((t, Error e) :: acc)
      | Ok bits ->
        let b = Array.of_list bits in
        let byte = List.foldi (List.init 8 ~f:(fun k -> b.(k + 1))) ~init:0 ~f:(fun k a v -> a lor (v lsl k)) in
        let ones = List.count (List.init 9 ~f:(fun k -> b.(k + 1))) ~f:(fun v -> v = 1) in
        let result =
          if b.(0) <> 0
          then Error "start bit"
          else if ones % 2 <> 0
          then Error (sprintf "parity of %02x" byte)
          else if b.(10) <> 1
          then Error "stop bit"
          else Ok byte
        in
        scan (t + (11 * bit)) ((t, result) :: acc))
    else scan (t + 1) acc
  in
  scan 0 []
;;

let checksum bytes = lnot (List.fold bytes ~init:0 ~f:( lxor )) land 0xFF

(* Characters grouped into telegrams: a character 13 bit times after the
   one before belongs to its telegram. A group of one is an
   acknowledgement, and is shown as such. *)
let telegrams ~us line =
  let chars = characters ~us line in
  let rec group acc cur last = function
    | [] -> List.rev (if List.is_empty cur then acc else List.rev cur :: acc)
    | (t, c) :: rest ->
      if Option.value_map last ~default:false ~f:(fun l -> t - l = 13 * bit_us * us)
      then group acc (c :: cur) (Some t) rest
      else group (if List.is_empty cur then acc else List.rev cur :: acc) [ c ] (Some t) rest
  in
  group [] [] None chars
  |> List.map ~f:(fun cs ->
    match Result.all cs with
    | Error e -> Bad e
    | Ok [ ack ] -> Telegram [ ack ]
    | Ok bytes ->
      let body = List.drop_last_exn bytes in
      if List.length body < 7
      then Bad "too short"
      else if List.last_exn bytes <> checksum body
      then Bad (sprintf "checksum %02x, want %02x" (List.last_exn bytes) (checksum body))
      else if List.nth_exn body 5 land 0xF <> List.length body - 7
      then Bad "length"
      else Telegram bytes)
;;

(* The bus with the chip and, if [ack], a device that acknowledges each
   good telegram. [us] clocks a microsecond (the thread's CLKDIV). Returns
   what is on the bus and the words the chip pushed. *)
let run ?(source = Firmware.knx_tx) ?(us = 1) ?(ack = true) ?(timeout = 2000) telegrams_ =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Open_drain else Input))
      ~threads:[ { (Firmware.knx_tx_config ~clkdiv:us ~timeout) with timeout_vector = Asm.label source "noack" } ]
  in
  let pending = Queue.of_list (List.concat_map telegrams_ ~f:Firmware.knx_words) in
  let bit = bit_us * us in
  let total = List.sum (module Int) telegrams_ ~f:(fun t -> ((List.length t + 1) * 13 * bit) + (80 * bit)) in
  let line = Array.create ~len:total true in
  let device_low = Array.create ~len:total false in
  let pushed = Queue.create () in
  (* The device: after each character it looks for the next one 13 bit
     times later; if none starts, the telegram has ended, and if it is
     good the device sends 0xCC 15 bit times after its last stop bit. *)
  let last_start = ref None in
  let in_char_until = ref (-1) in
  let ack_char = [ 0 ] @ List.init 8 ~f:(fun k -> (0xCC lsr k) land 1) @ [ 0; 1 ] in
  for t = 0 to total - 1 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    let ext = if device_low.(t) then 0 else 1 in
    Isa.step m ~inputs:ext;
    line.(t) <- Isa.lines m ~inputs:ext land 1 = 1;
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue pushed);
    if (not line.(t)) && t > 0 && line.(t - 1) && t > !in_char_until
    then (
      last_start := Some t;
      in_char_until := t + (11 * bit));
    match !last_start with
    | Some last when ack && t = last + (13 * bit) + 1 ->
      (match List.last (telegrams ~us (Array.sub line ~pos:0 ~len:(t + 1))) with
       | Some (Telegram bytes) when List.length bytes > 1 ->
         let first = last + (11 * bit) + (15 * bit) in
         List.iteri ack_char ~f:(fun k v ->
           if v = 0
           then
             for c = first + (k * bit) to first + (k * bit) + (pulse_us * us) - 1 do
               if c < total then device_low.(c) <- true
             done)
       | _ -> ())
    | _ -> ()
  done;
  telegrams ~us line, Queue.to_list pushed
;;

(* A light switched on: a GroupValueWrite of 1 from 1.1.1 to the group
   1/2/3 (0x0A03 in three-level form), normal priority, hop count 6. *)
let switch_on = [ 0xBC; 0x11; 0x01; 0x0A; 0x03; 0xE1; 0x00; 0x81 ]
let switch_off = [ 0xBC; 0x11; 0x01; 0x0A; 0x03; 0xE1; 0x00; 0x80 ]
let with_checksum t = t @ [ checksum t ]

let%test_unit "the driver's KNX_NOACK" = [%test_result: int] Firmware.knx_noack ~expect:56

let%test_unit "program: 63 words" = [%test_result: int] (Array.length (Asm.assemble Firmware.knx_tx)) ~expect:63

let%expect_test "a light switched on and off, each acknowledged" =
  let seen, pushed = run [ switch_on; switch_off ] in
  List.iter seen ~f:(fun s -> print_s [%sexp (s : seen)]);
  print_s [%sexp (List.map pushed ~f:(sprintf "0x%03x") : string list)];
  [%expect
    {|
    (Telegram (188 17 1 10 3 225 0 129 58))
    (Telegram (204))
    (Telegram (188 17 1 10 3 225 0 128 59))
    (Telegram (204))
    (0x2cc 0x2cc)
    |}]
;;

let%expect_test "nobody answers: the host gets 0" =
  let seen, pushed = run ~ack:false [ switch_on ] in
  List.iter seen ~f:(fun s -> print_s [%sexp (s : seen)]);
  print_s [%sexp (pushed : int list)];
  [%expect {|
    (Telegram (188 17 1 10 3 225 0 129 58))
    (0)
    |}]
;;

let expect ts = List.concat_map ts ~f:(fun t -> [ Telegram (with_checksum t); Telegram [ 0xCC ] ]), List.map ts ~f:(fun _ -> 0x2CC)

let%test_unit "random telegrams, 1 and 2 clocks a microsecond" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 0 15)
       (Quickcheck.Generator.list_with_length 22 (Int.gen_incl 0 255))
       (Int.gen_incl 1 2))
    ~trials:25
    ~sexp_of:[%sexp_of: int * int list * int]
    ~f:(fun (len, bytes, us) ->
      let t = List.take bytes 5 @ [ 0xE0 lor len ] @ List.take (List.drop bytes 6) (len + 1) in
      [%test_result: seen list * int list] (run ~us [ t ]) ~expect:(expect [ t ]))
;;

let%expect_test "planted bugs" =
  let good = Firmware.knx_tx in
  let session = [ switch_on; switch_off ] in
  let caught source = not ([%equal: seen list * int list] (run ~source session) (expect session)) in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first good ~pattern ~with_ in
    assert (not (String.equal s good));
    s
  in
  printf "the program as it is: %s\n" (if caught good then "WRONG" else "right");
  List.iter
    [ "the start bit's pulse 34 us", fw ~pattern:"nop [1]                 ; 33..34\n        set pins, 1             ; 35: released" ~with_:"nop                     ; 33..34\n        set pins, 1             ; 35: released"
    ; "a data bit's pulse 34 us", fw ~pattern:"nop [15]                ; 19..34" ~with_:"nop [14]                ; 19..34"
    ; "odd parity", fw ~pattern:"set y, 0                ; -1" ~with_:"set y, 1                ; -1"
    ; "the parity bit from X", fw ~pattern:"mov pins, y             ; 0: the parity bit" ~with_:"mov pins, x             ; 0: the parity bit"
    ; "the gap a microsecond short", fw ~pattern:"nop [5]                 ; 408..413" ~with_:"nop [4]                 ; 408..413"
    ; "no checksum", fw ~pattern:"jmp !x cks              ; 39" ~with_:"jmp ack                 ; 39"
    ; "the checksum not restarted", fw ~pattern:"next:   mov crc, null" ~with_:"next:   nop          "
    ; "the checksum's character from 0", fw ~pattern:"cks:    mov osr, crc" ~with_:"cks:    mov osr, null"
    ; "the acknowledgement's stop bit not read", fw ~pattern:"set y, 9                ; ten bits" ~with_:"set y, 8                ; ten bits"
    ; "the acknowledgement read a bit late", fw ~pattern:"set x, 6\naw:" ~with_:"set x, 13\naw:"
    ]
    ~f:(fun (name, source) -> printf "%-42s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the start bit's pulse 34 us                caught
    a data bit's pulse 34 us                   caught
    odd parity                                 caught
    the parity bit from X                      caught
    the gap a microsecond short                caught
    no checksum                                caught
    the checksum not restarted                 caught
    the checksum's character from 0            caught
    the acknowledgement's stop bit not read    caught
    the acknowledgement read a bit late        caught
    |}]
;;
