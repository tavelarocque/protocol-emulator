; LPC host firmware, thread 0. I/O reads and memory reads.
; Pins: P0..P3 LAD (open-drain), P4 LFRAME# (push-pull), P5 LCLK (push-pull).
; Config: out_base=0 out_count=4 (LAD), set_base=4 set_count=2 (bit0 LFRAME#,
; bit1 LCLK), in_base=0, out_msb_first=1, threshold=16.
; One LCLK period = 20 cycles. In every period, F is the cycle in which the
; falling-edge instruction runs; the rising-edge instruction runs at F+10,
; so its pins line is at F+11 = 100 + 20k. LAD and LFRAME# only change in
; the first few cycles after the falling edge.
; set pins values: 1 = fall (LCLK 0, LFRAME# 1), 3 = rise, 0 = START fall,
; 2 = START rise.

init:   set x, 2 [2]           ; cycles 0..2; clocks 0..2 in the idle loop, clock 3 is lastidle
        set y, 27 [1]          ; cycles 3..4 (LCLK stays high from reset until cycle 90)
dly:    jmp y-- dly [2]        ; cycles 5..88, 28 x 3
idle:   set pins, 1 [9]        ; F      fall, LAD released
        set pins, 3 [8]        ; F+10   rise
        jmp x-- idle           ; F+19
lastidle:
        set pins, 1 [9]        ; F      fall
        set pins, 3            ; F+10   rise
        pull                   ; F+11   type word (stalls only after the last read)
        mov y, osr             ; F+12   y = 0 (I/O) or 1 (memory)
        out null, 14 [6]       ; F+13   type bits 1..0 now at the top of the OSR
start:  set pins, 0            ; T      START: LFRAME# low, LCLK low
        mov pins, null         ; T+1    LAD 0000
        set x, 11 [7]          ; T+2    idle clocks after an I/O read, minus 1
        set pins, 2 [9]        ; T+10   rise with LFRAME# low
        set pins, 1            ; T+20   CYCTYPE: LFRAME# high, fall
        out pins, 4            ; T+21   0000 (I/O) or 0100 (memory)
        pull [7]               ; T+22   address word (bits 31..16 for memory)
        set pins, 3 [9]        ; T+30   rise
nib:    set pins, 1            ; F      address nibble, most significant first
        out pins, 4 [8]        ; F+1
        set pins, 3 [8]        ; F+10
        jmp !osre nib          ; F+19   four nibbles per word
post:   set pins, 1            ; F      first TAR clock, or memory nibble 4
        jmp !y tail            ; F+1
        set y, 0               ; F+2    memory: next time through, go to tail
        set x, 7               ; F+3    idle clocks after a memory read, minus 1
        pull                   ; F+4    address bits 15..0
        out pins, 4 [4]        ; F+5
        set pins, 3 [8]        ; F+10
        jmp nib                ; F+19
tail:   set y, 31              ; F+2
        mov pins, y [6]        ; F+3    TAR 1111: LAD released
        set pins, 3 [9]        ; F+10
        set pins, 1 [9]        ; TAR 2
        set pins, 3 [9]
        set pins, 1 [9]        ; SYNC
        set pins, 3 [9]
        set pins, 1 [5]        ; DATA, low nibble
        in pins, 4 [3]         ; F+6
        set pins, 3 [9]
        set pins, 1 [5]        ; DATA, high nibble
        in pins, 4             ; F+6
        push [2]               ; F+7    byte, low nibble first
        set pins, 3 [8]        ; F+10
        jmp idle               ; F+19
