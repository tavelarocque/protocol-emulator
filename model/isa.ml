(* Executable reference model of the protocol-emulator ISA.

   This is the specification in code form: docs/isa.md describes it in prose,
   and every hardware implementation of the core is checked against this
   module cycle for cycle. It is written for clarity, not speed, and has no
   dependency on the hardware so it cannot share the hardware's bugs.

   Decoding is total: every 16-bit word is a valid instruction (reserved
   encodings decode to NOP). That lets the hardware be differentially tested
   on uniformly random program memory, not just on programs we thought of. *)

open! Core

(* Each thread has its own program memory of [program_size] words. A jump
   reaches the [page_size] words of one page; see [Thread.page]. *)
let program_size = 256
let page_size = 64
let num_pages = program_size / page_size
let num_pins = 8
let fifo_depth = 4
let word_bits = 16
let word_mask = (1 lsl word_bits) - 1

(* The packet buffer: one memory of [buffer_size] words that can stand in
   for the host at one end of one thread's FIFOs; see [Buffer_mode]. *)
let buffer_size = 1024
let crc_bits = 32
let crc_mask = (1 lsl crc_bits) - 1
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
  type t =
    | Pins
    | X
    | Y
    | Page (* the thread's jump page; the value is taken modulo [num_pages] *)
  [@@deriving sexp_of, compare, equal, enumerate]

  let to_int = index_of ~all ~equal
  let of_int n = nth_opt all n

  let to_string = function
    | Pins -> "pins"
    | X -> "x"
    | Y -> "y"
    | Page -> "page"
  ;;
end

module Mov_loc = struct
  (* Encoding 7 is reserved and decodes the whole instruction as NOP. *)
  type t =
    | X
    | Y
    | Pins
    | Isr
    | Osr
    | Null
    | Crc
      (* the thread's CRC register. As a source: its low 16 bits, after
         which it holds its high 16 and stops following the data. As a
         destination: it starts again from its initial value, whatever the
         source. *)
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
    | Crc -> "crc"
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
        check "addr" addr ~lo:0 ~hi:(page_size - 1);
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
    ; autopull : bool
      (* an OUT that empties the OSR refills it from the TX FIFO in the same
         cycle, and an OUT that finds it empty waits for a word *)
    ; autopush : bool
      (* an IN that fills the ISR pushes it in the same cycle, and waits
         instead while the RX FIFO is full *)
    ; crc_poly : int
      (* the CRC register's polynomial, in the form used when the register
         shifts right: bit 0 is the coefficient of the highest power *)
    ; crc_init : int (* what the register starts from, 32 bits *)
    ; crc_invert : bool (* [mov ..., crc] reads the register inverted *)
    ; crc_in : bool (* the register follows the bits IN shifts in, not OUT's *)
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
    ; autopull = false
    ; autopush = false
    ; crc_poly = 0
    ; crc_init = 0
    ; crc_invert = false
    ; crc_in = false
    }
  ;;

  let crc_init t = t.crc_init land crc_mask
end

module Thread = struct
  type t =
    { config : Thread_config.t
    ; mutable pc : int
    ; mutable page : int
      (* A jump goes to [page * page_size + addr]. It starts as the page
         [start] is in and changes only by [set page]: not when the pc runs
         from one page into the next, and not on a timeout. *)
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
    ; mutable crc : int
    ; mutable crc_run : bool (* the CRC register is following the data *)
    ; tx_fifo : int Queue.t (* host -> thread *)
    ; rx_fifo : int Queue.t (* thread -> host *)
    ; mutable loaded : bool
      (* the host wrote this thread's memory in the last cycle; see
         [write_program] *)
    ; mutable enabled : bool
      (* a disabled thread is held in its initial state; its FIFOs keep
         their contents *)
    }

  (* The state a thread starts in, and is held in while disabled. *)
  let reset t =
    t.pc <- t.config.start;
    t.page <- t.config.start / page_size;
    t.x <- 0;
    t.y <- 0;
    t.isr <- 0;
    t.isr_count <- 0;
    t.osr <- 0;
    t.osr_count <- t.config.threshold (* OSR starts empty *);
    t.delay_left <- 0;
    t.waiting <- false;
    t.wait_count <- 0;
    t.div_count <- 0;
    t.crc <- Thread_config.crc_init t.config;
    t.crc_run <- true
  ;;

  let create (config : Thread_config.t) =
    { config
    ; pc = config.start
    ; page = config.start / page_size
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
    ; crc = Thread_config.crc_init config
    ; crc_run = true
    ; tx_fifo = Queue.create ()
    ; rx_fifo = Queue.create ()
    ; loaded = false
    ; enabled = true
    }
  ;;
end

(* What the packet buffer is doing. The host fills it or reads it back while
   it is [Off]. [Play] makes it the source of one thread's TX FIFO: while
   the pointer has not reached the end and that FIFO has room, one word a
   cycle moves from the buffer into it. [Record] makes it the sink of one
   thread's RX FIFO in the same way. The thread cannot tell: it pulls and
   pushes as it always did, with a host that never falls behind. *)
module Buffer_mode = struct
  type t =
    | Off
    | Play
    | Record
  [@@deriving sexp_of, compare, equal, enumerate]
end

(* The bit sampler: clock recovery for one input pin, in hardware, for line
   codes too fast for a thread to follow edge by edge. It looks at its pin
   twice per clock cycle, on both clock edges, so its three timing numbers
   count half cycles.

   It keeps a phase: the number of samples since the last edge it accepted.
   An edge is accepted, and the phase starts again from 0, if the phase had
   reached [blank]; edges before that are ignored. The sample taken at phase
   [sample] is a recovered bit. If the phase gets to [wrap] with no edge, a
   bit time has gone by without one: up to [misses] times in a row the phase
   starts again from 0 anyway and the bits keep coming at the pace of the
   last edge, and after that the carrier is lost and nothing more is
   recovered until the next edge. (With [misses] 7 it is never lost.)

   Manchester code has an edge in the middle of every bit and sometimes one
   between bits. With [blank] at three quarters of a bit the sampler locks
   to the middle edges and ignores the others, the level after each middle
   edge is the bit, and one bit time without an edge is the end of the
   frame: [misses] 0. NRZ code has edges only between bits, and not always:
   [blank] 0, [sample] half a bit, [wrap] one sample short of a bit, and as
   many [misses] as the code allows equal bits in a row.

   While the carrier is there the recovered bits shift through an 8-bit
   register, first bit ending up lowest. With [sync_enable], bits are passed
   on only after that register has held [sync]: for Ethernet 0xD5, the last
   byte before the frame. Each bit passed on shows on two pins as the
   threads see them, whatever those pins' modes: the bit itself on [pin],
   held until the next one, and a pulse one cycle long on the pin after it. *)
module Sampler_config = struct
  type t =
    { enable : bool
    ; pin : int (* 0..7: the input; the threads see the bit here and the pulse on the next pin *)
    ; invert : bool (* the recovered bit is the opposite of the sampled level *)
    ; sync_enable : bool
    ; misses : int (* 0..7 *)
    ; blank : int (* 0..31, in samples: half cycles *)
    ; sample : int (* 0..31 *)
    ; wrap : int (* 0..31 *)
    ; sync : int (* 8 bits, first bit lowest *)
    }
  [@@deriving sexp_of]

  let off =
    { enable = false
    ; pin = 0
    ; invert = false
    ; sync_enable = false
    ; misses = 0
    ; blank = 0
    ; sample = 0
    ; wrap = 0
    ; sync = 0
    }
  ;;
end

module Sampler = struct
  type t =
    { mutable config : Sampler_config.t
    ; mutable mid : bool
      (* the pin as it was at the falling clock edge in the middle of the
         last cycle; see [step] *)
    ; mutable last : bool (* the previous sample *)
    ; mutable phase : int
    ; mutable missed : int (* bit times in a row without an edge *)
    ; mutable carrier : bool
    ; mutable synced : bool (* the sync word has been seen since the carrier came *)
    ; mutable history : int (* the last 8 recovered bits *)
    ; mutable data : bool (* what the threads see on [pin] *)
    ; mutable strobe : bool (* and on the pin after it *)
    ; events : (string, int) Hashtbl.t
      (* how often each thing below has happened: not state, only a record
         for the tests that measure what they exercised *)
    }

  let create () =
    { config = Sampler_config.off
    ; mid = false
    ; last = false
    ; phase = 0
    ; missed = 0
    ; carrier = false
    ; synced = false
    ; history = 0
    ; data = false
    ; strobe = false
    ; events = Hashtbl.create (module String)
    }
  ;;

  (* What a disabled sampler is held at. [mid] is not part of it: that
     flip-flop follows the pin always. *)
  let reset t =
    t.last <- false;
    t.phase <- 0;
    t.missed <- 0;
    t.carrier <- false;
    t.synced <- false;
    t.history <- 0;
    t.data <- false;
    t.strobe <- false
  ;;

  (* One sample. Returns whether it passed a bit on. *)
  let sample t level =
    let c = t.config in
    let note what = Hashtbl.incr t.events what in
    let edge = Bool.( <> ) level t.last in
    t.last <- level;
    if edge && t.phase >= c.blank
    then (
      note (if t.carrier then "edge accepted" else "edge accepted: carrier found");
      t.phase <- 0;
      t.missed <- 0;
      t.carrier <- true)
    else (
      if edge then note "edge ignored";
      if t.phase >= c.wrap
      then
        if t.carrier && (c.misses = 7 || t.missed < c.misses)
        then (
          note "bit time without an edge: carried on";
          t.phase <- 0;
          if c.misses <> 7 then t.missed <- t.missed + 1)
        else (
          if t.carrier then note "bit time without an edge: carrier lost";
          t.carrier <- false)
      else t.phase <- t.phase + 1);
    if not t.carrier
    then (
      t.synced <- false;
      t.history <- 0;
      false)
    else if t.phase = c.sample
    then (
      let bit = Bool.( <> ) level c.invert in
      let pass = t.synced || not c.sync_enable in
      t.history <- (Bool.to_int bit lsl 7) lor (t.history lsr 1);
      if t.history = c.sync && not t.synced
      then (
        note "sync word seen";
        t.synced <- true);
      note (if pass then "bit passed on" else "bit held back before the sync word");
      if pass then t.data <- bit;
      pass)
    else false
  ;;

  (* One clock cycle: the two samples in the order they were taken. *)
  let cycle t ~early ~late =
    if not t.config.enable
    then reset t
    else (
      let a = sample t early in
      let b = sample t late in
      if a && b then Hashtbl.incr t.events "both samples of a cycle are bits";
      t.strobe <- a || b)
  ;;
end

type t =
  { programs : Instruction.t array array
    (* one memory per thread: thread n executes [programs.(n)] *)
  ; pin_modes : Pin_mode.t array
  ; threads : Thread.t array
  ; mutable sync_bypass : int
    (* pins whose inputs skip the 2-flop synchroniser; see [seen_inputs] *)
  ; mutable sync1 : int (* the synchroniser's two stages *)
  ; mutable sync2 : int
  ; mutable chain : bool
    (* thread 0's RX FIFO feeds thread 1's TX FIFO, one word per cycle *)
  ; buffer : int array
  ; mutable buffer_mode : Buffer_mode.t
  ; mutable buffer_thread : int (* whose FIFO the buffer plays into or records from *)
  ; mutable buffer_ptr : int (* the next word to write, read, play or record *)
  ; mutable buffer_end : int (* playing and recording stop when the pointer gets here *)
  ; mutable buffer_wrote : bool
    (* the buffer was written in the last cycle: like the program memories
       it answers a cycle after it is asked, and in a cycle with a write it
       is not asked, so nothing is played in the cycle after one *)
  ; sampler : Sampler.t
  ; mutable pin_out : int
  ; mutable cycle : int
  }

(* The word a memory holds where nothing was loaded. On the chip the memory
   is not reset and holds anything at all; 0, "jmp 0", is what this model
   uses, and the tests that compare it with the hardware load every word. *)
let unloaded = Instruction.decode 0

(* Each thread's memory loaded with its own program. *)
let create_separate ~programs ~pin_modes ~threads =
  if Array.length pin_modes <> num_pins then raise_s [%message "need one mode per pin"];
  if List.is_empty threads || List.length threads > 2
  then raise_s [%message "1 or 2 threads"];
  if Array.length programs <> List.length threads
  then raise_s [%message "need one program per thread"];
  let programs =
    Array.map programs ~f:(fun program ->
      if Array.length program > program_size
      then raise_s [%message "program too long" (Array.length program : int)];
      Array.init program_size ~f:(fun i ->
        if i < Array.length program then program.(i) else unloaded))
  in
  { programs
  ; pin_modes = Array.copy pin_modes
  ; threads = Array.of_list_map threads ~f:Thread.create
  ; sync_bypass = 0
  ; sync1 = mask num_pins (* reset high, like the idle bus *)
  ; sync2 = mask num_pins
  ; chain = false
  ; buffer = Array.create ~len:buffer_size 0
  ; buffer_mode = Off
  ; buffer_thread = 0
  ; buffer_ptr = 0
  ; buffer_end = 0
  ; buffer_wrote = false
  ; sampler = Sampler.create ()
  ; pin_out = mask num_pins (* all high: idle for UART, released for open-drain *)
  ; cycle = 0
  }
;;

(* One image loaded into every thread's memory, which is how the host driver
   loads a program unless told otherwise. *)
let create ~program ~pin_modes ~threads =
  create_separate
    ~programs:(Array.of_list_map threads ~f:(fun _ -> program))
    ~pin_modes
    ~threads
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

(* The CRC register takes one bit from each OUT or IN: the first bit that
   instruction shifted. Protocols with a CRC shift a bit at a time, so that
   is every bit. If the bit differs from the register's bit 0 the register
   shifts right and the polynomial is added, otherwise it only shifts. With
   the polynomial written low power first this is the CRC of USB, CAN and
   Ethernet alike; a CRC narrower than the register uses its low bits. *)
let crc_take (th : Thread.t) ~data ~count ~msb_first =
  if th.crc_run
  then (
    let b = (data lsr if msb_first then count - 1 else 0) land 1 in
    let feedback = (th.crc lxor b) land 1 in
    th.crc <- (th.crc lsr 1) lxor if feedback = 1 then th.config.crc_poly land crc_mask else 0)
;;

(* What a push sends: the bits shifted in since the last one,
   right-justified. For LSB first they sit at the top of the ISR, for MSB
   first at the bottom. *)
let pushed_word (th : Thread.t) =
  if th.isr_count = 0
  then 0
  else if th.config.in_msb_first
  then th.isr land mask th.isr_count
  else th.isr lsr (word_bits - th.isr_count)
;;

(* One tick of a thread: count down a delay, or execute an instruction. *)
let tick (program : Instruction.t array) (th : Thread.t) ~lines_now ~pin_out =
  if th.delay_left > 0
  then th.delay_left <- th.delay_left - 1
  else (
    let cfg = th.config in
    let instr = program.(th.pc) in
    (* Side-set: the top [sideset_count] bits of the 4-bit delay field are
       values for the side-set pins; the rest is the delay. *)
    let n = cfg.sideset_count in
    let side = instr.delay lsr (4 - n) in
    let delay = instr.delay land mask (4 - n) in
    let result =
      match instr.op with
      | Nop -> `Next
      | Jmp { cond; addr } ->
        if eval_cond th cond then `Goto ((th.page * page_size) + addr) else `Next
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
      | In { count; _ }
        when cfg.autopush
             && th.isr_count + count >= cfg.threshold
             && Queue.length th.rx_fifo >= fifo_depth ->
        (* Autopush with nowhere to push: the IN waits, nothing shifted. *)
        `Stall
      | Out _ when cfg.autopull && th.osr_count >= cfg.threshold ->
        (* Autopull on an empty OSR: this tick fetches a word if there is
           one, and the OUT itself runs on the next. *)
        (match Queue.dequeue th.tx_fifo with
         | None -> ()
         | Some v ->
           th.osr <- v land word_mask;
           th.osr_count <- 0);
        `Stall
      | In { src; count } ->
        let v =
          match src with
          | Pins -> read_pins lines_now ~base:cfg.in_base ~count
          | X -> th.x
          | Y -> th.y
          | Zeros -> 0
        in
        let data = v land mask count in
        if cfg.crc_in then crc_take th ~data ~count ~msb_first:cfg.in_msb_first;
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
        if cfg.autopush && th.isr_count >= cfg.threshold
        then (
          Queue.enqueue th.rx_fifo (pushed_word th);
          th.isr <- 0;
          th.isr_count <- 0);
        `Next
      | Out { dst; count } ->
        let data, rest =
          if cfg.out_msb_first
          then (th.osr lsr (word_bits - count)) land mask count, (th.osr lsl count) land word_mask
          else th.osr land mask count, th.osr lsr count
        in
        th.osr <- rest;
        th.osr_count <- min word_bits (th.osr_count + count);
        if not cfg.crc_in then crc_take th ~data ~count ~msb_first:cfg.out_msb_first;
        if cfg.autopull && th.osr_count >= cfg.threshold
        then
          Option.iter (Queue.dequeue th.tx_fifo) ~f:(fun v ->
            th.osr <- v land word_mask;
            th.osr_count <- 0);
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
          Queue.enqueue th.rx_fifo (pushed_word th);
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
          | Crc ->
            let v = (th.crc lxor if cfg.crc_invert then crc_mask else 0) land word_mask in
            th.crc <- th.crc lsr word_bits;
            th.crc_run <- false;
            v
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
         | Null -> ()
         | Crc ->
           th.crc <- Thread_config.crc_init cfg;
           th.crc_run <- true);
        `Next
      | Set { dst; value } ->
        (match dst with
         | Pins ->
           pin_out := write_pins !pin_out ~base:cfg.set_base ~count:cfg.set_count value
         | X -> th.x <- value
         | Y -> th.y <- value
         | Page -> th.page <- value % num_pages);
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

let exec program (th : Thread.t) ~lines_now ~pin_out =
  let loaded = th.loaded in
  th.loaded <- false;
  if (not th.enabled) || loaded
  then Thread.reset th
  else if th.div_count > 0
  then
    (* The clock divider: between ticks the thread does nothing at all,
       so delays, wait timeouts and side-set all count in ticks. *)
    th.div_count <- th.div_count - 1
  else (
    th.div_count <- max 0 (th.config.clkdiv - 1);
    tick program th ~lines_now ~pin_out)
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

(* With the bit sampler enabled, two pins show the threads what it has
   recovered instead of their own levels. *)
let seen_lines t ~inputs =
  let lines = lines t ~inputs:(seen_inputs t ~inputs) in
  let s = t.sampler in
  if not s.config.enable
  then lines
  else (
    let put lines pin level = lines land lnot (1 lsl pin) lor (Bool.to_int level lsl pin) in
    let pin = s.config.pin in
    put (put lines pin s.data) ((pin + 1) % num_pins) s.strobe)
;;

(* [inputs] is the level on each pin at the rising clock edge that ends
   this cycle. [inputs_mid] is the level at the falling edge in the middle of
   it, which only the bit sampler looks at; left out, it is taken to be the
   same, as for an input that changes just after a rising edge. *)
let step ?inputs_mid t ~inputs =
  let inputs_mid = Option.value inputs_mid ~default:inputs in
  let lines_now = seen_lines t ~inputs in
  let pin_out = ref t.pin_out in
  let move =
    t.chain
    && Array.length t.threads = 2
    && (not (Queue.is_empty t.threads.(0).rx_fifo))
    && Queue.length t.threads.(1).tx_fifo < fifo_depth
  in
  (* The buffer's move is judged at the start of the cycle too. An end the
     chain owns is not the buffer's. *)
  let buffered = t.buffer_thread < Array.length t.threads && t.buffer_ptr <> t.buffer_end in
  let chained end_ = t.chain && Array.length t.threads = 2 && t.buffer_thread = end_ in
  let play =
    Buffer_mode.equal t.buffer_mode Play
    && buffered
    && (not t.buffer_wrote)
    && (not (chained 1))
    && Queue.length t.threads.(t.buffer_thread).tx_fifo < fifo_depth
  in
  let record =
    Buffer_mode.equal t.buffer_mode Record
    && buffered
    && (not (chained 0))
    && not (Queue.is_empty t.threads.(t.buffer_thread).rx_fifo)
  in
  t.buffer_wrote <- false;
  Array.iteri t.threads ~f:(fun n th -> exec t.programs.(n) th ~lines_now ~pin_out);
  if move then Queue.enqueue t.threads.(1).tx_fifo (Queue.dequeue_exn t.threads.(0).rx_fifo);
  if play
  then (
    Queue.enqueue t.threads.(t.buffer_thread).tx_fifo t.buffer.(t.buffer_ptr);
    t.buffer_ptr <- (t.buffer_ptr + 1) % buffer_size);
  if record
  then (
    (* The word at the head as the cycle started: a push this cycle went
       in behind it. *)
    t.buffer.(t.buffer_ptr) <- Queue.dequeue_exn t.threads.(t.buffer_thread).rx_fifo;
    t.buffer_ptr <- (t.buffer_ptr + 1) % buffer_size;
    t.buffer_wrote <- true);
  t.pin_out <- !pin_out;
  (* The sampler's two samples of this cycle, half a cycle apart: the pin at
     the rising edge two cycles back, from the synchroniser, and at the
     falling edge after it. *)
  (let s = t.sampler in
   let at v = (v lsr s.config.pin) land 1 = 1 in
   Sampler.cycle s ~early:(at t.sync2) ~late:s.mid;
   s.mid <- at inputs_mid);
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

let buffered t ~thread ~end_ =
  thread = t.buffer_thread
  && Buffer_mode.equal t.buffer_mode (match end_ with `Tx -> Play | `Rx -> Record)
;;

let push_tx t ~thread v =
  let q = t.threads.(thread).tx_fifo in
  if Queue.length q >= fifo_depth || chained t ~thread ~end_:`Tx || buffered t ~thread ~end_:`Tx
  then false
  else (
    Queue.enqueue q (v land word_mask);
    true)
;;

let pop_rx t ~thread =
  if chained t ~thread ~end_:`Rx || buffered t ~thread ~end_:`Rx
  then None
  else Queue.dequeue t.threads.(thread).rx_fifo
;;

(* The host's side of the packet buffer. Like the other host actions these
   are called after the [step] of the cycle they happen in. Data moves only
   while the buffer is [Off]: a write stores at the pointer and a read
   returns the word there, and each moves the pointer on. *)
let set_buffer t ~mode ~thread =
  t.buffer_mode <- mode;
  t.buffer_thread <- thread
;;

let set_buffer_ptr t v = t.buffer_ptr <- v % buffer_size
let set_buffer_end t v = t.buffer_end <- v % buffer_size
let buffer_ptr t = t.buffer_ptr

let write_buffer t v =
  if Buffer_mode.equal t.buffer_mode Off
  then (
    t.buffer.(t.buffer_ptr) <- v land word_mask;
    t.buffer_ptr <- (t.buffer_ptr + 1) % buffer_size;
    t.buffer_wrote <- true)
;;

let read_buffer t =
  if Buffer_mode.equal t.buffer_mode Off
  then (
    let v = t.buffer.(t.buffer_ptr) in
    t.buffer_ptr <- (t.buffer_ptr + 1) % buffer_size;
    Some v)
  else None
;;

let set_chain t b = t.chain <- b

(* The host writes the bit sampler's registers. Like the other host actions
   this is called after the [step] of the cycle it happens in. *)
let set_sampler t (c : Sampler_config.t) =
  t.sampler.config
  <- { c with
       pin = c.pin land mask 3
     ; misses = c.misses land mask 3
     ; blank = c.blank land mask 5
     ; sample = c.sample land mask 5
     ; wrap = c.wrap land mask 5
     ; sync = c.sync land mask 8
     }
;;

(* The host writes one word of a thread's program memory. Like the other
   host actions it is called after the [step] of the cycle it happens in.

   A write to the memory of an enabled thread is ignored. After a write
   that lands, the thread is held in its initial state for one more cycle,
   even if the host enables it at once: the memory answers a cycle after it
   is asked, and in the cycle of a write it is not asked for the thread's
   first instruction. Returns whether the write landed. *)
let write_program t ~thread ~addr instr =
  let th = t.threads.(thread) in
  if th.enabled
  then false
  else (
    t.programs.(thread).(addr) <- instr;
    th.loaded <- true;
    true)
;;

(* Threads are enabled when created. While disabled, a thread is held in
   its initial state from the next step on, as the hardware's enable bit
   does. *)
let set_enabled t ~thread b = t.threads.(thread).enabled <- b
