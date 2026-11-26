; DCF77 receiver, thread 0, core clock 100 kHz.
; Needs: clkdiv=100 (one tick = 1 ms), timeout=1350 (ticks), timeout_vector=gap (5),
;        in_base=0, in_msb_first=1. P0 is an input (default).
;
; A pulse's low time that follows it (fall to next rise) is 730..970 ms normally
; and 1730..1970 ms across a gap (missing pulse or minute marker). A timed wait
; for the next rise with a 1350 ms budget tells the two apart: on expiry the
; core jumps to `gap`. The pulse's bit is sampled about 150 ms after its rise.
;
; Phase A (addresses 0..4): skip everything until the first gap. No words.
start:  wait 0 pin 0            ; skip a pulse cut short at reset (and the sync's reset 1s)
        wait 1 pin 0            ; first whole rising edge
syncA:  wait 0 pin 0            ; falling edge
        wait 1 pin 0 timeout    ; next rise within 1350 ms, else jump to gap
        jmp syncA
; Phase B: report every pulse. Entered only from the timeout vector.
gap:    wait 1 pin 0            ; rise of bit 0 of a minute
        set y, 1                ; gap flag for this pulse
bit:    set x, 28
dly:    jmp x-- dly [4]         ; 29 * 5 = 145 ticks; P0 sampled ~149 ms after the rise
        in y, 1                 ; word bit 1: gap flag (msb-first: ends up above the data bit)
        in pins, 1              ; word bit 0: P0 still high means a long pulse (1)
        push
        set y, 0
        wait 0 pin 0            ; end of pulse
        wait 1 pin 0 timeout    ; next rise within 1350 ms, else gap
        jmp bit
