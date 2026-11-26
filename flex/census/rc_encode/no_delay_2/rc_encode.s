; PT2262 / HX2262 / SC5262 remote control encoder on P0 (thread 0).
;
; Config: clkdiv=1600, so one thread tick = 1600 cycles = 4 alpha = 160 us.
; Every line segment of the PT2262 code is a whole number of 4-alpha quarters:
;   pulse cycle = H, b, b, L   (b = 0 for short, 1 for long)
;   trit        = two pulse cycles = 8 ticks
;   sync bit    = H then 31 x L   = 32 ticks
;   frame       = 12 x 8 + 32     = 128 ticks = 204800 cycles
; Every instruction takes exactly one tick and drives P0 by side-set, so the
; level of each quarter is the side value of the instruction run in it.
;
; Data: threshold=12, LSB first, no autopull. Each trit is taken as two
; single-bit outs: X = bit0, Y = bit1 (value 1 = '1', 2 = 'f', 0 = '0').
;   first pulse long  iff bit0 = 1
;   second pulse long iff bit0 = 1 or bit1 = 1  (short path does mov x, y)
; After a trit's two outs the OSR is empty (12 bits gone) exactly at the
; sixth trit of a word, which !osre detects in the first pulse cycle.
; Copy A of the trit loop sends word 1 (trits 0-5) and pulls word 2 at its
; end (always present, so no stall mid-frame); copy B sends word 2
; (trits 6-11) and goes to the sync bit, whose low part pulls the next code
; word. With no word left that pull stalls with side 0: P0 stays low.

.side_set 1

init:   set x, 31       side 0      ; tick 0: P0 low from cycle 1
        jmp sl          side 0      ; tick 1
sync:   set x, 27       side 1      ; sync quarter 0: high
sl:     jmp x-- sl      side 0      ; 28 ticks low (32 at start-up)
        pull            side 0      ; first word of the next code word
        out x, 1        side 0      ; trit 0 bit0
        out y, 1        side 0      ; trit 0 bit1  (sync = 1+28+3 = 32)

; ---- copy A: trits 0..5 (word 1) ----
p1a:    jmp !x s1a      side 1      ; T0 rise
        jmp !osre l1an  side 1      ; T1 long
        pull            side 1      ; T2 long, word end: take word 2
        jmp p2ae        side 0      ; T3
l1an:   nop             side 1      ; T2 long
        jmp p2a         side 0      ; T3
s1an:   jmp p2a         side 0      ; T3 short
s1a:    mov x, y        side 0      ; T1 short: second pulse long iff bit1
        jmp !osre s1an  side 0      ; T2 short
        pull            side 0      ; T3 short, word end: take word 2
p2ae:   jmp !x s2ae     side 1      ; T4 rise
        out x, 1        side 1      ; T5 long
        out y, 1        side 1      ; T6 long
        jmp p1b         side 0      ; T7
s2ae:   out x, 1        side 0      ; T5 short
        out y, 1        side 0      ; T6 short
        jmp p1b         side 0      ; T7
p2a:    jmp !x s2a      side 1      ; T4 rise
        out x, 1        side 1      ; T5 long
        out y, 1        side 1      ; T6 long
        jmp p1a         side 0      ; T7
s2a:    out x, 1        side 0      ; T5 short
        out y, 1        side 0      ; T6 short
        jmp p1a         side 0      ; T7

; ---- copy B: trits 6..11 (word 2) ----
p1b:    jmp !x s1b      side 1      ; T0 rise
        jmp !osre l1bn  side 1      ; T1 long
        nop             side 1      ; T2 long, word end
        jmp p2be        side 0      ; T3
l1bn:   nop             side 1      ; T2 long
        jmp p2b         side 0      ; T3
s1bn:   jmp p2b         side 0      ; T3 short
s1b:    mov x, y        side 0      ; T1 short
        jmp !osre s1bn  side 0      ; T2 short
        nop             side 0      ; T3 short, word end
p2be:   jmp !x s2be     side 1      ; T4 rise
        nop             side 1      ; T5 long
        nop             side 1      ; T6 long
        jmp sync        side 0      ; T7
s2be:   nop             side 0      ; T5 short
        nop             side 0      ; T6 short
        jmp sync        side 0      ; T7
p2b:    jmp !x s2b      side 1      ; T4 rise
        out x, 1        side 1      ; T5 long
        out y, 1        side 1      ; T6 long
        jmp p1b         side 0      ; T7
s2b:    out x, 1        side 0      ; T5 short
        out y, 1        side 0      ; T6 short
        jmp p1b         side 0      ; T7
