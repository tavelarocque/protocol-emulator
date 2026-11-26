; SDA 2506 EEPROM host, thread 0, clkdiv 10 (one tick = 10 cycles = 1 us).
; P0 CLK (side-set), P1 DATA (out/mov pins, set bit 0, in pins), P2 CE (set bit 1).
; Slot = 20 ticks: DATA changes at tick 0, CLK rises at tick 5, falls at tick 15.
; S = first slot of an operation; comments give the tick relative to it.
.side_set 1
        set x, 22       side 0 [2]  ; t0..2, CLK low at cycle 1
init:   jmp x-- init    side 0 [7]  ; 23 x 8 = 184 ticks, t3..186
next:   pull            side 0      ; S-13 (wait here after the last operation)
        mov y, osr      side 0      ; S-12 keep a copy of the word
        out null, 15    side 0      ; S-11
        out x, 1        side 0      ; S-10 X = bit 15 (1 = write)
        mov osr, y      side 0      ; S-9  restore the word, count reset
        jmp !x rdera    side 0      ; S-8
        set y, 15       side 0 [6]  ; S-7..S-1 write: 16 command bits
wloop:  out pins, 1     side 0 [4]  ; t0 DATA = bit (D0..D7, A0..A6, CB=1)
        nop             side 1 [7]  ; t5 CLK rises
        nop             side 1 [1]  ; t13
        jmp y-- wloop   side 0 [4]  ; t15 CLK falls
        set pins, 2     side 0 [4]  ; slot n t0: DATA low, CE high
        set pins, 0     side 0 [6]  ; slot n t5: CE falls with DATA low
        jmp tail        side 0      ; slot n t12
rdera:  out x, 8        side 0      ; S-7 X = low byte: 0 read, 1 erase
        set y, 6        side 0 [5]  ; S-6..S-1 7 address bits
aloop:  out pins, 1     side 0 [4]  ; t0 DATA = A0..A6
        nop             side 1 [7]  ; t5
        nop             side 1 [1]  ; t13
        jmp y-- aloop   side 0 [4]  ; t15
        mov pins, x     side 0 [4]  ; slot 7 t0: DATA = CB = X
        nop             side 1 [7]  ; t5
        nop             side 1 [1]  ; t13
        nop             side 0 [4]  ; t15
        set pins, 3     side 0 [4]  ; slot n t0: DATA released, CE high
        set pins, 1     side 0 [7]  ; slot n t5: CE falls with DATA high
tail:   set y, 6        side 0 [7]  ; slot n t13 (read: 7 sampled pulses follow)
        nop             side 0 [3]  ; t21
        nop             side 1 [7]  ; slot n+1 t5: start pulse / read pulse 1
        nop             side 1 [1]  ; t13
        nop             side 0 [4]  ; t15 CLK falls
        set pins, 1     side 0      ; slot n+2 t0: DATA released, CE low
        jmp !x rloop    side 0      ; t1: X = 0 only for a read
        wait 1 pin 0 timeout side 0 ; t2: CLK is low: times out after 20 ms
tov:    set pins, 3     side 0      ; slot n+2 + 20000 ticks: CE rises
        jmp next        side 0
rloop:  in pins, 1      side 0 [2]  ; slot n+k+2 t2: sample bit k
        nop             side 1 [7]  ; t5 read pulse k+2
        nop             side 1 [1]  ; t13
        jmp y-- rloop   side 0 [6]  ; t15
        in pins, 1      side 0      ; slot n+9 t2: sample bit 7
        push            side 0 [1]  ; t3
        set pins, 3     side 0      ; t5: CE rises
        jmp next        side 0      ; t6, next at t7 = next S - 13
