; can_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; CAN: the transmitter, on thread 1. Pins, the TX words and the result
; word are described at [can_rx] (examples/can_rx.s). Config:
; [Can.tx_config].
next:   pull                    ; N - 1
        set x, 0                ; X = 0 marks "waiting for the bus"
quiet:  set y, 10               ; the bus recessive for 11 bit times
q:      wait 1 pin 0 timeout [8]
        jmp y-- q
        wait 1 pin 0 timeout    ; a last look, then at once
        mov pins, x [2]         ; the start-of-frame bit (X is 0)
        out y, 16               ; N - 1, kept in the OSR until now
loop:   jmp !osre pad
        pull
bit:    jmp !x skip             ; the last bit sent: dominant, nothing to check
        wait 1 pin 0 timeout    ; recessive: the bus must be recessive too
send:   out x, 1 [1]
        mov pins, x [2]         ; drive TXD
        jmp y-- loop
        in y, 16                ; all sent, never stopped: 0xFFFF
        jmp fin
pad:    jmp bit
skip:   jmp send
lost:   jmp !x quiet            ; timeout vector. Waiting for the bus: count again
        in y, 16                ; mid-frame: stop sending. Y says where
d:      jmp !osre d2            ; take the rest of the frame's words, unsent
        pull
d2:     out null, 1
        jmp y-- d
fin:    push
        jmp next
