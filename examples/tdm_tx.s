; tdm_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; TDM audio (the DSP or PCM format of audio codecs): one data line
; carrying a frame of several 16-bit samples, one slot after another, with
; a pulse on the frame sync line to mark where the frame begins.
;
; Pins: P0 = BCLK and P1 = FSYNC (side-set), P2 = DATA, all push-pull.
; Config: [tdm_tx_config]: sideset_base 0, sideset_count 2; out_base 2,
; out_count 1; threshold 16; out most significant bit first.
;
; Host protocol: the first TX word is the slots in a frame, less one;
; after it one word per sample, slot 0 of
; the first frame first.
;
; On the wire: DATA and FSYNC change as BCLK falls and are read as it
; rises. FSYNC is high for one bit, the one before a frame's first: the
; last bit of the frame before (and one clock with nothing in it ahead of
; the first frame). Samples go most significant bit first.
;
; Timing: BCLK is 2 ticks low and 2 high, as in [i2s_tx]. The next sample
; is fetched inside the last bit, so the clock never stretches while the
; host keeps up; with the TX FIFO empty the thread stalls with BCLK low.
        .side_set 2
        pull              side 0       ; slots in a frame, less one
        mov isr, osr      side 0       ; kept in the ISR
        mov y, isr        side 0
        jmp sync          side 0
bit:    out pins, 1       side 0 [1]   ; bits 15..2 of a sample: BCLK low,
        jmp x-- bit       side 1 [1]   ; and high
        out pins, 1       side 0 [1]   ; bit 1
        jmp !y last       side 1       ; the frame's last slot?
        nop               side 1
        out pins, 1       side 0       ; bit 0
        pull              side 0       ; the next slot's sample
        set x, 13         side 1
        jmp y-- bit       side 1
last:   mov y, isr        side 1       ; slots, for the next frame
sync:   out pins, 1       side 2       ; bit 0 with FSYNC high
        pull              side 2       ; the next frame's first sample
        set x, 13         side 3
        jmp bit           side 3
