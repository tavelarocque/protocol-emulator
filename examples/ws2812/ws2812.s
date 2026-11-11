; WS2812B driver for the protocol emulator, thread 0, P0 push-pull, 10 MHz.
;
; Config: start=latch, sideset_base=0, sideset_count=1, threshold=16,
;         out_msb_first=1 (see run_args.txt).
;
; Host words, per frame:
;   1. N = number of bits in the frame (24 per LED), 0..65535
;   2. ceil(N/16) data words: the G,R,B bytes of each LED in chain order,
;      MSB first, two bytes per word (first byte in bits 15..8).
; After the last bit the line is held low for ~310 us (the latch). The same
; latch runs at reset, so the line idles low before the first frame.
;
; Bit period 13 cycles (1.3 us):
;   1: high 8 (800 ns), low 5 (500 ns)
;   0: high 4 (400 ns), low 9 (900 ns)
; Cycle offsets below are relative to the cycle `hi` executes (c0).

        .side_set 1

have:   out x, 1        side 0 [2]  ; c0+10..12: next bit, OSR still had bits
hi:     jmp !x zero     side 1 [3]  ; c0..c0+3: line high
one:    jmp low         side 1 [3]  ; c0+4..7: stays high for a 1
zero:   nop             side 0 [3]  ; c0+4..7: low for a 0
low:    jmp y-- cont    side 0      ; c0+8: line low; more bits in this frame?
latch:  set x, 11       side 0      ; no: latch, 12 * 258 cycles low
lx:     set y, 31       side 0
ly:     jmp y-- ly      side 0 [7]
        jmp x-- lx      side 0
frame:  pull            side 0      ; bit count of the next frame
        out y, 16       side 0
        jmp low         side 0
cont:   jmp !osre have  side 0      ; c0+9
        pull            side 0      ; c0+10: OSR empty, refill
        out x, 1        side 0      ; c0+11
        jmp hi          side 0      ; c0+12
