(* The XY2-100 sender ([Firmware.xy2_x] on thread 0, [Firmware.xy2_y] on
   thread 1) against a galvanometer driver's receiving side written here
   from the protocol's rules (the XY2-100 description in sigrok's decoder
   documentation and the scanner makers' manuals): a 2 MHz clock; data and
   SYNC change as the clock rises and are read as it falls; a frame is the
   bits up to and including the one read with SYNC low; a position frame is
   20 bits, control bits 001, 16 bits most significant first, and a parity
   bit that makes the number of ones even. The cocotb test runs the same
   firmware on the RTL and the gate netlist with sigrok's XY2-100 decoder
   reading each axis. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

(* The scanner. [tick] is the cycles in one of the sender's ticks: the
   clock must be high for 2 of them and low for 3 in every bit of a frame.
   With [strict], the host has kept ahead, and frames must follow one
   another with no gap and every change of X or Y come with a rising
   clock. *)
module Scanner = struct
  type axis =
    { mutable bits : int list (* newest first *)
    ; mutable frames : int list (* positions, newest first *)
    }

  type t =
    { tick : int
    ; strict : bool
    ; x : axis
    ; y : axis
    ; mutable clk : bool
    ; mutable sync : bool
    ; mutable dx : bool
    ; mutable dy : bool
    ; mutable started : bool (* the clock has risen once *)
    ; mutable last_rise : int option
    ; mutable last_fall : int option
    ; mutable in_frame : bool
    ; mutable last_change : int (* of X, Y or SYNC *)
    ; mutable errors : string list
    ; mutable now : int
    }

  let create ~tick ~strict =
    { tick
    ; strict
    ; x = { bits = []; frames = [] }
    ; y = { bits = []; frames = [] }
    ; clk = false
    ; sync = false
    ; dx = false
    ; dy = false
    ; started = false
    ; last_rise = None
    ; last_fall = None
    ; in_frame = false
    ; last_change = 0
    ; errors = []
    ; now = 0
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  let finish t name axis =
    let bits = List.rev axis.bits in
    axis.bits <- [];
    match bits with
    | 0 :: 0 :: 1 :: rest when List.length rest = 17 ->
      if List.sum (module Int) bits ~f:Fn.id % 2 <> 0 then error t (name ^ ": odd parity");
      let pos = List.fold (List.take rest 16) ~init:0 ~f:(fun a b -> (a lsl 1) lor b) in
      axis.frames <- (if pos >= 0x8000 then pos - 0x10000 else pos) :: axis.frames
    | _ ->
      error
        t
        (sprintf "%s: a frame of %d bits, %s" name (List.length bits) (String.concat (List.map bits ~f:Int.to_string)))
  ;;

  let step t ~clk ~sync ~dx ~dy =
    let changed = Bool.( <> ) sync t.sync || Bool.( <> ) dx t.dx || Bool.( <> ) dy t.dy in
    let rise = clk && not t.clk in
    let fall = t.clk && not clk in
    if t.started && changed
    then (
      (* Held from a tick before the clock falls to a tick after. *)
      (match t.last_fall with
       | Some f when t.now - f <= t.tick -> error t "a line changed just after CLK fell"
       | _ -> ());
      (* Between frames, with the host late, Y takes bit 0's level early. *)
      if t.strict && t.in_frame && not rise then error t "a line changed with no rising CLK";
      t.last_change <- t.now);
    if fall
    then (
      if t.now - t.last_change < t.tick then error t "a line changed just before CLK fell";
      (match t.last_rise with
       | Some r when t.now - r <> 2 * t.tick -> error t (sprintf "CLK high for %d cycles" (t.now - r))
       | _ -> ());
      t.x.bits <- Bool.to_int dx :: t.x.bits;
      t.y.bits <- Bool.to_int dy :: t.y.bits;
      t.in_frame <- sync;
      if not sync
      then (
        finish t "X" t.x;
        finish t "Y" t.y);
      t.last_fall <- Some t.now);
    if rise
    then (
      (match t.last_rise with
       | Some r when (t.in_frame || t.strict) && t.now - r <> 5 * t.tick ->
         error t (sprintf "a bit of %d cycles" (t.now - r))
       | _ -> ());
      t.started <- true;
      t.last_rise <- Some t.now);
    t.clk <- clk;
    t.sync <- sync;
    t.dx <- dx;
    t.dy <- dy;
    t.now <- t.now + 1
  ;;
end

(* [late]: the host pushes each frame's words only after the frame before
   has been sent, so the clock waits between frames. *)
let run ?(x_source = Firmware.xy2_x) ?(y_source = Firmware.xy2_y) ?(late = false) ~clkdiv points =
  let m =
    Isa.create_separate
      ~programs:[| Asm.assemble x_source; Asm.assemble y_source |]
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 4 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.xy2_x_config ~clkdiv; Firmware.xy2_y_config ~clkdiv ]
  in
  Isa.set_chain m true;
  let scanner = Scanner.create ~tick:clkdiv ~strict:(not late) in
  let pending = Queue.of_list (Firmware.Xy2.words points) in
  let gap = ref 0 in
  (* A frame is 100 ticks; one more frame's time ends the run. *)
  for _ = 1 to ((List.length points * if late then 200 else 100) + 150) * clkdiv do
    (if !gap > 0
     then decr gap
     else
       match Queue.peek pending with
       | Some v ->
         if Isa.push_tx m ~thread:0 v
         then (
           ignore (Queue.dequeue pending : int option);
           if late && Queue.length pending % 2 = 0 then gap := 160 * clkdiv)
       | None -> ());
    Isa.step m ~inputs:0;
    let l = Isa.lines m ~inputs:0 in
    let pin i = (l lsr i) land 1 = 1 in
    Scanner.step scanner ~clk:(pin 0) ~sync:(pin 1) ~dx:(pin 2) ~dy:(pin 3)
  done;
  scanner
;;

let result (s : Scanner.t) = s.errors, List.zip_exn (List.rev s.x.frames) (List.rev s.y.frames)

let%expect_test "four points, back to back at 2 MHz, then with the host late" =
  let points = [ 0, 0; 32767, -32768; -1, 1; 0x1234, 0x5A5A ] in
  List.iter [ false; true ] ~f:(fun late ->
    let errors, frames = result (run ~late ~clkdiv:1 points) in
    printf !"late %b: errors %{sexp:string list}\n" late errors;
    List.iter frames ~f:(fun (x, y) -> printf "  X %6d  Y %6d\n" x y));
  [%expect {|
    late false: errors ()
      X      0  Y      0
      X  32767  Y -32768
      X     -1  Y      1
      X   4660  Y  23130
    late true: errors ()
      X      0  Y      0
      X  32767  Y -32768
      X     -1  Y      1
      X   4660  Y  23130
    |}]
;;

let%test_unit "random points, at several clock dividers, host ahead or late" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 1 6)
       Bool.quickcheck_generator
       (Quickcheck.Generator.list_non_empty
          (Quickcheck.Generator.tuple2 (Int.gen_incl (-32768) 32767) (Int.gen_incl (-32768) 32767))))
    ~trials:150
    ~sexp_of:[%sexp_of: int * bool * (int * int) list]
    ~f:(fun (clkdiv, late, points) ->
      let points = List.take points 6 in
      let errors, frames = result (run ~late ~clkdiv points) in
      [%test_result: string list] errors ~expect:[];
      [%test_result: (int * int) list] frames ~expect:points)
;;

let%expect_test "planted bugs" =
  (* Parity odd and even both, ones in every bit position of each axis. *)
  let points = [ 1, 3; -1, 0x7FFF; 0x5555, -0x5556; 0, 0x0F0F; 0x1234, 0x4321 ] in
  let caught ~x_source ~y_source =
    List.exists [ 1, false; 1, true; 3, false ] ~f:(fun (clkdiv, late) ->
      let errors, frames =
        try result (run ~x_source ~y_source ~late ~clkdiv points) with
        | _ -> [ "frames missing" ], []
      in
      not (List.is_empty errors && [%equal: (int * int) list] frames points))
  in
  let fw source ~pattern ~with_ =
    let s = String.substr_replace_first source ~pattern ~with_ in
    assert (not (String.equal s source));
    s
  in
  let x = fw Firmware.xy2_x and y = fw Firmware.xy2_y in
  printf
    "the programs as they are: %s\n"
    (if caught ~x_source:Firmware.xy2_x ~y_source:Firmware.xy2_y then "WRONG" else "right");
  List.iter
    [ "control bits 000", x ~pattern:"set pins, 1      side 3 [1]" ~with_:"set pins, 0      side 3 [1]", Firmware.xy2_y
    ; "X's parity not started again", x ~pattern:"mov crc, null    side 3" ~with_:"nop              side 3", Firmware.xy2_y
    ; "X's parity bit always 0", x ~pattern:"mov pins, crc    side 1" ~with_:"set pins, 0      side 1", Firmware.xy2_y
    ; "SYNC low in the parity bit's high half only", x ~pattern:"jmp frame        side 1" ~with_:"jmp frame        side 3", Firmware.xy2_y
    ; "SYNC low after every bit", x ~pattern:"jmp !osre bit    side 2 [2]" ~with_:"jmp !osre bit    side 0 [2]", Firmware.xy2_y
    ; "CLK low for 2 ticks", x ~pattern:"jmp !osre bit    side 2 [2]" ~with_:"jmp !osre bit    side 2 [1]", Firmware.xy2_y
    ; "Y's position not handed over", x ~pattern:"push             side 2" ~with_:"nop              side 2", Firmware.xy2_y
    ; "Y's parity not started again", Firmware.xy2_x, y ~pattern:"mov crc, null" ~with_:"nop          "
    ; "Y's parity bit always 0", Firmware.xy2_x, y ~pattern:"mov pins, crc" ~with_:"set pins, 0  "
    ; "Y a tick late", Firmware.xy2_x, y ~pattern:"bit:    wait 0 pin 0 [1]" ~with_:"bit:    wait 0 pin 0 [2]"
    ; "Y a tick early", Firmware.xy2_x, y ~pattern:"bit:    wait 0 pin 0 [1]" ~with_:"bit:    wait 0 pin 0    "
    ; ( "Y's position taken in bit 0"
      , Firmware.xy2_x
      , y ~pattern:"set pins, 0                     ; bit 0, as CLK rises\n        wait 1 pin 0\n"
          ~with_:"set pins, 0                     ; bit 0, as CLK rises\n        wait 1 pin 0\n        pull\n"
        |> String.substr_replace_first
             ~pattern:"        pull                            ; the position, from thread 0\n"
             ~with_:"" )
    ]
    ~f:(fun (name, x_source, y_source) ->
      printf "%-45s %s\n" name (if caught ~x_source ~y_source then "caught" else "MISSED"));
  [%expect {|
    the programs as they are: right
    control bits 000                              caught
    X's parity not started again                  caught
    X's parity bit always 0                       caught
    SYNC low in the parity bit's high half only   caught
    SYNC low after every bit                      caught
    CLK low for 2 ticks                           caught
    Y's position not handed over                  caught
    Y's parity not started again                  caught
    Y's parity bit always 0                       caught
    Y a tick late                                 caught
    Y a tick early                                caught
    Y's position taken in bit 0                   caught
    |}]
;;
