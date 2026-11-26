; DSI transmitter on P0, thread 0, 10 MHz core clock, clkdiv 1.
; Config (run_args.txt): out_msb_first=1, in_msb_first=1, threshold=16,
; set_base=0, set_count=1, P0 push-pull.
;
; One half-bit H = 8333 cycles = N + 6 with N = 8327 held in the ISR.
; Every pair of consecutive "set pins" in a frame is exactly H apart.
; Drift over a frame is at most 17 x 1/3 = 5.7 cycles.

        set pins, 0             ; drive the line low at once
        set x, 8                ; build N = 8327 = 01000 00100 00111 (5-bit groups)
        in x, 5
        set x, 4
        in x, 5
        set x, 7
        in x, 5                 ; ISR = 8327 from here on, never touched again

gap:                            ; line low: 12 x (N + 3) cycles, about 10 ms
        set y, 11
gl:     mov x, isr
gw:     jmp x-- gw
        jmp y-- gl
        pull                    ; next level; stalls here, line low, when none
        out null, 8             ; drop the zero top byte (MSB first)
        set pins, 1 [1]         ; frame rise, half-bit 0 (start bit)
        mov x, isr
s0:     jmp x-- s0
bit:
        out y, 1                ; next data bit, D7 first
        jmp !y zero
        set pins, 1             ; 1: first half high
        mov x, isr [3]
o1:     jmp x-- o1
        set pins, 0             ; second half low
        mov x, isr
o2:     jmp x-- o2
        jmp !osre bit
        jmp gap                 ; D0 was 1: line already low, stop bits run
zero:
        set pins, 0             ; 0: first half low
        mov x, isr [3]
z1:     jmp x-- z1
        set pins, 1             ; second half high
        mov x, isr
z2:     jmp x-- z2
        jmp !osre bit
        nop [1]
        set pins, 0             ; D0 was 0: fall at half-bit 17
        jmp gap
