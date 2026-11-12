(* The PS/2 host firmware ([Firmware.Ps2]: receiver on thread 0, transmitter
   on thread 1) on the model chip, against a device modelled here from the
   PS/2 protocol's rules (IBM's Technical Reference as summarised by Adam
   Chapweske, "The PS/2 Mouse/Keyboard Protocol"), not from the firmware.

   The device draws its timing at random from the range the rules allow:
   each clock phase 30 to 50 us, DATA set up 5 to 25 us before CLK falls,
   0.1 to 2 ms between a request to send and its first clock. It follows the
   rules a real one must: it starts a frame only on a bus idle for 50 us,
   gives up its frame, to send it again, if the host holds CLK low before
   the 11th bit's clock, and takes a host byte only
   after 100 us of CLK low followed by DATA low with CLK released.

   Checked: every byte the device sends reaches the host as one well-formed
   frame, and nothing else does; every byte the host sends reaches the
   device, with odd parity, a stop bit, and the ACK (or its absence)
   reported; the receiver's
   record of the host's own byte matches; and the host's pulses meet the
   rules: CLK low at least 100 us to inhibit, DATA low before CLK is
   released, DATA changed only while CLK is low and at least 5 us before it
   rises. *)

open! Core
module Isa = Pe_model.Isa
module Firmware = Pe_model.Firmware
module Ps2 = Firmware.Ps2

let mhz = 10
let us = mhz

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    if i < 2 then Isa.Pin_mode.Open_drain else if i = 2 then Push_pull else Input)
;;

(* The device, as a coroutine: [cont] runs when cycle [wake] arrives. *)
type device =
  { rng : Random.State.t
  ; mutable clk_low : bool
  ; mutable data_low : bool
  ; mutable wake : int
  ; mutable cont : unit -> unit
  ; mutable guard : bool (* give up if CLK is low while released *)
  ; mutable now : int
  ; mutable clk : bool (* the lines, as last seen *)
  ; mutable data : bool
  ; mutable clk_low_for : int
  ; mutable idle_for : int
  ; to_send : int Queue.t
  ; sent : int Queue.t (* bytes whose frames completed *)
  ; received : (int * bool * bool) Queue.t (* byte, parity ok, stop bit *)
  ; mutable aborted : int
  ; present : bool
  ; acks : bool
  }

let between d lo hi = (lo * us) + Random.State.int d.rng (((hi - lo) * us) + 1)
let after d n k = d.wake <- d.now + n; d.cont <- k

let rec idle d =
  d.clk_low <- false;
  d.data_low <- false;
  d.guard <- false;
  d.wake <- Int.max_value;
  d.cont <- (fun () -> ())

and abort d =
  d.aborted <- d.aborted + 1;
  idle d

(* Device to host: 11 bits, DATA changing while CLK is high. *)
and send d byte =
  let parity = (Int.popcount byte + 1) % 2 in
  let bits =
    [ 0 ] @ List.init 8 ~f:(fun k -> (byte lsr k) land 1) @ [ parity; 1 ]
  in
  let rec go = function
    | [] ->
      Queue.enqueue d.sent byte;
      ignore (Queue.dequeue d.to_send : int option);
      idle d
    | b :: rest ->
      d.guard <- true;
      d.data_low <- b = 0;
      after d (between d 5 25) (fun () ->
        d.guard <- false;
        d.clk_low <- true;
        after d (between d 30 50) (fun () ->
          d.clk_low <- false;
          (* Once CLK has fallen for the 11th bit the frame counts as sent,
             whatever the host does next. *)
          if List.is_empty rest
          then go rest
          else (
            d.guard <- true;
            after d (between d 5 25) (fun () -> go rest))))
  in
  go bits

(* Host to device: 10 clocks reading DATA as CLK rises, then the ACK. *)
and receive d =
  let bits = Queue.create () in
  let rec pulse n k =
    d.clk_low <- true;
    after d (between d 30 50) (fun () ->
      if n > 0 then Queue.enqueue bits (Bool.to_int d.data);
      d.clk_low <- false;
      after d (between d 30 50) (fun () -> k ()))
  and clocks n = if n > 10 then ack () else pulse n (fun () -> clocks (n + 1))
  and ack () =
    let b = Queue.to_array bits in
    let byte = Array.foldi (Array.sub b ~pos:0 ~len:8) ~init:0 ~f:(fun k acc v -> acc lor (v lsl k)) in
    Queue.enqueue d.received (byte, (Int.popcount byte + b.(8)) % 2 = 1, b.(9) = 1);
    d.data_low <- d.acks;
    after d (between d 5 25) (fun () -> pulse 0 (fun () -> idle d))
  in
  after d (between d 100 2000) (fun () -> clocks 1)
;;

let device ~seed ~present ~acks =
  let d =
    { rng = Random.State.make [| seed |]
    ; clk_low = false
    ; data_low = false
    ; wake = Int.max_value
    ; cont = (fun () -> ())
    ; guard = false
    ; now = 0
    ; clk = true
    ; data = true
    ; clk_low_for = 0
    ; idle_for = 0
    ; to_send = Queue.create ()
    ; sent = Queue.create ()
    ; received = Queue.create ()
    ; aborted = 0
    ; present
    ; acks
    }
  in
  idle d;
  d
;;

let is_idle d = d.wake = Int.max_value && (not d.clk_low) && not d.data_low

(* One cycle of the device, given the lines during it. *)
let tick d c ~clk ~data =
  d.now <- c;
  let was_inhibited = d.clk_low_for >= 100 * us in
  d.clk_low_for <- (if clk then 0 else d.clk_low_for + 1);
  d.idle_for <- (if clk && data then d.idle_for + 1 else 0);
  d.clk <- clk;
  d.data <- data;
  if d.present
  then
    if d.guard && not clk
    then abort d
    else if c >= d.wake
    then d.cont ()
    else if is_idle d
    then
      if was_inhibited && clk && not data
      then receive d
      else if d.idle_for >= 50 * us
      then Option.iter (Queue.peek d.to_send) ~f:(send d)
;;

type event =
  | Device of int (* the device sends this byte *)
  | Host of int (* the host sends this byte *)
  | Both of int * int (* the device, and the host at the same moment or mid-frame *)
[@@deriving sexp_of]

type outcome =
  { frames : int list (* thread 0's RX words *)
  ; results : int list (* thread 1's RX words *)
  ; device_got : (int * bool * bool) list
  ; device_sent : int list
  ; aborted : int
  ; violations : string list
  }

let run ?(rx = Firmware.ps2_rx) ?(tx = Firmware.ps2_tx) ?(present = true) ?(acks = true) ~seed events =
  let rx_code = Pe_model.Asm.assemble ~origin:Ps2.rx_origin rx in
  let tx_origin = Array.length rx_code in
  let m =
    Isa.create
      ~program:
        (Pe_model.Asm.link [ Ps2.rx_origin, rx_code; tx_origin, Pe_model.Asm.assemble ~origin:tx_origin tx ])
      ~pin_modes:modes
      ~threads:
        [ Ps2.rx_config ~mhz
        ; { (Ps2.tx_config ~mhz) with
            start = tx_origin
          ; timeout_vector = tx_origin + Firmware.ps2_tx_dead
          }
        ]
  in
  let d = device ~seed ~present ~acks in
  let rng = Random.State.make [| seed; 1 |] in
  let frames = Queue.create ()
  and results = Queue.create ()
  and violations = Queue.create () in
  let violate fmt = ksprintf (fun s -> Queue.enqueue violations s) fmt in
  let pending = ref events
  and hold_until = ref (200 * us)
  and cut = ref None (* a [Both]'s host byte, and when to send it *)
  and was_busy = ref false
  and host_sends = ref 0
  and host_clk_since = ref None
  and prev_host_data = ref false
  and data_changed_at = ref None
  and prev_clk = ref true
  and cycle = ref 0 in
  let busy () =
    Option.is_some !cut
    || Queue.length results < !host_sends
    || (not (Queue.is_empty d.to_send))
    || not (is_idle d)
  in
  let push byte =
    assert (Isa.push_tx m ~thread:1 (Firmware.ps2_tx_word byte));
    incr host_sends
  in
  while ((not (List.is_empty !pending)) || busy () || !cycle < !hold_until) && !cycle < 3_000_000 do
    let c = !cycle in
    (* An event starts once the last is done and a random gap has passed.
       [Both] starts the device's frame and the host's byte together. *)
    let now_busy = busy () in
    if !was_busy && not now_busy then hold_until := c + ((100 + Random.State.int rng 400) * us);
    was_busy := now_busy;
    (match !cut, !pending with
     | Some (h, at), _ when c >= at ->
       push h;
       cut := None
     | None, ev :: rest when (not now_busy) && c >= !hold_until ->
       (match ev with
        | Device b -> Queue.enqueue d.to_send b
        | Host b -> push b
        | Both (b, h) ->
          Queue.enqueue d.to_send b;
          (* at once, so the inhibit lands in the frame's first microseconds
             and cuts it off; or later, when the transmitter must wait *)
          let delay = if Random.State.bool rng then 0 else (10 + Random.State.int rng 900) * us in
          cut := Some (h, c + delay));
       pending := rest;
       was_busy := true
     | _ -> ());
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue frames);
    Option.iter (Isa.pop_rx m ~thread:1) ~f:(Queue.enqueue results);
    let out = Isa.pin_out m in
    let host_data_low = out land 1 = 0
    and host_clk_low = out land 2 = 0 in
    let clk = not (host_clk_low || d.clk_low)
    and data = not (host_data_low || d.data_low) in
    (* The host's pulses. *)
    (match !host_clk_since, host_clk_low with
     | None, true -> host_clk_since := Some c
     | Some since, false ->
       if c - since < 100 * us then violate "host held CLK low only %d cycles" (c - since);
       if not host_data_low then violate "host released CLK before pulling DATA low";
       host_clk_since := None
     | _ -> ());
    if Bool.( <> ) host_data_low !prev_host_data
    then (
      if present && clk then violate "host changed DATA at cycle %d with CLK high" c;
      data_changed_at := Some c);
    if clk && not !prev_clk
    then
      Option.iter !data_changed_at ~f:(fun at ->
        if c - at < 5 * us then violate "DATA changed %d cycles before CLK rose" (c - at));
    prev_host_data := host_data_low;
    prev_clk := clk;
    tick d c ~clk ~data;
    let inputs = 0xFC lor Bool.to_int (not d.data_low) lor (Bool.to_int (not d.clk_low) lsl 1) in
    Isa.step m ~inputs;
    incr cycle
  done;
  if !cycle >= 3_000_000 then violate "did not finish";
  if Isa.pin_out m land 3 <> 3 then violate "host left a line low";
  { frames = Queue.to_list frames
  ; results = Queue.to_list results
  ; device_got = Queue.to_list d.received
  ; device_sent = Queue.to_list d.sent
  ; aborted = d.aborted
  ; violations = Queue.to_list violations
  }
;;

(* What must come out. Every device byte arrives exactly once, in order,
   whether or not the host cut its frame off (the device sends it again).
   Each host byte reaches the device, is ACKed, and is read back by the
   receiver with the ACK (0) where the stop bit would be, which is also how
   the two kinds of frame are told apart here. *)
let check ?rx ?tx ~seed events =
  let r = run ?rx ?tx ~seed events in
  let frame b = (Firmware.ps2_tx_word b land 0x1FF) lsl 1 in
  let device_bytes =
    List.filter_map events ~f:(function Device b | Both (b, _) -> Some b | Host _ -> None)
  and host_bytes =
    List.filter_map events ~f:(function Host h | Both (_, h) -> Some h | Device _ -> None)
  in
  let from_device, echoes = List.partition_tf r.frames ~f:(fun w -> w land 0x400 <> 0) in
  let ok =
    List.is_empty r.violations
    && [%equal: int list] from_device (List.map device_bytes ~f:(fun b -> frame b lor 0x400))
    && [%equal: int list] echoes (List.map host_bytes ~f:frame)
    && [%equal: (int * bool * bool) list]
         r.device_got
         (List.map host_bytes ~f:(fun h -> h, true, true))
    && [%equal: int list] r.results (List.map host_bytes ~f:(fun _ -> 0))
    && [%equal: int list] r.device_sent device_bytes
  in
  r, ok
;;

let random_events rng =
  List.init (1 + Random.State.int rng 6) ~f:(fun _ ->
    let b () = Random.State.int rng 256 in
    match Random.State.int rng 5 with
    | 0 | 1 -> Device (b ())
    | 2 | 3 -> Host (b ())
    | _ -> Both (b (), b ()))
;;

let%expect_test "one byte each way, decoded" =
  let r, ok = check ~seed:1 [ Device 0x1C; Host 0xED ] in
  print_s
    [%message
      ""
        ~frames:(List.map r.frames ~f:(sprintf "0x%03x") : string list)
        ~bytes:(List.map r.frames ~f:Ps2.byte_of_frame : int option list)
        ~results:(r.results : int list)
        ~device_got:(r.device_got : (int * bool * bool) list)
        (ok : bool)];
  [%expect {|
    ((frames (0x438 0x3da)) (bytes ((28) ())) (results (0))
     (device_got ((237 true true))) (ok true))
    |}]
;;

let%expect_test "random traffic, device timing drawn from the legal range" =
  let rng = Random.State.make [| 2027 |] in
  let frames = ref 0
  and aborted = ref 0 in
  for seed = 1 to 150 do
    let events = random_events rng in
    let r, ok = check ~seed events in
    frames := !frames + List.length r.frames;
    aborted := !aborted + r.aborted;
    if not ok
    then
      raise_s
        [%message
          "PS/2 mismatch"
            (seed : int)
            (events : event list)
            (r.frames : int list)
            (r.results : int list)
            (r.device_got : (int * bool * bool) list)
            (r.violations : string list)]
  done;
  printf "%d frames; the host cut the device off %d times\n" !frames !aborted;
  [%expect {| 600 frames; the host cut the device off 40 times |}]
;;

let%expect_test "no device: the transmitter times out and releases the bus" =
  let r = run ~present:false ~seed:3 [ Host 0xFF ] in
  print_s [%message "" (r.results : int list) (r.frames : int list) (r.violations : string list)];
  [%expect {| ((r.results (3)) (r.frames ()) (r.violations ())) |}]
;;

let%expect_test "a device that takes the byte but does not acknowledge it" =
  let r = run ~acks:false ~seed:5 [ Host 0xF4 ] in
  print_s
    [%message "" (r.results : int list) (r.device_got : (int * bool * bool) list) (r.violations : string list)];
  [%expect {| ((r.results (1)) (r.device_got ((244 true true))) (r.violations ())) |}]
;;

let%expect_test "planted firmware bugs: each is caught" =
  let mutate source ~pattern ~with_ =
    let m = String.substr_replace_first source ~pattern ~with_ in
    assert (not (String.equal m source));
    m
  in
  let rx = mutate Firmware.ps2_rx
  and tx = mutate Firmware.ps2_tx in
  let caught ?rx ?tx () =
    let rng = Random.State.make [| 7 |] in
    List.exists (List.range 1 41) ~f:(fun seed ->
      match check ?rx ?tx ~seed (random_events rng) with
      | _, ok -> not ok
      | exception _ -> true)
    || not ([%equal: int list] (run ?rx ?tx ~acks:false ~seed:5 [ Host 0xF4 ]).results [ 1 ])
  in
  List.iter
    [ ( "receiver never abandons a frame"
      , caught ~rx:(rx ~pattern:"wait 1 pin 1 timeout" ~with_:"wait 1 pin 1        ") () )
    ; ( "receiver samples as CLK rises"
      , caught
          ~rx:
            (rx
               ~pattern:"wait 0 pin 1 timeout    side 0"
               ~with_:"wait 0 pin 1 timeout [15] side 0")
          () )
    ; ( "receiver keeps an abandoned frame's bits"
      , caught ~rx:(rx ~pattern:"mov isr, null" ~with_:"mov x, x     ") () )
    ; ( "transmitter inhibits mid-frame (ignores P2)"
      , caught ~tx:(tx ~pattern:"wait 1 pin 2" ~with_:"wait 1 pin 1") () )
    ; "inhibit under 100 us", caught ~tx:(tx ~pattern:"set y, 12" ~with_:"set y, 4") ()
    ; ( "CLK released before DATA is low"
      , caught
          ~tx:
            (tx ~pattern:"set pins, 0 [5]" ~with_:"set pins, 3 [5]"
             |> String.substr_replace_first ~pattern:"set pins, 2 " ~with_:"set pins, 0 ")
          () )
    ; ( "DATA changed as CLK rises"
      , caught
          ~tx:
            (tx ~pattern:"wait 0 pin 1 timeout [2]" ~with_:"wait 1 pin 1 timeout [2]"
             |> String.substr_replace_first ~pattern:"        wait 1 pin 1 timeout\n" ~with_:"        wait 0 pin 1 timeout\n")
          () )
    ; ( "DATA changed before the receiver's sample"
      , caught ~tx:(tx ~pattern:"wait 0 pin 1 timeout [2]" ~with_:"wait 0 pin 1 timeout") () )
    ; "ACK never read", caught ~tx:(tx ~pattern:"in pins, 1" ~with_:"in null, 1") ()
    ]
    ~f:(fun (name, caught) -> printf "%-44s %s\n" name (if caught then "caught" else "MISSED"));
  [%expect {|
    receiver never abandons a frame              caught
    receiver samples as CLK rises                caught
    receiver keeps an abandoned frame's bits     caught
    transmitter inhibits mid-frame (ignores P2)  caught
    inhibit under 100 us                         caught
    CLK released before DATA is low              caught
    DATA changed as CLK rises                    caught
    DATA changed before the receiver's sample    caught
    ACK never read                               caught
    |}]
;;
