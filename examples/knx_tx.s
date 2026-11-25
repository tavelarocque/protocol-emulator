; knx_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; KNX TP1, the twisted-pair medium of the KNX building automation bus: a
; sender of telegrams, which then listens for the acknowledgement. 9600
; bit/s; a logical 0 is the bus pulled low for 35 us at the start of its
; 104 us bit, a logical 1 is no pulse. A character is a start bit (a 0), 8
; data bits least significant first, an even parity bit and a stop bit
; (a 1), and the next character of a telegram starts two bit times after
; that stop bit: thirteen bit times from start to start. A telegram is its
; control field, source address, destination address, the field with the
; address type, hop count and length, the TPCI and APCI and data, and a
; checksum: the exclusive or of all its bytes, inverted.
;
; The host sends the bytes. The firmware makes every character, the
; parity bits, the timing and the checksum. The checksum is the CRC
; register with the polynomial 0x80: every bit OUT shifts goes in at the
; top of eight bits that turn right once a bit, so after each byte the
; register is its old value exclusive or the byte; read inverted, its low
; byte is the checksum. The parity is Y: it starts at 0 and counts down
; once for every 1 sent, so its bit 0 is the parity of the 1s so far.
;
; After the checksum's stop bit the bus is left alone and the firmware
; waits for an acknowledgement (KNX's receivers send one character 15 bit
; times after a telegram): it waits [timeout] ticks for a start bit and
; reads ten bits, each 17 us into its bit time, where a 0's pulse is.
; Then the bus is quiet for 54 bit times or more before the next
; telegram. It sends without listening first, so it does not give way to
; another sender (KNX's arbitration), and it does not repeat a telegram
; that is not acknowledged: the host decides.
;
; The real bus is 30 V DC, and a 0 is a drop of a few volts with the
; overshoot that follows it: a transceiver (a TP-UART, an NCN5120, or
; discrete parts) drives and reads it. Here the pin stands for the bus as
; a wired AND: open-drain, low for a pulse, and read back for the
; acknowledgement, which another device pulls low.
;
; Pins: P0 = the bus, open-drain, with a pull-up. Config:
; [knx_tx_config]: out_base 0, out_count 1; set_base 0, set_count 1;
; in_base 0; threshold 8; crc_poly 0x80, crc_init 0, crc_invert;
; timeout_vector [knx_noack], timeout = the ticks to wait for an
; acknowledgement (one is due 1727 ticks after the wait starts, so 2000
; leaves two and a half bit times to spare); a tick is 1 us:
; CLKDIV 10 at 10 MHz, 50 at 50 MHz, 1 at 1 MHz. A bit is 104 ticks, so
; the bit rate is 9615 bit/s, 0.16% fast; the pulse is 35 ticks.
;
; Host protocol, per telegram:
;   TX : its bytes without the checksum, one a word; the last with bit 8
;        set ([knx_words]). The next byte is taken in the stop bit of the
;        character before, so a host that is late stretches the gap,
;        which a receiver takes as the end of the telegram.
;   RX : one word once the acknowledgement has been read: its ten bits,
;        the byte in bits 7:0, its parity bit in bit 8 and its stop bit
;        in bit 9 (0x2CC for an ACK); or 0 if no start bit came.
next:   mov crc, null           ; the checksum, the bytes' exclusive or, from 0
        pull                    ; a telegram's first byte
char:   set y, 0                ; -1: Y counts this character's 1s down
        set pins, 0             ; 0: the start bit, a 0: the bus pulled low
        nop [15]                ; 1..16
        nop [15]                ; 17..32
        nop [1]                 ; 33..34
        set pins, 1             ; 35: released
        set x, 3                ; 36
sr:     jmp x-- sr [15]         ; 37..100
        jmp bit [1]             ; 101..102
bit:    out x, 1                ; 103: a data bit, least significant first; the checksum takes it
        mov pins, x             ; 0: a 0 pulls the bus low, a 1 leaves it
        jmp !x zero             ; 1
        jmp y-- one             ; 2: a 1: Y's bit 0 becomes the parity so far
one:    nop [15]                ; 3..18
        nop [15]                ; 19..34
        set pins, 1             ; 35
        set x, 3                ; 36
br:     jmp x-- br [15]         ; 37..100
        nop                     ; 101
        jmp !osre bit           ; 102
        nop                     ; 103
        mov pins, y             ; 0: the parity bit, even
        nop [15]                ; 1..16
        nop [15]                ; 17..32
        nop [1]                 ; 33..34
        set pins, 1             ; 35: the stop bit and two bit times of rest follow
        mov x, osr              ; 36: the word's bits 15:8, now at the bottom
        jmp !x more             ; 37: 0: another byte
        jmp x-- last            ; 38
last:   jmp !x cks              ; 39: it was 1: the checksum next
        jmp ack                 ; 40: it was the checksum (0xFF): listen
more:   pull                    ; 38: the next byte
        set x, 22               ; 39
mw:     jmp x-- mw [15]         ; 40..407
        nop [5]                 ; 408..413
        jmp char                ; 414: the next start bit at 416, 13 bit times after this one's
cks:    mov osr, crc            ; 40: the checksum, the exclusive or inverted; the register stops
        set x, 22               ; 41
cw:     jmp x-- cw [15]         ; 42..409
        nop [3]                 ; 410..413
        jmp char                ; 414
zero:   jmp one                 ; 2: a 0, as long as a 1
ack:    wait 0 pin 0 timeout    ; the acknowledgement's start bit, or to [noack]
        set y, 9                ; ten bits
        set x, 6
aw:     jmp x-- aw [15]
        nop [3]
abit:   in pins, 1              ; 17 us into each bit: low for a 0
        set x, 5
ab:     jmp x-- ab [15]
        nop [4]
        jmp y-- abit            ; every 104 ticks
        push                    ; the byte, its parity bit and its stop bit
        jmp quiet
noack:  mov isr, null           ; no start bit in time: 0
        push
quiet:  set y, 10               ; 54 bit times and more of quiet bus
qo:     set x, 31
qi:     jmp x-- qi [15]
        jmp y-- qo
        jmp next
