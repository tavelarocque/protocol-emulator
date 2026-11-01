(* Assembler for the protocol-emulator ISA.

   Syntax, one instruction per line:

     label:  op operands [delay]   ; comment

   Operands are separated by spaces or commas. A jump target is a label or a
   number. [delay] is 0..15 extra idle cycles after the instruction.

     nop
     jmp [cond] target      cond: !x x-- !y y-- x!=y !osre !isrf
     wait 0|1 pin N [timeout]
     in   pins|x|y|null, N  (N = 1..16)
     out  pins|x|y|null, N
     push
     pull
     mov  x|y|pins|isr|osr|null, x|y|pins|isr|osr|null
     set  pins|x|y, N       (N = 0..31)

   [Isa.Instruction.to_string] produces this same syntax, and the test suite
   checks that disassembling then reassembling any 16-bit word round-trips.

   Both threads run from one shared program memory, so a program can be
   assembled to run from any [origin]: labels then resolve to absolute
   addresses from there. [link] places several programs in one image. *)

open! Core
open Isa

let error ~line msg = raise_s [%message "assembly error" (line : int) (msg : string)]

let strip_comment s =
  match String.index s ';' with
  | Some i -> String.prefix s i
  | None -> s
;;

let tokens s =
  String.split_on_chars s ~on:[ ' '; '\t'; ',' ] |> List.filter ~f:(Fn.non String.is_empty)
;;

let is_label s =
  (not (String.is_empty s))
  && String.for_all s ~f:(fun c -> Char.is_alphanum c || Char.equal c '_')
  && not (Char.is_digit s.[0])
;;

let parse_cond ~line = function
  | "!x" -> Cond.X_zero
  | "x--" -> X_dec
  | "!y" -> Y_zero
  | "y--" -> Y_dec
  | "x!=y" -> X_ne_y
  | "!osre" -> Osr_not_empty
  | "!isrf" -> Isr_not_full
  | c -> error ~line (sprintf "unknown jump condition %S" c)
;;

let parse_in_src ~line = function
  | "pins" -> In_src.Pins
  | "x" -> X
  | "y" -> Y
  | "null" -> Zeros
  | s -> error ~line (sprintf "bad IN source %S" s)
;;

let parse_out_dst ~line = function
  | "pins" -> Out_dst.Pins
  | "x" -> X
  | "y" -> Y
  | "null" -> Null
  | s -> error ~line (sprintf "bad OUT destination %S" s)
;;

let parse_set_dst ~line = function
  | "pins" -> Set_dst.Pins
  | "x" -> X
  | "y" -> Y
  | s -> error ~line (sprintf "bad SET destination %S" s)
;;

let parse_mov_loc ~line = function
  | "x" -> Mov_loc.X
  | "y" -> Y
  | "pins" -> Pins
  | "isr" -> Isr
  | "osr" -> Osr
  | "null" -> Null
  | s -> error ~line (sprintf "bad MOV operand %S" s)
;;

let assemble ?(origin = 0) (source : string) : Instruction.t array =
  (* Pass 1: strip comments, peel off labels, assign addresses. *)
  let labels = Hashtbl.create (module String) in
  let body = Queue.create () in
  (* [.side_set N]: from here on, the top N bits of every instruction's
     delay field are side-set values, given as [side V]. Must match the
     thread's SIDESET count register. *)
  let side_set = ref 0 in
  List.iteri (String.split_lines source) ~f:(fun i raw ->
    let line = i + 1 in
    let text = String.strip (strip_comment raw) in
    let text =
      match tokens text with
      | [ ".side_set"; n ] ->
        (match Int.of_string_opt n with
         | Some n when n >= 0 && n <= 3 ->
           if Queue.length body > 0
           then error ~line ".side_set must come before the first instruction";
           side_set := n
         | _ -> error ~line ".side_set takes 0 to 3");
        ""
      | _ -> text
    in
    let text =
      match String.lsplit2 text ~on:':' with
      | Some (lbl, rest) when is_label (String.strip lbl) ->
        let lbl = String.strip lbl in
        if Hashtbl.mem labels lbl then error ~line (sprintf "duplicate label %S" lbl);
        (* A label names the address of the next instruction. *)
        Hashtbl.set labels ~key:lbl ~data:(origin + Queue.length body);
        String.strip rest
      | _ -> text
    in
    if not (String.is_empty text) then Queue.enqueue body (line, text));
  let body = Queue.to_list body in
  if origin < 0 || origin + List.length body > program_size
  then
    raise_s
      [%message
        "program does not fit"
          (origin : int)
          ~instructions:(List.length body : int)
          (program_size : int)];
  (* Pass 2: parse each instruction. *)
  List.map body ~f:(fun (line, text) ->
    let num tok =
      match Int.of_string_opt tok with
      | Some v -> v
      | None -> error ~line (sprintf "expected a number, got %S" tok)
    in
    let target tok =
      match Hashtbl.find labels tok with
      | Some a -> a
      | None -> num tok
    in
    let polarity = function
      | "0" -> false
      | "1" -> true
      | p -> error ~line (sprintf "wait polarity must be 0 or 1, got %S" p)
    in
    let toks = tokens (String.lowercase text) in
    let toks, delay =
      match List.rev toks with
      | last :: rest when String.is_prefix last ~prefix:"[" && String.is_suffix last ~suffix:"]"
        ->
        List.rev rest, num (String.sub last ~pos:1 ~len:(String.length last - 2))
      | _ -> toks, 0
    in
    let n = !side_set in
    let toks, delay =
      match List.rev toks with
      | v :: "side" :: rest ->
        if n = 0 then error ~line "side without .side_set";
        let v = num v in
        if v < 0 || v >= 1 lsl n
        then error ~line (sprintf "side value %d does not fit in %d bits" v n);
        if delay >= 1 lsl (4 - n)
        then error ~line (sprintf "delay %d does not fit in %d bits after side-set" delay (4 - n));
        List.rev rest, (v lsl (4 - n)) lor delay
      | _ ->
        if n > 0 then error ~line "every instruction needs [side V] after .side_set";
        toks, delay
    in
    let op : Instruction.op =
      match toks with
      | [ "nop" ] -> Nop
      | [ "jmp"; t ] -> Jmp { cond = Always; addr = target t }
      | [ "jmp"; c; t ] -> Jmp { cond = parse_cond ~line c; addr = target t }
      | [ "wait"; p; "pin"; n ] -> Wait { polarity = polarity p; pin = num n; timeout = false }
      | [ "wait"; p; "pin"; n; "timeout" ] ->
        Wait { polarity = polarity p; pin = num n; timeout = true }
      | [ "in"; s; n ] -> In { src = parse_in_src ~line s; count = num n }
      | [ "out"; d; n ] -> Out { dst = parse_out_dst ~line d; count = num n }
      | [ "push" ] -> Push
      | [ "pull" ] -> Pull
      | [ "mov"; d; s ] -> Mov { dst = parse_mov_loc ~line d; src = parse_mov_loc ~line s }
      | [ "set"; d; v ] -> Set { dst = parse_set_dst ~line d; value = num v }
      | _ -> error ~line (sprintf "cannot parse %S" text)
    in
    let instr = { Instruction.op; delay } in
    (* Encoding range-checks every field. *)
    (try ignore (Instruction.encode instr : int) with
     | exn -> error ~line (Exn.to_string exn));
    instr)
  |> Array.of_list
;;

(* One memory image from programs assembled at their origins. Words no
   program uses are 0, which decodes as "jmp 0". Overlaps are an error. *)
let link (parts : (int * Instruction.t array) list) : Instruction.t array =
  let image = Array.create ~len:program_size None in
  List.iter parts ~f:(fun (origin, program) ->
    Array.iteri program ~f:(fun k instr ->
      let a = origin + k in
      if a >= program_size
      then raise_s [%message "program does not fit" (origin : int) (a : int)];
      if Option.is_some image.(a)
      then raise_s [%message "programs overlap" (a : int)];
      image.(a) <- Some instr));
  (* Trim after the last used word, so loading the image writes no more
     than it needs to. *)
  let length = ref 0 in
  Array.iteri image ~f:(fun a w -> if Option.is_some w then length := a + 1);
  Array.init !length ~f:(fun a -> Option.value image.(a) ~default:(Instruction.decode 0))
;;
