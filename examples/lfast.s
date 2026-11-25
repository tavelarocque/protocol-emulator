; lfast: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; NXP's LFAST link sending SIPI frames (SIPI, also called Zipwire: reads
; and writes of another chip's memory over LFAST), at LFAST's low speed,
; 5 Mbit/s. An LFAST frame is NRZ, most significant bit first: the sync
; pattern 0xA84B, a header byte (the payload's size, the logical channel,
; CTS), the payload, and a sleep bit. Here the payload is a SIPI frame: a
; header word (tag, command, channel), the address and data the command
; has, and a CRC-16 over all of them: CCITT's polynomial, from all ones,
; most significant bit first, as SIPI has it.
;
; The program makes the sync pattern, the timing, the CRC and the sleep
; bit (0: no request for the LVDS sleep mode), after which the line is
; low for twelve bit times or more before the next frame. LFAST puts no
; number on that time; twelve is for sigrok's decoder, which ends a frame
; that ends without an edge by a timeout of up to eight bit times, and
; takes an edge before then into the frame.
;
; The CRC register works least significant bit first, so it runs with
; the polynomial reversed (0x8408) and holds the CRC reversed: its bit 0
; is the CRC's top bit, the first to go out. The ISR turns it round:
; [mov isr, crc], then for each bit the ISR's bit 0 goes to the pin and
; [in null, 1] shifts the ISR right by one.
;
; LFAST is a differential LVDS pair: the pin is TXP's level, for an LVDS
; driver. A real link also shares a reference clock between the two chips,
; which the chip does not provide, and answers on a second pair, which
; this program does not read: it sends.
;
; Pins: P0 = the line, push-pull, low when idle. Config: [lfast_config]:
; out_base 0, out_count 1; set_base 0, set_count 1; threshold 16; out
; most significant bit first; crc_poly 0x8408, crc_init 0xFFFF.
; A bit is 5 ticks: CLKDIV 2 at 50 MHz for 5 Mbit/s.
;
; Host protocol, per frame:
;   TX word 0 : the LFAST header byte in bits 15:8 (payload size code,
;               logical channel, CTS, as the frame has them), and in bits
;               4:0 the number of words that follow, less one
;   then      : the SIPI frame without its CRC, 16 bits a word, most
;               significant first: its header, then the address and the
;               data.
; The payload size in the header must be the SIPI frame's bytes, CRC
; included: 2 x (words + 1), so 1, 3, 5, 7, 15, 17 or 31 words for LFAST's
; sizes of 4 to 64 bytes. A word is taken as the one before it ends,
; one every 80 ticks, faster than the host port can push them: the
; driver fills the packet buffer and plays it into the FIFO.
next:   set pins, 0             ; the line low: idle
        pull                    ; the LFAST header, and the SIPI frame's words less one
        set pins, 1 [4]         ; the sync pattern, 1010 1000 0100 1011, 5 ticks a bit
        set pins, 0 [4]
        set pins, 1 [4]
        set pins, 0 [4]
        set pins, 1 [4]
        set pins, 0 [15]
        set y, 6 [3]
        set pins, 1 [4]
        set pins, 0 [9]
        set pins, 1 [4]
        set pins, 0 [4]
        set pins, 1 [9]
hb:     out pins, 1 [3]         ; the header byte
        jmp y-- hb
        out pins, 1             ; its last bit, 5 ticks with the next four
        out x, 8                ; X: the SIPI frame's words less one
        mov crc, null           ; the CRC covers the SIPI frame alone
        nop
word:   pull                    ; a word of the SIPI frame
bit:    out pins, 1 [1]         ; its bits
        jmp !osre more
        jmp x-- word
        mov isr, crc            ; the last bit has gone: the CRC, its top bit in bit 0
crc:    mov pins, isr [2]
        in null, 1
        jmp !isrf crc
        set pins, 0 [4]         ; the sleep bit: 0
        set y, 3
gap:    jmp y-- gap [14]        ; and the line idle for twelve bits
        jmp next
more:   jmp bit [1]
