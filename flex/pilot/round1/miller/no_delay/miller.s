; Miller (delay encoding) transmitter: a fixed-rate level streamer.
;
; The host does the Miller coding (host.py). Each TX word holds 16 line
; levels, one per half bit (5 us), first level in bit 0. The thread runs
; with clkdiv = 25, so this two-instruction loop is 2 ticks = 50 cycles:
; exactly one half bit per `out`. Autopull (threshold 16) refills the OSR
; in the same tick as the 16th `out`, so there is never a gap between
; words. When the words run out, `out` stalls and P0 keeps its level.
;
; Needs: clkdiv 25, autopull, threshold 16, out_base 0, out_count 1,
; P0 push-pull (see run_args.txt).

loop:   out pins, 1     ; next half-bit level to P0
        jmp loop
