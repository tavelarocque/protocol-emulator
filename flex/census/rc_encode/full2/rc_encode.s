; PT2262 / HX2262 / SC5262 encoder, thread 0, P0 push-pull.
; Config: clkdiv=400 (one tick = 400 cycles = 1 alpha), threshold=12,
; autopull=1. Every count below is in ticks (alpha).
;
; Each pulse cycle is 16 ticks: 4 high, 8 "middle", 4 low. The middle is
; high for a long pulse cycle and low for a short one. For a trit with
; bit0 (b0) and bit1 (b1): first middle = b0, second middle = b0 | b1.
; ('0' = 00, '1' = b0 set, 'f' = b1 set.)

start:  set pins, 0     [15]    ; tick 0: drive P0 low at once
        set y, 11       [15]    ; 12 trits per code word
        jmp wait                ; first rise lands at about tick 140

next:   out x, 1        [1]     ; trit tick 30: X = b0 (stalls here, line low, when words run out)
trit:   set pins, 1     [3]     ; tick 0: rise
        mov pins, x     [7]     ; tick 4: first middle = b0
        set pins, 0     [3]     ; tick 12: fall
        set pins, 1     [2]     ; tick 16: rise
        jmp !x zero             ; tick 19
        out null, 1     [6]     ; tick 20: b0 = 1, so stay high; drop b1
        jmp low                 ; tick 27
zero:   out pins, 1     [7]     ; tick 20: second middle = b1
low:    set pins, 0             ; tick 28: fall
        jmp y-- next            ; tick 29
        set y, 11       [1]     ; tick 30 of trit 11
        set pins, 1     [3]     ; tick 32: sync rise
        set pins, 0     [15]    ; tick 36: sync fall
wait:   set x, 5        [8]     ; tick 52
loop:   jmp x-- loop    [15]    ; ticks 61..156, six passes
        jmp next                ; tick 157; next rise at tick 160 = 32 + 128
