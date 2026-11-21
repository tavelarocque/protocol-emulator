(* The TDM audio sender ([Firmware.tdm_tx]) against a codec's receiving
   side written here from the format's rules: it reads DATA and FSYNC as
   BCLK rises, starts a frame at the bit after the one FSYNC was high in,
   and counts. The cocotb test runs the same firmware on the RTL and the
   gate netlist with sigrok's TDM audio decoder reading the three wires. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

module Codec = struct
  type t =
    { mutable bclk : bool
    ; mutable fsync : bool
    ; mutable data : bool
    ; mutable since_change : int (* cycles since DATA or FSYNC last changed *)
    ; mutable since_rise : int
    ; mutable bclk_for : int (* cycles BCLK has been at its level *)
    ; mutable widths : (int * int) list (* (level, cycles) of each BCLK phase seen *)
    ; mutable bits : int list (* since the last frame sync, newest first *)
    ; mutable synced : bool
    ; mutable frames : int list list (* the bits of each whole frame, newest first *)
    ; mutable errors : string list
    }

  let create () =
    { bclk = false
    ; fsync = false
    ; data = false
    ; since_change = 1000
    ; since_rise = 1000
    ; bclk_for = 0
    ; widths = []
    ; bits = []
    ; synced = false
    ; frames = []
    ; errors = []
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors

  let step t ~bclk ~fsync ~data =
    if Bool.( <> ) fsync t.fsync || Bool.( <> ) data t.data
    then (
      if t.since_rise < 1 then error t "DATA or FSYNC changed right after BCLK rose";
      t.since_change <- 0)
    else t.since_change <- t.since_change + 1;
    if Bool.( <> ) bclk t.bclk
    then (
      t.widths <- (Bool.to_int t.bclk, t.bclk_for) :: t.widths;
      t.bclk_for <- 1)
    else t.bclk_for <- t.bclk_for + 1;
    if bclk && not t.bclk
    then (
      if t.since_change < 1 then error t "DATA or FSYNC changed as BCLK rose";
      t.since_rise <- 0;
      if fsync
      then (
        (* The bit FSYNC is high in belongs to the frame before. *)
        if t.synced then t.frames <- List.rev (Bool.to_int data :: t.bits) :: t.frames;
        t.synced <- true;
        t.bits <- [])
      else if t.synced
      then t.bits <- Bool.to_int data :: t.bits)
    else t.since_rise <- t.since_rise + 1;
    t.bclk <- bclk;
    t.fsync <- fsync;
    t.data <- data
  ;;

  let samples frame = List.chunks_of frame ~length:16 |> List.map ~f:(List.fold ~init:0 ~f:(fun a b -> (a lsl 1) lor b))
end

(* Send [frames], and one more of zeros so that the last has a frame sync
   after it. *)
let run ?(source = Firmware.tdm_tx) ?(clkdiv = 1) ~slots frames =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 3 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.tdm_tx_config ~clkdiv ]
  in
  let codec = Codec.create () in
  let words = Firmware.tdm_words ~slots (frames @ [ List.init slots ~f:(fun _ -> 0) ]) in
  let pending = Queue.of_list words in
  for _ = 1 to ((List.length words * 16 * 4) + 40) * max 1 clkdiv do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0xFF;
    let l = Isa.lines m ~inputs:0xFF in
    Codec.step codec ~bclk:(l land 1 = 1) ~fsync:((l lsr 1) land 1 = 1) ~data:((l lsr 2) land 1 = 1)
  done;
  codec
;;

let%expect_test "four slots to a frame" =
  let frames = [ [ 0x8001; 0x1234; 0xFFFF; 0x0000 ]; [ 0xA5A5; 0x5A5A; 0x7FFE; 0xC003 ] ] in
  let codec = run ~slots:4 frames in
  printf !"errors: %{sexp:string list}\n" codec.errors;
  List.iter (List.rev codec.frames) ~f:(fun f ->
    printf "frame of %d bits: %s\n" (List.length f) (String.concat ~sep:" " (List.map (Codec.samples f) ~f:(sprintf "%04x"))));
  (* Every BCLK phase but the first low, which is the wait for the host. *)
  printf
    !"BCLK phases, (level, cycles): %{sexp:(int * int) list}\n"
    (List.dedup_and_sort ~compare:[%compare: int * int] (List.drop_last_exn codec.widths));
  [%expect {|
    errors: ()
    frame of 64 bits: 8001 1234 ffff 0000
    frame of 64 bits: a5a5 5a5a 7ffe c003
    BCLK phases, (level, cycles): ((0 2) (1 2))
    |}]
;;

let%test_unit "random frames of 1 to 8 slots at several speeds" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3 (Int.gen_incl 1 8) (Int.gen_incl 1 4) (Int.gen_incl 0 1_000_000))
    ~trials:60
    ~sexp_of:[%sexp_of: int * int * int]
    ~f:(fun (slots, clkdiv, seed) ->
      let rand = Random.State.make [| seed |] in
      let frames = List.init 3 ~f:(fun _ -> List.init slots ~f:(fun _ -> Random.State.int rand 0x10000)) in
      let codec = run ~clkdiv ~slots frames in
      [%test_result: string list] codec.errors ~expect:[];
      [%test_result: int list list] (List.map (List.rev codec.frames) ~f:Codec.samples) ~expect:frames;
      [%test_result: (int * int) list]
        (List.dedup_and_sort ~compare:[%compare: int * int] (List.drop_last_exn codec.widths))
        ~expect:[ 0, 2 * clkdiv; 1, 2 * clkdiv ])
;;

let%expect_test "planted bugs" =
  let frames = [ [ 0x8001; 0x7FFE; 0x1248 ]; [ 0xFFFF; 0x0000; 0xA5C3 ] ] in
  let caught source =
    let codec = run ~source ~slots:3 frames in
    not
      (List.is_empty codec.errors
       && [%equal: int list list] (List.map (List.rev codec.frames) ~f:Codec.samples) frames
       && [%equal: (int * int) list]
            (List.dedup_and_sort ~compare:[%compare: int * int] (List.drop_last_exn codec.widths))
            [ 0, 2; 1, 2 ])
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.tdm_tx ~pattern ~with_ in
    assert (not (String.equal s Firmware.tdm_tx));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.tdm_tx then "WRONG" else "right");
  List.iter
    [ "the slot count not reloaded: a pulse every slot", fw ~pattern:"last:   mov y, isr " ~with_:"last:   nop        "
    ; "fifteen bits to a sample", fw ~pattern:"set x, 13         side 1" ~with_:"set x, 12         side 1"
    ; "the last slot never looked for: one pulse only", fw ~pattern:"jmp !y last       side 1" ~with_:"nop               side 1"
    ; "the clock stretched while a sample is fetched", fw ~pattern:"pull              side 0       ; the next slot" ~with_:"pull              side 0 [1]   ; the next slot"
    ; "FSYNC raised with the clock, after the data", fw ~pattern:"sync:   out pins, 1       side 2       ; bit 0 with FSYNC high\n        pull              side 2" ~with_:"sync:   out pins, 1       side 0       ; bit 0 with FSYNC high\n        pull              side 0"
    ; "bit 0 changed as the clock rises", fw ~pattern:"out pins, 1       side 0       ; bit 0\n        pull              side 0 " ~with_:"pull              side 0       ; bit 0\n        out pins, 1       side 1 "
    ]
    ~f:(fun (name, source) -> printf "%-50s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the slot count not reloaded: a pulse every slot    caught
    fifteen bits to a sample                           caught
    the last slot never looked for: one pulse only     caught
    the clock stretched while a sample is fetched      caught
    FSYNC raised with the clock, after the data        caught
    bit 0 changed as the clock rises                   caught
    |}]
;;
