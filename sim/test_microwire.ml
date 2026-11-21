(* The Microwire controller ([Firmware.microwire]) against a 93C46 EEPROM
   written here from the part's datasheet: commands, the write-enable
   latch, a read's dummy bit, and its timing rules. The cocotb test runs the
   same firmware on the RTL and the gate netlist with sigrok's Microwire
   and 93xx decoders reading the wires. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module E = Firmware.Eeprom93c46

(* A 93C46, 64 words of 16 bits. It takes DI as SK rises while CS is high,
   changes DO at that edge, and stores a written word when CS falls. *)
module Device = struct
  type t =
    { mem : int array
    ; mutable enabled : bool
    ; mutable taken : int list (* DI bits of this command, newest first *)
    ; mutable to_send : int list
    ; mutable d_out : bool (* DO; high when the device is not driving *)
    ; mutable sk : bool
    ; mutable cs : bool
    ; mutable di : bool
    ; mutable since_di : int (* cycles since DI last changed *)
    ; mutable since_cs : int (* cycles since CS last changed *)
    ; mutable sk_high : int
    ; mutable commands : string list
    ; mutable errors : string list
    }

  let create () =
    { mem = Array.create ~len:64 0xFFFF
    ; enabled = false
    ; taken = []
    ; to_send = []
    ; d_out = true
    ; sk = false
    ; cs = false
    ; di = false
    ; since_di = 1000
    ; since_cs = 1000
    ; sk_high = 0
    ; commands = []
    ; errors = []
    }
  ;;

  let value bits = List.fold bits ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b)
  let note t s = t.commands <- s :: t.commands
  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  (* The end of a transfer: a complete write is stored now. *)
  let deselect t =
    (match List.rev t.taken with
     | 1 :: 0 :: 1 :: rest when List.length rest = 22 ->
       let address = value (List.take rest 6)
       and word = value (List.drop rest 6) in
       if t.enabled
       then (
         t.mem.(address) <- word;
         note t (sprintf "write %02x %04x" address word))
       else note t (sprintf "write %02x refused" address)
     | 1 :: 0 :: 1 :: _ -> error t "a write cut short"
     | _ -> ());
    t.taken <- [];
    t.to_send <- [];
    t.d_out <- true
  ;;

  let clock t ~di =
    match t.to_send with
    | b :: rest ->
      t.d_out <- b = 1;
      t.to_send <- rest
    | [] ->
      if not (List.is_empty t.taken && not di) (* zeros before the start bit *)
      then t.taken <- Bool.to_int di :: t.taken;
      (match List.rev t.taken with
       | [ 1; 1; 0; a5; a4; a3; a2; a1; a0 ] ->
         let address = value [ a5; a4; a3; a2; a1; a0 ] in
         note t (sprintf "read %02x" address);
         t.d_out <- false;
         (* the dummy bit, then the word; then the words after it *)
         t.to_send
         <- List.concat_map (List.range address 64) ~f:(fun a -> E.field ~width:16 t.mem.(a))
       | [ 1; 0; 0; 1; 1; _; _; _; _ ] ->
         t.enabled <- true;
         note t "write enable"
       | [ 1; 0; 0; 0; 0; _; _; _; _ ] ->
         t.enabled <- false;
         note t "write disable"
       | _ -> ())
  ;;

  (* One cycle. The datasheet's limits, in cycles of a 10 MHz clock at 5 V:
     DI set up 100 ns before SK rises and held 100 ns after; CS high 50 ns
     before SK rises; SK high and low 250 ns each. *)
  let step t ~cs ~sk ~di =
    if Bool.( <> ) di t.di
    then (
      if t.cs && t.sk && t.sk_high < 1 then error t "DI changed right after SK rose";
      t.since_di <- 0)
    else t.since_di <- t.since_di + 1;
    if Bool.( <> ) cs t.cs then t.since_cs <- 0 else t.since_cs <- t.since_cs + 1;
    if t.cs && not cs then deselect t;
    if cs && sk && not t.sk
    then (
      if t.since_di < 1 then error t "DI changed as SK rose";
      if t.since_cs < 1 then error t "SK rose as CS did";
      clock t ~di);
    if (not cs) && sk then error t "SK high with CS low";
    t.sk_high <- (if sk then t.sk_high + 1 else 0);
    t.cs <- cs;
    t.sk <- sk;
    t.di <- di
  ;;
end

let modes =
  Array.init Isa.num_pins ~f:(fun i -> if i < 3 then Isa.Pin_mode.Push_pull else Input)
;;

type outcome =
  { device : Device.t
  ; read : int list (* RX words *)
  ; sk_periods : int list
  }

(* Run [transfers] (each a list of bits) one after another. *)
let run ?(source = Firmware.microwire) ?(device = Device.create ()) ~clkdiv transfers =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ Firmware.microwire_config ~clkdiv ]
  in
  let pending = Queue.of_list (List.concat_map transfers ~f:Firmware.microwire_words) in
  let bits = List.sum (module Int) transfers ~f:List.length in
  let read = Queue.create () in
  let rises = Queue.create () in
  let inputs = ref 0xFF in
  for cycle = 1 to 400 + ((bits + (8 * List.length transfers)) * 4 * max 1 clkdiv) do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:!inputs;
    let l = Isa.lines m ~inputs:!inputs in
    let cs = l land 1 = 1
    and sk = (l lsr 1) land 1 = 1
    and di = (l lsr 2) land 1 = 1 in
    if sk && not device.sk then Queue.enqueue rises cycle;
    Device.step device ~cs ~sk ~di;
    inputs := 0xF7 lor (Bool.to_int device.d_out lsl 3);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue read)
  done;
  let rises = Queue.to_list rises in
  { device
  ; read = Queue.to_list read
  ; sk_periods =
      List.zip_exn (List.drop_last_exn rises) (List.tl_exn rises)
      |> List.map ~f:(fun (a, b) -> b - a)
      |> List.dedup_and_sort ~compare
  }
;;

(* The RX words of each transfer, in order: a transfer of n bits makes
   n / 16 + 1 words. *)
let split transfers words =
  let rest = ref words in
  List.map transfers ~f:(fun t ->
    let n = List.length t in
    let mine, others = List.split_n !rest ((n / 16) + 1) in
    rest := others;
    Firmware.microwire_read ~n mine)
;;

let%expect_test "a write and a read: what goes over the wires and back to the host" =
  let transfers = [ E.write_enable; E.write ~address:5 ~value:0xBEEF; E.read ~address:5 ] in
  let r = run ~clkdiv:3 transfers in
  printf
    !"device: %{sexp:string list}, errors %{sexp:string list}\n"
    (List.rev r.device.commands)
    r.device.errors;
  printf !"RX words: %s\n" (String.concat ~sep:" " (List.map r.read ~f:(sprintf "%04x")));
  printf !"read back: %04x\n" (E.read_value (List.last_exn (split transfers r.read)));
  printf
    !"SK periods %{sexp:int list} cycles at CLKDIV 3: %.0f kHz at 10 MHz\n"
    r.sk_periods
    (10_000. /. Float.of_int (List.hd_exn r.sk_periods));
  [%expect {|
    device: ("write enable" "write 05 beef" "read 05"), errors ()
    RX words: 01ff ffff 01ff ff5f 00ef
    read back: beef
    SK periods (15 33) cycles at CLKDIV 3: 667 kHz at 10 MHz
    |}]
;;

let%test_unit "random writes and reads at every speed; a write while disabled is refused" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 3 12)
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.tuple2 (Int.gen_incl 0 63) (Int.gen_incl 0 0xFFFF)))
       Bool.quickcheck_generator)
    ~trials:120
    ~sexp_of:[%sexp_of: int * (int * int) list * bool]
    ~f:(fun (clkdiv, writes, enable) ->
      let writes = List.take writes 6 in
      let addresses = List.dedup_and_sort ~compare:Int.compare (List.map writes ~f:fst) in
      let transfers =
        (if enable then [ E.write_enable ] else [ E.write_disable ])
        @ List.map writes ~f:(fun (address, value) -> E.write ~address ~value)
        @ List.map addresses ~f:(fun address -> E.read ~address)
      in
      let r = run ~clkdiv transfers in
      [%test_result: string list] r.device.errors ~expect:[];
      let expected = Array.create ~len:64 0xFFFF in
      if enable then List.iter writes ~f:(fun (address, value) -> expected.(address) <- value);
      [%test_result: int array] r.device.mem ~expect:expected;
      let got = split transfers r.read in
      let reads = List.drop got (1 + List.length writes) in
      [%test_result: int list]
        (List.map reads ~f:E.read_value)
        ~expect:(List.map addresses ~f:(fun a -> expected.(a)));
      (* The dummy bit that leads a read is 0: the device was there. *)
      [%test_result: int list]
        (List.map reads ~f:(fun bits -> List.nth_exn bits 8))
        ~expect:(List.map addresses ~f:(fun _ -> 0)))
;;

let%expect_test "planted bugs" =
  let transfers =
    [ E.write_enable
    ; E.write ~address:9 ~value:0x8001
    ; E.write ~address:10 ~value:0x5AA5
    ; E.read ~address:9
    ; E.read ~address:10
    ]
  in
  let caught source =
    List.exists [ 3; 4; 7 ] ~f:(fun clkdiv ->
      let r = run ~source ~clkdiv transfers in
      let got = split transfers r.read in
      not
        (List.is_empty r.device.errors
         && r.device.mem.(9) = 0x8001
         && r.device.mem.(10) = 0x5AA5
         && [%equal: int list] (List.map (List.drop got 3) ~f:E.read_value) [ 0x8001; 0x5AA5 ]))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.microwire ~pattern ~with_ in
    assert (not (String.equal s Firmware.microwire));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.microwire then "WRONG" else "right");
  List.iter
    [ ( "DO read as SK rises, before the device answers"
      , fw
          ~pattern:
            "nop                 side 1     ; SK rises: the device takes the bit\n\
            \        in pins, 1          side 1 "
          ~with_:"in pins, 1          side 1\n        nop                 side 1 " )
    ; ( "CS left high between transfers"
      , fw ~pattern:"idle:   set pins, 0         side 0" ~with_:"idle:   nop                 side 0" )
    ; "the last word never sent to the host", fw ~pattern:"push                side 0" ~with_:"nop                 side 0"
    ; ( "DI changed as SK rises"
      , fw ~pattern:"out pins, 1         side 0 [1]" ~with_:"out pins, 1         side 1 [1]" )
    ]
    ~f:(fun (name, source) -> printf "%-50s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    DO read as SK rises, before the device answers     caught
    CS left high between transfers                     caught
    the last word never sent to the host               caught
    DI changed as SK rises                             caught
    |}]
;;
