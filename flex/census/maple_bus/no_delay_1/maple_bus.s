; Maple bus host transmitter, thread 0.
; P0 = SDCKA (A), P1 = SDCKB (B). set pins writes both: value = A + 2*B.
; Config (run_args.txt): set_base=0 set_count=2 threshold=16 out_msb_first=1
;   clkdiv=2 crc_poly=0x80 crc_init=0. One instruction = 2 cycles = 40 ns.
; Rule used for timing: consecutive "set pins" writes inside a frame are at
; least 4 instructions (8 cycles) apart, and they alternate between lines,
; so the same line is never written twice within 8 instructions (16 cycles).
; The CRC register with poly 0x80 is an 8-bit ring: it accumulates the XOR
; of all bytes fed by OUT, bit-reversed (bit 0 = checksum bit 7).

; ---------------- page 0: frame start and start pattern ----------------
frame:
        pull                    ; word 0 (N, sender); waits here when idle
        mov crc, null           ; checksum accumulator restarts from 0
        ; start pattern: A- B- B+ B- B+ B- B+ B- B+ A+
        set pins, 2             ; A-
        set y, 3                ; four B pulses
sp:     set x, 3
sd1:    jmp x-- sd1             ; 3 instructions
        set pins, 0             ; B-
        set x, 4
sd2:    jmp x-- sd2             ; 4 instructions
        set pins, 2             ; B+
        jmp y-- sp
        nop
        nop
        set pins, 3             ; A+ (both high)
        ; Y = 2N + 1 = words left after word 0 (ISR shifts right, new bits on top)
        mov isr, osr
        in null, 8              ; ISR = N
        mov x, isr
        set y, 1
        in y, 1                 ; ISR bit 15 = 1
        in x, 15                ; ISR = (ISR >> 15) | (N << 1) = 2N + 1
        mov y, isr
        mov isr, null           ; ISR count 0: data phase (checksum not sent)
        set page, 1
        jmp 1                   ; pair (page 1, word 1)

        .page 0
endp0:
        ; end pattern: A+ (if low), B+, B-, A-, A+, A-, A+, B+
        set pins, 1             ; A high
        set x, 1
e1:     jmp x-- e1
        set pins, 3             ; B+
        set x, 4
e2:     jmp x-- e2
        set pins, 1             ; B-
        set x, 1
e3:     jmp x-- e3
        set pins, 0             ; A-
        set x, 4
e4:     jmp x-- e4
        set pins, 1             ; A+
        set x, 4
e5:     jmp x-- e5
        set pins, 0             ; A-
        set x, 4
e6:     jmp x-- e6
        set pins, 1             ; A+
        set x, 1
e7:     jmp x-- e7
        set pins, 3             ; B+ : idle
        ; idle gap: at least 66 more instructions before the next frame
        set x, 31
i1:     jmp x-- i1
        set x, 31
i2:     jmp x-- i2
        jmp frame

        .align
; ---------------- page 1: bits, checksum, end pattern ----------------
; Bits come in pairs: an A-clocked bit (data on B), then a B-clocked bit
; (data on A). Before an A bit the lines are (A=1,B=0), or (1,1) at frame start.
T:      set pins, 1             ; A rises (step 1 of the A bit)
pair:   out x, 1                ; d (fed to CRC)
        jmp !x a0
        nop
        set pins, 3             ; step 2: B = 1
        set x, 1
w1:     jmp x-- w1
        set pins, 2             ; step 3: A falls
        jmp bb
a0:     nop
        set pins, 1             ; step 2: B = 0
        set x, 1
w2:     jmp x-- w2
        set pins, 0             ; step 3: A falls
        nop
bb:     out x, 1                ; e (fed to CRC)
        nop
        set pins, 2             ; step 1: B rises (A=0)
        jmp !x b0
        nop
        nop
        set pins, 3             ; step 2: A = 1
        set x, 1
w3:     jmp x-- w3
        set pins, 1             ; step 3: B falls
        jmp !osre tpair
        jmp !isrf dataw
        jmp endp
b0:     nop
        nop
        set pins, 2             ; step 2: A = 0 (no change)
        set x, 1
w4:     jmp x-- w4
        set pins, 0             ; step 3: B falls
        jmp !osre tpair
        jmp !isrf dataw
endp:   set page, 0
        jmp endp0
        .page 1
dataw:  jmp y-- nwrd            ; more data words?
        ; all data sent: checksum. CRC low byte = checksum bit-reversed.
        mov osr, crc            ; also stops the CRC
        out null, 8             ; OSR top byte = reversed checksum
        set y, 7
rv:     out x, 1                ; bit-reverse into ISR (shifts right)
        in x, 1
        jmp y-- rv
        in null, 8              ; ISR = checksum, ISR count 16: flag "sent"
        mov osr, isr
        out null, 8             ; OSR top = checksum, 8 bits to go
        jmp T
nwrd:   pull
tpair:  nop
        nop
        jmp T
