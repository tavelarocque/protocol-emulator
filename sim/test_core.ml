(* Differential test: the Hardcaml core against the ISA reference model.

   Each trial draws a random program (32 uniformly random 16-bit words, so
   every encoding including reserved ones gets exercised), a random thread
   configuration and pin-mode assignment, then runs both implementations in
   lockstep with random pin inputs and random host FIFO traffic, comparing
   the full architectural state after every cycle.

   The host only pushes when the TX FIFO is not full and only pops when the
   RX FIFO is not empty, judged at the start of the cycle. In the model the
   host's push/pop is applied after the step, which is the same ordering the
   hardware's start-of-cycle full/empty flags give. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Rtl = Pe_hw.Pe_core
module Sim = Cyclesim.With_interface (Rtl.I) (Rtl.O)

type state =
  { pc : int
  ; x : int
  ; y : int
  ; isr : int
  ; isr_count : int
  ; osr : int
  ; osr_count : int
  ; delay_left : int
  ; waiting : bool
  ; wait_count : int
  ; pin_out : int
  ; tx_level : int
  ; rx_level : int
  ; popped : int option
  }
[@@deriving sexp_of, equal]

let mode_code : Isa.Pin_mode.t -> int = function
  | Input -> 0
  | Push_pull -> 1
  | Open_drain -> 2
;;

let random_config rs =
  let rand n = Random.State.int rs n in
  let config =
    { Isa.Thread_config.start = rand Isa.program_size
    ; out_base = rand 8
    ; out_count = 1 + rand 8
    ; set_base = rand 8
    ; set_count = 1 + rand 5
    ; in_base = rand 8
    ; threshold = 1 + rand 16
    ; timeout_vector = rand Isa.program_size
    ; (* Mostly short budgets so timeouts actually fire within a trial,
         sometimes long ones, sometimes zero (expire immediately). *)
      timeout =
        (match rand 4 with
         | 0 -> 0
         | 1 | 2 -> rand 8
         | _ -> rand 65536)
    ; sideset_base = rand 8
    ; (* Half the trials without side-set, half with 1 to 3 side-set bits. *)
      sideset_count = (if rand 2 = 0 then 0 else 1 + rand 3)
    }
  in
  let modes =
    Array.init Isa.num_pins ~f:(fun _ ->
      match rand 3 with
      | 0 -> Isa.Pin_mode.Input
      | 1 -> Push_pull
      | _ -> Open_drain)
  in
  config, modes
;;

(* Functional coverage: what the model actually did on a cycle where the
   thread was executing (not counting down a delay). Computed from the model's
   state before the step, so it is independent of the hardware. *)
let classify (model : Isa.t) ~word ~inputs =
  let th = Isa.thread model 0 in
  let raw_op = word lsr 13 in
  match (Isa.Instruction.decode word).op with
  | Jmp { cond = Always; _ } -> "jmp (always)"
  | Jmp { cond; _ } -> "jmp " ^ Isa.Cond.to_string cond
  | Wait { polarity; pin; timeout } ->
    let level = (Isa.lines model ~inputs lsr pin) land 1 = 1 in
    if Bool.equal level polarity
    then "wait: condition met"
    else if timeout
            && (if th.waiting then th.wait_count else th.config.timeout) = 0
    then "wait: timed out"
    else if timeout
    then "wait: stalled, spending timeout budget"
    else "wait: stalled"
  | In { src; _ } -> "in " ^ Isa.In_src.to_string src
  | Out { dst; _ } -> "out " ^ Isa.Out_dst.to_string dst
  | Push ->
    if Queue.length th.rx_fifo >= Isa.fifo_depth then "push: stalled, RX full" else "push"
  | Pull -> if Queue.is_empty th.tx_fifo then "pull: stalled, TX empty" else "pull"
  | Mov { dst; src = _ } -> "mov to " ^ Isa.Mov_loc.to_string dst
  | Set { dst; _ } -> "set " ^ Isa.Set_dst.to_string dst
  | Nop when raw_op = 5 -> "mov (reserved -> nop)"
  | Nop when raw_op = 6 -> "set (reserved -> nop)"
  | Nop -> "nop"
;;

(* Runs one trial. Returns the first divergence, if any. *)
let run_trial ?coverage ?mutation ~seed ~cycles () =
  let rs = Random.State.make [| seed |] in
  let rand n = Random.State.int rs n in
  (* Uniformly random words, except that 3 in 4 have their delay field
     cleared: with uniform delays, 71% of cycles were spent idling. *)
  let words =
    Array.init Isa.program_size ~f:(fun _ ->
      let w = rand 65536 in
      if rand 4 = 0 then w else w land lnot (0xF lsl 9))
  in
  let config, modes = random_config rs in
  (* Each trial gets its own host behaviour, from never touching a FIFO to
     touching it every cycle. A single fixed rate never let the RX FIFO fill,
     so PUSH's stall-on-full path went untested. *)
  let host_rate () =
    match rand 4 with
    | 0 -> 0
    | 1 -> 10
    | 2 -> 33
    | _ -> 100
  in
  let push_pct = host_rate () in
  let pop_pct = host_rate () in
  let sim = Sim.create (Rtl.create ?mutation) in
  let i : _ Rtl.I.t = Cyclesim.inputs sim in
  let o : _ Rtl.O.t = Cyclesim.outputs sim in
  let o_before : _ Rtl.O.t = Cyclesim.outputs ~clock_edge:Before sim in
  let set (r : Bits.t ref) v = r := Bits.of_int ~width:(Bits.width !r) v in
  let get (r : Bits.t ref) = Bits.to_int !r in
  (* Reset, configure, load the program with the thread disabled. *)
  set i.clear 1;
  Cyclesim.cycle sim;
  set i.clear 0;
  set i.start config.start;
  set i.out_base config.out_base;
  set i.out_count config.out_count;
  set i.set_base config.set_base;
  set i.set_count config.set_count;
  set i.in_base config.in_base;
  set i.threshold config.threshold;
  set i.timeout_vector config.timeout_vector;
  set i.timeout config.timeout;
  set i.sideset_base config.sideset_base;
  set i.sideset_count config.sideset_count;
  set
    i.pin_modes
    (Array.foldi modes ~init:0 ~f:(fun p acc m -> acc lor (mode_code m lsl (2 * p))));
  Array.iteri words ~f:(fun a w ->
    set i.prog_we 1;
    set i.prog_addr a;
    set i.prog_data w;
    Cyclesim.cycle sim);
  set i.prog_we 0;
  set i.enable 1;
  let model =
    Isa.create
      ~program:(Array.map words ~f:Isa.Instruction.decode)
      ~pin_modes:modes
      ~threads:[ config ]
  in
  let rec loop cycle =
    if cycle >= cycles
    then None
    else (
      let th = Isa.thread model 0 in
      let pc_before = th.pc in
      let pins = rand 256 in
      let push = rand 100 < push_pct && get o.tx_level < Isa.fifo_depth in
      let push_value = rand 65536 in
      let pop = rand 100 < pop_pct && get o.rx_level > 0 in
      set i.pins_in pins;
      set i.tx_push (Bool.to_int push);
      set i.tx_data push_value;
      set i.rx_pop (Bool.to_int pop);
      Cyclesim.cycle sim;
      let rtl_popped = Option.some_if pop (get o_before.rx_data) in
      Option.iter coverage ~f:(fun table ->
        let key =
          if th.delay_left > 0
          then "(delay cycle)"
          else classify model ~word:words.(pc_before) ~inputs:pins
        in
        Hashtbl.incr table key;
        if th.delay_left = 0 && config.sideset_count > 0
        then Hashtbl.incr table "(side-set driving pins)");
      Isa.step model ~inputs:pins;
      if push then assert (Isa.push_tx model ~thread:0 push_value);
      let model_popped = if pop then Isa.pop_rx model ~thread:0 else None in
      let rtl =
        { pc = get o.pc
        ; x = get o.x
        ; y = get o.y
        ; isr = get o.isr
        ; isr_count = get o.isr_count
        ; osr = get o.osr
        ; osr_count = get o.osr_count
        ; delay_left = get o.delay_left
        ; waiting = get o.waiting = 1
        ; wait_count = get o.wait_count
        ; pin_out = get o.pin_out
        ; tx_level = get o.tx_level
        ; rx_level = get o.rx_level
        ; popped = rtl_popped
        }
      in
      let th = Isa.thread model 0 in
      let expected =
        { pc = th.pc
        ; x = th.x
        ; y = th.y
        ; isr = th.isr
        ; isr_count = th.isr_count
        ; osr = th.osr
        ; osr_count = th.osr_count
        ; delay_left = th.delay_left
        ; waiting = th.waiting
        ; wait_count = th.wait_count
        ; pin_out = Isa.pin_out model
        ; tx_level = Queue.length th.tx_fifo
        ; rx_level = Queue.length th.rx_fifo
        ; popped = model_popped
        }
      in
      if equal_state rtl expected
      then loop (cycle + 1)
      else
        Some
          [%message
            "RTL diverged from model"
              (seed : int)
              (cycle : int)
              ~instruction:
                (Isa.Instruction.to_string (Isa.Instruction.decode words.(pc_before))
                 : string)
              (pc_before : int)
              (expected : state)
              (rtl : state)
              (config : Isa.Thread_config.t)])
  in
  loop 0
;;

let trials = 400
let cycles_per_trial = 300

let%test_unit "RTL core matches the ISA model on random programs" =
  for seed = 0 to trials - 1 do
    match run_trial ~seed ~cycles:cycles_per_trial () with
    | None -> ()
    | Some divergence -> raise_s divergence
  done
;;

(* What the random programs actually exercised across the whole run. A
   behaviour with a zero count here is untested, however green the
   differential test is. *)
let%expect_test "coverage of the differential test" =
  let table = Hashtbl.create (module String) in
  for seed = 0 to trials - 1 do
    ignore (run_trial ~coverage:table ~seed ~cycles:cycles_per_trial () : Sexp.t option)
  done;
  let required =
    [ "jmp (always)"; "jmp !x"; "jmp x--"; "jmp !y"; "jmp y--"; "jmp x!=y"
    ; "jmp !osre"; "jmp !isrf"; "wait: condition met"; "wait: stalled"
    ; "wait: stalled, spending timeout budget"; "wait: timed out"; "in pins"
    ; "in x"; "in y"; "in null"; "out pins"; "out x"; "out y"; "out null"; "push"
    ; "push: stalled, RX full"; "pull"; "pull: stalled, TX empty"; "mov to x"
    ; "mov to y"; "mov to pins"; "mov to isr"; "mov to osr"; "mov to null"
    ; "mov (reserved -> nop)"; "set pins"; "set x"; "set y"
    ; "set (reserved -> nop)"; "nop"; "(delay cycle)"; "(side-set driving pins)"
    ]
  in
  List.iter required ~f:(fun key ->
    if not (Hashtbl.mem table key) then raise_s [%message "coverage hole" (key : string)]);
  let total = Hashtbl.data table |> List.sum (module Int) ~f:Fn.id in
  Hashtbl.to_alist table
  |> List.sort ~compare:(fun (a, _) (b, _) -> String.compare a b)
  |> List.iter ~f:(fun (key, n) ->
    printf "%-40s %6d  %5.1f%%\n" key n (100. *. Float.of_int n /. Float.of_int total));
  [%expect {|
    (delay cycle)                             24466   14.0%
    (side-set driving pins)                   54762   31.3%
    in null                                     685    0.4%
    in pins                                     917    0.5%
    in x                                        870    0.5%
    in y                                        963    0.6%
    jmp !isrf                                   578    0.3%
    jmp !osre                                   879    0.5%
    jmp !x                                     1057    0.6%
    jmp !y                                      982    0.6%
    jmp (always)                               1065    0.6%
    jmp x!=y                                   1466    0.8%
    jmp x--                                     513    0.3%
    jmp y--                                     641    0.4%
    mov (reserved -> nop)                      1562    0.9%
    mov to isr                                  485    0.3%
    mov to null                                 310    0.2%
    mov to osr                                  357    0.2%
    mov to pins                                 361    0.2%
    mov to x                                    226    0.1%
    mov to y                                    295    0.2%
    nop                                        3681    2.1%
    out null                                   1017    0.6%
    out pins                                    811    0.5%
    out x                                       952    0.5%
    out y                                       844    0.5%
    pull                                       1619    0.9%
    pull: stalled, TX empty                   19591   11.2%
    push                                       1566    0.9%
    push: stalled, RX full                     2576    1.5%
    set (reserved -> nop)                       885    0.5%
    set pins                                    801    0.5%
    set x                                       831    0.5%
    set y                                      1071    0.6%
    wait: condition met                        2598    1.5%
    wait: stalled                             32463   18.6%
    wait: stalled, spending timeout budget     8466    4.8%
    wait: timed out                            1550    0.9%
    |}]
;;

(* Test the test: every planted bug must make the RTL diverge from the model
   within the same budget the real test uses. The count shows how many
   random programs it took, a rough measure of how hard each bug is to hit. *)
let%expect_test "every planted bug in the core is caught" =
  List.iter Rtl.Mutation.all ~f:(fun mutation ->
    let first_failure =
      List.find (List.init trials ~f:Fn.id) ~f:(fun seed ->
        Option.is_some (run_trial ~mutation ~seed ~cycles:cycles_per_trial ()))
    in
    match first_failure with
    | None -> raise_s [%message "mutant survived" (mutation : Rtl.Mutation.t)]
    | Some seed ->
      printf
        "%-28s caught by program #%d\n"
        (Sexp.to_string (Rtl.Mutation.sexp_of_t mutation))
        (seed + 1));
  [%expect {|
    Xdec_never_decrements        caught by program #2
    Wait_timeout_ignores_budget  caught by program #6
    Delay_field_ignored          caught by program #1
    Set_pins_count_off_by_one    caught by program #6
    Push_not_right_justified     caught by program #10
    |}]
;;
