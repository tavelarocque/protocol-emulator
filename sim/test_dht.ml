(* The AM2302 / DHT22 reader ([Firmware.dht]) against a sensor written here
   from the AM2302 datasheet's timing table, with every interval drawn from
   the range the datasheet allows. The cocotb test runs the same firmware
   on the RTL and the gate netlist with sigrok's AM230x decoder reading the
   wire. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware

let clkdiv = 50 (* 10 MHz: a tick is 5 us *)
let us x = x * 10

(* An AM2302. After the host has held the line low for 0.8 ms or more and
   let go, it waits 20 to 200 us, answers with 75 to 85 us low and as long
   high, and sends 40 bits: 48 to 55 us low, then high for 22 to 30 us (a
   0) or 68 to 75 us (a 1). It ends with 45 to 55 us low. *)
module Sensor = struct
  type t =
    { rand : Random.State.t
    ; bits : int list
    ; send : int (* how many of them it sends before it stops *)
    ; mutable low_for : int
    ; mutable started : int list (* lengths of the start pulses seen, cycles *)
    ; mutable plan : (bool * int) list (* (drive low, cycles) still to play *)
    ; mutable line : bool
    }

  let bits_of ~humidity ~temperature =
    let bytes = [ humidity lsr 8; humidity land 0xFF; temperature lsr 8; temperature land 0xFF ] in
    let bytes = bytes @ [ List.sum (module Int) bytes ~f:Fn.id land 0xFF ] in
    List.concat_map bytes ~f:(fun b -> List.init 8 ~f:(fun i -> (b lsr (7 - i)) land 1))
  ;;

  let create ?(send = 40) ~seed ~humidity ~temperature () =
    { rand = Random.State.make [| seed |]
    ; bits = bits_of ~humidity ~temperature
    ; send
    ; low_for = 0
    ; started = []
    ; plan = []
    ; line = true
    }
  ;;

  let between t lo hi = us lo + Random.State.int t.rand (us (hi - lo) + 1)
  let drive t = match t.plan with (low, _) :: _ -> low | [] -> false

  let answer t =
    let bit b = [ true, between t 48 55; (false, if b = 1 then between t 68 75 else between t 22 30) ] in
    let sent = List.take t.bits t.send in
    t.plan
    <- [ false, between t 20 200; true, between t 75 85; false, between t 75 85 ]
       @ List.concat_map sent ~f:bit
       @ if t.send = 40 then [ true, between t 45 55 ] else []
  ;;

  let step t ~line =
    (match t.plan with
     | (low, n) :: rest -> t.plan <- (if n <= 1 then rest else (low, n - 1) :: rest)
     | [] ->
       if not line
       then t.low_for <- t.low_for + 1
       else (
         if t.low_for > 0 then t.started <- t.low_for :: t.started;
         if t.low_for >= us 800 && t.send > 0 then answer t;
         t.low_for <- 0));
    t.line <- line
  ;;
end

(* Take [readings] readings, [gap] cycles apart, the host emptying the RX
   FIFO only at the end of each: it holds the four words. *)
let run ?(source = Firmware.dht) ?(start_us = 1300) (sensor : Sensor.t) =
  let m =
    Isa.create
      ~program:(Asm.assemble source)
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i = 0 then Isa.Pin_mode.Open_drain else Input))
      ~threads:[ Firmware.dht_config ~clkdiv ]
  in
  let words = Queue.create () in
  assert (Isa.push_tx m ~thread:0 (Firmware.dht_word ~start_us));
  for _ = 1 to us (start_us + 8000) do
    let inputs = if Sensor.drive sensor then 0xFE else 0xFF in
    Isa.step m ~inputs;
    Sensor.step sensor ~line:(Isa.lines m ~inputs land 1 = 1)
  done;
  let rec drain () =
    match Isa.pop_rx m ~thread:0 with
    | Some w ->
      Queue.enqueue words w;
      drain ()
    | None -> ()
  in
  drain ();
  Queue.to_list words
;;

let show words =
  printf "RX words: %s: " (String.concat ~sep:" " (List.map words ~f:(sprintf "%04x")));
  match Firmware.dht_reading words with
  | Ok (h, t) -> printf "%.1f %%, %.1f C\n" (Float.of_int h /. 10.) (Float.of_int t /. 10.)
  | Error e -> printf "no reading: %s\n" e
;;

let%expect_test "a reading; a sensor that is not there; one that stops part way" =
  let sensor = Sensor.create ~seed:1 ~humidity:652 ~temperature:(0x8000 lor 101) () in
  show (run sensor);
  printf !"start pulses, us: %{sexp:int list}\n" (List.map sensor.started ~f:(fun c -> c / 10));
  let sensor = Sensor.create ~seed:1 ~humidity:652 ~temperature:351 () in
  show (run ~start_us:20_000 sensor);
  printf !"start pulses, us: %{sexp:int list}\n" (List.map sensor.started ~f:(fun c -> c / 10));
  show (run (Sensor.create ~send:0 ~seed:1 ~humidity:652 ~temperature:351 ()));
  show (run (Sensor.create ~send:21 ~seed:1 ~humidity:0xFFFF ~temperature:0xFFFF ()));
  [%expect {|
    RX words: 028c 8065 0073 0000: 65.2 %, -10.1 C
    start pulses, us: (1285)
    RX words: 028c 015f 00ee 0000: 65.2 %, 35.1 C
    start pulses, us: (20005)
    RX words: 0000 0000 0000 0001: no reading: the sensor stopped answering
    RX words: ffff f800 0000 0001: no reading: the sensor stopped answering
    |}]
;;

let%test_unit "random readings from sensors at every timing the datasheet allows" =
  Quickcheck.test
    (Quickcheck.Generator.tuple3 (Int.gen_incl 0 0xFFFF) (Int.gen_incl 0 0xFFFF) (Int.gen_incl 0 1_000_000))
    ~trials:150
    ~sexp_of:[%sexp_of: int * int * int]
    ~f:(fun (humidity, temperature, seed) ->
      let sensor = Sensor.create ~seed ~humidity ~temperature () in
      [%test_result: (int * int, string) Result.t]
        (Firmware.dht_reading (run sensor))
        ~expect:
          (Ok
             (humidity, if temperature land 0x8000 <> 0 then -(temperature land 0x7FFF) else temperature)))
;;

(* A sensor that stops lets the line go, so the bit it stopped in never
   ends: that one reads as a 1, whatever it was. *)
let%test_unit "a sensor that stops after any number of bits: the bits before, zeros after, and the flag" =
  List.iter (List.range 0 40) ~f:(fun send ->
    let sensor = Sensor.create ~send ~seed:send ~humidity:0xA5C3 ~temperature:0x0F69 () in
    let all =
      List.take sensor.bits (send - 1)
      @ (if send > 0 then [ 1 ] else [])
      @ List.init (40 - send) ~f:(fun _ -> 0)
    in
    let word bits = List.fold bits ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b) in
    [%test_result: int list]
      (run sensor)
      ~expect:[ word (List.take all 16); word (List.sub all ~pos:16 ~len:16); word (List.drop all 32); 1 ])
;;

let%expect_test "planted bugs" =
  let caught source =
    List.exists [ 3; 4; 5; 6 ] ~f:(fun seed ->
      let good = Sensor.create ~seed ~humidity:0x02F3 ~temperature:0x80C5 () in
      let stops = Sensor.create ~send:19 ~seed ~humidity:0xFFFF ~temperature:0xFFFF () in
      let absent = Sensor.create ~send:0 ~seed ~humidity:1 ~temperature:1 () in
      let reading = run ~source good in
      not
        ([%equal: (int * int, string) Result.t] (Firmware.dht_reading reading) (Ok (0x02F3, -0xC5))
         && List.for_all good.started ~f:(fun c -> c >= us 1000 && c <= us 2000)
         && [%equal: int list] (run ~source stops) [ 0xFFFF; 0xE000; 0; 1 ]
         && [%equal: int list] (run ~source absent) [ 0; 0; 0; 1 ]))
  in
  let fw ~pattern ~with_ =
    let s = String.substr_replace_first Firmware.dht ~pattern ~with_ in
    assert (not (String.equal s Firmware.dht));
    s
  in
  printf "the program as it is: %s\n" (if caught Firmware.dht then "WRONG" else "right");
  List.iter
    [ "the line read 20 to 25 us into the high", fw ~pattern:"nop [6]" ~with_:"nop [2]"
    ; "the line read 70 to 75 us into the high", fw ~pattern:"nop [6]" ~with_:"nop [12]"
    ; ( "a bit's low not waited for: a 1 read twice"
      , fw ~pattern:"bit:    wait 0 pin 0 timeout" ~with_:"bit:    nop" )
    ; "the start a quarter as long", fw ~pattern:"low:    jmp x-- low [7]" ~with_:"low:    jmp x-- low [1]"
    ; "the line never let go", fw ~pattern:"set pins, 1             ; and let go" ~with_:"nop"
    ; "the checksum never sent to the host", fw ~pattern:"push                    ; the checksum" ~with_:"nop                     ; the checksum"
    ; "a stopped sensor reported as read", fw ~pattern:"set x, 1\n" ~with_:"set x, 0\n"
    ; "four bits to a byte after a sensor stops", fw ~pattern:"jmp x-- fail\n        set x, 7" ~with_:"jmp x-- fail\n        set x, 3"
    ; "the answer's high taken for the first bit", fw ~pattern:"wait 1 pin 0 timeout    ; and high\n" ~with_:""
    ]
    ~f:(fun (name, source) -> printf "%-50s %s\n" name (if caught source then "caught" else "MISSED"));
  [%expect {|
    the program as it is: right
    the line read 20 to 25 us into the high            caught
    the line read 70 to 75 us into the high            caught
    a bit's low not waited for: a 1 read twice         caught
    the start a quarter as long                        caught
    the line never let go                              caught
    the checksum never sent to the host                caught
    a stopped sensor reported as read                  caught
    four bits to a byte after a sensor stops           caught
    the answer's high taken for the first bit          caught
    |}]
;;
