; ir_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Infrared burst sender: bursts of carrier with silences between them, each
; a whole number of carrier periods. The remote control codes are all
; made of these; which bursts and silences make a frame is the host's
; business, so one program sends any of them. RC-6 is sent with it
; ([rc6_words]); RC-5 and NEC have programs of their own, written before
; this one.
;
; Pins: P0 = the LED, push-pull, high = lit (side-set). Config:
; [ir_tx_config]: sideset_base 0, sideset_count 1; out most significant
; bit first; CLKDIV makes a tick half a carrier period: 139 for 36 kHz at
; 10 MHz.
;
; Host protocol: one TX word for a burst and the silence after it: the
; burst's carrier periods, less one, in bits 15:8, and the silence's, less
; three, in bits 7:0. The silence is counted from the end of the burst's
; last period to the start of the next burst, and the three are the ticks
; this program spends fetching the next word: that word must be in the
; FIFO by then, or the silence grows.
        .side_set 1
next:   pull                side 0     ; a burst and the silence after it
        out x, 8            side 0     ; carrier periods, less one
        out y, 8            side 0     ; periods of silence, less three
mark:   nop                 side 1     ; a carrier period: lit for a tick,
        jmp x-- mark        side 0     ; dark for a tick
space:  jmp y-- space       side 0 [1] ; silence, a period at a time
        jmp next            side 0
