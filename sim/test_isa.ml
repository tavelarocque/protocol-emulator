(* Tests for the ISA reference model, the assembler, and the first firmware.

   The model will become the oracle for the hardware core, so it gets the
   same treatment as hardware: exhaustive checks where the space is small,
   Quickcheck where it is not, and independent oracles for behaviour. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Uart_model = Pe_model.Uart_model

(* --- Encoding ----------------------------------------------------------- *)

(* All 65,536 instruction words: decode is total, and re-encoding a decoded
   instruction gives back an equivalent instruction. *)
let%test_unit "every 16-bit word decodes, and encode/decode round-trips" =
  for w = 0 to Isa.word_mask do
    let i = Isa.Instruction.decode w in
    [%test_result: Isa.Instruction.t] (Isa.Instruction.decode (Isa.Instruction.encode i)) ~expect:i
  done
;;

(* All 65,536 words again: the disassembler emits text the assembler reads
   back to the same instruction. *)
let%test_unit "disassemble then assemble round-trips for every word" =
  for w = 0 to Isa.word_mask do
    let i = Isa.Instruction.decode w in
    let text = Isa.Instruction.to_string i in
    match Asm.assemble text with
    | [| j |] -> [%test_result: Isa.Instruction.t] j ~expect:i ~message:text
    | _ -> raise_s [%message "expected one instruction" (text : string)]
  done
;;

let%test_unit "assembler rejects bad input" =
  List.iter
    [ "jmp nowhere"
    ; "set pins, 32"
    ; "wait 2 pin 0"
    ; "out pins, 17"
    ; "nop [16]"
    ; "frobnicate"
    ; "a: nop\na: nop"
    ]
    ~f:(fun src ->
      match Asm.assemble src with
      | _ -> raise_s [%message "assembler accepted bad input" (src : string)]
      | exception _ -> ())
;;

(* --- Semantics ---------------------------------------------------------- *)

let all_input = Array.create ~len:Isa.num_pins Isa.Pin_mode.Input

let machine ?(pin_modes = all_input) ?(configs = [ Isa.Thread_config.default ]) src =
  Isa.create ~program:(Asm.assemble src) ~pin_modes ~threads:configs
;;

let run m ~cycles ~inputs =
  for _ = 1 to cycles do
    Isa.step m ~inputs
  done
;;

let%test_unit "jmp x-- runs its loop body x+1 times" =
  let m = machine "set x, 5\nloop: jmp x-- loop\nnop" in
  (* 1 cycle for SET, then 6 iterations of the JMP. *)
  run m ~cycles:6 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).pc ~expect:1;
  run m ~cycles:1 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).pc ~expect:2
;;

let%test_unit "delay field adds idle cycles after the instruction" =
  let m = machine "nop [3]\nnop" in
  run m ~cycles:4 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).pc ~expect:1;
  run m ~cycles:1 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).pc ~expect:2
;;

let wait_program =
  {|
        set y, 7            ; Y must survive the timed wait untouched
        wait 1 pin 2 timeout
        set x, 1            ; pin went high in time
hang1:  jmp hang1
        set x, 2            ; address 4: timeout vector
hang2:  jmp hang2
|}
;;

let wait_config = { Isa.Thread_config.default with timeout_vector = 4; timeout = 5 }

let%test_unit "wait with timeout: pin arrives in time" =
  let m = machine ~configs:[ wait_config ] wait_program in
  run m ~cycles:20 ~inputs:0b100;
  [%test_result: int] (Isa.thread m 0).x ~expect:1
;;

let%test_unit "wait with timeout: pin never arrives, jump to timeout vector" =
  let m = machine ~configs:[ wait_config ] wait_program in
  run m ~cycles:20 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).x ~expect:2;
  [%test_result: int] (Isa.thread m 0).y ~expect:7
;;

let%test_unit "wait with timeout: stalls exactly TIMEOUT cycles before giving up" =
  for timeout = 0 to 12 do
    let m =
      machine ~configs:[ { wait_config with timeout } ] wait_program
    in
    (* Cycle 1 runs SET; the wait then stalls [timeout] cycles and jumps on
       the next, so the PC reaches the vector after 2 + timeout cycles. *)
    run m ~cycles:(1 + timeout) ~inputs:0;
    [%test_result: int] (Isa.thread m 0).pc ~expect:1 ~message:(sprintf "T=%d still waiting" timeout);
    run m ~cycles:1 ~inputs:0;
    [%test_result: int] (Isa.thread m 0).pc ~expect:4 ~message:(sprintf "T=%d jumped" timeout)
  done
;;

let%test_unit "each timed wait gets a fresh budget" =
  (* Two timed waits back to back: the second must not inherit the first's
     spent budget. Pin 2 rises after 3 cycles in the first wait. *)
  let m =
    machine
      ~configs:[ { Isa.Thread_config.default with timeout_vector = 5; timeout = 6 } ]
      {|
        wait 1 pin 2 timeout
        wait 0 pin 2 timeout
        set x, 1
hang1:  jmp hang1
        nop
        set x, 2            ; address 5: timeout vector
hang2:  jmp hang2
|}
  in
  run m ~cycles:3 ~inputs:0;
  run m ~cycles:1 ~inputs:0b100;
  (* Now in the second wait with the pin high: it should time out after a
     full budget of 6 stalled cycles, not sooner. *)
  run m ~cycles:6 ~inputs:0b100;
  [%test_result: int] (Isa.thread m 0).pc ~expect:1;
  run m ~cycles:1 ~inputs:0b100;
  [%test_result: int] (Isa.thread m 0).pc ~expect:5
;;

let%test_unit "wait without timeout stalls forever" =
  let m = machine "wait 1 pin 2\nset x, 1" in
  run m ~cycles:1000 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).pc ~expect:0
;;

let%test_unit "open-drain pin: 0 drives low, 1 releases to whatever is outside" =
  let pin_modes = Array.copy all_input in
  pin_modes.(3) <- Isa.Pin_mode.Open_drain;
  let configs = [ { Isa.Thread_config.default with set_base = 3 } ] in
  let m = machine ~pin_modes ~configs "set pins, 0\nset pins, 1\nhang: jmp hang" in
  let level ~inputs = (Isa.lines m ~inputs lsr 3) land 1 in
  run m ~cycles:1 ~inputs:0xFF;
  [%test_result: int] (level ~inputs:0xFF) ~expect:0;
  run m ~cycles:1 ~inputs:0xFF;
  [%test_result: int] (level ~inputs:0xFF) ~expect:1;
  (* Released, but another device on the bus is pulling it low. *)
  [%test_result: int] (level ~inputs:0x00) ~expect:0
;;

let%test_unit "two threads writing one pin: higher-numbered thread wins" =
  let pin_modes = Array.copy all_input in
  pin_modes.(0) <- Isa.Pin_mode.Push_pull;
  let configs =
    [ Isa.Thread_config.default; { Isa.Thread_config.default with start = 2 } ]
  in
  let m =
    machine ~pin_modes ~configs "a: set pins, 0\njmp a\nb: set pins, 1\njmp b"
  in
  run m ~cycles:1 ~inputs:0;
  [%test_result: int] (Isa.pin_out m land 1) ~expect:1
;;

let%test_unit "in/push: bits shifted in LSB-first come out right-justified" =
  let m =
    machine
      {|
        set x, 1
        in x, 1            ; bit 0 = 1
        set x, 0
        in x, 1            ; bit 1 = 0
        set x, 1
        in x, 1            ; bit 2 = 1
        push
hang:   jmp hang
|}
  in
  run m ~cycles:20 ~inputs:0;
  [%test_result: int option] (Isa.pop_rx m ~thread:0) ~expect:(Some 0b101)
;;

let%test_unit "out: bits leave the OSR LSB-first" =
  let m = machine "pull\nout x, 3\nout y, 5\nhang: jmp hang" in
  assert (Isa.push_tx m ~thread:0 0b10110_011);
  run m ~cycles:10 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).x ~expect:0b011;
  [%test_result: int] (Isa.thread m 0).y ~expect:0b10110
;;

(* --- First firmware: UART TX on the model, judged by the UART oracles ---- *)

let uart_tx_machine () =
  let pin_modes = Array.copy all_input in
  pin_modes.(0) <- Isa.Pin_mode.Push_pull;
  Isa.create
    ~program:(Asm.assemble Firmware.uart_tx)
    ~pin_modes
    ~threads:[ Isa.Thread_config.default ]
;;

(* Feed [divisor - 4] then [bytes] to the FIFO as space allows, and record
   the TX pin on every cycle. *)
let run_uart_tx ~divisor ~bytes =
  let m = uart_tx_machine () in
  let pending = Queue.of_list ((divisor - 4) :: bytes) in
  let cycles = 32 + (List.length bytes * ((10 * divisor) + 8)) + (2 * divisor) in
  (* An explicit loop, not List.init: List.init does not promise to call its
     function in index order, and this function has side effects. *)
  let trace = Queue.create () in
  for _ = 1 to cycles do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0;
    Queue.enqueue trace (Isa.lines m ~inputs:0 land 1 = 1)
  done;
  Queue.to_list trace
;;

let%test_unit "UART TX firmware: exact 8N1 waveform for random bytes and baud rates" =
  Quickcheck.test
    (Quickcheck.Generator.both (Int.gen_incl 0 255) (Int.gen_incl 4 64))
    ~trials:300
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (byte, divisor) ->
      let line = run_uart_tx ~divisor ~bytes:[ byte ] in
      let start =
        match List.findi line ~f:(fun _ level -> not level) with
        | Some (i, _) -> i
        | None -> raise_s [%message "no start bit"]
      in
      (* Line is idle-high before the frame. *)
      [%test_result: bool] (List.for_all (List.take line start) ~f:Fn.id) ~expect:true;
      let frame = List.sub line ~pos:start ~len:(10 * divisor) in
      [%test_result: bool list] frame ~expect:(Uart_model.frame ~divisor byte))
;;

let%test_unit "UART TX firmware: back-to-back bytes decode with a real receiver" =
  Quickcheck.test
    (Quickcheck.Generator.both
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 4 48))
    ~trials:200
    ~sexp_of:[%sexp_of: int list * int]
    ~f:(fun (bytes, divisor) ->
      let bytes = List.take bytes 6 in
      let line = run_uart_tx ~divisor ~bytes in
      [%test_result: (int list, Uart_model.Decode_error.t) Result.t]
        (Uart_model.decode ~divisor line)
        ~expect:(Ok bytes))
;;

(* --- Side-set ------------------------------------------------------------ *)

let side_config ~n =
  { Isa.Thread_config.default with sideset_base = 2; sideset_count = n; set_base = 2 }
;;

let%test_unit "side-set drives its pins and wins over the instruction's own write" =
  let m =
    machine ~configs:[ side_config ~n:1 ] ".side_set 1\nset pins, 0 side 1\nhang: jmp hang side 1"
  in
  run m ~cycles:1 ~inputs:0;
  [%test_result: int] ((Isa.pin_out m lsr 2) land 1) ~expect:1
;;

let%test_unit "side-set is driven while the instruction stalls" =
  let m = machine ~configs:[ side_config ~n:1 ] ".side_set 1\npull side 0\nnop side 1" in
  run m ~cycles:1 ~inputs:0;
  (* Still stalled on the empty FIFO, but the side pin went low. *)
  [%test_result: int] (Isa.thread m 0).pc ~expect:0;
  [%test_result: int] ((Isa.pin_out m lsr 2) land 1) ~expect:0
;;

let%test_unit "side-set splits the delay field: value on top, delay below" =
  let m =
    machine
      ~configs:[ side_config ~n:2 ]
      ".side_set 2\nnop side 2 [3]\nnop side 1\nhang: jmp hang side 1"
  in
  let program = Asm.assemble ".side_set 2\nnop side 2 [3]" in
  [%test_result: int] program.(0).delay ~expect:((2 lsl 2) lor 3);
  run m ~cycles:1 ~inputs:0;
  [%test_result: int] ((Isa.pin_out m lsr 2) land 3) ~expect:2;
  [%test_result: int] (Isa.thread m 0).delay_left ~expect:3;
  run m ~cycles:4 ~inputs:0;
  [%test_result: int] (Isa.thread m 0).pc ~expect:2;
  [%test_result: int] ((Isa.pin_out m lsr 2) land 3) ~expect:1
;;

let%test_unit "assembler enforces side-set syntax" =
  List.iter
    [ "nop side 1" (* side without .side_set *)
    ; ".side_set 1\nnop" (* missing side *)
    ; ".side_set 1\nnop side 2" (* value too wide *)
    ; ".side_set 2\nnop side 0 [4]" (* delay too wide after side-set *)
    ; "nop\n.side_set 1" (* directive after the first instruction *)
    ; ".side_set 4"
    ]
    ~f:(fun src ->
      match Asm.assemble src with
      | _ -> raise_s [%message "assembler accepted bad side-set input" (src : string)]
      | exception _ -> ())
;;
