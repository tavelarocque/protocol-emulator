; AC '97 controller, output direction only, thread 0, 50 MHz core.
;
; Pins: P0 BIT_CLK (input), P1 SYNC, P2 SDATA_OUT (push-pull).
; run_args: out_base=2,out_count=1  (out/mov pins drive SDATA only)
;           set_base=1,set_count=2  (set pins: bit0 = SYNC, bit1 = SDATA)
;           out_msb_first=1, threshold=16, no autopull.
;
; Every falling edge of BIT_CLK is one "step":
;     wait 1 pin 0   ; passes in the cycle F the thread first sees BIT_CLK
;                    ; high, which is the cycle BIT_CLK falls (2-flop delay)
;     A              ; at most 2 instructions; pin writes only here, in
;                    ; cycles F+1 or F+2, so they show at F+2 or F+3,
;                    ; never at a falling edge (F, F+4 or F+5)
;     wait 0 pin 0
;     B              ; bookkeeping
; A write made in the step of falling edge k is what edge k+1 carries.
; W(j) below names the step that writes frame bit j (j = -1 is the bit
; before the tag, where SYNC rises). Budget: a step may run one cycle
; late (wait 1 reached in F+1); see notes.md for the arithmetic.

init:   set pins, 0          ; SYNC and SDATA low from cycle 1
        pull                 ; first CTRL
        wait 0 pin 0         ; skip the synchroniser's reset-high (cycle 2)
        jmp e1

frame:  wait 1 pin 0         ; W(-1): SYNC high, SDATA low
        set pins, 1
        wait 0 pin 0
        wait 1 pin 0         ; W(0): tag bit 15 = 1
        set pins, 3
        wait 0 pin 0
        wait 1 pin 0         ; W(1): tag bit 14 = CTRL bit 8 (command)
        out pins, 1
        wait 0 pin 0
        out x, 1             ; X = CTRL bit 7 (read)
        wait 1 pin 0         ; W(2): tag bit 13 = command and not read
        jmp !x, w2s          ;   SDATA already holds the command bit;
        set pins, 1          ;   a read clears it
w2s:    wait 0 pin 0
        wait 1 pin 0         ; W(3): tag bit 12 = 1
        set pins, 3
        wait 0 pin 0
        set y, 8
        wait 1 pin 0         ; W(4): tag bit 11 = 1 (no change)
        wait 0 pin 0
        wait 1 pin 0         ; W(5): tag bit 10 = 0
        set pins, 1
        wait 0 pin 0
tidle:  wait 1 pin 0         ; W(6)..W(14): tag bits 9..1 = 0, 9 steps
        wait 0 pin 0
        jmp y--, tidle
        wait 1 pin 0         ; W(15): tag bit 0 = 0, SYNC low
        set pins, 0
        wait 0 pin 0
        wait 1 pin 0         ; W(16): slot 1 bit 19 = read
        mov pins, x
        wait 0 pin 0
        set x, 16            ; slot 1: 17 outs (address, then zeros)
        set y, 3             ; four slots: 1 to 4

sbit:   wait 1 pin 0         ; one bit of the OSR; past bit 16 it gives 0
        out pins, 1
        wait 0 pin 0
        jmp x--, sbit
        wait 1 pin 0         ; idle step: slot bit 1 (0, no write)
        wait 0 pin 0
        pull                 ; DATA, LEFT, RIGHT, then the next CTRL
        set x, 17            ; slots 2 to 4: 18 outs (16 bits, 2 zeros)
        wait 1 pin 0         ; idle step: slot bit 0 (0, no write)
        wait 0 pin 0
        jmp y--, sbit
        set y, 5             ; W(96)..W(253): 18 + 5 x 28 = 158 idle steps
iin:    wait 1 pin 0
        wait 0 pin 0
        jmp x--, iin
        jmp y--, iout
e1:     wait 1 pin 0         ; W(254), also the first step after reset
        wait 0 pin 0
        out null, 7          ; drop CTRL bits 15..9
        jmp frame
iout:   wait 1 pin 0
        wait 0 pin 0
        set x, 26
        jmp iin
