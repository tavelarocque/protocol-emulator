(* Two threads at work. Two protocols at once: side-set SPI on thread 0 and
   the UART transmitter on thread 1, loaded as one memory image, each judged
   by its own independent oracle. The clock divider. CHAIN, which feeds
   thread 0's output to thread 1. And the I2C-to-SPI bridge built from all
   three.

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
  Test_top.configure h ~thread:0 Demo.spi_config;
  Test_top.configure h ~thread:1 Demo.uart_config;
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

(* --- The clock divider ---------------------------------------------------- *)

let%test_unit "model: UART under a clock divider: bit time is divisor x CLKDIV cycles" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 4 12)
       (Int.gen_incl 0 7)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255)))
    ~trials:60
    ~sexp_of:[%sexp_of: int * int * int list]
    ~f:(fun (divisor, clkdiv, bytes) ->
      let bytes = List.take bytes 3 in
      let config =
        { Isa.Thread_config.default with
          out_base = 0
        ; out_count = 1
        ; set_base = 0
        ; set_count = 1
        ; threshold = 8
        ; clkdiv
        }
      in
      let m =
        Isa.create
          ~program:(Pe_model.Asm.assemble Firmware.uart_tx)
          ~pin_modes:(Array.init Isa.num_pins ~f:(fun p -> if p = 0 then Isa.Pin_mode.Push_pull else Input))
          ~threads:[ config ]
      in
      let pending = Queue.of_list ((divisor - 4) :: bytes) in
      let line = Queue.create () in
      let ticks = max 1 clkdiv in
      for _ = 1 to (List.length bytes + 2) * ((10 * divisor) + 4) * ticks do
        (match Queue.peek pending with
         | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
         | None -> ());
        Isa.step m ~inputs:0;
        Queue.enqueue line (Isa.pin_out m land 1 = 1)
      done;
      [%test_result: (int list, Uart_model.Decode_error.t) Result.t]
        (Uart_model.decode ~divisor:(divisor * ticks) (Queue.to_list line))
        ~expect:(Ok bytes))
;;

(* --- CHAIN: thread 0's output feeds thread 1 ------------------------------ *)

module Chained_echo = struct
  let first = Pe_model.Asm.assemble Firmware.echo
  let second_origin = Array.length first
  let image =
    Pe_model.Asm.link
      [ 0, first; second_origin, Pe_model.Asm.assemble ~origin:second_origin Firmware.echo ]
  ;;

  let configs =
    [ Isa.Thread_config.default
    ; { Isa.Thread_config.default with start = second_origin }
    ]
  ;;
end

let%test_unit "model: chained echo: words go in at thread 0 and out of thread 1" =
  Quickcheck.test
    (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 0xFFFF))
    ~trials:100
    ~sexp_of:[%sexp_of: int list]
    ~f:(fun values ->
      let values = List.take values 12 in
      let m =
        Isa.create
          ~program:Chained_echo.image
          ~pin_modes:(Array.create ~len:Isa.num_pins Isa.Pin_mode.Input)
          ~threads:Chained_echo.configs
      in
      Isa.set_chain m true;
      let pending = Queue.of_list values in
      let got = Queue.create () in
      for _ = 1 to 40 * List.length values do
        (match Queue.peek pending with
         | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
         | None -> ());
        Isa.step m ~inputs:0;
        (* The chained ends are closed to the host. *)
        [%test_result: int option] (Isa.pop_rx m ~thread:0) ~expect:None;
        [%test_result: bool] (Isa.push_tx m ~thread:1 0xDEAD) ~expect:false;
        Option.iter (Isa.pop_rx m ~thread:1) ~f:(Queue.enqueue got)
      done;
      [%test_result: int list] (Queue.to_list got) ~expect:values)
;;

let%test_unit "chip: chained echo through both threads" =
  let values = [ 0x0000; 0xFFFF; 0x1234; 0xBEEF; 0x8001; 0x7FFE ] in
  let h = Test_top.create ~half:4 in
  Test_top.load_image h Chained_echo.image;
  Test_top.configure h ~thread:1 (List.nth_exn Chained_echo.configs 1);
  Test_top.write h Top.Addr.ctrl 0b111 (* both threads, CHAIN *);
  List.iter values ~f:(Test_top.push ~thread:0 h);
  let got = List.map values ~f:(fun _ -> Test_top.pop ~thread:1 h) in
  [%test_result: int list] got ~expect:values;
  [%test_result: int] (Test_top.rx_level ~thread:0 h) ~expect:0
;;

(* --- The bridge: I2C reads in, SPI out, no host in the data path --------- *)

module Bridge = Firmware.Bridge
module I2c = Pe_model.I2c_model

let bridge_modes =
  Array.init Isa.num_pins ~f:(fun p ->
    match (Bridge.mode_bits lsr (2 * p)) land 3 with
    | 1 -> Isa.Pin_mode.Push_pull
    | 2 -> Open_drain
    | _ -> Input)
;;

(* What the SPI side must see for one I2C read: the address byte, then the
   data bytes, in one transfer. *)
let bridge_spi_events ~address ~bytes ~responses =
  expected_events ~sent:(((address lsl 1) lor 1) :: bytes) ~responses
;;

let i2c_read_events ~address ~bytes =
  let open I2c.Event in
  let n = List.length bytes in
  (Start
   :: Byte { value = (address lsl 1) lor 1; ack = true }
   :: List.mapi bytes ~f:(fun i value -> Byte { value; ack = i < n - 1 }))
  @ [ Stop ]
;;

(* One cycle of everything outside the chip: the I2C target and checker on
   P0/P1, the SPI slave and checker on P2..P5. Takes the levels the chip
   drives ([driven p], [level p]); returns the pin inputs to present. *)
let bridge_devices ~target ~i2c_checker ~slave ~spi_checker =
  fun ~driven ~level ->
  let t_sda, t_scl = I2c.Target.drive target in
  let sda = not ((driven 0 && not (level 0)) || t_sda)
  and scl = not ((driven 1 && not (level 1)) || t_scl) in
  I2c.Target.step target ~sda ~scl;
  I2c.Checker.step i2c_checker ~sda ~scl;
  let sck = driven 2 && level 2
  and mosi = driven 3 && level 3
  and cs_n = (not (driven 5)) || level 5 in
  Spi.Checker.step spi_checker ~sck ~mosi ~miso:(Spi.Slave.miso slave) ~cs_n;
  Spi.Slave.step slave ~sck ~mosi ~cs_n;
  0xFF
  land lnot (Bool.to_int (not sda))
  land lnot (Bool.to_int (not scl) lsl 1)
  land lnot (Bool.to_int (not (Spi.Slave.miso slave)) lsl 4)
;;

let%test_unit "the bridge image: both programs fit" =
  [%test_result: int] Bridge.spi_origin ~expect:25;
  [%test_pred: int] (fun n -> n <= Isa.program_size) (Array.length Bridge.image)
;;

let%test_unit "model: bridge: an I2C read comes out as one SPI transfer, untouched by the host" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Int.gen_incl 0 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 1 10)
       (Int.gen_incl 0 100))
    ~trials:100
    ~sexp_of:[%sexp_of: int * int list * int * int]
    ~f:(fun (address, bytes, clkdiv, stretch) ->
      let bytes = List.take bytes 4 in
      let n = List.length bytes in
      let responses = List.init (n + 1) ~f:(fun i -> (i * 0x35) land 0xFF) in
      let target = I2c.Target.create ~to_send:bytes ~address ~stretch () in
      let i2c_checker = I2c.Checker.create () in
      let slave = Spi.Slave.create ~responses in
      let spi_checker = Spi.Checker.create () in
      let devices = bridge_devices ~target ~i2c_checker ~slave ~spi_checker in
      let m =
        Isa.create
          ~program:Bridge.image
          ~pin_modes:bridge_modes
          ~threads:[ { Bridge.i2c_config with clkdiv }; Bridge.spi_config ]
      in
      Isa.set_chain m true;
      let pending = Queue.of_list (Bridge.read_command ~address ~count:n) in
      let replies = Queue.create () in
      let inputs = ref 0xFF in
      for _ = 1 to 400 + ((n + 2) * ((60 * clkdiv) + stretch + 30)) do
        (match Queue.peek pending with
         | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
         | None -> ());
        Isa.step m ~inputs:!inputs;
        let out = Isa.pin_out m in
        let driven p = not (Isa.Pin_mode.equal bridge_modes.(p) Isa.Pin_mode.Input) in
        let level p = (out lsr p) land 1 = 1 in
        inputs := devices ~driven ~level;
        Option.iter (Isa.pop_rx m ~thread:1) ~f:(fun v ->
          Queue.enqueue replies (Firmware.reverse_byte (v land 0xFF)))
      done;
      [%test_result: string list] (I2c.Checker.errors i2c_checker) ~expect:[];
      [%test_result: I2c.Event.t list]
        (I2c.Checker.events i2c_checker)
        ~expect:(i2c_read_events ~address ~bytes);
      [%test_result: string list] (Spi.Checker.errors spi_checker) ~expect:[];
      [%test_result: Spi.Event.t list]
        (Spi.Checker.events spi_checker)
        ~expect:(bridge_spi_events ~address ~bytes ~responses);
      [%test_result: int list]
        (Spi.Slave.received slave)
        ~expect:(((address lsl 1) lor 1) :: bytes);
      [%test_result: int list] (Queue.to_list replies) ~expect:responses)
;;

let%test_unit "chip: the bridge, loaded and started over SPI" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 0 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 0 60))
    ~trials:4
    ~sexp_of:[%sexp_of: int * int list * int]
    ~f:(fun (address, bytes, stretch) ->
      let bytes = List.take bytes 3 in
      let n = List.length bytes in
      let responses = List.init (n + 1) ~f:(fun i -> 0xA0 lor i) in
      let target = I2c.Target.create ~to_send:bytes ~address ~stretch () in
      let i2c_checker = I2c.Checker.create () in
      let slave = Spi.Slave.create ~responses in
      let spi_checker = Spi.Checker.create () in
      let devices = bridge_devices ~target ~i2c_checker ~slave ~spi_checker in
      let h = Test_top.create ~half:4 in
      h.on_cycle
      <- (fun () ->
           let out = Bits.to_int !((Test_top.o h).uio_out) in
           let oe = Bits.to_int !((Test_top.o h).uio_oe) in
           (* Open-drain pins show up as output-enable low = driving 0. *)
           let driven p = (oe lsr p) land 1 = 1 || p < 2 in
           let level p = if p < 2 then (oe lsr p) land 1 = 0 else (out lsr p) land 1 = 1 in
           (Test_top.i h).uio_in := Bits.of_int ~width:8 (devices ~driven ~level));
      Test_top.load_image h Bridge.image;
      Test_top.configure h ~thread:0 { Bridge.i2c_config with clkdiv = 3 };
      Test_top.configure h ~thread:1 Bridge.spi_config;
      Test_top.write h Top.Addr.pin_modes Bridge.mode_bits;
      Test_top.write h Top.Addr.ctrl 0b111 (* both threads, CHAIN *);
      List.iter (Bridge.read_command ~address ~count:n) ~f:(Test_top.push ~thread:0 h);
      let replies =
        List.map responses ~f:(fun _ ->
          Firmware.reverse_byte (Test_top.pop ~thread:1 h land 0xFF))
      in
      Test_top.wait h 400;
      [%test_result: string list] (I2c.Checker.errors i2c_checker) ~expect:[];
      [%test_result: I2c.Event.t list]
        (I2c.Checker.events i2c_checker)
        ~expect:(i2c_read_events ~address ~bytes);
      [%test_result: string list] (Spi.Checker.errors spi_checker) ~expect:[];
      [%test_result: Spi.Event.t list]
        (Spi.Checker.events spi_checker)
        ~expect:(bridge_spi_events ~address ~bytes ~responses);
      [%test_result: int list] replies ~expect:responses)
;;
