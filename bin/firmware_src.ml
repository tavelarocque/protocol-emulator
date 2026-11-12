(* Prints one firmware from model/firmware.ml as a standalone assembly file:
   the comment that documents it there (pins, configuration, host words) as
   ';' lines, then the program. examples/ is generated with this, so the
   files there cannot drift from the firmware the tests run.

   Usage: firmware_src.exe NAME path/to/firmware.ml *)

open! Core

let () =
  let argv = Sys.get_argv () in
  let name = argv.(1) in
  let source = In_channel.read_all argv.(2) in
  let program = List.Assoc.find_exn Pe_model.Firmware.all name ~equal:String.equal in
  (* The definition, then the comment block that ends just above it. *)
  let def =
    List.find_map_exn
      [ sprintf "\nlet %s =" name; sprintf "\nlet %s ~" name ]
      ~f:(fun pattern -> String.substr_index source ~pattern)
  in
  let before = String.prefix source def in
  let doc =
    match String.substr_index_all before ~may_overlap:false ~pattern:"\n(*" |> List.last with
    | Some start
      when String.is_suffix (String.rstrip before) ~suffix:"*)"
           && not (String.is_substring (String.drop_prefix before (start + 1)) ~substring:"\nlet ")
      ->
      let text = String.drop_prefix before (start + 3) |> String.rstrip in
      String.chop_suffix_exn text ~suffix:"*)" |> String.rstrip
    | _ -> ""
  in
  printf "; %s: generated from model/firmware.ml by bin/firmware_src.ml.\n" name;
  printf "; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]\n";
  printf "; are definitions in model/firmware.ml.\n;\n";
  String.split_lines doc
  |> List.iter ~f:(fun line ->
    let line = if String.is_prefix line ~prefix:"   " then String.drop_prefix line 3 else String.lstrip line in
    printf "%s\n" (String.rstrip ("; " ^ line)));
  let body = String.split_lines program |> List.drop_while ~f:(fun l -> String.is_empty (String.strip l)) in
  List.iter body ~f:(fun l -> printf "%s\n" (String.rstrip l))
;;
