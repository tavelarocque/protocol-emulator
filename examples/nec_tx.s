; nec_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; NEC infrared transmitter (the commonest remote-control code), carrier
; included: the pin drives an IR LED directly. A frame is a 9 ms burst of
; carrier, 4.5 ms of silence, then 32 bits, each a 562.5 us burst followed
; by 562.5 us of silence for a 0 or 1687.5 us for a 1, and a final burst.
;
; Pins: P0 = the LED, push-pull, high = lit. Config: [nec_tx_config]:
; sideset_base 0, sideset_count 1; threshold 16; CLKDIV sets the tick to
; half a carrier period: 132 for 37.9 kHz at 10 MHz.
;
; Host protocol, one frame at a time:
;   TX word 0 : carrier periods in the leading burst, less one: 341
;   TX word 1 : address in bits 7:0, its complement in 15:8 (or the high
;               address byte, in the extended form)
;   TX word 2 : command in bits 7:0, its complement in 15:8
; ([nec_words]). Bits go out LSB first, as NEC has them.
;
; Timing, in ticks of 13.2 us: a burst is 21 carrier periods (554 us), a
; 0 is 85 ticks from burst to burst (1.122 ms; NEC: 1.125) and a 1 is 170
; (2.244 ms; 2.25). The carrier is high one tick and low one.
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
