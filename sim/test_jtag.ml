(* The JTAG controller firmware ([Firmware.jtag]) against the IEEE 1149.1
   device model in [Jtag_model]. Two checks: a fixed session (reset, IDCODE,
   select and write the USER register, read it back, BYPASS) with the same
   expected answers as the cocotb test, and random scans, where the TDO the
   firmware reports and the device's final state must match an ideal
   controller clocking a second copy of the device with the same TMS and TDI
   bits. The cocotb test adds an outside judge (cocotbext-jtag's monitor). *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Jtag = Pe_model.Jtag_model

let modes =
  Array.init Isa.num_pins ~f:(fun i -> if i < 3 then Isa.Pin_mode.Push_pull else Input)
;;

(* Runs [scans] (each a list of (TMS, TDI) bits) through the firmware on the
   model chip, wired to a device model. Returns the TDO bits of each scan,
   and the device. *)
let run ?(source = Firmware.jtag) ?(clkdiv = 1) scans =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ { Firmware.jtag_config with clkdiv } ]
  in
  let device = Jtag.create () in
  let words =
    List.concat_map scans ~f:(fun bits ->
      Firmware.jtag_words ~tms:(List.map bits ~f:fst) ~tdi:(List.map bits ~f:snd))
  in
  let expected_rx =
    List.sum (module Int) scans ~f:(fun bits -> (List.length bits + 7) / 8)
  in
  let pending = Queue.of_list words in
  let rx = Queue.create () in
  let cycle = ref 0 in
  while Queue.length rx < expected_rx && !cycle < 200_000 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    let inputs = 0xF7 lor (Bool.to_int (Jtag.tdo device) lsl 3) in
    Isa.step m ~inputs;
    let p = Isa.pin_out m in
    Jtag.step device ~tck:(p land 1 = 1) ~tms:(p land 2 = 2) ~tdi:(p land 4 = 4);
    incr cycle
  done;
  let rx = ref (Queue.to_list rx) in
  let tdo =
    List.map scans ~f:(fun bits ->
      let n = List.length bits in
      let k = (n + 7) / 8 in
      let mine = List.take !rx k in
      rx := List.drop !rx k;
      if List.length mine < k then [] else Firmware.jtag_tdo ~n mine)
  in
  tdo, device
;;

(* An ideal controller: for each clock, set TMS and TDI with TCK low, read
   TDO, raise TCK, lower it. *)
let ideal scans =
  let device = Jtag.create () in
  let tdo =
    List.map scans ~f:(fun bits ->
      List.map bits ~f:(fun (tms, tdi) ->
        Jtag.step device ~tck:false ~tms ~tdi;
        let sampled = Jtag.tdo device in
        Jtag.step device ~tck:true ~tms ~tdi;
        Jtag.step device ~tck:false ~tms ~tdi;
        sampled))
  in
  tdo, device
;;

(* The host's view, as in the board driver: scans built from TAP paths. *)
let bits_of v n = List.init n ~f:(fun i -> (v lsr i) land 1 = 1)
let int_of bits = List.foldi bits ~init:0 ~f:(fun i acc b -> acc lor (Bool.to_int b lsl i))
let reset_scan = List.map [ true; true; true; true; true; false ] ~f:(fun m -> m, false)

let shift ~prefix v n =
  List.map prefix ~f:(fun m -> m, false)
  @ List.mapi (bits_of v n) ~f:(fun i b -> i = n - 1, b)
  @ [ true, false; false, false ]
;;

let shift_ir v n = shift ~prefix:[ true; true; false; false ] v n
let shift_dr v n = shift ~prefix:[ true; false; false ] v n

(* -1 if the scan came back short (the firmware lost TDO words). *)
let shifted ~prefix_len ~n tdo =
  if List.length tdo < prefix_len + n then -1 else int_of (List.sub tdo ~pos:prefix_len ~len:n)
;;

let session =
  [ reset_scan
  ; shift_dr 0 32
  ; shift_ir 0b1000 4
  ; shift_dr 0xCAFEF00D 32
  ; shift_dr 0x12345678 32
  ; shift_ir 0b1111 4
  ; shift_dr 0b1011 4
  ]
;;

let session_answers tdo =
  match tdo with
  | [ _; idcode; ir; before; after; _; bypass ] ->
    Some
      ( shifted ~prefix_len:3 ~n:32 idcode
      , shifted ~prefix_len:4 ~n:4 ir
      , shifted ~prefix_len:3 ~n:32 before
      , shifted ~prefix_len:3 ~n:32 after
      , shifted ~prefix_len:3 ~n:4 bypass )
  | _ -> None
;;

let expected_answers = Some (0x1BADC0DE, 0b0101, 0, 0xCAFEF00D, 0b0110)

let%test_unit "program: 11 words" =
  [%test_result: int] (Array.length (Asm.assemble Firmware.jtag)) ~expect:11
;;

let%test_unit "a session: IDCODE, a USER register written and read back, BYPASS" =
  List.iter [ 1; 2; 5 ] ~f:(fun clkdiv ->
    let tdo, device = run ~clkdiv session in
    [%test_result: (int * int * int * int * int) option]
      (session_answers tdo)
      ~expect:expected_answers;
    [%test_result: int] device.user ~expect:0x12345678)
;;

let%test_unit "random scans: the same TDO and device state as an ideal controller" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.list_non_empty
             (Quickcheck.Generator.tuple2 Bool.quickcheck_generator Bool.quickcheck_generator)))
       (Int.gen_incl 1 4))
    ~trials:200
    ~sexp_of:[%sexp_of: (bool * bool) list list * int]
    ~f:(fun (scans, clkdiv) ->
      (* Start from a known state and include a register write, so the
         random clocks move through every part of the state diagram. *)
      let scans = (reset_scan :: shift_ir 0b1000 4 :: List.take scans 4) in
      let got, device = run ~clkdiv scans in
      let want, reference = ideal scans in
      [%test_result: bool list list] got ~expect:want;
      [%test_result: Jtag.state] device.state ~expect:reference.state;
      [%test_result: int] device.ir ~expect:reference.ir;
      [%test_result: int] device.user ~expect:reference.user)
;;

let mutate ~pattern ~with_ =
  let m = String.substr_replace_first Firmware.jtag ~pattern ~with_ in
  assert (not (String.equal m Firmware.jtag));
  m
;;

let%expect_test "planted firmware bugs: each is caught" =
  List.iter
    [ ( "TCK left high after the rising edge"
      , mutate ~pattern:"jmp x-- more        side 0" ~with_:"jmp x-- more        side 1" )
    ; ( "TDO never sampled"
      , mutate ~pattern:"in pins, 1          side 1" ~with_:"in null, 1          side 1" )
    ; ( "a scan's last TDO bits never pushed"
      , mutate
          ~pattern:"push                side 0     ; the scan is done"
          ~with_:"nop                 side 0     ; the scan is done" )
    ]
    ~f:(fun (name, source) ->
      let tdo, _ = run ~source session in
      printf
        "%-40s %s\n"
        name
        (if [%equal: (int * int * int * int * int) option]
              (session_answers tdo)
              expected_answers
         then "MISSED"
         else "caught"));
  [%expect
    {|
    TCK left high after the rising edge      caught
    TDO never sampled                        caught
    a scan's last TDO bits never pushed      caught
    |}]
;;
