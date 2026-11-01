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
let i2c_word ~stop byte =
  let reversed = List.init 8 ~f:(fun i -> ((byte lsr i) land 1) lsl (7 - i)) |> List.fold ~init:0 ~f:( lor ) in
  reversed lor (1 lsl 8) lor (Bool.to_int stop lsl 9)
;;

let all = [ "uart_tx", uart_tx; "echo", echo; "i2c_controller", i2c_controller ]
