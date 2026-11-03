(* The SWD clock engine ([Firmware.swd]) on the model chip. The SWD framing
   lives in the board driver and is tested in cocotb against an ADIv5 target
   (test/swd_dp.v); here the engine's contract is checked directly: for
   random SWDIO bits and a target that pulls the line low after chosen
   rising edges, each sample must be the wired-AND of the host's bit and
   what the target drove after the previous rising edge, the target must
   see the same value on each rising edge, there must be exactly one rising
   edge per bit, and SWDIO must never change in the same clock as SWCLK
   rises (it would have no setup time). *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    match i with
    | 0 -> Isa.Pin_mode.Push_pull
    | 1 -> Open_drain
    | _ -> Input)
;;

type outcome =
  { samples : bool list (* what the chip reports *)
  ; seen : bool list (* what the target sampled on each rising edge *)
  ; setup_violations : int
  }

(* [pulls.(k)]: the target holds SWDIO low after rising edge k + 1 until the
   next rising edge. *)
let run ?(source = Firmware.swd) ?(clkdiv = 1) ~bits ~pulls () =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:modes
      ~threads:[ { Firmware.swd_config with clkdiv } ]
  in
  let n = List.length bits in
  let pending = Queue.of_list (Firmware.swd_words bits) in
  let rx = Queue.create () in
  let words = (n + 15) / 16 in
  let edges = ref 0
  and prev_clk = ref true (* pins reset high *)
  and prev_line = ref true
  and target_low = ref false
  and seen = Queue.create ()
  and violations = ref 0
  and cycle = ref 0 in
  while Queue.length rx < words && !cycle < 200_000 do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue rx);
    let inputs = 0xFD lor (Bool.to_int (not !target_low) lsl 1) in
    Isa.step m ~inputs;
    let clk = Isa.pin_out m land 1 = 1 in
    let line = Isa.pin_out m land 2 = 2 && not !target_low in
    if clk && not !prev_clk
    then (
      if not (Bool.equal line !prev_line) then incr violations;
      Queue.enqueue seen line;
      incr edges;
      target_low := (match List.nth pulls (!edges - 1) with Some p -> p | None -> false));
    prev_clk := clk;
    prev_line := Isa.pin_out m land 2 = 2 && not !target_low;
    incr cycle
  done;
  let samples =
    if Queue.length rx < words then [] else Firmware.swd_sampled ~n (Queue.to_list rx)
  in
  { samples; seen = Queue.to_list seen; setup_violations = !violations }
;;

(* The pins reset high, so the first push-pull drive of SWCLK low is not an
   edge, but the very first rising edge after it is the first bit's. *)
let expected ~bits ~pulls =
  List.mapi bits ~f:(fun k b ->
    let pulled = k > 0 && Option.value (List.nth pulls (k - 1)) ~default:false in
    b && not pulled)
;;

let%test_unit "program: 11 words" =
  [%test_result: int] (Array.length (Asm.assemble Firmware.swd)) ~expect:11
;;

let%test_unit "random bits: each sample is the host's bit AND the target's" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Quickcheck.Generator.list_non_empty Bool.quickcheck_generator)
       (Quickcheck.Generator.list Bool.quickcheck_generator)
       (Int.gen_incl 1 4))
    ~trials:300
    ~sexp_of:[%sexp_of: bool list * bool list * int]
    ~f:(fun (bits, pulls, clkdiv) ->
      let bits = List.take bits 70 in
      let r = run ~clkdiv ~bits ~pulls () in
      [%test_result: bool list] r.samples ~expect:(expected ~bits ~pulls);
      [%test_result: bool list] r.seen ~expect:(expected ~bits ~pulls);
      [%test_result: int] r.setup_violations ~expect:0)
;;

let%expect_test "planted firmware bugs: each is caught" =
  let mutate ~pattern ~with_ =
    let m = String.substr_replace_first Firmware.swd ~pattern ~with_ in
    assert (not (String.equal m Firmware.swd));
    m
  in
  let bits = List.init 40 ~f:(fun i -> i % 3 <> 0)
  and pulls = List.init 40 ~f:(fun i -> i % 5 = 2) in
  List.iter
    [ ( "SWDIO never driven"
      , mutate
          ~pattern:"out pins, 1         side 0"
          ~with_:"out null, 1         side 0" )
    ; ( "SWDIO moves as SWCLK rises"
      , mutate
          ~pattern:"out pins, 1         side 0     ; SWDIO (1 = released) while SWCLK is low\n        in pins, 1          side 1 [1]"
          ~with_:"out pins, 1         side 1     ; SWDIO (1 = released) while SWCLK is low\n        in pins, 1          side 1 [1]" )
    ; ( "a batch's last samples never pushed"
      , mutate
          ~pattern:"push                side 0     ; the batch is done"
          ~with_:"nop                 side 0     ; the batch is done" )
    ]
    ~f:(fun (name, source) ->
      let r = run ~source ~bits ~pulls () in
      let want = expected ~bits ~pulls in
      let ok =
        [%equal: bool list] r.samples want
        && [%equal: bool list] r.seen want
        && r.setup_violations = 0
      in
      printf "%-38s %s\n" name (if ok then "MISSED" else "caught"));
  [%expect
    {|
    SWDIO never driven                     caught
    SWDIO moves as SWCLK rises             caught
    a batch's last samples never pushed    caught
    |}]
;;
