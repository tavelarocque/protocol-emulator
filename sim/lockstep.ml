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
  ; page : int
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
  ; crc : int
  ; crc_run : bool
  ; tx_level : int
  ; rx_level : int
  ; popped : int option
  }
[@@deriving sexp_of, equal]

type sampler_state =
  { mid : bool
  ; last : bool
  ; phase : int
  ; missed : int
  ; carrier : bool
  ; synced : bool
  ; history : int
  ; pre : int
  ; run : int
  ; slevel : bool
  ; data : bool
  ; strobe : bool
  }
[@@deriving sexp_of, equal]

type state =
  { pin_out : int
  ; buf_ptr : int
  ; buf_read : int option (* the word the host read from the buffer this cycle *)
  ; smp : sampler_state
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
    | Random_runs
      (* each pin holds its level for a while: at each half cycle it changes
         with probability 1 in 5, so the bit sampler sees edges a few
         samples apart instead of at nearly every sample *)
    | Wave of (int * int) array
      (* cycle by cycle, the pins at the falling edge and at the rising edge
         that ends the cycle; all low once it runs out *)
    | Constant of int
    | Square of
        { period : int
        ; mask : int
        } (* [mask] for [period] cycles, then 0 for [period] *)
  [@@deriving sexp_of]

  (* What the host does to the packet buffer in one cycle: at most one of
     these. *)
  type buffer_action =
    | Mode of Isa.Buffer_mode.t * int (* and which thread *)
    | Ptr of int
    | End of int
    | Write of int
    | Read
  [@@deriving sexp_of]

  type buffer =
    { mode : Isa.Buffer_mode.t
    ; thread : int
    ; first : int (* the pointer at the start *)
    ; loaded : int list (* words the host stored from [first] on beforehand *)
    ; length : int (* the end is [first + length] *)
    ; script : (int * buffer_action) list (* (cycle, action) *)
    ; random : bool (* the host also acts at random, as a trial runs *)
    }
  [@@deriving sexp_of]

  let no_buffer =
    { mode = Off; thread = 0; first = 0; loaded = []; length = 0; script = []; random = false }
  ;;

  type t =
    { name : string
    ; words : int array array (* each thread's whole memory *)
    ; configs : Isa.Thread_config.t list
    ; modes : Isa.Pin_mode.t array
    ; chain : bool
    ; sync_bypass : int (* pins read without the synchroniser *)
    ; enabled : bool array (* at the start *)
    ; enables : enables
    ; writes : (int * int * int * int) list
      (* scripted host writes to program memory: (cycle, mask of threads,
         address, word). Random trials add their own. *)
    ; rates : (int * int) list (* per thread: host push %, host pop % *)
    ; buffer : buffer
    ; sampler : Isa.Sampler_config.t (* at the start *)
    ; sampler_random : bool (* the host rewrites the sampler's registers as the trial runs *)
    ; pins : pins
    ; cycles : int
    }
  [@@deriving sexp_of]
end

(* A sampler configuration. The timing numbers are mostly small, so that in
   a few hundred cycles of random pins edges are accepted and ignored, bit
   times go by, the carrier comes and goes, and bits are taken; the sync
   word is mostly one that random bits soon make. *)
let random_sampler rs : Isa.Sampler_config.t =
  let rand n = Random.State.int rs n in
  let small () = if rand 8 = 0 then rand 32 else rand 10 in
  { Isa.Sampler_config.enable = rand 8 > 0
  ; pin = rand 8
  ; invert = rand 2 = 0
  ; sync_enable = rand 2 = 0
  ; misses =
      (match rand 4 with
       | 0 -> 0
       | 1 -> 7
       | _ -> rand 8)
  ; blank = small ()
  ; sample = small ()
  ; wrap = small ()
  ; sync =
      (match rand 4 with
       | 0 -> 0x00
       | 1 -> 0xFF
       | 2 -> rand 4 lsl 6
       | _ -> rand 256)
  ; prescale = 0
  ; shift = 0
  ; stuff = 0
  }
  |> fun (c : Isa.Sampler_config.t) ->
  (* The prescaler and the shift, from a stream of their own so that the
     rest of a run is what it was before they existed: off in most runs,
     and a prescaler mostly small, so that samples still come often. *)
  let own = Random.State.make [| c.pin; c.blank; c.sample; c.wrap; c.sync; c.misses |] in
  let rand n = Random.State.int own n in
  { c with
    prescale =
      (match rand 6 with
       | 0 | 1 | 2 -> 0
       | 3 | 4 -> 1 + rand 4
       | _ -> if rand 4 = 0 then rand 1024 else 1 + rand 12)
  ; shift = (if rand 3 = 0 then rand 8 else 0)
  ; stuff =
      (match rand 6 with
       | 0 | 1 | 2 -> 0
       | 3 | 4 -> 1 + rand 3
       | _ -> rand 8)
  }
;;

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
  ; out_msb_first = rand 2 = 0
  ; in_msb_first = rand 2 = 0
  ; autopull = rand 3 = 0
  ; autopush = rand 3 = 0
  ; crc_poly = (rand 65536 lsl 16) lor rand 65536
  ; crc_init = (rand 65536 lsl 16) lor rand 65536
  ; crc_invert = rand 2 = 0
  ; crc_in = rand 2 = 0
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
  let word () =
    let w = rand 65536 in
    if rand 4 = 0 then w else w land lnot (0xF lsl 9)
  in
  (* A different program in each thread's memory. *)
  let words =
    Array.init Rtl.num_threads ~f:(fun _ -> Array.init Isa.program_size ~f:(fun _ -> word ()))
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
  (* A third of the trials read every pin through the synchroniser, a third
     bypass it on every pin, a third on a random subset. *)
  let sync_bypass =
    match rand 3 with
    | 0 -> 0
    | 1 -> 0xFF
    | _ -> rand 256
  in
  (* The packet buffer: left alone in half the trials, playing a few words
     into a thread or recording from one in the rest, anywhere in the
     memory, its end included. The host then acts on it at random. *)
  let buffer =
    let mode : Isa.Buffer_mode.t =
      match rand 4 with
      | 0 -> Play
      | 1 -> Record
      | _ -> Off
    in
    let length = rand 24 in
    { Scenario.mode
    ; thread = rand Rtl.num_threads
    ; first = (if rand 4 = 0 then Isa.buffer_size - 1 - rand 8 else rand Isa.buffer_size)
    ; loaded = List.init length ~f:(fun _ -> rand 65536)
    ; length
    ; script = []
    ; random = true
    }
  in
  (* The bit sampler: off in half the trials, on from the start in the
     rest, and rewritten by the host now and then in all of them. Half the
     trials hold each pin's level for a few samples at a time. *)
  let sampler = if rand 2 = 0 then Isa.Sampler_config.off else random_sampler rs in
  let pins = if rand 2 = 0 then Scenario.Random_pins else Random_runs in
  ( { Scenario.name = sprintf "random #%d" (seed + 1)
    ; words
    ; configs
    ; modes
    ; chain
    ; sync_bypass
    ; enabled
    ; enables = Random_flips
    ; writes = []
    ; rates
    ; buffer
    ; sampler
    ; sampler_random = true
    ; pins
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
    let level = (Isa.seen_lines model ~inputs lsr pin) land 1 = 1 in
    if Bool.equal level polarity
    then "wait: condition met"
    else if timeout && (if th.waiting then th.wait_count else th.config.timeout) = 0
    then "wait: timed out"
    else if timeout
    then "wait: stalled, spending timeout budget"
    else "wait: stalled"
  | In { count; _ } when th.config.autopush && th.isr_count + count >= th.config.threshold ->
    if Queue.length th.rx_fifo >= Isa.fifo_depth
    then "in: waiting, RX full (autopush)"
    else "in: filled the ISR and pushed it (autopush)"
  | Out _ when th.config.autopull && th.osr_count >= th.config.threshold ->
    if Queue.is_empty th.tx_fifo
    then "out: waiting for a word (autopull)"
    else "out: fetched a word (autopull)"
  | Out { count; _ }
    when th.config.autopull
         && th.osr_count + count >= th.config.threshold
         && not (Queue.is_empty th.tx_fifo) -> "out: emptied the OSR and refilled it (autopull)"
  | In { src; _ } -> "in " ^ Isa.In_src.to_string src
  | Out { dst; _ } -> "out " ^ Isa.Out_dst.to_string dst
  | Push ->
    if Queue.length th.rx_fifo >= Isa.fifo_depth then "push: stalled, RX full" else "push"
  | Pull -> if Queue.is_empty th.tx_fifo then "pull: stalled, TX empty" else "pull"
  | Mov { dst; src = Crc } when not (Isa.Mov_loc.equal dst Crc) -> "mov from crc"
  | Mov { dst; src = _ } -> "mov to " ^ Isa.Mov_loc.to_string dst
  | Set { dst; _ } -> "set " ^ Isa.Set_dst.to_string dst
  | Nop when raw_op = 5 -> "mov (reserved -> nop)"
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
    let word = words.(n).(th.pc) in
    add
      (if not th.enabled
       then "(thread disabled)"
       else if th.loaded
       then "(held: memory written last cycle)"
       else if th.div_count > 0
       then "(between divider ticks)"
       else if th.delay_left > 0
       then "(delay cycle)"
       else classify model ~thread:n ~word ~inputs);
    let mask, executing = pin_writes th (Isa.Instruction.decode word) in
    if executing && th.config.sideset_count > 0 then add "(side-set driving pins)";
    if mask <> 0 then incr drivers;
    (* A thread looking at what the bit sampler shows: a WAIT on either of
       its two pins, or an IN from pins whose first pin is its data pin. *)
    let smp = model.sampler in
    if executing && smp.config.enable
    then (
      let data_pin = (smp.config.pin + smp.config.shift) % Isa.num_pins in
      let pulse_pin = (data_pin + 1) % Isa.num_pins in
      let looked what =
        add what;
        if smp.config.shift <> 0 then add "(sampler: looked at on pins shifted from its input)"
      in
      match (Isa.Instruction.decode word).op with
      | Wait { pin; _ } when pin = pulse_pin ->
        looked (if smp.strobe then "(sampler: a WAIT sees its pulse)" else "(sampler: a WAIT sees no pulse)")
      | Wait { pin; _ } when pin = data_pin -> looked "(sampler: a WAIT looks at its bit)"
      | In { src = Pins; _ } when th.config.in_base = data_pin -> looked "(sampler: an IN takes its bit)"
      | _ -> ())
  done;
  let t0 = Isa.thread model 0
  and t1 = Isa.thread model 1 in
  if chain && (not (Queue.is_empty t0.rx_fifo)) && Queue.length t1.tx_fifo < Isa.fifo_depth
  then add "(chain moved a word)";
  if chain && Queue.length t1.tx_fifo >= Isa.fifo_depth && not (Queue.is_empty t0.rx_fifo)
  then add "(chain blocked: thread 1 TX full)";
  if !drivers = 2 then add "(both threads drive pins in one cycle)";
  if t0.enabled && t1.enabled then add "(both threads enabled)";
  (* The packet buffer, from the rules in the model's [step]. *)
  let th = Isa.thread model model.buffer_thread in
  let at_end = model.buffer_ptr = model.buffer_end in
  (match model.buffer_mode with
   | Off -> ()
   | Play when chain && model.buffer_thread = 1 -> add "(buffer: the chain owns that FIFO)"
   | Record when chain && model.buffer_thread = 0 -> add "(buffer: the chain owns that FIFO)"
   | (Play | Record) when at_end -> add "(buffer: at its end)"
   | Play when model.buffer_wrote -> add "(buffer: no play in the cycle after a write)"
   | Play when Queue.length th.tx_fifo >= Isa.fifo_depth -> add "(buffer: play waits, TX full)"
   | Play -> add "(buffer played a word)"
   | Record when Queue.is_empty th.rx_fifo -> ()
   | Record -> add "(buffer recorded a word)");
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
      let word = words.(n).(th.pc) in
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
  (* The host rewrites words as the trial runs, so keep its own copy. *)
  let words = Array.map s.words ~f:Array.copy in
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
    set ti.clkdiv config.clkdiv;
    set ti.out_msb_first (Bool.to_int config.out_msb_first);
    set ti.in_msb_first (Bool.to_int config.in_msb_first);
    set ti.autopull (Bool.to_int config.autopull);
    set ti.autopush (Bool.to_int config.autopush);
    set ti.crc_poly config.crc_poly;
    set ti.crc_init config.crc_init;
    set ti.crc_invert (Bool.to_int config.crc_invert);
    set ti.crc_in (Bool.to_int config.crc_in));
  set i.chain (Bool.to_int s.chain);
  set i.sync_bypass s.sync_bypass;
  set
    i.pin_modes
    (Array.foldi s.modes ~init:0 ~f:(fun p acc m -> acc lor (mode_code m lsl (2 * p))));
  Array.iteri words ~f:(fun n memory ->
    Array.iteri memory ~f:(fun a w ->
      set i.prog_we (1 lsl n);
      set i.prog_addr a;
      set i.prog_data w;
      Cyclesim.cycle sim));
  set i.prog_we 0;
  (* The packet buffer as the scenario starts it: the host points it at
     [first], stores [loaded], and points it back. *)
  let b = s.buffer in
  let point_at v =
    set i.buf_set_ptr 1;
    set i.buf_ptr_in v;
    Cyclesim.cycle sim;
    set i.buf_set_ptr 0
  in
  point_at b.first;
  List.iter b.loaded ~f:(fun w ->
    set i.buf_write 1;
    set i.buf_data w;
    Cyclesim.cycle sim);
  set i.buf_write 0;
  point_at b.first;
  (* One cycle with no write, so that the hold after the last one is over. *)
  Cyclesim.cycle sim;
  let model =
    Isa.create_separate
      ~programs:(Array.map words ~f:(Array.map ~f:Isa.Instruction.decode))
      ~pin_modes:s.modes
      ~threads:s.configs
  in
  Isa.set_chain model s.chain;
  Isa.set_sync_bypass model s.sync_bypass;
  (* The hardware's synchroniser has been sampling the pin inputs (held at
     0) all through configuration and program loading, so by now it holds
     0, not its reset value. Start the model's in the same place. The first
     version of this harness missed that, and the test caught the model and
     the RTL disagreeing about a pin on cycle 0. *)
  model.sync1 <- 0;
  model.sync2 <- 0;
  Isa.set_buffer_ptr model b.first;
  List.iter b.loaded ~f:(Isa.write_buffer model);
  Isa.set_buffer_ptr model b.first;
  model.buffer_wrote <- false;
  (* The buffer's mode, thread and end are levels the host holds. *)
  let buf_mode = ref b.mode
  and buf_thread = ref b.thread
  and buf_end = ref ((b.first + b.length) % Isa.buffer_size) in
  (* The sampler's registers are levels the host holds too. *)
  let sampler = ref s.sampler in
  let runs = ref 0 in
  let rec loop cycle =
    if cycle >= s.cycles
    then None
    else (
      (* The pins at the falling edge in the middle of this cycle and at the
         rising edge that ends it. *)
      let pins_mid, pins =
        match s.pins with
        | Random_pins ->
          let mid = rand 256 in
          mid, rand 256
        | Random_runs ->
          let half () =
            for p = 0 to Isa.num_pins - 1 do
              if rand 5 = 0 then runs := !runs lxor (1 lsl p)
            done;
            !runs
          in
          let mid = half () in
          mid, half ()
        | Wave w -> if cycle < Array.length w then w.(cycle) else 0, 0
        | Constant v -> v, v
        | Square { period; mask } ->
          let v = if cycle / period % 2 = 0 then mask else 0 in
          v, v
      in
      set i.pins_in pins;
      if s.sampler_random && rand 60 = 0 then sampler := random_sampler rs;
      (let c = !sampler in
       Isa.set_sampler model c;
       set i.smp.enable (Bool.to_int c.enable);
       set i.smp.pin c.pin;
       set i.smp.invert (Bool.to_int c.invert);
       set i.smp.sync_enable (Bool.to_int c.sync_enable);
       set i.smp.misses c.misses;
       set i.smp.blank c.blank;
       set i.smp.sample c.sample;
       set i.smp.wrap c.wrap;
       set i.smp.sync c.sync;
       set i.smp.prescale c.prescale;
       set i.smp.shift c.shift;
       set i.smp.stuff c.stuff;
       (* The top level's falling-edge flip-flop: the sampler's own pin. *)
       set i.smp.fall ((pins_mid lsr c.pin) land 1));
      let pcs_before = List.init Rtl.num_threads ~f:(fun n -> (Isa.thread model n).pc) in
      (* What the host does to the packet buffer this cycle, if anything. It
         never reads in the cycle after a write: the host port takes dozens
         of cycles for each access, and the buffer has not read the word
         out yet. *)
      let buffer_action : Scenario.buffer_action option =
        match List.Assoc.find b.script cycle ~equal:Int.equal with
        | Some a -> Some a
        | None when b.random && model.buffer_wrote && rand 3 = 0 ->
          (* Straight after a write, often set it playing: the cycle in
             which nothing may be played yet. Left to chance this came up
             once or twice in 400 trials. *)
          Some (Mode (Play, rand Rtl.num_threads))
        | None when b.random && rand 25 = 0 ->
          (match rand 6 with
           | 0 ->
             Some
               (Mode
                  ( (match rand 3 with
                     | 0 -> Off
                     | 1 -> Play
                     | _ -> Record)
                  , rand Rtl.num_threads ))
           | 1 -> Some (Ptr (rand Isa.buffer_size))
           | 2 -> Some (End ((model.buffer_ptr + rand 16) % Isa.buffer_size))
           | 3 | 4 -> Some (Write (rand 65536))
           | _ -> if model.buffer_wrote then None else Some Read)
        | None -> None
      in
      (match buffer_action with
       | Some (Mode (m, t)) ->
         buf_mode := m;
         buf_thread := t
       | Some (End v) -> buf_end := v
       | _ -> ());
      Isa.set_buffer model ~mode:!buf_mode ~thread:!buf_thread;
      Isa.set_buffer_end model !buf_end;
      set
        i.buf_mode
        (match !buf_mode with
         | Off -> 0
         | Play -> 1
         | Record -> 2);
      set i.buf_thread !buf_thread;
      set i.buf_end !buf_end;
      set i.buf_set_ptr 0;
      set i.buf_write 0;
      set i.buf_read 0;
      (match buffer_action with
       | Some (Ptr v) ->
         set i.buf_set_ptr 1;
         set i.buf_ptr_in v
       | Some (Write v) ->
         set i.buf_write 1;
         set i.buf_data v
       | Some Read -> set i.buf_read 1
       | _ -> ());
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
      (* The host writes a word of program memory now and then: mostly to a
         thread that is stopped, which is when a write lands, and sometimes
         to a running one, which both implementations must ignore. Random
         trials only; a directed scenario's program stays as written. *)
      let write =
        match List.find s.writes ~f:(fun (c, _, _, _) -> c = cycle), s.enables with
        | Some (_, mask, addr, w), _ -> Some (mask, addr, w)
        | None, Script _ -> None
        | None, Random_flips ->
          let mask =
            List.foldi (Array.to_list enabled) ~init:0 ~f:(fun n acc e ->
              if rand (if e then 200 else 6) = 0 then acc lor (1 lsl n) else acc)
          in
          if mask = 0 then None else Some (mask, rand Isa.program_size, rand 65536)
      in
      (match write with
       | None -> set i.prog_we 0
       | Some (mask, addr, w) ->
         set i.prog_we mask;
         set i.prog_addr addr;
         set i.prog_data w);
      Option.iter coverage ~f:(fun c ->
        List.iter (basic_bins model ~words ~chain:s.chain ~inputs:pins) ~f:(Hashtbl.incr c.basic);
        List.iter (cross_bins model ~words ~chain:s.chain ~inputs:pins) ~f:(Hashtbl.incr c.cross);
        Option.iter write ~f:(fun (mask, _, _) ->
          Array.iteri enabled ~f:(fun n e ->
            if mask land (1 lsl n) <> 0
            then
              Hashtbl.incr
                c.basic
                (if e
                 then "(program write to a running thread: ignored)"
                 else "(program write to a stopped thread)"))));
      let events_before = Hashtbl.copy model.sampler.events in
      Cyclesim.cycle sim;
      Isa.step model ~inputs_mid:pins_mid ~inputs:pins;
      Option.iter coverage ~f:(fun c ->
        Hashtbl.iteri model.sampler.events ~f:(fun ~key ~data ->
          let before = Option.value (Hashtbl.find events_before key) ~default:0 in
          if data > before then Hashtbl.incr c.basic ~by:(data - before) (sprintf "(sampler: %s)" key)));
      Option.iter write ~f:(fun (mask, addr, w) ->
        for n = 0 to Rtl.num_threads - 1 do
          if mask land (1 lsl n) <> 0
             && Isa.write_program model ~thread:n ~addr (Isa.Instruction.decode w)
          then words.(n).(addr) <- w
        done);
      let popped =
        List.mapi host ~f:(fun n (push, push_value, pop) ->
          (* The host's push and pop are refused at the chained ends. *)
          let buffers (mode : Isa.Buffer_mode.t) =
            Isa.Buffer_mode.equal !buf_mode mode && !buf_thread = n
          in
          let push_ok = if push then Isa.push_tx model ~thread:n push_value else false in
          if push && not push_ok then assert ((s.chain && n = 1) || buffers Play);
          let model_popped = if pop then Isa.pop_rx model ~thread:n else None in
          let rtl_popped =
            Option.some_if
              (pop && (not (s.chain && n = 0)) && not (buffers Record))
              (get (Rtl.O.thread o_before n).rx_data)
          in
          model_popped, rtl_popped)
      in
      (* The host's buffer action on the model, after the step like its
         other actions; a read is compared with the word the hardware
         showed during the cycle. *)
      let model_read, rtl_read =
        match buffer_action with
        | Some (Ptr v) ->
          Isa.set_buffer_ptr model v;
          None, None
        | Some (Write v) ->
          Isa.write_buffer model v;
          None, None
        | Some Read ->
          let got = Isa.read_buffer model in
          got, Option.map got ~f:(fun _ -> get o_before.buf_word)
        | _ -> None, None
      in
      let rtl_thread n =
        let t = Rtl.O.thread o n in
        { pc = get t.pc
        ; page = get t.page
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
        ; crc = get t.crc
        ; crc_run = get t.crc_run = 1
        ; tx_level = get t.tx_level
        ; rx_level = get t.rx_level
        ; popped = snd (List.nth_exn popped n)
        }
      in
      let model_thread n =
        let th = Isa.thread model n in
        { pc = th.pc
        ; page = th.page
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
        ; crc = th.crc
        ; crc_run = th.crc_run
        ; tx_level = Queue.length th.tx_fifo
        ; rx_level = Queue.length th.rx_fifo
        ; popped = fst (List.nth_exn popped n)
        }
      in
      let rtl_smp =
        let q = o.smp.state in
        { mid = get o.smp.mid = 1
        ; last = get q.last = 1
        ; phase = get q.phase
        ; missed = get q.missed
        ; carrier = get q.carrier = 1
        ; synced = get q.synced = 1
        ; history = get q.history
        ; pre = get q.pre
        ; run = get q.run
        ; slevel = get q.slevel = 1
        ; data = get q.data = 1
        ; strobe = get o.smp.strobe = 1
        }
      in
      let model_smp =
        let q = model.sampler in
        { mid = q.mid
        ; last = q.last
        ; phase = q.phase
        ; missed = q.missed
        ; carrier = q.carrier
        ; synced = q.synced
        ; history = q.history
        ; pre = q.pre
        ; run = q.run
        ; slevel = q.slevel
        ; data = q.data
        ; strobe = q.strobe
        }
      in
      let rtl =
        { pin_out = get o.pin_out
        ; buf_ptr = get o.buf_ptr
        ; buf_read = rtl_read
        ; smp = rtl_smp
        ; t0 = rtl_thread 0
        ; t1 = rtl_thread 1
        }
      in
      let expected =
        { pin_out = Isa.pin_out model
        ; buf_ptr = Isa.buffer_ptr model
        ; buf_read = model_read
        ; smp = model_smp
        ; t0 = model_thread 0
        ; t1 = model_thread 1
        }
      in
      if equal_state rtl expected
      then loop (cycle + 1)
      else (
        let instructions =
          List.mapi pcs_before ~f:(fun n pc ->
            pc, Isa.Instruction.to_string (Isa.Instruction.decode words.(n).(pc)))
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
