; EM4305 / EM4205 reader transmit firmware (Login and Write word), thread 0.
; clkdiv=40: one tick = 40 cycles = half a 125 kHz carrier period.
; Side-set (1 bit) drives P0 on every instruction: carrier-on code alternates
; side 1 / side 0, field-off code is side 0 (delays allowed there).
; Bit k of a command occupies ticks 0..63 (t0..t63) from its start.
; Registers: OSR data (msb first, threshold 8 = one row), Y row parity (0/1),
; ISR phase code F, X scratch/counter, CRC column-parity ring (poly 0x80).
; F: 0 stop bit, 1 col load, 2 row2 end, 3 pull hi, 4 row0 end, 5 pull lo,
;    6 Write prefix row end, >=7 back to the gap.

        .side_set 1

; ================= page 0 (PAGE = 0 while bits are sent) =================
; ---- data bit ----
data:   out x, 1            side 0      ; t1  X = bit
        jmp !x d0           side 1      ; t2
        jmp y-- d1a         side 0      ; t3  parity 1 -> 0, go d1a
        set y, 1            side 1      ; t4  parity 0 -> 1
        set x, 12           side 0      ; t5
fill1h: jmp fill1b          side 1      ; carrier fill loop head (H)
d0:     set x, 13           side 0      ; t3
fill0h: jmp fill0b          side 1      ; carrier fill loop head (H)
o1:     jmp o2              side 1      ; one-tail loop head (H)
; ---- parity bit: value Y, then Y = 0; X preset so the fill ends at t31 ----
par:    jmp y-- fill1h      side 0      ; p (odd)
        set y, 0            side 1      ; p+1
fill0b: jmp x-- fill0h      side 0      ; carrier until t31
        set x, 2            side 0 [6]  ; t32..t38 field off
offl:   jmp x-- offl        side 0 [7]  ; t39..t62
        jmp bit             side 0      ; t63
d1a:    set x, 13           side 1      ; t4
fill1b: jmp x-- fill1h      side 0      ; carrier until t31
        set x, 15           side 1      ; t32
o2:     jmp x-- o1          side 0      ; carrier t33..t63
; ---- start of every bit ----
bit:    jmp !osre data      side 1      ; t0
        mov x, isr          side 0      ; t1  X = F
        jmp x-- e1          side 1      ; t2
; F=0: stop bit (a 0), then F = 9 (gap), Y = 9 (gap loop count)
        set y, 9            side 0      ; t3
        mov isr, y          side 1      ; t4
        set x, 12           side 0      ; t5
        jmp fill0b          side 1      ; t6 -> fill0b t7
e2:     jmp x-- e3          side 0      ; t5
; F=2: end of row 2
        mov osr, osr        side 1      ; t6
        set x, 10           side 0      ; t7
        jmp par             side 1      ; t8 -> par t9
e3:     jmp x-- e4          side 1      ; t6
; F=3: pull hi (page 1)
        set page, 1         side 0      ; t7
        jmp ph              side 1      ; t8 -> ph t9
        .page 0
e4:     jmp x-- e5          side 0      ; t7
; F=4: end of row 0
        mov osr, osr        side 1      ; t8
        set x, 9            side 0      ; t9
        jmp par             side 1      ; t10 -> par t11
e5:     jmp x-- e6          side 1      ; t8
; F=5: pull lo, byte swap, restart CRC
        pull                side 0      ; t9
        mov x, osr          side 1      ; t10
        in x, 16            side 0      ; t11
        in x, 8             side 1      ; t12
        mov osr, isr        side 0      ; t13
        set x, 4            side 1      ; t14
        mov isr, x          side 0      ; t15
        mov crc, null       side 1      ; t16
        set x, 5            side 0      ; t17
        jmp par             side 1      ; t18 -> par t19
e6:     jmp x-- e7          side 0      ; t9
; F=6: Write: end of [0 0 1 0], next row is the 6 address-row bits
        mov osr, osr        side 1      ; t10
        out null, 2         side 0      ; t11
        set x, 7            side 1      ; t12
        nop                 side 0      ; t13
        jmp par             side 1      ; t14 -> par t15
; F>=7: back to the gap (carrier goes on)
e7:     set page, 1         side 1      ; t10
        jmp go              side 0      ; t11 -> go t12
        .page 0
e1:     mov isr, x          side 0      ; t3  F = F - 1
        jmp x-- e2          side 1      ; t4
; F=1: load column parity, reversed through the ISR (runs on into page 1, PAGE 0)
        mov osr, crc        side 0      ; t5
        out null, 8         side 1      ; t6
        out x, 1            side 0      ; t7
        in x, 1             side 1
        out x, 1            side 0
        in x, 1             side 1
        out x, 1            side 0
        in x, 1             side 1
        out x, 1            side 0
        in x, 1             side 1
        out x, 1            side 0
        in x, 1             side 1
        out x, 1            side 0
        in x, 1             side 1
        out x, 1            side 0
        in x, 1             side 1
        out x, 1            side 0
        in x, 1             side 1      ; t22
        mov osr, isr        side 0      ; t23
        mov isr, null       side 1      ; t24 F = 0
        set x, 1            side 0      ; t25
        jmp par             side 1      ; t26 -> par t27

; ================= page 1 (PAGE = 1): gap, command setup, field stop =================
        .page 1
gap:    set y, 9            side 0      ; reset entry: first fall at cycle 1
go:     set x, 31           side 1
gi:     nop                 side 0
        jmp x-- gi          side 1
        jmp y-- go          side 0      ; 10 x 33 periods
        nop                 side 1
        pull                side 0      ; command word (stalls low when done)
        mov x, osr          side 1
        jmp !x login        side 0
        out null, 12        side 1      ; Write: build [0 0 1 0][..][A0 A1 A2 A3 0 0]
        out x, 1            side 0      ; A3
        in x, 1             side 1
        out x, 1            side 0      ; A2
        in x, 1             side 1
        out x, 1            side 0      ; A1
        in x, 1             side 1
        out x, 1            side 0      ; A0
        in x, 1             side 1
        set y, 6            side 0      ; F = 6
        set x, 8            side 1
        jmp common          side 0
login:  set y, 5            side 1      ; F = 5
        set x, 4            side 0
common: in x, 10            side 1
        mov osr, isr        side 0
        out null, 4         side 1      ; first row: 4 bits; last carrier rise
        mov isr, y          side 0 [7]  ; field stop: 111 low ticks in all
        set y, 0            side 0 [7]
        set x, 10           side 0 [4]
fs:     jmp x-- fs          side 0 [7]
        set page, 0         side 0
        jmp bit             side 0
        .page 1
; F=3 pull hi (entered at t9)
ph:     pull                side 0      ; t9
        mov x, osr          side 1
        in x, 16            side 0
        in x, 8             side 1
        mov osr, isr        side 0
        set x, 2            side 1
        mov isr, x          side 0
        set x, 5            side 1
        set page, 0         side 0
        jmp par             side 1      ; t18 -> par t19
