; ST7735 4-line serial host (write only), thread 0, 40 MHz.
; Pins: P0 SDA (out pins), P1 SCL (side-set), P2 D/CX and P3 CSX (set pins).
; TX word: bit 15 = 1 if another byte of the same transfer follows, 0 if this
; is the transfer's last byte; bits 14..7 = the byte; bits 6..0 = 0.
; The first word of a transfer is its command byte (D/CX low), the rest data.
; Needs: threshold 9, out_msb_first, out_base 0 count 1, set_base 2 count 2,
; sideset_base 1 count 1.
        .side_set 1
start:
        set pins, 3        side 0   ; CSX high, D/CX high, SCL low
next:
        pull               side 0   ; wait for a command word (idle here)
        set pins, 0        side 0   ; CSX low, D/CX low
byte:
        out x, 1           side 0   ; X = "more bytes follow"
bit:
        out pins, 1        side 0   ; SDA = next bit, SCL low
        nop                side 0   ; SCL low, second cycle
        nop                side 1   ; SCL high: display samples SDA
        jmp !osre bit      side 1   ; SCL high, second cycle; 8 bits per byte
        jmp !x done        side 0   ; SCL falls after the eighth bit
        set pins, 1        side 0   ; a cycle later: D/CX high for data, CSX low
        pull               side 0   ; next data word (SCL low, CSX low if it stalls)
        jmp byte           side 0
done:
        set pins, 3        side 0   ; a cycle after SCL fell: CSX high
        jmp next           side 0
