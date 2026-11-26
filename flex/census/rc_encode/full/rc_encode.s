; PT2262 remote control encoder on P0, thread 0.
; Config: clkdiv=400 so one tick = one alpha (40 us), threshold=12 and
; autopull so each 16-bit word gives 6 trits of 2 bits, LSB first.
; Tick numbers below are relative to the rise of the trit's first pulse.
; A set pins at tick k gives the edge at tick k.

start:
        set pins, 0             ; line low at once
        set y, 11               ; 12 trits per frame (y-- loop)
        set x, 22               ; initial wait, 23 x 8 ticks
wait0:  jmp x--, wait0 [7]
                                ; falls into trit (first out also fetches)
trit:   out x, 2                ; tick -2: trit value 0, 1 or 2 ('f')
        jmp x--, nz             ; tick -1: '0' falls through
; '0': short, short
        set pins, 1 [3]         ; 0..3   high
        set pins, 0 [11]        ; 4..15  low
        set pins, 1 [3]         ; 16..19 high
        set pins, 0 [8]         ; 20..28 low
        jmp y--, trit           ; 29
        jmp sync                ; 30
nz:     set pins, 1             ; 0      high ('1' or 'f')
        jmp !x, one             ; 1      x is now 0 for '1', 1 for 'f'
; 'f': short, long
        nop [1]                 ; 2..3
        set pins, 0 [11]        ; 4..15  low
p2long: set pins, 1 [11]        ; 16..27 high
        set pins, 0             ; 28     low
        jmp y--, trit           ; 29
        jmp sync                ; 30
; '1': long, long
one:    nop [9]                 ; 2..11  high
        set pins, 0 [2]         ; 12..14 low
        jmp p2long              ; 15
; sync bit: entered at frame tick 383, rise at 384, next frame rise at 512
sync:   set y, 11               ; 383
        set pins, 1 [3]         ; 384..387 high
        set pins, 0 [15]        ; 388..403 low
        set x, 12               ; 404
wait1:  jmp x--, wait1 [7]      ; 405..508 (13 x 8)
        jmp trit                ; 509, out x at 510 = next frame tick -2
