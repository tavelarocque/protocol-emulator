; ST7735 4-line serial host, write only. Thread 0, 40 MHz, clkdiv 1.
; P0 SDA (out pins), P1 SCL (side-set), P2 D/CX and P3 CSX (set pins).
; TX word: bits 7..0 byte, bit 8 = command, bit 9 = last byte of transfer.
; OSR shifts MSB first, threshold 16: 6 unused bits, last, cmd, 8 data bits.
; set pins value: bit 0 = D/CX, bit 1 = CSX.
        .side_set 1
top:    pull            side 0  ; wait for a word, SCL low (also at reset)
        out null, 6     side 0  ; bits 15..10, unused
        out y, 1        side 0  ; Y = last flag
        out x, 1        side 0  ; X = command flag
        jmp !x data     side 0
        set pins, 0     side 0  ; command: D/CX low, CSX low
        jmp bit         side 0
data:   set pins, 1     side 0  ; data: D/CX high, CSX low
bit:    out pins, 1     side 0  ; SDA changes as SCL falls
        nop             side 0  ; SCL low 2 cycles
        nop             side 1  ; rising edge, display samples SDA
        jmp !osre bit   side 1  ; SCL high 2 cycles
        jmp !y top      side 0  ; fall of 8th pulse; not last: next word
        jmp !x dend     side 0
        set pins, 2     side 0  ; last was a command: D/CX stays low, CSX high
        jmp top         side 0
dend:   set pins, 3     side 0  ; last was data: D/CX stays high, CSX high
        jmp top         side 0
