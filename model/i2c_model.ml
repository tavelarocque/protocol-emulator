(* I2C reference models, written from the I2C specification with no
   reference to the firmware or hardware they will judge.

   The bus is two open-drain lines with pull-ups: a line is low if any
   device pulls it low. Everything here runs one step per core clock cycle.

   [Target] is a simulated I2C device: it watches for START, clocks in
   bytes on SCL rising edges, ACKs its own address and every data byte
   after it, and can stretch the clock (hold SCL low) after each byte.

   [Checker] is a passive bus monitor. It decodes START, STOP, bytes and
   ACK/NACK from the two lines alone, and flags protocol violations. It
   trusts nothing the target says: the target's ACK only counts if the
   checker sees SDA low on the ninth clock. *)

open! Core

(* --- Passive bus checker ------------------------------------------------ *)

module Event = struct
  type t =
    | Start
    | Stop
    | Byte of
        { value : int
        ; ack : bool
        }
  [@@deriving sexp_of, compare, equal]
end

module Checker = struct
  type t =
    { mutable prev_sda : bool
    ; mutable prev_scl : bool
    ; mutable in_transfer : bool
    ; mutable bits : bool list (* bits of the current byte so far, MSB first *)
    ; events : Event.t Queue.t
    ; errors : string Queue.t
    ; mutable cycle : int
    }

  let create () =
    { prev_sda = true
    ; prev_scl = true
    ; in_transfer = false
    ; bits = []
    ; events = Queue.create ()
    ; errors = Queue.create ()
    ; cycle = 0
    }
  ;;

  let error t msg = Queue.enqueue t.errors (sprintf "cycle %d: %s" t.cycle msg)

  let step t ~sda ~scl =
    (* SDA changing while SCL stays high is START or STOP. *)
    if t.prev_scl && scl && not (Bool.equal sda t.prev_sda)
    then (
      (* A STOP or repeated START is preceded by one SCL rising edge (the
         controller raises the clock before moving SDA), which looks like the
         first bit of a new byte. Two to eight bits means it cut a byte. *)
      let partial = List.length t.bits in
      if partial >= 2 && partial <= 8
      then error t (sprintf "START/STOP after %d bits of a byte" partial);
      if not sda
      then (
        Queue.enqueue t.events Start;
        t.in_transfer <- true)
      else (
        if not t.in_transfer then error t "STOP without START";
        Queue.enqueue t.events Stop;
        t.in_transfer <- false);
      t.bits <- [])
    else if (not t.prev_scl) && scl && t.in_transfer
    then (
      (* SCL rising edge: sample a bit. The ninth is the ACK. *)
      t.bits <- t.bits @ [ sda ];
      if List.length t.bits = 9
      then (
        let value =
          List.foldi (List.take t.bits 8) ~init:0 ~f:(fun i acc b ->
            if b then acc lor (1 lsl (7 - i)) else acc)
        in
        Queue.enqueue t.events (Byte { value; ack = not (List.nth_exn t.bits 8) });
        t.bits <- []));
    t.prev_sda <- sda;
    t.prev_scl <- scl;
    t.cycle <- t.cycle + 1
  ;;

  let events t = Queue.to_list t.events
  let errors t = Queue.to_list t.errors
end

(* --- Simulated target device ------------------------------------------- *)

module Target = struct
  type phase =
    | Idle
    | Receiving of int (* bits received so far in this byte *)
    | Acking (* holding SDA low through the ninth clock *)
    | Ignoring (* address did not match: wait for STOP *)

  type t =
    { address : int (* 7-bit *)
    ; stretch : int (* cycles to hold SCL low after each byte's ACK *)
    ; mutable phase : phase
    ; mutable shift : int
    ; mutable first_byte : bool
    ; mutable stretch_left : int
    ; mutable prev_sda : bool
    ; mutable prev_scl : bool
    ; received : int Queue.t (* data bytes written to this device *)
    }

  let create ~address ~stretch =
    { address
    ; stretch
    ; phase = Idle
    ; shift = 0
    ; first_byte = true
    ; stretch_left = 0
    ; prev_sda = true
    ; prev_scl = true
    ; received = Queue.create ()
    }
  ;;

  (* What the target drives this cycle, decided from its state at the start
     of the cycle: (pull SDA low, pull SCL low). *)
  let drive t = (match t.phase with Acking -> true | _ -> false), t.stretch_left > 0

  (* Observe the resolved bus levels for this cycle and update state. *)
  let step t ~sda ~scl =
    if t.stretch_left > 0 then t.stretch_left <- t.stretch_left - 1;
    let rise = (not t.prev_scl) && scl in
    let fall = t.prev_scl && not scl in
    (if t.prev_scl && scl && not (Bool.equal sda t.prev_sda)
     then (
       (* START (SDA falls) or STOP (SDA rises) while SCL is high. *)
       if not sda
       then (
         t.phase <- Receiving 0;
         t.shift <- 0;
         t.first_byte <- true)
       else t.phase <- Idle)
     else
       match t.phase with
       | Receiving n when rise ->
         t.shift <- ((t.shift lsl 1) lor Bool.to_int sda) land 0xFF;
         t.phase <- Receiving (n + 1)
       | Receiving 8 when fall ->
         (* End of the eighth bit: decide whether to ACK. *)
         if t.first_byte
         then (
           let addr = t.shift lsr 1 and read = t.shift land 1 = 1 in
           if addr = t.address && not read then t.phase <- Acking else t.phase <- Ignoring)
         else (
           Queue.enqueue t.received t.shift;
           t.phase <- Acking)
       | Acking when fall ->
         (* End of the ACK clock: release SDA, maybe stretch, next byte. *)
         t.first_byte <- false;
         t.shift <- 0;
         t.phase <- Receiving 0;
         t.stretch_left <- t.stretch
       | _ -> ());
    t.prev_sda <- sda;
    t.prev_scl <- scl
  ;;

  let received t = Queue.to_list t.received
end

(* --- A reference controller, for testing the two models above ----------- *)

(* An ideal I2C write, as a sequence of steps on the controller's own drives.
   It honours clock stretching (waits for SCL to actually go high). Used only
   to test the target and checker; the real controller is firmware. *)
module Reference_controller = struct
  type step =
    | Drive of
        { sda : bool
        ; scl : bool
        } (* true = released *)
    | Wait_scl_high
    | Hold of int

  let write ~address ~bytes ~half =
    let bit b =
      [ Drive { sda = b; scl = false }
      ; Hold half
      ; Drive { sda = b; scl = true }
      ; Wait_scl_high
      ; Hold half
      ; Drive { sda = b; scl = false }
      ]
    in
    let byte v = List.concat_map (List.init 8 ~f:(fun i -> (v lsr (7 - i)) land 1 = 1)) ~f:bit @ bit true in
    [ Drive { sda = true; scl = true }; Hold half; Drive { sda = false; scl = true }; Hold half ]
    @ List.concat_map ((address lsl 1) :: bytes) ~f:byte
    @ [ Drive { sda = false; scl = false }
      ; Hold half
      ; Drive { sda = false; scl = true }
      ; Wait_scl_high
      ; Hold half
      ; Drive { sda = true; scl = true }
      ; Hold half
      ]
  ;;

  (* Run the controller against [target], returning the resolved bus levels
     on every cycle. *)
  let run ~steps ~(target : Target.t) =
    let trace = Queue.create () in
    let sda_out = ref true and scl_out = ref true in
    let cycle () =
      let t_sda, t_scl = Target.drive target in
      let sda = !sda_out && not t_sda and scl = !scl_out && not t_scl in
      Target.step target ~sda ~scl;
      Queue.enqueue trace (sda, scl);
      scl
    in
    List.iter steps ~f:(function
      | Drive { sda; scl } ->
        sda_out := sda;
        scl_out := scl;
        ignore (cycle () : bool)
      | Hold n ->
        for _ = 1 to n do
          ignore (cycle () : bool)
        done
      | Wait_scl_high ->
        let budget = ref 100_000 in
        while (not (cycle ())) && !budget > 0 do
          decr budget
        done);
    Queue.to_list trace
  ;;
end
