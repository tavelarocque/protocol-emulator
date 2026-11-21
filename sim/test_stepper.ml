(* The step and direction engine ([Firmware.stepper]) against a stepper
   driver written here from the DRV8825's timing table: it counts steps and
   refuses pulses shorter than the part allows. The cocotb test runs the
   same firmware on the RTL and the gate netlist with sigrok's stepper
   motor decoder reading position and speed off the two wires. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let clkdiv = 10 (* 10 MHz: a tick is 1 us *)

(* A DRV8825's inputs. It steps on STEP's rising edge, in the direction DIR
   shows. Its limits, in cycles of 100 ns: STEP high and low for 1.9 us
   each; DIR set up 650 ns before the edge and held 650 ns after. *)
module Driver = struct
  type t =
    { mutable position : int
    ; mutable step : bool
    ; mutable dir : bool
    ; mutable now : int
    ; mutable step_changed : int
    ; mutable dir_changed : int
    ; mutable rises : (int * int) list (* (when, position after), newest first *)
    ; mutable errors : string list
    }

  let create () =
    { position = 0; step = false; dir = false; now = 0; step_changed = -1000; dir_changed = -1000; rises = []; errors = [] }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  let cycle t ~step ~dir =
    t.now <- t.now + 1;
    if Bool.( <> ) dir t.dir
    then (
      if t.step && t.now - t.step_changed < 7 then error t "DIR changed within 650 ns after a step";
      t.dir_changed <- t.now);
    if Bool.( <> ) step t.step
    then (
      if t.now - t.step_changed < 19
      then error t (if step then "STEP low for less than 1.9 us" else "STEP high for less than 1.9 us");
      if step
      then (
        if t.now - t.dir_changed < 7 then error t "DIR changed within 650 ns before a step";
        t.position <- (t.position + if dir then 1 else -1);
        t.rises <- (t.now, t.position) :: t.rises);
      t.step_changed <- t.now);
    t.step <- step;
    t.dir <- dir
  ;;
end

type outcome =
  { driver : Driver.t
  ; done_ : int list (* RX words *)
  }

(* Make [moves] (forwards, steps, period in ticks), the host keeping the
   FIFO fed and taking each report. *)
let run ?(source = Firmware.stepper) moves =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.stepper_config ~clkdiv ]
  in
  let driver = Driver.create () in
  let pending =
    Queue.of_list
      (List.concat_map moves ~f:(fun (forwards, steps, period) -> Firmware.stepper_words ~forwards ~steps ~period))
  in
  let ticks = List.sum (module Int) moves ~f:(fun (_, steps, period) -> (steps * period) + 20) in
  let done_ = Queue.create () in
  for _ = 1 to (ticks + 50) * clkdiv do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    let l = Isa.lines m ~inputs:0xFF in
    Driver.cycle driver ~step:(l land 1 = 1) ~dir:((l lsr 1) land 1 = 1);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue done_)
  done;
  { driver; done_ = Queue.to_list done_ }
;;

(* Cycles between one step and the next, in order. *)
let periods (d : Driver.t) =
  let times = List.rev_map d.rises ~f:fst in
  List.map2_exn (List.drop_last_exn times) (List.tl_exn times) ~f:(fun a b -> b - a)
;;

let%expect_test "a move out and a slower move back" =
  let r = run [ true, 5, 100; false, 3, 250 ] in
  printf !"errors: %{sexp:string list}\n" r.driver.errors;
  printf
    !"position after each step: %{sexp:int list}\n"
    (List.rev_map r.driver.rises ~f:snd);
  printf !"microseconds from each step to the next: %{sexp:int list}\n" (List.map (periods r.driver) ~f:(fun c -> c / 10));
  printf !"reports: %{sexp:int list}\n" r.done_;
  [%expect {|
    errors: ()
    position after each step: (1 2 3 4 5 4 3 2)
    microseconds from each step to the next: (100 100 100 100 106 250 250)
    reports: (0 0)
    |}]
;;

let%test_unit "random moves: every step counted, every period exact, the driver's timing met" =
  Quickcheck.test
    (Quickcheck.Generator.list_non_empty
       (Quickcheck.Generator.tuple3 Bool.quickcheck_generator (Int.gen_incl 1 12) (Int.gen_incl 4 300)))
    ~trials:120
    ~sexp_of:[%sexp_of: (bool * int * int) list]
    ~f:(fun moves ->
      let moves = List.take moves 5 in
      let r = run moves in
      [%test_result: string list] r.driver.errors ~expect:[];
      [%test_result: int]
        r.driver.position
        ~expect:(List.sum (module Int) moves ~f:(fun (forwards, steps, _) -> if forwards then steps else -steps));
      [%test_result: int list] r.done_ ~expect:(List.map moves ~f:(fun _ -> 0));
      (* Inside a move every step is one period after the last; a move's
         first step comes six ticks after the last period of the move
         before has run out. *)
      let expected =
        List.concat_mapi moves ~f:(fun i (_, steps, period) ->
          let last = i = List.length moves - 1 in
          List.init (steps - 1) ~f:(fun _ -> period * clkdiv)
          @ if last then [] else [ (period + 6) * clkdiv ])
      in
      [%test_result: int list] (periods r.driver) ~expect:expected)
;;

let%expect_test "planted bugs" =
  let moves = [ true, 4, 50; false, 2, 8; true, 3, 4; false, 6, 120 ] in
  let caught source =
    let r = run ~source moves in
    let right = run moves in
    not
      (List.is_empty r.driver.errors
       && r.driver.position = -1
       && [%equal: int list] r.done_ [ 0; 0; 0; 0 ]
       && [%equal: int list] (periods r.driver) (periods right.driver))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.stepper ~pattern ~with_ in
    assert (not (String.equal s Firmware.stepper));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.stepper then "WRONG" else "right");
  List.iter
    [ "STEP high for one tick", fw ~pattern:"nop                 side 1 " ~with_:"nop                 side 0 "
    ; "STEP left high while the period is counted", fw ~pattern:"low:    jmp x-- low         side 0" ~with_:"low:    jmp x-- low         side 1"
    ; "DIR set as the first step is made", fw ~pattern:"out pins, 1         side 0     ; DIR\n        out y, 15           side 0\n        pull                side 0 " ~with_:"out y, 15           side 0\n        pull                side 0\n        out pins, 1         side 1 "
    ; "the move never reported", fw ~pattern:"push                side 0" ~with_:"nop                 side 0"
    ; "the direction taken from the word's last bit", fw ~pattern:"out pins, 1         side 0     ; DIR\n        out y, 15           side 0" ~with_:"out y, 15           side 0\n        out pins, 1         side 0"
    ; "the period counted one tick short", fw ~pattern:"nop                 side 1     ; and is high for two ticks\n" ~with_:""
    ]
    ~f:(fun (name, source) -> printf "%-46s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    STEP high for one tick                         caught
    STEP left high while the period is counted     caught
    DIR set as the first step is made              caught
    the move never reported                        caught
    the direction taken from the word's last bit   caught
    the period counted one tick short              caught
    |}]
;;
