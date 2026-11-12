; spi_controller: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SPI controller, mode 0 (SCK idles low, sample on the rising edge),
; MSB first, full duplex.
;
; Pins: P0 = SCK, P1 = MOSI, P3 = CS_N (push-pull); P2 = MISO (input).
; Config: set_base 0, set_count 1 (SCK); out_base 1, out_count 3 (MOSI, -,
; CS_N: OUT writes only MOSI, MOV writes all three to move CS_N); in_base 2
; (MISO); threshold 8.
;
; Host protocol on the TX FIFO:
;   word 0  : H, the half-period loop count. A bit takes 2H + 9 cycles.
;   then one word per byte:
;     bits 7:0  the byte to send, bit-reversed (OUT shifts LSB first)
;     bit 8     1 = deselect after this byte, ending the transfer
; RX FIFO: one word per byte, the byte received, bit-reversed.
        set pins, 0         ; SCK idles low in mode 0 (pins reset high)
        pull                ; OSR <- H
        mov y, osr          ; Y = H for every delay below
idle:   set x, 4
        mov pins, x         ; CS_N high, MOSI low: deselected
        pull                ; first byte of a transfer
        mov pins, null      ; CS_N low: select
        mov x, y
c0:     jmp x-- c0
bit:    out pins, 1         ; MOSI = next bit, while SCK is low
        mov x, y
c1:     jmp x-- c1
        set pins, 1         ; SCK high: both sides sample
        in pins, 1          ; MISO
        mov x, y
c2:     jmp x-- c2
        set pins, 0         ; SCK low: the slave shifts its next bit out
        jmp !osre bit       ; 8 bits
        push                ; byte received
        out x, 1            ; X = deselect flag (word bit 8)
        jmp !x next
        mov x, y
c3:     jmp x-- c3
        jmp idle
next:   pull                ; next byte; SCK held low until it arrives
        jmp bit
