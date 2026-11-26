; PT2262 / rc_encode code-word sender on P0, thread 0.
; Config (run_args.txt): clkdiv=800 so one tick = 800 cycles = 2 alpha,
; side-set 1 pin on P0 (every instruction sets the line level),
; threshold 12 with autopull (one 12-bit word = 6 trits), ISR threshold 12
; counts the 12 trits of a frame with "in null, 1".
; Registers: X = 1 (constant for x!=y) except in delay loops, Y = trit value.
; Trit = 16 ticks: short pulse = 2 H + 6 L, long pulse = 6 H + 2 L.
; Sync = 2 H + 62 L ticks. Frame = 12*16 + 64 = 256 ticks = 204800 cycles.
; The value of trit k+1 is read during trit k (not during the last trit);
; trit 0 of a frame is read during the previous sync (or at start).

.side_set 1

start:  set x, 31          side 0   ; tick 0: line low
d0:     jmp x-- d0         side 0   ; 32 ticks
        set x, 31          side 0
d1:     jmp x-- d1         side 0   ; 32 ticks
        out y, 2           side 0   ; first trit (fetch tick + run tick)
        set x, 19          side 0
d2:     jmp x-- d2         side 0   ; 20 ticks
        set x, 1           side 0
        jmp top            side 0

; ---- trit, t0..t15 ----
top:    jmp x!=y s1        side 1   ; t0  y = 0 or 2: short first pulse
        nop                side 1   ; t1  '1': long first pulse
        nop                side 1   ; t2
        nop                side 1   ; t3
        nop                side 1   ; t4
        nop                side 1   ; t5
        nop                side 0   ; t6
        jmp mid            side 0   ; t7
s1:     nop                side 1   ; t1  short first pulse
        nop                side 0   ; t2
        nop                side 0   ; t3
        nop                side 0   ; t4
        nop                side 0   ; t5
        nop                side 0   ; t6
        nop                side 0   ; t7
mid:    jmp !y s2          side 1   ; t8  y = 0: short second pulse
        in null, 1         side 1   ; t9  long second pulse ('1', 'f')
        jmp !isrf l2out    side 1   ; t10 not the last trit: read next
        jmp l2go           side 1   ; t11 last trit: read nothing
l2out:  out y, 2           side 1   ; t11
l2go:   nop                side 1   ; t12
        nop                side 1   ; t13
        nop                side 0   ; t14
        jmp !isrf top      side 0   ; t15 next trit, or fall into sync
; ---- sync, s0..s63 ----
sync0:  nop                side 1   ; s0
sync1:  mov isr, null      side 1   ; s1  trit count back to 0
        out y, 2           side 0   ; s2  trit 0 of next frame (waits here at end)
        set x, 31          side 0   ; s3
d3:     jmp x-- d3         side 0   ; s4..s35
        set x, 24          side 0   ; s36
d4:     jmp x-- d4         side 0   ; s37..s61
        set x, 1           side 0   ; s62
        jmp top            side 0   ; s63
; ---- short second pulse ('0'), t9..t15 ----
s2:     in null, 1         side 1   ; t9
        jmp !isrf s2out    side 0   ; t10
        jmp s2go           side 0   ; t11 last trit
s2out:  out y, 2           side 0   ; t11
s2go:   nop                side 0   ; t12
        nop                side 0   ; t13
        nop                side 0   ; t14
        jmp !isrf top      side 0   ; t15
        jmp sync1          side 1   ; s0 of sync
