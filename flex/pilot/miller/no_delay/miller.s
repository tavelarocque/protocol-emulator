; Miller (delay) code transmitter, thread 0, pin P0 push-pull.
; Config: clkdiv=5 (one tick = 5 cycles = 500 ns; a bit = 20 ticks, half a
; bit = 10 ticks), threshold=8, out_base=0, out_count=1.
;
; Y bit 0 is the level of P0.  A transition is always the pair
;       jmp y-- next / next: mov pins, y
; (decrementing Y flips its bit 0; the jump goes to the next instruction
; so it does not matter whether it is taken).
; X is the bit just fetched, then the delay counter.
; The previous bit is kept in the PC: block Z = inside a 0 bit, block O =
; inside a 1 bit.  Tick numbers in comments count from the middle of the
; current bit (tick 0); the next bit starts at tick 10, its middle is 20.
; Words: bits 7..0 data (sent LSB first), bit 8 = last byte of the message.
; After 8 shifts the OSR counts as empty and bit 8 is the next bit out.

        set y, 1            ; P0 resets high
msg:    pull                ; wait for the first byte of a message
        jmp y-- st
st:     mov pins, y         ; start bit: transition at its start (tick -10)
        set x, 7            ; -9
        jmp z_w             ; -8, loop -7..0, fetch at tick 1

; ---- block O: in a 1 bit ----
o_more: pull                ; 4   next byte
o_get:  out x, 1            ; 5   next bit
        jmp !x o_zero       ; 6
        set x, 10           ; 7   1 after 1
o_w:    jmp x-- o_w         ; 8..18
one:    jmp y-- o_t         ; 19
o_t:    mov pins, y         ; 20 = 0: transition in the middle of a 1 bit
        jmp !osre o_pad     ; 1
        out x, 1            ; 2   byte done: X = last-byte flag
        jmp !x o_more       ; 3
        jmp gap             ; 4   end bit after a 1: no transition
o_pad:  nop                 ; 2
        nop                 ; 3
        jmp o_get           ; 4
o_zero: set x, 11           ; 7   0 after 1: no transition at all
        jmp z_w             ; 8, loop 9..20, fetch at 21 = 1

; ---- block Z: in a 0 bit ----
z_zero: nop                 ; 7   0 after 0
        nop                 ; 8
        jmp y-- z_t         ; 9
z_t:    mov pins, y         ; 10  transition at the start of the bit
        set x, 8            ; 11
z_w:    jmp x-- z_w         ; 12..20
        jmp !osre z_pad     ; 21 = 1
        out x, 1            ; 2   byte done: X = last-byte flag
        jmp !x z_more       ; 3
        jmp endz            ; 4
z_pad:  nop                 ; 2
        nop                 ; 3
        jmp z_get           ; 4
z_more: pull                ; 4   next byte
z_get:  out x, 1            ; 5   next bit
        jmp !x z_zero       ; 6
        set x, 9            ; 7   1 after 0
        jmp o_w             ; 8, loop 9..18, transition at 20

; ---- end of message ----
endz:   set x, 2            ; 5   end bit after a 0
e_w:    jmp x-- e_w         ; 6..8
        jmp y-- e_t         ; 9
e_t:    mov pins, y         ; 10  transition at the start of the end bit
gap:    set x, 31           ; silence: entered at tick 5 (after a 1) or 11
g_w:    nop                 ; (after a 0); 1 + 128 + 1 ticks here, then pull
        nop                 ; and the start pair.  The end bit ends at tick
        nop                 ; 30, the next start comes at tick 137 or 143:
        jmp x-- g_w         ; 535 or 565 cycles of silence (400 needed)
        jmp msg
