(* Directed scenarios for coverage closure.

   Each scenario here was written by an AI assistant (Claude) from the
   cross-coverage report of the random differential test: the report listed
   the bins random programs hit rarely or never, and the assistant wrote a
   small two-thread program and stimulus aimed at each. Nothing here is
   trusted on its own say-so. Every scenario runs through the same lockstep
   harness as the random trials (sim/lockstep.ml), so the reference model
   judges every cycle; sim/test_closure.ml checks which bins each scenario
   actually hit and which planted RTL bugs it catches. A scenario that hits
   nothing new or catches nothing would show up there.

   [target] records what the scenario was written to reach, so the report
   can show whether it did. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Scenario = Lockstep.Scenario

type t =
  { scenario : Scenario.t
  ; target : string list (* the bins or bugs it was written for *)
  }

let all_push_pull = Array.create ~len:Isa.num_pins Isa.Pin_mode.Push_pull
let all_input = Array.create ~len:Isa.num_pins Isa.Pin_mode.Input

(* Two programs, each assembled at its origin and given its own config
   (with [start] set to the origin), linked into one 64-word image. *)
let make
  ?(chain = false)
  ?(sync_bypass = 0)
  ?(modes = all_push_pull)
  ?(enabled = [| true; true |])
  ?(enables = Scenario.Script [])
  ?(rates = [ 0, 0; 0, 0 ])
  ?(pins = Scenario.Random_pins)
  ?(cycles = 400)
  ~name
  ~target
  threads
  =
  let assembled =
    List.map threads ~f:(fun (origin, source, (config : Isa.Thread_config.t)) ->
      origin, Asm.assemble ~origin source, { config with start = origin })
  in
  let image = Asm.link (List.map assembled ~f:(fun (o, p, _) -> o, p)) in
  let words =
    Array.init Isa.program_size ~f:(fun a ->
      if a < Array.length image then Isa.Instruction.encode image.(a) else 0)
  in
  { scenario =
      { Scenario.name
      ; words
      ; configs = List.map assembled ~f:(fun (_, _, c) -> c)
      ; modes
      ; chain
      ; sync_bypass
      ; enabled
      ; enables
      ; rates
      ; pins
      ; cycles
      }
  ; target
  }
;;

let cfg = Isa.Thread_config.default

let pin_fight =
  make
    ~name:"pins: two threads fight over overlapping pins"
    ~target:[ "pins: both threads write the same pin"; "Pin_priority_inverted" ]
    [ ( 0
      , {|
lp:     set pins, 21
        set pins, 10
        jmp lp
|}
      , { cfg with set_base = 2; set_count = 5 } )
    ; ( 3
      , {|
lp:     set pins, 10 [1]
        mov pins, null
        jmp lp
|}
      , { cfg with set_base = 3; set_count = 5; out_base = 0; out_count = 8 } )
    ]
;;

(* A producer pushing every 3 cycles into a consumer pulling every 15: the
   chain backs up, so thread 1's TX FIFO passes through every level and
   then thread 0's PUSH stalls behind it. *)
let chain_backpressure =
  make
    ~name:"chain: fast producer, slow divided consumer"
    ~target:
      [ "chain: move into thread 1 TX holding 0"
      ; "chain: move into thread 1 TX holding 1"
      ; "chain: move into thread 1 TX holding 2"
      ; "chain: move into thread 1 TX holding 3"
      ; "chain: thread 0 PUSH stalled behind a full chain"
      ; "Chain_ignores_full"
      ]
    ~chain:true
    [ ( 0
      , {|
lp:     in x, 16
        push
        jmp x-- lp
        set x, 31
        jmp lp
|}
      , cfg )
    ; ( 5
      , {|
lp:     pull
        out y, 16 [2]
        jmp lp
|}
      , { cfg with clkdiv = 3 } )
    ]
;;

(* Producer and consumer at similar rates, so words are moving, being
   pushed and being pulled in the same cycles. Both loops are bursty on
   purpose: the first version used two-instruction loops on both sides,
   which ran phase-locked (moves always on odd cycles, pushes and pulls on
   even ones), and the closure check rejected it for missing its targets. *)
let chain_streaming ~consumer_clkdiv =
  make
    ~name:(sprintf "chain: streaming, consumer CLKDIV %d" consumer_clkdiv)
    ~target:
      [ "chain: move in a cycle thread 1 pulls"; "chain: move in a cycle thread 0 pushes" ]
    ~chain:true
    [ ( 0
      , {|
lp:     push
        push
        push
        jmp lp
|}
      , cfg )
    ; ( 4
      , {|
lp:     pull
        pull
        jmp lp
|}
      , { cfg with clkdiv = consumer_clkdiv } )
    ]
;;

let divided_timing =
  make
    ~name:"divider: timeouts, delays and side-set on divided threads"
    ~target:
      [ "divider: timed wait expires on a divided thread"
      ; "divider: delay counted on a divided thread"
      ; "divider: side-set on a divided thread"
      ; "side-set: driven during a stall"
      ]
    ~modes:
      (Array.init Isa.num_pins ~f:(fun p ->
         if p < 2 then Isa.Pin_mode.Input else Push_pull))
    ~pins:(Square { period = 7; mask = 0b10 })
    ~rates:[ 0, 0; 0, 50 ]
    [ ( 0
      , {|
        .side_set 1
top:    set pins, 1             side 1 [3]
        wait 1 pin 0 timeout    side 0
        jmp top                 side 1
|}
      , { cfg with
          clkdiv = 3
        ; sideset_base = 7
        ; sideset_count = 1
        ; set_base = 6
        ; timeout = 4
        ; timeout_vector = 0
        } )
    ; ( 3
      , {|
        .side_set 2
top:    wait 1 pin 1 timeout    side 3 [1]
        in pins, 2              side 0
        push                    side 1
        jmp top                 side 2
|}
      , { cfg with
          clkdiv = 2
        ; sideset_base = 4
        ; sideset_count = 2
        ; timeout = 7
        ; timeout_vector = 3
        } )
    ]
;;

let enable_mid_flight =
  make
    ~name:"enable: threads disabled mid-delay, mid-wait and between ticks"
    ~target:
      [ "enable: disabled during a delay"
      ; "enable: disabled during a timed wait"
      ; "enable: disabled between divider ticks"
      ]
    ~modes:all_input
    ~pins:(Constant 0)
    ~enables:
      (Script
         [ 20, 0, false; 30, 0, true; 47, 0, false; 55, 0, true; 61, 0, false; 70, 0, true
         ; 25, 1, false; 40, 1, true; 90, 1, false; 100, 1, true
         ])
    ~cycles:200
    [ 0, {|
top:    nop [15]
        jmp top
|}, { cfg with clkdiv = 3 }
    ; ( 2
      , {|
top:    wait 1 pin 0 timeout
        jmp top
|}
      , { cfg with timeout = 1000; timeout_vector = 2 } )
    ]
;;

let both_fifos_stalled =
  make
    ~name:"fifo: one thread starved, the other blocked"
    ~target:[ "fifo: both threads stalled on FIFOs" ]
    [ 0, {|
lp:     pull
        jmp lp
|}, cfg
    ; 2, {|
lp:     push
        jmp lp
|}, cfg
    ]
;;

(* Exercises in thread 1 exactly the datapath behaviours the planted bugs
   corrupt, while thread 0 runs different code at a different address. *)
let thread1_datapath =
  make
    ~name:"thread 1: X decrement, delays, SET width, partial PUSH, timed wait"
    ~target:
      [ "Xdec_never_decrements"
      ; "Wait_timeout_ignores_budget"
      ; "Delay_field_ignored"
      ; "Set_pins_count_off_by_one"
      ; "Push_not_right_justified"
      ; "Fetch_port_crossed"
      ]
    ~modes:all_input
    ~pins:(Constant 0)
    ~rates:[ 0, 0; 0, 100 ]
    [ 0, {|
lp:     set y, 1
        nop
        jmp lp
|}, cfg
    ; ( 3
      , {|
top:    set x, 3
lp:     jmp x-- lp
        set pins, 5 [2]
        in x, 5
        push
        wait 1 pin 0 timeout
        jmp top
|}
      , { cfg with set_base = 2; set_count = 3; threshold = 16; timeout = 3; timeout_vector = 3 }
      )
    ]
;;

(* Reads every pin, every cycle, into X and Y, so the cycle a level is seen
   is directly visible in the compared state. Half the pins bypass the
   synchroniser, half do not. Added after the first eight scenarios all
   missed a planted synchroniser bug: none of them read pins in a way where
   two cycles of delay changed the outcome. *)
let synchroniser_timing =
  make
    ~name:"synchroniser: pins read every cycle, half of them bypassed"
    ~target:[ "Sync_bypass_inverted" ]
    ~modes:all_input
    ~sync_bypass:0x0F
    [ 0, {|
lp:     mov x, pins
        mov y, pins
        jmp lp
|}, cfg
    ; 3, {|
lp:     in pins, 8
        mov y, isr
        jmp lp
|}, { cfg with in_base = 2 }
    ]
;;

(* Thread 1 runs MSB first in both directions: OUT from the top of words the
   host pushes, IN into the bottom, partial words pushed. *)
let msb_first =
  make
    ~name:"thread 1: MSB-first OUT, IN and partial PUSH"
    ~target:[ "Push_ignores_in_direction" ]
    ~modes:all_input
    ~rates:[ 0, 0; 30, 100 ]
    [ 0, {|
lp:     nop
        jmp lp
|}, cfg
    ; ( 2
      , {|
top:    pull
        out x, 5
        in x, 5
        out y, 3
        in y, 3
        push
        jmp top
|}
      , { cfg with out_msb_first = true; in_msb_first = true; threshold = 16 } )
    ]
;;

let all =
  [ pin_fight
  ; chain_backpressure
  ; chain_streaming ~consumer_clkdiv:1
  ; chain_streaming ~consumer_clkdiv:2
  ; divided_timing
  ; enable_mid_flight
  ; both_fifos_stalled
  ; thread1_datapath
  ; synchroniser_timing
  ; msb_first
  ]
;;

(* Each scenario runs under a few seeds (the seed drives whatever the
   scenario leaves random: pin inputs, host push values). *)
let seeds = [ 1; 2; 3 ]

let run ?coverage ?mutation (d : t) ~seed =
  Lockstep.run ?coverage ?mutation ~rs:(Random.State.make [| seed; 7919 |]) d.scenario
;;
