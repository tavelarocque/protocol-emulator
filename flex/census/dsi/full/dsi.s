; DSI transmitter on P0 (push-pull), thread 0, 10 MHz core clock.
; Config: clkdiv=641, out_msb_first=1, threshold=16, set_base=0, set_count=1.
; One tick = 641 cycles. One half-bit = 13 ticks = 8333 cycles
; (ideal 8333.33, so half-bit k is 0.33*k cycles early, at most 5.7 at k=17).
; Tick numbers in comments are relative to the frame's rise (tick 0).
; Host word: bits 7..0 = level, MSB first on the line.

stop:   set pins, 0  [15]   ; t221: stop bits (line low). Also the reset entry:
                            ;       drives P0 low in cycle 0.
        set x, 31           ; t237
gap:    jmp x--, gap [6]    ; t238..t461: 32 x 7 ticks
main:   pull                ; t462: next level (stalls forever when none left)
        out null, 8         ; t463: drop bits 15..8
        set y, 7            ; t464: 8 data bits
        set pins, 1  [10]   ; t0 (=t465 of previous frame): rise, start bit
bit:    out x, 1            ; t13+26i-2: next data bit, D7 first
        jmp !x, zero        ; t13+26i-1
one:    set pins, 1  [12]   ; t13+26i: first half high
        set pins, 0  [9]    ; t26+26i: second half low
        jmp y--, bit        ; t36+26i
        jmp stop     [1]    ; t219..220, stop at t221
zero:   set pins, 0  [12]   ; t13+26i: first half low
        set pins, 1  [9]    ; t26+26i: second half high
        jmp y--, bit        ; t36+26i
        jmp stop     [1]    ; t219..220, stop at t221
