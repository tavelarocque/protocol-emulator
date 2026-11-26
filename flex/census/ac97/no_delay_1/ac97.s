; AC '97 controller, output direction only (SYNC on P1, SDATA_OUT on P2).
; BIT_CLK on P0 (input). Thread 0, every cycle.
; Config: out_base=2 out_count=1 (SDATA_OUT), set_base=1 set_count=2
; (set pins: bit0 = SYNC, bit1 = SDATA_OUT), out_msb_first=1, threshold=16.
;
; Timing: every bit period starts with "wait 1 pin 0", which completes in
; the cycle the rising edge of BIT_CLK becomes visible (rising edge + 2, the
; same cycle the codec's falling edge happens). The next one or two
; instructions may write pins (changes appear at rising + 4 or + 5, never on a
; falling edge); at most three instructions follow before the next wait.
; The level written in a period is carried by the NEXT falling edge.
; Host words per frame: CTRL, DATA, LEFT, RIGHT.

start:
        set pins, 0             ; SYNC and SDATA_OUT low at once
        wait 0 pin 0            ; let the synchroniser show the real (low) clock
        pull                    ; first CTRL
        out null, 1             ; drop CTRL bit 15 (as B does for later frames)

; ---- frame: period writing falling edge e (SYNC rises) ----
frame:
        wait 1 pin 0            ; edge e: SYNC=1, SDATA=0
        set pins, 1
        out null, 6             ; drop CTRL bits 14..9
        out x, 1                ; X = c8 (frame has a command)
        wait 1 pin 0            ; e+1: tag bit 15 = 1
        set pins, 3
        out y, 1                ; Y = c7 (read)
        mov isr, y              ; keep c7 for slot 1 bit 19
        wait 1 pin 0            ; e+2: tag bit 14 = c8
        mov pins, x
        jmp !y tag13            ; not a read: X stays c8
        jmp x-- tag13           ; read: X = c8 - 1 = 0
tag13:
        wait 1 pin 0            ; e+3: tag bit 13 = c8 and not c7
        mov pins, x
        wait 1 pin 0            ; e+4: tag bit 12 = 1
        set pins, 3
        wait 1 pin 0            ; e+5: tag bit 11 = 1 (unchanged)
        set x, 8
        wait 1 pin 0            ; e+6: tag bit 10 = 0
        set pins, 1
tagz:
        wait 1 pin 0            ; e+7 .. e+15: tag bits 9..1 = 0
        jmp x-- tagz
        wait 1 pin 0            ; e+16: tag bit 0 = 0, SYNC low
        set pins, 0
        wait 1 pin 0            ; e+17: slot 1 bit 19 = c7
        mov pins, isr
        set x, 18
        set y, 3
bits:
        wait 1 pin 0            ; 19 bits from the OSR (then zeros)
        out pins, 1
        jmp x-- bits
        pull                    ; next word: DATA, LEFT, RIGHT, next CTRL
                                ; (stalls for ever after the last frame,
                                ; with both lines low)
        wait 1 pin 0            ; first bit of slot 2, 3, 4; or slot 5 bit 19
        out pins, 1             ; (for slot 5 this is CTRL bit 15 = 0)
        set x, 18
        jmp y-- bits
        wait 1 pin 0            ; e+98
        set y, 5
        wait 1 pin 0            ; e+99
outer:
        set x, 25
inner:
        wait 1 pin 0            ; e+100 .. e+255: 6 x 26 periods
        jmp x-- inner
        jmp y-- outer
        jmp frame
