; OOK transmitter, Manchester, 2000 bit/s, on P0 (push-pull), thread 0.
; Config: clkdiv=25 (one tick = 25 cycles = 25 us), so half a bit = 10 ticks.
; out_msb_first=1, threshold=16, set_base=0, set_count=1.
; Registers: X = "last byte of frame" flag, Y = preamble/gap counter, then data bit.
; Host word: bits 15..9 = 0, bit 8 = last flag, bits 7..0 = byte.

endz:   set pins, 0             ; line low (start of run, and end of every frame)
        set y, 31
gapw:   jmp y--, gapw [6]       ; 32 x 7 = 224 ticks of silence
        pull                    ; first word of the next frame (stalls, line low, when none)
        out x, 8                ; X = flag (bits 15..8), byte now at the top of OSR
        set y, 15
pre:    set pins, 1 [9]         ; preamble bit "1": high half
        set pins, 0 [8]         ; low half
        jmp y--, pre            ; 16 bits; falls through at the start of bit 16 (T)
        nop [9]                 ; sync bit 16 = 0: low half (line already low)
        set pins, 1 [15]        ; T+10 rise (middle of bit 16)
        nop [3]
        set pins, 0 [15]        ; T+30 fall (middle of bit 17)
        nop [3]
        set pins, 1 [15]        ; T+50 rise (middle of bit 18)
        nop [3]
        set pins, 0 [6]         ; T+70 fall (middle of bit 19)
        jmp bitloop             ; T+77, out y at T+78, first data write at T+80
nextbyte: pull                  ; m+6
        out x, 8                ; m+7
bitloop: out y, 1               ; t-2
        jmp !y, zero            ; t-1
        set pins, 1 [9]         ; t: a 1 starts high
        set pins, 0 [2]         ; m = t+10: middle, low
        jmp common              ; m+3
zero:   set pins, 0 [9]         ; t: a 0 starts low
        set pins, 1 [3]         ; m = t+10: middle, high
common: jmp !osre, cont         ; m+4
        jmp !x, nextbyte        ; m+5: byte done; more bytes in this frame?
        jmp endz [3]            ; m+6: frame done; set pins 0 at m+10 = end of last bit
cont:   jmp bitloop [2]         ; m+5..m+7, out y at m+8
