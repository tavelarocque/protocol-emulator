(* The protocol-emulator core: two threads of the ISA in docs/isa.md,
   sharing one program memory and the 8 protocol pins.

   Every behaviour here is defined by the reference model in model/isa.ml,
   and sim/test_core.ml checks this circuit against that model cycle by
   cycle on random programs, configurations, pin inputs and host traffic.

   Structure: a single-cycle machine. Each cycle every thread reads the
   instruction at its own [pc] from the shared flop-based program memory (one
   read port per thread), decodes it combinationally, and its effects are
   registered at the clock edge. All reads of the pins see the levels at the
   start of the cycle. Pin writes land at the clock edge; when both threads
   write the same pin in the same cycle, thread 1 wins. That rule is built
   structurally: thread 1's datapath takes thread 0's next pin value as its
   starting point, exactly as the reference model threads one [pin_out]
   through the threads in order. *)

open! Core
open! Hardcaml
open! Signal

let program_size = 64
let num_pins = 8
let num_threads = 2

(* Per-thread inputs: configuration, enable, and the host side of the
   thread's FIFOs. *)
module Thread_in = struct
  type 'a t =
    { enable : 'a (* low: thread held at its initial state *)
    ; start : 'a [@bits 6]
    ; out_base : 'a [@bits 3]
    ; out_count : 'a [@bits 4]
    ; set_base : 'a [@bits 3]
    ; set_count : 'a [@bits 4]
    ; in_base : 'a [@bits 3]
    ; threshold : 'a [@bits 5]
    ; timeout_vector : 'a [@bits 6]
    ; timeout : 'a [@bits 16] (* max cycles a [wait ... timeout] stalls *)
    ; sideset_base : 'a [@bits 3]
    ; sideset_count : 'a [@bits 2] (* top bits of the delay field that are side-set *)
    ; tx_push : 'a
    ; tx_data : 'a [@bits 16]
    ; rx_pop : 'a
    }
  [@@deriving hardcaml]
end

(* Per-thread outputs: the host side of the FIFOs, and the thread's
   architectural state, exposed for differential testing. *)
module Thread_out = struct
  type 'a t =
    { rx_data : 'a [@bits 16] (* head of the RX FIFO *)
    ; tx_level : 'a [@bits 3]
    ; rx_level : 'a [@bits 3]
    ; pc : 'a [@bits 6]
    ; x : 'a [@bits 16]
    ; y : 'a [@bits 16]
    ; isr : 'a [@bits 16]
    ; isr_count : 'a [@bits 5]
    ; osr : 'a [@bits 16]
    ; osr_count : 'a [@bits 5]
    ; delay_left : 'a [@bits 4]
    ; waiting : 'a
    ; wait_count : 'a [@bits 16]
    }
  [@@deriving hardcaml]
end

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; prog_we : 'a
    ; prog_addr : 'a [@bits 6]
    ; prog_data : 'a [@bits 16]
    ; pin_modes : 'a [@bits 16] (* 2 bits per pin: 0 input, 1 push-pull, 2 open-drain *)
    ; pins_in : 'a [@bits 8]
    ; t0 : 'a Thread_in.t [@rtlprefix "t0_"]
    ; t1 : 'a Thread_in.t [@rtlprefix "t1_"]
    }
  [@@deriving hardcaml]

  let thread i n = if n = 0 then i.t0 else i.t1
end

module O = struct
  type 'a t =
    { pin_out : 'a [@bits 8] (* the output register *)
    ; pads_out : 'a [@bits 8] (* to the bidirectional pads *)
    ; pads_oe : 'a [@bits 8]
    ; t0 : 'a Thread_out.t [@rtlprefix "t0_"]
    ; t1 : 'a Thread_out.t [@rtlprefix "t1_"]
    }
  [@@deriving hardcaml]

  let thread o n = if n = 0 then o.t0 else o.t1
end

(* Planted bugs. Production builds use none; the test suite builds each one
   and asserts that both the differential test and the formal proof catch
   it. The first five are in a thread's datapath and are planted in thread 1
   only, so catching them proves the tests really exercise the second
   thread. The last two are in how the threads are put together. *)
module Mutation = struct
  type t =
    | Xdec_never_decrements
    | Wait_timeout_ignores_budget
    | Delay_field_ignored
    | Set_pins_count_off_by_one
    | Push_not_right_justified
    | Pin_priority_inverted (* thread 0 wins a pin both threads write *)
    | Fetch_port_crossed (* thread 1 fetches from thread 0's pc *)
  [@@deriving sexp_of, enumerate, equal]
end

let bit s i = select s i i

(* Shift right by a runtime amount of 0..16, through a 32-bit intermediate so
   shifting by the full width is well defined. [hi] supplies the bits that
   shift in from the top. *)
let shift_right ~hi lo ~by = uresize (log_shift srl (hi @: lo) by) 16

(* min(16, a + b) for 5-bit a and b. *)
let saturating_add a b =
  let sum = uresize a 6 +: uresize b 6 in
  mux2 (sum >:. 16) (of_int ~width:5 16) (uresize sum 5)
;;

(* Write the low bits of [value] to [count] pins starting at [base], wrapping
   modulo 8; other pins keep their [current] value. *)
let write_pins ~current ~base ~count ~value =
  let w = max 4 (width count) in
  concat_lsb
    (List.init num_pins ~f:(fun p ->
       let k = of_int ~width:3 p -: base in
       let in_range = uresize k w <: uresize count w in
       mux2 in_range (mux k (List.init num_pins ~f:(bit value))) (bit current p)))
;;

(* Read [count] pins starting at [base], wrapping modulo 8, LSB first. *)
let read_pins ~lines ~base ~count =
  let w = max 4 (width count) in
  uresize
    (concat_lsb
       (List.init num_pins ~f:(fun k ->
          mux (base +:. k) (bits_lsb lines) &: (of_int ~width:w k <: uresize count w))))
    16
;;

(* A thread's architectural state and one step of its next-state function,
   as an interface. [create] normally uses [rtl_step] below; passing
   [~datapath] substitutes another implementation of the same step with
   everything else (program memory, FIFOs, pins, the composition of the two
   threads) unchanged. The formal equivalence proof in sim/test_formal.ml
   uses this to compare this RTL against an independently written
   combinational spec.

   [pin_out] is the shared pin register as this thread sees it: the
   register itself for thread 0, thread 0's result for thread 1. *)
module Thread_state = struct
  type 'a t =
    { pc : 'a [@bits 6]
    ; x : 'a [@bits 16]
    ; y : 'a [@bits 16]
    ; isr : 'a [@bits 16]
    ; isr_count : 'a [@bits 5]
    ; osr : 'a [@bits 16]
    ; osr_count : 'a [@bits 5]
    ; delay_left : 'a [@bits 4]
    ; waiting : 'a
    ; wait_count : 'a [@bits 16]
    ; pin_out : 'a [@bits 8]
    }
  [@@deriving hardcaml]
end

module Step_in = struct
  type 'a t =
    { enable : 'a
    ; instr : 'a [@bits 16]
    ; lines : 'a [@bits 8]
    ; tx_empty : 'a
    ; tx_head : 'a [@bits 16]
    ; rx_full : 'a
    ; start : 'a [@bits 6]
    ; out_base : 'a [@bits 3]
    ; out_count : 'a [@bits 4]
    ; set_base : 'a [@bits 3]
    ; set_count : 'a [@bits 4]
    ; in_base : 'a [@bits 3]
    ; threshold : 'a [@bits 5]
    ; timeout_vector : 'a [@bits 6]
    ; timeout : 'a [@bits 16]
    ; sideset_base : 'a [@bits 3]
    ; sideset_count : 'a [@bits 2]
    }
  [@@deriving hardcaml]
end

module Step_out = struct
  type 'a t =
    { next : 'a Thread_state.t
    ; pull : 'a
    ; push : 'a
    ; push_value : 'a
    }
end

type datapath = Signal.t Thread_state.t -> Signal.t Step_in.t -> Signal.t Step_out.t

(* One step of one thread: the RTL datapath. Written as one shared datapath
   and an imperative [Always] block over wires that default to the current
   state. *)
let rtl_step ?mutation (s : Signal.t Thread_state.t) (i : Signal.t Step_in.t)
  : Signal.t Step_out.t
  =
  let is m = Option.value_map mutation ~default:false ~f:(Mutation.equal m) in
  let open Always in
  let w v = Variable.wire ~default:v in
  let pc = w s.pc in
  let x = w s.x in
  let y = w s.y in
  let isr = w s.isr in
  let isr_count = w s.isr_count in
  let osr = w s.osr in
  let osr_count = w s.osr_count in
  let delay_left = w s.delay_left in
  let waiting = w s.waiting in
  let wait_count = w s.wait_count in
  let pin_out = w s.pin_out in
  let instr = i.instr in
  (* --- Decode. --- *)
  let op = select instr 15 13 in
  (* The 4-bit delay field: its top [sideset_count] bits are side-set
     values, the rest is the delay. *)
  let delay_field = select instr 12 9 in
  let side_bits =
    log_shift srl delay_field (of_int ~width:3 4 -: uresize i.sideset_count 3)
  in
  let delay = delay_field &: log_shift srl (ones 4) i.sideset_count in
  let is_op n = op ==:. n in
  let count =
    let c = select instr 3 0 in
    mux2 (c ==:. 0) (of_int ~width:5 16) (uresize c 5)
  in
  let executing = i.enable &: (s.delay_left ==:. 0) in
  let x_nz = s.x <>:. 0 in
  let y_nz = s.y <>:. 0 in
  (* JMP *)
  let cond = select instr 8 6 in
  let cond_true =
    mux
      cond
      [ vdd
      ; ~:x_nz
      ; x_nz
      ; ~:y_nz
      ; y_nz
      ; s.x <>: s.y
      ; s.osr_count <: i.threshold
      ; s.isr_count <: i.threshold
      ]
  in
  (* WAIT *)
  let wait_level = mux (select instr 7 5) (bits_lsb i.lines) in
  let wait_ok = wait_level ==: bit instr 8 in
  let wait_timeout = bit instr 4 in
  let budget = mux2 s.waiting s.wait_count i.timeout in
  let budget_zero = budget ==:. 0 in
  let wait_expired =
    if is Wait_timeout_ignores_budget then wait_timeout else wait_timeout &: budget_zero
  in
  (* PUSH / PULL *)
  let is_pull = bit instr 8 in
  (* MOV: source/destination 6 and 7 are reserved, making the whole
     instruction a NOP. SET destination 3 likewise. *)
  let mov_dst = select instr 8 6 in
  let mov_src = select instr 5 3 in
  let mov_valid = (mov_dst <:. 6) &: (mov_src <:. 6) in
  let set_dst = select instr 8 7 in
  (* --- Control: stall, or move to the next/target instruction. --- *)
  let stall =
    (is_op 1 &: ~:wait_ok &: ~:wait_expired)
    |: (is_op 4 &: is_pull &: i.tx_empty)
    |: (is_op 4 &: ~:is_pull &: i.rx_full)
  in
  let goto_ = (is_op 0 &: cond_true) |: (is_op 1 &: ~:wait_ok &: wait_expired) in
  let target = mux2 (is_op 0) (select instr 5 0) i.timeout_vector in
  let next_pc = mux2 goto_ target (s.pc +:. 1) in
  let advance = executing &: ~:stall in
  let pull = executing &: is_op 4 &: is_pull &: ~:(i.tx_empty) in
  let push = executing &: is_op 4 &: ~:is_pull &: ~:(i.rx_full) in
  let push_value =
    if is Push_not_right_justified
    then s.isr
    else shift_right ~hi:(zero 16) s.isr ~by:(of_int ~width:5 16 -: s.isr_count)
  in
  (* --- Datapath values. --- *)
  let in_value =
    mux
      (select instr 8 7)
      [ read_pins ~lines:i.lines ~base:i.in_base ~count; s.x; s.y; zero 16 ]
  in
  let out_mask = ~:(uresize (log_shift sll (ones 32) count) 16) in
  let out_data = s.osr &: out_mask in
  let mov_value =
    mux mov_src [ s.x; s.y; uresize i.lines 16; s.isr; s.osr; zero 16 ]
  in
  let set_value = uresize (select instr 4 0) 16 in
  let set_count = if is Set_pins_count_off_by_one then i.set_count +:. 1 else i.set_count in
  (* What the instruction itself writes to the pins this cycle (if it
     completes); side-set is then applied on top. *)
  let instr_pins =
    let write ~base ~count ~value = write_pins ~current:s.pin_out ~base ~count ~value in
    let writes_pins ~op ~sel = advance &: is_op op &: sel in
    mux2
      (writes_pins ~op:3 ~sel:(select instr 8 7 ==:. 0))
      (write ~base:i.out_base ~count ~value:out_data)
    @@ mux2
         (writes_pins ~op:5 ~sel:(mov_valid &: (mov_dst ==:. 2)))
         (write ~base:i.out_base ~count:i.out_count ~value:mov_value)
    @@ mux2
         (writes_pins ~op:6 ~sel:(set_dst ==:. 0))
         (write ~base:i.set_base ~count:set_count ~value:set_value)
    @@ s.pin_out
  in
  compile
    [ if_
        ~:(i.enable)
        [ (* Held in the initial state until the host enables the thread. *)
          pc <-- i.start
        ; x <--. 0
        ; y <--. 0
        ; isr <--. 0
        ; isr_count <--. 0
        ; osr <--. 0
        ; osr_count <-- i.threshold
        ; delay_left <--. 0
        ; waiting <--. 0
        ; wait_count <--. 0
        ]
      @@ elif
           (s.delay_left <>:. 0)
           [ delay_left <-- s.delay_left -:. 1 ]
           [ (* Executing. A timed WAIT spends its budget while it stalls;
                every other effect happens only when not stalled. *)
             when_
               (is_op 1 &: ~:wait_ok &: wait_timeout &: ~:budget_zero)
               [ waiting <--. 1; wait_count <-- budget -:. 1 ]
           ; (* Pins: the instruction's own write, then side-set on top. Side-set
                applies on every executing cycle, stalled or not. *)
             pin_out
             <-- write_pins
                   ~current:instr_pins
                   ~base:i.sideset_base
                   ~count:i.sideset_count
                   ~value:(uresize side_bits 8)
           ; when_
               advance
               [ pc <-- next_pc
               ; waiting <--. 0
               ; (delay_left <-- if is Delay_field_ignored then zero 4 else delay)
               ; switch
                   op
                   [ ( of_int ~width:3 0
                     , [ when_
                           (if is Xdec_never_decrements then gnd else cond ==:. 2)
                           [ x <-- s.x -:. 1 ]
                       ; when_ (cond ==:. 4) [ y <-- s.y -:. 1 ]
                       ] )
                   ; ( of_int ~width:3 2
                     , [ isr <-- shift_right ~hi:in_value s.isr ~by:count
                       ; isr_count <-- saturating_add s.isr_count count
                       ] )
                   ; ( of_int ~width:3 3
                     , [ osr <-- shift_right ~hi:(zero 16) s.osr ~by:count
                       ; osr_count <-- saturating_add s.osr_count count
                       ; switch
                           (select instr 8 7)
                           [ of_int ~width:2 1, [ x <-- out_data ]
                           ; of_int ~width:2 2, [ y <-- out_data ]
                           ]
                       ] )
                   ; ( of_int ~width:3 4
                     , [ if_
                           is_pull
                           [ osr <-- i.tx_head; osr_count <--. 0 ]
                           [ isr <--. 0; isr_count <--. 0 ]
                       ] )
                   ; ( of_int ~width:3 5
                     , [ when_
                           mov_valid
                           [ switch
                               mov_dst
                               [ of_int ~width:3 0, [ x <-- mov_value ]
                               ; of_int ~width:3 1, [ y <-- mov_value ]
                               ; of_int ~width:3 3, [ isr <-- mov_value; isr_count <--. 0 ]
                               ; of_int ~width:3 4, [ osr <-- mov_value; osr_count <--. 0 ]
                               ]
                           ]
                       ] )
                   ; ( of_int ~width:3 6
                     , [ switch
                           set_dst
                           [ of_int ~width:2 1, [ x <-- set_value ]
                           ; of_int ~width:2 2, [ y <-- set_value ]
                           ]
                       ] )
                   ]
               ]
           ]
    ];
  { Step_out.next =
      { Thread_state.pc = pc.value
      ; x = x.value
      ; y = y.value
      ; isr = isr.value
      ; isr_count = isr_count.value
      ; osr = osr.value
      ; osr_count = osr_count.value
      ; delay_left = delay_left.value
      ; waiting = waiting.value
      ; wait_count = wait_count.value
      ; pin_out = pin_out.value
      }
  ; pull
  ; push
  ; push_value
  }
;;

let create ?mutation ?datapath (i : _ I.t) : _ O.t =
  let is m = Option.value_map mutation ~default:false ~f:(Mutation.equal m) in
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  (* --- Program memory: 64 x 16 flops, written by the host, shared. --- *)
  let program =
    List.init program_size ~f:(fun a ->
      reg spec ~enable:(i.prog_we &: (i.prog_addr ==:. a)) i.prog_data
      -- sprintf "prog_%d" a)
  in
  (* --- The shared pin register. Resets to all ones: idle-high for UART,
     released for open-drain. --- *)
  let pin_next = wire num_pins in
  let pin_out =
    reg (Reg_spec.override spec ~clear_to:(ones num_pins)) pin_next -- "pin_out"
  in
  (* --- Pin levels seen by both threads this cycle. --- *)
  let mode p = select i.pin_modes ((2 * p) + 1) (2 * p) in
  let lines =
    concat_lsb
      (List.init num_pins ~f:(fun p ->
         let ext = bit i.pins_in p in
         let out = bit pin_out p in
         mux (mode p) [ ext; out; out &: ext; ext ]))
  in
  (* --- Each thread's registers, named t0_pc, t1_pc, ... so the
     equivalence checker can pair them up between two builds. The thread's
     [pin_out] field is not a register of its own: the shared one is
     substituted below. --- *)
  let regs n =
    let d = Thread_state.map Thread_state.port_widths ~f:wire in
    let q =
      Thread_state.map2 d Thread_state.port_names ~f:(fun d name ->
        reg spec d -- sprintf "t%d_%s" n name)
    in
    d, q
  in
  let threads = List.init num_threads ~f:(fun n -> n, regs n) in
  let pcs = List.map threads ~f:(fun (_, (_, q)) -> q.pc) in
  let fetch n =
    let pc = List.nth_exn pcs (if n = 1 && is Fetch_port_crossed then 0 else n) in
    mux pc program
  in
  (* --- FIFOs. The thread-side strobes are wires, assigned when the
     thread's step is built. --- *)
  let fifos =
    List.map threads ~f:(fun (n, _) ->
      let ti = I.thread i n in
      let pull = wire 1 in
      let push = wire 1 in
      let push_value = wire 16 in
      let tx =
        Tiny_fifo.create
          ~name:(sprintf "t%d_tx" n)
          spec
          ~push:ti.tx_push
          ~data:ti.tx_data
          ~pop:pull
      in
      let rx =
        Tiny_fifo.create
          ~name:(sprintf "t%d_rx" n)
          spec
          ~push
          ~data:push_value
          ~pop:ti.rx_pop
      in
      pull, push, push_value, tx, rx)
  in
  (* --- Step the threads in priority order, threading the pin value
     through: the later thread's writes land on top. --- *)
  let order = if is Pin_priority_inverted then [ 1; 0 ] else [ 0; 1 ] in
  let final_pins =
    List.fold order ~init:pin_out ~f:(fun pins_so_far n ->
      let d, q = List.Assoc.find_exn threads ~equal:Int.equal n in
      let pull, push, push_value, (tx : Tiny_fifo.t), (rx : Tiny_fifo.t) =
        List.nth_exn fifos n
      in
      let ti = I.thread i n in
      let step : datapath =
        match datapath with
        | Some step -> step
        | None ->
          (* Datapath bugs are planted in thread 1 only. *)
          let mutation = if n = 1 then mutation else None in
          rtl_step ?mutation
      in
      let (out : _ Step_out.t) =
        step
          { q with pin_out = pins_so_far }
          { Step_in.enable = ti.enable
          ; instr = fetch n
          ; lines
          ; tx_empty = tx.empty
          ; tx_head = tx.head
          ; rx_full = rx.full
          ; start = ti.start
          ; out_base = ti.out_base
          ; out_count = ti.out_count
          ; set_base = ti.set_base
          ; set_count = ti.set_count
          ; in_base = ti.in_base
          ; threshold = ti.threshold
          ; timeout_vector = ti.timeout_vector
          ; timeout = ti.timeout
          ; sideset_base = ti.sideset_base
          ; sideset_count = ti.sideset_count
          }
      in
      pull <== out.pull;
      push <== out.push;
      push_value <== out.push_value;
      (* The per-thread pin_out wire drives nothing: tie it off. *)
      Thread_state.iter2 d { out.next with pin_out = zero num_pins } ~f:( <== );
      out.next.pin_out)
  in
  pin_next <== final_pins;
  (* Pads: push-pull drives the bit; open-drain drives low only for a 0. *)
  let pads_oe =
    concat_lsb
      (List.init num_pins ~f:(fun p ->
         (mode p ==:. 1) |: ((mode p ==:. 2) &: ~:(bit pin_out p))))
  in
  let pads_out =
    concat_lsb (List.init num_pins ~f:(fun p -> (mode p ==:. 1) &: bit pin_out p))
  in
  let thread_out n : _ Thread_out.t =
    let _, (q : _ Thread_state.t) = List.Assoc.find_exn threads ~equal:Int.equal n in
    let _, _, _, (tx : Tiny_fifo.t), (rx : Tiny_fifo.t) = List.nth_exn fifos n in
    { rx_data = rx.head
    ; tx_level = tx.level
    ; rx_level = rx.level
    ; pc = q.pc
    ; x = q.x
    ; y = q.y
    ; isr = q.isr
    ; isr_count = q.isr_count
    ; osr = q.osr
    ; osr_count = q.osr_count
    ; delay_left = q.delay_left
    ; waiting = q.waiting
    ; wait_count = q.wait_count
    }
  in
  { O.pin_out; pads_out; pads_oe; t0 = thread_out 0; t1 = thread_out 1 }
;;
