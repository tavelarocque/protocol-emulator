; xy2_x: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; XY2-100, the interface of laser galvanometer scanners: a clock at 2 MHz,
; a sync line, and one data line for each axis, every line a differential
; pair on the real cable and one pin here. Each axis's frame is 20 bits,
; data changing as the clock rises and read as it falls: three control
; bits, 001 for a 16-bit position; the position, most significant bit
; first; and even parity over the 20. SYNC is high for the first 19 bits
; and low for the parity bit, so a frame ends where SYNC is low. Frames
; follow one another with no gap, 100,000 a second.
;
; Two threads, one for each axis, since each makes its own parity on its
; CRC register (polynomial x + 1, from 1 for the control bits' one 1). This
; program, on thread 0, makes CLK and SYNC and sends X; [xy2_y], on thread
; 1, sends Y, following thread 0's clock. CHAIN carries Y's position to
; it: the host sends both to thread 0.
;
; Pins: P0 = CLK and P1 = SYNC (side-set), P2 = X, all push-pull; P3 = Y,
; thread 1's. Config: [xy2_x_config] and [xy2_y_config], with the same
; CLKDIV, both threads enabled by one CTRL write with CHAIN. A bit is 5
; ticks, CLK high for 2 and low for 3, so CLKDIV 1 at 10 MHz and 5 at
; 50 MHz give the 2 MHz clock.
;
; Host protocol: TX words to thread 0, two a frame, X's position and then
; Y's. The next frame's words are taken in the low half of the parity
; bit; when they are not there the clock waits there, low with SYNC low,
; so frames run with no gap only while the host keeps two words ahead
; (the packet buffer can). Y's word reaches thread 1 during bit 0.
        .side_set 2                     ; CLK, SYNC
frame:  pull             side 0         ; X's position, in the last bit's low half
        mov y, osr       side 0
        pull             side 0         ; Y's
        set pins, 0      side 3         ; bit 0: CLK rises, SYNC high; control 0
        mov x, osr       side 3
        in x, 16         side 2         ; CLK falls
        push             side 2         ; Y's position to thread 1, by the chain
        mov osr, y       side 2         ; X's to send
        set pins, 0      side 3         ; bit 1: control 0
        mov crc, null    side 3         ; the parity starts again
        nop              side 2 [2]
        set pins, 1      side 3 [1]     ; bit 2: control 1
        nop              side 2 [2]
bit:    out pins, 1      side 3 [1]     ; bits 3 to 18, the position
        jmp !osre bit    side 2 [2]
        mov pins, crc    side 1         ; bit 19, the parity; SYNC low
        jmp frame        side 1
