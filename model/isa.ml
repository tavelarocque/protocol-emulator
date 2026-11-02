(* Executable reference model of the protocol-emulator ISA.

   This is the specification in code form: docs/isa.md describes it in prose,
   and every hardware implementation of the core is checked against this
   module cycle for cycle. It is written for clarity, not speed, and has no
   dependency on the hardware so it cannot share the hardware's bugs.

   Decoding is total: every 16-bit word is a valid instruction (reserved
   encodings decode to NOP). That lets the hardware be differentially tested
   on uniformly random program memory, not just on programs we thought of. *)

open! Core

let program_size = 64
let num_pins = 8
let fifo_depth = 4
let word_bits = 16
let word_mask = (1 lsl word_bits) - 1
let mask n = (1 lsl n) - 1

(* Small enums are encoded by their position in [all]. *)
let index_of ~all ~equal t =
  fst (Option.value_exn (List.findi all ~f:(fun _ x -> equal x t)))
;;

let nth_opt all n = List.nth all n

module Cond = struct
  type t =
    | Always
    | X_zero
    | X_dec
    | Y_zero
    | Y_dec
    | X_ne_y
    | Osr_not_empty
    | Isr_not_full
  [@@deriving sexp_of, compare, equal, enumerate]

  let to_int = index_of ~all ~equal
  let of_int n = Option.value_exn (nth_opt all n)

  let to_string = function
    | Always -> ""
    | X_zero -> "!x"
    | X_dec -> "x--"
    | Y_zero -> "!y"
    | Y_dec -> "y--"
    | X_ne_y -> "x!=y"
    | Osr_not_empty -> "!osre"
    | Isr_not_full -> "!isrf"
  ;;
end

module In_src = struct
  type t =
    | Pins
    | X
    | Y
    | Zeros
  [@@deriving sexp_of, compare, equal, enumerate]

  let to_int = index_of ~all ~equal
  let of_int n = Option.value_exn (nth_opt all n)

  let to_string = function
    | Pins -> "pins"
    | X -> "x"
    | Y -> "y"
    | Zeros -> "null"
  ;;
end

module Out_dst = struct
  type t =
    | Pins
    | X
    | Y
    | Null
  [@@deriving sexp_of, compare, equal, enumerate]

  let to_int = index_of ~all ~equal
  let of_int n = Option.value_exn (nth_opt all n)

  let to_string = function
    | Pins -> "pins"
    | X -> "x"
    | Y -> "y"
    | Null -> "null"
  ;;
end

module Set_dst = struct
  (* Encoding 3 is reserved and decodes the whole instruction as NOP. *)
  type t =
    | Pins
    | X
    | Y
  [@@deriving sexp_of, compare, equal, enumerate]

  let to_int = index_of ~all ~equal
  let of_int n = nth_opt all n

  let to_string = function
    | Pins -> "pins"
    | X -> "x"
    | Y -> "y"
  ;;
end

module Mov_loc = struct
  (* Encodings 6 and 7 are reserved and decode the whole instruction as NOP. *)
  type t =
    | X
    | Y
    | Pins
    | Isr
    | Osr
    | Null
  [@@deriving sexp_of, compare, equal, enumerate]

  let to_int = index_of ~all ~equal
  let of_int n = nth_opt all n

  let to_string = function
    | X -> "x"
    | Y -> "y"
    | Pins -> "pins"
    | Isr -> "isr"
    | Osr -> "osr"
    | Null -> "null"
  ;;
end

module Instruction = struct
  type op =
    | Jmp of
        { cond : Cond.t
        ; addr : int
        }
    | Wait of
        { polarity : bool
        ; pin : int
        ; timeout : bool
        }
    | In of
        { src : In_src.t
        ; count : int
        }
    | Out of
        { dst : Out_dst.t
        ; count : int
        }
    | Push
    | Pull
    | Mov of
        { dst : Mov_loc.t
        ; src : Mov_loc.t
        }
    | Set of
        { dst : Set_dst.t
        ; value : int
        }
    | Nop
  [@@deriving sexp_of, compare, equal]

  type t =
    { op : op
    ; delay : int
    }
  [@@deriving sexp_of, compare, equal]

  let max_delay = 15

  let check name v ~lo ~hi =
    if v < lo || v > hi
    then raise_s [%message "field out of range" (name : string) (v : int) (lo : int) (hi : int)]
  ;;

  (* Layout: [15:13] opcode, [12:9] delay, [8:0] operands. *)
  let encode { op; delay } =
    check "delay" delay ~lo:0 ~hi:max_delay;
    let b = Bool.to_int in
    let opcode, arg =
      match op with
      | Jmp { cond; addr } ->
        check "addr" addr ~lo:0 ~hi:(program_size - 1);
        0, (Cond.to_int cond lsl 6) lor addr
      | Wait { polarity; pin; timeout } ->
        check "pin" pin ~lo:0 ~hi:(num_pins - 1);
        1, (b polarity lsl 8) lor (pin lsl 5) lor (b timeout lsl 4)
      | In { src; count } ->
        check "count" count ~lo:1 ~hi:word_bits;
        2, (In_src.to_int src lsl 7) lor (count land 15)
      | Out { dst; count } ->
        check "count" count ~lo:1 ~hi:word_bits;
        3, (Out_dst.to_int dst lsl 7) lor (count land 15)
      | Push -> 4, 0
      | Pull -> 4, 1 lsl 8
      | Mov { dst; src } -> 5, (Mov_loc.to_int dst lsl 6) lor (Mov_loc.to_int src lsl 3)
      | Set { dst; value } ->
        check "value" value ~lo:0 ~hi:31;
        6, (Set_dst.to_int dst lsl 7) lor value
      | Nop -> 7, 0
    in
    (opcode lsl 13) lor (delay lsl 9) lor arg
  ;;

  let decode w =
    let bits hi lo = (w lsr lo) land mask (hi - lo + 1) in
    let count () = if bits 3 0 = 0 then 16 else bits 3 0 in
    let op =
      match bits 15 13 with
      | 0 -> Jmp { cond = Cond.of_int (bits 8 6); addr = bits 5 0 }
      | 1 -> Wait { polarity = bits 8 8 = 1; pin = bits 7 5; timeout = bits 4 4 = 1 }
      | 2 -> In { src = In_src.of_int (bits 8 7); count = count () }
      | 3 -> Out { dst = Out_dst.of_int (bits 8 7); count = count () }
      | 4 -> if bits 8 8 = 1 then Pull else Push
      | 5 ->
        (match Mov_loc.of_int (bits 8 6), Mov_loc.of_int (bits 5 3) with
         | Some dst, Some src -> Mov { dst; src }
         | _ -> Nop)
      | 6 ->
        (match Set_dst.of_int (bits 8 7) with
         | Some dst -> Set { dst; value = bits 4 0 }
         | None -> Nop)
      | _ -> Nop
    in
    { op; delay = bits 12 9 }
  ;;

  (* Disassembly, in the same syntax the assembler accepts. *)
  let to_string { op; delay } =
    let body =
      match op with
      | Jmp { cond = Always; addr } -> sprintf "jmp %d" addr
      | Jmp { cond; addr } -> sprintf "jmp %s %d" (Cond.to_string cond) addr
      | Wait { polarity; pin; timeout } ->
        sprintf
          "wait %d pin %d%s"
          (Bool.to_int polarity)
          pin
          (if timeout then " timeout" else "")
      | In { src; count } -> sprintf "in %s, %d" (In_src.to_string src) count
      | Out { dst; count } -> sprintf "out %s, %d" (Out_dst.to_string dst) count
      | Push -> "push"
      | Pull -> "pull"
      | Mov { dst; src } ->
        sprintf "mov %s, %s" (Mov_loc.to_string dst) (Mov_loc.to_string src)
      | Set { dst; value } -> sprintf "set %s, %d" (Set_dst.to_string dst) value
      | Nop -> "nop"
    in
    if delay = 0 then body else sprintf "%s [%d]" body delay
  ;;
end

module Pin_mode = struct
  type t =
    | Input
    | Push_pull
    | Open_drain (* writing 0 drives low, writing 1 releases the line *)
  [@@deriving sexp_of, compare, equal]
end

(* Per-thread configuration, written by the host before the thread is
   enabled. *)
module Thread_config = struct
  type t =
    { start : int
    ; out_base : int
    ; out_count : int
    ; set_base : int
    ; set_count : int
    ; in_base : int
    ; threshold : int (* bits per OSR/ISR word, 1..16 *)
    ; timeout_vector : int
    ; timeout : int (* max cycles a [wait ... timeout] stalls, 0..65535 *)
    ; sideset_base : int (* first side-set pin *)
    ; sideset_count : int
      (* 0..3: how many of the delay field's top bits are side-set values *)
    ; clkdiv : int
      (* 0..65535: the thread executes one cycle in every [clkdiv]; 0 and 1
         both mean every cycle *)
    ; out_msb_first : bool
      (* OUT takes bits from the top of the OSR and shifts it left *)
    ; in_msb_first : bool
      (* IN shifts the ISR left, new bits entering at the bottom *)
    }
  [@@deriving sexp_of]

  let default =
    { start = 0
    ; out_base = 0
    ; out_count = 1
    ; set_base = 0
    ; set_count = 1
    ; in_base = 0
    ; threshold = 8
    ; timeout_vector = 0
    ; timeout = 0
    ; sideset_base = 0
    ; sideset_count = 0
    ; clkdiv = 0
    ; out_msb_first = false
    ; in_msb_first = false
    }
  ;;
end

module Thread = struct
  type t =
    { config : Thread_config.t
    ; mutable pc : int
    ; mutable x : int
    ; mutable y : int
    ; mutable isr : int
    ; mutable isr_count : int
    ; mutable osr : int
    ; mutable osr_count : int (* bits shifted out since the last refill *)
    ; mutable delay_left : int
    ; mutable waiting : bool (* stalled in a [wait ... timeout] *)
    ; mutable wait_count : int (* ticks of that wait's budget left *)
    ; mutable div_count : int (* cycles until the thread's next tick *)
    ; tx_fifo : int Queue.t (* host -> thread *)
    ; rx_fifo : int Queue.t (* thread -> host *)
    ; mutable enabled : bool
      (* a disabled thread is held in its initial state; its FIFOs keep
         their contents *)
    }

  (* The state a thread starts in, and is held in while disabled. *)
  let reset t =
    t.pc <- t.config.start;
    t.x <- 0;
    t.y <- 0;
    t.isr <- 0;
    t.isr_count <- 0;
    t.osr <- 0;
    t.osr_count <- t.config.threshold (* OSR starts empty *);
    t.delay_left <- 0;
    t.waiting <- false;
    t.wait_count <- 0;
    t.div_count <- 0
  ;;

  let create (config : Thread_config.t) =
    { config
    ; pc = config.start
    ; x = 0
    ; y = 0
    ; isr = 0
    ; isr_count = 0
    ; osr = 0
    ; osr_count = config.threshold (* OSR starts empty *)
    ; delay_left = 0
    ; waiting = false
    ; wait_count = 0
    ; div_count = 0
    ; tx_fifo = Queue.create ()
    ; rx_fifo = Queue.create ()
    ; enabled = true
    }
  ;;
end

type t =
  { program : Instruction.t array
  ; pin_modes : Pin_mode.t array
  ; threads : Thread.t array
  ; mutable sync_bypass : int
    (* pins whose inputs skip the 2-flop synchroniser; see [seen_inputs] *)
  ; mutable sync1 : int (* the synchroniser's two stages *)
  ; mutable sync2 : int
  ; mutable chain : bool
    (* thread 0's RX FIFO feeds thread 1's TX FIFO, one word per cycle *)
  ; mutable pin_out : int
  ; mutable cycle : int
  }

let create ~program ~pin_modes ~threads =
  if Array.length program > program_size
  then raise_s [%message "program too long" (Array.length program : int)];
  if Array.length pin_modes <> num_pins then raise_s [%message "need one mode per pin"];
  if List.is_empty threads || List.length threads > 2
  then raise_s [%message "1 or 2 threads"];
  (* Unwritten program memory resets to 0, which decodes as "jmp 0". *)
  let program =
    Array.init program_size ~f:(fun i ->
      if i < Array.length program then program.(i) else Instruction.decode 0)
  in
  { program
  ; pin_modes = Array.copy pin_modes
  ; threads = Array.of_list_map threads ~f:Thread.create
  ; sync_bypass = 0
  ; sync1 = mask num_pins (* reset high, like the idle bus *)
  ; sync2 = mask num_pins
  ; chain = false
  ; pin_out = mask num_pins (* all high: idle for UART, released for open-drain *)
  ; cycle = 0
  }
;;

let thread t i = t.threads.(i)
let pin_out t = t.pin_out
let cycle t = t.cycle

(* The level on each physical pin, given what is driving it from outside.
   This is the wire, as a logic analyser would see it. *)
let lines t ~inputs =
  List.init num_pins ~f:(fun i ->
    let ext = (inputs lsr i) land 1 in
    let out = (t.pin_out lsr i) land 1 in
    let level =
      match t.pin_modes.(i) with
      | Input -> ext
      | Push_pull -> out
      | Open_drain -> out land ext
    in
    level lsl i)
  |> List.fold ~init:0 ~f:( lor )
;;

let write_pins pin_out ~base ~count v =
  let r = ref pin_out in
  for k = 0 to min count num_pins - 1 do
    let p = (base + k) % num_pins in
    r := !r land lnot (1 lsl p) lor (((v lsr k) land 1) lsl p)
  done;
  !r
;;

let read_pins lines ~base ~count =
  let r = ref 0 in
  for k = 0 to min count num_pins - 1 do
    r := !r lor (((lines lsr ((base + k) % num_pins)) land 1) lsl k)
  done;
  !r
;;

let eval_cond (th : Thread.t) (cond : Cond.t) =
  match cond with
  | Always -> true
  | X_zero -> th.x = 0
  | X_dec ->
    let r = th.x <> 0 in
    th.x <- (th.x - 1) land word_mask;
    r
  | Y_zero -> th.y = 0
  | Y_dec ->
    let r = th.y <> 0 in
    th.y <- (th.y - 1) land word_mask;
    r
  | X_ne_y -> th.x <> th.y
  | Osr_not_empty -> th.osr_count < th.config.threshold
  | Isr_not_full -> th.isr_count < th.config.threshold
;;

(* One tick of a thread: count down a delay, or execute an instruction. *)
let tick t (th : Thread.t) ~lines_now ~pin_out =
  if th.delay_left > 0
  then th.delay_left <- th.delay_left - 1
  else (
    let cfg = th.config in
    let instr = t.program.(th.pc) in
    (* Side-set: the top [sideset_count] bits of the 4-bit delay field are
       values for the side-set pins; the rest is the delay. *)
    let n = cfg.sideset_count in
    let side = instr.delay lsr (4 - n) in
    let delay = instr.delay land mask (4 - n) in
    let result =
      match instr.op with
      | Nop -> `Next
      | Jmp { cond; addr } -> if eval_cond th cond then `Goto addr else `Next
      | Wait { polarity; pin; timeout } ->
        let level = (lines_now lsr pin) land 1 = 1 in
        if Bool.equal level polarity
        then `Next
        else if not timeout
        then `Stall
        else (
          (* The budget is loaded from the thread's TIMEOUT register when the
             wait starts, and counts down while it stalls. X and Y are left
             alone, so firmware can keep using them for bit timing. *)
          let budget = if th.waiting then th.wait_count else cfg.timeout in
          if budget = 0
          then `Goto cfg.timeout_vector
          else (
            th.waiting <- true;
            th.wait_count <- budget - 1;
            `Stall))
      | In { src; count } ->
        let v =
          match src with
          | Pins -> read_pins lines_now ~base:cfg.in_base ~count
          | X -> th.x
          | Y -> th.y
          | Zeros -> 0
        in
        let data = v land mask count in
        (* LSB first: new bits enter at the top and the ISR shifts right,
           so the first bit in ends up least significant once pushed. MSB
           first: they enter at the bottom and it shifts left, so the first
           bit in ends up most significant. *)
        th.isr
        <- (if cfg.in_msb_first
            then (th.isr lsl count) lor data
            else (th.isr lsr count) lor (data lsl (word_bits - count)))
           land word_mask;
        th.isr_count <- min word_bits (th.isr_count + count);
        `Next
      | Out { dst; count } ->
        let data, rest =
          if cfg.out_msb_first
          then (th.osr lsr (word_bits - count)) land mask count, (th.osr lsl count) land word_mask
          else th.osr land mask count, th.osr lsr count
        in
        th.osr <- rest;
        th.osr_count <- min word_bits (th.osr_count + count);
        (match dst with
         | Pins -> pin_out := write_pins !pin_out ~base:cfg.out_base ~count data
         | X -> th.x <- data
         | Y -> th.y <- data
         | Null -> ());
        `Next
      | Pull ->
        (match Queue.dequeue th.tx_fifo with
         | None -> `Stall
         | Some v ->
           th.osr <- v land word_mask;
           th.osr_count <- 0;
           `Next)
      | Push ->
        if Queue.length th.rx_fifo >= fifo_depth
        then `Stall
        else (
          (* The bits shifted in since the last push, right-justified: for
             LSB first they sit at the top of the ISR, for MSB first at the
             bottom. *)
          let v =
            if th.isr_count = 0
            then 0
            else if cfg.in_msb_first
            then th.isr land mask th.isr_count
            else th.isr lsr (word_bits - th.isr_count)
          in
          Queue.enqueue th.rx_fifo v;
          th.isr <- 0;
          th.isr_count <- 0;
          `Next)
      | Mov { dst; src } ->
        let v =
          match src with
          | X -> th.x
          | Y -> th.y
          | Pins -> lines_now
          | Isr -> th.isr
          | Osr -> th.osr
          | Null -> 0
        in
        (match dst with
         | X -> th.x <- v
         | Y -> th.y <- v
         | Pins -> pin_out := write_pins !pin_out ~base:cfg.out_base ~count:cfg.out_count v
         | Isr ->
           th.isr <- v;
           th.isr_count <- 0
         | Osr ->
           th.osr <- v;
           th.osr_count <- 0
         | Null -> ());
        `Next
      | Set { dst; value } ->
        (match dst with
         | Pins ->
           pin_out := write_pins !pin_out ~base:cfg.set_base ~count:cfg.set_count value
         | X -> th.x <- value
         | Y -> th.y <- value);
        `Next
    in
    (* Side-set pins are driven on every cycle the instruction executes,
       stalled or not, and win over the instruction's own pin write. *)
    pin_out := write_pins !pin_out ~base:cfg.sideset_base ~count:n side;
    match result with
    | `Stall -> ()
    | `Next ->
      th.waiting <- false;
      th.pc <- (th.pc + 1) % program_size;
      th.delay_left <- delay
    | `Goto addr ->
      th.waiting <- false;
      th.pc <- addr;
      th.delay_left <- delay)
;;

let exec t (th : Thread.t) ~lines_now ~pin_out =
  if not th.enabled
  then Thread.reset th
  else if th.div_count > 0
  then
    (* The clock divider: between ticks the thread does nothing at all,
       so delays, wait timeouts and side-set all count in ticks. *)
    th.div_count <- th.div_count - 1
  else (
    th.div_count <- max 0 (th.config.clkdiv - 1);
    tick t th ~lines_now ~pin_out)
;;

(* One clock cycle. Every thread sees the same snapshot of the pins; pin
   writes take effect at the end of the cycle; if two threads write the same
   pin in the same cycle, the higher-numbered thread wins.

   With [chain] set, one word moves from thread 0's RX FIFO to thread 1's TX
   FIFO in any cycle that starts with the first non-empty and the second not
   full. Like every FIFO rule here it is judged at the start of the cycle,
   so a word thread 0 pushes is not available to thread 1 until the cycle
   after it moves. *)
(* What the threads see of the outside world this cycle. External inputs
   change with no relation to the core clock, so each one passes through two
   flip-flops before any logic uses it: a level that arrives during cycle t
   is seen by the threads in cycle t + 2. Pins in [sync_bypass] skip this
   and are seen in the same cycle, for protocols too fast for the delay
   (the side-set SPI controller's MISO); the host sets them only where the
   signal is known to be stable when sampled. The threads' own outputs, read
   back on push-pull and open-drain pins, are never delayed. *)
let seen_inputs t ~inputs =
  ((inputs land t.sync_bypass) lor (t.sync2 land lnot t.sync_bypass)) land mask num_pins
;;

let seen_lines t ~inputs = lines t ~inputs:(seen_inputs t ~inputs)

let step t ~inputs =
  let lines_now = seen_lines t ~inputs in
  let pin_out = ref t.pin_out in
  let move =
    t.chain
    && Array.length t.threads = 2
    && (not (Queue.is_empty t.threads.(0).rx_fifo))
    && Queue.length t.threads.(1).tx_fifo < fifo_depth
  in
  Array.iter t.threads ~f:(fun th -> exec t th ~lines_now ~pin_out);
  if move then Queue.enqueue t.threads.(1).tx_fifo (Queue.dequeue_exn t.threads.(0).rx_fifo);
  t.pin_out <- !pin_out;
  t.sync2 <- t.sync1;
  t.sync1 <- inputs land mask num_pins;
  t.cycle <- t.cycle + 1
;;

let set_sync_bypass t pins = t.sync_bypass <- pins land mask num_pins

(* Host side of the FIFOs. [push_tx] returns false if the FIFO is full.
   While [chain] is set the host cannot push to thread 1 or pop from thread
   0: those ends belong to the chain. *)
let chained t ~thread ~end_ =
  t.chain && Array.length t.threads = 2 && thread = (match end_ with `Tx -> 1 | `Rx -> 0)
;;

let push_tx t ~thread v =
  let q = t.threads.(thread).tx_fifo in
  if Queue.length q >= fifo_depth || chained t ~thread ~end_:`Tx
  then false
  else (
    Queue.enqueue q (v land word_mask);
    true)
;;

let pop_rx t ~thread =
  if chained t ~thread ~end_:`Rx then None else Queue.dequeue t.threads.(thread).rx_fifo
;;

let set_chain t b = t.chain <- b

(* Threads are enabled when created. While disabled, a thread is held in
   its initial state from the next step on, as the hardware's enable bit
   does. *)
let set_enabled t ~thread b = t.threads.(thread).enabled <- b
