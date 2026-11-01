(* The I2C controller firmware, judged by the independent I2C oracles.

   On the reference model and on the whole chip (driven over SPI), the two
   open-drain lines are resolved against a simulated target device every
   cycle, and a passive checker decodes the bus. The firmware passes only if
   the checker sees a clean transaction, the target received the bytes, and
   the host got the right ACK reports. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module I2c = Pe_model.I2c_model
module Top = Pe_hw.Top

let config ~timeout =
  { Isa.Thread_config.default with
    out_base = 0
  ; out_count = 1
  ; set_base = 1
  ; set_count = 1
  ; in_base = 0
  ; threshold = 8
  ; timeout_vector = Firmware.i2c_timeout_vector
  ; timeout
  }
;;

let modes =
  Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Open_drain else Input)
;;

(* Host words for one write transaction. *)
let transaction ~address ~bytes =
  let all = (address lsl 1) :: bytes in
  List.mapi all ~f:(fun i b -> Firmware.i2c_word ~stop:(i = List.length all - 1) b)
;;

let expected_events ~address ~bytes ~acked =
  let open I2c.Event in
  (Start :: Byte { value = address lsl 1; ack = acked } :: List.map bytes ~f:(fun v ->
     Byte { value = v; ack = acked }))
  @ [ Stop ]
;;

type outcome =
  { events : I2c.Event.t list
  ; errors : string list
  ; received : int list
  ; reports : int list (* RX FIFO words: 0 ACK, 1 NACK, 2 stuck *)
  ; idle_at_end : bool (* both lines released *)
  }
[@@deriving sexp_of]

let run_on_model ?(source = Firmware.i2c_controller) ~half ~timeout ~target ~words ~cycles () =
  let m =
    Isa.create ~program:(Asm.assemble source) ~pin_modes:modes ~threads:[ config ~timeout ]
  in
  let checker = I2c.Checker.create () in
  let pending = Queue.of_list (half :: words) in
  let reports = Queue.create () in
  let last = ref (true, true) in
  for _ = 1 to cycles do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    let t_sda, t_scl = I2c.Target.drive target in
    let inputs = 0xFF land lnot (Bool.to_int t_sda lor (Bool.to_int t_scl lsl 1)) in
    Isa.step m ~inputs;
    let l = Isa.lines m ~inputs in
    let sda = l land 1 = 1
    and scl = (l lsr 1) land 1 = 1 in
    I2c.Target.step target ~sda ~scl;
    I2c.Checker.step checker ~sda ~scl;
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue reports);
    last := sda, scl
  done;
  { events = I2c.Checker.events checker
  ; errors = I2c.Checker.errors checker
  ; received = I2c.Target.received target
  ; reports = Queue.to_list reports
  ; idle_at_end = Poly.equal !last (true, true)
  }
;;

let budget ~half ~n ~stretch = 400 + ((n + 1) * ((20 * (half + 6)) + stretch + 20))

let%test_unit "timeout vector points at the stuck handler" =
  let program = Asm.assemble Firmware.i2c_controller in
  [%test_result: string]
    (Isa.Instruction.to_string program.(Firmware.i2c_timeout_vector))
    ~expect:"set x, 2";
  [%test_pred: int] (fun n -> n <= Isa.program_size) (Array.length program)
;;

let%test_unit "model: write transaction, ACKed, with clock stretching" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Int.gen_incl 0 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 2 12)
       (Int.gen_incl 0 300))
    ~trials:150
    ~sexp_of:[%sexp_of: int * int list * int * int]
    ~f:(fun (address, bytes, half, stretch) ->
      let bytes = List.take bytes 4 in
      let target = I2c.Target.create ~address ~stretch in
      let r =
        run_on_model
          ~half
          ~timeout:10_000
          ~target
          ~words:(transaction ~address ~bytes)
          ~cycles:(budget ~half ~n:(List.length bytes) ~stretch)
          ()
      in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: I2c.Event.t list] r.events ~expect:(expected_events ~address ~bytes ~acked:true);
      [%test_result: int list] r.received ~expect:bytes;
      [%test_result: int list] r.reports ~expect:(List.map (0 :: bytes) ~f:(fun _ -> 0));
      [%test_result: bool] r.idle_at_end ~expect:true)
;;

let%test_unit "model: wrong address is NACKed and reported" =
  let target = I2c.Target.create ~address:0x50 ~stretch:0 in
  let bytes = [ 0x12; 0x34 ] in
  let r =
    run_on_model
      ~half:4
      ~timeout:10_000
      ~target
      ~words:(transaction ~address:0x51 ~bytes)
      ~cycles:(budget ~half:4 ~n:2 ~stretch:0)
      ()
  in
  [%test_result: string list] r.errors ~expect:[];
  [%test_result: I2c.Event.t list]
    r.events
    ~expect:(expected_events ~address:0x51 ~bytes ~acked:false);
  [%test_result: int list] r.received ~expect:[];
  [%test_result: int list] r.reports ~expect:[ 1; 1; 1 ]
;;

let%test_unit "model: back-to-back transactions" =
  let target = I2c.Target.create ~address:0x3C ~stretch:20 in
  let words = transaction ~address:0x3C ~bytes:[ 0xAE ] @ transaction ~address:0x3C ~bytes:[ 0x00; 0xFF ] in
  let r =
    run_on_model ~half:3 ~timeout:10_000 ~target ~words ~cycles:(budget ~half:3 ~n:5 ~stretch:20) ()
  in
  [%test_result: string list] r.errors ~expect:[];
  [%test_result: I2c.Event.t list]
    r.events
    ~expect:
      (expected_events ~address:0x3C ~bytes:[ 0xAE ] ~acked:true
       @ expected_events ~address:0x3C ~bytes:[ 0x00; 0xFF ] ~acked:true);
  [%test_result: int list] r.received ~expect:[ 0xAE; 0x00; 0xFF ]
;;

let%test_unit "model: a stretch longer than TIMEOUT is reported and the bus released" =
  let target = I2c.Target.create ~address:0x20 ~stretch:2_000 in
  let r =
    run_on_model
      ~half:4
      ~timeout:100
      ~target
      ~words:(transaction ~address:0x20 ~bytes:[ 0x01 ])
      ~cycles:4_000
      ()
  in
  (* The address byte is ACKed, then the target stretches past the budget
     during the data byte. Only that byte is queued: after a 2 the firmware
     is idle again, and a real host would stop sending rather than start a
     new transaction on a bus that is still held low. *)
  [%test_result: int list] r.reports ~expect:[ 0; 2 ];
  [%test_result: bool] r.idle_at_end ~expect:true
;;

(* Test the test: a controller that moves SDA before lowering SCL changes
   SDA while SCL is high, which the checker must catch. *)
let%test_unit "planted firmware bug: SDA changed while SCL high is caught" =
  let mutant =
    String.substr_replace_first
      Firmware.i2c_controller
      ~pattern:"bit:    set pins, 0         ; SCL low\n        out pins, 1 "
      ~with_:"bit:    out pins, 1         ; BUG\n        set pins, 0 "
  in
  assert (not (String.equal mutant Firmware.i2c_controller));
  let target = I2c.Target.create ~address:0x42 ~stretch:0 in
  let bytes = [ 0x5A ] in
  let r =
    run_on_model
      ~source:mutant
      ~half:4
      ~timeout:10_000
      ~target
      ~words:(transaction ~address:0x42 ~bytes)
      ~cycles:(budget ~half:4 ~n:1 ~stretch:0)
      ()
  in
  let clean =
    List.is_empty r.errors
    && [%equal: I2c.Event.t list] r.events (expected_events ~address:0x42 ~bytes ~acked:true)
  in
  [%test_result: bool] clean ~expect:false
;;

(* --- The whole chip, over SPI ------------------------------------------ *)

let%test_unit "chip: I2C firmware loaded over SPI writes to a target device" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 0 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 0 150))
    ~trials:6
    ~sexp_of:[%sexp_of: int * int list * int]
    ~f:(fun (address, bytes, stretch) ->
      let bytes = List.take bytes 3 in
      let h = Test_top.create ~half:4 in
      let target = I2c.Target.create ~address ~stretch in
      let checker = I2c.Checker.create () in
      h.on_cycle
      <- (fun () ->
           (* Resolve the open-drain bus: low if the chip or the target pulls. *)
           let oe = Bits.to_int !((Test_top.o h).uio_oe) in
           let t_sda, t_scl = I2c.Target.drive target in
           let sda = not (oe land 1 = 1 || t_sda)
           and scl = not ((oe lsr 1) land 1 = 1 || t_scl) in
           (Test_top.i h).uio_in
           := Bits.of_int ~width:8 (0xFC lor Bool.to_int sda lor (Bool.to_int scl lsl 1));
           I2c.Target.step target ~sda ~scl;
           I2c.Checker.step checker ~sda ~scl);
      Test_top.load_firmware h Firmware.i2c_controller;
      Test_top.write h Top.Addr.set_cfg 0x11 (* SET: base 1 (SCL), count 1 *);
      Test_top.write h Top.Addr.timeout_vector Firmware.i2c_timeout_vector;
      Test_top.write h Top.Addr.timeout 10_000;
      Test_top.write h Top.Addr.pin_modes 0b1010 (* P0, P1 open-drain *);
      Test_top.write h Top.Addr.ctrl 1;
      let words = 4 :: transaction ~address ~bytes in
      List.iter words ~f:(Test_top.push h);
      let reports = List.init (List.length bytes + 1) ~f:(fun _ -> Test_top.pop h) in
      Test_top.wait h 400;
      [%test_result: string list] (I2c.Checker.errors checker) ~expect:[];
      [%test_result: I2c.Event.t list]
        (I2c.Checker.events checker)
        ~expect:(expected_events ~address ~bytes ~acked:true);
      [%test_result: int list] (I2c.Target.received target) ~expect:bytes;
      [%test_result: int list] reports ~expect:(List.map (0 :: bytes) ~f:(fun _ -> 0)))
;;
