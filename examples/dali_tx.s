; dali_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; DALI forward frame transmitter (lighting control): 1200 bit/s
; Manchester code on a bus that idles high. A frame is a start bit (a 1),
; 16 bits MSB first (address byte, command byte) and the bus idle
; again. A 1 is low for the first half of the bit and high for the second;
; a 0 the other way round.
;
; Pins: P0 = the bus level, push-pull (to a DALI driver; high = idle).
; Config: [dali_tx_config]: sideset_base 0, sideset_count 1; threshold 16;
; out_msb_first; CLKDIV sets the tick to 1/8 of a half bit: 521 for
; 52.1 us at 10 MHz.
;
; Host protocol: one TX word per frame, address in bits 15:8 and command
; in 7:0.
;
; Timing, in ticks: every half bit is exactly 8, whatever the bits either
; side of it, and each frame is followed by 256 of idle bus (13.3 ms: DALI
; asks for 9.2 ms between forward frames).
;
; The bit loop is written twice, once for a bus that is high and once for
; one that is low, because fetching the next bit takes two ticks and the
; bus must hold its level meanwhile.
        .side_set 1
frame:  pull            side 1        ; the bus idles high
        set y, 16       side 1        ; 16 bits after the start bit
        nop             side 0 [7]    ; start bit, a 1: the low half
hi:     jmp y-- get_h   side 1 [5]    ; high half of a 1 (2 more in get_h)
        jmp stop        side 1
get_h:  out x, 1        side 1
        jmp !x zero     side 1
        jmp hi          side 0 [7]    ; a 1: the low half
zero:   nop             side 1 [7]    ; a 0: the high half
lo:     jmp y-- get_l   side 0 [5]    ; low half of a 0 (2 more in get_l)
        jmp stop        side 0 [1]
get_l:  out x, 1        side 0
        jmp !x zero     side 0
        jmp hi          side 0 [7]    ; a 1: the low half
stop:   set x, 31       side 1
idle:   jmp x-- idle    side 1 [7]
        jmp frame       side 1
