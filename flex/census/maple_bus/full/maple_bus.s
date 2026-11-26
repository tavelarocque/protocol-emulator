; Maple bus host transmitter, thread 0, 50 MHz.
; P0 = SDCKA (A), P1 = SDCKB (B), both push-pull.
; Config (run_args.txt):
;   set_base=0 set_count=1   -> "set pins" writes A only
;   out_base=1 out_count=1   -> "out pins" / "mov pins" write B only
;   out_msb_first=1, threshold=16, in_msb_first=0 (IN shifts right)
;   crc_poly=0x80, crc_init=0 -> CRC register is an 8-bit rotating XOR:
;   after whole bytes fed MSB first it holds the XOR of the bytes, bit reversed.
; Registers: X = bit scratch / small loops, Y = data word count N,
;   ISR = constant 1 (source for "B high" via mov pins, isr), OSR = data.
; Every change is at least 7 cycles after the other line's last change and
; at least 12 after the same line's last change (see notes.md).

frame:
        pull                [15]   ; word 0: N, sender (stalls here when idle)
        mov x, osr          [15]
        out y, 8            [15]   ; Y = N (this OUT feeds the CRC, reset next)
        mov osr, x          [15]   ; OSR = word 0 again, full
        mov crc, null       [15]   ; CRC from crc_init = 0
        set x, 1            [15]
        mov isr, x          [15]   ; ISR = 1, the "high" source for B
; start pattern: A- ; (B- B+) x4 ; A+
        set pins, 0         [6]    ; A-
        set x, 3
sp:     mov pins, null      [11]   ; B-
        mov pins, isr       [10]   ; B+
        jmp x-- sp
        set pins, 1         [6]    ; A+
        jmp first
wl:     pull                       ; first half of a data word
first:
; ---- 16 bits of OSR, two bits per pass (even: clock A, data B; odd: clock B, data A)
p1:     set pins, 1         [6]    ; A high (no change if already high)
        out pins, 1         [6]    ; B = even bit
        set pins, 0         [6]    ; A falls: even bit clocked
        mov pins, isr       [5]    ; B high
        out x, 1                   ; odd bit
        jmp !x p1z          [4]
        set pins, 1         [6]    ; A = 1
p1z:    mov pins, null      [5]    ; B falls: odd bit clocked
        jmp !osre p1
        pull                       ; second half (word 1 of header, or data)
p2:     set pins, 1         [6]
        out pins, 1         [6]
        set pins, 0         [6]
        mov pins, isr       [5]
        out x, 1
        jmp !x p2z          [4]
        set pins, 1         [6]
p2z:    mov pins, null      [5]
        jmp !osre p2
        jmp y-- wl                 ; header pass + N data words
; ---- checksum: CRC low byte is the XOR bit reversed; reverse it through ISR
        mov osr, crc               ; OSR = CRC low 16 bits (CRC stops following)
        out null, 8                ; reversed checksum now in OSR[15:8]
rv:     out x, 1
        in x, 1                    ; ISR shifts right, bit enters at the top
        jmp !osre rv               ; 8 times
        in null, 8                 ; ISR[7:0] = checksum
        mov osr, isr
        out null, 8                ; OSR[15:8] = checksum, 8 bits left to send
        set y, 1                   ; Y = 1, the "high" source for B from here
p3:     set pins, 1         [6]
        out pins, 1         [6]
        set pins, 0         [6]
        mov pins, y         [5]
        out x, 1
        jmp !x p3z          [4]
        set pins, 1         [6]
p3z:    mov pins, null      [5]
        jmp !osre p3
; end pattern: A high if low; B+ ; B- ; A- A+ A- A+ ; B+
        set pins, 1         [6]
        mov pins, y         [11]   ; B+
        mov pins, null      [6]    ; B-
        set pins, 0         [11]   ; A-
        set pins, 1         [11]   ; A+
        set pins, 0         [11]   ; A-
        set pins, 1         [6]    ; A+
        mov pins, y         [15]   ; B+ : idle from here
        jmp frame           [15]
