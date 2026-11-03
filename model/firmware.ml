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

(* Low-speed USB transmit engine (1.5 Mbit/s): sends one packet's line
   states at exactly 8 core clocks per bit, so the core clock must be
   12 MHz, then ends it with EOP (two bit times of SE0, one of J) and
   releases the bus. The packet itself (SYNC, PID, payload, CRC, bit
   stuffing, NRZI) is built by the host ([Usb_model.packet_lines], and
   UsbHost in the board driver), the split RP2040 PIO-USB uses too.

   The chip cannot release a push-pull pin by itself (pin modes are the
   host's), so it drives the bus through a standard USB 1.1 transceiver in
   its VO/FSE0 mode, as FPGA and microcontroller USB cores do: VO is the
   differential data (1 = D+ high = K at low speed), FSE0 forces SE0, OE_N
   enables the drivers, and VP / VM are the transceiver's single-ended
   receivers (D+ and D-).

   Pins: P0 = VP, P1 = VM (inputs, for the receive side); P2 = VO,
   P3 = FSE0, P4 = OE_N (push-pull; FSE0 and OE_N by side-set, value bit 0
   is FSE0). Config: [usb_tx_config].

   Host protocol, per packet:
     TX word 0 : N - 1, for N line states (the packet without its EOP)
     then      : ceil(N / 16) words, bit k = VO for the k-th bit time.
   The host must keep the TX FIFO from running dry mid-packet: a word
   arriving late stretches a bit.

   Timing: every bit, word boundaries included, is 8 clocks: out [3] (4),
   jmp x-- (1), jmp !osre (1), jmp bit [1] (2); at a boundary the last two
   are replaced by the fall-through (1) and pull [1] (2). Between packets
   the bus is released and idle for at least 17 clocks, two bit times, the
   USB 1.1 minimum between a host's consecutive packets (7.1.18). *)
let usb_tx =
  {|
        .side_set 2
gap:    set x, 4            side 2     ; bus released and idle at least two
idle:   jmp x-- idle        side 2 [2] ; bit times before every packet
        pull                side 2     ; X <- line states - 1
        out x, 16           side 2
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
        jmp gap             side 2     ; then release the bus
pad:    jmp bit             side 0 [1]
|}
;;

let usb_tx_config =
  { Isa.Thread_config.default with
    out_base = 2
  ; out_count = 1
  ; set_base = 2
  ; set_count = 1
  ; sideset_base = 3
  ; sideset_count = 2
  ; threshold = 16
  }
;;

(* Host words for one packet, from its line states without the EOP (J and K
   only): VO = 1 for K. *)
let usb_tx_words (lines : Usb_model.line list) =
  let n = List.length lines in
  assert (n >= 1 && n <= 65536);
  (n - 1)
  :: List.map (List.chunks_of lines ~length:16) ~f:(fun chunk ->
    List.foldi chunk ~init:0 ~f:(fun k acc (l : Usb_model.line) ->
      match l with
      | K -> acc lor (1 lsl k)
      | J -> acc
      | Se0 -> invalid_arg "usb_tx_words: SE0 is the firmware's"))
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

(* Low-speed USB host, as the board uses it: [usb_tx] on thread 1, fed
   through CHAIN by [echo] on thread 0, which turns the FIFOs of both threads
   into one buffer of about 13 words. The host loads a whole transaction
   (a SETUP token and its 8-byte DATA0 packet are 10 words) with thread 1
   stopped, then starts it with one CTRL write, so the packets go out at
   full speed however slowly the host fed them. CHAIN moves words whether or
   not thread 1 runs; a re-enabled thread starts again at its START. *)
module Usb_host = struct
  let relay_origin = 0
  let relay = Asm.assemble ~origin:relay_origin echo
  let tx_origin = relay_origin + Array.length relay
  let tx = Asm.assemble ~origin:tx_origin usb_tx
  let image = Asm.link [ relay_origin, relay; tx_origin, tx ]
  let relay_config = { Isa.Thread_config.default with start = relay_origin }
  let tx_config = { usb_tx_config with start = tx_origin }

  (* P2, P3, P4 push-pull; the rest inputs. *)
  let mode_bits = 0b01_01_01_00_00

  (* CTRL while loading (thread 0 and CHAIN) and to send (both threads). *)
  let ctrl_load = 0b101
  let ctrl_send = 0b111
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
  ; "usb_tx", usb_tx
  ]
