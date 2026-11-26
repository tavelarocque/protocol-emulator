; AVR PDI programmer, thread 0, core clock 50 MHz.
;
; clkdiv = 5: one tick is 5 cycles, so a PDI slot (1 us, 50 cycles) is
; 10 ticks: ticks 0-4 are the low half (PDI_CLK = 0), ticks 5-9 the high
; half (PDI_CLK = 1). PDI_CLK (P0) is side-set by every instruction: every
; instruction in a low half says side 0, every one in a high half side 1.
; Each comment says which ticks of the slot an instruction covers.
; A write made in a tick shows one cycle later, so every edge is 1 cycle
; after its ideal place (within the +-2 allowed, and it never adds up).
;
; P1 (PDI_DATA, open-drain) is written by out/set/mov pins, only in the
; low half of a slot the chip sends (ticks 0-3), and only there.
;
; Config: clkdiv=5, sideset_base=0, sideset_count=1, out_base=1,
; out_count=1, set_base=1, set_count=1, in_base=1, threshold=8,
; crc_poly=1, crc_init=0 (the CRC register is then the running XOR of
; the bits shifted out, which is the even parity bit).

.side_set 1

; ---- 400 ticks (cycles 0 to 1999) with P0 high, P1 released ----
        set x, 31        side 1          ; 1 tick
w1:     jmp x-- w1       side 1 [7]      ; 32 x 8 = 256 ticks
        set x, 16        side 1          ; 1 tick
w2:     jmp x-- w2       side 1 [7]      ; 17 x 8 = 136 ticks
        set x, 14        side 1 [5]      ; 6 ticks: 400 in all

; ---- enable: 16 idle slots (slot 15's high half is main) ----
enlo:   nop              side 0 [4]      ; t0-4
        jmp x-- enlo     side 1 [4]      ; t5-9, slots 0 to 14
        nop              side 0 [4]      ; slot 15, t0-4

; ---- main: runs in the high half of the slot before the next frame ----
main:   pull             side 1          ; t5   next word
        mov x, osr       side 1          ; t6   keep a copy
        out null, 15     side 1          ; t7
        out y, 1         side 1          ; t8   y = bit 15 (end word)
        mov osr, x       side 1          ; t9   restore the word, count 0
        jmp !y frame     side 0          ; t0   falling edge of next slot

; ---- the end: this slot and 15 more idle, then PDI_CLK stops high ----
        set x, 15        side 0 [3]      ; t1-4
endhi:  jmp x-- endlo    side 1 [4]      ; t5-9
stop:   jmp stop         side 1          ; forever, P0 high
endlo:  jmp endhi        side 0 [4]      ; t0-4

; ---- the chip's frame ----
frame:  set pins, 0      side 0          ; t1   start bit
        mov crc, null    side 0 [2]      ; t2-4 parity accumulator = 0
        nop              side 1 [4]      ; t5-9
data:   out pins, 1      side 0 [4]      ; t0-4 data bit, LSB first
        jmp !osre data   side 1 [4]      ; t5-9 8 data slots
        mov pins, crc    side 0 [4]      ; t0-4 parity bit
        out x, 4         side 1 [4]      ; t5-9 x = answer length
        set pins, 1      side 0 [4]      ; t0-4 stop bit 1
        nop              side 1 [4]      ; t5-9
        jmp !x main      side 0 [4]      ; t0-4 stop bit 2 (line stays 1)

; ---- guard time: 128 idle slots ----
        set y, 31        side 1 [3]      ; t5-8 (stop bit 2, high half)
        jmp x-- guard    side 1          ; t9   always taken: x = length - 1
guard:  nop              side 0 [4]
        nop              side 1 [4]
        nop              side 0 [4]
        nop              side 1 [4]
        nop              side 0 [4]
        nop              side 1 [4]
        nop              side 0 [4]
        jmp y-- guard    side 1 [4]      ; 32 x 4 = 128 slots

; ---- the ATxmega's frames ----
rbyte:  nop              side 0 [4]      ; start bit slot
        nop              side 1 [4]
rbit:   nop              side 0 [4]      ; t0-4
        in pins, 1       side 1          ; t5   sample at the rising edge
        jmp !isrf rbit   side 1 [3]      ; t6-9 8 data slots
        push             side 0 [4]      ; parity slot
        nop              side 1 [4]
        nop              side 0 [4]      ; stop bit 1
        nop              side 1 [4]
        nop              side 0 [4]      ; stop bit 2
        jmp x-- rbyte    side 1 [4]

; ---- 2 idle slots, main in the high half of the second ----
        nop              side 0 [4]
        nop              side 1 [4]
        jmp main         side 0 [4]
