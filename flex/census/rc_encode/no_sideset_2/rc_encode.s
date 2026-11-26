; PT2262 / HX2262 / SC5262 remote control encoder on P0, thread 0.
; Config: clkdiv=100 (one tick = 100 cycles = alpha/4), threshold=12,
; set_base=0, set_count=1, out_base=0, out_count=1, no autopull.
; Times below are in ticks; one unit of 4 alpha = 1600 cycles = 16 ticks.
; Trit: two pulse cycles of 64 ticks: H at 0, data level at 16 (b), L at 48.
;   pulse 1 data = b0 ; pulse 2 data = b0 | b1 (value 3 never occurs).
; Y counts the 12 trits of a frame. X holds the pulse's data bit.

init:   set pins, 0             ; tick 0: drive P0 low at once
        set x, 15               ; tick 1
iw:     jmp x--, iw     [15]    ; ticks 2..257 (16 x 16)
        jmp sfall               ; tick 258; first rise at tick 755

; chk: 3 ticks before every rise. Pull a word when the OSR is empty
; (12 bits = 6 trits used). At the end of a run the pull stalls, line low.
chk:    jmp !osre, skip         ; rise - 3
        pull            [1]     ; rise - 2, rise - 1
rise:   set pins, 1             ; t0    rise
        out x, 1        [14]    ; t1    X = b0
        mov pins, x     [15]    ; t16   fall here if short
        nop             [15]    ; t32
        set pins, 0             ; t48   fall here if long
        jmp !x, za              ; t49
        out null, 1             ; t50   value 1: drop b1, X stays 1
        jmp p2          [12]    ; t51..t63
za:     out x, 1        [13]    ; t50..t63  value 0 or f: X = b1
p2:     set pins, 1     [15]    ; t64   rise
        mov pins, x     [15]    ; t80   fall here if short
        nop             [15]    ; t96
        set pins, 0             ; t112  fall here if long
        jmp y--, chk    [11]    ; t113..t124, next trit's chk at t125

; sync bit, entered at S = -3 (S = 0 is its rise)
        nop             [2]     ; S -3..-1
        set pins, 1     [15]    ; S 0   rise
sfall:  set pins, 0             ; S 16  fall
        set x, 29               ; S 17
swait:  jmp x--, swait  [15]    ; S 18..497 (30 x 16)
        set y, 11               ; S 498
        jmp chk         [9]     ; S 499..508, chk at S 509, rise at S 512

skip:   jmp rise        [1]     ; rise - 2, rise - 1
