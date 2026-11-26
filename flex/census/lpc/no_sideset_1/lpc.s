; LPC host, thread 0. LCLK = 20 cycles (2.5 MHz at 50 MHz).
; Pins: P0-P3 LAD (od), P4 LFRAME# (pp), P5 LCLK (pp).
; Config: set_base=4 set_count=2 (set pins: bit0 = LFRAME#, bit1 = LCLK),
;         out_base=0 out_count=4 (LAD), in_base=0, threshold=16, out_msb_first=1.
; set pins values: 0 = LCLK low/LFRAME low, 1 = LCLK low/LFRAME high,
;                  2 = LCLK high/LFRAME low, 3 = LCLK high/LFRAME high.
; Every LCLK period is 20 cycles. "rel 0" is the cycle the falling-edge
; instruction runs (rising edge E_prev + 9); the rising-edge instruction runs
; at rel 10. LAD and LFRAME# only change from instructions at rel 0..8.

; ---- prelude: LCLK stays high until the first fall at cycle 89 ----
        set y, 4                ; cycle 0
w:      jmp y-- w [15]          ; 5 x 16 = 80 cycles: 1..80
        set x, 2 [7]            ; 81..88, three idle clocks (0, 1, 2) follow

; ---- idle clocks: x+1 periods ----
idle:   set pins, 1 [9]         ; rel 0..9  LCLK low
        set pins, 3 [8]         ; rel 10..18 LCLK high
        jmp x-- idle            ; rel 19

; ---- one read slot: P0 = clock s-1 (idle), P1 = START clock s ----
slot:   set pins, 1             ; P0 rel 0
        pull                    ; rel 1: type word (stalls here after the last read)
        out x, 16               ; rel 2: x = type, OSR now empty
        jmp !x io0              ; rel 3
        set y, 7                ; rel 4: memory, 8 address nibbles
        set x, 4                ; rel 5: CYCTYPE 0100
        jmp j0 [3]              ; rel 6..9
io0:    set y, 3 [5]            ; rel 4..9: I/O, 4 nibbles, CYCTYPE 0000 (x=0)
j0:     set pins, 3 [9]         ; rel 10..19

        set pins, 0             ; P1 START rel 0: LFRAME# low
        mov pins, null [8]      ; rel 1..9: LAD 0000
        set pins, 2             ; rel 10: LCLK rises (edge s), LFRAME# still low
        set pins, 3 [8]         ; rel 11..19: LFRAME# high from edge s + 1 cycle

        set pins, 1             ; P2 CYCTYPE rel 0: LFRAME# high
        mov pins, x             ; rel 1: LAD = 0000 or 0100
        jmp !x ioc              ; rel 2
        set x, 7                ; rel 3: memory, 8 idle periods after DATA
        jmp b0 [5]              ; rel 4..9
ioc:    set x, 11 [6]           ; rel 3..9: I/O, 12 idle periods after DATA
b0:     set pins, 3 [9]         ; rel 10..19

aloop:  set pins, 1             ; ADDR rel 0
        jmp !osre has           ; rel 1
        pull                    ; rel 2: next address word
        out pins, 4 [5]         ; rel 3..8
        jmp rise                ; rel 9
has:    out pins, 4 [7]         ; rel 2..9
rise:   set pins, 3 [8]         ; rel 10..18
        jmp y-- aloop           ; rel 19 (y ends at 0xFFFF)

        set pins, 1             ; TAR 1 rel 0
        mov pins, y [8]         ; rel 1..9: LAD 1111 (released)
        set pins, 3 [9]
        set pins, 1 [9]         ; TAR 2
        set pins, 3 [9]
        set pins, 1 [9]         ; SYNC
        set pins, 3 [9]
        set pins, 1 [4]         ; DATA low nibble, rel 0..4
        in pins, 4 [4]          ; rel 5..9 (sees the level at rel 3)
        set pins, 3 [9]
        set pins, 1 [4]         ; DATA high nibble
        in pins, 4              ; rel 5
        push [3]                ; rel 6..9: the byte, bits 15..8 zero
        set pins, 3 [8]         ; rel 10..18
        jmp idle                ; rel 19
