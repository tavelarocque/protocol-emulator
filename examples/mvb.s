; mvb: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; IEC 61375-3-1 MVB, the Multifunction Vehicle Bus of trains: a sender of
; master frames and slave frames. 1.5 Mbit/s, Manchester coded: a 1 is
; high then low, a 0 low then high. A frame starts with a start bit (a 1)
; and an 8-bit start delimiter that has non-data symbols in it, NH (high
; for a whole bit time) and NL (low): 1 NH NL 0 NH NL 0 0 0 for a master
; frame, 1 1 1 1 NL NH 1 NL NH for a slave frame. Then the data, most
; significant bit first: a master frame is 16 bits (the function code
; and the address), a slave frame 16, 32, 64, 128 or 256 bits, and after
; every 64 bits, or after all of them in a shorter frame, an 8-bit check
; sequence. The frame ends with an end delimiter; here it is an NH, after
; which the line goes silent (low), so a frame both starts and ends with
; a change of level.
;
; The check sequence is a 7-bit CRC with the generator x^7 + x^6 + x^5 +
; x^2 + 1, an even parity bit over the data and those 7 bits, and all 8
; inverted. The firmware computes it on the CRC register with one
; polynomial, x^8 + x^5 + x^3 + x^2 + x + 1: the generator times x + 1
; (0xF4 written for a register that shifts right). The remainder R by
; that product gives both. The 8 bits wanted are R itself when R's last
; bit (which is the parity bit) is 0; when it is 1, they are R with the
; bits for x^7, x^6, x^5 and x^2 turned over, because the generator plus
; 1 is a multiple of x + 1 whose remainder by the generator is 1. So
; after a block the register is read inverted, its parity bit decides,
; and the eight bits go out from the ISR, which shifts right as the
; register holds them (first bit lowest), with a mask in the OSR that
; says which to turn over.
;
; The words after the first are counted down in Y, and a word with a
; multiple of 4 words after it ends a 64-bit block. That is tested when a
; word is pulled, and picks one of two copies of the bit loop: the copy
; for a word that ends a block goes on to the check sequence.
;
; Timing: a half bit is 16 ticks, so the core clock must be 48 MHz times
; CLKDIV: at 48 MHz with CLKDIV 1 the bit rate is exactly 1.5 Mbit/s. At
; 50 MHz no whole number of clocks makes a bit (33.3 are needed); 33 would
; be 1.0% fast, and 32, this program at CLKDIV 1, 4.2% fast.
;
; The real bus is RS-485 (ESD) or transformer coupled (EMD): the pins are
; for a line driver, P0 its data input and P1 its enable. A frame starts
; after eight bit times or more of silence.
;
; Pins: P0 = data, high for the line's high; P1 = the driver's enable;
; both push-pull, low while the bus is silent. Config: [mvb_config]:
; out_base 0, out_count 1; set_base 0, set_count 2; threshold 16; out
; most significant bit first; crc_poly 0xF4, crc_init 0, crc_invert.
;
; Host protocol, per frame:
;   TX word 0 : bit 15 set for a master frame; bits 3:0 the number of
;               16-bit words less one: 0 for a master frame; 0, 1, 3, 7 or
;               15 for a slave frame of 16 to 256 bits ([mvb_words])
;   then      : the words. A master frame's word is the function code in
;               bits 15:12 and the address in 11:0.
; A word is taken in the last bit of the one before, one every 10.7 us:
; the driver plays them from the packet buffer, faster than the host port
; could push them.
next:   set pins, 0             ; silent: the line low, the driver off
        set x, 15
gap:    jmp x-- gap [15]        ; eight bit times
        pull                    ; the header
        out x, 1                ; bit 15: a master frame
        out null, 11
        out y, 4                ; Y: the words after the first
        pull                    ; the first word
        jmp !x slave
        set pins, 3 [15]        ; half bit 1: the start bit, high; the driver on
        set pins, 2 [15]        ; 2
        set pins, 3 [15]        ; 3, 4: NH
        nop [15]
        set pins, 2 [15]        ; 5, 6: NL
        nop [15]
        nop [15]                ; 7, 8: 0
        set pins, 3 [15]
        nop [15]                ; 9, 10: NH
        nop [15]
        set pins, 2 [15]        ; 11, 12: NL
        nop [15]
        nop [15]                ; 13, 14: 0
        set pins, 3 [15]
        set pins, 2 [15]        ; 15, 16: 0
        set pins, 3 [15]
        set pins, 2 [14]        ; 17, 18: 0
        jmp first
slave:  set pins, 3 [15]        ; 1: the start bit
        set pins, 2 [15]        ; 2
        set pins, 3 [15]        ; 3, 4: 1
        set pins, 2 [15]
        set pins, 3 [15]        ; 5, 6: 1
        set pins, 2 [15]
        set pins, 3 [15]        ; 7, 8: 1
        set pins, 2 [15]
        nop [15]                ; 9, 10: NL
        nop [15]
        set pins, 3 [15]        ; 11, 12: NH
        nop [15]
        nop [15]                ; 13, 14: 1
        set pins, 2 [15]
        nop [15]                ; 15, 16: NL
        nop [15]
        set pins, 3 [14]        ; 17, 18: NH
        jmp first
first:  set pins, 3             ; 272: half bit 18, high
        mov crc, null           ; 273: the check sequence covers the data alone
        out x, 1                ; 274: the first bit
        jmp !y fl [10]          ; 275..285: a frame of one word: it ends the block
        set page, 1             ; 286
        jmp bitn                ; 287
fl:     set page, 1             ; 286
        jmp bitl                ; 287
.align
bitn:   mov pins, x             ; 0: the first half: the bit
        jmp x-- n1 [14]         ; 1..15: X - 1, whose bit 0 is the bit's opposite
n1:     mov pins, x             ; 16: the second half
        jmp !osre nmore [5]     ; 17..22
        jmp y-- nw              ; 23: the word has gone; Y > 0 here
nw:     pull                    ; 24: the next word
        mov isr, null           ; 25
        in y, 2                 ; 26
        mov x, isr              ; 27: the words after it, modulo 4
        jmp !x lw               ; 28: 0: it ends a block
        out x, 1 [1]            ; 29..30: its first bit; the CRC register takes it
        jmp bitn                ; 31
lw:     out x, 1 [1]            ; 29..30
        jmp bitl                ; 31
nmore:  out x, 1 [7]            ; 23..30: the next bit
        jmp bitn                ; 31
bitl:   mov pins, x             ; 0: the same, in a word that ends a block
        jmp x-- l1 [14]         ; 1..15
l1:     mov pins, x             ; 16
        jmp !osre lmore         ; 17
        mov isr, crc            ; 18: the block has gone: the register, inverted; it stops
        mov osr, isr            ; 19
        out null, 8             ; 20
        out x, 1                ; 21: its bit 7, the parity bit, inverted
        jmp !x odd              ; 22
        set x, 0                ; 23: parity bit 0: every bit as it is
        jmp x-- even            ; 24: X = 0xFFFF
even:   mov osr, x              ; 25
        out null, 8 [1]         ; 26..27: the mask in bits 15:8, a 1 for each bit as it is
cb:     out x, 1                ; 28: the mask's bit for the next check bit
        jmp !x cf               ; 29
        nop [1]                 ; 30..31
        mov pins, isr           ; 0: the bit
        mov x, isr              ; 1
        jmp x-- cq [13]         ; 2..15
cq:     mov pins, x             ; 16: its opposite
        jmp ct                  ; 17
cf:     mov x, isr              ; 30
        jmp x-- cg              ; 31
cg:     mov pins, x             ; 0: the bit turned over
        nop [14]                ; 1..15
        mov pins, isr [1]       ; 16..17: and its opposite
ct:     in null, 1              ; 18: the next check bit to bit 0
        jmp !osre cw            ; 19: eight in all
        jmp !y end              ; 20: the frame's last block
        mov crc, null           ; 21: the next block's from 0
        jmp y-- nw [1]          ; 22..23
cw:     jmp cb [7]              ; 20..27
odd:    set x, 27               ; 23: parity bit 1: 00011011, bits 0, 1, 2 and 5 turned over
        mov osr, x              ; 24
        out null, 8             ; 25
        jmp cb [1]              ; 26..27
lmore:  out x, 1 [12]           ; 18..30
        jmp bitl                ; 31
end:    nop [10]                ; 21..31
        set pins, 3 [15]        ; 32..47: the end delimiter, NH
        nop [13]                ; 48..61
        set page, 0             ; 62
        jmp next                ; 63
