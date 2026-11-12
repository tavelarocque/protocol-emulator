; spi_target: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SPI target (device mode): the chip answers as a mode-0 SPI device (SCK
; idles low, both sides sample on the rising edge and change on the
; falling one, MSB first), full duplex.
;
; Pins: P0 = SCK, P1 = MOSI, P3 = CS_N (inputs); P2 = MISO (push-pull).
; That is the pin map of [spi_controller] and [spi_fast], so one chip can
; be the controller and another the device on the same four wires.
; Config: [spi_target_config]: in_base 1 (MOSI), out_base 2 (MISO),
; threshold 8, IN shifts MSB first, TIMEOUT 0 and timeout_vector
; [spi_target_desel].
;
; Host protocol.
;   TX : the reply bytes, one per byte the controller clocks, bit-reversed
;        ([reverse_byte]; OUT shifts LSB first). One continuous stream
;        across transfers: the reply to byte n of the whole session is TX
;        word n. The firmware takes the next word as soon as a byte ends
;        (and the first at start), so it holds one reply ahead.
;   RX : each byte the controller sent (0 to 255), and after every
;        transfer the marker 0x100, so the host can tell commands apart.
;
; SPI has no flow control, so the host must stay ahead. A thread can only
; take from its TX FIFO with a [pull] that waits, and the ISA has no
; non-blocking version (PIO's [pull noblock], which would let the firmware
; send a filler byte instead): if the next reply is not there when a byte
; ends, the firmware waits for it and misses the controller's next bits,
; until the next deselect resynchronises it. The same holds for a full RX
; FIFO.
;
; Every bit, the firmware polls for SCK rising and checks CS_N in the same
; loop, so a deselect is seen even in the middle of a byte; the partial
; byte is dropped. Branching on a pin is the same trick as in
; [i2c_target]: [wait 0 pin 3 timeout] with TIMEOUT 0 falls through while
; CS_N is low and jumps to the vector the moment it is high. SCK is read
; through the OSR, so the reply's unsent bits are parked in Y meanwhile.
;
; Timing: SCK may run up to core clock / 16 (625 kHz at 10 MHz; the tests
; find the reference controller works from 8 clocks per SCK phase, with or
; without gaps between bytes). Not supported: other SPI modes, and sharing
; MISO with other devices (it is always driven, even when deselected).
        pull                ; the first reply byte
        out pins, 1         ; MISO = its bit 7, ready before the first edge
sel:    wait 0 pin 3        ; until selected
bit:    mov y, osr          ; park the reply's unsent bits
poll:   wait 0 pin 3 timeout ; deselected: to [desel]
        mov osr, pins
        out x, 1            ; X = SCK
        jmp !x poll
        mov osr, y          ; SCK rose: the reply bits back
        in pins, 1          ; sample MOSI
        wait 0 pin 0        ; SCK falls
        jmp !isrf next
        push                ; a whole byte received
        pull                ; the next reply byte
next:   out pins, 1         ; MISO = next bit, while SCK is low
        jmp bit
desel:  mov osr, y          ; CS_N rose: keep the reply for the next transfer
        mov isr, null       ; drop a partial byte
        set x, 1
        in x, 1
        in null, 8
        push                ; RX marker 0x100: end of transfer
        jmp sel
