; DSI transmitter on P0, thread 0.
; Config: clkdiv=13, out_msb_first=1, threshold=16 (see run_args.txt).
; One tick = 13 cycles = 1.3 us. One half-bit = 641 ticks = 8333 cycles
; (ideal 8333.33), so the error at half-bit 17 is only -5.7 cycles.
; Registers: X = current data bit, Y = delay counter, X also outer gap counter.
; OSR count (threshold 16) counts the 8 data bits: !osre ends the bit loop.

stopw:  set pins 0              ; reset entry and stop bits: line low (17H)
        set x, 20               ; gap: 1 + 21 * 514 ticks
g1:     set y, 31
g2:     jmp y-- g2 [15]         ; 32 * 16 = 512 ticks
        jmp x-- g1
frame:  pull                    ; next word (stalls with the line low)
        out null, 8             ; drop bits 15..8
        set pins 1 [15]         ; R: start bit rise, frame time zero
        set y, 18 [15]
d0:     nop [15]
        jmp y-- d0 [15]         ; 19 * 32 = 608 ticks
bitloop:
        out x, 1                ; X = next data bit, D7 first
        mov pins, x [15]        ; W1: first half = bit
        set y, 18 [15]
d1:     nop [15]
        jmp y-- d1 [15]         ; 608 ticks
        jmp !x zero
        set pins 0              ; W2 for a 1: second half low
        jmp cont
zero:   set pins 1 [1]          ; W2 for a 0: second half high
cont:   set y, 18 [15]
d2:     nop [15]
        jmp y-- d2 [15]         ; 608 ticks
        jmp !osre bitloop [13]
        jmp stopw
