; rc5_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; RC-5 infrared receiver: the other end of [rc5_tx], on the output of an
; IR receiver module, which is low while it sees carrier. One thread with
; the bit sampler in front of it, used as it is for Ethernet at a
; five-thousandth of the speed.
;
; A frame's first edge is in the middle of its first bit (a 1: silence,
; then carrier), and every bit has an edge in its middle. The sampler
; locks to those, ignores the edges between bits, and takes each bit a
; quarter of a bit after its middle edge: carrier there is a 1. The
; prescaler makes a sample 1/20 of a bit, and this thread's CLKDIV is the
; same number, so each of the sampler's pulses is one tick long.
;
; Pins: P0 = the module's output (input); P1 is taken by the sampler's
; pulse. Config: [rc5_rx_config ~clkdiv], sampler: [rc5_rx_sampler
; ~clkdiv], with CLKDIV 889 for RC-5's 1.778 ms bit at 10 MHz.
;
; Host protocol: one RX word for each frame, its 14 bits in bits 13:0,
; the first received highest: two start bits, the toggle bit, 5 address
; bits and 6 command bits ([rc5_word] shifted down by two). A
; transmission of fewer than 14 bits is dropped.
;
; Timing: a middle edge is accepted from 3/4 of a bit to 1.4 bits after
; the last, so a remote 20% fast or slow is read.
rx:     mov isr, null           ; (a frame cut short comes back here)
        set y, 13               ; 14 bits
        wait 1 pin 1            ; a frame's first bit
bit:    in pins, 1
        jmp y-- next
        push                    ; the frame
        jmp rx
next:   wait 1 pin 1 timeout    ; the next bit, or the frame was cut short
        jmp bit
