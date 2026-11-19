; mdio: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; MDIO controller (IEEE 802.3 clause 22, the management bus of Ethernet
; PHYs): a clock and one data line, 32 ones of preamble and then a 32-bit
; frame, MSB first, of which the PHY drives the last 17 bits in a read.
;
; Pins: P0 = MDC (side-set, push-pull); P1 = MDIO, open-drain with the
; bus's pull-up, so writing a 1 releases the line for the PHY. Config:
; [mdio_config]: sideset_base 0, sideset_count 1; out_base 1, in_base 1;
; threshold 16; both shift directions MSB first.
;
; Host protocol: every TX word is 16 bits shifted out, and comes back as an
; RX word of the 16 bits read on the line at the same time. A frame is
; four words: 0xFFFF, 0xFFFF, the header ([mdio_header]), and the data to
; write or 0xFFFF to read. In a read the fourth RX word is the register,
; and bit 0 of the third is the PHY's turnaround bit: 0 when one answered.
;
; Timing, in cycles: MDC is 2 low and 2 high (5 low between words, or as
; long as the host takes); MDIO
; changes one cycle after MDC falls, which gives a PHY one cycle of setup
; and two of hold. What is shifted in is the line as it stood one cycle
; before MDC rose (the synchroniser's two cycles are counted in that), so a
; PHY has three cycles after one rising edge to drive the bit for the
; next. At 10 MHz with CLKDIV 1 that is MDC at 2.5 MHz and exactly the
; 300 ns the standard allows a PHY, with nothing to spare; the driver's
; default is CLKDIV 2, 1.25 MHz, which leaves 300 ns of margin.
        .side_set 1
next:   pull           side 0
bit:    out pins, 1    side 0       ; MDC low: the next bit goes out
        nop            side 1       ; MDC rises
        in pins, 1     side 1       ; the line as it was just before
        jmp !osre bit  side 0       ; MDC falls
        push           side 0
        jmp next       side 0
