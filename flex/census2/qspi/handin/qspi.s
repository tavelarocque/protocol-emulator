; Quad SPI NOR controller: WREN + Quad Page Program (0x32, 1-1-4) per page.
; Pins: P0..P3 = IO0..IO3 (out pins, out_base 0, out_count 4),
;       P4 = SCK, P5 = CS# (side-set, base 4, 2 bits: bit0 SCK, bit1 CS#).
; Side values: 2 = idle (CS# high, SCK low), 0 = CS# low SCK low, 1 = CS# low SCK high.
; OSR shifts MSB first, no autopull: every word is fetched with an explicit pull.
; Host word: bits 7..0 byte, bit 8 = last byte of page.

        .side_set 2

        set x, 21       side 2          ; SCK low from the first cycle
        in x, 5         side 2          ; ISR = 21 << 11 = 43008, the wait count

page:   pull            side 2          ; first address word A23..A16; stalls (idle) when the host is done
        mov y, osr      side 2          ; keep it while the OSR sends the constants
        set x, 6        side 2          ; WREN = 0x06
        mov osr, x      side 2
        out null, 8     side 2          ; byte now on top of the OSR
        set x, 7        side 2
wren:   out pins, 1     side 0          ; CS# low, bit on IO0, SCK low
        jmp x-- wren    side 1          ; SCK rises
        set x, 25       side 2          ; CS# high; 25 << 1 = 0x32
        mov osr, x      side 2
        out null, 9     side 2          ; OSR = 0x3200: 0x32 on top
        set x, 7        side 2
cmd:    out pins, 1     side 0          ; QPP frame starts: CS# low
        jmp x-- cmd     side 1
        mov osr, y      side 0          ; A23..A16
        set y, 2        side 0          ; three address bytes
abyte:  out null, 8     side 0          ; skip bits 15..8 of the word
        set x, 7        side 0
abit:   out pins, 1     side 0
        jmp x-- abit    side 1
        pull            side 0          ; next address byte, after the third the first data byte
        jmp y-- abyte   side 0
data:   out null, 7     side 0          ; bits 15..9
        out y, 1        side 0          ; bit 8: last byte of the page
        out pins, 4     side 0          ; bits 7..4 on IO3..IO0
        nop             side 1
        out pins, 4     side 0          ; bits 3..0
        jmp !y more     side 1
        mov x, isr      side 2          ; last byte sent: CS# high, start the program wait
wait:   jmp x-- wait    side 2 [3]      ; 43009 x 4 cycles
        jmp page        side 2
more:   pull            side 0
        jmp data        side 0
