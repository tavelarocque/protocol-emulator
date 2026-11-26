; Maple bus host transmitter, thread 0, 50 MHz.
; P0 = SDCKA, P1 = SDCKB. set pins writes both: value = A + 2*B.
; Config: set_base=0 set_count=2 threshold=16 out_msb_first=1 crc_poly=0x80 crc_init=0
;
; The CRC register with polynomial 0x80 (x^8 + 1, low power first) is an
; 8-bit rotate-and-XOR: after whole bytes it holds the XOR of all bytes fed,
; bit-reversed. Every frame bit goes through "out x, 1", which feeds it.
;
; Line coding: every set pins instruction carries [11], so any two writes
; are at least 12 cycles apart (limits: 12 same line, 7 other line).
; Even bit v (clock A, data B), entered with A high:
;   v=1: 3 (B up), 2 (A down)      v=0: 1 (B down if high), 0 (A down)
; Odd bit v (clock B, data A), entered with A low:
;   2 (B up), then v=1: 3 (A up), 1 (B down)
;                  v=0: 0 (B down), 1 (A up: step 1 of the next even bit,
;                       or the first step of the end pattern)

start:
        set x, 7
idle:   jmp x-- idle [15]       ; 128 cycles of idle before every frame
        pull                    ; word 0: N << 8 | sender
        mov x, osr
        mov isr, null
        out y, 8                ; Y = N (this feeds the CRC; restarted below)
        mov osr, x              ; word 0 back in the OSR, shift count reset
        set x, 1
        in x, 1                 ; ISR shifts right, bits enter at the top
        in y, 8
        in null, 7              ; ISR = 2N + 1
        mov y, isr              ; Y = words still to come after word 0
        mov isr, null           ; ISR count 0: marks the data phase
        mov crc, null           ; restart the checksum
        ; start pattern from idle (1,1)
        set pins 2 [11]         ; A-
        set pins 0 [11]         ; B-
        set pins 2 [11]         ; B+
        set pins 0 [11]         ; B-
        set pins 2 [11]         ; B+
        set pins 0 [11]         ; B-
        set pins 2 [11]         ; B+
        set pins 0 [11]         ; B-
        set pins 2 [11]         ; B+
        set pins 3 [11]         ; A+
pair:
        out x, 1                ; even bit
        jmp !x e0
        set pins 3 [11]
        set pins 2 [11]
        jmp odd
e0:     set pins 1 [11]
        set pins 0 [11]
odd:    out x, 1                ; odd bit
        set pins 2 [11]
        jmp !x o0
        set pins 3 [11]
        jmp oc
o0:     set pins 0 [11]
oc:     set pins 1 [11]
        jmp !osre pair
        ; word (or checksum) done
        jmp !isrf dataw         ; ISR not full: still in the data phase
        ; end pattern from (1,0)
        set pins 3 [11]         ; B+
        set pins 1 [11]         ; B-
        set pins 0 [11]         ; A-
        set pins 1 [11]         ; A+
        set pins 0 [11]         ; A-
        set pins 1 [11]         ; A+
        set pins 3 [11]         ; B+
        jmp start
dataw:  jmp y-- nextword
        ; all words sent: build the checksum byte from the CRC register
        mov isr, null
        mov osr, crc            ; OSR = 0x00RR, RR = checksum bit-reversed
        out null, 8
rev:    out x, 1                ; R7 first ... R0 last
        in x, 1
        jmp !osre rev           ; ISR[15:8] = checksum
        in null, 8              ; ISR = checksum, count 16 (full: checksum phase)
        mov osr, isr
        out null, 8             ; 8 bits left to send
        jmp pair
nextword:
        pull
        jmp pair
