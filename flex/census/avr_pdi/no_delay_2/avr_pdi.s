; AVR PDI programmer, thread 0, 50 MHz core.
; clkdiv = 5: one tick = 5 cycles, one PDI slot (1 us) = 10 ticks.
; Every instruction is one tick. Side-set bit = P0 (PDI_CLK):
;   ticks L0..L4 of a slot carry side 0 (clock low), H0..H4 carry side 1.
; P1 (PDI_DATA, open-drain) is written by set/out/mov pins (base 1, count 1)
; only at the L0 tick of the chip's own frame slots.
; Registers: X = counters, Y = short delays (set y,k-2 ; l: jmp y-- l = k ticks),
; OSR = TX word, ISR = received bits (and the guard's outer counter),
; CRC (poly 1, init 0) = running parity of the data bits shifted out.

.side_set 1

; ---------------- page 0 ----------------
; startup: exactly 400 ticks (cycles 0..1999) with P0 high, P1 released
start:  set x, 23       side 1      ; 1
w0:     set y, 13       side 1      ; 1
w1:     jmp y-- w1      side 1      ; 14
        jmp x-- w0      side 1      ; 1   -> 24 x 16 = 384
        set y, 12       side 1      ; 1
w2:     jmp y-- w2      side 1      ; 13
        set x, 14       side 1      ; 1   -> total 400

; enable: idle slots 0..14 (slot 15 is the pre slot)
idle:   nop             side 0      ; L0
        set y, 2        side 0      ; L1
i1:     jmp y-- i1      side 0      ; L2-L4
        set y, 2        side 1      ; H0
i2:     jmp y-- i2      side 1      ; H1-H3
        jmp x-- idle    side 1      ; H4

; pre slot: an idle slot (or the chip's 2nd stop bit) that fetches the next
; word and tests for the end word (bit 15).
pre:    pull            side 0      ; L0
        mov x, osr      side 0      ; L1
        out null, 15    side 0      ; L2
        out y, 1        side 0      ; L3
        mov osr, x      side 0      ; L4  (restores the word, count 0)
        jmp !y frame    side 1      ; H0
        ; end word: rest of this slot, then 16 idle slots, then stop
        set x, 15       side 1      ; H1
        set y, 1        side 1      ; H2
e0:     jmp y-- e0      side 1      ; H3-H4
endl:   nop             side 0      ; L0
        set y, 2        side 0      ; L1
e1:     jmp y-- e1      side 0      ; L2-L4
        set y, 2        side 1      ; H0
e2:     jmp y-- e2      side 1      ; H1-H3
        jmp x-- endl    side 1      ; H4
done:   jmp done        side 1

; the chip's frame; entered at H1 of the pre slot
frame:  mov crc, null   side 1      ; H1  restart parity
        set y, 1        side 1      ; H2
f0:     jmp y-- f0      side 1      ; H3-H4
        set pins, 0     side 0      ; start bit L0
        set y, 2        side 0      ; L1
f1:     jmp y-- f1      side 0      ; L2-L4
        set y, 3        side 1      ; H0
f2:     jmp y-- f2      side 1      ; H1-H4
bit:    out pins, 1     side 0      ; data bit L0
        set y, 2        side 0      ; L1
f3:     jmp y-- f3      side 0      ; L2-L4
        set y, 2        side 1      ; H0
f4:     jmp y-- f4      side 1      ; H1-H3
        jmp !osre bit   side 1      ; H4
        mov pins, crc   side 0      ; parity L0
        set y, 2        side 0      ; L1
f5:     jmp y-- f5      side 0      ; L2-L4
        set y, 3        side 1      ; H0
f6:     jmp y-- f6      side 1      ; H1-H4
        set pins, 1     side 0      ; stop 1 L0
        mov x, osr      side 0      ; L1  X = word >> 8 = answer length
        set y, 1        side 0      ; L2
f7:     jmp y-- f7      side 0      ; L3-L4
        set y, 2        side 1      ; H0
f8:     jmp y-- f8      side 1      ; H1-H3
        jmp !x pre      side 1      ; H4  no answer: stop 2 is the pre slot
        ; answered: stop 2, then the guard time (page 1)
        set y, 3        side 0      ; L0
f9:     jmp y-- f9      side 0      ; L1-L4
        set y, 1        side 1      ; H0
f10:    jmp y-- f10     side 1      ; H1-H2
        set page, 1     side 1      ; H3
        jmp gentry      side 1      ; H4

; ---------------- page 1 ----------------
.align
; guard time: 8 groups of (1 outer slot + 15 inner slots) = 128 slots.
; The outer slot shifts one bit into the ISR; after 8, the ISR is full.
gentry: nop             side 0      ; L0 of guard slot 0
ocont:  set x, 14       side 0      ; L1
        in null, 1      side 0      ; L2
        set y, 0        side 0      ; L3
g0:     jmp y-- g0      side 0      ; L4
        set y, 3        side 1      ; H0
g1:     jmp y-- g1      side 1      ; H1-H4
ginner: set y, 3        side 0      ; L0
g2:     jmp y-- g2      side 0      ; L1-L4
        set y, 2        side 1      ; H0
g3:     jmp y-- g3      side 1      ; H1-H3
        jmp x-- ginner  side 1      ; H4  (15 inner slots)
        jmp !isrf ocont side 0      ; L0 of the next outer slot, or, once the
                                    ; ISR holds 8 bits, of the answer's first slot
; the ATxmega's answer. First byte's start slot:
        mov isr, null   side 0      ; L1  empty the ISR
        mov x, osr      side 0      ; L2  X = answer length (>= 1)
        jmp x-- a1      side 0      ; L3  X = length - 1
a1:     nop             side 0      ; L4
        set y, 3        side 1      ; H0
a2:     jmp y-- a2      side 1      ; H1-H4
rbit:   set y, 3        side 0      ; data bit L0
r1:     jmp y-- r1      side 0      ; L1-L4
        in pins, 1      side 1      ; H0  sample P1 at the rising edge
        set y, 1        side 1      ; H1
r2:     jmp y-- r2      side 1      ; H2-H3
        jmp !isrf rbit  side 1      ; H4
        push            side 0      ; parity slot L0: RX word = the byte
        set y, 2        side 0      ; L1
r3:     jmp y-- r3      side 0      ; L2-L4
        set y, 3        side 1      ; H0
r4:     jmp y-- r4      side 1      ; H1-H4
        set y, 3        side 0      ; stop 1 L0
r5:     jmp y-- r5      side 0      ; L1-L4
        set y, 3        side 1      ; H0
r6:     jmp y-- r6      side 1      ; H1-H4
        set y, 3        side 0      ; stop 2 L0
r7:     jmp y-- r7      side 0      ; L1-L4
        set y, 2        side 1      ; H0
r8:     jmp y-- r8      side 1      ; H1-H3
        jmp x-- rnext   side 1      ; H4  another byte follows
        set y, 3        side 0      ; idle slot 1 L0
r9:     jmp y-- r9      side 0      ; L1-L4
        set y, 1        side 1      ; H0
r10:    jmp y-- r10     side 1      ; H1-H2
        set page, 0     side 1      ; H3
        jmp pre         side 1      ; H4  idle slot 2 is the pre slot
.page 1
rnext:  set y, 3        side 0      ; next byte's start slot L0
r11:    jmp y-- r11     side 0      ; L1-L4
        set y, 2        side 1      ; H0
r12:    jmp y-- r12     side 1      ; H1-H3
        jmp rbit        side 1      ; H4
