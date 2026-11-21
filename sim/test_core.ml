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
    ; "(sampler: edge accepted)"; "(sampler: edge accepted: carrier found)"
    ; "(sampler: edge ignored)"; "(sampler: bit time without an edge: carried on)"
    ; "(sampler: bit time without an edge: carrier lost)"; "(sampler: bit passed on)"
    ; "(sampler: bit held back before the sync word)"; "(sampler: sync word seen)"
    ; "(sampler: both samples of a cycle are bits)"; "(sampler: a WAIT sees its pulse)"
    ; "(sampler: a WAIT sees no pulse)"; "(sampler: a WAIT looks at its bit)"
    ; "(sampler: an IN takes its bit)"; "(sampler: prescaled: a sample)"
    ; "(sampler: prescaled: a cycle between samples)"
    ; "(sampler: looked at on pins shifted from its input)"
    ; "(sampler: stuff bit taken out)"; "(sampler: a run longer than the stuffing allows)"
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
    (between divider ticks)                   58110    9.3%
    (both threads drive pins in one cycle)    10924    1.8%
    (both threads enabled)                   104850   16.9%
    (buffer played a word)                     1745    0.3%
    (buffer recorded a word)                    276    0.0%
    (buffer: at its end)                       5259    0.8%
    (buffer: no play in the cycle after a write)    195    0.0%
    (buffer: play waits, TX full)             44567    7.2%
    (buffer: the chain owns that FIFO)        12906    2.1%
    (chain blocked: thread 1 TX full)          4781    0.8%
    (chain moved a word)                        360    0.1%
    (delay cycle)                             39015    6.3%
    (held: memory written last cycle)           134    0.0%
    (program write to a running thread: ignored)   1100    0.2%
    (program write to a stopped thread)        2617    0.4%
    (sampler: a WAIT looks at its bit)         6211    1.0%
    (sampler: a WAIT sees its pulse)             77    0.0%
    (sampler: a WAIT sees no pulse)            5454    0.9%
    (sampler: a run longer than the stuffing allows)    266    0.0%
    (sampler: an IN takes its bit)              233    0.0%
    (sampler: bit held back before the sync word)   1871    0.3%
    (sampler: bit passed on)                   3214    0.5%
    (sampler: bit time without an edge: carried on)   5015    0.8%
    (sampler: bit time without an edge: carrier lost)   1017    0.2%
    (sampler: both samples of a cycle are bits)     27    0.0%
    (sampler: edge accepted)                  10262    1.7%
    (sampler: edge accepted: carrier found)    1360    0.2%
    (sampler: edge ignored)                   30197    4.9%
    (sampler: looked at on pins shifted from its input)   3567    0.6%
    (sampler: prescaled: a cycle between samples)  29194    4.7%
    (sampler: prescaled: a sample)            20541    3.3%
    (sampler: stuff bit taken out)              325    0.1%
    (sampler: sync word seen)                   184    0.0%
    (side-set driving pins)                   73245   11.8%
    (thread disabled)                         15746    2.5%
    in null                                    1033    0.2%
    in pins                                    1107    0.2%
    in x                                       1124    0.2%
    in y                                       1082    0.2%
    in: filled the ISR and pushed it (autopush)    929    0.1%
    in: waiting, RX full (autopush)            4735    0.8%
    jmp !isrf                                  1067    0.2%
    jmp !osre                                   592    0.1%
    jmp !x                                      820    0.1%
    jmp !y                                     1050    0.2%
    jmp (always)                               1759    0.3%
    jmp x!=y                                    883    0.1%
    jmp x--                                     709    0.1%
    jmp y--                                    1105    0.2%
    mov (reserved -> nop)                      1230    0.2%
    mov from crc                                506    0.1%
    mov to crc                                  755    0.1%
    mov to isr                                  504    0.1%
    mov to null                                 559    0.1%
    mov to osr                                  429    0.1%
    mov to pins                                 575    0.1%
    mov to x                                    440    0.1%
    mov to y                                    577    0.1%
    nop                                        4935    0.8%
    out null                                    943    0.2%
    out pins                                    864    0.1%
    out x                                      1013    0.2%
    out y                                       956    0.2%
    out: emptied the OSR and refilled it (autopull)    851    0.1%
    out: fetched a word (autopull)              225    0.0%
    out: waiting for a word (autopull)         8696    1.4%
    pull                                       2548    0.4%
    pull: stalled, TX empty                   18723    3.0%
    push                                       2469    0.4%
    push: stalled, RX full                     6153    1.0%
    set page                                   1089    0.2%
    set pins                                   1124    0.2%
    set x                                      1312    0.2%
    set y                                      1416    0.2%
    wait: condition met                        3681    0.6%
    wait: stalled                             34533    5.6%
    wait: stalled, spending timeout budget     9971    1.6%
    wait: timed out                            1923    0.3%

    pins: both threads write the same pin                5248
    chain: move into thread 1 TX holding 0                179
    chain: move into thread 1 TX holding 1                 58
    chain: move into thread 1 TX holding 2                 45
    chain: move into thread 1 TX holding 3                 78
    chain: move in a cycle thread 1 pulls                   3
    chain: move in a cycle thread 0 pushes                  4
    chain: thread 0 PUSH stalled behind a full chain     1040
    divider: timed wait expires on a divided thread       450
    divider: delay counted on a divided thread          10447
    divider: side-set on a divided thread               15374
    enable: disabled during a delay                       198
    enable: disabled during a timed wait                   43
    enable: disabled between divider ticks                211
    side-set: driven during a stall                     38071
    fifo: both threads stalled on FIFOs                  1029
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
    Push_not_right_justified     caught by program #5
    Pin_priority_inverted        caught by program #1
    Fetch_port_crossed           caught by program #1
    Chain_ignores_full           caught by program #1
    Push_ignores_in_direction    caught by program #8
    Sync_bypass_inverted         caught by program #1
    Jump_ignores_page            caught by program #1
    Write_lands_while_running    caught by program #1
    No_hold_after_write          caught by program #6
    Autopull_ignores_empty       caught by program #2
    Autopush_ignores_full        caught by program #11
    Crc_ignores_direction        caught by program #1
    Crc_read_keeps_running       caught by program #7
    Play_ignores_full            caught by program #1
    Play_past_end                caught by program #23
    Record_keeps_host_pop        caught by program #23
    Play_after_write             caught by program #8
    Sampler_samples_swapped      caught by program #1
    Sampler_blank_one_short      caught by program #1
    Sampler_passes_before_sync   caught by program #2
    Sampler_keeps_carrier        caught by program #2
    Sampler_pulse_on_wrong_pin   caught by program #4
    Sampler_prescale_one_long    caught by program #1
    Sampler_prescaled_takes_both caught by program #1
    Sampler_shift_ignored        caught by program #1
    Sampler_pulse_not_held       caught by program #2
    Sampler_stuff_one_late       caught by program #1
    Sampler_stuff_drops_any      caught by program #1
    Sampler_stuff_bit_not_counted caught by program #1
    |}]
;;
