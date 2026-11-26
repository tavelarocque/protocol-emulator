; Maple bus host transmitter, thread 0.
; P0 = SDCKA (A), P1 = SDCKB (B), both driven only by side-set.
; side value = A + 2*B : 3 = both high, 1 = A high B low, 2 = A low B high, 0 = both low.
; clkdiv 4: one tick = 4 cycles = 80 ns.
; Config: see run_args.txt (start = frame, timeout_vector = start pattern).

        .side_set 2

; ---------------- odd bit: SDCKB clocks, data on SDCKA. Entry: A low.
od:     out y, 1        side 2          ; step 1: B high (if low); take the bit (CRC sees it)
        jmp !y od0      side 2
        nop             side 3          ; step 2: A high (bit 1)
        nop             side 3
        jmp !osre ev    side 1          ; step 3: B falls. More bits in this word: next even bit
; ---------------- end of a 16-bit word (A high, B low)
wend:   jmp !isrf fin   side 1          ; ISR not full: checksum was just sent: end pattern
        jmp x-- nx      side 1          ; more words to pull
; ---------------- checksum: CRC holds bitreverse8(checksum) in bits 7..0
ck:     mov osr, crc    side 1          ; OSR = r (reading stops the CRC)
        out null, 8     side 1          ; skip the 8 zero bits above r
        mov crc, null   side 1          ; restart the CRC from 0
        out null, 1     side 1          ; feed r7 .. r0: CRC becomes bitreverse8(r) = checksum
        out null, 1     side 1
        out null, 1     side 1
        out null, 1     side 1
        out null, 1     side 1
        out null, 1     side 1
        out null, 1     side 1
        out null, 1     side 1
        mov osr, crc    side 1          ; OSR = checksum in bits 7..0
        out null, 8     side 1          ; checksum to bits 15..8, 8 bits left before empty
        mov isr, null   side 1          ; flag: ISR not full = checksum being sent
; ---------------- even bit: SDCKA clocks, data on SDCKB. Entry: B low.
ev:     out y, 1        side 1          ; step 1: A high (if low); take the bit
        jmp !y ev0      side 1
ev1:    nop             side 3          ; step 2: B high (bit 1)
        nop             side 3
        jmp od          side 2          ; step 3: A falls
; ---------------- start pattern (entered from the idle wait's timeout)
start:  mov x, isr      side 2          ; A falls. X = 2N+1 words still to pull
        set y, 3        side 2
sp:     nop             side 0          ; B falls
        nop             side 0
        nop             side 0
        nop             side 2          ; B rises
        nop             side 2
        jmp y-- sp      side 2          ; four low pulses on B
        out y, 1        side 3          ; A rises. Bit 0 of the frame (even, B already high)
        jmp y-- ev1     side 3          ; bit 0 = 1: B stays high, go on as an even bit
        nop             side 1          ; bit 0 = 0: B falls here, then as an even bit
ev0:    nop             side 1          ; step 2 for bit 0 (B already low)
        nop             side 0          ; step 3: A falls
        jmp od          side 0
od0:    nop             side 2          ; step 2 for bit 0 (A already low)
        nop             side 0          ; step 3: B falls
        jmp !osre ev    side 0
        jmp wend        side 1          ; end of word: A rises now (it would at the next bit anyway)
nx:     pull            side 1
        jmp ev          side 1
; ---------------- end pattern. Entry: A high, B low (just fell)
fin:    set x, 1        side 1
        nop             side 3          ; B rises
        mov crc, null   side 3          ; restart the CRC for the next frame
        nop             side 3
        nop             side 1          ; B falls
        nop             side 1
ep:     nop             side 0          ; A falls
        nop             side 0
        nop             side 0
        nop             side 1          ; A rises
        nop             side 1
        jmp x-- ep      side 1          ; two low pulses on A
; ---------------- frame setup (thread start). Idle: both high.
frame:  pull            side 3          ; B rises (end pattern) / wait for word 0 while idle
        mov isr, osr    side 3          ; ISR = N:sender
        in null, 8      side 3          ; ISR = N (shift right)
        mov x, isr      side 3          ; X = N
        in pins, 1      side 3          ; a 1 (P0 is high)
        in x, 8         side 3
        in null, 7      side 3          ; ISR = 2N+1
        wait 0 pin 0 timeout side 3     ; idle gap; P0 stays high so it times out to `start`
