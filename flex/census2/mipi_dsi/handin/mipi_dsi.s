; MIPI DSI low-power (LPDT) transmitter, thread 0. See notes.md for the design.
; Lane pins via set (set_base=0, set_count=2): 3=LP-11, 1=LP-10, 2=LP-01, 0=LP-00.
; P4..P6 (out_base=4, out_count=3) hold the ECC round number for the dispatcher.

; ---------------- page 0 ----------------
        set y, 31             ; power-up wait in LP-11 (about 6200 cycles)
dly_o:  set x, 31
dly_i:  jmp x-- dly_i [5]
        jmp y-- dly_o
pkt:    pull                  ; word 1: flag<<8 | DI (stalls in LP-11 when no more packets)
        mov isr, osr          ; ISR = word 1; ECC bits will be shifted in at the bottom
        pull                  ; word 2: parameters or WC
        mov y, osr            ; Y = word 2
        mov crc, null         ; fresh CRC register for round 0
W0:     set x, 0            ; round 0: P5
        mov pins, x
        mov osr, y
        out null, 1          ; feed pos 0 (cancelled below)
        mov osr, y
        out null, 2          ; feed pos 0 again, go to 2
        set x, 8
f1:    out null, 1
        jmp x-- f1
        out null, 2
        out null, 1
        out null, 1
        out null, 1
        jmp ext
; shared end of every ECC round: P = parity of the CRC register, shifted into the ISR
ext:    mov osr, crc          ; read R (the register stops following OUT)
xe:     mov x, osr            ; even so far
        jmp !x xend
        out x, 1
        jmp !x xe
xo:     mov x, osr            ; odd so far
        jmp !x xoe
        out x, 1
        jmp !x xo
        jmp xe
xoe:    jmp x-- xend          ; X 0 -> 0xFFFF, bit 0 = 1
xend:   in x, 1               ; ISR = ISR<<1 | P
        set page, 1
        jmp disp
.page 0
W1:     set x, 1            ; round 1: P4
        mov pins, x
        mov osr, isr
        out null, 5
        set x, 3
f2:    out null, 1
        jmp x-- f2
        mov osr, y
        set x, 6
f3:    out null, 1
        jmp x-- f3
        out null, 5
        out null, 1
        out null, 1
        jmp ext
W5:     set x, 5            ; round 5: P0
        mov pins, x
        mov osr, isr
        set x, 12
f4:    out null, 1
        jmp x-- f4
        mov osr, y
        set x, 15
f5:    out null, 1
        jmp x-- f5
        jmp ext
.align
; ---------------- page 1 ----------------
disp:   mov osr, pins         ; round number from P4..P6
        out null, 4
        out x, 3
        mov crc, null         ; fresh register for the next round (after the OUTs above)
        jmp !x t1
        jmp x-- c1
c1:     jmp !x W2
        jmp x-- c2
c2:     jmp !x W3
        jmp x-- c3
c3:     jmp !x t4
        jmp x-- c4
c4:     jmp !x t5
        set page, 2           ; round 5 done: transmit
        jmp tx
.page 1
t1:     set page, 0
        jmp W1
.page 1
t4:     set page, 2
        jmp W4
.page 1
t5:     set page, 0
        jmp W5
.page 1
W2:     set x, 2            ; round 2: P3
        mov pins, x
        mov osr, isr
        out null, 3
        set x, 5
f6:    out null, 1
        jmp x-- f6
        mov osr, y
        out null, 1          ; feed pos 0 (cancelled below)
        mov osr, y
        out null, 5          ; feed pos 0 again, go to 5
        set x, 4
f7:    out null, 1
        jmp x-- f7
        out null, 3
        out null, 1
        out null, 1
        set page, 0
        jmp ext
.page 1
W3:     set x, 3            ; round 3: P2
        mov pins, x
        mov osr, isr
        out null, 2
        out null, 1
        out null, 1
        out null, 4
        out null, 1
        out null, 1
        out null, 1
        mov osr, y
        out null, 2
        out null, 5
        out null, 1
        out null, 1
        out null, 4
        out null, 1
        set page, 0
        jmp ext
.page 1
.align
; ---------------- page 2 ----------------
W4:     set x, 4            ; round 4: P1
        mov pins, x
        mov osr, isr
        out null, 5
        out null, 1
        out null, 2
        out null, 1
        out null, 1
        mov osr, y
        out null, 1
        out null, 1
        out null, 1
        out null, 3
        out null, 1
        out null, 2
        out null, 1
        out null, 5
        out null, 1
        set page, 0
        jmp ext
.page 2
tx:     set x, 29             ; escape entry (bits 1,0) + LPDT command bits 1,1,1,0,0,0
        mov osr, x
ba:  out x, 1              ; entry: next bit, LSB first
        jmp !x baz
        set pins, 1 [4]       ; Mark-1 (LP-10)
        jmp bas
baz: set pins, 2 [5]       ; Mark-0 (LP-01)
bas: set pins, 0 [2]       ; space (LP-00)
        jmp !osre ba
        set pins, 2 [5]       ; command bit 0: Mark-0
        set pins, 0 [3]
        set pins, 1 [4]       ; command bit 1: Mark-1
        set pins, 0 [2]
        mov osr, isr          ; DI is word 1, above the 6 ECC bits
        out null, 6
        mov osr, osr          ; restart the OSR count
bb:  out x, 1              ; DI: next bit, LSB first
        jmp !x bbz
        set pins, 1 [4]       ; Mark-1 (LP-10)
        jmp bbs
bbz: set pins, 2 [5]       ; Mark-0 (LP-01)
bbs: set pins, 0 [2]       ; space (LP-00)
        jmp !osre bb
        mov osr, y            ; word 2 low byte
bc:  out x, 1              ; byte 1: next bit, LSB first
        jmp !x bcz
        set pins, 1 [4]       ; Mark-1 (LP-10)
        jmp bcs
bcz: set pins, 2 [5]       ; Mark-0 (LP-01)
bcs: set pins, 0 [2]       ; space (LP-00)
        jmp !osre bc
        mov osr, osr          ; word 2 high byte
bd:  out x, 1              ; byte 2: next bit, LSB first
        jmp !x bdz
        set pins, 1 [4]       ; Mark-1 (LP-10)
        jmp bds
bdz: set pins, 2 [5]       ; Mark-0 (LP-01)
bds: set pins, 0 [2]       ; space (LP-00)
        jmp !osre bd
        set page, 3
        jmp ecc
.align
; ---------------- page 3 ----------------
ecc:    mov osr, isr          ; ECC: the low 6 bits of the ISR, then 0, 0
        out x, 6
        mov osr, x
be:  out x, 1              ; ECC: next bit, LSB first
        jmp !x bez
        set pins, 1 [4]       ; Mark-1 (LP-10)
        jmp bes
bez: set pins, 2 [5]       ; Mark-0 (LP-01)
bes: set pins, 0 [2]       ; space (LP-00)
        jmp !osre be
        mov osr, isr          ; long-packet flag: ISR bit 14
        out null, 14
        out x, 1
        jmp !x exit
        mov crc, null         ; CRC over the payload only
pl:     jmp !y crcs           ; Y = WC bytes left
        jmp y-- pl2
pl2:    pull
bf:  out x, 1              ; payload: next bit, LSB first
        jmp !x bfz
        set pins, 1 [4]       ; Mark-1 (LP-10)
        jmp bfs
bfz: set pins, 2 [5]       ; Mark-0 (LP-01)
bfs: set pins, 0 [2]       ; space (LP-00)
        jmp !osre bf
        jmp pl
crcs:   mov osr, crc          ; checksum, low byte then high byte
        set y, 1
bg:  out x, 1              ; checksum: next bit, LSB first
        jmp !x bgz
        set pins, 1 [4]       ; Mark-1 (LP-10)
        jmp bgs
bgz: set pins, 2 [5]       ; Mark-0 (LP-01)
bgs: set pins, 0 [2]       ; space (LP-00)
        jmp !osre bg
        jmp y-- bg2
exit:   set pins, 1 [4]       ; exit: Mark-1
        set pins, 3           ; Stop state LP-11
        set page, 0
        jmp pkt
.page 3
bg2:    mov osr, osr
        jmp bg
