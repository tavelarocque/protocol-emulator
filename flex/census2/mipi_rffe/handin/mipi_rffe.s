; MIPI RFFE bus master, thread 0.
; P0 = SCLK (push-pull, side-set), P1 = SDATA (open-drain: out/set/mov pins).
; Config (run_args.txt): sideset_base=0 sideset_count=1, out_base=1
; out_count=1, set_base=1 set_count=1, in_base=1, threshold=16,
; out_msb_first=1, in_msb_first=1, crc_poly=1, crc_init=1 (the CRC register
; is then the running odd-parity bit of the OUT bits), start = INIT.
;
; Clock template: "oK" = K cycles after the instruction that raises SCLK.
; The rising instruction (o0) runs at r-1 so its writes show at r; the
; falling instruction runs at o10. Every clock is exactly 20 cycles.
; Frames: the OSR holds the bits (MSB first), the ISR's count says when a
; frame is done (count 8 or 4 at the start, 16 = full = frame over).
; X = what to do after the frame's parity bit (state), Y = byte count n.
; States: 0 W (Y-- ? data frame : park), 1 HI_w, 2 HI_r, 3 A_r, 4 A_w,
;         5 LO_r, 6 LO_w, 7 TA (turnaround then read Y bytes).

.side_set 1

; ---------------- page 0: between sequences, build the command frame ------
; END is reached at o12 of the sequence's last clock (r+11). The next SSC is
; at r+140; SEQ runs at r+115 = S-25.
END:    set x, 11       side 0 [7]
endw:   jmp x-- endw    side 0 [7]      ; 12 x 8 = 96 cycles
SEQ:    pull            side 0          ; e0: header (stalls when words end)
        mov isr, osr    side 0          ; e1: ISR = header
        out null, 3     side 0          ; e2
        out y, 5        side 0          ; e3: Y = n
        out x, 4        side 0          ; e4: X = kind
        jmp !x K0       side 0          ; e5
        jmp x-- q1      side 0
q1:     jmp !x K1       side 0          ; e7
        jmp x-- q2      side 0
q2:     jmp !x K2       side 0          ; e9
        jmp x-- q3      side 0
q3:     jmp !x K3       side 0          ; e11
        jmp x-- q4      side 0
q4:     jmp !x K4       side 0          ; e13
        jmp x-- q5      side 0
q5:     jmp !x K5       side 0          ; e15
; kind 6, Extended Register Read Long: 00111 B2..B0 -> state HI_r
K6:     set x, 7        side 0          ; e16
        in x, 5         side 0
        mov x, y        side 0
        jmp x-- k6a     side 0
k6a:    in x, 3         side 0          ; e20: n-1
        set x, 2        side 0
        jmp CM0         side 0 [1]      ; e22 -> e24
; kind 0, Register 0 Write: 1 D6..D0 -> state W with Y = 0
K0:     set y, 1        side 0          ; e6
        in y, 1         side 0
        pull            side 0          ; data word
        mov y, osr      side 0
        in y, 7         side 0          ; e10
        set y, 0        side 0 [4]      ; e11
        jmp CM0         side 0 [7]      ; e16 -> e24
; kind 1, Register Write: 010 A4..A0 -> state W, Y = 1
K1:     set y, 2        side 0          ; e8
        jmp K12         side 0 [2]      ; e9 -> e12
; kind 2, Register Read: 011 A4..A0 -> state TA, Y = 1
K2:     set x, 7        side 0          ; e10
        set y, 3        side 0          ; e11
K12:    in y, 3         side 0          ; e12
        pull            side 0          ; address word
        mov y, osr      side 0
        in y, 5         side 0
        set y, 1        side 0
        jmp CM0         side 0 [6]      ; e17 -> e24
; kind 3, Extended Register Write: 0000 B3..B0 -> state A_w
K3:     in null, 4      side 0          ; e12
        mov x, y        side 0
        jmp x-- k3a     side 0
k3a:    in x, 4         side 0
        set x, 4        side 0
        jmp CM0         side 0 [6]      ; e17 -> e24
; kind 4, Extended Register Read: 0010 B3..B0 -> state A_r
K4:     set x, 2        side 0          ; e14
        in x, 4         side 0
        mov x, y        side 0
        jmp x-- k4a     side 0
k4a:    in x, 4         side 0
        set x, 3        side 0
        jmp CM0         side 0 [3]      ; e20 -> e24
; kind 5, Extended Register Write Long: 00110 B2..B0 -> state HI_w
K5:     set x, 6        side 0          ; e16
        in x, 5         side 0
        mov x, y        side 0
        jmp x-- k5a     side 0
k5a:    in x, 3         side 0
        set x, 1        side 0 [2]      ; e21 -> e24
; ISR = kind:SA:C. SSC: SDATA high at S, low at S+20, first clock at S+40.
CM0:    set pins, 1     side 0 [7]      ; e24 = S-1
        mov osr, isr    side 0          ; e32
        out null, 4     side 0          ; drop the kind: SA:C on top
        mov isr, null   side 0
        in null, 4      side 0          ; ISR count 4: 12 bits to send
        mov crc, null   side 0          ; parity starts here
        set page, 2     side 0 [6]
        set pins, 0     side 0 [7]      ; e44 = S+19
        nop             side 0 [7]
        jmp FL          side 0 [3]      ; e60 -> FL at e64 = S+39

; start: both lines low at once, then wait until END's place for S(0) = 400
.page 1
INIT:   set pins, 0     side 0 [7]      ; cycle 0
        set x, 31       side 0 [4]      ; cycle 8
initw:  jmp x-- initw   side 0 [7]      ; cycles 13 to 268
        set page, 0     side 0          ; 269
        jmp END         side 0          ; 270 -> END at 271, SEQ at 375

; ---------------- page 2: the bus engine ---------------------------------
.align
DP:     pull            side 0          ; o18: next data/address word
        out null, 8     side 0          ; o19: its byte on top
FL:     out pins, 1     side 1 [7]      ; o0: SCLK up, bit out
        in null, 1      side 1 [1]      ; o8: count it
        nop             side 0 [7]      ; o10: SCLK down
        jmp !isrf FL    side 0 [1]      ; o18
PC:     mov pins, crc   side 1          ; o0: parity bit
        mov crc, null   side 1          ; o1
        mov isr, null   side 1          ; o2
        in null, 8      side 1          ; o3: next frame or byte is 8 bits
        jmp !x ST0      side 1          ; o4
        jmp x-- p1      side 1
p1:     jmp !x ST1      side 1          ; o6
        jmp x-- p2      side 1
p2:     jmp !x ST2      side 1          ; o8
        jmp x-- p3      side 1
p3:     jmp !x ST3      side 0          ; o10: SCLK down
        jmp x-- p4      side 0
p4:     jmp !x ST4      side 0          ; o12
        jmp x-- p5      side 0
p5:     jmp !x ST5      side 0          ; o14
        jmp x-- p6      side 0
p6:     jmp !x ST6      side 0          ; o16
        nop             side 0 [2]      ; o17: state 7, TA
TA:     set pins, 0     side 1 [7]      ; o0: chip's bus park
        jmp y-- ta1     side 1 [1]      ; o8: Y = n-1
ta1:    nop             side 0 [7]      ; o10
        set pins, 1     side 0 [1]      ; o18: let go, shows at r(b)+18
RL:     nop             side 1 [7]      ; o0
        nop             side 1 [1]      ; o8
        nop             side 0 [3]      ; o10
        in pins, 1      side 0 [4]      ; o14: sample at r+13
        jmp !isrf RL    side 0          ; o19
RP:     nop             side 1 [7]      ; o0: slave's parity bit
        nop             side 1 [1]      ; o8
        push            side 0          ; o10
        in null, 8      side 0          ; o11
        jmp y-- rn      side 0 [6]      ; o12
        jmp SPARK       side 0          ; o19
rn:     jmp RL          side 0          ; o19
SPARK:  nop             side 1 [7]      ; o0: slave's bus park
        set pins, 0     side 1 [1]      ; o8: hold low, shows at r(e)+8
ENDX:   set page, 0     side 0          ; o10
        jmp END         side 0          ; o11 -> END at o12
.page 2
PARK:   set pins, 0     side 1 [7]      ; o0: chip's bus park
        jmp ENDX        side 1 [1]      ; o8 -> o10
ST0:    jmp y-- w1      side 1 [4]      ; o5: W
        nop             side 0 [7]      ; o10
        jmp PARK        side 0 [1]      ; o18 -> o20
w1:     jmp DP          side 0 [7]      ; o10 -> o18
ST1:    pull            side 1 [2]      ; o7: HI_w, address word, A15 on top
        set x, 6        side 0 [7]      ; o10: then LO_w
        jmp FL          side 0 [1]      ; o18 -> o20
ST2:    pull            side 1          ; o9: HI_r
        set x, 5        side 0 [7]      ; o10: then LO_r
        jmp FL          side 0 [1]
ST3:    set x, 7        side 0 [4]      ; o11: A_r, then TA
        jmp DP          side 0 [1]      ; o16 -> o18
ST4:    jmp DP          side 0 [4]      ; o13: A_w (X = 0 = W) -> o18
ST5:    set x, 7        side 0 [3]      ; o15: LO_r, then TA
        jmp FL          side 0          ; o19 -> o20
ST6:    jmp FL          side 0 [2]      ; o17: LO_w (X = 0 = W) -> o20
