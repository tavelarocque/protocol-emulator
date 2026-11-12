; echo: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Echo: every 16-bit word the host pushes to the TX FIFO comes back on the
; RX FIFO unchanged. Exercises the whole host data path (SPI, both FIFOs,
; OSR, ISR) with no pins involved.
loop:   pull
        out x, 16
        in x, 16
        push
        jmp loop
