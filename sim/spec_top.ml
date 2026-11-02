(* An independent specification of the whole chip: the SPI host port and
   register file of hw/top.ml, written from the protocol and register map
   documented at the top of that file, around [Spec_core] (the independent
   description of the two-thread core).

   The style differs from the RTL where it can: plain next-state equations
   instead of an [Always] block, the register map as a table that drives
   both the writes and the reads, and the read data as an OR of one-hot
   terms rather than a multiplexer over an address-indexed array. As with
   [Spec_core], what it shares with the RTL is the register names, widths
   and reset values, which the equivalence checker needs to pair the two;
   the SPI port's state (a bit counter, the bits shifted in so far, the
   latched command byte, the MISO shift register) is therefore held in the
   same form.

   sim/test_formal.ml proves the chip's top level equal to this in one
   clock, from every state. With [Spec_core] inside, that covers everything
   between the Tiny Tapeout pins. *)

open! Core
open! Hardcaml
open! Signal
module P = Pe_hw.Pe_core
module T = Pe_hw.Top

let bit s i = select s i i

(* Bugs planted in this spec, never in the RTL: the proof must fail with
   each, which shows it really compares this file's logic. *)
module Plant = struct
  type t =
    | Status_levels_swapped (* STATUS reports the TX level where RX belongs *)
    | Pop_on_write (* writing the RX FIFO's address pops it, as a read does *)
  [@@deriving sexp_of, enumerate]
end

(* Per-thread configuration registers, from the register map: offset in the
   bank, name, width, reset value. *)
let bank_registers =
  [ 0x1, "start", 6, 0
  ; 0x2, "out_cfg", 8, 0x10
  ; 0x3, "set_cfg", 8, 0x10
  ; 0x4, "in_base", 3, 0
  ; 0x5, "threshold", 5, 8
  ; 0x6, "timeout_vector", 6, 0
  ; 0xB, "timeout", 16, 0
  ; 0xC, "sideset", 6, 0
  ; 0xD, "clkdiv", 16, 0
  ; 0xF, "shift", 2, 0
  ]
;;

let bank_base n = 0x40 + (0x10 * n)
let tx_offset = 0x8
let rx_offset = 0x9
let status_offset = 0xA

let create ?plant (i : _ T.I.t) : _ T.O.t =
  let planted p = Option.value_map plant ~default:false ~f:(Poly.equal p) in
  let spec = Reg_spec.create ~clock:i.clock ~clear:i.clear () in
  (* A register holding [next], reset to [init]. *)
  let state ?(init = 0) ~name ~width next =
    reg (Reg_spec.override spec ~clear_to:(of_int ~width init)) next -- name
  in
  (* --- The host SPI port, mode 0, MSB first, 24 bits per transaction. ---
     Its three inputs are sampled through two flip-flops each (CS_N idles
     high), and edges of SCK are found by comparing with the previous
     sample. *)
  let synchronised ?(init = 0) name pin =
    let first = state ~init ~name:(name ^ "_s1") ~width:1 pin in
    state ~init ~name:(name ^ "_s2") ~width:1 first
  in
  let sck = synchronised "host_sck" (bit i.ui_in 0)
  and cs_n = synchronised ~init:1 "host_cs_n" (bit i.ui_in 1)
  and mosi = synchronised "host_mosi" (bit i.ui_in 2) in
  let sck_before = state ~name:"host_sck_prev" ~width:1 sck in
  let selected = ~:cs_n in
  let rising = selected &: sck &: ~:sck_before
  and falling = selected &: ~:sck &: sck_before in
  let count_next = wire 5
  and received_next = wire 23
  and command_next = wire 8
  and miso_next = wire 16 in
  let count = state ~name:"host_bit_count" ~width:5 count_next
  and received = state ~name:"host_shift_in" ~width:23 received_next
  and command = state ~name:"host_cmd" ~width:8 command_next
  and miso = state ~name:"host_miso_shift" ~width:16 miso_next in
  (* The transaction so far, including the bit arriving on this edge. *)
  let word = received @: mosi in
  (* Bit 8 (the last of the command byte) and bit 24 (the last of the data)
     arrive on the rising edges seen with 7 and 23 bits already counted. *)
  let command_ends = rising &: (count ==:. 7)
  and data_ends = rising &: (count ==:. 23) in
  let new_command = select word 7 0 in
  let writes = bit command 7
  and address = select command 6 0
  and data = select word 15 0 in
  let written a = data_ends &: writes &: (address ==:. a) in
  (* --- The register file. --- *)
  let config ?init ~name ~width address =
    let next = wire width in
    let r = state ?init ~name ~width next in
    next <== mux2 (written address) (select data (width - 1) 0) r;
    r
  in
  let ctrl = config ~name:"cfg_ctrl" ~width:3 0x40
  and pin_modes = config ~name:"cfg_pin_modes" ~width:16 0x47
  and sync_bypass = config ~name:"cfg_sync_bypass" ~width:8 0x4E in
  let banks =
    List.init 2 ~f:(fun n ->
      List.map bank_registers ~f:(fun (offset, name, width, init) ->
        ( offset
        , config
            ~init
            ~name:(sprintf "cfg_t%d_%s" n name)
            ~width
            (bank_base n + offset) )))
  in
  let field n name =
    let offset, _, _, _ =
      List.find_exn bank_registers ~f:(fun (_, nm, _, _) -> String.equal nm name)
    in
    List.Assoc.find_exn (List.nth_exn banks n) ~equal:Int.equal offset
  in
  (* Reads: the address in the command byte selects the data, at the moment
     the command byte completes. *)
  let read_address = select new_command 6 0 in
  let reading = command_ends &: ~:(bit new_command 7) in
  let pops = List.init 2 ~f:(fun _ -> wire 1) in
  let thread_in n : _ P.Thread_in.t =
    let f = field n in
    { enable = bit ctrl n
    ; start = f "start"
    ; out_base = select (f "out_cfg") 2 0
    ; out_count = select (f "out_cfg") 7 4
    ; set_base = select (f "set_cfg") 2 0
    ; set_count = select (f "set_cfg") 7 4
    ; in_base = f "in_base"
    ; threshold = f "threshold"
    ; timeout_vector = f "timeout_vector"
    ; timeout = f "timeout"
    ; sideset_base = select (f "sideset") 2 0
    ; sideset_count = select (f "sideset") 5 4
    ; clkdiv = f "clkdiv"
    ; out_msb_first = bit (f "shift") 0
    ; in_msb_first = bit (f "shift") 1
    ; tx_push = written (bank_base n + tx_offset)
    ; tx_data = data
    ; rx_pop = List.nth_exn pops n
    }
  in
  let core =
    Spec_core.create
      { P.I.clock = i.clock
      ; clear = i.clear
      ; prog_we = data_ends &: writes &: (address <:. 0x40)
      ; prog_addr = select address 5 0
      ; prog_data = data
      ; pin_modes
      ; pins_in = i.uio_in
      ; sync_bypass
      ; chain = bit ctrl 2
      ; t0 = thread_in 0
      ; t1 = thread_in 1
      }
  in
  let has_data n = (P.O.thread core n).rx_level <>:. 0
  and is_full n = (P.O.thread core n).tx_level ==:. 4 in
  List.iteri pops ~f:(fun n pop ->
    let access = if planted Plant.Pop_on_write then command_ends else reading in
    pop <== (access &: (read_address ==:. bank_base n + rx_offset) &: has_data n));
  (* Everything readable, as (address, value): configuration reads back what
     was written; RX pops (0 if empty); STATUS packs pc [13:8], enable [7],
     RX level [6:4], TX level [2:0]. Everything else reads 0. *)
  let readable =
    [ 0x40, ctrl; 0x47, pin_modes; 0x4E, sync_bypass ]
    @ List.concat_mapi banks ~f:(fun n regs ->
      let t = P.O.thread core n in
      let base = bank_base n in
      let rx_level, tx_level =
        if planted Plant.Status_levels_swapped then t.tx_level, t.rx_level else t.rx_level, t.tx_level
      in
      List.map regs ~f:(fun (offset, r) -> base + offset, r)
      @ [ base + rx_offset, mux2 (has_data n) t.rx_data (zero 16)
        ; ( base + status_offset
          , concat_msb [ zero 2; t.pc; bit ctrl n; rx_level; gnd; tx_level ] )
        ])
  in
  let read_data =
    List.map readable ~f:(fun (a, v) ->
      sresize (read_address ==:. a) 16 &: uresize v 16)
    |> List.reduce_exn ~f:( |: )
  in
  (* --- The SPI port's next state. CS_N high resets the bit count and
     nothing else. The count stops at 24. MISO loads the read data when the
     command completes and shifts on falling edges once the first data bit
     has been sampled, that is from the ninth bit on. --- *)
  count_next
  <== mux2 cs_n (zero 5) (mux2 (rising &: (count <:. 24)) (count +:. 1) count);
  received_next <== mux2 rising (select word 22 0) received;
  command_next <== mux2 command_ends new_command command;
  miso_next
  <== mux2
        command_ends
        read_data
        (mux2 (falling &: (count >=:. 9)) (sll miso 1) miso);
  { T.O.uo_out =
      concat_lsb
        [ msb miso
        ; bit ctrl 0
        ; has_data 0
        ; is_full 0
        ; bit ctrl 1
        ; has_data 1
        ; is_full 1
        ; gnd
        ]
  ; uio_out = core.pads_out
  ; uio_oe = core.pads_oe
  }
;;
