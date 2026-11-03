(* Low-speed USB (1.5 Mbit/s) at the wire, written from the USB 1.1
   specification (chapter 7, electrical; chapter 8, protocol layer) with no
   reference to the firmware it judges.

   Encoding, as a host or device puts a packet on the bus:
     SYNC (0x80, so 0000 0001 LSB first), the PID byte, any payload with its
     CRC, all least significant bit first; bit stuffing (a 0 after every six
     consecutive 1s); NRZI (a 0 toggles the line, a 1 leaves it); then EOP:
     SE0 for two bit times and J for one.

   Line states at low speed: J = D- high, D+ low (idle, also the level a
   device's 1.5 kohm pull-up on D- gives); K = D+ high, D- low; SE0 = both
   low.

   The receiver [Receiver] judges a waveform sampled once per core clock:
   it finds the first K (the start of SYNC), samples each bit in its
   middle, undoes NRZI and stuffing, and requires an EOP of exactly two bit
   times of SE0 then J. [bit_cycles] is the nominal clocks per bit. *)

open! Core

type line =
  | J
  | K
  | Se0
[@@deriving sexp_of, equal, compare]

(* Token, data and handshake PIDs: the low nibble, with its complement in
   the high nibble on the wire. *)
module Pid = struct
  let out_ = 0x1
  let in_ = 0x9
  let setup = 0xD
  let data0 = 0x3
  let data1 = 0xB
  let ack = 0x2
  let nak = 0xA
  let stall = 0xE
  let byte p = p lor ((lnot p land 0xF) lsl 4)
end

let bits_of_byte b = List.init 8 ~f:(fun i -> (b lsr i) land 1 = 1)
let bits_of_bytes bytes = List.concat_map bytes ~f:bits_of_byte

(* CRC5 over a token's 11 bits (address, endpoint), x^5 + x^2 + 1, preset
   to ones, sent inverted. *)
let crc5 bits =
  let crc =
    List.fold bits ~init:0x1F ~f:(fun crc b ->
      if (crc land 1) lxor Bool.to_int b = 1 then (crc lsr 1) lxor 0x14 else crc lsr 1)
  in
  lnot crc land 0x1F
;;

(* CRC16 over a data payload, x^16 + x^15 + x^2 + 1, preset to ones, sent
   inverted, least significant byte first. *)
let crc16 bytes =
  let crc =
    List.fold (bits_of_bytes bytes) ~init:0xFFFF ~f:(fun crc b ->
      if (crc land 1) lxor Bool.to_int b = 1 then (crc lsr 1) lxor 0xA001 else crc lsr 1)
  in
  lnot crc land 0xFFFF
;;

(* The bytes of a token packet after SYNC: PID, then 7-bit address, 4-bit
   endpoint and CRC5, packed least significant bit first. *)
let token ~pid ~addr ~endp =
  let field = addr lor (endp lsl 7) in
  let crc = crc5 (List.init 11 ~f:(fun i -> (field lsr i) land 1 = 1)) in
  let v = field lor (crc lsl 11) in
  [ Pid.byte pid; v land 0xFF; v lsr 8 ]
;;

let data ~pid payload =
  let c = crc16 payload in
  (Pid.byte pid :: payload) @ [ c land 0xFF; c lsr 8 ]
;;

let handshake ~pid = [ Pid.byte pid ]

let stuff bits =
  let rec go run = function
    | [] -> []
    | b :: rest ->
      if b
      then if run = 5 then true :: false :: go 0 rest else true :: go (run + 1) rest
      else false :: go 0 rest
  in
  go 0 bits
;;

let nrzi ?(from = J) bits =
  let flip = function
    | J -> K
    | K -> J
    | Se0 -> assert false
  in
  List.folding_map bits ~init:from ~f:(fun level b ->
    let next = if b then level else flip level in
    next, next)
;;

(* The line states of a whole packet, SYNC to EOP, from its bytes after
   SYNC (PID first). *)
let packet_lines bytes =
  nrzi (stuff (bits_of_byte 0x80 @ bits_of_bytes bytes)) @ [ Se0; Se0; J ]
;;

(* --- The judge --------------------------------------------------------- *)

module Receiver = struct
  type error =
    | No_packet
    | Stuffing_violation of int (* seven 1s in a row, at this decoded bit *)
    | Bad_sync of bool list
    | Not_whole_bytes of int
    | Bad_eop of string
    | Pid_check of int
  [@@deriving sexp_of, equal, compare]

  (* [samples] is the line once per core clock. Bit k is sampled at the
     middle of its bit time, counted from the first K; that is the
     reference receiver's whole clock recovery, which is exact for a
     transmitter on the same clock. Returns the bytes after SYNC. *)
  let decode ~bit_cycles (samples : line list) =
    let a = Array.of_list samples in
    match Array.findi a ~f:(fun _ l -> equal_line l K) with
    | None -> Error No_packet
    | Some (start, _) ->
      let at k =
        let i = start + (k * bit_cycles) + (bit_cycles / 2) in
        if i < Array.length a then Some a.(i) else None
      in
      (* Collect line states up to the first SE0. *)
      let rec collect k acc =
        match at k with
        | None -> Error (Bad_eop "the waveform ends before an EOP")
        | Some Se0 -> Ok (List.rev acc, k)
        | Some l -> collect (k + 1) (l :: acc)
      in
      Result.bind (collect 0 []) ~f:(fun (levels, eop_at) ->
        (* EOP: exactly two bit times of SE0, then J. *)
        let eop_ok =
          match at eop_at, at (eop_at + 1), at (eop_at + 2) with
          | Some Se0, Some Se0, Some J -> true
          | _ -> false
        in
        if not eop_ok
        then Error (Bad_eop "SE0 is not two bit times followed by J")
        else (
          (* Undo NRZI, from idle J. *)
          let raw =
            List.folding_map levels ~init:J ~f:(fun prev l -> l, equal_line prev l)
          in
          (* Undo stuffing. *)
          let rec unstuff run i = function
            | [] -> Ok []
            | b :: rest ->
              if run = 6
              then
                if b
                then Error (Stuffing_violation i)
                else unstuff 0 (i + 1) rest
              else
                Result.map
                  (unstuff (if b then run + 1 else 0) (i + 1) rest)
                  ~f:(fun tl -> b :: tl)
          in
          Result.bind (unstuff 0 0 raw) ~f:(fun bits ->
            let sync, rest = List.split_n bits 8 in
            if not ([%equal: bool list] sync (bits_of_byte 0x80))
            then Error (Bad_sync sync)
            else if List.length rest % 8 <> 0 || List.is_empty rest
            then Error (Not_whole_bytes (List.length rest))
            else (
              let bytes =
                List.chunks_of rest ~length:8
                |> List.map ~f:(List.foldi ~init:0 ~f:(fun i acc b ->
                  acc lor (Bool.to_int b lsl i)))
              in
              let pid = List.hd_exn bytes in
              if pid lsr 4 <> lnot pid land 0xF then Error (Pid_check pid) else Ok bytes))))
  ;;
end
