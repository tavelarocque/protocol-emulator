; Maple bus host transmitter, thread 0, 50 MHz.
; P0 = SDCKA, P1 = SDCKB, both push-pull. set pins writes both: value = A | B<<1.
; Config: set_base=0 set_count=2 threshold=16 out_msb_first=1 crc_poly=0x80.
; The CRC register with poly 0x80 is an 8-bit rotate whose bit 0 is XORed
; with each OUT bit: after whole bytes it holds the XOR checksum, bit-reversed.
; Every pin write is at least 12 cycles after the previous one.
; Y: words still to pull in this frame. X: current bit / loop counter.
; ISR count: 0 (not full) during header and data, 16 (full) during checksum.

frame:
    pull                  ; word 0: N | sender (waits while the host has none)
    mov x, osr            ; keep word 0
    mov isr, null
    set y, 1
    in y, 1               ; ISR = 0x8000
    out y, 8              ; Y = N
    in y, 8               ; ISR = N<<8 | 0x80
    in null, 7            ; ISR = 2N+1
    mov y, isr            ; Y = words left to pull: word 1 and 2N data words
    mov isr, null         ; ISR count 0: data phase
    mov osr, x            ; word 0 back in the OSR, full
    mov crc, null         ; checksum starts from 0 (out y, 8 above fed it)
; start pattern from (A,B) = (1,1)
    set pins 2 [10]       ; A-
    set x, 3
sp: set pins 0 [11]       ; B-
    set pins 2 [10]       ; B+
    jmp x-- sp
    set pins 3 [9]        ; A+
    jmp ev_bit            ; bit 0: its step 1 makes no change, skip it
; one even bit (clocked by A) then one odd bit (clocked by B)
pair:
    set pins 1 [9]        ; even step 1: A high, B is low
ev_bit:
    out x, 1
    jmp !x ev0
    set pins 3 [11]       ; step 2: B = 1
    set pins 2 [10]       ; step 3: A falls
    jmp odd
ev0:
    set pins 1 [11]       ; step 2: B = 0
    set pins 0 [11]       ; step 3: A falls
odd:
    set pins 2 [9]        ; odd step 1: B high, A is low
    out x, 1
    jmp !x od0
    set pins 3 [11]       ; step 2: A = 1
    set pins 1 [10]       ; step 3: B falls
    jmp !osre pair
    jmp wd
od0:
    set pins 2 [11]       ; step 2: A = 0
    set pins 0 [10]       ; step 3: B falls
    jmp !osre pair
wd: jmp y-- next_word     ; more words in this frame
    jmp !isrf cks         ; data done: send the checksum
; end pattern, from (A,B) = (v,0)
    set pins 1 [11]       ; A high if low
    set pins 3 [11]       ; B+
    set pins 1 [11]       ; B-
    set pins 0 [11]       ; A-
    set pins 1 [11]       ; A+
    set pins 0 [11]       ; A-
    set pins 1 [11]       ; A+
    set pins 3            ; B+
    set x, 31
idle: jmp x-- idle [3]    ; 128 cycles of idle before the next frame
    jmp frame
next_word:
    pull
    jmp pair
cks:
    mov osr, crc          ; checksum, bit-reversed, in bits 7..0
    out null, 8
    set x, 7
rev: out y, 1             ; bits c'7 .. c'0
    in y, 1               ; right shift: ISR[15:8] = checksum in order
    jmp x-- rev
    in null, 8            ; ISR = checksum; ISR count 16: full
    mov osr, isr
    out null, 8           ; checksum at the top, 8 bits left in the OSR
    set y, 0
    jmp pair
