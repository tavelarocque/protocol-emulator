; LPC host for the protocol emulator, thread 0.
;
; Configuration (run_args.txt): clkdiv=10, so the thread executes one
; instruction every 10 core cycles, at cycles 0, 10, 20, ...  One LCLK
; period (20 cycles) is exactly two instructions.  LCLK is P5, driven by
; side-set: every instruction at a cycle 100+20k-ish "slot 0" says side 1
; (that write shows at cycle 101+20k, rising edge k, error +1 cycle) and
; every "slot 1" instruction says side 0 (falling edge at 111+20k).
; LAD and LFRAME# change only in slot 1, 10 cycles away from any rising
; edge.  set pins writes P0..P4 (LAD[3:0] and LFRAME#), out pins writes
; P0..P3 only.  Autopull with threshold 16 and MSB-first OUT, so the host's
; words stream through the OSR: type word, then address word(s).
;
; Notation in comments: "S" is the START clock of the read being set up,
; "t" its first TAR clock, "s0"/"s1" the slot within the LCLK period that
; ends with rising edge of that clock number (s0 = the tick of the rising
; edge that begins the period, s1 = the falling-edge tick).

.side_set 1

; ---- prologue: ticks 0..9 (cycles 0..90), LCLK held low, no edges ----
        set x, 4        side 0      ; tick 0
pd:     jmp x-- pd      side 0      ; ticks 1..5
        out y, 16       side 0      ; ticks 6 (autopull fetch) and 7: y = type
        set x, 1        side 0      ; tick 8
        jmp w2          side 0      ; tick 9, w2 runs at tick 10 = cycle 100

; ---- extra idle after an I/O read (4 periods), falls into join ----
iox:    set x, 3        side 0      ; t+7 s1
il:     nop             side 1
        jmp x-- il      side 0      ; periods t+8 .. t+11

; ---- next read: arrives here at S-6 s0 ----
join:   out y, 16       side 1      ; S-6 s0: y = type (stalls forever after the last read)
        set x, 3        side 0      ; S-6 s1
w2:     nop             side 1      ; s0  \ periods S-5 .. S-2
        jmp x-- w2      side 0      ; s1  /
        nop             side 1      ; S-1 s0
        jmp !y ios      side 0      ; S-1 s1: I/O read -> ios
; memory read
        set x, 7        side 1      ; S s0
        set pins, 0x00  side 0      ; S s1: START (LFRAME# low, LAD 0000)
        nop             side 1      ; S+1 s0
        set pins, 0x14  side 0      ; S+1 s1: CYCTYPE memory read (0100)
        nop             side 1      ; S+2 s0
; address nibbles, most significant first
al:     out pins, 4     side 0      ; s1 of S+2 ..
        jmp x-- al      side 1      ; s0, falls through at t s0
; turnaround and data
        set pins, 0x1f  side 0      ; t s1: TAR 1111, LAD released from here on
        nop             side 1      ; t+1
        nop             side 0
        nop             side 1      ; t+2 (SYNC)
        nop             side 0
        nop             side 1      ; t+3 (low nibble)
        nop             side 0
        in pins, 4      side 1      ; t+4 s0 = rising edge t+3: low nibble
        nop             side 0
        in pins, 4      side 1      ; t+5 s0 = rising edge t+4: high nibble
        push            side 0      ; t+5 s1: 0x00HL to the host
        nop             side 1      ; t+6 s0
        nop             side 0      ; t+6 s1
        jmp !y iox      side 1      ; t+7 s0 = rising edge t+6 (L)
        jmp join        side 0      ; t+7 s1 (after a memory read)

; I/O read start
ios:    set x, 3        side 1      ; S s0
        set pins, 0x00  side 0      ; S s1: START
        nop             side 1      ; S+1 s0
        set pins, 0x10  side 0      ; S+1 s1: CYCTYPE I/O read (0000)
        jmp al          side 1      ; S+2 s0
