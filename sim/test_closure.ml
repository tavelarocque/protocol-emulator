(* Coverage closure: the directed scenarios in sim/directed.ml, judged.

   1. Every directed scenario passes the lockstep comparison against the
      reference model, under several seeds.
   2. Cross coverage: the random trials' counts for each cross bin are
      printed by test_core.ml; here the directed suite must hit every cross
      bin on its own, and every scenario must hit each bin it was written
      to reach. A generated test that misses its target fails the build.
   3. The directed suite must catch every planted RTL bug, and each
      scenario written for a bug must catch that bug. *)

open! Core
module Rtl = Pe_hw.Pe_core

let%test_unit "every directed scenario matches the reference model" =
  List.iter Directed.all ~f:(fun d ->
    List.iter Directed.seeds ~f:(fun seed ->
      match Directed.run d ~seed with
      | None -> ()
      | Some divergence -> raise_s divergence))
;;

let%expect_test "cross coverage of the directed suite, and each scenario's targets" =
  let total = Lockstep.create_coverage () in
  List.iter Directed.all ~f:(fun d ->
    let mine = Lockstep.create_coverage () in
    List.iter Directed.seeds ~f:(fun seed ->
      ignore (Directed.run ~coverage:mine d ~seed : Sexp.t option);
      ignore (Directed.run ~coverage:total d ~seed : Sexp.t option));
    let cross_targets =
      List.filter d.target ~f:(List.mem Lockstep.all_cross_bins ~equal:String.equal)
    in
    let missed = List.filter cross_targets ~f:(fun t -> not (Hashtbl.mem mine.cross t)) in
    if not (List.is_empty missed)
    then
      raise_s
        [%message
          "directed scenario missed its targets"
            ~scenario:(d.scenario.name : string)
            (missed : string list)]);
  List.iter Lockstep.all_cross_bins ~f:(fun bin ->
    let n = Hashtbl.find total.cross bin |> Option.value ~default:0 in
    if n = 0 then raise_s [%message "cross bin not closed" (bin : string)];
    printf "%-50s %6d\n" bin n);
  [%expect {|
    pins: both threads write the same pin                 399
    chain: move into thread 1 TX holding 0                 12
    chain: move into thread 1 TX holding 1                 36
    chain: move into thread 1 TX holding 2                 33
    chain: move into thread 1 TX holding 3               1230
    chain: move in a cycle thread 1 pulls                 420
    chain: move in a cycle thread 0 pushes                558
    chain: thread 0 PUSH stalled behind a full chain     1626
    divider: timed wait expires on a divided thread        42
    divider: delay counted on a divided thread            534
    divider: side-set on a divided thread                 780
    enable: disabled during a delay                         9
    enable: disabled during a timed wait                    6
    enable: disabled between divider ticks                  6
    side-set: driven during a stall                       351
    fifo: both threads stalled on FIFOs                  1176
    |}]
;;

let%expect_test "the directed suite catches every planted bug" =
  List.iter Rtl.Mutation.all ~f:(fun mutation ->
    let name = Sexp.to_string (Rtl.Mutation.sexp_of_t mutation) in
    let catches (d : Directed.t) =
      List.exists Directed.seeds ~f:(fun seed ->
        Option.is_some (Directed.run ~mutation d ~seed))
    in
    (* The scenarios written for this bug must catch it... *)
    List.iter Directed.all ~f:(fun d ->
      if List.mem d.target name ~equal:String.equal && not (catches d)
      then
        raise_s
          [%message "scenario missed the bug it targets" ~scenario:(d.scenario.name : string) name]);
    (* ...and the report shows every scenario that does. *)
    let catchers = List.filter Directed.all ~f:catches in
    if List.is_empty catchers then raise_s [%message "mutant survived" name];
    printf "%-28s caught by %d of %d\n" name (List.length catchers) (List.length Directed.all));
  [%expect {|
    Xdec_never_decrements        caught by 2 of 19
    Wait_timeout_ignores_budget  caught by 3 of 19
    Delay_field_ignored          caught by 5 of 19
    Set_pins_count_off_by_one    caught by 4 of 19
    Push_not_right_justified     caught by 3 of 19
    Pin_priority_inverted        caught by 1 of 19
    Fetch_port_crossed           caught by 19 of 19
    Chain_ignores_full           caught by 3 of 19
    Push_ignores_in_direction    caught by 1 of 19
    Sync_bypass_inverted         caught by 3 of 19
    Jump_ignores_page            caught by 1 of 19
    Write_lands_while_running    caught by 1 of 19
    No_hold_after_write          caught by 1 of 19
    Autopull_ignores_empty       caught by 1 of 19
    Autopush_ignores_full        caught by 2 of 19
    Crc_ignores_direction        caught by 1 of 19
    Crc_read_keeps_running       caught by 1 of 19
    Play_ignores_full            caught by 2 of 19
    Play_past_end                caught by 2 of 19
    Record_keeps_host_pop        caught by 1 of 19
    Play_after_write             caught by 1 of 19
    Sampler_samples_swapped      caught by 1 of 19
    Sampler_blank_one_short      caught by 1 of 19
    Sampler_passes_before_sync   caught by 1 of 19
    Sampler_keeps_carrier        caught by 1 of 19
    Sampler_pulse_on_wrong_pin   caught by 2 of 19
    Sampler_prescale_one_long    caught by 1 of 19
    Sampler_prescaled_takes_both caught by 1 of 19
    Sampler_shift_ignored        caught by 1 of 19
    Sampler_pulse_not_held       caught by 1 of 19
    Sampler_stuff_one_late       caught by 1 of 19
    Sampler_stuff_drops_any      caught by 1 of 19
    Sampler_stuff_bit_not_counted caught by 2 of 19
    |}]
;;
