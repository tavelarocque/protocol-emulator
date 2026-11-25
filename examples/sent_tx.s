; sent_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SAE J2716 SENT, a sensor's transmitter: one line, frames of nibbles
; each told by the time from one falling edge to the next. A frame is a
; calibration pulse of 56 ticks, a status nibble, the data nibbles and a
; CRC-4 nibble, then a pause pulse; a nibble of value v lasts 12 + v
; ticks. Every pulse is low for 5 ticks and high for the rest.
;
; Pins: P0 = the SENT line, push-pull; it idles high. Config:
; [sent_tx_config]: set_base 0, set_count 1; threshold 16; out most
; significant bit first; the CRC register at x^4 + x^3 + x^2 + 1
; ([sent_crc_poly]), from [sent_crc_init]. A thread tick is half a SENT
; tick: CLKDIV 15 for the nominal 3 us tick at 10 MHz, 75 at 50 MHz; 450
; at 10 MHz for the longest the standard has, 90 us.
;
; Host protocol:
;   TX : once, N - 1, where N is the number of data nibbles in a frame (1
;        to 6 in the standard). Then for each frame its status nibble and
;        its N data nibbles, four to a word, the first in bits 15:12
;        ([sent_words]); what is left of a frame's last word is not sent.
;   RX : nothing.
;
; The CRC is the chip's: SAE J2716's recommended CRC-4, seed 0101, over
; the data nibbles but not the status, with a nibble of zeros after them.
; The CRC register follows each bit OUT shifts, most significant first.
; It takes each bit in at the top, as if a nibble of zeros followed, so
; it starts from the seed times x^4, 0011, and needs no zeros at the end.
; It shifts right, so it holds the CRC with its bits reversed, and starts
; from 0011 reversed. The status nibble is taken with one OUT of four bits, whose first bit the
; register takes before the next instruction starts it again. A data
; nibble's high time is its four bits one at a time: 8, 4, 2 and 1 ticks
; for those that are 1. The CRC's bits come out of the register least
; significant first, so its nibble waits 1, 2, 4 and 8.
;
; The pause pulse makes the frame 120 ticks longer: the standard allows
; 12 to 768, and sigrok's decoder finds the end of a frame only at a pulse
; of more than 100. While the host has no frame the line stays high, so a
; pause lasts until the next frame. Within a frame a word is needed every
; four nibbles; one that comes late stretches the low time of the nibble
; that waits for it.
        set pins, 1             ; the line idles high
        pull                    ; N - 1, once
        mov isr, osr            ; kept in the ISR
frame:  pull                    ; a frame: the status nibble first
        set pins, 0 [9]         ; 0: calibration pulse, low for 5 ticks
        set pins, 1             ; 10
        set y, 22               ; 11
cal:    jmp y-- cal [3]         ; 12..103
        nop [7]                 ; 104..111: 56 ticks in all
        set pins, 0             ; 0: the status nibble
        out x, 4                ; 1: its value; the CRC takes its first bit
        mov crc, null           ; 2: and starts again
        nop [6]                 ; 3..9
        set pins, 1             ; 10
st:     jmp x-- st [1]          ; 11..12+2s
        mov x, isr [10]         ; ..23+2s: N - 1 data nibbles after the next
data:   set pins, 0             ; 0: a data nibble
        jmp !osre have          ; 1
        pull                    ; 2: four nibbles to a word
        jmp low                 ; 3
have:   nop [1]                 ; 2..3
low:    nop [5]                 ; 4..9
        set pins, 1             ; 10
        out y, 1                ; 11: its bits, most significant first;
        jmp !y d4               ; 12  the CRC takes each
        nop [15]                ; 8 ticks for an 8
d4:     out y, 1
        jmp !y d2
        nop [7]
d2:     out y, 1
        jmp !y d1
        nop [3]
d1:     out y, 1
        jmp !y dend
        nop [1]
dend:   jmp x-- data [4]        ; ..23+2v
        set pins, 0             ; 0: the CRC nibble
        mov osr, crc            ; 1: in bits 3:0, reversed; the CRC stops
        out null, 12            ; 2
        nop [6]                 ; 3..9
        set pins, 1             ; 10
        out y, 1                ; 11: its least significant bit,
        jmp !y c2               ; 12
        nop [1]                 ; 1 tick
c2:     out y, 1
        jmp !y c4
        nop [3]
c4:     out y, 1
        jmp !y c8
        nop [7]
c8:     out y, 1
        jmp !y cend
        nop [15]
cend:   nop [4]                 ; ..23+2c
        set pins, 0 [9]         ; 0: the pause pulse
        set pins, 1             ; 10
        set y, 13               ; 11
pause:  jmp y-- pause [15]      ; 12..235
        jmp frame [2]           ; 236..238; the next frame's pull, 239
