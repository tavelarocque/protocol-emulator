(* Chip top level: SPI host port, register file, and the protocol-emulator
   core, mapped onto the Tiny Tapeout pins.

   Pins
     ui_in[0]   SCK    host SPI clock (mode 0, MSB first)
     ui_in[1]   CS_N   host SPI chip select, active low
     ui_in[2]   MOSI
     uo_out[0]  MISO
     uo_out[1]  thread enabled
     uo_out[2]  RX FIFO not empty (data waiting for the host)
     uo_out[3]  TX FIFO full
     uio[7:0]   the 8 protocol pins, each input / push-pull / open-drain

   SPI transaction: CS low, 24 bits, CS high.
     bit 23     1 = write, 0 = read
     bits 22:16 register address
     bits 15:0  write data (MOSI) or read data (MISO)

   The SPI inputs are oversampled in the core clock domain through 2-flop
   synchronisers, so SCK must be slow relative to the core clock: each SCK
   phase must last at least 4 core clocks.

   Register map
     0x00-0x3F  program memory word (write)
     0x40       CTRL: bit 0 = thread enable
     0x41       START address [5:0]
     0x42       OUT config: base [2:0], count [7:4]
     0x43       SET config: base [2:0], count [7:4]
     0x44       IN base [2:0]
     0x45       THRESHOLD [4:0] (1..16)
     0x46       TIMEOUT_VECTOR [5:0]
     0x47       PIN_MODES, 2 bits per pin: 0 input, 1 push-pull, 2 open-drain
     0x48       TX FIFO (write pushes; dropped if full)
     0x49       RX FIFO (read pops; reads 0 if empty)
     0x4A       STATUS (read): [13:8] pc, [7] enable, [6:4] rx level, [2:0] tx level
     0x4B       TIMEOUT [15:0]: max cycles a [wait ... timeout] stalls
   Configuration registers read back what was written. *)

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
  let ctrl = 0x40
  let start = 0x41
  let out_cfg = 0x42
  let set_cfg = 0x43
  let in_base = 0x44
  let threshold = 0x45
  let timeout_vector = 0x46
  let pin_modes = 0x47
  let tx_fifo = 0x48
  let rx_fifo = 0x49
  let status = 0x4A
  let timeout = 0x4B
end

let bit s i = select s i i

let create (i : _ I.t) : _ O.t =
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  let spec_to v = Reg_spec.override spec ~clear_to:v in
  (* --- SPI pins into the core clock domain. CS_N resets high (idle). --- *)
  let sync ?(init = gnd) s = reg (spec_to init) (reg (spec_to init) s) in
  let sck = sync (bit i.ui_in 0) in
  let cs_n = sync ~init:vdd (bit i.ui_in 1) in
  let mosi = sync (bit i.ui_in 2) in
  let sck_prev = reg spec sck in
  let rise = sck &: ~:sck_prev &: ~:cs_n in
  let fall = ~:sck &: sck_prev &: ~:cs_n in
  let open Always in
  let bit_count = Variable.reg spec ~width:5 in
  let shift_in = Variable.reg spec ~width:23 in
  let cmd = Variable.reg spec ~width:8 in
  let miso_shift = Variable.reg spec ~width:16 in
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
  let config ?(init = 0) width = Variable.reg (spec_to (of_int ~width init)) ~width in
  let enable = config 1 in
  let start = config 6 in
  let out_cfg = config ~init:0x10 8 in
  let set_cfg = config ~init:0x10 8 in
  let in_base = config 3 in
  let threshold = config ~init:8 5 in
  let timeout_vector = config 6 in
  let timeout = config 16 in
  let pin_modes = config 16 in
  (* --- The core. Host-side strobes are wires assigned below. --- *)
  let rx_pop = wire 1 in
  let core =
    Pe_core.create
      { Pe_core.I.clock = i.clock
      ; clear = i.clear
      ; enable = enable.value
      ; prog_we = data_done &: is_write &: (addr <:. Addr.program_words)
      ; prog_addr = select addr 5 0
      ; prog_data = data_now
      ; start = start.value
      ; out_base = select out_cfg.value 2 0
      ; out_count = select out_cfg.value 7 4
      ; set_base = select set_cfg.value 2 0
      ; set_count = select set_cfg.value 7 4
      ; in_base = in_base.value
      ; threshold = threshold.value
      ; timeout_vector = timeout_vector.value
      ; timeout = timeout.value
      ; pin_modes = pin_modes.value
      ; pins_in = i.uio_in
      ; tx_push = write_to Addr.tx_fifo
      ; tx_data = data_now
      ; rx_pop
      }
  in
  let status =
    concat_msb
      [ zero 2
      ; core.pc
      ; enable.value
      ; core.rx_level
      ; gnd
      ; core.tx_level
      ]
  in
  (* Read data, selected by the address in the command byte as it completes. *)
  let read_addr = select cmd_now 6 0 in
  let read_value =
    let table = Array.create ~len:(Addr.timeout + 2) (zero 16) in
    table.(Addr.ctrl) <- uresize enable.value 16;
    table.(Addr.start) <- uresize start.value 16;
    table.(Addr.out_cfg) <- uresize out_cfg.value 16;
    table.(Addr.set_cfg) <- uresize set_cfg.value 16;
    table.(Addr.in_base) <- uresize in_base.value 16;
    table.(Addr.threshold) <- uresize threshold.value 16;
    table.(Addr.timeout_vector) <- uresize timeout_vector.value 16;
    table.(Addr.pin_modes) <- pin_modes.value;
    table.(Addr.rx_fifo) <- core.rx_data;
    table.(Addr.status) <- status;
    table.(Addr.timeout) <- timeout.value;
    (* The last entry is zero, and mux repeats it for higher addresses. *)
    mux read_addr (Array.to_list table)
  in
  let rx_nonempty = core.rx_level <>:. 0 in
  rx_pop
  <== (cmd_done &: ~:(bit cmd_now 7) &: (read_addr ==:. Addr.rx_fifo) &: rx_nonempty);
  let read_value = mux2 (read_addr ==:. Addr.rx_fifo &: ~:rx_nonempty) (zero 16) read_value in
  compile
    [ if_
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
    ; when_ (write_to Addr.ctrl) [ enable <-- select data_now 0 0 ]
    ; when_ (write_to Addr.start) [ start <-- select data_now 5 0 ]
    ; when_ (write_to Addr.out_cfg) [ out_cfg <-- select data_now 7 0 ]
    ; when_ (write_to Addr.set_cfg) [ set_cfg <-- select data_now 7 0 ]
    ; when_ (write_to Addr.in_base) [ in_base <-- select data_now 2 0 ]
    ; when_ (write_to Addr.threshold) [ threshold <-- select data_now 4 0 ]
    ; when_ (write_to Addr.timeout_vector) [ timeout_vector <-- select data_now 5 0 ]
    ; when_ (write_to Addr.timeout) [ timeout <-- data_now ]
    ; when_ (write_to Addr.pin_modes) [ pin_modes <-- data_now ]
    ];
  { O.uo_out =
      concat_lsb
        [ msb miso_shift.value
        ; enable.value
        ; rx_nonempty
        ; core.tx_level ==:. Tiny_fifo.depth
        ; zero 4
        ]
  ; uio_out = core.pads_out
  ; uio_oe = core.pads_oe
  }
;;
