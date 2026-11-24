; ST7735 4-line serial host, write only. Thread 0, 40 MHz, no clock divider.
; P0 SDA (out pin 0), P1 SCL (side-set), P2 D/CX, P3 CSX (out pins 2, 3).
; One TX word per byte, shifted out most significant bit first:
;   [15:12] CSX=0, D/CX, 0, bit7     -> written to P3..P0 before the 1st clock
;   [11:5]  bit6 .. bit0             -> SDA, one per clock
;   [4:1]   CSX after, D/CX, 0, bit0 -> written to P3..P0 after the 8th clock
;   [0]     unused
; Config: out_base=0 out_count=4 sideset_base=1 sideset_count=1
; out_msb_first=1; P0..P3 push-pull. An "out pins, 4" puts the first bit
; shifted on P3 and the last on P0; its P1 bit is overridden by side-set.
; An "out pins, 1" writes P0 only and leaves D/CX and CSX as they were
; (seen in pe_sim; isa.md does not say). 37 cycles per byte.
        .side_set 1
        nop             side 0 [1]   ; SCL low well before the first CSX edge
top:    pull            side 0       ; wait for a byte, SCL low
        out pins, 4     side 0 [1]   ; CSX low, D/CX, SDA = bit 7
        set x, 6        side 1 [1]   ; SCL high: bit 7 taken
bits:   out pins, 1     side 0 [1]   ; SCL low, SDA = next bit
        jmp x-- bits    side 1 [1]   ; SCL high: bit taken
        nop             side 0 [1]   ; SCL low, two cycles before CSX may move
        out pins, 4     side 0       ; CSX high if this was the last byte
        jmp top         side 0
