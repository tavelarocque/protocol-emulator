; tlc5620: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; TLC5620 (a serial quad 8-bit DAC): 11 bits clocked in, a pulse on LOAD
; to put them in the chosen DAC's latch, and a pulse on LDAC to bring the
; latched values to all four outputs together.
;
; Pins: P0 = CLK (side-set), P1 = DATA, P2 = LOAD, P3 = LDAC, all
; push-pull. Config: [tlc5620_config]: sideset_base 0, sideset_count 1;
; out_base 1, out_count 1; set_base 2, set_count 2; out most significant
; bit first; a tick of 100 ns or more (CLKDIV 1 at 10 MHz, 5 at 50 MHz).
;
; Host protocol: one TX word per write ([tlc5620_word]): the DAC (0 to 3)
; in bits 15:14, the range bit (1 doubles the output) in bit 13, the value
; in bits 12:5, and bit 4 set to pulse LDAC after it. With LDAC pulsed
; only on the last of several writes, their outputs change together.
;
; On the wire: DATA changes as CLK rises and the DAC takes it as CLK
; falls; LOAD and LDAC are low for three ticks.
        .side_set 1
        set pins, 3       side 0       ; LOAD and LDAC high
next:   pull              side 0       ; a write
        set x, 10         side 0
bit:    out pins, 1       side 1       ; DATA, as CLK rises
        jmp x-- bit       side 0       ; taken as CLK falls
        set pins, 2       side 0 [2]   ; LOAD low: into the DAC's latch
        set pins, 3       side 0
        out x, 1          side 0       ; the outputs too?
        jmp !x next       side 0
        set pins, 1       side 0 [2]   ; LDAC low
        set pins, 3       side 0
        jmp next          side 0
