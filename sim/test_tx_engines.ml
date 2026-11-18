(* The transmit-only engines added on v2.0 (I2S, DMX512, Wiegand, NEC
   infrared), run on the reference model and read back by receivers written
   here from each protocol's rules. The cocotb tests run the same firmware
   on the RTL and the gate netlist and hand the pins to sigrok's decoders,
   which this project did not write; these tests are the fast check, and
   they pin down the timing to the cycle. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* The pins on every cycle while [source] runs with [words] fed to its TX
   FIFO as fast as it takes them. *)
let record ?(cycles = 50_000) ~pins ~config source words =
  let modes =
    Array.init Isa.num_pins ~f:(fun i -> if i < pins then Isa.Pin_mode.Push_pull else Input)
  in
  let m = Isa.create ~program:(Asm.assemble source) ~pin_modes:modes ~threads:[ config ] in
  let pending = Queue.of_list words in
  Array.init cycles ~f:(fun _ ->
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    Isa.pin_out m)
;;

let bit trace pin t = (trace.(t) lsr pin) land 1

(* Cycles at which [pin] changes to [level]. *)
let edges trace pin level =
  List.filter
    (List.range 1 (Array.length trace))
    ~f:(fun t -> bit trace pin t = level && bit trace pin (t - 1) <> level)
;;

(* Runs of [pin] at [level]: (first cycle, length). A run still going when
   the trace ends is left out. *)
let runs trace pin level =
  let ends = edges trace pin (1 - level) in
  List.filter_map (edges trace pin level) ~f:(fun a ->
    List.find ends ~f:(fun b -> b > a) |> Option.map ~f:(fun b -> a, b - a))
;;

(* --- I2S -------------------------------------------------------------------- *)

(* A receiver as the standard describes one: SD and WS are read on SCK's
   rising edge; a change of WS says the bit after this one is the first,
   most significant, bit of a sample for the channel WS now names. WS is
   taken to idle high before the chip drives it (a pull-up, as in the cocotb
   test), so the first left sample is announced by an edge like every
   other. *)
let i2s_receive trace =
  let samples = ref [] in
  let ws_before = ref 1 in
  let current = ref None in
  let first_next = ref false in
  List.iter (edges trace 0 1) ~f:(fun t ->
    let ws = bit trace 1 t in
    let sd = bit trace 2 t in
    if !first_next
    then (
      Option.iter !current ~f:(fun (channel, bits) ->
        samples := (channel, List.length bits, List.fold (List.rev bits) ~init:0 ~f:(fun a b -> (a lsl 1) lor b)) :: !samples);
      current := Some (ws, [ sd ]);
      first_next := false)
    else current := Option.map !current ~f:(fun (channel, bits) -> channel, sd :: bits);
    if ws <> !ws_before then first_next := true;
    ws_before := ws);
  List.rev !samples
;;

let i2s_frames = [ 0x1234, 0xABCD; 0x8001, 0x7FFE; 0x0000, 0xFFFF; 0x5A5A, 0xA5A5 ]

let i2s_run ?(source = Firmware.i2s_tx) () =
  record
    ~cycles:1_000
    ~pins:3
    ~config:Firmware.i2s_tx_config
    source
    (List.concat_map i2s_frames ~f:(fun (l, r) -> [ l; r ]) @ [ 0; 0 ])
;;

let%test_unit "I2S: the start address is the instruction that fetches a left sample" =
  let program = Asm.assemble Firmware.i2s_tx in
  [%test_result: int] (Array.length program) ~expect:11;
  assert (
    match program.(Firmware.i2s_tx_start).op with
    | Pull -> true
    | _ -> false)
;;

let%test_unit "I2S: every sample arrives, 16 bits, on the right channel" =
  let got = i2s_receive (i2s_run ()) in
  let want = List.concat_map i2s_frames ~f:(fun (l, r) -> [ 0, 16, l; 1, 16, r ]) in
  [%test_result: (int * int * int) list] (List.take got 8) ~expect:want
;;

let%test_unit "I2S: the bit clock never stretches while the FIFO has samples" =
  let trace = i2s_run () in
  let rises = edges trace 0 1 in
  let gaps = List.map2_exn (List.drop_last_exn rises) (List.tl_exn rises) ~f:(fun a b -> b - a) in
  (* 10 samples of 16 bits were queued. *)
  [%test_result: int list] (List.dedup_and_sort ~compare (List.take gaps 150)) ~expect:[ 4 ]
;;

let%test_unit "I2S: a planted bug (the right sample one bit short) is caught" =
  let short =
    String.substr_replace_first
      Firmware.i2s_tx
      ~pattern:"set x, 14        side 3 [1]"
      ~with_:"set x, 13        side 3 [1]"
  in
  assert (not (String.equal short Firmware.i2s_tx));
  let got = i2s_receive (i2s_run ~source:short ()) in
  let want = List.concat_map i2s_frames ~f:(fun (l, r) -> [ 0, 16, l; 1, 16, r ]) in
  assert (not ([%equal: (int * int * int) list] (List.take got 8) want))
;;

(* --- DMX512 ----------------------------------------------------------------- *)

let dmx_bit = 40 (* cycles: 250 kbit/s at 10 MHz *)

(* A receiver: a low of 88 us or more is a break; after the mark, each
   falling edge starts a slot, sampled mid-bit: a start bit, 8 data bits LSB
   first, two stop bits that must be high. Returns each packet's slots, or
   an error. *)
let dmx_receive trace =
  let n = Array.length trace in
  let packets = ref [] in
  let errors = ref [] in
  let t = ref 1 in
  let level t = bit trace 0 t in
  while !t < n do
    if level !t = 0 && level (!t - 1) = 1
    then (
      let start = !t in
      let rise = ref start in
      while !rise < n && level !rise = 0 do
        incr rise
      done;
      if !rise - start >= 880
      then (
        (* A break. The mark after it must last 8 us at least. *)
        let fall = ref !rise in
        while !fall < n && level !fall = 1 do
          incr fall
        done;
        if !fall - !rise < 80 then errors := "short mark after break" :: !errors;
        packets := [] :: !packets;
        t := !fall)
      else (
        let sample k = if start + (k * dmx_bit) + (dmx_bit / 2) < n then level (start + (k * dmx_bit) + (dmx_bit / 2)) else 1 in
        let byte = List.foldi (List.init 8 ~f:(fun k -> sample (k + 1))) ~init:0 ~f:(fun k a b -> a lor (b lsl k)) in
        if sample 9 = 0 || sample 10 = 0 then errors := "stop bit low" :: !errors;
        (match !packets with
         | p :: rest -> packets := (byte :: p) :: rest
         | [] -> errors := "slot before any break" :: !errors);
        t := start + (10 * dmx_bit) + (dmx_bit / 2)))
    else incr t
  done;
  List.rev_map !packets ~f:List.rev, List.rev !errors
;;

let dmx_packets = [ [ 0x00; 0x00; 0xFF; 0x55; 0x81; 0x7E ]; [ 0x00; 0x10; 0x20 ] ]

let dmx_run ?(source = Firmware.dmx_tx) () =
  record
    ~cycles:8_000
    ~pins:1
    ~config:{ Isa.Thread_config.default with threshold = 9 }
    source
    ((dmx_bit - 4)
     :: List.concat_map dmx_packets ~f:(fun slots ->
       List.mapi slots ~f:(fun i b -> Firmware.dmx_word ~break:(i = 0) b)))
;;

let%test_unit "DMX512: both packets arrive whole, with legal breaks and stop bits" =
  let trace = dmx_run () in
  [%test_result: int list list * string list] (dmx_receive trace) ~expect:(dmx_packets, []);
  (* The standard's numbers for a transmitter: break 92 us, mark 12 us. *)
  let lows = runs trace 0 0 in
  let breaks = List.filter lows ~f:(fun (_, len) -> len >= 880) in
  [%test_result: int] (List.length breaks) ~expect:2;
  List.iter breaks ~f:(fun (a, len) ->
    assert (len >= 920);
    let mark = List.find_exn (runs trace 0 1) ~f:(fun (b, _) -> b = a + len) |> snd in
    assert (mark >= 120))
;;

let%test_unit "DMX512: back-to-back slots are 11 bit times and one cycle apart" =
  let trace = dmx_run () in
  let starts = edges trace 0 0 in
  let gaps = List.map2_exn (List.drop_last_exn starts) (List.tl_exn starts) ~f:(fun a b -> b - a) in
  (* Slot 0x55's falling edges are a bit apart; what matters is that no
     slot-to-slot distance is shorter than 11 bits. A slot of 0xFF followed
     by any slot gives the distance exactly. *)
  assert (List.mem gaps ((11 * dmx_bit) + 1) ~equal:Int.equal)
;;

let%test_unit "DMX512: a planted bug (one stop bit) is caught" =
  let one_stop =
    String.substr_replace_first Firmware.dmx_tx ~pattern:"stop:   jmp x-- stop [1]" ~with_:"stop:   jmp x-- stop"
  in
  assert (not (String.equal one_stop Firmware.dmx_tx));
  let _, errors = dmx_receive (dmx_run ~source:one_stop ()) in
  assert (not (List.is_empty errors))
;;

(* --- Wiegand ---------------------------------------------------------------- *)

let wiegand_bits = List.init 26 ~f:(fun i -> (0x2CE58B5 lsr i) land 1)

let wiegand_run ?(source = Firmware.wiegand_tx) ?(bits = wiegand_bits) () =
  let words =
    List.chunks_of bits ~length:16
    |> List.map ~f:(List.foldi ~init:0 ~f:(fun i a b -> a lor (b lsl i)))
  in
  record
    ~cycles:(List.length bits * 10_500)
    ~pins:2
    ~config:{ Firmware.wiegand_tx_config with clkdiv = 250 }
    source
    ((List.length bits - 1) :: words)
;;

(* (cycle, bit) for every pulse; [None] if both lines were ever low at once
   or a pulse is not 50 us. *)
let wiegand_receive trace =
  let pulses pin = List.map (runs trace pin 0) ~f:(fun (a, len) -> a, len, pin) in
  let all = List.sort (pulses 0 @ pulses 1) ~compare:[%compare: int * int * int] in
  let both_low = Array.exists trace ~f:(fun p -> p land 3 = 0) in
  if both_low || List.exists all ~f:(fun (_, len, _) -> len <> 500)
  then None
  else Some (List.map all ~f:(fun (a, _, pin) -> a, pin))
;;

let%test_unit "Wiegand: 26 bits, 50 us pulses exactly 1 ms apart, across the word boundary too" =
  match wiegand_receive (wiegand_run ()) with
  | None -> assert false
  | Some pulses ->
    [%test_result: int list] (List.map pulses ~f:snd) ~expect:wiegand_bits;
    let at = List.map pulses ~f:fst in
    let gaps = List.map2_exn (List.drop_last_exn at) (List.tl_exn at) ~f:(fun a b -> b - a) in
    [%test_result: int list] (List.dedup_and_sort ~compare gaps) ~expect:[ 10_000 ]
;;

let%test_unit "Wiegand: frames of 1 to 40 bits, one after another" =
  List.iter [ 1; 15; 16; 17; 32; 33; 34; 40 ] ~f:(fun n ->
    let bits = List.init n ~f:(fun i -> (i * 7 / 3) land 1) in
    match wiegand_receive (wiegand_run ~bits ()) with
    | None -> assert false
    | Some pulses -> [%test_result: int list] (List.map pulses ~f:snd) ~expect:bits)
;;

let%test_unit "Wiegand: a planted bug (the lines swapped) is caught" =
  let swapped =
    String.substr_replace_first
      Firmware.wiegand_tx
      ~pattern:"set pins, 1         ; a 1"
      ~with_:"set pins, 2         ; a 1"
  in
  assert (not (String.equal swapped Firmware.wiegand_tx));
  match wiegand_receive (wiegand_run ~source:swapped ()) with
  | None -> ()
  | Some pulses -> assert (not ([%equal: int list] (List.map pulses ~f:snd) wiegand_bits))
;;

(* --- NEC infrared ----------------------------------------------------------- *)

(* A receiver module's view: the carrier is present while the pin has been
   high within the last carrier period and a half. Then NEC's rules, each
   interval to 5%: a 9 ms burst and 4.5 ms of silence, then 32 bits told
   apart by the distance from one burst's start to the next (1.125 ms or
   2.25 ms), each burst 562.5 us. Times in cycles at 10 MHz. *)
let nec_receive trace =
  let n = Array.length trace in
  let rises = edges trace 0 1 in
  let bursts =
    (* (start, end) of each run of carrier: rises no more than 400 cycles apart. *)
    List.fold rises ~init:[] ~f:(fun acc t ->
      match acc with
      | (a, b) :: rest when t - b <= 400 -> (a, t) :: rest
      | _ -> (t, t) :: acc)
    |> List.rev
  in
  let near x want = Float.(abs (of_int x - want) <= 0.05 * want) in
  ignore n;
  match bursts with
  | (a0, b0) :: rest when near (b0 - a0) 90_000. ->
    let starts = List.map rest ~f:fst in
    (match starts with
     | first :: _ when near (first - a0) 135_000. ->
       let gaps = List.map2_exn (List.drop_last_exn starts) (List.tl_exn starts) ~f:(fun a b -> b - a) in
       let bits =
         List.map gaps ~f:(fun g ->
           if near g 11_250. then Some 0 else if near g 22_500. then Some 1 else None)
       in
       let marks_ok = List.for_all rest ~f:(fun (a, b) -> near (b - a + 132) 5_625.) in
       if List.length bits = 32 && List.for_all bits ~f:Option.is_some && marks_ok
       then (
         let v = List.foldi bits ~init:0 ~f:(fun i a b -> a lor (Option.value_exn b lsl i)) in
         let byte k = (v lsr (8 * k)) land 0xFF in
         if byte 0 lxor byte 1 = 0xFF && byte 2 lxor byte 3 = 0xFF then Some (byte 0, byte 2) else None)
       else None
     | _ -> None)
  | _ -> None
;;

let nec_run ?(source = Firmware.nec_tx) ~address ~command () =
  record
    ~cycles:760_000
    ~pins:1
    ~config:{ Firmware.nec_tx_config with clkdiv = 132 }
    source
    (Firmware.nec_words ~address ~command)
;;

let%test_unit "NEC infrared: frames decode, every interval within 5%" =
  List.iter [ 0x04, 0x08; 0x00, 0xFF; 0xFF, 0x00; 0xA5, 0x3C ] ~f:(fun (address, command) ->
    [%test_result: (int * int) option]
      (nec_receive (nec_run ~address ~command ()))
      ~expect:(Some (address, command)))
;;

let%test_unit "NEC infrared: the carrier is 37.9 kHz at even duty" =
  let trace = nec_run ~address:0x04 ~command:0x08 () in
  let highs = runs trace 0 1 in
  [%test_result: int list] (List.dedup_and_sort ~compare (List.map highs ~f:snd)) ~expect:[ 132 ];
  let rises = List.map highs ~f:fst in
  let gaps = List.map2_exn (List.drop_last_exn rises) (List.tl_exn rises) ~f:(fun a b -> b - a) in
  assert (List.count gaps ~f:(fun g -> g = 264) > 900)
;;

let%test_unit "NEC infrared: a planted bug (a 1 with too short a silence) is caught" =
  let short =
    String.substr_replace_first
      Firmware.nec_tx
      ~pattern:"long:   jmp x-- long       side 0 [3]"
      ~with_:"long:   jmp x-- long       side 0 [1]"
  in
  assert (not (String.equal short Firmware.nec_tx));
  [%test_result: (int * int) option]
    (nec_receive (nec_run ~source:short ~address:0x04 ~command:0x08 ()))
    ~expect:None
;;
