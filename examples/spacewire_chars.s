; spacewire_chars: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SpaceWire (ECSS-E-ST-50-12C), data-strobe encoded: two lines, D
; carrying the bits and S changing whenever D does not, so that exactly
; one of the two changes every bit. The characters: a data character is a
; parity bit, a 0 flag and 8 bits least significant first; a control
; character a parity bit, a 1 flag and two bits (FCT 00, EOP 01, EEP 10,
; ESC 11, in the order sent); NULL is ESC then FCT. Each parity bit makes
; the ones odd over itself, the flag after it and the data bits of the
; character before.
;
; Two threads. This program, on thread 0, makes the characters: it reads
; the host's words, works out each parity bit and pushes the bits, two to
; an RX word, which CHAIN carries to thread 1. [spacewire_ds] on thread 1
; puts them on D and S at one bit every 5 ticks. Every character is an
; even number of bits, so a word never straddles two. The parity is the
; CRC register, which follows the bits IN shifts (polynomial 1: its bit 0
; is their parity): it starts again after each flag, so when the next
; character comes it holds the parity of the last one's data bits, the
; parity bit of a control character (flag 1), and its opposite that of a
; data character, X less one being X's bit 0 turned over.
;
; Config: [spacewire_chars_config]: threshold 2, autopush; shifts least
; significant bit first; crc_poly 1, crc_init 0, crc_in. CHAIN on.
;
; Host protocol on thread 0's TX FIFO:
;   0x000 to 0x0FF : a data character
;   0x100          : EOP, the end of a packet
;   0x200 + n      : n NULLs (1 to 255)
; A link starts with NULLs; so the first word should be some. The line
; takes a data character every 50 ticks, faster than the host port can
; push words: the driver plays them from the packet buffer.
next:   pull
        mov y, osr              ; the word, kept
        out null, 8
        out x, 1                ; bit 8: EOP
        jmp !x notend
        mov x, crc              ; EOP: the parity,
        in x, 1
        set x, 1
        in x, 1                 ; the flag 1,
        mov crc, null
        in null, 1              ; then 0, 1
        in x, 1
        jmp next
notend: out x, 1                ; bit 9: NULLs
        jmp !x data
        mov osr, y
        out y, 8                ; how many
nulls:  jmp y-- null
        jmp next
null:   mov x, crc              ; ESC: the parity,
        in x, 1
        set x, 1
        in x, 1                 ; the flag 1,
        mov crc, null
        in x, 1                 ; 1, 1
        in x, 1
        mov x, crc              ; FCT: the parity,
        in x, 1
        set x, 1
        in x, 1                 ; the flag 1,
        mov crc, null
        in null, 1              ; 0, 0
        in null, 1
        jmp nulls
data:   mov x, crc              ; a data character: the parity,
        jmp x-- dpar            ; turned over: X less one
dpar:   in x, 1
        in null, 1              ; the flag 0,
        mov crc, null
        mov osr, y
        set y, 7
dbit:   out x, 1                ; the 8 bits, least significant first
        in x, 1
        jmp y-- dbit
        jmp next
