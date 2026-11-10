(* The 1-Wire bus engine ([Firmware.onewire]) on the model chip, against
   devices modelled here from the 1-Wire timing rules (Maxim application
   note 126 and the DS18B20 data sheet), not from the firmware. The ROM
   commands, search and CRC live in the board driver and are tested in
   cocotb against a third-party slave model (test/onewire_slave_model.v).

   Every device draws its timing at random from the range the rules allow:
   when it samples the host's bit (15 to 60 us into a slot), how long it
   holds the line low to send a 0 (15 to 60 us), how long it waits after a
   reset before its presence pulse (15 to 60 us), and how long that pulse
   lasts (60 to 240 us). Whatever they draw, the host's samples must be the
   wired-AND of what it wrote and what every device sent, each device must
   read the same, and the host's own pulses must meet the rules:
     reset low at least 480 us, then at least 480 us before the next slot;
     a 1's low time 1 to 15 us, a 0's 60 to 120 us;
     at least 1 us high between slots, 60 to 120 us from one slot's start
     to the end of its recovery. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let us = 10 (* core cycles per microsecond: a 10 MHz core clock, CLKDIV 10 *)

let modes =
  Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Open_drain else Input)
;;

type timing =
  { sample_at : int (* us after a slot's falling edge *)
  ; hold : int (* us a 0 is held low *)
  ; presence_wait : int (* us after the reset pulse ends *)
  ; presence_low : int
  }
[@@deriving sexp_of]

type state =
  | Idle
  | Slot of
      { since : int (* the line fell at this cycle *)
      ; mutable risen : bool
      }
  | Presence of { from : int } (* the reset pulse ended at this cycle *)

type device =
  { t : timing
  ; mutable bits : bool list (* to send in the coming slots; 1 when empty *)
  ; mutable sending_zero : bool
  ; mutable taken : bool option (* the bit taken at the last falling edge *)
  ; mutable state : state
  ; seen : bool Queue.t (* the line, at its sample point in each slot *)
  ; mutable resets : int
  }

let device t bits =
  { t
  ; bits
  ; sending_zero = false
  ; taken = None
  ; state = Idle
  ; seen = Queue.create ()
  ; resets = 0
  }
;;

(* Whether [d] pulls the line low in cycle [c]. *)
let pulls d c =
  match d.state with
  | Slot { since; _ } -> d.sending_zero && c - since < d.t.hold * us
  | Presence { from } ->
    let k = c - from in
    k >= d.t.presence_wait * us && k < (d.t.presence_wait + d.t.presence_low) * us
  | Idle -> false
;;

(* Advance [d] after cycle [c], given the line before and during it. *)
let observe d c ~prev ~line =
  match d.state with
  | Idle ->
    if prev && not line
    then (
      (* A device cannot tell a reset from a slot when the line falls, so
         it starts a slot; if the line stays low long enough to be a reset,
         the bit goes back. *)
      (match d.bits with
       | b :: rest ->
         d.sending_zero <- not b;
         d.taken <- Some b;
         d.bits <- rest
       | [] ->
         d.sending_zero <- false;
         d.taken <- None);
      d.state <- Slot { since = c; risen = false })
  | Slot ({ since; risen } as slot) ->
    (* The device keeps its own time: it samples [sample_at] after the
       fall whenever the line rose, and is done once it has sampled and
       released. *)
    let k = c - since in
    if k = d.t.sample_at * us then Queue.enqueue d.seen line;
    if line && (not risen) && k >= 480 * us
    then (
      d.resets <- d.resets + 1;
      Option.iter d.taken ~f:(fun b -> d.bits <- b :: d.bits);
      Queue.clear d.seen;
      d.state <- Presence { from = c })
    else (
      if line then slot.risen <- true;
      if slot.risen && k > d.t.sample_at * us && k >= d.t.hold * us then d.state <- Idle)
  | Presence { from } ->
    if c - from >= (d.t.presence_wait + d.t.presence_low) * us then d.state <- Idle
;;

type exchange =
  | Reset
  | Slots of bool list
[@@deriving sexp_of]

let word = function
  | Reset -> Firmware.onewire_reset_word
  | Slots bits -> Firmware.onewire_slots_word bits
;;

type outcome =
  { rx : int list
  ; seen : bool list list (* per device, since its last reset *)
  ; violations : string list
  }

(* Runs [exchanges] with [devices] on the bus and checks the host's pulse
   timing as it goes. *)
let run ?(source = Firmware.onewire) ~exchanges devices =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ { Firmware.onewire_config with clkdiv = us } ]
  in
  let pending = Queue.of_list (List.map exchanges ~f:word) in
  let rx = Queue.create () in
  let violations = Queue.create () in
  let violate fmt = ksprintf (fun s -> Queue.enqueue violations s) fmt in
  let line_prev = ref true
  and host_low_since = ref None
  and last_fall = ref None
  and last_rise = ref None
  and after_reset = ref false
  and cycle = ref 0 in
  let n = List.length exchanges in
  while Queue.length rx < n && !cycle < 2_000_000 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    let c = !cycle in
    let device_low = List.exists devices ~f:(fun d -> pulls d c) in
    let host_low = Isa.pin_out m land 1 = 0 in
    let line = not (host_low || device_low) in
    List.iter devices ~f:(fun d -> observe d c ~prev:!line_prev ~line);
    line_prev := line;
    (* The host's own pulses: what it drives, whatever the devices do. *)
    (match !host_low_since, host_low with
     | None, true ->
       (match !last_rise, !last_fall with
        | Some r, Some f ->
          let high = c - r in
          if !after_reset && high < 480 * us
          then violate "only %d cycles after a reset before the next pulse" high;
          if high < 1 * us then violate "recovery of %d cycles" high;
          if (not !after_reset) && c - f < 61 * us
          then violate "slot of %d cycles" (c - f)
        | _ -> ());
       host_low_since := Some c;
       last_fall := Some c
     | Some since, false ->
       let low = c - since in
       let ok =
         low >= 480 * us
         || (low >= 1 * us && low < 15 * us)
         || (low >= 60 * us && low < 120 * us)
       in
       if not ok then violate "host held the line low %d cycles" low;
       after_reset := low >= 480 * us;
       host_low_since := None;
       last_rise := Some c
     | _ -> ());
    let inputs = 0xFE lor Bool.to_int (not device_low) in
    Isa.step m ~inputs;
    incr cycle
  done;
  if Queue.length rx < n then violate "only %d of %d exchanges finished" (Queue.length rx) n;
  { rx = Queue.to_list rx
  ; seen = List.map devices ~f:(fun d -> Queue.to_list d.seen)
  ; violations = Queue.to_list violations
  }
;;

(* What the host must read: for a reset, 0 if any device is present; for
   slots, the wired-AND of its bits and every device's. In a slot where no
   device sends a 0, the host is writing, and every device must read the
   host's bit (since its last reset); a slot where some device sends a 0 is
   a read, and what a device samples then is not defined, so it is [None]. *)
let expected ~exchanges ~sends =
  let sends = Array.of_list sends in
  let pos = ref 0 in
  let heard = ref [] in
  let rx =
    List.map exchanges ~f:(function
      | Reset ->
        heard := [];
        if Array.is_empty sends then 1 else 0
      | Slots bits ->
        let got, written =
          List.unzip
            (List.map bits ~f:(fun b ->
               let k = !pos in
               incr pos;
               let all_ones =
                 Array.for_all sends ~f:(fun s -> Option.value (List.nth s k) ~default:true)
               in
               all_ones && b, if all_ones then Some b else None))
        in
        heard := !heard @ written;
        List.foldi got ~init:0 ~f:(fun k acc v -> acc lor (Bool.to_int v lsl k)))
  in
  rx, !heard
;;

let timing_gen =
  let open Quickcheck.Generator.Let_syntax in
  let%map sample_at = Int.gen_incl 15 60
  and hold = Int.gen_incl 15 60
  and presence_wait = Int.gen_incl 15 60
  and presence_low = Int.gen_incl 60 240 in
  { sample_at; hold; presence_wait; presence_low }
;;

let exchanges_gen =
  let open Quickcheck.Generator.Let_syntax in
  let slots =
    let%bind n = Int.gen_incl 1 8 in
    let%map bits = List.gen_with_length n Bool.quickcheck_generator in
    Slots bits
  in
  let%map rest = List.gen_with_length 4 slots
  and more = Bool.quickcheck_generator in
  (Reset :: rest) @ if more then [ Reset; Slots [ true; false; true ] ] else []
;;

(* Each device's bits to send, one per slot from its first. *)
let check ?source ~exchanges ~devices () =
  let sends = List.map devices ~f:(fun (_, s) -> s) in
  let ds = List.map devices ~f:(fun (t, s) -> device t s) in
  let r = run ?source ~exchanges ds in
  let want_rx, heard = expected ~exchanges ~sends in
  (* Each device's samples, kept only where the host was writing. *)
  let seen =
    List.map r.seen ~f:(fun s ->
      match List.map2 s heard ~f:(fun got want -> Option.map want ~f:(fun _ -> got)) with
      | Ok l -> l
      | Unequal_lengths -> List.map s ~f:Option.some (* a slot missed *))
  in
  r, want_rx, seen, List.map ds ~f:(fun _ -> heard)
;;

let%test_unit "program: 25 words" =
  [%test_result: int] (Array.length (Asm.assemble Firmware.onewire)) ~expect:25
;;

let%test_unit "random exchanges, 0 to 3 devices with random legal timing" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2
       exchanges_gen
       (List.gen_with_length
          3
          (Quickcheck.Generator.tuple2
             timing_gen
             (List.gen_with_length 40 Bool.quickcheck_generator))))
    ~trials:120
    ~sexp_of:[%sexp_of: exchange list * (timing * bool list) list]
    ~f:(fun (exchanges, devs) ->
      List.iter [ 0; 1; 3 ] ~f:(fun k ->
        let devices = List.take devs k in
        let r, want_rx, seen, want_seen = check ~exchanges ~devices () in
        [%test_result: string list] r.violations ~expect:[];
        [%test_result: int list] r.rx ~expect:want_rx;
        [%test_result: bool option list list] seen ~expect:want_seen))
;;

(* The tightest legal devices: a 0 held only 15 us, the latest and shortest
   presence pulse, and a device that samples as early as allowed. *)
let%test_unit "the tightest legal device timing" =
  let t = { sample_at = 15; hold = 15; presence_wait = 60; presence_low = 60 } in
  let t' = { sample_at = 60; hold = 60; presence_wait = 15; presence_low = 60 } in
  let exchanges = [ Reset; Slots [ true; true; false; true; true; true; false; true ] ] in
  let devices = [ t, [ false; true; true; false; true; false; true; true ] ] in
  List.iter [ devices; [ t', snd (List.hd_exn devices) ] ] ~f:(fun devices ->
    let r, want_rx, seen, want_seen = check ~exchanges ~devices () in
    [%test_result: string list] r.violations ~expect:[];
    [%test_result: int list] r.rx ~expect:want_rx;
    [%test_result: bool option list list] seen ~expect:want_seen)
;;

let%expect_test "planted firmware bugs: each is caught" =
  let mutate ~pattern ~with_ =
    let m = String.substr_replace_first Firmware.onewire ~pattern ~with_ in
    assert (not (String.equal m Firmware.onewire));
    m
  in
  let tight = { sample_at = 15; hold = 15; presence_wait = 60; presence_low = 60 } in
  let exchanges =
    [ Reset; Slots [ true; true; false; true; true; true; true; true ]; Reset; Slots [ true ] ]
  in
  let devices = [ tight, [ false; true; true; false; true; true; true; true; true; false ] ] in
  List.iter
    [ "reset pulse too short", mutate ~pattern:"set y, 29" ~with_:"set y, 28"
    ; "presence sampled too early", mutate ~pattern:"set y, 3 [2]" ~with_:"set y, 2 [2]"
    ; "slot sampled too late", mutate ~pattern:"out pins, 1 [8]" ~with_:"out pins, 1 [9]"
    ; "a 0 held too briefly", mutate ~pattern:"set y, 2\n" ~with_:"set y, 1\n"
    ; "too little rest after a reset", mutate ~pattern:"set y, 24" ~with_:"set y, 23"
    ; "slots ignore the bits", mutate ~pattern:"out pins, 1 [8]" ~with_:"out null, 1 [8]"
    ]
    ~f:(fun (name, source) ->
      let r, want_rx, seen, want_seen = check ~source ~exchanges ~devices () in
      let ok =
        List.is_empty r.violations
        && [%equal: int list] r.rx want_rx
        && [%equal: bool option list list] seen want_seen
      in
      printf "%-32s %s\n" name (if ok then "MISSED" else "caught"));
  [%expect {|
    reset pulse too short            caught
    presence sampled too early       caught
    slot sampled too late            caught
    a 0 held too briefly             caught
    too little rest after a reset    caught
    slots ignore the bits            caught
    |}]
;;
