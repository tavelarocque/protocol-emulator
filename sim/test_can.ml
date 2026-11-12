(* The CAN firmware ([Firmware.Can]: listen-only receiver on thread 0,
   transmitter on thread 1) on the model chip, against a CAN node modelled
   here from ISO 11898-1's rules, not from the firmware. The node has its
   own clock (a bit of 79 to 81 core cycles against the chip's 80, so up to
   1.25% off), samples at 70% of each bit, hard-synchronises on a start of
   frame and resynchronises on later falling edges, removes stuff bits as
   they arrive, checks the CRC, and drives the ACK slot of every good frame.
   It also sends frames of its own, and contends for the bus: when the chip
   and the node start in the same bit, the lower identifier must win, the
   loser must stop without disturbing a bit, and send again afterwards.

   Checked: every frame the chip sends reaches the node intact and is
   acknowledged; every frame the node sends is recorded by the receiver and
   decodes to what was sent; the chip's bits are each exactly 80 cycles; it
   never drives a dominant bit after losing arbitration; and with no node,
   it reports that nobody acknowledged. *)

open! Core
module Isa = Pe_model.Isa
module Firmware = Pe_model.Firmware
module Can = Firmware.Can

let clkdiv = 8
let bit_cycles = 10 * clkdiv

let modes =
  Array.init Isa.num_pins ~f:(fun i -> if i = 1 then Isa.Pin_mode.Push_pull else Input)
;;

(* The node. [tx] is what it drives this cycle (true = recessive). *)
type node =
  { bit : int (* its bit time, in core cycles *)
  ; mutable phase : int (* cycles into the current bit; -1 when the bus is idle *)
  ; mutable recessive_run : int (* bit times of recessive bus, for idle detection *)
  ; mutable idle_cycles : int
  ; mutable prev_bus : bool
  ; mutable rx : int list (* this frame's bits so far, newest first, stuffing removed *)
  ; mutable raw_run : int * int (* last raw bit, run length *)
  ; mutable field : [ `Frame | `Crc_delim | `Ack | `Done | `Bad ]
  ; mutable ack_now : bool
  ; mutable sending : int list (* bits still to drive, this one first *)
  ; mutable driving : bool (* true = recessive *)
  ; mutable lost : bool
  ; to_send : int list Queue.t
  ; received : (int * int list) Queue.t
  ; mutable sent : int
  ; mutable bit_errors : int
  ; contend : bool (* start a frame in the same bit as another node's SOF *)
  }

let node ~bit ~contend =
  { bit
  ; phase = -1
  ; recessive_run = 0
  ; idle_cycles = 0
  ; prev_bus = true
  ; rx = []
  ; raw_run = -1, 0
  ; field = `Done
  ; ack_now = false
  ; sending = []
  ; driving = true
  ; lost = false
  ; to_send = Queue.create ()
  ; received = Queue.create ()
  ; sent = 0
  ; bit_errors = 0
  ; contend
  }
;;

let value bits = List.fold bits ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b)

(* One sampled bit of a frame the node is receiving (or sending). *)
let take n b =
  match n.field with
  | `Frame ->
    let last, run = n.raw_run in
    if run = 5
    then (
      if b = last then n.field <- `Bad;
      n.raw_run <- b, 1)
    else (
      n.raw_run <- (b, if b = last then run + 1 else 1);
      n.rx <- b :: n.rx;
      let got = List.rev n.rx in
      let len = List.length got in
      if len >= 19
      then (
        let dlc = value (List.sub got ~pos:15 ~len:4) in
        if dlc > 8 || value (List.sub got ~pos:12 ~len:3) <> 0
        then n.field <- `Bad
        else if len = 19 + (8 * dlc) + 15
        then (
          let body = List.sub got ~pos:0 ~len:(19 + (8 * dlc)) in
          let crc = value (List.sub got ~pos:(19 + (8 * dlc)) ~len:15) in
          (* its own CRC, bit by bit *)
          let want =
            List.fold body ~init:0 ~f:(fun c b ->
              let c' = (c lsl 1) land 0x7FFF in
              if ((c lsr 14) land 1) lxor b = 1 then c' lxor 0x4599 else c')
          in
          if crc <> want
          then n.field <- `Bad
          else (
            (* a stuff bit may still follow the CRC *)
            n.field <- `Crc_delim;
            if List.is_empty n.sending
            then
              Queue.enqueue
                n.received
                ( value (List.sub got ~pos:1 ~len:11)
                , List.map
                    (List.chunks_of (List.sub got ~pos:19 ~len:(8 * dlc)) ~length:8)
                    ~f:value )))))
  | `Crc_delim ->
    let last, run = n.raw_run in
    if run = 5 && b <> last
    then n.raw_run <- b, 1 (* that stuff bit *)
    else if b = 1
    then (
      n.field <- `Ack;
      n.ack_now <- List.is_empty n.sending)
    else n.field <- `Bad
  | `Ack -> n.field <- `Done
  | `Done | `Bad -> ()
;;

(* One core cycle: the bus as it was, giving what the node drives next. *)
let tick n ~bus =
  let fell = n.prev_bus && not bus in
  n.prev_bus <- bus;
  if n.phase < 0
  then (
    n.idle_cycles <- (if bus then n.idle_cycles + 1 else 0);
    (* A contending node holds its frame for another node's start of frame,
       for a while; then it starts by itself like any other. *)
    let start_own =
      n.idle_cycles >= (if n.contend then 25 else 11) * n.bit && not (Queue.is_empty n.to_send)
    in
    if fell || start_own
    then (
      (* start of frame: someone else's (hard synchronisation), or its own *)
      n.phase <- 0;
      n.rx <- [];
      n.raw_run <- -1, 0;
      n.field <- `Frame;
      n.lost <- false;
      n.recessive_run <- 0;
      let join = start_own || (fell && n.contend && not (Queue.is_empty n.to_send)) in
      n.sending <- (if join then Queue.peek_exn n.to_send else []);
      (match n.sending with
       | b :: _ -> n.driving <- b = 1
       | [] -> ())))
  else (
    (* resynchronise on a falling edge it did not cause *)
    if fell && n.driving && n.phase > n.bit / 2 then n.phase <- n.bit - 1;
    if fell && n.driving && n.phase <= n.bit / 4 then n.phase <- 0;
    n.phase <- n.phase + 1;
    if n.phase = n.bit * 7 / 10
    then (
      let b = Bool.to_int bus in
      (match n.sending with
       | sent :: _ when sent = 1 && b = 0 && Poly.( = ) n.field `Frame ->
         (* arbitration lost: stop, and listen to the rest *)
         n.sending <- [];
         n.lost <- true;
         n.driving <- true
       | sent :: _ when sent <> b && not (Poly.( = ) n.field `Ack) -> n.bit_errors <- n.bit_errors + 1
       | _ -> ());
      n.recessive_run <- (if bus then n.recessive_run + 1 else 0);
      take n b);
    if n.phase >= n.bit
    then (
      n.phase <- 0;
      (match n.sending with
       | _ :: (b :: _ as rest) ->
         n.sending <- rest;
         n.driving <- b = 1
       | [ _ ] ->
         n.sending <- [];
         n.driving <- true;
         n.sent <- n.sent + 1;
         ignore (Queue.dequeue n.to_send : int list option)
       | [] ->
         n.driving <- not n.ack_now;
         n.ack_now <- false);
      if n.recessive_run >= 7 && List.is_empty n.sending
      then (
        n.phase <- -1;
        n.idle_cycles <- 7 * n.bit)))
;;

type frame = int * int list [@@deriving sexp_of, equal]

type outcome =
  { results : int list (* thread 1's RX words *)
  ; heard : (int * int list * bool) option list (* the receiver's frames, decoded *)
  ; node_got : frame list
  ; node_sent : int
  ; node_bit_errors : int
  ; violations : string list
  }

(* The chip sends [chip_frames] in order, sending again whenever it loses
   arbitration; the node sends [node_frames]. *)
let run ?(rx = Firmware.can_rx) ?(tx = Firmware.can_tx) ?node:(nd = None) ~chip_frames ~node_frames () =
  let rx_code = Pe_model.Asm.assemble ~origin:0 rx in
  let tx_origin = Array.length rx_code in
  let m =
    Isa.create
      ~program:(Pe_model.Asm.link [ 0, rx_code; tx_origin, Pe_model.Asm.assemble ~origin:tx_origin tx ])
      ~pin_modes:modes
      ~threads:
        [ Can.rx_config ~clkdiv
        ; { (Can.tx_config ~clkdiv) with
            start = tx_origin
          ; timeout_vector = tx_origin + Firmware.can_tx_lost
          }
        ]
  in
  Option.iter nd ~f:(fun n ->
    List.iter node_frames ~f:(fun (id, data) -> Queue.enqueue n.to_send (Can.frame_bits ~id ~data)));
  let violations = Queue.create () in
  let violate fmt = ksprintf (fun s -> Queue.enqueue violations s) fmt in
  let results = Queue.create ()
  and words = Queue.create ()
  and heard = Queue.create ()
  and pending = Queue.create ()
  and todo = ref chip_frames
  and in_flight = ref None
  and prev_tx = ref true
  and last_edge = ref None
  and stopped_at = ref None
  and cycle = ref 0 in
  let node_busy () =
    match nd with
    | Some n -> (not (Queue.is_empty n.to_send)) || n.phase >= 0
    | None -> false
  in
  let quiet_since = ref 0 in
  while
    ((not (List.is_empty !todo)) || Option.is_some !in_flight || node_busy () || !cycle - !quiet_since < 30 * bit_cycles)
    && !cycle < 4_000_000
  do
    let c = !cycle in
    (* The host: one frame at a time, its words as the FIFO takes them. *)
    (match !in_flight, !todo with
     | None, (id, data) :: _ ->
       let bits = Can.frame_bits ~id ~data in
       List.iter (Can.tx_words bits) ~f:(Queue.enqueue pending);
       in_flight := Some (List.length bits);
       stopped_at := None
     | _ -> ());
    (match Queue.peek pending with
     | Some w -> if Isa.push_tx m ~thread:1 w then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Option.iter (Isa.pop_rx m ~thread:1) ~f:(fun r ->
      Queue.enqueue results r;
      if not (Queue.is_empty pending) then violate "result %d before the frame's words were taken" r;
      (* acknowledged or never acknowledged: done. Otherwise send it again. *)
      if r = 0 || r = Can.frame_end then todo := List.tl_exn !todo;
      in_flight := None);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(fun w ->
      if w = Can.frame_end
      then (
        Queue.enqueue heard (Can.decode (Can.levels (Queue.to_list words)));
        Queue.clear words)
      else Queue.enqueue words w);
    let chip_tx = Isa.pin_out m land 2 <> 0 in
    let node_tx = Option.value_map nd ~default:true ~f:(fun n -> n.driving) in
    let bus = chip_tx && node_tx in
    if not bus then quiet_since := c;
    (* The chip's own bits: every edge a whole number of bit times after
       the last, and nothing dominant once the bus contradicted it. *)
    if Bool.( <> ) chip_tx !prev_tx
    then (
      Option.iter !last_edge ~f:(fun e ->
        if (c - e) % bit_cycles <> 0 && c - e < 12 * bit_cycles
        then violate "chip TXD edges %d cycles apart" (c - e));
      last_edge := Some c);
    prev_tx := chip_tx;
    Option.iter nd ~f:(fun n -> tick n ~bus);
    Isa.step m ~inputs:(0xFE lor Bool.to_int bus);
    incr cycle
  done;
  if !cycle >= 4_000_000 then violate "did not finish";
  ignore !stopped_at;
  { results = Queue.to_list results
  ; heard = Queue.to_list heard
  ; node_got = Option.value_map nd ~default:[] ~f:(fun n -> Queue.to_list n.received)
  ; node_sent = Option.value_map nd ~default:0 ~f:(fun n -> n.sent)
  ; node_bit_errors = Option.value_map nd ~default:0 ~f:(fun n -> n.bit_errors)
  ; violations = Queue.to_list violations
  }
;;

let%expect_test "CRC-15/CAN check value, and a frame's bits" =
  (* The catalogued check value: the CRC of the ASCII digits 1 to 9. *)
  let digits = List.concat_map (String.to_list "123456789") ~f:(fun ch -> Can.msb_first ~width:8 (Char.to_int ch)) in
  printf "0x%04x\n" (Can.crc15 digits);
  let bits = Can.frame_bits ~id:0x555 ~data:[ 0x00; 0xFF ] in
  print_endline (String.concat (List.map bits ~f:Int.to_string));
  print_s [%sexp (Can.decode bits : (int * int list * bool) option)];
  [%expect {|
    0x059e
    01010101010100000110000010000111110111001000010110001111
    ((1365 (0 255) false))
    |}]
;;

let random_frame rng =
  ( Random.State.int rng 0x800
  , List.init (Random.State.int rng 9) ~f:(fun _ -> List.random_element_exn ~random_state:rng [ 0; 0xFF; Random.State.int rng 256 ]) )
;;

(* Everything a run must satisfy, whoever won each arbitration. *)
let check ?rx ?tx ~bit ~contend ~chip_frames ~node_frames () =
  let nd = node ~bit ~contend in
  let r = run ?rx ?tx ~node:(Some nd) ~chip_frames ~node_frames () in
  let sort = List.sort ~compare:[%compare: int * int list] in
  let all = sort (chip_frames @ node_frames) in
  let heard = List.filter_map r.heard ~f:Fn.id in
  let ok =
    List.is_empty r.violations
    && r.node_bit_errors = 0
    && r.node_sent = List.length node_frames
    && [%equal: frame list] (sort r.node_got) (sort chip_frames)
    (* every frame was on the bus once, whole, and the receiver has each *)
    && List.length heard = List.length r.heard
    && [%equal: frame list] (sort (List.map heard ~f:(fun (id, d, _) -> id, d))) all
    (* the chip's frames acknowledged, the node's not (the chip only listens) *)
    && List.for_all heard ~f:(fun (id, d, ack) ->
      Bool.equal ack (List.mem chip_frames (id, d) ~equal:[%equal: frame])
      || List.mem node_frames (id, d) ~equal:[%equal: frame])
    && List.count r.results ~f:(fun w -> w = 0) = List.length chip_frames
    && not (List.mem r.results Can.frame_end ~equal:Int.equal)
  in
  r, ok
;;

let%expect_test "random traffic both ways; the node's clock up to 1.25% off" =
  let rng = Random.State.make [| 11898 |] in
  let lost = ref 0
  and frames = ref 0 in
  for trial = 1 to 120 do
    let bit = 79 + (trial % 3) in
    let contend = trial % 2 = 0 in
    let chip_frames = List.init (1 + Random.State.int rng 3) ~f:(fun _ -> random_frame rng) in
    let node_frames =
      List.init (Random.State.int rng 3) ~f:(fun _ -> random_frame rng)
      |> List.filter ~f:(fun (id, _) -> not (List.exists chip_frames ~f:(fun (i, _) -> i = id)))
    in
    let r, ok = check ~bit ~contend ~chip_frames ~node_frames () in
    frames := !frames + List.length r.heard;
    lost := !lost + List.count r.results ~f:(fun w -> w <> 0);
    if not ok
    then
      raise_s
        [%message
          "CAN mismatch"
            (trial : int)
            (bit : int)
            (contend : bool)
            (chip_frames : frame list)
            (node_frames : frame list)
            (r.results : int list)
            (r.heard : (int * int list * bool) option list)
            (r.node_got : frame list)
            (r.node_sent : int)
            (r.node_bit_errors : int)
            (r.violations : string list)]
  done;
  printf "%d frames on the bus; the chip lost arbitration %d times and sent again\n" !frames !lost;
  [%expect {| 353 frames on the bus; the chip lost arbitration 21 times and sent again |}]
;;

let%expect_test "no other node: sent, and nobody acknowledged" =
  let r = run ~chip_frames:[ 0x123, [ 0xDE; 0xAD ] ] ~node_frames:[] () in
  print_s
    [%message
      ""
        ~results:(List.map r.results ~f:(sprintf "0x%04x") : string list)
        (r.heard : (int * int list * bool) option list)
        (r.violations : string list)];
  [%expect {| ((results (0xffff)) (r.heard (((291 (222 173) false)))) (r.violations ())) |}]
;;

let%expect_test "planted firmware bugs: each is caught" =
  let mutate source ~pattern ~with_ =
    let m = String.substr_replace_all source ~pattern ~with_ in
    assert (not (String.equal m source));
    m
  in
  let rx = mutate Firmware.can_rx
  and tx = mutate Firmware.can_tx in
  let caught ?rx ?tx () =
    let rng = Random.State.make [| 5 |] in
    List.exists (List.range 1 31) ~f:(fun trial ->
      let chip_frames = List.init (1 + Random.State.int rng 3) ~f:(fun _ -> random_frame rng) in
      let node_frames =
        List.init (1 + Random.State.int rng 2) ~f:(fun _ -> random_frame rng)
        |> List.filter ~f:(fun (id, _) -> not (List.exists chip_frames ~f:(fun (i, _) -> i = id)))
      in
      match check ?rx ?tx ~bit:(79 + (trial % 3)) ~contend:(trial % 2 = 0) ~chip_frames ~node_frames () with
      | _, ok -> not ok
      | exception _ -> true)
  in
  List.iter
    [ "receiver never resynchronises", caught ~rx:(rx ~pattern:"jmp !x dom" ~with_:"jmp dom") ()
    ; ( "receiver's run of recessive bits never reset"
      , caught ~rx:(rx ~pattern:"dom:    set y, 7" ~with_:"dom:    nop     ") () )
    ; "frame ended after 4 recessive bits", caught ~rx:(rx ~pattern:"set y, 7" ~with_:"set y, 3") ()
    ; ( "receiver a tick short when no word is pushed"
      , caught ~rx:(rx ~pattern:"nf:     jmp smp [1]" ~with_:"nf:     jmp smp") () )
    ; "transmitter's bits 11 ticks long", caught ~tx:(tx ~pattern:"mov pins, x [2]" ~with_:"mov pins, x [3]") ()
    ; ( "transmitter never checks the bus"
      , caught
          ~tx:(tx ~pattern:"wait 1 pin 0 timeout    ; recessive: the bus" ~with_:"nop                     ; recessive: the bus")
          () )
    ; "transmitter does not wait for an idle bus", caught ~tx:(tx ~pattern:"set y, 10" ~with_:"set y, 0") ()
    ; ( "words of a stopped frame left in the FIFO"
      , caught ~tx:(tx ~pattern:"jmp y-- d\n" ~with_:"nop\n") () )
    ; ( "ACK reported as never acknowledged"
      , caught ~tx:(tx ~pattern:"in y, 16                ; mid-frame" ~with_:"in x, 16                ; mid-frame") () )
    ]
    ~f:(fun (name, caught) -> printf "%-46s %s\n" name (if caught then "caught" else "MISSED"));
  [%expect {|
    receiver never resynchronises                  caught
    receiver's run of recessive bits never reset   caught
    frame ended after 4 recessive bits             caught
    receiver a tick short when no word is pushed   caught
    transmitter's bits 11 ticks long               caught
    transmitter never checks the bus               caught
    transmitter does not wait for an idle bus      caught
    words of a stopped frame left in the FIFO      caught
    ACK reported as never acknowledged             caught
    |}]
;;
