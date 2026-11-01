(* Differential test: the Hardcaml core against the ISA reference model, on
   random programs. The harness is sim/lockstep.ml.

   Each trial draws a random program (64 uniformly random 16-bit words, so
   every encoding including reserved ones gets exercised), a random
   configuration for each of the two threads and a random pin-mode
   assignment, then runs both implementations in lockstep with random pin
   inputs, random host FIFO traffic on both threads, and threads being
   enabled and disabled at random, comparing the full architectural state of
   both threads and the shared pins after every cycle. The two threads run
   from the same memory, so they often execute overlapping code and fight
   over the same pins, which is what tests the composition. *)

open! Core
module Rtl = Pe_hw.Pe_core

let trials = 400
let cycles_per_trial = 300
let run_trial ?coverage ?mutation ~seed ~cycles () =
  Lockstep.run_random ?coverage ?mutation ~seed ~cycles ()
;;

let%test_unit "RTL core matches the ISA model on random programs" =
  for seed = 0 to trials - 1 do
    match run_trial ~seed ~cycles:cycles_per_trial () with
    | None -> ()
    | Some divergence -> raise_s divergence
  done
;;

(* What the random programs actually exercised across the whole run. A
   behaviour with a zero count here is untested, however green the
   differential test is. *)
let%expect_test "coverage of the differential test" =
  let coverage = Lockstep.create_coverage () in
  for seed = 0 to trials - 1 do
    ignore (run_trial ~coverage ~seed ~cycles:cycles_per_trial () : Sexp.t option)
  done;
  let table = coverage.basic in
  let required =
    [ "jmp (always)"; "jmp !x"; "jmp x--"; "jmp !y"; "jmp y--"; "jmp x!=y"
    ; "jmp !osre"; "jmp !isrf"; "wait: condition met"; "wait: stalled"
    ; "wait: stalled, spending timeout budget"; "wait: timed out"; "in pins"
    ; "in x"; "in y"; "in null"; "out pins"; "out x"; "out y"; "out null"; "push"
    ; "push: stalled, RX full"; "pull"; "pull: stalled, TX empty"; "mov to x"
    ; "mov to y"; "mov to pins"; "mov to isr"; "mov to osr"; "mov to null"
    ; "mov (reserved -> nop)"; "set pins"; "set x"; "set y"
    ; "set (reserved -> nop)"; "nop"; "(delay cycle)"; "(side-set driving pins)"
    ; "(thread disabled)"; "(both threads enabled)"
    ; "(both threads drive pins in one cycle)"; "(between divider ticks)"
    ; "(chain moved a word)"; "(chain blocked: thread 1 TX full)"
    ]
  in
  List.iter required ~f:(fun key ->
    if not (Hashtbl.mem table key) then raise_s [%message "coverage hole" (key : string)]);
  let total = Hashtbl.data table |> List.sum (module Int) ~f:Fn.id in
  Hashtbl.to_alist table
  |> List.sort ~compare:(fun (a, _) (b, _) -> String.compare a b)
  |> List.iter ~f:(fun (key, n) ->
    printf "%-40s %6d  %5.1f%%\n" key n (100. *. Float.of_int n /. Float.of_int total));
  (* The cross bins: combinations that random programs reach rarely or
     never. Coverage closure (test_closure.ml) targets the weak ones. *)
  print_endline "";
  List.iter Lockstep.all_cross_bins ~f:(fun bin ->
    printf "%-50s %6d\n" bin (Hashtbl.find coverage.cross bin |> Option.value ~default:0));
  [%expect {|
    (between divider ticks)                   57365   13.4%
    (both threads drive pins in one cycle)    10472    2.4%
    (both threads enabled)                   104986   24.4%
    (chain blocked: thread 1 TX full)          2327    0.5%
    (chain moved a word)                        293    0.1%
    (delay cycle)                             36512    8.5%
    (side-set driving pins)                   71477   16.6%
    (thread disabled)                         15597    3.6%
    in null                                    1345    0.3%
    in pins                                    1130    0.3%
    in x                                       1472    0.3%
    in y                                       1171    0.3%
    jmp !isrf                                   794    0.2%
    jmp !osre                                   886    0.2%
    jmp !x                                     1327    0.3%
    jmp !y                                     1580    0.4%
    jmp (always)                               1135    0.3%
    jmp x!=y                                   2416    0.6%
    jmp x--                                     782    0.2%
    jmp y--                                     649    0.2%
    mov (reserved -> nop)                      2548    0.6%
    mov to isr                                  602    0.1%
    mov to null                                 401    0.1%
    mov to osr                                  434    0.1%
    mov to pins                                 766    0.2%
    mov to x                                    516    0.1%
    mov to y                                    473    0.1%
    nop                                        5327    1.2%
    out null                                   1424    0.3%
    out pins                                   1183    0.3%
    out x                                      1337    0.3%
    out y                                      1329    0.3%
    pull                                       1898    0.4%
    pull: stalled, TX empty                   29970    7.0%
    push                                       2386    0.6%
    push: stalled, RX full                     4275    1.0%
    set (reserved -> nop)                      1545    0.4%
    set pins                                   1248    0.3%
    set x                                      1505    0.4%
    set y                                      1415    0.3%
    wait: condition met                        3949    0.9%
    wait: stalled                             38744    9.0%
    wait: stalled, spending timeout budget    10794    2.5%
    wait: timed out                            1770    0.4%

    pins: both threads write the same pin                4896
    chain: move into thread 1 TX holding 0                138
    chain: move into thread 1 TX holding 1                 69
    chain: move into thread 1 TX holding 2                 39
    chain: move into thread 1 TX holding 3                 47
    chain: move in a cycle thread 1 pulls                   2
    chain: move in a cycle thread 0 pushes                  7
    chain: thread 0 PUSH stalled behind a full chain      745
    divider: timed wait expires on a divided thread       315
    divider: delay counted on a divided thread           9198
    divider: side-set on a divided thread               16328
    enable: disabled during a delay                       185
    enable: disabled during a timed wait                   50
    enable: disabled between divider ticks                206
    side-set: driven during a stall                     43012
    fifo: both threads stalled on FIFOs                  2166
    |}]
;;

(* Test the test: every planted bug must make the RTL diverge from the model
   within the same budget the real test uses. Datapath bugs are planted in
   thread 1 only, so this also shows the second thread is really exercised. The count shows how many
   random programs it took, a rough measure of how hard each bug is to hit. *)
let%expect_test "every planted bug in the core is caught" =
  List.iter Rtl.Mutation.all ~f:(fun mutation ->
    let first_failure =
      List.find (List.init trials ~f:Fn.id) ~f:(fun seed ->
        Option.is_some (run_trial ~mutation ~seed ~cycles:cycles_per_trial ()))
    in
    match first_failure with
    | None -> raise_s [%message "mutant survived" (mutation : Rtl.Mutation.t)]
    | Some seed ->
      printf
        "%-28s caught by program #%d\n"
        (Sexp.to_string (Rtl.Mutation.sexp_of_t mutation))
        (seed + 1));
  [%expect {|
    Xdec_never_decrements        caught by program #2
    Wait_timeout_ignores_budget  caught by program #4
    Delay_field_ignored          caught by program #2
    Set_pins_count_off_by_one    caught by program #4
    Push_not_right_justified     caught by program #4
    Pin_priority_inverted        caught by program #10
    Fetch_port_crossed           caught by program #1
    Chain_ignores_full           caught by program #25
    |}]
;;
