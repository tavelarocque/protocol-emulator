; AUD branch trace receiver, thread 0.
; Pins: P0 AUDCK, P1 nAUDSYNC, P2..P5 AUDATA0..3 (all inputs).
; Config: start=16 (main), in_base=2, threshold=16.
;
; State kept between addresses:
;   ISR = low half L of the previous destination address
;   Y   = high half H of the previous destination address
; ISR shifts right (default): bits enter at the top, so nibbles read
; least significant first end up in the right places after 16 bits.

; ---- 4, 8 or 16 bit address: X = nibble count - 1 ----
w8:     set x, 1
        jmp half
w16:    set x, 3
half:   mov osr, isr        ; OSR = old L
        mov isr, null       ; ISR empty, count 0
nib:    wait 0 pin 0
        wait 1 pin 0        ; rising edge of AUDCK
        in pins, 4          ; address nibble into the top of the ISR
        out null, 4         ; drop the nibble of old L it replaces
        jmp x-- nib
merge:  jmp !isrf mstep     ; fill the rest of the ISR from old L
; ---- ISR = new L (16 bits), Y = new H: push both ----
tail:   mov x, isr
        push                ; bits 15..0
        in y, 16
        push                ; bits 31..16
        in x, 16            ; ISR = L again for the next address
; ---- wait for an edge with nAUDSYNC high and decode it ----
main:   wait 0 pin 0
        wait 1 pin 0
        mov osr, pins
        out null, 2         ; drop AUDCK, nAUDSYNC
        out x, 2            ; X = AUDATA1..0 (width code for 10ww)
        jmp !x half         ; 0x8: 4 bits, X = 0 = one nibble
        jmp x-- a1
a1:     jmp !x w8           ; 0x9
        jmp x-- a2
a2:     jmp !x w16          ; 0xA
        out x, 2            ; AUDATA3..2: 0 for idle 0x3, 2 for 0xB
        jmp !x main         ; idle
; ---- 32 bit address ----
w32:    mov isr, null
lo:     wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        jmp !isrf lo
        mov x, isr          ; X = new L
        mov isr, null
hi:     wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        jmp !isrf hi
        mov y, isr          ; Y = new H
        mov isr, null
        in x, 16            ; ISR = new L
        jmp tail
mstep:  out x, 4
        in x, 4
        jmp merge
