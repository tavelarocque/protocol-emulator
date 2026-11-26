; LPC host, thread 0. I/O reads and memory reads.
;
; Config (run_args.txt): clkdiv=10, so one tick = 10 cycles = half an LCLK
; period. Every instruction is exactly one tick and side-sets LCLK, so the
; program alternates "L" ticks (LCLK low, change LAD/LFRAME#) and "H" ticks
; (LCLK high = rising edge, nothing else changes). L tick of clock k runs at
; cycle 90+20k (shows 91+20k), H tick at 100+20k (rising edge shows 101+20k).
;
; Side-set: 2 bits, base P4. bit0 = P4 LFRAME#, bit1 = P5 LCLK.
;   side 1: LFRAME# high, LCLK low     side 3: LFRAME# high, LCLK high
;   side 0: LFRAME# low,  LCLK low     side 2: LFRAME# low,  LCLK high
; set pins / out pins: P0..P3 (LAD). in pins: P0..P3.
; OSR: msb first, threshold 16, autopull: host words stream through it.
; X: type of the next read, then the idle padding count for this read.
; Y: loop counters.

        .side_set 2

; ---- preamble: ticks 0..9 LCLK low, rising edge 0 at tick 10 ----
        set y, 6        side 1      ; tick 0
w0:     jmp y-- w0      side 1      ; ticks 1..7
        pull            side 1      ; tick 8: first type word into OSR
        set x, 1        side 1      ; tick 9: pad 2 clocks (clocks 1, 2)
        jmp pad         side 3      ; tick 10: rising edge 0

; ---- idle: X+1 clocks, then read next type and branch ----
pad:    nop             side 1      ; L
        jmp x-- pad     side 3      ; H
        out x, 16       side 1      ; L: X = type; autopull loads address word
        jmp !x io       side 3      ; H: last clock before START

; ---- memory read: START, CYCTYPE 0100, 8 address nibbles ----
mem:    set pins, 0     side 0      ; c0 L  START: LAD 0000, LFRAME# low
        set y, 7        side 2      ; c0 H
        set pins, 4     side 1      ; c1 L  CYCTYPE+DIR 0100
        set x, 6        side 3      ; c1 H  idle pad after a memory read
addr:   out pins, 4     side 1      ; L  address nibble, msb first
        jmp y-- addr    side 3      ; H

; ---- common tail from the first TAR clock t ----
tar:    set pins, 15    side 1      ; t L    TAR: release LAD (1111)
        set y, 1        side 3      ; t H
tw:     nop             side 1      ; t+1 L, t+2 L
        jmp y-- tw      side 3      ; t+1 H, t+2 H (SYNC)
        nop             side 1      ; t+3 L
        in pins, 4      side 3      ; t+3 H  low nibble
        nop             side 1      ; t+4 L
        in pins, 4      side 3      ; t+4 H  high nibble
        push            side 1      ; t+5 L  byte to host
        jmp pad         side 3      ; t+5 H

; ---- I/O read: START, CYCTYPE 0000, 4 address nibbles ----
io:     set pins, 0     side 0      ; c0 L  START
        set y, 3        side 2      ; c0 H
        set x, 10       side 1      ; c1 L  CYCTYPE+DIR 0000 (LAD already 0000)
        jmp addr        side 3      ; c1 H
