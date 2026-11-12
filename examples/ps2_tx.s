; ps2_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; PS/2: the transmitter, on thread 1. Pins, the TX word, the result word
; and how it shares the bus with the receiver are described at [ps2_rx]
; (examples/ps2_rx.s). Config: [Ps2.tx_config].
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
