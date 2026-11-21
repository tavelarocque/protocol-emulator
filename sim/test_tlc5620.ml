(* The TLC5620 writer ([Firmware.tlc5620]) against the DAC's digital side
   written here from its datasheet: the shift register, the latches, the
   two ways its outputs update, and its timing limits. The cocotb test runs
   the same firmware on the RTL and the gate netlist with sigrok's TLC5620
   decoder reading the four wires. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* A TLC5620. DATA is shifted in as CLK falls, while LOAD is high. LOAD
   falling puts the last 11 bits into one DAC's latch; the outputs follow
   the latches when LDAC falls, or at once if LDAC is low. Its limits, in
   cycles of 100 ns: DATA set up 50 ns before CLK falls and held 50 ns
   after; LOAD and LDAC low for 250 ns; LOAD falling 50 ns or more after
   CLK. *)
module Dac = struct
  type t =
    { mutable shift : int list (* newest first *)
    ; latch : (bool * int) option array (* (doubled, value) *)
    ; output : (bool * int) option array
    ; mutable updates : (bool * int) option list list (* the outputs at each update, newest first *)
    ; mutable clk : bool
    ; mutable data : bool
    ; mutable load : bool
    ; mutable ldac : bool
    ; mutable since_data : int
    ; mutable since_clk_fall : int
    ; mutable load_low : int
    ; mutable ldac_low : int
    ; mutable errors : string list
    }

  let create () =
    { shift = []
    ; latch = Array.create ~len:4 None
    ; output = Array.create ~len:4 None
    ; updates = []
    ; clk = false
    ; data = true
    ; load = true
    ; ldac = true
    ; since_data = 1000
    ; since_clk_fall = 1000
    ; load_low = 0
    ; ldac_low = 0
    ; errors = []
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  let update t =
    Array.blit ~src:t.latch ~src_pos:0 ~dst:t.output ~dst_pos:0 ~len:4;
    t.updates <- Array.to_list t.output :: t.updates
  ;;

  let step t ~clk ~data ~load ~ldac =
    (* A change in the cycle after CLK falls is 100 ns after it: held. *)
    if Bool.( <> ) data t.data then t.since_data <- 0 else t.since_data <- t.since_data + 1;
    if t.clk && not clk
    then (
      if t.since_data < 1 then error t "DATA changed as CLK fell";
      if t.load then t.shift <- Bool.to_int t.data :: t.shift else error t "CLK with LOAD low";
      t.since_clk_fall <- 0)
    else t.since_clk_fall <- t.since_clk_fall + 1;
    if t.load && not load
    then (
      if t.since_clk_fall < 1 then error t "LOAD fell as CLK did";
      (match List.rev (List.take t.shift 11) with
       | [ a1; a0; rng; d7; d6; d5; d4; d3; d2; d1; d0 ] ->
         let value = List.fold [ d7; d6; d5; d4; d3; d2; d1; d0 ] ~init:0 ~f:(fun a b -> (a lsl 1) lor b) in
         t.latch.((a1 * 2) + a0) <- Some (rng = 1, value)
       | _ -> error t "LOAD with fewer than 11 bits clocked in");
      if List.length t.shift <> 11 then error t (sprintf "%d bits clocked in before LOAD" (List.length t.shift));
      t.shift <- [];
      if not ldac then update t);
    if (not t.load) && load && t.load_low < 3 then error t "LOAD low for less than 250 ns";
    if t.ldac && not ldac then update t;
    if (not t.ldac) && ldac && t.ldac_low < 3 then error t "LDAC low for less than 250 ns";
    t.load_low <- (if load then 0 else t.load_low + 1);
    t.ldac_low <- (if ldac then 0 else t.ldac_low + 1);
    t.clk <- clk;
    t.data <- data;
    t.load <- load;
    t.ldac <- ldac
  ;;
end

(* [writes]: (dac, doubled, value, update). *)
let run ?(source = Firmware.tlc5620) ?(clkdiv = 1) writes =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 4 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.tlc5620_config ~clkdiv ]
  in
  let dac = Dac.create () in
  let pending =
    Queue.of_list
      (List.map writes ~f:(fun (dac, double, value, update) -> Firmware.tlc5620_word ~dac ~double ~value ~update))
  in
  for _ = 1 to ((List.length writes * 40) + 20) * max 1 clkdiv do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    let l = Isa.lines m ~inputs:0xFF in
    let pin i = (l lsr i) land 1 = 1 in
    Dac.step dac ~clk:(pin 0) ~data:(pin 1) ~load:(pin 2) ~ldac:(pin 3)
  done;
  dac
;;

let show (o : (bool * int) option list) =
  String.concat
    ~sep:" "
    (List.map o ~f:(function
       | None -> "-"
       | Some (double, v) -> sprintf "%d%s" v (if double then "x2" else "")))
;;

let%expect_test "four DACs written and brought out together, then one changed by itself" =
  let dac = run [ 0, false, 64, false; 1, true, 128, false; 2, false, 255, false; 3, true, 1, true; 2, false, 0, true ] in
  printf !"errors: %{sexp:string list}\n" dac.errors;
  List.iter (List.rev dac.updates) ~f:(fun o -> printf "outputs: %s\n" (show o));
  [%expect {|
    errors: ()
    outputs: 64 128x2 255 1x2
    outputs: 64 128x2 0 1x2
    |}]
;;

let%test_unit "random writes at several speeds" =
  Quickcheck.test
    (Quickcheck.Generator.tuple2
       (Int.gen_incl 1 4)
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.tuple4
             (Int.gen_incl 0 3)
             Bool.quickcheck_generator
             (Int.gen_incl 0 255)
             Bool.quickcheck_generator)))
    ~trials:150
    ~sexp_of:[%sexp_of: int * (int * bool * int * bool) list]
    ~f:(fun (clkdiv, writes) ->
      let writes = List.take writes 8 in
      let dac = run ~clkdiv writes in
      [%test_result: string list] dac.errors ~expect:[];
      (* What the latches and outputs should have gone through. *)
      let latch = Array.create ~len:4 None in
      let updates =
        List.filter_map writes ~f:(fun (d, double, value, update) ->
          latch.(d) <- Some (double, value);
          Option.some_if update (Array.to_list latch))
      in
      [%test_result: (bool * int) option list] (Array.to_list dac.latch) ~expect:(Array.to_list latch);
      [%test_result: (bool * int) option list list] (List.rev dac.updates) ~expect:updates)
;;

let%expect_test "planted bugs" =
  let writes = [ 0, false, 0x81, false; 3, true, 0x7E, true; 1, false, 0xFF, false; 2, true, 0x00, true ] in
  let caught source =
    List.exists [ 1; 2 ] ~f:(fun clkdiv ->
      let dac = run ~source ~clkdiv writes in
      not
        (List.is_empty dac.errors
         && [%equal: (bool * int) option list list]
              (List.rev dac.updates)
              [ [ Some (false, 0x81); None; None; Some (true, 0x7E) ]
              ; [ Some (false, 0x81); Some (false, 0xFF); Some (true, 0x00); Some (true, 0x7E) ]
              ]))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.tlc5620 ~pattern ~with_ in
    assert (not (String.equal s Firmware.tlc5620));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.tlc5620 then "WRONG" else "right");
  List.iter
    [ "ten bits clocked in", fw ~pattern:"set x, 10 " ~with_:"set x, 9  "
    ; "LOAD low for one tick", fw ~pattern:"set pins, 2       side 0 [2]" ~with_:"set pins, 2       side 0    "
    ; "LDAC low for one tick", fw ~pattern:"set pins, 1       side 0 [2]" ~with_:"set pins, 1       side 0    "
    ; "LDAC pulsed after every write", fw ~pattern:"jmp !x next       side 0" ~with_:"nop               side 0"
    ; "LDAC pulsed where LOAD should be", fw ~pattern:"set pins, 2       side 0 [2]" ~with_:"set pins, 1       side 0 [2]"
    ; ( "DATA changed as CLK falls"
      , fw
          ~pattern:"out pins, 1       side 1       ; DATA, as CLK rises\n        jmp x-- bit       side 0 "
          ~with_:"out pins, 1       side 0       ; DATA, as CLK rises\n        jmp x-- bit       side 1 " )
    ; "LOAD pulled low with the last clock still high", fw ~pattern:"jmp x-- bit       side 0 " ~with_:"jmp x-- bit       side 1 "
    ]
    ~f:(fun (name, source) -> printf "%-50s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    ten bits clocked in                                caught
    LOAD low for one tick                              caught
    LDAC low for one tick                              caught
    LDAC pulsed after every write                      caught
    LDAC pulsed where LOAD should be                   caught
    DATA changed as CLK falls                          caught
    LOAD pulled low with the last clock still high     caught
    |}]
;;
