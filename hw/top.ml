(* Chip top level: SPI host port, register file, and the two-thread
   protocol-emulator core, mapped onto the Tiny Tapeout pins.

   Pins
     ui_in[0]   SCK    host SPI clock (mode 0, MSB first)
     ui_in[1]   CS_N   host SPI chip select, active low
     ui_in[2]   MOSI
     uo_out[0]  MISO
     uo_out[1]  thread 0 enabled
     uo_out[2]  thread 0 RX FIFO not empty (data waiting for the host)
     uo_out[3]  thread 0 TX FIFO full
     uo_out[4]  thread 1 enabled
     uo_out[5]  thread 1 RX FIFO not empty
     uo_out[6]  thread 1 TX FIFO full
     uio[7:0]   the 8 protocol pins, each input / push-pull / open-drain

   SPI transaction: CS low, 24 bits, CS high.
     bit 23     1 = write, 0 = read
     bits 22:16 register address
     bits 15:0  write data (MOSI) or read data (MISO)

   The SPI inputs are oversampled in the core clock domain through 2-flop
   synchronisers, so SCK must be slow relative to the core clock: each SCK
   phase must last at least 4 core clocks.

   Register map. Thread 0's bank is at 0x40, thread 1's at 0x50, with the
   same layout; offsets 0x0, 0x7 and 0xE hold the global registers and are
   unused in thread 1's bank.
     0x00-0x3F  program memory word (write), shared by both threads
     0x40       CTRL (global): bit 0 = thread 0 enable, bit 1 = thread 1
                enable. One write starts or stops both together. Bit 2 =
                CHAIN: thread 0's RX FIFO feeds thread 1's TX FIFO directly,
                and the host cannot pop thread 0 or push thread 1.
     0x47       PIN_MODES (global), 2 bits per pin: 0 input, 1 push-pull,
                2 open-drain
     0x4E       SYNC_BYPASS (global), 1 bit per pin: read that pin's input
                directly instead of through the 2-flop synchroniser (two
                cycles sooner, but only safe for signals known to be stable
                when sampled)
     bank + 0x1 START address [5:0]
     bank + 0x2 OUT config: base [2:0], count [7:4]
     bank + 0x3 SET config: base [2:0], count [7:4]
     bank + 0x4 IN base [2:0]
     bank + 0x5 THRESHOLD [4:0] (1..16)
     bank + 0x6 TIMEOUT_VECTOR [5:0]
     bank + 0x8 TX FIFO (write pushes; dropped if full)
     bank + 0x9 RX FIFO (read pops; reads 0 if empty)
     bank + 0xA STATUS (read): [13:8] pc, [7] enable, [6:4] rx level,
                [2:0] tx level
     bank + 0xB TIMEOUT [15:0]: max cycles a [wait ... timeout] stalls
     bank + 0xC SIDESET: base pin [2:0], count [5:4] (0..3 delay bits used)
     bank + 0xD CLKDIV [15:0]: the thread runs one cycle in every CLKDIV
                (0 and 1: every cycle)
     bank + 0xF SHIFT: bit 0 = OUT most significant bit first, bit 1 = IN
                most significant bit first (both 0: LSB first, as before)
   Configuration registers read back what was written; unmapped addresses
   read 0. Pin conflicts: if both threads write a pin in the same cycle,
   thread 1 wins. *)

open! Core
open! Hardcaml
open! Signal

module I = struct
  type 'a t =
    { clock : 'a
    ; clear : 'a
    ; ui_in : 'a [@bits 8]
    ; uio_in : 'a [@bits 8]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { uo_out : 'a [@bits 8]
    ; uio_out : 'a [@bits 8]
    ; uio_oe : 'a [@bits 8]
    }
  [@@deriving hardcaml]
end

module Addr = struct
  let program_words = 0x40

  (* Global registers. *)
  let ctrl = 0x40
  let pin_modes = 0x47
  let sync_bypass = 0x4E

  (* Thread 0's per-thread registers; [for_thread n] moves one into thread
     n's bank. *)
  let start = 0x41
  let out_cfg = 0x42
  let set_cfg = 0x43
  let in_base = 0x44
  let threshold = 0x45
  let timeout_vector = 0x46
  let tx_fifo = 0x48
  let rx_fifo = 0x49
  let status = 0x4A
  let timeout = 0x4B
  let sideset = 0x4C
  let clkdiv = 0x4D
  let shift = 0x4F
  let bank_size = 0x10
  let for_thread n a = a + (bank_size * n)
  let last = for_thread 1 shift
end

let bit s i = select s i i

let create (i : _ I.t) : _ O.t =
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let spec_to v = Reg_spec.override spec ~clear_to:v in
  (* Every register here is named, so the formal proof can pair it with its
     counterpart in an independently written spec (sim/spec_top.ml). *)
  (* --- SPI pins into the core clock domain. CS_N resets high (idle). --- *)
  let sync ?(init = gnd) name s =
    let s1 = reg (spec_to init) s -- (name ^ "_s1") in
    reg (spec_to init) s1 -- (name ^ "_s2")
  in
  let sck = sync "host_sck" (bit i.ui_in 0) in
  let cs_n = sync ~init:vdd "host_cs_n" (bit i.ui_in 1) in
  let mosi = sync "host_mosi" (bit i.ui_in 2) in
  let sck_prev = reg spec sck -- "host_sck_prev" in
  let rise = sck &: ~:sck_prev &: ~:cs_n in
  let fall = ~:sck &: sck_prev &: ~:cs_n in
  let open Always in
  let named name (v : Variable.t) =
    ignore (v.value -- name : Signal.t);
    v
  in
  let bit_count = Variable.reg spec ~width:5 |> named "host_bit_count" in
  let shift_in = Variable.reg spec ~width:23 |> named "host_shift_in" in
  let cmd = Variable.reg spec ~width:8 |> named "host_cmd" in
  let miso_shift = Variable.reg spec ~width:16 |> named "host_miso_shift" in
  (* The word as it stands after this rising edge's bit is shifted in. *)
  let shifted = shift_in.value @: mosi in
  let cmd_now = select shifted 7 0 in
  let data_now = select shifted 15 0 in
  let cmd_done = rise &: (bit_count.value ==:. 7) in
  let data_done = rise &: (bit_count.value ==:. 23) in
  let is_write = bit cmd.value 7 in
  let addr = select cmd.value 6 0 in
  let write_to a = data_done &: is_write &: (addr ==:. a) in
  (* --- Configuration registers. --- *)
  let config ?(init = 0) name width =
    Variable.reg (spec_to (of_int ~width init)) ~width |> named name
  in
  let ctrl = config "cfg_ctrl" 3 in
  let pin_modes = config "cfg_pin_modes" 16 in
  let sync_bypass = config "cfg_sync_bypass" 8 in
  (* One bank of per-thread registers. Returns its writes as (address,
     register, write rule), its RX pop strobe, and the thread's core inputs. *)
  let bank n =
    let a = Addr.for_thread n in
    let config ?init name width = config ?init (sprintf "cfg_t%d_%s" n name) width in
    let start = config "start" 6 in
    let out_cfg = config ~init:0x10 "out_cfg" 8 in
    let set_cfg = config ~init:0x10 "set_cfg" 8 in
    let in_base = config "in_base" 3 in
    let threshold = config ~init:8 "threshold" 5 in
    let timeout_vector = config "timeout_vector" 6 in
    let timeout = config "timeout" 16 in
    let sideset = config "sideset" 6 in
    let clkdiv = config "clkdiv" 16 in
    let shift = config "shift" 2 in
    let writes =
      List.map
        [ Addr.start, start
        ; Addr.out_cfg, out_cfg
        ; Addr.set_cfg, set_cfg
        ; Addr.in_base, in_base
        ; Addr.threshold, threshold
        ; Addr.timeout_vector, timeout_vector
        ; Addr.timeout, timeout
        ; Addr.sideset, sideset
        ; Addr.clkdiv, clkdiv
        ; Addr.shift, shift
        ]
        ~f:(fun (offset, (r : Variable.t)) ->
          let addr = a offset in
          addr, r, when_ (write_to addr) [ r <-- select data_now (width r.value - 1) 0 ])
    in
    let rx_pop = wire 1 in
    let core_in =
      { Pe_core.Thread_in.enable = bit ctrl.value n
      ; start = start.value
      ; out_base = select out_cfg.value 2 0
      ; out_count = select out_cfg.value 7 4
      ; set_base = select set_cfg.value 2 0
      ; set_count = select set_cfg.value 7 4
      ; in_base = in_base.value
      ; threshold = threshold.value
      ; timeout_vector = timeout_vector.value
      ; timeout = timeout.value
      ; sideset_base = select sideset.value 2 0
      ; sideset_count = select sideset.value 5 4
      ; clkdiv = clkdiv.value
      ; out_msb_first = bit shift.value 0
      ; in_msb_first = bit shift.value 1
      ; tx_push = write_to (a Addr.tx_fifo)
      ; tx_data = data_now
      ; rx_pop
      }
    in
    writes, rx_pop, core_in
  in
  let banks = List.init Pe_core.num_threads ~f:bank in
  let bank_in n =
    let _, _, core_in = List.nth_exn banks n in
    core_in
  in
  let core =
    Pe_core.create
      { Pe_core.I.clock = i.clock
      ; clear = i.clear
      ; prog_we = data_done &: is_write &: (addr <:. Addr.program_words)
      ; prog_addr = select addr 5 0
      ; prog_data = data_now
      ; pin_modes = pin_modes.value
      ; pins_in = i.uio_in
      ; sync_bypass = sync_bypass.value
      ; chain = bit ctrl.value 2
      ; t0 = bank_in 0
      ; t1 = bank_in 1
      }
  in
  let rx_nonempty n = (Pe_core.O.thread core n).rx_level <>:. 0 in
  let tx_full n = (Pe_core.O.thread core n).tx_level ==:. Tiny_fifo.depth in
  (* Read data, selected by the address in the command byte as it completes. *)
  let read_addr = select cmd_now 6 0 in
  let table = Array.create ~len:(Addr.last + 2) (zero 16) in
  table.(Addr.ctrl) <- uresize ctrl.value 16;
  table.(Addr.pin_modes) <- pin_modes.value;
  table.(Addr.sync_bypass) <- uresize sync_bypass.value 16;
  List.iteri banks ~f:(fun n (writes, _, _) ->
    let a = Addr.for_thread n in
    let t = Pe_core.O.thread core n in
    List.iter writes ~f:(fun (addr, (r : Variable.t), _) -> table.(addr) <- uresize r.value 16);
    table.(a Addr.rx_fifo) <- mux2 (rx_nonempty n) t.rx_data (zero 16);
    table.(a Addr.status)
    <- concat_msb [ zero 2; t.pc; bit ctrl.value n; t.rx_level; gnd; t.tx_level ]);
  (* The last entry is zero, and mux repeats it for higher addresses. *)
  let read_value = mux read_addr (Array.to_list table) in
  List.iteri banks ~f:(fun n (_, rx_pop, _) ->
    rx_pop
    <== (cmd_done
         &: ~:(bit cmd_now 7)
         &: (read_addr ==:. Addr.for_thread n Addr.rx_fifo)
         &: rx_nonempty n));
  compile
    ([ if_
         cs_n
         [ bit_count <--. 0 ]
         [ when_
             rise
             [ shift_in <-- select shifted 22 0
             ; when_ (bit_count.value <:. 24) [ bit_count <-- bit_count.value +:. 1 ]
             ; when_ (bit_count.value ==:. 7) [ cmd <-- cmd_now; miso_shift <-- read_value ]
             ]
         ; (* MISO changes on falling edges, once the host has sampled the
              first data bit. *)
           when_
             (fall &: (bit_count.value >=:. 9))
             [ miso_shift <-- sll miso_shift.value 1 ]
         ]
     ; when_ (write_to Addr.ctrl) [ ctrl <-- select data_now 2 0 ]
     ; when_ (write_to Addr.pin_modes) [ pin_modes <-- data_now ]
     ; when_ (write_to Addr.sync_bypass) [ sync_bypass <-- select data_now 7 0 ]
     ]
     @ List.concat_map banks ~f:(fun (writes, _, _) ->
       List.map writes ~f:(fun (_, _, w) -> w)));
  { O.uo_out =
      concat_lsb
        [ msb miso_shift.value
        ; bit ctrl.value 0
        ; rx_nonempty 0
        ; tx_full 0
        ; bit ctrl.value 1
        ; rx_nonempty 1
        ; tx_full 1
        ; gnd
        ]
  ; uio_out = core.pads_out
  ; uio_oe = core.pads_oe
  }
;;
