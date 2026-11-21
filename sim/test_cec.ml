(* The HDMI-CEC initiator ([Firmware.cec]) against a follower written here
   from the CEC specification's timing table: what a receiver must accept
   and what it must reject. The cocotb test runs the same firmware on the
   RTL and the gate netlist with sigrok's CEC decoder reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let clkdiv = 1000 (* 10 MHz: a tick is 0.1 ms *)
let ms x = Float.to_int (x *. 10_000.)

(* A follower at [address]. It times every pulse against the limits a
   receiver works to, collects blocks, and acknowledges those of a message
   sent to it by holding the line low for 1.5 ms from the ACK bit's edge. *)
module Follower = struct
  type t =
    { address : int
    ; mutable line : bool
    ; mutable now : int
    ; mutable fell : int option (* when the pulse in progress began *)
    ; mutable low : int (* how long it stayed low *)
    ; mutable in_message : bool
    ; mutable bits : int list (* of this block, newest first *)
    ; mutable blocks : int list (* of this message, newest first *)
    ; mutable for_me : bool
    ; mutable hold_until : int (* drive low until then *)
    ; mutable ack_bit : bool (* the pulse in progress is an ACK bit *)
    ; mutable messages : int list list
    ; mutable errors : string list
    }

  let create ~address =
    { address
    ; line = true
    ; now = 0
    ; fell = None
    ; low = 0
    ; in_message = false
    ; bits = []
    ; blocks = []
    ; for_me = false
    ; hold_until = 0
    ; ack_bit = false
    ; messages = []
    ; errors = []
    }
  ;;

  let drive t = t.now < t.hold_until
  let error t s = t.errors <- s :: t.errors
  let within v lo hi = v >= ms lo && v <= ms hi

  (* A pulse is over: it began at [fell], was low for [low], and the next
     began (or the line was given up on) [period] after it. *)
  let pulse t ~low ~period =
    if t.ack_bit
    then (
      t.ack_bit <- false;
      (* Ours to answer; only its length is checked. *)
      (match period with
       | Some p when not (within p 2.05 2.75) -> error t (sprintf "ACK bit %d cycles long" p)
       | _ -> ());
      t.bits <- [])
    else if within low 3.5 3.9 && Option.for_all period ~f:(fun p -> within p 4.3 4.7)
    then (
      (* A start bit begins a message whenever it comes: one given up
         part way leaves nothing behind. *)
      t.in_message <- true;
      t.bits <- [];
      t.blocks <- [])
    else if not t.in_message
    then error t (sprintf "not a start bit: low %d cycles" low)
    else (
      let bit =
        if within low 0.4 0.8
        then Some 1
        else if within low 1.3 1.7
        then Some 0
        else None
      in
      match bit, period with
      | None, _ ->
        error t (sprintf "a bit low for %d cycles" low);
        t.in_message <- false
      | Some _, Some p when not (within p 2.05 2.75) ->
        error t (sprintf "a bit %d cycles long" p);
        t.in_message <- false
      | Some b, _ -> t.bits <- b :: t.bits)
  ;;

  (* A falling edge: the tenth bit of a block is its ACK bit. *)
  let falling t =
    if t.in_message && List.length t.bits = 9
    then (
      let eom, data =
        match t.bits with
        | eom :: data -> eom, List.fold (List.rev data) ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b)
        | [] -> assert false
      in
      if List.is_empty t.blocks then t.for_me <- data land 0xF = t.address;
      t.blocks <- data :: t.blocks;
      t.ack_bit <- true;
      if t.for_me then t.hold_until <- t.now + ms 1.5;
      if eom = 1
      then (
        t.messages <- List.rev t.blocks :: t.messages;
        t.in_message <- false))
  ;;

  let step t ~line =
    t.now <- t.now + 1;
    (match t.line, line with
     | true, false ->
       Option.iter t.fell ~f:(fun fell -> pulse t ~low:t.low ~period:(Some (t.now - fell)));
       t.fell <- Some t.now;
       falling t
     | false, true -> Option.iter t.fell ~f:(fun fell -> t.low <- t.now - fell)
     | true, true ->
       (* Idle for longer than any bit: the last pulse had no successor. *)
       Option.iter t.fell ~f:(fun fell ->
         if t.now - fell > ms 5.0
         then (
           pulse t ~low:t.low ~period:None;
           t.fell <- None))
     | false, false -> ());
    t.line <- line
  ;;
end

type outcome =
  { follower : Follower.t
  ; reports : int list
  ; gaps : int list (* cycles of idle line between messages *)
  }

(* Send [messages] (each the TX words of one) with the host keeping the
   FIFO fed. *)
let run ?(source = Firmware.cec) ?(address = 4) messages =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Open_drain else Input))
      ~threads:[ Firmware.cec_config ~clkdiv ]
  in
  let follower = Follower.create ~address in
  let pending = Queue.of_list (List.concat messages) in
  let blocks = Queue.length pending in
  let reports = Queue.create () in
  let high = ref 0 in
  let gaps = Queue.create () in
  for _ = 1 to ms 4.5 + (blocks * ms 24.0) + (List.length messages * ms 22.0) do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    let inputs = if Follower.drive follower then 0xFE else 0xFF in
    Isa.step m ~inputs;
    let line = Isa.lines m ~inputs land 1 = 1 in
    if line
    then incr high
    else (
      if !high > ms 5.0 then Queue.enqueue gaps !high;
      high := 0);
    Follower.step follower ~line;
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue reports)
  done;
  { follower; reports = Queue.to_list reports; gaps = Queue.to_list gaps }
;;

let message ~destination data = Firmware.cec_words ~initiator:1 ~destination data
let blocks ~destination data = ((1 lsl 4) lor destination) :: data

let%expect_test "messages to a follower, to an address nobody has, and to everyone" =
  let sent = [ 4, [ 0x04 ]; 5, [ 0x8F ]; 15, [ 0x82; 0x10; 0x00 ]; 4, [] ] in
  let r = run (List.map sent ~f:(fun (destination, data) -> message ~destination data)) in
  printf !"errors: %{sexp:string list}\n" r.follower.errors;
  List.iter (List.rev r.follower.messages) ~f:(fun m ->
    printf "heard: %s\n" (String.concat ~sep:":" (List.map m ~f:(sprintf "%02x"))));
  printf !"acknowledged (0) or not (1), block by block: %{sexp:int list}\n" r.reports;
  printf
    !"idle line between messages, in bit times: %{sexp:string list}\n"
    (List.map r.gaps ~f:(fun g -> sprintf "%.1f" (Float.of_int g /. Float.of_int (ms 2.4))));
  (* The message to address 5 ends at its header, which nobody
     acknowledges: the follower never sees a whole message there. *)
  [%test_result: int list list]
    (List.rev r.follower.messages)
    ~expect:
      (List.filter_map sent ~f:(fun (destination, data) ->
         Option.some_if (destination <> 5) (blocks ~destination data)));
  [%expect {|
    errors: ()
    heard: 14:04
    heard: 1f:82:10:00
    heard: 14
    acknowledged (0) or not (1), block by block: (0 0 1 1 1 1 1 0)
    idle line between messages, in bit times: (7.6 8.1 8.0)
    |}]
;;

let%test_unit "random messages: every byte value, lengths 0 to 5" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2
       (Int.gen_incl 0 15)
       (Quickcheck.Generator.list (Int.gen_incl 0 255)))
    ~trials:25
    ~sexp_of:[%sexp_of: int * int list]
    ~f:(fun (destination, data) ->
      let data = List.take data 5 in
      let r = run [ message ~destination data ] in
      [%test_result: string list] r.follower.errors ~expect:[];
      let all = blocks ~destination data in
      (* To the follower: every block acknowledged. To everyone: nobody
         objects. To anyone else: the header goes unanswered and the
         message stops there, unless the header was all of it. *)
      let whole = destination = 4 || destination = 15 || List.is_empty data in
      [%test_result: int list list] r.follower.messages ~expect:(if whole then [ all ] else []);
      [%test_result: int list]
        r.reports
        ~expect:
          (if destination = 4 then List.map all ~f:(fun _ -> 0) else if destination = 15 then List.map all ~f:(fun _ -> 1) else [ 1 ]))
;;

let%expect_test "planted bugs" =
  let sent = [ 4, [ 0x00; 0xFF; 0xA5 ]; 5, [ 0x36 ]; 4, [ 0x5A ] ] in
  let right_reports = [ 0; 0; 0; 0; 1; 0; 0 ] in
  let caught source =
    let r = run ~source (List.map sent ~f:(fun (destination, data) -> message ~destination data)) in
    not
      (List.is_empty r.follower.errors
       && [%equal: int list list]
            (List.rev r.follower.messages)
            (List.filter_map sent ~f:(fun (destination, data) ->
               Option.some_if (destination <> 5) (blocks ~destination data)))
       && [%equal: int list] r.reports right_reports
       && List.for_all r.gaps ~f:(fun g -> g >= 7 * ms 2.4))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.cec ~pattern ~with_ in
    assert (not (String.equal s Firmware.cec));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.cec then "WRONG" else "right");
  List.iter
    [ "a 0 low for 1.2 ms", fw ~pattern:"zero:   nop [8]" ~with_:"zero:   nop [5]"
    ; "a start bit low for 3.2 ms", fw ~pattern:"        nop [4]\n" ~with_:"        nop\n"
    ; ( "the ACK read while the initiator still holds the line"
      , fw
          ~pattern:"set pins, 0 [5]         ; ACK bit: sent as a 1,\n        set pins, 1 [3]\n        in pins, 1 "
          ~with_:"set pins, 0 [4]         ; ACK bit: sent as a 1,\n        in pins, 1\n        set pins, 1 [3] " )
    ; "EOM not looked at: no end to a message", fw ~pattern:"cont:   jmp !x more " ~with_:"cont:   jmp more    "
    ; "a block's first bit 3.1 ms after the ACK bit", fw ~pattern:"more:   pull [2]" ~with_:"more:   pull [9]"
    ; "sends on after a block nobody acknowledged", fw ~pattern:"jmp !y abort" ~with_:"nop         "
    ; ( "an abandoned message's other blocks left in the FIFO"
      , fw ~pattern:"abort:  jmp x-- end " ~with_:"abort:  jmp end     " )
    ; "straight back on the bus after a message", fw ~pattern:"set y, 10 " ~with_:"set y, 0  "
    ; "every bit sent as a 1", fw ~pattern:"jmp !x zero" ~with_:"nop        "
    ]
    ~f:(fun (name, source) -> printf "%-54s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    a 0 low for 1.2 ms                                     caught
    a start bit low for 3.2 ms                             caught
    the ACK read while the initiator still holds the line  caught
    EOM not looked at: no end to a message                 caught
    a block's first bit 3.1 ms after the ACK bit           caught
    sends on after a block nobody acknowledged             caught
    an abandoned message's other blocks left in the FIFO   caught
    straight back on the bus after a message               caught
    every bit sent as a 1                                  caught
    |}]
;;
