; USB Power Delivery BMC transmitter on P0, thread 0, 20 MHz, every cycle.
; One bit = 66 cycles, half bit = 33. All timing is by instruction counts.
;
; Registers in the data part of a packet:
;   ISR  the 16-bit word being sent, rotated right 4 bits per symbol by the
;        CRC feed (in x,1 x4). Its shift count counts nibbles: full = word done.
;   OSR  copy of ISR while decoding, then the symbol's bits c1..c4 plus a
;        sentinel 1 above them (the serializer stops when OSR == 1).
;   Y    countdown: 8N+3 after the header, -4 per data word; 3,2,1,0 select
;        CRC low, CRC high, EOP, closing.
;   X    scratch. A toggle of P0 is  mov x,pins / jmp x--,+1 / mov pins,x
;        (decrementing flips bit 0 whatever the other pins read).
; In the preamble and Sync-1 X instead holds the line level in bit 0.
; Config: threshold=16 crc_in=1 crc_poly=0xEDB88320 crc_init=0xFFFFFFFF crc_invert=1

; ------------------------------------------------------------ page 0
start:  set pins, 0                 ; line low at cycle 1
gap:    set x, 31 [15]
gl:     jmp x--, gl [15]            ; 512 cycles of silence
pkt:    pull                        ; first word: kind, count (stalls when no more)
        mov isr, null
        set x, 3
        in x, 3                     ; bits 0..2 = 1,1,0
        out y, 2                    ; Y = kind
        out x, 3                    ; X = N
        in x, 3
        in null, 10                 ; ISR = 8N+3
        mov x, isr
        mov isr, null               ; count 0 for the SOP chunk
        jmp !y, kind0
        jmp y--, kk
kk:     jmp !y, kind1
kind2:  set y, 3                    ; K2 = Sync-3, bits c1..c4
        in y, 4
        set y, 24                   ; K3 = Sync-1
        in y, 5
k4s3:   set y, 6                    ; K4 = Sync-3
        in y, 5
ksent:  set y, 1                    ; sentinel then a 0: chunk is bits 0..14
        in y, 2
        mov osr, x                  ; keep 8N+3 in OSR during the preamble
        set x, 0                    ; level parity: line is low
        set y, 31                   ; 32 preamble pairs
        set page, 3
.page 3
        jmp pp
.page 0
kind1:  set y, 12                   ; K2 = Sync-1
        in y, 4
        set y, 6                    ; K3 = Sync-3
        in y, 5
        jmp k4s3
kind0:  set y, 12                   ; K2 = Sync-1
        in y, 4
        set y, 24                   ; K3 = Sync-1
        in y, 5
        set y, 17                   ; K4 = Sync-2
        in y, 5
        jmp ksent

; ------------------------------------------------------------ page 1
.align
; serializer: one bit per pass, 66 cycles, start transition at s2
ser:    mov x, osr
        jmp x--, s1
s1:     jmp !x, symdone             ; OSR == 1: only the sentinel is left
        nop [12]                    ; = dispatch time of symdone paths
ser_t:  mov x, pins
        jmp x--, s2
s2:     mov pins, x [15]            ; bit start
        out x, 1 [13]
        jmp !x, s0
        mov x, pins
        jmp x--, s3
s3:     mov pins, x [13]            ; mid-bit transition of a 1
        jmp ser
s0:     nop [14]
        jmp ser [1]
; after a symbol: every path reaches its head 13 cycles after symdone
symdone: jmp !isrf, dpad            ; nibbles left in this word
        jmp !y, endp                ; Y=0: closing transition
        jmp y--, wa
wa:     jmp !y, eopp                ; was 1: EOP
        jmp y--, wb
wb:     jmp !y, crc1                ; was 2: CRC high half
        jmp y--, wc
wc:     jmp !y, crc2                ; was 3: CRC low half
        jmp y--, pullp              ; else next data word, Y -= 4
pullp:  pull
        mov isr, osr [1]
        jmp dhead
crc2:   set y, 2
        jmp crcw
crc1:   set y, 1 [3]
crcw:   mov x, crc                  ; first read freezes it, second gives high half
        mov isr, x
        jmp dhead
eopp:   nop [8]
        mov x, pins
        jmp x--, e1
e1:     mov pins, x [15]            ; EOP c0 = 1: start
        set x, 22 [13]              ; c1..c4 = 0,1,1,0 + sentinel
        mov osr, x
        mov x, pins
        jmp x--, e2
e2:     mov pins, x [15]            ; mid
        jmp ser_t [14]
endp:   nop [10]
        mov x, pins
        jmp x--, en1
en1:    mov pins, x [15]            ; closing transition
        nop [15]
        nop
        set pins, 0                 ; 33 later: fall if it left the line high
        set page, 0
.page 0
        jmp gap
.page 1
dpad:   nop [11]
; data symbol head: c0 = n0, then decode the nibble into OSR = c1..c4 + sentinel
dhead:  mov x, pins
        jmp x--, dh1
dh1:    mov pins, x [15]            ; c0 start
        mov osr, isr [1]
        set page, 2
        out x, 1                    ; feed n0..n3 to the CRC, rotating ISR
        in x, 1
        out x, 1
        in x, 1
        out x, 1
        in x, 1
; ------------------------------------------------------------ page 2 (fall through)
.page 2
        out x, 1
        in x, 1
        mov osr, isr                ; nibble now at bits 12..15
        out null, 12
        out x, 1                    ; n0
        jmp !x, dz
        mov x, pins
        jmp x--, dh2
dh2:    mov pins, x                 ; mid of c0 when n0 = 1
        jmp dm
dz:     nop [3]
dm:     out x, 1                    ; n1
        jmp !x, n1z
        out x, 1                    ; n2
        jmp !x, n10
        out x, 1                    ; n3
        jmp !x, m3
        set x, 30 [4]               ; E,F
        jmp L
m3:     set x, 23 [4]               ; 6,7
        jmp L
n10:    out x, 1
        jmp !x, m1
        set x, 27 [4]               ; A,B
        jmp L
m1:     set x, 26 [4]               ; 2,3
        jmp L
n1z:    out x, 1                    ; n2
        jmp !x, n00
        out x, 1                    ; n3
        jmp !x, m2
        set x, 29 [4]               ; C,D
        jmp L
m2:     set x, 21 [4]               ; 4,5
        jmp L
n00:    out x, 1
        jmp !x, m0
        set x, 25 [4]               ; 8,9
        jmp L
m0:     mov osr, isr                ; 0 or 1: look at n0 again
        out null, 12
        out x, 1
        jmp !x, nib0
        set x, 20                   ; 1
        jmp L
nib0:   set x, 31 [1]               ; 0
L:      mov osr, x
        set page, 1
.page 1
        jmp ser_t [14]

; ------------------------------------------------------------ page 3
.align
.page 3
; preamble: 32 pairs (0,1). X bit 0 is the level, decremented per transition.
pp:     jmp x--, p1 [1]
p1:     mov pins, x [15]            ; bit 2k start
        nop [15]
        nop [15]
        nop [15]
        jmp x--, p2 [1]
p2:     mov pins, x [15]            ; bit 2k+1 start
        nop [15]
        jmp x--, p3
p3:     mov pins, x [15]            ; its mid
        nop [13]
        jmp y--, pp
; Sync-1 = 0,0,0,1,1 then K2's c0 = 0
        set y, 2
        jmp x--, z1
zl:     jmp x--, z1 [1]
z1:     mov pins, x [15]
        nop [15]
        nop [15]
        nop [14]
        jmp y--, zl
        jmp x--, o1 [1]
o1:     mov pins, x [15]
        nop [15]
        jmp x--, o2
o2:     mov pins, x [15]
        nop [15]
        jmp x--, o3
o3:     mov pins, x [15]
        nop [15]
        jmp x--, o4
o4:     mov pins, x [15]
        nop [15]
        jmp x--, o5
o5:     mov pins, x [15]            ; K2 c0 start
        mov y, osr [15]             ; Y = 8N+3
        pull                        ; header
        mov x, osr [15]
        mov osr, isr [10]           ; SOP chunk: K2 c1..c4, K3, K4, sentinel
        mov isr, x                  ; header, count 0
        mov crc, null               ; CRC starts here
        set page, 1
.page 1
        jmp ser_t
