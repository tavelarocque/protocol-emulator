(* The lockstep differential harness: the Hardcaml core against the ISA
   reference model, cycle by cycle, comparing the full architectural state
   of both threads and the shared pins after every cycle.

   A run is described by a [Scenario]: the program memory, both threads'
   configurations, pin modes, CHAIN, and policies for the pin inputs, the
   host's FIFO traffic and the thread enables. Random trials
   ([random_scenario]) and directed scenarios (sim/directed.ml) go through
   exactly the same checking, so a directed test is only ever as trusted as
   a random one: the model judges it.

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
  ; div_count : int
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

module Scenario = struct
  type enables =
    | Random_flips (* off about once every 300 cycles, back after about 20 *)
    | Script of (int * int * bool) list (* (cycle, thread, enabled) *)
  [@@deriving sexp_of]

  type pins =
    | Random_pins
    | Constant of int
    | Square of
        { period : int
        ; mask : int
        } (* [mask] for [period] cycles, then 0 for [period] *)
  [@@deriving sexp_of]

  type t =
    { name : string
    ; words : int array (* all 64 *)
    ; configs : Isa.Thread_config.t list
    ; modes : Isa.Pin_mode.t array
    ; chain : bool
    ; enabled : bool array (* at the start *)
    ; enables : enables
    ; rates : (int * int) list (* per thread: host push %, host pop % *)
    ; pins : pins
    ; cycles : int
    }
  [@@deriving sexp_of]
end

let random_config rs =
  let rand n = Random.State.int rs n in
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
  ; (* Mostly full speed, so programs get somewhere in 300 cycles. *)
    clkdiv =
      (match rand 4 with
       | 0 -> 0
       | 1 -> 1
       | 2 -> 2 + rand 2
       | _ -> rand 6)
  }
;;

let random_modes rs =
  Array.init Isa.num_pins ~f:(fun _ ->
    match Random.State.int rs 3 with
    | 0 -> Isa.Pin_mode.Input
    | 1 -> Push_pull
    | _ -> Open_drain)
;;

(* A random trial. Returns the scenario and the random state to keep
   drawing from while it runs. *)
let random_scenario ~seed ~cycles =
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
     enabled 7 times in 8. A first version flipped enables at a fixed rate,
     which left both threads running together only 31% of the time. *)
  let enabled = Array.init Rtl.num_threads ~f:(fun _ -> rand 8 > 0) in
  (* A third of the trials chain thread 0's output into thread 1. The host
     keeps trying to use the chained FIFO ends, which both implementations
     must ignore. *)
  let chain = rand 3 = 0 in
  ( { Scenario.name = sprintf "random #%d" (seed + 1)
    ; words
    ; configs
    ; modes
    ; chain
    ; enabled
    ; enables = Random_flips
    ; rates
    ; pins = Random_pins
    ; cycles
    }
  , rs )
;;

(* --- Coverage ----------------------------------------------------------------- *)

(* What one thread did this cycle, from the model's state before the step,
   so it is independent of the hardware. *)
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
    else if timeout && (if th.waiting then th.wait_count else th.config.timeout) = 0
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

let pin_mask ~base ~count =
  List.init (min count Isa.num_pins) ~f:(fun k -> 1 lsl ((base + k) % Isa.num_pins))
  |> List.fold ~init:0 ~f:( lor )
;;

(* The pins a thread writes this cycle, and whether it is executing an
   instruction at all (enabled, on a divider tick, no delay pending). OUT,
   MOV and SET never stall; side-set applies stalled or not. *)
let pin_writes (th : Isa.Thread.t) (instr : Isa.Instruction.t) =
  let c = th.config in
  let executing = th.enabled && th.div_count = 0 && th.delay_left = 0 in
  if not executing
  then 0, false
  else (
    let side = pin_mask ~base:c.sideset_base ~count:c.sideset_count in
    let own =
      match instr.op with
      | Out { dst = Pins; count } -> pin_mask ~base:c.out_base ~count
      | Mov { dst = Pins; _ } -> pin_mask ~base:c.out_base ~count:c.out_count
      | Set { dst = Pins; _ } -> pin_mask ~base:c.set_base ~count:c.set_count
      | _ -> 0
    in
    side lor own, true)
;;

(* The basic bins: per thread, which instruction outcome; plus a few
   whole-chip conditions. The required list in test_core.ml must all be
   hit by the random trials alone. *)
let basic_bins (model : Isa.t) ~words ~chain ~inputs =
  let bins = Queue.create () in
  let add = Queue.enqueue bins in
  let drivers = ref 0 in
  for n = 0 to Rtl.num_threads - 1 do
    let th = Isa.thread model n in
    let word = words.(th.pc) in
    add
      (if not th.enabled
       then "(thread disabled)"
       else if th.div_count > 0
       then "(between divider ticks)"
       else if th.delay_left > 0
       then "(delay cycle)"
       else classify model ~thread:n ~word ~inputs);
    let mask, executing = pin_writes th (Isa.Instruction.decode word) in
    if executing && th.config.sideset_count > 0 then add "(side-set driving pins)";
    if mask <> 0 then incr drivers
  done;
  let t0 = Isa.thread model 0
  and t1 = Isa.thread model 1 in
  if chain && (not (Queue.is_empty t0.rx_fifo)) && Queue.length t1.tx_fifo < Isa.fifo_depth
  then add "(chain moved a word)";
  if chain && Queue.length t1.tx_fifo >= Isa.fifo_depth && not (Queue.is_empty t0.rx_fifo)
  then add "(chain blocked: thread 1 TX full)";
  if !drivers = 2 then add "(both threads drive pins in one cycle)";
  if t0.enabled && t1.enabled then add "(both threads enabled)";
  Queue.to_list bins
;;

(* Cross bins: combinations that matter for correctness and that uniformly
   random programs reach rarely or never. These are the targets of coverage
   closure (sim/test_closure.ml). *)
let cross_bins (model : Isa.t) ~words ~chain ~inputs =
  let bins = Queue.create () in
  let add = Queue.enqueue bins in
  let threads = List.init Rtl.num_threads ~f:(Isa.thread model) in
  let info =
    List.mapi threads ~f:(fun n (th : Isa.Thread.t) ->
      let word = words.(th.pc) in
      let instr = Isa.Instruction.decode word in
      let mask, executing = pin_writes th instr in
      let what = if executing then classify model ~thread:n ~word ~inputs else "" in
      th, instr, mask, executing, what)
  in
  let th0, i0, m0, x0, w0 = List.nth_exn info 0
  and th1, i1, m1, x1, w1 = List.nth_exn info 1 in
  if m0 land m1 <> 0 then add "pins: both threads write the same pin";
  (* CHAIN *)
  let moves =
    chain && (not (Queue.is_empty th0.rx_fifo)) && Queue.length th1.tx_fifo < Isa.fifo_depth
  in
  if moves
  then (
    add (sprintf "chain: move into thread 1 TX holding %d" (Queue.length th1.tx_fifo));
    if x1 && String.equal w1 "pull" then add "chain: move in a cycle thread 1 pulls";
    if x0 && String.equal w0 "push" then add "chain: move in a cycle thread 0 pushes");
  if chain && x0 && String.equal w0 "push: stalled, RX full"
  then add "chain: thread 0 PUSH stalled behind a full chain";
  (* Clock divider, enables, stalls *)
  List.iter2_exn [ th0, i0, x0, w0; th1, i1, x1, w1 ] [ 0; 1 ] ~f:(fun (th, _, x, w) _ ->
    let divided = th.config.clkdiv > 1 in
    if divided && x && String.equal w "wait: timed out"
    then add "divider: timed wait expires on a divided thread";
    if divided && th.enabled && th.div_count = 0 && th.delay_left > 0
    then add "divider: delay counted on a divided thread";
    if divided && x && th.config.sideset_count > 0
    then add "divider: side-set on a divided thread";
    if (not th.enabled) && th.delay_left > 0 then add "enable: disabled during a delay";
    if (not th.enabled) && th.waiting then add "enable: disabled during a timed wait";
    if (not th.enabled) && th.div_count > 0 then add "enable: disabled between divider ticks";
    if x
       && th.config.sideset_count > 0
       && String.is_substring w ~substring:"stalled"
    then add "side-set: driven during a stall");
  let fifo_stall w =
    String.equal w "push: stalled, RX full" || String.equal w "pull: stalled, TX empty"
  in
  if x0 && x1 && fifo_stall w0 && fifo_stall w1 then add "fifo: both threads stalled on FIFOs";
  Queue.to_list bins
;;

let all_cross_bins =
  [ "pins: both threads write the same pin"
  ; "chain: move into thread 1 TX holding 0"
  ; "chain: move into thread 1 TX holding 1"
  ; "chain: move into thread 1 TX holding 2"
  ; "chain: move into thread 1 TX holding 3"
  ; "chain: move in a cycle thread 1 pulls"
  ; "chain: move in a cycle thread 0 pushes"
  ; "chain: thread 0 PUSH stalled behind a full chain"
  ; "divider: timed wait expires on a divided thread"
  ; "divider: delay counted on a divided thread"
  ; "divider: side-set on a divided thread"
  ; "enable: disabled during a delay"
  ; "enable: disabled during a timed wait"
  ; "enable: disabled between divider ticks"
  ; "side-set: driven during a stall"
  ; "fifo: both threads stalled on FIFOs"
  ]
;;

type coverage =
  { basic : (string, int) Hashtbl.t
  ; cross : (string, int) Hashtbl.t
  }

let create_coverage () =
  { basic = Hashtbl.create (module String); cross = Hashtbl.create (module String) }
;;

(* --- Running a scenario ------------------------------------------------------ *)

(* Runs [s] in lockstep, drawing whatever its policies leave random from
   [rs]. Returns the first divergence, if any. *)
let run ?coverage ?mutation ~rs (s : Scenario.t) =
  let rand n = Random.State.int rs n in
  let enabled = Array.copy s.enabled in
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
  List.iteri s.configs ~f:(fun n (config : Isa.Thread_config.t) ->
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
    set ti.sideset_count config.sideset_count;
    set ti.clkdiv config.clkdiv);
  set i.chain (Bool.to_int s.chain);
  set
    i.pin_modes
    (Array.foldi s.modes ~init:0 ~f:(fun p acc m -> acc lor (mode_code m lsl (2 * p))));
  Array.iteri s.words ~f:(fun a w ->
    set i.prog_we 1;
    set i.prog_addr a;
    set i.prog_data w;
    Cyclesim.cycle sim);
  set i.prog_we 0;
  let model =
    Isa.create
      ~program:(Array.map s.words ~f:Isa.Instruction.decode)
      ~pin_modes:s.modes
      ~threads:s.configs
  in
  Isa.set_chain model s.chain;
  let rec loop cycle =
    if cycle >= s.cycles
    then None
    else (
      let pins =
        match s.pins with
        | Random_pins -> rand 256
        | Constant v -> v
        | Square { period; mask } -> if cycle / period % 2 = 0 then mask else 0
      in
      set i.pins_in pins;
      let pcs_before = List.init Rtl.num_threads ~f:(fun n -> (Isa.thread model n).pc) in
      (* Per-thread host actions, decided from the state at the start of the
         cycle. *)
      let host =
        List.mapi s.rates ~f:(fun n (push_pct, pop_pct) ->
          (match s.enables with
           | Random_flips ->
             if rand (if enabled.(n) then 300 else 20) = 0
             then enabled.(n) <- not enabled.(n)
           | Script script ->
             List.iter script ~f:(fun (c, t, e) -> if c = cycle && t = n then enabled.(n) <- e));
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
      Option.iter coverage ~f:(fun c ->
        List.iter
          (basic_bins model ~words:s.words ~chain:s.chain ~inputs:pins)
          ~f:(Hashtbl.incr c.basic);
        List.iter
          (cross_bins model ~words:s.words ~chain:s.chain ~inputs:pins)
          ~f:(Hashtbl.incr c.cross));
      Cyclesim.cycle sim;
      Isa.step model ~inputs:pins;
      let popped =
        List.mapi host ~f:(fun n (push, push_value, pop) ->
          (* The host's push and pop are refused at the chained ends. *)
          let push_ok = if push then Isa.push_tx model ~thread:n push_value else false in
          if push && not push_ok then assert (s.chain && n = 1);
          let model_popped = if pop then Isa.pop_rx model ~thread:n else None in
          let rtl_popped =
            Option.some_if
              (pop && not (s.chain && n = 0))
              (get (Rtl.O.thread o_before n).rx_data)
          in
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
        ; div_count = get t.div_count
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
        ; div_count = th.div_count
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
            pc, Isa.Instruction.to_string (Isa.Instruction.decode s.words.(pc)))
        in
        Some
          [%message
            "RTL diverged from model"
              ~scenario:(s.name : string)
              (cycle : int)
              (instructions : (int * string) list)
              (expected : state)
              (rtl : state)
              ~chain:(s.chain : bool)
              ~configs:(s.configs : Isa.Thread_config.t list)]))
  in
  loop 0
;;

let run_random ?coverage ?mutation ~seed ~cycles () =
  let scenario, rs = random_scenario ~seed ~cycles in
  run ?coverage ?mutation ~rs scenario
;;
