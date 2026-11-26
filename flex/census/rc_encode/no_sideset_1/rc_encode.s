; PT2262 / HX2262 / SC5262 encoder on P0, thread 0.
; Config: clkdiv=400 (one tick = one alpha = 40 us), autopull, threshold=12.
; Every edge is made by one instruction whose tick is fixed by the listing,
; so all times below are in ticks (alpha), relative to the frame's first
; rise (f) or the trit's first rise (t).
; A trit is 2 bits in X: 0 = '0', 1 = '1', 2 = 'f'.
;   pulse 1 middle level (t4..t11)  = bit 0 of X  (long only for '1')
;   pulse 2 middle level (t20..t27) = (X != 0)    (long for '1' and 'f')
; Y counts the trits of a frame (11 down to 0).

start:  set pins, 0             ; tick 0: drive P0 low at once
        set y, 11               ; trits in the first frame
        set x, 10              ; startup wait: 11 x 15 ticks
        jmp low

trit:   out x, 2                ; t-1: next trit (stalls here, line low, when no words are left)
        set pins, 1 [3]         ; t0: rise
        mov pins, x [7]         ; t4: middle of pulse 1 = bit 0 of X
        set pins, 0 [3]         ; t12: fall
        set pins, 1 [2]         ; t16: rise
        jmp !x short            ; t19
        jmp join [7]            ; t20..t27: long, line stays high
short:  set pins, 0 [7]         ; t20..t27: short, line low
join:   set pins, 0 [1]         ; t28: fall
        jmp y-- trit            ; t30: next trit's out at t31, rise at t32
        set y, 11               ; f383
        set pins, 1 [3]         ; f384: sync rise
        set pins, 0             ; f388: sync fall
        set x, 7                ; f389
low:    jmp x-- low [14]        ; f390..f509: 8 x 15 ticks
        jmp trit                ; f510: out at f511, next frame's rise at f512
