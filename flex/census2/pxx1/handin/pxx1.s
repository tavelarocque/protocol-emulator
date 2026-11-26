; FrSky PXX1 transmitter for the protocol emulator, thread 0, line on P0.
; Clock divider 25: one tick = 0.5 us. A bit's low pulse is 16 ticks,
; a 0 lasts 32 ticks and a 1 lasts 48 ticks.
;
; Every page holds the same 11-word bit loop at offsets 0..10, so jumps by
; number (jmp 5, jmp 10) land in whatever page PAGE selects. The page and
; the ISR's shift count (via !isrf) pick the code that loads the next chunk
; when the OSR runs empty (threshold 16; short chunks are pre-shifted).
;
; Bit timeline (ticks from the bit's falling edge, n0):
;   n3  jmp !osre: chunk continues, or the page's loader runs (n4..n28)
;   n16 rise
;   n29 jmp !x: X = 0 means a stuffed 0 is due
;   n32 out pins,1: a 0 is the next falling edge; a 1 keeps P0 high and
;       the wait times out into VEC, which pulls P0 low at n48
; X counts the 1s still allowed before a stuffed 0 (5 after any 0).
; ISR holds [extra flags | pair counter | a>>8] from word 1 onwards.

; ---------------- page 0 ----------------
.page 0
        set x, 5 [1]            ; 0  stuffed bit: n30
        set pins, 0             ; 1  n32 = next n0
        jmp 10 [1]              ; 2  n1..n2
        nop [11]                ; 3  n4..n15
        set pins, 1 [12]        ; 4  n16 rise
        jmp !x 0                ; 5  n29
        nop [1]                 ; 6  n30
        out pins, 1             ; 7  n32
        wait 0 pin 0 timeout    ; 8  n33
        set x, 5                ; 9  n2 (after a 0)
        jmp !osre 3             ; 10 n3
; chunk ended in page 0: word 0 (ISR count < 16) or extra flags (>= 16)
        jmp !isrf p0w1          ; n4
        mov osr, null           ; n5  CRC chunk (placeholder: 16 zero bits)
        mov isr, isr [9]        ; n6  ISR count 0 marks the CRC chunk
        set pins, 1 [10]        ; n16
        set page, 1             ; n27
        jmp 5                   ; n28
.page 0
p0w1:   pull                    ; n5  word 1 = [extra | flag2]
        mov isr, osr            ; n6
        in null, 4              ; n7  [0 | extra | f2>>4]
        set y, 3                ; n8  pairs left after the first
        in y, 4                 ; n9  [3 | 0 | extra]
        mov y, isr              ; n10
        in y, 8                 ; n11 rotate: [extra | 3 | 0], count 16
        out null, 8 [3]         ; n12 OSR = [flag2 | 0], 8 bits to send
        set pins, 1 [10]        ; n16
        set page, 1             ; n27
        jmp 5                   ; n28

; ---------------- page 1 ----------------
.align
        set x, 5 [1]
        set pins, 0
        jmp 10 [1]
        nop [11]
        set pins, 1 [12]
        jmp !x 0
        nop [1]
        out pins, 1
        wait 0 pin 0 timeout
        set x, 5
        jmp !osre 3
; chunk ended in page 1: flag 2 (count >= 16) or CRC (< 16)
        jmp !isrf p1cl          ; n4
        pull                    ; n5  channel a
        out null, 4             ; n6
        out y, 4                ; n7  Y = a>>8; OSR = [a & 0xFF | 0]
        in y, 4                 ; n8  [a>>8 | extra | cnt]
        mov y, isr              ; n9
        in y, 12 [5]            ; n10 rotate: [extra | cnt | a>>8]
        set pins, 1 [10]        ; n16
        set page, 2             ; n27
        jmp 5                   ; n28
.page 1
p1cl:   jmp !x p1cs             ; n5  stuffed 0 still due after the CRC?
        nop [9]                 ; n6
        set pins, 1 [14]        ; n16 this bit is the closing flag's first 0
        set y, 5                ; n31
p1f1:   set pins, 0 [15]        ; six 1s
        set pins, 1 [15]
        nop [14]
        jmp y-- p1f1
        set pins, 0 [15]        ; last 0
        set pins, 1             ; line stays high from here
gap:    set x, 20               ; idle between frames
g1:     set y, 31
g2:     jmp y-- g2 [15]
        jmp x-- g1 [15]
frame:  pull                    ; word 0; blocks (line high) when words run out
        mov isr, osr
        mov y, isr
        in y, 8                 ; [w0 & 0xFF | w0 >> 8], count 8
        mov osr, isr
        set pins, 0 [15]        ; header 0x7E, not stuffed
        set pins, 1 [14]
        set y, 5
p1h1:   set pins, 0 [15]
        set pins, 1 [15]
        nop [14]
        jmp y-- p1h1
        set pins, 0 [15]
        set pins, 1 [14]
        set page, 0
        set pins, 0             ; first data bit, n0
        set x, 5                ; n1
        jmp 10                  ; n2 -> page 0 offset 10 at n3
.page 1
p1cs:   nop [9]                 ; n6  this bit is the stuffed 0
        set pins, 1 [15]        ; n16
        set pins, 0 [15]        ; n32 closing flag's first 0
        set pins, 1 [13]        ; n48
        set y, 5                ; n62
        jmp p1f1                ; n63

; ---------------- page 2 ----------------
.align
        set x, 5 [1]
        set pins, 0
        jmp 10 [1]
        nop [11]
        set pins, 1 [12]
        jmp !x 0
        nop [1]
        out pins, 1
        wait 0 pin 0 timeout
        set x, 5
        jmp !osre 3
; chunk ended in page 2: a & 0xFF (count >= 16) or b & 0xF (< 16)
        jmp !isrf p2b2          ; n4
        pull                    ; n5  channel b
        out null, 4             ; n6
        out y, 8                ; n7  Y = b>>4; OSR = [b & 0xF | 0], 4 bits
        mov isr, isr [7]        ; n8  count 0
        set pins, 1 [10]        ; n16
        set page, 2             ; n27
        jmp 5                   ; n28
.page 2
p2b2:   mov osr, isr            ; n5  [extra | cnt | a>>8]
        out null, 12 [9]        ; n6  OSR = [a>>8 | 0], 4 bits
        set pins, 1 [10]        ; n16
        set page, 3             ; n27
        jmp 5                   ; n28

; ---------------- page 3 ----------------
.align
        set x, 5 [1]
        set pins, 0
        jmp 10 [1]
        nop [11]
        set pins, 1 [12]
        jmp !x 0
        nop [1]
        out pins, 1
        wait 0 pin 0 timeout
        set x, 5
        jmp !osre 3
; chunk ended in page 3: a >> 8 (count < 16) or b >> 4 (>= 16)
        jmp !isrf p3b3          ; n4
        mov y, isr              ; n5
        in y, 4                 ; n6  [a>>8 | extra | cnt]
        mov osr, isr            ; n7
        out null, 12            ; n8
        out y, 4                ; n9  Y = cnt
        jmp y-- p3mo            ; n10 more pairs?
        mov y, isr              ; n11 no: extra flags next
        in y, 4                 ; n12 [cnt | a>>8 | extra]
        mov osr, isr            ; n13
        out null, 8 [1]         ; n14 OSR = [extra | 0], 8 bits
        set pins, 1 [10]        ; n16
        set page, 0             ; n27
        jmp 5                   ; n28
.page 3
p3mo:   in y, 4                 ; n11 [cnt-1 | a>>8 | extra]
        mov y, isr              ; n12
        in y, 8                 ; n13 [extra | cnt-1 | a>>8]
        pull                    ; n14 next channel a
        out null, 4             ; n15
        set pins, 1             ; n16
        out y, 4                ; n17
        in y, 4                 ; n18
        mov y, isr              ; n19
        in y, 12 [6]            ; n20 [extra | cnt-1 | a>>8]
        set page, 2             ; n27
        jmp 5                   ; n28
.page 3
p3b3:   mov osr, y              ; n5  Y = b>>4
        out null, 8             ; n6  OSR = [b>>4 | 0], 8 bits
        mov y, isr              ; n7
        in y, 16 [7]            ; n8  count 16, contents unchanged
        set pins, 1 [10]        ; n16
        set page, 3             ; n27
        jmp 5                   ; n28
vec:    set pins, 0             ; timeout vector: a 1 ended, n48 = next n0
        jmp x-- 10 [1]          ; n1..n2, X >= 1 here so always taken
