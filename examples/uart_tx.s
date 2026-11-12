; uart_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; UART transmitter, 8N1, LSB first, on one push-pull pin (out_base and
; set_base both point at it, out_count = set_count = 1, threshold = 8).
;
; Host protocol on the thread's TX FIFO:
;   word 0     : divisor - 4, where divisor = clock cycles per bit (>= 4).
;                4 is the fixed instruction overhead of each bit period.
;   word 1..   : one byte per word.
;
; Timing: every bit, including start, is exactly [divisor] cycles. The stop
; bit is divisor + 1 cycles when bytes are back to back (one extra cycle for
; the PULL), which any UART receiver accepts.
        set pins, 1         ; line idles high
        pull                ; OSR <- divisor - 4
        mov y, osr          ; Y = per-bit loop count
next:   pull                ; wait for a byte; line stays high meanwhile
        set pins, 0 [1]     ; start bit (2 cycles, then the delay loop)
        mov x, y
start:  jmp x-- start
bit:    out pins, 1         ; data bit, LSB first
        mov x, y
hold:   jmp x-- hold
        jmp !osre bit       ; until all 8 bits are out
        set pins, 1         ; stop bit
        mov x, y
stop:   jmp x-- stop
        jmp next
