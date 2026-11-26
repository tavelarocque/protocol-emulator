; SD card bus (SD mode) host, command channel only. Thread 0, clkdiv=10.
; One tick = 10 cycles. Each CLK period (40 cycles) is 4 ticks:
;   F = falling edge tick (side 0), M = CMD may change (side 0),
;   R = rising edge tick (side 1, also where CMD is sampled), H = high (side 1).
; Slot n (rising edge n) has F at tick 18+4n, M 19+4n, R 20+4n, H 21+4n.
.side_set 1
; ---- reset: CLK high for ticks 0..17, X = 79 (80 init clocks) ----
        set x, 19       side 1 [7]
        in x, 5         side 1 [6]      ; ISR = 10011
        in x, 2         side 1          ; ISR = 1001111 = 79
        mov x, isr      side 1
gH:     jmp gF          side 1          ; H tick of an idle clock
r2f:    jmp r2l         side 0 [1]      ; F,M of R2 header skip
bF:     jmp bR          side 0 [1]      ; F,M of a receive bit
vec:    jmp srch        side 1          ; timeout_vector: H tick, CMD still high
r1:     set y, 9        side 0          ; F: R1 = 10 groups of 5 bits
wnext:  mov x, osr      side 0          ; M: reload inner count
bR:     in pins, 1      side 1          ; R: sample CMD (autopush every 16)
        jmp x-- bF      side 1          ; H
        jmp y-- wnext   side 0          ; F
tail:   mov x, osr      side 0          ; M: idle clocks after a response
gR:     jmp x-- gH      side 1          ; R: idle clock loop
gapend: pull            side 1          ; H of the 8th idle clock: word 1 (stalls if none)
        out y, 8        side 0          ; F_s: Y = response type
        set pins, 0     side 0          ; M_s: start bit
        out null, 2     side 1 [1]      ; R_s,H_s
        mov crc, null   side 0          ; F: CRC register = 0x48 (state after "01")
        set pins, 1     side 0          ; M: transmission bit
        set x, 2        side 1          ; R: two more words to pull
Lfull:  nop             side 1          ; H
        jmp L2          side 0          ; F
apull:  pull            side 0          ; F (OSR was empty)
L2:     out pins, 1     side 0          ; M: index / argument bit
        jmp !osre Lfull side 1          ; R
        jmp x-- apull   side 1          ; H
        mov isr, crc    side 0          ; F: ISR = CRC7, bit0 = its MSB
        mov pins, isr   side 0          ; M: CRC bit 6
        mov osr, isr    side 1 [1]
        out null, 14    side 0
        out pins, 1     side 0          ; CRC bit 5
        mov osr, isr    side 1 [1]
        out null, 13    side 0
        out pins, 1     side 0          ; CRC bit 4
        mov osr, isr    side 1 [1]
        out null, 12    side 0
        out pins, 1     side 0          ; CRC bit 3
        mov osr, isr    side 1 [1]
        out null, 11    side 0
        out pins, 1     side 0          ; CRC bit 2
        mov osr, isr    side 1 [1]
        out null, 10    side 0
        out pins, 1     side 0          ; CRC bit 1
        mov osr, isr    side 1 [1]
        out null, 9     side 0
        out pins, 1     side 0          ; CRC bit 0
        set x, 7        side 1 [1]      ; 8 idle clocks if no response
        in null, 9      side 0          ; F_e: ISR count 9 (R1 header alignment)
        set pins, 1     side 0          ; M_e: end bit
        jmp y-- srch    side 1 [1]      ; R_e,H_e: response? Y becomes type-1
gF:     jmp gR          side 0 [1]      ; F,M of an idle clock
srch:   set x, 4        side 0          ; F
        mov osr, x      side 0          ; M: OSR = 4 (R1 inner count)
        wait 0 pin 1 timeout side 1     ; R: CMD high -> vec
        jmp !y r1       side 1          ; H: start bit found
        mov isr, null   side 0          ; F: R2
        set x, 7        side 0          ; M
        mov osr, x      side 1          ; R: R2 = 16 groups of 8 bits
        set y, 15       side 1          ; H
        set x, 5        side 0 [1]      ; F,M
r2l:    jmp x-- r2f     side 1 [1]      ; R,H
        jmp wnext       side 0          ; F
