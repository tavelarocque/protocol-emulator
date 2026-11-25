; caliper: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; A digital caliper's data port, as cheap calipers send it: the chip is
; the caliper, sending a reading the host gives. A packet is 24 bits, least
; significant first, each read as CLK rises: the reading in bits 15:0 (bits
; 19:16 are 0 here: no reading above 655.35 mm), the sign in bit 20 (1 for
; negative), 0 in bits 21 and 22, and the unit in bit 23 (1 for inches).
; The reading counts hundredths of a millimetre, or halves of a
; thousandth of an inch. CLK rests high between packets.
;
; Pins: P0 = CLK (side-set), P1 = DATA, push-pull. Config:
; [caliper_config]: sideset_base 0, sideset_count 1; out_base 1;
; threshold 16; shifts least significant bit first. A bit is 8 ticks, CLK
; low for 4 with DATA changed as it falls, and high for 4; calipers clock
; at about 77 kHz, a bit of 13 us: CLKDIV 16 at 10 MHz (12.8 us), 81 at
; 50 MHz (12.96 us).
;
; Host protocol: two TX words a packet: the reading, then a word with
; bit 0 set for a negative reading and bit 1 for inches. The firmware
; places those two bits in the packet's top byte in the ISR, and sends
; that byte from the ISR's bottom bit, shifting it down. After each
; packet CLK stays high for 64 bit times or more (0.8 ms at 13 us), so
; that a reader can tell where the next one starts.
        .side_set 1
next:   pull               side 1       ; the reading
        mov y, osr         side 1
        pull               side 1       ; bit 0 negative, bit 1 inches
        in null, 4         side 1       ; the packet's bits 16 to 19: 0
        out x, 1           side 1
        in x, 1            side 1       ; bit 20: the sign
        in null, 2         side 1       ; 21 and 22: 0
        out x, 1           side 1
        in x, 1            side 1       ; bit 23: inches
        in null, 8         side 1       ; those eight at the ISR's bottom
        mov osr, y         side 1
        set y, 7           side 1
bit:    out pins, 1        side 0 [3]   ; bits 0 to 15: DATA as CLK falls,
        jmp !osre bit      side 1 [3]   ; read as it rises
top:    mov pins, isr      side 0 [3]   ; bits 16 to 23
        in null, 1         side 1 [2]
        jmp y-- top        side 1
        set x, 31          side 1
rest:   nop                side 1 [7]   ; 64 bit times
        jmp x-- rest       side 1 [7]
        jmp next           side 1
