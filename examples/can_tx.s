; can_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; CAN: the transmitter, on thread 1, with the framing on the chip: it
; stuffs the bits, computes the CRC, arbitrates and reads the ACK slot.
; Config: [Can.tx_config].
;
; A bit is 20 ticks here (the receiver's is 10, so this thread's CLKDIV is
; half the receiver's). Ticks are counted from the instruction that drives
; a bit, tick 0; the next bit is driven at tick 20, along every path.
;
; TX words: N - 1, then the N bits from the identifier to the end of the
; data, as they are before stuffing and with no CRC, 15 to a word, the
; first in bit 0 ([Can.tx_words]). Both must be in the FIFO before the bus
; is looked at, so the first bit never waits for the host; after that a
; word is needed every 15 bit times. One frame at a time: the next one's
; words must not be there until this one has reported.
;
; Stuffing. The last level sent is which of the two loops the thread is
; in, [z] after a dominant bit and [o] after a recessive one. The length
; of the run is the ISR's shift count: 11 after the first bit of a run,
; one more for each equal bit, and at 15, the threshold, the ISR counts as
; full: five equal bits, so the next bit is their opposite and is not
; taken from the OSR. The CRC register follows OUT, so it sees every bit
; of the frame and no stuff bit.
;
; The CRC. When Y runs out a field has ended. The 15 bits a word holds
; never end with the data (18 + 8 n is not a multiple of 15 for n up to
; 8), so the OSR not empty means the data has just ended: the CRC
; register is moved to the OSR and goes out through the same loops, bit
; 15 of it never sent. The OSR empty means that was the CRC.
;
; Arbitration. Fourteen ticks into every recessive bit it has sent, stuff
; bits included, the thread reads RXD. (One bit goes unread: a fifth
; recessive bit that is also the last of the data or of the CRC, where
; arbitration is long over.) Dominant: another node is driving,
; and it stops at once, takes the rest of the frame's bits from the FIFO
; unsent, and reports. The wait with TIMEOUT = 0 is that branch;
; [can_tx_lost] is the vector, used while waiting for an idle bus as well,
; which X being 0 tells apart. A wait that times out does not change
; PAGE, so the vector sets it.
;
; One RX word reports:
;   0   a receiver acknowledged the frame
;   1   the frame went out and nobody acknowledged it
;   2   stopped: arbitration lost, or the bus dominant under a recessive
;       bit. Send it again.
next:   pull                    ; N - 1
        mov isr, osr            ; kept in the ISR while the bus is watched
        pull                    ; the first 15 bits, here before the frame starts
        set x, 0                ; X = 0 marks "waiting for the bus"
quiet:  set y, 24               ; the bus recessive for 11 bit times: 25 looks
q:      wait 1 pin 0 timeout [7]
        jmp y-- q
        wait 1 pin 0 timeout    ; a last look, then at once
        mov pins, x             ; 0: the start-of-frame bit (X is 0)
        mov y, isr              ; 1: N - 1
        mov crc, null           ; 2: the CRC from zero
        mov isr, null           ; 3
        in null, 11             ; 4: a run of one dominant bit
        set page, 1 [11]        ; 5..16
        jmp zo                  ; 17
        .page 0
end0:   jmp !osre de0           ; 7: a field has ended, on a dominant bit
        jmp tail                ; 8: it was the CRC
de0:    mov osr, crc            ; 8: it was the data. The CRC goes out next
        set y, 14 [6]           ; 9..15
        set page, 1             ; 16
        jmp zo                  ; 17
        .page 0
end1:   jmp !osre de1           ; 7: the same, on a recessive bit
        jmp tail
de1:    mov osr, crc            ; 8
        set y, 14 [2]           ; 9..11
        set page, 1             ; 12
        jmp ow                  ; 13: this bit is checked like any other
        .page 0
tail:   nop [10]                ; 9..19
        set pins, 1             ; 0: the CRC delimiter
        nop [15]                ; 1..16
        nop [3]                 ; 17..20: the ACK slot begins
        nop [12]                ; 1..13
        mov isr, null           ; 14
        in pins, 1              ; 15: RXD in the ACK slot
        push                    ; 0 if a receiver drove it
        jmp next
lost:   set page, 0             ; timeout vector: PAGE may be either
        jmp !x quiet            ; waiting for the bus: count again
d:      out null, 1             ; mid-frame: the rest of its bits, unsent
        jmp y-- d
        set x, 2
        mov isr, null
        in x, 16
        push
        jmp next
        .align
z:      nop [12]                ; 5..17: the last bit sent was dominant
zo:     out x, 1 [1]            ; 18..19: the next bit; the CRC takes it
        mov pins, x             ; 0
        jmp !x zs               ; 1
        mov isr, null           ; 2: recessive now, a run of one
        in null, 11             ; 3
        jmp y-- o               ; 4
        set page, 0             ; 5
        jmp end1                ; 6
        .page 1
zs:     in null, 1              ; 2: one more dominant bit
        jmp !isrf zc            ; 3
        mov isr, null [13]      ; 4..17: five. A recessive stuff bit is next
        in null, 11 [1]         ; 18..19
        set pins, 1             ; 0
        set x, 1 [2]            ; 1..3: X says what is on TXD, for the vector
        jmp y-- o               ; 4
        set page, 0             ; 5
        jmp end1                ; 6
        .page 1
zc:     jmp y-- z               ; 4
x0:     set page, 0             ; 5
        jmp end0                ; 6
        .page 1
o:      nop [8]                 ; 5..13: the last bit sent was recessive
ow:     wait 1 pin 0 timeout [3] ; 14..17: so the bus must be recessive too
        out x, 1 [1]            ; 18..19
        mov pins, x             ; 0
        jmp !x oz               ; 1
        in null, 1              ; 2: one more recessive bit
        jmp !isrf oc            ; 3
        jmp y-- os              ; 4: five. A dominant stuff bit is next
        mov isr, null [12]      ; 5..17: and the field ends with it
        in null, 11 [1]         ; 18..19
        set pins, 0             ; 0
        jmp x0 [3]              ; 1..4
os:     mov isr, null [8]       ; 5..13
        wait 1 pin 0 timeout [3] ; 14..17
        in null, 11 [1]         ; 18..19
        set pins, 0             ; 0
        jmp z [3]               ; 1..4
oz:     mov isr, null           ; 2: dominant now, a run of one
        in null, 11             ; 3
        jmp y-- z               ; 4
        set page, 0             ; 5
        jmp end0                ; 6
        .page 1
oc:     jmp y-- o               ; 4
        set page, 0             ; 5
        jmp end1                ; 6
