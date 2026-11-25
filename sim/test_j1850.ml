(* The SAE J1850 VPW transmitter ([Firmware.j1850_tx]) against a receiver
   written here from SAE J1850's VPW symbol timing: it classes each run of
   one level by its length against the limits a receiver works to, reads
   active short and passive long as 1, active long and passive short as 0,
   wants a start of frame after an idle bus, ends the frame at end of data,
   and checks the CRC-8 with a CRC of its own. The cocotb test runs the
   same firmware on the RTL and the gate netlist with sigrok's J1850 VPW
   decoder reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* SAE J1850's CRC-8: x^8 + x^4 + x^3 + x^2 + 1, from all ones, most
   significant bit first, sent inverted. *)
let crc8 bytes =
  List.fold bytes ~init:0xFF ~f:(fun crc b ->
    List.fold (List.range 0 8) ~init:(crc lxor b) ~f:(fun c _ ->
      if c land 0x80 <> 0 then ((c lsl 1) lxor 0x1D) land 0xFF else (c lsl 1) land 0xFF))
  lxor 0xFF
;;

let us = 10 (* cycles at 10 MHz *)

module Receiver = struct
  type t =
    { mutable now : int
    ; mutable level : bool (* true: active *)
    ; mutable since : int (* when the bus took that level *)
    ; mutable synced : bool (* the bus has been idle long enough to start *)
    ; mutable in_frame : bool
    ; mutable bits : int list (* this frame's, newest first *)
    ; mutable frames : int list list (* each without its CRC, newest first *)
    ; mutable errors : string list
    }

  let create () =
    { now = 0
    ; level = false
    ; since = 0
    ; synced = false
    ; in_frame = false
    ; bits = []
    ; frames = []
    ; errors = []
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  (* The receiver's limits, in us: a short symbol is over 34 and up to 96,
     a long one up to 163, a start of frame or end of data up to 239; a
     passive bus for longer than that is the end of the frame, and 280 is
     the shortest space between frames. *)
  let symbol d = if d > 34 * us && d <= 96 * us then Some `Short else if d > 96 * us && d <= 163 * us then Some `Long else None

  let end_of_data t =
    t.in_frame <- false;
    let bits = List.rev t.bits in
    if List.length bits % 8 <> 0 || List.length bits < 16
    then error t (sprintf "a frame of %d bits" (List.length bits))
    else (
      let bytes = List.chunks_of bits ~length:8 |> List.map ~f:(List.fold ~init:0 ~f:(fun a b -> (a lsl 1) lor b)) in
      let data, crc = List.drop_last_exn bytes, List.last_exn bytes in
      if crc <> crc8 data then error t "CRC" else t.frames <- data :: t.frames)
  ;;

  (* A run of one level is over: the bus was at [active] for [d] cycles. *)
  let run t ~active ~d =
    if not t.in_frame
    then (
      if active
      then
        if t.synced && d > 163 * us && d <= 239 * us
        then (
          t.in_frame <- true;
          t.bits <- [])
        else if t.synced
        then error t (sprintf "an active pulse of %d cycles on an idle bus" d);
      (* Only a bus idle for the space between frames may begin one. *)
      t.synced <- (not active) && d >= 280 * us)
    else (
      match symbol d with
      | None -> error t (sprintf "a symbol of %d cycles" d)
      | Some length ->
        let bit =
          match active, length with
          | true, `Short | false, `Long -> 1
          | true, `Long | false, `Short -> 0
        in
        t.bits <- bit :: t.bits)
  ;;

  let step t ~active =
    t.now <- t.now + 1;
    if Bool.( <> ) active t.level
    then (
      run t ~active:t.level ~d:(t.now - t.since);
      t.level <- active;
      t.since <- t.now)
    else if t.in_frame && (not active) && t.now - t.since > 163 * us
    then (
      (* End of data: passive for longer than any symbol. *)
      end_of_data t;
      t.synced <- false)
    else if (not t.in_frame) && (not active) && t.now - t.since >= 280 * us
    then t.synced <- true
  ;;
end

let clkdiv = 10 (* a tick of 1 us *)

(* Send [frames], each the bytes before its CRC, with the host keeping the
   FIFO fed, and run until the last one's interframe space is over. *)
let run ?(source = Firmware.j1850_tx) frames =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.j1850_tx_config ~clkdiv ]
  in
  let r = Receiver.create () in
  let pending = Queue.of_list (List.concat_map frames ~f:Firmware.j1850_words) in
  let reports = Queue.create () in
  let bytes = List.sum (module Int) frames ~f:(fun f -> List.length f + 1) in
  for _ = 1 to us * ((bytes * 1024) + (List.length frames * 600) + 400) do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    Receiver.step r ~active:(Isa.lines m ~inputs:0xFF land 1 = 1);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue reports)
  done;
  r, Queue.to_list reports
;;

let show (r, reports) =
  printf !"errors: %{sexp:string list}\n" r.Receiver.errors;
  List.iter (List.rev r.frames) ~f:(fun f ->
    printf "frame: %s, CRC %02x\n" (String.concat ~sep:" " (List.map f ~f:(sprintf "%02x"))) (crc8 f));
  printf !"reports: %{sexp:int list}\n" reports
;;

let%expect_test "OBD-II requests: mode 3, mode 1 PID 0, a byte of every bit pattern" =
  let frames = [ [ 0x68; 0x6A; 0xF1; 0x03 ]; [ 0x68; 0x6A; 0xF1; 0x01; 0x00 ]; [ 0x00; 0xFF; 0x55; 0xAA ] ] in
  let r, reports = run frames in
  show (r, reports);
  [%test_result: int list list] (List.rev r.frames) ~expect:frames;
  [%expect {|
    errors: ()
    frame: 68 6a f1 03, CRC cd
    frame: 68 6a f1 01 00, CRC 17
    frame: 00 ff 55 aa, CRC 1b
    reports: (0 0 0)
    |}]
;;

let%test_unit "random frames of 1 to 11 bytes" =
  Quickcheck.test
    (Quickcheck.Generator.list_with_length 2 (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255)))
    ~trials:20
    ~sexp_of:[%sexp_of: int list list]
    ~f:(fun frames ->
      let frames = List.map frames ~f:(fun f -> List.take f 11) in
      let r, reports = run frames in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: int list list] (List.rev r.frames) ~expect:frames;
      [%test_result: int list] reports ~expect:(List.map frames ~f:(fun _ -> 0)))
;;

let%expect_test "planted bugs" =
  let frames = [ [ 0x68; 0x6A; 0xF1; 0x03 ]; [ 0x48; 0x6B; 0x10; 0x43; 0x01 ] ] in
  let caught source =
    let r, reports = run ~source frames in
    not
      (List.is_empty r.errors
       && [%equal: int list list] (List.rev r.frames) frames
       && [%equal: int list] reports [ 0; 0 ])
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.j1850_tx ~pattern ~with_ in
    assert (not (String.equal s Firmware.j1850_tx));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.j1850_tx then "WRONG" else "right");
  List.iter
    [ "start of frame 160 us", fw ~pattern:"set x, 23 " ~with_:"set x, 18 "
    ; "a passive 1 sent short", fw ~pattern:"jmp !y p0 " ~with_:"jmp p0    "
    ; "an active 0 sent 92 us", fw ~pattern:"a0:     set x, 14" ~with_:"a0:     set x, 5 "
    ; "the CRC's bits lost on the way round", fw ~pattern:"in y, 1 " ~with_:"in null, 1"
    ; "the CRC not started again for the next frame", fw ~pattern:"mov crc, null" ~with_:"nop          "
    ; "a frame straight after the last", fw ~pattern:"set x, 18" ~with_:"set x, 0 "
    ; "the CRC sent while data bytes are left", fw ~pattern:"jmp !x crc8 " ~with_:"jmp x-- crc8"
    ]
    ~f:(fun (name, source) -> printf "%-46s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    start of frame 160 us                          caught
    a passive 1 sent short                         caught
    an active 0 sent 92 us                         caught
    the CRC's bits lost on the way round           caught
    the CRC not started again for the next frame   caught
    a frame straight after the last                caught
    the CRC sent while data bytes are left         caught
    |}]
;;
