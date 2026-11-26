; AVR PDI programmer, thread 0, clkdiv 25: one tick = 25 cycles = half a PDI slot.
; Every instruction is one half slot: side 0 = low half (L), side 1 = high half (H).
; P0 = PDI_CLK (side-set), P1 = PDI_DATA (open drain, set/out/mov pins).
; Parity comes from the CRC register (poly 1, init 0): bit 0 = XOR of the bits OUT sent.
        .side_set 1
; ---- before slot 0: P0 high, P1 released (80 ticks in all)
start:  wait 0 pin 0 timeout  side 1    ; P0 is 1, so this times out to `pre`
pre:    pull                  side 1    ; first word
        mov isr, osr          side 1
        in null, 15           side 1    ; ISR = word >> 15 = end flag
        mov x, isr            side 1    ; X = end flag
        set y, 15             side 1
; ---- enable: 16 idle slots
en:     nop                   side 0
        jmp y-- en            side 1
; ---- one frame of the chip (12 slots); OSR = word, X = its end flag
nf:     mov pins, x           side 0    ; s0 L: start bit 0 (or 1 = released if end word)
        jmp x-- endp          side 1    ; s0 H: end word -> end
        out pins, 1           side 0    ; s1 L: data bit 0
        mov isr, osr          side 1    ; s1 H: ISR = word >> 1
        out pins, 1           side 0    ; s2 L
        in null, 7            side 1    ; s2 H: ISR = word >> 8 = answer length
        out pins, 1           side 0    ; s3 L
        mov y, isr            side 1    ; s3 H: Y = answer length
        out pins, 1           side 0    ; s4 L
        nop                   side 1
        out pins, 1           side 0    ; s5 L
        nop                   side 1
        out pins, 1           side 0    ; s6 L
        nop                   side 1
        out pins, 1           side 0    ; s7 L
        nop                   side 1
        out pins, 1           side 0    ; s8 L: data bit 7, autopull loads the next word
        mov isr, osr          side 1    ; s8 H
        mov pins, crc         side 0    ; s9 L: parity
        in null, 15           side 1    ; s9 H: ISR = next word's end flag
        set pins, 1           side 0    ; s10 L: stop bit 1
        mov x, isr            side 1    ; s10 H: X = next word's end flag
        mov crc, null         side 0    ; s11 L: stop bit 2, restart parity
        jmp !y nf             side 1    ; s11 H: no answer -> next frame
; ---- guard time: 128 idle slots (1 + 32 passes of 8 ticks, last tick is the answer's start L)
        set x, 31             side 0
g:      nop                   side 1
        nop                   side 0
        nop                   side 1
        nop                   side 0
        nop                   side 1
        nop                   side 0
        nop                   side 1
        jmp x-- g             side 0
; ---- answer: Y bytes from the ATxmega
ash:    mov isr, null         side 1    ; start bit slot, H
        jmp y-- ai            side 0    ; data slot 1 L, count the byte
ai:     in pins, 1            side 1    ; data slot H: sample P1 near the rising edge
        jmp !isrf ai          side 0    ; next slot L
        push                  side 1    ; parity slot H
        set x, 0              side 0    ; stop 1 L
        mov isr, osr          side 1    ; stop 1 H
        in null, 15           side 0    ; stop 2 L
        nop                   side 1    ; stop 2 H
        jmp x!=y ash          side 0    ; next start L (more bytes) or idle 1 L
        mov x, isr            side 1    ; idle 1 H: X = next word's end flag
        nop                   side 0    ; idle 2 L
        jmp nf                side 1    ; idle 2 H
; ---- end: slot 1 was the frame's s0; 15 more idle slots, then P0 high for good
endp:   set y, 13             side 0    ; end slot 2 L
e:      nop                   side 1
        jmp y-- e             side 0
hang:   jmp hang              side 1
