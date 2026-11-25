; iso7816_clk: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; The card's clock, on thread 1 beside [iso7816]: high one tick, low the
; next.
        .side_set 1
clk:    nop                 side 1
        jmp clk             side 0
