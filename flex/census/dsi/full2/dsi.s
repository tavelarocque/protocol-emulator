; DSI transmitter, thread 0, P0 push-pull, 10 MHz core, clkdiv 1.
; Config (run_args.txt): threshold=16, out_msb_first=1, in_msb_first=1,
; set_base=0, set_count=1.
;
; Every half-bit is exactly 8333 cycles from one `set pins` to the next.
; The ISR holds K = 8327, the delay-loop count; a delay block
; "mov x, isr / l: jmp x-- l" takes K + 2 cycles.
; Half-bit intervals (set to next set), all = K + 6 = 8333:
;   start bit : set [1] + mov + loop(K+1) + out + jmp        = 2+1+K+1+2
;   first half: set [3] + mov + loop(K+1)                    = 4+1+K+1
;   second half: set + mov + loop(K+1) + jmp !osre + out + jmp, or
;                set + mov + loop(K+1) + jmp !osre + jmp main [1]

        set pins, 0             ; drive the line low at once
        set x, 8                ; build K = 8*1024 + 4*32 + 7 = 8327 in ISR
        in x, 5
        set x, 4
        in x, 5
        set x, 7
        in x, 5
main:   set pins, 0             ; idle low; also start of stop bits (half-bit 17)
        set y, 15               ; 16 half-bit delays: stop bits + gap
gap:    mov x, isr
gapi:   jmp x-- gapi
        jmp y-- gap
        pull                    ; next level (stalls, line low, when none left)
        out null, 8             ; drop bits 15..8
        set pins, 1 [1]         ; start bit: frame rise, half-bit 0
        mov x, isr
sd:     jmp x-- sd
bit:    out x, 1                ; next data bit, MSB first
        jmp !x zero
one:    set pins, 1 [3]         ; 1: high then low
        mov x, isr
o1:     jmp x-- o1
        set pins, 0
        mov x, isr
o2:     jmp x-- o2
        jmp !osre bit
        jmp main [1]
zero:   set pins, 0 [3]         ; 0: low then high
        mov x, isr
z1:     jmp x-- z1
        set pins, 1
        mov x, isr
z2:     jmp x-- z2
        jmp !osre bit
        jmp main [1]
