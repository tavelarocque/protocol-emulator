; DSI transmitter on P0, thread 0, 10 MHz core clock, clkdiv 1.
; Config (run_args.txt): out_base 0, out_count 1, set_base 0, set_count 1,
; threshold 16, out_msb_first 1, in_msb_first 1. P0 push-pull.
;
; Every half-bit is H = 8333 cycles between pin writes (ideal 8333.33;
; the drift reaches 5.7 cycles at half-bit 17, far inside +-80).
; Y holds D = H - 7 = 8326, the count for every delay loop.
; A delay "mov x, y" plus "l: jmp x-- l" takes D + 2 cycles; each path
; between two pin writes has 5 more cycles of work or nop padding.

        set pins, 0          ; drive P0 low at once (shows at cycle 1)
        set x, 8             ; build Y = 8326 = 8<<10 | 4<<5 | 6
        in x, 4
        set x, 4
        in x, 5
        set x, 6
        in x, 5
        mov y, isr
        mov isr, null        ; ISR count back to 0, used as the gap counter

frame:  pull                 ; waits here (line low) when the words run out
        out null, 8          ; drop bits 15..8; 8 data bits left, D7 first
gap:    mov x, y             ; gap: 16 x (D + 4) cycles low
g1:     jmp x-- g1
        in null, 1
        jmp !isrf gap
        mov isr, null

        set pins, 1          ; rise: half-bit 0, start bit (time R)
        mov x, y
s1:     jmp x-- s1
        nop
        nop
bit:    out x, 1             ; next data bit, MSB first
        jmp !x zero
        set pins, 1          ; D = 1: first half high (R + 8333 for D7)
        mov x, y
h1:     jmp x-- h1
        nop
        nop
        nop
        nop
        set pins, 0          ; second half low
        jmp common
zero:   set pins, 0          ; D = 0: first half low
        mov x, y
h0:     jmp x-- h0
        nop
        nop
        nop
        nop
        set pins, 1          ; second half high
        nop                  ; matches "jmp common" on the other path
common: mov x, y
c1:     jmp x-- c1
        jmp !osre bit
        nop
        nop
        set pins, 0          ; half-bit 17: stop bits, line low
        jmp frame
