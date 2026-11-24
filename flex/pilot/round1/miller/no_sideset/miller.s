; Miller (delay code) transmitter, thread 0, pin P0 push-pull.
;
; The host does the line coding. Each TX word is 16 line levels, least
; significant bit first, one level per half bit (50 cycles). The thread only
; clocks them out: with clkdiv = 25 the two instructions below take 2 ticks =
; 50 cycles, and autopull refills the OSR in the same tick as the out that
; empties it, so there is never a gap between words.
;
; When the TX FIFO runs dry the out stalls and P0 keeps its last level.
;
; Config: out_base=0, out_count=1, threshold=16, autopull=1, clkdiv=25.

loop:
    out pins, 1         ; next half-bit level to P0
    jmp loop            ; 2 ticks x 25 cycles = 50 cycles per half bit
