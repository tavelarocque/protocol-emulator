(* Tests of the I2C oracles themselves, before they judge any firmware.
   An oracle that has never been shown to reject anything is not an oracle. *)

open! Core
module I2c = Pe_model.I2c_model

let decode trace =
  let c = I2c.Checker.create () in
  List.iter trace ~f:(fun (sda, scl) -> I2c.Checker.step c ~sda ~scl);
  I2c.Checker.events c, I2c.Checker.errors c
;;

let write_events ~address ~bytes ~acked =
  let open I2c.Event in
  let ack_data = acked in
  (Start :: Byte { value = address lsl 1; ack = acked } :: List.map bytes ~f:(fun v ->
     Byte { value = v; ack = ack_data }))
  @ [ Stop ]
;;

let%test_unit "write to the right address: every byte ACKed, delivered, decoded" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Int.gen_incl 0 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 2 20)
       (Int.gen_incl 0 60))
    ~trials:300
    ~sexp_of:[%sexp_of: int * int list * int * int]
    ~f:(fun (address, bytes, half, stretch) ->
      let bytes = List.take bytes 5 in
      let target = I2c.Target.create ~address ~stretch () in
      let trace =
        I2c.Reference_controller.run
          ~steps:(I2c.Reference_controller.write ~address ~bytes ~half)
          ~target
      in
      let events, errors = decode trace in
      [%test_result: string list] errors ~expect:[];
      [%test_result: I2c.Event.t list] events ~expect:(write_events ~address ~bytes ~acked:true);
      [%test_result: int list] (I2c.Target.received target) ~expect:bytes)
;;

let%test_unit "write to the wrong address: NACK, nothing delivered" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3
       (Int.gen_incl 0 127)
       (Int.gen_incl 1 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255)))
    ~trials:200
    ~sexp_of:[%sexp_of: int * int * int list]
    ~f:(fun (address, offset, bytes) ->
      let bytes = List.take bytes 3 in
      let target = I2c.Target.create ~address:((address + offset) % 128) ~stretch:0 () in
      let trace =
        I2c.Reference_controller.run
          ~steps:(I2c.Reference_controller.write ~address ~bytes ~half:4)
          ~target
      in
      let events, errors = decode trace in
      [%test_result: string list] errors ~expect:[];
      [%test_result: I2c.Event.t list] events ~expect:(write_events ~address ~bytes ~acked:false);
      [%test_result: int list] (I2c.Target.received target) ~expect:[])
;;

let%test_unit "clock stretching really holds SCL low" =
  let target = I2c.Target.create ~address:0x42 ~stretch:50 () in
  let trace =
    I2c.Reference_controller.run
      ~steps:(I2c.Reference_controller.write ~address:0x42 ~bytes:[ 0xA5 ] ~half:4)
      ~target
  in
  (* Longest run of SCL low must reflect the stretch, not just half periods. *)
  let longest, _ =
    List.fold trace ~init:(0, 0) ~f:(fun (best, run) (_, scl) ->
      let run = if scl then 0 else run + 1 in
      max best run, run)
  in
  [%test_pred: int] (fun n -> n >= 50) longest
;;

(* The checker must reject what it should. Each case is a corrupted bus. *)
let%test_unit "checker flags a STOP in the middle of a byte" =
  let target = I2c.Target.create ~address:0x10 ~stretch:0 () in
  let trace =
    I2c.Reference_controller.run
      ~steps:(I2c.Reference_controller.write ~address:0x10 ~bytes:[ 0xFF ] ~half:4)
      ~target
  in
  (* Cut the trace after a few data bits and append a STOP condition. *)
  let cut = List.take trace 60 in
  let stop = [ false, false; false, true; false, true; true, true; true, true ] in
  let _, errors = decode (cut @ stop) in
  [%test_pred: string list] (fun e -> not (List.is_empty e)) errors
;;

let%test_unit "checker flags a STOP with no START" =
  (* SDA low, SCL low; SCL rises; SDA rises while SCL is high. *)
  let _, errors = decode [ false, false; false, true; true, true ] in
  [%test_pred: string list] (fun e -> not (List.is_empty e)) errors
;;

let%test_unit "checker reads data on SCL rising edges, not levels" =
  (* SDA glitching while SCL is low must not change the decoded byte. *)
  let target = I2c.Target.create ~address:0x55 ~stretch:0 () in
  let trace =
    I2c.Reference_controller.run
      ~steps:(I2c.Reference_controller.write ~address:0x55 ~bytes:[ 0x3C ] ~half:6)
      ~target
  in
  let glitched = List.map trace ~f:(fun (sda, scl) -> if scl then sda, scl else not sda, scl) in
  let events, _ = decode glitched in
  let events_clean, _ = decode trace in
  [%test_result: I2c.Event.t list] events ~expect:events_clean
;;

let%test_unit "read: the target sends its bytes MSB first until the controller NACKs" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Int.gen_incl 0 127)
       (Quickcheck.Generator.list_non_empty (Int.gen_incl 0 255))
       (Int.gen_incl 2 20)
       (Int.gen_incl 0 60))
    ~trials:300
    ~sexp_of:[%sexp_of: int * int list * int * int]
    ~f:(fun (address, bytes, half, stretch) ->
      let bytes = List.take bytes 5 in
      (* One spare byte scripted: it must not be sent after the NACK. *)
      let target = I2c.Target.create ~to_send:(bytes @ [ 0x99 ]) ~address ~stretch () in
      let count = List.length bytes in
      let trace =
        I2c.Reference_controller.run
          ~steps:(I2c.Reference_controller.read ~address ~count ~half)
          ~target
      in
      let events, errors = decode trace in
      let open I2c.Event in
      [%test_result: string list] errors ~expect:[];
      [%test_result: I2c.Event.t list]
        events
        ~expect:
          ((Start :: Byte { value = (address lsl 1) lor 1; ack = true }
            :: List.mapi bytes ~f:(fun i v -> Byte { value = v; ack = i < count - 1 }))
           @ [ Stop ]);
      [%test_result: int list] (I2c.Target.sent target) ~expect:bytes;
      [%test_result: int list] (I2c.Target.received target) ~expect:[])
;;
