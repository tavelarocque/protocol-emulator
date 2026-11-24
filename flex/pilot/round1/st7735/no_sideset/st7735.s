; ST7735 4-line serial interface, host side, write only.
; Thread 0, core clock 40 MHz (25 ns per cycle), no side-set.
;
; Pins   P0 SDA   : out pins  (out_base=0, out_count=1)
;        P1 SCL   : set pins bit 0  (set_base=1, set_count=3)
;        P2 D/CX  : set pins bit 1
;        P3 CSX   : set pins bit 2
; Config threshold=8, out_msb_first=1, no autopull.
;
; TX word: bits 15..8 = the byte, sent most significant bit first
;          bit 7      = 1 if another data byte of the same transfer follows,
;                       0 if this byte is the last one of its transfer
;          bits 6..0  = 0 (ignored)
; The first word of a transfer is its command byte.
;
; One bit takes 5 cycles (125 ns): SDA changes, 1 cycle later SCL rises,
; SCL stays high 2 cycles, then low 3 cycles. D/CX only changes between
; bytes, while SCL is low: it is steady through all 8 bits of every byte.

idle:   set pins, 6 [1]     ; CSX high, D/CX high, SCL low (also the reset state fix: SCL low)
        pull                ; wait here for the command word of the next transfer
        set pins, 0         ; CSX low, D/CX low (command), SCL low
cbit:   out pins, 1         ; SDA = next bit of the command byte
        set pins, 1 [1]     ; SCL high for 2 cycles, D/CX low
        set pins, 0         ; SCL low
        jmp !osre cbit      ; 8 bits per word
more:   out x, 1            ; X = the "more" flag, bit 7 of the word just sent
        jmp !x idle         ; that was the last byte: raise CSX
        set pins, 2         ; D/CX high before the first bit of a data byte
        pull                ; next data byte
dbit:   out pins, 1         ; SDA = next bit of the data byte
        set pins, 3 [1]     ; SCL high for 2 cycles, D/CX high (data)
        set pins, 2         ; SCL low
        jmp !osre dbit
        jmp more
