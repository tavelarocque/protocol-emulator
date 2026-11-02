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
let create ?(planted_chain_bug = false) (i : _ P.I.t) : _ P.O.t =
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let high = Reg_spec.override spec ~clear_to:(ones P.num_pins) in
  (* Program memory: word [a] takes [prog_data] when the host writes [a]. *)
  let program =
    List.init P.program_size ~f:(fun a ->
      reg spec ~enable:(i.prog_we &: (i.prog_addr ==:. a)) i.prog_data
      -- sprintf "prog_%d" a)
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
  let divider n (c : _ P.Thread_in.t) =
    let count_next = wire 16 in
    let count = reg spec count_next -- sprintf "t%d_div_count" n in
    let tick = count ==:. 0 in
    let period_minus_one = mux2 (c.clkdiv <=:. 1) (zero 16) (c.clkdiv -:. 1) in
    count_next
    <== mux2 (~:(c.enable)) (zero 16) (mux2 tick period_minus_one (count -:. 1));
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
  let tx0 = Fifo.create spec ~name:"t0_tx" ~push:i.t0.tx_push ~data:i.t0.tx_data ~pop:pull0 in
  let rx0 =
    Fifo.create
      spec
      ~name:"t0_rx"
      ~push:push0
      ~data:value0
      ~pop:(moves |: (host_ok &: i.t0.rx_pop))
  in
  let tx1 =
    Fifo.create
      spec
      ~name:"t1_tx"
      ~push:(moves |: (host_ok &: i.t1.tx_push))
      ~data:(mux2 moves rx0.head i.t1.tx_data)
      ~pop:pull1
  in
  let rx1 = Fifo.create spec ~name:"t1_rx" ~push:push1 ~data:value1 ~pop:i.t1.rx_pop in
  moves <== (i.chain &: ~:(rx0.empty) &: (if planted_chain_bug then vdd else ~:(tx1.full)));
  (* "If two threads write the same pin in the same cycle, the
     higher-numbered thread wins": thread 1 steps from the pins thread 0
     leaves. *)
  let step state (c : _ P.Thread_in.t) ~pc ~tick ~(tx : Fifo.t) ~(rx : Fifo.t) ~pins =
    Spec.step
      { state with pin_out = pins }
      { P.Step_in.enable = c.enable
      ; tick
      ; instr = mux pc program
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
      }
  in
  let s0 = step t0 i.t0 ~pc:t0.pc ~tick:tick0 ~tx:tx0 ~rx:rx0 ~pins:pin_out in
  let s1 = step t1 i.t1 ~pc:t1.pc ~tick:tick1 ~tx:tx1 ~rx:rx1 ~pins:s0.next.pin_out in
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
    }
  in
  { P.O.pin_out
  ; pads_out
  ; pads_oe
  ; t0 = out t0 ~div:div0 ~tx:tx0 ~rx:rx0
  ; t1 = out t1 ~div:div1 ~tx:tx1 ~rx:rx1
  }
;;
