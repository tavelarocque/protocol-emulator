; S/PDIF (IEC 60958 consumer) transmitter on P0, thread 0.
; Cell (unit interval) = 8 core-clock cycles -> 48 kHz at 49.152 MHz.
;
; pe_sim run flags:  -config set_base=0,set_count=1,autopull=1,threshold=16 -mode 0=pp
;
; Host words per frame: L[15:0], L[23:16], R[15:0], R[23:16].
;
; Registers
;   OSR  the word being sent. Autopull joins the 16-bit and the 8-bit word of
;        a sample into one stream of 26 bits: 24 data bits, then V = 0 and
;        U = 0, which are the zero bits 8 and 9 of the second word.
;   X    bit counter of the 26-bit loop (scratch outside it).
;   Y    the bit being sent (scratch outside the loop).
;   ISR  frame counter c, and one flag in its shift count:
;        ISR full (16 bits shifted in)  = the left subframe is being sent,
;        ISR not full                   = the right subframe is being sent.
;        c is 24 in frame 0 of a block and goes down by one a frame; after 0
;        it is reloaded with 191.  So c = 24: preamble B.  c = 22 (frame 2)
;        and c = 0 (frame 24): channel status bit C = 1.
;
; The line rests high (the output register resets to ones), so every preamble
; is the inverted form.  The line level is held in the program counter: the
; bit loop exists twice, h_bit (line high before the bit) and l_bit (line low
; before the bit).  Because parity is even the line is high again before
; every preamble; the parity bit is whatever brings the line back high.
;
; Times in the comments are cycles; t = 0 is the start of the last bit of the
; 26-bit loop (U, time slot 29).  C starts at t = 16, P at t = 32, the next
; subframe's preamble at t = 48 and its first data bit at t = 112.

start:  pull                    ; wait for the first word; P0 still high
        set y, 25               ; frame counter + 1 for the first frame

; ---- right subframe done, or start: next frame, preamble B or M ----
adv:    set pins, 0             ; t=48  preamble cell 0
        jmp y-- stor_a           ; t=49  y = c - 1; falls through if c was 0
        set y, 31               ; t=50  c was 0 (so ISR = 0): build 191 in ISR
        in y, 5                 ; t=51
        set y, 5                ; t=52
        in y, 5                 ; t=53
        in null, 6              ; t=54  ISR = 31 + 5*32 = 191, 16 bits in: full
        jmp stor3               ; t=55  (y = 5, which is not 24: preamble M)
stor_a:  in y, 16      [5]       ; t=50  ISR = new c, full (left subframe)
stor3:  set x, 24     [15]      ; t=56
        set pins, 1             ; t=72  cell 3
        jmp x!=y pre_m [6]       ; t=73  new c = 24: first frame of a block
        set pins, 0             ; t=80  B: cell 4
        set x, 25     [6]       ; t=81  26 bits
        set pins, 1   [15]      ; t=88  B: cell 5
        jmp h_bit     [1]       ; t=104
pre_m:   set x, 25     [15]      ; t=80  26 bits
        set pins, 0   [7]       ; t=96  M: cell 6
        set pins, 1   [1]       ; t=104 M: cell 7

; ---- one bit, line high before it ----
h_bit:  out y, 1      [5]       ; t=-6
        set pins, 0             ; t=0   start of the bit: always a change
        jmp !y hz     [6]       ; t=1
        set pins, 1             ; t=8   a one changes again
        jmp x-- h_bit           ; t=9   (the last bit, U, is 0: no exit here)
hz:     jmp x-- l_bit [1]       ; t=8   a zero: the line stays low
; 26 bits sent, line low
        mov y, isr    [5]       ; t=10  y = c
        set pins, 1             ; t=16  C: start of the bit
        set x, 22               ; t=17
        jmp x!=y el_n            ; t=18
        jmp c1_l       [4]       ; t=19  c = 22: C = 1
el_n:    jmp !y c1_l    [4]       ; t=19  c = 0:  C = 1
                                ;       C = 0: line stays high, falls through
c1_h:    set pins, 1   [7]       ; t=24  C = 1 from low: back to high
p_h:     set pins, 0   [7]       ; t=32  line high before P: P = 1
        set pins, 1             ; t=40
        jmp tail                ; t=41

; ---- one bit, line low before it ----
l_bit:  out y, 1      [5]
        set pins, 1             ; t=0
        jmp !y lz     [6]       ; t=1
        set pins, 0             ; t=8
        jmp x-- l_bit           ; t=9   (never exits here either)
lz:     jmp x-- h_bit [1]       ; t=8   a zero: the line stays high
; 26 bits sent, line high
        mov y, isr    [5]       ; t=10  y = c
        set pins, 0             ; t=16  C: start of the bit
        set x, 22               ; t=17
        jmp x!=y eh_n            ; t=18
        jmp c1_h       [4]       ; t=19  c = 22: C = 1
eh_n:    jmp !y c1_h    [4]       ; t=19  c = 0:  C = 1
                                ;       C = 0: line stays low, falls through
c1_l:    set pins, 0   [7]       ; t=24  C = 1 from high: back to low
p_l:     set pins, 1   [9]       ; t=32  line low before P: P = 0

; ---- end of a subframe, line high ----
tail:   pull                    ; t=42  drop the 6 unused bits, take the next
                                ;       word; after the last frame this waits
                                ;       for ever with P0 high
        mov y, isr              ; t=43  y = c
        jmp !isrf adv [3]       ; t=44  not full: that was a right subframe
; ---- left subframe done: preamble W, then the right subframe ----
        set pins, 0             ; t=48  cell 0
        mov isr, y    [15]      ; t=49  same c, shift count 0: not full
        set x, 25     [6]       ; t=65  26 bits
        set pins, 1   [15]      ; t=72  cell 3
        set pins, 0   [7]       ; t=88  cell 5
        set pins, 1   [8]       ; t=96  cell 6
        jmp h_bit               ; t=105
