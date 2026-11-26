; AC '97 controller, output direction only (SYNC and SDATA_OUT).
; Thread 0, 50 MHz core, BIT_CLK on P0 (input), SYNC on P1, SDATA_OUT on P2.
; Config: set_base=1 set_count=2 (set pins writes SYNC=bit0, SDATA=bit1),
;         out_base=2 out_count=1 (out/mov pins write SDATA only),
;         out_msb_first=1, threshold=16, no autopull.
;
; Timing rule: every bit is one "block": `wait 1 pin 0` (W) followed by 1 to 3
; instructions. W completes 2 cycles after a rising edge of BIT_CLK (the
; synchroniser delay). A pin write in the 1st or 2nd instruction after W shows
; 3 or 4 cycles after the rising edge: after the falling edge that follows it
; (2 cycles after the rise) and before the next one (6 or 7 cycles after the
; rise). So each block sets the level for the next falling edge. The next W
; must come 2 to 4 instructions after the previous one.

        set pins, 0          ; SYNC=0 SDATA=0 from cycle 1
        wait 0 pin 0         ; P0 reads high for 2 cycles after reset: skip that

; Two blocks before every frame (edges e-2, e-1): fetch CTRL and split it.
; If the host has no more words, the pull waits forever with both lines low.
P1:     wait 1 pin 0
        pull                 ; CTRL
        out null, 7          ; drop bits 15..9
        out x, 1             ; x = bit 8: frame carries a command
P2:     wait 1 pin 0
        out y, 1             ; y = bit 7: the command is a read

; Edge e: SYNC rises with the last (zero) bit of the previous frame.
frame:  wait 1 pin 0
        set pins, 1          ; e: SYNC=1 SDATA=0
        wait 1 pin 0
        set pins, 3          ; e+1: tag 15 = 1
        wait 1 pin 0
        mov pins, x          ; e+2: tag 14 = command
        wait 1 pin 0         ; e+3: tag 13 = write = (x != y)
        jmp x!=y WR
        set pins, 1
        jmp J
WR:     set pins, 3
J:      wait 1 pin 0
        set pins, 3          ; e+4: tag 12 = 1
        wait 1 pin 0
        set x, 8             ; e+5: tag 11 = 1 (held)
        wait 1 pin 0
        set pins, 1          ; e+6: tag 10 = 0
HOLD:   wait 1 pin 0         ; e+7 .. e+15: tag 9..1 = 0, SYNC held high
        jmp x-- HOLD
        wait 1 pin 0
        set pins, 0          ; e+16: SYNC=0, tag 0 = 0
        set x, 18
        wait 1 pin 0
        mov pins, y          ; e+17: slot 1 bit 19 = read
        set y, 2
S1:     wait 1 pin 0         ; e+18 .. e+36: address, then zeros
        out pins, 1
        jmp x-- S1
SLOT:   wait 1 pin 0         ; slots 2, 3, 4: DATA, LEFT, RIGHT
        pull
        out pins, 1          ; bit 19
        set x, 18
SB:     wait 1 pin 0         ; bits 18..0 (bits 3..0 shift out as zeros)
        out pins, 1
        jmp x-- SB
        jmp y-- SLOT
        wait 1 pin 0         ; e+97 (SDATA already 0)
        set y, 11
Z1:     set x, 12
Z2:     wait 1 pin 0         ; 12 x 13 = 156 blocks: e+98 .. e+253
        jmp x-- Z2
        jmp y-- Z1
        jmp P1               ; P1, P2 are e+254, e+255; next frame at e+256
