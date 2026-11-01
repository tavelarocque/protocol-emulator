open! Core
open! Hardcaml
open Harness

(* 1. Property: for random bytes and baud divisors, the line matches the
   ideal frame cycle for cycle, and a real receiver decodes the same byte. *)
let%test_unit "random bytes and divisors: exact waveform and receiver agree" =
  Quickcheck.test
    (Quickcheck.Generator.both (Int.gen_incl 0 255) (Int.gen_incl 1 64))
    ~trials:500
    ~sexp_of:[%sexp_of: int * int]
    ~f:(fun (byte, divisor) ->
      let v = check ~divisor ~byte () in
      [%test_result: bool] v.exact_ok ~expect:true ~message:"exact waveform";
      [%test_result: bool] v.receiver_ok ~expect:true ~message:"receiver decode")
;;

(* 2. Test the tests: every planted bug must be caught by the cycle-exact
   oracle. The table also shows which bugs a protocol-level receiver alone
   would miss, which is the argument for keeping both oracles. *)
let%expect_test "every planted bug is caught, and by which oracle" =
  let cases = List.init 300 ~f:(fun k -> (k * 37) % 256, 1 + (k % 24)) in
  let total = List.length cases in
  List.iter Uart_tx.Mutation.all ~f:(fun mutation ->
    let caught f =
      List.count cases ~f:(fun (byte, divisor) ->
        not (f (check ~mutation ~divisor ~byte ())))
    in
    let exact = caught (fun v -> v.exact_ok) in
    let receiver = caught (fun v -> v.receiver_ok) in
    if exact = 0
    then raise_s [%message "mutant survived the test suite" (mutation : Uart_tx.Mutation.t)];
    printf
      "%-20s  exact-waveform caught %3d/%d   receiver caught %3d/%d\n"
      (Sexp.to_string (Uart_tx.Mutation.sexp_of_t mutation))
      exact
      total
      receiver
      total);
  [%expect {|
    Stop_bit_short        exact-waveform caught 300/300   receiver caught  13/300
    Msb_first             exact-waveform caught 281/300   receiver caught 281/300
    Divisor_off_by_one    exact-waveform caught 300/300   receiver caught 192/300
    |}]
;;

(* 3. A readable waveform, locked in as documentation. After the first run,
   inspect the diff, and if it is right, accept it with `dune promote`. *)
let%expect_test "waveform: 0x4D at divisor 2 (not a bit-palindrome, so bit order is visible)" =
  let sim = create_sim () in
  let waves, sim = Hardcaml_waveterm.Waveform.create sim in
  ignore (transmit sim ~divisor:2 ~byte:0x4D : bool list option);
  Hardcaml_waveterm.Waveform.print ~display_width:100 ~display_height:20 ~wave_width:0 waves;
  [%expect {|
    ┌Signals───────────┐┌Waves─────────────────────────────────────────────────────────────────────────┐
    │clock             ││┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐│
    │                  ││ └┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└┘└│
    │clear             ││──┐                                                                           │
    │                  ││  └─────────────────────────────────────────                                  │
    │                  ││──┬─────────────────────────────────────────                                  │
    │data              ││ .│4D                                                                         │
    │                  ││──┴─────────────────────────────────────────                                  │
    │                  ││──┬─────────────────────────────────────────                                  │
    │divisor           ││ .│0002                                                                       │
    │                  ││──┴─────────────────────────────────────────                                  │
    │start             ││  ┌─┐                                                                         │
    │                  ││──┘ └───────────────────────────────────────                                  │
    │busy              ││    ┌───────────────────────────────────────                                  │
    │                  ││────┘                                                                         │
    │tx                ││────┐   ┌───┐   ┌───────┐       ┌───┐   ┌───                                  │
    │                  ││    └───┘   └───┘       └───────┘   └───┘                                     │
    │                  ││                                                                              │
    │                  ││                                                                              │
    └──────────────────┘└──────────────────────────────────────────────────────────────────────────────┘
    |}]
;;
