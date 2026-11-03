(* The divider-timed I2C controller ([Firmware.i2c]): writes and reads,
   clock stretching, a stuck bus, and bit timing, judged by the same
   independent I2C oracles as the first controller. On the reference model
   and on the whole chip over SPI. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module I2c = Pe_model.I2c_model
module Top = Pe_hw.Top

let modes =
  Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Open_drain else Input)
;;

let write_words ~address ~bytes =
  let all = (address lsl 1) :: bytes in
  List.mapi all ~f:(fun i b -> Firmware.i2c_write_word ~stop:(i = List.length all - 1) b)
;;

let read_words ~address ~count =
  Firmware.i2c_write_word ~stop:false ((address lsl 1) lor 1)
  :: List.init count ~f:(fun i -> Firmware.i2c_read_word ~last:(i = count - 1))
;;

(* The RX word for a byte seen on the bus. *)
let report ~byte ~ack = Firmware.reverse_byte byte lor (if ack then 0 else 0x100)

let write_events ~address ~bytes =
  let open I2c.Event in
  (Start :: List.map ((address lsl 1) :: bytes) ~f:(fun value -> Byte { value; ack = true }))
  @ [ Stop ]
;;

let read_events ~address ~bytes =
  let open I2c.Event in
  let n = List.length bytes in
  (Start
   :: Byte { value = (address lsl 1) lor 1; ack = true }
   :: List.mapi bytes ~f:(fun i value -> Byte { value; ack = i < n - 1 }))
  @ [ Stop ]
;;

type outcome =
  { events : I2c.Event.t list
  ; errors : string list
  ; reports : int list
  ; trace : (bool * bool) list (* (SDA, SCL) every cycle *)
  ; released : bool (* the chip drives neither line at the end *)
  }

let run_on_model ?(source = Firmware.i2c) ?(timeout = 10_000) ~clkdiv ~target ~words ~cycles () =
  let config = { Firmware.i2c_config with clkdiv; timeout } in
  let m = Isa.create ~program:(Asm.assemble source) ~pin_modes:modes ~threads:[ config ] in
  let checker = I2c.Checker.create () in
  let pending = Queue.of_list words in
  let reports = Queue.create () in
  let trace = Queue.create () in
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
    Queue.enqueue trace (sda, scl);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue reports)
  done;
  { events = I2c.Checker.events checker
  ; errors = I2c.Checker.errors checker
  ; reports = Queue.to_list reports
  ; trace = Queue.to_list trace
  ; released = Isa.pin_out m land 0b11 = 0b11
  }
;;

(* 6 ticks a bit, 9 bits a byte, plus START/STOP and the stretch. *)
let budget ~clkdiv ~bytes ~stretch = 200 + ((bytes + 1) * ((60 * clkdiv) + stretch + 20))

let%test_unit "timeout vector points at the stuck handler; the program is 25 words" =
  let program = Asm.assemble Firmware.i2c in
  [%test_result: Isa.Instruction.op]
    program.(Firmware.i2c_stuck).op
    ~expect:(Mov { dst = Isr; src = Null });
  [%test_result: int] (Array.length program) ~expect:25
;;

let gen_common =
  Quickcheck.Generator.tuple4
    (Int.gen_incl 0 127)
    (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
    (Int.gen_incl 1 20)
    (Int.gen_incl 0 300)
;;

let%test_unit "model: write transaction, every byte ACKed, with clock stretching" =
  Quickcheck.test
    gen_common
    ~trials:150
    ~sexp_of:[%sexp_of: int * int list * int * int]
    ~f:(fun (address, bytes, clkdiv, stretch) ->
      let bytes = List.take bytes 4 in
      let target = I2c.Target.create ~address ~stretch () in
      let r =
        run_on_model
          ~clkdiv
          ~target
          ~words:(write_words ~address ~bytes)
          ~cycles:(budget ~clkdiv ~bytes:(List.length bytes) ~stretch)
          ()
      in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: I2c.Event.t list] r.events ~expect:(write_events ~address ~bytes);
      [%test_result: int list] (I2c.Target.received target) ~expect:bytes;
      [%test_result: int list]
        r.reports
        ~expect:(List.map ((address lsl 1) :: bytes) ~f:(fun byte -> report ~byte ~ack:true));
      [%test_result: bool] r.released ~expect:true)
;;

let%test_unit "model: register read: write the pointer, then read bytes back" =
  Quickcheck.test
    gen_common
    ~trials:150
    ~sexp_of:[%sexp_of: int * int list * int * int]
    ~f:(fun (address, bytes, clkdiv, stretch) ->
      let bytes = List.take bytes 4 in
      let register = (address * 37) land 0xFF in
      let target = I2c.Target.create ~to_send:bytes ~address ~stretch () in
      let n = List.length bytes in
      let r =
        run_on_model
          ~clkdiv
          ~target
          ~words:(write_words ~address ~bytes:[ register ] @ read_words ~address ~count:n)
          ~cycles:(budget ~clkdiv ~bytes:(n + 3) ~stretch)
          ()
      in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: I2c.Event.t list]
        r.events
        ~expect:(write_events ~address ~bytes:[ register ] @ read_events ~address ~bytes);
      [%test_result: int list] (I2c.Target.received target) ~expect:[ register ];
      [%test_result: int list]
        r.reports
        ~expect:
          (List.map [ address lsl 1; register ] ~f:(fun byte -> report ~byte ~ack:true)
           @ (report ~byte:((address lsl 1) lor 1) ~ack:true
              :: List.mapi bytes ~f:(fun i byte -> report ~byte ~ack:(i < n - 1)))))
;;

let%test_unit "model: no device at the address: the NACK is reported" =
  let target = I2c.Target.create ~address:0x21 ~stretch:0 () in
  let r =
    run_on_model
      ~clkdiv:3
      ~target
      ~words:(write_words ~address:0x20 ~bytes:[])
      ~cycles:(budget ~clkdiv:3 ~bytes:1 ~stretch:0)
      ()
  in
  [%test_result: string list] r.errors ~expect:[];
  [%test_result: int list] r.reports ~expect:[ report ~byte:0x40 ~ack:false ]
;;

let%test_unit "model: a target that never releases SCL: timeout, report, lines released" =
  let target = I2c.Target.create ~address:0x33 ~stretch:1_000_000 () in
  let r =
    run_on_model
      ~clkdiv:4
      ~timeout:200
      ~target
      ~words:(write_words ~address:0x33 ~bytes:[])
      ~cycles:3_000
      ()
  in
  [%test_result: int list] r.reports ~expect:[ report ~byte:0x66 ~ack:true; 0x200 ];
  [%test_result: bool] r.released ~expect:true
;;

let%expect_test "bit timing: 6 ticks a bit, SCL low 3 and high 3" =
  let clkdiv = 17 in
  let target = I2c.Target.create ~address:0x50 ~stretch:0 () in
  let r =
    run_on_model
      ~clkdiv
      ~target
      ~words:(write_words ~address:0x50 ~bytes:[ 0x00; 0xFF ])
      ~cycles:(budget ~clkdiv ~bytes:2 ~stretch:0)
      ()
  in
  let scl = List.map r.trace ~f:snd in
  let rises =
    List.filter_mapi (List.zip_exn (true :: List.drop_last_exn scl) scl) ~f:(fun i (a, b) ->
      Option.some_if ((not a) && b) i)
  in
  let periods =
    List.zip_exn (List.drop_last_exn rises) (List.tl_exn rises)
    |> List.map ~f:(fun (a, b) -> b - a)
  in
  let high =
    (* Cycles SCL stays high after the first data-bit rising edge. *)
    let from = List.nth_exn rises 1 in
    List.drop scl from |> List.take_while ~f:Fn.id |> List.length
  in
  let within_byte = List.take (List.tl_exn periods) 7 in
  printf
    !"clkdiv %d: SCL period %{sexp:int list} cycles, high %d, %.1f kHz at 10 MHz\n"
    clkdiv
    (List.dedup_and_sort within_byte ~compare)
    high
    (10_000. /. Float.of_int (List.hd_exn within_byte));
  [%expect {| clkdiv 17: SCL period (102) cycles, high 51, 98.0 kHz at 10 MHz |}]
;;

(* The firmware's own mutation test: raise SDA for STOP while SCL is still
   low. The bus then never sees a STOP, which the checker must notice. *)
let%test_unit "planted firmware bug: STOP with SCL low is caught" =
  let pattern = "set pins, 1         side 1     ; then SDA rises" in
  let mutant =
    String.substr_replace_first
      Firmware.i2c
      ~pattern
      ~with_:"set pins, 1         side 0     ; then SDA rises"
  in
  assert (not (String.equal mutant Firmware.i2c));
  let target = I2c.Target.create ~address:0x42 ~stretch:0 () in
  let r =
    run_on_model
      ~source:mutant
      ~clkdiv:2
      ~target
      ~words:(write_words ~address:0x42 ~bytes:[ 0x5A ])
      ~cycles:(budget ~clkdiv:2 ~bytes:1 ~stretch:0)
      ()
  in
  let clean =
    List.is_empty r.errors
    && [%equal: I2c.Event.t list] r.events (write_events ~address:0x42 ~bytes:[ 0x5A ])
  in
  [%test_result: bool] clean ~expect:false
;;

(* --- The whole chip, over SPI ------------------------------------------ *)

let attach_bus h ~target ~checker =
  h.Test_top.on_cycle
  <- (fun () ->
       let oe = Bits.to_int !((Test_top.o h).uio_oe) in
       let t_sda, t_scl = I2c.Target.drive target in
       let sda = not (oe land 1 = 1 || t_sda)
       and scl = not ((oe lsr 1) land 1 = 1 || t_scl) in
       (Test_top.i h).uio_in
       := Bits.of_int ~width:8 (0xFC lor Bool.to_int sda lor (Bool.to_int scl lsl 1));
       I2c.Target.step target ~sda ~scl;
       I2c.Checker.step checker ~sda ~scl)
;;

let%test_unit "chip: register read over I2C, firmware loaded over SPI" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 0 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 0 150))
    ~trials:4
    ~sexp_of:[%sexp_of: int * int list * int]
    ~f:(fun (address, bytes, stretch) ->
      let bytes = List.take bytes 3 in
      let n = List.length bytes in
      let register = 0x0F in
      let h = Test_top.create ~half:4 () in
      let target = I2c.Target.create ~to_send:bytes ~address ~stretch () in
      let checker = I2c.Checker.create () in
      attach_bus h ~target ~checker;
      Test_top.load_firmware h Firmware.i2c;
      Test_top.configure h ~thread:0 { Firmware.i2c_config with clkdiv = 3 };
      Test_top.write h Top.Addr.pin_modes 0b1010 (* P0, P1 open-drain *);
      Test_top.write h Top.Addr.ctrl 1;
      let words = write_words ~address ~bytes:[ register ] @ read_words ~address ~count:n in
      List.iter words ~f:(Test_top.push h);
      let reports = List.map words ~f:(fun _ -> Test_top.pop h) in
      Test_top.wait h 400;
      [%test_result: string list] (I2c.Checker.errors checker) ~expect:[];
      [%test_result: I2c.Event.t list]
        (I2c.Checker.events checker)
        ~expect:(write_events ~address ~bytes:[ register ] @ read_events ~address ~bytes);
      [%test_result: int list] (I2c.Target.received target) ~expect:[ register ];
      [%test_result: int list]
        (List.drop reports 3 |> List.map ~f:(fun w -> Firmware.reverse_byte (w land 0xFF)))
        ~expect:bytes)
;;
