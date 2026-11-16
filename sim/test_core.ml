(* Differential test: the Hardcaml core against the ISA reference model, on
   random programs. The harness is sim/lockstep.ml.

   Each trial draws a random program for each thread (uniformly random 16-bit words, so
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
    ; "set page"; "nop"; "(delay cycle)"; "(side-set driving pins)"
    ; "(thread disabled)"; "(both threads enabled)"
    ; "(program write to a stopped thread)"
    ; "(program write to a running thread: ignored)"
    ; "(held: memory written last cycle)"
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
    (between divider ticks)                   55935   12.8%
    (both threads drive pins in one cycle)    12223    2.8%
    (both threads enabled)                   104055   23.9%
    (chain blocked: thread 1 TX full)          2670    0.6%
    (chain moved a word)                        282    0.1%
    (delay cycle)                             36383    8.3%
    (held: memory written last cycle)           145    0.0%
    (program write to a running thread: ignored)   1071    0.2%
    (program write to a stopped thread)        2754    0.6%
    (side-set driving pins)                   72739   16.7%
    (thread disabled)                         16453    3.8%
    in null                                    1483    0.3%
    in pins                                    1129    0.3%
    in x                                       1381    0.3%
    in y                                       1254    0.3%
    jmp !isrf                                  1176    0.3%
    jmp !osre                                  1133    0.3%
    jmp !x                                      741    0.2%
    jmp !y                                     1413    0.3%
    jmp (always)                               1367    0.3%
    jmp x!=y                                   1038    0.2%
    jmp x--                                     736    0.2%
    jmp y--                                     972    0.2%
    mov (reserved -> nop)                      2600    0.6%
    mov to isr                                  559    0.1%
    mov to null                                 619    0.1%
    mov to osr                                  415    0.1%
    mov to pins                                 547    0.1%
    mov to x                                    407    0.1%
    mov to y                                    398    0.1%
    nop                                        5529    1.3%
    out null                                   1557    0.4%
    out pins                                   1204    0.3%
    out x                                      1278    0.3%
    out y                                      1246    0.3%
    pull                                       2496    0.6%
    pull: stalled, TX empty                   31237    7.2%
    push                                       2422    0.6%
    push: stalled, RX full                     5474    1.3%
    set page                                   1084    0.2%
    set pins                                   1251    0.3%
    set x                                      1269    0.3%
    set y                                      1245    0.3%
    wait: condition met                        3988    0.9%
    wait: stalled                             37163    8.5%
    wait: stalled, spending timeout budget    11754    2.7%
    wait: timed out                            1519    0.3%

    pins: both threads write the same pin                6295
    chain: move into thread 1 TX holding 0                127
    chain: move into thread 1 TX holding 1                 61
    chain: move into thread 1 TX holding 2                 39
    chain: move into thread 1 TX holding 3                 55
    chain: move in a cycle thread 1 pulls                   1
    chain: move in a cycle thread 0 pushes                  7
    chain: thread 0 PUSH stalled behind a full chain     1046
    divider: timed wait expires on a divided thread       216
    divider: delay counted on a divided thread           9756
    divider: side-set on a divided thread               14486
    enable: disabled during a delay                       163
    enable: disabled during a timed wait                   39
    enable: disabled between divider ticks                190
    side-set: driven during a stall                     45049
    fifo: both threads stalled on FIFOs                  3442
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
    Xdec_never_decrements        caught by program #1
    Wait_timeout_ignores_budget  caught by program #1
    Delay_field_ignored          caught by program #1
    Set_pins_count_off_by_one    caught by program #5
    Push_not_right_justified     caught by program #11
    Pin_priority_inverted        caught by program #11
    Fetch_port_crossed           caught by program #1
    Chain_ignores_full           caught by program #24
    Push_ignores_in_direction    caught by program #27
    Sync_bypass_inverted         caught by program #1
    Jump_ignores_page            caught by program #1
    Write_lands_while_running    caught by program #1
    No_hold_after_write          caught by program #2
    |}]
;;
