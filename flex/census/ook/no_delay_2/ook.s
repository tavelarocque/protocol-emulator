; OOK Manchester transmitter, thread 0, P0 push-pull.
; Config: clkdiv=10 (1 tick = 10 cycles, half bit = 25 ticks, bit = 50 ticks),
;         out_msb_first=1, threshold=16, set_base=0, set_count=1.
; Tick numbers in comments are relative to the start of the current bit.
; Every frame bit (preamble, sync, data) goes through the same routine at
; "next"; only the boundary path (OSR empty) differs per state in Y:
;   Y=3 preamble just sent, Y=2 sync just sent, Y=1 last byte sent,
;   Y=0 byte sent and more bytes follow.
; The first word of each frame is pulled before the gap and kept in ISR.

        set pins, 0          ; drive P0 low at once (shows at cycle 1)
frame:  pull                 ; blocks here, line low, when no more frames
        mov isr, osr         ; keep the frame's first word
        set y, 31            ; gap: 32 * 34 ticks = 10880 cycles
g1:     set x, 31
g2:     jmp x-- g2
        jmp y-- g1
        set y, 3             ; state: sending preamble
        set x, 0
        jmp x-- ff           ; X = 0 so falls through, X becomes 0xFFFF
ff:     mov osr, x           ; preamble: 16 ones, count 0
        jmp next             ; next runs at tick -2 of bit 0

zero:   set pins, 0          ; 0   a 0 starts low
        set x, 22            ; 1
z1:     jmp x-- z1           ; 2..24
        set pins, 1          ; 25  rise in the middle
        jmp tail             ; 26

tail:   jmp !osre more       ; 27  more bits in this OSR load
        jmp !y pullnext      ; 28  byte done, not last: next byte
        set x, 1             ; 29
        jmp x!=y notlast     ; 30
        set x, 17            ; 31  Y=1: frame over
e1:     jmp x-- e1           ; 32..49
        set pins, 0          ; 50  end of last bit: line low
        jmp frame

notlast: jmp y-- dec         ; 31  Y: 3->2 or 2->1
dec:    jmp x!=y presdone    ; 32  Y=2: preamble done
        mov osr, isr         ; 33  Y=1: sync done, restore first word
        out null, 7          ; 34
        out y, 1             ; 35  Y = last-byte flag
        set x, 9             ; 36
        jmp m1               ; 37
presdone: set x, 5           ; 33  sync nibble 0101
        mov osr, x           ; 34
        out null, 12         ; 35  leaves 0101 at the top, count 12
        set x, 9             ; 36
        jmp m1               ; 37
pullnext: pull               ; 29
        out null, 7          ; 30
        out y, 1             ; 31  Y = last-byte flag
        set x, 13            ; 32
        jmp m1               ; 33
more:   set x, 18            ; 28
m1:     jmp x-- m1           ; ..47
next:   out x, 1             ; 48 = -2 of the next bit
        jmp !x zero          ; -1
        set pins, 1          ; 0   a 1 starts high
        set x, 22            ; 1
o1:     jmp x-- o1           ; 2..24
        set pins, 0          ; 25  fall in the middle
        jmp tail             ; 26
