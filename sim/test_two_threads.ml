(* Two protocols at once: side-set SPI on thread 0 and the UART transmitter
   on thread 1, loaded as one memory image, each judged by its own
   independent oracle.

   And the property that makes two threads worth having: isolation. A
   thread's pins must behave identically, cycle for cycle, whether or not
   the other thread is running. The two threads share the program memory,
   the pin register and the pin snapshot, so a composition bug (crossed
   fetch ports, a pin write landing on the wrong thread's pins) shows up
   here as the SPI waveform changing when the UART starts. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Firmware = Pe_model.Firmware
module Demo = Pe_model.Firmware.Two_protocols
module Spi = Pe_model.Spi_model
module Uart_model = Pe_model.Uart_model
module Top = Pe_hw.Top

let spi_words bytes =
  List.mapi bytes ~f:(fun i b -> Firmware.spi_word ~last:(i = List.length bytes - 1) b)
;;

let expected_events ~sent ~responses =
  let open Spi.Event in
  (Select :: List.map2_exn sent responses ~f:(fun mosi miso -> Byte { mosi; miso }))
  @ [ Deselect ]
;;

let modes =
  Array.init Isa.num_pins ~f:(fun p ->
    match (Demo.mode_bits lsr (2 * p)) land 3 with
    | 1 -> Isa.Pin_mode.Push_pull
    | _ -> Input)
;;

type outcome =
  { spi_trace : int list (* P0..P3 every cycle *)
  ; spi_events : Spi.Event.t list
  ; spi_errors : string list
  ; slave_received : int list
  ; host_received : int list
  ; uart_line : bool list (* P4 every cycle *)
  }

(* On the reference model. With [uart = None] thread 1 stays disabled. *)
let run_model ~sent ~responses ~uart ~cycles =
  let m =
    Isa.create
      ~program:Demo.image
      ~pin_modes:modes
      ~threads:[ Demo.spi_config; Demo.uart_config ]
  in
  Isa.set_enabled m ~thread:1 (Option.is_some uart);
  let slave = Spi.Slave.create ~responses in
  let checker = Spi.Checker.create () in
  let pending =
    [| Queue.of_list (spi_words sent)
     ; Queue.of_list
         (match uart with
          | None -> []
          | Some (divisor, bytes) -> (divisor - 4) :: bytes)
    |]
  in
  let host_rx = Queue.create () in
  let spi_trace = Queue.create () in
  let uart_line = Queue.create () in
  for _ = 1 to cycles do
    Array.iteri pending ~f:(fun thread q ->
      match Queue.peek q with
      | Some v -> if Isa.push_tx m ~thread v then ignore (Queue.dequeue q : int option)
      | None -> ());
    let inputs = 0xFF land lnot (Bool.to_int (not (Spi.Slave.miso slave)) lsl 2) in
    Isa.step m ~inputs;
    let l = Isa.lines m ~inputs in
    let sck = l land 1 = 1
    and mosi = (l lsr 1) land 1 = 1
    and cs_n = (l lsr 3) land 1 = 1 in
    Spi.Checker.step checker ~sck ~mosi ~miso:(Spi.Slave.miso slave) ~cs_n;
    Spi.Slave.step slave ~sck ~mosi ~cs_n;
    Queue.enqueue spi_trace (l land 0xF);
    Queue.enqueue uart_line ((l lsr 4) land 1 = 1);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(fun v ->
      Queue.enqueue host_rx (Firmware.reverse_byte (v land 0xFF)))
  done;
  { spi_trace = Queue.to_list spi_trace
  ; spi_events = Spi.Checker.events checker
  ; spi_errors = Spi.Checker.errors checker
  ; slave_received = Spi.Slave.received slave
  ; host_received = Queue.to_list host_rx
  ; uart_line = Queue.to_list uart_line
  }
;;

let gen =
  Quickcheck.Generator.tuple3
    (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
    (Int.gen_incl 4 24)
    (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
;;

let%test_unit "the demo image: both programs fit, and the UART was relocated" =
  [%test_result: int] Demo.uart_origin ~expect:(Array.length Demo.spi);
  (* test/test.py hardcodes this. *)
  [%test_result: int] Demo.uart_origin ~expect:26;
  [%test_pred: int] (fun n -> n <= Isa.program_size) (Array.length Demo.image);
  (* Relocation moved every UART jump target past the SPI program. *)
  Array.iter Demo.uart ~f:(fun instr ->
    match instr.op with
    | Jmp { addr; _ } -> [%test_pred: int] (fun a -> a >= Demo.uart_origin) addr
    | _ -> ())
;;

let%test_unit "model: SPI and UART run at the same time, each correct" =
  Quickcheck.test
    gen
    ~trials:100
    ~sexp_of:[%sexp_of: int list * int * int list]
    ~f:(fun (sent, divisor, bytes) ->
      let sent = List.take sent 4
      and bytes = List.take bytes 4 in
      let responses = List.map sent ~f:(fun b -> (b * 7) land 0xFF) in
      let cycles = 200 + (List.length bytes * ((10 * divisor) + 4)) in
      let r = run_model ~sent ~responses ~uart:(Some (divisor, bytes)) ~cycles in
      [%test_result: string list] r.spi_errors ~expect:[];
      [%test_result: Spi.Event.t list] r.spi_events ~expect:(expected_events ~sent ~responses);
      [%test_result: int list] r.slave_received ~expect:sent;
      [%test_result: int list] r.host_received ~expect:responses;
      [%test_result: (int list, Uart_model.Decode_error.t) Result.t]
        (Uart_model.decode ~divisor r.uart_line)
        ~expect:(Ok bytes))
;;

let%test_unit "model: the SPI waveform is identical whether or not the UART runs" =
  Quickcheck.test
    gen
    ~trials:100
    ~sexp_of:[%sexp_of: int list * int * int list]
    ~f:(fun (sent, divisor, bytes) ->
      let sent = List.take sent 4 in
      let responses = List.map sent ~f:(fun b -> b lxor 0x5A) in
      let cycles = 300 in
      let alone = run_model ~sent ~responses ~uart:None ~cycles in
      let shared = run_model ~sent ~responses ~uart:(Some (divisor, bytes)) ~cycles in
      [%test_result: int list] shared.spi_trace ~expect:alone.spi_trace;
      (* And the UART line really was busy, so the comparison means
         something. *)
      [%test_pred: bool list] (List.exists ~f:not) shared.uart_line)
;;

(* --- The whole chip, over SPI ------------------------------------------- *)

(* Loads the demo image, configures both banks, and attaches an SPI slave
   and checker to P0..P3. Returns the chip with both threads still
   disabled. *)
let chip ~responses =
  let h = Test_top.create ~half:4 in
  let slave = Spi.Slave.create ~responses in
  let checker = Spi.Checker.create () in
  h.on_cycle
  <- (fun () ->
       let out = Bits.to_int !((Test_top.o h).uio_out) in
       let oe = Bits.to_int !((Test_top.o h).uio_oe) in
       let driven p = (oe lsr p) land 1 = 1 in
       let level p = (out lsr p) land 1 = 1 in
       let sck = driven 0 && level 0
       and mosi = driven 1 && level 1
       and cs_n = (not (driven 3)) || level 3 in
       Spi.Checker.step checker ~sck ~mosi ~miso:(Spi.Slave.miso slave) ~cs_n;
       Spi.Slave.step slave ~sck ~mosi ~cs_n;
       (Test_top.i h).uio_in
       := Bits.of_int ~width:8 (Bool.to_int (Spi.Slave.miso slave) lsl 2));
  Test_top.load_image h Demo.image;
  let configure thread (c : Isa.Thread_config.t) =
    let w a v = Test_top.write h (Top.Addr.for_thread thread a) v in
    w Top.Addr.start c.start;
    w Top.Addr.out_cfg (c.out_base lor (c.out_count lsl 4));
    w Top.Addr.set_cfg (c.set_base lor (c.set_count lsl 4));
    w Top.Addr.in_base c.in_base;
    w Top.Addr.threshold c.threshold;
    w Top.Addr.sideset (c.sideset_base lor (c.sideset_count lsl 4))
  in
  configure 0 Demo.spi_config;
  configure 1 Demo.uart_config;
  Test_top.write h Top.Addr.pin_modes Demo.mode_bits;
  h, slave, checker
;;

let%test_unit "chip: SPI and UART loaded as one image over SPI, running together" =
  Quickcheck.test
    gen
    ~trials:6
    ~sexp_of:[%sexp_of: int list * int * int list]
    ~f:(fun (sent, divisor, bytes) ->
      let sent = List.take sent 3
      and bytes = List.take bytes 3 in
      let responses = List.map sent ~f:(fun b -> b lxor 0xFF) in
      let h, slave, checker = chip ~responses in
      (* One write starts both threads in the same cycle. *)
      Test_top.write h Top.Addr.ctrl 0b11;
      Queue.clear h.trace;
      (* The UART's queue goes first so its line is busy while SPI runs. *)
      List.iter ((divisor - 4) :: bytes) ~f:(Test_top.push ~thread:1 h);
      List.iter (spi_words sent) ~f:(Test_top.push ~thread:0 h);
      let got =
        List.map sent ~f:(fun _ ->
          Firmware.reverse_byte (Test_top.pop ~thread:0 h land 0xFF))
      in
      Test_top.wait h ((Isa.fifo_depth + 1) * ((10 * divisor) + 4));
      [%test_result: string list] (Spi.Checker.errors checker) ~expect:[];
      [%test_result: Spi.Event.t list]
        (Spi.Checker.events checker)
        ~expect:(expected_events ~sent ~responses);
      [%test_result: int list] (Spi.Slave.received slave) ~expect:sent;
      [%test_result: int list] got ~expect:responses;
      let uart_line = List.map (Queue.to_list h.trace) ~f:(fun (out, _) -> (out lsr 4) land 1 = 1) in
      [%test_result: (int list, Uart_model.Decode_error.t) Result.t]
        (Uart_model.decode ~divisor uart_line)
        ~expect:(Ok bytes);
      (* Both threads still running, and both reported on the status pins. *)
      [%test_result: int] (Bits.to_int !((Test_top.o h).uo_out) land 0b10010) ~expect:0b10010)
;;
