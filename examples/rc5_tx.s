; rc5_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; RC-5 infrared transmitter (Philips remote controls), carrier included:
; 14 bits of Manchester code, 1.778 ms each: two start bits, a toggle bit,
; 5 address bits and 6 command bits, MSB first. A 1 is half a bit of
; silence and then half a bit of 36 kHz carrier; a 0 the other way round.
;
; Pins: P0 = the LED, push-pull, high = lit. Config: [rc5_tx_config]:
; sideset_base 0, sideset_count 1; threshold 14; out_msb_first; CLKDIV
; sets the tick to half a carrier period: 139 for 36.0 kHz at 10 MHz.
;
; Host protocol: one TX word per frame, the 14 bits in bits 15:2
; ([rc5_word]).
;
; Timing, in ticks of 13.9 us: a burst is exactly 32 carrier periods (64
; ticks, 890 us), and where a 1 is followed by a 0 their two bursts are one
; unbroken burst of 64 periods, which is why the program looks a bit ahead
; before each burst. Silences are 64 ticks, or 65 between two 0s. A frame
; is followed by 89 ms of silence, so frames repeat every 114 ms as RC-5
; has them.
        .side_set 1
frame:  pull             side 0
        set y, 13        side 0        ; 13 more bits after the first
fetch:  out x, 1         side 0        ; a bit that arrives in silence
        jmp !x zero      side 0
one:    set x, 28        side 0        ; a 1: silence first
s1:     jmp x-- s1       side 0 [1]
        jmp y-- look     side 0        ; look at the bit after it
        jmp last         side 0        ; there is none
look:   out x, 1         side 0
        jmp !x long      side 0
        set x, 31        side 0        ; a 1 follows: 32 periods of carrier,
b1:     nop              side 1        ; then on to that 1's silence
        jmp x-- b1       side 0
        jmp one          side 0
zero:   set x, 31        side 0        ; a 0: carrier first
b0:     nop              side 1
        jmp x-- b0       side 0
        jmp sil          side 0
long:   set x, 30        side 0        ; a 0 follows a 1: their bursts are
l1:     nop              side 1        ; one, 64 periods long
        jmp x-- l1       side 0
        set x, 31        side 1        ; (the 32nd period, while reloading)
        nop              side 0
l2:     nop              side 1
        jmp x-- l2       side 0
sil:    set x, 29        side 0        ; the 0's silence
s0:     jmp x-- s0       side 0 [1]
        jmp y-- fetch    side 0
        jmp stop         side 0
last:   set x, 31        side 0        ; the last bit, a 1: its burst
b2:     nop              side 1
        jmp x-- b2       side 0
stop:   set y, 24        side 0        ; silence after the frame
gap:    set x, 31        side 0
g:      jmp x-- g        side 0 [7]
        jmp y-- gap      side 0
        jmp frame        side 0
