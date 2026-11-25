; mil1553_mon: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; The MIL-STD-1553B bus monitor, on thread 1 beside [mil1553_bc] (see
; there): every word on the bus, the BC's own and the RTs' answers, goes
; to the host as two RX words, the 16 bits and then a tag.
;
; A word from a quiet bus starts with a command or status sync, whose
; middle is a falling edge a bit and a half after the bus rises; after a
; word, a quarter of a bit time past its end, the bus is high if a
; command or status sync follows at once, and low for a data sync or a
; quiet bus, and then a data sync's middle is a rising edge. From the
; middle of the sync each bit is read a quarter of a bit time into it,
; in its first half, which is the bit (the receiver does not check that
; the second half is the opposite). The CRC register, following the bits
; IN takes, checks the parity over the 17. When no data sync's middle
; comes within two bit times the bus is quiet: [mil1553_mon_idle], the
; timeout vector.
;
; Pins: P2 = RX, an input. Config: [mil1553_mon_config]: in_base 2;
; threshold 16, autopush; in most significant bit first; crc_poly 1,
; crc_init 0, crc_in; timeout_vector [mil1553_mon_idle], timeout 20; CLKDIV
; as thread 0's.
;
; Host protocol on the RX FIFO, two words for each word on the bus: its
; 16 bits, then a tag: bit 0 set for a command or status sync, clear for
; a data sync; bit 1 set if the parity is right (odd over the 17 bits);
; bit 2 the parity bit as received. Two words every 20 us is more than
; the host port carries at 10 MHz: the driver records them in the packet
; buffer.
        wait 0 pin 2            ; the bus quiet (RX reads high for two cycles after reset)
idle:   wait 1 pin 2            ; a quiet bus: a command or status sync rises
csync:  set y, 1                ; a command or status sync
        wait 0 pin 2            ; its middle falls
        jmp word [9]
dsync:  set y, 0 [3]            ; a data sync
        wait 1 pin 2 timeout    ; its middle rises, or the bus is quiet
        jmp word [9]
word:   mov isr, null
        mov crc, null
        set x, 15 [3]
bit:    in pins, 1 [8]          ; a bit's first half, most significant first
        jmp x-- bit             ; the 16th pushes the word
        in pins, 1              ; the parity bit
        mov x, crc              ; 1 if the 17 bits have odd parity
        in x, 1
        in y, 1
        push                    ; the tag
        mov isr, null [4]
        in pins, 1              ; just after the word: what comes next
        mov x, isr
        jmp !x dsync
        jmp csync
