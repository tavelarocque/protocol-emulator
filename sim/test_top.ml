(* System tests of the whole chip, driven only through its pins.

   An OCaml SPI host bit-bangs the chip's SPI port exactly as the Tiny
   Tapeout demo board's RP2040 will: loading firmware, writing
   configuration, pushing and popping FIFO words. The protocol pins are
   recorded every cycle and judged by the same independent UART oracles used
   everywhere else. *)

open! Core
open! Hardcaml
module Top = Pe_hw.Top
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Uart_model = Pe_model.Uart_model
module Sim = Cyclesim.With_interface (Top.I) (Top.O)

type host =
  { sim : (Bits.t ref Top.I.t, Bits.t ref Top.O.t) Cyclesim.t
  ; half : int (* core clocks per SCK phase *)
  ; trace : (int * int) Queue.t (* (uio_out, uio_oe) every cycle *)
  ; mutable on_cycle : unit -> unit
      (* runs before every clock, e.g. to model devices on the protocol pins *)
  }

let i h = Cyclesim.inputs h.sim
let o h = Cyclesim.outputs h.sim

let step h =
  h.on_cycle ();
  Cyclesim.cycle h.sim;
  Queue.enqueue h.trace (Bits.to_int !((o h).uio_out), Bits.to_int !((o h).uio_oe))
;;

let wait h n =
  for _ = 1 to n do
    step h
  done
;;

let drive h ~sck ~cs_n ~mosi =
  (i h).ui_in := Bits.of_int ~width:8 (sck lor (cs_n lsl 1) lor (mosi lsl 2))
;;

let create ?mutation ~half () =
  let h =
    { sim = Sim.create (Top.create ?mutation); half; trace = Queue.create (); on_cycle = (fun () -> ()) }
  in
  drive h ~sck:0 ~cs_n:1 ~mosi:0;
  (i h).clear := Bits.vdd;
  step h;
  (i h).clear := Bits.gnd;
  wait h 4;
  h
;;

(* One SPI mode-0 transaction, MSB first: data changes while SCK is low and
   both sides sample on the rising edge. Returns the 16 bits read on MISO. *)
let transfer h ~write ~addr ~data =
  let word = (Bool.to_int write lsl 23) lor (addr lsl 16) lor (data land 0xFFFF) in
  drive h ~sck:0 ~cs_n:0 ~mosi:0;
  wait h h.half;
  let read = ref 0 in
  for b = 23 downto 0 do
    let mosi = (word lsr b) land 1 in
    drive h ~sck:0 ~cs_n:0 ~mosi;
    wait h h.half;
    if b < 16 then read := (!read lsl 1) lor (Bits.to_int !((o h).uo_out) land 1);
    drive h ~sck:1 ~cs_n:0 ~mosi;
    wait h h.half
  done;
  drive h ~sck:0 ~cs_n:0 ~mosi:0;
  wait h h.half;
  drive h ~sck:0 ~cs_n:1 ~mosi:0;
  wait h (2 * h.half);
  !read
;;

let write h addr data = ignore (transfer h ~write:true ~addr ~data : int)
let read h addr = transfer h ~write:false ~addr ~data:0
let status ?(thread = 0) h = read h (Top.Addr.for_thread thread Top.Addr.status)
let tx_level ?thread h = status ?thread h land 0x7
let rx_level ?thread h = (status ?thread h lsr 4) land 0x7

let load_image h image =
  write h Top.Addr.ctrl 0;
  Array.iteri image ~f:(fun a instr -> write h a (Isa.Instruction.encode instr))
;;

let load_firmware h source = load_image h (Asm.assemble source)

(* Writes every field of a thread's configuration into its bank. *)
let configure h ~thread (c : Isa.Thread_config.t) =
  let w a v = write h (Top.Addr.for_thread thread a) v in
  w Top.Addr.start c.start;
  w Top.Addr.out_cfg (c.out_base lor (c.out_count lsl 4));
  w Top.Addr.set_cfg (c.set_base lor (c.set_count lsl 4));
  w Top.Addr.in_base c.in_base;
  w Top.Addr.threshold c.threshold;
  w Top.Addr.timeout_vector c.timeout_vector;
  w Top.Addr.timeout c.timeout;
  w Top.Addr.sideset (c.sideset_base lor (c.sideset_count lsl 4));
  w Top.Addr.clkdiv c.clkdiv;
  let b v n = Bool.to_int v lsl n in
  w
    Top.Addr.shift
    (b c.out_msb_first 0
     lor b c.in_msb_first 1
     lor b c.autopull 2
     lor b c.autopush 3
     lor b c.crc_invert 4
     lor b c.crc_in 5);
  w Top.Addr.crc_poly_lo (c.crc_poly land 0xFFFF);
  w Top.Addr.crc_poly_hi (c.crc_poly lsr 16);
  w Top.Addr.crc_init_lo (c.crc_init land 0xFFFF);
  w Top.Addr.crc_init_hi (c.crc_init lsr 16)
;;

let push ?(thread = 0) h v =
  while tx_level ~thread h >= Isa.fifo_depth do
    ()
  done;
  write h (Top.Addr.for_thread thread Top.Addr.tx_fifo) v
;;

let pop ?(thread = 0) h =
  while rx_level ~thread h = 0 do
    ()
  done;
  read h (Top.Addr.for_thread thread Top.Addr.rx_fifo)
;;

(* --- Register file ------------------------------------------------------ *)

let%test_unit "reset values" =
  let h = create ~half:4 () in
  [%test_result: int] (read h Top.Addr.ctrl) ~expect:0;
  [%test_result: int] (read h Top.Addr.out_cfg) ~expect:0x10;
  [%test_result: int] (read h Top.Addr.set_cfg) ~expect:0x10;
  [%test_result: int] (read h Top.Addr.threshold) ~expect:8;
  [%test_result: int] (read h Top.Addr.status) ~expect:0;
  (* Reading an empty RX FIFO returns 0 and does not underflow it. *)
  [%test_result: int] (read h Top.Addr.rx_fifo) ~expect:0;
  [%test_result: int] (rx_level h) ~expect:0
;;

let%test_unit "thread 1's bank resets like thread 0's, and the unused slots read 0" =
  let h = create ~half:4 () in
  let t1 = Top.Addr.for_thread 1 in
  [%test_result: int] (read h (t1 Top.Addr.out_cfg)) ~expect:0x10;
  [%test_result: int] (read h (t1 Top.Addr.set_cfg)) ~expect:0x10;
  [%test_result: int] (read h (t1 Top.Addr.threshold)) ~expect:8;
  [%test_result: int] (status ~thread:1 h) ~expect:0;
  (* Thread 1's bank has LOAD where thread 0's has CTRL. The other two
     slots that hold globals in thread 0's bank are unused here. *)
  [%test_result: int] (read h Top.Addr.load) ~expect:0x30;
  write h (t1 Top.Addr.pin_modes) 0xFFFF;
  write h (t1 Top.Addr.sync_bypass) 0xFFFF;
  [%test_result: int] (read h (t1 Top.Addr.pin_modes)) ~expect:0;
  [%test_result: int] (read h (t1 Top.Addr.sync_bypass)) ~expect:0;
  [%test_result: int] (read h Top.Addr.ctrl) ~expect:0 ~message:"global CTRL untouched";
  [%test_result: int] (read h Top.Addr.pin_modes) ~expect:0
;;

let%test_unit "configuration registers read back what was written" =
  let per_thread =
    Top.Addr.
      [ start, 0xFF
      ; out_cfg, 0xFF
      ; set_cfg, 0xFF
      ; in_base, 0x7
      ; threshold, 0x1F
      ; timeout_vector, 0xFF
      ; timeout, 0xFFFF
      ; sideset, 0x3F
      ; clkdiv, 0xFFFF
      ; shift, 0x3F
      ; crc_poly_lo, 0xFFFF
      ; crc_poly_hi, 0xFFFF
      ; crc_init_lo, 0xFFFF
      ; crc_init_hi, 0xFFFF
      ]
  in
  let registers =
    Top.Addr.
      [ ctrl, 0x7
      ; pin_modes, 0xFFFF
      ; sync_bypass, 0xFF
      ; load, 0x3F
      ; smp_ctrl, 0x1FF
      ; smp_time, 0x7FFF
      ; smp_sync, 0xFF
      ]
    @ per_thread
    @ List.map per_thread ~f:(fun (a, m) -> Top.Addr.for_thread 1 a, m)
  in
  Quickcheck.test
    (Quickcheck.Generator.both (Int.gen_incl 4 8) (Int.gen_incl 0 0xFFFF))
    ~trials:20
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (half, seed) ->
      let h = create ~half () in
      let values = List.map registers ~f:(fun (a, m) -> a, m, (seed * (a + 7)) land 0xFFFF) in
      List.iter values ~f:(fun (a, _, v) -> write h a v);
      List.iter values ~f:(fun (a, m, v) ->
        [%test_result: int] (read h a) ~expect:(v land m) ~message:(sprintf "reg 0x%x" a)))
;;

(* --- Firmware loaded over SPI ------------------------------------------- *)

let%test_unit "Ethernet receive through the host port: a frame on pin 2, read back from the buffer" =
  (* Everything a driver does, over SPI: the program, the thread's
     configuration, the sampler's three registers, the buffer set recording.
     Then a frame on the pin, two clocks to the half bit, and the buffer read
     back. (This simulator moves every flip-flop on the rising edge, the
     falling-edge one too, so the sampler here sees each clock's level
     twice. The chip-level test in test/test.py has real half cycles.) *)
  let h = create ~half:4 () in
  load_image h (Firmware.eth_rx_image ());
  configure h ~thread:0 Firmware.eth_rx_config;
  let c = Firmware.eth_rx_sampler in
  write h Top.Addr.smp_time (c.blank lor (c.sample lsl 5) lor (c.wrap lsl 10));
  write h Top.Addr.smp_sync c.sync;
  write h Top.Addr.smp_ctrl (1 lor (c.pin lsl 1) lor (Bool.to_int c.sync_enable lsl 5) lor (c.misses lsl 6));
  write h Top.Addr.buf_ptr 0;
  write h Top.Addr.buf_end (Isa.buffer_size - 1);
  write h Top.Addr.buf_ctrl 2;
  write h Top.Addr.ctrl 1;
  [%test_result: int] (read h Top.Addr.smp_status) ~expect:0 ~message:"no carrier yet";
  let frame = Test_ethernet.random_frame (Random.State.make [| 802; 3; 12 |]) 61 in
  let line =
    Test_ethernet_rx.transmission frame |> List.concat_map ~f:(fun v -> [ v; v ]) |> Queue.of_list
  in
  let clocks = Queue.length line in
  h.on_cycle
  <- (fun () ->
       let level = Option.value (Queue.dequeue line) ~default:false in
       (i h).uio_in := Bits.of_int ~width:8 (if level then 1 lsl c.pin else 0));
  wait h (clocks / 2);
  [%test_result: int] (read h Top.Addr.smp_status) ~expect:3 ~message:"carrier and sync, mid-frame";
  wait h (clocks / 2);
  [%test_result: int] (read h Top.Addr.smp_status) ~expect:0 ~message:"carrier gone after the frame";
  let recorded = read h Top.Addr.buf_ptr in
  write h Top.Addr.ctrl 0;
  write h Top.Addr.buf_ctrl 0;
  write h Top.Addr.buf_ptr 0;
  let words = Array.init recorded ~f:(fun _ -> read h Top.Addr.buf_data) |> Array.to_list in
  Test_ethernet_rx.expect_frame frame (Firmware.eth_rx_frame words)
;;

let%test_unit "echo firmware: words round-trip through SPI, both FIFOs and the core" =
  Quickcheck.test
    (Quickcheck.Generator.both
       (Int.gen_incl 4 8)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 0xFFFF)))
    ~trials:10
    ~sexp_of:[%sexp_of: int * int list]
    ~f:(fun (half, values) ->
      let values = List.take values 12 in
      let h = create ~half () in
      load_firmware h Firmware.echo;
      write h Top.Addr.ctrl 1;
      (* Interleave: push up to 3 ahead, then drain, so both FIFOs fill. *)
      let got = Queue.create () in
      List.iteri values ~f:(fun k v ->
        push h v;
        if k % 3 = 2 then Queue.enqueue got (pop h));
      while Queue.length got < List.length values do
        Queue.enqueue got (pop h)
      done;
      [%test_result: int list] (Queue.to_list got) ~expect:values)
;;

let%test_unit "UART firmware loaded over SPI: bytes on pin 0 decode with a real receiver" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 4 8)
       (Int.gen_incl 8 40)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255)))
    ~trials:12
    ~sexp_of:[%sexp_of: int * int * int list]
    ~f:(fun (half, divisor, bytes) ->
      let bytes = List.take bytes 4 in
      let h = create ~half () in
      load_firmware h Firmware.uart_tx;
      write h Top.Addr.pin_modes 0b01 (* pin 0 push-pull, rest inputs *);
      write h Top.Addr.ctrl 1;
      Queue.clear h.trace;
      push h (divisor - 4);
      List.iter bytes ~f:(push h);
      (* Up to a full FIFO of bytes can still be queued after the last push. *)
      wait h ((Isa.fifo_depth + 1) * ((10 * divisor) + 4));
      let trace = Queue.to_list h.trace in
      [%test_result: bool]
        (List.for_all trace ~f:(fun (_, oe) -> oe land 1 = 1))
        ~expect:true
        ~message:"pin 0 driven throughout";
      let line = List.map trace ~f:(fun (out, _) -> out land 1 = 1) in
      [%test_result: (int list, Uart_model.Decode_error.t) Result.t]
        (Uart_model.decode ~divisor line)
        ~expect:(Ok bytes))
;;

(* --- Planted host-port bugs --------------------------------------------- *)

(* Each bug in [Top.Mutation] must be caught through the pins alone, by the
   register read-back, the echo firmware, or the echo firmware with the two
   memories loaded separately. *)
let%expect_test "planted host-port bugs: each is caught through the pins" =
  List.iter Top.Mutation.all ~f:(fun mutation ->
    let h = create ~mutation ~half:4 () in
    let values = Top.Addr.[ timeout, 0xA5C3; clkdiv, 0x1234; out_cfg, 0x37 ] in
    List.iter values ~f:(fun (a, v) -> write h a v);
    let readback_ok = List.for_all values ~f:(fun (a, v) -> read h a = v) in
    let h = create ~mutation ~half:4 () in
    load_firmware h Firmware.echo;
    write h Top.Addr.ctrl 1;
    let words = [ 0x0001; 0x8000; 0x5A5A ] in
    (* Plain writes and reads, not [push] and [pop]: those poll STATUS, which
       a broken MISO could make them do forever. Three words fit both FIFOs. *)
    List.iter words ~f:(write h Top.Addr.tx_fifo);
    wait h 200;
    let echo_ok = List.for_all words ~f:(fun w -> read h Top.Addr.rx_fifo = w) in
    (* Each thread's memory on its own: echo into thread 0's only, then
       three words of "jmp 0" into thread 1's only. Thread 0 must still
       echo. *)
    let h = create ~mutation ~half:4 () in
    write h Top.Addr.load 0x10;
    load_firmware h Firmware.echo;
    write h Top.Addr.load 0x20;
    load_image h (Array.create ~len:3 (Isa.Instruction.decode 0));
    write h Top.Addr.ctrl 1;
    List.iter words ~f:(write h Top.Addr.tx_fifo);
    wait h 200;
    let separate_ok = List.for_all words ~f:(fun w -> read h Top.Addr.rx_fifo = w) in
    printf
      "%-20s read-back %s, echo %s, separate memories %s\n"
      (Sexp.to_string (Top.Mutation.sexp_of_t mutation))
      (if readback_ok then "MISSED" else "caught")
      (if echo_ok then "MISSED" else "caught")
      (if separate_ok then "MISSED" else "caught"));
  [%expect {|
    Miso_shifts_early    read-back caught, echo caught, separate memories caught
    Load_writes_both     read-back MISSED, echo MISSED, separate memories caught
    |}]
;;
