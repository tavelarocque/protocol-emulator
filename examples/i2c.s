; i2c: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; I2C controller, reads and writes, timed by the clock divider.
;
; The same 9-clock routine moves every byte in either direction: it shifts
; 9 bits out on SDA (8 data bits, then the ACK slot) while sampling SDA on
; each clock. Writing a byte, the host's data goes out and the slot is
; released so the target can ACK. Reading, the host sends 0xFF (SDA
; released) and puts its own ACK or NACK in the slot. Either way what was
; sampled is what was on the bus, so the RX word reports it all.
;
; Pins: P0 = SDA (open-drain), P1 = SCL (open-drain, driven by side-set).
; Config: out_base 0, out_count 1, set_base 0, set_count 1 (SDA); in_base 0;
; sideset_base 1, sideset_count 1 (SCL); timeout_vector = [i2c_stuck];
; TIMEOUT = the longest clock stretch to tolerate, in ticks;
; CLKDIV = clock / (6 x bit rate), so 17 for 98 kHz at 10 MHz.
;
; Every bit is 6 ticks, SCL low for 3 and high for 3, which meets
; standard-mode (100 kHz) timing whenever a tick is at least 1.6 us. START
; and STOP hold SDA for 3 ticks around the SCL edge.
;
; Host protocol on the TX FIFO, one word per byte:
;   bits 7:0  the byte, bit-reversed (OUT shifts LSB first; I2C is MSB
;             first). 0xFF to read a byte.
;   bit 8     the ACK slot: 1 when writing (release SDA so the target can
;             ACK); when reading, 0 = ACK (send more), 1 = NACK (last byte)
;   bit 9     1 = send STOP after this byte, ending the transaction
; The first byte after idle (the address, with R/W in bit 0) gets a START.
; RX FIFO, one word per byte as seen on the bus: bits 7:0 the byte,
; bit-reversed; bit 8 the ACK slot, 0 = ACK, 1 = NACK. 0x200 = the bus was
; stuck (SCL held low longer than TIMEOUT); the firmware then releases both
; lines and returns to idle.
;
; One property is deliberate: the RX word of a read's last byte has bit 8
; set (the controller's NACK), which is exactly the "last byte" flag of the
; SPI firmware's TX words. That is what lets [Bridge] below chain them.
        .side_set 1
idle:   pull                side 1     ; bus idle: both lines released
        set pins, 0         side 1 [2] ; START: SDA falls while SCL is high
byte:   set y, 8            side 0     ; SCL low; 9 bits: 8 data + ACK slot
bit:    out pins, 1         side 0 [1] ; SDA = next bit while SCL is low
        nop                 side 1     ; release SCL
        wait 1 pin 1 timeout side 1    ; until SCL is really high: the target may stretch
        in pins, 1          side 1     ; sample SDA
        jmp y-- bit         side 0     ; SCL low
        push                side 0     ; the byte and its ACK slot, as seen on the bus
        out x, 1            side 0     ; X = STOP flag (word bit 9)
        jmp !x next         side 0
        set pins, 0         side 0     ; STOP: SDA low while SCL is low,
        nop                 side 1     ; release SCL,
        wait 1 pin 1 timeout side 1 [1]
        set pins, 1         side 1     ; then SDA rises while SCL is high
        jmp idle            side 1
next:   pull                side 0     ; next byte; SCL held low until it arrives
        jmp byte            side 0
stuck:  mov isr, null       side 1     ; timeout vector: SCL never went high
        in null, 9          side 1
        set x, 1            side 1
        in x, 1             side 1
        push                side 1     ; report 0x200: bus stuck
        set pins, 1         side 1     ; release SDA (side-set released SCL)
        jmp idle            side 1
