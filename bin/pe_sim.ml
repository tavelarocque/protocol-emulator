(* Command-line tools for writing firmware without the rest of the project:

     pe_sim asm PROGRAM.s
       assembles PROGRAM.s and prints one hex word per line, as the
       firmware images in test/ are

     pe_sim run PROGRAM.s [-config k=v,...] [-mode P=pp|od|in ...]
                [-tx FILE] [-cycles N] [-inputs HEX] [-stimulus FILE]
       runs it on thread 0 of the reference model (model/isa.ml, the model
       the RTL is checked against every cycle). TX words (one per line,
       decimal or 0x hex) are pushed whenever the TX FIFO has room. Prints
       every change of the 8 protocol pins' output as "pins CYCLE XX" (bit
       k = pin Pk as driven; an open-drain 1 and an input read as 1), and
       every word the thread pushes as "rx CYCLE WORD". Pins that are inputs
       read [-inputs] (default 0xFF). [-stimulus FILE] changes those levels
       as the run goes: each line is "CYCLE HEX", meaning that from that
       cycle on the input pins read HEX (bit k = pin Pk), until the next
       line's cycle. Lines must be in increasing cycle order; blank lines
       and lines starting with # are skipped.

       [-lines] prints the level on each wire instead, as "lines CYCLE XX":
       inputs as the stimulus has them, open-drain pins as the wired AND.
       [-bypass HEX] sets SYNC_BYPASS: those input pins are read without
       the two-cycle synchroniser. [-thread1 PROGRAM.s] runs a second
       program on thread 1, from its own program memory, with [-config1]
       and [-tx1]; its RX words print as "rx1 CYCLE WORD".

     The run itself is Pe_model.Sim_run (model/sim_run.ml), which the
     playground (docs/playground.html) runs too, compiled to JavaScript.

   -config keys are the thread configuration's fields, as in docs/isa.md:
   start, out_base, out_count, set_base, set_count, in_base, threshold,
   timeout_vector, timeout, sideset_base, sideset_count, clkdiv,
   out_msb_first, in_msb_first (0 or 1). *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Sim_run = Pe_model.Sim_run

let asm_cmd =
  Command.basic
    ~summary:"assemble a program; one hex word per line"
    (let%map_open.Command file = anon ("PROGRAM.s" %: string) in
     fun () ->
       Array.iter (Asm.assemble (In_channel.read_all file)) ~f:(fun i ->
         printf "%04x\n" (Isa.Instruction.encode i)))
;;

let run_cmd =
  Command.basic
    ~summary:"run a program on the reference model"
    (let%map_open.Command file = anon ("PROGRAM.s" %: string)
     and config =
       flag
         "-config"
         (optional_with_default "" string)
         ~doc:
           "k=v,... thread config: start out_base out_count set_base set_count in_base \
            threshold timeout_vector timeout sideset_base sideset_count clkdiv \
            out_msb_first in_msb_first autopull autopush crc_poly crc_init crc_invert crc_in"
     and modes = flag "-mode" (listed string) ~doc:"P=pp|od|in pin mode (default in)"
     and tx = flag "-tx" (optional string) ~doc:"FILE TX words, one per line"
     and cycles = flag "-cycles" (optional_with_default 100_000 int) ~doc:"N cycles to run"
     and inputs = flag "-inputs" (optional_with_default "0xFF" string) ~doc:"HEX input pin levels"
     and stimulus =
       flag
         "-stimulus"
         (optional string)
         ~doc:"FILE input pin levels over time, one \"CYCLE HEX\" per line"
     and lines =
       flag
         "-lines"
         no_arg
         ~doc:" print the level on each wire (\"lines CYCLE XX\") instead of the output register"
     and bypass =
       flag
         "-bypass"
         (optional_with_default "0" string)
         ~doc:"HEX input pins read without the two-cycle synchroniser (SYNC_BYPASS)"
     and thread1 =
       flag "-thread1" (optional string) ~doc:"PROGRAM.s run this on thread 1 too, from its own memory"
     and config1 =
       flag "-config1" (optional_with_default "" string) ~doc:"k=v,... thread 1's config"
     and tx1 = flag "-tx1" (optional string) ~doc:"FILE thread 1's TX words (its RX words print as rx1)"
     in
     fun () ->
       let read_words = Option.value_map ~default:[] ~f:(fun f -> Sim_run.words_of_string (In_channel.read_all f)) in
       let thread file config tx =
         { Sim_run.program = Asm.assemble (In_channel.read_all file)
         ; config = Sim_run.config_of_string config
         ; tx = read_words tx
         }
       in
       Sim_run.run
         ~lines
         ~sync_bypass:(Sim_run.parse_int bypass)
         ~threads:
           (thread file config tx
            :: Option.value_map thread1 ~default:[] ~f:(fun f -> [ thread f config1 tx1 ]))
         ~pin_modes:(Sim_run.modes_of_flags modes)
         ~cycles
         ~inputs:(Sim_run.parse_int inputs)
         ~stimulus:
           (Option.value_map stimulus ~default:[] ~f:(fun f ->
              Sim_run.stimulus_of_string (In_channel.read_all f)))
         ~emit:print_endline
         ())
;;

let () =
  Command_unix.run
    (Command.group ~summary:"protocol emulator firmware tools" [ "asm", asm_cmd; "run", run_cmd ])
;;
