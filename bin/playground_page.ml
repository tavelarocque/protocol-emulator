(* The playground (docs/playground.html): the firmware the tests run, with
   the configuration, TX words and stimulus each test gives it, and the
   reference model compiled to JavaScript to run them in the browser.

     playground_page.exe presets EXAMPLES_DIR test.py ws2812.tx > presets.json
       the presets, each checked here on the native model first: a run
       whose pins the test's own receiver cannot read stops the build
     playground_page.exe page page.html pe_js.js plex.css presets.json > playground.html

   Every program is the text of its examples/*.s file, which is generated
   from model/firmware.ml. Configurations and TX words come from
   model/firmware.ml and from the tests in sim/, so they cannot drift from
   what the tests run. Where the test puts a device on the pins (an I2C
   target, an SPI device) the device runs here, on the native model, and
   what it drove is recorded as the preset's stimulus: in the browser it is
   a recording, which follows the firmware only as long as the firmware's
   timing is unchanged. playground/exact.js runs every preset both here
   (native pe_sim) and in JavaScript and requires the same output. *)

open! Core
module Isa = Pe_model.Isa
module Asm = Pe_model.Asm
module Firmware = Pe_model.Firmware
module Sim_run = Pe_model.Sim_run
module Uart_model = Pe_model.Uart_model
module I2c = Pe_model.I2c_model
module Spi = Pe_model.Spi_model
module Tx = Pe_test.Test_tx_engines

let repo = "https://github.com/tavelarocque/protocol-emulator/blob/main/"
let sigrok = "https://github.com/sigrokproject/libsigrokdecode/tree/master/decoders/"

module Json = struct
  type t =
    | S of string
    | I of int
    | B of bool
    | L of t list
    | O of (string * t) list

  let escape s =
    String.concat_map s ~f:(function
      | '"' -> "\\\""
      | '\\' -> "\\\\"
      | '\n' -> "\\n"
      | '\t' -> "\\t"
      | '<' -> "\\u003c" (* so no text can close the page's script element *)
      | c when Char.to_int c < 0x20 -> sprintf "\\u%04x" (Char.to_int c)
      | c -> String.make 1 c)
  ;;

  let rec to_string = function
    | S s -> "\"" ^ escape s ^ "\""
    | I i -> Int.to_string i
    | B b -> Bool.to_string b
    | L l -> "[" ^ String.concat ~sep:"," (List.map l ~f:to_string) ^ "]"
    | O o ->
      "{\n"
      ^ String.concat
          ~sep:",\n"
          (List.map o ~f:(fun (k, v) -> to_string (S k) ^ ":" ^ to_string v))
      ^ "}"
  ;;
end

open Json

type thread =
  { firmware : string (* examples/<firmware>.s *)
  ; config : Isa.Thread_config.t
  ; words : (int * string) list (* TX words, and what each means *)
  }

type preset =
  { id : string
  ; title : string
  ; spec : string (* one line under the title in the picker *)
  ; clock_hz : int
  ; cycles : int
  ; inputs : int
  ; bypass : int
  ; modes : (int * Isa.Pin_mode.t) list
  ; pins : (int * string) list
  ; threads : thread list
  ; stimulus : (int * int) list
  ; stimulus_note : string
  ; what : string
  ; model_test : string (* sim/test_*.ml *)
  ; chip_test : string (* a test function in test/test.py *)
  ; decoder : string * string (* name, link *)
  }

let examples = ref ""
let test_py = ref ""

let source firmware =
  let file =
    if String.equal firmware "ws2812" then "ws2812/ws2812.s" else firmware ^ ".s"
  in
  let text = In_channel.read_all (!examples ^/ file) in
  (* The example is generated from model/firmware.ml: the same program. *)
  (match List.Assoc.find Firmware.all firmware ~equal:String.equal with
   | Some fw ->
     if not
          ([%equal: Isa.Instruction.t array] (Asm.assemble text) (Asm.assemble fw))
     then failwithf "examples/%s is not the firmware in model/firmware.ml" file ()
   | None -> ());
  file, text
;;

let mode_flag (pin, (mode : Isa.Pin_mode.t)) =
  sprintf
    "%d=%s"
    pin
    (match mode with
     | Push_pull -> "pp"
     | Open_drain -> "od"
     | Input -> "in")
;;

let modes_of_array a =
  Array.to_list a
  |> List.filter_mapi ~f:(fun i (m : Isa.Pin_mode.t) ->
    match m with
    | Input -> None
    | m -> Some (i, m))
;;

let tx_text words =
  String.concat
    (List.map words ~f:(fun (w, meaning) ->
       (if String.is_empty meaning then "" else "# " ^ meaning ^ "\n") ^ Int.to_string w ^ "\n"))
;;

let stimulus_text ~note changes =
  (if String.is_empty note then "" else "# " ^ note ^ "\n")
  ^ String.concat (List.map changes ~f:(fun (c, v) -> sprintf "%d %02x\n" c v))
;;

(* Run-length: the cycles at which a per-cycle list of levels changes. *)
let changes_of levels =
  List.foldi levels ~init:[] ~f:(fun c acc v ->
    match acc with
    | (_, last) :: _ when last = v -> acc
    | _ -> (c, v) :: acc)
  |> List.rev
;;

(* A preset run natively, exactly as pe_sim and the playground run it:
   the output lines. *)
let run_native ?(lines = true) p =
  let out = Queue.create () in
  Sim_run.run
    ~lines
    ~sync_bypass:p.bypass
    ~threads:
      (List.map p.threads ~f:(fun t ->
         { Sim_run.program = Asm.assemble (snd (source t.firmware))
         ; config = t.config
         ; tx = List.map t.words ~f:fst
         }))
    ~pin_modes:
      (Array.init Isa.num_pins ~f:(fun i ->
         List.Assoc.find p.modes i ~equal:Int.equal |> Option.value ~default:Isa.Pin_mode.Input))
    ~cycles:p.cycles
    ~inputs:p.inputs
    ~stimulus:p.stimulus
    ~emit:(Queue.enqueue out)
    ();
  Queue.to_list out
;;

(* The wire levels on every cycle, and the words each thread sent back. *)
let levels p =
  let a = Array.create ~len:p.cycles 0 in
  let rx = Array.create ~len:2 [] in
  let changes = Queue.create () in
  List.iter (run_native p) ~f:(fun line ->
    match String.split line ~on:' ' with
    | [ "lines"; c; v ] -> Queue.enqueue changes (Int.of_string c, Int.of_string ("0x" ^ v))
    | [ "rx"; _; w ] -> rx.(0) <- Int.of_string w :: rx.(0)
    | [ "rx1"; _; w ] -> rx.(1) <- Int.of_string w :: rx.(1)
    | _ -> failwithf "unexpected line %S" line ());
  let changes = Queue.to_array changes in
  Array.iteri changes ~f:(fun k (c, v) ->
    let stop = if k + 1 < Array.length changes then fst changes.(k + 1) else p.cycles in
    for i = c to stop - 1 do
      a.(i) <- v
    done);
  a, Array.map rx ~f:List.rev
;;

let pin a k = Array.map a ~f:(fun v -> (v lsr k) land 1 = 1)
let fail p what = failwithf "playground preset %s: %s" p.id what ()

(* A device on the pins, run on the native model the way the tests run it,
   recorded: what it drove on each cycle becomes the stimulus. The loop is
   Sim_run.run's: TX words in, the device's levels, a step, RX words out. *)
let record ~threads ~pin_modes ~bypass ~cycles ~drives ~sees =
  let m =
    Isa.create_separate
      ~programs:
        (Array.of_list_map threads ~f:(fun t -> Asm.assemble (snd (source t.firmware))))
      ~pin_modes
      ~threads:(List.map threads ~f:(fun t -> t.config))
  in
  Isa.set_sync_bypass m bypass;
  let pending = Array.of_list_map threads ~f:(fun t -> Queue.of_list (List.map t.words ~f:fst)) in
  let driven = Queue.create () in
  let rx = Array.create ~len:2 [] in
  for _ = 0 to cycles - 1 do
    Array.iteri pending ~f:(fun thread q ->
      match Queue.peek q with
      | Some v -> if Isa.push_tx m ~thread v then ignore (Queue.dequeue q : int option)
      | None -> ());
    let inputs = drives () in
    Queue.enqueue driven inputs;
    Isa.step m ~inputs;
    sees (Isa.lines m ~inputs);
    Array.iteri pending ~f:(fun thread _ ->
      Option.iter (Isa.pop_rx m ~thread) ~f:(fun w -> rx.(thread) <- w :: rx.(thread)))
  done;
  changes_of (Queue.to_list driven), Array.map rx ~f:List.rev
;;

(* The replay of a recording must give the host what the device run did. *)
let check_replay p rx =
  let _, got = levels p in
  if not ([%equal: int list array] got rx) then fail p "the recorded stimulus does not replay"
;;

let base =
  { id = ""
  ; title = ""
  ; spec = ""
  ; clock_hz = 10_000_000
  ; cycles = 0
  ; inputs = 0xFF
  ; bypass = 0
  ; modes = []
  ; pins = []
  ; threads = []
  ; stimulus = []
  ; stimulus_note = ""
  ; what = ""
  ; model_test = ""
  ; chip_test = ""
  ; decoder = "", ""
  }
;;

(* ------------------------------------------------------------- presets *)

let uart () =
  let divisor = 87 in
  let text = "Hello" in
  let bytes = List.map (String.to_list text) ~f:Char.to_int in
  let p =
    { base with
      id = "uart"
    ; title = "UART"
    ; spec = "115,200 baud, 8N1"
    ; cycles = ((List.length bytes * 10) + 6) * divisor
    ; modes = Sim_run.modes_of_flags [ "0=pp" ] |> modes_of_array
    ; pins = [ 0, "TX" ]
    ; threads =
        [ { firmware = "uart_tx"
          ; config = Firmware.Uart_duplex.tx_config
          ; words =
              List.map (Firmware.Uart_duplex.tx_setup ~divisor) ~f:(fun w ->
                w, sprintf "bit time: %d clocks, less 4" divisor)
              @ List.map bytes ~f:(fun b -> b, sprintf "'%c'" (Char.of_int_exn b))
          }
        ]
    ; what =
        "Fifteen instructions send serial text. The host gives the bit time once, then a byte \
         a word; the thread makes the start bit, eight data bits and the stop bit by counting \
         clocks. Change the first word to change the baud rate."
    ; model_test = "sim/test_uart_tx.ml"
    ; chip_test = "test_midi"
    ; decoder = "uart", sigrok ^ "uart"
    }
  in
  let a, _ = levels p in
  (match Uart_model.decode ~divisor (Array.to_list (pin a 0)) with
   | Ok got when [%equal: int list] got bytes -> ()
   | _ -> fail p "the UART receiver model does not read the text back");
  p
;;

let spi () =
  let module T = Pe_test.Test_spi_fw in
  let sent = [ 0x9F; 0x00; 0x00; 0x00 ] in
  let responses = [ 0xFF; 0xEF; 0x40; 0x18 ] in
  let threads =
    [ { firmware = "spi_fast"
      ; config = T.fast_config
      ; words =
          List.map2_exn (T.transfer sent) sent ~f:(fun w b ->
            w, sprintf "0x%02X bit-reversed%s" b (if w land 0x100 <> 0 then ", last byte: deselect after" else ""))
      }
    ]
  in
  let cycles = 60 + (30 * List.length sent) in
  let bypass = 0b100 in
  let slave = Spi.Slave.create ~responses in
  let stimulus, rx =
    record
      ~threads
      ~pin_modes:T.modes
      ~bypass
      ~cycles
      ~drives:(fun () -> 0xFF land lnot (Bool.to_int (not (Spi.Slave.miso slave)) lsl 2))
      ~sees:(fun l ->
        Spi.Slave.step slave ~sck:(l land 1 = 1) ~mosi:((l lsr 1) land 1 = 1) ~cs_n:((l lsr 3) land 1 = 1))
  in
  if not ([%equal: int list] (Spi.Slave.received slave) sent) then failwith "spi: the device did not receive the bytes";
  if not ([%equal: int list] (List.map rx.(0) ~f:(fun v -> Firmware.reverse_byte (v land 0xFF))) responses)
  then failwith "spi: the host did not get the device's answers";
  let p =
    { base with
      id = "spi"
    ; title = "SPI"
    ; spec = "5 Mbit/s, mode 0, a flash's JEDEC ID read"
    ; cycles
    ; bypass
    ; modes = modes_of_array T.modes
    ; pins = [ 0, "SCK"; 1, "MOSI"; 2, "MISO"; 3, "CS_N" ]
    ; threads
    ; stimulus
    ; stimulus_note = "MISO as the test's SPI device drove it (model/spi_model.ml), recorded"
    ; what =
        "Side-set SPI: SCK comes from the delay field of every instruction, so a bit is two \
         instructions and the clock is the core clock over two. The host sends 0x9F, a flash \
         chip's read-ID command, and three dummy bytes; the device answers EF 40 18. MISO is \
         read without the synchroniser (-bypass 0x04), as the firmware's notes require."
    ; model_test = "sim/test_spi_fw.ml"
    ; chip_test = "test_spi_flash_commands"
    ; decoder = "spi", sigrok ^ "spi"
    }
  in
  check_replay p rx;
  p
;;

let i2c () =
  let module T = Pe_test.Test_i2c in
  let address = 0x50 in
  let clkdiv = 17 in
  let words =
    List.map (T.write_words ~address ~bytes:[ 0x10 ]) ~f:(fun w -> w, "")
    @ List.map (T.read_words ~address ~count:2) ~f:(fun w -> w, "")
  in
  let words =
    List.mapi words ~f:(fun i (w, _) ->
      ( w
      , match i with
        | 0 -> "START, address 0x50 write"
        | 1 -> "register 0x10, then STOP"
        | 2 -> "START, address 0x50 read"
        | 3 -> "read a byte, ACK it"
        | _ -> "read a byte, NACK it, STOP" ))
  in
  let threads = [ { firmware = "i2c"; config = { Firmware.i2c_config with clkdiv }; words } ] in
  let stretch = 30 in
  let cycles =
    T.budget ~clkdiv ~bytes:1 ~stretch + T.budget ~clkdiv ~bytes:2 ~stretch
  in
  let target = I2c.Target.create ~to_send:[ 0xCA; 0xFE ] ~address ~stretch () in
  let stimulus, rx =
    record
      ~threads
      ~pin_modes:T.modes
      ~bypass:0
      ~cycles
      ~drives:(fun () ->
        let sda, scl = I2c.Target.drive target in
        0xFF land lnot (Bool.to_int sda lor (Bool.to_int scl lsl 1)))
      ~sees:(fun l -> I2c.Target.step target ~sda:(l land 1 = 1) ~scl:((l lsr 1) land 1 = 1))
  in
  if not ([%equal: int list] (I2c.Target.received target) [ 0x10 ])
  then failwith "i2c: the target did not receive the register";
  let p =
    { base with
      id = "i2c"
    ; title = "I2C"
    ; spec = "98 kHz, a register read with clock stretching"
    ; cycles
    ; modes = modes_of_array T.modes
    ; pins = [ 0, "SDA"; 1, "SCL" ]
    ; threads
    ; stimulus
    ; stimulus_note =
        "SDA and SCL as the test's I2C target pulled them low (model/i2c_model.ml), recorded"
    ; what =
        "An I2C controller timed by the clock divider (CLKDIV 17: 98 kHz at 10 MHz). It \
         writes register 0x10 to the device at 0x50, then reads two bytes back. The device \
         stretches the clock after each byte: the firmware waits for SCL to really rise. Each \
         RX word is a byte as seen on the bus, bit-reversed, with the ACK in bit 8."
    ; model_test = "sim/test_i2c.ml"
    ; chip_test = "test_eeprom_24xx"
    ; decoder = "i2c", sigrok ^ "i2c"
    }
  in
  check_replay p rx;
  p
;;

let nec_tx () =
  let address = 0x04
  and command = 0x08 in
  let p =
    { base with
      id = "nec_tx"
    ; title = "NEC infrared"
    ; spec = "a remote's frame on a 38 kHz carrier"
    ; cycles = 760_000
    ; modes = [ 0, Push_pull ]
    ; pins = [ 0, "IR" ]
    ; threads =
        [ { firmware = "nec_tx"
          ; config = { Firmware.nec_tx_config with clkdiv = 132 }
          ; words =
              List.mapi (Firmware.nec_words ~address ~command) ~f:(fun i w ->
                ( w
                , match i with
                  | 0 -> "carrier: CLKDIV 132, half a period of 37.9 kHz"
                  | 1 -> "address 0x04 and its inverse"
                  | _ -> "command 0x08 and its inverse" ))
          }
        ]
    ; what =
        "An NEC infrared remote: a 9 ms burst of carrier, 4.5 ms of quiet, then 32 bits told \
         apart by the gap after each burst. The carrier is made by side-set, one instruction \
         per half period. Zoom in on a burst to see it."
    ; model_test = "sim/test_tx_engines.ml"
    ; chip_test = "test_nec_infrared"
    ; decoder = "ir_nec", sigrok ^ "ir_nec"
    }
  in
  let a, _ = levels p in
  (match Tx.nec_receive a with
   | Some (a', c') when a' = address && c' = command -> ()
   | _ -> fail p "the test's NEC receiver does not read the frame");
  p
;;

let nec_rx () =
  let value = 0xF708FB04 in
  let levels_ = Tx.nec_module_output value in
  let p =
    { base with
      id = "nec_rx"
    ; title = "NEC receiver"
    ; spec = "a receiver module's output, decoded"
    ; cycles = Array.length levels_
    ; pins = [ 0, "IR_IN" ]
    ; threads =
        [ { firmware = "nec_rx"
          ; config = { Firmware.nec_rx_config with clkdiv = 352 }
          ; words = []
          }
        ]
    ; stimulus = changes_of (Array.to_list levels_)
    ; stimulus_note =
        "an IR receiver module's output for address 0x04, command 0x08: low while it sees \
         carrier (sim/test_tx_engines.ml, nec_module_output)"
    ; what =
        "The other end: the input pin carries what an IR receiver module outputs, low during \
         each burst. The thread measures the gaps with a wait timeout and hands the host two \
         words: address and its inverse, command and its inverse. The stimulus is input; edit \
         it to send another frame."
    ; model_test = "sim/test_tx_engines.ml"
    ; chip_test = "test_nec_receive"
    ; decoder = "ir_nec", sigrok ^ "ir_nec"
    }
  in
  let _, rx = levels p in
  if not ([%equal: int list] rx.(0) [ value land 0xFFFF; value lsr 16 ])
  then fail p "the receiver does not hand the host the frame";
  p
;;

let ws2812 ~tx_file ~run_args =
  let words = Sim_run.words_of_string (In_channel.read_all tx_file) in
  let args = String.split (String.strip (In_channel.read_all run_args)) ~on:' ' in
  let rec flags = function
    | "-config" :: c :: rest ->
      let cfg, modes = flags rest in
      Sim_run.config_of_string c :: cfg, modes
    | "-mode" :: m :: rest ->
      let cfg, modes = flags rest in
      cfg, m :: modes
    | [] -> [], []
    | x :: _ -> failwithf "run_args.txt: %s" x ()
  in
  let config, modes =
    match flags args with
    | [ c ], m -> c, m
    | _ -> failwith "run_args.txt: one -config"
  in
  let leds = 3 in
  let bits = leds * 24 in
  { base with
    id = "ws2812"
  ; title = "WS2812 LEDs"
  ; spec = "three LEDs: red, green, blue"
  ; cycles = (bits * 20) + 4000 + 6000
  ; modes = modes_of_array (Sim_run.modes_of_flags modes)
  ; pins = [ 0, "DIN" ]
  ; threads =
      [ { firmware = "ws2812"
        ; config
        ; words =
            List.mapi words ~f:(fun i w ->
              w, if i = 0 then sprintf "%d bits: %d LEDs" bits leds else "two colour bytes, G R B order")
        }
      ]
  ; what =
      "The firmware a programmer who had never seen the chip wrote from the instruction set \
       alone, in 16 instructions (examples/ws2812). A 1 is 800 ns high and 500 ns low, a 0 is \
       400 ns and 900 ns, most significant bit first, then a latch of 310 us. The TX words \
       are examples/ws2812/host.py's for three LEDs."
  ; model_test = "examples/ws2812/accept.py"
  ; chip_test = "test_ws2812"
  ; decoder = "rgb_led_ws281x", sigrok ^ "rgb_led_ws281x"
  }
;;

let dmx () =
  let packets = Tx.dmx_packets in
  let p =
    { base with
      id = "dmx"
    ; title = "DMX512"
    ; spec = "250 kbit/s, two packets of slots"
    ; cycles = 8_000
    ; modes = [ 0, Push_pull ]
    ; pins = [ 0, "DMX" ]
    ; threads =
        [ { firmware = "dmx_tx"
          ; config = { Isa.Thread_config.default with threshold = 9 }
          ; words =
              (Tx.dmx_bit - 4, sprintf "bit time: %d clocks, less 4" Tx.dmx_bit)
              :: List.concat_map packets ~f:(fun slots ->
                List.mapi slots ~f:(fun i b ->
                  ( Firmware.dmx_word ~break:(i = 0) b
                  , if i = 0 then sprintf "break, then start code 0x%02X" b else sprintf "slot 0x%02X" b )))
          }
        ]
    ; what =
        "Stage lighting. Each packet starts with a break (the line low for more than 88 us) \
         and a mark, then slots of 8 bits with two stop bits. A word's bit 0 asks for a break \
         first; the rest is the slot."
    ; model_test = "sim/test_tx_engines.ml"
    ; chip_test = "test_dmx512"
    ; decoder = "dmx512", sigrok ^ "dmx512"
    }
  in
  let a, _ = levels p in
  let trace = Array.map a ~f:(fun v -> v land 1) in
  if not ([%equal: int list list * string list] (Tx.dmx_receive trace) (packets, []))
  then fail p "the test's DMX receiver does not read the packets";
  p
;;

let two_threads () =
  let module T = Pe_test.Test_two_threads in
  let module D = Firmware.Two_protocols in
  let sent = [ 0x12; 0x34; 0x56 ] in
  let responses = List.map sent ~f:(fun b -> (b * 7) land 0xFF) in
  let divisor = 20 in
  let text = "OK!" in
  let bytes = List.map (String.to_list text) ~f:Char.to_int in
  let threads =
    [ { firmware = "spi_fast"
      ; config = D.spi_config
      ; words = List.map2_exn (T.spi_words sent) sent ~f:(fun w b -> w, sprintf "SPI byte 0x%02X, bit-reversed" b)
      }
    ; { firmware = "uart_tx"
        (* Each thread has a program memory of its own here, so the UART
           program starts at 0, not after the SPI one as in D.image. *)
      ; config = { D.uart_config with start = 0 }
      ; words =
          (divisor - 4, sprintf "bit time: %d clocks, less 4" divisor)
          :: List.map bytes ~f:(fun b -> b, sprintf "'%c'" (Char.of_int_exn b))
      }
    ]
  in
  let cycles = 200 + (List.length bytes * ((10 * divisor) + 4)) in
  let slave = Spi.Slave.create ~responses in
  let stimulus, rx =
    record
      ~threads
      ~pin_modes:T.modes
      ~bypass:D.sync_bypass
      ~cycles
      ~drives:(fun () -> 0xFF land lnot (Bool.to_int (not (Spi.Slave.miso slave)) lsl 2))
      ~sees:(fun l ->
        Spi.Slave.step slave ~sck:(l land 1 = 1) ~mosi:((l lsr 1) land 1 = 1) ~cs_n:((l lsr 3) land 1 = 1))
  in
  if not ([%equal: int list] (Spi.Slave.received slave) sent) then failwith "two threads: SPI device";
  let p =
    { base with
      id = "two"
    ; title = "Two at once"
    ; spec = "SPI on thread 0, UART on thread 1"
    ; cycles
    ; bypass = D.sync_bypass
    ; modes = modes_of_array T.modes
    ; pins = [ 0, "SCK"; 1, "MOSI"; 2, "MISO"; 3, "CS_N"; 4, "TX" ]
    ; threads
    ; stimulus
    ; stimulus_note = "MISO as the test's SPI device drove it (model/spi_model.ml), recorded"
    ; what =
        "Two programs at once, one to a thread, each with its own program memory, FIFOs and \
         pins: side-set SPI on P0 to P3 and the UART on P4. Neither knows the other is there. \
         Thread 1's RX words, if it had any, would show as rx1."
    ; model_test = "sim/test_two_threads.ml"
    ; chip_test = "test_two_protocols"
    ; decoder = "spi", sigrok ^ "spi"
    }
  in
  check_replay p rx;
  let a, _ = levels p in
  (match Uart_model.decode ~divisor (Array.to_list (pin a 4)) with
   | Ok got when [%equal: int list] got bytes -> ()
   | _ -> fail p "the UART receiver model does not read thread 1's text");
  p
;;

let mvb () =
  let module T = Pe_test.Test_mvb in
  let frames = T.poll in
  let words =
    List.concat_map frames ~f:(function
      | `M w ->
        List.mapi (Firmware.mvb_words ~master:true [ w ]) ~f:(fun i v ->
          v, if i = 0 then "a master frame: one word" else sprintf "0x%04X: port 0x123, 4 bytes" v)
      | `S ws ->
        List.mapi (Firmware.mvb_words ~master:false ws) ~f:(fun i v ->
          v, if i = 0 then sprintf "a slave frame: %d words" (List.length ws) else sprintf "data 0x%04X" v))
  in
  let bits =
    List.sum (module Int) frames ~f:(function
      | `M _ -> 24
      | `S ws -> (16 * List.length ws) + (8 * ((List.length ws + 3) / 4)))
  in
  let p =
    { base with
      id = "mvb"
    ; title = "MVB train bus"
    ; spec = "1.5 Mbit/s, the longest program: 112 instructions"
    ; clock_hz = 48_000_000
    ; cycles = ((bits + (20 * List.length frames)) * 32) + 400
    ; inputs = 0
    ; modes = [ 0, Push_pull; 1, Push_pull ]
    ; pins = [ 0, "MVB"; 1, "EN" ]
    ; threads = [ { firmware = "mvb"; config = Firmware.mvb_config ~clkdiv:1; words } ]
    ; what =
        "IEC 61375 Multifunction Vehicle Bus: a master frame asking for process data port \
         0x123, and the slave frame that answers. Manchester code, start delimiters, and a \
         check sequence after every 64 bits, made on the thread's CRC register. At 48 MHz, 16 \
         clocks are a half bit."
    ; model_test = "sim/test_mvb.ml"
    ; chip_test = "test_mvb"
    ; decoder = "mvb (yeckel)", "https://github.com/yeckel/sigrok_mvb_decoder"
    }
  in
  let a, _ = levels p in
  if not ([%equal: T.frame list] (T.receive ~half:16 (pin a 0) (pin a 1)) (T.expect frames))
  then fail p "the test's MVB receiver does not read the frames";
  p
;;

let ltc () =
  let module T = Pe_test.Test_ltc in
  let p =
    { base with
      id = "ltc"
    ; title = "SMPTE timecode"
    ; spec = "25 frames a second, biphase mark"
    ; clock_hz = 400_000
    ; cycles = ((List.length T.session * 80) + 4) * 200
    ; inputs = 0
    ; modes = [ 0, Push_pull ]
    ; pins = [ 0, "LTC" ]
    ; threads =
        [ { firmware = "ltc"
          ; config = Firmware.ltc_config ~clkdiv:1
          ; words =
              List.concat_mapi T.session ~f:(fun k frame ->
                let h, m, s, f = List.nth_exn T.times k in
                List.mapi frame ~f:(fun i w ->
                  w, if i = 0 then sprintf "%02d:%02d:%02d:%02d, frames and user bits" h m s f else ""))
          }
        ]
    ; what =
        "Linear timecode as on a film set: 80 bits a frame, biphase mark, the sync word, and \
         the polarity bit, which depends on bits sent after it (the firmware works it out on \
         the CRC register first). Three frames, 23:59:59:22 to :24, with the chip at 400 kHz."
    ; model_test = "sim/test_ltc.ml"
    ; chip_test = "test_ltc_timecode"
    ; decoder = "ltc (sigrok pull request 136)", "https://github.com/sigrokproject/libsigrokdecode/pull/136"
    }
  in
  let a, _ = levels p in
  if not
       ([%equal: (T.frame list, string) Result.t]
          (Result.map (T.bits ~half:100 (pin a 0)) ~f:T.frames)
          (T.expect T.times))
  then fail p "the test's timecode reader does not read the frames";
  p
;;

let i2s () =
  let frames = Tx.i2s_frames in
  let p =
    { base with
      id = "i2s"
    ; title = "I2S audio"
    ; spec = "16-bit stereo, 2.5 MHz bit clock"
    ; cycles = 1_000
    ; modes = [ 0, Push_pull; 1, Push_pull; 2, Push_pull ]
    ; pins = [ 0, "SCK"; 1, "WS"; 2, "SD" ]
    ; threads =
        [ { firmware = "i2s_tx"
          ; config = Firmware.i2s_tx_config
          ; words =
              List.concat_map frames ~f:(fun (l, r) ->
                [ l, sprintf "left 0x%04X" l; r, sprintf "right 0x%04X" r ])
              @ [ 0, "silence"; 0, "silence" ]
          }
        ]
    ; what =
        "The bus between audio chips: a bit clock, a word select that is low for the left \
         sample and high for the right and changes one bit early, and the samples most \
         significant bit first. Side-set makes SCK and WS; the fetch of the next sample hides \
         inside the last bit, so the clock never stretches."
    ; model_test = "sim/test_tx_engines.ml"
    ; chip_test = "test_i2s"
    ; decoder = "i2s", sigrok ^ "i2s"
    }
  in
  let a, _ = levels p in
  let got = Tx.i2s_receive (Array.map a ~f:(fun v -> v land 7)) in
  let want = List.concat_map frames ~f:(fun (l, r) -> [ 0, 16, l; 1, 16, r ]) in
  if not ([%equal: (int * int * int) list] (List.take got 8) want)
  then fail p "the test's I2S receiver does not read the samples";
  p
;;

let uart_rx () =
  let module T = Pe_test.Test_uart_rx in
  let divisor = 87 in
  let bytes = [ 0x4F; 0x4B ] in
  let line = T.line ~bit_time:(Float.of_int divisor *. 1.02) ~frames:(List.map bytes ~f:(fun b -> 2, b, true)) in
  let p =
    { base with
      id = "uart_rx"
    ; title = "UART receiver"
    ; spec = "a sender 2% slow, read mid-bit"
    ; cycles = List.length line + (4 * divisor)
    ; pins = [ 0, "RX" ]
    ; threads =
        [ { firmware = "uart_rx"
          ; config =
              { Isa.Thread_config.default with
                in_base = 0
              ; threshold = 9
              ; timeout = 0
              ; timeout_vector = Firmware.uart_rx_bad
              }
          ; words =
              List.mapi (Firmware.Uart_duplex.rx_setup ~divisor) ~f:(fun i w ->
                w, if i = 0 then sprintf "bit time: %d clocks, less 4" divisor else "half a bit, to sample mid-bit")
          }
        ]
    ; stimulus = changes_of (List.map line ~f:(fun high -> if high then 0xFF else 0xFE))
    ; stimulus_note =
        "the line from the test's frame generator: \"OK\" at 115,200 baud, 2% slow \
         (sim/test_uart_rx.ml)"
    ; what =
        "A receiver: it waits for the start bit's falling edge, waits half a bit, then samples \
         every bit time. Each RX word is the byte with the stop bit in bit 8, so 0x14F is a \
         good 'O'. The sender here is 2% slower than the receiver expects."
    ; model_test = "sim/test_uart_rx.ml"
    ; chip_test = "test_uart_duplex"
    ; decoder = "uart", sigrok ^ "uart"
    }
  in
  let _, rx = levels p in
  if not ([%equal: int list] rx.(0) (List.map bytes ~f:T.good))
  then fail p "the receiver does not hand the host the bytes";
  p
;;

(* --------------------------------------------------------------- output *)

let chip_test_line name =
  let lines = String.split_lines (In_channel.read_all !test_py) in
  match
    List.findi lines ~f:(fun _ l -> String.is_prefix l ~prefix:(sprintf "async def %s(" name))
  with
  | Some (i, _) -> i + 1
  | None -> failwithf "test/test.py has no %s" name ()
;;

let to_json p =
  O
    [ "id", S p.id
    ; "title", S p.title
    ; "spec", S p.spec
    ; "clock_hz", I p.clock_hz
    ; "cycles", I p.cycles
    ; "inputs", S (sprintf "0x%02X" p.inputs)
    ; "bypass", S (sprintf "0x%02X" p.bypass)
    ; "modes", L (List.map p.modes ~f:(fun m -> S (mode_flag m)))
    ; "pins", L (List.map p.pins ~f:(fun (pin, name) -> O [ "pin", I pin; "name", S name ]))
    ; ( "threads"
      , L
          (List.map p.threads ~f:(fun t ->
             let file, text = source t.firmware in
             O
               [ "firmware", S t.firmware
               ; "file", S ("examples/" ^ file)
               ; "source", S text
               ; "config", S (Sim_run.config_to_string t.config)
               ; "tx", S (tx_text t.words)
               ])) )
    ; "stimulus", S (if List.is_empty p.stimulus then "" else stimulus_text ~note:p.stimulus_note p.stimulus)
    ; "recorded", B (String.is_substring p.stimulus_note ~substring:"recorded")
    ; "what", S p.what
    ; ( "links"
      , L
          [ O [ "text", S p.model_test; "href", S (repo ^ p.model_test) ]
          ; O
              [ "text", S ("test/test.py: " ^ p.chip_test)
              ; "href", S (sprintf "%stest/test.py#L%d" repo (chip_test_line p.chip_test))
              ]
          ; O [ "text", S ("sigrok decoder: " ^ fst p.decoder); "href", S (snd p.decoder) ]
          ] )
    ]
;;

let presets ~tx_file ~run_args =
  [ uart ()
  ; spi ()
  ; i2c ()
  ; nec_tx ()
  ; ws2812 ~tx_file ~run_args
  ; dmx ()
  ; two_threads ()
  ; nec_rx ()
  ; uart_rx ()
  ; i2s ()
  ; mvb ()
  ; ltc ()
  ]
;;

let page ~template ~model ~fonts ~presets =
  let inside_script s = String.substr_replace_all s ~pattern:"</script" ~with_:"<\\/script" in
  let fill page (marker, text) =
    if List.length (String.substr_index_all page ~may_overlap:false ~pattern:marker) <> 1
    then failwithf "playground/page.html must have the marker %s exactly once" marker ();
    String.substr_replace_first page ~pattern:marker ~with_:text
  in
  List.fold
    [ "/*PRESETS*/null", inside_script presets; "/*MODEL*/", inside_script model; "/*FONTS*/", fonts ]
    ~init:template
    ~f:fill
;;

(* js_of_ocaml ends its output with a "//# buildInfo:" comment naming its
   version, and the same release names itself "6.2.0" or "6.2.0+6.2.0"
   depending on how opam installed it. The comment does nothing in the page,
   so leave it out: the committed page must not depend on the install. *)
let without_build_stamp js =
  String.split_lines js
  |> List.filter ~f:(fun l -> not (String.is_prefix l ~prefix:"//# buildInfo:"))
  |> String.concat ~sep:"\n"
  |> fun s -> s ^ "\n"
;;

let () =
  match Sys.get_argv () with
  | [| _; "presets"; dir; tests; tx_file; run_args |] ->
    examples := dir;
    test_py := tests;
    print_endline (Json.to_string (L (List.map (presets ~tx_file ~run_args) ~f:to_json)))
  | [| _; "page"; template; model; fonts; presets |] ->
    print_string
      (page
         ~template:(In_channel.read_all template)
         ~model:(without_build_stamp (In_channel.read_all model))
         ~fonts:(In_channel.read_all fonts)
         ~presets:(String.strip (In_channel.read_all presets)))
  | _ ->
    prerr_endline
      "usage: playground_page.exe presets EXAMPLES_DIR test.py ws2812.tx run_args.txt\n\
      \       playground_page.exe page page.html pe_js.js plex.css presets.json";
    exit 2
;;
