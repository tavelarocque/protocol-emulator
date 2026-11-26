; T55xx reader write/reset commands on P0 (push-pull), thread 0, 10 MHz.
; Run with clkdiv=40: one tick = 40 cycles = half a carrier period.
; P0 is driven only by side-set. While the field is on, every executed
; instruction alternates side 1 / side 0, so P0 toggles every 40 cycles.
; In a gap every instruction is side 0 (delays allowed there).
;
; Timing in ticks (x 40 cycles):
;   power-up / post-write carrier: 267 (from its rise to the start-gap fall)
;   bit 0 on-time: 47 (1880 cycles), bit 1 on-time: 111 (4440 cycles)
;   write gaps: 36 to 47, start gap: 41 to 45
;
; Registers: OSR = word being sent (MSB first, threshold 16), X = bit /
; loop counter, ISR = copy of the header, Y = segments still to send:
; protected 6 (pwd hi, pwd lo, lock, data hi, data lo, addr),
; standard 4 (lock, data hi, data lo, addr), reset 0.

.side_set 1

carrier:
    set y, 3            side 1      ; rise: carrier starts (ends a gap)
outer:
    set x, 31           side 0
inner:
    nop                 side 1
    jmp x-- inner       side 0
    jmp y-- outer       side 1
    nop                 side 0
    pull                side 1      ; next header; stalls high after the last command

; ---- start gap: fall here, parse header (all side 0)
    mov isr, osr        side 0      ; fall: start gap begins; ISR = header
    out null, 8         side 0
    out x, 2            side 0      ; X = reset flag, protected flag
    out null, 4         side 0      ; OSR now holds only o1 o0 (count 14)
    set y, 4            side 0
    jmp !x have         side 0      ; standard write
    set y, 6            side 0
    jmp x-- hd          side 0      ; X: 1 -> 0 (protected), 2 -> 1 (reset)
hd:
    jmp !x have         side 0      ; protected write
    set y, 0            side 0      ; reset

; ---- end of every gap: fill, take next bit, start its field-on time
have:
    set x, 7            side 0
fill:
    jmp x-- fill        side 0 [3]  ; 8 x 4 = 32 ticks
    out x, 1            side 0      ; next bit
    jmp !x send0        side 0

send1:                              ; 111 ticks of field on
    set x, 30           side 1      ; rise
l1:
    nop                 side 0
    jmp x-- l1          side 1
    nop                 side 0
send0:                              ; 47 ticks of field on
    set x, 22           side 1      ; rise (for a 0)
l0:
    nop                 side 0
    jmp x-- l0          side 1

; ---- write gap: fall here
gap:
    jmp !osre have      side 0      ; fall; more bits in this word
    jmp !y done         side 0      ; all segments sent
    jmp y-- dsp         side 0
dsp:
    jmp !y do_addr      side 0
    set x, 3            side 0
    jmp x!=y do_fifo    side 0
do_lock:                            ; lock bit = header bit 2
    mov osr, isr        side 0
    out null, 13        side 0
    out x, 1            side 0
    mov osr, x          side 0
    out null, 15        side 0
    jmp have            side 0
do_addr:                            ; address = header bits 5..3
    mov osr, isr        side 0
    out null, 10        side 0
    out x, 3            side 0
    mov osr, x          side 0
    out null, 13        side 0
    jmp have            side 0
do_fifo:                            ; password or data word
    pull                side 0
    jmp have            side 0
done:                               ; finish the last write gap (36 ticks)
    nop                 side 0 [7]
    nop                 side 0 [7]
    nop                 side 0 [7]
    nop                 side 0 [7]
    jmp carrier         side 0 [1]
