(* Low-speed USB transmit ([Firmware.usb_tx]) on the model chip, through a
   model of a USB 1.1 transceiver in VO/FSE0 mode, judged two ways:
   - the reference receiver ([Usb_model.Receiver], written from the USB 1.1
     spec) must decode every packet back to the bytes that were sent;
   - the waveform must equal the ideal one cycle for cycle: each line state
     exactly 8 clocks, the drivers on from the first bit of SYNC to the end
     of EOP's J and off otherwise. The receiver alone would forgive some
     timing faults (a bus idles at J, so drivers released one bit early
     look the same to it); this check does not. *)

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
let run ?(source = Firmware.usb_tx) packets =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ Firmware.usb_tx_config ]
  in
  let pending =
    Queue.of_list
      (List.concat_map packets ~f:(fun bytes ->
         let lines = Usb.packet_lines bytes in
         Firmware.usb_tx_words (List.take lines (List.length lines - 3))))
  in
  let total_bits =
    List.sum (module Int) packets ~f:(fun b -> List.length (Usb.packet_lines b))
  in
  let lines = Queue.create ()
  and driven = Queue.create ()
  and line = ref Usb.J in
  for _ = 1 to (total_bits * 8) + (List.length packets * 40) + 200 do
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
  [%test_result: int] (Array.length (Asm.assemble Firmware.usb_tx)) ~expect:17
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
    let m = String.substr_replace_first Firmware.usb_tx ~pattern ~with_ in
    assert (not (String.equal m Firmware.usb_tx));
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
      , mutate ~pattern:"set x, 4            side 2" ~with_:"set x, 0            side 2" )
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
    no idle gap between packets        caught: only 9 idle clocks between packets
    |}]
;;

(* --- As the board uses it: a slow host, a whole transaction buffered ---- *)

let%test_unit "a slow host loads a transaction with thread 1 stopped; it goes out exact" =
  let module H = Firmware.Usb_host in
  let packets =
    [ Usb.token ~pid:Usb.Pid.setup ~addr:0 ~endp:0
    ; Usb.data ~pid:Usb.Pid.data0 [ 0x80; 0x06; 0x00; 0x01; 0x00; 0x00; 0x12; 0x00 ]
    ]
  in
  let words =
    List.concat_map packets ~f:(fun bytes ->
      let lines = Usb.packet_lines bytes in
      Firmware.usb_tx_words (List.take lines (List.length lines - 3)))
  in
  [%test_result: int] (List.length words) ~expect:10;
  let m =
    Isa.create
      ~program:H.image
      ~pin_modes:modes
      ~threads:[ H.relay_config; H.tx_config ]
  in
  Isa.set_chain m true;
  Isa.set_enabled m ~thread:1 false;
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
  Isa.set_enabled m ~thread:1 true;
  for _ = 1 to 2000 do
    step ()
  done;
  [%test_result: string option]
    (judge packets { lines = Queue.to_list lines; driven = Queue.to_list driven })
    ~expect:None
;;
