(* The LFAST sender ([Firmware.lfast]) against a receiver written here from
   the LFAST frame of NXP's and Infineon's manuals (the TC27x user manual's
   tables, which sigrok's decoder cites): NRZ, most significant bit first,
   the sync pattern 0xA84B, a header byte whose top three bits give the
   payload's size, the payload, a sleep bit. It samples each bit in its
   middle from the first edge, and requires every edge of the frame on a
   bit boundary. The payload is then checked as a SIPI frame: its CRC-16
   (CCITT's polynomial 0x1021, from all ones, most significant bit first),
   written here, over all of it but the CRC. The cocotb test runs the
   same firmware on the RTL and the gate netlist with sigrok's LFAST and
   SIPI decoders reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let crc16 bytes =
  List.fold bytes ~init:0xFFFF ~f:(fun crc b ->
    let crc = ref (crc lxor (b lsl 8)) in
    for _ = 1 to 8 do
      crc := if !crc land 0x8000 <> 0 then ((!crc lsl 1) lxor 0x1021) land 0xFFFF else (!crc lsl 1) land 0xFFFF
    done;
    !crc)
;;

(* Payload bytes for each size code. *)
let payload_bytes = [| 1; 4; 8; 12; 16; 32; 64; 36 |]

type frame =
  { header : int
  ; payload : int list
  ; sleep : int
  }
[@@deriving sexp_of, equal, compare]

(* The frames on [line] (one level per core clock) at [bit] clocks a bit. *)
let receive ~bit (line : bool array) =
  let n = Array.length line in
  let at t = t < n && line.(t) in
  let rec next_change t = if t + 1 >= n then None else if Bool.( <> ) line.(t) line.(t + 1) then Some (t + 1) else next_change (t + 1) in
  let rec frames t acc =
    match next_change t with
    | None -> List.rev acc
    | Some r when not (at r) -> frames r (Error (sprintf "a falling edge at %d with no frame" r) :: acc)
    | Some r ->
      let sample i = Bool.to_int (at (r + (i * bit) + (bit / 2))) in
      let field ~pos ~width = List.init width ~f:(fun k -> sample (pos + k)) |> List.fold ~init:0 ~f:(fun a b -> (a lsl 1) lor b) in
      let sync = field ~pos:0 ~width:16 in
      let header = field ~pos:16 ~width:8 in
      let size = payload_bytes.(header lsr 5) in
      let payload = List.init size ~f:(fun k -> field ~pos:(24 + (8 * k)) ~width:8) in
      let bits = 24 + (8 * size) + 1 in
      let sleep = sample (bits - 1) in
      let ends = r + (bits * bit) in
      (* Every edge inside the frame on a bit boundary, and the line low
         for two bits after it. *)
      let rec off_beat t =
        match next_change t with
        | Some e when e < ends -> if (e - r) % bit <> 0 then Some e else off_beat e
        | _ -> None
      in
      let result =
        if sync <> 0xA84B
        then Error (sprintf "sync %04x" sync)
        else (
          match off_beat r with
          | Some e -> Error (sprintf "an edge %d clocks into a bit" ((e - r) % bit))
          | None ->
            if List.exists (List.range ends (ends + (2 * bit))) ~f:at
            then Error "the line not idle after the frame"
            else Ok { header; payload; sleep })
      in
      frames (max ends r) (result :: acc)
  in
  frames 0 []
;;

(* A SIPI frame's words, if its CRC is right. *)
let sipi payload =
  let body = List.drop_last_exn (List.drop_last_exn payload) in
  let crc = List.fold (List.drop payload (List.length body)) ~init:0 ~f:(fun a b -> (a lsl 8) lor b) in
  if crc <> crc16 body
  then Error (sprintf "CRC %04x, want %04x" crc (crc16 body))
  else Ok (List.chunks_of body ~length:2 |> List.map ~f:(function [ h; l ] -> (h lsl 8) lor l | _ -> assert false))
;;

let run ?(source = Firmware.lfast) ?(clkdiv = 1) frames =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.lfast_config ~clkdiv ]
  in
  let pending = Queue.of_list (List.concat_map frames ~f:(fun (header, words) -> Firmware.lfast_words ~header words)) in
  let bits = List.sum (module Int) frames ~f:(fun (_, words) -> 16 + 8 + (16 * List.length words) + 16 + 1 + 8) in
  let line = Queue.create () in
  for _ = 1 to (bits * 5 * clkdiv) + 200 do
    (* A host as fast as the packet buffer: a word whenever there is room. *)
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0;
    Queue.enqueue line (Isa.lines m ~inputs:0 land 1 = 1)
  done;
  receive ~bit:(5 * clkdiv) (Queue.to_array line)
;;

(* SIPI's header word: tag, command, channel. *)
let sipi_header ~tag ~command ~channel = (tag lsl 13) lor (command lsl 8) lor (channel lsl 1)

(* The LFAST header for a SIPI frame of [words] (and its CRC) on data
   channel A. *)
let lfast_header words =
  let bytes = (2 * List.length words) + 2 in
  let code = Option.value_exn (Array.findi payload_bytes ~f:(fun _ b -> b = bytes)) |> fst in
  (code lsl 5) lor (0b0100 lsl 1)
;;

let expect frames =
  List.map frames ~f:(fun (header, words) ->
    let bytes = List.concat_map words ~f:(fun w -> [ w lsr 8; w land 0xFF ]) in
    let crc = crc16 bytes in
    Ok { header; payload = bytes @ [ crc lsr 8; crc land 0xFF ]; sleep = 0 })
;;

let write = [ sipi_header ~tag:1 ~command:0b00110 ~channel:1; 0x4000; 0x1000; 0xDEAD; 0xBEEF ]
let read = [ sipi_header ~tag:2 ~command:0b00010 ~channel:1; 0x4000; 0x1000 ]
let jtag_id = [ sipi_header ~tag:3 ~command:0b10010 ~channel:0 ]
let session = List.map [ write; read; jtag_id ] ~f:(fun w -> lfast_header w, w)

let%test_unit "program: 33 words" = [%test_result: int] (Array.length (Asm.assemble Firmware.lfast)) ~expect:33

let%expect_test "a write, a read and a JTAG ID request, at three speeds" =
  List.iter [ 1; 2; 3 ] ~f:(fun clkdiv ->
    [%test_result: (frame, string) Result.t list] (run ~clkdiv session) ~expect:(expect session));
  List.iter (run session) ~f:(fun f ->
    let f = Result.ok_or_failwith f in
    printf
      !"header %02x, %d bytes, SIPI %{sexp:(string list, string) Result.t}, sleep %d\n"
      f.header
      (List.length f.payload)
      (Result.map (sipi f.payload) ~f:(List.map ~f:(sprintf "%04x")))
      f.sleep);
  [%expect
    {|
    header 68, 12 bytes, SIPI (Ok (2602 4000 1000 dead beef)), sleep 0
    header 48, 8 bytes, SIPI (Ok (4202 4000 1000)), sleep 0
    header 28, 4 bytes, SIPI (Ok (7200)), sleep 0
    |}]
;;

let%test_unit "random SIPI frames of every size LFAST carries" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Quickcheck.Generator.of_list [ 1; 3; 5; 7; 15; 17; 31 ])
       (Quickcheck.Generator.list_with_length 31 (Int.gen_incl 0 0xFFFF))
       (Int.gen_incl 1 3))
    ~trials:40
    ~sexp_of:[%sexp_of: int * int list * int]
    ~f:(fun (n, words, clkdiv) ->
      let frames = [ (let w = List.take words n in lfast_header w, w) ] in
      [%test_result: (frame, string) Result.t list] (run ~clkdiv frames) ~expect:(expect frames))
;;

let%expect_test "planted bugs" =
  let good = Firmware.lfast in
  let caught source = not ([%equal: (frame, string) Result.t list] (run ~source session) (expect session)) in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first good ~pattern ~with_ in
    assert (not (String.equal s good));
    s
  in
  printf "the program as it is: %s\n" (if caught good then "WRONG" else "right");
  List.iter
    [ "the sync pattern's third bit 0", fw ~pattern:"set pins, 0 [4]\n        set pins, 1 [4]\n        set pins, 0 [4]\n        set pins, 1 [4]\n        set pins, 0 " ~with_:"set pins, 0 [4]\n        set pins, 0 [4]\n        set pins, 0 [4]\n        set pins, 1 [4]\n        set pins, 0 "
    ; "the header's last bit a tick short", fw ~pattern:"        nop\nword:" ~with_:"word:"
    ; "a word of the frame left out", fw ~pattern:"jmp x-- word" ~with_:"jmp !x word "
    ; "the CRC over the LFAST header too", fw ~pattern:"mov crc, null           ; the CRC covers" ~with_:"nop                     ; the CRC covers"
    ; "the CRC sent the wrong way round", fw ~pattern:"crc:    mov pins, isr [2]\n        in null, 1" ~with_:"crc:    mov osr, isr [2]\n        out pins, 1"
    ; "the last bit of the frame a tick long", fw ~pattern:"mov isr, crc " ~with_:"mov isr, crc [1]"
    ; "a sleep request", fw ~pattern:"set pins, 0 [4]         ; the sleep bit" ~with_:"set pins, 1 [4]         ; the sleep bit"
    ]
    ~f:(fun (name, source) -> printf "%-40s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect
    {|
    the program as it is: right
    the sync pattern's third bit 0           caught
    the header's last bit a tick short       caught
    a word of the frame left out             caught
    the CRC over the LFAST header too        caught
    the CRC sent the wrong way round         caught
    the last bit of the frame a tick long    caught
    a sleep request                          caught
    |}]
;;
