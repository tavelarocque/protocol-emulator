; microwire: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Microwire controller, as the 93Cxx serial EEPROMs speak it: chip select
; high for a transfer, one bit to the device and one from it on every
; clock, any number of bits.
;
; Microwire is SPI's older relative, but the SPI engines do not fit it:
; chip select is active high, and a transfer is not a whole number of
; bytes (a 93C46 command is a start bit, two opcode bits and six address
; bits, with sixteen data bits after it one way or the other).
;
; Pins: P0 = CS (push-pull, high for a transfer), P1 = SK (side-set), P2 =
; DI, to the device; P3 = DO, from it. Config: [microwire_config]:
; sideset_base 1, sideset_count 1; set_base 0, set_count 1; out_base 2,
; out_count 1; in_base 3; threshold 16; autopull, autopush; out and in
; most significant bit first. A bit is 5 ticks, SK low for 3 and high for
; 2: CLKDIV 3 for 667 kHz at 10 MHz.
;
; The device takes DI as SK rises and changes DO just after; DO is read
; one tick after SK rises, so the bit read on a clock is the device's
; answer to that clock. DO comes through the input synchroniser, which
; takes two cycles, so a tick must be at least three: CLKDIV 3 or more.
;
; Host protocol:
;   TX : the number of bits, less one; then the bits to send, 16 to a
;        word, the first in the top bit (a last word's bits at its top).
;   RX : the bits read, one for every clock, 16 to a word, first in the
;        top bit; the last word holds what is left, lowest bits, and is
;        empty when nothing is.
        .side_set 1
idle:   set pins, 0         side 0     ; CS low: no transfer
        pull                side 0     ; the number of bits, less one
        out y, 16           side 0
        set pins, 1         side 0     ; CS high
bit:    out pins, 1         side 0 [1] ; DI while SK is low
        nop                 side 1     ; SK rises: the device takes the bit
        in pins, 1          side 1     ; and its answer is read before SK falls
        jmp y-- bit         side 0
        push                side 0     ; what is left of the last word
        jmp idle            side 0
