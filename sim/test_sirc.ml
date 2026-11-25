(* The Sony SIRC transmitter ([Firmware.sirc_tx]) against a receiver
   written here from SIRC's rules: a 40 kHz carrier, a unit of 600 us, a
   start burst of 4 units, then for each bit a unit dark and a burst of 2
   units for a 1 or 1 for a 0, least significant bit first, 12, 15 or 20
   bits, and a frame every 45 ms. The cocotb test runs the same firmware on
   the RTL and the gate netlist with sigrok's SIRC decoder on what a
   receiver module would make of the LED. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let clkdiv = 125 (* 10 MHz: a tick is half a period of 40 kHz *)
let period = 2 * clkdiv
let unit_ = 6000 (* 600 us at 10 MHz *)
let frame_period = 450_000 (* 45 ms *)

(* The LED, cycle by cycle, while [words] are sent with the host keeping
   the FIFO fed. *)
let led ?(source = Firmware.sirc_tx) ~frames words =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.sirc_tx_config ~clkdiv ]
  in
  let pending = Queue.of_list words in
  Array.init ((frames * frame_period) + (4 * unit_)) ~f:(fun _ ->
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    Isa.lines m ~inputs:0xFF land 1 = 1)
;;

type frame =
  { start : int (* cycle of the start burst's first rise *)
  ; bits : int
  ; command : int
  ; address : int
  ; extended : int option
  }
[@@deriving sexp]

(* The receiver. Bursts first: a burst runs from its first rise to one
   period after its last, every rise in it one period after the one before,
   and the LED lit for half of every period. Then each burst and silence in
   units, to within a quarter of a unit; then the frames. *)
let receive trace =
  let rises =
    List.filter (List.range 1 (Array.length trace)) ~f:(fun i -> trace.(i) && not trace.(i - 1))
  in
  let errors = ref [] in
  let error s = if not (List.mem !errors s ~equal:String.equal) then errors := s :: !errors in
  let groups =
    List.group rises ~break:(fun a b ->
      if b - a < period then error (sprintf "carrier period of %d cycles" (b - a));
      b - a > period)
  in
  if Array.count trace ~f:Fn.id <> List.length rises * clkdiv
  then error "the LED is not lit for half a period";
  let units cycles =
    let n = Float.iround_nearest_exn (Float.of_int cycles /. Float.of_int unit_) in
    if abs (cycles - (n * unit_)) > unit_ / 4 then None else Some n
  in
  (* (start, burst in units, silence after it in units; None: longer than a frame's gap) *)
  let runs =
    List.mapi groups ~f:(fun i g ->
      let first = List.hd_exn g in
      let stop = List.last_exn g + period in
      let next = Option.map (List.nth groups (i + 1)) ~f:List.hd_exn in
      let dark = Option.value next ~default:(Array.length trace) - stop in
      first, units (stop - first), if dark > 2 * unit_ then None else units dark)
  in
  let frames = ref [] in
  let rec frame = function
    | [] -> ()
    | (start, Some 4, Some 1) :: rest ->
      let rec bits acc = function
        | (_, Some b, Some 1) :: rest when b = 1 || b = 2 -> bits ((b - 1) :: acc) rest
        | (_, Some b, None) :: rest when b = 1 || b = 2 -> Some (List.rev ((b - 1) :: acc)), rest
        | rest -> None, rest
      in
      (match bits [] rest with
       | Some bits, rest ->
         let value l = List.foldi l ~init:0 ~f:(fun i acc b -> acc lor (b lsl i)) in
         let n = List.length bits in
         let command = value (List.take bits 7) in
         (match n with
          | 12 | 15 ->
            frames
            := { start; bits = n; command; address = value (List.drop bits 7); extended = None } :: !frames
          | 20 ->
            frames
            := { start
               ; bits = n
               ; command
               ; address = value (List.take (List.drop bits 7) 5)
               ; extended = Some (value (List.drop bits 12))
               }
               :: !frames
          | n -> error (sprintf "a frame of %d bits" n));
         frame rest
       | None, rest ->
         error "a bit that is not SIRC's code";
         frame rest)
    | (start, burst, dark) :: rest ->
      error
        (sprintf
           !"not a start burst at cycle %d: %{sexp:int option} lit, %{sexp:int option} dark"
           start
           burst
           dark);
      frame rest
  in
  frame runs;
  let frames = List.rev !frames in
  (* A remote repeats a frame every 45 ms; the program claims exactly. *)
  List.iteri frames ~f:(fun i f ->
    match List.nth frames (i + 1) with
    | Some g when g.start - f.start <> frame_period ->
      error (sprintf "frames %d cycles apart" (g.start - f.start))
    | _ -> ());
  frames, List.rev !errors
;;

let send cases =
  List.concat_map cases ~f:(fun (bits, command, address, extended) ->
    Firmware.sirc_words ~bits ~command ~address ?extended ())
;;

let result ?source cases =
  let frames, errors = receive (led ?source ~frames:(List.length cases) (send cases)) in
  List.map frames ~f:(fun f -> f.bits, f.command, f.address, f.extended), errors
;;

let cases =
  [ 12, 0x15, 0x01, None (* a TV's power key *)
  ; 15, 0x2A, 0xA5, None
  ; 20, 0x1A, 0x1A, Some 0xE2 (* a Blu-ray player's play key *)
  ; 12, 0x7F, 0x1F, None
  ; 20, 0x00, 0x00, Some 0x00
  ; 20, 0x7F, 0x1F, Some 0xFF
  ; 15, 0x00, 0xFF, None
  ]
;;

let%expect_test "SIRC: the words for three frames, and what a receiver makes of the LED" =
  let three = List.take cases 3 in
  printf !"words: %s\n" (String.concat ~sep:" " (List.map (send three) ~f:(sprintf "%04x")));
  let trace = led ~frames:3 (send three) in
  let frames, errors = receive trace in
  List.iter frames ~f:(fun f -> print_s [%sexp (f : frame)]);
  printf !"errors: %{sexp:string list}\n" errors;
  [%expect {|
    words: 000c 0095 000f 52aa 0014 2d1a 000e
    ((start 1875) (bits 12) (command 21) (address 1) (extended ()))
    ((start 451875) (bits 15) (command 42) (address 165) (extended ()))
    ((start 901875) (bits 20) (command 26) (address 26) (extended (226)))
    errors: ()
    |}]
;;

let%test_unit "SIRC: every frame reaches the receiver, 45 ms apart" =
  [%test_result: (int * int * int * int option) list * string list]
    (result cases)
    ~expect:(cases, [])
;;

let%expect_test "planted bugs" =
  let three = List.take cases 3 @ [ List.nth_exn cases 5 ] in
  let caught source =
    not
      ([%equal: (int * int * int * int option) list * string list]
         (result ~source three)
         (three, []))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.sirc_tx ~pattern ~with_ in
    assert (not (String.equal s Firmware.sirc_tx));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.sirc_tx then "WRONG" else "right");
  List.iter
    [ "a 1 sent as a burst of 3 units", fw ~pattern:"set x, 11 " ~with_:"set x, 17 "
    ; "the LED lit in the space before a bit", fw ~pattern:"got:    out x, 1            side 0" ~with_:"got:    out x, 1            side 1"
    ; "the carrier at two thirds of its rate", fw ~pattern:"burst:  nop                 side 1" ~with_:"burst:  nop                 side 1 [1]"
    ; "a 1 not counted against the period", fw ~pattern:"d3:     mov isr, x          side 0" ~with_:"d3:     nop                 side 0"
    ; "the 20-bit frame's second word never taken", fw ~pattern:"jmp !osre have      side 0" ~with_:"jmp have            side 0"
    ; "the space a tick short", fw ~pattern:"got:    out x, 1            side 0 [6]" ~with_:"got:    out x, 1            side 0 [5]"
    ; "one bit too few", fw ~pattern:"out y, 16           side 0" ~with_:"out y, 16           side 0\n        jmp y-- y1          side 0\ny1:     nop                 side 0"
    ]
    ~f:(fun (name, source) -> printf "%-46s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    a 1 sent as a burst of 3 units                 caught
    the LED lit in the space before a bit          caught
    the carrier at two thirds of its rate          caught
    a 1 not counted against the period             caught
    the 20-bit frame's second word never taken     caught
    the space a tick short                         caught
    one bit too few                                caught
    |}]
;;
