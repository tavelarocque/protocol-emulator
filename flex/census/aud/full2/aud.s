; AUD branch trace receiver, thread 0, 50 MHz core, AUDCK 1 MHz.
; Pins: P0 AUDCK, P1 nAUDSYNC, P2..P5 AUDATA0..3. All inputs.
; Config: in_base=2, timeout=0, timeout_vector=0 (idle).
; State between addresses: X = destination bits 15..0, Y = bits 31..16.
; While an address arrives the ISR starts as a copy of X; each nibble
; shifts in at the top, so after k nibbles the ISR holds the k new nibbles
; on top and the old upper bits below. A rotate (mov x, isr then in x, n)
; puts them back in order.

idle:
    wait 0 pin 0            ; AUDCK low
    wait 1 pin 0            ; rising edge (as synchronised)
    wait 1 pin 5 timeout    ; AUDATA3 = 0: idle nibble 0x3, back to idle
    in x, 16                ; command 0x8..0xB: ISR = old low half
    mov osr, pins
    out null, 2             ; drop AUDCK, nAUDSYNC
    out x, 2                ; X = AUDATA1..0 = width code
    jmp !x w4
    jmp x-- d1              ; always taken (X was not 0)
d1: jmp !x w8
    jmp x-- d2              ; always taken
d2: jmp !x w16

w32:                        ; 8 nibbles: low half, then high half
    set x, 3
l32a:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    jmp x-- l32a
    mov y, isr              ; Y = new low half (old high half not needed)
    set x, 3
l32b:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    jmp x-- l32b
    mov x, isr              ; X = new high half
    mov osr, x              ; swap X and Y through the OSR
    mov x, y
    mov y, osr
    jmp emit

w16:
    set x, 3
l16:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    jmp x-- l16
    mov x, isr
    jmp emit

w8:
    set x, 1
l8:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    jmp x-- l8
    mov x, isr              ; X = new byte on top, old bits 15..8 below
    in x, 8                 ; rotate: old bits 15..8 back on top
    mov x, isr
    jmp emit

w4:
    wait 0 pin 0
    wait 1 pin 0
    in pins, 4
    mov x, isr              ; X = new nibble on top, old bits 15..4 below
    in x, 12                ; rotate: old bits 15..4 back on top
    mov x, isr

emit:
    in x, 16
    push                    ; bits 15..0
    in y, 16
    push                    ; bits 31..16
    jmp idle
