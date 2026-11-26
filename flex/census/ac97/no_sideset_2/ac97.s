; AC '97 controller, output direction only, thread 0.
; P0 = BIT_CLK (input), P1 = SYNC, P2 = SDATA_OUT (push-pull).
; Config: set_base=1 set_count=2 (set pins writes SYNC=bit0, SDATA=bit1),
;         out_base=2 out_count=1 (out pins / mov pins write SDATA only),
;         out_msb_first=1, threshold=16.
;
; Every bit is one "group": a `wait 1 pin 0` that sees a rising edge of
; BIT_CLK (it executes 2 cycles after the rise, in the cycle BIT_CLK falls),
; then at most 3 more cycles. Pin writes are made only in the first two
; cycles after the wait, so they show 1 to 2 cycles after the falling edge
; and at least 1 cycle before the next one (periods are 4 or 5 cycles).
; The group that sees the rise before falling edge k-1 sets the level
; carried by falling edge k. Frame groups are numbered e .. e+255, where e is
; the edge at which SYNC first goes high (see TASK.md).

start:  set pins 0              ; SYNC=0, SDATA=0 from cycle 1
        wait 0 pin 0            ; skip the synchroniser's reset-high reads
        jmp frame

; ---- tag, second part (reached from group e+2) ----
e3:     wait 1 pin 0            ; e+3: tag bit 13 = c8 & !c7
        jmp !x wy               ; X = c7: 0 -> bit is c8 (in Y)
        set pins 1              ; read: SYNC=1, SDATA=0
        jmp e4
wy:     mov pins y              ; SDATA = c8
e4:     wait 1 pin 0            ; e+4: tag bit 12 = 1
        set pins 3
        wait 1 pin 0 [1]        ; e+5: tag bit 11 = 1 (no change); the delay
                                ; keeps the next wait off this same high phase
        wait 1 pin 0            ; e+6: tag bit 10 = 0
        set pins 1
        set y 8
z1:     wait 1 pin 0            ; e+7 .. e+15: tag bits 9..1 = 0
        jmp y-- z1
        wait 1 pin 0            ; e+16: tag bit 0 = 0, SYNC low
        set pins 0
        set y 18
        wait 1 pin 0            ; e+17: slot 1 bit 19 = c7 (read flag)
        mov pins x
        set x 3                 ; slots 1 (rest), 2, 3, 4
        jmp bits

; ---- slots 2, 3, 4: pull a word, send it and 4 zero bits ----
slot:   wait 1 pin 0            ; first bit of slot 2/3/4
        pull
        out pins 1              ; shows 3 cycles after the fall: still safe
        set y 18
bits:   wait 1 pin 0            ; remaining 19 bits of a slot
        out pins 1              ; past 16 bits the OSR gives zeros
        jmp y-- bits
        jmp x-- slot

; ---- slots 5..12: 159 zero bits (e+97 .. e+255) ----
        wait 1 pin 0            ; e+97
        set y 4
        set x 29
zl:     wait 1 pin 0            ; 30 + 4 * 32 groups
        jmp x-- zl
        set x 31
        jmp y-- zl

; ---- group e: SYNC rises (with the previous frame's last bit, or idle) ----
frame:  wait 1 pin 0            ; e
        pull                    ; CTRL; stalls forever with lines low when the words run out
        set pins 1              ; SYNC=1, SDATA=0
        out null 7              ; OSR top = c8
        wait 1 pin 0            ; e+1: tag bit 15 = 1
        set pins 3
        out y 1                 ; Y = c8 (command present)
        out x 1                 ; X = c7 (read); OSR top = address a6..a0
        wait 1 pin 0            ; e+2: tag bit 14 = c8
        mov pins y
        jmp e3
