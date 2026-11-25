; xy2_y: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; XY2-100's Y axis, on thread 1, beside [xy2_x] on thread 0 (see there).
; It reads CLK on P0 and SYNC on P1, thread 0's outputs, which a thread
; sees a tick after they are written, and drives Y on P3. A wait on CLK
; low completes in the first low tick; one tick of delay and the next
; instruction writes Y in the tick in which thread 0 raises CLK and writes
; X, so all three change together. Each bit is four instructions in five
; ticks: wait for CLK low, write, wait for CLK high, and one more. Before
; bit 0 thread 0 may be waiting for the host with CLK low: Y is then 0, bit
; 0's value, until CLK rises.
;
; Config: [xy2_y_config]: out_base 3, set_base 3; threshold 16; out most
; significant bit first; the CRC register as thread 0's; CLKDIV as thread
; 0's.
        wait 0 pin 1                    ; SYNC low: before the first frame
frame:  wait 0 pin 0 [1]                ; CLK low in the last bit, or idle
        set pins, 0                     ; bit 0, as CLK rises
        wait 1 pin 0
        wait 0 pin 0 [1]
        set pins, 0                     ; bit 1
        wait 1 pin 0
        pull                            ; the position, from thread 0
        wait 0 pin 0 [1]
        set pins, 1                     ; bit 2
        wait 1 pin 0
        mov crc, null                   ; the parity starts again
bit:    wait 0 pin 0 [1]
        out pins, 1                     ; bits 3 to 18
        wait 1 pin 0
        jmp !osre bit
        wait 0 pin 0 [1]
        mov pins, crc                   ; bit 19, the parity
        wait 1 pin 0
        jmp frame
