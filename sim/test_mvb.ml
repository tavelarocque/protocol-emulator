(* The MVB sender ([Firmware.mvb]) against a receiver written here from the
   frame of IEC 61375-3-1: Manchester code, a 1 high then low and a 0 low
   then high, a start bit and the master or slave start delimiter (1 NH NL
   0 NH NL 0 0 0, or 1 1 1 1 NL NH 1 NL NH, where NH and NL are a whole bit
   time high or low), the data most significant bit first, a check
   sequence after every 64 bits (or after all of a shorter frame), and an
   NH ending the frame before the line goes silent. The check sequence is
   computed here bit by bit as the standard defines it: the 7-bit
   remainder by x^7 + x^6 + x^5 + x^2 + 1, an even parity bit over the
   data and those 7 bits, all 8 inverted. The firmware computes it another
   way (one remainder by that polynomial times x + 1), so the two meet only
   if the algebra in its comment is right. Every edge must fall on the
   half-bit grid counted from the frame's first edge, and the driver
   enable must be on exactly from the start bit to the end of the NH. The
   cocotb test runs the same firmware on the RTL and the gate netlist,
   with an MVB decoder for sigrok written by others reading the wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

type frame =
  | Master of int
  | Slave of int list
  | Bad of string
[@@deriving sexp_of, equal, compare]

let check_sequence bits =
  (* The remainder of the data times x^7 by the generator, MSB first. *)
  let g = 0b1100101 in
  let r = List.fold bits ~init:0 ~f:(fun r b -> let top = ((r lsr 6) land 1) lxor b in let r = (r lsl 1) land 0x7F in if top = 1 then r lxor g else r) in
  let crc = List.init 7 ~f:(fun k -> (r lsr (6 - k)) land 1) in
  let parity = List.fold (bits @ crc) ~init:0 ~f:( lxor ) in
  List.map (crc @ [ parity ]) ~f:(fun b -> 1 - b)
;;

let master_delimiter = [ 1; 0; 1; 1; 0; 0; 0; 1; 1; 1; 0; 0; 0; 1; 0; 1; 0; 1 ]
let slave_delimiter = [ 1; 0; 1; 0; 1; 0; 1; 0; 0; 0; 1; 1; 1; 0; 0; 0; 1; 1 ]

(* The frames on [line] (the bus level, one per clock), with [enable] the
   driver's enable, at [half] clocks a half bit. *)
let receive ~half (line : bool array) (enable : bool array) =
  let n = Array.length line in
  let level t = t < n && line.(t) in
  let rec next_rise t = if t + 1 >= n then None else if (not line.(t)) && line.(t + 1) then Some (t + 1) else next_rise (t + 1) in
  let rec frames t acc =
    match next_rise t with
    | None -> List.rev acc
    | Some r ->
      let h k = Bool.to_int (level (r + (k * half) + (half / 2))) in
      let halves = List.init 18 ~f:h in
      let kind =
        if List.equal Int.equal halves master_delimiter
        then `Master
        else if List.equal Int.equal halves slave_delimiter
        then `Slave
        else `None
      in
      (match kind with
       | `None -> frames (r + 1) (Bad (sprintf "no delimiter at %d" r) :: acc)
       | (`Master | `Slave) as kind ->
         (* Bits until a pair that is not a bit: it must be NH, then silence. *)
         let rec bits k acc =
           match h (18 + (2 * k)), h (19 + (2 * k)) with
           | 1, 0 -> bits (k + 1) (1 :: acc)
           | 0, 1 -> bits (k + 1) (0 :: acc)
           | 1, 1 -> Ok (List.rev acc, k)
           | _ -> Error "NL where the end delimiter belongs"
         in
         let result, ends =
           match bits 0 [] with
           | Error e -> Error e, r + (20 * half)
           | Ok (bits, k) ->
             let ends = r + ((20 + (2 * k)) * half) in
             let silent = List.for_all (List.range ends (ends + (4 * half))) ~f:(fun t -> t >= n || ((not line.(t)) && not enable.(t))) in
             let rec off_grid t =
               if t + 1 >= ends then None
               else if Bool.( <> ) line.(t) line.(t + 1) && (t + 1 - r) % half <> 0 then Some (t + 1)
               else off_grid (t + 1)
             in
             let enabled = List.for_all (List.range r ends) ~f:(fun t -> enable.(t)) && (r = 0 || not enable.(r - 1)) in
             let rec blocks = function
               | [] -> Ok []
               | bits ->
                 let size = min 64 (List.length bits - 8) in
                 if size <= 0 then Error "a block too short"
                 else (
                   let data = List.take bits size
                   and cs = List.sub bits ~pos:size ~len:8 in
                   if not (List.equal Int.equal cs (check_sequence data))
                   then Error "check sequence"
                   else Result.map (blocks (List.drop bits (size + 8))) ~f:(fun rest -> data @ rest))
             in
             let words data = List.chunks_of data ~length:16 |> List.map ~f:(List.fold ~init:0 ~f:(fun a b -> (a lsl 1) lor b)) in
             ( (match off_grid r with
                | Some e -> Error (sprintf "an edge %d clocks off the half bits" ((e - r) % half))
                | None ->
                  if not silent then Error "not silent after the end delimiter"
                  else if not enabled then Error "the driver enable"
                  else (
                    match kind, List.length bits with
                    | `Master, 24 -> Result.map (blocks bits) ~f:(fun d -> `M (List.hd_exn (words d)))
                    | `Slave, (24 | 40 | 72 | 144 | 288) -> Result.map (blocks bits) ~f:(fun d -> `S (words d))
                    | _, l -> Error (sprintf "%d bits" l)))
             , ends )
         in
         let f =
           match result with
           | Ok (`M w) -> Master w
           | Ok (`S ws) -> Slave ws
           | Error e -> Bad e
         in
         frames ends (f :: acc))
  in
  frames 0 []
;;

let run ?(source = Firmware.mvb) ?(clkdiv = 1) frames_ =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ Firmware.mvb_config ~clkdiv ]
  in
  let words = List.concat_map frames_ ~f:(function `M w -> Firmware.mvb_words ~master:true [ w ] | `S ws -> Firmware.mvb_words ~master:false ws) in
  let pending = Queue.of_list words in
  let bits = List.sum (module Int) frames_ ~f:(function `M _ -> 24 | `S ws -> (16 * List.length ws) + (8 * ((List.length ws + 3) / 4))) in
  let total = ((bits + (20 * List.length frames_)) * 32 * clkdiv) + 400 in
  let line = Array.create ~len:total false
  and enable = Array.create ~len:total false in
  for t = 0 to total - 1 do
    (* A host as fast as the packet buffer. *)
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:0;
    let l = Isa.lines m ~inputs:0 in
    line.(t) <- l land 1 = 1;
    enable.(t) <- l land 2 = 2
  done;
  receive ~half:(16 * clkdiv) line enable
;;

let expect frames_ = List.map frames_ ~f:(function `M w -> Master w | `S ws -> Slave ws)

(* A master asks for process data port 0x123, 4 bytes (function code 1),
   and the port's source answers with a slave frame of 32 bits. *)
let poll = [ `M 0x1123; `S [ 0xCAFE; 0x0042 ] ]

let%test_unit "program: 123 words" = [%test_result: int] (Array.length (Asm.assemble Firmware.mvb)) ~expect:123

let%expect_test "a process data request and its answer" =
  List.iter (run poll) ~f:(fun f -> print_s [%sexp (f : frame)]);
  [%expect {|
    (Master 4387)
    (Slave (51966 66))
    |}]
;;

let%test_unit "every slave frame size, at CLKDIV 1 and 2" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Quickcheck.Generator.of_list [ 1; 2; 4; 8; 16 ])
       (Quickcheck.Generator.list_with_length 17 (Int.gen_incl 0 0xFFFF))
       (Int.gen_incl 1 2))
    ~trials:30
    ~sexp_of:[%sexp_of: int * int list * int]
    ~f:(fun (n, ws, clkdiv) ->
      let frames_ = [ `M (List.hd_exn ws); `S (List.take (List.tl_exn ws) n) ] in
      [%test_result: frame list] (run ~clkdiv frames_) ~expect:(expect frames_))
;;

let%expect_test "planted bugs" =
  let good = Firmware.mvb in
  let session = [ `M 0x1123; `S [ 0xCAFE; 0x0042 ]; `S (List.init 8 ~f:(fun k -> 0x1111 * (k + 1))) ] in
  let caught source = not ([%equal: frame list] (run ~source session) (expect session)) in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first good ~pattern ~with_ in
    assert (not (String.equal s good));
    s
  in
  printf "the program as it is: %s\n" (if caught good then "WRONG" else "right");
  List.iter
    [ "the master delimiter's NL a 0", fw ~pattern:"set pins, 2 [15]        ; 5, 6: NL\n        nop [15]" ~with_:"set pins, 2 [15]        ; 5, 6: NL\n        set pins, 3 [15]"
    ; "the slave delimiter's last NH a 1", fw ~pattern:"set pins, 3 [14]        ; 17, 18: NH" ~with_:"set pins, 2 [14]        ; 17, 18: NH"
    ; "a second half a tick early", fw ~pattern:"jmp x-- n1 [14]" ~with_:"jmp x-- n1 [13]"
    ; "the check sequence over the delimiter too", fw ~pattern:"mov crc, null           ; 273" ~with_:"nop                     ; 273"
    ; "the next block's not from 0", fw ~pattern:"mov crc, null           ; 21" ~with_:"nop                     ; 21"
    ; "no bit turned over", fw ~pattern:"jmp !x odd" ~with_:"jmp !x even"
    ; "the mask one bit off", fw ~pattern:"set x, 27" ~with_:"set x, 26"
    ; "blocks of 32 bits", fw ~pattern:"in y, 2" ~with_:"in y, 1"
    ; "the check bits in the wrong order", fw ~pattern:"ct:     in null, 1" ~with_:"ct:     nop       "
    ; "an NL to end the frame", fw ~pattern:"set pins, 3 [15]        ; 32..47" ~with_:"set pins, 2 [15]        ; 32..47"
    ; "a frame of one word with two", fw ~pattern:"jmp !y fl [10]" ~with_:"jmp !x fl [10]"
    ]
    ~f:(fun (name, source) -> printf "%-42s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the master delimiter's NL a 0              caught
    the slave delimiter's last NH a 1          caught
    a second half a tick early                 caught
    the check sequence over the delimiter too  caught
    the next block's not from 0                caught
    no bit turned over                         caught
    the mask one bit off                       caught
    blocks of 32 bits                          caught
    the check bits in the wrong order          caught
    an NL to end the frame                     caught
    a frame of one word with two               caught
    |}]
;;
