; LPC host, thread 0. clkdiv 10: one tick = 10 cycles = half an LCLK period.
; Every instruction is one tick. Side-set (1 bit) drives LCLK on P5.
; "A" ticks (side 0) are the falling half: the only ticks that change LAD/LFRAME.
; "B" ticks (side 1) are the rising edges (rising edge k executes at cycle 100+20k).
; P0..P3 LAD (open drain), P4 LFRAME#, P5 LCLK.
; set pins writes P0..P4; out pins writes P0..P3 (MSB first); in pins reads P0..P3.
; Autopull, threshold 16: the OSR always holds the next host word.
; S = START clock of the current read, t = its first TAR clock.

        .side_set 1
start:  set y, 1        side 0 [3]  ; ticks 0-3, LCLK falls; pad covers clocks 0,1
        pull            side 0 [4]  ; ticks 4-8, first host word (type of read 0)
pad:    nop             side 0      ; A  idle clock
        jmp y-- pad     side 1      ; B  idle clocks: y+1 of them
        nop             side 0      ; A  S-2
top:    out x, 16       side 1      ; B  S-2  type word -> X (stalls here when the words run out)
        jmp !x io       side 0      ; A  S-1
        set x, 7        side 1      ; B  S-1  memory read: 8 address nibbles
        set pins, 0x00  side 0      ; A  S    START: LFRAME# low, LAD 0000
        set y, 4        side 1      ; B  S    idle clocks after a memory read: 5
        set pins, 0x14  side 0      ; A  S+1  CYCTYPE memory read: LFRAME# high, LAD 0100
        nop             side 1      ; B  S+1
addr:   out pins, 4     side 0      ; A  address nibble, most significant first
        jmp x-- addr    side 1      ; B
        set pins, 0x1f  side 0      ; A  t    TAR: release LAD, LFRAME# high
        set x, 1        side 1      ; B  t
tar2:   nop             side 0      ; A  t+1, t+2 (TAR, SYNC)
        jmp x-- tar2    side 1      ; B
        nop             side 0      ; A  t+3
        in pins, 4      side 1      ; B  t+3  low data nibble
        nop             side 0      ; A  t+4
        in pins, 4      side 1      ; B  t+4  high data nibble
        push            side 0      ; A  t+5  byte to the host
        nop             side 1      ; B  t+5
        nop             side 0      ; A  t+6
        jmp pad         side 1      ; B  t+6  last clock of the read
io:     set x, 3        side 1      ; B  S-1  I/O read: 4 address nibbles
        set pins, 0x00  side 0      ; A  S    START
        set y, 8        side 1      ; B  S    idle clocks after an I/O read: 9
        set pins, 0x10  side 0      ; A  S+1  CYCTYPE I/O read: LAD 0000
        jmp addr        side 1      ; B  S+1
