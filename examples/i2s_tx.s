; i2s_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; I2S transmitter (Philips I2S, the bus between audio chips): the chip
; makes the bit clock and the word select and shifts out 16-bit stereo
; samples, most significant bit first.
;
; Pins: P0 = SCK and P1 = WS (side-set), P2 = SD, all push-pull. Config:
; [i2s_tx_config]: sideset_base 0, sideset_count 2; out_base 2,
; out_count 1; threshold 16; out_msb_first; start = [i2s_tx_start].
;
; Host protocol: TX words alternate left sample, right sample.
;
; On the wire, as the standard has it: SD and WS change while SCK is low
; and are read on its rising edge; WS is 0 for the left sample and 1 for
; the right, and changes one bit early, with the last bit of the sample
; before. So each sample's bits 15 to 1 go out under its own WS level and
; bit 0 under the next one's.
;
; Timing: SCK is 2 ticks low and 2 high, core clock / 4: 2.5 MHz at
; 10 MHz, a 78.125 kHz sample rate; CLKDIV slows it. The fetch of the next
; sample fits inside the last bit, so the clock never stretches while the
; host keeps up. When the TX FIFO is empty the thread stalls with SCK low
; and the bus simply pauses.
        .side_set 2
lbit:   out pins, 1      side 0 [1]   ; left bits 15..1: WS 0, SCK low
        jmp x-- lbit     side 1 [1]   ; SCK high
        out pins, 1      side 2       ; left bit 0, with WS already 1
        pull             side 2       ; the right sample
        set x, 14        side 3 [1]
rbit:   out pins, 1      side 2 [1]   ; right bits 15..1: WS 1
        jmp x-- rbit     side 3 [1]
        out pins, 1      side 0       ; right bit 0, with WS already 0
entry:  pull             side 0       ; the left sample
        set x, 14        side 1
        jmp lbit         side 1
