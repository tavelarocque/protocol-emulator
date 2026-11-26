; SWIM host for an STM8 target, thread 0, 40 MHz core.
;
; Config (run_args.txt): clkdiv=5, out_msb_first=1, in_msb_first=1,
; threshold=16, crc_poly=1; P0 open-drain. Everything else default:
; out/set/in base 0, out/set count 1.
;
; With clkdiv 5 one tick is one SWIM clock (5 cycles), ticks fall on cycles
; 5k, and a write made in tick k shows on P0 at cycle 5k+1 (1 cycle late,
; inside the +-2 limit). Every target event is on a multiple of 5 cycles.
; In the comments, times are ticks. A bit is 22 ticks: a 1 is low 2 ticks,
; a 0 low 20. The chip writes the bit value at t+2 with `out pins,1` (so a
; 0 simply stays low) and releases at t+20.
;
; The CRC register with crc_poly=1 and crc_init=0 keeps the running parity
; of the first bit of every OUT in its bit 0; `mov crc, null` restarts it
; before each frame and `mov pins, crc` sends it as the parity bit.
;
; Registers: Y = command word (cmd/N frames), then the byte counter;
; X = payload / scratch; OSR = bits being sent; ISR = saved word (address
; word 2, or the WOTF data word for a resend) or received bits.
; The acknowledge bit is read with mov osr,pins / out null,15 / out x,1.
;
; After the synchronisation frame the program never waits on the line
; again: the target is exactly on the timetable, so every frame is placed
; by counting ticks from the end of the synchronisation frame.

; ---------------------------------------------------------------- page 0
; Entry sequence. First fall in tick 130 (cycle 651).
start:  set x, 31                 ; 0
w0:     jmp x-- w0 [3]            ; 1..128
        set x, 30                 ; 129
        set pins, 0 [3]           ; e = 130: fall
w1:     jmp x-- w1 [3]            ; 134..257
        set pins, 1               ; e+128: rise (R0)
        mov osr, null [1]         ; R+1, R+2: OSR shift count 0 = pulse counter
; four 1 kHz pulses: fall at R+4000 ticks, rise at R+8000
p1:     set y, 8                  ; R+3: 1 + 9*444 = 3997 ticks
o1:     set x, 26
i1:     jmp x-- i1 [15]           ; 27*16 = 432
        jmp y-- o1 [10]
        set pins, 0               ; F = R+4000
        set y, 8 [2]              ; 3 + 9*444 = 3999 ticks
o2:     set x, 26
i2:     jmp x-- i2 [15]
        jmp y-- o2 [10]
        set pins, 1               ; R' = F+4000
        out null, 4               ; R'+1: count pulses (16 bits = 4 pulses)
        jmp !osre p1              ; R'+2
        mov osr, null             ; R4+3
; four 2 kHz pulses: fall at R+2000 ticks, rise at R+4000
p2:     set y, 3 [3]              ; R+4: 4 + 4*498 = 1996 ticks
o3:     set x, 30
i3:     jmp x-- i3 [15]           ; 31*16 = 496
        jmp y-- o3
        set pins, 0               ; F = R+2000
        set y, 3 [2]              ; 3 + 4*499 = 1999 ticks
o4:     set x, 30
i4:     jmp x-- i4 [15]
        jmp y-- o4 [1]
        set pins, 1               ; R' = F+2000
        out null, 4
        jmp !osre p2 [1]          ; R'+2, R'+3
; synchronisation frame from the target: low 250000..250640
        wait 0 pin 0
        wait 1 pin 0              ; rise seen at 250642: done in tick 50129
        set page, 1 [15]          ; 50130..50145
        nop [15]                  ; 50146..50161
        jmp op [1]                ; 50162..50163: op at 50164 = 50172 - 8

; ROTF receive. r0 = start of a target data frame (tick).
.page 0
rx0:    nop [15]                  ; r0-7 (first frame: from rd, page 2)
        nop [15]
        nop [5]
rx:     mov isr, null             ; r0+31
        set x, 7                  ; r0+32
rb:     in pins, 1 [15]           ; r0+33+22j: middle of data bit j+1
        jmp x-- rb [5]
        push                      ; r0+209
        nop [9]
        set pins, 0 [1]           ; r0+220: chip ACK, low 2 ticks
        set pins, 1               ; r0+222
        jmp y-- rmore             ; r0+223
        set page, 1 [15]          ; r0+224..239
        jmp op [15]               ; r0+240..255: op at r0+256 = next t0 - 8
.page 0
rmore:  nop [15]                  ; r0+224..239
        nop                       ; r0+240
        jmp rx0 [15]              ; r0+241..256: rx0 at r0+257 = r0'-7

; ---------------------------------------------------------------- page 1
.align
; One operation. t0 = start of its command frame (tick).
op:     pull                      ; t0-8: command word (stalls when none left)
        mov y, osr                ; t0-7
crs:    mov crc, null             ; t0-6 (command frame resend entry)
        mov osr, y                ; t0-5
        out null, 4               ; t0-4: next bits are 11..8 = 0 (start), 0, c1, c0
        set x, 3                  ; t0-3
cl:     set pins, 1 [1]           ; t-2
cl0:    set pins, 0 [1]           ; t: bit start
        out pins, 1 [15]          ; t+2: bit value
        jmp x-- cl [1]            ; t+18
        set pins, 1 [1]           ; t0+86
        set pins, 0 [1]           ; t0+88: parity bit
        mov pins, crc [15]        ; t0+90
        nop [1]                   ; t0+106
        set pins, 1 [12]          ; t0+108; target ACK bit at t0+110
        mov osr, pins             ; t0+121: sample the ACK bit
        out null, 15
        out x, 1                  ; X = P0
        jmp !x cnk                ; t0+124: NACK
        jmp !y sr                 ; t0+125: SRST done
        mov osr, y                ; t0+126
        out null, 8
        out x, 8 [15]             ; t0+128: X = N
        nop [4]                   ; t0+144..148
; byte frame N, t1 = t0+154
        mov crc, null             ; t1-5
        mov osr, x                ; t1-4
        out null, 7               ; t1-3: next bits are 8 (0 = start) and 7..0
bln:    set pins, 1 [1]
bln0:   set pins, 0 [1]
        out pins, 1 [15]
        jmp !osre bln [1]
        set pins, 1 [1]           ; t1+196
        set pins, 0 [1]           ; t1+198: parity
        mov pins, crc [15]
        pull [1]                  ; t1+216: address word 1
        set pins, 1               ; t1+218
        mov x, osr [15]           ; t1+219: X = A[23:16]
        nop [15]
        nop [7]                   ; to t1+258
; byte frame A[23:16], t2 = t1+264
        mov crc, null             ; t2-5
        mov osr, x
        out null, 7
bla:    set pins, 1 [1]
bla0:   set pins, 0 [1]
        out pins, 1 [15]
        jmp !osre bla [1]
        set pins, 1 [1]
        set pins, 0 [1]           ; t2+198: parity
        mov pins, crc [15]
        pull [1]                  ; t2+216: address word 2
        set pins, 1               ; t2+218
        mov isr, osr              ; t2+219: ISR = A[15:0]
        out x, 8 [15]             ; t2+220: X = A[15:8]
        set page, 2 [15]          ; t2+236
        jmp bsa1 [6]              ; t2+252..258: bsa1 at t3-5
.page 1
sr:     nop [15]                  ; t0+126
        jmp op [3]                ; t0+142..145: op at t0+146 = next t0 - 8
cnk:    nop [15]                  ; t0+125
        jmp crs [6]               ; t0+141..147: crs at t0+148 = next t0 - 6

; ---------------------------------------------------------------- page 2
.align
; byte frame A[15:8], t3
bsa1:   mov crc, null             ; t3-5
        mov osr, x
        out null, 7
bl1:    set pins, 1 [1]
bl10:   set pins, 0 [1]
        out pins, 1 [15]
        jmp !osre bl1 [1]
        set pins, 1 [1]
        set pins, 0 [1]           ; t3+198: parity
        mov pins, crc [15]
        mov osr, isr [1]          ; t3+216
        set pins, 1               ; t3+218
        out null, 8
        out x, 8 [15]             ; t3+220: X = A[7:0]
        nop [15]
        nop [6]                   ; to t3+258
; byte frame A[7:0], t4 = t3+264
        mov crc, null             ; t4-5
        mov osr, x
        out null, 7
bl2:    set pins, 1 [1]
bl20:   set pins, 0 [1]
        out pins, 1 [15]
        jmp !osre bl2 [1]
        set pins, 1 [1]
        set pins, 0 [1]           ; t4+198: parity
        mov pins, crc [15]
        mov osr, y [1]            ; t4+216
        set pins, 1               ; t4+218
        out null, 6               ; t4+219
        out x, 1                  ; t4+220: X = command bit 1 (1 = WOTF)
        out null, 1
        out y, 8                  ; t4+222: Y = N
        jmp y-- dn1               ; t4+223: Y = N-1 (N >= 1)
dn1:    jmp !x rd                 ; t4+224: ROTF
        nop [15]                  ; t4+225
        nop [15]                  ; to t4+256
; WOTF data frames, t5 = start of the frame
dp:     pull                      ; t5-7
        mov isr, osr              ; t5-6: keep the word for a resend
drs:    mov crc, null             ; t5-5
        mov osr, isr
        out null, 7
dl:     set pins, 1 [1]
dl0:    set pins, 0 [1]
        out pins, 1 [15]
        jmp !osre dl [1]
        set pins, 1 [1]
        set pins, 0 [1]           ; t5+198: parity
        mov pins, crc [15]
        nop [1]
        set pins, 1 [12]          ; t5+218; target ACK bit at t5+220
        mov osr, pins             ; t5+231: sample it
        out null, 15
        out x, 1
        jmp !x dnk                ; t5+234
        jmp y-- dmore             ; t5+235
        set page, 1 [15]          ; t5+236
        jmp op [3]                ; t5+252..255: op at t5+256
.page 2
dmore:  nop [15]                  ; t5+236
        jmp dp [4]                ; t5+252..256: dp at t5+257 = t6-7
dnk:    nop [15]                  ; t5+235
        jmp drs [7]               ; t5+251..258: drs at t5+259 = t6-5
rd:     set page, 0 [15]          ; t4+225
        jmp rx0 [15]              ; t4+241..256: rx0 at t4+257 = r0-7
