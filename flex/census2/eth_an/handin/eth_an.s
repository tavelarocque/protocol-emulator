; Ethernet auto-negotiation FLP burst transmitter, thread 0.
; Config: clkdiv=4 (one tick = 4 cycles = 100 ns), set_base=0, set_count=2
; (set pins writes P0 and P1, P1 always 0), out_base=0, out_count=1
; (out pins writes P0 only), threshold=16.
; All times below are in ticks. Pulse = 1 tick high = 4 cycles.
; Pulse positions are 625 ticks (2500 cycles) apart.

        set pins, 0             ; P0 = P1 = 0 at once (shows at cycle 1)

main:                           ; gap before every burst: 1 + 32*3089 = 98849 ticks
        set y, 31
g1:     set x, 31
g2:     nop [15]                ; inner body: 6 x 16 = 96 ticks per pass
        nop [15]
        nop [15]
        nop [15]
        nop [15]
        jmp x-- g2 [15]         ; 32 passes = 3072 ticks
        jmp y-- g1 [15]         ; outer pass = 1 + 3072 + 16 = 3089 ticks

        pull                    ; one word = one burst; stalls (line idle) when none
        set y, 15               ; 16 bits, D0 first (OSR shifts LSB first)

bit:    set pins, 1             ; clock pulse rises (tick T)
        set pins, 0 [14]        ; falls at T+1: 15 ticks
        set x, 18               ; 1 tick
d1:     nop [15]                ; 19 passes x 32 = 608 ticks
        jmp x-- d1 [15]
        out pins, 1             ; data pulse Dk at T+625 (P0 = Dk)
        set pins, 0 [13]        ; 14 ticks
        set x, 18               ; 1 tick
d2:     nop [15]                ; 608 ticks
        jmp x-- d2 [15]
        jmp y-- bit             ; 1 tick: next clock at T+1250

        set pins, 1             ; 17th (last) clock pulse
        set pins, 0
        jmp main
