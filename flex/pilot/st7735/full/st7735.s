; ST7735 4-line serial host, write only. Thread 0, 40 MHz, clkdiv 1.
; P0 SDA (out pins), P1 SCL (side-set), P2 D/CX and P3 CSX (set pins).
; Word: bit 9 = last byte of transfer, bit 8 = command, bits 7..0 = byte.
; Needs: out MSB first, threshold 16, out_base 0 count 1,
;        set_base 2 count 2, sideset_base 1 count 1.
        .side_set 1
start:
        pull                side 0      ; wait for a word, SCL low
        out null, 6         side 0      ; drop bits 15..10
        out x, 1            side 0      ; X = last-byte flag
        out y, 1            side 0      ; Y = command flag
        jmp !y, data        side 0
        set pins, 0         side 0      ; command: CSX low, D/CX low
        jmp bitloop         side 0
data:
        set pins, 1         side 0      ; data: CSX low, D/CX high
bitloop:
        out pins, 1         side 0 [1]  ; SDA, SCL low for 2 cycles
        jmp !osre, bitloop  side 1 [1]  ; SCL high for 2 cycles
        jmp !x, start       side 0 [1]  ; SCL low; more bytes in this transfer
        set pins, 3         side 0      ; CSX high (D/CX high)
        jmp start           side 0
