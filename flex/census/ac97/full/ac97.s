; AC '97 controller, output direction only, thread 0.
; P0 = BIT_CLK (input), P1 = SYNC, P2 = SDATA_OUT.
; Config: set_base=1 set_count=2 (set pins: bit0 = SYNC, bit1 = SDATA),
;         out_base=2 out_count=1 (out/mov pins drive SDATA only),
;         out_msb_first=1, threshold=16.
;
; Every bit slot is: "wait 1 pin 0" (sees a rising edge of BIT_CLK two
; cycles late, which is the very cycle that edge's falling edge happens),
; then 1 to 3 instructions, the pin write (if any) always the first. The
; write shows two cycles after the falling edge and so is the level for the
; NEXT falling edge. 1 instruction minimum keeps a wait from seeing the same
; high phase twice; 3 maximum keeps up with a 4-cycle BIT_CLK period.
; Edge offsets below are those of the falling edge that carries the level.

        set pins, 0          ; SYNC and SDATA low at once
        wait 0 pin 0         ; skip the two reset cycles that read high
        pull                 ; first CTRL
        wait 1 pin 0         ; R0: level for F1 stays low
        jmp fstart           ; fstart sets SYNC for F2 (e = 2)

loop:   wait 1 pin 0         ; e+2: tag bit 14 = command
        mov pins, x
        jmp x!=y wr          ; x=1,y=0: write, keep x = 1
        mov x, null          ; none (0,0) or read (1,1): bit 13 = 0
wr:     wait 1 pin 0         ; e+3: tag bit 13 = slot 2 valid
        mov pins, x
        wait 1 pin 0         ; e+4: tag bit 12 = 1
        set pins, 3
        wait 1 pin 0         ; e+5: tag bit 11 = 1 (no change)
        set x, 8
        wait 1 pin 0         ; e+6: tag bit 10 = 0
        set pins, 1
z1:     wait 1 pin 0         ; e+7..e+15: tag bits 9..1 = 0
        jmp x-- z1
        wait 1 pin 0         ; e+16: SYNC low, tag bit 0 = 0
        set pins, 0
        set x, 7
        wait 1 pin 0         ; e+17: slot 1 bit 19 = read flag
        mov pins, y
s1:     wait 1 pin 0         ; e+18..e+25: address bits, then a 0 (OSR spent)
        out pins, 1
        jmp x-- s1
        pull                 ; DATA
        wait 1 pin 0         ; e+26: 0
        set x, 9
        set y, 2
z2:     wait 1 pin 0         ; e+27..e+36: 0
        jmp x-- z2
        set x, 18
wb:     wait 1 pin 0         ; 16 sample bits then 3 zeros of slots 2, 3, 4
        out pins, 1
        jmp x-- wb
        wait 1 pin 0         ; slot's last bit, 0 (already low)
        pull                 ; next word: LEFT, RIGHT, then the next CTRL
        set x, 18            ; (after the last frame this pull stalls for good,
        jmp y-- wb           ;  with SYNC and SDATA low)
        wait 1 pin 0         ; e+97: 0
        set x, 29
        set y, 4
zi:     wait 1 pin 0         ; e+98..e+255: 0 (30 + 4 x 32 bits)
        jmp x-- zi
        set x, 31
        jmp y-- zi
fstart: wait 1 pin 0         ; e (= e+256 of the previous frame): SYNC high
        set pins, 1
        out null, 7          ; CTRL bits 15..9
        out x, 1             ; x = command
        wait 1 pin 0         ; e+1: tag bit 15 = 1
        set pins, 3
        out y, 1             ; y = read
        jmp loop
