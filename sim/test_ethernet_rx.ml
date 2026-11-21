(* 10BASE-T Ethernet receive on the reference model: the bit sampler and
   the [eth_rx] firmware behind it.

   The transmitter here is written from IEEE 802.3's description of the wire,
   like the receiver in test_ethernet.ml: Manchester cells of 100 ns, the
   preamble, the delimiter, the frame, its FCS, the start of idle. It makes
   a list of the times at which the line changes, in nanoseconds, with
   nothing rounded to the chip's clock: its own clock may run fast or slow,
   its edges may each be early or late, and the chip's clock starts at any
   point in a cycle. The chip sees that line at its rising and falling clock
   edges, as it would on a board. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
open Test_ethernet

(* --- An Ethernet transmitter, from the standard ------------------------------ *)

let preamble = [ 0x55; 0x55; 0x55; 0x55; 0x55; 0x55; 0x55; 0xD5 ]

(* The bits of a frame as sent, FCS included, after the preamble. *)
let frame_bits ?(bad_fcs = false) frame =
  let bits = bits_of_bytes frame in
  let fcs = fcs_bits bits in
  bits @ if bad_fcs then List.mapi fcs ~f:(fun k b -> if k = 7 then 1 - b else b) else fcs
;;

(* The line levels of some bits in Manchester code, one per half bit: a 1 is
   low then high, a 0 high then low (802.3 7.3.1.1). *)
let manchester bits = List.concat_map bits ~f:(fun b -> [ b = 0; b = 1 ])

(* A whole transmission as half-bit levels: preamble, frame, then the line
   held high for three bit times, which is how a frame ends (the standard
   allows 250 to 450 ns). Before and after it the line is low: what a
   receiver's comparator gives with no signal on the pair. *)
let transmission ?bad_fcs frame =
  manchester (bits_of_bytes preamble @ frame_bits ?bad_fcs frame) @ List.init 6 ~f:(fun _ -> true)
;;

(* A line: the times at which it changes level, in ns, starting low. *)
type line = float array

(* Half-bit levels starting at [start] ns. Each change of level is moved by
   up to [jitter] ns either way, independently, and the sender's clock is
   [ppm] parts per million slow. *)
let line_of_halves ?(rs = Random.State.make [| 0 |]) ?(jitter = 0.) ?(ppm = 0.) ~start halves : line =
  let half = 50. *. (1. +. (ppm *. 1e-6)) in
  let edges = Queue.create () in
  let level = ref false in
  List.iteri (halves @ [ false ]) ~f:(fun k v ->
    if Bool.( <> ) v !level
    then (
      level := v;
      let j = if Float.(jitter > 0.) then Random.State.float_range rs (-.jitter) jitter else 0. in
      Queue.enqueue edges (start +. (Float.of_int k *. half) +. j)));
  Queue.to_array edges
;;

let line_end (line : line) = if Array.is_empty line then 0. else Array.last line

(* --- The chip receiving ---------------------------------------------------------- *)

(* The chip with [eth_rx] running on thread 0, the sampler on, and the
   buffer recording. *)
let receiver ?(source = Firmware.eth_rx) ?(sampler = Firmware.eth_rx_sampler) () =
  let image = Asm.link [ Firmware.eth_rx_origin, Asm.assemble ~origin:Firmware.eth_rx_origin source ] in
  let m =
    Isa.create
      ~program:image
      ~pin_modes:(Array.create ~len:Isa.num_pins Isa.Pin_mode.Input)
      ~threads:[ Firmware.eth_rx_config ]
  in
  Isa.set_sampler m sampler;
  Isa.set_buffer_ptr m 0;
  Isa.set_buffer_end m (Isa.buffer_size - 1);
  Isa.set_buffer m ~mode:Record ~thread:0;
  m
;;

(* Clocks the chip along a line until [until] ns. The chip's clock has a
   period of [clock] ns and its first rising edge is [phase] ns after time
   0; each cycle the line is looked at where the falling edge and the next
   rising edge come. *)
let clock_along ?(clock = 25.) ?(phase = 0.) m (line : line) ~until =
  let next = ref 0 in
  let level = ref false in
  let at time =
    while !next < Array.length line && Float.(line.(!next) <= time) do
      level := not !level;
      incr next
    done;
    if !level then 1 lsl Firmware.eth_rx_data_pin else 0
  in
  let cycles = Float.iround_up_exn ((until -. phase) /. clock) in
  for t = 0 to cycles - 1 do
    let rise = phase +. (Float.of_int t *. clock) in
    let inputs_mid = at (rise +. (clock /. 2.)) in
    let inputs = at (rise +. clock) in
    Isa.step m ~inputs_mid ~inputs
  done
;;

(* What the buffer recorded, read back the way a driver does. *)
let recorded m =
  let n = Isa.buffer_ptr m in
  Isa.set_buffer m ~mode:Off ~thread:0;
  Isa.set_buffer_ptr m 0;
  (* An array: [List.init] calls its function last element first. *)
  Array.init n ~f:(fun _ -> Option.value_exn (Isa.read_buffer m)) |> Array.to_list
;;

(* One frame sent to a fresh chip. Returns what [Firmware.eth_rx_frame]
   makes of the words recorded. *)
let receive_one ?source ?sampler ?clock ?phase ?rs ?jitter ?ppm ?bad_fcs frame =
  let m = receiver ?source ?sampler () in
  let line = line_of_halves ?rs ?jitter ?ppm ~start:1000. (transmission ?bad_fcs frame) in
  clock_along ?clock ?phase m line ~until:(line_end line +. 2000.);
  Firmware.eth_rx_frame (recorded m)
;;

(* The frame with its FCS, as bytes: what a good reception returns. *)
let with_fcs frame = bytes_of_bits (frame_bits frame)

let expect_frame ?(what = "") frame result =
  match result with
  | Ok (bytes, crc_ok) ->
    [%test_result: int list] bytes ~expect:(with_fcs frame) ~message:what;
    if not crc_ok then raise_s [%message "the CRC register did not end at the residue" what]
  | Error why -> raise_s [%message "frame not received" what why]
;;

let%test_unit "Ethernet receive: frames of 60 to 1514 bytes arrive whole and the CRC checks" =
  let rs = Random.State.make [| 802; 3; 1 |] in
  List.iter [ 60; 61; 62; 63; 64; 127; 512; 1513; 1514 ] ~f:(fun length ->
    let frame = random_frame rs length in
    expect_frame ~what:(sprintf "%d bytes" length) frame (receive_one frame))
;;

let%test_unit "Ethernet receive: every byte value, and the longest runs" =
  List.iter
    [ List.init 60 ~f:(fun _ -> 0x00); List.init 60 ~f:(fun _ -> 0xFF); List.init 256 ~f:Fn.id ]
    ~f:(fun frame -> expect_frame frame (receive_one frame))
;;

let%test_unit "Ethernet receive: wherever the chip's clock stands against the sender's" =
  (* The sender's first edge at every eighth of a nanosecond across one
     clock cycle, with the sender's clock at both ends of what the standard
     allows (100 ppm) and well beyond it. *)
  let rs = Random.State.make [| 802; 3; 2 |] in
  let frame = random_frame rs 64 in
  List.iter [ -5000.; -100.; 0.; 100.; 5000. ] ~f:(fun ppm ->
    List.iter (List.range 0 200) ~f:(fun k ->
      let phase = Float.of_int k /. 8. in
      expect_frame
        ~what:(sprintf "phase %.3f ns, %.0f ppm" phase ppm)
        frame
        (receive_one ~phase ~ppm frame)))
;;

let%test_unit "Ethernet receive: a long frame from a sender 100 ppm off drifts a bit and more" =
  (* 1514 bytes at 100 ppm is 1.2 bit times of drift from first bit to last:
     only following the sender's clock, edge by edge, gets to the end. *)
  let rs = Random.State.make [| 802; 3; 3 |] in
  let frame = random_frame rs 1514 in
  List.iter [ -100.; 100. ] ~f:(fun ppm -> expect_frame frame (receive_one ~ppm frame))
;;

let%test_unit "Ethernet receive: a frame with a wrong FCS is told apart" =
  let rs = Random.State.make [| 802; 3; 4 |] in
  let frame = random_frame rs 64 in
  match receive_one ~bad_fcs:true frame with
  | Ok (_, false) -> ()
  | Ok (_, true) -> raise_s [%message "a wrong FCS passed"]
  | Error why -> raise_s [%message "frame not received" why]
;;

let%test_unit "Ethernet receive: two frames with the shortest gap between them" =
  (* 9.6 us, 96 bit times, from the end of one frame to the next preamble. *)
  let rs = Random.State.make [| 802; 3; 5 |] in
  let a = random_frame rs 60 in
  let b = random_frame rs 61 in
  let m = receiver () in
  let first = line_of_halves ~start:1000. (transmission a) in
  let second = line_of_halves ~start:(line_end first +. 9600.) (transmission b) in
  let line = Array.append first second in
  clock_along m line ~until:(line_end line +. 2000.);
  let words = recorded m in
  let n = ((List.length a + 4 + 1) / 2) + 3 in
  expect_frame ~what:"first" a (Firmware.eth_rx_frame (List.take words n));
  expect_frame ~what:"second" b (Firmware.eth_rx_frame (List.drop words n))
;;

let%test_unit "Ethernet receive: link pulses and noise on an idle line record nothing" =
  (* A link pulse is the line high for 100 ns, every 16 ms; here a few, close
     together, then bursts of edges that are not a preamble. *)
  let m = receiver () in
  let pulses = List.concat_map [ 1000.; 3000.; 5000. ] ~f:(fun t -> [ t; t +. 100. ]) in
  let rs = Random.State.make [| 802; 3; 6 |] in
  let noise =
    List.init 400 ~f:(fun _ -> Random.State.float_range rs 20. 300.)
    |> List.folding_map ~init:8000. ~f:(fun t gap -> t +. gap, t +. gap)
  in
  let line = Array.of_list (pulses @ noise) in
  clock_along m line ~until:(line_end line +. 2000.);
  [%test_result: int list] (recorded m) ~expect:[]
;;

let%test_unit "Ethernet receive: a frame after link pulses and noise still arrives" =
  let rs = Random.State.make [| 802; 3; 7 |] in
  let frame = random_frame rs 64 in
  let m = receiver () in
  let pulses = [ 1000.; 1100.; 2000.; 2100. ] in
  let sent = line_of_halves ~start:4000. (transmission frame) in
  let line = Array.append (Array.of_list pulses) sent in
  clock_along m line ~until:(line_end line +. 2000.);
  expect_frame frame (Firmware.eth_rx_frame (recorded m))
;;

(* --- How much jitter ------------------------------------------------------------ *)

(* Frames out of [n] received whole with a good CRC when every edge on the
   line is moved by up to [jitter] ns either way, the sender's clock is off
   by up to 100 ppm, and the chip's clock starts anywhere. *)
let good_frames ?sampler ?clock ~jitter ~n ~seed () =
  let rs = Random.State.make [| 802; 3; seed |] in
  List.count (List.range 0 n) ~f:(fun _ ->
    let frame = random_frame rs 64 in
    let ppm = Random.State.float_range rs (-100.) 100. in
    let phase = Random.State.float_range rs 0. (Option.value clock ~default:25.) in
    match receive_one ?sampler ?clock ~phase ~rs ~jitter ~ppm frame with
    | Ok (bytes, true) -> [%equal: int list] bytes (with_fcs frame)
    | _ -> false)
;;

let%expect_test "Ethernet receive: how much jitter on every edge it stands" =
  (* Two edges that are each off by J move apart or together by up to 2 J.
     At 40 MHz a sample is 12.5 ns: the edge between bits may show one
     sample late (it is still ignored) and the next middle edge two samples
     early (it is still accepted), so 2 J up to 12.5 ns is safe whatever the
     clocks do, and beyond that frames start to be lost. At 50 MHz a sample
     is 10 ns and both directions have two samples. *)
  let sweep name ?sampler ?clock () =
    printf "%s\n" name;
    List.iter [ 0.; 2.; 4.; 6.; 7.; 8.; 10.; 12.; 14.; 16. ] ~f:(fun jitter ->
      printf
        "  every edge within %2.0f ns: %3d of 200 frames\n"
        jitter
        (good_frames ?sampler ?clock ~jitter ~n:200 ~seed:8 ()))
  in
  sweep "40 MHz clock" ();
  sweep "50 MHz clock" ~sampler:Firmware.eth_rx_sampler_50 ~clock:20. ();
  [%expect {|
    40 MHz clock
      every edge within  0 ns: 200 of 200 frames
      every edge within  2 ns: 200 of 200 frames
      every edge within  4 ns: 200 of 200 frames
      every edge within  6 ns: 200 of 200 frames
      every edge within  7 ns: 190 of 200 frames
      every edge within  8 ns: 136 of 200 frames
      every edge within 10 ns:  74 of 200 frames
      every edge within 12 ns:   6 of 200 frames
      every edge within 14 ns:   0 of 200 frames
      every edge within 16 ns:   0 of 200 frames
    50 MHz clock
      every edge within  0 ns: 200 of 200 frames
      every edge within  2 ns: 200 of 200 frames
      every edge within  4 ns: 200 of 200 frames
      every edge within  6 ns: 200 of 200 frames
      every edge within  7 ns: 200 of 200 frames
      every edge within  8 ns: 200 of 200 frames
      every edge within 10 ns: 200 of 200 frames
      every edge within 12 ns:  99 of 200 frames
      every edge within 14 ns:  17 of 200 frames
      every edge within 16 ns:   0 of 200 frames
    |}]
;;

(* --- The chip receiving what the chip sends ---------------------------------------- *)

let%test_unit "Ethernet: thread 1 receives the frame thread 0 sends" =
  (* [eth_tx] on thread 0 playing from the buffer, its TD+ pin read back by
     the sampler, [eth_rx] on thread 1. With the buffer taken, the host pops
     thread 1's words itself, which a model's host is fast enough to do. *)
  let rs = Random.State.make [| 802; 3; 9 |] in
  List.iter [ 60; 61; 1514 ] ~f:(fun length ->
    let frame = random_frame rs length in
    let odd = length % 2 = 1 in
    let tx = Asm.link [ Firmware.eth_tx_origin, Asm.assemble ~origin:Firmware.eth_tx_origin Firmware.eth_tx ] in
    let modes = Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input) in
    let m =
      Isa.create_separate
        ~programs:[| tx; Firmware.eth_rx_image () |]
        ~pin_modes:modes
        ~threads:[ Firmware.eth_tx_config ~odd; { Firmware.eth_rx_config with in_base = 0 } ]
    in
    let rx = Asm.assemble (String.substr_replace_all Firmware.eth_rx ~pattern:"pin 3" ~with_:"pin 1") in
    Array.iteri rx ~f:(fun addr instr ->
      Isa.set_enabled m ~thread:1 false;
      ignore (Isa.write_program m ~thread:1 ~addr instr : bool));
    Isa.set_enabled m ~thread:0 false;
    Isa.step m ~inputs:0;
    List.iter (Firmware.eth_tx_words frame) ~f:(fun w ->
      Isa.write_buffer m w;
      Isa.step m ~inputs:0);
    Isa.set_buffer_ptr m 0;
    Isa.set_buffer_end m (List.length (Firmware.eth_tx_words frame));
    Isa.set_buffer m ~mode:Play ~thread:0;
    Isa.set_sampler m { Firmware.eth_rx_sampler with pin = 0 };
    Isa.set_enabled m ~thread:0 true;
    Isa.set_enabled m ~thread:1 true;
    let words = Queue.create () in
    for _ = 1 to (4 * 8 * (length + 12)) + 400 do
      (* A push-pull pin reads back what the chip drives. *)
      Isa.step m ~inputs:(Isa.pin_out m);
      Option.iter (Isa.pop_rx m ~thread:1) ~f:(Queue.enqueue words)
    done;
    expect_frame ~what:(sprintf "%d bytes" length) frame (Firmware.eth_rx_frame (Queue.to_list words)))
;;

let%test_unit "Ethernet: the chip's own link pulses reach its receiver and record nothing" =
  (* Thread 0 with nothing to send, so only link pulses; thread 1 receiving
     from the same pin. Two pulses go by. *)
  let modes = Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input) in
  let rx = Asm.assemble (String.substr_replace_all Firmware.eth_rx ~pattern:"pin 3" ~with_:"pin 1") in
  let rx_image = Asm.link [ Firmware.eth_rx_origin, rx ] in
  let m =
    Isa.create_separate
      ~programs:[| Firmware.eth_tx_image (); rx_image |]
      ~pin_modes:modes
      ~threads:
        [ { (Firmware.eth_tx_config ~odd:false) with start = Firmware.eth_tx_link }
        ; { Firmware.eth_rx_config with in_base = 0 }
        ]
  in
  Isa.set_sampler m { Firmware.eth_rx_sampler with pin = 0 };
  let pulses = ref 0 in
  let high = ref false in
  for _ = 1 to 2 * 641_000 do
    Isa.step m ~inputs:(Isa.pin_out m);
    let now = Isa.pin_out m land 3 = 1 in
    if now && not !high then incr pulses;
    high := now;
    match Isa.pop_rx m ~thread:1 with
    | Some word -> raise_s [%message "a link pulse was taken for data" (word : int)]
    | None -> ()
  done;
  [%test_result: int] !pulses ~expect:2
;;

(* --- The sampler on its own -------------------------------------------------------- *)

(* The bits a thread would be handed: the data pin at each pulse. *)
let sampled ~sampler ~clock (line : line) ~until =
  let m =
    Isa.create
      ~program:(Asm.assemble "top: jmp top")
      ~pin_modes:(Array.create ~len:Isa.num_pins Isa.Pin_mode.Input)
      ~threads:[ Isa.Thread_config.default ]
  in
  Isa.set_sampler m sampler;
  let bits = Queue.create () in
  let pin = sampler.Isa.Sampler_config.pin in
  let next = ref 0 in
  let level = ref false in
  let at time =
    while !next < Array.length line && Float.(line.(!next) <= time) do
      level := not !level;
      incr next
    done;
    if !level then 1 lsl pin else 0
  in
  for t = 0 to Float.iround_up_exn (until /. clock) - 1 do
    let rise = Float.of_int t *. clock in
    let inputs_mid = at (rise +. (clock /. 2.)) in
    let inputs = at (rise +. clock) in
    Isa.step m ~inputs_mid ~inputs;
    let seen = Isa.seen_lines m ~inputs in
    if (seen lsr ((pin + 1) % Isa.num_pins)) land 1 = 1 then Queue.enqueue bits ((seen lsr pin) land 1)
  done;
  Queue.to_list bits
;;

let%test_unit "sampler: without a sync word every bit is passed on; inverted, its opposite" =
  let bits = [ 1; 0; 1; 1; 0; 0; 1; 0; 1; 1; 1; 0 ] in
  let line = line_of_halves ~start:500. (manchester bits) in
  let sampler = { Firmware.eth_rx_sampler with sync_enable = false; pin = 5 } in
  (* The first edge of the first bit is not in the middle of a bit unless
     the bit is a 1 (the line starts low), which it is here. *)
  [%test_result: int list] (sampled ~sampler ~clock:25. line ~until:3000.) ~expect:bits;
  [%test_result: int list]
    (sampled ~sampler:{ sampler with invert = true } ~clock:25. line ~until:3000.)
    ~expect:(List.map bits ~f:(fun b -> 1 - b))
;;

let%test_unit "sampler: NRZ data, with runs of equal bits, from a sender 2% off" =
  (* Not Manchester: one level per bit, edges only where the data changes.
     The sampler restarts its phase at every edge and keeps its own time
     through the runs. 250 ns bits on a 40 MHz clock are 20 samples. *)
  let rs = Random.State.make [| 802; 3; 10 |] in
  let sampler =
    { Isa.Sampler_config.enable = true
    ; pin = 4
    ; invert = false
    ; sync_enable = true
    ; sync = 0x7E
    ; misses = 7
    ; blank = 0
    ; sample = 9
    ; wrap = 19
    ; prescale = 0
    ; shift = 0
    ; stuff = 0
    }
  in
  List.iter [ -2.; 0.; 2. ] ~f:(fun percent ->
    (* A sync word, then data with no run longer than 6 bits. *)
    let data =
      List.init 400 ~f:(fun _ -> Random.State.int rs 2)
      |> List.folding_map ~init:(0, 0) ~f:(fun (prev, run) b ->
        let b = if run >= 6 then 1 - prev else b in
        (b, if b = prev then run + 1 else 1), b)
    in
    let bits = [ 0; 1; 0; 1; 0; 1; 1; 1; 1; 1; 1; 0 ] @ data in
    let bit_ns = 250. *. (1. +. (percent /. 100.)) in
    let edges = Queue.create () in
    let level = ref 0 in
    List.iteri (bits @ [ 0 ]) ~f:(fun k b ->
      if b <> !level
      then (
        level := b;
        Queue.enqueue edges (500. +. (Float.of_int k *. bit_ns))));
    let line = Queue.to_array edges in
    let got = sampled ~sampler ~clock:25. line ~until:(500. +. (Float.of_int (List.length bits) *. bit_ns)) in
    [%test_result: int list]
      (List.take got (List.length data - 2))
      ~expect:(List.take data (List.length data - 2))
      ~message:(sprintf "%.0f%% off" percent))
;;

(* --- A planted bug ---------------------------------------------------------------- *)

let%test_unit "Ethernet receive: a planted bug (the bit taken a cycle late) is caught" =
  (* With a delay on the jump the IN lands on the next bit's pulse cycle and
     the thread is not waiting when a close pulse comes. *)
  let planted =
    String.substr_replace_all
      Firmware.eth_rx
      ~pattern:"        jmp x-- bit\n"
      ~with_:"        jmp x-- bit [2]\n"
  in
  assert (not (String.equal planted Firmware.eth_rx));
  let rs = Random.State.make [| 802; 3; 11 |] in
  let frame = random_frame rs 64 in
  match receive_one ~source:planted frame with
  | Ok (bytes, true) when [%equal: int list] bytes (with_fcs frame) ->
    raise_s [%message "the planted bug was not caught"]
  | _ -> ()
;;
