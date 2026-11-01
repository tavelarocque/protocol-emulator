open! Core

(* Firmware for the protocol-emulator core, in its assembly language. *)

(* UART transmitter, 8N1, LSB first, on one push-pull pin (out_base and
   set_base both point at it, out_count = set_count = 1, threshold = 8).

   Host protocol on the thread's TX FIFO:
     word 0     : divisor - 4, where divisor = clock cycles per bit (>= 4).
                  4 is the fixed instruction overhead of each bit period.
     word 1..   : one byte per word.

   Timing: every bit, including start, is exactly [divisor] cycles. The stop
   bit is divisor + 1 cycles when bytes are back to back (one extra cycle for
   the PULL), which any UART receiver accepts. *)
let uart_tx =
  {|
        set pins, 1         ; line idles high
        pull                ; OSR <- divisor - 4
        mov y, osr          ; Y = per-bit loop count
next:   pull                ; wait for a byte; line stays high meanwhile
        set pins, 0 [1]     ; start bit (2 cycles, then the delay loop)
        mov x, y
start:  jmp x-- start
bit:    out pins, 1         ; data bit, LSB first
        mov x, y
hold:   jmp x-- hold
        jmp !osre bit       ; until all 8 bits are out
        set pins, 1         ; stop bit
        mov x, y
stop:   jmp x-- stop
        jmp next
|}
;;

(* Echo: every 16-bit word the host pushes to the TX FIFO comes back on the
   RX FIFO unchanged. Exercises the whole host data path (SPI, both FIFOs,
   OSR, ISR) with no pins involved. *)
let echo =
  {|
loop:   pull
        out x, 16
        in x, 16
        push
        jmp loop
|}
;;

(* I2C controller, write transactions, with clock stretching.

   Pins: P0 = SDA, P1 = SCL, both open-drain.
   Config: out_base 0, out_count 1 (SDA); set_base 1, set_count 1 (SCL);
   in_base 0 (SDA); threshold 8; timeout_vector = [i2c_timeout_vector];
   TIMEOUT = the longest clock stretch to tolerate, in cycles.

   Host protocol on the TX FIFO:
     word 0  : H, the half-period loop count (each SCL phase is about H + 4
               cycles).
     then one word per byte, first the address byte (address << 1, write):
       bits 7:0  the byte, bit-reversed (OUT shifts LSB first; I2C is MSB
                 first)
       bit 8     must be 1: releases SDA so the target can ACK
       bit 9     1 = send STOP after this byte, ending the transaction
   RX FIFO, one word per byte: 0 = ACK, 1 = NACK.
   If a target holds SCL low longer than TIMEOUT, the firmware pushes 2,
   releases both lines and returns to idle.

   Every SDA change happens while SCL is low, except START and STOP. *)
let i2c_controller =
  {|
        pull                ; OSR <- H, the half-period loop count
        mov y, osr          ; Y = H for every delay below
idle:   pull                ; first byte of a transaction; bus idle
        mov pins, null      ; START: SDA low while SCL is high
        mov x, y
d0:     jmp x-- d0
bit:    set pins, 0         ; SCL low
        out pins, 1         ; SDA = next bit, MSB first
        mov x, y
d1:     jmp x-- d1
        set pins, 1         ; release SCL
        wait 1 pin 1 timeout ; until SCL is really high: the target may stretch
        mov x, y
d2:     jmp x-- d2
        jmp !osre bit       ; 8 data bits
        set pins, 0         ; SCL low for the ACK clock
        out pins, 1         ; release SDA (word bit 8)
        mov x, y
d3:     jmp x-- d3
        set pins, 1         ; release SCL
        wait 1 pin 1 timeout
        in pins, 1          ; sample SDA: 0 = ACK, 1 = NACK
        push                ; report it to the host
        mov x, y
d4:     jmp x-- d4
        set pins, 0         ; SCL low: end of the ACK clock
        out x, 1            ; X = STOP flag (word bit 9)
        jmp !x next         ; no STOP: next byte of this transaction
        mov pins, null      ; STOP: SDA low while SCL is low,
        mov x, y
d5:     jmp x-- d5
        set pins, 1         ; release SCL,
        wait 1 pin 1 timeout
        mov x, y
d6:     jmp x-- d6
        set x, 1
        mov pins, x         ; then release SDA while SCL is high
        mov x, y
d7:     jmp x-- d7
        jmp idle
next:   pull                ; next byte; SCL is held low until it arrives
        jmp bit
stuck:  set x, 2            ; timeout vector: SCL never went high
        in x, 2
        push                ; report 2 = bus stuck
        set pins, 1         ; release SCL
        set x, 1
        mov pins, x         ; release SDA
        jmp idle
|}
;;

(* Address of [stuck:] above; the tests check it still points there. *)
let i2c_timeout_vector = 42

(* Host-side encoding of one byte for [i2c_controller]. *)
let reverse_byte byte =
  List.init 8 ~f:(fun i -> ((byte lsr i) land 1) lsl (7 - i)) |> List.fold ~init:0 ~f:( lor )
;;

let i2c_word ~stop byte = reverse_byte byte lor (1 lsl 8) lor (Bool.to_int stop lsl 9)

(* SPI controller, mode 0 (SCK idles low, sample on the rising edge),
   MSB first, full duplex.

   Pins: P0 = SCK, P1 = MOSI, P3 = CS_N (push-pull); P2 = MISO (input).
   Config: set_base 0, set_count 1 (SCK); out_base 1, out_count 3 (MOSI, -,
   CS_N: OUT writes only MOSI, MOV writes all three to move CS_N); in_base 2
   (MISO); threshold 8.

   Host protocol on the TX FIFO:
     word 0  : H, the half-period loop count. A bit takes 2H + 9 cycles.
     then one word per byte:
       bits 7:0  the byte to send, bit-reversed (OUT shifts LSB first)
       bit 8     1 = deselect after this byte, ending the transfer
   RX FIFO: one word per byte, the byte received, bit-reversed. *)
let spi_controller =
  {|
        set pins, 0         ; SCK idles low in mode 0 (pins reset high)
        pull                ; OSR <- H
        mov y, osr          ; Y = H for every delay below
idle:   set x, 4
        mov pins, x         ; CS_N high, MOSI low: deselected
        pull                ; first byte of a transfer
        mov pins, null      ; CS_N low: select
        mov x, y
c0:     jmp x-- c0
bit:    out pins, 1         ; MOSI = next bit, while SCK is low
        mov x, y
c1:     jmp x-- c1
        set pins, 1         ; SCK high: both sides sample
        in pins, 1          ; MISO
        mov x, y
c2:     jmp x-- c2
        set pins, 0         ; SCK low: the slave shifts its next bit out
        jmp !osre bit       ; 8 bits
        push                ; byte received
        out x, 1            ; X = deselect flag (word bit 8)
        jmp !x next
        mov x, y
c3:     jmp x-- c3
        jmp idle
next:   pull                ; next byte; SCK held low until it arrives
        jmp bit
|}
;;

(* Host-side encoding of one byte for [spi_controller]. *)
let spi_word ~last byte = reverse_byte byte lor (Bool.to_int last lsl 8)

(* SPI controller at 2 cycles per bit, using side-set for SCK.

   Same pins, host protocol and RX format as [spi_controller], minus the
   half-period word: it always runs at full speed (core clock / 2, so
   5 Mbit/s at 10 MHz). Config: sideset_base 0, sideset_count 1 (SCK);
   out_base 1, out_count 3; in_base 2; threshold 8.

   Each bit is two instructions: OUT puts MOSI out while side-set holds SCK
   low, then IN samples MISO while side-set raises SCK. The byte is unrolled
   so no loop instruction sits between bits.

   Timing limit: IN samples MISO one core clock after SCK falls, so the
   slave's clock-to-output time plus pad delays must be under one clock
   period (100 ns at 10 MHz). Slower slaves need [spi_controller]. *)
let spi_fast =
  {|
        .side_set 1
idle:   set x, 4            side 0 ; SCK low
        mov pins, x         side 0 ; CS_N high, MOSI low: deselected
        pull                side 0 ; first byte of a transfer
        mov pins, null      side 0 ; CS_N low: select
byte:
        out pins, 1         side 0 ; bit 7: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 6: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 5: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 4: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 3: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 2: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 1: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 0: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        push                side 0 ; byte received
        out x, 1            side 0 ; X = deselect flag (word bit 8)
        jmp !x next         side 0
        jmp idle            side 0
next:   pull                side 0 ; next byte; SCK stays low until it arrives
        jmp byte            side 0
|}
;;

(* I2C controller, reads and writes, timed by the clock divider.

   The same 9-clock routine moves every byte in either direction: it shifts
   9 bits out on SDA (8 data bits, then the ACK slot) while sampling SDA on
   each clock. Writing a byte, the host's data goes out and the slot is
   released so the target can ACK. Reading, the host sends 0xFF (SDA
   released) and puts its own ACK or NACK in the slot. Either way what was
   sampled is what was on the bus, so the RX word reports it all.

   Pins: P0 = SDA (open-drain), P1 = SCL (open-drain, driven by side-set).
   Config: out_base 0, out_count 1, set_base 0, set_count 1 (SDA); in_base 0;
   sideset_base 1, sideset_count 1 (SCL); timeout_vector = [i2c_stuck];
   TIMEOUT = the longest clock stretch to tolerate, in ticks;
   CLKDIV = clock / (6 x bit rate), so 17 for 98 kHz at 10 MHz.

   Every bit is 6 ticks, SCL low for 3 and high for 3, which meets
   standard-mode (100 kHz) timing whenever a tick is at least 1.6 us. START
   and STOP hold SDA for 3 ticks around the SCL edge.

   Host protocol on the TX FIFO, one word per byte:
     bits 7:0  the byte, bit-reversed (OUT shifts LSB first; I2C is MSB
               first). 0xFF to read a byte.
     bit 8     the ACK slot: 1 when writing (release SDA so the target can
               ACK); when reading, 0 = ACK (send more), 1 = NACK (last byte)
     bit 9     1 = send STOP after this byte, ending the transaction
   The first byte after idle (the address, with R/W in bit 0) gets a START.
   RX FIFO, one word per byte as seen on the bus: bits 7:0 the byte,
   bit-reversed; bit 8 the ACK slot, 0 = ACK, 1 = NACK. 0x200 = the bus was
   stuck (SCL held low longer than TIMEOUT); the firmware then releases both
   lines and returns to idle.

   One property is deliberate: the RX word of a read's last byte has bit 8
   set (the controller's NACK), which is exactly the "last byte" flag of the
   SPI firmware's TX words. That is what lets [Bridge] below chain them. *)
let i2c =
  {|
        .side_set 1
idle:   pull                side 1     ; bus idle: both lines released
        set pins, 0         side 1 [2] ; START: SDA falls while SCL is high
byte:   set y, 8            side 0     ; SCL low; 9 bits: 8 data + ACK slot
bit:    out pins, 1         side 0 [1] ; SDA = next bit while SCL is low
        nop                 side 1     ; release SCL
        wait 1 pin 1 timeout side 1    ; until SCL is really high: the target may stretch
        in pins, 1          side 1     ; sample SDA
        jmp y-- bit         side 0     ; SCL low
        push                side 0     ; the byte and its ACK slot, as seen on the bus
        out x, 1            side 0     ; X = STOP flag (word bit 9)
        jmp !x next         side 0
        set pins, 0         side 0     ; STOP: SDA low while SCL is low,
        nop                 side 1     ; release SCL,
        wait 1 pin 1 timeout side 1 [1]
        set pins, 1         side 1     ; then SDA rises while SCL is high
        jmp idle            side 1
next:   pull                side 0     ; next byte; SCL held low until it arrives
        jmp byte            side 0
stuck:  mov isr, null       side 1     ; timeout vector: SCL never went high
        in null, 9          side 1
        set x, 1            side 1
        in x, 1             side 1
        push                side 1     ; report 0x200: bus stuck
        set pins, 1         side 1     ; release SDA (side-set released SCL)
        jmp idle            side 1
|}
;;

(* Address of [stuck:] in [i2c]; the tests check it still points there. *)
let i2c_stuck = 18

(* Host-side words for [i2c]. *)
let i2c_write_word ~stop byte = reverse_byte byte lor (1 lsl 8) lor (Bool.to_int stop lsl 9)
let i2c_read_word ~last = 0xFF lor (Bool.to_int last lsl 8) lor (Bool.to_int last lsl 9)

let i2c_config =
  { Isa.Thread_config.default with
    out_base = 0
  ; out_count = 1
  ; set_base = 0
  ; set_count = 1
  ; in_base = 0
  ; sideset_base = 1
  ; sideset_count = 1
  ; timeout_vector = i2c_stuck
  ; timeout = 10_000
  ; clkdiv = 17
  }
;;

(* Two protocols at once, one per thread, from one shared memory image:
   [spi_fast] on thread 0 (P0 SCK, P1 MOSI, P2 MISO, P3 CS_N) and [uart_tx]
   on thread 1 (P4 TX). Each program keeps its own host protocol on its own
   thread's FIFOs; neither knows the other exists. The UART program is
   assembled to run from just after the SPI one. *)
module Two_protocols = struct
  let spi_origin = 0
  let spi = Asm.assemble ~origin:spi_origin spi_fast
  let uart_origin = spi_origin + Array.length spi
  let uart = Asm.assemble ~origin:uart_origin uart_tx
  let image = Asm.link [ spi_origin, spi; uart_origin, uart ]

  let spi_config =
    { Isa.Thread_config.default with
      start = spi_origin
    ; sideset_base = 0
    ; sideset_count = 1
    ; out_base = 1
    ; out_count = 3
    ; in_base = 2
    ; threshold = 8
    }
  ;;

  let uart_config =
    { Isa.Thread_config.default with
      start = uart_origin
    ; out_base = 4
    ; out_count = 1
    ; set_base = 4
    ; set_count = 1
    ; threshold = 8
    }
  ;;

  (* P0, P1, P3, P4 push-pull; P2 (MISO) and the rest inputs. *)
  let mode_bits = 0b01_01_00_01_01
end

(* An I2C-to-SPI bridge with no host in the data path: [i2c] on thread 0
   reads a sensor, CHAIN carries each byte it pushes straight into thread
   1's TX FIFO, and [spi_fast] on thread 1 sends it out. One SPI transfer
   (CS low to CS high) mirrors one I2C read byte for byte, address byte
   first, ending on the byte the controller NACKed. The host only queues the
   I2C read commands, and drains the SPI device's replies from thread 1's
   RX FIFO (or the SPI thread stalls once it has four).

   Pins: P0 SDA, P1 SCL (open-drain); P2 SCK, P3 MOSI, P4 MISO, P5 CS_N
   (push-pull, MISO input). [spi_fast] is position-independent apart from
   its config, so it moves to P2..P5 by changing its bases. *)
module Bridge = struct
  let i2c_origin = 0
  let i2c_program = Asm.assemble ~origin:i2c_origin i2c
  let spi_origin = i2c_origin + Array.length i2c_program
  let spi = Asm.assemble ~origin:spi_origin spi_fast
  let image = Asm.link [ i2c_origin, i2c_program; spi_origin, spi ]
  let i2c_config = { i2c_config with start = i2c_origin }

  let spi_config =
    { Isa.Thread_config.default with
      start = spi_origin
    ; sideset_base = 2
    ; sideset_count = 1
    ; out_base = 3
    ; out_count = 3
    ; in_base = 4
    ; threshold = 8
    }
  ;;

  (* P0, P1 open-drain; P2, P3, P5 push-pull; P4 input. *)
  let mode_bits = 0b01_00_01_01_10_10

  (* Host words for one I2C read of [count] bytes from [address]. *)
  let read_command ~address ~count =
    i2c_write_word ~stop:false ((address lsl 1) lor 1)
    :: List.init count ~f:(fun i -> i2c_read_word ~last:(i = count - 1))
  ;;
end

let all =
  [ "uart_tx", uart_tx
  ; "echo", echo
  ; "i2c_controller", i2c_controller
  ; "spi_controller", spi_controller
  ; "spi_fast", spi_fast
  ; "i2c", i2c
  ]
