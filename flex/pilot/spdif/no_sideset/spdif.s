; S/PDIF transmitter, 8 cycles per cell (48 kHz), P0, thread 0.
; config: start=12 set_base=0 set_count=1 autopull=1 threshold=16
; State: line level is in the PC (H/L copies), frame counter c in ISR,
; ISR-full flag = "next subframe is the right one", Y = slot counter.
bit_l:   set pins, 1
        jmp y-- cont_l
tail_l:  mov y, isr
        set x, 22
        jmp x!=y n22_l
        jmp c1_l [2]
n22_l:   jmp !y c1_l [2]
c1_h:    set pins, 1 [7]
p1:     set pins, 0 [7]
        set pins, 1 [5]
fin:    out null, 6
        jmp !osre pre
start:  pull
        set y, 25
        mov isr, y
pre:    set pins, 0
        jmp !isrf left [6]
right:  mov isr, y [15]
        set pins, 1 [15]
        set pins, 0 [7]
        set pins, 1 [13]
        jmp entry
left:   jmp y-- dec
        in y, 6
        in null, 1
        in y, 1
        in null, 8
        jmp pre_m [10]
dec:    in y, 16
        set x, 24
        jmp x!=y pre_m [12]
pre_b:   set pins, 1 [7]
        set pins, 0 [7]
        set pins, 1 [15]
        jmp entry [6]
pre_m:   set pins, 1 [15]
        nop [7]
        set pins, 0 [7]
        set pins, 1 [5]
        jmp entry
entry:  set y, 26
bit_h:   set pins, 0
        jmp y-- cont_h
tail_h:  mov y, isr
        set x, 22
        jmp x!=y n22_h
        jmp c1_h [2]
n22_h:   jmp !y c1_h [2]
c1_l:    set pins, 0 [7]
p0:     set pins, 1 [12]
        jmp fin
cont_h:  out x, 1
        jmp !x mid_l [4]
mid_h:   set pins, 1
        jmp bit_h [6]
cont_l:  out x, 1
        jmp !x mid_h [4]
mid_l:   set pins, 0
        jmp bit_l [6]
