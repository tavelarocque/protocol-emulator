(* 10BASE-T Ethernet transmit on the reference model, and the three things
   v2.1 adds that it stands on: autopull and autopush, the packet buffer, and
   the CRC register.

   The receiver here is written from IEEE 802.3's description of the wire,
   not from the firmware: Manchester cells of 100 ns, a preamble, a
   start-of-frame delimiter, the frame, a frame check sequence, the idle
   signal. Its CRC-32 is computed the other way round from the chip's, in a
   register that shifts left with the polynomial written high power first,
   and is itself checked against the published check value. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* --- An Ethernet receiver, from the standard --------------------------------- *)

(* CRC-32 over bits in the order they are sent, as 802.3 3.2.9 defines it:
   the first 32 bits complemented, division by the generator polynomial,
   the remainder complemented and sent highest power first. *)
let fcs_bits bits =
  let crc =
    List.fold bits ~init:0xFFFF_FFFF ~f:(fun crc b ->
      let top = (crc lsr 31) lxor b in
      let crc = (crc lsl 1) land 0xFFFF_FFFF in
      if top = 1 then crc lxor 0x04C1_1DB7 else crc)
  in
  let crc = lnot crc land 0xFFFF_FFFF in
  List.init 32 ~f:(fun k -> (crc lsr (31 - k)) land 1)
;;

let bits_of_bytes bytes = List.concat_map bytes ~f:(fun v -> List.init 8 ~f:(fun k -> (v lsr k) land 1))

let bytes_of_bits bits =
  List.chunks_of bits ~length:8
  |> List.map ~f:(fun byte -> List.foldi byte ~init:0 ~f:(fun k acc b -> acc lor (b lsl k)))
;;

let%test_unit "the receiver's CRC-32 gives the published check value" =
  (* CRC-32 of "123456789" is 0xCBF43926, with bit 0 the first bit sent. *)
  let sent = fcs_bits (bits_of_bytes (List.map (String.to_list "123456789") ~f:Char.to_int)) in
  let value = List.foldi sent ~init:0 ~f:(fun k acc b -> acc lor (b lsl k)) in
  [%test_result: int] value ~expect:0xCBF43926
;;

(* What is on the pair in each clock: [`Idle] with no voltage across it,
   [`High] with TD+ above TD-, [`Low] the other way. Both pins high is not
   a level a transmitter may make. *)
let level v =
  match v land 3 with
  | 0 -> `Idle
  | 1 -> `High
  | 2 -> `Low
  | _ -> `Both
;;

(* Reads one frame from the wire, a level per 25 ns clock, starting at
   [from]. A bit is four clocks: low then high is a 1, high then low a 0,
   and each half must last exactly two. The frame ends where the line stays
   high instead; it must then stay high for 250 to 450 ns in all (the start
   of idle) and be idle from there to the end of the trace. Returns the
   frame's bytes without preamble, delimiter and FCS, or why it is not a
   frame. *)
let receive trace ~from =
  let at t = level trace.(t) in
  let first =
    List.find (List.range from (Array.length trace)) ~f:(fun t -> not (phys_equal (at t) `Idle))
  in
  match first with
  | None -> Error "no frame"
  | Some s ->
    let rec cells t acc =
      match at t, at (t + 1), at (t + 2), at (t + 3) with
      | `Low, `Low, `High, `High -> cells (t + 4) (1 :: acc)
      | `High, `High, `Low, `Low -> cells (t + 4) (0 :: acc)
      | _ -> t, List.rev acc
    in
    let stop, bits = cells s [] in
    let high =
      List.take_while (List.range stop (Array.length trace)) ~f:(fun t -> phys_equal (at t) `High)
      |> List.length
    in
    (* The idle signal counts from the last bit's own end if it ended high. *)
    let ended_high = (not (List.is_empty bits)) && List.last_exn bits = 1 in
    let idle_ns = 25 * (high + if ended_high then 2 else 0) in
    let after = stop + high in
    let quiet = List.for_all (List.range after (Array.length trace)) ~f:(fun t -> phys_equal (at t) `Idle) in
    if high = 0
    then Error (sprintf "the line broke the code at clock %d" stop)
    else if idle_ns < 250 || idle_ns > 450
    then Error (sprintf "start of idle lasted %d ns" idle_ns)
    else if not quiet
    then Error "the line is not idle after the frame"
    else if List.length bits % 8 <> 0
    then Error (sprintf "%d bits is not a whole number of bytes" (List.length bits))
    else (
      let bytes = bytes_of_bits bits in
      let preamble, rest = List.split_n bytes 8 in
      if not ([%equal: int list] preamble [ 0x55; 0x55; 0x55; 0x55; 0x55; 0x55; 0x55; 0xD5 ])
      then Error "bad preamble or start-of-frame delimiter"
      else if List.length rest < 64
      then Error (sprintf "a frame of %d bytes is shorter than 64" (List.length rest))
      else (
        let frame, fcs = List.split_n rest (List.length rest - 4) in
        if [%equal: int list] (bits_of_bytes fcs) (fcs_bits (bits_of_bytes frame))
        then Ok frame
        else Error "frame check sequence is wrong"))
;;

(* --- The chip sending a frame ---------------------------------------------------- *)

(* The host's part, in the order a driver does it: with the thread stopped,
   fill the buffer, point it at the start, set it playing into thread 0,
   start the thread. Returns the two pins on every clock after that. *)
let send ?(source = Firmware.eth_tx) ?(config = Firmware.eth_tx_config) ?(after = 200) bytes =
  let modes = Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input) in
  let odd = List.length bytes % 2 = 1 in
  let image = Asm.link [ Firmware.eth_tx_origin, Asm.assemble ~origin:Firmware.eth_tx_origin source ] in
  let m = Isa.create ~program:image ~pin_modes:modes ~threads:[ config ~odd ] in
  Isa.set_enabled m ~thread:0 false;
  Isa.step m ~inputs:0xFF;
  let words = Firmware.eth_tx_words bytes in
  List.iter words ~f:(fun w ->
    Isa.write_buffer m w;
    Isa.step m ~inputs:0xFF);
  Isa.set_buffer_ptr m 0;
  Isa.set_buffer_end m (List.length words);
  Isa.set_buffer m ~mode:Play ~thread:0;
  Isa.set_enabled m ~thread:0 true;
  (* One clock for the thread to leave reset and drive the pair idle. *)
  Isa.step m ~inputs:0xFF;
  Isa.step m ~inputs:0xFF;
  let clocks = (4 * 8 * (List.length bytes + 12)) + after in
  Array.init clocks ~f:(fun _ ->
    Isa.step m ~inputs:0xFF;
    Isa.pin_out m)
;;

let random_frame rs length = List.init length ~f:(fun _ -> Random.State.int rs 256)

(* --- Link pulses ------------------------------------------------------------------ *)

(* Where the pair is not idle in a trace: the clock each stretch starts at,
   how many clocks it lasts, and the two pins through it if they never
   change (TD+ in bit 0). *)
let stretches trace =
  let found = Queue.create () in
  let start = ref None in
  Array.iteri (Array.append trace [| 0 |]) ~f:(fun t v ->
    let v = v land 3 in
    match !start with
    | None -> if v <> 0 && v <> 3 then start := Some (t, v, true)
    | Some (t0, v0, same) ->
      if v = 0 || v = 3
      then (
        Queue.enqueue found (t0, t - t0, if same then Some v0 else None);
        start := None)
      else if v <> v0
      then start := Some (t0, v0, false));
  Queue.to_list found
;;

let%test_unit "Ethernet: with nothing to send, a link pulse every 16 ms" =
  (* IEEE 802.3 14.2.1.1: a pulse every 16 ms, give or take 8, and the
     pulse itself TD+ above TD- for about one bit time. Here: 100 ns, four
     clocks at 40 MHz, and 640,000 clocks apart to within a thousandth. *)
  let modes = Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input) in
  let m =
    Isa.create
      ~program:(Firmware.eth_tx_image ())
      ~pin_modes:modes
      ~threads:[ { (Firmware.eth_tx_config ~odd:false) with start = Firmware.eth_tx_link } ]
  in
  let trace =
    Array.init (3 * 641_000) ~f:(fun _ ->
      Isa.step m ~inputs:0xFF;
      Isa.pin_out m)
  in
  match stretches trace with
  | [ (a, 4, Some 1); (b, 4, Some 1); (c, 4, Some 1) ] ->
    List.iter [ a; b - a; c - b ] ~f:(fun gap ->
      if gap < 639_500 || gap > 640_500 then raise_s [%message "link pulses not 16 ms apart" (gap : int)])
  | other -> raise_s [%message "not three link pulses" (other : (int * int * int option) list)]
;;

let%test_unit "Ethernet: after a frame the link pulses carry on" =
  let rs = Random.State.make [| 802; 3; 20 |] in
  let frame = random_frame rs 60 in
  let trace = send ~after:650_000 frame in
  (* The receiver wants an idle line after the frame: give it the trace up
     to well before the pulse. *)
  (match receive (Array.sub trace ~pos:0 ~len:(Array.length trace - 649_800)) ~from:0 with
   | Ok got -> [%test_result: int list] got ~expect:frame
   | Error why -> raise_s [%message "frame not received" why]);
  (* The frame is one long stretch; the one after it is a link pulse, 16 ms
     after the frame ended. *)
  match stretches trace with
  | [ (start, length, None); (pulse, 4, Some 1) ] ->
    let gap = pulse - (start + length) in
    if gap < 639_500 || gap > 640_500 then raise_s [%message "first link pulse not 16 ms after the frame" (gap : int)]
  | other -> raise_s [%message "not a frame and then one link pulse" (other : (int * int * int option) list)]
;;

let%test_unit "Ethernet: frames of 60 to 1514 bytes arrive whole, with a good FCS" =
  let rs = Random.State.make [| 802; 3 |] in
  List.iter [ 60; 61; 62; 63; 64; 127; 512; 1513; 1514 ] ~f:(fun length ->
    let frame = random_frame rs length in
    match receive (send frame) ~from:0 with
    | Ok got -> [%test_result: int list] got ~expect:frame
    | Error why -> raise_s [%message "frame not received" (length : int) why])
;;

let%test_unit "Ethernet: every byte value and both lengths of run" =
  (* All zeros and all ones are the longest runs of one cell shape; a count
     covers every byte. *)
  List.iter
    [ List.init 60 ~f:(fun _ -> 0x00); List.init 60 ~f:(fun _ -> 0xFF); List.init 256 ~f:Fn.id ]
    ~f:(fun frame ->
      match receive (send frame) ~from:0 with
      | Ok got -> [%test_result: int list] got ~expect:frame
      | Error why -> raise_s [%message "frame not received" why])
;;

let%test_unit "Ethernet: the preamble starts on a fixed clock" =
  (* Nothing in the start waits on anything but the buffer, so the preamble
     begins at a fixed clock. *)
  let trace = send (List.init 60 ~f:Fn.id) in
  let first = Array.findi_exn trace ~f:(fun _ v -> v land 3 <> 0) |> fst in
  [%test_result: int] first ~expect:2
;;

let%test_unit "Ethernet: a planted bug (a 0 after a 0 sent as a 1) is caught" =
  let planted =
    String.substr_replace_all
      Firmware.eth_tx
      ~pattern:"d0z:    jmp d0          side 2"
      ~with_:"d0z:    jmp d1          side 2"
  in
  assert (not (String.equal planted Firmware.eth_tx));
  let frame = random_frame (Random.State.make [| 1 |]) 60 in
  match receive (send ~source:planted frame) ~from:0 with
  | Ok got -> assert (not ([%equal: int list] got frame))
  | Error _ -> ()
;;

let%test_unit "Ethernet: the receiver rejects a frame sent with the CRC not inverted" =
  (* The receiver must be able to say no for a reason of its own. *)
  let config ~odd = { (Firmware.eth_tx_config ~odd) with crc_invert = false } in
  match receive (send ~config (List.init 60 ~f:Fn.id)) ~from:0 with
  | Error why -> [%test_result: string] why ~expect:"frame check sequence is wrong"
  | Ok _ -> failwith "accepted"
;;

(* --- The pieces, apart from Ethernet ------------------------------------------ *)

let run_program ?(threads = 1) ~config source ~host ~cycles =
  let modes = Array.create ~len:Isa.num_pins Isa.Pin_mode.Push_pull in
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:(List.init threads ~f:(fun _ -> config))
  in
  host m;
  for _ = 1 to cycles do
    Isa.step m ~inputs:0xFF
  done;
  m
;;

let%test_unit "autopull: OUT refills the OSR with no clock lost, and waits when there is nothing" =
  (* Eight bits a word onto P0, one a clock, with no pull anywhere. *)
  let config = { Isa.Thread_config.default with threshold = 8; autopull = true } in
  let m = run_program ~config "lp: out pins, 1\n jmp lp" ~cycles:0 ~host:(fun m ->
    ignore (Isa.push_tx m ~thread:0 0xA5 : bool);
    ignore (Isa.push_tx m ~thread:0 0x3C : bool))
  in
  let seen =
    Array.init 40 ~f:(fun _ ->
      Isa.step m ~inputs:0xFF;
      Isa.pin_out m land 1)
    |> Array.to_list
  in
  (* The first OUT finds the OSR empty and fetches; from then on a bit
     every other clock (the jmp), across the word boundary too. *)
  let bits = List.filteri seen ~f:(fun t _ -> t >= 1 && t % 2 = 1) |> Fn.flip List.take 16 in
  [%test_result: int list] bits ~expect:(bits_of_bytes [ 0xA5; 0x3C ]);
  (* Both words gone: the thread waits at the OUT with the OSR empty. *)
  let th = Isa.thread m 0 in
  [%test_result: int] th.pc ~expect:0;
  assert (Queue.is_empty th.tx_fifo)
;;

let%test_unit "autopush and record: every word a thread shifts in lands in the buffer" =
  (* X counts down; each value is shifted in whole and pushed by the IN. *)
  let config = { Isa.Thread_config.default with threshold = 16; autopush = true } in
  let m =
    run_program
      ~config
      "set x, 9\nlp: in x, 16\n jmp x-- lp\nend: jmp end"
      ~cycles:60
      ~host:(fun m ->
        Isa.set_buffer_ptr m 100;
        Isa.set_buffer_end m 200;
        Isa.set_buffer m ~mode:Record ~thread:0)
  in
  [%test_result: int] (Isa.buffer_ptr m) ~expect:110;
  Isa.set_buffer m ~mode:Off ~thread:0;
  Isa.set_buffer_ptr m 100;
  let words = Array.init 10 ~f:(fun _ -> Option.value_exn (Isa.read_buffer m)) |> Array.to_list in
  [%test_result: int list] words ~expect:[ 9; 8; 7; 6; 5; 4; 3; 2; 1; 0 ]
;;

let%test_unit "autopush: an IN that would fill the ISR waits while the RX FIFO is full" =
  let config = { Isa.Thread_config.default with threshold = 16; autopush = true } in
  let m = run_program ~config "lp: in y, 16\n set y, 1\n jmp lp" ~cycles:60 ~host:ignore in
  let th = Isa.thread m 0 in
  [%test_result: int] (Queue.length th.rx_fifo) ~expect:Isa.fifo_depth;
  [%test_result: int] th.isr_count ~expect:0;
  (* The host takes one word and exactly one more IN goes through. *)
  ignore (Isa.pop_rx m ~thread:0 : int option);
  for _ = 1 to 10 do
    Isa.step m ~inputs:0xFF
  done;
  [%test_result: int] (Queue.length th.rx_fifo) ~expect:Isa.fifo_depth
;;

let%test_unit "the buffer plays up to its end and no further, and the host cannot push meanwhile" =
  let config = { Isa.Thread_config.default with threshold = 16 } in
  let m =
    run_program ~config "lp: pull\n mov x, osr\n jmp lp" ~cycles:0 ~host:(fun m ->
      Isa.set_enabled m ~thread:0 false;
      Isa.step m ~inputs:0xFF;
      List.iter [ 11; 22; 33; 44; 55; 66; 77 ] ~f:(fun w ->
        Isa.write_buffer m w;
        Isa.step m ~inputs:0xFF);
      Isa.set_buffer_ptr m 0;
      Isa.set_buffer_end m 6;
      Isa.set_buffer m ~mode:Play ~thread:0;
      Isa.set_enabled m ~thread:0 true)
  in
  assert (not (Isa.push_tx m ~thread:0 99));
  let seen = ref [] in
  for _ = 1 to 80 do
    Isa.step m ~inputs:0xFF;
    let x = (Isa.thread m 0).x in
    if x <> 0 && not (List.mem !seen x ~equal:Int.equal) then seen := x :: !seen
  done;
  [%test_result: int list] (List.rev !seen) ~expect:[ 11; 22; 33; 44; 55; 66 ];
  [%test_result: int] (Isa.buffer_ptr m) ~expect:6
;;

(* The CRC register after a thread has shifted [bytes] out a bit at a time,
   eight bits a word. With [msb_first] the host left-justifies each byte,
   as it does for any MSB-first protocol. *)
let crc_after ~config ~msb_first bytes =
  let config =
    { config with Isa.Thread_config.threshold = 8; autopull = true; out_msb_first = msb_first }
  in
  let m = run_program ~config "lp: out null, 1\n jmp lp" ~cycles:0 ~host:ignore in
  List.iter bytes ~f:(fun b ->
    assert (Isa.push_tx m ~thread:0 (if msb_first then b lsl 8 else b));
    for _ = 1 to 20 do
      Isa.step m ~inputs:0xFF
    done);
  (Isa.thread m 0).crc
;;

let check_string = List.map (String.to_list "123456789") ~f:Char.to_int

let reverse ~bits v =
  List.fold (List.range 0 bits) ~init:0 ~f:(fun acc k -> acc lor (((v lsr k) land 1) lsl (bits - 1 - k)))
;;

(* The published check values of three CRCs, each the CRC of "123456789"
   (the catalogue of parametrised CRC algorithms). One register does all
   three: the host writes the polynomial low power first and what the
   register starts from. *)
let%test_unit "the CRC register: Ethernet's CRC-32, USB's CRC-16 and CAN's CRC-15" =
  let cfg poly init = { Isa.Thread_config.default with crc_poly = poly; crc_init = init } in
  (* CRC-32: polynomial 0x04C11DB7, from all ones, sent inverted. *)
  let crc32 = crc_after ~config:(cfg 0xEDB88320 0xFFFF_FFFF) ~msb_first:false check_string in
  [%test_result: int] (lnot crc32 land 0xFFFF_FFFF) ~expect:0xCBF43926;
  (* USB's CRC-16: polynomial 0x8005, from all ones, sent inverted. *)
  let crc16 = crc_after ~config:(cfg (reverse ~bits:16 0x8005) 0xFFFF) ~msb_first:false check_string in
  [%test_result: int] (lnot crc16 land 0xFFFF) ~expect:0xB4C8;
  (* CAN's CRC-15: polynomial 0x4599, from zero, bytes highest bit first.
     The register holds it with its highest power in bit 0, the bit that
     goes on the wire first. *)
  let crc15 = crc_after ~config:(cfg (reverse ~bits:15 0x4599) 0) ~msb_first:true check_string in
  [%test_result: int] (reverse ~bits:15 crc15) ~expect:0x059E
;;

let%test_unit "mov from the CRC register reads it low half first and stops it; mov to it starts it again" =
  let config =
    { Isa.Thread_config.default with
      threshold = 16
    ; crc_poly = 0xEDB88320
    ; crc_init = 0x1234_5678
    ; crc_invert = true
    }
  in
  let m = run_program ~config "mov x, crc\n mov y, crc\n pull\n out null, 16\n end: jmp end" ~cycles:2 ~host:ignore in
  let th = Isa.thread m 0 in
  [%test_result: int] th.x ~expect:(lnot 0x5678 land 0xFFFF);
  [%test_result: int] th.y ~expect:(lnot 0x1234 land 0xFFFF);
  (* Stopped: bits shifted out now leave it alone. *)
  assert (Isa.push_tx m ~thread:0 0xBEEF);
  for _ = 1 to 5 do
    Isa.step m ~inputs:0xFF
  done;
  [%test_result: int] th.crc ~expect:0;
  [%test_result: bool] th.crc_run ~expect:false;
  let m = run_program ~config "mov x, crc\n mov crc, null\n end: jmp end" ~cycles:3 ~host:ignore in
  [%test_result: int] (Isa.thread m 0).crc ~expect:0x1234_5678;
  [%test_result: bool] (Isa.thread m 0).crc_run ~expect:true
;;
