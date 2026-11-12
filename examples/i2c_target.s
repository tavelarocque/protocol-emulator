; i2c_target: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; I2C target (device mode): the chip answers as a 7-bit-address I2C device
; that any controller can write to and read from, with clock stretching and
; repeated START.
;
; Pins: P0 = SDA, P1 = SCL, both open-drain. Config: [i2c_target_config]:
; in_base 0, out_base 0, set_base 0 (SDA); sideset_base 1 (SCL, so any
; instruction can hold it low); threshold 8; IN shifts MSB first; TIMEOUT 0
; and timeout_vector [i2c_target_rest] (see "branching on a pin" below).
;
; Host protocol.
;   TX word 0  : the device's 7-bit address (1 to 127).
;   TX, then   : one word per byte a controller reads, bit-reversed (OUT
;                shifts LSB first; [reverse_byte]). The firmware takes a
;                word only once the previous byte was ACKed, so exactly the
;                bytes sent are consumed. If none is ready it holds SCL low
;                until the host pushes one.
;   RX         : one word per byte a controller writes (the byte as is,
;                0 to 255), and, for every START or repeated START that
;                addresses this device, a marker word: the address byte
;                (address << 1 | R/W) << 8, so always 256 or more. A register
;                read therefore arrives as [W marker; register; R marker].
;                While the RX FIFO is full the firmware holds SCL low, after
;                ACKing the byte.
;
; Bus conditions. A START is SDA falling while SCL is high; a STOP is SDA
; rising while SCL is high. Between transactions ([idle]) the firmware
; watches every SDA falling edge and checks SCL, so it also sees the
; repeated STARTs of other devices' transactions. Inside a write, a STOP or
; repeated START can only come where the first bit of a byte would be, so
; that bit gets a polling loop that watches SCL and SDA together; the
; other seven bits use plain waits. Both conditions go to [start], which
; waits for SCL to fall: after a repeated START that is the next address;
; after a STOP, SCL stays high until the next START, so it is the same.
;
; The address is compared after its seventh bit, during the R/W bit, so
; the ACK is on SDA 4 clocks after SCL falls. The first version compared
; the whole address byte after the eighth bit, which on a read put the ACK
; and a one-clock SCL pulse 10 to 11 clocks after SCL fell; the reference
; controller with SCL low for 10 clocks saw the pulse as an extra clock
; and flagged a cut byte.
;
; Branching on a pin. That loop must leave on either of two pins. The SCL
; exit is a [wait 1 pin 1 timeout] with TIMEOUT 0: it falls through while
; SCL is high and jumps to timeout_vector ([rest], the remaining 7 bits)
; the moment SCL is low. SDA is read through the OSR ([mov osr, pins] then
; [out x, 1]), which isolates pin 0 whatever the other pins are doing.
; The loop reads SDA first and SCL after it. A controller may change SDA
; as soon as SCL has fallen (the spec's minimum data hold time is 0), so
; an SDA change only counts as STOP or repeated START if SCL is still high
; afterwards. Checking SCL first and SDA second looks equivalent but is
; not: a data bit whose SDA moves in the same clock as SCL falls would
; read as a repeated START or a STOP. The tests keep that version as a
; planted bug, and only a controller with zero hold time catches it.
;
; Timing. The reference controller in the tests works down to an SCL low
; time of 7 core clocks, with a data hold time of one clock or of zero; the
; random tests cover 7 to 62. Its data setup time (SDA settled before SCL
; rises) must be at least 2 clocks, since [idle] reads SCL one clock after
; it sees SDA fall; that one is from reading the code, not measured. At 10
; MHz the I2C spec's fast mode (400 kHz) guarantees 13 clocks low and 1 of
; setup, so: standard mode, and fast mode from a controller with 2 clocks
; of setup or more (cocotbext-i2c's I2cMaster has 12). Not supported:
; general call (address 0), 10-bit addresses, and a STOP or START in the
; middle of a byte.
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
