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
  }

let i h = Cyclesim.inputs h.sim
let o h = Cyclesim.outputs h.sim

let step h =
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

let create ~half =
  let h = { sim = Sim.create Top.create; half; trace = Queue.create () } in
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
let tx_level h = read h Top.Addr.status land 0x7
let rx_level h = (read h Top.Addr.status lsr 4) land 0x7

let load_firmware h source =
  write h Top.Addr.ctrl 0;
  Array.iteri (Asm.assemble source) ~f:(fun a instr ->
    write h a (Isa.Instruction.encode instr))
;;

let push h v =
  while tx_level h >= Isa.fifo_depth do
    ()
  done;
  write h Top.Addr.tx_fifo v
;;

let pop h =
  while rx_level h = 0 do
    ()
  done;
  read h Top.Addr.rx_fifo
;;

(* --- Register file ------------------------------------------------------ *)

let%test_unit "reset values" =
  let h = create ~half:4 in
  [%test_result: int] (read h Top.Addr.ctrl) ~expect:0;
  [%test_result: int] (read h Top.Addr.out_cfg) ~expect:0x10;
  [%test_result: int] (read h Top.Addr.set_cfg) ~expect:0x10;
  [%test_result: int] (read h Top.Addr.threshold) ~expect:8;
  [%test_result: int] (read h Top.Addr.status) ~expect:0;
  (* Reading an empty RX FIFO returns 0 and does not underflow it. *)
  [%test_result: int] (read h Top.Addr.rx_fifo) ~expect:0;
  [%test_result: int] (rx_level h) ~expect:0
;;

let%test_unit "configuration registers read back what was written" =
  let registers =
    Top.Addr.
      [ ctrl, 0x1
      ; start, 0x3F
      ; out_cfg, 0xFF
      ; set_cfg, 0xFF
      ; in_base, 0x7
      ; threshold, 0x1F
      ; timeout_vector, 0x3F
      ; pin_modes, 0xFFFF
      ; timeout, 0xFFFF
      ]
  in
  Quickcheck.test
    (Quickcheck.Generator.both (Int.gen_incl 4 8) (Int.gen_incl 0 0xFFFF))
    ~trials:20
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (half, seed) ->
      let h = create ~half in
      let values = List.map registers ~f:(fun (a, m) -> a, m, (seed * (a + 7)) land 0xFFFF) in
      List.iter values ~f:(fun (a, _, v) -> write h a v);
      List.iter values ~f:(fun (a, m, v) ->
        [%test_result: int] (read h a) ~expect:(v land m) ~message:(sprintf "reg 0x%x" a)))
;;

(* --- Firmware loaded over SPI ------------------------------------------- *)

let%test_unit "echo firmware: words round-trip through SPI, both FIFOs and the core" =
  Quickcheck.test
    (Quickcheck.Generator.both
       (Int.gen_incl 4 8)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 0xFFFF)))
    ~trials:10
    ~sexp_of:[%sexp_of: int * int list]
    ~f:(fun (half, values) ->
      let values = List.take values 12 in
      let h = create ~half in
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
      let h = create ~half in
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
