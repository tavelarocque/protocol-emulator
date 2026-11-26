; AUD branch trace receiver, thread 0, 50 MHz core, AUDCK 1 MHz.
; Pins (all inputs): P0 AUDCK, P1 nAUDSYNC, P2..P5 AUDATA0..3.
; Config: in_base=2, threshold=16, start=idle, timeout_vector=idle, timeout=0.
;
; Registers:
;   OSR  previous destination address, bits 15..0 (count reset by mov osr)
;   Y    previous destination address, bits 31..16
;   ISR  nibbles being assembled (shifts right, so nibbles sent least
;        significant first end up in order)
;   X    scratch: width code, then previous low bits shifted down
;
; Each nibble is read one cycle after the thread sees AUDCK rise; every line
; passes the same two-flop synchroniser, so the data seen then is the data
; of that rising edge (stable 25 cycles either side of it on the pins).

; ---- 8-bit address: two nibbles, upper 8 bits of the low word kept ----
w8:     out null, 8         ; OSR = previous low word: drop its low byte
        out x, 8            ; X = previous bits 15..8
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4          ; bits 3..0
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4          ; bits 7..4
        in x, 8             ; bits 15..8 from the previous address
        jmp tail

; ---- 4-bit address: one nibble, upper 12 bits of the low word kept ----
w4:     out null, 4
        out x, 12           ; X = previous bits 15..4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4          ; bits 3..0
        in x, 12            ; bits 15..4 from the previous address

; ---- ISR holds the new low word: keep it, push it, push the high word ----
tail:   mov osr, isr        ; new previous low word
tailp:  push                ; word 1: bits 15..0
        in y, 16
        push                ; word 2: bits 31..16

; ---- idle / command: wait for a rising edge of AUDCK ----
idle:   wait 0 pin 0
        wait 1 pin 0
        wait 1 pin 5 timeout ; AUDATA3 low: idle nibble 0x3 -> timeout_vector = idle
        in pins, 2          ; command 0x8..0xB: AUDATA1..0 give the width
        in null, 14         ; right-justify it in the ISR
        mov x, isr          ; X = 0 (4 bits), 1 (8), 2 (16), 3 (32)
        mov isr, null       ; empty the ISR for the address nibbles
        jmp !x w4
        jmp x-- d1
d1:     jmp !x w8
        jmp x-- d2          ; X = 0 for 16 bits, 1 for 32 bits
; ---- 16 or 32 bits: first four nibbles are the whole low word ----
d2:     wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        jmp !x tail         ; 16 bits: done
        mov osr, isr        ; 32 bits: keep the low word
        mov isr, null
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        wait 0 pin 0
        wait 1 pin 0
        in pins, 4
        mov y, isr          ; new high word
        mov isr, null
        mov x, osr
        in x, 16            ; ISR = new low word
        jmp tailp
