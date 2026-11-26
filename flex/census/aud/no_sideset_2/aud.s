; AUD branch trace receiver, thread 0, 50 MHz core, AUDCK 1 MHz.
; Pins (all inputs): P0 AUDCK, P1 nAUDSYNC, P2..P5 AUDATA0..3.
; Config: in_base=2, threshold=16, timeout=0, timeout_vector=vec (word 26).
;
; Registers between addresses:
;   ISR = low half L of the previous destination address, shift count 0
;   Y   = high half H of the previous destination address
;   X, OSR = scratch
; While an address arrives, `in pins, 4` shifts each nibble into the top of
; the ISR (right shift), so after k nibbles ISR = rotr(newL, 4k) with count
; 4k. Rotating on by 4 until the count reaches 16 (!isrf) gives newL.
; End of an address of 1, 2 or 4 nibbles is seen as nAUDSYNC high at the
; next rising edge: `wait 0 pin 1 timeout` with timeout 0 jumps to vec.

idle:   wait 0 pin 0            ; wait for AUDCK low
        wait 1 pin 0            ; rising edge (as the thread sees it)
        mov osr, pins           ; snapshot of the sync-high nibble
cls:    out null, 5             ; drop P0..P4
        out x, 1                ; X = P5 = AUDATA3: 1 for command, 0 for idle
        jmp !x idle
nib:    wait 0 pin 0            ; command seen: receive the low 16 bits
        wait 1 pin 0
        wait 0 pin 1 timeout    ; nAUDSYNC high: address ended -> vec
        in pins, 4
        jmp !isrf nib           ; fewer than 4 nibbles so far
        wait 0 pin 0            ; 4 nibbles: is there a 5th?
        wait 1 pin 0
        wait 0 pin 1 timeout    ; no: 16-bit address ended -> vec
        mov x, isr              ; 32-bit: X = new L
        mov isr, null           ; count 0 for the high half
hin:    in pins, 4
        jmp !isrf hwait
        mov y, isr              ; Y = new H
        mov isr, null
        in x, 16                ; ISR = L, count 16
        mov osr, null           ; no snapshot: classify as idle afterwards
        jmp fin
hwait:  wait 0 pin 0
        wait 1 pin 0
        jmp hin
vec:    mov osr, pins           ; snapshot of the nibble that ended it
fin:    jmp !isrf rot           ; rotate until count 16
        mov x, isr              ; X = L
        push                    ; bits 15..0
        in y, 16
        push                    ; bits 31..16
        mov isr, x              ; ISR = L, count 0
        jmp cls                 ; this edge's nibble: idle or command
rot:    mov x, isr
        in x, 4                 ; rotate ISR right by 4
        jmp fin
