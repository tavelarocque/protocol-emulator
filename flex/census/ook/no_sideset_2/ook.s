; OOK transmitter, Manchester, 2000 bit/s, on P0 (push-pull), thread 0.
; Run with clkdiv=25: one tick = 25 cycles, half a bit = 10 ticks, a bit = 20.
; out_msb_first=1, threshold=16: each word is 7 zero bits, the last-byte
; flag (into Y), then the 8 data bits MSB first; the OSR is empty after them.
; In comments, s is the tick at which the current bit starts.

        set pins, 0             ; tick 0: drive the line low at once
fin:    set pins, 0             ; end of frame (falls here if last bit was 0)
        set x, 15
gap:    jmp x--, gap [15]       ; 16 x 16 = 256 ticks of silence
        pull                    ; first word of the next frame (waits if none)
        out null, 7
        out y, 1                ; Y = 1 on the last byte of the frame
        set x, 15               ; 16 preamble bits
pre:    set pins, 1 [9]         ; bit start: rise
        set pins, 0 [8]         ; middle: fall
        jmp x--, pre
; sync 0 1 0 1; the line is low, the first instruction here is at the start
; of bit 16 (call it b)
        nop [9]                 ; b .. b+9, first half of a 0
        set pins, 1 [15]        ; b+10, middle of bit 16: rise
        nop [3]
        set pins, 0 [15]        ; b+30, middle of bit 17: fall
        nop [3]
        set pins, 1 [15]        ; b+50, middle of bit 18: rise
        nop [3]
        set pins, 0 [6]         ; b+70, middle of bit 19: fall
        jmp bitout              ; b+77, bitout at b+78 = s-2 of data bit 0
getword: pull                   ; s+15
        out null, 7             ; s+16
        out y, 1                ; s+17
bitout: out x, 1                ; s+18: the next bit
        jmp x--, one            ; s+19
zero:   set pins, 0 [9]         ; s: a 0 starts low
        set pins, 1 [1]         ; s+10: rise in the middle
        jmp tail                ; s+12
one:    set pins, 1 [9]         ; s: a 1 starts high
        set pins, 0 [2]         ; s+10: fall in the middle
tail:   jmp !osre, more         ; s+13
        jmp !y, getword         ; s+14: byte done; another byte in this frame?
        jmp fin [4]             ; s+15..s+19, fin at s+20: end of the last bit
more:   jmp bitout [3]          ; s+14..s+17
