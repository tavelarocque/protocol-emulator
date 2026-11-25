(* The I3C SDR controller ([Firmware.i3c]) against targets written here
   from the MIPI I3C Basic specification: the broadcast address and the
   CCCs RSTDAA, ENTDAA and SETDASA, dynamic address assignment with the
   targets arbitrating for the bus with their provisioned IDs, private
   writes with odd parity in the T bit, and private reads that the target
   ends with T = 0 or the controller ends in a T bit of 1. A monitor on the
   bus times every edge against the specification's open-drain table. The
   cocotb test runs the same firmware on the RTL and the gate netlist with
   the I3C decoder from sigrok's extra decoders reading the wires. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let popcount v = Int.popcount (v land 0xFF)

(* An I3C target. It sees the two lines once a cycle and changes what it
   drives on SDA in reply, so it answers a cycle after the edge it answers.
   It takes a bit as SCL rises and changes its own SDA after SCL falls.
   Its device is eight bytes of memory: a private write's first byte sets
   the pointer and the bytes after it are stored from there; a private
   read returns the bytes from the pointer on, with T = 1 while there is
   another one and T = 0 after the last. *)
module Target = struct
  type kind =
    | Ccc_code (* the byte after 0x7E/W *)
    | Ccc_data
    | Pointer (* a private write's first byte *)
    | Data
    | Setdasa (* the dynamic address, after SETDASA and the static address *)

  type phase =
    | Off (* not taking part until a START or repeated START *)
    | Address of int * int (* value, bits taken *)
    | Ninth of bool * phase (* the ACK slot: held low if ACKing; then *)
    | Rx of kind * int * int (* value, bits taken; the ninth is T *)
    | Tx of int * int * bool (* byte, bit being driven (8 = T), T *)
    | Ended (* sent T = 0: only a repeated START or a STOP may follow *)
    | Id of int (* ENTDAA: bit [i] of the 64 is being driven *)
    | Dynamic of int * int (* ENTDAA: the address and its parity bit *)

  type t =
    { name : string
    ; pid : int (* provisioned ID, 48 bits *)
    ; chars : int (* BCR << 8 | DCR: with the ID, the 64 bits ENTDAA reads *)
    ; static_address : int option
    ; mutable da : int option
    ; mem : int array
    ; mutable ptr : int
    ; mutable phase : phase
    ; mutable pull : bool (* SDA held low *)
    ; mutable entdaa : bool
    ; mutable ccc : int option (* the frame's CCC *)
    ; mutable scl : bool
    ; mutable sda : bool
    ; mutable sent : int (* bytes of the read under way *)
    ; mutable log : string list
    ; mutable errors : string list
    }

  let create ?static_address ~name ~pid ~bcr ~dcr () =
    { name
    ; pid
    ; chars = (bcr lsl 8) lor dcr
    ; static_address
    ; da = None
    ; mem = Array.create ~len:8 0
    ; ptr = 0
    ; phase = Off
    ; pull = false
    ; entdaa = false
    ; ccc = None
    ; scl = true
    ; sda = true
    ; sent = 0
    ; log = []
    ; errors = []
    }
  ;;

  let note t s = t.log <- s :: t.log
  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors
  let id_bit t i =
    (if i < 48 then t.pid lsr (47 - i) else t.chars lsr (63 - i)) land 1 = 1
  ;;

  (* The 64 bits as the controller's four RX words. *)
  let id_words t = [ t.pid lsr 32; (t.pid lsr 16) land 0xFFFF; t.pid land 0xFFFF; t.chars ]

  (* The address byte is in: whether to ACK it, and what follows. *)
  let addressed t a =
    let address = a lsr 1
    and read = a land 1 = 1 in
    if address = Firmware.i3c_broadcast && not read
    then true, Rx (Ccc_code, 0, 0)
    else if address = Firmware.i3c_broadcast
    then
      (* 0x7E/R: in ENTDAA, every target without an address answers *)
      if t.entdaa && Option.is_none t.da then true, Id 0 else false, Off
    else if [%equal: int option] (Some address) t.da
    then true, if read then Tx (0, 0, false) else Rx (Pointer, 0, 0)
    else if (not read)
            && [%equal: int option] t.ccc (Some 0x87)
            && [%equal: int option] (Some address) t.static_address
            && Option.is_none t.da
    then true, Rx (Setdasa, 0, 0)
    else false, Off
  ;;

  let take t kind v =
    match kind with
    | Ccc_code ->
      t.ccc <- Some v;
      note t (sprintf "CCC %02x" v);
      (match v with
       | 0x06 -> t.da <- None (* RSTDAA *)
       | 0x07 -> t.entdaa <- true
       | _ -> ());
      Ccc_data
    | Ccc_data ->
      note t (sprintf "CCC data %02x" v);
      Ccc_data
    | Pointer ->
      t.ptr <- v land 7;
      Data
    | Data ->
      t.mem.(t.ptr) <- v;
      note t (sprintf "write [%d] %02x" t.ptr v);
      t.ptr <- min 7 (t.ptr + 1);
      Data
    | Setdasa ->
      t.da <- Some (v lsr 1);
      note t (sprintf "SETDASA: dynamic address %02x" (v lsr 1));
      Ccc_data
  ;;

  (* The next byte of a read: the byte, and T = 1 if another follows. *)
  let next_byte t =
    let b = t.mem.(t.ptr) in
    let more = t.ptr < 7 in
    t.ptr <- min 7 (t.ptr + 1);
    b, more
  ;;

  let drive_tx t byte i more = t.pull <- (if i < 8 then (byte lsr (7 - i)) land 1 = 0 else not more)

  let condition t ~stop =
    let what = if stop then "STOP" else "START" in
    (match t.phase with
     | Off | Ended | Address (_, (0 | 1)) | Rx (_, _, 1) -> ()
     | Tx (_, 8, true) when not stop ->
       note t (sprintf "read of %d bytes ended by the controller" t.sent)
     | Tx _ -> error t (sprintf "%s while the target drives SDA" what)
     | Id _ | Dynamic _ -> error t (sprintf "%s inside ENTDAA" what)
     | _ -> error t (sprintf "%s inside a byte" what));
    t.pull <- false;
    if stop
    then (
      t.phase <- Off;
      t.entdaa <- false;
      t.ccc <- None)
    else t.phase <- Address (0, 0)
  ;;

  let rise t =
    let bit = Bool.to_int t.sda in
    match t.phase with
    | Address (v, n) when n < 8 -> t.phase <- Address ((v lsl 1) lor bit, n + 1)
    | Rx (kind, v, n) when n < 8 -> t.phase <- Rx (kind, (v lsl 1) lor bit, n + 1)
    | Rx (kind, v, _) ->
      (* T: odd parity over the byte and itself *)
      if (popcount v + bit) % 2 = 0
      then (
        error t (sprintf "parity error after %02x" v);
        t.phase <- Off)
      else t.phase <- Rx (take t kind v, 0, 0)
    | Tx (byte, i, more) ->
      if i < 8 && (byte lsr (7 - i)) land 1 = 1 && not t.sda
      then error t "SDA low while the target sends a 1";
      (* T = 1: let go as SCL rises, so the controller may end the read *)
      if i = 8 && more then t.pull <- false
    | Id i ->
      if id_bit t i && not t.sda
      then (
        (* another target sent a 0: it has the lower ID and wins *)
        t.pull <- false;
        t.phase <- Off)
    | Dynamic (v, n) when n < 8 -> t.phase <- Dynamic ((v lsl 1) lor bit, n + 1)
    | Off | Address _ | Ninth _ | Ended | Dynamic _ -> ()
  ;;

  let fall t =
    match t.phase with
    | Address (v, 8) ->
      let ack, next = addressed t v in
      t.pull <- ack;
      t.phase <- Ninth (ack, next)
    | Ninth (_, next) ->
      t.pull <- false;
      t.phase <- next;
      (match next with
       | Tx _ ->
         let byte, more = next_byte t in
         t.sent <- 1;
         t.phase <- Tx (byte, 0, more);
         drive_tx t byte 0 more
       | Id 0 -> t.pull <- not (id_bit t 0)
       | _ -> ())
    | Tx (byte, i, more) when i < 8 ->
      t.phase <- Tx (byte, i + 1, more);
      drive_tx t byte (i + 1) more
    | Tx (_, _, more) ->
      if not more
      then (
        t.pull <- false;
        note t (sprintf "read of %d bytes ended by the target" t.sent);
        t.phase <- Ended)
      else (
        let byte, more = next_byte t in
        t.sent <- t.sent + 1;
        t.phase <- Tx (byte, 0, more);
        drive_tx t byte 0 more)
    | Ended -> error t "a clock after the target ended the read"
    | Id 63 ->
      t.pull <- false;
      t.phase <- Dynamic (0, 0)
    | Id i ->
      t.phase <- Id (i + 1);
      t.pull <- not (id_bit t (i + 1))
    | Dynamic (v, 8) ->
      (* seven bits of address, then a parity bit making the ones odd *)
      let ok = popcount v % 2 = 1 in
      if ok
      then (
        t.da <- Some (v lsr 1);
        note t (sprintf "ENTDAA: dynamic address %02x" (v lsr 1)))
      else error t "ENTDAA: parity error in the dynamic address";
      t.pull <- ok;
      t.phase <- Ninth (ok, Off)
    | Off | Address _ | Rx _ | Dynamic _ -> ()
  ;;

  let step t ~scl ~sda =
    if Bool.( <> ) scl t.scl
    then (
      t.sda <- sda;
      if scl then rise t else fall t)
    else if scl && Bool.( <> ) sda t.sda
    then (
      t.sda <- sda;
      condition t ~stop:sda)
    else t.sda <- sda;
    t.scl <- scl
  ;;
end

(* A monitor on the two lines, timing them against the open-drain table of
   the specification ([ns] a cycle), and checking what only the bus shows:
   that the controller's SDA never moves in the cycle SCL does, and that
   after an address nobody ACKed the next thing is a repeated START or a
   STOP. *)
module Monitor = struct
  type t =
    { ns : float
    ; mutable cycle : int
    ; mutable scl : bool
    ; mutable sda : bool
    ; mutable own : bool (* the controller's SDA: released *)
    ; mutable scl_since : int (* cycle of SCL's last edge *)
    ; mutable start_at : int option (* a START or Sr not yet followed by SCL falling *)
    ; mutable from_idle : bool
    ; mutable stop_at : int
    ; mutable init : int (* clocks left of the first address after a START *)
    ; mutable clocks : int (* rising edges since the START or Sr *)
    ; mutable nacked : int (* 1: a NACK seen; 2: then SCL rose *)
    ; mutable low_min : int
    ; mutable high_min : int
    ; mutable errors : string list
    }

  let create ~ns =
    { ns
    ; cycle = 0
    ; scl = true
    ; sda = true
    ; own = true
    ; scl_since = 0
    ; start_at = None
    ; from_idle = true
    ; stop_at = -1000
    ; init = 0
    ; clocks = 0
    ; nacked = 0
    ; low_min = Int.max_value
    ; high_min = Int.max_value
    ; errors = []
    }
  ;;

  let error t s = if not (List.mem t.errors s ~equal:String.equal) then t.errors <- s :: t.errors
  let at_least t name ~cycles ns = if Float.(of_int cycles * t.ns < ns) then error t name
  let at_most t name ~cycles ns = if Float.(of_int cycles * t.ns > ns) then error t name

  let step t ~scl ~sda ~own =
    t.cycle <- t.cycle + 1;
    let scl_moved = Bool.( <> ) scl t.scl in
    if scl_moved && Bool.( <> ) own t.own
    then error t (if scl then "controller SDA moved as SCL rose" else "controller SDA moved as SCL fell");
    if scl_moved
    then (
      let held = t.cycle - t.scl_since in
      if scl
      then (
        t.low_min <- min t.low_min held;
        at_least t "SCL low under tLOW_OD (200 ns)" ~cycles:held 200.;
        t.clocks <- t.clocks + 1;
        if t.nacked = 1 then t.nacked <- 2;
        if t.clocks = 9 && sda then t.nacked <- 1)
      else (
        t.high_min <- min t.high_min held;
        at_least t "SCL high under tHIGH (24 ns)" ~cycles:held 24.;
        if t.init > 0
        then (
          at_least t "SCL high under tHIGH_INIT (200 ns)" ~cycles:held 200.;
          t.init <- t.init - 1);
        if t.nacked = 2 then error t "clocked on after a NACK";
        Option.iter t.start_at ~f:(fun s ->
          let cas = t.cycle - s in
          at_least t "tCAS under 38.4 ns" ~cycles:cas 38.4;
          if t.from_idle then at_most t "tCAS over 1 us (ENTAS0)" ~cycles:cas 1000.;
          t.start_at <- None));
      t.scl_since <- t.cycle)
    else if scl && Bool.( <> ) sda t.sda
    then (
      let since = t.cycle - t.scl_since in
      if sda
      then (
        at_least t "tCBP under 19.2 ns" ~cycles:since 19.2;
        t.stop_at <- t.cycle;
        t.from_idle <- true)
      else (
        if t.from_idle
        then (
          at_least t "bus free under tCAS (38.4 ns)" ~cycles:(t.cycle - t.stop_at) 38.4;
          t.init <- 8)
        else at_least t "tCBSr under 19.2 ns" ~cycles:since 19.2;
        t.start_at <- Some t.cycle;
        t.from_idle <- false);
      t.clocks <- 0;
      t.nacked <- 0);
    t.scl <- scl;
    t.sda <- sda;
    t.own <- own
  ;;
end

let modes =
  Array.init Isa.num_pins ~f:(function
    | 0 -> Isa.Pin_mode.Open_drain
    | 1 -> Isa.Pin_mode.Push_pull
    | _ -> Input)
;;

(* The chip, the targets and the monitor, stepped a cycle at a time; the
   host code below pushes words and pops replies, and a pop runs the bus
   until a reply comes. *)
module Sim = struct
  type t =
    { m : Isa.t
    ; targets : Target.t list
    ; monitor : Monitor.t
    ; pending : int Queue.t
    ; rx : int Queue.t
    ; mutable cycle : int
    }

  exception Hung

  let create ?(source = Firmware.i3c) ?(ns = 100.) ~clkdiv targets =
    { m =
        Isa.create
          ~program:(Asm.assemble source)
          ~pin_modes:modes
          ~threads:[ Firmware.i3c_config ~clkdiv ]
    ; targets
    ; monitor = Monitor.create ~ns
    ; pending = Queue.create ()
    ; rx = Queue.create ()
    ; cycle = 0
    }
  ;;

  let step t =
    (match Queue.peek t.pending with
     | Some v -> if Isa.push_tx t.m ~thread:0 v then ignore (Queue.dequeue_exn t.pending : int)
     | None -> ());
    let low = List.exists t.targets ~f:(fun g -> g.Target.pull) in
    let inputs = if low then 0xFE else 0xFF in
    Isa.step t.m ~inputs;
    let l = Isa.lines t.m ~inputs in
    let sda = l land 1 = 1
    and scl = (l lsr 1) land 1 = 1 in
    Monitor.step t.monitor ~scl ~sda ~own:(Isa.pin_out t.m land 1 = 1);
    List.iter t.targets ~f:(fun g -> Target.step g ~scl ~sda);
    Option.iter (Isa.pop_rx t.m ~thread:0) ~f:(Queue.enqueue t.rx);
    t.cycle <- t.cycle + 1
  ;;

  let push t w = Queue.enqueue t.pending w

  let pop t =
    let rec go n =
      match Queue.dequeue t.rx with
      | Some v -> v
      | None ->
        if n = 0 then raise Hung;
        step t;
        go (n - 1)
    in
    go 100_000
  ;;

  let settle t =
    for _ = 1 to 400 do
      step t
    done
  ;;

  let errors t =
    List.rev t.monitor.errors
    @ List.concat_map t.targets ~f:(fun g ->
      List.rev_map g.errors ~f:(fun e -> g.name ^ ": " ^ e))
  ;;
end

(* The host's side, as a driver would write it: segments, data and STOP. *)
module Host = struct
  let segment sim ~address ~read ~count =
    Sim.push sim (Firmware.i3c_segment ~address ~read ~count)
  ;;

  let stop sim = Sim.push sim Firmware.i3c_stop

  (* A broadcast CCC with no data; [`Ack] or [`Nack]. *)
  let ccc sim code =
    segment sim ~address:0x7E ~read:false ~count:0;
    Sim.push sim (Firmware.i3c_data code);
    if Sim.pop sim = 0 then `Ack else `Nack
  ;;

  let write sim ~address bytes =
    segment sim ~address ~read:false ~count:0;
    List.iter bytes ~f:(fun b -> Sim.push sim (Firmware.i3c_data b));
    if Sim.pop sim = 0 then `Ack else `Nack
  ;;

  (* Up to [n] bytes; the list ends early where the target sent T = 0. *)
  let read sim ~address n =
    segment sim ~address ~read:true ~count:n;
    if Sim.pop sim <> 0
    then None
    else (
      let rec go k acc =
        if k = n
        then List.rev acc
        else (
          let w = Sim.pop sim in
          let acc = (w lsr 1) :: acc in
          if w land 1 = 0 then List.rev acc else go (k + 1) acc)
      in
      Some (go 0 []))
  ;;

  (* SETDASA: the target at [static] gets [dynamic]. *)
  let setdasa sim ~static ~dynamic =
    ignore (ccc sim 0x87 : [ `Ack | `Nack ]);
    write sim ~address:static [ dynamic lsl 1 ]
  ;;

  (* ENTDAA, ending the frame: each target that answers gets the next of
     [addresses]. Returns (the 64 bits it sent, as four words; the
     address; its ACK). *)
  let entdaa sim addresses =
    ignore (ccc sim 0x07 : [ `Ack | `Nack ]);
    let rec round addresses acc =
      segment sim ~address:0x7E ~read:true ~count:0;
      match Sim.pop sim, addresses with
      | 0, da :: rest ->
        Sim.push sim (Firmware.i3c_address_word da);
        let id = List.rev (List.fold (List.range 0 4) ~init:[] ~f:(fun acc _ -> Sim.pop sim :: acc)) in
        let ack = Sim.pop sim = 0 in
        round rest ((id, da, ack) :: acc)
      | _ ->
        stop sim;
        List.rev acc
    in
    round addresses []
  ;;
end

let targets () =
  [ Target.create ~name:"A" ~pid:0x0123_4567_89AB ~bcr:0x06 ~dcr:0x44 ()
  ; Target.create ~name:"B" ~pid:0x0123_4567_89A0 ~bcr:0x07 ~dcr:0x45 ()
  ; Target.create ~name:"C" ~pid:0x7000_0000_0001 ~bcr:0x00 ~dcr:0x00 ()
  ; Target.create ~name:"D" ~static_address:0x50 ~pid:0x0000_0000_0001 ~bcr:0 ~dcr:0 ()
  ]
;;

(* Every CCC and transfer the tests use, on [sim]'s targets A to D:
   RSTDAA; SETDASA for D; ENTDAA for the others; a write, a write then a
   read the controller ends, a read the target ends; a read and a write to
   an address nobody has. *)
let session sim =
  let r = ref [] in
  let say fmt = ksprintf (fun s -> r := s :: !r) fmt in
  let ack = function
    | `Ack -> "ACK"
    | `Nack -> "NACK"
  in
  let bytes l = String.concat ~sep:" " (List.map l ~f:(sprintf "%02x")) in
  say "RSTDAA %s" (ack (Host.ccc sim 0x06));
  Host.stop sim;
  say "SETDASA %s" (ack (Host.setdasa sim ~static:0x50 ~dynamic:0x20));
  Host.stop sim;
  List.iter (Host.entdaa sim [ 0x08; 0x09; 0x0A; 0x0B ]) ~f:(fun (id, da, a) ->
    say
      "ENTDAA %s -> %02x %s"
      (String.concat (List.map id ~f:(sprintf "%04x")))
      da
      (if a then "ACK" else "NACK"));
  say "write 09 %s" (ack (Host.write sim ~address:0x09 [ 0x02; 0xA5; 0x5A; 0x3C ]));
  Host.stop sim;
  say "write 09 %s" (ack (Host.write sim ~address:0x09 [ 0x06; 0x77; 0x88 ]));
  Host.stop sim;
  say "write 09 %s" (ack (Host.write sim ~address:0x09 [ 0x02 ]));
  say "read 09 %s" (Option.value_map (Host.read sim ~address:0x09 2) ~default:"NACK" ~f:bytes);
  Host.stop sim;
  say "write 09 %s" (ack (Host.write sim ~address:0x09 [ 0x06 ]));
  say "read 09 %s" (Option.value_map (Host.read sim ~address:0x09 4) ~default:"NACK" ~f:bytes);
  Host.stop sim;
  say "read 30 %s" (Option.value_map (Host.read sim ~address:0x30 2) ~default:"NACK" ~f:bytes);
  Host.stop sim;
  say "write 31 %s" (ack (Host.write sim ~address:0x31 [ 0x01; 0x02 ]));
  say "read 20 %s" (Option.value_map (Host.read sim ~address:0x20 1) ~default:"NACK" ~f:bytes);
  Host.stop sim;
  Sim.settle sim;
  List.rev !r
;;

let%expect_test "addresses given by SETDASA and ENTDAA, then writes and reads" =
  let ts = targets () in
  let sim = Sim.create ~clkdiv:1 ts in
  List.iter (session sim) ~f:print_endline;
  List.iter ts ~f:(fun g ->
    printf
      "%s: %s\n   %s\n"
      g.name
      (Option.value_map g.da ~default:"no address" ~f:(sprintf "address %02x"))
      (String.concat ~sep:"; " (List.rev g.log)));
  printf !"errors %{sexp:string list}\n" (Sim.errors sim);
  let mon = sim.monitor in
  printf
    "SCL low %d, high %d cycles at least: %.1f MHz at 10 MHz with CLKDIV 1; %d cycles in all\n"
    mon.low_min
    mon.high_min
    (10. /. Float.of_int (mon.low_min + mon.high_min))
    sim.cycle;
  [%expect {|
    RSTDAA ACK
    SETDASA ACK
    ENTDAA 0123456789a00745 -> 08 ACK
    ENTDAA 0123456789ab0644 -> 09 ACK
    ENTDAA 7000000000010000 -> 0a ACK
    write 09 ACK
    write 09 ACK
    write 09 ACK
    read 09 a5 5a
    write 09 ACK
    read 09 77 88
    read 30 NACK
    write 31 NACK
    read 20 00
    A: address 09
       CCC 06; CCC 87; CCC 07; ENTDAA: dynamic address 09; write [2] a5; write [3] 5a; write [4] 3c; write [6] 77; write [7] 88; read of 2 bytes ended by the controller; read of 2 bytes ended by the target
    B: address 08
       CCC 06; CCC 87; CCC 07; ENTDAA: dynamic address 08
    C: address 0a
       CCC 06; CCC 87; CCC 07; ENTDAA: dynamic address 0a
    D: address 20
       CCC 06; CCC 87; SETDASA: dynamic address 20; CCC 07; read of 1 bytes ended by the controller
    errors ()
    SCL low 3, high 2 cycles at least: 2.0 MHz at 10 MHz with CLKDIV 1; 3583 cycles in all
    |}]
;;

let%expect_test "the tick must be 100 ns: at 50 MHz CLKDIV 5 meets the open-drain table, 4 does not" =
  List.iter [ 5; 4 ] ~f:(fun clkdiv ->
    let sim = Sim.create ~ns:20. ~clkdiv (targets ()) in
    ignore (session sim : string list);
    printf !"CLKDIV %d at 50 MHz: %{sexp:string list}\n" clkdiv (Sim.errors sim));
  [%expect {|
    CLKDIV 5 at 50 MHz: ()
    CLKDIV 4 at 50 MHz: ("SCL high under tHIGH_INIT (200 ns)")
    |}]
;;

let%test_unit "random targets, addresses, writes and reads, at every speed" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Int.gen_incl 1 6)
       (List.gen_with_length 4 (Int.gen_incl 0 ((1 lsl 48) - 1)))
       (Int.gen_incl 1 4)
       (List.gen_with_length 6 (Int.gen_incl 0 255)))
    ~trials:60
    ~sexp_of:[%sexp_of: int * int list * int * int list]
    ~f:(fun (clkdiv, pids, n, data) ->
      let pids = List.dedup_and_sort ~compare (List.take pids n) in
      let ts =
        List.mapi pids ~f:(fun i pid ->
          Target.create ~name:(Int.to_string i) ~pid ~bcr:i ~dcr:(0x10 + i) ())
      in
      let sim = Sim.create ~clkdiv ts in
      let got = Host.entdaa sim (List.init (List.length ts + 1) ~f:(fun i -> 0x10 + i)) in
      (* the lowest ID wins each round, so the addresses go in ID order *)
      [%test_result: (int list * int * bool) list]
        got
        ~expect:
          (List.map ts ~f:Target.id_words
           |> List.sort ~compare:[%compare: int list]
           |> List.mapi ~f:(fun i id -> id, 0x10 + i, true));
      let last = 0x10 + List.length ts - 1 in
      [%test_eq: [ `Ack | `Nack ]] (Host.write sim ~address:last (0 :: data)) `Ack;
      Host.stop sim;
      [%test_eq: [ `Ack | `Nack ]] (Host.write sim ~address:last [ 0 ]) `Ack;
      [%test_result: int list option]
        (Host.read sim ~address:last 8)
        ~expect:(Some (data @ [ 0; 0 ]));
      Host.stop sim;
      Sim.settle sim;
      [%test_result: string list] (Sim.errors sim) ~expect:[])
;;

let%expect_test "planted bugs" =
  let run ?(clkdiv = 1) source =
    let sim = Sim.create ~source ~clkdiv (targets ()) in
    match session sim with
    | log -> Some (log, Sim.errors sim)
    | exception Sim.Hung -> None
  in
  let right = run Firmware.i3c in
  let caught source =
    List.exists [ 1; 3 ] ~f:(fun clkdiv ->
      match run ~clkdiv source, right with
      | Some (log, []), Some (expect, []) -> not ([%equal: string list] log expect)
      | _ -> true)
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.i3c ~pattern ~with_ in
    assert (not (String.equal s Firmware.i3c));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.i3c then "WRONG" else "right");
  List.iter
    [ ( "parity: the CRC register not restarted for a byte"
      , fw ~pattern:"par:    mov crc, null       side 0" ~with_:"par:    nop                 side 0" )
    ; ( "T after a write always 1"
      , fw ~pattern:"mov pins, crc       side 0 [1]" ~with_:"set pins, 1         side 0 [1]" )
    ; ( "SDA moves as SCL falls after a START"
      , fw
          ~pattern:"set y, 7            side 0     ; SCL falls; the address"
          ~with_:"set y, 7            side 1     ; SCL falls; the address" )
    ; ( "a read the target would go on with not ended"
      , fw ~pattern:"set pins, 0         side 1 [1] ; no:" ~with_:"nop                 side 1 [1] ; no:" )
    ; ( "T = 0 not heeded"
      , fw ~pattern:"more:   wait 1 pin 0 timeout side 1" ~with_:"more:   nop                 side 1" )
    ; ( "a NACKed write's data sent anyway"
      , fw ~pattern:"set y, 0            side 0" ~with_:"nop                 side 0" )
    ; ( "ACK slot not released"
      , fw ~pattern:"ack:    set pins, 1         side 0 [1]" ~with_:"ack:    nop                 side 0 [1]" )
    ; ( "one byte more read than asked"
      , fw ~pattern:"jmp x-- rbyte       side 0     ; X" ~with_:"jmp rbyte           side 0     ; X" )
    ; ( "ENTDAA: 60 bits of ID, not 64"
      , fw ~pattern:"pword:  set y, 15" ~with_:"pword:  set y, 14" )
    ; ( "ENTDAA: the address sent as 8 bits"
      , fw ~pattern:"set y, 6            side 0     ; then" ~with_:"set y, 7            side 0     ; then" )
    ; ( "STOP: SDA rises with SCL"
      , fw ~pattern:"stop:   set pins, 0         side 0 [1] ; STOP: SDA low while SCL is low,\n        nop                 side 1 [1]"
          ~with_:"stop:   set pins, 0         side 0 [1] ; STOP: SDA low while SCL is low,\n        nop                 side 0 [1]" )
    ]
    ~f:(fun (name, source) -> printf "%-52s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    parity: the CRC register not restarted for a byte    caught
    T after a write always 1                             caught
    SDA moves as SCL falls after a START                 caught
    a read the target would go on with not ended         caught
    T = 0 not heeded                                     caught
    a NACKed write's data sent anyway                    caught
    ACK slot not released                                caught
    one byte more read than asked                        caught
    ENTDAA: 60 bits of ID, not 64                        caught
    ENTDAA: the address sent as 8 bits                   caught
    STOP: SDA rises with SCL                             caught
    |}]
;;
