; CAN FD (ISO) transmitter, thread 0.
;
; Pins: P0 the bus (open drain). P1 rate flag (1 nominal, 0 data rate).
;       P7..P2 dynamic stuff counter, 63 at SOF, minus 1 per stuff bit.
; Bit loop registers:
;   OSR  bits of the current segment, msb first, threshold 16
;   ISR  run state: count = 11 + run length (full = 5 equal bits),
;        value 0 exactly when the run is of zeros. Each IN feeds the CRC.
;   Y    header phase: control word [0 1 0 BRS][DLC][000000][1 IDE]
;        (bits 15..12: the RRS/IDE, FDF, res, BRS segment; bits 1..0: k)
;        data phase: number of data bytes still to load (0..16)
;   X    scratch
; A bit slot writes the line at offset 5 and lasts 25 cycles, plus 75 at
; W (a timed wait on P1) when the rate is nominal.
; Numbers in comments are cycle offsets in the slot.

; ================================================================ page 0
DDP:    jmp !y PHC                    ; 13  no data left: CRC field
DD:     jmp y-- DD2                   ; 14
DD2:    jmp !y HALF                   ; 15
        jmp y-- FULL                  ; 16
FULL:   pull                          ; 17  next data word
        jmp W [5]                     ; 18
HALF:   pull                          ; 16  last word holds one byte
        out x, 8                      ; 17
        mov osr, x                    ; 18
        out null, 8 [4]               ; 19
W:      wait 0 pin 1 timeout          ; 24  (timeout vector = LOOP)
LOOP:   jmp !isrf NORMAL              ; 0
STUFF:  mov x, isr                    ; 1   five equal bits: stuff slot
        mov isr, null                 ; 2
        jmp !x SZ [1]                 ; 3
SO:     set pins, 0                   ; 5   stuff 0 after ones
        in null, 12                   ; 6
        jmp DEC [1]                   ; 7
SZ:     set pins, 1                   ; 5   stuff 1 after zeros
        in pins, 12 [2]               ; 6
DEC:    mov x, pins                   ; 9   stuff counter minus 1
        jmp x-- d1                    ; 10
d1:     jmp x-- d2                    ; 11
d2:     jmp x-- d3                    ; 12
d3:     jmp x-- d4                    ; 13
d4:     mov pins, x                   ; 14
        jmp W [8]                     ; 15
NORMAL: mov x, isr                    ; 1
        jmp !x PZ                     ; 2
PO:     out x, 1                      ; 3   previous level 1
        jmp !x CH0                    ; 4
SAME:   in x, 1                       ; 5   same level, run grows
        jmp TL [2]                    ; 6
CH0:    set pins, 0                   ; 5   change to 0
        mov isr, null                 ; 6
        in null, 12                   ; 7
        jmp TL                        ; 8
PZ:     out x, 1                      ; 3   previous level 0
        jmp !x SAME                   ; 4
CH1:    set pins, 1                   ; 5   change to 1
        mov isr, null                 ; 6
        in pins, 12 [1]               ; 7
TL:     jmp !osre NE                  ; 9   segment used up?
        mov osr, y                    ; 10
        out x, 2                      ; 11
        jmp !x DDP                    ; 12
        set page, 1                   ; 13  header phase
        jmp HD                        ; 14
.page 0
NE:     jmp W [13]                    ; 10
; CRC field entry, offset 14 of the last data slot
PHC:    mov isr, pins                 ; 14  snapshot: stuff counter
        mov osr, pins                 ; 15
        out null, 14                  ; 16
        out y, 1                      ; 17  rate
        jmp !y PCF [7]                ; 18
        set y, 15                     ; 26  nominal: slot = 20 + 5 * 16
        set x, 17 [1]                 ; 27
PNL:    jmp x-- PNL [3]               ; 29
        set page, 2                   ; 101
        jmp FS0                       ; 102 -> 103
.page 0
PCF:    set page, 2                   ; 26  data rate: y = 0, slot 25
        jmp FS0                       ; 27 -> 28

; ================================================================ page 1
.align
.page 1
; Header dispatch: entered at offset 15, OSR = Y with 2 bits taken.
HD:     out null, 12                  ; 15
        out x, 2                      ; 16  k
        jmp x-- h1                    ; 17
h1:     jmp !x BRSD                   ; 18  k = 1: BRS just sent
        jmp x-- h2                    ; 19
h2:     jmp !x LOADF                  ; 20  k = 2
        pull                          ; 21  k = 3: second identifier word
        jmp y-- HRET [7]              ; 22
LOADF:  mov osr, y                    ; 21  segment RRS/IDE, FDF, res, BRS
        out x, 4                      ; 22
        mov osr, x                    ; 23
        out null, 12                  ; 24
        jmp y-- HRET [4]              ; 25
HRET:   set x, 15 [3]                 ; 30
HRL:    jmp x-- HRL [3]               ; 34
        set page, 0                   ; 98
        jmp LOOP                      ; 99
.page 1
BRSD:   mov osr, y                    ; 19
        out null, 3                   ; 20
        out x, 1                      ; 21  BRS
        jmp !x B0                     ; 22
        mov x, pins                   ; 23  P1 := 0, data rate
        jmp x-- b1                    ; 24
b1:     jmp x-- b2                    ; 25
b2:     mov pins, x                   ; 26
        set x, 9 [3]                  ; 27
B1L:    jmp x-- B1L [3]               ; 31
COMMON: mov osr, y                    ; 71 (BRS 1) or 86 (BRS 0)
        out null, 4
        out x, 4                      ; DLC
        mov osr, x
        out null, 11                  ; segment ESI, DLC
        mov y, x
        set x, 10                     ; bytes: 9 -> 12, 10 -> 16
        jmp x!=y N10
        set y, 16 [1]
J:      jmp END [1]
N10:    set x, 9
        jmp x!=y J
        set y, 12 [1]
END:    set page, 0
        jmp LOOP                      ; slot ends at 85 or 100
.page 1
B0:     set x, 14 [1]                 ; 23
        jmp B1L                       ; 25

; after the ACK slot (entered at ACK + 56 or + 57)
NACK:   set x, 9 [2]                  ; +56
NKL:    jmp x-- NKL [3]               ; +59
        set pins, 0                   ; +99  error flag
        set y, 22                     ; +100
NK1:    set x, 23
NK2:    jmp x-- NK2
        jmp y-- NK1
        set pins, 1                   ; +699
TAIL:   set y, 10                     ; SETUP - 1048
T1:     set x, 14
T2:     jmp x-- T2 [5]
        jmp y-- T1 [3]
        set page, 3
        jmp SETUP
.page 1
ACK:    set x, 9 [1]                  ; +57
AKL:    jmp x-- AKL [3]               ; +59
        jmp TAIL                      ; +99 -> TAIL at +100

; ================================================================ page 2
.align
.page 2
PAD:    nop
; Phase C slot: line written at offset 2, slot = 20 + 5 (Y + 1) cycles.
FS0:    mov x, pins                   ; 0   fixed stuff bit
        jmp x-- f0                    ; 1
f0:     mov pins, x                   ; 2
        mov osr, isr                  ; 3
        out null, 11                  ; 4
        out x, 1                      ; 5   m2
        jmp !x T0                     ; 6
        out x, 1                      ; 7   m1
        jmp !x T10                    ; 8
        out x, 1                      ; 9   m0
        jmp !x L110                   ; 10
        set x, 0                      ; 11  m = 7, n = 0
        jmp GC                        ; 12
L110:   set x, 3                      ; m = 6, n = 1
        jmp GC
T10:    out x, 1
        jmp !x L100
        set x, 6                      ; m = 5, n = 2
        jmp GC
L100:   set x, 5                      ; m = 4, n = 3
        jmp GC
T0:     out x, 1
        jmp !x T00
        out x, 1
        jmp !x L010
        set x, 12                     ; m = 3, n = 4
        jmp GC
L010:   set x, 15                     ; m = 2, n = 5
        jmp GC
T00:    out x, 1
        jmp !x L000
        set x, 10                     ; m = 1, n = 6
        jmp GC
L000:   set x, 9 [1]                  ; m = 0, n = 7
GC:     mov osr, x                    ; 13  Gray code and parity
        out null, 12                  ; 14
        mov x, y [4]                  ; 15
FL0:    jmp x-- FL0 [4]               ; 20
GL:     out x, 1 [1]                  ; 0   stuff count bit or parity
        mov pins, x                   ; 2
        in x, 1                       ; 3   into the CRC
        mov x, y [14]                 ; 4
GLD:    jmp x-- GLD [4]               ; 19
        jmp !osre GL                  ; 24
CF1:    mov x, pins                   ; 0   fixed stuff bit
        jmp x-- c1                    ; 1
c1:     mov pins, x                   ; 2
        mov isr, crc                  ; 3   CRC bits 16..1, bit 16 in bit 0
        jmp FMID                      ; 4
D:      mov x, y [1]                  ; 0   CRC bit
        mov pins, isr                 ; 2
        in null, 1                    ; 3
        out null, 1 [14]              ; 4
DL:     jmp x-- DL [4]                ; 19
        jmp !osre D                   ; 24
F:      mov x, pins                   ; 0   fixed stuff bit
        jmp x-- fa                    ; 1
fa:     mov pins, x [2]               ; 2
FMID:   mov osr, null                 ; 5   four CRC bits follow
        out null, 12                  ; 6
        mov x, y [11]                 ; 7
FLL:    jmp x-- FLL [4]               ; 19
        jmp !isrf D                   ; 24

; ================================================================ page 3
.page 3
C0S:    set page, 3                   ; 0   CRC bit 0
        mov isr, crc                  ; 1
        mov pins, isr [1]             ; 2
        mov x, y [15]                 ; 4
C0L:    jmp x-- C0L [4]               ; 20
DELIM:  mov x, y [1]                  ; 0   CRC delimiter
        set pins, 1                   ; 2
DLL:    jmp x-- DLL [3]               ; 3   ends at ACK - 36
        set x, 16
AL:     jmp x-- AL [4]
        mov x, pins                   ; ACK + 50: P0 low = acknowledged
        jmp x-- ak                    ; +51
ak:     in x, 1                       ; +52
        push                          ; +53
        set page, 1                   ; +54
        jmp !x NACK                   ; +55
        jmp ACK                       ; +56
.page 3
START:  set y, 19 [15]                ; 0   first SETUP at cycle 1948
        set page, 1 [15]              ; 16
        jmp T1 [13]                   ; 32
.page 3
SETUP:  pull                          ; 0   header word
        out x, 1                      ; 1   IDE
        in x, 1                       ; 2
        set x, 1                      ; 3
        in x, 1                       ; 4
        in null, 6                    ; 5
        out y, 1                      ; 6   BRS
        out null, 10                  ; 7
        out x, 4                      ; 8   DLC
        in x, 4                       ; 9
        in y, 1                       ; 10
        set x, 2                      ; 11
        in x, 3                       ; 12
        mov y, isr                    ; 13  control word
        mov osr, y                    ; 14
        out null, 15                  ; 15
        out x, 1                      ; 16  IDE
        pull                          ; 17  identifier (first) word
        jmp !x SBASE                  ; 18
        mov x, osr                    ; 19  extended: SOF ID28..18 SRR IDE ID17..16
        in x, 2                       ; 20
        set x, 3                      ; 21
        in x, 2                       ; 22
        out null, 3                   ; 23
        out x, 11                     ; 24
        in x, 11                      ; 25
        in null, 1                    ; 26
        mov osr, isr                  ; 27
        jmp SFIN                      ; 28
SBASE:  mov x, osr                    ; 19  base: SOF ID10..0 RRS (13 bits)
        in null, 1                    ; 20
        in x, 11                      ; 21
        in null, 4                    ; 22
        mov osr, isr                  ; 23
        out null, 3 [4]               ; 24
SFIN:   set x, 0                      ; 29
        jmp x-- s1                    ; 30
s1:     mov pins, x                   ; 31  all pins 1: rate nominal, counter 63
        mov isr, x                    ; 32  run state: previous level 1
        mov crc, null [10]            ; 33
        set page, 0                   ; 44
        jmp LOOP                      ; 45 -> LOOP at 46, SOF at 52
