; OOK transmitter, Manchester coded, 2000 bit/s at a 1 MHz core clock.
; Thread 0, P0 push-pull (set_base 0, set_count 1).
; Config: clkdiv=25, so one tick = 25 cycles, half a bit = 10 ticks,
; a bit = 20 ticks. out_msb_first=1, threshold=16.
; Every transition is written by a "set pins" on an exact tick, so the
; timing below is counted in ticks. B = tick a data bit starts.
;
; Word from host: bits 15..9 zero, bit 8 = last byte of frame, 7..0 = byte.
; After a pull: out null,7 drops bits 15..9, out y,1 puts the last flag in
; Y, then eight "out x,1" give the byte MSB first. After the 8th, the OSR
; count reaches 16 = threshold, so !osre is false at the byte's end.

start:  set pins, 0             ; drive the line low at once (tick 0)
        set x, 31
gap:    jmp x--, gap [15]       ; 32 x 16 = 512 ticks of silence
        pull                    ; first word of a frame; stalls (line low) when none
        out null, 7
        out y, 1                ; Y = last-byte flag
        set x, 15               ; 16 preamble bits
pre:    set pins, 1 [9]         ; T0 + 20k: rise, high 10 ticks
        set pins, 0 [8]         ; T0 + 20k + 10: fall
        jmp x--, pre            ; 9 + 1 = 10 ticks low
; sync nibble 0 1 0 1, S = T0 + 320 is the start of bit 16
        nop [9]                 ; S      : low first half of the 0
        set pins, 1 [15]        ; S + 10 : rise (middle of bit 16)
        nop [3]
        set pins, 0 [15]        ; S + 30 : fall (middle of bit 17)
        nop [3]
        set pins, 1 [15]        ; S + 50 : rise (middle of bit 18)
        nop [3]
        set pins, 0 [7]         ; S + 70 : fall (middle of bit 19)
; data bits: out x at B - 2, jmp at B - 1, set pins at B
bitgo:  out x, 1
        jmp !x, zero
one:    set pins, 1 [9]         ; B      : high first half
        set pins, 0             ; B + 10 : low second half
        jmp next                ; B + 11
zero:   set pins, 0 [9]         ; B      : low first half
        set pins, 1 [1]         ; B + 10 : high second half, 2 ticks
next:   jmp !osre, getbit       ; B + 12
        jmp y--, endframe       ; B + 13 : byte done; last byte of the frame?
        pull                    ; B + 14 : next byte of this frame
        out null, 7             ; B + 15
        out y, 1                ; B + 16
        jmp bitgo               ; B + 17 -> out x at B + 18
getbit: jmp bitgo [4]           ; B + 13 .. B + 17 -> out x at B + 18
endframe:
        jmp start [5]           ; B + 14 .. B + 19 -> set pins,0 at B + 20 (frame end)
