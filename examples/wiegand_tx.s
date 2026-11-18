; wiegand_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Wiegand transmitter (card readers and keypads): two lines, D0 and D1,
; both idle high; a 0 is a short low pulse on D0, a 1 a short low pulse on
; D1.
;
; Pins: P0 = D0, P1 = D1, push-pull or open-drain. Config:
; [wiegand_tx_config]: set_base 0, set_count 2; threshold 16; CLKDIV sets
; the tick: 250 for 25 us at 10 MHz.
;
; Host protocol, one frame at a time:
;   TX word 0 : N - 1, for a frame of N bits (26 and 34 are the common
;               formats; parity bits are the host's to work out)
;   then      : ceil(N / 16) words, first bit sent in bit 0
;
; Timing, in ticks: the pulse is 2 and bits are exactly 40 apart, also
; where a word ends: 50 us and 1 ms with a 25 us tick, which is what
; readers send.
        set pins, 3         ; both lines idle high
frame:  pull                ; X <- bits - 1
        out x, 16
word:   pull
bit:    out y, 1
        jmp !y zero
        set pins, 1         ; a 1: D1 low
        jmp gap
zero:   set pins, 2 [1]     ; a 0: D0 low
gap:    set pins, 3 [15]
        nop [15]
        jmp x-- more
        jmp frame
more:   jmp !osre same      ; both ways round take 3 ticks
        pull
        jmp bit
same:   jmp bit [1]
