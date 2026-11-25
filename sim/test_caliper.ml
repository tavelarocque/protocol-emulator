(* The caliper firmware ([Firmware.caliper]) against a reader written here
   from the data port of cheap digital calipers as their users describe it
   (24-bit packets, least significant bit first, read on the rising clock;
   the reading in 1/100 mm or 1/2000 in, a sign bit and an inch bit; the
   clock resting high between packets). The cocotb test runs the same
   firmware on the RTL and the gate netlist with sigrok's caliper decoder
   reading the two wires. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* The reader. A packet begins with the first fall of CLK after it has
   rested high for 50 bit times, and ends once CLK has been high for 4 bit
   times. DATA is taken as CLK rises, and must not change while CLK is high
   or in the tick before it rises. The chip's own timing is exact, so the
   reader holds it to it: CLK low for 4 ticks and high for 4 in every bit,
   and 64 bit times or more of rest between packets. *)
module Reader = struct
  type t =
    { tick : int
    ; mutable clk : bool
    ; mutable data : bool
    ; mutable high_for : int
    ; mutable armed : bool (* the clock has rested: the next fall starts a packet *)
    ; mutable in_packet : bool
    ; mutable bits : int list (* newest first *)
    ; mutable last_fall : int
    ; mutable last_rise : int
    ; mutable data_changed : int
    ; mutable packets : (int * bool * bool) list (* counts, negative, inches; newest first *)
    ; mutable rests : int list (* CLK high before each packet after the first, in bit times *)
    ; mutable errors : string list
    ; mutable now : int
    }

  let create ~tick =
    { tick
    ; clk = true
    ; data = false
    ; high_for = 0
    ; armed = false
    ; in_packet = false
    ; bits = []
    ; last_fall = 0
    ; last_rise = 0
    ; data_changed = 0
    ; packets = []
    ; rests = []
    ; errors = []
    ; now = 0
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors
  let bit t = 8 * t.tick

  let finish t =
    let bits = List.rev t.bits in
    t.bits <- [];
    t.in_packet <- false;
    if List.length bits <> 24
    then error t (sprintf "a packet of %d bits" (List.length bits))
    else (
      let field lo n = List.foldi (List.sub bits ~pos:lo ~len:n) ~init:0 ~f:(fun i a b -> a lor (b lsl i)) in
      if field 21 2 <> 0 then error t "bits 21 and 22 not 0";
      t.packets <- (field 0 20, field 20 1 = 1, field 23 1 = 1) :: t.packets)
  ;;

  let step t ~clk ~data =
    if Bool.( <> ) data t.data
    then (
      if t.in_packet && clk then error t "DATA changed while CLK was high";
      t.data_changed <- t.now);
    if t.clk && not clk
    then (
      if t.armed
      then (
        if t.last_rise > 0 then t.rests <- (t.high_for / bit t) :: t.rests;
        t.armed <- false;
        t.in_packet <- true)
      else if t.in_packet && t.now - t.last_rise <> 4 * t.tick
      then error t (sprintf "CLK high for %d cycles" (t.now - t.last_rise));
      t.last_fall <- t.now);
    if clk && not t.clk && t.in_packet
    then (
      if t.now - t.last_fall <> 4 * t.tick then error t (sprintf "CLK low for %d cycles" (t.now - t.last_fall));
      if t.now - t.data_changed < t.tick then error t "DATA changed just before CLK rose";
      t.bits <- Bool.to_int data :: t.bits;
      t.last_rise <- t.now);
    t.high_for <- (if clk then t.high_for + 1 else 0);
    if t.in_packet && t.high_for >= 4 * bit t then finish t;
    if (not t.in_packet) && t.high_for >= 50 * bit t then t.armed <- true;
    t.clk <- clk;
    t.data <- data;
    t.now <- t.now + 1
  ;;
end

let run ?(source = Firmware.caliper) ~clkdiv readings =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.caliper_config ~clkdiv ]
  in
  let reader = Reader.create ~tick:clkdiv in
  (* The line has rested before the chip starts. *)
  for _ = 1 to 60 * 8 * clkdiv do
    Reader.step reader ~clk:true ~data:false
  done;
  let pending =
    Queue.of_list
      (List.concat_map readings ~f:(fun (counts, negative, inches) ->
         Firmware.caliper_words ~counts ~negative ~inches))
  in
  for _ = 1 to ((List.length readings * 800) + 300) * clkdiv do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0;
    let l = Isa.lines m ~inputs:0 in
    Reader.step reader ~clk:(l land 1 = 1) ~data:(l land 2 = 2)
  done;
  reader
;;

(* What a caliper's display would show. *)
let show (counts, negative, inches) =
  let sign = if negative then "-" else "" in
  if inches
  then sprintf "%s%d.%04d in" sign (counts / 2000) (counts % 2000 * 5)
  else sprintf "%s%d.%02d mm" sign (counts / 100) (counts % 100)
;;

let%expect_test "three readings" =
  let r = run ~clkdiv:2 [ 1234, false, false; 50, true, false; 1001, false, true ] in
  printf !"errors: %{sexp:string list}\n" r.errors;
  List.iter (List.rev r.packets) ~f:(fun p -> print_endline (show p));
  printf !"rests between packets, bit times: %{sexp:int list}\n" (List.rev r.rests);
  [%expect {|
    errors: ()
    12.34 mm
    -0.50 mm
    0.5005 in
    rests between packets, bit times: (66 66)
    |}]
;;

let%test_unit "random readings at several clock dividers" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2
       (Int.gen_incl 1 4)
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.tuple3 (Int.gen_incl 0 0xFFFF) Bool.quickcheck_generator Bool.quickcheck_generator)))
    ~trials:100
    ~sexp_of:[%sexp_of: int * (int * bool * bool) list]
    ~f:(fun (clkdiv, readings) ->
      let readings = List.take readings 4 in
      let r = run ~clkdiv readings in
      [%test_result: string list] r.errors ~expect:[];
      [%test_result: (int * bool * bool) list] (List.rev r.packets) ~expect:readings;
      List.iter r.rests ~f:(fun n -> assert (n >= 64)))
;;

let%expect_test "planted bugs" =
  let readings = [ 0xFFFF, true, true; 0, false, false; 0x8001, true, false; 0x7FFE, false, true ] in
  let caught source =
    List.exists [ 1; 3 ] ~f:(fun clkdiv ->
      let r = run ~source ~clkdiv readings in
      not
        (List.is_empty r.errors
         && [%equal: (int * bool * bool) list] (List.rev r.packets) readings
         && List.for_all r.rests ~f:(fun n -> n >= 64)))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.caliper ~pattern ~with_ in
    assert (not (String.equal s Firmware.caliper));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.caliper then "WRONG" else "right");
  List.iter
    [ "the sign one bit late", fw ~pattern:"in null, 2 " ~with_:"in null, 1 "
    ; "the top byte one bit early", fw ~pattern:"in null, 8 " ~with_:"in null, 9 "
    ; "the sign never sent", fw ~pattern:"in x, 1            side 1       ; bit 20" ~with_:"in null, 1         side 1       ; bit 20"
    ; "seven bits of the top byte", fw ~pattern:"set y, 7 " ~with_:"set y, 6 "
    ; "the top byte not shifted down", fw ~pattern:"in null, 8 " ~with_:"in null, 7 "
    ; ( "DATA changed as CLK rises"
      , fw ~pattern:"out pins, 1        side 0 [3]   ; bits 0 to 15: DATA as CLK falls,\n        jmp !osre bit      side 1 [3]"
          ~with_:"out pins, 1        side 1 [3]   ; bits 0 to 15: DATA as CLK falls,\n        jmp !osre bit      side 0 [3]" )
    ; "the top byte's bits a tick short", fw ~pattern:"in null, 1         side 1 [2]" ~with_:"in null, 1         side 1 [1]"
    ; "CLK low while resting", fw ~pattern:"rest:   nop                side 1 [7]" ~with_:"rest:   nop                side 0 [7]"
    ; "a rest of 32 bit times", fw ~pattern:"rest:   nop                side 1 [7]   ; 64 bit times\n" ~with_:"rest:\n"
    ]
    ~f:(fun (name, source) -> printf "%-40s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the sign one bit late                    caught
    the top byte one bit early               caught
    the sign never sent                      caught
    seven bits of the top byte               caught
    the top byte not shifted down            caught
    DATA changed as CLK rises                caught
    the top byte's bits a tick short         caught
    CLK low while resting                    caught
    a rest of 32 bit times                   caught
    |}]
;;
