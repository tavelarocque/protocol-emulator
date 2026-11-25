; spacewire_ds: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SpaceWire's data-strobe encoding, on thread 1 beside [spacewire_chars]
; on thread 0 (see there). Two bits a word, from the chain: after a bit in
; an even place D and S differ, after one in an odd place they are equal,
; so exactly one of them changes every bit; both start low, as a link
; does after reset. A bit is 5 ticks: CLKDIV 1 gives 2 Mbit/s at 10 MHz,
; the standard's lowest data signalling rate, and 10 Mbit/s at 50 MHz, the
; rate a link starts at. When the bits run out the lines hold still, which
; a receiver takes for a disconnect after 850 ns: this is a transmitter
; only, and sends no FCT of its own.
;
; Real links are LVDS pairs: the pins are the inputs of an LVDS driver
; for each of D and S.
;
; Pins: P0 = D, P1 = S, push-pull. Config: [spacewire_ds_config]:
; set_base 0, set_count 2; threshold 2, autopull; shifts least
; significant bit first; CLKDIV sets the rate.
        set pins, 0             ; D and S low
even:   out x, 1
        jmp !x e0
        set pins, 1 [1]         ; D 1, S 0
        jmp odd
e0:     set pins, 2 [1]         ; D 0, S 1
        jmp odd
odd:    out x, 1
        jmp !x o0
        set pins, 3 [1]         ; D 1, S 1
        jmp even
o0:     set pins, 0 [1]         ; D 0, S 0
        jmp even
