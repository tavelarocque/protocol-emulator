(* Device mode: the chip as an I2C device ([Firmware.i2c_target]).

   The controller is the reference controller from [I2c_model], written from
   the I2C specification: it moves SDA one clock after SCL falls (the
   tightest data hold time the spec allows short of zero) and honours clock
   stretching. The independent bus checker judges every cycle. Also here:
   the chip sharing a bus with a model device at another address, two model
   chips talking to each other (the controller firmware on one, the target
   firmware on the other), the whole chip over SPI, and planted firmware
   bugs the scenarios must catch. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module I2c = Pe_model.I2c_model
module Ref = I2c.Reference_controller
module Top = Pe_hw.Top

let modes =
  Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Open_drain else Input)
;;

(* The reference controller one cycle at a time, so it can share a bus with
   devices that are themselves stepped per cycle. Same timing as
   [Reference_controller.run]: a Drive lasts one cycle, Hold n lasts n, and
   Wait_scl_high lasts until a cycle in which SCL is high. *)
module Controller = struct
  type t =
    { mutable steps : Ref.step list
    ; mutable sda : bool (* true = released *)
    ; mutable scl : bool
    ; mutable hold : int
    ; mutable waiting : bool
    }

  let create steps = { steps; sda = true; scl = true; hold = 0; waiting = false }

  let rec begin_cycle t =
    if t.hold = 0 && not t.waiting
    then (
      match t.steps with
      | [] -> ()
      | Ref.Drive { sda; scl } :: rest ->
        t.sda <- sda;
        t.scl <- scl;
        t.steps <- rest;
        t.hold <- 1
      | Ref.Hold n :: rest ->
        t.steps <- rest;
        t.hold <- n;
        if n = 0 then begin_cycle t
      | Ref.Wait_scl_high :: rest ->
        t.steps <- rest;
        t.waiting <- true)
  ;;

  let end_cycle t ~scl =
    if t.waiting then (if scl then t.waiting <- false) else if t.hold > 0 then t.hold <- t.hold - 1
  ;;

  let finished t = List.is_empty t.steps && t.hold = 0 && not t.waiting
end

(* --- Expected bus events and RX words ----------------------------------- *)

let marker ~address ~read = Firmware.i2c_target_marker ~address ~read

let write_events ~address ~bytes =
  let open I2c.Event in
  (Start :: List.map ((address lsl 1) :: bytes) ~f:(fun value -> Byte { value; ack = true }))
  @ [ Stop ]
;;

let read_part ~address ~reply =
  let open I2c.Event in
  let n = List.length reply in
  Start
  :: Byte { value = (address lsl 1) lor 1; ack = true }
  :: List.mapi reply ~f:(fun i value -> Byte { value; ack = i < n - 1 })
;;

(* write [bytes], repeated START, read [reply], STOP *)
let register_read_events ~address ~bytes ~reply =
  List.drop_last_exn (write_events ~address ~bytes) @ read_part ~address ~reply @ [ I2c.Event.Stop ]
;;

let read_events ~address ~reply = read_part ~address ~reply @ [ I2c.Event.Stop ]

(* --- One model chip on a bus with the reference controller --------------- *)

type outcome =
  { events : I2c.Event.t list
  ; errors : string list
  ; rx : int list (* every RX word the host popped *)
  ; chip_held_scl : int (* cycles the chip held SCL low while the controller released it *)
  ; finished : bool (* the controller ran all its steps *)
  ; released : bool (* the chip drives neither line at the end *)
  }

let run_model
  ?(source = Firmware.i2c_target)
  ?(targets = [])
  ?(tx = [])
  ?(tx_at = 0)
  ?(rx_at = 0)
  ~address
  ~steps
  ()
  =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ Firmware.i2c_target_config ]
  in
  assert (Isa.push_tx m ~thread:0 (Firmware.i2c_target_address_word address));
  let ctl = Controller.create steps in
  let checker = I2c.Checker.create () in
  let pending = Queue.of_list tx in
  let rx = Queue.create () in
  let held = ref 0 in
  let cycle = ref 0 in
  let after = ref 0 in
  while !after < 300 && !cycle < 1_000_000 do
    if !cycle >= tx_at
    then (
      match Queue.peek pending with
      | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
      | None -> ());
    if !cycle >= rx_at then Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    Controller.begin_cycle ctl;
    let t_sda, t_scl =
      List.fold targets ~init:(false, false) ~f:(fun (a, b) t ->
        let x, y = I2c.Target.drive t in
        a || x, b || y)
    in
    let ext_sda = ctl.Controller.sda && not t_sda
    and ext_scl = ctl.Controller.scl && not t_scl in
    let inputs = 0xFC lor Bool.to_int ext_sda lor (Bool.to_int ext_scl lsl 1) in
    Isa.step m ~inputs;
    let l = Isa.lines m ~inputs in
    let sda = l land 1 = 1
    and scl = (l lsr 1) land 1 = 1 in
    if ext_scl && not scl then incr held;
    List.iter targets ~f:(fun t -> I2c.Target.step t ~sda ~scl);
    I2c.Checker.step checker ~sda ~scl;
    Controller.end_cycle ctl ~scl;
    if Controller.finished ctl then incr after;
    incr cycle
  done;
  { events = I2c.Checker.events checker
  ; errors = I2c.Checker.errors checker
  ; rx = Queue.to_list rx
  ; chip_held_scl = !held
  ; finished = Controller.finished ctl
  ; released = Isa.pin_out m land 0b11 = 0b11
  }
;;

let check_clean r =
  [%test_result: string list] r.errors ~expect:[];
  [%test_result: bool] r.finished ~expect:true;
  [%test_result: bool] r.released ~expect:true
;;

let tx_reply reply = List.map reply ~f:Firmware.i2c_target_read_word

(* The reference controller moves SDA one clock after SCL falls. The I2C
   spec allows zero: this drops that clock, so SDA moves in the same cycle
   SCL falls (and the SCL low time shrinks by one). *)
let zero_hold steps =
  let rec go = function
    | Ref.Drive { scl = false; _ } :: (Ref.Drive { scl = false; _ } :: _ as rest) -> go rest
    | s :: rest -> s :: go rest
    | [] -> []
  in
  go steps
;;

let hold ~zero steps = if zero then zero_hold steps else steps

let%test_unit "program: 63 words, and the timeout vector is [rest]" =
  let program = Asm.assemble Firmware.i2c_target in
  [%test_result: int] (Array.length program) ~expect:63;
  [%test_result: Isa.Instruction.op]
    program.(Firmware.i2c_target_rest).op
    ~expect:(Wait { polarity = true; pin = 1; timeout = false });
  [%test_result: Isa.Instruction.op]
    program.(Firmware.i2c_target_rest - 1).op
    ~expect:(Jmp { cond = Always; addr = Firmware.i2c_target_rest - 7 })
;;

let gen_address = Int.gen_incl 1 127
let gen_bytes = Quickcheck.Generator.list (Int.gen_incl 0 255)
let gen_bytes_non_empty = Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255)

let%test_unit "model: writes from the reference controller, 6 to 60 clocks per half bit" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4 gen_address gen_bytes (Int.gen_incl 6 60) Bool.quickcheck_generator)
    ~trials:300
    ~sexp_of:[%sexp_of: int * int list * int * bool]
    ~f:(fun (address, bytes, half, zero) ->
      let bytes = List.take bytes 6 in
      let r = run_model ~address ~steps:(hold ~zero (Ref.write ~address ~bytes ~half)) () in
      check_clean r;
      [%test_result: I2c.Event.t list] r.events ~expect:(write_events ~address ~bytes);
      [%test_result: int list] r.rx ~expect:(marker ~address ~read:false :: bytes);
      (* With both FIFOs ready the chip never needs to stretch, and its
         one-clock SCL pulse at a push must land while SCL is already low. *)
      [%test_result: int] r.chip_held_scl ~expect:0)
;;

let%test_unit "model: register read with a repeated START" =
  Quickcheck.test
    (Quickcheck.Generator.tuple5
       gen_address
       (Int.gen_incl 0 255)
       gen_bytes_non_empty
       (Int.gen_incl 6 60)
       Bool.quickcheck_generator)
    ~trials:300
    ~sexp_of:[%sexp_of: int * int * int list * int * bool]
    ~f:(fun (address, register, reply, half, zero) ->
      let reply = List.take reply 3 in
      let r =
        run_model
          ~address
          ~tx:(tx_reply reply)
          ~steps:
            (hold
               ~zero
               (Ref.write_then_read ~address ~bytes:[ register ] ~count:(List.length reply) ~half))
          ()
      in
      check_clean r;
      [%test_result: I2c.Event.t list]
        r.events
        ~expect:(register_read_events ~address ~bytes:[ register ] ~reply);
      [%test_result: int list]
        r.rx
        ~expect:[ marker ~address ~read:false; register; marker ~address ~read:true ];
      [%test_result: int] r.chip_held_scl ~expect:0)
;;

let%test_unit "model: plain reads, and a probe with no data" =
  let address = 0x50 and reply = [ 0xA5; 0xFF; 0x00; 0x81 ] in
  let r =
    run_model
      ~address
      ~tx:(tx_reply reply)
      ~steps:
        (Ref.write ~address ~bytes:[] ~half:12
         @ Ref.read ~address ~count:2 ~half:12
         @ Ref.read ~address ~count:2 ~half:12)
      ()
  in
  check_clean r;
  [%test_result: I2c.Event.t list]
    r.events
    ~expect:
      (write_events ~address ~bytes:[]
       @ read_events ~address ~reply:(List.take reply 2)
       @ read_events ~address ~reply:(List.drop reply 2));
  [%test_result: int list]
    r.rx
    ~expect:(marker ~address ~read:false :: List.init 2 ~f:(fun _ -> marker ~address ~read:true))
;;

let%test_unit "model: the host is late on both FIFOs, so the chip stretches the clock" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3 gen_address (Int.gen_incl 8 40) (Int.gen_incl 0 3000))
    ~trials:40
    ~sexp_of:[%sexp_of: int * int * int]
    ~f:(fun (address, half, late) ->
      (* Seven RX words into a 4-deep FIFO nobody drains yet, then a read the
         host has not supplied yet. *)
      let bytes = [ 0x10; 1; 2; 3; 4; 5 ]
      and reply = [ 0xC3; 0x3C ] in
      let r =
        run_model
          ~address
          ~tx:(tx_reply reply)
          ~tx_at:(8000 + late)
          ~rx_at:(4000 + late)
          ~steps:(Ref.write_then_read ~address ~bytes ~count:2 ~half)
          ()
      in
      check_clean r;
      [%test_result: I2c.Event.t list]
        r.events
        ~expect:(register_read_events ~address ~bytes ~reply);
      [%test_result: int list]
        r.rx
        ~expect:((marker ~address ~read:false :: bytes) @ [ marker ~address ~read:true ]);
      [%test_result: bool] (r.chip_held_scl > 1000) ~expect:true)
;;

(* The chip shares the bus with a model device at another address: it must
   ignore that device's traffic, including its repeated STARTs, and answer
   only its own. *)
let shared_bus ?(source = Firmware.i2c_target) ?(zero = false) () =
  let chip = 0x3C
  and other = 0x21 in
  let reply = [ 0x11; 0x22 ]
  and other_reply = [ 0x99; 0x44 ] in
  let target = I2c.Target.create ~to_send:other_reply ~address:other ~stretch:25 () in
  let half = 15 in
  let r =
    run_model
      ~source
      ~targets:[ target ]
      ~address:chip
      ~tx:(tx_reply reply)
      ~steps:
        (hold
           ~zero
           (Ref.write ~address:chip ~bytes:[ 0x07; 0xE0 ] ~half
            @ Ref.write_then_read ~address:other ~bytes:[ 0x05; 0xFE ] ~count:2 ~half
            @ Ref.write_then_read ~address:chip ~bytes:[ 0x08 ] ~count:2 ~half
            @ Ref.write ~address:other ~bytes:[ 0x00 ] ~half))
      ()
  in
  let expected_events =
    write_events ~address:chip ~bytes:[ 0x07; 0xE0 ]
    @ register_read_events ~address:other ~bytes:[ 0x05; 0xFE ] ~reply:other_reply
    @ register_read_events ~address:chip ~bytes:[ 0x08 ] ~reply
    @ write_events ~address:other ~bytes:[ 0x00 ]
  in
  let expected_rx =
    [ marker ~address:chip ~read:false
    ; 0x07
    ; 0xE0
    ; marker ~address:chip ~read:false
    ; 0x08
    ; marker ~address:chip ~read:true
    ]
  in
  let ok =
    List.is_empty r.errors
    && r.finished
    && r.released
    && [%equal: I2c.Event.t list] r.events expected_events
    && [%equal: int list] r.rx expected_rx
    && [%equal: int list] (I2c.Target.received target) [ 0x05; 0xFE; 0x00 ]
  in
  ok, r, expected_events, expected_rx, target
;;

let%test_unit "model: sharing the bus with another device" =
  List.iter [ false; true ] ~f:(fun zero ->
  let ok, r, expected_events, expected_rx, target = shared_bus ~zero () in
  if not ok
  then (
    check_clean r;
    [%test_result: I2c.Event.t list] r.events ~expect:expected_events;
    [%test_result: int list] r.rx ~expect:expected_rx;
    [%test_result: int list] (I2c.Target.received target) ~expect:[ 0x05; 0xFE; 0x00 ]))
;;

(* The smallest half bit (in core clocks) at which the reference controller
   can write to and read from the chip, with the usual one clock of data
   hold time and with none. The firmware's comment quotes the result. *)
let%expect_test "timing: the fastest controller the chip keeps up with" =
  let works ~zero half =
    let address = 0x2A in
    let r =
      run_model
        ~address
        ~tx:(tx_reply [ 0x96; 0x69 ])
        ~steps:
          (hold ~zero (Ref.write_then_read ~address ~bytes:[ 0xB5; 0x4A ] ~count:2 ~half))
        ()
    in
    List.is_empty r.errors
    && r.finished
    && r.chip_held_scl = 0
    && [%equal: I2c.Event.t list]
         r.events
         (register_read_events ~address ~bytes:[ 0xB5; 0x4A ] ~reply:[ 0x96; 0x69 ])
  in
  List.iter [ false, 2; true, 1 ] ~f:(fun (zero, extra) ->
    let fastest = List.find_exn (List.range 1 40) ~f:(works ~zero) in
    (* and everything slower works too, up to 60 *)
    assert (List.for_all (List.range fastest 61) ~f:(works ~zero));
    printf
      "data hold %d: works from half = %d, SCL low %d clocks\n"
      (if zero then 0 else 1)
      fastest
      (fastest + extra));
  [%expect
    {|
    data hold 1: works from half = 5, SCL low 7 clocks
    data hold 0: works from half = 6, SCL low 7 clocks
    |}]
;;

(* --- Chip to chip -------------------------------------------------------- *)

(* Two model chips on one bus: [Firmware.i2c] (the controller) on one,
   [Firmware.i2c_target] on the other. Each sees the other's drive one clock
   late, as through a wire and the input register. *)
let%test_unit "two chips: one is the controller, the other the device" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       gen_address
       gen_bytes
       gen_bytes_non_empty
       (Quickcheck.Generator.of_list [ 4; 5; 17 ]))
    ~trials:30
    ~sexp_of:[%sexp_of: int * int list * int list * int]
    ~f:(fun (address, data, reply, clkdiv) ->
      let data = List.take data 3
      and reply = List.take reply 3 in
      let n = List.length reply in
      let controller =
        Isa.create
          ~program:(Asm.assemble Firmware.i2c)
          ~pin_modes:modes
          ~threads:[ { Firmware.i2c_config with clkdiv } ]
      in
      let device =
        Isa.create
          ~program:(Asm.assemble Firmware.i2c_target)
          ~pin_modes:modes
          ~threads:[ Firmware.i2c_target_config ]
      in
      let register = 0x42 in
      let words =
        let w ~stop b = Firmware.i2c_write_word ~stop b in
        (w ~stop:false (address lsl 1) :: List.mapi (register :: data) ~f:(fun i b ->
           w ~stop:(i = List.length data) b))
        @ [ w ~stop:false ((address lsl 1) lor 1) ]
        @ List.init n ~f:(fun i -> Firmware.i2c_read_word ~last:(i = n - 1))
      in
      let to_controller = Queue.of_list words in
      let to_device =
        Queue.of_list
          (Firmware.i2c_target_address_word address :: tx_reply reply)
      in
      let reports = Queue.create ()
      and device_rx = Queue.create () in
      let checker = I2c.Checker.create () in
      for _ = 1 to 400 * clkdiv * 10 do
        (match Queue.peek to_controller with
         | Some v -> if Isa.push_tx controller ~thread:0 v then ignore (Queue.dequeue to_controller : int option)
         | None -> ());
        (match Queue.peek to_device with
         | Some v -> if Isa.push_tx device ~thread:0 v then ignore (Queue.dequeue to_device : int option)
         | None -> ());
        let a = Isa.pin_out controller
        and b = Isa.pin_out device in
        Isa.step controller ~inputs:(0xFC lor (b land 3));
        Isa.step device ~inputs:(0xFC lor (a land 3));
        let bus = Isa.pin_out controller land Isa.pin_out device in
        I2c.Checker.step checker ~sda:(bus land 1 = 1) ~scl:(bus land 2 = 2);
        Option.iter (Isa.pop_rx controller ~thread:0) ~f:(Queue.enqueue reports);
        Option.iter (Isa.pop_rx device ~thread:0) ~f:(Queue.enqueue device_rx)
      done;
      [%test_result: string list] (I2c.Checker.errors checker) ~expect:[];
      [%test_result: I2c.Event.t list]
        (I2c.Checker.events checker)
        ~expect:(write_events ~address ~bytes:(register :: data) @ read_events ~address ~reply);
      [%test_result: int list]
        (Queue.to_list device_rx)
        ~expect:
          ((marker ~address ~read:false :: register :: data) @ [ marker ~address ~read:true ]);
      [%test_result: int list]
        (List.drop (Queue.to_list reports) (List.length data + 3)
         |> List.map ~f:(fun w -> Firmware.reverse_byte (w land 0xFF)))
        ~expect:reply)
;;

(* --- Planted firmware bugs --------------------------------------------- *)

let mutate ~pattern ~with_ =
  let m = String.substr_replace_first Firmware.i2c_target ~pattern ~with_ in
  assert (not (String.equal m Firmware.i2c_target));
  m
;;

(* The first-bit loops checking SCL before SDA instead of after: the same
   number of words (padded with NOPs so [rest] stays put), and correct
   whenever the controller holds SDA a while after SCL falls. *)
let scl_first =
  let from = String.substr_index_exn Firmware.i2c_target ~pattern:"high:" in
  let upto = String.substr_index_exn Firmware.i2c_target ~pattern:"rest:" in
  String.prefix Firmware.i2c_target from
  ^ {|high:   wait 1 pin 1 timeout side 1
        mov osr, pins       side 1
        out x, 1            side 1
        jmp !x start        side 1
        jmp high            side 1
low:    wait 1 pin 1 timeout side 1
        mov osr, pins       side 1
        out x, 1            side 1
        jmp !x low          side 1
        jmp start           side 1
        nop                 side 1
        nop                 side 1
|}
  ^ String.drop_prefix Firmware.i2c_target upto
;;

let mutants =
  [ "SCL checked before SDA on a byte's first bit", scl_first
  ; ( "never ACKs"
    , mutate
        ~pattern:"ack:    set pins, 0"
        ~with_:"ack:    set pins, 1" )
  ; ( "repeated START missed"
    , mutate
        ~pattern:"jmp start           side 1 ; SCL still high"
        ~with_:"jmp idle            side 1 ; SCL still high" )
  ; ( "STOP missed"
    , mutate ~pattern:"jmp !x lsame        side 1" ~with_:"jmp lsame           side 1" )
  ; ( "answers every address"
    , mutate
        ~pattern:"jmp x!=y idle       side 1 ; not ours"
        ~with_:"nop                 side 1 ; not ours" )
  ; ( "no clock stretching on a full RX FIFO"
    , mutate ~pattern:"push                side 0" ~with_:"push                side 1" )
  ]
;;

let%expect_test "planted firmware bugs: each is caught" =
  List.iter mutants ~f:(fun (name, source) ->
    assert (Array.length (Asm.assemble source) = 63);
    let shared, _, _, _, _ = shared_bus ~source () in
    let shared0, _, _, _, _ = shared_bus ~source ~zero:true () in
    let stretch =
      let address = 0x3C in
      let r =
        run_model
          ~source
          ~address
          ~rx_at:3000
          ~steps:(Ref.write ~address ~bytes:[ 1; 2; 3; 4; 5 ] ~half:10)
          ()
      in
      List.is_empty r.errors
      && [%equal: int list] r.rx (marker ~address ~read:false :: [ 1; 2; 3; 4; 5 ])
    in
    (* A zero-hold controller at every speed from 6 to 25 clocks per half
       bit, so SCL's falling edge lands at every phase of the firmware's
       polling loop, writing bytes where the first bit differs from the
       second. *)
    let sweep =
      List.for_all (List.range 6 26) ~f:(fun half ->
        let address = 0x3C
        and bytes = [ 0xBF; 0x40; 0xA5; 0x5A ] in
        let r =
          run_model
            ~source
            ~address
            ~steps:(zero_hold (Ref.write ~address ~bytes ~half))
            ()
        in
        List.is_empty r.errors
        && [%equal: int list] r.rx (marker ~address ~read:false :: bytes))
    in
    printf
      "%-46s %s\n"
      name
      (if shared && shared0 && stretch && sweep then "MISSED" else "caught"));
  [%expect
    {|
    SCL checked before SDA on a byte's first bit   caught
    never ACKs                                     caught
    repeated START missed                          caught
    STOP missed                                    caught
    answers every address                          caught
    no clock stretching on a full RX FIFO          caught
    |}]
;;

(* --- The whole chip, over SPI ------------------------------------------- *)

let%test_unit "chip: write and register read from the reference controller" =
  let address = 0x3C
  and register = 0x20
  and data = [ 0xDE; 0xAD ]
  and reply = [ 0x5A; 0xC3 ] in
  let h = Test_top.create ~half:4 in
  Test_top.load_firmware h Firmware.i2c_target;
  Test_top.configure h ~thread:0 Firmware.i2c_target_config;
  Test_top.write h Top.Addr.pin_modes 0b1010;
  Test_top.write h Top.Addr.ctrl 1;
  Test_top.push h (Firmware.i2c_target_address_word address);
  List.iter (tx_reply reply) ~f:(Test_top.push h);
  let ctl =
    Controller.create
      (Ref.write ~address ~bytes:(register :: data) ~half:12
       @ Ref.write_then_read ~address ~bytes:[ register ] ~count:2 ~half:12)
  in
  let checker = I2c.Checker.create () in
  h.Test_top.on_cycle
  <- (fun () ->
       Controller.begin_cycle ctl;
       let oe = Bits.to_int !((Test_top.o h).uio_oe) in
       let sda = ctl.Controller.sda && oe land 1 = 0
       and scl = ctl.Controller.scl && oe land 2 = 0 in
       (Test_top.i h).uio_in
       := Bits.of_int ~width:8 (0xFC lor Bool.to_int sda lor (Bool.to_int scl lsl 1));
       I2c.Checker.step checker ~sda ~scl;
       Controller.end_cycle ctl ~scl);
  let rx = List.map (List.range 0 7) ~f:(fun _ -> Test_top.pop h) in
  while not (Controller.finished ctl) do
    Test_top.wait h 100
  done;
  Test_top.wait h 200;
  [%test_result: string list] (I2c.Checker.errors checker) ~expect:[];
  [%test_result: I2c.Event.t list]
    (I2c.Checker.events checker)
    ~expect:
      (write_events ~address ~bytes:(register :: data)
       @ register_read_events ~address ~bytes:[ register ] ~reply);
  [%test_result: int list]
    rx
    ~expect:
      ((marker ~address ~read:false :: register :: data)
       @ [ marker ~address ~read:false; register; marker ~address ~read:true ]);
  [%test_result: int] (Bits.to_int !((Test_top.o h).uio_oe) land 0b11) ~expect:0
;;
