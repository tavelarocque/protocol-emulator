; AUD branch trace receiver, thread 0, 50 MHz core clock.
; Pins: P0 AUDCK, P1 nAUDSYNC, P2..P5 AUDATA0..3 (all inputs).
; Config: in_base=2 (in pins,4 reads AUDATA3..0), threshold=16.
; Registers between addresses: ISR = low half L of the previous
; destination (shift count reset to 0), Y = high half H. X, OSR scratch.
; ISR shifts right: each in puts its bits at the top, so nibbles sent
; least significant first end up in place after 16 bits.

idle:
    wait 0 pin 0        ; AUDCK low (also skips the reset-time high reads)
    wait 1 pin 0        ; rising edge seen (2 cycles after the pin)
    mov osr, pins
    out null, 5
    out x, 1            ; X = AUDATA3: 0 idle (0x3), 1 command (0x8..0xB)
    jmp !x idle
    mov osr, pins       ; read again, still well inside the stable window
    out null, 2
    out x, 1            ; X = AUDATA0
    jmp !x even
    out x, 1            ; X = AUDATA1
    jmp !x w8           ; 0x9: 8 bits
; 0xB: 32 bits. Low half into ISR, park it in OSR, high half into ISR.
w32:
    mov isr, null
    set x, 3
w32a:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    jmp x-- w32a
    mov osr, isr        ; new L
    mov isr, null
    set x, 3
w32b:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    jmp x-- w32b
    mov y, isr          ; new H
    mov x, osr          ; new L
; Push L then H, then leave ISR = L with its count at 0.
emit:
    mov isr, null
    in x, 16
    push
    in y, 16
    push
    mov isr, x
    jmp idle
even:
    out x, 1            ; X = AUDATA1
    jmp !x w4           ; 0x8: 4 bits
; 0xA: 16 bits, the whole low half.
w16:
    mov isr, null
    set x, 3
w16a:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    jmp x-- w16a
    mov x, isr
    jmp emit
; 0x9: ISR = L. Two nibbles give n1 n0 L[15:8] (top to bottom); shifting
; in L[15:8] again (the low 8 bits of that) rotates it to L[15:8] n1 n0.
w8:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    mov x, isr
    in x, 8
    mov x, isr
    jmp emit
; 0x8: one nibble gives n L[15:4]; shift in its low 12 bits, L[15:4].
w4:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    mov x, isr
    in x, 12
    mov x, isr
    jmp emit
