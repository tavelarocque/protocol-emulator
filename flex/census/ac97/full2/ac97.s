; AC '97 controller, output direction only, thread 0.
; P0 = BIT_CLK (input), P1 = SYNC, P2 = SDATA_OUT.
; Config (run_args.txt): out_base=2 out_count=1 (SDATA), set_base=1 set_count=2
; (bit 0 = SYNC, bit 1 = SDATA), threshold=16, out_msb_first=1, in_msb_first=1.
;
; Timing rule used everywhere: the thread sees P0 two cycles late, so a
; "wait 1 pin 0" that is already stalling completes in the very cycle w in
; which BIT_CLK falls. Writes made in cycles w+1 and w+2 show in w+2 and w+3,
; which is never a falling edge (next one is w+4 or w+5). Every block below
; is: one wait (= one falling edge), then at most 3 cycles of work, with pin
; writes only in the first two of them. The next wait is reached between w+2
; (BIT_CLK seen low again) and w+4 (next edge seen at w+4 at the earliest).
;
; Block B(t) = wait for edge S+t-1, then set the level for edge S+t, where S is
; the edge at which this frame's SYNC is first high. Frame bit t (1..256) is
; carried by edge S+t.

        set pins, 0             ; SYNC and SDATA low from cycle 1
        set x, 4
        in x, 3                 ; ISR = 100b
        set x, 31
        in x, 5                 ; ISR = 10011111b = 159 (kept for good)
        pull                    ; CTRL of the first frame
        wait 0 pin 0            ; past the two reset cycles that read high
        set x, 7                ; waits for edges 0..7, first SYNC at edge 8

tail:                           ; x+1 waits, the last is for edge S-1
        wait 1 pin 0
        jmp x-- tail
        set pins, 1             ; B(0): SYNC high, SDATA low
        out null, 7             ; drop CTRL bits 15..9
        wait 1 pin 0            ; B(1): tag 15 = 1
        set pins, 3
        out x, 1                ; x = bit 8 (command)
        out y, 1                ; y = bit 7 (read)
        wait 1 pin 0            ; B(2): tag 14 = slot 1 valid
        mov pins, x
        wait 1 pin 0            ; B(3): tag 13 = slot 2 valid = write = (x != y)
        jmp x!=y t13            ; write: SDATA is already 1 from tag 14
        mov pins, null          ; read or no command: 0
t13:
        wait 1 pin 0            ; B(4): tag 12 = 1
        set pins, 3
        wait 1 pin 0 [1]        ; B(5): tag 11 = 1, nothing to change
        wait 1 pin 0            ; B(6): tag 10 = 0
        set pins, 1
        set x, 9
w9:     wait 1 pin 0            ; B(7)..B(16) waits: tag 9..1 = 0, then
        jmp x-- w9              ; B(16)'s own wait (edge S+15)
        set pins, 0             ; B(16): tag 0 = 0, SYNC low
        wait 1 pin 0            ; B(17): slot 1 bit 19 = read flag
        mov pins, y
        set x, 7
        set y, 10
s1:     wait 1 pin 0            ; B(18)..B(25): address bits 6..0, then a 0
        out pins, 1             ; (the OSR gives zeros once its 16 bits are out)
        jmp x-- s1
        pull                    ; DATA
w11:    wait 1 pin 0            ; B(26)..B(36): slot 1 bits 10..0 = 0
        jmp y-- w11
        set x, 15
        set y, 2                ; three 20-bit slots: DATA, LEFT, RIGHT

slot:   wait 1 pin 0            ; 16 bits of the word, MSB first
        out pins, 1
        jmp x-- slot
        wait 1 pin 0            ; pad bit 1 = 0 (OSR is empty, gives 0)
        out pins, 1
        pull                    ; LEFT, RIGHT, or next frame's CTRL (stalls at the end)
        set x, 15
        wait 1 pin 0 [1]        ; pad bit 2
        wait 1 pin 0 [1]        ; pad bit 3
        wait 1 pin 0            ; pad bit 4
        jmp y-- slot
        mov x, isr              ; 159: B(97)..B(256), 160 waits
        jmp tail
