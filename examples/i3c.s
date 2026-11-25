; i3c: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; MIPI I3C controller, SDR mode: START, the broadcast address 0x7E and
; the CCCs sent after it, ENTDAA to give targets their dynamic
; addresses, private writes and reads to a target at its dynamic address,
; repeated START and STOP. What I3C has and I2C does not is done here: the
; ninth bit after a byte the controller writes is T, odd parity over the
; byte, computed by the CRC register; after a byte a target returns it is
; the target's end-of-data bit, and the controller ends a read the target
; would go on with by pulling SDA low while SCL is high in that bit; and
; ENTDAA reads each target's 48-bit provisioned ID, BCR and DCR as 64
; bits that the targets arbitrate for, then sends the dynamic address with
; its parity bit.
;
; Pins: P0 = SDA, open-drain; P1 = SCL, push-pull, driven by side-set.
; SDA stays open-drain for the whole frame. The specification wants a
; controller to drive SDA push-pull for data and switch to open drain for
; the address arbitration and the ACK, but a pin's drive mode here is set
; by the host and no instruction can change it, so a frame on this chip
; is open-drain throughout. The levels on the wire are the same; what
; changes is that a rising SDA edge comes from the pull-up, so every bit
; is timed to the specification's open-drain limits, not its push-pull
; ones (below).
;
; Config: [i3c_config]: out_base 0, out_count 1, set_base 0, set_count 1,
; in_base 0 (SDA); sideset_base 1, sideset_count 1 (SCL); threshold 16;
; out and in most significant bit first; CRC polynomial 1 from 0, read
; inverted, so the register is the parity of the bits OUT shifted and a
; read of it is the odd parity bit; start [i3c_idle]; TIMEOUT 0 and
; timeout_vector [i3c_ended], which makes [wait ... timeout] a branch on
; SDA. CLKDIV makes a tick 100 ns or more: 1 at 10 MHz, 5 at 50 MHz.
;
; Timing. A bit is SCL low for 3 ticks and high for 2 (the ninth bits and
; those around a START longer), so 2 MHz with a 100 ns tick, at 10 MHz or
; 50 MHz alike. That is the fastest the open-drain timing allows: SCL low
; at least 200 ns (tLOW_OD) and, in the address after a START, high at
; least 200 ns (tHIGH_INIT). It is not I3C's 12.5 MHz, which needs
; push-pull SDA, and at 50 MHz a 5-tick bit could not reach it anyway
; (10 MHz at CLKDIV 1). SDA changes one tick after SCL falls and two
; before it rises. START and repeated START hold SDA low two ticks before
; SCL falls (tCAS, under ENTAS0's 1 us); SCL is high two ticks or more
; before STOP and repeated START. A bus with I2C devices on it is not
; supported: their spike filters need SCL high under 50 ns.
;
; Host protocol: a frame is a segment word, then that segment's data
; words if it writes, then further segments, each after a repeated START,
; and finally the STOP word. The first word after STOP must be a segment.
;   segment : bit 15 = 1; bits 14:7 the address byte (address << 1 |
;             R/W); bit 6 = R/W again; bits 5:0 for a read the most bytes
;             to read (1 to 63), 0 for an ENTDAA round (address 0x7E,
;             read). [i3c_segment]
;   data    : bits 15:14 = 00, bits 13:6 a byte to write; the firmware
;             adds its T bit. [i3c_data]
;   STOP    : 0x4000. [i3c_stop]
;   address : in an ENTDAA round, once the round's 0x7E has been
;             ACKed: the dynamic address in bits 15:9, bit 8 clear; the
;             firmware adds its parity bit. [i3c_address_word]
; RX words:
;   after every address : 0 ACK, 1 NACK. A segment NACKed has its data
;             words taken from the FIFO unsent, up to the next segment or
;             STOP, which is then done as usual.
;   after a byte read   : byte << 1 | T. T = 1 the target had more;
;             T = 0 it ended the read there, and no more words come for
;             that segment. The last byte asked for has T as the target
;             sent it, and the controller ends the read whatever it was.
;   an ENTDAA round ACKed : four words of 16 bits, the 64 bits the target
;             won the arbitration with (provisioned ID 47:32, 31:16, 15:0,
;             then BCR << 8 | DCR), then the ACK of the dynamic address.
; A round NACKed means no target wants an address: the host sends STOP.
;
; Where it waits. Every PULL and PUSH comes with SCL low, just after a
; ninth bit (an ACK, a T bit) or, in ENTDAA, after the round's ACK, so a
; host that falls behind stretches the low half of the clock at a place
; the specification lets a controller stall it. The 64 bits of an ENTDAA
; round are pushed as they come; a host that pops the round's ACK before
; it sends the address leaves the FIFO room for all four.
;
; Not supported: in-band interrupts and hot-join (an address a target
; wins in the arbitrable header is reported as an ACK or NACK, no more),
; HDR modes, and I2C devices on the bus.
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
