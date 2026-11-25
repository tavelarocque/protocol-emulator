(* The ISO 7816-3 card reader ([Firmware.iso7816], with [Firmware.iso7816_clk]
   on the other thread making CLK) against a card written here from
   ISO/IEC 7816-3: clocked by CLK, an etu of 372 of its cycles; reset by
   RST held low for 400 cycles or more; its answer to reset 400 to 40,000
   cycles after RST rises; characters of a start bit, 8 data bits and a
   parity bit, 12 etu or more apart and 16 etu or more where the direction
   turns; the error signal 10.5 etu after a character's start, 1 to 2 etu
   long, and the character sent again 2 etu or more after it. Its own
   edges are each up to 0.19 etu off where they belong, inside the 0.2 the
   standard allows, so a reader that does not sample in the middle of a
   bit is caught. It answers SELECT and READ BINARY under T=0, sometimes
   with a NULL procedure byte first.

   The host side here is the T=0 layer the driver has: it reads the answer
   to reset as ISO 7816-3 lays it out, sends each command's header, and
   acts on the procedure bytes. The cocotb test runs the same firmware on
   the RTL and the gate netlist, judged by two ISO 7816 decoders for
   sigrok that this project did not write. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let etu = 372
let clkdiv = 1 (* thread 1's: CLK at 5 MHz on a 10 MHz core clock; thread 0 has twice it *)

(* The level on the line of each bit of a character carrying [byte]: the
   start bit, 8 data bits, the parity bit. *)
let levels ~inverse byte =
  let line = Firmware.iso7816_line ~inverse byte in
  let data = List.init 8 ~f:(fun k -> (line lsr k) land 1 = 1) in
  let highs = List.count data ~f:Fn.id in
  (* Direct: an even number of 1s, and a 1 is high. Inverse: an even
     number of 1s, and a 1 is low, so an odd number of highs. *)
  let parity = if inverse then highs % 2 = 0 else highs % 2 = 1 in
  Array.of_list ((false :: data) @ [ parity ])
;;

let parity_right ~inverse (bits : bool array) =
  let highs = Array.count bits ~f:Fn.id in
  if inverse then highs % 2 = 1 else highs % 2 = 0
;;

let byte_of ~inverse (bits : bool array) =
  let line = List.foldi (Array.to_list (Array.sub bits ~pos:0 ~len:8)) ~init:0 ~f:(fun k acc b -> acc lor (Bool.to_int b lsl k)) in
  Firmware.iso7816_line ~inverse line
;;

module Card = struct
  type sending =
    { byte : int
    ; bits : bool array (* start, 8 data, parity *)
    ; edges : int array (* where bit k begins, k = 1 to 9, and the line is let go (10): clocks after the start *)
    ; start : int
    ; wrong : bool (* sent with the parity wrong, as noise would *)
    ; mutable signal_from : int option (* the reader's error signal *)
    ; mutable signal_to : int option
    }

  type receiving =
    { r_start : int
    ; mutable taken : bool list (* newest first *)
    ; mutable asked : bool (* the card pulls I/O low: the error signal *)
    }

  type app =
    | Header of int list (* bytes so far, newest first *)
    | Data of int list * int * int list (* header; bytes to come; bytes so far, newest first *)

  type t =
    { inverse : bool
    ; rng : Random.State.t
    ; jitter : int (* clocks an edge of the card's may be off *)
    ; atr : int list
    ; memory : int array
    ; corrupt : int list (* the card's characters, counted from 0, it first sends with the parity wrong *)
    ; ask_again : int list (* the reader's characters it signals an error on, once *)
    ; mutable n : int (* CLK cycles *)
    ; mutable clk : bool
    ; mutable rst : bool
    ; mutable io : bool
    ; mutable phase_cycles : int (* core cycles CLK has held its level *)
    ; mutable high_cycles : int
    ; mutable started : bool (* CLK has run *)
    ; mutable rst_low : int (* CLK cycles RST has been low *)
    ; mutable atr_at : int option
    ; mutable drive : bool (* false: the card pulls I/O low *)
    ; queue : (int * int) Queue.t (* bytes to send, each with clocks to wait beyond the least *)
    ; mutable tx : sending option
    ; mutable rx : receiving option
    ; mutable last_card : int option (* the card's last character's start *)
    ; mutable last_reader : int option
    ; mutable last_was_reader : bool
    ; mutable again : int option (* a reader's character the card asked for again *)
    ; mutable sent : int (* characters the card has started, repetitions not counted *)
    ; mutable repeat : bool (* the next is a repetition *)
    ; mutable heard_count : int
    ; mutable app : app
    ; mutable events : string list (* newest first *)
    ; mutable errors : string list
    }

  let create ?(inverse = false) ?(jitter = 70) ?(corrupt = []) ?(ask_again = []) ~seed ~atr () =
    { inverse
    ; rng = Random.State.make [| seed |]
    ; jitter
    ; atr
    ; memory = Array.init 256 ~f:(fun a -> ((a * 29) + 7) land 0xFF)
    ; corrupt
    ; ask_again
    ; n = 0
    ; clk = false
    ; rst = false
    ; io = true
    ; phase_cycles = 0
    ; high_cycles = 0
    ; started = false
    ; rst_low = 0
    ; atr_at = None
    ; drive = true
    ; queue = Queue.create ()
    ; tx = None
    ; rx = None
    ; last_card = None
    ; last_reader = None
    ; last_was_reader = false
    ; again = None
    ; sent = 0
    ; repeat = false
    ; heard_count = 0
    ; app = Header []
    ; events = []
    ; errors = []
    }
  ;;

  let note t s = t.events <- s :: t.events
  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors
  let extra t limit = Random.State.int_incl t.rng 0 limit

  (* What the card says after a command, each byte with how much later
     than the least it may start. *)
  let say t bytes = List.iter bytes ~f:(fun b -> Queue.enqueue t.queue (b, extra t (2 * etu)))

  let command t header data =
    match header with
    | [ cla; 0xA4; p1; p2; lc ] ->
      note t (sprintf "SELECT %02x a4 %02x %02x %02x, data %s" cla p1 p2 lc
                (String.concat ~sep:" " (List.map data ~f:(sprintf "%02x"))));
      say t (if [%equal: int list] data [ 0x3F; 0x00 ] then [ 0x90; 0x00 ] else [ 0x6A; 0x82 ])
    | [ cla; 0xB0; p1; p2; le ] ->
      note t (sprintf "READ BINARY %02x b0 %02x %02x %02x" cla p1 p2 le);
      let from = ((p1 lsl 8) lor p2) land 0xFF in
      say t (List.init le ~f:(fun k -> t.memory.((from + k) land 0xFF)) @ [ 0x90; 0x00 ])
    | _ -> say t [ 0x6D; 0x00 ]
  ;;

  (* A byte from the reader, taken. *)
  let heard t byte =
    match t.app with
    | Header acc ->
      let acc = byte :: acc in
      if List.length acc < 5
      then t.app <- Header acc
      else (
        let header = List.rev acc in
        let ins, p3 = List.nth_exn header 1, List.nth_exn header 4 in
        (* A NULL procedure byte now and then: the card wants more time. *)
        if Random.State.bool t.rng then say t [ 0x60 ];
        match ins with
        | 0xA4 when p3 > 0 ->
          say t [ ins ];
          t.app <- Data (header, p3, [])
        | 0xB0 ->
          say t [ ins ];
          command t header [];
          t.app <- Header []
        | _ ->
          command t header [];
          t.app <- Header [])
    | Data (header, left, acc) ->
      if left = 1
      then (
        command t header (List.rev (byte :: acc));
        t.app <- Header [])
      else t.app <- Data (header, left - 1, byte :: acc)
  ;;

  let start_sending t byte =
    let wrong = (not t.repeat) && List.mem t.corrupt t.sent ~equal:Int.equal in
    if not t.repeat then t.sent <- t.sent + 1;
    t.repeat <- false;
    let bits = levels ~inverse:t.inverse byte in
    if wrong then bits.(9) <- not bits.(9);
    let edges =
      Array.init 11 ~f:(fun k -> if k = 0 then 0 else (k * etu) + Random.State.int_incl t.rng (-t.jitter) t.jitter)
    in
    t.tx <- Some { byte; bits; edges; start = t.n; wrong; signal_from = None; signal_to = None }
  ;;

  (* One CLK cycle of the card: [line] is I/O as the rising edge finds it. *)
  let clock t ~line =
    t.n <- t.n + 1;
    if not t.rst
    then (
      if t.rst_low = 0
      then (
        (* RST has fallen: everything stops, and I/O is let go. *)
        t.drive <- true;
        t.tx <- None;
        t.rx <- None;
        Queue.clear t.queue;
        t.app <- Header [];
        t.atr_at <- None);
      t.rst_low <- t.rst_low + 1)
    else (
      if t.rst_low > 0
      then (
        if t.rst_low < 400 then error t (sprintf "RST low for %d clock cycles, under 400" t.rst_low);
        note t "reset";
        t.rst_low <- 0;
        t.last_card <- None;
        t.last_reader <- None;
        t.again <- None;
        t.atr_at <- Some (t.n + 400 + extra t 2000);
        List.iter t.atr ~f:(fun b -> Queue.enqueue t.queue (b, extra t etu)));
      (* Sending. *)
      (match t.tx with
       | None -> ()
       | Some s ->
         let k = t.n - s.start in
         let bit = Array.count s.edges ~f:(fun e -> e <= k) - 1 in
         t.drive <- (if bit < 10 then s.bits.(bit) else true);
         (* The line, from a cycle after the card let go of it: low is the
            reader's error signal. *)
         if k > s.edges.(10) && k < 13 * etu
         then (
           if (not line) && Option.is_none s.signal_from then s.signal_from <- Some k;
           if line && Option.is_some s.signal_from && Option.is_none s.signal_to then s.signal_to <- Some k);
         if k = 13 * etu
         then (
           t.tx <- None;
           t.last_card <- Some s.start;
           t.last_was_reader <- false;
           match s.signal_from with
           | None -> if s.wrong then error t "a character with its parity wrong taken without an error signal"
           | Some from ->
             let len = Option.value s.signal_to ~default:(13 * etu) - from in
             if from * 10 < 103 * etu || from * 10 > 107 * etu
             then error t (sprintf "an error signal %.2f etu after the start" (Float.of_int from /. Float.of_int etu));
             if len < etu || len > 2 * etu
             then error t (sprintf "an error signal %.2f etu long" (Float.of_int len /. Float.of_int etu));
             if not s.wrong then error t (sprintf "an error signal on %02x, sent right" s.byte);
             note t (sprintf "error signal on %02x: sent again" s.byte);
             (* Again, 2 etu or more after the signal was seen at 11. *)
             let rest = Queue.to_list t.queue in
             Queue.clear t.queue;
             Queue.enqueue t.queue (s.byte, etu + extra t etu);
             List.iter rest ~f:(Queue.enqueue t.queue);
             t.repeat <- true));
      (* Receiving. *)
      (match t.rx with
       | None -> ()
       | Some r ->
         let k = t.n - r.r_start in
         if Bool.( <> ) line t.io && k < 10 * etu && not r.asked
         then (
           let off = k - (((k + (etu / 2)) / etu) * etu) in
           if abs off > 1
           then error t (sprintf "the reader's edge %d clock cycles off an etu boundary" off));
         if k % etu = etu / 2 && k < 10 * etu then r.taken <- line :: r.taken;
         if k = 10 * etu
         then (
           let bits = Array.of_list (List.rev r.taken) in
           let byte = byte_of ~inverse:t.inverse (Array.sub bits ~pos:1 ~len:9) in
           if bits.(0) then error t "a start bit high in its middle";
           let index = t.heard_count in
           let right = parity_right ~inverse:t.inverse (Array.sub bits ~pos:1 ~len:9) in
           if not right then error t (sprintf "the reader's parity wrong on %02x" byte);
           (match t.again with
            | Some b when b <> byte -> error t (sprintf "%02x sent again as %02x" b byte)
            | _ -> ());
           let asked = (not right) || (List.mem t.ask_again index ~equal:Int.equal && Option.is_none t.again) in
           if asked
           then (
             r.asked <- true;
             t.again <- Some byte;
             note t (sprintf "asked for %02x again" byte))
           else (
             t.again <- None;
             t.heard_count <- t.heard_count + 1;
             heard t byte));
         if r.asked && k = (10 * etu) + (etu / 2) then t.drive <- false;
         if r.asked && k = 12 * etu then t.drive <- true;
         if k = (if r.asked then 12 else 10) * etu then t.rx <- None);
      (* A start bit from the reader. *)
      if Option.is_none t.tx && Option.is_none t.rx && t.io && (not line) && t.drive
      then (
        let gap from = t.n - Option.value from ~default:(-100_000) in
        if t.last_was_reader
        then (
          let least = if Option.is_some t.again then 13 else 12 in
          if gap t.last_reader < least * etu
          then error t (sprintf "reader characters %d clock cycles apart" (gap t.last_reader)))
        else if gap t.last_card < 16 * etu
        then error t (sprintf "the reader sent %d clock cycles after the card" (gap t.last_card));
        if Option.is_none t.last_card && Option.is_none t.last_reader
        then error t "the reader sent before the answer to reset";
        t.rx <- Some { r_start = t.n; taken = []; asked = false };
        t.last_reader <- Some t.n;
        t.last_was_reader <- true);
      (* The card's next character. *)
      (match Queue.peek t.queue with
       | Some (byte, more) when Option.is_none t.tx && Option.is_none t.rx && line ->
         let due =
           match t.atr_at with
           | Some at -> at
           | None ->
             if t.last_was_reader
             then Option.value_exn t.last_reader + (16 * etu) + more
             else Option.value_exn t.last_card + (12 * etu) + more
         in
         if t.n >= due
         then (
           ignore (Queue.dequeue t.queue : (int * int) option);
           t.atr_at <- None;
           start_sending t byte;
           t.drive <- false)
       | _ -> ()));
    t.io <- line
  ;;

  (* One core cycle of the wires. *)
  let step t ~clk ~rst ~line =
    t.phase_cycles <- t.phase_cycles + 1;
    if Bool.( <> ) clk t.clk
    then (
      if t.started
      then (
        if clk
        then (
          (* A period ends: 1 to 5 MHz, high 40 to 60% of it. *)
          let period = t.phase_cycles + t.high_cycles in
          if period < 2 || period > 10 then error t (sprintf "a CLK period of %d core cycles" period);
          if t.high_cycles * 10 < period * 4 || t.high_cycles * 10 > period * 6
          then error t (sprintf "CLK high %d of %d core cycles" t.high_cycles period))
        else t.high_cycles <- t.phase_cycles);
      t.started <- true;
      t.phase_cycles <- 0;
      t.clk <- clk;
      if clk
      then (
        t.rst <- rst;
        clock t ~line))
  ;;
end

(* The T=0 layer on the host: the answer to reset as ISO 7816-3 lays it
   out, then each command, acting on the procedure bytes. *)
module Host = struct
  type apdu =
    { header : int list
    ; data : int list
    ; le : int
    }

  type state =
    | Atr of int list (* newest first *)
    | Procedure of apdu * int list (* waiting for a procedure byte; data read so far, newest first *)
    | Incoming of apdu * int list * int (* data bytes still to come *)
    | Sw2 of apdu * int list * int
    | Done

  type t =
    { inverse : bool
    ; mutable apdus : apdu list
    ; mutable state : state
    ; mutable atr : int list
    ; mutable results : (int list * int) list (* newest first: data, status word *)
    ; out : int Queue.t (* TX words *)
    }

  let create ~inverse apdus = { inverse; apdus; state = Atr []; atr = []; results = []; out = Queue.create () }
  let send t bytes = List.iter bytes ~f:(fun b -> Queue.enqueue t.out (Firmware.iso7816_line ~inverse:t.inverse b))

  (* The answer to reset is whole once its interface bytes, historical
     bytes and, if any T other than 0 is named, TCK are in. *)
  let atr_complete atr =
    match atr with
    | _ts :: t0 :: rest ->
      let rec walk y rest ~tck =
        let count = Int.popcount (y land 7) in
        let td = y land 8 <> 0 in
        if List.length rest < count + Bool.to_int td
        then None
        else (
          let rest = List.drop rest count in
          if td
          then (
            let td = List.hd_exn rest in
            walk (td lsr 4) (List.tl_exn rest) ~tck:(tck || td land 15 <> 0))
          else Some (rest, tck))
      in
      (match walk (t0 lsr 4) rest ~tck:false with
       | None -> false
       | Some (rest, tck) -> List.length rest >= (t0 land 15) + Bool.to_int tck)
    | _ -> false
  ;;

  let next t =
    match t.apdus with
    | [] -> t.state <- Done
    | a :: more ->
      t.apdus <- more;
      send t a.header;
      t.state <- Procedure (a, [])
  ;;

  let received t word =
    let b = Firmware.iso7816_line ~inverse:t.inverse (word land 0xFF) in
    match t.state with
    | Atr acc ->
      let acc = b :: acc in
      if atr_complete (List.rev acc)
      then (
        t.atr <- List.rev acc;
        next t)
      else t.state <- Atr acc
    | Procedure (a, got) ->
      if b = 0x60
      then () (* NULL: the card wants more time *)
      else if b = List.nth_exn a.header 1
      then
        if a.le > 0
        then t.state <- Incoming (a, got, a.le)
        else send t a.data
      else t.state <- Sw2 (a, got, b)
    | Incoming (a, got, left) ->
      t.state <- (if left = 1 then Procedure ({ a with le = 0 }, b :: got) else Incoming (a, b :: got, left - 1))
    | Sw2 (_, got, sw1) ->
      t.results <- (List.rev got, (sw1 lsl 8) lor b) :: t.results;
      next t
    | Done -> ()
  ;;
end

let modes =
  Array.init Isa.num_pins ~f:(fun i ->
    if i < 2 then Isa.Pin_mode.Push_pull else if i = 2 then Isa.Pin_mode.Open_drain else Input)
;;

let etu_cycles = 2 * clkdiv * etu

(* A session: the reader started (a cold reset), the answer to reset, then
   [apdus]; with [warm], a second reset (thread 0 stopped and started) and
   those commands after it. The host acts [latency] cycles after it has
   something to send. *)
let run
  ?(source = Firmware.iso7816)
  ?(clk_source = Firmware.iso7816_clk)
  ?(inverse = false)
  ?(latency = 0)
  ?warm
  ~(card : Card.t)
  apdus
  =
  let m =
    Isa.create_separate
      ~programs:[| Asm.assemble source; Asm.assemble clk_source |]
      ~pin_modes:modes
      ~threads:
        [ Firmware.iso7816_config ~clkdiv:(2 * clkdiv) ~inverse; Firmware.iso7816_clk_config ~clkdiv ]
  in
  let host = ref (Host.create ~inverse apdus) in
  let hosts = ref [] in
  let warm = ref warm in
  let inputs = ref 0xFF in
  let wait = ref 0 in
  let quiet = ref 0 in
  let cycle = ref 0 in
  let stopped = ref false in
  while !cycle < 2000 * etu_cycles && !quiet < 30 * etu_cycles do
    incr cycle;
    let h = !host in
    if Queue.is_empty h.out
    then wait := latency
    else if !wait > 0
    then decr wait
    else (
      match Queue.peek h.out with
      | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue h.out : int option)
      | None -> ());
    Isa.step m ~inputs:!inputs;
    if !stopped
    then (
      Isa.set_enabled m ~thread:0 true;
      stopped := false);
    let l = Isa.lines m ~inputs:!inputs in
    Card.step card ~clk:(l land 1 = 1) ~rst:((l lsr 1) land 1 = 1) ~line:((l lsr 2) land 1 = 1);
    inputs := 0xFB lor (Bool.to_int card.drive lsl 2);
    Option.iter (Isa.pop_rx m ~thread:0) ~f:(Host.received h);
    match h.state with
    | Done ->
      incr quiet;
      (match !warm with
       | Some more when !quiet = 10 * etu_cycles ->
         (* A warm reset: thread 0 stopped and started again, CLK running on. *)
         Isa.set_enabled m ~thread:0 false;
         stopped := true;
         hosts := h :: !hosts;
         host := Host.create ~inverse more;
         warm := None;
         quiet := 0
       | _ -> ())
    | _ -> quiet := 0
  done;
  card, List.rev (!host :: !hosts)
;;

let select = { Host.header = [ 0x00; 0xA4; 0x00; 0x00; 0x02 ]; data = [ 0x3F; 0x00 ]; le = 0 }
let read_binary ~offset le = { Host.header = [ 0x00; 0xB0; offset lsr 8; offset land 0xFF; le ]; data = []; le }
let atr = [ 0x3B; 0x92; 0x11; 0x00; 0x31; 0xC0 ]
let hex l = String.concat ~sep:" " (List.map l ~f:(sprintf "%02x"))

let show ((card : Card.t), (hosts : Host.t list)) =
  List.iter hosts ~f:(fun (h : Host.t) ->
    printf "host: answer to reset %s\n" (hex h.atr);
    List.iter (List.rev h.results) ~f:(fun (data, sw) -> printf "  data [%s] status %04x\n" (hex data) sw));
  printf "card:\n";
  List.iter (List.rev card.events) ~f:(printf "  %s\n");
  printf !"errors: %{sexp:string list}\n" (List.rev card.errors)
;;

let%expect_test "the program's size and where its timeout vector points" =
  let program = Asm.assemble Firmware.iso7816 in
  printf "%d instructions, poll at %d (iso7816_poll %d); the clock %d\n" (Array.length program)
    (Asm.label Firmware.iso7816 "poll") Firmware.iso7816_poll (Array.length (Asm.assemble Firmware.iso7816_clk));
  [%expect {| 62 instructions, poll at 7 (iso7816_poll 7); the clock 2 |}]
;;

let%expect_test "a reset, its answer, SELECT and READ BINARY, the card's edges 0.19 etu off at most" =
  show (run ~card:(Card.create ~seed:1 ~atr ()) [ select; read_binary ~offset:0x10 8 ]);
  [%expect {|
    host: answer to reset 3b 92 11 00 31 c0
      data [] status 9000
      data [d7 f4 11 2e 4b 68 85 a2] status 9000
    card:
      reset
      SELECT 00 a4 00 00 02, data 3f 00
      READ BINARY 00 b0 00 10 08
    errors: ()
    |}]
;;

let%expect_test "an error signal each way, twice, with the host slow; then a warm reset" =
  let card = Card.create ~seed:2 ~atr ~corrupt:[ 3; 9 ] ~ask_again:[ 2; 6 ] () in
  show (run ~latency:3000 ~card ~warm:[ read_binary ~offset:0xF0 4 ] [ select; read_binary ~offset:0x10 8 ]);
  [%expect {|
    host: answer to reset 3b 92 11 00 31 c0
      data [] status 9000
      data [d7 f4 11 2e 4b 68 85 a2] status 9000
    host: answer to reset 3b 92 11 00 31 c0
      data [37 54 71 8e] status 9000
    card:
      reset
      error signal on 00: sent again
      asked for 00 again
      asked for 00 again
      SELECT 00 a4 00 00 02, data 3f 00
      READ BINARY 00 b0 00 10 08
      error signal on 60: sent again
      reset
      READ BINARY 00 b0 00 f0 04
    errors: ()
    |}]
;;

let%expect_test "the inverse convention: TS 3F, each byte turned round and inverted, odd parity on the line" =
  let card = Card.create ~seed:3 ~inverse:true ~atr:[ 0x3F; 0x92; 0x11; 0x00; 0x31; 0xC0 ] ~corrupt:[ 7 ] () in
  show (run ~inverse:true ~card [ select; read_binary ~offset:0x20 3 ]);
  [%expect {|
    host: answer to reset 3f 92 11 00 31 c0
      data [] status 9000
      data [a7 c4 e1] status 9000
    card:
      reset
      error signal on a4: sent again
      SELECT 00 a4 00 00 02, data 3f 00
      READ BINARY 00 b0 00 20 03
    errors: ()
    |}]
;;

(* What the host must get: the answer to reset, then for each command its
   data and status word. *)
let expected (card : Card.t) (apdus : Host.apdu list) =
  ( card.atr
  , List.map apdus ~f:(fun (a : Host.apdu) ->
      match a.header with
      | [ _; 0xA4; _; _; _ ] -> [], if [%equal: int list] a.data [ 0x3F; 0x00 ] then 0x9000 else 0x6A82
      | [ _; 0xB0; p1; p2; le ] -> List.init le ~f:(fun k -> card.memory.(((p1 lsl 8) lor p2 + k) land 0xFF)), 0x9000
      | _ -> [], 0x6D00) )
;;

let right ?warm (card, hosts) apdus =
  let sessions = (apdus :: Option.to_list warm) in
  List.is_empty card.Card.errors
  && List.length hosts = List.length sessions
  && List.for_all2_exn hosts sessions ~f:(fun (h : Host.t) apdus ->
    let atr, results = expected card apdus in
    Poly.(h.state = Done) && [%equal: int list] h.atr atr && [%equal: (int list * int) list] (List.rev h.results) results)
;;

let%expect_test "random sessions: commands, error signals each way, the host's pace, both conventions" =
  let rng = Random.State.make [| 7 |] in
  let runs = 24 in
  let good = ref 0 in
  for seed = 1 to runs do
    let inverse = Random.State.bool rng in
    let apdu () =
      match Random.State.int rng 3 with
      | 0 -> select
      | 1 -> { select with data = [ Random.State.int rng 256; Random.State.int rng 256 ] }
      | _ -> read_binary ~offset:(Random.State.int rng 256) (1 + Random.State.int rng 12)
    in
    let apdus = List.init (1 + Random.State.int rng 3) ~f:(fun _ -> apdu ()) in
    let some () = List.init (Random.State.int rng 3) ~f:(fun _ -> Random.State.int rng 24) in
    let atr = [ (if inverse then 0x3F else 0x3B); 0x92; 0x11; 0x00; 0x31; 0xC0 ] in
    let card = Card.create ~seed ~inverse ~atr ~corrupt:(some ()) ~ask_again:(some ()) () in
    let result = run ~inverse ~latency:(Random.State.int rng 6000) ~card apdus in
    if right result apdus then incr good else show result
  done;
  printf "%d of %d sessions right\n" !good runs;
  [%expect {| 24 of 24 sessions right |}]
;;

let%expect_test "planted bugs" =
  let apdus = [ select; read_binary ~offset:0x10 8 ] in
  let caught ?(source = Firmware.iso7816) ?(clk_source = Firmware.iso7816_clk) () =
    let card = Card.create ~seed:2 ~atr ~corrupt:[ 3; 9 ] ~ask_again:[ 2; 6 ] () in
    not (right (run ~source ~clk_source ~latency:3000 ~card apdus) apdus)
  in
  let fw ?(source = Firmware.iso7816) ~pattern ~with_ () =
    let s = String.substr_replace_first source ~pattern ~with_ in
    assert (not (String.equal s source));
    s
  in
  printf "the program as it is: %s\n" (if caught () then "WRONG" else "right");
  List.iter
    [ "a data bit a tick short", fw ~pattern:"sbit:   mov pins, isr     [8]" ~with_:"sbit:   mov pins, isr     [7]" ()
    ; "the parity bit always high", fw ~pattern:"mov pins, crc     [10]" ~with_:"set pins, 3       [10]" ()
    ; "no guard time: 11.1 etu apart", fw ~pattern:"go:     set y, 29" ~with_:"go:     set y, 0 " ()
    ; "no wait where the direction turns", fw ~pattern:"set x, 5                ;   six" ~with_:"set x, 0                ;   six" ()
    ; ( "no error signal on a wrong parity"
      , fw ~pattern:"set pins, 1       [15]  ;   I/O low" ~with_:"set pins, 3       [15]  ;   I/O low" () )
    ; "the error signal at 11 etu", fw ~pattern:"set y, 20         [15]" ~with_:"set y, 31         [15]" ()
    ; "the card's error signal ignored", fw ~pattern:"wait 0 pin 2 timeout    ; T + 4092" ~with_:"jmp poll                ; T + 4092" ()
    ; ( "the card's bits sampled near their start"
      , fw ~pattern:"set y, 31         [13]\nrs:" ~with_:"set y, 20         [13]\nrs:" () )
    ; "the parity not checked", fw ~pattern:"jmp !x good" ~with_:"jmp good   " ()
    ; "RST low 390 clock cycles", fw ~pattern:"rst1:   set y, 31         [15]" ~with_:"rst1:   set y, 4          [15]" ()
    ; ( "the parity of the card's character from the last one"
      , fw ~pattern:"mov crc, null     [15]\n        set y, 31" ~with_:"nop               [15]\n        set y, 31" () )
    ; ( "a repetition 2 etu early, at 12"
      , fw
          ~pattern:"set y, 31         [15]  ; it is: wait for it to end,\nw:      jmp y-- w         [15]\n        wait 1 pin 2"
          ~with_:"set y, 0          [15]  ; it is: wait for it to end,\nw:      jmp y-- w         [15]\n        nop" () )
    ]
    ~f:(fun (name, source) -> printf "%-55s %s\n" name (if caught ~source () then "caught" else "MISSED"));
  let clock =
    fw ~source:Firmware.iso7816_clk ~pattern:"nop                 side 1" ~with_:"nop                 side 1 [1]" ()
  in
  printf "%-55s %s\n" "CLK high two ticks of three" (if caught ~clk_source:clock () then "caught" else "MISSED");
  [%expect {|
    the program as it is: right
    a data bit a tick short                                 caught
    the parity bit always high                              caught
    no guard time: 11.1 etu apart                           caught
    no wait where the direction turns                       caught
    no error signal on a wrong parity                       caught
    the error signal at 11 etu                              caught
    the card's error signal ignored                         caught
    the card's bits sampled near their start                caught
    the parity not checked                                  caught
    RST low 390 clock cycles                                caught
    the parity of the card's character from the last one    caught
    a repetition 2 etu early, at 12                         caught
    CLK high two ticks of three                             caught
    |}]
;;
