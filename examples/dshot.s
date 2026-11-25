; dshot: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; DShot, a flight controller's command to a motor's speed controller (ESC):
; 16-bit frames on one wire, most significant bit first. Bits 15:5 are the
; value (0 disarms, 1 to 47 are commands, 48 to 2047 throttle), bit 4 asks
; the ESC for telemetry, and bits 3:0 are the checksum: the exclusive or of
; the three nibbles of the 12 bits before it. Every bit has the same
; period and begins with the line rising; a 0 is high for 37.5% of it and
; a 1 for 75%, the DShot600 numbers (625 ns and 1250 ns of 1670 ns).
;
; Pins: P0 = the line, push-pull (side-set), low between frames. Config:
; [dshot_config]: sideset_base 0, sideset_count 1; threshold 16; out most
; significant bit first, in least significant first; the CRC register
; with polynomial x^4 + 1 (0x8) from 0, whose remainder is that exclusive
; or. A bit is 8 ticks, so CLKDIV is the clock over eight times the bit
; rate, rounded: at 10 MHz, 2 is 625 kbit/s (DShot600, 4% fast), 4 is
; DShot300 and 8 DShot150, both 4% fast; at 50 MHz, 10 is DShot600 (4%
; fast) and 5 DShot1200, 21 and 42 DShot300 and DShot150 (1% slow).
;
; Host protocol: one TX word a frame, the value shifted left once with the
; telemetry bit below it, in bits 11:0 ([dshot_word]). The firmware makes
; the checksum: the CRC register follows the 12 bits, OUT to nowhere, and
; since it shifts right its remainder comes out reversed, so four OUTs
; and INs turn it round in the ISR, under the 12 bits. That takes 44
; ticks with the line low, so a frame's last fall and the next one's first
; rise are 47 ticks (5.9 bit times) apart or more; with the FIFO empty the
; line stays low. Bidirectional DShot is not made: see the cocotb test.
        .side_set 1
next:   pull                side 0      ; a frame: the 12 bits in 11:0
        mov y, osr          side 0      ; kept to send
        out null, 4         side 0      ; bits 15:12 are not sent
        mov crc, null       side 0      ; the checksum from 0
sum:    out null, 1         side 0      ; the CRC register follows the 12 bits
        jmp !osre sum       side 0
        mov osr, crc        side 0      ; the checksum, its first bit lowest
        out null, 12        side 0
rev:    out x, 1            side 0      ; turned round in the ISR, which
        in x, 1             side 0      ; shifts right
        jmp !osre rev       side 0
        in y, 12            side 0      ; the 12 bits above it
        mov osr, isr        side 0      ; the frame
bit:    out x, 1            side 0 [1]  ; the end of the bit before: low
        jmp !x zero         side 1 [2]  ; every bit is high for 3 ticks
        jmp !osre bit       side 1 [2]  ; a 1 for 3 more
        jmp next            side 0
zero:   jmp !osre bit       side 0 [2]  ; a 0 is low
        jmp next            side 0
