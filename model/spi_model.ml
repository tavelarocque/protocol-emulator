(* SPI reference models (mode 0: SCK idles low, data sampled on the rising
   edge, changed on the falling edge; MSB first), written from the protocol
   definition with no reference to the firmware or hardware they judge.

   [Slave] is a simulated SPI device. While selected it shifts MOSI in on
   rising edges and shifts its scripted response out on MISO, presenting
   each bit before the rising edge that samples it.

   [Checker] is a passive monitor of the four wires. It decodes the bytes
   exchanged in each transfer and enforces mode-0 rules: MOSI never changes
   while SCK is high, chip select only changes while SCK is low, and a
   transfer ends on a byte boundary. *)

open! Core

module Slave = struct
  type t =
    { responses : int Queue.t
    ; received : int Queue.t
    ; mutable selected : bool
    ; mutable shift : int
    ; mutable bits : int
    ; mutable out_byte : int
    ; mutable miso : bool
    ; mutable prev_sck : bool
    ; mutable fresh : bool (* [out_byte] loaded but none of its bits sent yet *)
    }

  let create ~responses =
    { responses = Queue.of_list responses
    ; received = Queue.create ()
    ; selected = false
    ; shift = 0
    ; bits = 0
    ; out_byte = 0xFF
    ; miso = true
    ; prev_sck = false
    ; fresh = false
    }
  ;;

  let load_next t =
    t.out_byte <- Option.value (Queue.dequeue t.responses) ~default:0xFF;
    t.fresh <- true;
    t.miso <- (t.out_byte lsr 7) land 1 = 1
  ;;

  (* The level the slave drives on MISO this cycle. *)
  let miso t = t.miso

  let step t ~sck ~mosi ~cs_n =
    let rise = (not t.prev_sck) && sck
    and fall = t.prev_sck && not sck in
    if cs_n
    then (
      t.selected <- false;
      t.miso <- true)
    else if not t.selected
    then (
      (* Selected: the first bit must be on MISO before the first edge. *)
      (* A response preloaded at the end of the previous transfer but never
         clocked out is still the next one to send. *)
      t.selected <- true;
      t.shift <- 0;
      t.bits <- 0;
      if t.fresh then t.miso <- (t.out_byte lsr 7) land 1 = 1 else load_next t)
    else if rise
    then (
      t.shift <- ((t.shift lsl 1) lor Bool.to_int mosi) land 0xFF;
      t.bits <- t.bits + 1;
      t.fresh <- false)
    else if fall
    then
      if t.bits = 8
      then (
        Queue.enqueue t.received t.shift;
        t.shift <- 0;
        t.bits <- 0;
        load_next t)
      else t.miso <- (t.out_byte lsr (7 - t.bits)) land 1 = 1;
    t.prev_sck <- sck
  ;;

  let received t = Queue.to_list t.received
end

module Event = struct
  type t =
    | Select
    | Byte of
        { mosi : int
        ; miso : int
        }
    | Deselect
  [@@deriving sexp_of, compare, equal]
end

module Checker = struct
  type t =
    { mutable prev_sck : bool
    ; mutable prev_mosi : bool
    ; mutable prev_cs_n : bool
    ; mutable mosi_bits : int list
    ; mutable miso_bits : int list
    ; events : Event.t Queue.t
    ; errors : string Queue.t
    ; mutable cycle : int
    }

  let create () =
    { prev_sck = false
    ; prev_mosi = false
    ; prev_cs_n = true
    ; mosi_bits = []
    ; miso_bits = []
    ; events = Queue.create ()
    ; errors = Queue.create ()
    ; cycle = 0
    }
  ;;

  let error t msg = Queue.enqueue t.errors (sprintf "cycle %d: %s" t.cycle msg)
  let to_int bits = List.fold bits ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b)

  let step t ~sck ~mosi ~miso ~cs_n =
    let selected = not cs_n in
    if not (Bool.equal cs_n t.prev_cs_n)
    then (
      if sck || t.prev_sck then error t "chip select changed while SCK high";
      if cs_n
      then (
        if not (List.is_empty t.mosi_bits)
        then error t (sprintf "deselected after %d bits of a byte" (List.length t.mosi_bits));
        Queue.enqueue t.events Deselect)
      else Queue.enqueue t.events Select;
      t.mosi_bits <- [];
      t.miso_bits <- [])
    else if selected
    then (
      if t.prev_sck && sck && not (Bool.equal mosi t.prev_mosi)
      then error t "MOSI changed while SCK high";
      if (not t.prev_sck) && sck
      then (
        t.mosi_bits <- t.mosi_bits @ [ Bool.to_int mosi ];
        t.miso_bits <- t.miso_bits @ [ Bool.to_int miso ];
        if List.length t.mosi_bits = 8
        then (
          Queue.enqueue
            t.events
            (Byte { mosi = to_int t.mosi_bits; miso = to_int t.miso_bits });
          t.mosi_bits <- [];
          t.miso_bits <- [])));
    t.prev_sck <- sck;
    t.prev_mosi <- mosi;
    t.prev_cs_n <- cs_n;
    t.cycle <- t.cycle + 1
  ;;

  let events t = Queue.to_list t.events
  let errors t = Queue.to_list t.errors
end
