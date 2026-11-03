(* The low-speed USB engine ([Firmware.usb]) on the model chip, through a
   model of a USB 1.1 transceiver in VO/FSE0 mode, judged two ways:
   - the reference receiver ([Usb_model.Receiver], written from the USB 1.1
     spec) must decode every packet back to the bytes that were sent;
   - the waveform must equal the ideal one cycle for cycle: each line state
     exactly 8 clocks, the drivers on from the first bit of SYNC to the end
     of EOP's J and off otherwise. The receiver alone would forgive some
     timing faults (a bus idles at J, so drivers released one bit early
     look the same to it); this check does not.
   Receiving is judged against a device model whose clock is up to 1.5% off
   either way (the low-speed tolerance), from a random phase: the recorded
   levels must decode to the bytes sent, and in a whole IN transaction the
   engine's ACK must start 2 to 7.5 bit times after the data's EOP. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Usb = Pe_model.Usb_model

(* --- The encoder against known captures -------------------------------- *)

let%expect_test "tokens and CRCs match captured USB packets" =
  let hex l = List.map l ~f:(sprintf "%02X") |> String.concat ~sep:" " in
  print_endline (hex (Usb.token ~pid:Usb.Pid.setup ~addr:0 ~endp:0));
  print_endline (hex (Usb.token ~pid:Usb.Pid.in_ ~addr:0 ~endp:0));
  (* GET_DESCRIPTOR (device), 64 bytes, as every host sends it first. *)
  print_endline
    (hex (Usb.data ~pid:Usb.Pid.data0 [ 0x80; 0x06; 0x00; 0x01; 0x00; 0x00; 0x40; 0x00 ]));
  print_endline (hex (Usb.data ~pid:Usb.Pid.data1 []));
  [%expect
    {|
    2D 00 10
    69 00 10
    C3 80 06 00 01 00 00 40 00 DD 94
    4B 00 00
    |}]
;;

let%test_unit "CRC16 over a payload and its CRC leaves the fixed residual" =
  Quickcheck.test
    (Quickcheck.Generator.list (Int.gen_incl 0 255))
    ~trials:200
    ~sexp_of:[%sexp_of: int list]
    ~f:(fun payload ->
      let c = Usb.crc16 payload in
      [%test_result: int] (Usb.crc16 (payload @ [ c land 0xFF; c lsr 8 ])) ~expect:0x4FFE)
;;

let%test_unit "stuffing: never seven 1s in a row, and the receiver undoes it" =
  Quickcheck.test
    (Quickcheck.Generator.list (Int.gen_incl 0 255))
    ~trials:200
    ~sexp_of:[%sexp_of: int list]
    ~f:(fun payload ->
      let bytes = Usb.data ~pid:Usb.Pid.data0 (List.take payload 8) in
      let lines = Usb.packet_lines bytes in
      let wave = List.concat_map lines ~f:(fun l -> List.init 8 ~f:(Fn.const l)) in
      [%test_result: (int list, Usb.Receiver.error) Result.t]
        (Usb.Receiver.decode ~bit_cycles:8 (List.init 5 ~f:(Fn.const Usb.J) @ wave))
        ~expect:(Ok bytes))
;;

(* --- The firmware ------------------------------------------------------- *)

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    if i >= 2 && i <= 4 then Isa.Pin_mode.Push_pull else Input)
;;

(* The transceiver and the bus: with OE_N low the transceiver drives D+ and
   D- from VO and FSE0; otherwise the bus idles at J (the device's pull-up
   on D-). *)
let bus pins =
  let vo = pins land 0b100 <> 0
  and fse0 = pins land 0b1000 <> 0
  and oe_n = pins land 0b10000 <> 0 in
  if oe_n then false, Usb.J else true, if fse0 then Usb.Se0 else if vo then Usb.K else Usb.J
;;

let inputs line =
  (* VP on P0, VM on P1; the other inputs idle high. *)
  match (line : Usb.line) with
  | J -> 0xFE
  | K -> 0xFD
  | Se0 -> 0xFC
;;

type trace =
  { lines : Usb.line list (* the bus, once per clock *)
  ; driven : bool list (* transceiver drivers on *)
  }

(* Sends [packets] (each a list of bytes after SYNC) back to back, the host
   keeping the TX FIFO topped up, and records the bus. *)
let run ?(source = Firmware.usb) packets =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ Firmware.usb_config ~origin:0 ]
  in
  let pending =
    Queue.of_list
      (List.concat_map packets ~f:(fun bytes ->
         let lines = Usb.packet_lines bytes in
         Firmware.usb_send_words (List.take lines (List.length lines - 3))))
  in
  let total_bits =
    List.sum (module Int) packets ~f:(fun b -> List.length (Usb.packet_lines b))
  in
  let lines = Queue.create ()
  and driven = Queue.create ()
  and line = ref Usb.J in
  for _ = 1 to (total_bits * 8) + (List.length packets * 60) + 200 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:(inputs !line);
    let d, l = bus (Isa.pin_out m) in
    line := l;
    Queue.enqueue lines l;
    Queue.enqueue driven d
  done;
  { lines = Queue.to_list lines; driven = Queue.to_list driven }
;;

(* Splits a trace into its packets: each runs from a stretch of driving to
   the next release. *)
let packets_of trace =
  let rec go acc cur = function
    | [] -> List.rev (if List.is_empty cur then acc else List.rev cur :: acc)
    | (d, l) :: rest ->
      if d
      then go acc ((d, l) :: cur) rest
      else if List.is_empty cur
      then go acc [] rest
      else go (List.rev cur :: acc) [] rest
  in
  go [] [] (List.zip_exn trace.driven trace.lines)
;;

let ideal bytes = List.concat_map (Usb.packet_lines bytes) ~f:(fun l -> List.init 8 ~f:(Fn.const l))

(* Both checks for each packet; [None] if all pass. *)
let judge packets trace =
  let got = packets_of trace in
  (* Idle runs between driven stretches, after the first. *)
  let gaps =
    let rec go acc run seen = function
      | [] -> List.rev acc
      | d :: rest ->
        if d
        then go (if seen && run > 0 then run :: acc else acc) 0 true rest
        else go acc (run + 1) seen rest
    in
    go [] 0 false trace.driven
  in
  let short_gap = List.find gaps ~f:(fun g -> g < 16) in
  if Option.is_some short_gap
  then Some (sprintf "only %d idle clocks between packets" (Option.value_exn short_gap))
  else
  if List.length got <> List.length packets
  then Some (sprintf "%d packets driven, %d sent" (List.length got) (List.length packets))
  else
    List.find_map (List.zip_exn packets got) ~f:(fun (bytes, seg) ->
      let wave = List.map seg ~f:snd in
      match Usb.Receiver.decode ~bit_cycles:8 (Usb.J :: wave @ [ Usb.J; Usb.J ]) with
      | Error e -> Some (Sexp.to_string (Usb.Receiver.sexp_of_error e))
      | Ok b when not ([%equal: int list] b bytes) -> Some "decoded the wrong bytes"
      | Ok _ ->
        if [%equal: Usb.line list] wave (ideal bytes)
        then None
        else Some "waveform differs from the ideal, cycle for cycle")
;;

let%test_unit "program size" =
  [%test_result: int] (Array.length (Asm.assemble Firmware.usb)) ~expect:49
;;

let gen_packet =
  let open Quickcheck.Generator.Let_syntax in
  match%bind Int.gen_incl 0 2 with
  | 0 ->
    let%map pid = Quickcheck.Generator.of_list Usb.Pid.[ setup; in_; out_ ]
    and addr = Int.gen_incl 0 127
    and endp = Int.gen_incl 0 15 in
    Usb.token ~pid ~addr ~endp
  | 1 ->
    let%map pid = Quickcheck.Generator.of_list Usb.Pid.[ data0; data1 ]
    and n = Int.gen_incl 0 8
    and payload = Quickcheck.Generator.list_with_length 8 (Int.gen_incl 0 255) in
    Usb.data ~pid (List.take payload n)
  | _ ->
    let%map pid = Quickcheck.Generator.of_list Usb.Pid.[ ack; nak; stall ] in
    Usb.handshake ~pid
;;

let%test_unit "random packets, back to back: decoded, and exact to the clock" =
  Quickcheck.test
    (Quickcheck.Generator.list_with_length 3 gen_packet)
    ~trials:150
    ~sexp_of:[%sexp_of: int list list]
    ~f:(fun packets ->
      match judge packets (run packets) with
      | None -> ()
      | Some why -> raise_s [%message why])
;;

let%test_unit "a long run of 1s is stuffed and still exact" =
  let packets = [ Usb.data ~pid:Usb.Pid.data0 (List.init 8 ~f:(Fn.const 0xFF)) ] in
  [%test_result: string option] (judge packets (run packets)) ~expect:None
;;

let%expect_test "planted firmware bugs: each is caught" =
  let mutate ~pattern ~with_ =
    let m = String.substr_replace_first Firmware.usb ~pattern ~with_ in
    assert (not (String.equal m Firmware.usb));
    m
  in
  let packets =
    [ Usb.token ~pid:Usb.Pid.setup ~addr:0 ~endp:0
    ; Usb.data ~pid:Usb.Pid.data0 [ 0x80; 0x06; 0x00; 0x01; 0x00; 0x00; 0x40; 0x00 ]
    ; Usb.handshake ~pid:Usb.Pid.ack
    ]
  in
  List.iter
    [ ( "word boundary one clock short"
      , mutate ~pattern:"pull                side 0 [1]" ~with_:"pull                side 0    " )
    ; ( "SE0 one bit time, not two"
      , mutate ~pattern:"set x, 4            side 1" ~with_:"set x, 1            side 1" )
    ; ( "drivers released during EOP's J"
      , mutate
          ~pattern:"set pins, 0         side 0 [3]"
          ~with_:"set pins, 0         side 2 [3]" )
    ; ( "no idle gap between packets"
      , mutate ~pattern:"set y, 9            side 2" ~with_:"set y, 0            side 2" )
    ]
    ~f:(fun (name, source) ->
      printf
        "%-34s %s\n"
        name
        (match judge packets (run ~source packets) with
         | None -> "MISSED"
         | Some why -> "caught: " ^ why));
  [%expect {|
    word boundary one clock short      caught: waveform differs from the ideal, cycle for cycle
    SE0 one bit time, not two          caught: (Bad_eop"SE0 is not two bit times followed by J")
    drivers released during EOP's J    caught: only 4 idle clocks between packets
    no idle gap between packets        caught: only 11 idle clocks between packets
    |}]
;;

(* --- As the board uses it: a slow host, a whole transaction buffered ---- *)

let%test_unit "a slow host loads a transaction with the engine stopped; it goes out exact" =
  let module H = Firmware.Usb_host in
  let packets =
    [ Usb.token ~pid:Usb.Pid.setup ~addr:0 ~endp:0
    ; Usb.data ~pid:Usb.Pid.data0 [ 0x80; 0x06; 0x00; 0x01; 0x00; 0x00; 0x12; 0x00 ]
    ]
  in
  let words =
    List.concat_map packets ~f:(fun bytes ->
      let lines = Usb.packet_lines bytes in
      Firmware.usb_send_words (List.take lines (List.length lines - 3)))
  in
  [%test_result: int] (List.length words) ~expect:10;
  let m =
    Isa.create ~program:H.image ~pin_modes:modes ~threads:(H.configs Tx_buffered)
  in
  Isa.set_chain m true;
  Isa.set_enabled m ~thread:(H.engine_thread Tx_buffered) false;
  let lines = Queue.create ()
  and driven = Queue.create ()
  and line = ref Usb.J
  and pending = Queue.of_list words in
  let step () =
    Isa.step m ~inputs:(inputs !line);
    let d, l = bus (Isa.pin_out m) in
    line := l;
    Queue.enqueue lines l;
    Queue.enqueue driven d
  in
  (* One word every 2,000 clocks: about 15 times slower than the engine
     sends them. Nothing may reach the bus while loading. *)
  while not (Queue.is_empty pending) do
    if Isa.push_tx m ~thread:0 (Queue.peek_exn pending)
    then ignore (Queue.dequeue_exn pending : int);
    for _ = 1 to 2000 do
      step ()
    done
  done;
  [%test_result: bool] (Queue.exists driven ~f:Fn.id) ~expect:false;
  Isa.set_enabled m ~thread:(H.engine_thread Tx_buffered) true;
  for _ = 1 to 2000 do
    step ()
  done;
  [%test_result: string option]
    (judge packets { lines = Queue.to_list lines; driven = Queue.to_list driven })
    ~expect:None
;;

(* --- Receiving ------------------------------------------------------------- *)

let%test_unit "the engine's constants match its program" =
  let p = Asm.assemble Firmware.usb in
  [%test_result: Isa.Instruction.op]
    p.(Firmware.usb_tmo).op
    ~expect:(Mov { dst = Osr; src = Pins });
  [%test_result: Isa.Instruction.op] p.(Firmware.usb_idle).op ~expect:Pull;
  [%test_result: int] Firmware.Usb_host.engine_origin ~expect:5
;;

(* A device on the bus: once [start] clocks have passed it sends [bytes],
   each bit [period] clocks long (8 is exact; USB low speed allows 1.5% either
   way), then idles at J. *)
let device_line ~start ~period bytes =
  let lines = Array.of_list (Usb.packet_lines bytes) in
  fun cycle ->
    if Float.(of_int cycle < start)
    then Usb.J
    else (
      let k = Float.iround_down_exn ((Float.of_int cycle -. start) /. period) in
      if k < Array.length lines then lines.(k) else Usb.J)
;;

(* The engine alone, given one receive command, against [device]; returns
   the words it pushed once it is idle again. *)
let receive ?(source = Firmware.usb) device =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ Firmware.usb_config ~origin:0 ]
  in
  assert (Isa.push_tx m ~thread:0 Firmware.usb_receive);
  let rx = Queue.create () in
  let cycle = ref 0 in
  let idle () = (Isa.thread m 0).pc = Firmware.usb_idle && !cycle > 10 in
  while (not (idle ())) && !cycle < 3000 do
    Isa.step m ~inputs:(inputs (device !cycle));
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    incr cycle
  done;
  Queue.to_list rx
;;

let gen_device_packet =
  let open Quickcheck.Generator.Let_syntax in
  match%bind Int.gen_incl 0 1 with
  | 0 ->
    let%map pid = Quickcheck.Generator.of_list Usb.Pid.[ data0; data1 ]
    and n = Int.gen_incl 0 8
    and payload = Quickcheck.Generator.list_with_length 8 (Int.gen_incl 0 255) in
    Usb.data ~pid (List.take payload n)
  | _ ->
    let%map pid = Quickcheck.Generator.of_list Usb.Pid.[ ack; nak; stall ] in
    Usb.handshake ~pid
;;

let%test_unit "receive: random packets, the sender's clock up to 1.5% off either way" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       gen_device_packet
       (Float.gen_incl (-0.015) 0.015)
       (Float.gen_incl 20. 120.))
    ~trials:300
    ~sexp_of:[%sexp_of: int list * float * float]
    ~f:(fun (bytes, err, start) ->
      let words = receive (device_line ~start ~period:(8. *. (1. +. err)) bytes) in
      [%test_result: (int list, string) Result.t]
        (Usb.decode_levels (Firmware.usb_levels words))
        ~expect:(Ok bytes))
;;

let%test_unit "receive: every 1-bit long run, at both clock extremes" =
  (* Eight 0xFF bytes: the longest runs without a transition the stuffing
     allows, where the receiver must hold its timing on timeouts alone. *)
  let bytes = Usb.data ~pid:Usb.Pid.data1 (List.init 8 ~f:(Fn.const 0xFF)) in
  List.iter [ -0.015; 0.; 0.015 ] ~f:(fun err ->
    List.iter [ 20.; 20.3; 20.6; 20.9 ] ~f:(fun start ->
      let words = receive (device_line ~start ~period:(8. *. (1. +. err)) bytes) in
      [%test_result: (int list, string) Result.t]
        (Usb.decode_levels (Firmware.usb_levels words))
        ~expect:(Ok bytes)))
;;

(* A whole IN transaction on the engine: send IN, receive, send ACK. The
   device answers [delay] bit times after the IN token's EOP. The ACK must
   start 2 to 7.5 bit times after the data packet's EOP (USB 1.1, 7.1.18). *)
let in_transaction ~delay ~err data =
  let m =
    Isa.create
      ~program:(Asm.assemble Firmware.usb)
      ~pin_modes:modes
      ~threads:[ Firmware.usb_config ~origin:0 ]
  in
  let send bytes =
    let lines = Usb.packet_lines bytes in
    Firmware.usb_send_words (List.take lines (List.length lines - 3))
  in
  let pending =
    Queue.of_list
      (send (Usb.token ~pid:Usb.Pid.in_ ~addr:3 ~endp:1)
       @ [ Firmware.usb_receive ]
       @ send (Usb.handshake ~pid:Usb.Pid.ack))
  in
  let device = ref (fun _ -> Usb.J) in
  let host_driving = ref false
  and last_host_end = ref None
  and device_eop_end = ref None
  and ack_start = ref None
  and line = ref Usb.J
  and lines = Queue.create ()
  and rx = Queue.create () in
  for cycle = 0 to 4000 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    let dev = !device cycle in
    Isa.step m ~inputs:(inputs !line);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    let d, l = bus (Isa.pin_out m) in
    (* The host's first release: the IN token is done; the device answers. *)
    if !host_driving && (not d) && Option.is_none !last_host_end
    then (
      last_host_end := Some cycle;
      let start = Float.of_int cycle +. (float delay *. 8. *. (1. +. err)) in
      device := device_line ~start ~period:(8. *. (1. +. err)) data;
      let n = List.length (Usb.packet_lines data) in
      device_eop_end
      := Some (Float.iround_up_exn (start +. (float n *. 8. *. (1. +. err)))));
    if d && (not !host_driving) && Option.is_some !last_host_end && Option.is_none !ack_start
    then ack_start := Some cycle;
    host_driving := d;
    line := if d then l else dev;
    Queue.enqueue lines (d, !line)
  done;
  let received = Usb.decode_levels (Firmware.usb_levels (Queue.to_list rx)) in
  let turnaround =
    match !ack_start, !device_eop_end with
    | Some a, Some e -> Some (a - e)
    | _ -> None
  in
  let host_packets =
    packets_of
      { driven = Queue.to_list lines |> List.map ~f:fst
      ; lines = Queue.to_list lines |> List.map ~f:snd
      }
    |> List.map ~f:(fun seg ->
      Usb.Receiver.decode ~bit_cycles:8 (Usb.J :: List.map seg ~f:snd @ [ Usb.J; Usb.J ]))
  in
  received, turnaround, host_packets
;;

let%test_unit "an IN transaction: data received, ACK sent 2 to 7.5 bit times later" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       gen_device_packet
       (Int.gen_incl 2 7)
       (Float.gen_incl (-0.015) 0.015))
    ~trials:60
    ~sexp_of:[%sexp_of: int list * int * float]
    ~f:(fun (data, delay, err) ->
      let received, turnaround, host_packets = in_transaction ~delay ~err data in
      [%test_result: (int list, string) Result.t] received ~expect:(Ok data);
      [%test_result: (int list, Usb.Receiver.error) Result.t list]
        host_packets
        ~expect:
          [ Ok (Usb.token ~pid:Usb.Pid.in_ ~addr:3 ~endp:1)
          ; Ok (Usb.handshake ~pid:Usb.Pid.ack)
          ];
      match turnaround with
      | None -> failwith "no ACK"
      | Some t ->
        if t < 16 || t > 60
        then raise_s [%message "ACK outside 2 to 7.5 bit times" (t : int)])
;;

let%expect_test "planted receive bugs: each is caught" =
  let mutate ~pattern ~with_ =
    let m = String.substr_replace_first Firmware.usb ~pattern ~with_ in
    assert (not (String.equal m Firmware.usb));
    m
  in
  let cases =
    List.concat_map [ -0.015; 0.; 0.015 ] ~f:(fun err ->
      List.map
        [ Usb.data ~pid:Usb.Pid.data1 (List.init 8 ~f:(fun i -> (i * 37) land 0xFF))
        ; Usb.data ~pid:Usb.Pid.data0 (List.init 8 ~f:(Fn.const 0xFF))
        ; Usb.handshake ~pid:Usb.Pid.nak
        ]
        ~f:(fun bytes -> bytes, err))
  in
  List.iter
    [ ( "K waits on the wrong pin"
      , mutate
          ~pattern:"kw:     wait 0 pin 0 timeout"
          ~with_:"kw:     wait 0 pin 1 timeout" )
    ; "no end marker", mutate ~pattern:"set x, 1            side 2" ~with_:"set x, 0            side 2"
    ; ( "sampled late after a fall to J"
      , mutate ~pattern:"jmp toj             side 2" ~with_:"jmp toj             side 2 [3]" )
    ]
    ~f:(fun (name, source) ->
      let failures =
        List.count cases ~f:(fun (bytes, err) ->
          let words = receive ~source (device_line ~start:30. ~period:(8. *. (1. +. err)) bytes) in
          not ([%equal: (int list, string) Result.t]
                 (Usb.decode_levels (Firmware.usb_levels words))
                 (Ok bytes)))
      in
      printf "%-34s %s\n" name
        (if failures = 0 then "MISSED" else sprintf "caught in %d of %d" failures (List.length cases)));
  [%expect
    {|
    K waits on the wrong pin           caught in 9 of 9
    no end marker                      caught in 9 of 9
    sampled late after a fall to J     caught in 9 of 9
    |}]
;;
