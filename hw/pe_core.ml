(* The protocol-emulator core: one thread of the ISA in docs/isa.md.

   Every behaviour here is defined by the reference model in model/isa.ml,
   and sim/test_core.ml checks this circuit against that model cycle by
   cycle on random programs, configurations, pin inputs and host traffic.

   Structure: a single-cycle machine. Each cycle the instruction at [pc] is
   read from a flop-based program memory, decoded combinationally, and its
   effects are registered at the clock edge. All reads of the pins see the
   levels at the start of the cycle; pin writes land at the clock edge. *)

open! Core
open! Hardcaml
open! Signal

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; enable : 'a (* low: thread held at its initial state *)
    ; prog_we : 'a
    ; prog_addr : 'a [@bits 6]
    ; prog_data : 'a [@bits 16]
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
    ; pin_modes : 'a [@bits 16] (* 2 bits per pin: 0 input, 1 push-pull, 2 open-drain *)
    ; pins_in : 'a [@bits 8]
    ; tx_push : 'a
    ; tx_data : 'a [@bits 16]
    ; rx_pop : 'a
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { pin_out : 'a [@bits 8] (* the output register *)
    ; pads_out : 'a [@bits 8] (* to the bidirectional pads *)
    ; pads_oe : 'a [@bits 8]
    ; rx_data : 'a [@bits 16] (* head of the RX FIFO *)
    ; tx_level : 'a [@bits 3]
    ; rx_level : 'a [@bits 3]
    ; (* Architectural state, exposed for differential testing. *)
      pc : 'a [@bits 6]
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

(* Planted bugs. Production builds use none; the test suite builds each one
   and asserts the differential test catches it. *)
module Mutation = struct
  type t =
    | Xdec_never_decrements
    | Wait_timeout_ignores_budget
    | Delay_field_ignored
    | Set_pins_count_off_by_one
    | Push_not_right_justified
  [@@deriving sexp_of, enumerate, equal]
end

let program_size = 64
let num_pins = 8

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

(* The thread's architectural state and one step of its next-state
   function, as an interface. [create] normally builds the datapath below;
   passing [~datapath] substitutes another implementation of the same step
   with everything else (program memory, FIFOs, pins) unchanged. The formal
   equivalence proof in sim/test_formal.ml uses this to compare this RTL
   against an independently written combinational spec. *)
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

let create ?mutation ?datapath (i : _ I.t) : _ O.t =
  let is m = Option.value_map mutation ~default:false ~f:(Mutation.equal m) in
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let open Always in
  (* --- Program memory: 32 x 16 flops, written by the host. --- *)
  let program =
    List.init program_size ~f:(fun a ->
      reg spec ~enable:(i.prog_we &: (i.prog_addr ==:. a)) i.prog_data
      -- sprintf "prog_%d" a)
  in
  (* --- Thread state. --- *)
  let pc = Variable.reg spec ~width:6 in
  let x = Variable.reg spec ~width:16 in
  let y = Variable.reg spec ~width:16 in
  let isr = Variable.reg spec ~width:16 in
  let isr_count = Variable.reg spec ~width:5 in
  let osr = Variable.reg spec ~width:16 in
  let osr_count = Variable.reg spec ~width:5 in
  let delay_left = Variable.reg spec ~width:4 in
  (* Wait-timeout budget: loaded from [i.timeout] when a timed wait starts
     stalling, counted down while it stalls. Independent of X and Y. *)
  let waiting = Variable.reg spec ~width:1 in
  let wait_count = Variable.reg spec ~width:16 in
  (* Pins reset to all ones: idle-high for UART, released for open-drain. *)
  let pin_out =
    Variable.reg (Reg_spec.override spec ~clear_to:(ones num_pins)) ~width:num_pins
  in
  (* Stable register names: used in waveforms, and by the equivalence
     checker to pair up state between two circuits. *)
  List.iter
    [ pc, "pc"; x, "x"; y, "y"; isr, "isr"; isr_count, "isr_count"; osr, "osr"
    ; osr_count, "osr_count"; delay_left, "delay_left"; waiting, "waiting"
    ; wait_count, "wait_count"; pin_out, "pin_out"
    ]
    ~f:(fun ((v : Variable.t), n) -> ignore (v.value -- n : Signal.t));
  (* --- Pin levels seen by the thread this cycle. --- *)
  let lines =
    concat_lsb
      (List.init num_pins ~f:(fun p ->
         let mode = select i.pin_modes ((2 * p) + 1) (2 * p) in
         let ext = bit i.pins_in p in
         let out = bit pin_out.value p in
         mux mode [ ext; out; out &: ext; ext ]))
  in
  (* --- FIFOs. The thread-side strobes are wires, assigned below. --- *)
  let thread_pull = wire 1 in
  let thread_push = wire 1 in
  let push_value = wire 16 in
  let tx = Tiny_fifo.create ~name:"tx" spec ~push:i.tx_push ~data:i.tx_data ~pop:thread_pull in
  let rx = Tiny_fifo.create ~name:"rx" spec ~push:thread_push ~data:push_value ~pop:i.rx_pop in
  let instr = mux pc.value program in
  (match datapath with
   | Some step ->
     let current =
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
     in
     let (out : _ Step_out.t) =
       step
         current
         { Step_in.enable = i.enable
         ; instr
         ; lines
         ; tx_empty = tx.empty
         ; tx_head = tx.head
         ; rx_full = rx.full
         ; start = i.start
         ; out_base = i.out_base
         ; out_count = i.out_count
         ; set_base = i.set_base
         ; set_count = i.set_count
         ; in_base = i.in_base
         ; threshold = i.threshold
         ; timeout_vector = i.timeout_vector
         ; timeout = i.timeout
         ; sideset_base = i.sideset_base
         ; sideset_count = i.sideset_count
         }
     in
     thread_pull <== out.pull;
     thread_push <== out.push;
     push_value <== out.push_value;
     let (n : _ Thread_state.t) = out.next in
     compile
       [ pc <-- n.pc
       ; x <-- n.x
       ; y <-- n.y
       ; isr <-- n.isr
       ; isr_count <-- n.isr_count
       ; osr <-- n.osr
       ; osr_count <-- n.osr_count
       ; delay_left <-- n.delay_left
       ; waiting <-- n.waiting
       ; wait_count <-- n.wait_count
       ; pin_out <-- n.pin_out
       ]
   | None ->
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
  let executing = i.enable &: (delay_left.value ==:. 0) in
  let x_nz = x.value <>:. 0 in
  let y_nz = y.value <>:. 0 in
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
      ; x.value <>: y.value
      ; osr_count.value <: i.threshold
      ; isr_count.value <: i.threshold
      ]
  in
  (* WAIT *)
  let wait_level = mux (select instr 7 5) (bits_lsb lines) in
  let wait_ok = wait_level ==: bit instr 8 in
  let wait_timeout = bit instr 4 in
  let budget = mux2 waiting.value wait_count.value i.timeout in
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
    |: (is_op 4 &: is_pull &: tx.empty)
    |: (is_op 4 &: ~:is_pull &: rx.full)
  in
  let goto_ = (is_op 0 &: cond_true) |: (is_op 1 &: ~:wait_ok &: wait_expired) in
  let target = mux2 (is_op 0) (select instr 5 0) i.timeout_vector in
  let next_pc = mux2 goto_ target (pc.value +:. 1) in
  let advance = executing &: ~:stall in
  thread_pull <== (executing &: is_op 4 &: is_pull &: ~:(tx.empty));
  thread_push <== (executing &: is_op 4 &: ~:is_pull &: ~:(rx.full));
  push_value
  <== (if is Push_not_right_justified
       then isr.value
       else shift_right ~hi:(zero 16) isr.value ~by:(of_int ~width:5 16 -: isr_count.value));
  (* --- Datapath values. --- *)
  let in_value =
    mux
      (select instr 8 7)
      [ read_pins ~lines ~base:i.in_base ~count; x.value; y.value; zero 16 ]
  in
  let out_mask = ~:(uresize (log_shift sll (ones 32) count) 16) in
  let out_data = osr.value &: out_mask in
  let mov_value =
    mux mov_src [ x.value; y.value; uresize lines 16; isr.value; osr.value; zero 16 ]
  in
  let set_value = uresize (select instr 4 0) 16 in
  let set_count = if is Set_pins_count_off_by_one then i.set_count +:. 1 else i.set_count in
  (* What the instruction itself writes to the pins this cycle (if it
     completes); side-set is then applied on top. *)
  let instr_pins =
    let write ~base ~count ~value = write_pins ~current:pin_out.value ~base ~count ~value in
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
    @@ pin_out.value
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
           (delay_left.value <>:. 0)
           [ delay_left <-- delay_left.value -:. 1 ]
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
                           [ x <-- x.value -:. 1 ]
                       ; when_ (cond ==:. 4) [ y <-- y.value -:. 1 ]
                       ] )
                   ; ( of_int ~width:3 2
                     , [ isr <-- shift_right ~hi:in_value isr.value ~by:count
                       ; isr_count <-- saturating_add isr_count.value count
                       ] )
                   ; ( of_int ~width:3 3
                     , [ osr <-- shift_right ~hi:(zero 16) osr.value ~by:count
                       ; osr_count <-- saturating_add osr_count.value count
                       ; switch
                           (select instr 8 7)
                           [ of_int ~width:2 1, [ x <-- out_data ]
                           ; of_int ~width:2 2, [ y <-- out_data ]
                           ]
                       ] )
                   ; ( of_int ~width:3 4
                     , [ if_
                           is_pull
                           [ osr <-- tx.head; osr_count <--. 0 ]
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
    ]);
  (* Pads: push-pull drives the bit; open-drain drives low only for a 0. *)
  let pads_oe =
    concat_lsb
      (List.init num_pins ~f:(fun p ->
         let mode = select i.pin_modes ((2 * p) + 1) (2 * p) in
         (mode ==:. 1) |: ((mode ==:. 2) &: ~:(bit pin_out.value p))))
  in
  let pads_out =
    concat_lsb
      (List.init num_pins ~f:(fun p ->
         let mode = select i.pin_modes ((2 * p) + 1) (2 * p) in
         (mode ==:. 1) &: bit pin_out.value p))
  in
  { O.pin_out = pin_out.value
  ; pads_out
  ; pads_oe
  ; rx_data = rx.head
  ; tx_level = tx.level
  ; rx_level = rx.level
  ; pc = pc.value
  ; x = x.value
  ; y = y.value
  ; isr = isr.value
  ; isr_count = isr_count.value
  ; osr = osr.value
  ; osr_count = osr_count.value
  ; delay_left = delay_left.value
  ; waiting = waiting.value
  ; wait_count = wait_count.value
  }
;;
