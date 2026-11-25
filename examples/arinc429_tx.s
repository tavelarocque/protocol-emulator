; arinc429_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; ARINC 429, the avionics data bus: 32-bit words on one twisted pair, at
; 100 kbit/s (high speed) or 12.5 kbit/s (low speed). A bit is bipolar
; return to zero: the line goes to HI for the first half of a 1, to LO for
; the first half of a 0, and back to NULL for the second half; words are
; separated by at least four bit times of NULL. A word is sent bit 1
; first: bits 1 to 8 the label, its most significant bit first (the
; reverse of the rest of the word); 9 and 10 the SDI; 11 to 29 the data;
; 30 and 31 the SSM; 32 the parity, which makes the ones odd.
;
; The host gives the label as its octal number reads, in the bottom byte;
; the firmware turns it round in the ISR (IN shifting left), sends the 31
; bits, makes the parity on the CRC register (polynomial 1, following the
; bits OUT shifts), sends it, and keeps four bit times of NULL before the
; next word.
;
; The line is two wires at +-10 V between them; the chip's pins are the
; inputs of an ARINC 429 line driver (an HI-8586, HI-3182 or similar),
; which takes one logic input high for HI and the other for LO, both low
; for NULL. A logic analyser on those two inputs sees what the decoders
; here read.
;
; Pins: P0 = HI (the line driver's "1" input), P1 = LO (its "0" input),
; push-pull, both low between words. Config: [arinc429_config]: set_base
; 0, set_count 2; threshold 16; in most significant bit first, out least
; significant first; crc_poly 1, crc_init 0. A bit is 20 ticks: CLKDIV 5
; at 10 MHz and 25 at 50 MHz for 100 kbit/s, 40 and 200 for 12.5 kbit/s,
; all exact.
;
; Host protocol: two TX words a word on the line ([arinc429_words]):
;   word 1 : the label in bits 7:0 (octal 205 is 0x85), the SDI in 9:8,
;            and data bits 11 to 16 in 15:10
;   word 2 : data bits 17 to 29 in 12:0, the SSM in 14:13; bit 15 unused
; Both words of the next are taken in the gap, and when they are there
; in time the gap is exactly four bit times; when not, the line stays at
; NULL until they come.
        set pins, 0             ; NULL: HI and LO both low
next:   pull                    ; word 1
        out x, 8                ; X: the label
        mov y, osr
        in y, 8                 ; the SDI and data bits 11 to 16, to send after it
        mov osr, x
        set y, 7
rev:    out x, 1                ; the label from its least significant bit
        in x, 1                 ; into the ISR's bottom: turned round
        jmp y-- rev
        pull                    ; word 2
        mov x, isr              ; bits 1 to 16, bit 1 lowest
        mov isr, osr            ; word 2 waits in the ISR
        mov osr, x
        mov crc, null           ; the parity from bit 1
        set y, 30               ; 31 bits
bit:    out x, 1
        jmp !x zero
        set pins, 1 [8]         ; a 1: HI for half a bit
        jmp low
zero:   set pins, 2 [8]         ; a 0: LO
        jmp low
low:    set pins, 0 [4]         ; NULL for the other half
        jmp !osre more
        mov osr, isr            ; after bit 16: word 2
        jmp y-- bit
more:   nop
        jmp y-- bit
        mov x, crc              ; the 31 bits' parity
        jmp !x pone             ; even: the parity bit is a 1
        set pins, 2 [8]         ; odd: a 0
        jmp gap
pone:   set pins, 1 [8]
        jmp gap
gap:    set pins, 0 [15]        ; NULL: the rest of the bit and four more
        nop [15]
        nop [15]
        jmp next [3]
