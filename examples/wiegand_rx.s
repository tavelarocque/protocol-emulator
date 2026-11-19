; wiegand_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Wiegand receiver: the reader's side of [wiegand_tx], taking the bits a
; card reader or keypad sends on D0 and D1.
;
; Pins: P0 = D0, P1 = D1, inputs, with the pull-ups the bus has. They must
; be pins 0 and 1: the program looks at both lines at once by copying all
; eight pins and taking the first two. Config: [wiegand_rx_config]:
; in_base 0, threshold 16, in_msb_first.
;
; Host protocol, one frame at a time:
;   TX word : N - 1, for a frame of N bits; the thread then waits for it
;   RX      : ceil(N / 16) words, 16 bits each and whatever is left in the
;             last, the first bit received in the top bit of each
;
; The lines are looked at every 5 cycles, so a pulse of a microsecond is
; seen at 10 MHz (readers send 20 us and more). The bit is D0's level
; during the pulse: low in a 0's pulse, high in a 1's. A frame that stops
; short leaves its bits waiting for the rest; the host notices by the
; time it takes, and stops and starts the thread to clear them.
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
