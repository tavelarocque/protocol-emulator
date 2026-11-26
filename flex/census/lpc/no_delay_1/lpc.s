; LPC host firmware, thread 0. I/O reads and memory reads.
; Config (run_args.txt): clkdiv=10, so one tick = 10 cycles = half an LCLK period.
; Every clock k is two ticks: F (LCLK falls, the only tick that changes LAD or
; LFRAME#) and H (LCLK rises: rising edge k, no LAD/LFRAME# change).
; Side-set, 2 pins from P4: bit 0 = LFRAME# (P4), bit 1 = LCLK (P5).
;   side 1 = LCLK low, LFRAME# high     side 3 = LCLK high, LFRAME# high
;   side 0 = LCLK low, LFRAME# low      side 2 = LCLK high, LFRAME# low
; set pins / out pins: LAD[3:0] on P0..P3. OSR: msb first, autopull, threshold 16.
; Host words: type (0 = I/O, 1 = memory), then 1 or 2 address words.
; Registers: Y = type of the current read, X = loop counter.

.side_set 2

; ---- boot: ticks 0..90 hold LCLK low, then clocks 0..3 idle ----
boot:   set x, 6        side 1   ; tick 0
        pull            side 1   ; tick 10: OSR = first type word
dl:     jmp x-- dl      side 1   ; ticks 20..80
        set x, 0        side 1   ; tick 90  (F of clock 0)
        nop             side 3   ; tick 100 (H of clock 0, rising edge 0)

; ---- idle clocks before a START: X+3 clocks ----
idle:   out y, 16       side 1   ; F: Y = type word; autopull loads the address
                                 ;    (stalls here for good once the words run out)
        nop             side 3   ; H
wl:     nop             side 1   ; F
        jmp x-- wl      side 3   ; H
        set x, 3        side 1   ; F: 4 address nibbles for an I/O read
        nop             side 3   ; H, falls into start

; ---- one read: START in clock s ----
start:  set pins, 0     side 0   ; F s: START, LFRAME# low, LAD 0000
        jmp !y io       side 2   ; H s
        set pins, 4     side 1   ; F s+1: CYCTYPE memory read, 0100
        set x, 7        side 3   ; H s+1: 8 address nibbles
addr:   out pins, 4     side 1   ; F: address nibble, most significant first
        jmp x-- addr    side 3   ; H
        set pins, 15    side 1   ; F t: TAR, chip drives 1111
        nop             side 3   ; H t
        nop             side 1   ; F t+1: TAR, nobody
        nop             side 3   ; H t+1
        nop             side 1   ; F t+2: SYNC
        nop             side 3   ; H t+2
        nop             side 1   ; F t+3
        in pins, 4      side 3   ; H t+3: low nibble
        nop             side 1   ; F t+4
        in pins, 4      side 3   ; H t+4: high nibble
        push            side 1   ; F t+5: 0x00HL to the host
        jmp !y ioext    side 3   ; H t+5
        set x, 4        side 1   ; F t+6: memory read, 7 idle clocks follow
        jmp idle        side 3   ; H t+6: rising edge L
ioext:  set x, 8        side 1   ; F t+6: I/O read, 11 idle clocks follow
        jmp idle        side 3   ; H t+6
io:     set pins, 0     side 1   ; F s+1: CYCTYPE I/O read, 0000
        jmp addr        side 3   ; H s+1 (X = 3 already)
