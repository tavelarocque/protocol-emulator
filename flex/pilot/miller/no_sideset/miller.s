; Miller (delay) encoder on P0, thread 0.   27 instructions.
;
; Configuration (run_args.txt):
;   clkdiv=5          one tick = 5 cycles: a bit is 20 ticks, half a bit 10
;   set_base=0, set_count=1    "set pins" writes P0
;   threshold=8       "!osre" turns false after the 8 data bits of a word
;   timeout=0, timeout_vector=8 (label "fall")
;
; There is no "toggle pin" and no jump on a pin, so the line is turned over
; with a timed wait whose budget is 0: "wait 0 pin 0 timeout" falls through
; when P0 reads low and jumps at once to timeout_vector when it reads high.
;
; X = the bit being sent (or the last-byte flag). Y = the bit before it.
; Tick numbers in the comments count ticks; "set pins" executes on tick t for
; a transition, and N is that tick for the next bit boundary.
; Code reached with Y = 0 runs 2 ticks earlier than with Y = 1 ("early" and
; "late"): after a 0 there are 20 ticks to prepare, after a mid-bit
; transition only 10, and a boundary transition (only after a 0) needs 7.

gap:                        ; silence after a message (also run once at reset)
    set x, 6
gl:
    jmp x--, gl [15]        ; 7 x 16 ticks
newmsg:
    pull                    ; first byte; stalls for ever when no more words
    set x, 0                ; the start bit is a 0 after a 0 ...
    set y, 0
toggle:                     ; ... and falls into its transition
    wait 0 pin 0 timeout    ; t-1   high: jump to fall.  low: next line
    set pins, 1             ; t
    jmp cont                ; t+1
fall:                       ; address 8 = timeout_vector
    set pins, 0 [1]         ; t, t+1
cont:
    jmp !x, c0              ; t+2   it was a 0: transition at the bit's start
    jmp !y, gap             ; t+3   X=1, Y=0: it was the end bit's transition
fetch:                      ; early N-8, late N-6 (shown: early)
    jmp !osre, pad          ; N-8
    out x, 1                ; N-7   8 bits gone: bit 8 is the last-byte flag
    jmp !x, dopull          ; N-6
    jmp !y, toggle [3]      ; N-5   end bit: a 0. After a 0, transition at N
    jmp gap                 ;       after a 1, none
pad:
    jmp bit [2]             ; N-7..N-5
dopull:
    pull                    ; N-5
bit:
    out x, 1                ; N-4
    jmp !x, zero            ; N-3
    jmp !y, o0              ; N-2 (late: N)
    jmp toggle [7]          ; late: N+1, then toggle at N+9: transition N+10
o0:
    set y, 1                ; N-1
    jmp toggle [8]          ; N, then toggle at N+9: transition N+10
zero:
    jmp !y, toggle          ; N-2   0 after 0: transition at N
    set y, 0 [1]            ; late only: N+1, N+2.  0 after 1: no transition
c0:
    jmp fetch [8]           ; t+3 .. t+11: fetch at t+12 = next boundary - 8
