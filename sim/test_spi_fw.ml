(* The SPI controller firmware, judged by the independent SPI oracles: a
   simulated slave with scripted responses on the wires, and a passive
   mode-0 checker decoding both directions. On the reference model and on
   the whole chip over SPI. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Spi = Pe_model.Spi_model
module Top = Pe_hw.Top

let config =
  { Isa.Thread_config.default with
    set_base = 0
  ; set_count = 1
  ; out_base = 1
  ; out_count = 3
  ; in_base = 2
  ; threshold = 8
  }
;;

(* P0 SCK, P1 MOSI, P3 CS_N push-pull; P2 MISO input. *)
let mode_bits = 0b01_00_01_01

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    match (mode_bits lsr (2 * i)) land 3 with
    | 1 -> Isa.Pin_mode.Push_pull
    | _ -> Input)
;;

let transfer bytes =
  List.mapi bytes ~f:(fun i b -> Firmware.spi_word ~last:(i = List.length bytes - 1) b)
;;

let expected_events ~sent ~responses =
  let open Spi.Event in
  (Select :: List.map2_exn sent responses ~f:(fun mosi miso -> Byte { mosi; miso }))
  @ [ Deselect ]
;;

type outcome =
  { events : Spi.Event.t list
  ; errors : string list
  ; received_by_slave : int list
  ; received_by_host : int list
  ; sck_rises : int list (* cycles of SCK rising edges, for bit timing *)
  }

(* [spi_fast]: SCK comes from side-set instead of SET. *)
let fast_config = { config with sideset_base = 0; sideset_count = 1 }

let run_on_model
  ?(sync_bypass = 0)
  ?(source = Firmware.spi_controller)
  ?(cfg = config)
  ?half
  ~responses
  ~words
  ~cycles
  ()
  =
  let m = Isa.create ~program:(Asm.assemble source) ~pin_modes:modes ~threads:[ cfg ] in
  Isa.set_sync_bypass m sync_bypass;
  let slave = Spi.Slave.create ~responses in
  let checker = Spi.Checker.create () in
  let pending = Queue.of_list (Option.to_list half @ words) in
  let host_rx = Queue.create () in
  let rises = Queue.create () in
  let prev_sck = ref false in
  for cycle = 1 to cycles do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    let inputs = 0xFF land lnot (Bool.to_int (not (Spi.Slave.miso slave)) lsl 2) in
    Isa.step m ~inputs;
    let l = Isa.lines m ~inputs in
    let sck = l land 1 = 1
    and mosi = (l lsr 1) land 1 = 1
    and cs_n = (l lsr 3) land 1 = 1 in
    let miso = Spi.Slave.miso slave in
    Spi.Checker.step checker ~sck ~mosi ~miso ~cs_n;
    Spi.Slave.step slave ~sck ~mosi ~cs_n;
    if sck && not !prev_sck then Queue.enqueue rises cycle;
    prev_sck := sck;
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(fun v ->
      Queue.enqueue host_rx (if cfg.in_msb_first then v else Firmware.reverse_byte (v land 0xFF)))
  done;
  { events = Spi.Checker.events checker
  ; errors = Spi.Checker.errors checker
  ; received_by_slave = Spi.Slave.received slave
  ; received_by_host = Queue.to_list host_rx
  ; sck_rises = Queue.to_list rises
  }
;;

let budget ~half ~n = 100 + (n * 8 * ((2 * half) + 12))

(* --- The oracles themselves ---------------------------------------------- *)

let%test_unit "checker flags MOSI changing while SCK is high" =
  let c = Spi.Checker.create () in
  List.iter
    [ false, false, true
    ; false, false, false (* select *)
    ; true, false, false (* SCK high *)
    ; true, true, false (* MOSI changes while high: violation *)
    ]
    ~f:(fun (sck, mosi, cs_n) -> Spi.Checker.step c ~sck ~mosi ~miso:true ~cs_n);
  [%test_pred: string list] (Fn.non List.is_empty) (Spi.Checker.errors c)
;;

let%test_unit "checker flags a deselect in the middle of a byte" =
  let c = Spi.Checker.create () in
  List.iter
    [ false, true; false, false; true, false; false, false; false, true ]
    ~f:(fun (sck, cs_n) -> Spi.Checker.step c ~sck ~mosi:false ~miso:true ~cs_n);
  [%test_pred: string list] (Fn.non List.is_empty) (Spi.Checker.errors c)
;;

(* --- Firmware on the model ---------------------------------------------- *)

let%test_unit "model: full-duplex transfers of random bytes at random speeds" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 0 8))
    ~trials:200
    ~sexp_of:[%sexp_of: int list * int list * int]
    ~f:(fun (sent, responses, half) ->
      let sent = List.take sent 6 in
      let responses =
        List.init (List.length sent) ~f:(fun i ->
          Option.value (List.nth responses i) ~default:(i * 37 % 256))
      in
      let r =
        run_on_model
          ~half
          ~responses
          ~words:(transfer sent)
          ~cycles:(budget ~half ~n:(List.length sent))
          ()
      in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: Spi.Event.t list] r.events ~expect:(expected_events ~sent ~responses);
      [%test_result: int list] r.received_by_slave ~expect:sent;
      [%test_result: int list] r.received_by_host ~expect:responses)
;;

let%test_unit "model: back-to-back transfers each select and deselect" =
  let r =
    run_on_model
      ~half:1
      ~responses:[ 0x11; 0x22; 0x33 ]
      ~words:(transfer [ 0x9F ] @ transfer [ 0x03; 0x00 ])
      ~cycles:(budget ~half:1 ~n:3 + 50)
      ()
  in
  [%test_result: string list] r.errors ~expect:[];
  [%test_result: Spi.Event.t list]
    r.events
    ~expect:
      (expected_events ~sent:[ 0x9F ] ~responses:[ 0x11 ]
       @ expected_events ~sent:[ 0x03; 0x00 ] ~responses:[ 0x22; 0x33 ])
;;

(* Test the test: driving MOSI after raising SCK breaks mode 0. *)
let%test_unit "planted firmware bug: MOSI changed while SCK high is caught" =
  let mutant =
    String.substr_replace_first
      Firmware.spi_controller
      ~pattern:
        "bit:    out pins, 1         ; MOSI = next bit, while SCK is low\n\
        \        mov x, y\n\
         c1:     jmp x-- c1\n\
        \        set pins, 1 "
      ~with_:
        "bit:    set pins, 1         ; BUG\n\
        \        mov x, y\n\
         c1:     jmp x-- c1\n\
        \        out pins, 1 "
  in
  assert (not (String.equal mutant Firmware.spi_controller));
  let sent = [ 0xA5; 0x3C ] in
  let r =
    run_on_model ~source:mutant ~half:2 ~responses:[ 1; 2 ] ~words:(transfer sent)
      ~cycles:(budget ~half:2 ~n:2) ()
  in
  let clean = List.is_empty r.errors && [%equal: int list] r.received_by_slave sent in
  [%test_result: bool] clean ~expect:false
;;

(* The number that decides whether the ISA needs side-set. *)
let%expect_test "bit timing (loop-timed firmware)" =
  List.iter [ 0; 1; 4 ] ~f:(fun half ->
    let r = run_on_model ~half ~responses:[ 0 ] ~words:(transfer [ 0x55 ]) ~cycles:300 () in
    let periods =
      List.zip_exn (List.drop_last_exn r.sck_rises) (List.tl_exn r.sck_rises)
      |> List.map ~f:(fun (a, b) -> b - a)
      |> List.dedup_and_sort ~compare
    in
    printf
      !"H=%d: cycles per bit %{sexp:int list}, %.2f Mbit/s at 10 MHz\n"
      half
      periods
      (10. /. Float.of_int (List.hd_exn periods)));
  [%expect {|
    H=0: cycles per bit (9), 1.11 Mbit/s at 10 MHz
    H=1: cycles per bit (11), 0.91 Mbit/s at 10 MHz
    H=4: cycles per bit (17), 0.59 Mbit/s at 10 MHz
    |}]
;;

(* MISO (P2) bypasses the input synchroniser: see [Firmware.spi_fast]. *)
let run_fast = run_on_model ~sync_bypass:0b100 ~source:Firmware.spi_fast ~cfg:fast_config

let%test_unit "side-set SPI through the synchroniser reads MISO two cycles stale" =
  (* Why [spi_fast] needs SYNC_BYPASS on MISO: with the two-cycle delay it
     samples bits from the wrong SCK period. *)
  let responses = [ 0xA5; 0x3C ] in
  let r =
    run_on_model
      ~source:Firmware.spi_fast
      ~cfg:fast_config
      ~responses
      ~words:(transfer [ 0x00; 0x00 ])
      ~cycles:200
      ()
  in
  [%test_pred: int list] (fun got -> not ([%equal: int list] got responses)) r.received_by_host
;;

let%test_unit "model: side-set SPI, full-duplex transfers of random bytes" =
  Quickcheck.test
    (Quickcheck.Generator.both
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255)))
    ~trials:200
    ~sexp_of:[%sexp_of: int list * int list]
    ~f:(fun (sent, responses) ->
      let sent = List.take sent 6 in
      let responses =
        List.init (List.length sent) ~f:(fun i ->
          Option.value (List.nth responses i) ~default:(i * 53 % 256))
      in
      let r = run_fast ~responses ~words:(transfer sent) ~cycles:(60 + (30 * List.length sent)) () in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: Spi.Event.t list] r.events ~expect:(expected_events ~sent ~responses);
      [%test_result: int list] r.received_by_slave ~expect:sent;
      [%test_result: int list] r.received_by_host ~expect:responses)
;;

let%expect_test "side-set SPI bit timing" =
  let r = run_fast ~responses:[ 0; 0 ] ~words:(transfer [ 0x55; 0xAA ]) ~cycles:200 () in
  let periods =
    List.zip_exn (List.drop_last_exn r.sck_rises) (List.tl_exn r.sck_rises)
    |> List.map ~f:(fun (a, b) -> b - a)
  in
  let within_byte = List.filteri periods ~f:(fun i _ -> (i + 1) % 8 <> 0) in
  printf
    !"cycles per bit within a byte %{sexp:int list}, %.2f Mbit/s at 10 MHz; byte-to-byte gap %d\n"
    (List.dedup_and_sort within_byte ~compare)
    (10. /. Float.of_int (List.hd_exn within_byte))
    (List.nth_exn periods 7);
  [%expect {| cycles per bit within a byte (2), 5.00 Mbit/s at 10 MHz; byte-to-byte gap 7 |}]
;;

(* --- The whole chip, over SPI ------------------------------------------- *)

let msb_config = { fast_config with out_msb_first = true; in_msb_first = true }

let msb_transfer bytes =
  List.mapi bytes ~f:(fun i b -> Firmware.spi_msb_word ~last:(i = List.length bytes - 1) b)
;;

let%test_unit "model: side-set SPI with MSB-first shifting: plain bytes both ways" =
  Quickcheck.test
    (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
    ~trials:200
    ~sexp_of:[%sexp_of: int list]
    ~f:(fun sent ->
      let sent = List.take sent 6 in
      let responses = List.map sent ~f:(fun b -> (b * 5) land 0xFF) in
      let r =
        run_on_model
          ~sync_bypass:0b100
          ~source:Firmware.spi_fast
          ~cfg:msb_config
          ~responses
          ~words:(msb_transfer sent)
          ~cycles:(60 + (30 * List.length sent))
          ()
      in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: Spi.Event.t list] r.events ~expect:(expected_events ~sent ~responses);
      [%test_result: int list] r.received_by_slave ~expect:sent;
      [%test_result: int list] r.received_by_host ~expect:responses)
;;

let chip_test ?(msb = false) ~fast () =
  Quickcheck.test
    (Quickcheck.Generator.both
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 0 3))
    ~trials:6
    ~sexp_of:[%sexp_of: int list * int]
    ~f:(fun (sent, half) ->
      let sent = List.take sent 3 in
      let responses = List.map sent ~f:(fun b -> b lxor 0xFF) in
      let h = Test_top.create ~half:4 () in
      let slave = Spi.Slave.create ~responses in
      let checker = Spi.Checker.create () in
      h.on_cycle
      <- (fun () ->
           (* Undriven pins read as the board pulls them: SCK and MOSI low,
              CS_N high. *)
           let out = Bits.to_int !((Test_top.o h).uio_out) in
           let oe = Bits.to_int !((Test_top.o h).uio_oe) in
           let driven p = (oe lsr p) land 1 = 1 in
           let level p = (out lsr p) land 1 = 1 in
           let sck = driven 0 && level 0
           and mosi = driven 1 && level 1
           and cs_n = (not (driven 3)) || level 3 in
           let miso = Spi.Slave.miso slave in
           Spi.Checker.step checker ~sck ~mosi ~miso ~cs_n;
           Spi.Slave.step slave ~sck ~mosi ~cs_n;
           (* The slave reacts to this cycle's SCK edge before the chip's
              next sample: a response time under one core clock (100 ns at
              10 MHz), as real SPI devices manage in tens of ns. The
              side-set firmware samples MISO exactly one clock after SCK
              falls, so it depends on this; the loop-timed one has slack. *)
           (Test_top.i h).uio_in
           := Bits.of_int ~width:8 (Bool.to_int (Spi.Slave.miso slave) lsl 2));
      if fast
      then (
        Test_top.load_firmware h Firmware.spi_fast;
        Test_top.write h Top.Addr.sideset 0x10 (* side-set: base 0 (SCK), count 1 *);
        Test_top.write h Top.Addr.sync_bypass 0b100 (* MISO read directly *))
      else (
        Test_top.load_firmware h Firmware.spi_controller;
        Test_top.write h Top.Addr.set_cfg 0x10 (* SET: base 0 (SCK), count 1 *));
      Test_top.write h Top.Addr.out_cfg 0x31 (* OUT: base 1 (MOSI), count 3 *);
      Test_top.write h Top.Addr.in_base 2 (* MISO *);
      Test_top.write h Top.Addr.pin_modes mode_bits;
      Test_top.write h Top.Addr.ctrl 1;
      if msb then Test_top.write h Top.Addr.shift 0b11 (* MSB first, OUT and IN *);
      List.iter
        ((if fast then [] else [ half ]) @ if msb then msb_transfer sent else transfer sent)
        ~f:(Test_top.push h);
      let got =
        List.map sent ~f:(fun _ ->
          let v = Test_top.pop h in
          if msb then v else Firmware.reverse_byte (v land 0xFF))
      in
      Test_top.wait h 200;
      [%test_result: string list] (Spi.Checker.errors checker) ~expect:[];
      [%test_result: Spi.Event.t list]
        (Spi.Checker.events checker)
        ~expect:(expected_events ~sent ~responses);
      [%test_result: int list] (Spi.Slave.received slave) ~expect:sent;
      [%test_result: int list] got ~expect:responses)
;;

let%test_unit "chip: SPI firmware loaded over SPI talks to a slave device" =
  chip_test ~fast:false ()
;;

let%test_unit "chip: side-set SPI firmware loaded over SPI talks to a slave device" =
  chip_test ~fast:true ()
;;

let%test_unit "chip: side-set SPI with MSB-first shifting, no bit reversal on the host" =
  chip_test ~msb:true ~fast:true ()
;;
