; dali_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; DALI receiver: the other direction of [dali_tx], for one thread with the
; bit sampler in front of it. A controller reads a gear's 8-bit answers
; with it; it reads 16- and 24-bit frames the same way.
;
; A frame starts with an edge that is not in the middle of a bit (the bus
; falls for the start bit's first half), so the sampler is not locked to
; the middles of bits, as it is for Ethernet. It is set to take every
; edge and a sample every half bit: what reaches this program is the
; bus's level in each half bit, from the start bit's first half on. The
; prescaler makes a sample 1/10 of a half bit, and this thread's CLKDIV
; is the same number, so each of the sampler's pulses is one tick long.
;
; Pins: P1 = the bus as received, high when idle (input); P2 is taken by
; the sampler's pulse. Config: [dali_rx_config ~clkdiv], sampler:
; [dali_rx_sampler ~clkdiv], with CLKDIV 417 for 1200 bit/s at 10 MHz.
;
; Host protocol, for each frame:
;   RX : the half bits, 16 to a word, the first received in the top bit;
;        the last word holds what is left, lowest bits, and is empty if
;        nothing is; then 0x10000 minus the number of half bits.
; [dali_rx_frame] pairs the half bits up into the frame's bits. After
; the last bit the bus is idle and two or three high half bits follow
; before the sampler gives up: two high in one bit is not a bit, and that
; is how the end is told from data.
;
; The count is how the host finds the end of a frame's words: it is
; 0xFF00 or more for anything under 256 half bits, and no other word can
; be, because the sampler never passes more than three equal half bits
; in a row and the last word's top bits are clear ([dali_rx_frames]).
; When the sampler is switched on it reports the idle bus once, as three
; high half bits: that is no frame, like any other report without a
; start bit. A frame that begins inside that report is still read: high
; half bits before a frame's first low one are the idle bus.
;
; Timing: an edge is taken whenever it comes, and each half bit is
; sampled in its middle counting from the last edge. Two half bits can
; pass between edges, so a sender 15% fast or slow is read (DALI allows
; 10%).
rx:     mov x, null
        jmp x-- first           ; X = 0xFFFF: it counts the half bits, downwards
first:  wait 1 pin 2            ; a frame's first half bit
half:   in pins, 1              ; take it; sixteen make a word
        wait 1 pin 2 timeout    ; the next, or the end of the frame
        jmp x-- half
eof:    push                    ; what is left of the last word
        in x, 16                ; then the count
        jmp rx
