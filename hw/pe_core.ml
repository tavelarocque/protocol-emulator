(* The protocol-emulator core: two threads of the ISA in docs/isa.md, each
   with its own program memory, sharing the 8 protocol pins.

   Every behaviour here is defined by the reference model in model/isa.ml,
   and sim/test_core.ml checks this circuit against that model cycle by
   cycle on random programs, configurations, pin inputs and host traffic.

   Structure: a single-cycle machine. Each cycle every thread has the
   instruction at its own [pc], read from its own program memory, decodes it
   combinationally, and its effects are registered at the clock edge. The
   memory is an SRAM macro, which registers its address: it is given the pc
   the thread will have next cycle, so its output is always the instruction
   at the pc the thread has now (see [program_memory]). All reads of the pins see the levels at the
   start of the cycle. Pin writes land at the clock edge; when both threads
   write the same pin in the same cycle, thread 1 wins. That rule is built
   structurally: thread 1's datapath takes thread 0's next pin value as its
   starting point, exactly as the reference model threads one [pin_out]
   through the threads in order. *)

open! Core
open! Hardcaml
open! Signal

let program_size = 256
let pc_bits = Int.ceil_log2 program_size
let page_size = 64
let page_bits = pc_bits - Int.ceil_log2 page_size
let num_pins = 8
let num_threads = 2
let crc_bits = 32

(* The packet buffer: [buffer_size] words that play into one thread's TX
   FIFO or record from its RX FIFO. *)
let buffer_size = 1024
let buffer_bits = Int.ceil_log2 buffer_size

(* Per-thread inputs: configuration, enable, and the host side of the
   thread's FIFOs. *)
module Thread_in = struct
  type 'a t =
    { enable : 'a (* low: thread held at its initial state *)
    ; start : 'a [@bits pc_bits]
    ; out_base : 'a [@bits 3]
    ; out_count : 'a [@bits 4]
    ; set_base : 'a [@bits 3]
    ; set_count : 'a [@bits 4]
    ; in_base : 'a [@bits 3]
    ; threshold : 'a [@bits 5]
    ; timeout_vector : 'a [@bits pc_bits]
    ; timeout : 'a [@bits 16] (* max cycles a [wait ... timeout] stalls *)
    ; sideset_base : 'a [@bits 3]
    ; sideset_count : 'a [@bits 2] (* top bits of the delay field that are side-set *)
    ; clkdiv : 'a [@bits 16] (* one tick every [clkdiv] cycles; 0 and 1: every cycle *)
    ; out_msb_first : 'a (* OUT takes bits from the top of the OSR *)
    ; in_msb_first : 'a (* IN shifts the ISR left *)
    ; autopull : 'a (* an OUT that empties the OSR refills it from the TX FIFO *)
    ; autopush : 'a (* an IN that fills the ISR pushes it *)
    ; crc_poly : 'a [@bits crc_bits] (* low power first: the register shifts right *)
    ; crc_init : 'a [@bits crc_bits]
    ; crc_invert : 'a (* [mov ..., crc] reads the register inverted *)
    ; crc_in : 'a (* the register follows IN's bits, not OUT's *)
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
    ; pc : 'a [@bits pc_bits]
    ; page : 'a [@bits page_bits]
    ; x : 'a [@bits 16]
    ; y : 'a [@bits 16]
    ; isr : 'a [@bits 16]
    ; isr_count : 'a [@bits 5]
    ; osr : 'a [@bits 16]
    ; osr_count : 'a [@bits 5]
    ; delay_left : 'a [@bits 4]
    ; waiting : 'a
    ; wait_count : 'a [@bits 16]
    ; div_count : 'a [@bits 16]
    ; crc : 'a [@bits crc_bits]
    ; crc_run : 'a
    }
  [@@deriving hardcaml]
end

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; prog_we : 'a [@bits num_threads]
      (* bit n: write thread n's memory. Ignored while that thread is
         enabled, and the thread is held in its initial state for the cycle
         after a write, while the memory reads its first instruction. *)
    ; prog_addr : 'a [@bits pc_bits]
    ; prog_data : 'a [@bits 16]
    ; pin_modes : 'a [@bits 16] (* 2 bits per pin: 0 input, 1 push-pull, 2 open-drain *)
    ; pins_in : 'a [@bits 8] (* straight from the pads, asynchronous *)
    ; sync_bypass : 'a [@bits 8] (* pins read without the 2-flop synchroniser *)
    ; chain : 'a (* thread 0's RX FIFO feeds thread 1's TX FIFO *)
    ; buf_mode : 'a [@bits 2]
      (* the packet buffer: 1 plays into [buf_thread]'s TX FIFO, 2 records
         from its RX FIFO, 0 and 3 leave it to the host *)
    ; buf_thread : 'a
    ; buf_end : 'a [@bits buffer_bits] (* playing and recording stop here *)
    ; buf_set_ptr : 'a (* the host sets the pointer to [buf_ptr_in] *)
    ; buf_ptr_in : 'a [@bits buffer_bits]
    ; buf_write : 'a
      (* the host stores [buf_data] at the pointer, which moves on. Only
         while the buffer is left to the host, like [buf_read]. *)
    ; buf_data : 'a [@bits 16]
    ; buf_read : 'a (* the host has taken the word at the pointer, which moves on *)
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
    ; buf_ptr : 'a [@bits buffer_bits]
    ; buf_word : 'a [@bits 16] (* the word at the pointer *)
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
   thread. The rest are in how the threads are put together. *)
module Mutation = struct
  type t =
    | Xdec_never_decrements
    | Wait_timeout_ignores_budget
    | Delay_field_ignored
    | Set_pins_count_off_by_one
    | Push_not_right_justified
    | Pin_priority_inverted (* thread 0 wins a pin both threads write *)
    | Fetch_port_crossed (* thread 1 fetches from thread 0's pc *)
    | Chain_ignores_full (* the chain moves a word into a full FIFO, losing it *)
    | Push_ignores_in_direction
      (* PUSH right-justifies as if IN were always LSB first *)
    | Sync_bypass_inverted
      (* SYNC_BYPASS read with the wrong polarity: bypassed pins go through
         the synchroniser and synchronised ones skip it *)
    | Jump_ignores_page (* a jump stays in the page the pc is in *)
    | Write_lands_while_running
      (* a host write to a running thread's memory lands, taking the
         memory's address from the fetch *)
    | No_hold_after_write
      (* a thread enabled in the cycle after a write to its memory runs at
         once, on whatever the memory last read *)
    | Autopull_ignores_empty (* autopull loads the OSR from an empty TX FIFO *)
    | Autopush_ignores_full (* an autopushing IN goes ahead with the RX FIFO full *)
    | Crc_ignores_direction (* the CRC takes its bits LSB first whatever the shift direction *)
    | Crc_read_keeps_running (* reading the CRC register does not stop it *)
    | Play_ignores_full (* the buffer plays a word into a full TX FIFO, losing it *)
    | Play_past_end (* the buffer plays on when the pointer has reached the end *)
    | Record_keeps_host_pop (* the host can still pop the FIFO the buffer records from *)
    | Play_after_write (* a word is played in the cycle after a write, before the memory has read it *)
  [@@deriving sexp_of, enumerate, equal]
end

let bit s i = select s i i

(* Shift right by a runtime amount of 0..16, through a 32-bit intermediate so
   shifting by the full width is well defined. [hi] supplies the bits that
   shift in from the top. *)
let shift_right ~hi lo ~by = uresize (log_shift srl (hi @: lo) by) 16

(* Shift left by 0..16, zeros in from the bottom, through 32 bits so that
   shifting by the full width clears the word. *)
let shift_left x ~by = uresize (log_shift sll (uresize x 32) by) 16

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
    { pc : 'a [@bits pc_bits]
    ; page : 'a [@bits page_bits]
      (* a jump goes to [page @: instr[5:0]]; set only by [set page] and,
         while disabled, to the page of [start] *)
    ; x : 'a [@bits 16]
    ; y : 'a [@bits 16]
    ; isr : 'a [@bits 16]
    ; isr_count : 'a [@bits 5]
    ; osr : 'a [@bits 16]
    ; osr_count : 'a [@bits 5]
    ; delay_left : 'a [@bits 4]
    ; waiting : 'a
    ; wait_count : 'a [@bits 16]
    ; crc : 'a [@bits crc_bits]
    ; crc_run : 'a (* the CRC register is following the data *)
    ; pin_out : 'a [@bits 8]
    }
  [@@deriving hardcaml]
end

module Step_in = struct
  type 'a t =
    { enable : 'a
    ; tick : 'a (* from the thread's clock divider; low: hold everything *)
    ; instr : 'a [@bits 16]
    ; lines : 'a [@bits 8]
    ; tx_empty : 'a
    ; tx_head : 'a [@bits 16]
    ; rx_full : 'a
    ; start : 'a [@bits pc_bits]
    ; out_base : 'a [@bits 3]
    ; out_count : 'a [@bits 4]
    ; set_base : 'a [@bits 3]
    ; set_count : 'a [@bits 4]
    ; in_base : 'a [@bits 3]
    ; threshold : 'a [@bits 5]
    ; timeout_vector : 'a [@bits pc_bits]
    ; timeout : 'a [@bits 16]
    ; sideset_base : 'a [@bits 3]
    ; sideset_count : 'a [@bits 2]
    ; out_msb_first : 'a
    ; in_msb_first : 'a
    ; autopull : 'a
    ; autopush : 'a
    ; crc_poly : 'a [@bits crc_bits]
    ; crc_init : 'a [@bits crc_bits]
    ; crc_invert : 'a
    ; crc_in : 'a
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
  let page = w s.page in
  let x = w s.x in
  let y = w s.y in
  let isr = w s.isr in
  let isr_count = w s.isr_count in
  let osr = w s.osr in
  let osr_count = w s.osr_count in
  let delay_left = w s.delay_left in
  let waiting = w s.waiting in
  let wait_count = w s.wait_count in
  let crc = w s.crc in
  let crc_run = w s.crc_run in
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
  let executing = i.enable &: i.tick &: (s.delay_left ==:. 0) in
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
  (* MOV: source/destination 7 is reserved, making the whole instruction
     a NOP. 6 is the CRC register. *)
  let mov_dst = select instr 8 6 in
  let mov_src = select instr 5 3 in
  let mov_valid = (mov_dst <:. 7) &: (mov_src <:. 7) in
  let set_dst = select instr 8 7 in
  (* Autopull: an OUT that finds the OSR empty spends this tick fetching.
     Autopush: an IN that would fill the ISR waits while the RX FIFO is
     full. *)
  let tx_has = if is Autopull_ignores_empty then vdd else ~:(i.tx_empty) in
  let out_fetches = is_op 3 &: i.autopull &: (s.osr_count >=: i.threshold) in
  let in_fills =
    is_op 2 &: i.autopush &: (uresize s.isr_count 6 +: uresize count 6 >=: uresize i.threshold 6)
  in
  let in_waits = if is Autopush_ignores_full then gnd else in_fills &: i.rx_full in
  (* --- Control: stall, or move to the next/target instruction. --- *)
  let stall =
    (is_op 1 &: ~:wait_ok &: ~:wait_expired)
    |: (is_op 4 &: is_pull &: i.tx_empty)
    |: (is_op 4 &: ~:is_pull &: i.rx_full)
    |: out_fetches
    |: in_waits
  in
  let goto_ = (is_op 0 &: cond_true) |: (is_op 1 &: ~:wait_ok &: wait_expired) in
  let jump_page =
    if is Jump_ignores_page then select s.pc (pc_bits - 1) (pc_bits - page_bits) else s.page
  in
  let target = mux2 (is_op 0) (jump_page @: select instr 5 0) i.timeout_vector in
  let next_pc = mux2 goto_ target (s.pc +:. 1) in
  let advance = executing &: ~:stall in
  (* --- Datapath values. --- *)
  let in_value =
    mux
      (select instr 8 7)
      [ read_pins ~lines:i.lines ~base:i.in_base ~count; s.x; s.y; zero 16 ]
  in
  let out_mask = ~:(uresize (log_shift sll (ones 32) count) 16) in
  (* The ISR and the OSR's count as an IN or an OUT leaves them. *)
  let isr_in =
    mux2
      i.in_msb_first
      (shift_left s.isr ~by:count |: (in_value &: out_mask))
      (shift_right ~hi:in_value s.isr ~by:count)
  in
  let isr_count_in = saturating_add s.isr_count count in
  let osr_count_out = saturating_add s.osr_count count in
  (* What a push sends: the bits shifted in, right-justified. *)
  let justified isr isr_count =
    let lsb_first = shift_right ~hi:(zero 16) isr ~by:(of_int ~width:5 16 -: isr_count) in
    (* MSB first: the bits shifted in sit at the bottom of the ISR. *)
    let msb_first = isr &: ~:(uresize (log_shift sll (ones 32) isr_count) 16) in
    if is Push_not_right_justified
    then isr
    else if is Push_ignores_in_direction
    then lsb_first
    else mux2 i.in_msb_first msb_first lsb_first
  in
  let autopush = advance &: in_fills in
  (* An OUT that empties the OSR takes the next word in the same tick. *)
  let refill = advance &: is_op 3 &: i.autopull &: (osr_count_out >=: i.threshold) &: tx_has in
  let fetch = executing &: out_fetches &: tx_has in
  let pull = (executing &: is_op 4 &: is_pull &: ~:(i.tx_empty)) |: refill |: fetch in
  let push = (executing &: is_op 4 &: ~:is_pull &: ~:(i.rx_full)) |: autopush in
  let push_value = mux2 (is_op 2) (justified isr_in isr_count_in) (justified s.isr s.isr_count) in
  (* LSB first: the low [count] bits. MSB first: the top [count] bits,
     brought down to the bottom. *)
  let out_data =
    mux2
      i.out_msb_first
      (shift_right ~hi:(zero 16) s.osr ~by:(of_int ~width:5 16 -: count))
      (s.osr &: out_mask)
  in
  let crc_read = select (s.crc ^: repeat i.crc_invert crc_bits) 15 0 in
  let mov_value =
    mux mov_src [ s.x; s.y; uresize i.lines 16; s.isr; s.osr; zero 16; crc_read ]
  in
  (* The CRC register after it has taken this instruction's first bit:
     the lowest of the bits shifted, or the highest when shifting MSB
     first. *)
  let crc_taken =
    let data = mux2 i.crc_in (in_value &: out_mask) out_data in
    let msb_first = mux2 i.crc_in i.in_msb_first i.out_msb_first in
    let msb_first = if is Crc_ignores_direction then gnd else msb_first in
    let first = mux2 msb_first (mux (select (count -:. 1) 3 0) (bits_lsb data)) (bit data 0) in
    srl s.crc 1 ^: (i.crc_poly &: repeat (bit s.crc 0 ^: first) crc_bits)
  in
  let crc_takes = advance &: s.crc_run &: mux2 i.crc_in (is_op 2) (is_op 3) in
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
        ; page <-- select i.start (pc_bits - 1) (pc_bits - page_bits)
        ; x <--. 0
        ; y <--. 0
        ; isr <--. 0
        ; isr_count <--. 0
        ; osr <--. 0
        ; osr_count <-- i.threshold
        ; delay_left <--. 0
        ; waiting <--. 0
        ; wait_count <--. 0
        ; crc <-- i.crc_init
        ; crc_run <--. 1
        ]
      @@ elif
           ~:(i.tick)
           [ (* Between clock-divider ticks: nothing changes. *) ]
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
           ; when_ fetch [ osr <-- i.tx_head; osr_count <--. 0 ]
           ; when_ crc_takes [ crc <-- crc_taken ]
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
                     , [ isr <-- isr_in
                       ; isr_count <-- isr_count_in
                       ; when_ in_fills [ isr <--. 0; isr_count <--. 0 ]
                       ] )
                   ; ( of_int ~width:3 3
                     , [ osr
                         <-- mux2
                               i.out_msb_first
                               (shift_left s.osr ~by:count)
                               (shift_right ~hi:(zero 16) s.osr ~by:count)
                       ; osr_count <-- osr_count_out
                       ; when_ refill [ osr <-- i.tx_head; osr_count <--. 0 ]
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
                           ; (* Reading the CRC register leaves its high half in
                                its low half and stops it; writing it starts it
                                again, and comes second. *)
                             when_
                               (mov_src ==:. 6)
                               [ crc <-- srl s.crc 16
                               ; (crc_run <-- if is Crc_read_keeps_running then s.crc_run else gnd)
                               ]
                           ; when_ (mov_dst ==:. 6) [ crc <-- i.crc_init; crc_run <--. 1 ]
                           ]
                       ] )
                   ; ( of_int ~width:3 6
                     , [ switch
                           set_dst
                           [ of_int ~width:2 1, [ x <-- set_value ]
                           ; of_int ~width:2 2, [ y <-- set_value ]
                           ; of_int ~width:2 3, [ page <-- select instr (page_bits - 1) 0 ]
                           ]
                       ] )
                   ]
               ]
           ]
    ];
  { Step_out.next =
      { Thread_state.pc = pc.value
      ; page = page.value
      ; x = x.value
      ; y = y.value
      ; isr = isr.value
      ; isr_count = isr_count.value
      ; osr = osr.value
      ; osr_count = osr_count.value
      ; delay_left = delay_left.value
      ; waiting = waiting.value
      ; wait_count = wait_count.value
      ; crc = crc.value
      ; crc_run = crc_run.value
      ; pin_out = pin_out.value
      }
  ; pull
  ; push
  ; push_value
  }
;;

(* How a thread's program memory is built. Both give the same thing: a
   memory of [program_size] words that registers its address, so that
   [dout] in one cycle is the word at the [addr] of the cycle before, or is
   unspecified if that cycle was a write. Reset does not touch it.

   [Macro] instantiates IHP's SRAM macro, and is what the chip is built
   from. [Model] is that behaviour in flip-flops, for simulation and the
   proofs; on a write cycle its [dout] holds, which no thread can observe,
   because a thread is held in its initial state in the cycle after a
   write to its memory. *)
module Memory = struct
  type t =
    | Macro
    | Model
    | Proof
      (* for the equivalence proofs: the program memories as [Model], the
         packet buffer as [Macro]. The checker pairs the buffer on the two
         sides by its instance name, gives both the same arbitrary word
         out of it each cycle, and requires everything driven into it to
         be equal: sixteen thousand flip-flops and a 1024-way multiplexer
         on each side were more than it could finish. *)
  [@@deriving sexp_of, equal]
end

(* One memory of [words] words of 16 bits, either way. [prefix] names the
   model's registers and [instance] the macro. *)
let memory_block (memory : Memory.t) ~clock ~words ~prefix ~instance ~we ~addr ~data =
  match memory with
  | Proof -> raise_s [%message "memory_block: the caller picks Model or Macro"]
  | Model ->
    let spec = Reg_spec.create ~clock () in
    let cells =
      List.init words ~f:(fun a ->
        reg spec ~enable:(we &: (addr ==:. a)) data -- sprintf "%s_%d" prefix a)
    in
    let next = wire 16 in
    let dout = reg spec next -- sprintf "%s_dout" prefix in
    next <== mux2 we dout (mux addr cells);
    dout
  | Macro ->
    let bits = Int.ceil_log2 words in
    let inst =
      Instantiation.create
        ()
        ~instance
        ~name:(sprintf "RM_IHPSG13_1P_%dx16_c2_bm_bist" words)
        ~inputs:
          [ "A_CLK", clock
          ; "A_MEN", vdd
          ; "A_WEN", we
          ; "A_REN", ~:we
          ; "A_ADDR", addr
          ; "A_DIN", data
          ; "A_DLY", vdd
          ; "A_BM", ones 16
          ; "A_BIST_CLK", gnd
          ; "A_BIST_EN", gnd
          ; "A_BIST_MEN", gnd
          ; "A_BIST_WEN", gnd
          ; "A_BIST_REN", gnd
          ; "A_BIST_ADDR", zero bits
          ; "A_BIST_DIN", zero 16
          ; "A_BIST_BM", zero 16
          ]
        ~outputs:[ "A_DOUT", 16 ]
    in
    Map.find_exn inst "A_DOUT"
;;

let program_memory (memory : Memory.t) ~clock ~n ~we ~addr ~data =
  memory_block
    (match memory with
     | Proof -> Model
     | m -> m)
    ~clock
    ~words:program_size
    ~prefix:(sprintf "t%d_prog" n)
    ~instance:(sprintf "sram%d" n)
    ~we
    ~addr
    ~data
;;

let create ?mutation ?datapath ?(memory = Memory.Model) (i : _ I.t) : _ O.t =
  let is m = Option.value_map mutation ~default:false ~f:(Mutation.equal m) in
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  (* --- The shared pin register. Resets to all ones: idle-high for UART,
     released for open-drain. --- *)
  let pin_next = wire num_pins in
  let pin_out =
    reg (Reg_spec.override spec ~clear_to:(ones num_pins)) pin_next -- "pin_out"
  in
  (* --- External inputs into the clock domain: two flip-flops per pin, so
     a level that changes as the first one samples it has a full cycle to
     settle before any logic sees it. Reset high, like the idle bus. Pins in
     [sync_bypass] are read directly, for protocols that cannot afford the
     two-cycle delay. --- *)
  let sync_spec = Reg_spec.override spec ~clear_to:(ones num_pins) in
  let sync1 = reg sync_spec i.pins_in -- "pins_sync1" in
  let sync2 = reg sync_spec sync1 -- "pins_sync2" in
  let bypass = if is Sync_bypass_inverted then ~:(i.sync_bypass) else i.sync_bypass in
  let ext_in = (i.pins_in &: bypass) |: (sync2 &: ~:bypass) in
  (* --- Pin levels seen by both threads this cycle. --- *)
  let mode p = select i.pin_modes ((2 * p) + 1) (2 * p) in
  let lines =
    concat_lsb
      (List.init num_pins ~f:(fun p ->
         let ext = bit ext_in p in
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
  (* --- Program memories. A write lands only while the thread is disabled.
     The thread is then held disabled for one more cycle, in which the
     memory reads the instruction at [start]. Otherwise the address is the
     thread's next pc. --- *)
  let loading =
    List.init num_threads ~f:(fun n ->
      if is Write_lands_while_running
      then bit i.prog_we n
      else bit i.prog_we n &: ~:((I.thread i n).enable))
  in
  let enables =
    List.init num_threads ~f:(fun n ->
      let loaded = reg spec (List.nth_exn loading n) -- sprintf "t%d_loaded" n in
      if is No_hold_after_write
      then
        (* The register stays in the circuit, so that the equivalence
           checker can still pair it with the spec's. *)
        (I.thread i n).enable |: (loaded &: ~:loaded)
      else (I.thread i n).enable &: ~:loaded)
  in
  let fetch n =
    let next_pc m =
      let (d : _ Thread_state.t), _ = List.Assoc.find_exn threads ~equal:Int.equal m in
      d.pc
    in
    let we = List.nth_exn loading n in
    program_memory
      memory
      ~clock:i.clock
      ~n
      ~we
      ~addr:(mux2 we i.prog_addr (next_pc (if n = 1 && is Fetch_port_crossed then 0 else n)))
      ~data:i.prog_data
  in
  (* --- Clock dividers: the thread ticks when its counter is 0, then
     reloads it with [clkdiv - 1]. Held at 0 while disabled, so a thread's
     first enabled cycle is a tick. --- *)
  let dividers =
    List.map threads ~f:(fun (n, _) ->
      let ti = I.thread i n in
      let d = wire 16 in
      let q = reg spec d -- sprintf "t%d_div_count" n in
      let tick = q ==:. 0 in
      d
      <== mux2
            ~:(List.nth_exn enables n)
            (zero 16)
            (mux2 tick (mux2 (ti.clkdiv ==:. 0) (zero 16) (ti.clkdiv -:. 1)) (q -:. 1));
      q, tick)
  in
  (* --- FIFOs. The thread-side strobes are wires, assigned when the
     thread's step is built. With [chain] set, a mover takes thread 0's RX
     head into thread 1's TX FIFO whenever the first is non-empty and the
     second not full (both judged at the start of the cycle), and the host
     loses access to those two ends. --- *)
  let move = wire 1 in
  let move_data = wire 16 in
  (* The packet buffer's moves, assigned below: a word played into
     [buf_thread]'s TX FIFO, or recorded from its RX FIFO. While it plays or
     records, that end of that FIFO is not the host's. *)
  let play = wire 1 in
  let record = wire 1 in
  let buf_word = wire 16 in
  let buffers n mode = (i.buf_mode ==:. mode) &: (i.buf_thread ==:. n) in
  let fifos =
    List.map threads ~f:(fun (n, _) ->
      let ti = I.thread i n in
      let pull = wire 1 in
      let push = wire 1 in
      let push_value = wire 16 in
      let played = play &: (i.buf_thread ==:. n) in
      let recorded = record &: (i.buf_thread ==:. n) in
      let tx_push = ti.tx_push &: ~:(buffers n 1) in
      let rx_pop =
        if is Record_keeps_host_pop then ti.rx_pop else ti.rx_pop &: ~:(buffers n 2)
      in
      let from_host = mux2 played buf_word ti.tx_data in
      let host_push, host_data =
        if n = 1
        then move |: played |: (tx_push &: ~:(i.chain)), mux2 move move_data from_host
        else played |: tx_push, from_host
      in
      let host_pop =
        (if n = 0 then move |: (rx_pop &: ~:(i.chain)) else rx_pop) |: recorded
      in
      let tx =
        Tiny_fifo.create
          ~name:(sprintf "t%d_tx" n)
          spec
          ~push:host_push
          ~data:host_data
          ~pop:pull
      in
      let rx =
        Tiny_fifo.create
          ~name:(sprintf "t%d_rx" n)
          spec
          ~push
          ~data:push_value
          ~pop:host_pop
      in
      pull, push, push_value, tx, rx)
  in
  (let _, _, _, _, (rx0 : Tiny_fifo.t) = List.nth_exn fifos 0 in
   let _, _, _, (tx1 : Tiny_fifo.t), _ = List.nth_exn fifos 1 in
   let room = if is Chain_ignores_full then vdd else ~:(tx1.full) in
   move <== (i.chain &: ~:(rx0.empty) &: room);
   move_data <== rx0.head);
  (* --- The packet buffer. One word a cycle moves between it and the
     FIFO it stands at, judged at the start of the cycle like the chain; an
     end the chain owns is not the buffer's. Like a program memory it
     answers a cycle after it is asked, so it is asked for the word the
     pointer will be at next cycle, and in a cycle with a write it is not
     asked at all: nothing is played in the cycle after one. --- *)
  let buf_ptr =
    let _, _, _, (tx0 : Tiny_fifo.t), (rx0 : Tiny_fifo.t) = List.nth_exn fifos 0 in
    let _, _, _, (tx1 : Tiny_fifo.t), (rx1 : Tiny_fifo.t) = List.nth_exn fifos 1 in
    let ptr_next = wire buffer_bits in
    let ptr = reg spec ptr_next -- "buf_ptr" in
    let we = wire 1 in
    let wrote = reg spec we -- "buf_wrote" in
    let left_to_host = (i.buf_mode ==:. 0) |: (i.buf_mode ==:. 3) in
    let more = if is Play_past_end then vdd else ptr <>: i.buf_end in
    (* The planted bug keeps the register in the circuit, so that the
       equivalence checker can still pair it with the spec's. *)
    let settled = if is Play_after_write then ~:wrote |: wrote else ~:wrote in
    let room = if is Play_ignores_full then vdd else ~:(mux2 i.buf_thread tx1.full tx0.full) in
    play <== ((i.buf_mode ==:. 1) &: more &: settled &: ~:(i.chain &: i.buf_thread) &: room);
    record
    <== ((i.buf_mode ==:. 2)
         &: (ptr <>: i.buf_end)
         &: ~:(i.chain &: ~:(i.buf_thread))
         &: ~:(mux2 i.buf_thread rx1.empty rx0.empty));
    let host_write = i.buf_write &: left_to_host in
    let host_read = i.buf_read &: left_to_host in
    we <== (record |: host_write);
    ptr_next
    <== mux2
          i.buf_set_ptr
          i.buf_ptr_in
          (mux2 (play |: record |: host_write |: host_read) (ptr +:. 1) ptr);
    buf_word
    <== memory_block
          (match memory with
           | Proof -> Macro
           | m -> m)
          ~clock:i.clock
          ~words:buffer_size
          ~prefix:"buf"
          ~instance:"sram_buf"
          ~we
          ~addr:(mux2 we ptr ptr_next)
          ~data:(mux2 record (mux2 i.buf_thread rx1.head rx0.head) i.buf_data);
    ptr
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
          { Step_in.enable = List.nth_exn enables n
          ; tick = snd (List.nth_exn dividers n)
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
          ; out_msb_first = ti.out_msb_first
          ; in_msb_first = ti.in_msb_first
          ; autopull = ti.autopull
          ; autopush = ti.autopush
          ; crc_poly = ti.crc_poly
          ; crc_init = ti.crc_init
          ; crc_invert = ti.crc_invert
          ; crc_in = ti.crc_in
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
    ; page = q.page
    ; x = q.x
    ; y = q.y
    ; isr = q.isr
    ; isr_count = q.isr_count
    ; osr = q.osr
    ; osr_count = q.osr_count
    ; delay_left = q.delay_left
    ; waiting = q.waiting
    ; wait_count = q.wait_count
    ; div_count = fst (List.nth_exn dividers n)
    ; crc = q.crc
    ; crc_run = q.crc_run
    }
  in
  { O.pin_out; pads_out; pads_oe; buf_ptr; buf_word; t0 = thread_out 0; t1 = thread_out 1 }
;;
