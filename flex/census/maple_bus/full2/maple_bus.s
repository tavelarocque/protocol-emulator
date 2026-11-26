; Maple bus host transmitter, thread 0, 50 MHz core clock.
; P0 = SDCKA (A), P1 = SDCKB (B), both push-pull.
; Config (run_args.txt): set_base=0 set_count=2, out_base=0 out_count=2,
; out_msb_first=1, threshold=16, crc_poly=0x80 (crc_init 0).
;
; set pins value = A | B<<1.
; The CRC register with poly 0x80 is an 8-bit ring: each OUT's first bit is
; XORed into the bit that went in 8 bits earlier, so after the frame its low
; byte is the XOR checksum, bit-reversed (first sent bit at bit 0).
;
; Pair flag in the ISR: not full = next boundary ends the first word of a
; pair, full = it ends the second. ISR not full with a nonzero value marks
; the end of the checksum.

frame:
    pull                    ; word 0 = N<<8 | sender (blocks while idle)
    mov x, osr
    out y, 8                ; Y = N, pairs still to come after (w0, w1)
    mov osr, x              ; word 0 back in the OSR, shift count 0
    mov crc, null           ; restart the XOR ring (that OUT fed it)
    mov isr, null           ; flag: first word of a pair, value 0
    ; start pattern: A- B- B+ B- B+ B- B+ B- B+ A+
    set pins, 2  [11]       ; A-
    set x, 3
sp: set pins, 0  [12]       ; B-
    set pins, 2  [11]       ; B+
    jmp x-- sp
    set pins, 3  [5]        ; A+ ; bit 0's step 1 is then no change
even:                       ; bit clocked by A, data on B. A is high here
    out x, 1                ; next bit (MSB first), also into the CRC ring
    jmp !x e0
    set pins, 3  [7]        ; step 2: B = 1
    set pins, 2  [7]        ; step 3: A falls
    jmp odd
e0: set pins, 1  [7]        ; step 2: B = 0
    set pins, 0  [7]        ; step 3: A falls
odd:                        ; bit clocked by B, data on A. A is low here
    set pins, 2  [10]       ; step 1: B = 1
    out x, 1
    jmp !x o0               ; a 0 needs no step 2: A is already low
    set pins, 3  [7]        ; step 2: A = 1
o0: mov pins, x  [7]        ; step 3: A = bit, B falls
    set pins, 1  [4]        ; next even bit's step 1, or end pattern's A high
    jmp !osre even
    jmp !isrf notfull       ; word done: which one?
    mov isr, null           ; second word of a pair done
    jmp y-- next_word
    ; all words sent: prepare the checksum
    mov osr, crc            ; low byte = checksum bit-reversed, ring frozen now
    out null, 8
rev: out x, 1               ; reverse it through the ISR (shifts right,
    in x, 1                 ; new bits enter at bit 15)
    jmp !osre rev
    in null, 8              ; ISR = checksum in its low byte
    mov osr, isr
    out null, 8             ; OSR: 8 checksum bits left, MSB first
    set x, 1
    mov isr, x              ; flag: checksum (not full, value 1)
    jmp even
notfull:
    mov x, isr
    jmp !x first_done
    ; end pattern (A already high, B low): B+ B- A- A+ A- A+ B+
    set pins, 3  [12]       ; B+
    set pins, 1  [12]       ; B-
    set pins, 0  [12]       ; A-
    set pins, 1  [12]       ; A+
    set pins, 0  [12]       ; A-
    set pins, 1  [12]       ; A+
    set pins, 3  [15]       ; B+ : idle
    set x, 31
gap: jmp x-- gap  [3]       ; 128 cycles of idle before the next frame
    jmp frame
first_done:
    in null, 16             ; flag: ISR full = second word of the pair next
next_word:
    pull
    jmp even
