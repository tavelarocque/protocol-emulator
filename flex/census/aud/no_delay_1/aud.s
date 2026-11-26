; AUD branch trace receiver, thread 0, 50 MHz core, AUDCK 1 MHz.
; Pins (inputs): P0 AUDCK, P1 nAUDSYNC, P2..P5 AUDATA0..3.
; Config: in_base=2, threshold=16, timeout=0, timeout_vector=1 (idle).
;
; Registers:
;   OSR  low 16 bits of the previous destination address (L)
;   Y    high 16 bits of the previous destination address (H)
;   X    scratch: width code, loop counter, shifted copy of L
;   ISR  assembles the new low (or high) half
;
; nAUDSYNC is not read: outside an address only 0x3 (idle) and 0x8..0xB
; (commands) appear, so AUDATA3 alone tells a command from idle, and the
; command says exactly how many address nibbles follow.

        mov osr, null        ; L = 0 (Y is already 0 at start)
idle:                        ; address 1, also the timeout vector
        wait 0 pin 0         ; AUDCK low
        wait 1 pin 0         ; rising edge of AUDCK
        wait 1 pin 5 timeout ; AUDATA3 low (idle 0x3): timeout 0 -> idle
        in pins, 2           ; command 10ww: w = AUDATA1..0
        in null, 14          ; right-justify w in the ISR
        mov x, isr           ; X = w
        mov isr, null
        jmp !x w4
        jmp x-- d1
d1:     jmp !x w8
        jmp x-- d2
d2:     jmp !x w16
w32:    set x, 3             ; 8 nibbles: low half first
lo32:   wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        jmp x-- lo32
        mov osr, isr         ; new L
        mov isr, null
        set x, 3
hi32:   wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        jmp x-- hi32
        mov y, isr           ; new H
        mov isr, null
        mov x, osr
        in x, 16             ; ISR = new L
        jmp finish
w16:    set x, 3             ; 4 nibbles replace L
l16:    wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        jmp x-- l16
        jmp finish
w8:     out null, 8          ; X = L >> 8
        out x, 8
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        in x, 8              ; ISR = new byte | old L[15:8] << 8
        jmp finish
w4:     out null, 4          ; X = L >> 4
        out x, 12
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        in x, 12             ; ISR = new nibble | old L[15:4] << 4
finish: mov osr, isr         ; keep new L
        push                 ; bits 15..0
        in y, 16
        push                 ; bits 31..16
        jmp idle
