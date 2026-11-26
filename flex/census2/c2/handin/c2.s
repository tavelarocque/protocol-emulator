; Silicon Labs C2 master for the protocol emulator, thread 0.
;
; Pins: P0 = C2CK (push-pull, driven only by side-set),
;       P1 = C2D (open-drain, written by out/set pins, read by in pins).
; Config (run_args.txt): clkdiv=5, sideset_base=0, sideset_count=1,
;       set_base=1, out_base=1, in_base=1 (set_count, out_count 1 and
;       threshold 8 are the defaults).
;
; Timing: clkdiv 5 gives one tick per 5 cycles, 10 ticks per 50-cycle slot.
; The rising edge of slot s is the instruction executed at tick 400 + 10s
; (shown at cycle 2000 + 50s + 1). Within a slot the ticks are t0..t9:
; t0 = C2CK rises, t3 = chip changes C2D, t5 = chip samples C2D,
; t8 = C2CK falls for the next slot's strobe, t9 = still low.
;
; A frame is sent as: START strobe (made by the set-up code), then the
; chip's bits C from the OSR by the loop at wbit (Y = bits - 1), then:
;   AW: C = INS(1,1), ADDRESS, STOP(1); X = 0xFFFF: ends in wbit.
;   DW: C = INS(1,0), LENGTH; X = n: wbit pulls n data words, then dtail
;       makes the last bit's strobe, releases C2D, WAIT, STOP.
;   AR: C = INS bit 0; X = 0: dtail makes that strobe, releases C2D,
;       makes the INS bit 1 strobe (released), then the read loop.
;   DR: C = INS(0,0), LENGTH, followed in the OSR by n-1 again; X = 0:
;       dtail as for AR (its plain strobe is the WAIT), X = n-1 from OSR.
; dtail tells DW from the reads by the OSR count (8 after a data byte,
; 1 or 4 after a read's header), with threshold 8.

.side_set 1

; ---- device reset: C2CK low ticks 0..256 (cycles 1..1286), high after ----
        set x, 31        side 0          ; tick 0
rst:    jmp x-- rst      side 0 [7]      ; ticks 1..256
        set y, 14        side 1 [3]      ; ticks 257..260
rhi:    jmp y-- rhi      side 1 [7]      ; ticks 261..380

; ---- frame entry: tick -19 relative to this frame's START rise ----
frame:  pull             side 1          ; -19 header word
        out x, 8         side 1          ; -18 X = address or n
        out null, 4      side 1          ; -17
        out y, 1         side 1          ; -16 bit 12
        jmp !y evn       side 1          ; -15 AR or DR
        out y, 1         side 1          ; -14 bit 13
        jmp !y aw        side 1          ; -13 AW
; DW at -12, Y = 1, X = n
        in y, 2          side 1          ; -12 INS bits 1, 0
        mov y, x         side 1 [2]      ; -11..-9
shared: jmp y-- sh1      side 1          ; -8  Y = n-1
sh1:    in y, 2          side 1          ; -7  LENGTH
        in y, 2          side 1          ; -6  n-1 again (for DR's read count)
        in null, 10      side 1 [2]      ; -5..-3 right-justify
        set y, 3         side 0 [1]      ; -2,-1 START falls; 4 bits
        mov osr, isr     side 1 [2]      ; 0..2 START rises

; ---- chip bits: out at t3, strobe falls t8, rises t0 ----
wbit:   out pins, 1      side 1          ; t3
        jmp y-- wfall    side 1 [3]      ; t4..t7
        jmp !x dtail     side 0          ; t8 last bit's strobe falls
        jmp x!=y pullp   side 0          ; t9
        jmp frame        side 1          ; t0 AW: STOP rises
pullp:  pull             side 1          ; t0 DW: next data byte
        set y, 7         side 1          ; t1
        jmp x-- wbit     side 1          ; t2
wfall:  nop              side 0 [1]      ; t8,t9
        jmp wbit         side 1 [2]      ; t0..t2

; ---- after the last chip bit (entered at t9, C2CK low) ----
dtail:  mov x, osr       side 0          ; t9 reads: X = bytes - 1
        mov isr, null    side 1          ; t0 last bit's strobe rises
        set pins, 1      side 1 [6]      ; t1..t7 release C2D
        set y, 7         side 0 [1]      ; t8,t9 WAIT (or AR's INS bit 1)
        jmp !osre rd     side 1 [7]      ; t0..t7 reads go on to rd
        nop              side 0 [1]      ; t8,t9 DW: STOP falls
        jmp frame        side 1          ; t0 STOP rises

; ---- device bytes: sample at t5, push after 8 bits ----
rd:     nop              side 0 [1]      ; t8,t9
        jmp rin          side 1 [4]      ; t0..t4
rmore:  set y, 7         side 1 [4]      ; t0..t4
rin:    in pins, 1       side 1          ; t5
        jmp y-- rd       side 1 [1]      ; t6,t7
        push             side 0          ; t8 next strobe falls
        jmp x-- rmore    side 0          ; t9
        jmp frame        side 1          ; t0 STOP rises

evn:    out y, 1         side 1          ; -14 bit 13
        jmp !y dr        side 1          ; -13 DR
; AR at -12, Y = 1, X = 0
        mov osr, null    side 1 [7]      ; -12..-5 C = 0 (INS bit 0)
        set y, 0         side 1 [1]      ; -4,-3 one bit
        nop              side 0 [1]      ; -2,-1 START falls
        jmp wbit         side 1 [2]      ; 0..2 START rises
; AW at -12, Y = 0, X = address
aw:     jmp y-- aw1      side 1          ; -12 Y = 0xFFFF
aw1:    in y, 2          side 1          ; -11 INS 1, 1
        in x, 8          side 1          ; -10 ADDRESS
        in y, 1          side 1          ; -9  STOP 1
        in null, 5       side 1          ; -8
        mov osr, isr     side 1          ; -7
        mov x, y         side 1 [3]      ; -6..-3 X = 0xFFFF
        set y, 10        side 0 [1]      ; -2,-1 START falls; 11 bits
        jmp wbit         side 1 [2]      ; 0..2 START rises
; DR at -12, Y = 0, X = n
dr:     in y, 2          side 1          ; -12 INS 0, 0
        mov y, x         side 1          ; -11
        set x, 0         side 1          ; -10
        jmp shared       side 1          ; -9
