; OOK / Manchester transmitter on P0, thread 0.
; Config: clkdiv=10 (one tick = 10 cycles), threshold=16, out_msb_first=1.
; Half bit = 25 ticks, bit = 50 ticks. Delay idiom: "set r,k" then
; "l: jmp r-- l" takes k+2 ticks in total.
; Tick numbers in comments: t = tick within the current bit (0..49),
; s = tick counted from the start of sync bit 16.

start:  set pins, 0          ; drive P0 low (run start / end of frame, t50)
frame:  pull                 ; next frame's first word; stalls forever when done
        set x, 31            ; gap: 32 x 34 ticks = 1088 ticks
outer:  set y, 31
inner:  jmp y--, inner
        jmp x--, outer
        set y, 15            ; 16 preamble bits
; ---- preamble: 16 ones ----
pbit:   set pins, 1          ; t0  rise
        set x, 22            ; t1
pd1:    jmp x--, pd1         ; t2..t24
        set pins, 0          ; t25 fall
        set x, 21            ; t26
pd2:    jmp x--, pd2         ; t27..t48
        jmp y--, pbit        ; t49
; ---- sync 0 1 0 1: rise s25, fall s75, rise s125, fall s175 ----
        set x, 23            ; s0
sd0:    jmp x--, sd0         ; s1..s24
        set pins, 1          ; s25
        set x, 23            ; s26, then 2*(23+1) = 48 ticks
sd1:    nop
        jmp x--, sd1         ; through s74
        set pins, 0          ; s75
        set x, 23
sd2:    nop
        jmp x--, sd2         ; through s124
        set pins, 1          ; s125
        set x, 23
sd3:    nop
        jmp x--, sd3         ; through s174
        set pins, 0          ; s175
        set y, 2             ; s176
sd4:    jmp y--, sd4         ; s177..s179
        jmp nextb            ; s180 -> nextb at s181 (= t31), bit at s200
; ---- data bits ----
bit:    mov pins, x          ; t0  first half = the bit
        set y, 21            ; t1
bd1:    jmp y--, bd1         ; t2..t23
        jmp !x, zero         ; t24
        set pins, 0          ; t25 bit 1: second half low
        jmp mid              ; t26
zero:   set pins, 1          ; t25 bit 0: second half high
        nop                  ; t26
mid:    jmp !osre, more      ; t27 more bits in this byte?
        mov y, isr           ; t28 last-byte flag
        jmp !y, next         ; t29
        set y, 17            ; t30 last byte: end the frame
ld:     jmp y--, ld          ; t31..t48
        jmp start            ; t49 -> set pins 0 at t50
next:   pull                 ; t30
nextb:  out null, 7          ; t31
        out y, 1             ; t32 flag
        mov isr, y           ; t33 keep flag in ISR
        out x, 1             ; t34 first data bit (MSB)
        set y, 12            ; t35
nd:     jmp y--, nd          ; t36..t48
        jmp bit              ; t49
more:   out x, 1             ; t28 next bit
        set y, 18            ; t29
md:     jmp y--, md          ; t30..t48
        jmp bit              ; t49
