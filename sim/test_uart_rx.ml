(* The UART receiver firmware ([Firmware.uart_rx]) and full-duplex UART.

   The line is driven by an independent frame generator written here, which
   can run off-rate: a real sender's clock never matches the receiver's
   exactly, so the receiver must tolerate a bit time a few percent longer or
   shorter than its own. The generator works in fractional cycles, so a 2%
   error is really 2%, not rounded away. *)

open! Core
open! Hardcaml
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Uart_model = Pe_model.Uart_model
module Duplex = Firmware.Uart_duplex
module Top = Pe_hw.Top

(* One line sample per cycle. Each frame is an optional run of idle bits,
   then start, 8 data bits LSB first, and a stop bit at [stop] (true for a
   good frame). [bit_time] is cycles per bit, possibly fractional. *)
let line ~bit_time ~frames =
  let bits =
    List.concat_map frames ~f:(fun (idle_bits, byte, stop) ->
      List.init idle_bits ~f:(fun _ -> true)
      @ [ false ]
      @ List.init 8 ~f:(fun k -> (byte lsr k) land 1 = 1)
      @ [ stop ])
  in
  let bits = Array.of_list (List.init 3 ~f:(fun _ -> true) @ bits @ [ true; true; true ]) in
  let n = Float.iround_up_exn (Float.of_int (Array.length bits) *. bit_time) in
  List.init n ~f:(fun c ->
    let k = Float.iround_down_exn (Float.of_int c /. bit_time) in
    if k < Array.length bits then bits.(k) else true)
;;

(* Runs [uart_rx] on the model against [samples] on pin 0. Returns the RX
   FIFO words. *)
let receive_on_model ~divisor samples =
  let m =
    Isa.create
      ~program:(Asm.assemble (Firmware.uart_rx ~pin:0))
      ~pin_modes:(Array.create ~len:Isa.num_pins Isa.Pin_mode.Input)
      ~threads:
        [ { Isa.Thread_config.default with
            in_base = 0
          ; threshold = 9
          ; timeout = 0
          ; timeout_vector = Firmware.uart_rx_bad
          }
        ]
  in
  List.iter (Duplex.rx_setup ~divisor) ~f:(fun w -> assert (Isa.push_tx m ~thread:0 w));
  let got = Queue.create () in
  List.iter samples ~f:(fun level ->
    Isa.step m ~inputs:(if level then 0xFF else 0xFE);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue got));
  (* Let the last frame finish. *)
  for _ = 1 to 4 * divisor do
    Isa.step m ~inputs:0xFF;
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Queue.enqueue got)
  done;
  Queue.to_list got
;;

let good byte = byte lor 0x100

let%test_unit "the generator's on-rate frames are what the reference receiver expects" =
  (* Anchor the generator to the existing UART oracle before using it. *)
  let samples = line ~bit_time:16. ~frames:[ 0, 0xA5, true; 2, 0x3C, true ] in
  [%test_result: (int list, Uart_model.Decode_error.t) Result.t]
    (Uart_model.decode ~divisor:16 samples)
    ~expect:(Ok [ 0xA5; 0x3C ])
;;

let%test_unit "model: bytes received at random baud rates, sender off by up to 2%" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 10 40)
       (Int.gen_incl (-20) 20)
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.both (Int.gen_incl 0 3) (Int.gen_incl 0 255))))
    ~trials:300
    ~sexp_of:[%sexp_of: int * int * (int * int) list]
    ~f:(fun (divisor, permille, frames) ->
      let frames = List.take frames 5 in
      let bit_time = Float.of_int divisor *. (1. +. (Float.of_int permille /. 1000.)) in
      let samples = line ~bit_time ~frames:(List.map frames ~f:(fun (i, b) -> i, b, true)) in
      [%test_result: int list]
        (receive_on_model ~divisor samples)
        ~expect:(List.map frames ~f:(fun (_, b) -> good b)))
;;

let%test_unit "model: a framing error is reported, and the next frame still decodes" =
  let divisor = 16 in
  let samples =
    line ~bit_time:16. ~frames:[ 0, 0x55, true; 0, 0x0F, false; 2, 0xC3, true ]
  in
  [%test_result: int list]
    (receive_on_model ~divisor samples)
    ~expect:[ good 0x55; 0x0F; good 0xC3 ]
;;

let%expect_test "sampling point: how far off-rate the sender can be" =
  (* The widest symmetric baud error that still decodes every byte value
     correctly, for a few divisors. It is set by where the stop bit is
     sampled: 9.5 bit times in, so about 5% either way at best for an
     isolated frame. Reaching that limit says the sampling point is
     centred, i.e. the half-bit count compensates for the synchroniser's
     two cycles. Back-to-back frames are tested above to +/-2%. *)
  List.iter [ 10; 16; 32 ] ~f:(fun divisor ->
    let ok permille =
      List.for_all (List.init 256 ~f:Fn.id) ~f:(fun b ->
        let bit_time = Float.of_int divisor *. (1. +. (Float.of_int permille /. 1000.)) in
        [%equal: int list]
          (receive_on_model ~divisor (line ~bit_time ~frames:[ 1, b, true ]))
          [ good b ])
    in
    let widest =
      List.find_exn (List.rev (List.init 80 ~f:Fn.id)) ~f:(fun p -> ok p && ok (-p))
    in
    printf "divisor %2d: tolerates +/-%.1f%%\n" divisor (Float.of_int widest /. 10.));
  [%expect {|
    divisor 10: tolerates +/-5.3%
    divisor 16: tolerates +/-5.2%
    divisor 32: tolerates +/-5.5%
    |}]
;;

(* --- Full duplex on the chip: TX on thread 0, RX on thread 1 ------------- *)

let%test_unit "the framing-error vector points at the bad-frame handler" =
  let program = Asm.assemble (Firmware.uart_rx ~pin:3) in
  [%test_result: Isa.Instruction.op]
    program.(Firmware.uart_rx_bad).op
    ~expect:(Wait { polarity = true; pin = 3; timeout = false })
;;

let%test_unit "model: a break (line held low) gives framing errors, then recovery" =
  let divisor = 12 in
  let low = List.init (30 * divisor) ~f:(fun _ -> false) in
  let samples =
    List.init (3 * divisor) ~f:(fun _ -> true)
    @ low
    @ line ~bit_time:12. ~frames:[ 2, 0x96, true ]
  in
  let got = receive_on_model ~divisor samples in
  (* Every word before the last is a framing error; the last is the byte. *)
  [%test_result: int] (List.last_exn got) ~expect:(good 0x96);
  [%test_pred: int list]
    (List.for_all ~f:(fun w -> w land 0x100 = 0))
    (List.drop_last_exn got)
;;

let%test_unit "the duplex image: both programs fit" =
  [%test_result: int] Duplex.rx_origin ~expect:15;
  [%test_pred: int] (fun n -> n <= Isa.program_size) (Array.length Duplex.image)
;;

let%test_unit "chip: full-duplex UART, TX looped back into RX" =
  Quickcheck.test
    (Quickcheck.Generator.both
       (Int.gen_incl 10 24)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255)))
    ~trials:6
    ~sexp_of:[%sexp_of: int * int list]
    ~f:(fun (divisor, bytes) ->
      let bytes = List.take bytes 4 in
      let h = Test_top.create ~half:4 in
      (* A wire from P0 (TX) to P1 (RX). *)
      h.on_cycle
      <- (fun () ->
           let tx = Bits.to_int !((Test_top.o h).uio_out) land 1 in
           (Test_top.i h).uio_in := Bits.of_int ~width:8 (0xFD lor (tx lsl 1)));
      Test_top.load_image h Duplex.image;
      Test_top.configure h ~thread:0 Duplex.tx_config;
      Test_top.configure h ~thread:1 Duplex.rx_config;
      Test_top.write h Top.Addr.pin_modes Duplex.mode_bits;
      Test_top.write h Top.Addr.ctrl 0b11;
      List.iter (Duplex.rx_setup ~divisor) ~f:(Test_top.push ~thread:1 h);
      List.iter (Duplex.tx_setup ~divisor) ~f:(Test_top.push ~thread:0 h);
      List.iter bytes ~f:(fun b ->
        Test_top.push ~thread:0 h b;
        [%test_result: int] (Test_top.pop ~thread:1 h) ~expect:(good b)))
;;
