; AVR PDI programmer, thread 0.
; Config: clkdiv=5 (one tick = 5 cycles, one PDI slot = 10 ticks),
; side-set 1 bit on P0 (PDI_CLK), out/set/in on P1 (PDI_DATA).
; In every slot: tick t0 = falling edge (side 0), tick t5 = rising edge
; (side 1). P1 is only written at t0..t3 of a slot the chip sends.
; Ticks fall on cycles 0, 5, 10, ...; a write shows one cycle later, so
; every edge is at its ideal cycle + 1.
;
; Registers while sending a frame: OSR = TX word, X = next data bit,
; Y = 0 - (number of 1 bits so far), so Y bit 0 is the parity bit.
; OSR shift count (threshold 8) counts the data bits.
; After the 8 data bits the OSR holds word >> 8: its low 4 bits are the
; answer length, kept there through the guard time.

.side_set 1

; ---- before cycle 2000: P0 high, P1 released ----
        set y, 31           side 1          ; tick 0
w1:     jmp y-- w1          side 1 [7]      ; ticks 1..256
        set y, 16           side 1          ; tick 257
w2:     jmp y-- w2          side 1 [7]      ; ticks 258..393
        set y, 14           side 1 [4]      ; ticks 394..398 (X is 0)
        jmp ri              side 1          ; tick 399; ri at 400 = cycle 2000

; ---- idle slots: Y+1 slots, then rbit if X != 0 (X decremented), else D ----
ri:     nop                 side 0 [4]      ; t0..t4
ri_hi:  nop                 side 1 [2]      ; t5..t7
        jmp y-- ri2         side 1          ; t8
        jmp x-- rbit        side 1          ; t9

; ---- D: dispatch slot (idle). Pull the next word; end word -> end ----
D:      pull                side 0          ; t0
        mov x, osr          side 0          ; t1
        out null, 15        side 0          ; t2
        out y, 1            side 0          ; t3  Y = bit 15
        mov osr, x          side 0          ; t4  word back, count reset
        jmp !y dok          side 1          ; t5
        set y, 15           side 1 [3]      ; t6..t9  end word
eidle:  nop                 side 0 [4]      ; 16 idle slots
        nop                 side 1 [3]
        jmp y-- eidle       side 1
halt:   jmp halt            side 1          ; P0 high, P1 released

dok:    nop                 side 1 [3]      ; t6..t9 (Y is 0)
; ---- start bit ----
start:  set pins, 0         side 0          ; t0
        out x, 1            side 0 [3]      ; t1..t4  data bit 0
        nop                 side 1 [4]      ; t5..t9
; ---- 8 data bits ----
bit:    mov pins, x         side 0          ; t0
        jmp !x b0           side 0          ; t1
        jmp y-- b1          side 0 [2]      ; t2..t4  count a 1
b1:     jmp !osre more      side 1          ; t5
        nop                 side 1 [3]      ; t6..t9
; ---- parity ----
        mov pins, y         side 0 [4]      ; t0..t4
        nop                 side 1 [4]      ; t5..t9
; ---- stop bit 1: decide on the answer ----
        set pins, 1         side 0          ; t0
        mov x, osr          side 0          ; t1  X = answer length
        set y, 0            side 0 [1]      ; t2..t3
        jmp !x ri_hi        side 0          ; t4  no answer: stop 2 is D
        set x, 3            side 1          ; t5
        set y, 31           side 1 [3]      ; t6..t9
; ---- stop bit 2 ----
        nop                 side 0 [4]
        nop                 side 1 [4]
; ---- guard time: 4 x 32 = 128 idle slots ----
g:      nop                 side 0 [4]      ; t0..t4
        jmp y-- g1          side 1 [2]      ; t5..t7
        set y, 31           side 1          ; t8
        jmp x-- g           side 1          ; t9
; ---- start bit of the first answer byte ----
        mov x, osr          side 0          ; t0  X = n
        jmp x-- r0          side 0 [3]      ; t1..t4  X = n - 1
r0:     nop                 side 1 [4]      ; t5..t9
; ---- 8 data bits of an answer byte ----
rbit:   nop                 side 0 [4]      ; t0..t4
        in pins, 1          side 1          ; t5  sample at the rising edge
        jmp !isrf rbit      side 1 [3]      ; t6..t9
; ---- parity slot: push, then 4 idle slots in all (parity, stop, stop,
; ---- and the next start bit or the first idle slot after the answer)
        push                side 0          ; t0
        set y, 3            side 0 [2]      ; t1..t3
        jmp ri_hi           side 0          ; t4

; ---- out-of-line pieces ----
ri2:    jmp ri              side 1          ; t9
b0:     jmp b1              side 0 [2]      ; t2..t4
more:   out x, 1            side 1          ; t6
        jmp bit             side 1 [2]      ; t7..t9
g1:     jmp g               side 1 [1]      ; t8..t9
