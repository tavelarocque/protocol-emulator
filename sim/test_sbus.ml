(* The SBUS transmitter ([Firmware.sbus_tx]) against an SBUS input written
   here from the protocol's rules, as a flight controller has one: the
   line inverted, 100 kbit/s, 8 data bits, even parity, two stop bits, a
   message of 25 bytes between rests. The cocotb test runs the same
   firmware on the RTL and the gate netlist with sigrok's SBUS decoder, on
   its UART decoder, reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* Send [bytes] at [bit_time] cycles a bit, the host keeping the FIFO fed,
   or from [late_at] not at all for [late_for] cycles. The line, cycle by
   cycle, from where the program first puts it low (a pin is high from
   reset until then). *)
let run ?(source = Firmware.sbus_tx) ?late_at ?(late_for = 0) ~bit_time bytes =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.sbus_tx_config ]
  in
  let pending = Queue.of_list (Firmware.sbus_tx_words ~bit_time bytes) in
  let line = Queue.create () in
  for cycle = 1 to ((List.length bytes + 4) * 12 * bit_time) + late_for do
    let late = match late_at with Some at -> cycle >= at && cycle < at + late_for | None -> false in
    (match Queue.peek pending with
     | Some v when not late -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | _ -> ());
    Isa.step m ~inputs:0xFF;
    Queue.enqueue line (Isa.lines m ~inputs:0xFF land 1)
  done;
  List.drop_while (Queue.to_list line) ~f:(fun l -> l = 1) |> Array.of_list
;;

(* An SBUS input. A character begins where the line rises from rest. Each
   of its 12 bits is read in the middle and turned over: a start bit 0,
   8 data bits least significant first, a parity bit that makes the number
   of ones even, two stop bits 1. A rest of more than a character's length
   ends a message. *)
module Receiver = struct
  type message =
    { channels : int list
    ; ch17 : bool
    ; ch18 : bool
    ; frame_lost : bool
    ; failsafe : bool
    }
  [@@deriving sexp_of, equal, compare]

  (* (cycle the start bit began, byte), or what was wrong with a character. *)
  let characters ~bit_time (line : int array) =
    let n = Array.length line in
    let out = ref [] in
    let error = ref None in
    let t = ref 1 in
    while Option.is_none !error && !t < n do
      if line.(!t - 1) = 0 && line.(!t) = 1
      then (
        let start = !t in
        if start + (12 * bit_time) > n
        then error := Some "a character cut short"
        else (
          let bit k = 1 - line.(start + (k * bit_time) + (bit_time / 2)) in
          let data = List.init 8 ~f:(fun k -> bit (1 + k)) in
          if bit 0 <> 0
          then error := Some "no start bit"
          else if (List.sum (module Int) data ~f:Fn.id + bit 9) % 2 <> 0
          then error := Some "parity"
          else if bit 10 <> 1 || bit 11 <> 1
          then error := Some "a stop bit missing"
          else (
            out := (start, List.foldi data ~init:0 ~f:(fun k acc b -> acc lor (b lsl k))) :: !out;
            (* Look for the next start bit from the middle of the last
               stop bit on. *)
            t := start + (11 * bit_time) + (bit_time / 2))))
      else incr t
    done;
    match !error with
    | Some e -> Error e
    | None -> Ok (List.rev !out)
  ;;

  let message bytes =
    match bytes with
    | 0x0F :: rest when List.length rest = 24 && List.last_exn rest = 0x00 ->
      let bits = List.concat_map (List.take rest 22) ~f:(fun b -> List.init 8 ~f:(fun k -> (b lsr k) land 1)) in
      let channels =
        List.chunks_of bits ~length:11
        |> List.map ~f:(fun ch -> List.foldi ch ~init:0 ~f:(fun k acc b -> acc lor (b lsl k)))
      in
      let flags = List.nth_exn rest 22 in
      let flag k = (flags lsr k) land 1 = 1 in
      Ok { channels; ch17 = flag 0; ch18 = flag 1; frame_lost = flag 2; failsafe = flag 3 }
    | _ -> Error (sprintf "not a message: %d bytes" (List.length bytes))
  ;;

  let messages ~bit_time line =
    let%bind.Result chars = characters ~bit_time line in
    List.group chars ~break:(fun (a, _) (b, _) -> b - a > 24 * bit_time)
    |> List.map ~f:(fun group -> message (List.map group ~f:snd))
    |> Result.all
  ;;
end

(* Cycles from the first start bit to every later change of the line. *)
let edges (line : int array) =
  let changes = List.filter (List.range 1 (Array.length line)) ~f:(fun t -> line.(t) <> line.(t - 1)) in
  match changes with
  | [] -> []
  | first :: rest -> List.map rest ~f:(fun t -> t - first)
;;

let example : Receiver.message =
  { channels = [ 992; 1500; 172; 992; 1811; 172; 992; 992; 1200; 800; 0; 2047; 1; 1024; 1365; 682 ]
  ; ch17 = true
  ; ch18 = false
  ; frame_lost = false
  ; failsafe = true
  }
;;

let bytes_of (m : Receiver.message) =
  Firmware.sbus_message
    ~channels:m.channels
    ~ch17:m.ch17
    ~ch18:m.ch18
    ~frame_lost:m.frame_lost
    ~failsafe:m.failsafe
;;

let%expect_test "one message: every channel and flag, 3 ms, every edge on a bit boundary" =
  let bit_time = 100 in
  let line = run ~bit_time (bytes_of example) in
  printf !"%{sexp:(Receiver.message list, string) Result.t}\n" (Receiver.messages ~bit_time line);
  let e = edges line in
  printf "edges off a bit boundary: %d\n" (List.count e ~f:(fun t -> t % bit_time <> 0));
  (* The last change is the fall into the footer's stop bits, two bits
     before the message's end. *)
  printf "the message lasts %d cycles\n" (List.last_exn e + (2 * bit_time));
  printf "the line rests %s before and after\n" (if line.(0) = 0 && line.(Array.length line - 1) = 0 then "low" else "HIGH");
  (* The header 0x0F: start high, four ones sent low, four zeros and the
     parity 0 sent high, two stop bits low. *)
  printf !"%{sexp:int list}\n" (List.take e 3);
  [%expect {|
    (Ok
     (((channels
        (992 1500 172 992 1811 172 992 992 1200 800 0 2047 1 1024 1365 682))
       (ch17 true) (ch18 false) (frame_lost false) (failsafe true))))
    edges off a bit boundary: 0
    the message lasts 30000 cycles
    the line rests low before and after
    (100 500 1000)
    |}]
;;

let%expect_test "a host that is late: the line rests, and the bytes still arrive" =
  let bit_time = 20 in
  let bytes = bytes_of example in
  let line = run ~bit_time ~late_at:1000 ~late_for:2000 bytes in
  let chars = Receiver.characters ~bit_time line |> Result.ok_or_failwith in
  printf "the bytes as sent: %b\n" ([%equal: int list] (List.map chars ~f:snd) bytes);
  let gaps = List.map2_exn (List.drop_last_exn chars) (List.tl_exn chars) ~f:(fun (a, _) (b, _) -> b - a) in
  printf !"cycles from one start bit to the next: %{sexp:int list}\n" (List.dedup_and_sort gaps ~compare:Int.compare);
  [%expect {|
    the bytes as sent: true
    cycles from one start bit to the next: (240 1076)
    |}]
;;

let message_gen =
  let open Quickcheck.Generator.Let_syntax in
  let%map channels = List.gen_with_length 16 (Int.gen_incl 0 2047)
  and ch17 = Bool.quickcheck_generator
  and ch18 = Bool.quickcheck_generator
  and frame_lost = Bool.quickcheck_generator
  and failsafe = Bool.quickcheck_generator in
  { Receiver.channels; ch17; ch18; frame_lost; failsafe }
;;

let%test_unit "random messages at random bit times: read back, every bit exact" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2 message_gen (Int.gen_incl 6 120))
    ~trials:60
    ~sexp_of:[%sexp_of: Receiver.message * int]
    ~f:(fun (m, bit_time) ->
      let line = run ~bit_time (bytes_of m) in
      [%test_result: (Receiver.message list, string) Result.t] (Receiver.messages ~bit_time line) ~expect:(Ok [ m ]);
      let e = edges line in
      [%test_result: int] (List.count e ~f:(fun t -> t % bit_time <> 0)) ~expect:0;
      [%test_result: bool] (List.last_exn e <= 298 * bit_time) ~expect:true)
;;

let%test_unit "any bytes, not only messages: each character as sent" =
  Quickcheck.test
    (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
    ~trials:60
    ~sexp_of:[%sexp_of: int list]
    ~f:(fun bytes ->
      let bytes = List.take bytes 12 in
      let line = run ~bit_time:10 bytes in
      [%test_result: (int list, string) Result.t]
        (Result.map (Receiver.characters ~bit_time:10 line) ~f:(List.map ~f:snd))
        ~expect:(Ok bytes))
;;

let%expect_test "planted bugs" =
  let bit_time = 30 in
  let bytes = bytes_of example in
  let right = edges (run ~bit_time bytes) in
  let caught source =
    let line = run ~source ~bit_time bytes in
    not
      ([%equal: (Receiver.message list, string) Result.t] (Receiver.messages ~bit_time line) (Ok [ example ])
       && line.(0) = 0
       && [%equal: int list] (edges line) right
       && List.for_all right ~f:(fun t -> t % bit_time = 0))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.sbus_tx ~pattern ~with_ in
    assert (not (String.equal s Firmware.sbus_tx));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.sbus_tx then "WRONG" else "right");
  List.iter
    [ "the line resting high", fw ~pattern:"set pins, 0         ; the line rests low" ~with_:"set pins, 1"
    ; "the start bit low", fw ~pattern:"set pins, 1 [1]" ~with_:"set pins, 0 [1]"
    ; "the data bits not inverted", fw ~pattern:"jmp x-- inv " ~with_:"nop         "
    ; "the parity never started again", fw ~pattern:"mov crc, null " ~with_:"nop           "
    ; "no parity bit: a data bit held", fw ~pattern:"mov x, crc [1]" ~with_:"nop [1]       "
    ; "the parity bit always low", fw ~pattern:"mov x, crc [1]" ~with_:"mov x, null [1]"
    ; "the stop bits high", fw ~pattern:"set pins, 0 [5]" ~with_:"set pins, 1 [5]"
    ; "one stop bit", fw ~pattern:"stop:   jmp x-- stop [1]" ~with_:"stop:   jmp x-- stop"
    ; "the start bit a cycle short", fw ~pattern:"set pins, 1 [1]" ~with_:"set pins, 1    "
    ; "the parity bit a cycle short", fw ~pattern:"mov x, y [3]" ~with_:"mov x, y [2]"
    ; "the last data bit a cycle short", fw ~pattern:"mov x, crc [1]" ~with_:"mov x, crc    "
    ; "the stop bits a cycle short", fw ~pattern:"set pins, 0 [5]" ~with_:"set pins, 0 [4]"
    ]
    ~f:(fun (name, source) -> printf "%-36s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the line resting high                caught
    the start bit low                    caught
    the data bits not inverted           caught
    the parity never started again       caught
    no parity bit: a data bit held       caught
    the parity bit always low            caught
    the stop bits high                   caught
    one stop bit                         caught
    the start bit a cycle short          caught
    the parity bit a cycle short         caught
    the last data bit a cycle short      caught
    the stop bits a cycle short          caught
    |}]
;;
