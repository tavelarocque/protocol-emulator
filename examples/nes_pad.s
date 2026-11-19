; nes_pad: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; NES gamepad, read as the console reads it: a pulse on the latch line
; makes the pad's shift register take in its eight buttons, and eight
; clocks bring them out, A first; a pressed button reads 0.
;
; Pins: P0 = latch and P1 = clock (side-set, push-pull), P2 = data, an
; input. Config: [nes_pad_config]: sideset_base 0, sideset_count 2;
; in_base 2; threshold 8; in_msb_first; CLKDIV sets the tick to 3 us: 30
; at 10 MHz.
;
; Host protocol: any TX word asks for one reading; the RX word is the
; buttons, A in bit 7, then B, Select, Start, Up, Down, Left, Right.
;
; Timing, as the console's: latch high 12 us, then the clock, idle high,
; low 6 us and high 6 us for each button. A button is read as the clock
; falls; the pad moves to the next as it rises.
        .side_set 2                 ; bit 0 the latch, bit 1 the clock
next:   pull           side 2       ; until the host asks
        nop            side 3 [3]   ; latch: the pad takes in its buttons
        set x, 7       side 2 [1]
bit:    in pins, 1     side 0 [1]   ; read a button; the clock falls
        jmp x-- bit    side 2 [1]   ; the clock rises: the pad moves on
        push           side 2
        jmp next       side 2
