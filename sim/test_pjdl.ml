(* The PJON node on PJDL ([Firmware.pjdl]) against a receiver written here
   from the PJDL v4.1 specification and the PJON v3.2 packet format: it
   looks for a frame initializer of three synchronization pads, then reads
   bytes, each a synchronization pad and eight data bits sampled in their
   middles, least significant first, timing every pad bit against the
   mode's 10 per cent window and every data bit from the falling edge of
   its pad. Then it checks the packet as PJON's: the length, the meta CRC
   over the first three bytes and the end CRC over all before it, both
   PJON's CRC8 written here from its reference code. The cocotb test runs
   the same firmware on the RTL and the gate netlist with sigrok's PJDL
   and PJON decoders reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let clock_hz = 10_000_000
let per_us = clock_hz / 1_000_000

(* PJON's CRC8: each byte into the low bits, then eight shifts right, adding
   0x97 when a 1 falls out. *)
let crc8 bytes =
  List.fold bytes ~init:0 ~f:(fun crc b ->
    let crc = ref (crc lxor b) in
    for _ = 1 to 8 do
      let odd = !crc land 1 in
      crc := !crc lsr 1;
      if odd = 1 then crc := !crc lxor 0x97
    done;
    !crc)
;;

(* The specification's times for each mode, in microseconds: data bit, pad
   bit. *)
let spec_times = function
  | 1 -> 44, 116
  | 2 -> 40, 92
  | 3 -> 28, 88
  | 4 -> 26, 60
  | _ -> assert false
;;

(* Every frame in [line] (one level per core clock): its bytes, or why it
   was not one. *)
let receive ~mode (line : bool array) =
  let data_us, pad_us = spec_times mode in
  let d = data_us * per_us
  and p = pad_us * per_us in
  let n = Array.length line in
  let at t = t < n && line.(t) in
  let rec next_edge t level = if t >= n then None else if Bool.equal line.(t) level then Some t else next_edge (t + 1) level in
  let within v want = 10 * abs (v - want) <= want in
  let frames = ref [] in
  (* A pad that begins at [s]: the line high until its falling edge, which
     comes a pad bit later, give or take 10 per cent; then the low data
     bit. Returns the falling edge. *)
  let pad s =
    match next_edge (s + (d / 4)) false with
    | Some f when at (s + (d / 4)) && within (f - s) p && not (at (f + (d / 2))) -> Ok f
    | Some f -> Error (sprintf "a pad from %d to %d" s f)
    | None -> Error "a pad that never ends"
  in
  let rec frames_from t =
    match next_edge t true with
    | None -> ()
    | Some r ->
      let result =
        let open Result.Let_syntax in
        (* A node sends only after the line has been free (low) for a
           byte's time. *)
        let%bind () =
          if r - t >= p + (9 * d) then Ok () else Error (sprintf "a frame after %d us of free line" ((r - t) / per_us))
        in
        let%bind f1 = pad r in
        let%bind f2 = pad (f1 + d) in
        let%bind f3 = pad (f2 + d) in
        (* Bytes, each from the end of the last bit before it, until the
           line stays low where a pad would be. *)
        let rec bytes s acc =
          if not (at (s + (p / 2)))
          then Ok (List.rev acc, s)
          else (
            let%bind f = pad s in
            let byte =
              List.init 8 ~f:(fun k -> Bool.to_int (at (f + d + (k * d) + (d / 2))) lsl k)
              |> List.fold ~init:0 ~f:( lor )
            in
            bytes (f + (9 * d)) (byte :: acc))
        in
        bytes (f3 + d) []
      in
      (match result with
       | Ok (bytes, s) ->
         frames := Ok bytes :: !frames;
         frames_from s
       | Error e ->
         frames := Error e :: !frames;
         (* Look again after this edge's run. *)
         frames_from (Option.value (next_edge r false) ~default:n))
  in
  (match next_edge 0 false with
   | Some t -> frames_from t
   | None -> ());
  List.rev !frames
;;

type packet =
  { receiver : int
  ; sender : int option
  ; payload : int list
  }
[@@deriving sexp_of, equal, compare]

(* A frame's bytes as a PJON packet with CRC8. *)
let packet bytes =
  match bytes with
  | receiver :: config :: length :: meta :: rest ->
    let all_but_last = List.drop_last_exn bytes in
    if length <> List.length bytes
    then Error (sprintf "length %d, %d bytes" length (List.length bytes))
    else if meta <> crc8 [ receiver; config; length ]
    then Error "meta CRC"
    else if List.last_exn bytes <> crc8 all_but_last
    then Error "end CRC"
    else if config land 0b1111_1101 <> 0
    then Error (sprintf "configuration %02x" config)
    else (
      let fields = List.drop_last_exn rest in
      if config land 2 <> 0
      then (
        match fields with
        | sender :: payload -> Ok { receiver; sender = Some sender; payload }
        | [] -> Error "no sender")
      else Ok { receiver; sender = None; payload = fields })
  | _ -> Error "fewer than five bytes"
;;

type outcome =
  { packets : (packet, string) Result.t list
  ; reports : int list (* RX words: each packet's end CRC *)
  ; line : bool array
  }

(* Sends [packets] (each the TX words of one) in [mode], with the host
   keeping the FIFO fed. *)
let run ?(mode = 4) ?source packets =
  let source = Option.value source ~default:(Firmware.pjdl ~mode) in
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.pjdl_config ~mode ~clock_hz ]
  in
  let data_us, pad_us = spec_times mode in
  let pending = Queue.of_list (List.concat packets) in
  let bytes = Queue.length pending + (2 * List.length packets) in
  let reports = Queue.create () in
  let line = Queue.create () in
  let cycles = per_us * ((3 * (pad_us + data_us)) + (bytes * (pad_us + (9 * data_us))) + (List.length packets * 1000) + 2000) in
  for _ = 1 to cycles do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0;
    Queue.enqueue line (Isa.lines m ~inputs:0 land 1 = 1);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue reports)
  done;
  let line = Queue.to_array line in
  { packets = List.map (receive ~mode line) ~f:(Result.bind ~f:packet)
  ; reports = Queue.to_list reports
  ; line
  }
;;

let words { receiver; sender; payload } = Firmware.pjdl_words ?sender ~receiver payload

let end_crc p =
  let w = words p in
  let header = List.take w 3 in
  let bytes = header @ [ crc8 header ] @ List.drop w 3 in
  crc8 bytes
;;

let%expect_test "program size in each mode" =
  List.iter [ 1; 2; 3; 4 ] ~f:(fun mode ->
    printf "mode %d: %d words\n" mode (Array.length (Asm.assemble (Firmware.pjdl ~mode))));
  [%expect
    {|
    mode 1: 56 words
    mode 2: 55 words
    mode 3: 54 words
    mode 4: 56 words
    |}]
;;

let%expect_test "a packet in each mode, the pads and bits exact" =
  let p = { receiver = 42; sender = Some 1; payload = [ 0x68; 0x69 ] } in
  List.iter [ 1; 2; 3; 4 ] ~f:(fun mode ->
    let r = run ~mode [ words p ] in
    (* Every run of the line, in microseconds: the pads and bits as the
       specification has them. *)
    let runs =
      Array.to_list r.line
      |> List.group ~break:Bool.( <> )
      |> List.map ~f:(fun g -> List.length g / per_us)
    in
    let data_us, pad_us = spec_times mode in
    let fits = List.for_all (List.drop (List.drop_last_exn runs) 1) ~f:(fun us ->
      (* A high run is a pad, maybe after 1 bits; a low run, 0 bits. *)
      us % data_us = 0 || (us - pad_us) % data_us = 0) in
    printf
      !"mode %d: %{sexp:(packet, string) Result.t list} end CRC %{sexp:int list} (%02x) runs fit: %b\n"
      mode
      r.packets
      r.reports
      (end_crc p)
      fits);
  [%expect
    {|
    mode 1: ((Ok ((receiver 42) (sender (1)) (payload (104 105))))) end CRC (57) (39) runs fit: true
    mode 2: ((Ok ((receiver 42) (sender (1)) (payload (104 105))))) end CRC (57) (39) runs fit: true
    mode 3: ((Ok ((receiver 42) (sender (1)) (payload (104 105))))) end CRC (57) (39) runs fit: true
    mode 4: ((Ok ((receiver 42) (sender (1)) (payload (104 105))))) end CRC (57) (39) runs fit: true
    |}]
;;

let%test_unit "random packets: receivers, senders, every byte value, payloads of 0 to 9" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Int.gen_incl 1 4)
       (Int.gen_incl 1 254)
       (Option.quickcheck_generator (Int.gen_incl 1 254))
       (Quickcheck.Generator.list (Int.gen_incl 0 255)))
    ~trials:40
    ~sexp_of:[%sexp_of: int * int * int option * int list]
    ~f:(fun (mode, receiver, sender, payload) ->
      let payload = List.take payload (if Option.is_some sender then 9 else 10) in
      let p = { receiver; sender; payload } in
      let r = run ~mode [ words p ] in
      [%test_result: (packet, string) Result.t list] r.packets ~expect:[ Ok p ];
      [%test_result: int list] r.reports ~expect:[ end_crc p ])
;;

let%expect_test "planted bugs" =
  let sent =
    [ { receiver = 42; sender = Some 1; payload = [ 0x55; 0xA5 ] }
    ; { receiver = 7; sender = None; payload = [ 0x0F ] }
    ]
  in
  let good = Firmware.pjdl ~mode:4 in
  let caught source =
    let r = run ~source (List.map sent ~f:words) in
    not
      ([%equal: (packet, string) Result.t list] r.packets (List.map sent ~f:(fun p -> Ok p))
       && [%equal: int list] r.reports (List.map sent ~f:end_crc))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first good ~pattern ~with_ in
    assert (not (String.equal s good));
    s
  in
  printf "the program as it is: %s\n" (if caught good then "WRONG" else "right");
  List.iter
    [ "two pads in the frame initializer", fw ~pattern:"set y, 2\ninit:" ~with_:"set y, 1\ninit:"
    ; ( "a header byte's pad 8 us short"
      , fw ~pattern:"length\n        nop [15]\n        nop [9]" ~with_:"length\n        nop [15]\n        nop [5]" )
    ; "a header data bit 2 us long", fw ~pattern:"hbit:   out pins, 1 [11]" ~with_:"hbit:   out pins, 1 [12]"
    ; "no low data bit after a pad", fw ~pattern:"set pins, 0 [12]        ; the sync" ~with_:"set pins, 0 [0]         ; the sync"
    ; "a host byte where the meta CRC goes", fw ~pattern:"mov osr, crc            ; tick 2" ~with_:"pull                    ; tick 2"
    ; "the CRC not restarted after the meta CRC", fw ~pattern:"mov crc, null           ; tick 1" ~with_:"nop                     ; tick 1"
    ; "the CRC never restarted between packets", fw ~pattern:"mov crc, null           ; the CRC register" ~with_:"nop                     ; the CRC register"
    ; "one byte too many: the length counted from 4", fw ~pattern:"m4:     jmp x-- m5" ~with_:"m4:     nop       "
    ; "no free line before a packet", fw ~pattern:"jmp y-- gap [15]" ~with_:"nop             "
    ; "the line left high after a packet", fw ~pattern:"set pins, 0             ; the line low again" ~with_:"set pins, 1             ; the line low again"
    ]
    ~f:(fun (name, source) -> printf "%-48s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    two pads in the frame initializer                caught
    a header byte's pad 8 us short                   caught
    a header data bit 2 us long                      caught
    no low data bit after a pad                      caught
    a host byte where the meta CRC goes              caught
    the CRC not restarted after the meta CRC         caught
    the CRC never restarted between packets          caught
    one byte too many: the length counted from 4     caught
    no free line before a packet                     caught
    the line left high after a packet                caught
    |}]
;;
