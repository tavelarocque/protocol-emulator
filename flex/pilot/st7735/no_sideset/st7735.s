; ST7735 4-line serial host, write only. Thread 0, 40 MHz, clkdiv 1.
; Entry point is "fin" (config start=8).
; out pins : P0 SDA                    (out_base 0, out_count 1, MSB first)
; set pins : P1 SCL, P2 D/CX, P3 CSX   (set_base 1, set_count 3)
;            value bit0 = SCL, bit1 = D/CX, bit2 = CSX
; TX word: bit 9 = last byte of transfer, bit 8 = command, bits 7..0 = byte.
; Each bit: SDA set, 1 cycle later SCL high for 2 cycles, then low >= 2 cycles
; (5 cycles = 125 ns a bit).
data:   pull                ; 0  next data word
        out y, 8            ; 1  Y = bits 15..8: 2 if last byte, else 0
        set x, 7            ; 2
dbit:   out pins, 1         ; 3  SDA = next bit, MSB first
        set pins, 3 [1]     ; 4  D/CX high, SCL high for 2 cycles
        set pins, 2         ; 5  SCL low, D/CX stays high
        jmp x-- dbit        ; 6
tail:   jmp !y data         ; 7  not the last byte: go on with data
fin:    set pins, 4         ; 8  CSX high, D/CX low, SCL low (idle; reset entry)
        pull                ; 9  command word of the next transfer
        out y, 7            ; 10 Y = bits 15..9: 1 if last byte, else 0
        out null, 1         ; 11 drop bit 8 (always 1 on a command)
        set x, 7            ; 12
        set pins, 0         ; 13 CSX falls; D/CX low, SCL low
cbit:   out pins, 1         ; 14
        set pins, 1 [1]     ; 15 SCL high for 2 cycles, D/CX low
        set pins, 0         ; 16 SCL low
        jmp x-- cbit        ; 17
        jmp tail            ; 18 last -> fin, else -> data
