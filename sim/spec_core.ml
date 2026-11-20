(* An independent specification of the whole two-thread core: everything in
   [Pe_core.create] (program memory, input synchronisers, pin levels, clock
   dividers, FIFOs, CHAIN, the order the threads write the shared pin
   register, the pads), with the spec datapath ([Spec_step]) for each
   thread.

   It is written from docs/isa.md and the reference model's [Isa.step], not
   from the RTL, and in a different style: plain functional next-state
   equations instead of [Always] blocks, every rule stated the way the
   documentation states it. What it shares with the RTL is only what the
   equivalence checker needs to line the two up: the register names and
   widths, and the FIFO's state encoding (write pointer, read pointer, level,
   four storage words). Hardcaml's checker cuts both circuits at their
   registers and pairs them by name, so the two must hold the same state in
   the same form; the logic that computes the next state from it is what is
   compared.

   sim/test_formal.ml proves the RTL core equal to this, for every state of
   every register and every input, in one clock. *)

open! Core
open! Hardcaml
open! Signal
module P = Pe_hw.Pe_core
module Spec = Spec_step.Make (Signal)

let depth = 4
let bit s p = select s p p

(* A FIFO of [depth] words, from the documented rules: a push into a full
   FIFO and a pop from an empty one do nothing; full, empty, level and the
   head are as they were at the start of the cycle. *)
module Fifo = struct
  type t =
    { head : Signal.t
    ; level : Signal.t
    ; full : Signal.t
    ; empty : Signal.t
    }

  let create spec ~name ~push ~data ~pop =
    let named s n = s -- sprintf "%s_%s" name n in
    let wr_next = wire 2
    and rd_next = wire 2
    and level_next = wire 3 in
    let wr = named (reg spec wr_next) "wr"
    and rd = named (reg spec rd_next) "rd"
    and level = named (reg spec level_next) "level" in
    let full = level ==:. depth
    and empty = level ==:. 0 in
    let accepted = push &: ~:full
    and taken = pop &: ~:empty in
    wr_next <== mux2 accepted (wr +:. 1) wr;
    rd_next <== mux2 taken (rd +:. 1) rd;
    (* one in and none out: one more; one out and none in: one fewer *)
    level_next
    <== mux2 (accepted ^: taken) (mux2 accepted (level +:. 1) (level -:. 1)) level;
    let words =
      List.init depth ~f:(fun k ->
        named (reg spec ~enable:(accepted &: (wr ==:. k)) data) (sprintf "mem_%d" k))
    in
    { head = mux rd words; level; full; empty }
  ;;
end

(* [planted_chain_bug] plants a bug in this spec, not in the RTL: the CHAIN
   mover ignores a full destination FIFO. The proof must then fail, which
   shows it really compares the RTL with this file's composition logic. *)
(* The bit sampler given one sample of its pin, from the model's rules, in
   the order the model states them:

   - an edge is a sample that differs from the one before; it is accepted if
     the phase is not below [blank], and the phase then starts again;
   - otherwise, if the phase is not below [wrap], a bit time has gone by.
     With the carrier there and a miss still allowed ([misses] 7 allows any
     number) the phase starts again and the miss is counted; if not, the
     carrier is lost;
   - otherwise the phase moves on by one;
   - with no carrier there is no sync and no history;
   - a sample that leaves the phase at [sample], with the carrier there, is
     a bit: it enters the history, the history may now be the sync word,
     and the bit is passed on if the sync word had been seen before it, or
     is not asked for. *)
let sampler_sample (c : _ P.Sampler_in.t) (s : _ P.Sampler_state.t) level =
  let changed = level <>: s.last in
  let accepted = changed &: ~:(s.phase <: c.blank) in
  let bit_time_gone = ~:accepted &: ~:(s.phase <: c.wrap) in
  let counted = c.misses <>:. 7 in
  let allowed = ~:counted |: (s.missed <: c.misses) in
  let carried = bit_time_gone &: s.carrier &: allowed in
  let lost = bit_time_gone &: ~:carried in
  let moves_on = ~:accepted &: ~:bit_time_gone in
  let phase =
    priority_select_with_default
      [ { valid = accepted |: carried; value = zero 5 }
      ; { valid = moves_on; value = s.phase +:. 1 }
      ]
      ~default:s.phase
  in
  let missed =
    priority_select_with_default
      [ { valid = accepted; value = zero 3 }
      ; { valid = carried &: counted; value = s.missed +:. 1 }
      ]
      ~default:s.missed
  in
  let carrier = accepted |: (s.carrier &: ~:lost) in
  let is_bit = carrier &: (phase ==: c.sample) in
  let value = mux2 c.invert ~:level level in
  let history = mux2 is_bit (concat_lsb [ select s.history 7 1; value ]) s.history in
  let passed = is_bit &: mux2 c.sync_enable s.synced vdd in
  ( { P.Sampler_state.last = level
    ; phase
    ; missed
    ; carrier
    ; synced = mux2 carrier (s.synced |: (is_bit &: (history ==: c.sync))) gnd
    ; history = mux2 carrier history (zero 8)
    ; data = mux2 passed value s.data
    }
  , passed )
;;

let create ?(planted_chain_bug = false) (i : _ P.I.t) : _ P.O.t =
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let high = Reg_spec.override spec ~clear_to:(ones P.num_pins) in
  (* Program memory, one per thread. "A write to the memory of an enabled
     thread is ignored": word [a] of thread n's memory takes [prog_data]
     when the host writes [a] there and the thread is disabled. Reset does
     not touch a memory.

     A memory answers a cycle late: [dout] is the word at the address it
     was given the cycle before. It is given the pc the thread is about to
     have, so [dout] is the instruction at the pc the thread has. In a cycle
     with a write it reads nothing, which is why "the thread is held in its
     initial state for the cycle after a write": [loaded] remembers it. *)
  let unreset = Reg_spec.create ~clock:i.clock () in
  let memory n (c : _ P.Thread_in.t) ~next_pc =
    let written = select i.prog_we n n &: (c.enable ==:. 0) in
    let words =
      List.init P.program_size ~f:(fun a ->
        reg unreset ~enable:(written &: (i.prog_addr ==:. a)) i.prog_data
        -- sprintf "t%d_prog_%d" n a)
    in
    let dout_next = wire 16 in
    let dout = reg unreset dout_next -- sprintf "t%d_prog_dout" n in
    dout_next <== mux2 written dout (mux next_pc words);
    let loaded = reg spec written -- sprintf "t%d_loaded" n in
    dout, c.enable &: (loaded ==:. 0)
  in
  (* "A level that arrives during cycle t is seen by the threads in cycle
     t + 2", except on the pins in SYNC_BYPASS, which are read directly. *)
  let sync1 = reg high i.pins_in -- "pins_sync1" in
  let sync2 = reg high sync1 -- "pins_sync2" in
  let external_ =
    concat_lsb
      (List.init P.num_pins ~f:(fun p ->
         mux2 (bit i.sync_bypass p) (bit i.pins_in p) (bit sync2 p)))
  in
  let pin_out_next = wire P.num_pins in
  let pin_out = reg high pin_out_next -- "pin_out" in
  let mode p = select i.pin_modes ((2 * p) + 1) (2 * p) in
  let push_pull p = mode p ==:. 1
  and open_drain p = mode p ==:. 2 in
  (* Pin levels table: input: the external level; push-pull: the output
     register; open-drain: low if either side pulls it low. Mode 3 is
     reserved and reads as an input. *)
  let lines =
    concat_lsb
      (List.init P.num_pins ~f:(fun p ->
         let ext = bit external_ p
         and out = bit pin_out p in
         mux2 (push_pull p) out (mux2 (open_drain p) (out &: ext) ext)))
  in
  (* The bit sampler. "The sampler's two samples of this cycle, half a cycle
     apart: the pin at the rising edge two cycles back, from the
     synchroniser, and at the falling edge after it." A disabled sampler is
     held at its initial state, which is all zeros; the flip-flop that
     brings in the falling-edge sample follows it always. *)
  let smp_mid = reg spec i.smp.fall -- "smp_mid" in
  let smp, smp_strobe =
    let next = P.Sampler_state.map P.Sampler_state.port_widths ~f:wire in
    let now =
      P.Sampler_state.map2 next P.Sampler_state.port_names ~f:(fun d name ->
        reg spec d -- ("smp_" ^ name))
    in
    let on = i.smp.enable in
    let early = bit (log_shift srl sync2 i.smp.pin) 0 in
    let between, first_passed = sampler_sample i.smp now early in
    let after, second_passed = sampler_sample i.smp between smp_mid in
    P.Sampler_state.iter2 next after ~f:(fun d v -> d <== (v &: repeat on (width v)));
    now, reg spec (on &: (first_passed |: second_passed)) -- "smp_strobe"
  in
  (* "With the bit sampler enabled, two pins show the threads what it has
     recovered instead of their own levels": the bit on its pin, the pulse on
     the pin after it, counting round from 7 to 0. *)
  let lines =
    let shows_bit = binary_to_onehot i.smp.pin &: repeat i.smp.enable P.num_pins in
    let shows_pulse = rotl shows_bit 1 in
    (shows_bit &: repeat smp.data P.num_pins)
    |: (shows_pulse &: repeat smp_strobe P.num_pins)
    |: (lines &: ~:(shows_bit |: shows_pulse))
  in
  (* Thread state, one register per field, except the pin register, which
     is shared. *)
  let thread_regs n =
    let next = P.Thread_state.map P.Thread_state.port_widths ~f:wire in
    let fields = P.Thread_state.map2 next P.Thread_state.port_names ~f:(fun d name ->
      if String.equal name "pin_out" then d else reg spec d -- sprintf "t%d_%s" n name)
    in
    next, fields
  in
  let t0_next, t0 = thread_regs 0
  and t1_next, t1 = thread_regs 1 in
  (* "The thread runs one cycle in every clkdiv (0 and 1: every cycle).
     Its first tick is the first cycle it is enabled." *)
  let instr0, enabled0 = memory 0 i.t0 ~next_pc:t0_next.pc
  and instr1, enabled1 = memory 1 i.t1 ~next_pc:t1_next.pc in
  let enabled n = if n = 0 then enabled0 else enabled1 in
  let divider n (c : _ P.Thread_in.t) =
    let count_next = wire 16 in
    let count = reg spec count_next -- sprintf "t%d_div_count" n in
    let tick = count ==:. 0 in
    let period_minus_one = mux2 (c.clkdiv <=:. 1) (zero 16) (c.clkdiv -:. 1) in
    count_next
    <== mux2 (~:(enabled n)) (zero 16) (mux2 tick period_minus_one (count -:. 1));
    count, tick
  in
  let div0, tick0 = divider 0 i.t0
  and div1, tick1 = divider 1 i.t1 in
  (* FIFOs. The threads' own strobes come from their steps below. *)
  let pull0 = wire 1
  and push0 = wire 1
  and value0 = wire 16 in
  let pull1 = wire 1
  and push1 = wire 1
  and value1 = wire 16 in
  (* CHAIN: "in any cycle that starts with the first non-empty and the
     second not full, one word moves across. While chained, the host cannot
     pop thread 0's RX FIFO or push to thread 1's TX FIFO." *)
  let moves = wire 1 in
  let host_ok = ~:(i.chain) in
  (* The packet buffer: "[Play] makes it the source of one thread's TX FIFO:
     while the pointer has not reached the end and that FIFO has room, one
     word a cycle moves from the buffer into it. [Record] makes it the sink
     of one thread's RX FIFO in the same way." While it does either, the
     host cannot use that end of that FIFO. *)
  let plays = wire 1
  and records = wire 1
  and buf_word = wire 16 in
  let playing n = (i.buf_mode ==:. 1) &: (i.buf_thread ==:. n)
  and recording n = (i.buf_mode ==:. 2) &: (i.buf_thread ==:. n) in
  let played n = plays &: (i.buf_thread ==:. n)
  and recorded n = records &: (i.buf_thread ==:. n) in
  let tx0 =
    Fifo.create
      spec
      ~name:"t0_tx"
      ~push:(played 0 |: (i.t0.tx_push &: ~:(playing 0)))
      ~data:(mux2 (played 0) buf_word i.t0.tx_data)
      ~pop:pull0
  in
  let rx0 =
    Fifo.create
      spec
      ~name:"t0_rx"
      ~push:push0
      ~data:value0
      ~pop:(moves |: recorded 0 |: (host_ok &: i.t0.rx_pop &: ~:(recording 0)))
  in
  let tx1 =
    Fifo.create
      spec
      ~name:"t1_tx"
      ~push:(moves |: played 1 |: (host_ok &: i.t1.tx_push &: ~:(playing 1)))
      ~data:(mux2 moves rx0.head (mux2 (played 1) buf_word i.t1.tx_data))
      ~pop:pull1
  in
  let rx1 =
    Fifo.create
      spec
      ~name:"t1_rx"
      ~push:push1
      ~data:value1
      ~pop:(recorded 1 |: (i.t1.rx_pop &: ~:(recording 1)))
  in
  moves <== (i.chain &: ~:(rx0.empty) &: (if planted_chain_bug then vdd else ~:(tx1.full)));
  (* The buffer's own state: the pointer, the memory, and whether it was
     written in the last cycle. "An end the chain owns is not the
     buffer's": thread 1's TX FIFO and thread 0's RX FIFO. "Nothing is
     played in the cycle after a write." The host stores and takes words
     only while the buffer is neither playing nor recording. *)
  let buf_ptr =
    let next = wire P.buffer_bits in
    let ptr = reg spec next -- "buf_ptr" in
    let stores = wire 1 in
    let wrote = reg spec stores -- "buf_wrote" in
    let of_thread a b = mux2 i.buf_thread b a in
    let not_at_end = ptr <>: i.buf_end in
    plays
    <== ((i.buf_mode ==:. 1)
         &: not_at_end
         &: (wrote ==:. 0)
         &: ~:(i.chain &: (i.buf_thread ==:. 1))
         &: ~:(of_thread tx0.full tx1.full));
    records
    <== ((i.buf_mode ==:. 2)
         &: not_at_end
         &: ~:(i.chain &: (i.buf_thread ==:. 0))
         &: ~:(of_thread rx0.empty rx1.empty));
    let hosts = (i.buf_mode <>:. 1) &: (i.buf_mode <>:. 2) in
    let host_stores = hosts &: i.buf_write
    and host_takes = hosts &: i.buf_read in
    stores <== (records |: host_stores);
    let moves_on = plays |: records |: host_stores |: host_takes in
    next <== mux2 i.buf_set_ptr i.buf_ptr_in (mux2 moves_on (ptr +:. 1) ptr);
    (* The memory itself is not described here: it is named. The proof
       gives this side and the RTL the same arbitrary word out of it in
       every cycle and requires everything driven into it to be equal, so
       what is specified is how it is used: it is written at the pointer
       with the word being stored, and otherwise asked for the word the
       pointer is about to be at, since "it answers a cycle after it is
       asked". The rest of its pins are held as the chip holds them. *)
    let stored = mux2 records (of_thread rx0.head rx1.head) i.buf_data in
    let memory =
      Instantiation.create
        ()
        ~instance:"sram_buf"
        ~name:(sprintf "RM_IHPSG13_1P_%dx16_c2_bm_bist" P.buffer_size)
        ~inputs:
          [ "A_CLK", i.clock
          ; "A_MEN", vdd
          ; "A_WEN", stores
          ; "A_REN", stores ==:. 0
          ; "A_ADDR", mux2 stores ptr next
          ; "A_DIN", stored
          ; "A_DLY", vdd
          ; "A_BM", ones 16
          ; "A_BIST_CLK", gnd
          ; "A_BIST_EN", gnd
          ; "A_BIST_MEN", gnd
          ; "A_BIST_WEN", gnd
          ; "A_BIST_REN", gnd
          ; "A_BIST_ADDR", zero P.buffer_bits
          ; "A_BIST_DIN", zero 16
          ; "A_BIST_BM", zero 16
          ]
        ~outputs:[ "A_DOUT", 16 ]
    in
    buf_word <== Map.find_exn memory "A_DOUT";
    ptr
  in
  (* "If two threads write the same pin in the same cycle, the
     higher-numbered thread wins": thread 1 steps from the pins thread 0
     leaves. *)
  let step state (c : _ P.Thread_in.t) ~enable ~instr ~tick ~(tx : Fifo.t) ~(rx : Fifo.t) ~pins =
    Spec.step
      { state with pin_out = pins }
      { P.Step_in.enable
      ; tick
      ; instr
      ; lines
      ; tx_empty = tx.empty
      ; tx_head = tx.head
      ; rx_full = rx.full
      ; start = c.start
      ; out_base = c.out_base
      ; out_count = c.out_count
      ; set_base = c.set_base
      ; set_count = c.set_count
      ; in_base = c.in_base
      ; threshold = c.threshold
      ; timeout_vector = c.timeout_vector
      ; timeout = c.timeout
      ; sideset_base = c.sideset_base
      ; sideset_count = c.sideset_count
      ; out_msb_first = c.out_msb_first
      ; in_msb_first = c.in_msb_first
      ; autopull = c.autopull
      ; autopush = c.autopush
      ; crc_poly = c.crc_poly
      ; crc_init = c.crc_init
      ; crc_invert = c.crc_invert
      ; crc_in = c.crc_in
      }
  in
  let s0 =
    step t0 i.t0 ~enable:enabled0 ~instr:instr0 ~tick:tick0 ~tx:tx0 ~rx:rx0 ~pins:pin_out
  in
  let s1 =
    step
      t1
      i.t1
      ~enable:enabled1
      ~instr:instr1
      ~tick:tick1
      ~tx:tx1
      ~rx:rx1
      ~pins:s0.next.pin_out
  in
  let connect next (s : _ P.Step_out.t) ~pull ~push ~value =
    P.Thread_state.iter2 next { s.next with pin_out = zero P.num_pins } ~f:( <== );
    pull <== s.pull;
    push <== s.push;
    value <== s.push_value
  in
  connect t0_next s0 ~pull:pull0 ~push:push0 ~value:value0;
  connect t1_next s1 ~pull:pull1 ~push:push1 ~value:value1;
  pin_out_next <== s1.next.pin_out;
  (* Pads: "push-pull drives the bit; open-drain drives low only for a 0". *)
  let pads_oe =
    concat_lsb
      (List.init P.num_pins ~f:(fun p ->
         push_pull p |: (open_drain p &: (bit pin_out p ==:. 0))))
  and pads_out =
    concat_lsb (List.init P.num_pins ~f:(fun p -> mux2 (push_pull p) (bit pin_out p) gnd))
  in
  let out (s : _ P.Thread_state.t) ~div ~(tx : Fifo.t) ~(rx : Fifo.t) : _ P.Thread_out.t =
    { rx_data = rx.head
    ; tx_level = tx.level
    ; rx_level = rx.level
    ; pc = s.pc
    ; page = s.page
    ; x = s.x
    ; y = s.y
    ; isr = s.isr
    ; isr_count = s.isr_count
    ; osr = s.osr
    ; osr_count = s.osr_count
    ; delay_left = s.delay_left
    ; waiting = s.waiting
    ; wait_count = s.wait_count
    ; div_count = div
    ; crc = s.crc
    ; crc_run = s.crc_run
    }
  in
  { P.O.pin_out
  ; pads_out
  ; pads_oe
  ; buf_ptr
  ; buf_word
  ; smp = { state = smp; strobe = smp_strobe; mid = smp_mid }
  ; t0 = out t0 ~div:div0 ~tx:tx0 ~rx:rx0
  ; t1 = out t1 ~div:div1 ~tx:tx1 ~rx:rx1
  }
;;
