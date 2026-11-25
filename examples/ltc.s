; ltc: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SMPTE linear timecode (LTC) at 25 frames a second, as EBU uses it: an
; 80-bit frame every 40 ms, 2000 bit/s, in biphase mark code: the level
; turns over at the start of every bit, and a 1 turns it over in its
; middle too. A frame is the time and the user bits laid out as SMPTE 12M
; has them, least significant bit first (frame units 0-3, user bits 4-7,
; frame tens 8-9, drop frame 10, colour frame 11, user bits 12-15, then
; seconds, minutes and hours the same way, with flags at 27, 43, 58 and
; 59), and then the sync word 0011 1111 1111 1101.
;
; The host sends each frame's first 64 bits as four words; the firmware
; sends them biphase coded with nothing between frames, makes the sync
; word, and puts the polarity correction bit (bit 59 at 25 frames a
; second) into each frame: it makes the frame's 1s even, so every frame
; starts with the line at the same level. That bit depends on bits that
; come after it (60 to 63), so when the fourth word arrives it is run
; through the CRC register (polynomial 1: the parity of every bit OUT
; shifts) before it is sent: all its bits once, bit 48 twice more and bit
; 59 once more, which with the three words before leaves the parity of
; every bit but 59; read inverted, that is the polarity bit, and the word
; is put back together around it in the ISR. Bit 59 as the host sends it
; does not count.
;
; The level is Y's bit 0: Y counts down once for every edge, and
; [mov pins, y] puts it out. The ISR counts the frame's five words
; (four, then the sync word, built in the ISR from SET values); at the
; end of each word the count picks what comes next, with every path the
; same length.
;
; It does not count the frames itself: the host sends every frame's time.
; It sends only 25 frame timecode: at 30 frames a second the polarity bit
; is bit 27, and it depends on 36 bits the host has not sent by then.
;
; A half bit is 100 ticks: 25 frames a second with CLKDIV 25 at 10 MHz,
; 125 at 50 MHz, 1 at 400 kHz, all exact. A real LTC output is an audio
; level signal: the pin needs a level shifter or a transformer.
;
; Pins: P0 = the line, push-pull. Config: [ltc_config]: out_base 0,
; out_count 1; set_base 0, set_count 1; threshold 16; least significant
; bit first; crc_poly 1, crc_init 0, crc_invert.
;
; Host protocol: four words for each frame, bits 0-15, 16-31, 32-47 and
; 48-63 ([ltc_words]). A frame's first word is taken as its first bit
; starts, the others a bit before they are needed, so the host has a
; frame's time (40 ms) to send the next; if it sends none, the line
; stays at the level the last frame's sync word ended with an edge to.
        set y, 1                ; the level, turned over before each bit: low first
        pull                    ; the first frame's first word: wait for the host
        set x, 5
        mov isr, x              ; five words to a frame
        jmp bit                 ; the first edge
frame:  mov crc, null           ; 108: the parity, from 0
        set x, 5                ; 109
        mov isr, x              ; 110: five words to the frame
        set x, 21               ; 111
fw:     jmp x-- fw [3]          ; 112..199
        jmp y-- fe              ; 0: the level turns over
fe:     mov pins, y             ; 1: the edge the frame's first bit starts with
        pull                    ; 2: its first word: wait for the host
        jmp bo                  ; 3
bit:    jmp y-- edge            ; 0: the level turns over
edge:   mov pins, y [2]         ; 1..3: the edge every bit starts with
bo:     out x, 1                ; 4: the bit; the CRC register takes it
        jmp !x zero             ; 5
        set x, 22 [1]           ; 6..7: a 1
one:    jmp x-- one [3]         ; 8..99
        jmp y-- mid             ; 100
mid:    mov pins, y             ; 101: its edge in the middle
        jmp rest                ; 102
zero:   set x, 23               ; 6: a 0
zl:     jmp x-- zl [3]          ; 7..102
rest:   jmp !osre more          ; 103
        mov x, isr              ; 104: the word has gone
        jmp x-- dw              ; 105
dw:     mov isr, x              ; 106
        jmp !x frame            ; 107: the sync word: a new frame
        jmp x-- dx              ; 108
dx:     jmp !x tosync           ; 109: the fourth word: the sync word next
        jmp x-- dz              ; 110
dz:     jmp !x last             ; 111: the third: the fourth next
        pull                    ; 112: the second or the third word
wt:     set x, 20               ; 113
wl:     jmp x-- wl [3]          ; 114..197
        jmp bit [1]             ; 198..199
more:   jmp wt [8]              ; 104..112
last:   pull                    ; 112: the fourth word; its bit 11 is bit 59
        mov isr, osr            ; 113: a copy
        out null, 1             ; 114: bit 48 to the parity
        mov osr, isr            ; 115
        set x, 15               ; 116
lp:     out null, 1             ; 117..148: bits 48 to 63 to the parity
        jmp x-- lp
        mov osr, isr            ; 149
        mov isr, null           ; 150
        out x, 11               ; 151: bits 48 to 58; 48 to the parity a third time
        in x, 11                ; 152
        out null, 1             ; 153: bit 59, to the parity a second time
        mov x, crc              ; 154: the parity of the rest, inverted: the polarity bit
        in x, 1                 ; 155
        out x, 4                ; 156: bits 60 to 63
        in x, 4                 ; 157
        mov osr, isr            ; 158: the word with its polarity bit
        set x, 2                ; 159
        mov isr, x              ; 160: two words left
        set x, 8                ; 161
ll:     jmp x-- ll [3]          ; 162..197
        jmp bit [1]             ; 198..199
tosync: set page, 1             ; 110
        jmp sync                ; 111
.align
sync:   mov isr, null           ; 112
        in null, 2              ; 113: bits 64 and 65: 0
        set x, 31               ; 114
        in x, 5                 ; 115: 66 to 70: 1
        in x, 5                 ; 116: 71 to 75
        in x, 2                 ; 117: 76 and 77
        in null, 1              ; 118: 78: 0
        set x, 1                ; 119
        in x, 1                 ; 120: 79: 1
        mov osr, isr            ; 121: the sync word
        mov isr, x              ; 122: one word left
        set x, 17               ; 123
sl:     jmp x-- sl [3]          ; 124..195
        set page, 0 [2]         ; 196..198
        jmp bit                 ; 199
