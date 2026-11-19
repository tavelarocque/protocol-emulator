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

(* --- MDIO ------------------------------------------------------------------- *)

(* The model's bus has no PHY on it, only the pull-up, so the line is the
   chip's own open-drain output and what the chip shifts in is what it
   shifted out. Returns the pins on every cycle and the RX words. *)
let mdio_run ?(source = Firmware.mdio) words =
  let modes =
    Array.init Isa.num_pins ~f:(fun i ->
      match i with
      | 0 -> Isa.Pin_mode.Push_pull
      | 1 -> Open_drain
      | _ -> Input)
  in
  let m =
    Isa.create ~program:(Asm.assemble source) ~pin_modes:modes ~threads:[ Firmware.mdio_config ]
  in
  let pending = Queue.of_list words in
  let read = ref [] in
  let trace =
    Array.init 600 ~f:(fun _ ->
      (match Queue.peek pending with
       | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
       | None -> ());
      Option.iter (Isa.pop_rx m ~thread:0) ~f:(fun v -> read := v :: !read);
      Isa.step m ~inputs:0xFF;
      Isa.pin_out m)
  in
  trace, List.rev !read
;;

let mdio_frame = [ 0xFFFF; 0xFFFF; Firmware.mdio_header ~read:false ~phy:5 ~reg:0; 0x1140 ]

(* What a PHY needs of a frame: MDIO at each rising edge of MDC spells the
   words out MSB first, and does not move in the cycle before the edge or
   the cycle after it. *)
let mdio_as_a_phy_reads_it trace =
  let rises = edges trace 0 1 in
  let bits = List.map rises ~f:(fun t -> bit trace 1 t) in
  let want =
    List.concat_map mdio_frame ~f:(fun w -> List.init 16 ~f:(fun k -> (w lsr (15 - k)) land 1))
  in
  [%equal: int list] bits want
  && List.for_all rises ~f:(fun t ->
    bit trace 1 (t - 1) = bit trace 1 t && bit trace 1 (t + 1) = bit trace 1 t)
;;

let%test_unit "MDIO: the header is start, write or read, PHY, register, turnaround" =
  [%test_result: int]
    (Firmware.mdio_header ~read:false ~phy:5 ~reg:0)
    ~expect:0b0101_00101_00000_10;
  [%test_result: int]
    (Firmware.mdio_header ~read:true ~phy:31 ~reg:2)
    ~expect:0b0110_11111_00010_11
;;

let%test_unit "MDIO: a write frame as a PHY reads it, and as the chip reads it back" =
  let trace, read = mdio_run mdio_frame in
  assert (mdio_as_a_phy_reads_it trace);
  [%test_result: int list] read ~expect:mdio_frame;
  (* 2.5 MHz at most: rising edges four cycles apart, seven between words. *)
  let rises = edges trace 0 1 in
  let gaps = List.map2_exn (List.drop_last_exn rises) (List.tl_exn rises) ~f:(fun a b -> b - a) in
  [%test_result: int list] (List.dedup_and_sort ~compare gaps) ~expect:[ 4; 7 ]
;;

let%test_unit "MDIO: a planted bug (data changing as the clock rises) is caught" =
  let late =
    String.substr_replace_first
      Firmware.mdio
      ~pattern:"out pins, 1    side 0"
      ~with_:"out pins, 1    side 1"
  in
  assert (not (String.equal late Firmware.mdio));
  assert (not (mdio_as_a_phy_reads_it (fst (mdio_run ~source:late mdio_frame))))
;;

(* --- DALI ------------------------------------------------------------------- *)

let dali_half = 8 * 521 (* cycles: half a bit at 1200 bit/s, CLKDIV 521 *)

let dali_run ?(source = Firmware.dali_tx) words =
  record ~cycles:(List.length words * 350_000) ~pins:1 ~config:{ Firmware.dali_tx_config with clkdiv = 521 } source words
;;

(* Frames as a DALI receiver finds them: the bus falls from idle, and from
   there each bit is two half bits read at their middles: low then high is
   a 1, high then low a 0, anything else an error. A start bit, 16 bits, and
   then the bus must stay high. *)
let dali_receive trace =
  let n = Array.length trace in
  let frames = ref [] in
  let t = ref 1 in
  while !t < n do
    if bit trace 0 !t = 0 && bit trace 0 (!t - 1) = 1
    then (
      let start = !t in
      let half k = bit trace 0 (min (n - 1) (start + (k * dali_half) + (dali_half / 2))) in
      let bits =
        List.init 17 ~f:(fun k ->
          match half (2 * k), half ((2 * k) + 1) with
          | 0, 1 -> Some 1
          | 1, 0 -> Some 0
          | _ -> None)
      in
      let idle = List.for_all [ 34; 35; 36; 37 ] ~f:(fun k -> half k = 1) in
      (frames
       := (match Option.all bits with
           | Some (1 :: data) when idle -> Some (List.fold data ~init:0 ~f:(fun a b -> (a lsl 1) lor b))
           | _ -> None)
          :: !frames);
      t := start + (38 * dali_half))
    else incr t
  done;
  List.rev !frames
;;

let dali_words = [ 0xFF05; 0x02A5; 0x0000; 0xFFFF; 0x5555; 0xAAAA ]

let%test_unit "DALI: frames decode, and every half bit is the same length" =
  let trace = dali_run dali_words in
  [%test_result: int option list] (dali_receive trace) ~expect:(List.map dali_words ~f:Option.some);
  let lengths = List.map (runs trace 0 0) ~f:snd |> List.dedup_and_sort ~compare in
  [%test_result: int list] lengths ~expect:[ dali_half; 2 * dali_half ];
  (* Between frames the bus rests 9.2 ms or more. *)
  let highs = List.map (runs trace 0 1) ~f:snd in
  assert (List.for_all highs ~f:(fun h -> h <= 2 * dali_half || h >= 92_000))
;;

let%test_unit "DALI: a planted bug (a short last half bit after a 0) is caught" =
  let short = String.substr_replace_first Firmware.dali_tx ~pattern:"jmp stop        side 0 [1]" ~with_:"jmp stop        side 0" in
  assert (not (String.equal short Firmware.dali_tx));
  let lengths = List.map (runs (dali_run ~source:short dali_words) 0 0) ~f:snd |> List.dedup_and_sort ~compare in
  assert (not ([%equal: int list] lengths [ dali_half; 2 * dali_half ]))
;;

(* --- RC-5 infrared ---------------------------------------------------------- *)

let rc5_run ?(source = Firmware.rc5_tx) ~toggle ~address ~command () =
  record ~cycles:280_000 ~pins:1 ~config:{ Firmware.rc5_tx_config with clkdiv = 139 } source [ Firmware.rc5_word ~toggle ~address ~command ]
;;

(* Bursts of carrier as (first cycle, carrier periods): rising edges exactly
   one carrier period (278 cycles) apart belong to one burst. *)
let rc5_bursts trace =
  List.fold (edges trace 0 1) ~init:[] ~f:(fun acc t ->
    match acc with
    | (a, n, last) :: rest when t - last = 278 -> (a, n + 1, t) :: rest
    | _ -> (t, 1, t) :: acc)
  |> List.rev_map ~f:(fun (a, n, _) -> a, n)
;;

(* The 14 bits, from RC-5's rules. Each burst must be 32 or 64 carrier
   periods and each silence between bursts one or two half bits, to within
   an eighth of one; that gives the half bits in order, lit or dark, after
   the dark half that begins the first start bit. Dark then lit is a 1, lit
   then dark a 0. *)
let rc5_receive trace =
  let half = 32 * 278 in
  let rec halves = function
    | [] -> Some []
    | (a, n) :: rest ->
      let lit = List.init (n / 32) ~f:(fun _ -> true) in
      (match rest with
       | _ when n <> 32 && n <> 64 -> None
       | [] -> Some lit
       | (next, _) :: _ ->
         let gap = next - (a + (n * 278)) in
         let k = (gap + (half / 2)) / half in
         if (k = 1 || k = 2) && abs (gap - (k * half)) <= half / 8
         then Option.map (halves rest) ~f:(fun tail -> lit @ List.init k ~f:(fun _ -> false) @ tail)
         else None)
  in
  match halves (rc5_bursts trace) with
  | None -> None
  | Some after_first ->
    (* A frame ending in a 0 ends dark, which no burst shows. *)
    let all = (false :: after_first) @ [ false ] in
    let bits =
      List.init 14 ~f:(fun i ->
        match List.nth all (2 * i), List.nth all ((2 * i) + 1) with
        | Some false, Some true -> Some 1
        | Some true, Some false -> Some 0
        | _ -> None)
    in
    Option.map (Option.all bits) ~f:(List.fold ~init:0 ~f:(fun a b -> (a lsl 1) lor b))
;;

let%test_unit "RC-5: frames decode, every burst whole and every silence in time" =
  List.iter [ true, 5, 0x35; false, 0, 0; true, 31, 63; false, 21, 42; true, 10, 21 ] ~f:(fun (toggle, address, command) ->
    let want = (0b11 lsl 12) lor (Bool.to_int toggle lsl 11) lor (address lsl 6) lor command in
    [%test_result: int option] (rc5_receive (rc5_run ~toggle ~address ~command ())) ~expect:(Some want))
;;

let%test_unit "RC-5: a planted bug (a joined burst one period long) is caught" =
  let long = String.substr_replace_first Firmware.rc5_tx ~pattern:"long:   set x, 30" ~with_:"long:   set x, 31" in
  assert (not (String.equal long Firmware.rc5_tx));
  [%test_result: int option] (rc5_receive (rc5_run ~source:long ~toggle:true ~address:5 ~command:0x35 ())) ~expect:None
;;

(* --- Receivers --------------------------------------------------------------- *)

(* The RX words a receiver produces while its input pins follow [levels]
   (one entry per cycle, all eight pins), with [words] fed to its TX FIFO. *)
let receive ?(words = []) ~config source levels =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.create ~len:Isa.num_pins Isa.Pin_mode.Input)
      ~threads:[ config ]
  in
  let pending = Queue.of_list words in
  let read = ref [] in
  Array.iter levels ~f:(fun pins ->
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(fun v -> read := v :: !read);
    Isa.step m ~inputs:pins);
  List.rev !read
;;

(* Pin levels over time from (level of the eight pins, cycles) runs. *)
let waveform runs = Array.concat (List.map runs ~f:(fun (pins, n) -> Array.create ~len:n pins))

(* A reader's lines: idle, then for each bit a low pulse on D0 (pin 0) for
   a 0 or D1 (pin 1) for a 1, then idle again. *)
let wiegand_lines ?(pulse = 500) ?(interval = 10_000) bits =
  waveform
    (((0xFF, 200) :: List.concat_map bits ~f:(fun b -> [ 0xFF land lnot (1 lsl b), pulse; 0xFF, interval - pulse ]))
     @ [ 0xFF, 200 ])
;;

(* What the host makes of the words: 16 bits a word, the first received at
   the top, the last word holding what is left. *)
let wiegand_bits_of ~n words =
  List.concat_mapi words ~f:(fun k w ->
    let width = min 16 (n - (16 * k)) in
    List.init width ~f:(fun i -> (w lsr (width - 1 - i)) land 1))
;;

let wiegand_receive_frame ?(source = Firmware.wiegand_rx) ?pulse ?interval bits =
  let n = List.length bits in
  receive ~words:[ n - 1 ] ~config:Firmware.wiegand_rx_config source (wiegand_lines ?pulse ?interval bits)
  |> wiegand_bits_of ~n
;;

let%test_unit "Wiegand receiver: frames of 1 to 40 bits, pulses of 1 us to 100 us" =
  List.iter [ 1; 2; 15; 16; 17; 26; 31; 32; 33; 34; 40 ] ~f:(fun n ->
    List.iter [ 10, 400; 200, 2_500; 1_000, 5_000 ] ~f:(fun (pulse, interval) ->
      let bits = List.init n ~f:(fun i -> ((i * 5) + (n * 3)) / 7 land 1) in
      [%test_result: int list] (wiegand_receive_frame ~pulse ~interval bits) ~expect:bits))
;;

let%test_unit "Wiegand receiver: one frame after another, each asked for" =
  let a = List.init 26 ~f:(fun i -> (0x2CE58B5 lsr i) land 1) in
  let b = List.init 26 ~f:(fun i -> (0x13A0F5C lsr i) land 1) in
  let words =
    receive
      ~words:[ 25; 25 ]
      ~config:Firmware.wiegand_rx_config
      Firmware.wiegand_rx
      (Array.append (wiegand_lines ~interval:2_000 a) (wiegand_lines ~interval:2_000 b))
  in
  [%test_result: int list] (wiegand_bits_of ~n:26 (List.take words 2)) ~expect:a;
  [%test_result: int list] (wiegand_bits_of ~n:26 (List.drop words 2)) ~expect:b
;;

let%test_unit "Wiegand receiver: a planted bug (D1 never looked at) is caught" =
  let blind =
    String.substr_replace_first Firmware.wiegand_rx ~pattern:"jmp x-- poll        ; high" ~with_:"jmp poll            ; high"
  in
  assert (not (String.equal blind Firmware.wiegand_rx));
  let bits = List.init 26 ~f:(fun i -> (0x2CE58B5 lsr i) land 1) in
  assert (not ([%equal: int list] (wiegand_receive_frame ~source:blind ~interval:2_000 bits) bits))
;;

(* A receiver module's output for an NEC frame, low while it sees carrier:
   16 units of burst, 8 of silence, then for each of [bits] bits of [value],
   LSB first, a burst of one unit and a silence of one (a 0) or three (a 1),
   and a last burst. [unit]: cycles in NEC's 562.5 us. *)
let nec_module_output ?(unit = 5625) ?(bits = 32) value =
  let burst n = 0xFE, n * unit
  and silence n = 0xFF, n * unit in
  waveform
    ([ silence 2; burst 16; silence 8 ]
     @ List.concat (List.init bits ~f:(fun k -> [ burst 1; silence (if (value lsr k) land 1 = 1 then 3 else 1) ]))
     @ [ burst 1; silence 12 ])
;;

let nec_rx ?(source = Firmware.nec_rx) levels =
  receive ~config:{ Firmware.nec_rx_config with clkdiv = 352 } source levels
;;

let%test_unit "NEC receiver: the start address is where a frame is looked for" =
  let program = Asm.assemble Firmware.nec_rx in
  assert (
    match program.(Firmware.nec_rx_start).op, program.(Firmware.nec_rx_start + 1).op with
    | Mov _, Wait _ -> true
    | _ -> false)
;;

let%test_unit "NEC receiver: frames from remotes 23% slow to 23% fast" =
  List.iter [ 4300; 4500; 4800; 5100; 5625; 6100; 6400; 6750; 6900 ] ~f:(fun unit ->
    List.iter [ 0xF708FB04; 0x00FFFF00; 0xFF0000FF; 0x5AA51234; 0x0000FFFF; 0xFFFF0000 ] ~f:(fun value ->
      [%test_result: int list]
        (nec_rx (nec_module_output ~unit value))
        ~expect:[ value land 0xFFFF; value lsr 16 ]))
;;

let%test_unit "NEC receiver: a repeat code is ignored and does not spoil the next frame" =
  let unit = 5625 in
  let repeat = waveform [ 0xFF, 2 * unit; 0xFE, 16 * unit; 0xFF, 4 * unit; 0xFE, unit; 0xFF, 12 * unit ] in
  [%test_result: int list] (nec_rx repeat) ~expect:[];
  [%test_result: int list]
    (nec_rx (Array.append repeat (nec_module_output 0xF708FB04)))
    ~expect:[ 0xFB04; 0xF708 ]
;;

let%test_unit "NEC receiver: a frame cut short never leaves the pairs of words out of step" =
  List.iter (List.range 0 31) ~f:(fun bits ->
    let cut = nec_module_output ~bits 0xF708FB04 in
    let words = nec_rx (Array.append cut (nec_module_output 0x5AA51234)) in
    (* The cut frame's last burst reads as one more bit, so the first word
       has gone to the host once 16 real bits were sent: then zeros stand
       where the command belongs. With 31 real bits the frame would be
       complete, and right. *)
    let cut_words = if bits >= 16 then [ 0xFB04; 0 ] else [] in
    [%test_result: int list] words ~expect:(cut_words @ [ 0x1234; 0x5AA5 ]))
;;

let%test_unit "NEC receiver: a planted bug (bits read too late) is caught by a fast remote" =
  let late = String.substr_replace_first Firmware.nec_rx ~pattern:"read:   nop [15]" ~with_:"read:   nop [15]\n        nop [9]" in
  assert (not (String.equal late Firmware.nec_rx));
  assert (
    not
      ([%equal: int list]
         (nec_rx ~source:late (nec_module_output ~unit:4500 0xFF0000FF))
         [ 0x00FF; 0xFF00 ]))
;;
