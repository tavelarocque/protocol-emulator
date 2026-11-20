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
    ; "mov to crc"; "mov from crc"
    ; "in: waiting, RX full (autopush)"; "in: filled the ISR and pushed it (autopush)"
    ; "out: waiting for a word (autopull)"; "out: fetched a word (autopull)"
    ; "out: emptied the OSR and refilled it (autopull)"
    ; "mov (reserved -> nop)"; "set pins"; "set x"; "set y"
    ; "set page"; "nop"; "(delay cycle)"; "(side-set driving pins)"
    ; "(thread disabled)"; "(both threads enabled)"
    ; "(program write to a stopped thread)"
    ; "(program write to a running thread: ignored)"
    ; "(held: memory written last cycle)"
    ; "(both threads drive pins in one cycle)"; "(between divider ticks)"
    ; "(chain moved a word)"; "(chain blocked: thread 1 TX full)"
    ; "(buffer played a word)"; "(buffer recorded a word)"; "(buffer: at its end)"
    ; "(buffer: play waits, TX full)"; "(buffer: the chain owns that FIFO)"
    ; "(buffer: no play in the cycle after a write)"
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
    (between divider ticks)                   57812   12.0%
    (both threads drive pins in one cycle)    11394    2.4%
    (both threads enabled)                   103793   21.6%
    (buffer played a word)                     1038    0.2%
    (buffer recorded a word)                    542    0.1%
    (buffer: at its end)                       4651    1.0%
    (buffer: no play in the cycle after a write)      2    0.0%
    (buffer: play waits, TX full)             26657    5.6%
    (buffer: the chain owns that FIFO)        10265    2.1%
    (chain blocked: thread 1 TX full)          4430    0.9%
    (chain moved a word)                        331    0.1%
    (delay cycle)                             37546    7.8%
    (held: memory written last cycle)           139    0.0%
    (program write to a running thread: ignored)   1119    0.2%
    (program write to a stopped thread)        2824    0.6%
    (side-set driving pins)                   72901   15.2%
    (thread disabled)                         16845    3.5%
    in null                                    1109    0.2%
    in pins                                    1041    0.2%
    in x                                       1152    0.2%
    in y                                       1075    0.2%
    in: filled the ISR and pushed it (autopush)    903    0.2%
    in: waiting, RX full (autopush)            3626    0.8%
    jmp !isrf                                   859    0.2%
    jmp !osre                                   702    0.1%
    jmp !x                                      812    0.2%
    jmp !y                                     1016    0.2%
    jmp (always)                               1566    0.3%
    jmp x!=y                                   1022    0.2%
    jmp x--                                     647    0.1%
    jmp y--                                    1058    0.2%
    mov (reserved -> nop)                      1259    0.3%
    mov from crc                                448    0.1%
    mov to crc                                  652    0.1%
    mov to isr                                  547    0.1%
    mov to null                                 540    0.1%
    mov to osr                                  445    0.1%
    mov to pins                                 525    0.1%
    mov to x                                    423    0.1%
    mov to y                                    535    0.1%
    nop                                        4795    1.0%
    out null                                    998    0.2%
    out pins                                    945    0.2%
    out x                                      1033    0.2%
    out y                                       961    0.2%
    out: emptied the OSR and refilled it (autopull)    790    0.2%
    out: fetched a word (autopull)              211    0.0%
    out: waiting for a word (autopull)        10205    2.1%
    pull                                       2406    0.5%
    pull: stalled, TX empty                   19940    4.2%
    push                                       2377    0.5%
    push: stalled, RX full                     6907    1.4%
    set page                                    897    0.2%
    set pins                                   1176    0.2%
    set x                                      1331    0.3%
    set y                                      1268    0.3%
    wait: condition met                        3650    0.8%
    wait: stalled                             32473    6.8%
    wait: stalled, spending timeout budget    11524    2.4%
    wait: timed out                            1809    0.4%

    pins: both threads write the same pin                5541
    chain: move into thread 1 TX holding 0                165
    chain: move into thread 1 TX holding 1                 56
    chain: move into thread 1 TX holding 2                 41
    chain: move into thread 1 TX holding 3                 69
    chain: move in a cycle thread 1 pulls                   6
    chain: move in a cycle thread 0 pushes                  4
    chain: thread 0 PUSH stalled behind a full chain     1152
    divider: timed wait expires on a divided thread       430
    divider: delay counted on a divided thread          10247
    divider: side-set on a divided thread               15533
    enable: disabled during a delay                       181
    enable: disabled during a timed wait                   64
    enable: disabled between divider ticks                187
    side-set: driven during a stall                     38621
    fifo: both threads stalled on FIFOs                  1476
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
    Wait_timeout_ignores_budget  caught by program #3
    Delay_field_ignored          caught by program #1
    Set_pins_count_off_by_one    caught by program #1
    Push_not_right_justified     caught by program #7
    Pin_priority_inverted        caught by program #1
    Fetch_port_crossed           caught by program #1
    Chain_ignores_full           caught by program #1
    Push_ignores_in_direction    caught by program #8
    Sync_bypass_inverted         caught by program #1
    Jump_ignores_page            caught by program #1
    Write_lands_while_running    caught by program #1
    No_hold_after_write          caught by program #2
    Autopull_ignores_empty       caught by program #2
    Autopush_ignores_full        caught by program #85
    Crc_ignores_direction        caught by program #1
    Crc_read_keeps_running       caught by program #3
    Play_ignores_full            caught by program #1
    Play_past_end                caught by program #20
    Record_keeps_host_pop        caught by program #24
    Play_after_write             caught by program #140
    |}]
;;
