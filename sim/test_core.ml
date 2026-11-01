(* Differential test: the Hardcaml core against the ISA reference model.

   Each trial draws a random program (64 uniformly random 16-bit words, so
   every encoding including reserved ones gets exercised), a random
   configuration for each of the two threads and a random pin-mode
   assignment, then runs both implementations in lockstep with random pin
   inputs, random host FIFO traffic on both threads, and threads being
   enabled and disabled at random, comparing the full architectural state of
   both threads and the shared pins after every cycle. The two threads run
   from the same memory, so they often execute overlapping code and fight
   over the same pins, which is what tests the composition.

   The host only pushes when a TX FIFO is not full and only pops when an RX
   FIFO is not empty, judged at the start of the cycle. In the model the
   host's push/pop is applied after the step, which is the same ordering the
   hardware's start-of-cycle full/empty flags give. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Rtl = Pe_hw.Pe_core
module Sim = Cyclesim.With_interface (Rtl.I) (Rtl.O)

type thread_state =
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
  ; tx_level : int
  ; rx_level : int
  ; popped : int option
  }
[@@deriving sexp_of, equal]

type state =
  { pin_out : int
  ; t0 : thread_state
  ; t1 : thread_state
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
  config
;;

let random_modes rs =
  Array.init Isa.num_pins ~f:(fun _ ->
    match Random.State.int rs 3 with
    | 0 -> Isa.Pin_mode.Input
    | 1 -> Push_pull
    | _ -> Open_drain)
;;

(* Functional coverage: what the model actually did on a cycle where the
   thread was executing (not counting down a delay). Computed from the model's
   state before the step, so it is independent of the hardware. *)
let classify (model : Isa.t) ~thread ~word ~inputs =
  let th = Isa.thread model thread in
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

(* Does this thread write pins this cycle, according to the model? OUT,
   MOV and SET never stall, so decoding the instruction is enough. *)
let drives_pins (th : Isa.Thread.t) (instr : Isa.Instruction.t) =
  th.enabled
  && th.delay_left = 0
  && (th.config.sideset_count > 0
      ||
      match instr.op with
      | Out { dst = Pins; _ } | Mov { dst = Pins; _ } | Set { dst = Pins; _ } -> true
      | _ -> false)
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
  let configs = List.init Rtl.num_threads ~f:(fun _ -> random_config rs) in
  let modes = random_modes rs in
  (* Each thread gets its own host behaviour, from never touching a FIFO to
     touching it every cycle. A single fixed rate never let the RX FIFO fill,
     so PUSH's stall-on-full path went untested. *)
  let host_rate () =
    match rand 4 with
    | 0 -> 0
    | 1 -> 10
    | 2 -> 33
    | _ -> 100
  in
  let rates = List.init Rtl.num_threads ~f:(fun _ -> host_rate (), host_rate ()) in
  (* Threads are mostly running, with short disabled spells: each starts
     enabled 7 times in 8, is disabled about once every 300 cycles, and
     comes back after about 20. A first version flipped enables at a fixed
     rate, which left both threads running together only 31% of the
     time. *)
  let enabled = Array.init Rtl.num_threads ~f:(fun _ -> rand 8 > 0) in
  let sim = Sim.create (Rtl.create ?mutation) in
  let i : _ Rtl.I.t = Cyclesim.inputs sim in
  let o : _ Rtl.O.t = Cyclesim.outputs sim in
  let o_before : _ Rtl.O.t = Cyclesim.outputs ~clock_edge:Before sim in
  let set (r : Bits.t ref) v = r := Bits.of_int ~width:(Bits.width !r) v in
  let get (r : Bits.t ref) = Bits.to_int !r in
  (* Reset, configure, load the program with both threads disabled. *)
  set i.clear 1;
  Cyclesim.cycle sim;
  set i.clear 0;
  List.iteri configs ~f:(fun n (config : Isa.Thread_config.t) ->
    let ti = Rtl.I.thread i n in
    set ti.start config.start;
    set ti.out_base config.out_base;
    set ti.out_count config.out_count;
    set ti.set_base config.set_base;
    set ti.set_count config.set_count;
    set ti.in_base config.in_base;
    set ti.threshold config.threshold;
    set ti.timeout_vector config.timeout_vector;
    set ti.timeout config.timeout;
    set ti.sideset_base config.sideset_base;
    set ti.sideset_count config.sideset_count);
  set
    i.pin_modes
    (Array.foldi modes ~init:0 ~f:(fun p acc m -> acc lor (mode_code m lsl (2 * p))));
  Array.iteri words ~f:(fun a w ->
    set i.prog_we 1;
    set i.prog_addr a;
    set i.prog_data w;
    Cyclesim.cycle sim);
  set i.prog_we 0;
  let model =
    Isa.create
      ~program:(Array.map words ~f:Isa.Instruction.decode)
      ~pin_modes:modes
      ~threads:configs
  in
  let rec loop cycle =
    if cycle >= cycles
    then None
    else (
      let pins = rand 256 in
      set i.pins_in pins;
      let pcs_before = List.init Rtl.num_threads ~f:(fun n -> (Isa.thread model n).pc) in
      (* Per-thread host actions, decided from the state at the start of the
         cycle. *)
      let host =
        List.mapi rates ~f:(fun n (push_pct, pop_pct) ->
          if rand (if enabled.(n) then 300 else 20) = 0
          then enabled.(n) <- not enabled.(n);
          Isa.set_enabled model ~thread:n enabled.(n);
          let to_ = Rtl.O.thread o n in
          let ti = Rtl.I.thread i n in
          let push = rand 100 < push_pct && get to_.tx_level < Isa.fifo_depth in
          let push_value = rand 65536 in
          let pop = rand 100 < pop_pct && get to_.rx_level > 0 in
          set ti.enable (Bool.to_int enabled.(n));
          set ti.tx_push (Bool.to_int push);
          set ti.tx_data push_value;
          set ti.rx_pop (Bool.to_int pop);
          push, push_value, pop)
      in
      Option.iter coverage ~f:(fun table ->
        let drivers = ref 0 in
        for n = 0 to Rtl.num_threads - 1 do
          let th = Isa.thread model n in
          let word = words.(th.pc) in
          let key =
            if not th.enabled
            then "(thread disabled)"
            else if th.delay_left > 0
            then "(delay cycle)"
            else classify model ~thread:n ~word ~inputs:pins
          in
          Hashtbl.incr table key;
          if th.enabled && th.delay_left = 0 && th.config.sideset_count > 0
          then Hashtbl.incr table "(side-set driving pins)";
          if drives_pins th (Isa.Instruction.decode word) then incr drivers
        done;
        if !drivers = 2 then Hashtbl.incr table "(both threads drive pins in one cycle)";
        if (Isa.thread model 0).enabled && (Isa.thread model 1).enabled
        then Hashtbl.incr table "(both threads enabled)");
      Cyclesim.cycle sim;
      Isa.step model ~inputs:pins;
      let popped =
        List.mapi host ~f:(fun n (push, push_value, pop) ->
          if push then assert (Isa.push_tx model ~thread:n push_value);
          let model_popped = if pop then Isa.pop_rx model ~thread:n else None in
          let rtl_popped = Option.some_if pop (get (Rtl.O.thread o_before n).rx_data) in
          model_popped, rtl_popped)
      in
      let rtl_thread n =
        let t = Rtl.O.thread o n in
        { pc = get t.pc
        ; x = get t.x
        ; y = get t.y
        ; isr = get t.isr
        ; isr_count = get t.isr_count
        ; osr = get t.osr
        ; osr_count = get t.osr_count
        ; delay_left = get t.delay_left
        ; waiting = get t.waiting = 1
        ; wait_count = get t.wait_count
        ; tx_level = get t.tx_level
        ; rx_level = get t.rx_level
        ; popped = snd (List.nth_exn popped n)
        }
      in
      let model_thread n =
        let th = Isa.thread model n in
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
        ; tx_level = Queue.length th.tx_fifo
        ; rx_level = Queue.length th.rx_fifo
        ; popped = fst (List.nth_exn popped n)
        }
      in
      let rtl = { pin_out = get o.pin_out; t0 = rtl_thread 0; t1 = rtl_thread 1 } in
      let expected =
        { pin_out = Isa.pin_out model; t0 = model_thread 0; t1 = model_thread 1 }
      in
      if equal_state rtl expected
      then loop (cycle + 1)
      else (
        let instructions =
          List.map pcs_before ~f:(fun pc ->
            pc, Isa.Instruction.to_string (Isa.Instruction.decode words.(pc)))
        in
        Some
          [%message
            "RTL diverged from model"
              (seed : int)
              (cycle : int)
              (instructions : (int * string) list)
              (expected : state)
              (rtl : state)
              (configs : Isa.Thread_config.t list)]))
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
    ; "(thread disabled)"; "(both threads enabled)"
    ; "(both threads drive pins in one cycle)"
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
    (both threads drive pins in one cycle)    22472    4.8%
    (both threads enabled)                   104825   22.3%
    (delay cycle)                             49012   10.4%
    (side-set driving pins)                  101854   21.7%
    (thread disabled)                         15652    3.3%
    in null                                    1450    0.3%
    in pins                                    1869    0.4%
    in x                                       2083    0.4%
    in y                                       1782    0.4%
    jmp !isrf                                  1432    0.3%
    jmp !osre                                  1151    0.2%
    jmp !x                                     1434    0.3%
    jmp !y                                     2226    0.5%
    jmp (always)                               2289    0.5%
    jmp x!=y                                   2253    0.5%
    jmp x--                                    1237    0.3%
    jmp y--                                    1269    0.3%
    mov (reserved -> nop)                      2841    0.6%
    mov to isr                                  770    0.2%
    mov to null                                 653    0.1%
    mov to osr                                  620    0.1%
    mov to pins                                 794    0.2%
    mov to x                                    605    0.1%
    mov to y                                    542    0.1%
    nop                                        7547    1.6%
    out null                                   1906    0.4%
    out pins                                   1679    0.4%
    out x                                      1935    0.4%
    out y                                      1849    0.4%
    pull                                       2803    0.6%
    pull: stalled, TX empty                   33010    7.0%
    push                                       3393    0.7%
    push: stalled, RX full                     8453    1.8%
    set (reserved -> nop)                      1937    0.4%
    set pins                                   1531    0.3%
    set x                                      2146    0.5%
    set y                                      2178    0.5%
    wait: condition met                        5184    1.1%
    wait: stalled                             54754   11.7%
    wait: stalled, spending timeout budget    14622    3.1%
    wait: timed out                            3109    0.7%
    |}]
;;

(* Test the test: every planted bug must make the RTL diverge from the model
   within the same budget the real test uses. Datapath bugs are planted in
   thread 1 only, so this also shows the second thread is really exercised. The count shows how many
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
    Xdec_never_decrements        caught by program #6
    Wait_timeout_ignores_budget  caught by program #6
    Delay_field_ignored          caught by program #1
    Set_pins_count_off_by_one    caught by program #6
    Push_not_right_justified     caught by program #21
    Pin_priority_inverted        caught by program #4
    Fetch_port_crossed           caught by program #1
    |}]
;;
