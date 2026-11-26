; AVR PDI programmer, thread 0, 50 MHz core, PDI_CLK 1 MHz (50 cycles a slot)
; P0 = RESET/PDI_CLK, written only by `set pins` (set_base 0, set_count 1)
; P1 = PDI_DATA, written by `out pins` / `mov pins` (out_base 1, out_count 1),
;      read by `in pins` (in_base 1)
; Times in comments are slot-local: t0 is the cycle of the instruction that
; makes the falling edge (it shows one cycle later, on the ideal place),
; t25 the one that makes the rising edge, t50 the next slot's t0.
; Parity: the CRC register with crc_poly=1, crc_init=0 is a 1-bit XOR of the
; first bit of every OUT, so after the 8 data OUTs it holds the parity bit.

start:  set y, 15                  ; c0: 16 enable slots
        wait 0 pin 0 timeout       ; P0 is high: times out into IDLE_ (timeout_vector)

; ---- idle slots: enter IDLE_ at t49 with Y = n-1, runs n slots, leaves at t49
IDLE_:  nop                        ; t49
IDLE:   set pins, 0 [15]           ; t0  fall
        nop [8]                    ; t16
        set pins, 1 [15]           ; t25 rise
        jmp y-- IDLE_ [7]          ; t41 -> t49

; ---- next host word, entered at t49 of a slot with P1 released
W:      pull                       ; t49 (stalls for ever after the end word)
        set pins, 0                ; t0  fall
        out x, 12                  ; t1  X = count<<8 | byte
        out y, 4                   ; t2  Y = 8 for the end word, else 0
        jmp !y FRAME               ; t3
END:    set y, 14 [15]             ; t4  this slot + 15 more idle slots
TAIL:   nop [4]                    ; t20
        set pins, 1 [15]           ; t25 rise
        jmp IDLE_ [7]              ; t41 -> t49

; ---- the chip's frame: start bit slot (fall already made by W)
FRAME:  mov pins, null [1]         ; t4  P1 = 0 (start bit)
        mov osr, x [2]             ; t6
        mov crc, null [15]         ; t9  parity accumulator = 0
        set pins, 1 [15]           ; t25 rise
        nop [8]                    ; t41
DB:     set pins, 0 [8]            ; t0  fall
        out pins, 1 [15]           ; t9  P1 = data bit (CRC takes it)
        set pins, 1 [15]           ; t25 rise
        jmp !osre DB [8]           ; t41 (8 data bits, threshold 8)
PAR:    set pins, 0 [8]            ; t0  fall
        mov pins, crc [15]         ; t9  P1 = parity
        set pins, 1 [15]           ; t25 rise
        set x, 1 [7]               ; t41
        out y, 4                   ; t49 Y = answer length
ST1:    set pins, 0 [8]            ; t0  fall
        mov pins, x [15]           ; t9  P1 = 1 (stop bit, released from here on)
        set pins, 1 [6]            ; t25 rise
        mov osr, y [15]            ; t32 keep the answer length in the OSR
        jmp !y IDLE_               ; t48 not answered: 1 idle slot (2nd stop) then W
        set y, 4                   ; t49 answered: X=1, Y=4 -> 2 + 4*32 = 130 slots

; ---- idle slots counted by X (inner) and Y (outer); leaves into AB with Y=OSR
; second stop bit + 128 guard slots + the ATxmega's start bit = 130 slots
G:      set pins, 0 [15]           ; t0  fall
        jmp x-- Gw [5]             ; t16
        set x, 31                  ; t22
        jmp y-- Grise [1]          ; t23
        set pins, 1 [15]           ; t25 rise (last slot)
        mov y, osr [8]             ; t41 Y = bytes still to come, this one included

; ---- the ATxmega's 8 data bits
AB:     set pins, 0 [15]           ; t0  fall
        nop [8]                    ; t16
        set pins, 1                ; t25 rise
        in pins, 1 [15]            ; t26 sample P1
        jmp !isrf AB [7]           ; t42
; ---- its parity slot
A9:     set pins, 0                ; t0  fall
        push                       ; t1
        jmp y-- A9c                ; t2  Y = bytes after this one
A9c:    mov osr, y                 ; t3
        jmp !y A9last              ; t4
        set x, 2                   ; t5  parity, 2 stops, next start bit = 4 slots
        set y, 0 [15]              ; t6
        jmp Grise [2]              ; t22
A9last: set y, 3 [13]              ; t5  parity, 2 stops, 2 idle = 5 slots, then W
        jmp TAIL                   ; t19

Gw:     nop [2]                    ; t22
Grise:  set pins, 1 [15]           ; t25 rise
        jmp G [8]                  ; t41
