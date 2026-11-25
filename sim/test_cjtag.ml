(* The compact JTAG probe ([Firmware.cjtag]) against a TAP.7 written here
   from IEEE 1149.7's two-wire rules, with the IEEE 1149.1 device of
   [Jtag_model] behind it. The TAP.7 counts TMSC edges while TCKC is high
   and acts on the escape when TCKC falls (eight or more: reset; six or
   seven: selection; four or five: deselection), takes the twelve bits
   after a selection escape as the online activation code, extension code
   and check packet, and once online in OScan1 takes nTDI and TMS on two
   rising edges of TCKC and drives TDO from the next falling edge to the
   one after. It reports any TMSC change in the tick TCKC rises (a race
   with the target's sampling), and one to three edges while TCKC is high,
   which name no escape this target has. The cocotb test runs the same
   firmware on the
   RTL and the gate netlist with sigrok's cJTAG decoder reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Jtag = Pe_model.Jtag_model

module Tap7 = struct
  type mode =
    | Offline
    | Activating of int list (* the bits after a selection escape, newest first *)
    | Online
  [@@deriving sexp_of]

  type t =
    { tap : Jtag.t
    ; mutable mode : mode
    ; mutable tckc : bool
    ; mutable tmsc : bool
    ; mutable edges : int (* TMSC edges since TCKC rose *)
    ; mutable slot : int (* OScan1: the bit the next rising edge takes: 0 nTDI, 1 TMS, 2 TDO *)
    ; mutable ntdi : bool
    ; mutable tms : bool
    ; mutable drive : bool option (* what the target puts on TMSC *)
    ; mutable clocked : bool (* the JTAG clock of this packet has risen *)
    ; mutable events : string list (* newest first *)
    ; mutable errors : string list
    }

  let create () =
    { tap = Jtag.create ()
    ; mode = Offline
    ; tckc = false
    ; tmsc = true
    ; edges = 0
    ; slot = 0
    ; ntdi = false
    ; tms = false
    ; drive = None
    ; clocked = false
    ; events = []
    ; errors = []
    }
  ;;

  let event t s = t.events <- s :: t.events
  let error t s = t.errors <- s :: t.errors

  (* The TAP behind the TAP.7 to Test-Logic-Reset, as a reset escape puts
     it: five clocks with TMS high. *)
  let reset_tap t =
    for _ = 1 to 5 do
      Jtag.step t.tap ~tck:true ~tms:true ~tdi:false;
      Jtag.step t.tap ~tck:false ~tms:true ~tdi:false
    done
  ;;

  let rising t =
    match t.mode with
    | Offline -> ()
    | Activating bits ->
      let bits = Bool.to_int t.tmsc :: bits in
      if List.length bits < 12
      then t.mode <- Activating bits
      else (
        let code = List.rev bits in
        (* OAC 1100 (OScan1), EC 1000, CP 0000, first bit first. *)
        if [%equal: int list] code [ 0; 0; 1; 1; 0; 0; 0; 1; 0; 0; 0; 0 ]
        then (
          t.mode <- Online;
          t.slot <- 0;
          event t "online in OScan1")
        else (
          t.mode <- Offline;
          event t (sprintf !"activation code %{sexp:int list} refused" code)))
    | Online ->
      (match t.slot with
       | 0 ->
         t.ntdi <- t.tmsc;
         t.slot <- 1
       | 1 ->
         t.tms <- t.tmsc;
         t.slot <- 2
       | _ ->
         (* The DTS has sampled TDO: the JTAG clock rises. *)
         Jtag.step t.tap ~tck:true ~tms:t.tms ~tdi:(not t.ntdi);
         t.clocked <- true;
         t.slot <- 0)
  ;;

  let falling t =
    (match t.edges with
     | 0 -> ()
     | 1 | 2 | 3 -> error t (sprintf "%d TMSC edges while TCKC was high" t.edges)
     | 4 | 5 ->
       t.mode <- Offline;
       event t "deselection escape"
     | 6 | 7 ->
       t.mode <- Activating [];
       event t "selection escape"
     | _ ->
       t.mode <- Offline;
       reset_tap t;
       event t "reset escape");
    if t.edges > 0
    then (
      t.slot <- 0;
      t.drive <- None);
    t.edges <- 0;
    (match t.mode with
     | Online when t.slot = 2 -> t.drive <- Some (Jtag.tdo t.tap)
     | _ -> t.drive <- None);
    if t.clocked
    then (
      Jtag.step t.tap ~tck:false ~tms:t.tms ~tdi:(not t.ntdi);
      t.clocked <- false)
  ;;

  (* One core clock: the levels on TCKC and TMSC at its end. *)
  let step t ~tckc ~tmsc =
    (match t.tckc, tckc with
     | false, true ->
       if Bool.( <> ) tmsc t.tmsc then error t "TMSC changed as TCKC rose";
       t.tmsc <- tmsc;
       rising t
     | true, false -> falling t
     | true, true -> if Bool.( <> ) tmsc t.tmsc then t.edges <- t.edges + 1
     | false, false -> ());
    t.tckc <- tckc;
    t.tmsc <- tmsc
  ;;

  (* What the target puts on TMSC: 1 is the pull-up. *)
  let line t = Option.value t.drive ~default:true
end

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    match i with
    | 0 -> Isa.Pin_mode.Push_pull
    | 1 -> Open_drain
    | _ -> Input)
;;

type command =
  | Activate
  | Scan of (bool * bool) list (* (TMS, TDI) per clock *)

(* Runs [commands] through the firmware on the model chip, wired to a
   TAP.7. Returns the TDO bits of each scan, and the TAP.7. *)
let run ?(source = Firmware.cjtag) ?(clkdiv = 1) commands =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ { Firmware.cjtag_config with clkdiv } ]
  in
  let tap7 = Tap7.create () in
  let words =
    List.concat_map commands ~f:(function
      | Activate -> [ Firmware.cjtag_activate ]
      | Scan bits -> Firmware.cjtag_words ~tms:(List.map bits ~f:fst) ~tdi:(List.map bits ~f:snd))
  in
  let scans = List.filter_map commands ~f:(function Scan b -> Some b | Activate -> None) in
  let expected_rx = List.sum (module Int) scans ~f:(fun bits -> (List.length bits + 7) / 8) in
  let pending = Queue.of_list words in
  let rx = Queue.create () in
  let cycle = ref 0 in
  while (Queue.length rx < expected_rx || not (Queue.is_empty pending)) && !cycle < 400_000 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    let inputs = 0xFD lor (Bool.to_int (Tap7.line tap7) lsl 1) in
    Isa.step m ~inputs;
    let wire = Isa.lines m ~inputs in
    Tap7.step tap7 ~tckc:(wire land 1 = 1) ~tmsc:(wire land 2 = 2);
    incr cycle
  done;
  let rx = ref (Queue.to_list rx) in
  let tdo =
    List.map scans ~f:(fun bits ->
      let n = List.length bits in
      let k = (n + 7) / 8 in
      let mine = List.take !rx k in
      rx := List.drop !rx k;
      if List.length mine < k then [] else Pe_model.Firmware.jtag_tdo ~n mine)
  in
  tdo, tap7
;;

(* An ideal 1149.1 controller on the same device, with no TAP.7 between. *)
let ideal scans =
  let device = Jtag.create () in
  let tdo =
    List.map scans ~f:(fun bits ->
      List.map bits ~f:(fun (tms, tdi) ->
        let sampled = Jtag.tdo device in
        Jtag.step device ~tck:true ~tms ~tdi;
        Jtag.step device ~tck:false ~tms ~tdi;
        sampled))
  in
  tdo, device
;;

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

let shifted ~prefix_len ~n tdo =
  if List.length tdo < prefix_len + n then -1 else int_of (List.sub tdo ~pos:prefix_len ~len:n)
;;

(* Online, then as test_jtag.ml: IDCODE, the USER register written and read
   back, and BYPASS. *)
let session =
  [ Activate
  ; Scan reset_scan
  ; Scan (shift_dr 0 32)
  ; Scan (shift_ir 0b1000 4)
  ; Scan (shift_dr 0xCAFEF00D 32)
  ; Scan (shift_dr 0x12345678 32)
  ; Scan (shift_ir 0b1111 4)
  ; Scan (shift_dr 0b1011 4)
  ]
;;

let session_answers (tdo, (tap7 : Tap7.t)) =
  match tdo with
  | [ _; idcode; ir; before; after; _; bypass ] ->
    Some
      ( List.rev tap7.events
      , tap7.errors
      , shifted ~prefix_len:3 ~n:32 idcode
      , shifted ~prefix_len:4 ~n:4 ir
      , shifted ~prefix_len:3 ~n:32 before
      , shifted ~prefix_len:3 ~n:32 after
      , shifted ~prefix_len:3 ~n:4 bypass
      , tap7.tap.user )
  | _ -> None
;;

let expected_answers =
  Some
    ( [ "reset escape"; "selection escape"; "online in OScan1" ]
    , []
    , 0x1BADC0DE
    , 0b0101
    , 0
    , 0xCAFEF00D
    , 0b0110
    , 0x12345678 )
;;

type answers = (string list * string list * int * int * int * int * int * int) option
[@@deriving sexp_of, equal, compare]

let%test_unit "program: 55 words" =
  [%test_result: int] (Array.length (Asm.assemble Firmware.cjtag)) ~expect:55
;;

let%expect_test "a session: online, IDCODE, a USER register written and read back, BYPASS" =
  List.iter [ 1; 2; 5 ] ~f:(fun clkdiv ->
    [%test_result: answers] (session_answers (run ~clkdiv session)) ~expect:expected_answers);
  let tdo, tap7 = run session in
  printf
    !"events %{sexp:string list}\nIDCODE %08x\n"
    (List.rev tap7.events)
    (shifted ~prefix_len:3 ~n:32 (List.nth_exn tdo 1));
  [%expect
    {|
    events ("reset escape" "selection escape" "online in OScan1")
    IDCODE 1badc0de
    |}]
;;

let%test_unit "random scans: the same TDO and device state as an ideal controller" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.list_non_empty
             (Quickcheck.Generator.tuple2 Bool.quickcheck_generator Bool.quickcheck_generator)))
       (Int.gen_incl 1 4))
    ~trials:100
    ~sexp_of:[%sexp_of: (bool * bool) list list * int]
    ~f:(fun (scans, clkdiv) ->
      let scans = reset_scan :: shift_ir 0b1000 4 :: List.take scans 4 in
      let got, tap7 = run ~clkdiv (Activate :: List.map scans ~f:(fun s -> Scan s)) in
      let want, reference = ideal scans in
      [%test_result: string list] tap7.errors ~expect:[];
      [%test_result: bool list list] got ~expect:want;
      [%test_result: Jtag.state] tap7.tap.state ~expect:reference.state;
      [%test_result: int] tap7.tap.ir ~expect:reference.ir;
      [%test_result: int] tap7.tap.user ~expect:reference.user)
;;

(* USER selected, then the activation again: its reset escape puts the TAP
   in Test-Logic-Reset, which selects IDCODE, so one clock with TMS low and
   a DR scan read the IDCODE, not USER. *)
let%expect_test "activated twice: the second activation resets the TAP and goes online again" =
  let tdo, tap7 =
    run
      [ Activate
      ; Scan reset_scan
      ; Scan (shift_ir 0b1000 4)
      ; Activate
      ; Scan [ false, false ]
      ; Scan (shift_dr 0 32)
      ]
  in
  printf
    !"events %{sexp:string list}\nerrors %{sexp:string list}\nIDCODE %08x\n"
    (List.rev tap7.events)
    tap7.errors
    (shifted ~prefix_len:3 ~n:32 (List.nth_exn tdo 3));
  [%expect
    {|
    events ("reset escape" "selection escape" "online in OScan1" "reset escape"
     "selection escape" "online in OScan1")
    errors ()
    IDCODE 1badc0de
    |}]
;;

let%expect_test "planted bugs" =
  let mutate ~pattern ~with_ =
    let m = String.substr_replace_first Firmware.cjtag ~pattern ~with_ in
    assert (not (String.equal m Firmware.cjtag));
    m
  in
  let caught source =
    not ([%equal: answers] (session_answers (run ~source session)) expected_answers)
  in
  printf "the program as it is: %s\n" (if caught Firmware.cjtag then "WRONG" else "right");
  List.iter
    [ "six edges in the reset escape", mutate ~pattern:"set y, 3            side 1" ~with_:"set y, 2            side 1"
    ; "four edges in the selection escape", mutate ~pattern:"set y, 2            side 1" ~with_:"set y, 1            side 1"
    ; ( "the OAC's third bit 0"
      , mutate
          ~pattern:"set pins, 1         side 0\n        set y, 1"
          ~with_:"set pins, 0         side 0\n        set y, 1" )
    ; "no check packet", mutate ~pattern:"set y, 3            side 0" ~with_:"jmp next            side 0"
    ; "TDI sent as it is, not inverted", mutate ~pattern:"jmp !y tdi0" ~with_:"jmp y-- tdi0"
    ; ( "TMS set as TCKC rises"
      , mutate
          ~pattern:"out pins, 1         side 0     ; TMS\n        nop                 side 1"
          ~with_:"nop                 side 0     ; TMS\n        out pins, 1         side 1" )
    ; ( "TMSC not released for TDO"
      , mutate ~pattern:"set pins, 1         side 0     ; TCKC falls, TMSC" ~with_:"nop                 side 0     ; TCKC falls, TMSC" )
    ; "TDO sampled a tick early", mutate ~pattern:"nop                 side 0 [1]" ~with_:"nop                 side 0    "
    ; "no TDO slot", mutate ~pattern:"in pins, 1          side 1" ~with_:"in pins, 1          side 0"
    ]
    ~f:(fun (name, source) -> printf "%-36s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect
    {|
    the program as it is: right
    six edges in the reset escape        caught
    four edges in the selection escape   caught
    the OAC's third bit 0                caught
    no check packet                      caught
    TDI sent as it is, not inverted      caught
    TMS set as TCKC rises                caught
    TMSC not released for TDO            caught
    TDO sampled a tick early             caught
    no TDO slot                          caught
    |}]
;;
