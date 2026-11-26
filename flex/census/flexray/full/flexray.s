; FlexRay static-segment transmitter, channel A, 10 Mbit/s, 50 MHz core.
; One bit = 5 cycles. P0 = TxD (push-pull). Thread 0.
;
; Config (run_args.txt): start=43 threshold=8 out_msb_first=1 (in shifts right),
;   crc_poly = bit-reversed 0x5D6DCB = 0xD3B6BA, crc_init = bit-reversed 0xFEDCBA = 0x5D3B7F.
; The CRC register follows every OUT, so the only OUTs inside a frame are the
; header and payload data bits (out pins, 1). Everything else uses IN/MOV/SET.
; Each byte: BSS high (5 cycles), BSS low (5 cycles), 8 data bits. The cycles of
; the two BSS bits are where bookkeeping happens; every line below is timed so a
; pin write lands exactly 5 cycles after the previous bit's write.
; Times in comments: T = cycle of the BSS-high write of the byte being set up.

; ---- header bytes 2..4 (reached from next, first visit of the frame) ----
hdr2:   pull                    ; T+2  OSR = w1 = L
        mov y, osr              ; T+3  Y = L
        pull                    ; T+4  OSR = w2 = header CRC
        set pins, 0             ; T+5  BSS low
        mov x, osr              ; T+6  X = w2
        in x, 11                ; T+7  ISR = w2 << 5 (top-aligned)
        in y, 7                 ; T+8  ISR = A = L<<9 | w2>>2
        mov osr, isr            ; T+9  OSR = A, count 0
h2:     out pins, 1 [3]         ; header byte 2 = A[15:8]
        jmp !osre h2
        set pins, 1             ; U    BSS high, byte 3
        mov osr, osr            ; U+1  count 0, OSR = A<<8
        in x, 2                 ; U+2  build Y' = L<<9 | w2[1:0]
        in null, 7              ; U+3
        in y, 7                 ; U+4
        set pins, 0             ; U+5  BSS low
        mov y, isr [3]          ; U+6  Y = Y'
h3:     out pins, 1 [3]         ; header byte 3 = A[7:0]
        jmp !osre h3
        set pins, 1             ; V    BSS high, byte 4
        pull                    ; V+1  OSR = w3 = cycle count
        mov x, osr              ; V+2  X = w3
        in x, 6                 ; V+3  ISR top = w3
        in y, 2                 ; V+4  ISR top = w2[1:0] w3 = byte 4
        set pins, 0             ; V+5  BSS low
        mov osr, isr            ; V+6  OSR = byte 4 at top, count 0
        mov isr, y              ; V+7  recover L from Y'
        in null, 9              ; V+8  ISR = L, ISR count 9 (>= threshold)
        mov y, isr              ; V+9  Y = L (payload word counter)
h4:     out pins, 1 [3]         ; header byte 4, or 2nd byte of a payload word / w0
        jmp !osre h4
; ---- after every second byte: BSS high of the next byte, then dispatch ----
next:   set pins, 1             ; T    BSS high (next byte is header 2, payload or CRC)
        jmp !isrf hdr2          ; T+1  ISR count < 8 only right after w0
        jmp y-- pay             ; T+2  payload words left?
        mov isr, crc            ; T+3  ISR = CRC register low 16 (reflected CRC)
        set y, 2                ; T+4  CRC bytes left after this one
cz:     set pins, 0 [4]         ; T+5  BSS low
cb:     mov pins, isr           ; t    CRC bit = ISR bit 0 (LSB of reflected = MSB of CRC)
        in null, 1              ; t+1  ISR >>= 1
        jmp !isrf cw            ; t+2
        jmp y-- cm [1]          ; t+3  byte done: another CRC byte?
        set pins, 0 [4]         ; FES low
        set pins, 1 [15]        ; FES high, then idle
; ---- frame start (also program start) ----
frame:  pull [15]               ; OSR = w0 (stalls here, line high, when words run out)
        mov isr, null [15]      ; ISR count 0: marks "header byte 2 comes next"
        mov crc, null [15]      ; restart CRC from crc_init
        set pins, 0 [15]        ; TSS: 16 cycles low (64 cycles after FES rising edge)
        set pins, 1 [9]         ; c0: FSS and BSS high of header byte 0
pz:     set pins, 0 [4]         ; c10 / T+5: BSS low
p0:     out pins, 1 [3]         ; first byte of a 16-bit word (w0 or payload)
        jmp !osre p0
        set pins, 1             ; M    BSS high
        mov osr, osr [3]        ; M+1  count 0, OSR = word<<8
        set pins, 0 [3]         ; M+5  BSS low
        jmp h4                  ; M+9
pay:    pull                    ; T+3  OSR = payload word
        jmp pz                  ; T+4
cw:     jmp cb [1]              ; t+3  next CRC bit at t+5
cm:     set pins, 1             ; T'   BSS high of CRC byte 1 or 2
        jmp !y cl               ; T'+1
        mov isr, isr [1]        ; T'+2 byte 1: rest of the first read, count 0
        jmp cz                  ; T'+4
cl:     mov isr, crc [1]        ; T'+2 byte 2: second read, CRC bits 23..16 of the register
        jmp cz                  ; T'+4
