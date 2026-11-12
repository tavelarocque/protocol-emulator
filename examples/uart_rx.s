; uart_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; UART receiver, 8N1, LSB first, on pin [pin] (an input, read through the
; input synchroniser). Config: in_base = [pin], threshold 9, TIMEOUT 0,
; timeout_vector = origin + [uart_rx_bad].
;
; Host protocol on the TX FIFO, once at start:
;   word 0 : divisor - 4, where divisor = clock cycles per bit (>= 10),
;            exactly as for [uart_tx]
;   word 1 : the half-bit delay, [uart_rx_half ~divisor]
; RX FIFO, one word per frame: bits 7:0 the byte (LSB first is the order
; IN shifts, so no bit reversal), bit 8 the stop bit as sampled: 1 for a
; good frame, 0 for a framing error or a break.
;
; Timing: the start bit's falling edge reaches the thread 2 cycles late
; (the synchroniser); a half-bit delay then puts the first sample in the
; middle of data bit 0, and every later sample is exactly one divisor on.
; The test suite checks reception with the sender's baud rate off by up to
; 2% either way. Back-to-back frames need divisor >= 10.
;
; After a frame, the firmware goes straight back to looking for the next
; start bit, unless the stop bit was low (a framing error or a break): then
; it first waits for the line to return high, so it does not mistake the
; rest of a long low for new frames. That branch is a [wait 1 ... timeout]
; with TIMEOUT 0, which falls through if the pin is high and jumps to the
; timeout vector at once if it is low. The first version waited for idle
; after every frame and lost back-to-back frames from a fast sender: the
; next start bit had already begun when it checked.
        pull                ; OSR <- divisor - 4
        mov y, osr          ; Y = per-bit loop count
        pull                ; OSR <- half-bit count, kept there for good
start:  wait 0 pin 0      ; start bit
        mov x, osr
half:   jmp x-- half        ; to the middle of the start bit
bit:    mov x, y
hold:   jmp x-- hold        ; one bit time on
        in pins, 1          ; sample: 8 data bits, then the stop bit
        jmp !isrf bit       ; until 9 bits (threshold 9)
        push                ; byte in bits 7:0, stop bit in bit 8
        wait 1 pin 0 timeout ; stop bit high: next frame. Low: to [bad]
        jmp start
bad:    wait 1 pin 0      ; framing error or break: wait for the line to idle
        jmp start
