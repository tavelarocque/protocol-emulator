; ST7789V 4-line serial host (write only), thread 0, 50 MHz.
; P0 SDA (out pins), P1 SCL (side-set), P2 D/CX and P3 CSX (set pins, bit0 = D/CX, bit1 = CSX).
; Word: bits 7..0 byte, bit 8 command, bit 9 last byte of transfer. OSR shifts MSB first, threshold 16.
; The command flag is not needed: the first byte of every transfer is the command.
        .side_set 1
idle:   set pins, 3        side 0      ; CSX high, D/CX high, SCL low
        pull               side 0      ; first word of a transfer (the command)
        set pins, 0        side 0      ; CSX low, D/CX low
        jmp byte           side 0
data:   pull               side 0      ; next word of the same transfer
        set pins, 1        side 0      ; CSX low, D/CX high
byte:   out null, 6        side 0      ; bits 15..10 (always 0)
        out y, 1           side 0      ; bit 9: last byte of the transfer
        out null, 1        side 0      ; bit 8: command flag, implied by position
bit:    out pins, 1        side 0 [1]  ; SDA = next bit, SCL low for 2 cycles
        jmp !osre bit      side 1 [1]  ; SCL high for 2 cycles; loop until 16 bits used
        jmp !y data        side 0      ; SCL low; not last: another data byte
        jmp idle           side 0      ; last: CSX rises one cycle after SCL fell
