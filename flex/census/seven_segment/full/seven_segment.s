; 7-segment (common-anode) driver, thread 0, 10 MHz.
; Pins P0..P7 = a b c d e f g dp, lit = 0.
; Config: start=64, out_base=0, out_count=8, out_msb_first=1, in_msb_first=1, threshold=16.
;
; Per word: pull, decode into the ISR as  last<<8 | dp_n<<7 | g_n<<6 | f_n<<5 | e_n..a_n
; (the _n bits are pin levels, 0 = lit), pad, then one `mov pins, isr` writes all 8 pins at once.
; Every path from one `mov pins` to the next is exactly 1000 cycles.
;
; Page 0: the digit dispatch chain, the 16 leaves and the 4 tails (reached with PAGE = 0).
; Page 1: the main loop (start = 64, PAGE = 1).

; ---------------- page 0 ----------------
; Chain: X = digit. c_k falls through to leaf k when X = 0, else decrements and goes on.
; Digit d spends d+1 cycles in the chain (15 for d = 15); leaf delays make chain+leaf = 17.
; Leaf: X = segments a..e (pin levels), then jump to the tail that sets Y = g,f (pin levels).
c0:     jmp x-- c1
        set x, 0  [14]          ; 0: a b c d e f
        jmp t2
c1:     jmp x-- c2
        set x, 25 [13]          ; 1: b c
        jmp t3
c2:     jmp x-- c3
        set x, 4  [12]          ; 2: a b d e g
        jmp t1
c3:     jmp x-- c4
        set x, 16 [11]          ; 3: a b c d g
        jmp t1
c4:     jmp x-- c5
        set x, 25 [10]          ; 4: b c f g
        jmp t0
c5:     jmp x-- c6
        set x, 18 [9]           ; 5: a c d f g
        jmp t0
c6:     jmp x-- c7
        set x, 2  [8]           ; 6: a c d e f g
        jmp t0
c7:     jmp x-- c8
        set x, 24 [7]           ; 7: a b c
        jmp t3
c8:     jmp x-- c9
        set x, 0  [6]           ; 8: all
        jmp t0
c9:     jmp x-- c10
        set x, 16 [5]           ; 9: a b c d f g
        jmp t0
c10:    jmp x-- c11
        set x, 8  [4]           ; A: a b c e f g
        jmp t0
c11:    jmp x-- c12
        set x, 3  [3]           ; b: c d e f g
        jmp t0
c12:    jmp x-- c13
        set x, 6  [2]           ; C: a d e f
        jmp t2
c13:    jmp x-- c14
        set x, 1  [1]           ; d: b c d e g
        jmp t1
c14:    jmp x-- c15
        set x, 6                ; E: a d e f g
        jmp t0
c15:    set x, 14               ; F: a e f g
        jmp t0
; Tails: Y = g_n<<1 | f_n. 2 cycles each.
t0:     set y, 0
        jmp common
t1:     set y, 1
        jmp common
t2:     set y, 2
        jmp common
t3:     set y, 3  [1]
common: in y, 2
        in x, 5
        set page, 1
        jmp pad

; ---------------- page 1 ----------------
        .align
top:    pull                    ; next word (the host keeps the FIFO full)
        mov isr, null
        out null, 9             ; bits 15..7 are 0
        out x, 1                ; bit 6: last
        in x, 1
        out y, 1                ; bit 5: blank
        out x, 1                ; bit 4: dp (1 = lit)
        jmp x-- dpn             ; X-1 flips bit 0: pin level of dp
dpn:    in x, 1
        out x, 4                ; bits 3..0: digit
        set page, 0
        jmp !y c0               ; not blank: dispatch on the digit (19 cycles to common)
        set x, 31 [15]          ; blank: a..e dark
        set y, 3                ; f, g dark
        jmp common [1]
        .page 1
pad:    set x, 31 [14]          ; 15 cycles
l1:     jmp x-- l1 [15]         ; 512 cycles
        set x, 26               ; 1 cycle
l2:     jmp x-- l2 [15]         ; 432 cycles
        mov pins, isr           ; THE pin change, once per 1000 cycles
        mov osr, isr
        out null, 7
        out x, 1                ; ISR bit 8: last word?
        jmp !x top
        jmp x-- n1              ; X: 1 -> 0
n1:     jmp x-- n2              ; X: 0 -> 0xFFFF (all pins dark)
n2:     set y, 31 [15]          ; 16 cycles
w1:     jmp y-- w1 [15]         ; 512 cycles
        set y, 28               ; 1 cycle
w2:     jmp y-- w2 [15]         ; 464 cycles
        mov pins, x             ; blank, 1000 cycles after the last character
halt:   jmp halt
