; Miller (delay) code transmitter, thread 0, pin P0 push-pull.
;
; Config: out_base=0 out_count=1 threshold=8 clkdiv=5
;   clkdiv=5 makes one tick 5 cycles, so a bit is 20 ticks and half a bit 10.
;   Every transition is made by "mov pins, y" on a tick, so all transitions
;   sit on the same 5-cycle grid and no error can build up.
;
; Host word: bits 7..0 = one data byte, bit 8 = 1 on the last byte of a
; message. The chip adds the start bit, the end bit and the gap.
;
; Registers:
;   Y  toggle counter. "jmp y-- next / mov pins, y" flips P0, because every
;      decrement flips Y's bit 0 and out_count=1 writes only that bit.
;   X  the bit just shifted out of the OSR (data bit or last-byte flag),
;      and the gap counter.
;   The previous bit is not stored: it is the place in the program
;   (b0 = previous bit was 0, b1 = previous bit was 1).
;
; Tick numbers in the comments: B is the tick of the "mov pins" slot at the
; start of the current bit, so its middle is B+10 and the next bit is B+20.
; Every data bit is fetched by "out x, 1" at B-3.

        set y, 1                ; P0 resets high, so the first toggle must write 0
gap:    set x, 9
g:      jmp x-- g [15]          ; 160 ticks of silence (also once at reset)
msg:    pull                    ; wait here for the first byte of a message
        jmp y-- st
st:     mov pins, y [1]         ; S      start bit: always a transition
b0d:    nop [14]                ; ..B-4
b0:     out x, 1                ; B-3    previous bit was 0
        jmp x-- one             ; B-2    a 1
z0:     jmp y-- z0a             ; B-1    a 0 after a 0: transition at bit start
z0a:    mov pins, y             ; B
zt:     jmp !osre b0d           ; B+1    more bits in this byte
        out x, 1                ; B+2    last-byte flag
        jmp x-- end0            ; B+3
        pull                    ; B+4    next byte
        jmp b0 [11]             ; B+5..B+16
end0:   nop [14]                ; B+4..B+18   end bit after a 0:
        jmp y-- e0a             ; B+19
e0a:    mov pins, y             ; B+20        a transition at its start
        jmp gap
b1d:    nop [4]                 ; B+12..B+16
b1:     out x, 1                ; B-3    previous bit was 1
        jmp !x z1               ; B-2    a 0 after a 1: no transition
one:    nop [9]                 ; B-1..B+8
        jmp y-- o1              ; B+9
o1:     mov pins, y             ; B+10   a 1: transition in the middle
        jmp !osre b1d           ; B+11   more bits in this byte
        out x, 1                ; B+12   last-byte flag
        jmp x-- gap             ; B+13   end bit after a 1: no transition
        pull                    ; B+14   next byte
        jmp b1 [1]              ; B+15,B+16
z1:     jmp zt [1]              ; B-1,B
