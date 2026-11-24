; S/PDIF (IEC 60958 consumer) transmitter on P0, thread 0.
;
; One instruction = one tick = clkdiv core cycles. One cell = 2 ticks.
; With clkdiv=4 a cell is 8 cycles: 48 kHz at 49.152 MHz.
;
; Config: sideset_base=0, sideset_count=1, autopull=1, threshold=16,
;         in_msb_first=1, clkdiv=4.   Pin mode: 0=pp.
;
; The line level is the side-set bit of the instruction that is running.
; P0 rests high (reset value of the output register), so every preamble
; starts from "line high" and is the sheet's table inverted.
;
; Where the state lives:
;   line level before a bit ..... program position (dH/uH = high, dL/uL = low)
;   left or right subframe ...... ISR shift count ("isr full" = next is right)
;   frame counter F ............. ISR value. F = (24 - frame) mod 192, so
;                                 F=24: preamble B, F=22 or F=0: C=1.
;   bit counter ................. Y, in the data loop only
;   data bit .................... X
;
; The data loop sends 25 bits: 24 sample bits and V. V is bit 8 of the
; second word of the sample, which the host always sends as 0. Autopull
; swaps in the second word after 16 bits without costing a tick.
; U, C and P are sent by the handlers in page 1. P needs no arithmetic: it is
; whichever bit brings the line back high.

        .side_set 1

; ------------------------------------------------------------ page 0
start:  set y, 25          side 1      ; F starts at 25; the left preamble decrements first
        mov isr, y         side 1      ; isr = F, count 0: next subframe is left
tail:   pull               side 1      ; last tick of P. Blocks here, line high, when the words stop
pre:    jmp !isrf left     side 0      ; t1  first tick of every preamble

; right subframe: preamble W, line 0 0 0 1 1 0 1 1
        mov y, isr         side 0      ; t2
        mov isr, y         side 0      ; t3  same F, count back to 0: next is left
        set x, 1           side 0      ; t4
w1:     jmp x-- w1         side 0      ; t5 t6
        set x, 2           side 1      ; t7
w2:     jmp x-- w2         side 1      ; t8 t9 t10
        nop                side 0      ; t11
        nop                side 0      ; t12
        jmp pend           side 1      ; t13

; left subframe: next frame, so F moves on
left:   mov y, isr         side 0      ; t2
        jmp y-- lok        side 0      ; t3  F != 0: F = F - 1
; F was 0 (frame 24 just went): F = 191, and this frame (25) starts with M
        set x, 23          side 0      ; t4
        mov isr, x         side 0      ; t5
        set x, 7           side 0      ; t6
        in x, 3            side 1      ; t7  isr = 23 * 8 + 7 = 191
        mov y, isr         side 1      ; t8
        mov isr, y         side 1      ; t9  count back to 0 before lsave
        jmp lsave          side 1      ; t10
lok:    set x, 24          side 0      ; t4
        jmp x!=y lm        side 0      ; t5
; preamble B, line 0 0 0 1 0 1 1 1
        in y, 16           side 0      ; t6  isr = F, count 16: next is right
        nop                side 1      ; t7
        nop                side 1      ; t8
        nop                side 0      ; t9
        nop                side 0      ; t10
        nop                side 1      ; t11
        nop                side 1      ; t12
        jmp pend           side 1      ; t13
; preamble M, line 0 0 0 1 1 1 0 1
lm:     nop                side 0      ; t6
        nop                side 1      ; t7
        nop                side 1      ; t8
        nop                side 1      ; t9
        nop                side 1      ; t10
lsave:  in y, 16           side 1      ; t11 isr = F, count 16: next is right
        nop                side 1      ; t12
        set y, 24          side 0      ; t13 25 bits: 24 of the sample, and V
        set page, 1        side 0      ; t14
        nop                side 1      ; t15
        jmp dh             side 1      ; t16
        .page 0
pend:   set page, 1        side 1      ; t14 end of B and W
        set y, 24          side 1      ; t15
        jmp dh             side 1      ; t16

; ------------------------------------------------------------ page 1
        .align
; data loop, 4 ticks a bit. dh: line high before the bit. dl: line low.
dh:     out x, 1           side 0
        jmp !x dhz         side 0
        nop                side 1      ; a 1: back high, still dh
        jmp y-- dh         side 1
        jmp uh             side 0      ; U t1
dhz:    nop                side 0      ; a 0: stays low, now dl
        jmp y-- dl         side 0
        jmp ul             side 1      ; U t1
dl:     out x, 1           side 1
        jmp !x dlz         side 1
        nop                side 0
        jmp y-- dl         side 0
        jmp ul             side 1      ; U t1
dlz:    nop                side 1
        jmp y-- dh         side 1
        nop                side 0      ; U t1, falls into uh

; U, C, P: 12 ticks. C = 1 when F is 22 (frame 2) or 0 (frame 24).
; from line high:  C=1: 0000 11 00 1111     C=0: 0000 1111 00 11
uh:     mov y, isr         side 0      ; t2
        set x, 22          side 0      ; t3
        jmp x!=y uhc       side 0      ; t4
        nop                side 1      ; t5  F = 22
uh1:    jmp sufa           side 1      ; t6  C = 1
uhc:    jmp !y uh1         side 1      ; t5  F = 0
        jmp sufb           side 1      ; t6  C = 0
; from line low:   C=1: 1111 00 11 00 11    C=0: 1111 0000 1111
ul:     mov y, isr         side 1      ; t2
        set x, 22          side 1      ; t3
        jmp x!=y ulc       side 1      ; t4
        nop                side 0      ; t5
ul1:    jmp sufb           side 0      ; t6  C = 1
ulc:    jmp !y ul1         side 0      ; t5
        jmp sufa           side 0      ; t6  C = 0

sufa:   nop                side 0      ; t7
        nop                side 0      ; t8
        set page, 0        side 1      ; t9
        nop                side 1      ; t10
        jmp tail           side 1      ; t11
        .page 1
sufb:   nop                side 1      ; t7
        set page, 0        side 1      ; t8
        nop                side 0      ; t9
        nop                side 0      ; t10
        jmp tail           side 1      ; t11
