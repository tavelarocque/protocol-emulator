; DSI transmitter on P0, thread 0, 10 MHz core clock.
; Config: in_msb_first=1, out_msb_first=1, threshold=16 (set_base 0, set_count 1).
; Every half-bit is exactly 8333 cycles: one set pins, then C+6 cycles.
; ISR holds C = 8327, X is the delay counter, Y the current bit (or the gap
; counter), OSR the word; !osre counts the 8 data bits.

        set pins, 0          ; drive P0 low at once (shows at cycle 1)
        set x, 8             ; build C = 8327 = 8<<10 | 4<<5 | 7 in the ISR
        in x, 5
        set x, 4
        in x, 5
        set x, 7
        in x, 5
        jmp gap

tail:   nop                  ; after D0: keeps half-bit 17 at 8333 cycles
gap:    set pins, 0          ; half-bit 17: stop bits begin (or idle)
        set y, 15            ; 16 half-bit delays of low
g:      mov x, isr
gl:     jmp x--, gl
        jmp y--, g
        pull                 ; next word; stalls here, line low, when none
        out null, 8          ; drop bits 15..8
        set pins, 1          ; rise: start bit, frame time zero
        nop
        mov x, isr
d0:     jmp x--, d0
bit:    out y, 1             ; next data bit, D7 first
        jmp !y, zero
        set pins, 1          ; first half of a 1: high
        nop
        nop
        nop
        mov x, isr
d1:     jmp x--, d1
        set pins, 0          ; second half of a 1: low
        mov x, isr
d2:     jmp x--, d2
        jmp !osre, bit
        jmp tail
zero:   set pins, 0          ; first half of a 0: low
        nop
        nop
        nop
        mov x, isr
d3:     jmp x--, d3
        set pins, 1          ; second half of a 0: high
        mov x, isr
d4:     jmp x--, d4
        jmp !osre, bit
        jmp tail
