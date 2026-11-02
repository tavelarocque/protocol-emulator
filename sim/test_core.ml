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
    (between divider ticks)                   54923   12.9%
    (both threads drive pins in one cycle)    10205    2.4%
    (both threads enabled)                   104088   24.4%
    (chain blocked: thread 1 TX full)          2707    0.6%
    (chain moved a word)                        221    0.1%
    (delay cycle)                             37173    8.7%
    (side-set driving pins)                   70079   16.4%
    (thread disabled)                         16493    3.9%
    in null                                    1205    0.3%
    in pins                                    1406    0.3%
    in x                                       1183    0.3%
    in y                                       1208    0.3%
    jmp !isrf                                   856    0.2%
    jmp !osre                                  1841    0.4%
    jmp !x                                     1145    0.3%
    jmp !y                                     1411    0.3%
    jmp (always)                               1741    0.4%
    jmp x!=y                                   1944    0.5%
    jmp x--                                     710    0.2%
    jmp y--                                     723    0.2%
    mov (reserved -> nop)                      2172    0.5%
    mov to isr                                  564    0.1%
    mov to null                                 601    0.1%
    mov to osr                                  623    0.1%
    mov to pins                                 830    0.2%
    mov to x                                    445    0.1%
    mov to y                                    409    0.1%
    nop                                        4977    1.2%
    out null                                   1328    0.3%
    out pins                                   1615    0.4%
    out x                                      1222    0.3%
    out y                                      1211    0.3%
    pull                                       1848    0.4%
    pull: stalled, TX empty                   28859    6.8%
    push                                       2332    0.5%
    push: stalled, RX full                     7050    1.6%
    set (reserved -> nop)                      1595    0.4%
    set pins                                   1232    0.3%
    set x                                      1138    0.3%
    set y                                      1296    0.3%
    wait: condition met                        3668    0.9%
    wait: stalled                             39017    9.1%
    wait: stalled, spending timeout budget    10240    2.4%
    wait: timed out                            1766    0.4%

    pins: both threads write the same pin                5269
    chain: move into thread 1 TX holding 0                129
    chain: move into thread 1 TX holding 1                 40
    chain: move into thread 1 TX holding 2                 23
    chain: move into thread 1 TX holding 3                 29
    chain: move in a cycle thread 1 pulls                   1
    chain: move in a cycle thread 0 pushes                 10
    chain: thread 0 PUSH stalled behind a full chain     1149
    divider: timed wait expires on a divided thread       375
    divider: delay counted on a divided thread           8997
    divider: side-set on a divided thread               14455
    enable: disabled during a delay                       177
    enable: disabled during a timed wait                   44
    enable: disabled between divider ticks                196
    side-set: driven during a stall                     42230
    fifo: both threads stalled on FIFOs                  2714
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
    Xdec_never_decrements        caught by program #3
    Wait_timeout_ignores_budget  caught by program #4
    Delay_field_ignored          caught by program #1
    Set_pins_count_off_by_one    caught by program #6
    Push_not_right_justified     caught by program #16
    Pin_priority_inverted        caught by program #6
    Fetch_port_crossed           caught by program #1
    Chain_ignores_full           caught by program #9
    Push_ignores_in_direction    caught by program #11
    Sync_bypass_inverted         caught by program #1
    |}]
;;
