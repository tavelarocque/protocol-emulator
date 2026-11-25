; sirc_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Sony SIRC infrared transmitter, the 40 kHz carrier included, so the pin
; drives an IR LED. The program does the whole frame from the bits: the
; start burst, the code of every bit, and the frame period.
;
; SIRC counts in units of 600 us (24 carrier periods). A frame is a start
; burst of 4 units, then for each bit a unit dark and a burst, 2 units for
; a 1 and 1 for a 0; the bits go least significant first: 7 of command,
; then 5 of address (12-bit frames), 8 of address (15-bit) or 5 of address
; and 8 extended (20-bit). A remote repeats a frame every 45 ms, start to
; start, and so does this program: it counts the units each frame uses
; and stays dark for the rest of 75, so frames from the FIFO start
; exactly 45 ms apart (later, only if the host is late).
;
; Pins: P0 = the LED, push-pull, high = lit (side-set). Config:
; [sirc_tx_config]: sideset_base 0, sideset_count 1; threshold 16; in
; most significant bit first (the ISR holds the period's count, built
; with IN); CLKDIV makes a tick half a carrier period: 125 for 40 kHz at
; 10 MHz, 625 at 50 MHz. A unit is 48 ticks.
;
; Host protocol, one frame at a time ([sirc_words]):
;   TX word 0 : the number of bits: 12, 15 or 20
;   TX word 1 : the frame's first 16 bits, the first in bit 0: the
;               command in bits 6:0, the address from bit 7 up
;   TX word 2 : (20-bit frames) the last four bits, in bits 3:0
; The data words are taken before the start burst begins, and the second
; during the frame, so a 20-bit frame needs all three in the FIFO.
;
; Registers: X counts carrier periods and holds each bit; Y counts the
; bits; the ISR is the count of the period's units still to go.
        .side_set 1
next:   pull                side 0      ; the number of bits
        out y, 16           side 0
        set x, 17           side 0      ; ISR = 17 x 4 + 3 = 71: the units of
        mov isr, x          side 0      ;   the 75 (45 ms) left after the
        set x, 3            side 0      ;   start burst
        in x, 2             side 0
        pull                side 0      ; the first 16 bits
        set x, 23           side 0 [6]  ; the start burst: 4 units
        jmp burst           side 0
bit:    mov x, isr          side 0 [7]  ; a bit: first a unit dark, 48 ticks;
        jmp x-- d1          side 0 [7]  ;   the period loses two units, this
d1:     jmp x-- d2          side 0 [7]  ;   one and the burst's first
d2:     mov isr, x          side 0 [7]
        jmp !osre have      side 0
        pull                side 0      ; a 20-bit frame's last four bits
got:    out x, 1            side 0 [6]  ; the bit
        jmp !x zero         side 0
        mov x, isr          side 0      ; a 1: the burst's second unit
        jmp x-- d3          side 0
d3:     mov isr, x          side 0
        set x, 11           side 0      ; a burst of 2 units
        jmp burst           side 0
zero:   set x, 5            side 0 [4]  ; a burst of 1 unit
burst:  nop                 side 1      ; four carrier periods, lit a tick
        nop                 side 0      ;   and dark a tick
        nop                 side 1
        nop                 side 0
        nop                 side 1
        nop                 side 0
        nop                 side 1
        jmp x-- burst       side 0
        jmp y-- bit         side 0      ; the next bit, or the end of the frame:
        mov x, isr          side 0 [7]  ;   dark for the units the period has
        jmp x-- g0          side 0 [7]  ;   left, two of them as the ticks
g0:     jmp x-- g           side 0 [7]  ;   around this loop
g:      set y, 4            side 0 [3]  ; a unit
g1:     jmp y-- g1          side 0 [7]
        jmp x-- g           side 0 [3]
        jmp next            side 0 [7]
have:   jmp got             side 0      ; as long as the pull it stands for
