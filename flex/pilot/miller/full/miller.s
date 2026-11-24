; Miller (delay) encoder, 100 kbit/s on P0, core clock 10 MHz.
; Config: clkdiv 5 (one tick = 5 cycles, one bit = 20 ticks, half bit = 10),
;         threshold 8, out_base 0, out_count 1, P0 push-pull.
; Y bit 0 is the line level: "jmp y-- next / mov pins, y" is a toggle.
; S = tick of the current bit's start. The previous bit is held in the PC:
; hk0/f0 run after a 0, hk1/f1 after a 1.
        set y, 0            ; dummy toggle below then writes 1: no change
e0t:    jmp y-- e0          ; S+19  (end bit after a 0: transition at its start)
e0:     mov pins, y         ; S+20
gap:    set x, 6
g:      jmp x-- g [15]      ; 7 * 16 = 112 ticks
idle:   pull                ; wait for the first word of a message
zt:     jmp y-- z1          ; S-1
z1:     mov pins, y         ; S     transition at the start of a 0 (or start bit)
hk0:    jmp !osre d0        ; S+1
        out x, 1            ; S+2   byte done: bit 8 = last byte?
        jmp !x m0           ; S+3
        jmp e0t [14]        ; S+4   last: end bit after a 0
m0:     pull [12]           ; S+4   next byte
f0:     out x, 1            ; S+17  next bit, previous was 0
        jmp !x zt           ; S+18  0 after 0: toggle at S+20
one:    nop [9]             ; S-1   a 1: toggle at S+10
        jmp y-- o1          ; S+9
o1:     mov pins, y         ; S+10
hk1:    jmp !osre d1        ; S+11
        out x, 1            ; S+12
        jmp !x m1           ; S+13
        jmp gap             ; S+14  last: end bit after a 1 has no transition
m1:     pull [2]            ; S+14
f1:     out x, 1            ; S+17  next bit, previous was 1
        jmp x-- one         ; S+18
zn:     jmp hk0 [1]         ; S-1   0 after 1: no transition
d0:     jmp f0 [14]         ; S+2
d1:     jmp f1 [4]          ; S+12
