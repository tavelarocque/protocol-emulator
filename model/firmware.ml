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

(* UART receiver, 8N1, LSB first, on pin [pin] (an input, read through the
   input synchroniser). Config: in_base = [pin], threshold 9, TIMEOUT 0,
   timeout_vector = origin + [uart_rx_bad].

   Host protocol on the TX FIFO, once at start:
     word 0 : divisor - 4, where divisor = clock cycles per bit (>= 10),
              exactly as for [uart_tx]
     word 1 : the half-bit delay, [uart_rx_half ~divisor]
   RX FIFO, one word per frame: bits 7:0 the byte (LSB first is the order
   IN shifts, so no bit reversal), bit 8 the stop bit as sampled: 1 for a
   good frame, 0 for a framing error or a break.

   Timing: the start bit's falling edge reaches the thread 2 cycles late
   (the synchroniser); a half-bit delay then puts the first sample in the
   middle of data bit 0, and every later sample is exactly one divisor on.
   The test suite checks reception with the sender's baud rate off by up to
   2% either way. Back-to-back frames need divisor >= 10.

   After a frame, the firmware goes straight back to looking for the next
   start bit, unless the stop bit was low (a framing error or a break): then
   it first waits for the line to return high, so it does not mistake the
   rest of a long low for new frames. That branch is a [wait 1 ... timeout]
   with TIMEOUT 0, which falls through if the pin is high and jumps to the
   timeout vector at once if it is low. The first version waited for idle
   after every frame and lost back-to-back frames from a fast sender: the
   next start bit had already begun when it checked. *)
let uart_rx ~pin =
  String.substr_replace_all
    ~pattern:"PIN"
    ~with_:(Int.to_string pin)
    {|
        pull                ; OSR <- divisor - 4
        mov y, osr          ; Y = per-bit loop count
        pull                ; OSR <- half-bit count, kept there for good
start:  wait 0 pin PIN      ; start bit
        mov x, osr
half:   jmp x-- half        ; to the middle of the start bit
bit:    mov x, y
hold:   jmp x-- hold        ; one bit time on
        in pins, 1          ; sample: 8 data bits, then the stop bit
        jmp !isrf bit       ; until 9 bits (threshold 9)
        push                ; byte in bits 7:0, stop bit in bit 8
        wait 1 pin PIN timeout ; stop bit high: next frame. Low: to [bad]
        jmp start
bad:    wait 1 pin PIN      ; framing error or break: wait for the line to idle
        jmp start
|}
;;

(* Offset of [bad:] in [uart_rx], its timeout vector. *)
let uart_rx_bad = 13

(* The second host word for [uart_rx]. *)
let uart_rx_half ~divisor = (divisor / 2) - 1

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

(* Host-side encoding of one byte for [spi_controller] and [spi_fast], with
   the thread shifting LSB first (the default). *)
let spi_word ~last byte = reverse_byte byte lor (Bool.to_int last lsl 8)

(* The same with the thread's SHIFT register set to MSB first in both
   directions: the byte goes in plainly, in the top half of the word (OUT
   takes bits from the top), and the deselect flag in the bit just below it.
   The RX word is then the received byte as is. No bit reversal on either
   side. *)
let spi_msb_word ~last byte = (byte lsl 8) lor (Bool.to_int last lsl 7)

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
   period (100 ns at 10 MHz). Slower slaves need [spi_controller]. For the
   same reason MISO must bypass the input synchroniser (SYNC_BYPASS), whose
   two-cycle delay would make every sample stale; that is safe here because
   MISO changes only after SCK falls, a full clock before it is sampled. *)
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
     bit 10    1 = a repeated START after this byte (with bit 9 clear): the
               next word is an address again, and no STOP comes between
   The first byte after idle (the address, with R/W in bit 0) gets a START.

   A repeated START releases SDA while SCL is low (it is low only if the
   host put an ACK in a read's slot), releases SCL and waits for it to be
   high, since a target may be stretching, and then goes the way of the
   first START: SCL has been high for at least 4 ticks when SDA falls.
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
next:   out x, 1            side 0     ; X = repeated START flag (word bit 10)
        jmp !x more         side 0
        set pins, 1         side 0 [1] ; repeated START: SDA released while SCL is low,
        wait 1 pin 1 timeout side 1 [1] ; SCL released, and really high,
        jmp idle            side 1     ; then START, as at the beginning
more:   pull                side 0     ; next byte; SCL held low until it arrives
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
let i2c_stuck = 23

(* Host-side words for [i2c]. *)
let i2c_write_word ?(restart = false) ~stop byte =
  reverse_byte byte lor (1 lsl 8) lor (Bool.to_int stop lsl 9) lor (Bool.to_int restart lsl 10)
;;

let i2c_read_word ~last = 0xFF lor (Bool.to_int last lsl 8) lor (Bool.to_int last lsl 9)

(* A read's last byte followed by a repeated START where the STOP would be. *)
let i2c_read_word_then_restart = 0xFF lor (1 lsl 8) lor (1 lsl 10)

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

(* I2C target (device mode): the chip answers as a 7-bit-address I2C device
   that any controller can write to and read from, with clock stretching and
   repeated START.

   Pins: P0 = SDA, P1 = SCL, both open-drain. Config: [i2c_target_config]:
   in_base 0, out_base 0, set_base 0 (SDA); sideset_base 1 (SCL, so any
   instruction can hold it low); threshold 8; IN shifts MSB first; TIMEOUT 0
   and timeout_vector [i2c_target_rest] (see "branching on a pin" below).

   Host protocol.
     TX word 0  : the device's 7-bit address (1 to 127).
     TX, then   : one word per byte a controller reads, bit-reversed (OUT
                  shifts LSB first; [reverse_byte]). The firmware takes a
                  word only once the previous byte was ACKed, so exactly the
                  bytes sent are consumed. If none is ready it holds SCL low
                  until the host pushes one.
     RX         : one word per byte a controller writes (the byte as is,
                  0 to 255), and, for every START or repeated START that
                  addresses this device, a marker word: the address byte
                  (address << 1 | R/W) << 8, so always 256 or more. A register
                  read therefore arrives as [W marker; register; R marker].
                  While the RX FIFO is full the firmware holds SCL low, after
                  ACKing the byte.

   Bus conditions. A START is SDA falling while SCL is high; a STOP is SDA
   rising while SCL is high. Between transactions ([idle]) the firmware
   watches every SDA falling edge and checks SCL, so it also sees the
   repeated STARTs of other devices' transactions. Inside a write, a STOP or
   repeated START can only come where the first bit of a byte would be, so
   that bit gets a polling loop that watches SCL and SDA together; the
   other seven bits use plain waits. Both conditions go to [start], which
   waits for SCL to fall: after a repeated START that is the next address;
   after a STOP, SCL stays high until the next START, so it is the same.

   The address is compared after its seventh bit, during the R/W bit, so
   the ACK is on SDA 4 clocks after SCL falls. The first version compared
   the whole address byte after the eighth bit, which on a read put the ACK
   and a one-clock SCL pulse 10 to 11 clocks after SCL fell; the reference
   controller with SCL low for 10 clocks saw the pulse as an extra clock
   and flagged a cut byte.

   Branching on a pin. That loop must leave on either of two pins. The SCL
   exit is a [wait 1 pin 1 timeout] with TIMEOUT 0: it falls through while
   SCL is high and jumps to timeout_vector ([rest], the remaining 7 bits)
   the moment SCL is low. SDA is read through the OSR ([mov osr, pins] then
   [out x, 1]), which isolates pin 0 whatever the other pins are doing.
   The loop reads SDA first and SCL after it. A controller may change SDA
   as soon as SCL has fallen (the spec's minimum data hold time is 0), so
   an SDA change only counts as STOP or repeated START if SCL is still high
   afterwards. Checking SCL first and SDA second looks equivalent but is
   not: a data bit whose SDA moves in the same clock as SCL falls would
   read as a repeated START or a STOP. The tests keep that version as a
   planted bug, and only a controller with zero hold time catches it.

   Timing. The reference controller in the tests works down to an SCL low
   time of 7 core clocks, with a data hold time of one clock or of zero; the
   random tests cover 7 to 62. Its data setup time (SDA settled before SCL
   rises) must be at least 2 clocks, since [idle] reads SCL one clock after
   it sees SDA fall; that one is from reading the code, not measured. At 10
   MHz the I2C spec's fast mode (400 kHz) guarantees 13 clocks low and 1 of
   setup, so: standard mode, and fast mode from a controller with 2 clocks
   of setup or more (cocotbext-i2c's I2cMaster has 12). Not supported:
   general call (address 0), 10-bit addresses, and a STOP or START in the
   middle of a byte. *)
let i2c_target =
  {|
        .side_set 1
        pull                side 1 ; Y <- own 7-bit address, once
        mov y, osr          side 1
idle:   wait 1 pin 0        side 1 ; SDA high...
        wait 0 pin 0        side 1 ; ...then falling
        mov osr, pins       side 1
        out null, 1         side 1
        out x, 1            side 1 ; X = SCL as SDA fell
        jmp !x idle         side 1 ; SCL low: only a data bit
start:  mov isr, null       side 1 ; START or repeated START (or a STOP: see [event])
        in null, 1          side 1 ; a 0 on top, so 7 address bits fill the ISR
        wait 0 pin 1        side 1
abit:   wait 1 pin 1        side 1 ; address, MSB first
        in pins, 1          side 1
        wait 0 pin 1        side 1
        jmp !isrf abit      side 1
        mov x, isr          side 1 ; X = the 7-bit address
        jmp x!=y idle       side 1 ; not ours: no ACK, back to watching
        wait 1 pin 1        side 1 ; R/W bit
        mov osr, pins       side 1
        out x, 1            side 1 ; X = R/W: 0 write, 1 read
        in x, 1             side 1
        in null, 8          side 1 ; RX marker: (address << 1 | R/W) << 8
        wait 0 pin 1        side 1
ack:    set pins, 0         side 1 ; ACK: SDA low for the ninth clock
        wait 1 pin 1        side 1
        wait 0 pin 1        side 1
        set pins, 1         side 1 ; release SDA
        push                side 0 ; byte to the host; SCL held low while RX is full
        jmp !x wbyte        side 1
read:   pull                side 0 ; next byte to send; SCL held low until there is one
rbit:   out pins, 1         side 1 ; SDA = next bit while SCL is low
        wait 1 pin 1        side 1
        wait 0 pin 1        side 1
        jmp !osre rbit      side 1
        set pins, 1         side 1 ; release SDA for the controller's ACK
        wait 1 pin 1        side 1
        mov osr, pins       side 1
        out x, 1            side 1 ; X = SDA: 0 = ACK, 1 = NACK
        wait 0 pin 1        side 1
        jmp !x read         side 1 ; ACK: another byte
        jmp idle            side 1 ; NACK: wait for STOP or repeated START
wbyte:  wait 1 pin 1        side 1 ; first bit of a byte, or STOP, or repeated START
        in pins, 1          side 1
        mov x, isr          side 1 ; X = SDA at the rising edge
        jmp !x low          side 1
high:   mov osr, pins       side 1 ; SDA first...
        out x, 1            side 1
        jmp !x event        side 1
        wait 1 pin 1 timeout side 1 ; ...then SCL. Low: a data bit, on to [rest]
        jmp high            side 1
low:    mov osr, pins       side 1
        out x, 1            side 1
        jmp !x lsame        side 1
event:  wait 1 pin 1 timeout side 1 ; SDA moved. SCL low by now: it moved after SCL fell, data
        jmp start           side 1 ; SCL still high: repeated START, or STOP
lsame:  wait 1 pin 1 timeout side 1 ; SCL low: a data bit, on to [rest]
        jmp low             side 1
rest:   wait 1 pin 1        side 1 ; timeout vector: the other 7 bits
        in pins, 1          side 1
        wait 0 pin 1        side 1
        jmp !isrf rest      side 1
        set x, 0            side 1 ; X = 0: still a write
        jmp ack             side 1
|}
;;

(* Address of [rest:] in [i2c_target], its timeout vector. *)
let i2c_target_rest = 57

let i2c_target_config =
  { Isa.Thread_config.default with
    out_base = 0
  ; out_count = 1
  ; set_base = 0
  ; set_count = 1
  ; in_base = 0
  ; sideset_base = 1
  ; sideset_count = 1
  ; threshold = 8
  ; timeout = 0
  ; timeout_vector = i2c_target_rest
  ; in_msb_first = true
  }
;;

(* Host-side words for [i2c_target]. *)
let i2c_target_address_word address = address
let i2c_target_read_word byte = reverse_byte byte
let i2c_target_marker ~address ~read = ((address lsl 1) lor Bool.to_int read) lsl 8

(* SPI target (device mode): the chip answers as a mode-0 SPI device (SCK
   idles low, both sides sample on the rising edge and change on the
   falling one, MSB first), full duplex.

   Pins: P0 = SCK, P1 = MOSI, P3 = CS_N (inputs); P2 = MISO (push-pull).
   That is the pin map of [spi_controller] and [spi_fast], so one chip can
   be the controller and another the device on the same four wires.
   Config: [spi_target_config]: in_base 1 (MOSI), out_base 2 (MISO),
   threshold 8, IN shifts MSB first, TIMEOUT 0 and timeout_vector
   [spi_target_desel].

   Host protocol.
     TX : the reply bytes, one per byte the controller clocks, bit-reversed
          ([reverse_byte]; OUT shifts LSB first). One continuous stream
          across transfers: the reply to byte n of the whole session is TX
          word n. The firmware takes the next word as soon as a byte ends
          (and the first at start), so it holds one reply ahead.
     RX : each byte the controller sent (0 to 255), and after every
          transfer the marker 0x100, so the host can tell commands apart.

   SPI has no flow control, so the host must stay ahead. A thread can only
   take from its TX FIFO with a [pull] that waits, and the ISA has no
   non-blocking version (PIO's [pull noblock], which would let the firmware
   send a filler byte instead): if the next reply is not there when a byte
   ends, the firmware waits for it and misses the controller's next bits,
   until the next deselect resynchronises it. The same holds for a full RX
   FIFO.

   Every bit, the firmware polls for SCK rising and checks CS_N in the same
   loop, so a deselect is seen even in the middle of a byte; the partial
   byte is dropped. Branching on a pin is the same trick as in
   [i2c_target]: [wait 0 pin 3 timeout] with TIMEOUT 0 falls through while
   CS_N is low and jumps to the vector the moment it is high. SCK is read
   through the OSR, so the reply's unsent bits are parked in Y meanwhile.

   Timing: SCK may run up to core clock / 16 (625 kHz at 10 MHz; the tests
   find the reference controller works from 8 clocks per SCK phase, with or
   without gaps between bytes). Not supported: other SPI modes, and sharing
   MISO with other devices (it is always driven, even when deselected). *)
let spi_target =
  {|
        pull                ; the first reply byte
        out pins, 1         ; MISO = its bit 7, ready before the first edge
sel:    wait 0 pin 3        ; until selected
bit:    mov y, osr          ; park the reply's unsent bits
poll:   wait 0 pin 3 timeout ; deselected: to [desel]
        mov osr, pins
        out x, 1            ; X = SCK
        jmp !x poll
        mov osr, y          ; SCK rose: the reply bits back
        in pins, 1          ; sample MOSI
        wait 0 pin 0        ; SCK falls
        jmp !isrf next
        push                ; a whole byte received
        pull                ; the next reply byte
next:   out pins, 1         ; MISO = next bit, while SCK is low
        jmp bit
desel:  mov osr, y          ; CS_N rose: keep the reply for the next transfer
        mov isr, null       ; drop a partial byte
        set x, 1
        in x, 1
        in null, 8
        push                ; RX marker 0x100: end of transfer
        jmp sel
|}
;;

(* Address of [desel:] in [spi_target], its timeout vector. *)
let spi_target_desel = 16

let spi_target_config =
  { Isa.Thread_config.default with
    in_base = 1
  ; out_base = 2
  ; out_count = 1
  ; threshold = 8
  ; timeout = 0
  ; timeout_vector = spi_target_desel
  ; in_msb_first = true
  }
;;

let spi_target_reply_word byte = reverse_byte byte
let spi_target_end_marker = 0x100

(* JTAG controller (IEEE 1149.1): drives TCK, TMS and TDI and samples TDO,
   for any sequence of clocks the host asks for, so the host walks the TAP
   state machine, shifts instructions and reads or writes data registers.

   Pins: P0 = TCK (side-set), P1 = TMS, P2 = TDI (push-pull); P3 = TDO
   (input). Config: [jtag_config]: sideset_base 0, sideset_count 1;
   out_base 1, out_count 2; in_base 3; threshold 16.

   Host protocol, one scan at a time:
     TX word 0 : N - 1, for a scan of N clocks (1 to 65536)
     then      : ceil(N / 8) words of (TMS, TDI) pairs, LSB first: bits
                 2k and 2k + 1 are TMS and TDI for the k-th clock of the
                 word ([jtag_words] builds them)
     RX        : ceil(N / 8) words of TDO, one bit per clock, LSB first,
                 the last word right-justified when N is not a multiple of 8.
   TDO is sampled just before TCK rises, which is when the device holds it
   steady (it changes on the falling edge). TMS and TDI change while TCK is
   low.

   Timing: TCK is high for 2 ticks and low for 3 (more at word boundaries),
   so it runs at core clock / 5 at CLKDIV 1: 2 MHz at 10 MHz. TDO must
   settle within one core clock of TCK falling at CLKDIV 1 (the input
   synchroniser takes the rest); CLKDIV 2 gives it four. *)
let jtag =
  {|
        .side_set 1
next:   pull                side 0     ; X <- clocks - 1
        out x, 16           side 0
word:   pull                side 0     ; up to 8 clocks of (TMS, TDI)
bit:    out pins, 2         side 0     ; TMS and TDI while TCK is low
        in pins, 1          side 1 [1] ; TCK high: the device samples TMS and TDI
        jmp x-- more        side 0     ; TCK falls: the device moves TDO
        push                side 0     ; the scan is done: its last TDO bits
        jmp next            side 0
more:   jmp !osre bit       side 0
        push                side 0     ; 8 TDO bits
        jmp word            side 0
|}
;;

let jtag_config =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; out_base = 1
  ; out_count = 2
  ; in_base = 3
  ; threshold = 16
  }
;;

(* Host-side words for a scan: [tms] and [tdi] give one bit per clock. *)
let jtag_words ~tms ~tdi =
  let n = List.length tms in
  assert (n = List.length tdi && n >= 1 && n <= 65536);
  let pairs = List.zip_exn tms tdi |> List.chunks_of ~length:8 in
  (n - 1)
  :: List.map pairs ~f:(fun chunk ->
    List.foldi chunk ~init:0 ~f:(fun k acc (m, d) ->
      acc lor (Bool.to_int m lsl (2 * k)) lor (Bool.to_int d lsl ((2 * k) + 1))))
;;

(* TDO bits of a scan of [n] clocks from its RX words. *)
let jtag_tdo ~n words =
  List.concat_mapi words ~f:(fun w v ->
    List.init (min 8 (n - (8 * w))) ~f:(fun k -> (v lsr k) land 1 = 1))
;;

(* SWD (Arm Serial Wire Debug) clock engine: drives SWCLK and SWDIO and
   samples SWDIO, one bit per clock, for any number of clocks. The SWD
   protocol itself (line reset, the JTAG-to-SWD switch, request packets,
   parity, ACK, turnaround) is built by the host from these clocks, the way
   a CMSIS-DAP probe or the RP2040's PIO-based probe splits the work: the
   chip owns the timing, the host owns the framing. [host/protocol_emulator.py]
   has the framing (SwdController).

   SWDIO is one wire driven by both sides in turn, so it is open-drain with
   a pull-up: a 1 releases it, which is also how the host lets the target
   drive during turnaround, ACK and read data.

   Pins: P0 = SWCLK (side-set, push-pull), P1 = SWDIO (open-drain, pull-up
   required). Config: [swd_config]: sideset_base 0, sideset_count 1;
   out_base 1, out_count 1; in_base 1; threshold 16.

   Host protocol, per batch of clocks:
     TX word 0 : N - 1, for N clocks (1 to 65536)
     then      : ceil(N / 16) words, bit k = the SWDIO level for the k-th
                 clock of the word (1 = released)
     RX        : ceil(N / 16) words, bit k = SWDIO sampled just before the
                 k-th clock's rising edge (the target drives after a rising
                 edge and samples on one; so does this).
   SWCLK is high 2 ticks and low 3 (more at word boundaries): 2 MHz at
   10 MHz with CLKDIV 1. *)
let swd =
  {|
        .side_set 1
next:   pull                side 0     ; X <- clocks - 1
        out x, 16           side 0
word:   pull                side 0     ; up to 16 clocks of SWDIO bits
bit:    out pins, 1         side 0     ; SWDIO (1 = released) while SWCLK is low
        in pins, 1          side 1 [1] ; SWCLK rises: sample SWDIO just before
        jmp x-- more        side 0     ; SWCLK falls
        push                side 0     ; the batch is done: its last bits
        jmp next            side 0
more:   jmp !osre bit       side 0
        push                side 0     ; 16 sampled bits
        jmp word            side 0
|}
;;

let swd_config =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; out_base = 1
  ; out_count = 1
  ; in_base = 1
  ; threshold = 16
  }
;;

let swd_words bits =
  let n = List.length bits in
  assert (n >= 1 && n <= 65536);
  (n - 1)
  :: List.map (List.chunks_of bits ~length:16) ~f:(fun chunk ->
    List.foldi chunk ~init:0 ~f:(fun k acc b -> acc lor (Bool.to_int b lsl k)))
;;

let swd_sampled ~n words =
  List.concat_mapi words ~f:(fun w v ->
    List.init (min 16 (n - (16 * w))) ~f:(fun k -> (v lsr k) land 1 = 1))
;;

(* 1-Wire (Maxim/Analog Devices; DS18B20 temperature sensors, iButtons):
   the bus engine, at standard speed. A protocol this chip was not designed
   for: it was added as firmware alone, on the finished hardware.

   One wire, open-drain with a pull-up, carries everything. Every exchange
   starts with the host pulling the line low: a reset pulse (480 us or more,
   answered by every device's presence pulse) or a time slot (about 70 us).
   In a slot the host writes a 1 by releasing the line within 15 us, a 0 by
   holding it low for 60 us; it reads by writing a 1 and sampling the line
   15 us after the slot began, while a device sending a 0 holds it low.
   Writes and reads are therefore one operation, and the engine does only
   that: reset pulses, and runs of 1 to 8 slots, each slot both writing a
   bit and sampling the line. ROM commands, the search algorithm and CRC8
   are the host's (OneWire in host/protocol_emulator.py), the same split as
   the SWD engine.

   Timing is in ticks of 1 us: the host sets CLKDIV to the core clock in
   MHz (10 at 10 MHz). The delays follow Maxim's application note 126:
     reset : low 482 us; sample presence 70 us after release; then 413 us
             of recovery before the next exchange can start
     slot  : low 6 us; a 0 stays low to 65 us; sample at 15 us; release;
             recover 11 us. 76 us a slot
   Pins: P0 = DQ (open-drain, pull-up required). Config: [onewire_config]:
   set_base 0 and out_base 0, count 1; in_base 0; threshold 16; CLKDIV.

   Host protocol, one TX word per exchange:
     [0]     1 = a reset pulse; RX: 1 word, bit 0 = the line at the
             presence sample (0: a device answered)
     [3:1]   otherwise N - 1, for N slots (1 to 8)
     [11:4]  the bits to write, first slot in bit 4 (1-Wire sends least
             significant bit first). RX: 1 word, bit k = the line sampled
             in slot k *)
let onewire =
  {|
next:   pull                    ; [0] reset, [3:1] slots - 1, [11:4] bits
        out x, 1
        jmp !x slots
        set pins, 0             ; reset pulse: low 482 us
        set y, 29
rlow:   jmp y-- rlow [15]       ; 30 x 16 us
        set pins, 1             ; release
        set y, 3 [2]
rwait:  jmp y-- rwait [15]      ; 4 x 16 us
        nop [2]
        in pins, 1              ; 70 us after release: presence
        set y, 24
rrec:   jmp y-- rrec [15]       ; 25 x 16 us
        push [9]
        jmp next
slots:  out x, 3                ; X = slots - 1
slot:   set pins, 0 [5]         ; the slot begins: low 6 us
        out pins, 1 [8]         ; a 1 releases the line, a 0 keeps it low
        in pins, 1              ; 15 us into the slot: sample
        set y, 2
swait:  jmp y-- swait [15]      ; 3 x 16 us
        set pins, 1 [9]         ; release (65 us into the slot), recover
        jmp x-- slot
        push
        jmp next
|}
;;

let onewire_config =
  { Isa.Thread_config.default with
    set_base = 0
  ; set_count = 1
  ; out_base = 0
  ; out_count = 1
  ; in_base = 0
  ; threshold = 16
  }
;;

(* The TX word for a reset pulse, and for a run of 1 to 8 slots. *)
let onewire_reset_word = 1

let onewire_slots_word bits =
  let n = List.length bits in
  assert (n >= 1 && n <= 8);
  ((n - 1) lsl 1)
  lor List.foldi bits ~init:0 ~f:(fun k acc b -> acc lor (Bool.to_int b lsl (4 + k)))
;;

(* PS/2 (IBM keyboards and mice): the host side, on both threads. Like
   1-Wire, a protocol this chip was not designed for, added as firmware alone
   on the finished hardware.

   Two open-drain lines with pull-ups, DATA and CLK. The device makes every
   clock pulse, at 10 to 16.7 kHz, in both directions. A frame is 11 bits:
   start (0), 8 data bits least significant first, odd parity, stop (1).
     device to host : the device changes DATA while CLK is high; the host
                      reads it when CLK falls
     host to device : the host holds CLK low for at least 100 us, pulls DATA
                      low (the start bit) and releases CLK. The device then
                      clocks: the host changes DATA while CLK is low, the
                      device reads it when CLK rises. After the stop bit the
                      device pulls DATA low for one more clock, the ACK
   Pins: P0 = DATA, P1 = CLK, both open-drain; P2 push-pull, internal (see
   below). CLKDIV on both threads is the
   core clock in MHz, so a tick is 1 us, as for [onewire].

   The receiver, [ps2_rx], runs on thread 0 and never stops listening: it
   takes DATA at each falling edge of CLK and pushes 11 bits as one word,
     bit 0 start, bits 8:1 the byte, bit 9 parity, bit 10 stop.
   Every wait inside a frame has a timeout (TIMEOUT = 150 ticks; a clock
   phase is 50 us at most), which jumps to [ps2_rx_abandon]: a frame the
   device gave up, or the host's own 100 us of CLK low, is dropped, never
   pushed short.

   The transmitter, [ps2_tx], runs on thread 1. One TX word a byte:
     bits 7:0 the byte, bit 8 its odd parity, bit 9 a 1 (the stop bit, which
     releases DATA): [ps2_tx_word]; threshold 10.
   and one RX word back: 0 = the device acknowledged, 1 = it did not,
   3 = it never clocked (TIMEOUT, 20 ms; both lines released).

   The threads coordinate through a pin. A device counts its frame as sent
   once CLK has fallen for the 11th bit, and re-sends it if the host
   inhibits any earlier; so an inhibit that lands late in a frame, after
   the receiver has its 11 bits but before the device is done, would
   deliver a byte twice. The receiver therefore holds P2 (push-pull, by
   side-set, wired to nothing) low from a frame's first falling edge until
   it has pushed or abandoned it, and the transmitter waits for P2 to be
   high before it inhibits. A thread reads another's output with no delay,
   so the inhibit can land no later than a frame's second microsecond,
   where the device simply starts again.

   The receiver abandons the frame the
   inhibit looked like, then hears the device clock the host's byte and
   pushes that too, with the ACK where the stop bit would be: so the host
   reads back what was on the wire. For that the transmitter changes DATA
   3 us after CLK falls, after the receiver's sample (1 or 2 us after). *)
let ps2_rx =
  {|
        .side_set 1
idle:   wait 1 pin 1            side 1 ; CLK high: the bus is free, or a frame is over
        wait 0 pin 1            side 1 ; CLK falls: a frame begins
        jmp samp                side 0 ; P2 low from here: a frame is under way
next:   wait 1 pin 1 timeout    side 0 ; the rest of the clock pulse...
        wait 0 pin 1 timeout    side 0 ; ...and the next falling edge, or give up
samp:   in pins, 1              side 0 ; DATA at the falling edge
        jmp !isrf next          side 0
        push                    side 0 ; 11 bits
        jmp idle                side 1
gone:   mov isr, null           side 1 ; timeout vector: drop what was shifted in
        jmp idle                side 1
|}
;;

let ps2_rx_abandon = 9

(* PS/2: the transmitter, on thread 1. Pins, the TX word, the result word
   and how it shares the bus with the receiver are described at [ps2_rx]
   (examples/ps2_rx.s). Config: [Ps2.tx_config]. *)
let ps2_tx =
  {|
next:   pull                    ; [7:0] byte, [8] odd parity, [9] 1
        wait 1 pin 2            ; not while the receiver is inside a frame
        set pins, 1             ; CLK low, DATA released: inhibit the device
        set y, 12
inh:    jmp y-- inh [15]        ; 13 x 16 us = 208 us
        set pins, 0 [5]         ; DATA low too: the start bit, 6 us before...
        set pins, 2             ; ...CLK is released: request to send
bit:    wait 0 pin 1 timeout [2] ; the device clocks; CLK falls. 3 us on,
        out pins, 1             ; the next bit, while CLK is low
        wait 1 pin 1 timeout
        jmp !osre bit           ; 8 data bits, parity, stop (DATA released)
        wait 0 pin 1 timeout    ; the device's ACK clock
        in pins, 1              ; DATA: 0 = acknowledged
        push
        wait 1 pin 1 timeout
        jmp next
dead:   set pins, 3             ; timeout vector: release both lines
        set x, 3
        in x, 2
        push                    ; 3 = the device never clocked
        jmp next
|}
;;

let ps2_tx_dead = 16

let ps2_tx_word byte =
  let ones = Int.popcount (byte land 0xFF) in
  (byte land 0xFF) lor (Bool.to_int (ones % 2 = 0) lsl 8) lor (1 lsl 9)
;;

(* Both threads in one image: the receiver at 0, the transmitter after it. *)
module Ps2 = struct
  let rx_origin = 0
  let rx = Asm.assemble ~origin:rx_origin ps2_rx
  let tx_origin = rx_origin + Array.length rx
  let tx = Asm.assemble ~origin:tx_origin ps2_tx
  let image = Asm.link [ rx_origin, rx; tx_origin, tx ]

  (* [mhz]: the core clock, so that a tick is 1 us. *)
  let rx_config ~mhz =
    { Isa.Thread_config.default with
      start = rx_origin
    ; in_base = 0
    ; sideset_base = 2
    ; sideset_count = 1
    ; threshold = 11
    ; timeout = 150
    ; timeout_vector = rx_origin + ps2_rx_abandon
    ; clkdiv = mhz
    }
  ;;

  let tx_config ~mhz =
    { Isa.Thread_config.default with
      start = tx_origin
    ; set_base = 0
    ; set_count = 2
    ; out_base = 0
    ; out_count = 1
    ; in_base = 0
    ; threshold = 10
    ; timeout = 20_000
    ; timeout_vector = tx_origin + ps2_tx_dead
    ; clkdiv = mhz
    }
  ;;

  (* P0 and P1 open-drain, P2 push-pull, the rest inputs. *)
  let mode_bits = 0b01_10_10

  (* The byte in a word the receiver pushed, if the frame is well formed:
     start 0, odd parity, stop 1. *)
  let byte_of_frame w =
    let byte = (w lsr 1) land 0xFF in
    let parity = (w lsr 9) land 1 in
    if w land 1 = 0 && (w lsr 10) land 1 = 1 && (Int.popcount byte + parity) % 2 = 1
    then Some byte
    else None
  ;;
end

(* CAN (ISO 11898 classical CAN, through a transceiver): a node, on the two
   threads and the bit sampler. It sends data frames, receives every other
   node's and acknowledges them. Firmware alone, 11-bit identifiers.

   What it leaves out: error frames and the error counters behind them (it
   stays silent about a frame it finds wrong, as a node in the standard's
   error-passive state does, and simply does not acknowledge it); overload
   frames; extended identifiers, whose frames it neither receives nor
   acknowledges; answering remote frames, which is the host's business.

   Pins: P0 = RXD (input, through the synchroniser), P1 = TXD (push-pull;
   0 is dominant). P2 and P3 are taken: the sampler listens to P0 and shows
   what it recovers there, two pins on, so that P0 is still the line itself
   for the transmitter. A bit is 20 ticks for both threads and 20 samples
   for the sampler: one CLKDIV for all three, the core clock / (20 x bit
   rate): 4 for 125 kbit/s at 10 MHz. [Can.sampler] has the sampler's
   settings: every edge restarts its phase, the bit is taken 13 samples
   on, runs of equal bits are kept time through, and stuff bits are taken
   out, so the receiver sees a frame's bits and nothing else.

   The receiver, [can_rx], on thread 0. A pulse lasts one sample, which is
   one tick of this thread, so each `wait 1 pin 3` meets the next bit. The
   CRC register follows IN: every bit of the frame goes through it, and
   after the last bit of the CRC it holds 0 if the frame is good.

   It waits for a dominant bit, the start of a frame, and takes the 14 bits
   ID, RTR, IDE, r0. In r0, which is dominant in every frame, it looks at
   TXD: low means thread 1 is sending this very frame (it cannot still be
   low after losing arbitration, which is over by then), and a node does
   not receive or acknowledge its own frame. Then the DLC, as many bytes as
   it says (none in a remote frame; eight for 8 and above), and the 15 bits
   of the CRC. If the CRC register holds 0, it drives TXD low for the ACK
   slot: from 7 ticks after the pulse of the CRC delimiter, which is the
   end of that bit or a tick past it, for 20 ticks.
   After its own frame, after an extended one, and when it starts, it
   waits for the line to stay recessive for ten bit times before it takes
   a dominant bit for a start of frame. (After a frame with a wrong CRC it
   does not wait: the next frame may come eleven bit times after that
   one's last dominant bit, which can be five bits before its end. If the
   next dominant bit is another node's ACK or an error flag instead, what
   follows it reads as an extended frame or one more bad one.) That is a wait on RXD itself with
   TIMEOUT = 200 ticks, and [Can.rx_idle] is its vector: the recovered
   bits would not do, since with the stuff bits gone a frame's data can
   be recessive for any number of them.

   RX words for a frame: the 14 bits ID, RTR, IDE, r0; then DLC, data and
   CRC, 15 bits to a word, the last word short, and an empty word after it
   when they fill their words exactly; then 0xFFFF if the frame was good
   and acknowledged, 0xFFFE if not. Every other word is below 0x8000, so
   the two marks cannot be taken for data ([Can.rx_frames]).

   The transmitter, [can_tx], on thread 1, is described below. *)
let can_rx =
  {|
integ:  wait 1 pin 0            ; the line itself recessive...
        wait 0 pin 0 timeout    ; ...and for ten bit times: between frames
        jmp integ               ; it fell first: again
idle:   wait 1 pin 2            ; timeout vector. (An ACK may still show)
        wait 0 pin 2            ; a dominant bit: the start of a frame
        mov crc, null
        mov isr, null
        set y, 13
h:      wait 1 pin 3
        in pins, 1
        jmp y-- h               ; ID, RTR, IDE, r0
        mov osr, pins           ; r0 is on the bus now, dominant: whose?
        out null, 1
        out y, 1                ; TXD
        jmp !y integ            ; thread 1's: not received, not acknowledged
        mov osr, isr
        out null, 1             ; r0
        out x, 1                ; IDE
        jmp !x std
        jmp integ               ; an extended frame: not for this receiver
std:    out x, 1                ; RTR, kept in X
        push                    ; the first word
        set y, 3
d:      wait 1 pin 3
        in pins, 1
        jmp y-- d
        mov y, isr              ; the DLC
        jmp !x data
        jmp crc                 ; a remote frame has no data
data:   mov osr, isr
        out null, 3
        out x, 1                ; the DLC's top bit: 8 and above, 8 bytes
        jmp !x byte
        set y, 8
byte:   jmp y-- more
        jmp crc
more:   set x, 7
b:      wait 1 pin 3
        in pins, 1
        jmp x-- b
        jmp byte
crc:    set y, 14
c:      wait 1 pin 3
        in pins, 1
        jmp y-- c
        mov x, crc              ; 0: nothing left over, the frame is good
        wait 1 pin 3            ; the CRC delimiter
        jmp !x ack
        push                    ; bad: the bits left, then 0xFFFE
        jmp y-- bad
bad:    in y, 16
        jmp idle                ; the next dominant bit may be a new frame
ack:    nop [4]                 ; to the end of the delimiter
        set pins, 0 [15]        ; the ACK slot, one bit long
        nop [3]
        set pins, 1
        push                    ; the bits left, then 0xFFFF
        in y, 16
        jmp idle
|}
;;

(* CAN: the transmitter, on thread 1, with the framing on the chip: it
   stuffs the bits, computes the CRC, arbitrates and reads the ACK slot.
   Config: [Can.tx_config].

   A bit is 20 ticks here (the receiver's is 10, so this thread's CLKDIV is
   half the receiver's). Ticks are counted from the instruction that drives
   a bit, tick 0; the next bit is driven at tick 20, along every path.

   TX words: N - 1, then the N bits from the identifier to the end of the
   data, as they are before stuffing and with no CRC, 15 to a word, the
   first in bit 0 ([Can.tx_words]). Both must be in the FIFO before the bus
   is looked at, so the first bit never waits for the host; after that a
   word is needed every 15 bit times. One frame at a time: the next one's
   words must not be there until this one has reported.

   Stuffing. The last level sent is which of the two loops the thread is
   in, [z] after a dominant bit and [o] after a recessive one. The length
   of the run is the ISR's shift count: 11 after the first bit of a run,
   one more for each equal bit, and at 15, the threshold, the ISR counts as
   full: five equal bits, so the next bit is their opposite and is not
   taken from the OSR. The CRC register follows OUT, so it sees every bit
   of the frame and no stuff bit.

   The CRC. When Y runs out a field has ended. The 15 bits a word holds
   never end with the data (18 + 8 n is not a multiple of 15 for n up to
   8), so the OSR not empty means the data has just ended: the CRC
   register is moved to the OSR and goes out through the same loops, bit
   15 of it never sent. The OSR empty means that was the CRC.

   Arbitration. Fourteen ticks into every recessive bit it has sent, stuff
   bits included, the thread reads RXD. (One bit goes unread: a fifth
   recessive bit that is also the last of the data or of the CRC, where
   arbitration is long over.) Dominant: another node is driving,
   and it stops at once, takes the rest of the frame's bits from the FIFO
   unsent, and reports. The wait with TIMEOUT = 0 is that branch;
   [can_tx_lost] is the vector, used while waiting for an idle bus as well,
   which X being 0 tells apart. A wait that times out does not change
   PAGE, so the vector sets it.

   One RX word reports:
     0   a receiver acknowledged the frame
     1   the frame went out and nobody acknowledged it
     2   stopped: arbitration lost, or the bus dominant under a recessive
         bit. Send it again. *)
let can_tx =
  {|
next:   pull                    ; N - 1
        mov isr, osr            ; kept in the ISR while the bus is watched
        pull                    ; the first 15 bits, here before the frame starts
        set x, 0                ; X = 0 marks "waiting for the bus"
quiet:  set y, 24               ; the bus recessive for 11 bit times: 25 looks
q:      wait 1 pin 0 timeout [7]
        jmp y-- q
        wait 1 pin 0 timeout    ; a last look, then at once
        mov pins, x             ; 0: the start-of-frame bit (X is 0)
        mov y, isr              ; 1: N - 1
        mov crc, null           ; 2: the CRC from zero
        mov isr, null           ; 3
        in null, 11             ; 4: a run of one dominant bit
        set page, 1 [11]        ; 5..16
        jmp zo                  ; 17
        .page 0
end0:   jmp !osre de0           ; 7: a field has ended, on a dominant bit
        jmp tail                ; 8: it was the CRC
de0:    mov osr, crc            ; 8: it was the data. The CRC goes out next
        set y, 14 [6]           ; 9..15
        set page, 1             ; 16
        jmp zo                  ; 17
        .page 0
end1:   jmp !osre de1           ; 7: the same, on a recessive bit
        jmp tail
de1:    mov osr, crc            ; 8
        set y, 14 [2]           ; 9..11
        set page, 1             ; 12
        jmp ow                  ; 13: this bit is checked like any other
        .page 0
tail:   nop [10]                ; 9..19
        set pins, 1             ; 0: the CRC delimiter
        nop [15]                ; 1..16
        nop [3]                 ; 17..20: the ACK slot begins
        nop [12]                ; 1..13
        mov isr, null           ; 14
        in pins, 1              ; 15: RXD in the ACK slot
        push                    ; 0 if a receiver drove it
        jmp next
lost:   set page, 0             ; timeout vector: PAGE may be either
        jmp !x quiet            ; waiting for the bus: count again
d:      out null, 1             ; mid-frame: the rest of its bits, unsent
        jmp y-- d
        set x, 2
        mov isr, null
        in x, 16
        push
        jmp next
        .align
z:      nop [12]                ; 5..17: the last bit sent was dominant
zo:     out x, 1 [1]            ; 18..19: the next bit; the CRC takes it
        mov pins, x             ; 0
        jmp !x zs               ; 1
        mov isr, null           ; 2: recessive now, a run of one
        in null, 11             ; 3
        jmp y-- o               ; 4
        set page, 0             ; 5
        jmp end1                ; 6
        .page 1
zs:     in null, 1              ; 2: one more dominant bit
        jmp !isrf zc            ; 3
        mov isr, null [13]      ; 4..17: five. A recessive stuff bit is next
        in null, 11 [1]         ; 18..19
        set pins, 1             ; 0
        set x, 1 [2]            ; 1..3: X says what is on TXD, for the vector
        jmp y-- o               ; 4
        set page, 0             ; 5
        jmp end1                ; 6
        .page 1
zc:     jmp y-- z               ; 4
x0:     set page, 0             ; 5
        jmp end0                ; 6
        .page 1
o:      nop [8]                 ; 5..13: the last bit sent was recessive
ow:     wait 1 pin 0 timeout [3] ; 14..17: so the bus must be recessive too
        out x, 1 [1]            ; 18..19
        mov pins, x             ; 0
        jmp !x oz               ; 1
        in null, 1              ; 2: one more recessive bit
        jmp !isrf oc            ; 3
        jmp y-- os              ; 4: five. A dominant stuff bit is next
        mov isr, null [12]      ; 5..17: and the field ends with it
        in null, 11 [1]         ; 18..19
        set pins, 0             ; 0
        jmp x0 [3]              ; 1..4
os:     mov isr, null [8]       ; 5..13
        wait 1 pin 0 timeout [3] ; 14..17
        in null, 11 [1]         ; 18..19
        set pins, 0             ; 0
        jmp z [3]               ; 1..4
oz:     mov isr, null           ; 2: dominant now, a run of one
        in null, 11             ; 3
        jmp y-- z               ; 4
        set page, 0             ; 5
        jmp end0                ; 6
        .page 1
oc:     jmp y-- o               ; 4
        set page, 0             ; 5
        jmp end1                ; 6
|}
;;

module Can = struct
  (* The transmitter first: its two pages are the image's first two. The
     receiver is in a page of its own. *)
  let tx_origin = 0
  let tx = Asm.assemble ~origin:tx_origin can_tx
  let rx_origin = 2 * Isa.page_size
  let rx = Asm.assemble ~origin:rx_origin can_rx
  let image = Asm.link [ tx_origin, tx; rx_origin, rx ]

  (* The transmitter's timeout vector, and the receiver's. *)
  let tx_lost ?(origin = tx_origin) source = Asm.label ~origin source "lost"
  let rx_idle ?(origin = rx_origin) source = Asm.label ~origin source "idle"

  (* The CRC register's polynomial for CRC-15/CAN: 0x4599 with its 15 bits
     reversed, since the register shifts right. Bit 0 is then the CRC's
     most significant bit, the first sent. *)
  let crc_poly = List.fold (List.range 0 15) ~init:0 ~f:(fun acc k -> acc lor (((0x4599 lsr k) land 1) lsl (14 - k)))

  (* [clkdiv]: core clock / (20 x bit rate), for both threads and the
     sampler. *)
  let rx_config ~clkdiv =
    { Isa.Thread_config.default with
      start = rx_origin
    ; in_base = 2
    ; in_msb_first = true
    ; threshold = 15
    ; autopush = true
    ; set_base = 1
    ; set_count = 1
    ; clkdiv
    ; crc_poly
    ; crc_init = 0
    ; crc_in = true
    ; timeout = 200
    ; timeout_vector = rx_idle can_rx
    }
  ;;

  let tx_config ~clkdiv =
    { Isa.Thread_config.default with
      start = tx_origin
    ; out_base = 1
    ; out_count = 1
    ; set_base = 1
    ; set_count = 1
    ; in_base = 0
    ; threshold = 15
    ; autopull = true
    ; timeout = 0
    ; timeout_vector = tx_lost can_tx
    ; clkdiv
    ; crc_poly
    ; crc_init = 0
    }
  ;;

  (* The sampler: RXD on pin 0, 20 samples of [clkdiv] cycles to the bit,
     the bit taken 13 samples after an edge, never losing the carrier,
     stuff bits after five equal bits taken out, shown on pins 2 and 3. *)
  let sampler ~clkdiv =
    { Isa.Sampler_config.off with
      enable = true
    ; pin = 0
    ; misses = 7
    ; blank = 0
    ; sample = 13
    ; wrap = 19
    ; prescale = clkdiv
    ; shift = 2
    ; stuff = 5
    }
  ;;

  (* The transmitter's RX word. *)
  let acknowledged = 0
  let not_acknowledged = 1
  let stopped = 2

  (* P1 push-pull, the rest inputs. *)
  let mode_bits = 0b01_00

  (* CRC-15/CAN: polynomial 0x4599, over the bits from the start of frame
     to the end of the data, before stuffing. *)
  let crc15 bits =
    List.fold bits ~init:0 ~f:(fun crc b ->
      let top = (crc lsr 14) land 1 in
      let crc = (crc lsl 1) land 0x7FFF in
      if top lxor b = 1 then crc lxor 0x4599 else crc)
  ;;

  let msb_first ~width v = List.init width ~f:(fun k -> (v lsr (width - 1 - k)) land 1)

  (* A frame as bits on the wire (1 is recessive), from [body], which is
     its bits from the start-of-frame bit to the end of the data: the CRC
     after them, a stuff bit after every five equal bits up to the end of
     the CRC, then the CRC delimiter, the ACK slot (sent recessive) and the
     ACK delimiter. [crc] is a CRC to send in place of the right one. *)
  let wire_bits ?crc body =
    let body = body @ msb_first ~width:15 (Option.value crc ~default:(crc15 body)) in
    let stuffed, _, _ =
      List.fold body ~init:([], -1, 0) ~f:(fun (acc, last, run) b ->
        let run = if b = last then run + 1 else 1 in
        if run = 5 then (1 - b) :: b :: acc, 1 - b, 1 else b :: acc, b, run)
    in
    List.rev stuffed @ [ 1; 1; 1 ]
  ;;

  (* A data frame with an 11-bit identifier, or with [rtr] the remote frame
     that asks for it ([dlc] is then what it carries where the length
     goes). *)
  let frame_bits ?(rtr = false) ?dlc ~id ~data () =
    let n = List.length data in
    assert (id >= 0 && id < 0x800 && n <= 8);
    wire_bits
      (([ 0 ] @ msb_first ~width:11 id)
       @ [ Bool.to_int rtr; 0; 0 ]
       @ msb_first ~width:4 (Option.value dlc ~default:n)
       @ List.concat_map data ~f:(msb_first ~width:8))
  ;;

  (* The transmitter's words for a data frame: the bits from the identifier
     to the end of the data, 15 to a word. The start-of-frame bit, the
     stuffing and the CRC are the chip's. *)
  let tx_words ~id ~data =
    let n = List.length data in
    assert (id >= 0 && id < 0x800 && n <= 8);
    let bits =
      msb_first ~width:11 id @ [ 0; 0; 0 ] @ msb_first ~width:4 n @ List.concat_map data ~f:(msb_first ~width:8)
    in
    (List.length bits - 1)
    :: List.map (List.chunks_of bits ~length:15) ~f:(fun chunk ->
      List.foldi chunk ~init:0 ~f:(fun k acc b -> acc lor (b lsl k)))
  ;;

  (* The receiver's marks after a frame. *)
  let good = 0xFFFF
  let bad = 0xFFFE

  (* The frames in the receiver's RX words: for each, its identifier, its
     data and whether it is a remote frame, or [None] for one the receiver
     marked bad (or whose words do not fit a frame, which a good one's
     always do). Words after the last mark are a frame still arriving. *)
  let rx_frames words =
    let value bits = List.fold bits ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b) in
    let frame words =
      match words with
      | head :: rest when head < 0x4000 ->
        let id = head lsr 3
        and rtr = (head lsr 2) land 1 = 1 in
        (match rest with
         | first :: _ ->
           let dlc = first lsr 11 in
           let n = if rtr then 0 else Int.min dlc 8 in
           let total = 4 + (8 * n) + 15 in
           let full = total / 15
           and short = total % 15 in
           if List.length rest <> full + 1 || List.exists rest ~f:(fun w -> w >= 0x8000)
           then None
           else (
             let bits =
               List.concat_mapi rest ~f:(fun k w -> msb_first ~width:(if k < full then 15 else short) w)
             in
             let data = List.sub bits ~pos:4 ~len:(8 * n) in
             Some (id, List.map (List.chunks_of data ~length:8) ~f:value, rtr))
         | [] -> None)
      | _ -> None
    in
    let rec go acc current = function
      | [] -> List.rev acc
      | w :: rest when w = good -> go (frame (List.rev current) :: acc) [] rest
      | w :: rest when w = bad -> go (None :: acc) [] rest
      | w :: rest -> go acc (w :: current) rest
    in
    go [] [] words
  ;;
end

(* Low-speed USB engine (1.5 Mbit/s, so a 12 MHz core clock: 8 clocks per
   bit). It runs commands from its TX FIFO: send a packet, or receive one.
   Everything above the wire (SYNC, PID, CRC5, CRC16, bit stuffing, NRZI)
   is the host's ([Usb_model], and UsbHost in the board driver), the split
   RP2040 PIO-USB uses too; the engine owns the bit timing, EOP, the bus
   turnaround and clock recovery, which the host is far too slow for.

   The chip cannot release a push-pull pin by itself (pin modes are the
   host's), so it drives the bus through a standard USB 1.1 transceiver in
   its VO/FSE0 mode, as FPGA and microcontroller USB cores do: VO is the
   differential data (1 = D+ high = K at low speed), FSE0 forces SE0, OE_N
   enables the drivers, and VP / VM are the transceiver's single-ended
   receivers (D+ and D-).

   Pins: P0 = VP, P1 = VM (inputs, through the synchroniser); P2 = VO,
   P3 = FSE0, P4 = OE_N (push-pull; FSE0 and OE_N by side-set, value bit 0
   is FSE0). Config: [usb_config].

   Commands (TX FIFO):
     send    : N - 1 (bit 15 clear), for N line states (the packet without
               its EOP), then ceil(N / 16) words, bit k = VO for the k-th
               bit time ([usb_send_words]). The engine waits until the bus
               has been idle for at least two bit times, sends the packet at
               exactly 8 clocks per bit, word boundaries included, adds EOP
               (two bit times of SE0, one of J) and releases the bus.
     receive : [usb_receive] (bit 15 set). The engine waits for a packet
               (the first K of SYNC), records the line level of every bit
               (1 = K) until EOP, and pushes them 16 to a word, first in
               bit 0, the last word ending with a single 1 after the last
               bit ([usb_levels] reads them back). It waits as long as it
               takes: a host that gets no answer stops and restarts the
               thread.

   Receive timing: in each bit the engine waits for the edge that would
   leave the current level (VP falling on K, VM falling on J) with a timed
   wait of TIMEOUT = 2. An edge re-aligns it: two clocks after the edge is
   seen it samples both pins, so SE0 (EOP) is told from the new level. No
   edge: the timeout vector samples again one bit time on. Every sample is
   two to three clocks after the latest edge the synchroniser shows, which
   keeps it inside the bit whatever the sender's clock does between edges
   (bit stuffing guarantees one at least every seven bits).

   Turnaround: before sending, the bus is idle for 37 clocks after one of
   the engine's own packets and about 23 after a received one: 2 to 7.5 bit
   times, as USB 1.1 requires (7.1.18). *)
let usb =
  {|
        .side_set 2
next:   pull                side 2     ; a command; bus released
        out x, 15           side 2     ; X <- line states - 1
        out y, 1            side 2     ; bit 15: receive
        jmp !y send         side 2
        set y, 2            side 2     ; receive. Y = J, as {VM, VP}
        wait 1 pin 0        side 2     ; until the first K of SYNC
        jmp tok             side 2
tok:    mov osr, pins       side 2     ; the line went K (or SE0):
        out x, 2            side 2     ; X <- {VM, VP}: K 1, J 2, SE0 0
        jmp !x eop          side 2
        in x, 1             side 2     ; record VP
        jmp !isrf kw        side 2
        push                side 2
kw:     wait 0 pin 0 timeout side 2    ; on K, until VP falls
        jmp toj             side 2
toj:    mov osr, pins       side 2     ; the line went J (or SE0)
        out x, 2            side 2
        jmp !x eop          side 2
        in x, 1             side 2
        jmp !isrf jw        side 2
        push                side 2
        jmp jw              side 2
tmo:    mov osr, pins       side 2     ; timeout vector: no edge for a bit,
        out x, 2            side 2     ; the same level again
        in x, 1             side 2
        jmp !isrf same      side 2
        push                side 2
same:   jmp x!=y kw         side 2     ; still K; still J falls through, so
jw:     wait 0 pin 1 timeout side 2    ; both reach their wait in the same
        jmp tok             side 2     ; clocks. On J, until VM falls
eop:    set x, 1            side 2
        in x, 1             side 2     ; a 1 after the last bit marks the end
        push                side 2
        jmp next            side 2
send:   set y, 9            side 2     ; bus idle first: two bit times at
idle:   jmp y-- idle        side 2 [2] ; least after a received packet's EOP
        pull                side 2     ; the first 16 line states
        jmp bit             side 2
more:   jmp !osre pad       side 0
        pull                side 0 [1] ; word boundary, in the same 8 clocks
bit:    out pins, 1         side 0 [3] ; VO for this bit time, drivers on
        jmp x-- more        side 0
        nop                 side 0 [2] ; the last bit's 8 clocks
        set x, 4            side 1     ; EOP: SE0 for two bit times,
se0:    jmp x-- se0         side 1 [2]
        set pins, 0         side 0 [3] ; then J (VO = 0) for one,
        nop                 side 0 [3]
        jmp next            side 2     ; then release the bus
pad:    jmp bit             side 0 [1]
|}
;;

(* The timeout vector and the engine's idle point, relative to its origin
   (test_usb checks them against the assembled program). *)
let usb_tmo = 22
let usb_idle = 0

let usb_config ~origin =
  { Isa.Thread_config.default with
    start = origin
  ; in_base = 0
  ; out_base = 2
  ; out_count = 1
  ; set_base = 2
  ; set_count = 1
  ; sideset_base = 3
  ; sideset_count = 2
  ; threshold = 16
  ; timeout = 2
  ; timeout_vector = origin + usb_tmo
  }
;;

let usb_receive = 0x8000

(* Host words to send one packet, from its line states without the EOP (J
   and K only): VO = 1 for K. *)
let usb_send_words (lines : Usb_model.line list) =
  let n = List.length lines in
  assert (n >= 1 && n <= 0x8000);
  (n - 1)
  :: List.map (List.chunks_of lines ~length:16) ~f:(fun chunk ->
    List.foldi chunk ~init:0 ~f:(fun k acc (l : Usb_model.line) ->
      match l with
      | K -> acc lor (1 lsl k)
      | J -> acc
      | Se0 -> invalid_arg "usb_send_words: SE0 is the firmware's"))
;;

(* The line levels a receive recorded, from its words (the last carries the
   end marker). *)
let usb_levels words : Usb_model.line list =
  match List.rev words with
  | [] -> []
  | last :: earlier_rev ->
    (* No marker (a garbled receive): every bit, which will not decode. *)
    let top = if last = 0 then 16 else Int.floor_log2 last in
    let bits w n = List.init n ~f:(fun k -> (w lsr k) land 1 = 1) in
    List.concat_map (List.rev earlier_rev) ~f:(fun w -> bits w 16) @ bits last top
    |> List.map ~f:(fun b -> if b then Usb_model.K else Usb_model.J)
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

  (* MISO read directly; see [spi_fast]. *)
  let sync_bypass = 1 lsl 2
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

  (* MISO (P4) read directly; see [spi_fast]. I2C goes through the
     synchroniser. *)
  let sync_bypass = 1 lsl 4

  (* Host words for one I2C read of [count] bytes from [address]. *)
  let read_command ~address ~count =
    i2c_write_word ~stop:false ((address lsl 1) lor 1)
    :: List.init count ~f:(fun i -> i2c_read_word ~last:(i = count - 1))
  ;;
end

(* Low-speed USB host, as the board uses it: the engine [usb] on one
   thread and [echo] on the other relaying through CHAIN (thread 0's RX
   FIFO into thread 1's TX FIFO), so the FIFOs of both threads are one
   buffer of 13 words, on whichever side of the engine needs it. The host
   always writes commands to thread 0 and reads results from thread 1:
   - [Tx_buffered]: echo on thread 0, the engine on thread 1. The buffer is
     before the engine: for sending (a SETUP token and its 8-byte DATA0
     packet are 10 words), loaded with the engine stopped and then started
     with one CTRL write, so the packets go out at full speed however
     slowly the host fed them.
   - [Rx_buffered]: the engine on thread 0, echo on thread 1. The buffer is
     after the engine: for receiving (an 8-byte data packet is about 7
     words), so a slow host loses nothing.
   CHAIN moves words whether or not a thread runs, and a re-enabled thread
   starts again at its START. *)
module Usb_host = struct
  let relay_origin = 0
  let relay = Asm.assemble ~origin:relay_origin echo
  let engine_origin = relay_origin + Array.length relay
  let engine = Asm.assemble ~origin:engine_origin usb
  let image = Asm.link [ relay_origin, relay; engine_origin, engine ]
  let relay_config = { Isa.Thread_config.default with start = relay_origin }
  let engine_config = usb_config ~origin:engine_origin

  type layout =
    | Tx_buffered
    | Rx_buffered

  let engine_thread = function
    | Tx_buffered -> 1
    | Rx_buffered -> 0
  ;;

  let configs = function
    | Tx_buffered -> [ relay_config; engine_config ]
    | Rx_buffered -> [ engine_config; relay_config ]
  ;;

  (* P2, P3, P4 push-pull; the rest inputs. *)
  let mode_bits = 0b01_01_01_00_00
end

(* Full-duplex UART: [uart_tx] on thread 0 sending on P0, [uart_rx] on
   thread 1 receiving on P1, one memory image. *)
module Uart_duplex = struct
  let tx = Asm.assemble uart_tx
  let rx_origin = Array.length tx
  let rx = Asm.assemble ~origin:rx_origin (uart_rx ~pin:1)
  let image = Asm.link [ 0, tx; rx_origin, rx ]

  let tx_config =
    { Isa.Thread_config.default with
      out_base = 0
    ; out_count = 1
    ; set_base = 0
    ; set_count = 1
    ; threshold = 8
    }
  ;;

  let rx_config =
    { Isa.Thread_config.default with
      start = rx_origin
    ; in_base = 1
    ; threshold = 9
    ; timeout = 0
    ; timeout_vector = rx_origin + uart_rx_bad
    }
  ;;

  (* P0 push-pull (TX); P1 input (RX). *)
  let mode_bits = 0b00_01

  (* Host words to start each side at [divisor] cycles per bit. *)
  let tx_setup ~divisor = [ divisor - 4 ]
  let rx_setup ~divisor = [ divisor - 4; uart_rx_half ~divisor ]
end

(* I2S transmitter (Philips I2S, the bus between audio chips): the chip
   makes the bit clock and the word select and shifts out 16-bit stereo
   samples, most significant bit first.

   Pins: P0 = SCK and P1 = WS (side-set), P2 = SD, all push-pull. Config:
   [i2s_tx_config]: sideset_base 0, sideset_count 2; out_base 2,
   out_count 1; threshold 16; out_msb_first; start = [i2s_tx_start].

   Host protocol: TX words alternate left sample, right sample.

   On the wire, as the standard has it: SD and WS change while SCK is low
   and are read on its rising edge; WS is 0 for the left sample and 1 for
   the right, and changes one bit early, with the last bit of the sample
   before. So each sample's bits 15 to 1 go out under its own WS level and
   bit 0 under the next one's.

   Timing: SCK is 2 ticks low and 2 high, core clock / 4: 2.5 MHz at
   10 MHz, a 78.125 kHz sample rate; CLKDIV slows it. The fetch of the next
   sample fits inside the last bit, so the clock never stretches while the
   host keeps up. When the TX FIFO is empty the thread stalls with SCK low
   and the bus simply pauses. *)
let i2s_tx =
  {|
        .side_set 2
lbit:   out pins, 1      side 0 [1]   ; left bits 15..1: WS 0, SCK low
        jmp x-- lbit     side 1 [1]   ; SCK high
        out pins, 1      side 2       ; left bit 0, with WS already 1
        pull             side 2       ; the right sample
        set x, 14        side 3 [1]
rbit:   out pins, 1      side 2 [1]   ; right bits 15..1: WS 1
        jmp x-- rbit     side 3 [1]
        out pins, 1      side 0       ; right bit 0, with WS already 0
entry:  pull             side 0       ; the left sample
        set x, 14        side 1
        jmp lbit         side 1
|}
;;

let i2s_tx_start = 8

let i2s_tx_config =
  { Isa.Thread_config.default with
    start = i2s_tx_start
  ; sideset_base = 0
  ; sideset_count = 2
  ; out_base = 2
  ; out_count = 1
  ; threshold = 16
  ; out_msb_first = true
  }
;;

(* DMX512 transmitter (stage lighting, on RS-485): a break, a mark, then a
   start code and up to 512 slots, each one start bit, 8 data bits LSB
   first and two stop bits at 250 kbit/s.

   Pins: P0 = the line, push-pull (to an RS-485 driver). Config: threshold
   9, the rest as reset.

   Host protocol on the TX FIFO:
     word 0  : bit time - 4, in clock cycles: 36 for 250 kbit/s at 10 MHz
     then    : one word per slot: bit 0 = 1 to send a break and the mark
               after it first (so: on the start code), bits 8:1 the byte
               ([dmx_word])

   Timing: every bit is exactly one bit time, and back-to-back slots have
   two stop bits and one cycle more. (Two exactly is legal, but a receiver
   that samples on the bit boundaries then sees the next start bit in the
   sample where it looks for the idle line; sigrok's decoder is one.) The
   break is 9 x (4 x (bit time - 3) + 3) cycles,
   136 us at 10 MHz (the standard asks a transmitter for 92 us or more),
   and the mark after it 4 bit times, 16 us (12 us or more). Between slots
   the line idles high for as long as the host takes, which the standard
   allows up to a second. *)
let dmx_tx =
  {|
        set pins, 1
        pull                ; bit time - 4
        mov y, osr
next:   pull                ; the line stays high while waiting
        out x, 1            ; break first?
        jmp !x slot
        set pins, 0         ; break: 9 rounds of about 4 bit times
brk:    mov x, y
b:      jmp x-- b [3]
        in null, 1          ; count the rounds in the ISR's bit counter
        jmp !isrf brk
        set pins, 1         ; mark after break
        mov x, y
m:      jmp x-- m [3]
        mov isr, null       ; clear the round counter
slot:   set pins, 0 [1]     ; start bit
        mov x, y
start:  jmp x-- start
bit:    out pins, 1         ; data bit, LSB first
        mov x, y
hold:   jmp x-- hold
        jmp !osre bit
        set pins, 1 [1]     ; two stop bits and a cycle
        mov x, y
stop:   jmp x-- stop [1]
        jmp next
|}
;;

let dmx_word ~break byte = Bool.to_int break lor (byte lsl 1)

(* Wiegand transmitter (card readers and keypads): two lines, D0 and D1,
   both idle high; a 0 is a short low pulse on D0, a 1 a short low pulse on
   D1.

   Pins: P0 = D0, P1 = D1, push-pull or open-drain. Config:
   [wiegand_tx_config]: set_base 0, set_count 2; threshold 16; CLKDIV sets
   the tick: 250 for 25 us at 10 MHz.

   Host protocol, one frame at a time:
     TX word 0 : N - 1, for a frame of N bits (26 and 34 are the common
                 formats; parity bits are the host's to work out)
     then      : ceil(N / 16) words, first bit sent in bit 0

   Timing, in ticks: the pulse is 2 and bits are exactly 40 apart, also
   where a word ends: 50 us and 1 ms with a 25 us tick, which is what
   readers send. *)
let wiegand_tx =
  {|
        set pins, 3         ; both lines idle high
frame:  pull                ; X <- bits - 1
        out x, 16
word:   pull
bit:    out y, 1
        jmp !y zero
        set pins, 1         ; a 1: D1 low
        jmp gap
zero:   set pins, 2 [1]     ; a 0: D0 low
gap:    set pins, 3 [15]
        nop [15]
        jmp x-- more
        jmp frame
more:   jmp !osre same      ; both ways round take 3 ticks
        pull
        jmp bit
same:   jmp bit [1]
|}
;;

let wiegand_tx_config = { Isa.Thread_config.default with set_count = 2; threshold = 16 }

(* NEC infrared transmitter (the commonest remote-control code), carrier
   included: the pin drives an IR LED directly. A frame is a 9 ms burst of
   carrier, 4.5 ms of silence, then 32 bits, each a 562.5 us burst followed
   by 562.5 us of silence for a 0 or 1687.5 us for a 1, and a final burst.

   Pins: P0 = the LED, push-pull, high = lit. Config: [nec_tx_config]:
   sideset_base 0, sideset_count 1; threshold 16; CLKDIV sets the tick to
   half a carrier period: 132 for 37.9 kHz at 10 MHz.

   Host protocol, one frame at a time:
     TX word 0 : carrier periods in the leading burst, less one: 341
     TX word 1 : address in bits 7:0, its complement in 15:8 (or the high
                 address byte, in the extended form)
     TX word 2 : command in bits 7:0, its complement in 15:8
   ([nec_words]). Bits go out LSB first, as NEC has them.

   Timing, in ticks of 13.2 us: a burst is 21 carrier periods (554 us), a
   0 is 85 ticks from burst to burst (1.122 ms; NEC: 1.125) and a 1 is 170
   (2.244 ms; 2.25). The carrier is high one tick and low one. *)
let nec_tx =
  {|
        .side_set 1
frame:  pull               side 0     ; carrier periods in the leader - 1
        mov x, osr         side 0
lead:   nop                side 1     ; 9 ms of carrier
        jmp x-- lead       side 0
        set x, 20          side 0     ; 4.5 ms of silence
gap1:   jmp x-- gap1       side 0 [7]
        set x, 20          side 0
gap2:   jmp x-- gap2       side 0 [7]
        set y, 1           side 0     ; two words of 16 bits
word:   pull               side 0
bit:    set x, 20          side 0     ; a burst of 21 periods
mark:   nop                side 1
        jmp x-- mark       side 0
        out x, 1           side 0     ; the bit
        jmp !x short       side 0
        set x, 20          side 0     ; a 1: two more units of silence
long:   jmp x-- long       side 0 [3]
short:  set x, 18          side 0
space:  jmp x-- space      side 0 [1]
        jmp !osre bit      side 0
        jmp y-- word       side 0
        set x, 20          side 0     ; the final burst
last:   nop                side 1
        jmp x-- last       side 0
        jmp frame          side 0
|}
;;

let nec_tx_config =
  { Isa.Thread_config.default with sideset_base = 0; sideset_count = 1; threshold = 16 }
;;

let nec_words ~address ~command =
  [ 341; address lor ((address lxor 0xFF) lsl 8); command lor ((command lxor 0xFF) lsl 8) ]
;;

(* MDIO controller (IEEE 802.3 clause 22, the management bus of Ethernet
   PHYs): a clock and one data line, 32 ones of preamble and then a 32-bit
   frame, MSB first, of which the PHY drives the last 17 bits in a read.

   Pins: P0 = MDC (side-set, push-pull); P1 = MDIO, open-drain with the
   bus's pull-up, so writing a 1 releases the line for the PHY. Config:
   [mdio_config]: sideset_base 0, sideset_count 1; out_base 1, in_base 1;
   threshold 16; both shift directions MSB first.

   Host protocol: every TX word is 16 bits shifted out, and comes back as an
   RX word of the 16 bits read on the line at the same time. A frame is
   four words: 0xFFFF, 0xFFFF, the header ([mdio_header]), and the data to
   write or 0xFFFF to read. In a read the fourth RX word is the register,
   and bit 0 of the third is the PHY's turnaround bit: 0 when one answered.

   Timing, in cycles: MDC is 2 low and 2 high (5 low between words, or as
   long as the host takes); MDIO
   changes one cycle after MDC falls, which gives a PHY one cycle of setup
   and two of hold. What is shifted in is the line as it stood one cycle
   before MDC rose (the synchroniser's two cycles are counted in that), so a
   PHY has three cycles after one rising edge to drive the bit for the
   next. At 10 MHz with CLKDIV 1 that is MDC at 2.5 MHz and exactly the
   300 ns the standard allows a PHY, with nothing to spare; the driver's
   default is CLKDIV 2, 1.25 MHz, which leaves 300 ns of margin. *)
let mdio =
  {|
        .side_set 1
next:   pull           side 0
bit:    out pins, 1    side 0       ; MDC low: the next bit goes out
        nop            side 1       ; MDC rises
        in pins, 1     side 1       ; the line as it was just before
        jmp !osre bit  side 0       ; MDC falls
        push           side 0
        jmp next       side 0
|}
;;

let mdio_config =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; out_base = 1
  ; in_base = 1
  ; threshold = 16
  ; out_msb_first = true
  ; in_msb_first = true
  }
;;

(* Start 01, then 01 to write or 10 to read, the PHY and register numbers,
   and the turnaround: 10 driven in a write, released (11) in a read. *)
let mdio_header ~read ~phy ~reg =
  (0b01 lsl 14)
  lor ((if read then 0b10 else 0b01) lsl 12)
  lor (phy lsl 7)
  lor (reg lsl 2)
  lor if read then 0b11 else 0b10
;;

(* DALI forward frame transmitter (lighting control): 1200 bit/s
   Manchester code on a bus that idles high. A frame is a start bit (a 1),
   16 bits MSB first (address byte, command byte) and the bus idle
   again. A 1 is low for the first half of the bit and high for the second;
   a 0 the other way round.

   Pins: P0 = the bus level, push-pull (to a DALI driver; high = idle).
   Config: [dali_tx_config]: sideset_base 0, sideset_count 1; threshold 16;
   out_msb_first; CLKDIV sets the tick to 1/8 of a half bit: 521 for
   52.1 us at 10 MHz.

   Host protocol: one TX word per frame, address in bits 15:8 and command
   in 7:0.

   Timing, in ticks: every half bit is exactly 8, whatever the bits either
   side of it, and each frame is followed by 256 of idle bus (13.3 ms: DALI
   asks for 9.2 ms between forward frames).

   The bit loop is written twice, once for a bus that is high and once for
   one that is low, because fetching the next bit takes two ticks and the
   bus must hold its level meanwhile. *)
let dali_tx =
  {|
        .side_set 1
frame:  pull            side 1        ; the bus idles high
        set y, 16       side 1        ; 16 bits after the start bit
        nop             side 0 [7]    ; start bit, a 1: the low half
hi:     jmp y-- get_h   side 1 [5]    ; high half of a 1 (2 more in get_h)
        jmp stop        side 1
get_h:  out x, 1        side 1
        jmp !x zero     side 1
        jmp hi          side 0 [7]    ; a 1: the low half
zero:   nop             side 1 [7]    ; a 0: the high half
lo:     jmp y-- get_l   side 0 [5]    ; low half of a 0 (2 more in get_l)
        jmp stop        side 0 [1]
get_l:  out x, 1        side 0
        jmp !x zero     side 0
        jmp hi          side 0 [7]    ; a 1: the low half
stop:   set x, 31       side 1
idle:   jmp x-- idle    side 1 [7]
        jmp frame       side 1
|}
;;

let dali_tx_config =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; threshold = 16
  ; out_msb_first = true
  }
;;

(* RC-5 infrared transmitter (Philips remote controls), carrier included:
   14 bits of Manchester code, 1.778 ms each: two start bits, a toggle bit,
   5 address bits and 6 command bits, MSB first. A 1 is half a bit of
   silence and then half a bit of 36 kHz carrier; a 0 the other way round.

   Pins: P0 = the LED, push-pull, high = lit. Config: [rc5_tx_config]:
   sideset_base 0, sideset_count 1; threshold 14; out_msb_first; CLKDIV
   sets the tick to half a carrier period: 139 for 36.0 kHz at 10 MHz.

   Host protocol: one TX word per frame, the 14 bits in bits 15:2
   ([rc5_word]).

   Timing, in ticks of 13.9 us: a burst is exactly 32 carrier periods (64
   ticks, 890 us), and where a 1 is followed by a 0 their two bursts are one
   unbroken burst of 64 periods, which is why the program looks a bit ahead
   before each burst. Silences are 64 ticks, or 65 between two 0s. A frame
   is followed by 89 ms of silence, so frames repeat every 114 ms as RC-5
   has them. *)
let rc5_tx =
  {|
        .side_set 1
frame:  pull             side 0
        set y, 13        side 0        ; 13 more bits after the first
fetch:  out x, 1         side 0        ; a bit that arrives in silence
        jmp !x zero      side 0
one:    set x, 28        side 0        ; a 1: silence first
s1:     jmp x-- s1       side 0 [1]
        jmp y-- look     side 0        ; look at the bit after it
        jmp last         side 0        ; there is none
look:   out x, 1         side 0
        jmp !x long      side 0
        set x, 31        side 0        ; a 1 follows: 32 periods of carrier,
b1:     nop              side 1        ; then on to that 1's silence
        jmp x-- b1       side 0
        jmp one          side 0
zero:   set x, 31        side 0        ; a 0: carrier first
b0:     nop              side 1
        jmp x-- b0       side 0
        jmp sil          side 0
long:   set x, 30        side 0        ; a 0 follows a 1: their bursts are
l1:     nop              side 1        ; one, 64 periods long
        jmp x-- l1       side 0
        set x, 31        side 1        ; (the 32nd period, while reloading)
        nop              side 0
l2:     nop              side 1
        jmp x-- l2       side 0
sil:    set x, 29        side 0        ; the 0's silence
s0:     jmp x-- s0       side 0 [1]
        jmp y-- fetch    side 0
        jmp stop         side 0
last:   set x, 31        side 0        ; the last bit, a 1: its burst
b2:     nop              side 1
        jmp x-- b2       side 0
stop:   set y, 24        side 0        ; silence after the frame
gap:    set x, 31        side 0
g:      jmp x-- g        side 0 [7]
        jmp y-- gap      side 0
        jmp frame        side 0
|}
;;

let rc5_tx_config =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; threshold = 14
  ; out_msb_first = true
  }
;;

(* Two start bits, the toggle bit (which a remote flips on each new key
   press), address and command, left-aligned in the word. *)
let rc5_word ~toggle ~address ~command =
  ((0b11 lsl 12) lor (Bool.to_int toggle lsl 11) lor (address lsl 6) lor command) lsl 2
;;

(* Wiegand receiver: the reader's side of [wiegand_tx], taking the bits a
   card reader or keypad sends on D0 and D1.

   Pins: P0 = D0, P1 = D1, inputs, with the pull-ups the bus has. They must
   be pins 0 and 1: the program looks at both lines at once by copying all
   eight pins and taking the first two. Config: [wiegand_rx_config]:
   in_base 0, threshold 16, in_msb_first.

   Host protocol, one frame at a time:
     TX word : N - 1, for a frame of N bits; the thread then waits for it
     RX      : ceil(N / 16) words, 16 bits each and whatever is left in the
               last, the first bit received in the top bit of each

   The lines are looked at every 5 cycles, so a pulse of a microsecond is
   seen at 10 MHz (readers send 20 us and more). The bit is D0's level
   during the pulse: low in a 0's pulse, high in a 1's. A frame that stops
   short leaves its bits waiting for the rest; the host notices by the
   time it takes, and stops and starts the thread to clear them. *)
let wiegand_rx =
  {|
frame:  pull                ; N - 1
        mov y, osr
poll:   mov osr, pins       ; all eight pins as they are now
        out x, 1            ; D0
        jmp !x pulse        ; low: a 0 is arriving
        out x, 1            ; D1
        jmp x-- poll        ; high as well: look again
pulse:  in pins, 1          ; D0 is the bit
        wait 1 pin 0        ; until the pulse is over
        wait 1 pin 1
        jmp y-- more
        push                ; that was the last bit: send what is left
        jmp frame
more:   jmp !isrf poll
        push                ; 16 bits: send them
        jmp poll
|}
;;

let wiegand_rx_config =
  { Isa.Thread_config.default with in_base = 0; threshold = 16; in_msb_first = true }
;;

(* NEC infrared receiver: the other end of [nec_tx], on the output of an IR
   receiver module, which is low while it sees carrier.

   Pins: P0 = the module's output (the program tests pin 0 by number).
   Config: [nec_rx_config]: start = [nec_rx_start]; in_base 0; threshold
   16; timeout 128, timeout_vector 0; CLKDIV sets the tick to 1/16 of NEC's
   562.5 us unit: 352 for 35.2 us at 10 MHz.

   Host protocol: RX words come in pairs. A frame is the address in bits
   7:0 with its complement (or the high address byte) in 15:8, then the
   command and its complement. A frame that was cut short after its first
   word is completed with 0x0000, which no command word can be, so the
   pairs never slip. Checking the complements is the host's part.

   How a frame is told from everything else, times in units of 562.5 us:
     - its first burst must still be there after 5 units (the leader is 16;
       a bit's burst is 1);
     - the silence after it must still be there after 4.5 units (it is 8;
       a repeat code's is 4, and is ignored);
     - each bit is read about 1.3 units after its burst ends: silence
       still, a 1 (whose silence is 3 units); the next burst already, a 0
       (1 unit). The thread is back waiting for that burst to end well
       before it does: a remote may run 20% fast or slow, with room to
       spare;
     - a wait of more than 8 units for a bit's burst to begin or end
       abandons the frame, through the timeout vector. X remembers whether
       a word has gone to the host yet. *)
let nec_rx =
  {|
abort:  jmp !x start            ; cut short before any word went: start again
        mov isr, null
        in null, 16
        push                    ; after one: zeros in the command's place
start:  mov isr, null           ; nothing received yet
        wait 0 pin 0            ; a burst begins
        set x, 4
lead:   jmp x-- lead [15]       ; 5 units later
        mov osr, pins
        out x, 1
        jmp !x leader           ; still there: a frame's leading burst
        jmp start               ; gone: something else
leader: wait 1 pin 0            ; the leading burst ends
        set x, 3
gap:    jmp x-- gap [15]        ; 4.5 units later
        nop [4]
        mov osr, pins
        out x, 1
        jmp !x start            ; a burst already: a repeat code
        set x, 0                ; no word sent yet
        set y, 31               ; 32 bits
bit:    wait 0 pin 0 timeout    ; the bit's burst begins
        wait 1 pin 0 timeout    ; and ends
        jmp !isrf same          ; 16 bits waiting? Send them now, in the
        push                    ; silence, not after a read, when the next
        set x, 1                ; burst may already be on its way out
        jmp read
same:   nop [2]                 ; (as long as sending takes)
read:   nop [15]                ; about 1.3 units after the burst
        in pins, 1              ; silence still: a 1. The next burst: a 0
        jmp y-- bit
        push                    ; the second word
        jmp start
|}
;;

let nec_rx_start = 4

let nec_rx_config =
  { Isa.Thread_config.default with
    start = nec_rx_start
  ; in_base = 0
  ; threshold = 16
  ; timeout = 128
  ; timeout_vector = 0
  }
;;

(* DALI receiver: the other direction of [dali_tx], for one thread with the
   bit sampler in front of it. A controller reads a gear's 8-bit answers
   with it; it reads 16- and 24-bit frames the same way.

   A frame starts with an edge that is not in the middle of a bit (the bus
   falls for the start bit's first half), so the sampler is not locked to
   the middles of bits, as it is for Ethernet. It is set to take every
   edge and a sample every half bit: what reaches this program is the
   bus's level in each half bit, from the start bit's first half on. The
   prescaler makes a sample 1/10 of a half bit, and this thread's CLKDIV
   is the same number, so each of the sampler's pulses is one tick long.

   Pins: P1 = the bus as received, high when idle (input); P2 is taken by
   the sampler's pulse. Config: [dali_rx_config ~clkdiv], sampler:
   [dali_rx_sampler ~clkdiv], with CLKDIV 417 for 1200 bit/s at 10 MHz.

   Host protocol, for each frame:
     RX : the half bits, 16 to a word, the first received in the top bit;
          the last word holds what is left, lowest bits, and is empty if
          nothing is; then 0x10000 minus the number of half bits.
   [dali_rx_frame] pairs the half bits up into the frame's bits. After
   the last bit the bus is idle and two or three high half bits follow
   before the sampler gives up: two high in one bit is not a bit, and that
   is how the end is told from data.

   The count is how the host finds the end of a frame's words: it is
   0xFF00 or more for anything under 256 half bits, and no other word can
   be, because the sampler never passes more than three equal half bits
   in a row and the last word's top bits are clear ([dali_rx_frames]).
   When the sampler is switched on it reports the idle bus once, as three
   high half bits: that is no frame, like any other report without a
   start bit. A frame that begins inside that report is still read: high
   half bits before a frame's first low one are the idle bus.

   Timing: an edge is taken whenever it comes, and each half bit is
   sampled in its middle counting from the last edge. Two half bits can
   pass between edges, so a sender 15% fast or slow is read (DALI allows
   10%). *)
let dali_rx =
  {|
rx:     mov x, null
        jmp x-- first           ; X = 0xFFFF: it counts the half bits, downwards
first:  wait 1 pin 2            ; a frame's first half bit
half:   in pins, 1              ; take it; sixteen make a word
        wait 1 pin 2 timeout    ; the next, or the end of the frame
        jmp x-- half
eof:    push                    ; what is left of the last word
        in x, 16                ; then the count
        jmp rx
|}
;;

(* [eof] above: where the thread goes when the half bits stop. *)
let dali_rx_eof = 6

let dali_rx_config ~clkdiv =
  { Isa.Thread_config.default with
    in_base = 1
  ; threshold = 16
  ; autopush = true
  ; in_msb_first = true
  ; timeout = 24
  ; timeout_vector = dali_rx_eof
  ; clkdiv
  }
;;

(* Ten samples to the half bit. Every edge is accepted (blank 0), the level
   is taken five samples after an edge or after the last half bit's end,
   and three half bits without an edge end the frame: inside a frame there
   is never more than one. *)
let dali_rx_sampler ~clkdiv =
  { Isa.Sampler_config.off with
    enable = true
  ; pin = 1
  ; misses = 2
  ; blank = 0
  ; sample = 5
  ; wrap = 9
  ; prescale = clkdiv
  }
;;

(* The bits of the frame [dali_rx] pushed as [words], start bit left out,
   or why they are not one frame. *)
let dali_rx_frame (words : int list) =
  match List.rev words with
  | [] | [ _ ] -> Error "fewer than two words"
  | count :: rev_data ->
    let n = (0x10000 - count) land 0xFFFF in
    let data = List.rev rev_data in
    if List.length data <> (n / 16) + 1
    then Error (sprintf "%d half bits counted but %d words" n (List.length data))
    else (
      let halves =
        List.concat_mapi data ~f:(fun k w ->
          let width = min 16 (n - (16 * k)) in
          List.init width ~f:(fun i -> (w lsr (width - 1 - i)) land 1))
      in
      (* The bus idle before the frame, as when the sampler has just been
         switched on: a frame begins low. *)
      let halves = List.drop_while halves ~f:(fun h -> h = 1) in
      let rec bits acc = function
        | 0 :: 1 :: rest -> bits (1 :: acc) rest
        | 1 :: 0 :: rest -> bits (0 :: acc) rest
        | 0 :: 0 :: _ -> Error "low for a whole bit: not DALI's code"
        | [] | [ _ ] | 1 :: 1 :: _ -> Ok (List.rev acc)
        | _ -> Error "a half bit that is neither 0 nor 1"
      in
      match bits [] halves with
      | Ok (1 :: frame) -> Ok frame
      | Ok _ -> Error "no start bit"
      | Error _ as e -> e)
;;

(* Every frame in the words [dali_rx] pushed: a word of 0xFF00 or more is
   a count and ends one. Words after the last count are a frame still
   arriving, and are left out. *)
let dali_rx_frames (words : int list) =
  let frames, _ =
    List.fold words ~init:([], []) ~f:(fun (frames, current) w ->
      if w >= 0xFF00 then dali_rx_frame (List.rev (w :: current)) :: frames, [] else frames, w :: current)
  in
  List.rev frames
;;

(* RC-5 infrared receiver: the other end of [rc5_tx], on the output of an
   IR receiver module, which is low while it sees carrier. One thread with
   the bit sampler in front of it, used as it is for Ethernet at a
   five-thousandth of the speed.

   A frame's first edge is in the middle of its first bit (a 1: silence,
   then carrier), and every bit has an edge in its middle. The sampler
   locks to those, ignores the edges between bits, and takes each bit a
   quarter of a bit after its middle edge: carrier there is a 1. The
   prescaler makes a sample 1/20 of a bit, and this thread's CLKDIV is the
   same number, so each of the sampler's pulses is one tick long.

   Pins: P0 = the module's output (input); P1 is taken by the sampler's
   pulse. Config: [rc5_rx_config ~clkdiv], sampler: [rc5_rx_sampler
   ~clkdiv], with CLKDIV 889 for RC-5's 1.778 ms bit at 10 MHz.

   Host protocol: one RX word for each frame, its 14 bits in bits 13:0,
   the first received highest: two start bits, the toggle bit, 5 address
   bits and 6 command bits ([rc5_word] shifted down by two). A
   transmission of fewer than 14 bits is dropped.

   Timing: a middle edge is accepted from 3/4 of a bit to 1.4 bits after
   the last, so a remote 20% fast or slow is read. *)
let rc5_rx =
  {|
rx:     mov isr, null           ; (a frame cut short comes back here)
        set y, 13               ; 14 bits
        wait 1 pin 1            ; a frame's first bit
bit:    in pins, 1
        jmp y-- next
        push                    ; the frame
        jmp rx
next:   wait 1 pin 1 timeout    ; the next bit, or the frame was cut short
        jmp bit
|}
;;

let rc5_rx_config ~clkdiv =
  { Isa.Thread_config.default with
    in_base = 0
  ; threshold = 14
  ; in_msb_first = true
  ; timeout = 40
  ; timeout_vector = 0
  ; clkdiv
  }
;;

(* Twenty samples to the bit. The edge between two bits shows 10 samples
   after the one in the middle and is ignored; the next middle edge shows
   20 after, and is accepted from 15 on. The bit is the level 5 samples
   after its middle edge, inverted: the module is low for carrier. With no
   edge by 28 samples the frame is over. *)
let rc5_rx_sampler ~clkdiv =
  { Isa.Sampler_config.off with
    enable = true
  ; pin = 0
  ; invert = true
  ; misses = 0
  ; blank = 15
  ; sample = 5
  ; wrap = 28
  ; prescale = clkdiv
  }
;;

(* Microwire controller, as the 93Cxx serial EEPROMs speak it: chip select
   high for a transfer, one bit to the device and one from it on every
   clock, any number of bits.

   Microwire is SPI's older relative, but the SPI engines do not fit it:
   chip select is active high, and a transfer is not a whole number of
   bytes (a 93C46 command is a start bit, two opcode bits and six address
   bits, with sixteen data bits after it one way or the other).

   Pins: P0 = CS (push-pull, high for a transfer), P1 = SK (side-set), P2 =
   DI, to the device; P3 = DO, from it. Config: [microwire_config]:
   sideset_base 1, sideset_count 1; set_base 0, set_count 1; out_base 2,
   out_count 1; in_base 3; threshold 16; autopull, autopush; out and in
   most significant bit first. A bit is 5 ticks, SK low for 3 and high for
   2: CLKDIV 3 for 667 kHz at 10 MHz.

   The device takes DI as SK rises and changes DO just after; DO is read
   one tick after SK rises, so the bit read on a clock is the device's
   answer to that clock. DO comes through the input synchroniser, which
   takes two cycles, so a tick must be at least three: CLKDIV 3 or more.

   Host protocol:
     TX : the number of bits, less one; then the bits to send, 16 to a
          word, the first in the top bit (a last word's bits at its top).
     RX : the bits read, one for every clock, 16 to a word, first in the
          top bit; the last word holds what is left, lowest bits, and is
          empty when nothing is. *)
let microwire =
  {|
        .side_set 1
idle:   set pins, 0         side 0     ; CS low: no transfer
        pull                side 0     ; the number of bits, less one
        out y, 16           side 0
        set pins, 1         side 0     ; CS high
bit:    out pins, 1         side 0 [1] ; DI while SK is low
        nop                 side 1     ; SK rises: the device takes the bit
        in pins, 1          side 1     ; and its answer is read before SK falls
        jmp y-- bit         side 0
        push                side 0     ; what is left of the last word
        jmp idle            side 0
|}
;;

let microwire_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 1
  ; sideset_count = 1
  ; set_base = 0
  ; set_count = 1
  ; out_base = 2
  ; out_count = 1
  ; in_base = 3
  ; threshold = 16
  ; autopull = true
  ; autopush = true
  ; out_msb_first = true
  ; in_msb_first = true
  ; clkdiv
  }
;;

(* The TX words for a transfer of [bits] (0 or 1 each, in order). *)
let microwire_words (bits : int list) =
  let n = List.length bits in
  (n - 1)
  :: List.map (List.chunks_of bits ~length:16) ~f:(fun chunk ->
    List.foldi chunk ~init:0 ~f:(fun i acc b -> acc lor (b lsl (15 - i))))
;;

(* The bits read in a transfer of [n] bits, from its RX words. *)
let microwire_read ~n (words : int list) =
  List.concat_mapi words ~f:(fun k w ->
    let width = max 0 (min 16 (n - (16 * k))) in
    List.init width ~f:(fun i -> (w lsr (width - 1 - i)) land 1))
;;

(* A 93C46 with 16-bit words (64 of them): the bits of its commands. *)
module Eeprom93c46 = struct
  let field ~width v = List.init width ~f:(fun i -> (v lsr (width - 1 - i)) land 1)
  let command ~opcode ~address = (1 :: field ~width:2 opcode) @ field ~width:6 address

  (* The clocks of a read: the command, whose last clock is answered with
     a dummy 0, then one for each of the word's 16 bits. *)
  let read ~address = command ~opcode:0b10 ~address @ List.init 16 ~f:(fun _ -> 0)
  let write ~address ~value = command ~opcode:0b01 ~address @ field ~width:16 value
  let write_enable = command ~opcode:0b00 ~address:0b110000
  let write_disable = command ~opcode:0b00 ~address:0b000000

  (* The word in what a read's clocks read back; bit 8 of them is the
     dummy 0, by which a device shows it is there. *)
  let read_value (bits : int list) =
    List.fold (List.drop bits 9) ~init:0 ~f:(fun acc b -> (acc lsl 1) lor b)
  ;;
end

(* HDMI-CEC initiator: the one-wire control bus between HDMI devices. It
   sends messages and reads each block's acknowledgement.

   A message is a start bit (low 3.7 ms, high 0.8 ms) and then blocks of
   ten bits: eight of data, most significant first, EOM (1 on the last
   block) and ACK. Every bit is 2.4 ms long and begins with the line low:
   for 0.6 ms it is a 1, for 1.5 ms a 0. The initiator sends the ACK bit
   as a 1, and a follower that accepts the block holds the line low to
   make it a 0.

   Pins: P0 = the CEC line, open-drain. Config: [cec_config]: set_base 0,
   set_count 1; in_base 0; out most significant bit first; CLKDIV makes a
   tick 0.1 ms: 1000 at 10 MHz.

   Host protocol:
     TX : one word for each block: the byte in bits 15:8, EOM in bit 7,
          and in bit 6 a 1 if the message is to everyone (address 15).
          The first block of a message is its header: the initiator's
          address in the top four bits, the destination's in the low four.
     RX : one word for each block sent: the line 1.0 ms into its ACK bit,
          0 if a follower held it low.
   A message to one device is acknowledged by a 0; in a message to
   everyone a 0 is a follower's objection. Either way a block that fails
   ends the message there, as the standard asks: the blocks still queued
   for it are taken from the FIFO and not sent, so the host sees fewer
   words than it queued blocks, the last of them the failure.

   The next block must be in the FIFO before the last one's ACK bit is
   over, or the line stays idle and the followers give the message up.
   After a message the program keeps off the bus for seven bit times, as
   an initiator that wants to send again must.

   It does not listen before it sends, or give way to another initiator. *)
let cec =
  {|
idle:   pull                    ; a message's first block
        set pins, 0 [15]        ; start bit: low for 3.7 ms,
        nop [15]
        nop [4]
        set pins, 1 [5]         ; then high for 0.8 ms
block:  set y, 8                ; 9 bits: the block's 8 and EOM
bit:    out x, 1
        set pins, 0 [4]         ; every bit begins low: 0.6 ms for a 1,
        jmp !x zero
        set pins, 1 [14]        ; and high for the rest of its 2.4 ms
        jmp next
zero:   nop [8]                 ; 1.5 ms for a 0
        set pins, 1 [6]
next:   jmp y-- bit
        nop                     ; (the last bit's high time, as inside the loop)
        set pins, 0 [5]         ; ACK bit: sent as a 1,
        set pins, 1 [3]
        in pins, 1              ; and 1.0 ms after its edge the line is low if a follower holds it
        mov y, isr
        push                    ; the line as it was read
        jmp !y low
        out y, 1                ; high: right only in a message to everyone
        jmp !y abort
        jmp cont
low:    out y, 1 [1]            ; low: right only in a message to one device
        jmp !y cont
        jmp abort
cont:   jmp !x more             ; X is the bit sent last: EOM
end:    set y, 10               ; end of message: seven bit times off the bus
free:   jmp y-- free [15]
        jmp idle
more:   pull [2]                ; the next block: its first bit begins 2.4 ms after the ACK bit did
        jmp block
abort:  jmp x-- end             ; the message ends here; was that its last block?
        pull                    ; no: take the rest of it from the FIFO, unsent
        out null, 8
        out x, 1
        jmp abort
|}
;;

let cec_config ~clkdiv =
  { Isa.Thread_config.default with set_base = 0; set_count = 1; in_base = 0; out_msb_first = true; clkdiv }
;;

(* The TX words for a message from [initiator] to [destination] (15:
   everyone) with the bytes [data] after the header. *)
let cec_words ~initiator ~destination data =
  let blocks = ((initiator lsl 4) lor destination) :: data in
  let last = List.length blocks - 1 in
  List.mapi blocks ~f:(fun i b ->
    (b lsl 8) lor (Bool.to_int (i = last) lsl 7) lor (Bool.to_int (destination = 15) lsl 6))
;;

(* Infrared burst sender: bursts of carrier with silences between them, each
   a whole number of carrier periods. The remote control codes are all
   made of these; which bursts and silences make a frame is the host's
   business, so one program sends any of them. RC-6 is sent with it
   ([rc6_words]); RC-5 and NEC have programs of their own, written before
   this one.

   Pins: P0 = the LED, push-pull, high = lit (side-set). Config:
   [ir_tx_config]: sideset_base 0, sideset_count 1; out most significant
   bit first; CLKDIV makes a tick half a carrier period: 139 for 36 kHz at
   10 MHz.

   Host protocol: one TX word for a burst and the silence after it: the
   burst's carrier periods, less one, in bits 15:8, and the silence's, less
   three, in bits 7:0. The silence is counted from the end of the burst's
   last period to the start of the next burst, and the three are the ticks
   this program spends fetching the next word: that word must be in the
   FIFO by then, or the silence grows. *)
let ir_tx =
  {|
        .side_set 1
next:   pull                side 0     ; a burst and the silence after it
        out x, 8            side 0     ; carrier periods, less one
        out y, 8            side 0     ; periods of silence, less three
mark:   nop                 side 1     ; a carrier period: lit for a tick,
        jmp x-- mark        side 0     ; dark for a tick
space:  jmp y-- space       side 0 [1] ; silence, a period at a time
        jmp next            side 0
|}
;;

let ir_tx_config ~clkdiv =
  { Isa.Thread_config.default with sideset_base = 0; sideset_count = 1; out_msb_first = true; clkdiv }
;;

(* The TX words for [runs]: (carrier periods, periods of silence after). *)
let ir_tx_words (runs : (int * int) list) =
  List.map runs ~f:(fun (mark, space) -> ((mark - 1) lsl 8) lor (space - 3))
;;

(* An RC-6 frame, mode 0, as bursts and silences in units of 16 carrier
   periods (444 us at 36 kHz): a leader of 6 lit and 2 dark; a start bit, a
   1; three mode bits, 0; the toggle bit, twice as long as the others; 8
   address bits and 8 command bits, most significant first. A 1 is lit then
   dark, a 0 dark then lit: the other way round from RC-5. The frame ends
   with 6 units dark. *)
let rc6_runs ~toggle ~address ~command =
  let bit ?(width = 1) b = if b = 1 then [ 1, width; 0, width ] else [ 0, width; 1, width ] in
  let field ~width v = List.init width ~f:(fun i -> (v lsr (width - 1 - i)) land 1) in
  let levels =
    [ 1, 6; 0, 2 ]
    @ bit 1
    @ List.concat_map [ 0; 0; 0 ] ~f:bit
    @ bit ~width:2 (Bool.to_int toggle)
    @ List.concat_map (field ~width:8 address @ field ~width:8 command) ~f:bit
    @ [ 0, 6 ]
  in
  (* Runs of the same level joined, then paired: lit, and the dark after. *)
  let joined =
    List.fold levels ~init:[] ~f:(fun acc (level, n) ->
      match acc with
      | (l, m) :: rest when l = level -> (l, m + n) :: rest
      | _ -> (level, n) :: acc)
    |> List.rev
  in
  let rec pairs = function
    | (1, mark) :: (0, space) :: rest -> (16 * mark, 16 * space) :: pairs rest
    | [] -> []
    | _ -> assert false
  in
  pairs joined
;;

let rc6_words ~toggle ~address ~command = ir_tx_words (rc6_runs ~toggle ~address ~command)

(* Step and direction, for stepper motor drivers (A4988, DRV8825 and the
   like): a direction level and one pulse for each step, at an exact
   period.

   Pins: P0 = STEP (side-set), P1 = DIR, both push-pull. Config:
   [stepper_config]: sideset_base 0, sideset_count 1; out_base 1, out_count
   1; out most significant bit first; CLKDIV sets the tick: 10 for 1 us at
   10 MHz.

   Host protocol, for each move at one speed:
     TX : the direction in bit 15 and the number of steps, less one, in
          bits 14:0; then the period of a step in ticks, less four.
     RX : one word, 0, when the move's last step has been made.
   STEP is high for two ticks of every period, and DIR is set three ticks
   before a move's first step. A ramp is several moves, each at its own
   speed; a move's first step comes six ticks after the last period of the
   move before has run out, while the next two words are fetched. *)
let stepper =
  {|
        .side_set 1
next:   pull                side 0     ; a move: direction, and steps less one
        out pins, 1         side 0     ; DIR
        out y, 15           side 0
        pull                side 0     ; the period, less four
step:   mov x, osr          side 1     ; STEP rises
        nop                 side 1     ; and is high for two ticks
low:    jmp x-- low         side 0     ; low for the rest of the period
        jmp y-- step        side 0
        push                side 0     ; the move is made
        jmp next            side 0
|}
;;

let stepper_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; out_base = 1
  ; out_count = 1
  ; out_msb_first = true
  ; threshold = 16
  ; clkdiv
  }
;;

(* The TX words for a move of [steps] (1 to 32768) at [period] ticks a
   step, forwards (DIR high) or not. *)
let stepper_words ~forwards ~steps ~period =
  [ (Bool.to_int forwards lsl 15) lor (steps - 1); period - 4 ]
;;

(* AM2302 / DHT22 and DHT11 humidity and temperature sensors: one wire,
   the sensor answering a start pulse with 40 bits whose length is their
   value.

   Pins: P0 = the data line, open-drain, with the sensor's pull-up. Config:
   [dht_config]: threshold 16, autopush, in most significant bit first;
   timeout 60 and timeout_vector [dht_fail]; CLKDIV makes a tick 5 us: 50
   at 10 MHz.

   Host protocol:
     TX : one word to take a reading: how long to hold the line low to
          start, in units of 40 us, less one: 32 (1.3 ms) for an AM2302,
          500 (20 ms) for a DHT11.
     RX : four words: the humidity, the temperature, the checksum (8 bits),
          and 0 if the sensor sent all 40 bits or 1 if it stopped
          answering, with 0 for every bit after the one it stopped in.

   On the wire the sensor answers a released line with 80 us low and 80 us
   high, then sends each bit as 50 us low and a high of 26 us for a 0 or
   70 us for a 1. The line is read 40 to 45 us after it rises: a 0 is over
   by then and a 1 is not. Any level that lasts 300 us ends the reading. *)
let dht =
  {|
idle:   pull                    ; a reading: how long the start is
        mov x, osr
        set pins, 0             ; the start: the line held low,
low:    jmp x-- low [7]         ; 40 us at a time
        set pins, 1             ; and let go
        set y, 4                ; five bytes
        set x, 7                ; of eight bits
        wait 0 pin 0 timeout    ; the sensor's answer: low,
        wait 1 pin 0 timeout    ; and high
bit:    wait 0 pin 0 timeout    ; a bit begins: low,
        wait 1 pin 0 timeout    ; then high
        nop [6]
        in pins, 1              ; 40 to 45 us into the high
        jmp x-- bit
        set x, 7
        jmp y-- bit
        push                    ; the checksum: the last 8 bits
        in null, 16             ; all 40 read
        jmp idle
fail:   in null, 1              ; the sensor stopped: 0 for each bit not read,
        jmp x-- fail
        set x, 7
        jmp y-- fail
        push
        set x, 1
        in x, 16                ; and a 1 to say so
        jmp idle
|}
;;

let dht_fail = 19

let dht_config ~clkdiv =
  { Isa.Thread_config.default with
    threshold = 16
  ; autopush = true
  ; in_msb_first = true
  ; timeout = 60
  ; timeout_vector = dht_fail
  ; clkdiv
  }
;;

(* The TX word for a start pulse of [start_us]. *)
let dht_word ~start_us = (start_us / 40) - 1

(* A reading from the four RX words: relative humidity and temperature in
   tenths, as an AM2302 sends them (the temperature's top bit is its
   sign). *)
let dht_reading = function
  | [ humidity; temperature; checksum; 0 ] ->
    let sum = (humidity lsr 8) + (humidity land 0xFF) + (temperature lsr 8) + (temperature land 0xFF) in
    if sum land 0xFF <> checksum
    then Error "checksum"
    else Ok (humidity, if temperature land 0x8000 <> 0 then -(temperature land 0x7FFF) else temperature)
  | [ _; _; _; _ ] -> Error "the sensor stopped answering"
  | _ -> Error "not four words"
;;

(* A stream of levels at an exact rate: each bit of each TX word is the
   level of one pin for one cell. The codes that are a line switched at a
   fixed rate are all made with it; which cells make a frame is the host's
   business. Qi packets ([qi_cells]), EM4100 tags ([em4100_cells]) and
   Morse code ([morse_cells]) are sent with it.

   Pins: P0 = the line, push-pull, low until the first word. Config:
   [bitstream_config]: threshold 16, autopull, out most significant bit
   first; a cell is two ticks, so CLKDIV is the clock over twice the cell
   rate.

   Host protocol: TX words, 16 cells each, the first cell in bit 15. A word
   is fetched as the last cell of the one before leaves, with no gap, as
   long as it is in the FIFO by then; if it is not, the line holds its
   level until a word comes. So a frame ends on the level the line should
   rest at, and the host has 16 cells to supply each word. *)
let bitstream =
  {|
        set pins, 0             ; the line starts low
cell:   out pins, 1             ; a cell; the last of a word fetches the next
        jmp cell
|}
;;

let bitstream_config ~clkdiv =
  { Isa.Thread_config.default with threshold = 16; autopull = true; out_msb_first = true; clkdiv }
;;

(* Cells as TX words, the last word filled out with [idle]. *)
let bitstream_words ?(idle = 0) cells =
  List.chunks_of cells ~length:16
  |> List.map ~f:(fun chunk ->
    let chunk = chunk @ List.init (16 - List.length chunk) ~f:(fun _ -> idle) in
    List.fold chunk ~init:0 ~f:(fun acc c -> (acc lsl 1) lor c))
;;

(* A Qi packet as the power receiver sends it to the charger (by load
   modulation; this is the modulating signal), two cells to a bit, 2 kbit/s:
   the line changes at the start of every bit, and in the middle of a 1 as
   well. A preamble of [preamble] ones (11 to 25), then each byte as a
   start bit 0, eight data bits least significant first, an odd parity bit
   and a stop bit 1: the header, the message, and a checksum that is the
   exclusive or of them all. The line is low before the packet. After the
   stop bit it changes once more, which is what lets a demodulator time
   that bit, rests there for two bit times, and is low again by the end. *)
let qi_cells ?(preamble = 11) ~header message =
  let bytes = header :: message in
  let checksum = List.fold bytes ~init:0 ~f:( lxor ) in
  let byte b =
    let data = List.init 8 ~f:(fun i -> (b lsr i) land 1) in
    (0 :: data) @ [ 1 lxor List.fold data ~init:0 ~f:( lxor ); 1 ]
  in
  let bits = List.init preamble ~f:(fun _ -> 1) @ List.concat_map (bytes @ [ checksum ]) ~f:byte in
  let level = ref 0 in
  let cells =
    List.concat_map bits ~f:(fun b ->
      let first = 1 - !level in
      let second = if b = 1 then 1 - first else first in
      level := second;
      [ first; second ])
  in
  cells @ List.init 4 ~f:(fun _ -> 1 - !level) @ List.init 8 ~f:(fun _ -> 0)
;;

(* How long a Qi message is, from its header: the standard's table. *)
let qi_message_length header =
  if header < 0x20
  then 1
  else if header < 0x80
  then 2 + ((header - 32) / 16)
  else if header < 0xE0
  then 8 + ((header - 128) / 8)
  else 20 + ((header - 224) / 4)
;;

(* An EM4100 tag's 64 bits as a reader sees them, Manchester coded, two
   cells to a bit (a bit is 64 periods of the 125 kHz field: 512 us): nine
   ones; the 8-bit version and 32-bit number as ten groups of four bits,
   each followed by its even parity; four column parities; and a stop bit
   0. A 1 is high then low. A tag repeats them for as long as it is in the
   field: [repeats] times here, and the line is low again after the
   last. *)
let em4100_bits ~version ~id =
  let nibbles =
    List.init 2 ~f:(fun i -> (version lsr (4 * (1 - i))) land 0xF)
    @ List.init 8 ~f:(fun i -> (id lsr (4 * (7 - i))) land 0xF)
  in
  let row n = List.init 4 ~f:(fun i -> (n lsr (3 - i)) land 1) in
  let parity bits = List.fold bits ~init:0 ~f:( lxor ) in
  List.init 9 ~f:(fun _ -> 1)
  @ List.concat_map nibbles ~f:(fun n -> row n @ [ parity (row n) ])
  @ List.init 4 ~f:(fun column -> parity (List.map nibbles ~f:(fun n -> (n lsr (3 - column)) land 1)))
  @ [ 0 ]
;;

let em4100_cells ?(repeats = 1) ~version ~id () =
  List.concat (List.init repeats ~f:(fun _ -> em4100_bits ~version ~id))
  |> List.concat_map ~f:(fun b -> if b = 1 then [ 1; 0 ] else [ 0; 1 ])
  |> fun cells -> cells @ [ 0 ]
;;

let morse_code =
  [ 'a', ".-"; 'b', "-..."; 'c', "-.-."; 'd', "-.."; 'e', "."; 'f', "..-."; 'g', "--."; 'h', "...."
  ; 'i', ".."; 'j', ".---"; 'k', "-.-"; 'l', ".-.."; 'm', "--"; 'n', "-."; 'o', "---"; 'p', ".--."
  ; 'q', "--.-"; 'r', ".-."; 's', "..."; 't', "-"; 'u', "..-"; 'v', "...-"; 'w', ".--"; 'x', "-..-"
  ; 'y', "-.--"; 'z', "--.."; '0', "-----"; '1', ".----"; '2', "..---"; '3', "...--"; '4', "....-"
  ; '5', "....."; '6', "-...."; '7', "--..."; '8', "---.."; '9', "----."
  ]
;;

(* Morse code, one cell to a dot: a dash is three dots long, the gap inside
   a letter one, between letters three and between words seven. Seven
   cells of silence end the text. *)
let morse_cells text =
  String.split (String.lowercase text) ~on:' '
  |> List.filter ~f:(fun w -> not (String.is_empty w))
  |> List.map ~f:(fun word ->
    String.to_list word
    |> List.map ~f:(fun c ->
      List.Assoc.find_exn morse_code c ~equal:Char.equal
      |> String.to_list
      |> List.map ~f:(fun mark -> if Char.equal mark '-' then [ 1; 1; 1 ] else [ 1 ])
      |> List.intersperse ~sep:[ 0 ]
      |> List.concat)
    |> List.intersperse ~sep:[ 0; 0; 0 ]
    |> List.concat)
  |> List.intersperse ~sep:(List.init 7 ~f:(fun _ -> 0))
  |> List.concat
  |> fun cells -> cells @ List.init 7 ~f:(fun _ -> 0)
;;

(* TDM audio (the DSP or PCM format of audio codecs): one data line
   carrying a frame of several 16-bit samples, one slot after another, with
   a pulse on the frame sync line to mark where the frame begins.

   Pins: P0 = BCLK and P1 = FSYNC (side-set), P2 = DATA, all push-pull.
   Config: [tdm_tx_config]: sideset_base 0, sideset_count 2; out_base 2,
   out_count 1; threshold 16; out most significant bit first.

   Host protocol: the first TX word is the slots in a frame, less one;
   after it one word per sample, slot 0 of
   the first frame first.

   On the wire: DATA and FSYNC change as BCLK falls and are read as it
   rises. FSYNC is high for one bit, the one before a frame's first: the
   last bit of the frame before (and one clock with nothing in it ahead of
   the first frame). Samples go most significant bit first.

   Timing: BCLK is 2 ticks low and 2 high, as in [i2s_tx]. The next sample
   is fetched inside the last bit, so the clock never stretches while the
   host keeps up; with the TX FIFO empty the thread stalls with BCLK low. *)
let tdm_tx =
  {|
        .side_set 2
        pull              side 0       ; slots in a frame, less one
        mov isr, osr      side 0       ; kept in the ISR
        mov y, isr        side 0
        jmp sync          side 0
bit:    out pins, 1       side 0 [1]   ; bits 15..2 of a sample: BCLK low,
        jmp x-- bit       side 1 [1]   ; and high
        out pins, 1       side 0 [1]   ; bit 1
        jmp !y last       side 1       ; the frame's last slot?
        nop               side 1
        out pins, 1       side 0       ; bit 0
        pull              side 0       ; the next slot's sample
        set x, 13         side 1
        jmp y-- bit       side 1
last:   mov y, isr        side 1       ; slots, for the next frame
sync:   out pins, 1       side 2       ; bit 0 with FSYNC high
        pull              side 2       ; the next frame's first sample
        set x, 13         side 3
        jmp bit           side 3
|}
;;

let tdm_tx_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 2
  ; out_base = 2
  ; out_count = 1
  ; threshold = 16
  ; out_msb_first = true
  ; clkdiv
  }
;;

(* The TX words for [frames], each a list of [slots] samples. *)
let tdm_words ~slots frames = (slots - 1) :: List.concat frames

(* TLC5620 (a serial quad 8-bit DAC): 11 bits clocked in, a pulse on LOAD
   to put them in the chosen DAC's latch, and a pulse on LDAC to bring the
   latched values to all four outputs together.

   Pins: P0 = CLK (side-set), P1 = DATA, P2 = LOAD, P3 = LDAC, all
   push-pull. Config: [tlc5620_config]: sideset_base 0, sideset_count 1;
   out_base 1, out_count 1; set_base 2, set_count 2; out most significant
   bit first; a tick of 100 ns or more (CLKDIV 1 at 10 MHz, 5 at 50 MHz).

   Host protocol: one TX word per write ([tlc5620_word]): the DAC (0 to 3)
   in bits 15:14, the range bit (1 doubles the output) in bit 13, the value
   in bits 12:5, and bit 4 set to pulse LDAC after it. With LDAC pulsed
   only on the last of several writes, their outputs change together.

   On the wire: DATA changes as CLK rises and the DAC takes it as CLK
   falls; LOAD and LDAC are low for three ticks. *)
let tlc5620 =
  {|
        .side_set 1
        set pins, 3       side 0       ; LOAD and LDAC high
next:   pull              side 0       ; a write
        set x, 10         side 0
bit:    out pins, 1       side 1       ; DATA, as CLK rises
        jmp x-- bit       side 0       ; taken as CLK falls
        set pins, 2       side 0 [2]   ; LOAD low: into the DAC's latch
        set pins, 3       side 0
        out x, 1          side 0       ; the outputs too?
        jmp !x next       side 0
        set pins, 1       side 0 [2]   ; LDAC low
        set pins, 3       side 0
        jmp next          side 0
|}
;;

let tlc5620_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; out_base = 1
  ; out_count = 1
  ; set_base = 2
  ; set_count = 2
  ; threshold = 16
  ; out_msb_first = true
  ; clkdiv
  }
;;

let tlc5620_word ~dac ~double ~value ~update =
  (dac lsl 14) lor (Bool.to_int double lsl 13) lor (value lsl 5) lor (Bool.to_int update lsl 4)
;;

(* Sony SIRC infrared transmitter, the 40 kHz carrier included, so the pin
   drives an IR LED. The program does the whole frame from the bits: the
   start burst, the code of every bit, and the frame period.

   SIRC counts in units of 600 us (24 carrier periods). A frame is a start
   burst of 4 units, then for each bit a unit dark and a burst, 2 units for
   a 1 and 1 for a 0; the bits go least significant first: 7 of command,
   then 5 of address (12-bit frames), 8 of address (15-bit) or 5 of address
   and 8 extended (20-bit). A remote repeats a frame every 45 ms, start to
   start, and so does this program: it counts the units each frame uses
   and stays dark for the rest of 75, so frames from the FIFO start
   exactly 45 ms apart (later, only if the host is late).

   Pins: P0 = the LED, push-pull, high = lit (side-set). Config:
   [sirc_tx_config]: sideset_base 0, sideset_count 1; threshold 16; in
   most significant bit first (the ISR holds the period's count, built
   with IN); CLKDIV makes a tick half a carrier period: 125 for 40 kHz at
   10 MHz, 625 at 50 MHz. A unit is 48 ticks.

   Host protocol, one frame at a time ([sirc_words]):
     TX word 0 : the number of bits: 12, 15 or 20
     TX word 1 : the frame's first 16 bits, the first in bit 0: the
                 command in bits 6:0, the address from bit 7 up
     TX word 2 : (20-bit frames) the last four bits, in bits 3:0
   The data words are taken before the start burst begins, and the second
   during the frame, so a 20-bit frame needs all three in the FIFO.

   Registers: X counts carrier periods and holds each bit; Y counts the
   bits; the ISR is the count of the period's units still to go. *)
let sirc_tx =
  {|
        .side_set 1
next:   pull                side 0      ; the number of bits
        out y, 16           side 0
        set x, 17           side 0      ; ISR = 17 x 4 + 3 = 71: the units of
        mov isr, x          side 0      ;   the 75 (45 ms) left after the
        set x, 3            side 0      ;   start burst
        in x, 2             side 0
        pull                side 0      ; the first 16 bits
        set x, 23           side 0 [6]  ; the start burst: 4 units
        jmp burst           side 0
bit:    mov x, isr          side 0 [7]  ; a bit: first a unit dark, 48 ticks;
        jmp x-- d1          side 0 [7]  ;   the period loses two units, this
d1:     jmp x-- d2          side 0 [7]  ;   one and the burst's first
d2:     mov isr, x          side 0 [7]
        jmp !osre have      side 0
        pull                side 0      ; a 20-bit frame's last four bits
got:    out x, 1            side 0 [6]  ; the bit
        jmp !x zero         side 0
        mov x, isr          side 0      ; a 1: the burst's second unit
        jmp x-- d3          side 0
d3:     mov isr, x          side 0
        set x, 11           side 0      ; a burst of 2 units
        jmp burst           side 0
zero:   set x, 5            side 0 [4]  ; a burst of 1 unit
burst:  nop                 side 1      ; four carrier periods, lit a tick
        nop                 side 0      ;   and dark a tick
        nop                 side 1
        nop                 side 0
        nop                 side 1
        nop                 side 0
        nop                 side 1
        jmp x-- burst       side 0
        jmp y-- bit         side 0      ; the next bit, or the end of the frame:
        mov x, isr          side 0 [7]  ;   dark for the units the period has
        jmp x-- g0          side 0 [7]  ;   left, two of them as the ticks
g0:     jmp x-- g           side 0 [7]  ;   around this loop
g:      set y, 4            side 0 [3]  ; a unit
g1:     jmp y-- g1          side 0 [7]
        jmp x-- g           side 0 [3]
        jmp next            side 0 [7]
have:   jmp got             side 0      ; as long as the pull it stands for
|}
;;

let sirc_tx_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; threshold = 16
  ; in_msb_first = true
  ; clkdiv
  }
;;

(* The TX words for a frame: [bits] is 12, 15 or 20. The address takes
   the bits after the command's 7, and in a 20-bit frame [extended] the
   last 8. *)
let sirc_words ~bits ~command ~address ?(extended = 0) () =
  let frame = command lor (address lsl 7) lor (extended lsl 12) in
  bits :: (frame land 0xFFFF) :: (if bits > 16 then [ frame lsr 16 ] else [])
;;

(* SLE 4442 memory card reader (the Siemens / Infineon "SLE 4432/4442"
   protected memory cards, and others with the same 3-wire protocol). The
   program is the card reader's side of it: the reset and the card's
   answer to it, a command with its START and STOP conditions, and the
   card's output clocked in, with the extra clock that ends it.

   The card's rules: I/O changes only on a falling edge of CLK (from the
   card) or while CLK is low (from the reader), except for START (I/O
   falling while CLK is high) and STOP (I/O rising while CLK is high). A
   reset is RST high with one clock pulse during it; when RST falls the
   card puts the first bit of its answer on I/O, and 31 more clocks give
   the rest of 32 bits; the 33rd releases I/O. A command is START, three
   bytes (control, address, data), each least significant bit first,
   taken as CLK rises, then a 25th clock during which STOP comes. A read
   command's output then starts on the next falling edge, one bit per
   clock, and one clock after the last bit releases I/O.

   Pins: P0 = RST, P1 = CLK, push-pull; P2 = I/O, open-drain (the card's
   output is open-drain too, so the line needs its pull-up). Config:
   [sle4442_config]: sideset_base 1, sideset_count 1; set_base 0,
   set_count 3 (RST, CLK under side-set, I/O); out_base 2, out_count 1;
   in_base 2; threshold 16; CLKDIV makes a tick 5 us (50 at 10 MHz, 250 at
   50 MHz). CLK is then 40 kHz (25 us a clock, 15 low and 10 high; longer
   between bytes), inside the card's 7 to 50 kHz and its 9 us minimum
   high and low; I/O changes 5 us after CLK falls and 10 us before it
   rises; RST is high for 30 us.

   Host protocol, one operation at a time ([sle4442_words]):
     TX word 0 : [8:0] the number of bytes to clock in at the end (0 to
                 511), [9] reset first, [10] a command first
     TX word 1 : (a command) control byte in bits 7:0, address in 15:8
     TX word 2 : (a command) data byte in bits 15:8, and bit 0 set
     RX        : one word per byte clocked in, the byte in bits 7:0
   After the bytes comes one more clock, as the card asks to end its
   output. The answer to reset is 4 bytes; Read Main Memory (0x30) from
   address N is 256 - N.

   A command starts only when both its words are in hand. Then the program
   waits for no one but the RX FIFO: if the host lets it fill, CLK stays
   low until there is room. *)
let sle4442 =
  {|
        .side_set 1
        set pins, 4         side 0      ; RST low, I/O released
next:   pull                side 0      ; bytes, reset, command
        out y, 9            side 0
        out x, 1            side 0
        jmp !x nr           side 0
        set pins, 5         side 0 [1]  ; RST high, 10 us before CLK rises
        nop                 side 1 [1]  ; a clock pulse while RST is high
        nop                 side 0 [1]
        set pins, 4         side 0 [1]  ; RST low: the answer's first bit is on I/O
nr:     out x, 1            side 0
        jmp !x data         side 0
        pull                side 0      ; control and address
        mov isr, osr        side 0
        pull                side 0      ; data, then bit 0 set
        mov x, osr          side 0
        mov osr, isr        side 0
        nop                 side 1 [1]  ; CLK high, I/O released
        set pins, 0         side 1 [1]  ; I/O falls while CLK is high: START
cbit:   nop                 side 0      ; CLK falls; I/O held a tick
        out pins, 1         side 0 [1]  ; the next bit
        jmp !osre cbit      side 1 [1]  ; the card takes it as CLK rises
        jmp !x stop         side 1      ; both words sent?
        mov osr, x          side 1      ; no: the data byte, as the last 8
        out null, 8         side 1      ;   bits of the OSR
        set x, 0            side 1
        jmp cbit            side 1
stop:   nop                 side 0      ; CLK falls
        set pins, 0         side 0 [1]  ; I/O low
        nop                 side 1 [1]  ; the 25th clock
        set pins, 4         side 1 [1]  ; I/O rises while CLK is high: STOP
data:   jmp y-- byte        side 0      ; Y bytes from the card,
        nop                 side 0 [2]  ;   then one more clock
        nop                 side 1 [1]
        jmp next            side 0
byte:   set x, 7            side 0
bit:    nop                 side 0 [2]  ; CLK low 15 us: the card's next bit
        in pins, 1          side 1      ; read as CLK rises
        jmp x-- bit         side 1
        push                side 0
        jmp data            side 0
|}
;;

let sle4442_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 1
  ; sideset_count = 1
  ; set_base = 0
  ; set_count = 3
  ; out_base = 2
  ; out_count = 1
  ; in_base = 2
  ; threshold = 16
  ; clkdiv
  }
;;

(* The TX words for an operation: a reset, or a command (control, address,
   data), or neither, then [bytes] clocked in. *)
let sle4442_words ?(reset = false) ?command ~bytes () =
  let flags = (Bool.to_int reset lsl 9) lor (Bool.to_int (Option.is_some command) lsl 10) in
  (bytes lor flags)
  ::
  (match command with
   | None -> []
   | Some (control, address, data) -> [ control lor (address lsl 8); (data lsl 8) lor 1 ])
;;

(* PWM, and so RC servo pulses: a pin high for one count and low for
   another, over and over.

   Pins: P0, push-pull (side-set). Config: [pwm_config]: sideset_base 0,
   sideset_count 1; CLKDIV sets the tick.

   Host protocol: two TX words when the thread starts: H then L. The pin
   is then high for H + 2 ticks and low for L + 3, for as long as the thread
   runs ([pwm_words] does the sums). To change them the host stops the
   thread, which leaves the pin as it is, and starts it with two new
   words.

   A servo wants 1 to 2 ms high every 20 ms: with a tick of 1 us (CLKDIV
   10 at 10 MHz), 1.5 ms is H = 1498 and L = 18497. *)
let pwm =
  {|
        .side_set 1
        pull             side 0
        mov isr, osr     side 0     ; the high count, kept in the ISR
        pull             side 0     ; the low count stays in the OSR
high:   mov x, isr       side 1
h:      jmp x-- h        side 1
        mov x, osr       side 0
l:      jmp x-- l        side 0
        jmp high         side 0
|}
;;

let pwm_config = { Isa.Thread_config.default with sideset_base = 0; sideset_count = 1 }

(* The two words for a pin high [high] ticks in every [period]. *)
let pwm_words ~high ~period = [ high - 2; period - high - 3 ]

(* NES gamepad, read as the console reads it: a pulse on the latch line
   makes the pad's shift register take in its eight buttons, and eight
   clocks bring them out, A first; a pressed button reads 0.

   Pins: P0 = latch and P1 = clock (side-set, push-pull), P2 = data, an
   input. Config: [nes_pad_config]: sideset_base 0, sideset_count 2;
   in_base 2; threshold 8; in_msb_first; CLKDIV sets the tick to 3 us: 30
   at 10 MHz.

   Host protocol: any TX word asks for one reading; the RX word is the
   buttons, A in bit 7, then B, Select, Start, Up, Down, Left, Right.

   Timing, as the console's: latch high 12 us, then the clock, idle high,
   low 6 us and high 6 us for each button. A button is read as the clock
   falls; the pad moves to the next as it rises. *)
let nes_pad =
  {|
        .side_set 2                 ; bit 0 the latch, bit 1 the clock
next:   pull           side 2       ; until the host asks
        nop            side 3 [3]   ; latch: the pad takes in its buttons
        set x, 7       side 2 [1]
bit:    in pins, 1     side 0 [1]   ; read a button; the clock falls
        jmp x-- bit    side 2 [1]   ; the clock rises: the pad moves on
        push           side 2
        jmp next       side 2
|}
;;

let nes_pad_config =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 2
  ; in_base = 2
  ; threshold = 8
  ; in_msb_first = true
  }
;;

(* Futaba SBUS transmitter: the serial bus a radio control receiver sends
   its channels on, to a flight controller or to servos. It is a UART
   turned upside down: the line rests low, a start bit is high, then 8
   data bits least significant first, each sent as its opposite, an even
   parity bit sent as its opposite, and two stop bits low, at 100 kbit/s.

   The firmware makes each character from a plain byte: the start bit, the
   inversion of every bit, the parity and the stop bits are its work. No
   instruction inverts a pin or a register, so a data bit goes to X and
   [jmp x--] takes one from it: X's bit 0 is then the bit's opposite, and
   [mov pins, x] puts that on the line. The parity is kept by the CRC
   register, which takes every bit OUT shifts: with the polynomial 1 its
   bit 0 is the parity of the bits so far, and read with [crc_invert] it
   comes back as the level the line needs.

   Pins: P0 = the line, push-pull, low while there is nothing to send.
   Config: [sbus_tx_config]: threshold 8; crc_poly 1, crc_init 0,
   crc_invert; the rest as reset.

   Host protocol on the TX FIFO ([sbus_tx_words]):
     word 0  : bit time - 6, in clock cycles: 94 for 100 kbit/s at 10 MHz,
               494 at 50 MHz (both exact)
     then    : one byte per word
   An SBUS message is 25 bytes: 0x0F, the sixteen 11-bit channels packed
   least significant bit first into 22 bytes, a byte of flags, 0x00. The
   host packs them ([sbus_message]); the firmware does not count bytes.

   Timing: every bit is exactly one bit time, and back-to-back bytes have
   exactly two stop bits, so a message is 3 ms at 100 kbit/s. Between
   bytes the line rests low for as long as the host takes. *)
let sbus_tx =
  {|
        set pins, 0         ; the line rests low
        pull                ; bit time - 6
        mov y, osr
next:   pull                ; wait for a byte; the line stays low
        mov crc, null       ; the parity starts from 0
        set pins, 1 [1]     ; start bit: high
        mov x, y
start:  jmp x-- start
bit:    out x, 1            ; a data bit, LSB first; the CRC register takes it too
        jmp x-- inv         ; X = bit - 1: its bit 0 is the bit's opposite
inv:    mov pins, x         ; the bit, inverted
        mov x, y
hold:   jmp x-- hold
        jmp !osre bit       ; until all 8 are out
        mov x, crc [1]      ; the parity of the 8, read inverted
        mov pins, x         ; the parity bit, even, inverted
        mov x, y [3]
par:    jmp x-- par
        set pins, 0 [5]     ; two stop bits: low
        mov x, y
stop:   jmp x-- stop [1]
        jmp next
|}
;;

let sbus_tx_config = { Isa.Thread_config.default with crc_poly = 1; crc_init = 0; crc_invert = true }

(* An SBUS message's 25 bytes. Flags: bit 0 channel 17, bit 1 channel 18,
   bit 2 frame lost, bit 3 failsafe. *)
let sbus_message ~channels ~ch17 ~ch18 ~frame_lost ~failsafe =
  assert (List.length channels = 16 && List.for_all channels ~f:(fun v -> v >= 0 && v < 2048));
  let bits = List.concat_map channels ~f:(fun v -> List.init 11 ~f:(fun k -> (v lsr k) land 1)) in
  let packed =
    List.chunks_of bits ~length:8
    |> List.map ~f:(fun byte -> List.foldi byte ~init:0 ~f:(fun k acc b -> acc lor (b lsl k)))
  in
  let flag k b = Bool.to_int b lsl k in
  [ 0x0F ] @ packed @ [ flag 0 ch17 lor flag 1 ch18 lor flag 2 frame_lost lor flag 3 failsafe; 0x00 ]
;;

let sbus_tx_words ~bit_time bytes = (bit_time - 6) :: bytes

(* DShot, a flight controller's command to a motor's speed controller (ESC):
   16-bit frames on one wire, most significant bit first. Bits 15:5 are the
   value (0 disarms, 1 to 47 are commands, 48 to 2047 throttle), bit 4 asks
   the ESC for telemetry, and bits 3:0 are the checksum: the exclusive or of
   the three nibbles of the 12 bits before it. Every bit has the same
   period and begins with the line rising; a 0 is high for 37.5% of it and
   a 1 for 75%, the DShot600 numbers (625 ns and 1250 ns of 1670 ns).

   Pins: P0 = the line, push-pull (side-set), low between frames. Config:
   [dshot_config]: sideset_base 0, sideset_count 1; threshold 16; out most
   significant bit first, in least significant first; the CRC register
   with polynomial x^4 + 1 (0x8) from 0, whose remainder is that exclusive
   or. A bit is 8 ticks, so CLKDIV is the clock over eight times the bit
   rate, rounded: at 10 MHz, 2 is 625 kbit/s (DShot600, 4% fast), 4 is
   DShot300 and 8 DShot150, both 4% fast; at 50 MHz, 10 is DShot600 (4%
   fast) and 5 DShot1200, 21 and 42 DShot300 and DShot150 (1% slow).

   Host protocol: one TX word a frame, the value shifted left once with the
   telemetry bit below it, in bits 11:0 ([dshot_word]). The firmware makes
   the checksum: the CRC register follows the 12 bits, OUT to nowhere, and
   since it shifts right its remainder comes out reversed, so four OUTs
   and INs turn it round in the ISR, under the 12 bits. That takes 44
   ticks with the line low, so a frame's last fall and the next one's first
   rise are 47 ticks (5.9 bit times) apart or more; with the FIFO empty the
   line stays low. Bidirectional DShot is not made: see the cocotb test. *)
let dshot =
  {|
        .side_set 1
next:   pull                side 0      ; a frame: the 12 bits in 11:0
        mov y, osr          side 0      ; kept to send
        out null, 4         side 0      ; bits 15:12 are not sent
        mov crc, null       side 0      ; the checksum from 0
sum:    out null, 1         side 0      ; the CRC register follows the 12 bits
        jmp !osre sum       side 0
        mov osr, crc        side 0      ; the checksum, its first bit lowest
        out null, 12        side 0
rev:    out x, 1            side 0      ; turned round in the ISR, which
        in x, 1             side 0      ; shifts right
        jmp !osre rev       side 0
        in y, 12            side 0      ; the 12 bits above it
        mov osr, isr        side 0      ; the frame
bit:    out x, 1            side 0 [1]  ; the end of the bit before: low
        jmp !x zero         side 1 [2]  ; every bit is high for 3 ticks
        jmp !osre bit       side 1 [2]  ; a 1 for 3 more
        jmp next            side 0
zero:   jmp !osre bit       side 0 [2]  ; a 0 is low
        jmp next            side 0
|}
;;

let dshot_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; threshold = 16
  ; out_msb_first = true
  ; crc_poly = 0x8
  ; crc_init = 0
  ; clkdiv
  }
;;

let dshot_word ~value ~telemetry = (value lsl 1) lor Bool.to_int telemetry

(* XY2-100, the interface of laser galvanometer scanners: a clock at 2 MHz,
   a sync line, and one data line for each axis, every line a differential
   pair on the real cable and one pin here. Each axis's frame is 20 bits,
   data changing as the clock rises and read as it falls: three control
   bits, 001 for a 16-bit position; the position, most significant bit
   first; and even parity over the 20. SYNC is high for the first 19 bits
   and low for the parity bit, so a frame ends where SYNC is low. Frames
   follow one another with no gap, 100,000 a second.

   Two threads, one for each axis, since each makes its own parity on its
   CRC register (polynomial x + 1, from 1 for the control bits' one 1). This
   program, on thread 0, makes CLK and SYNC and sends X; [xy2_y], on thread
   1, sends Y, following thread 0's clock. CHAIN carries Y's position to
   it: the host sends both to thread 0.

   Pins: P0 = CLK and P1 = SYNC (side-set), P2 = X, all push-pull; P3 = Y,
   thread 1's. Config: [xy2_x_config] and [xy2_y_config], with the same
   CLKDIV, both threads enabled by one CTRL write with CHAIN. A bit is 5
   ticks, CLK high for 2 and low for 3, so CLKDIV 1 at 10 MHz and 5 at
   50 MHz give the 2 MHz clock.

   Host protocol: TX words to thread 0, two a frame, X's position and then
   Y's. The next frame's words are taken in the low half of the parity
   bit; when they are not there the clock waits there, low with SYNC low,
   so frames run with no gap only while the host keeps two words ahead
   (the packet buffer can). Y's word reaches thread 1 during bit 0. *)
let xy2_x =
  {|
        .side_set 2                     ; CLK, SYNC
frame:  pull             side 0         ; X's position, in the last bit's low half
        mov y, osr       side 0
        pull             side 0         ; Y's
        set pins, 0      side 3         ; bit 0: CLK rises, SYNC high; control 0
        mov x, osr       side 3
        in x, 16         side 2         ; CLK falls
        push             side 2         ; Y's position to thread 1, by the chain
        mov osr, y       side 2         ; X's to send
        set pins, 0      side 3         ; bit 1: control 0
        mov crc, null    side 3         ; the parity starts again
        nop              side 2 [2]
        set pins, 1      side 3 [1]     ; bit 2: control 1
        nop              side 2 [2]
bit:    out pins, 1      side 3 [1]     ; bits 3 to 18, the position
        jmp !osre bit    side 2 [2]
        mov pins, crc    side 1         ; bit 19, the parity; SYNC low
        jmp frame        side 1
|}
;;

(* XY2-100's Y axis, on thread 1, beside [xy2_x] on thread 0 (see there).
   It reads CLK on P0 and SYNC on P1, thread 0's outputs, which a thread
   sees a tick after they are written, and drives Y on P3. A wait on CLK
   low completes in the first low tick; one tick of delay and the next
   instruction writes Y in the tick in which thread 0 raises CLK and writes
   X, so all three change together. Each bit is four instructions in five
   ticks: wait for CLK low, write, wait for CLK high, and one more. Before
   bit 0 thread 0 may be waiting for the host with CLK low: Y is then 0, bit
   0's value, until CLK rises.

   Config: [xy2_y_config]: out_base 3, set_base 3; threshold 16; out most
   significant bit first; the CRC register as thread 0's; CLKDIV as thread
   0's. *)
let xy2_y =
  {|
        wait 0 pin 1                    ; SYNC low: before the first frame
frame:  wait 0 pin 0 [1]                ; CLK low in the last bit, or idle
        set pins, 0                     ; bit 0, as CLK rises
        wait 1 pin 0
        wait 0 pin 0 [1]
        set pins, 0                     ; bit 1
        wait 1 pin 0
        pull                            ; the position, from thread 0
        wait 0 pin 0 [1]
        set pins, 1                     ; bit 2
        wait 1 pin 0
        mov crc, null                   ; the parity starts again
bit:    wait 0 pin 0 [1]
        out pins, 1                     ; bits 3 to 18
        wait 1 pin 0
        jmp !osre bit
        wait 0 pin 0 [1]
        mov pins, crc                   ; bit 19, the parity
        wait 1 pin 0
        jmp frame
|}
;;

let xy2_x_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 2
  ; out_base = 2
  ; out_count = 1
  ; set_base = 2
  ; set_count = 1
  ; threshold = 16
  ; out_msb_first = true
  ; crc_poly = 1
  ; crc_init = 1
  ; clkdiv
  }
;;

let xy2_y_config ~clkdiv =
  { (xy2_x_config ~clkdiv) with sideset_base = 0; sideset_count = 0; out_base = 3; set_base = 3 }
;;

(* The two programs, each at address 0 of its own thread's memory. *)
module Xy2 = struct
  let x = Asm.assemble xy2_x
  let y = Asm.assemble xy2_y

  (* X's and Y's positions, as signed 16-bit numbers, as TX words. *)
  let words points = List.concat_map points ~f:(fun (x, y) -> [ x land 0xFFFF; y land 0xFFFF ])
end

(* A digital caliper's data port, as cheap calipers send it: the chip is
   the caliper, sending a reading the host gives. A packet is 24 bits, least
   significant first, each read as CLK rises: the reading in bits 15:0 (bits
   19:16 are 0 here: no reading above 655.35 mm), the sign in bit 20 (1 for
   negative), 0 in bits 21 and 22, and the unit in bit 23 (1 for inches).
   The reading counts hundredths of a millimetre, or halves of a
   thousandth of an inch. CLK rests high between packets.

   Pins: P0 = CLK (side-set), P1 = DATA, push-pull. Config:
   [caliper_config]: sideset_base 0, sideset_count 1; out_base 1;
   threshold 16; shifts least significant bit first. A bit is 8 ticks, CLK
   low for 4 with DATA changed as it falls, and high for 4; calipers clock
   at about 77 kHz, a bit of 13 us: CLKDIV 16 at 10 MHz (12.8 us), 81 at
   50 MHz (12.96 us).

   Host protocol: two TX words a packet: the reading, then a word with
   bit 0 set for a negative reading and bit 1 for inches. The firmware
   places those two bits in the packet's top byte in the ISR, and sends
   that byte from the ISR's bottom bit, shifting it down. After each
   packet CLK stays high for 64 bit times or more (0.8 ms at 13 us), so
   that a reader can tell where the next one starts. *)
let caliper =
  {|
        .side_set 1
next:   pull               side 1       ; the reading
        mov y, osr         side 1
        pull               side 1       ; bit 0 negative, bit 1 inches
        in null, 4         side 1       ; the packet's bits 16 to 19: 0
        out x, 1           side 1
        in x, 1            side 1       ; bit 20: the sign
        in null, 2         side 1       ; 21 and 22: 0
        out x, 1           side 1
        in x, 1            side 1       ; bit 23: inches
        in null, 8         side 1       ; those eight at the ISR's bottom
        mov osr, y         side 1
        set y, 7           side 1
bit:    out pins, 1        side 0 [3]   ; bits 0 to 15: DATA as CLK falls,
        jmp !osre bit      side 1 [3]   ; read as it rises
top:    mov pins, isr      side 0 [3]   ; bits 16 to 23
        in null, 1         side 1 [2]
        jmp y-- top        side 1
        set x, 31          side 1
rest:   nop                side 1 [7]   ; 64 bit times
        jmp x-- rest       side 1 [7]
        jmp next           side 1
|}
;;

let caliper_config ~clkdiv =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; out_base = 1
  ; out_count = 1
  ; threshold = 16
  ; clkdiv
  }
;;

(* The two TX words for a reading of [counts] (0 to 65535). *)
let caliper_words ~counts ~negative ~inches =
  [ counts; Bool.to_int negative lor (Bool.to_int inches lsl 1) ]
;;

(* MIPI I3C controller, SDR mode: START, the broadcast address 0x7E and
   the CCCs sent after it, ENTDAA to give targets their dynamic
   addresses, private writes and reads to a target at its dynamic address,
   repeated START and STOP. What I3C has and I2C does not is done here: the
   ninth bit after a byte the controller writes is T, odd parity over the
   byte, computed by the CRC register; after a byte a target returns it is
   the target's end-of-data bit, and the controller ends a read the target
   would go on with by pulling SDA low while SCL is high in that bit; and
   ENTDAA reads each target's 48-bit provisioned ID, BCR and DCR as 64
   bits that the targets arbitrate for, then sends the dynamic address with
   its parity bit.

   Pins: P0 = SDA, open-drain; P1 = SCL, push-pull, driven by side-set.
   SDA stays open-drain for the whole frame. The specification wants a
   controller to drive SDA push-pull for data and switch to open drain for
   the address arbitration and the ACK, but a pin's drive mode here is set
   by the host and no instruction can change it, so a frame on this chip
   is open-drain throughout. The levels on the wire are the same; what
   changes is that a rising SDA edge comes from the pull-up, so every bit
   is timed to the specification's open-drain limits, not its push-pull
   ones (below).

   Config: [i3c_config]: out_base 0, out_count 1, set_base 0, set_count 1,
   in_base 0 (SDA); sideset_base 1, sideset_count 1 (SCL); threshold 16;
   out and in most significant bit first; CRC polynomial 1 from 0, read
   inverted, so the register is the parity of the bits OUT shifted and a
   read of it is the odd parity bit; start [i3c_idle]; TIMEOUT 0 and
   timeout_vector [i3c_ended], which makes [wait ... timeout] a branch on
   SDA. CLKDIV makes a tick 100 ns or more: 1 at 10 MHz, 5 at 50 MHz.

   Timing. A bit is SCL low for 3 ticks and high for 2 (the ninth bits and
   those around a START longer), so 2 MHz with a 100 ns tick, at 10 MHz or
   50 MHz alike. That is the fastest the open-drain timing allows: SCL low
   at least 200 ns (tLOW_OD) and, in the address after a START, high at
   least 200 ns (tHIGH_INIT). It is not I3C's 12.5 MHz, which needs
   push-pull SDA, and at 50 MHz a 5-tick bit could not reach it anyway
   (10 MHz at CLKDIV 1). SDA changes one tick after SCL falls and two
   before it rises. START and repeated START hold SDA low two ticks before
   SCL falls (tCAS, under ENTAS0's 1 us); SCL is high two ticks or more
   before STOP and repeated START. A bus with I2C devices on it is not
   supported: their spike filters need SCL high under 50 ns.

   Host protocol: a frame is a segment word, then that segment's data
   words if it writes, then further segments, each after a repeated START,
   and finally the STOP word. The first word after STOP must be a segment.
     segment : bit 15 = 1; bits 14:7 the address byte (address << 1 |
               R/W); bit 6 = R/W again; bits 5:0 for a read the most bytes
               to read (1 to 63), 0 for an ENTDAA round (address 0x7E,
               read). [i3c_segment]
     data    : bits 15:14 = 00, bits 13:6 a byte to write; the firmware
               adds its T bit. [i3c_data]
     STOP    : 0x4000. [i3c_stop]
     address : in an ENTDAA round, once the round's 0x7E has been
               ACKed: the dynamic address in bits 15:9, bit 8 clear; the
               firmware adds its parity bit. [i3c_address_word]
   RX words:
     after every address : 0 ACK, 1 NACK. A segment NACKed has its data
               words taken from the FIFO unsent, up to the next segment or
               STOP, which is then done as usual.
     after a byte read   : byte << 1 | T. T = 1 the target had more;
               T = 0 it ended the read there, and no more words come for
               that segment. The last byte asked for has T as the target
               sent it, and the controller ends the read whatever it was.
     an ENTDAA round ACKed : four words of 16 bits, the 64 bits the target
               won the arbitration with (provisioned ID 47:32, 31:16, 15:0,
               then BCR << 8 | DCR), then the ACK of the dynamic address.
   A round NACKed means no target wants an address: the host sends STOP.

   Where it waits. Every PULL and PUSH comes with SCL low, just after a
   ninth bit (an ACK, a T bit) or, in ENTDAA, after the round's ACK, so a
   host that falls behind stretches the low half of the clock at a place
   the specification lets a controller stall it. The 64 bits of an ENTDAA
   round are pushed as they come; a host that pops the round's ACK before
   it sends the address leaves the FIFO room for all four.

   Not supported: in-band interrupts and hot-join (an address a target
   wins in the arbitrable header is reported as an ACK or NACK, no more),
   HDR modes, and I2C devices on the bus. *)
let i3c =
  {|
        .side_set 1
stop:   set pins, 0         side 0 [1] ; STOP: SDA low while SCL is low,
        nop                 side 1 [1] ; SCL high,
        set pins, 1         side 1     ; then SDA rises while SCL is high
idle:   pull                side 1     ; bus free: a frame's first segment
        out null, 1         side 1     ; (its kind bit)
start:  set pins, 0         side 1 [1] ; START: SDA falls while SCL is high
        set y, 7            side 0     ; SCL falls; the address and R/W bit
abit:   out pins, 1         side 0 [1] ; SDA = the next bit while SCL is low
        nop                 side 1 [1] ; SCL high
        jmp y-- abit        side 0     ; SCL falls
ack:    set pins, 1         side 0 [1] ; ACK slot: SDA released
        nop                 side 1     ; SCL rises
        in pins, 1          side 1     ; the ACK (0) or NACK (1), for the host
        wait 0 pin 0 timeout side 1    ; NACK: on to [ended]
        push                side 0     ; SCL falls
        out x, 1            side 0     ; the segment's R/W bit
        jmp !x next         side 0     ; a write: its data words follow
        out x, 6            side 0     ; a read: the bytes to read; 0 is ENTDAA
        jmp !x entdaa       side 0
        jmp x-- rbyte       side 0     ; X = bytes to read after this one
entdaa: pull                side 0     ; the dynamic address to give
        set x, 3            side 0     ; first 64 bits from the targets,
pword:  set y, 15           side 0     ; four words of 16
        jmp rbit            side 0
rbyte:  set y, 7            side 0     ; a byte from the target
rbit:   nop                 side 0 [1] ; SCL low: the target drives SDA
        nop                 side 1     ; SCL rises
        in pins, 1          side 1     ; the bit
        jmp y-- rbit        side 0     ; SCL falls
        jmp !osre pid       side 0     ; ENTDAA (the OSR holds the address): 16 bits in
        nop                 side 0     ; T bit: the target drives it
        nop                 side 1     ; SCL rises
        in pins, 1          side 1     ; T: 1 the target has more, 0 it is done
        jmp x-- more        side 1     ; another byte wanted?
        set pins, 0         side 1 [1] ; no: SDA low while SCL is high ends the read
ended:  push                side 0     ; SCL falls: the byte and T, or a NACK
        set y, 0            side 0     ; drop data words up to a segment or STOP
next:   pull                side 0     ; SCL low: the next word
        out x, 1            side 0     ; a segment: repeated START
        jmp x-- sr          side 0
        out x, 1            side 0     ; STOP
        jmp x-- stop        side 0
        jmp !y next         side 0     ; a data word after a NACK or a read: dropped
        set y, 7            side 0     ; a data byte (X = 0xFFFF)
par:    mov crc, null       side 0     ; the parity starts here
dbit:   out pins, 1         side 0 [1] ; SDA = the next bit while SCL is low
        nop                 side 1 [1] ; SCL high
        jmp y-- dbit        side 0     ; SCL falls
        mov pins, crc       side 0 [1] ; T: odd parity, from the CRC register
        nop                 side 1 [1]
        jmp !x ack          side 0     ; ENTDAA's address (X = 0): the target ACKs it
        jmp next            side 0
sr:     set pins, 1         side 0 [1] ; repeated START: SDA released while SCL is low,
        nop                 side 1 [1] ; SCL high,
        jmp start           side 1     ; then SDA falls
more:   wait 1 pin 0 timeout side 1    ; T = 0: on to [ended]
        push                side 0     ; SCL falls: the byte and T
        jmp rbyte           side 0
pid:    push                side 0     ; 16 of the 64 bits
        jmp x-- pword       side 0
        set y, 6            side 0     ; then the dynamic address, 7 bits,
        set x, 0            side 0     ; its parity and the target's ACK
        jmp par             side 0
|}
;;

(* Addresses in [i3c]: where the thread starts, and the timeout vector,
   which [wait 0/1 pin 0 timeout] with TIMEOUT 0 jumps to when SDA is not
   the level waited for. The tests check they still point there. *)
let i3c_idle = 3
let i3c_ended = 35

let i3c_config ~clkdiv =
  { Isa.Thread_config.default with
    start = i3c_idle
  ; out_base = 0
  ; out_count = 1
  ; set_base = 0
  ; set_count = 1
  ; in_base = 0
  ; sideset_base = 1
  ; sideset_count = 1
  ; threshold = 16
  ; out_msb_first = true
  ; in_msb_first = true
  ; timeout = 0
  ; timeout_vector = i3c_ended
  ; crc_poly = 1
  ; crc_init = 0
  ; crc_invert = true
  ; clkdiv
  }
;;

(* Host words for [i3c]. [count] is for a read: the most bytes to read,
   1 to 63; 0 makes the segment an ENTDAA round, at 0x7E. *)
let i3c_segment ~address ~read ~count =
  0x8000 lor (((address lsl 1) lor Bool.to_int read) lsl 7) lor (Bool.to_int read lsl 6) lor count
;;

let i3c_data byte = (byte land 0xFF) lsl 6
let i3c_stop = 0x4000
let i3c_address_word address = (address land 0x7F) lsl 9
let i3c_broadcast = 0x7E

(* Odd parity: the T bit after a byte written, and ENTDAA's parity bit
   after a dynamic address, make the count of ones odd. *)
let i3c_odd_parity ~bits value =
  1 lxor (List.init bits ~f:(fun k -> (value lsr k) land 1) |> List.fold ~init:0 ~f:( lxor ))
;;

(* SAE J2716 SENT, a sensor's transmitter: one line, frames of nibbles
   each told by the time from one falling edge to the next. A frame is a
   calibration pulse of 56 ticks, a status nibble, the data nibbles and a
   CRC-4 nibble, then a pause pulse; a nibble of value v lasts 12 + v
   ticks. Every pulse is low for 5 ticks and high for the rest.

   Pins: P0 = the SENT line, push-pull; it idles high. Config:
   [sent_tx_config]: set_base 0, set_count 1; threshold 16; out most
   significant bit first; the CRC register at x^4 + x^3 + x^2 + 1
   ([sent_crc_poly]), from [sent_crc_init]. A thread tick is half a SENT
   tick: CLKDIV 15 for the nominal 3 us tick at 10 MHz, 75 at 50 MHz; 450
   at 10 MHz for the longest the standard has, 90 us.

   Host protocol:
     TX : once, N - 1, where N is the number of data nibbles in a frame (1
          to 6 in the standard). Then for each frame its status nibble and
          its N data nibbles, four to a word, the first in bits 15:12
          ([sent_words]); what is left of a frame's last word is not sent.
     RX : nothing.

   The CRC is the chip's: SAE J2716's recommended CRC-4, seed 0101, over
   the data nibbles but not the status, with a nibble of zeros after them.
   The CRC register follows each bit OUT shifts, most significant first.
   It takes each bit in at the top, as if a nibble of zeros followed, so
   it starts from the seed times x^4, 0011, and needs no zeros at the end.
   It shifts right, so it holds the CRC with its bits reversed, and starts
   from 0011 reversed. The status nibble is taken with one OUT of four bits, whose first bit the
   register takes before the next instruction starts it again. A data
   nibble's high time is its four bits one at a time: 8, 4, 2 and 1 ticks
   for those that are 1. The CRC's bits come out of the register least
   significant first, so its nibble waits 1, 2, 4 and 8.

   The pause pulse makes the frame 120 ticks longer: the standard allows
   12 to 768, and sigrok's decoder finds the end of a frame only at a pulse
   of more than 100. While the host has no frame the line stays high, so a
   pause lasts until the next frame. Within a frame a word is needed every
   four nibbles; one that comes late stretches the low time of the nibble
   that waits for it. *)
let sent_tx =
  {|
        set pins, 1             ; the line idles high
        pull                    ; N - 1, once
        mov isr, osr            ; kept in the ISR
frame:  pull                    ; a frame: the status nibble first
        set pins, 0 [9]         ; 0: calibration pulse, low for 5 ticks
        set pins, 1             ; 10
        set y, 22               ; 11
cal:    jmp y-- cal [3]         ; 12..103
        nop [7]                 ; 104..111: 56 ticks in all
        set pins, 0             ; 0: the status nibble
        out x, 4                ; 1: its value; the CRC takes its first bit
        mov crc, null           ; 2: and starts again
        nop [6]                 ; 3..9
        set pins, 1             ; 10
st:     jmp x-- st [1]          ; 11..12+2s
        mov x, isr [10]         ; ..23+2s: N - 1 data nibbles after the next
data:   set pins, 0             ; 0: a data nibble
        jmp !osre have          ; 1
        pull                    ; 2: four nibbles to a word
        jmp low                 ; 3
have:   nop [1]                 ; 2..3
low:    nop [5]                 ; 4..9
        set pins, 1             ; 10
        out y, 1                ; 11: its bits, most significant first;
        jmp !y d4               ; 12  the CRC takes each
        nop [15]                ; 8 ticks for an 8
d4:     out y, 1
        jmp !y d2
        nop [7]
d2:     out y, 1
        jmp !y d1
        nop [3]
d1:     out y, 1
        jmp !y dend
        nop [1]
dend:   jmp x-- data [4]        ; ..23+2v
        set pins, 0             ; 0: the CRC nibble
        mov osr, crc            ; 1: in bits 3:0, reversed; the CRC stops
        out null, 12            ; 2
        nop [6]                 ; 3..9
        set pins, 1             ; 10
        out y, 1                ; 11: its least significant bit,
        jmp !y c2               ; 12
        nop [1]                 ; 1 tick
c2:     out y, 1
        jmp !y c4
        nop [3]
c4:     out y, 1
        jmp !y c8
        nop [7]
c8:     out y, 1
        jmp !y cend
        nop [15]
cend:   nop [4]                 ; ..23+2c
        set pins, 0 [9]         ; 0: the pause pulse
        set pins, 1             ; 10
        set y, 13               ; 11
pause:  jmp y-- pause [15]      ; 12..235
        jmp frame [2]           ; 236..238; the next frame's pull, 239
|}
;;

(* The CRC register for SENT's CRC-4: x^4 + x^3 + x^2 + 1 (1101 below the
   x^4), and the seed 0101 with the nibble of zeros folded in (0011), both
   reversed because the register shifts right. *)
let sent_crc_poly = 0b1011
let sent_crc_init = 0b1100

let sent_tx_config ~clkdiv =
  { Isa.Thread_config.default with
    set_base = 0
  ; set_count = 1
  ; threshold = 16
  ; out_msb_first = true
  ; crc_poly = sent_crc_poly
  ; crc_init = sent_crc_init
  ; clkdiv
  }
;;

(* A frame's TX words: the status nibble and the data nibbles, four to a
   word, the first in bits 15:12. *)
let sent_words ~status data =
  let nibbles = status :: data in
  List.chunks_of nibbles ~length:4
  |> List.map ~f:(fun chunk ->
    List.foldi chunk ~init:0 ~f:(fun i acc n -> acc lor ((n land 0xF) lsl (12 - (4 * i)))))
;;

(* SAE J1850 VPW, the GM and Chrysler OBD-II bus, a transmitting node at
   10.4 kbit/s: start of frame, the bytes as symbols that alternate between
   active and passive, each 64 or 128 us, the CRC-8 byte, end of data.

   Pins: P0 = the bus driver's input, push-pull, high = active. The bus
   idles passive (low); a transceiver turns this into the bus's 7 V. A
   passive symbol is a 0 when short and a 1 when long, an active one the
   other way round, so a byte (eight symbols, the first passive) always
   ends active. Config: [j1850_tx_config]: set_base 0, set_count 1;
   threshold 8; out most significant bit first; the CRC register at
   SAE J1850's 0x1D reversed ([j1850_crc_poly]) from 0xFF, read inverted.
   A thread tick is 1 us: CLKDIV 10 at 10 MHz, 50 at 50 MHz.

   Host protocol, for each frame:
     TX : N, the number of bytes before the CRC (1 to 11), then the bytes,
          one to a word in bits 15:8 ([j1850_words]): the header (priority,
          target, source), the mode and the data.
     RX : one word, 0, once the frame's last symbol has ended.

   Ticks are counted from the instruction that drives a symbol, tick 0.
   Start of frame: active for 200. Then each symbol runs to the next's
   tick 0, at 64 or 128. The end of each active symbol is spent on the
   bookkeeping, 35 ticks on every path: whether the byte has bits left,
   whether there is another byte, and fetching it. The CRC register
   follows every bit OUT shifts. After the last data byte it is read into
   the OSR, where its bits are in the reverse of the order they go out in,
   so the same 35 ticks turn them round: each goes through Y into the ISR,
   which shifts the other way, and back to the OSR. Then the CRC goes out
   like any byte. End of data: passive. The next frame's start comes 312
   us or more later, past the 300 of the interframe space; so does the
   first, after the thread starts.

   It sends only: it does not watch the bus for an idle one before it
   starts, or give way to a node that wins arbitration. A word the host
   is late with stretches the active symbol that ends a byte. *)
let j1850_tx =
  {|
        set pins, 0             ; passive
        jmp quiet               ; and quiet for as long as between frames
next:   pull                    ; N
        mov isr, osr            ; bytes after this one, the CRC counted
        pull                    ; the first byte
        mov crc, null           ; the CRC from 0xFF
        set pins, 1             ; 0: start of frame, active
        set x, 23               ; 1
sof:    jmp x-- sof [7]         ; 2..193
        nop [5]                 ; 194..199
pas:    set pins, 0             ; 0: a passive symbol
        out y, 1                ; 1: its bit; the CRC takes it
        jmp !y p0               ; 2
        set x, 14               ; 3: a 1 is long, 64 ticks more
p1:     jmp x-- p1 [3]          ; 4..63
        nop [2]                 ; 64..66
p0:     set x, 14               ; 3
pw:     jmp x-- pw [3]          ; 4..63
act:    set pins, 1             ; 0: an active symbol
        out y, 1                ; 1
        jmp !y a0               ; 2
a1:     set x, 5                ; 3: a 1 is short
aw:     jmp x-- aw [3]          ; 4..27
        nop                     ; 28
        jmp !osre bits          ; 29: the 35 ticks before the next symbol
        mov x, isr              ; 30
        jmp x-- byte            ; 31
        nop [15]                ; 32..47: the CRC has gone
        nop [15]                ; 48..63
        set pins, 0             ; 0: end of data, passive
        push                    ; 1: the frame is sent
quiet:  set x, 18               ; 2
ifs:    jmp x-- ifs [15]        ; 3..306
        jmp next                ; 307: the next start of frame at 312
byte:   mov isr, x              ; 32
        jmp !x crc8             ; 33: the CRC is next
        pull                    ; 34: the next byte
        nop [15]                ; 35..50
        nop [11]                ; 51..62
        jmp pas                 ; 63
crc8:   mov osr, crc            ; 34: inverted; the CRC stops
        out null, 8             ; 35: the top half, all ones
        set x, 7                ; 36
rev:    out y, 1                ; 37..60: eight bits from the OSR's top,
        in y, 1                 ;   each into the ISR's top
        jmp x-- rev
        mov osr, isr            ; 61: the CRC, first bit topmost
        mov isr, null           ; 62: no byte after it
        jmp pas                 ; 63
bits:   nop [15]                ; 30..45
        nop [15]                ; 46..61
        jmp pas [1]             ; 62..63
a0:     set x, 14               ; 3: a 0 is long, 64 ticks more
al:     jmp x-- al [3]          ; 4..63
        jmp a1 [2]              ; 64..66
|}
;;

(* SAE J1850's CRC-8: 0x1D written low power first, reversed because the
   register shifts right; from 0xFF, sent inverted. *)
let j1850_crc_poly = 0xB8

let j1850_tx_config ~clkdiv =
  { Isa.Thread_config.default with
    set_base = 0
  ; set_count = 1
  ; threshold = 8
  ; out_msb_first = true
  ; crc_poly = j1850_crc_poly
  ; crc_init = 0xFF
  ; crc_invert = true
  ; clkdiv
  }
;;

(* A frame's TX words: its bytes before the CRC. *)
let j1850_words bytes = List.length bytes :: List.map bytes ~f:(fun b -> (b land 0xFF) lsl 8)

(* 10BASE-T Ethernet transmitter: a whole frame on the wire from firmware.
   Preamble, start-of-frame delimiter, the frame Manchester coded at
   10 Mbit/s, its CRC-32 frame check sequence, and the idle signal that ends
   it.

   The core clock must be 40 MHz: a bit is 4 clocks and each half of it 2.
   That leaves no clock in which to fetch a word, so the thread runs with
   autopull, and no host could supply 625,000 words a second, so the frame
   is played from the packet buffer. The CRC register follows every bit OUT
   shifts and the firmware sends what it holds after the data.

   Pins (side-set, base P0): P0 = TD+, P1 = TD-, push-pull. Idle is both
   low, no voltage across the pair. A 1 is TD+ low then high, a 0 high then
   low, with TD- the opposite. On a wire they drive a 10BASE-T transformer
   through series resistors.

   Config: [eth_tx_config ~odd]. The host loads the buffer with the frame
   from the destination address to the end of the data, padded to at least
   60 bytes, no FCS: two bytes a word, the first in bits 7:0. A frame with
   an odd number of bytes starts at [eth_tx_odd] instead and its first word
   holds only its first byte, in bits 15:8. The host then sets the buffer
   playing into this thread and enables the thread. The host stops the
   thread before the next frame.

   Between frames the thread sends link pulses, which is how the other end
   of a 10BASE-T link knows anyone is there: TD+ high for 100 ns every
   16 ms. The 16 ms is ten waits of TIMEOUT ticks each, on a pin that can
   never be seen high because it is this thread's own TD+ driven low; each
   one ends at the timeout vector, [eth_tx_tick], which counts it. A host
   that wants the pulses before it has sent anything starts the thread at
   [eth_tx_link].

   Every bit has four slots. The first fetches the bit after the one on the
   wire into X, the second asks whether the OSR is empty, and the last two
   branch on X into the loop for a 1 or the loop for a 0. An empty OSR in
   the data means the buffer has played out, and the two slots load the CRC
   register's low half instead; an empty OSR there loads its high half; an
   empty OSR there ends the frame. A branch that must pick between two
   places in one slot jumps one way and falls into the other, which is why
   the loops for a 1 follow one another and use [jmp !x], and the loops for
   a 0 do the same with [jmp x--].

   It is the first program here longer than a page: the start and the
   preamble sit at the end of page 0 and the bit loops in page 1. *)
let eth_tx_origin = 51
let eth_tx_odd = eth_tx_origin + 2

let eth_tx =
  {|
        .side_set 2
        pull            side 0      ; wait for a frame's first word
        jmp go          side 0
        pull            side 0      ; start here for an odd number of bytes:
        out null, 8     side 0      ;   the first word holds one
go:     set y, 30       side 0
pre:    nop             side 2 [1]  ; preamble: a 1 ...
        nop             side 1 [1]
        nop             side 1 [1]  ; ... and a 0, 31 times
        jmp y-- pre     side 2 [1]
        mov crc, null   side 2      ; it ends 1, 1. The CRC starts with the frame
        set page, 1     side 2
        nop             side 1
        jmp d1          side 1      ; the second 1 is the bit loop's first turn

d1:     out x, 1        side 2      ; sending a 1 from the frame
        jmp !osre d1m   side 2
        mov osr, crc    side 1      ; the data has run out: the FCS, low half
        jmp !x c0       side 1
c1:     out x, 1        side 2      ; sending a 1 from the FCS's low half
        jmp !osre c1m   side 2
        mov osr, crc    side 1      ; its high half
        jmp !x e0       side 1
e1:     out x, 1        side 2      ; sending a 1 from the FCS's high half
        jmp !osre e1m   side 2
        jmp !x e1z      side 1      ; one bit left, in X
        jmp last1       side 1

d0:     out x, 1        side 1      ; the same three, sending a 0
        jmp !osre d0m   side 1
        mov osr, crc    side 2
        jmp x-- c1      side 2
c0:     out x, 1        side 1
        jmp !osre c0m   side 1
        mov osr, crc    side 2
        jmp x-- e1      side 2
e0:     out x, 1        side 1
        jmp !osre e0m   side 1
        jmp x-- e0o     side 2
        jmp last0       side 2

d1m:    jmp !x d1z      side 1      ; the second half of the bit, and on to
        jmp d1          side 1      ;   the loop for the next
d1z:    jmp d0          side 1
c1m:    jmp !x c1z      side 1
        jmp c1          side 1
c1z:    jmp c0          side 1
e1m:    jmp !x e1z2     side 1
        jmp e1          side 1
e1z2:   jmp e0          side 1
d0m:    jmp !x d0z      side 2
        jmp d1          side 2
d0z:    jmp d0          side 2
c0m:    jmp !x c0z      side 2
        jmp c1          side 2
c0z:    jmp c0          side 2
e0m:    jmp !x e0z      side 2
        jmp e1          side 2
e0z:    jmp e0          side 2

e1z:    jmp last0       side 1
e0o:    jmp last1       side 2
last1:  nop             side 2 [1]  ; the last bit, a 1: low, then high
        nop             side 1 [1]
idle:   nop             side 1 [3]  ; start of idle: TD+ high for three bit times
        nop             side 1 [3]
        nop             side 1 [3]
link:   set y, 9        side 0      ; between frames: ten waits of TIMEOUT ticks,
lwait:  wait 1 pin 0 timeout side 0 ;   each on TD+, which this thread holds low,
ltick:  jmp y-- lwait   side 0      ;   and each ending here, at the timeout vector
        nop             side 1 [3]  ; then a link pulse: TD+ high for 100 ns
        jmp link        side 0
last0:  nop             side 1 [1]  ; the last bit, a 0: high, then low
        nop             side 2
        jmp idle        side 2
|}
;;

(* CRC-32 as Ethernet sends it: the polynomial low power first, the
   register starting as all ones and sent inverted. *)
(* [link] and [ltick] in the program above. *)
let eth_tx_link = eth_tx_origin + 62
let eth_tx_tick = eth_tx_link + 2

(* A tenth of the time between link pulses, in clocks: 1.6 ms at 40 MHz. *)
let eth_tx_link_ticks = 64_000

let eth_tx_config ~odd =
  { Isa.Thread_config.default with
    start = (if odd then eth_tx_odd else eth_tx_origin)
  ; timeout_vector = eth_tx_tick
  ; timeout = eth_tx_link_ticks
  ; threshold = 16
  ; sideset_base = 0
  ; sideset_count = 2
  ; autopull = true
  ; crc_poly = 0xEDB88320
  ; crc_init = 0xFFFF_FFFF
  ; crc_invert = true
  }
;;

let eth_tx_image () = Asm.link [ eth_tx_origin, Asm.assemble ~origin:eth_tx_origin eth_tx ]

(* The buffer's words for a frame of bytes, as [eth_tx] wants them. *)
let eth_tx_words bytes =
  let odd = List.length bytes % 2 = 1 in
  let bytes = if odd then 0 :: bytes else bytes in
  List.chunks_of bytes ~length:2
  |> List.map ~f:(function
    | [ a; b ] -> a lor (b lsl 8)
    | _ -> assert false)
;;

(* 10BASE-T receive: the other half of [eth_tx], for one thread with the
   bit sampler in front of it.

   The sampler does what no program here is fast enough for: it finds the
   middle of each bit on the wire (clock recovery), reads the bit there
   (Manchester decoding) and lets nothing through until the preamble's last
   byte, 0xD5, has gone by. What reaches this program is the frame, a bit at
   a time: the bit on pin 2 and a one-cycle pulse on pin 3 as each arrives,
   never fewer than three cycles apart.

   The program takes each bit with one IN. Every 16 make a word, pushed by
   itself, and the CRC register follows them, FCS included, so that after a
   good frame it holds the same number whatever the frame was (0xDEBB20E3).
   X counts the bits. When no pulse comes for TIMEOUT ticks the frame is
   over, and the program pushes three more words: the count, as 0x10000
   minus the number of bits, and the CRC register's two halves. An odd last
   byte gets a word of its own first. With the buffer recording, the host
   reads back the frame and those three words when it likes.

   Config: [eth_rx_config]; sampler: [eth_rx_sampler]. The clock is 40 MHz,
   as for [eth_tx], or 50 MHz with [eth_rx_sampler_50]. *)
let eth_rx_origin = 0
let eth_rx_data_pin = 2

let eth_rx =
  {|
rx:     mov crc, null           ; the CRC starts from its initial value
        mov x, null
        jmp x-- first           ; X = 0xFFFF: it counts the bits, downwards
first:  wait 1 pin 3            ; a frame's first bit
bit:    in pins, 1              ; take it; the CRC register follows
        wait 1 pin 3 timeout    ; the next bit, or the end of the frame
        jmp x-- bit
eof:    mov y, crc              ; what is left in the CRC register, low half:
                                ;   reading it stops it following the INs
        in null, 8              ; an odd last byte becomes a word of its own
        in x, 16                ; then three more words: the bit count,
        in y, 16                ;   the CRC register's low half
        mov y, crc
        in y, 16                ;   and its high half
        jmp rx
|}
;;

(* [eof] above: where the thread goes when a frame's bits stop. *)
let eth_rx_eof = eth_rx_origin + 7

let eth_rx_config =
  { Isa.Thread_config.default with
    start = eth_rx_origin
  ; in_base = eth_rx_data_pin
  ; threshold = 16
  ; autopush = true
  ; timeout_vector = eth_rx_eof
  ; timeout = 8
  ; crc_poly = 0xEDB88320
  ; crc_init = 0xFFFF_FFFF
  ; crc_in = true
  }
;;

(* The sampler for 10 Mbit Manchester on a 40 MHz clock: 8 samples to the
   bit. The edge between two bits shows 4 samples after the one in the
   middle, or 5 if it is late; the next middle edge 8 after, give or take.
   Edges are accepted from 6 on. Twelve samples without one end the frame. *)
let eth_rx_sampler =
  { Isa.Sampler_config.enable = true
  ; pin = eth_rx_data_pin
  ; invert = false
  ; sync_enable = true
  ; sync = 0xD5
  ; misses = 0
  ; blank = 5
  ; sample = 1
  ; wrap = 11
  ; prescale = 0
  ; shift = 0
  ; stuff = 0
  }
;;

(* The same on a 50 MHz clock, 10 samples to the bit: edges accepted from 8
   on. More margin, but [eth_tx] cannot run on this clock. *)
let eth_rx_sampler_50 = { eth_rx_sampler with blank = 7; sample = 2; wrap = 14 }
let eth_rx_image () = Asm.link [ eth_rx_origin, Asm.assemble ~origin:eth_rx_origin eth_rx ]

(* The residue: what the CRC register holds after a frame and its FCS. *)
let eth_rx_residue = 0xDEBB20E3

(* What [eth_rx] pushed for one frame, read back: the frame's bytes (FCS
   included) and whether the CRC register ended at the residue. An error
   says why the words are not one whole frame. *)
let eth_rx_frame (words : int list) =
  match List.rev words with
  | crc_hi :: crc_lo :: count :: data when List.length words >= 3 ->
    let bits = (0x10000 - count) land 0xFFFF in
    let data = List.rev data in
    if bits % 8 <> 0
    then Error (sprintf "%d bits is not a whole number of bytes" bits)
    else (
      let bytes = bits / 8 in
      if List.length data <> (bytes + 1) / 2
      then Error (sprintf "%d bytes counted but %d words" bytes (List.length data))
      else (
        let all = List.concat_map data ~f:(fun w -> [ w land 0xFF; w lsr 8 ]) in
        (* An odd last byte is alone in the low half of its word. *)
        Ok (List.take all bytes, (crc_hi lsl 16) lor crc_lo = eth_rx_residue)))
  | _ -> Error "fewer than three words"
;;

(* Compact JTAG (IEEE 1149.7) as the debug probe: two pins, TCKC and TMSC,
   in the OScan1 format. The chip brings a TAP.7 online with escape
   sequences and the online activation code, then runs JTAG scans the way
   [jtag] does, each JTAG clock as an OScan1 packet of three TCKC clocks on
   the one data line: the inverse of TDI, then TMS, both from the chip, then
   TDO from the target.

   An escape is TMSC toggled while TCKC is high: eight edges reset the
   TAP.7, six select it. The activation is OpenOCD's for its cJTAG
   adapters: the reset escape, three clocks, the selection escape and
   twelve bits, the online activation code for OScan1 (0, 0, 1, 1, first
   bit first), the extension code (0, 0, 0, 1) and the check packet (0, 0,
   0, 0). J-Link's short activation sends the same twelve bits.

   TMSC changes only while TCKC is low, a tick after it fell: never in a
   tick where TCKC moves, except at the start of the TDO bit, where the
   chip lets go of TMSC as TCKC falls and the target takes it over, as the
   standard has the two sides change over at that edge.

   Pins: P0 = TCKC (side-set, push-pull); P1 = TMSC (open-drain, with a
   pull-up: a 1 releases it, which is how the target gets the line for
   TDO). Config: [cjtag_config]: sideset_base 0, sideset_count 1; set_base
   1, set_count 1; out_base 1, out_count 1; in_base 1; threshold 16.

   Host protocol:
     TX word 0x8000 : bring the target online in OScan1 (no RX word).
     TX word N - 1  : a scan of N JTAG clocks (1 to 32768), then ceil(N /
                      8) words of (TDI, TMS) pairs, LSB first: bits 2k and
                      2k + 1 are TDI and TMS for the k-th clock of the
                      word ([cjtag_words] builds them).
     RX             : ceil(N / 8) words of TDO, one bit per clock, LSB
                      first, as [jtag] returns them.

   Timing: an OScan1 packet is 13 ticks, TCKC high for one tick in each of
   its three clocks: 770 kHz of JTAG clocks (2.3 MHz TCKC) at 10 MHz with
   CLKDIV 1, five times that at 50 MHz. TDO is sampled three ticks after
   TCKC falls, just before it rises; it passes the input synchroniser, so
   the target must drive it within one core clock of TCKC falling at
   CLKDIV 1 (CLKDIV 2 gives it three). *)
let cjtag =
  {|
        .side_set 1
next:   pull                side 0     ; a command
        out x, 15           side 0     ; clocks - 1
        out y, 1            side 0     ; bit 15: bring the target online
        jmp !y word         side 0
        set pins, 0         side 0     ; TMSC low while TCKC is low
        set y, 3            side 1     ; TCKC rises
reset:  set pins, 1         side 1     ; reset escape: eight edges while TCKC is high
        set pins, 0         side 1
        jmp y-- reset       side 1
        set y, 2            side 0     ; TCKC falls
pad:    nop                 side 1     ; three clocks with TMSC low
        jmp y-- pad         side 0
        set y, 2            side 1     ; TCKC rises
select: set pins, 1         side 1     ; selection escape: six edges
        set pins, 0         side 1
        jmp y-- select      side 1
        set y, 1            side 0     ; TCKC falls
oac0:   nop                 side 1     ; OAC bits 0 and 1: 0
        jmp y-- oac0        side 0
        set pins, 1         side 0
        set y, 1            side 0
oac1:   nop                 side 1     ; OAC bits 2 and 3: 1
        jmp y-- oac1        side 0
        set pins, 0         side 0
        set y, 2            side 0
ec0:    nop                 side 1     ; EC bits 0 to 2: 0
        jmp y-- ec0         side 0
        set pins, 1         side 0
        nop                 side 1     ; EC bit 3: 1
        nop                 side 0
        set pins, 0         side 0
        set y, 3            side 0
cp:     nop                 side 1     ; the check packet: four 0s
        jmp y-- cp          side 0
        set pins, 1         side 0     ; TMSC released: online, in OScan1
        jmp next            side 0
word:   pull                side 0     ; up to 8 clocks of (TDI, TMS)
bit:    out y, 1            side 0     ; TDI
        jmp !y tdi0         side 0
        set pins, 0         side 0     ; nTDI: TMSC low for a 1
        jmp ntdi            side 1     ; TCKC rises: the target takes it
tdi0:   set pins, 1         side 0     ; and high for a 0
        nop                 side 1
ntdi:   nop                 side 0     ; TCKC falls
        out pins, 1         side 0     ; TMS
        nop                 side 1     ; TCKC rises: the target takes it
        set pins, 1         side 0     ; TCKC falls, TMSC released: the target drives TDO
        nop                 side 0 [1] ; through the input synchroniser
        in pins, 1          side 1     ; TCKC rises: TDO sampled just before
        jmp x-- more        side 0     ; TCKC falls: the target lets go
        push                side 0     ; the scan is done: its last TDO bits
        jmp next            side 0
more:   jmp !osre bit       side 0
        push                side 0     ; 8 TDO bits
        jmp word            side 0
|}
;;

let cjtag_config =
  { Isa.Thread_config.default with
    sideset_base = 0
  ; sideset_count = 1
  ; set_base = 1
  ; set_count = 1
  ; out_base = 1
  ; out_count = 1
  ; in_base = 1
  ; threshold = 16
  }
;;

let cjtag_activate = 0x8000

(* Host-side words for a scan: [tms] and [tdi] give one bit per clock. *)
let cjtag_words ~tms ~tdi =
  let n = List.length tms in
  assert (n = List.length tdi && n >= 1 && n <= 32768);
  let pairs = List.zip_exn tdi tms |> List.chunks_of ~length:8 in
  (n - 1)
  :: List.map pairs ~f:(fun chunk ->
    List.foldi chunk ~init:0 ~f:(fun k acc (d, m) ->
      acc lor (Bool.to_int d lsl (2 * k)) lor (Bool.to_int m lsl ((2 * k) + 1))))
;;

(* PJDL timing: (tick in us, data bit in ticks, pad bit in ticks) for each
   of the specification's four communication modes. Modes 1 to 3 count in
   4 us ticks, mode 4 in 2 us: data bits of 44, 40, 28 and 26 us, pads of
   116, 92, 88 and 60 us. *)
let pjdl_timing ~mode =
  match mode with
  | 1 -> 4, 11, 29
  | 2 -> 4, 10, 23
  | 3 -> 4, 7, 22
  | 4 -> 2, 13, 30
  | _ -> invalid_arg "PJDL modes are 1 to 4"
;;

(* A PJON node sending packets over PJDL (Padded Jittering Data Link), the
   one-wire link of the PJON protocol, in one of PJDL's four modes. The
   line idles low. A packet is a frame initializer, three synchronization
   pads (a pad bit high, then a data bit low), then its bytes, each a
   synchronization pad and eight data bits, least significant first. Every
   time is exact to the tick: the pad bit 116, 92, 88 or 60 us and the data
   bit 44, 40, 28 or 26 us in modes 1 to 4 ([pjdl_timing]). test/pjdl.hex
   is mode 4.

   The PJON packet: receiver ID, header configuration, length, the meta CRC
   (a CRC8 of the three bytes before it), then sender ID, port, packet ID
   and payload as the configuration has them, then the end CRC. The
   program puts in both CRCs, with PJON's CRC8 (polynomial 0x97, written
   low power first, from 0), which is the one PJON uses for packets of 15
   bytes or less; above that PJON asks for CRC32, which this program does
   not send. The CRC register follows each data bit as it goes out, and
   not the pads. After the meta CRC it starts again from 0, which is what
   it would hold anyway: a CRC from 0 with no final inversion, run over
   bytes and then their own CRC, comes back to 0. So the end CRC covers the
   whole packet, as PJON's does.

   The length byte is the host's, as CAN's DLC is: the program counts the
   bytes it sends by it. Before every packet the line is low for longer
   than a byte (a pad and ten data bits), the time PJDL asks a free line to
   have been quiet, and the time after which a receiver takes a frame to
   have ended. The program does not listen for a free line first, ask for
   or wait for an acknowledgement, or receive: its pin drives both levels,
   and PJDL's other nodes need the line released to a pull-down, which no
   pin mode of the chip does.

   Pins: P0 = the line, push-pull. Config: [pjdl_config]: set_base 0,
   set_count 1; out_base 0, out_count 1; threshold 8; crc_poly 0x97,
   crc_init 0; CLKDIV makes a tick 4 us (2 us in mode 4): 40 (20) at 10
   MHz, 200 (100) at 50 MHz.

   Host protocol: one TX word for each byte of the packet except the two
   CRCs, in order: receiver ID, header configuration, length (the whole
   packet's, CRCs included, 5 to 15), and the rest. Each byte must be in
   the FIFO by the time its pad begins. RX: one word for each packet when
   it has gone out, its end CRC. *)
let pjdl ~mode =
  let _, d, p = pjdl_timing ~mode in
  (* Instructions taking [n] ticks in all. *)
  let fill n =
    List.init ((n + 15) / 16) ~f:(fun i ->
      sprintf "        nop [%d]\n" (min 16 (n - (16 * i)) - 1))
    |> String.concat
  in
  sprintf
    {|
start:  set pins, 0             ; the line low: idle
idle:   set y, %d
gap:    jmp y-- gap [15]        ; for longer than a byte before a packet
        pull                    ; the receiver ID: a packet begins
        mov crc, null           ; the CRC register from 0
        set y, 2
init:   set pins, 1 [%d]        ; the frame initializer: three pads
%s        set pins, 0 [%d]        ; each with its low data bit
        jmp y-- init
        set pins, 1             ; tick 0 of a byte: its pad begins
        set y, 2                ; three bytes before the meta CRC
        jmp first
hdr:    pull
first:  mov x, osr              ; tick 3; the last of them is the length
%s        set pins, 0 [%d]        ; the sync pad's low data bit
hbit:   out pins, 1 [%d]        ; a data bit
        jmp !osre hbit
        set pins, 1             ; tick 0 of the next pad
        jmp y-- hdr
        mov osr, crc            ; tick 2: the meta CRC; the register stops
        jmp x-- m1              ; X: the length less 5, the bytes
m1:     jmp x-- m2              ; still to come from the host
m2:     jmp x-- m3
m3:     jmp x-- m4
m4:     jmp x-- m5
m5:
%s        set pins, 0 [%d]
mbit:   out pins, 1 [%d]
        jmp !osre mbit
        set pins, 1
        mov crc, null           ; tick 1: from 0 again, as it is over the bytes so far
pnext:  jmp !x end              ; tick 2: no more bytes from the host
        pull
        jmp x-- p1
p1:
%s        set pins, 0 [%d]
pbit:   out pins, 1 [%d]
        jmp !osre pbit
        set pins, 1
        jmp pnext
end:    mov osr, crc            ; tick 3: the end CRC
        mov x, osr
        in x, 8                 ; for the host too
%s        set pins, 0 [%d]
ebit:   out pins, 1 [%d]
        jmp !osre ebit
        set pins, 0             ; the line low again: the packet has gone
        push
        jmp idle
|}
    ((((p + (10 * d)) + 15) / 16) - 1)
    (min 15 (p - 1))
    (fill (p - 1 - min 15 (p - 1)))
    (d - 2)
    (fill (p - 4))
    (d - 1)
    (d - 2)
    (fill (p - 8))
    (d - 1)
    (d - 2)
    (fill (p - 5))
    (d - 1)
    (d - 2)
    (fill (p - 6))
    (d - 1)
    (d - 2)
;;

let pjdl_config ~mode ~clock_hz =
  let tick_us, _, _ = pjdl_timing ~mode in
  { Isa.Thread_config.default with
    set_base = 0
  ; set_count = 1
  ; out_base = 0
  ; out_count = 1
  ; threshold = 8
  ; crc_poly = 0x97
  ; crc_init = 0
  ; clkdiv = clock_hz / 1_000_000 * tick_us
  }
;;

(* The TX words for a PJON packet to [receiver] with [payload], from
   [sender] if there is one (header configuration bit 1, sender info). *)
let pjdl_words ?sender ~receiver payload =
  let info = Option.to_list sender in
  [ receiver; (if Option.is_some sender then 0x02 else 0x00); 5 + List.length info + List.length payload ]
  @ info
  @ payload
;;

(* NXP's LFAST link sending SIPI frames (SIPI, also called Zipwire: reads
   and writes of another chip's memory over LFAST), at LFAST's low speed,
   5 Mbit/s. An LFAST frame is NRZ, most significant bit first: the sync
   pattern 0xA84B, a header byte (the payload's size, the logical channel,
   CTS), the payload, and a sleep bit. Here the payload is a SIPI frame: a
   header word (tag, command, channel), the address and data the command
   has, and a CRC-16 over all of them: CCITT's polynomial, from all ones,
   most significant bit first, as SIPI has it.

   The program makes the sync pattern, the timing, the CRC and the sleep
   bit (0: no request for the LVDS sleep mode), after which the line is
   low for twelve bit times or more before the next frame. LFAST puts no
   number on that time; twelve is for sigrok's decoder, which ends a frame
   that ends without an edge by a timeout of up to eight bit times, and
   takes an edge before then into the frame.

   The CRC register works least significant bit first, so it runs with
   the polynomial reversed (0x8408) and holds the CRC reversed: its bit 0
   is the CRC's top bit, the first to go out. The ISR turns it round:
   [mov isr, crc], then for each bit the ISR's bit 0 goes to the pin and
   [in null, 1] shifts the ISR right by one.

   LFAST is a differential LVDS pair: the pin is TXP's level, for an LVDS
   driver. A real link also shares a reference clock between the two chips,
   which the chip does not provide, and answers on a second pair, which
   this program does not read: it sends.

   Pins: P0 = the line, push-pull, low when idle. Config: [lfast_config]:
   out_base 0, out_count 1; set_base 0, set_count 1; threshold 16; out
   most significant bit first; crc_poly 0x8408, crc_init 0xFFFF.
   A bit is 5 ticks: CLKDIV 2 at 50 MHz for 5 Mbit/s.

   Host protocol, per frame:
     TX word 0 : the LFAST header byte in bits 15:8 (payload size code,
                 logical channel, CTS, as the frame has them), and in bits
                 4:0 the number of words that follow, less one
     then      : the SIPI frame without its CRC, 16 bits a word, most
                 significant first: its header, then the address and the
                 data.
   The payload size in the header must be the SIPI frame's bytes, CRC
   included: 2 x (words + 1), so 1, 3, 5, 7, 15, 17 or 31 words for LFAST's
   sizes of 4 to 64 bytes. A word is taken as the one before it ends,
   one every 80 ticks, faster than the host port can push them: the
   driver fills the packet buffer and plays it into the FIFO. *)
let lfast =
  {|
next:   set pins, 0             ; the line low: idle
        pull                    ; the LFAST header, and the SIPI frame's words less one
        set pins, 1 [4]         ; the sync pattern, 1010 1000 0100 1011, 5 ticks a bit
        set pins, 0 [4]
        set pins, 1 [4]
        set pins, 0 [4]
        set pins, 1 [4]
        set pins, 0 [15]
        set y, 6 [3]
        set pins, 1 [4]
        set pins, 0 [9]
        set pins, 1 [4]
        set pins, 0 [4]
        set pins, 1 [9]
hb:     out pins, 1 [3]         ; the header byte
        jmp y-- hb
        out pins, 1             ; its last bit, 5 ticks with the next four
        out x, 8                ; X: the SIPI frame's words less one
        mov crc, null           ; the CRC covers the SIPI frame alone
        nop
word:   pull                    ; a word of the SIPI frame
bit:    out pins, 1 [1]         ; its bits
        jmp !osre more
        jmp x-- word
        mov isr, crc            ; the last bit has gone: the CRC, its top bit in bit 0
crc:    mov pins, isr [2]
        in null, 1
        jmp !isrf crc
        set pins, 0 [4]         ; the sleep bit: 0
        set y, 3
gap:    jmp y-- gap [14]        ; and the line idle for twelve bits
        jmp next
more:   jmp bit [1]
|}
;;

let lfast_config ~clkdiv =
  { Isa.Thread_config.default with
    out_base = 0
  ; out_count = 1
  ; set_base = 0
  ; set_count = 1
  ; threshold = 16
  ; out_msb_first = true
  ; crc_poly = 0x8408
  ; crc_init = 0xFFFF
  ; clkdiv
  }
;;

(* The TX words for an LFAST frame with [header] carrying the SIPI frame
   [words] (its CRC left out). *)
let lfast_words ~header (words : int list) = ((header lsl 8) lor (List.length words - 1)) :: words

let all =
  [ "uart_tx", uart_tx
  ; "echo", echo
  ; "i2c_controller", i2c_controller
  ; "spi_controller", spi_controller
  ; "spi_fast", spi_fast
  ; "i2c", i2c
  ; "uart_rx", uart_rx ~pin:0
  ; "i2c_target", i2c_target
  ; "spi_target", spi_target
  ; "jtag", jtag
  ; "swd", swd
  ; "usb", usb
  ; "onewire", onewire
  ; "ps2_rx", ps2_rx
  ; "ps2_tx", ps2_tx
  ; "can_rx", can_rx
  ; "can_tx", can_tx
  ; "i2s_tx", i2s_tx
  ; "dmx_tx", dmx_tx
  ; "wiegand_tx", wiegand_tx
  ; "nec_tx", nec_tx
  ; "mdio", mdio
  ; "dali_tx", dali_tx
  ; "rc5_tx", rc5_tx
  ; "wiegand_rx", wiegand_rx
  ; "nec_rx", nec_rx
  ; "dali_rx", dali_rx
  ; "rc5_rx", rc5_rx
  ; "microwire", microwire
  ; "cec", cec
  ; "ir_tx", ir_tx
  ; "stepper", stepper
  ; "dht", dht
  ; "bitstream", bitstream
  ; "tdm_tx", tdm_tx
  ; "tlc5620", tlc5620
  ; "sirc_tx", sirc_tx
  ; "sle4442", sle4442
  ; "pwm", pwm
  ; "nes_pad", nes_pad
  ; "sbus_tx", sbus_tx
  ; "dshot", dshot
  ; "xy2_x", xy2_x
  ; "xy2_y", xy2_y
  ; "caliper", caliper
  ; "i3c", i3c
  ; "sent_tx", sent_tx
  ; "j1850_tx", j1850_tx
  ; "cjtag", cjtag
  ; "pjdl", pjdl ~mode:4
  ; "lfast", lfast
  ]
