(* The MIL-STD-1553B bus controller ([Firmware.mil1553_bc] on thread 0)
   and bus monitor ([Firmware.mil1553_mon] on thread 1) against a remote
   terminal written here from MIL-STD-1553B: Manchester II at 1 Mbit/s,
   each half bit one level; a command or status word's sync positive for a
   bit and a half then negative, a data word's the opposite; 16 bits most
   significant first and odd parity; the words of a message contiguous. The
   terminal takes a receive command's data words and answers with its
   status word, answers a transmit command with its status word and the
   data words, answers mode commands, keeps quiet after a broadcast
   (address 31), and answers between 4 and 12 us after the message (mid
   parity to mid sync). It reads the bus from the chip's TX and TX-bar, and
   puts the bus, the chip's words and its own, on RX as a transceiver's
   receiver does. The cocotb test runs the same firmware on the RTL and
   the gate netlist with the MIL-STD-1553 sigrok decoder (an unmerged pull
   request) reading the bus. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module M = Firmware.Mil1553

type word =
  { value : int
  ; command_sync : bool (* command or status sync, else data sync *)
  ; parity_ok : bool
  ; from_rt : bool
  }
[@@deriving sexp_of, equal]

let odd_parity v = 1 - (Int.popcount v % 2)

(* The levels of a word on the bus, half bit by half bit: +1 or -1. *)
let word_halves ~command_sync value =
  let sync = if command_sync then [ 1; 1; 1; -1; -1; -1 ] else [ -1; -1; -1; 1; 1; 1 ] in
  let bits = List.init 16 ~f:(fun k -> (value lsr (15 - k)) land 1) @ [ odd_parity value ] in
  sync @ List.concat_map bits ~f:(fun b -> if b = 1 then [ 1; -1 ] else [ -1; 1 ])
;;

module Rt = struct
  type t =
    { bit : int (* cycles a bit *)
    ; address : int
    ; response_us : int (* mid parity to mid sync: 4 to 12 *)
    ; memory : int array array (* by subaddress *)
    ; bad_word : int option (* an answer's word sent with its parity wrong *)
    ; mutable now : int
    ; mutable sending : int list (* the RT's levels still to put on the bus *)
    ; mutable send_at : int
    ; mutable log : string list
    ; mutable errors : string list
    }

  let create ?(response_us = 6) ?bad_word ~bit () =
    { bit
    ; address = 5
    ; response_us
    ; bad_word
    ; memory = Array.init 32 ~f:(fun sa -> Array.init 32 ~f:(fun k -> (sa lsl 8) lor k))
    ; now = 0
    ; sending = []
    ; send_at = 0
    ; log = []
    ; errors = []
    }
  ;;

  let error t fmt = ksprintf (fun s -> t.errors <- sprintf "%d: %s" t.now s :: t.errors) fmt
  let status t = t.address lsl 11

  (* Answer with [words], the first sync starting [response_us] - 2 us
     after [ended], the end of the BC's last word. *)
  let respond t ~ended words =
    t.send_at <- ended + ((t.response_us - 2) * t.bit);
    t.sending
    <- List.concat_mapi words ~f:(fun k (command_sync, v) ->
         let halves = word_halves ~command_sync v in
         (* A wrong parity bit: its two halves the other way round. *)
         let halves =
           if Option.equal Int.equal t.bad_word (Some k)
           then List.take halves 38 @ List.rev (List.drop halves 38)
           else halves
         in
         List.concat_map halves ~f:(fun l -> List.init (t.bit / 2) ~f:(fun _ -> l)))
  ;;

  (* The BC's message [message], which ended at [ended]: act on it as
     MIL-STD-1553B has a terminal act. *)
  let message t ~ended (message : word list) =
    match message with
    | [] -> ()
    | cmd :: data ->
      let addr = cmd.value lsr 11 in
      let transmit = (cmd.value lsr 10) land 1 = 1 in
      let sa = (cmd.value lsr 5) land 31 in
      let wc = cmd.value land 31 in
      let mode = sa = 0 || sa = 31 in
      let expected = if transmit then 0 else if mode then wc lsr 4 else if wc = 0 then 32 else wc in
      if addr <> t.address && addr <> 31
      then t.log <- sprintf "not for this RT: %04x" cmd.value :: t.log
      else if not cmd.command_sync
      then error t "a message that starts with a data sync"
      else if List.exists (cmd :: data) ~f:(fun w -> not w.parity_ok)
      then error t "a parity error: no answer"
      else if List.exists data ~f:(fun w -> w.command_sync)
      then error t "a command sync among the data words"
      else if List.length data <> expected
      then error t "%d data words where the command has %d" (List.length data) expected
      else (
        let broadcast = addr = 31 in
        let values = List.map data ~f:(fun w -> w.value) in
        match mode, transmit with
        | true, _ ->
          t.log <- sprintf !"mode code %d %{sexp:int list}%s" wc values (if broadcast then " broadcast" else "") :: t.log;
          if not broadcast
          then respond t ~ended ((true, status t) :: (if transmit && wc >= 16 then [ false, 0x0ABC ] else []))
        | false, false ->
          List.iteri values ~f:(fun k v -> t.memory.(sa).(k) <- v);
          t.log
          <- sprintf !"received at subaddress %d: %{sexp:int list}%s" sa values (if broadcast then " broadcast" else "")
             :: t.log;
          if not broadcast then respond t ~ended [ true, status t ]
        | false, true ->
          let n = if wc = 0 then 32 else wc in
          let out = List.init n ~f:(fun k -> t.memory.(sa).(k)) in
          t.log <- sprintf !"sent from subaddress %d: %{sexp:int list}" sa out :: t.log;
          if broadcast
          then error t "a broadcast transmit command"
          else respond t ~ended ((true, status t) :: List.map out ~f:(fun v -> false, v)))
  ;;

  (* One cycle: [bc] is the level the chip drives (+1, -1 or 0). Returns
     the bus and whether the RT drove it. *)
  let step t ~bc =
    let mine =
      if t.now >= t.send_at
      then (
        match t.sending with
        | l :: rest ->
          t.sending <- rest;
          l
        | [] -> 0)
      else 0
    in
    if bc <> 0 && mine <> 0 then error t "the BC talks over the RT";
    t.now <- t.now + 1;
    (if mine <> 0 then mine else bc), mine <> 0
  ;;
end

(* Every word on the bus, read from its levels cycle by cycle and from
   whether the RT drove it: each half bit one level from start to end, a
   sync, Manchester bits; a word that follows at once is part of the same
   message. *)
let words_on_bus ~bit (bus : int array) (rt_drove : bool array) =
  let n = Array.length bus in
  let out = ref [] in
  let errors = ref [] in
  let t = ref 1 in
  while !t < n do
    if bus.(!t) <> 0 && bus.(!t - 1) = 0
    then (
      let s = ref !t in
      let continue = ref true in
      while !continue do
        if !s + (20 * bit) > n
        then (
          errors := "a word cut short" :: !errors;
          continue := false)
        else (
          let h = bit / 2 in
          let half k =
            let levels = List.init h ~f:(fun u -> bus.(!s + (k * h) + u)) in
            match List.dedup_and_sort levels ~compare:Int.compare with
            | [ l ] when l <> 0 -> Some l
            | _ -> None
          in
          (match Option.all (List.init 40 ~f:half) with
           | None -> errors := sprintf "%d: a half bit that is not one level" !s :: !errors
           | Some halves ->
             let sync = List.take halves 6 in
             let command_sync = [%equal: int list] sync [ 1; 1; 1; -1; -1; -1 ] in
             if (not command_sync) && not ([%equal: int list] sync [ -1; -1; -1; 1; 1; 1 ])
             then errors := sprintf "%d: no sync" !s :: !errors
             else (
               match
                 List.chunks_of (List.drop halves 6) ~length:2
                 |> List.map ~f:(function
                   | [ 1; -1 ] -> Some 1
                   | [ -1; 1 ] -> Some 0
                   | _ -> None)
                 |> Option.all
               with
               | None -> errors := sprintf "%d: not Manchester" !s :: !errors
               | Some bits ->
                 let value = List.fold (List.take bits 16) ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b) in
                 let parity_ok = List.sum (module Int) bits ~f:Fn.id % 2 = 1 in
                 out := (!s, { value; command_sync; parity_ok; from_rt = rt_drove.(!s) }) :: !out));
          s := !s + (20 * bit);
          if !s >= n || bus.(!s) = 0 then continue := false)
      done;
      t := !s + 1)
    else incr t
  done;
  List.rev !out, List.rev !errors
;;

type result =
  { bus : (int * word) list (* start cycle, word *)
  ; bus_errors : string list
  ; rt_log : string list
  ; rt_errors : string list
  ; monitor : (int * int) list (* the RX words in pairs: bits, tag *)
  ; end_cycle : int
  }

(* Run the BC and the monitor against the RT, the host pushing [host_words]
   to thread 0 as fast as it takes them and popping thread 1. The RT acts
   on a message once the bus has been quiet for two bit times after a word
   of the BC's. *)
let run
  ?(bc = Firmware.mil1553_bc)
  ?(mon = Firmware.mil1553_mon)
  ?(clkdiv = 1)
  ?response_us
  ?bad_word
  ?(cycles = 4000)
  host_words
  =
  let bit = 10 * max 1 clkdiv in
  let m =
    Isa.create_separate
      ~programs:[| Asm.assemble bc; Asm.assemble mon |]
      ~pin_modes:(Array.init Isa.num_pins ~f:(fun i -> if i < 2 then Isa.Pin_mode.Push_pull else Input))
      ~threads:[ { Firmware.mil1553_bc_config with clkdiv }; { Firmware.mil1553_mon_config with clkdiv } ]
  in
  let rt = Rt.create ?response_us ?bad_word ~bit () in
  let pending = Queue.of_list host_words in
  let rx = Queue.create () in
  let bus = Queue.create () in
  let drove = Queue.create () in
  let inputs = ref 0 in
  let acted_to = ref 0 in
  let total = cycles * max 1 clkdiv in
  for _ = 1 to total do
    (match Queue.peek pending with
     | Some v -> if Isa.push_tx m ~thread:0 v then ignore (Queue.dequeue pending : int option)
     | None -> ());
    Isa.step m ~inputs:!inputs;
    Option.iter (Isa.pop_rx m ~thread:1) ~f:(Queue.enqueue rx);
    let l = Isa.lines m ~inputs:!inputs in
    let bc =
      match l land 1, (l lsr 1) land 1 with
      | 1, 0 -> 1
      | 0, 1 -> -1
      | 0, 0 -> 0
      | _ ->
        Rt.error rt "TX and TX-bar both high";
        0
    in
    let b, mine = Rt.step rt ~bc in
    Queue.enqueue bus b;
    Queue.enqueue drove mine;
    let n = Queue.length bus in
    let ended = n - (2 * bit) in
    if ended > 0
       && Queue.get bus (ended - 1) <> 0
       && (not (Queue.get drove (ended - 1)))
       && List.for_all (List.range ended n) ~f:(fun k -> Queue.get bus k = 0)
    then (
      let words, _ = words_on_bus ~bit (Queue.to_array bus) (Queue.to_array drove) in
      let message = List.filter_map words ~f:(fun (s, w) -> if s >= !acted_to && not w.from_rt then Some w else None) in
      Rt.message rt ~ended message;
      acted_to := ended);
    inputs := (if b = 1 then 0b0100 else 0) lor if b = -1 then 0b1000 else 0
  done;
  let words, bus_errors = words_on_bus ~bit (Queue.to_array bus) (Queue.to_array drove) in
  let rx = Queue.to_list rx in
  { bus = words
  ; bus_errors
  ; rt_log = List.rev rt.log
  ; rt_errors = List.rev rt.errors
  ; monitor = List.chunks_of rx ~length:2 |> List.map ~f:(function [ a; b ] -> a, b | [ a ] -> a, -1 | _ -> assert false)
  ; end_cycle = total
  }
;;

(* What the monitor should have handed over for each word on the bus. *)
let expected_monitor (r : result) =
  List.map r.bus ~f:(fun (_, w) ->
    ( w.value
    , Bool.to_int w.command_sync
      lor (Bool.to_int w.parity_ok lsl 1)
      lor ((if w.parity_ok then odd_parity w.value else 1 - odd_parity w.value) lsl 2) ))
;;

let show_bus (r : result) =
  List.iter r.bus ~f:(fun (s, w) ->
    printf
      "%6d %s %s %04x%s\n"
      s
      (if w.from_rt then "RT" else "BC")
      (if w.command_sync then "C" else "D")
      w.value
      (if w.parity_ok then "" else " PARITY"));
  printf !"bus errors %{sexp:string list}\n" r.bus_errors;
  printf !"RT %{sexp:string list}\n" r.rt_log;
  printf !"RT errors %{sexp:string list}\n" r.rt_errors;
  let heard = [%equal: (int * int) list] r.monitor (expected_monitor r) in
  printf "the monitor heard every word as it was: %b\n" heard;
  if not heard then print_s [%sexp (List.map r.monitor ~f:(fun (a, b) -> sprintf "%04x/%d" a b) : string list)]
;;

(* For each BC command word after the first: the bus quiet before it, in
   microseconds. *)
let gaps ~bit (r : result) =
  List.filter_map (List.zip_exn (List.drop_last_exn r.bus) (List.tl_exn r.bus)) ~f:(fun ((a, _), (b, w)) ->
    if w.command_sync && not w.from_rt then Some (Float.of_int (b - a - (20 * bit)) /. Float.of_int bit) else None)
;;

let rx_cmd = M.command ~rt:5 ~transmit:false ~subaddress:2 ~count:3
let tx_cmd = M.command ~rt:5 ~transmit:true ~subaddress:2 ~count:3

let%expect_test "a receive command with three data words, then a transmit command" =
  let r = run [ rx_cmd; 0x1234; 0xABCD; 0x0001; tx_cmd ] in
  show_bus r;
  printf !"quiet before each later command (us): %{sexp:float list}\n" (gaps ~bit:10 r);
  [%expect {|
        16 BC C 2843
       216 BC D 1234
       416 BC D abcd
       616 BC D 0001
       856 RT C 2800
      1205 BC C 2c43
      1445 RT C 2800
      1645 RT D 1234
      1845 RT D abcd
      2045 RT D 0001
    bus errors ()
    RT ("received at subaddress 2: (4660 43981 1)"
     "sent from subaddress 2: (4660 43981 1)")
    RT errors ()
    the monitor heard every word as it was: true
    quiet before each later command (us): (14.9)
    |}]
;;

let%expect_test "mode commands, a broadcast, a terminal that is not there, 32 words" =
  let r =
    run
      ~cycles:17000
      ([ M.command ~rt:5 ~transmit:false ~subaddress:0 ~count:17 (* synchronize, with a data word *)
      ; 0x00FF
      ; M.command ~rt:5 ~transmit:true ~subaddress:31 ~count:16 (* transmit vector word *)
      ; M.command ~rt:5 ~transmit:true ~subaddress:0 ~count:2 (* transmit status word *)
      ; M.command ~rt:31 ~transmit:false ~subaddress:4 ~count:1 (* broadcast: no answer *)
      ; 0x5555
      ; M.command ~rt:7 ~transmit:true ~subaddress:1 ~count:1 (* nobody at 7 *)
      ; M.command ~rt:5 ~transmit:false ~subaddress:9 ~count:0
      ]
    @ List.init 32 ~f:(fun k -> 0x9000 + k)
       @ [ M.command ~rt:5 ~transmit:true ~subaddress:9 ~count:0 ])
  in
  printf "%d words on the bus\n" (List.length r.bus);
  printf !"bus errors %{sexp:string list}\n" r.bus_errors;
  printf !"RT %{sexp:string list}\n" r.rt_log;
  printf !"RT errors %{sexp:string list}\n" r.rt_errors;
  printf "the monitor heard every word as it was: %b\n" ([%equal: (int * int) list] r.monitor (expected_monitor r));
  printf !"quiet before each later command (us): %{sexp:float list}\n" (gaps ~bit:10 r);
  [%expect {|
    79 words on the bus
    bus errors ()
    RT ("mode code 17 (255)" "mode code 16 ()" "mode code 2 ()"
     "received at subaddress 4: (21845) broadcast" "not for this RT: 3c21"
      "received at subaddress 9: (36864 36865 36866 36867 36868 36869 36870 36871 36872 36873 36874 36875\
     \n 36876 36877 36878 36879 36880 36881 36882 36883 36884 36885 36886 36887\
     \n 36888 36889 36890 36891 36892 36893 36894 36895)"
      "sent from subaddress 9: (36864 36865 36866 36867 36868 36869 36870 36871 36872 36873 36874 36875\
     \n 36876 36877 36878 36879 36880 36881 36882 36883 36884 36885 36886 36887\
     \n 36888 36889 36890 36891 36892 36893 36894 36895)")
    RT errors ()
    the monitor heard every word as it was: true
    quiet before each later command (us): (14.9 15.4 15.5 15.2 16.1 14.9)
    |}]
;;

let%expect_test "CLKDIV 5 (1 Mbit/s at 50 MHz), answers at 4 and at 12 us" =
  List.iter [ 5, 4; 5, 12; 1, 4; 1, 12 ] ~f:(fun (clkdiv, response_us) ->
    let r = run ~clkdiv ~response_us [ rx_cmd; 0x1234; 0xABCD; 0x0001; tx_cmd ] in
    printf
      "CLKDIV %d, %2d us: %d words, %s, monitor %b, RT errors %d\n"
      clkdiv
      response_us
      (List.length r.bus)
      (if List.is_empty r.bus_errors then "every half bit exact" else "BUS ERRORS")
      ([%equal: (int * int) list] r.monitor (expected_monitor r))
      (List.length r.rt_errors));
  [%expect {|
    CLKDIV 5,  4 us: 10 words, every half bit exact, monitor true, RT errors 0
    CLKDIV 5, 12 us: 10 words, every half bit exact, monitor true, RT errors 0
    CLKDIV 1,  4 us: 10 words, every half bit exact, monitor true, RT errors 0
    CLKDIV 1, 12 us: 10 words, every half bit exact, monitor true, RT errors 0
    |}]
;;

let%expect_test "the timeout vectors are where the programs' labels are" =
  let at source label = List.Assoc.find_exn (snd (Asm.assemble_with_labels source)) label ~equal:String.equal in
  printf "%b %b\n" (at Firmware.mil1553_bc "next" = Firmware.mil1553_bc_next) (at Firmware.mil1553_mon "idle" = Firmware.mil1553_mon_idle);
  [%expect {| true true |}]
;;

let%test_unit "random messages, random answer times: the RT and the monitor agree with the host" =
  Quickcheck.test
    (Quickcheck.Generator.tuple4
       (Int.gen_incl 1 31)
       (Int.gen_incl 1 6)
       (List.gen_with_length 6 (Int.gen_incl 0 0xFFFF))
       (Int.gen_incl 4 12))
    ~trials:30
    ~sexp_of:[%sexp_of: int * int * int list * int]
    ~f:(fun (sa, n, data, response_us) ->
      let sa = if sa = 31 then 30 else sa in
      let data = List.take data n in
      let r =
        run
          ~response_us
          ([ M.command ~rt:5 ~transmit:false ~subaddress:sa ~count:n ] @ data @ [ M.command ~rt:5 ~transmit:true ~subaddress:sa ~count:n ])
      in
      [%test_result: string list] r.bus_errors ~expect:[];
      [%test_result: string list] r.rt_errors ~expect:[];
      [%test_result: string list]
        r.rt_log
        ~expect:
          [ sprintf !"received at subaddress %d: %{sexp:int list}" sa data
          ; sprintf !"sent from subaddress %d: %{sexp:int list}" sa data
          ];
      [%test_result: (int * int) list] r.monitor ~expect:(expected_monitor r))
;;

let%expect_test "planted bugs" =
  let host = [ rx_cmd; 0x1234; 0xABCD; 0x0001; tx_cmd; M.command ~rt:5 ~transmit:false ~subaddress:0 ~count:17; 0x00FF ] in
  let summary (r : result) = r.bus, r.bus_errors, r.rt_log, r.rt_errors, r.monitor in
  (* The RT answers the transmit command with its second data word's
     parity wrong, which the monitor must report. *)
  let right = summary (run ~bad_word:2 host) in
  let caught ?bc ?mon () =
    let r = run ?bc ?mon ~bad_word:2 host in
    let bus, bus_errors, rt_log, rt_errors, monitor = summary r in
    let rbus, _, rlog, _, rmon = right in
    not
      ([%equal: (int * word) list] bus rbus
       && List.is_empty bus_errors
       && [%equal: (int * int) list] monitor (expected_monitor r)
       && [%equal: string list] rt_log rlog
       && List.is_empty rt_errors
       && [%equal: (int * int) list] monitor rmon)
  in
  let fw program ~pattern ~with_ =
    let s = String.substr_replace_first program ~pattern ~with_ in
    assert (not (String.equal s program));
    s
  in
  let b = fw Firmware.mil1553_bc and m = fw Firmware.mil1553_mon in
  printf "the programs as they are: %s\n" (if caught () then "WRONG" else "right");
  List.iter
    [ "command sync low first", `B (b ~pattern:"set pins, 1 [14]" ~with_:"set pins, 2 [14]")
    ; "command sync a tick short", `B (b ~pattern:"set pins, 2 [11]" ~with_:"set pins, 2 [10]")
    ; "data sync high first", `B (b ~pattern:"set pins, 2 [12]" ~with_:"set pins, 1 [12]")
    ; "a 1 sent low then high", `B (b ~pattern:"set pins, 1 [4]         ; a 1" ~with_:"set pins, 2 [4]         ; a 1")
    ; "a 0's first half a tick long", `B (b ~pattern:"set pins, 2 [4]         ; a 0" ~with_:"set pins, 2 [5]         ; a 0")
    ; "even parity", `B (b ~pattern:"jmp !x pone" ~with_:"jmp x-- pone")
    ; "parity not started again", `B (b ~pattern:"mov crc, null
        set pins, 1 [11]" ~with_:"set pins, 1 [11]")
    ; "TX-bar driven with TX", `B (b ~pattern:"set pins, 1 [4]         ; a 1" ~with_:"set pins, 3 [4]         ; a 1")
    ; "the word count taken as it is", `B (b ~pattern:"jmp !y w32
        jmp send" ~with_:"jmp send
        jmp send")
    ; "no data word for mode codes", `B (b ~pattern:"out y, 1                ; a mode" ~with_:"set y, 0                ; a mode")
    ; "data words after a transmit command", `B (b ~pattern:"jmp !x rcv
        jmp send" ~with_:"jmp rcv
        jmp send")
    ; "the next command without waiting", `B (b ~pattern:"wait 1 pin 2 timeout
        jmp quiet" ~with_:"jmp next
        jmp quiet")
    ; "the monitor three ticks early", `M (m ~pattern:"set x, 15 [3]" ~with_:"set x, 15    ")
    ; "the monitor three ticks late", `M (m ~pattern:"set x, 15 [3]" ~with_:"set x, 15 [6]")
    ; "the monitor's parity not checked", `M (m ~pattern:"mov x, crc              ; 1 if" ~with_:"set x, 1                ; 1 if")
    ; "data and status syncs mixed up", `M (m ~pattern:"jmp !x dsync
        jmp csync" ~with_:"jmp !x csync
        jmp dsync")
    ; "the monitor's parity from the last word", `M (m ~pattern:"        mov crc, null
        set x, 15" ~with_:"        set x, 15")
    ]
    ~f:(fun (name, which) ->
      let bug = match which with `B bc -> caught ~bc () | `M mon -> caught ~mon () in
      printf "%-40s %s\n" name (if bug then "caught" else "MISSED"));
  [%expect {|
    the programs as they are: right
    command sync low first                   caught
    command sync a tick short                caught
    data sync high first                     caught
    a 1 sent low then high                   caught
    a 0's first half a tick long             caught
    even parity                              caught
    parity not started again                 caught
    TX-bar driven with TX                    caught
    the word count taken as it is            caught
    no data word for mode codes              caught
    data words after a transmit command      caught
    the next command without waiting         caught
    the monitor three ticks early            caught
    the monitor three ticks late             caught
    the monitor's parity not checked         caught
    data and status syncs mixed up           caught
    the monitor's parity from the last word  caught
    |}]
;;
