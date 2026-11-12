; i2c_controller: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; I2C controller, write transactions, with clock stretching.
;
; Pins: P0 = SDA, P1 = SCL, both open-drain.
; Config: out_base 0, out_count 1 (SDA); set_base 1, set_count 1 (SCL);
; in_base 0 (SDA); threshold 8; timeout_vector = [i2c_timeout_vector];
; TIMEOUT = the longest clock stretch to tolerate, in cycles.
;
; Host protocol on the TX FIFO:
;   word 0  : H, the half-period loop count (each SCL phase is about H + 4
;             cycles).
;   then one word per byte, first the address byte (address << 1, write):
;     bits 7:0  the byte, bit-reversed (OUT shifts LSB first; I2C is MSB
;               first)
;     bit 8     must be 1: releases SDA so the target can ACK
;     bit 9     1 = send STOP after this byte, ending the transaction
; RX FIFO, one word per byte: 0 = ACK, 1 = NACK.
; If a target holds SCL low longer than TIMEOUT, the firmware pushes 2,
; releases both lines and returns to idle.
;
; Every SDA change happens while SCL is low, except START and STOP.
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
