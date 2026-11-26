; FSI master for the protocol emulator, thread 0.
;
; Pins: P0 = FSI_DAT (open-drain, set pins), P1 = FSI_CLK (push-pull, side-set).
; FSI_CLK is 2.5 MHz: one clock ("slot") is 20 cycles. In a slot whose falling
; edge shows at cycle F, the instruction executed at F-1 carries side 0 and the
; one executed at F+9 carries side 1 (rising edge shows at F+10). Every
; instruction executed in F-1..F+8 says side 0, in F+9..F+18 side 1.
; Comments give the cycle each instruction executes in, relative to F.
;
; Configuration (run_args.txt): start=21, set_base=0, set_count=1,
; sideset_base=1, sideset_count=1, out_msb_first=1, in_msb_first=1,
; threshold=16, crc_poly=0xE, crc_init=0xE (the CRC state after START=1),
; crc_in=1 (the CRC register follows IN; the TX loops feed it with `in x, 1`).
;
; Registers while sending: OSR = the bits of the current field, bottom-
; justified, its shift count set so that the field ends when the OSR is empty;
; X = the bit; Y = the type (op word bits 2..0: RW S1 S0); ISR = CRC feed
; (junk), its count marks the header phase.
; While receiving: Y = the pin snapshot of a released line with FSI_CLK low,
; X = the sample, ISR = the word being received, OSR = the type (bits 15..13
; after a shift) for deciding what follows.

.side_set 1

; ============================ page 0 ============================

; header/address loop continuation
CAB:    nop             side 0 [6]      ; F+2..F+8
        jmp LAB         side 1 [6]      ; F+9..F+15 -> LAB at F+16

; idle loop continuation
IC:     nop             side 1 [7]      ; F+10..F+17
        jmp I           side 1          ; F+18 -> I at F+19

; entry into the idle loop with 24 slots (4 response CRC + 20 idle),
; reached at F (the falling-edge instruction ran at F-1 in page 2)
I23:    set x, 23       side 0 [5]      ; F..F+5
        jmp I1          side 0          ; F+6 -> I1 at F+7

; after the header field: set up the address low field
EA:     mov osr, y      side 0          ; F+3
        out null, 14    side 0          ; F+4
        out x, 1        side 0          ; F+5   X = S1 (4-byte access)
        jmp !x A2       side 0 [2]      ; F+6..F+8
        pull            side 1          ; F+9   4 bytes: address bits 15..1 then "11"
        out x, 15       side 1          ; F+10  X = address >> 1
        mov osr, x      side 1          ; F+11
        out null, 1     side 1          ; F+12  15 bits left
        jmp LAB         side 1 [2]      ; F+13..F+15
A2:     pull            side 1 [5]      ; F+9..F+14   all 16 address bits
        jmp LAB         side 1          ; F+15

; after the address field, R1 / W2 / R2: field = S0 (already in the OSR)
BJ:     jmp TBE         side 1 [5]      ; F+9..F+14
; after the address field, W1: field = data word bits 8..0 (size bit 0 + byte)
BW1:    pull            side 0 [4]      ; F+4..F+8
        out null, 7     side 1 [4]      ; F+9..F+13
        jmp TBE         side 1          ; F+14

start:  set x, 3        side 1          ; c0    4 idle clocks before the first START
        set y, 11       side 1 [1]      ; c1..c2
burn:   jmp y-- burn    side 1 [7]      ; c3..c98

; idle loop: one slot per pass, data released; X+1 slots, then the next START
I:      nop             side 0 [7]      ; F-1..F+6
I1:     nop             side 0 [1]      ; F+7..F+8
        jmp x-- IC      side 1          ; F+9
; last idle slot: fetch the operation word (stalls here, clock high, when the
; host has no more transactions). N = F+20 is the START clock's falling edge.
TXS:    pull            side 1          ; N-10
        out null, 11    side 1          ; N-9
        out x, 2        side 1          ; N-8   X = slave ID
        in x, 2         side 1          ; N-7
        set x, 4        side 1          ; N-6
        in x, 3         side 1          ; N-5   ABS_ADR 100
        out y, 3        side 1          ; N-4   Y = RW S1 S0
        mov osr, y      side 1          ; N-3
        out null, 13    side 1          ; N-2
        set pins, 0     side 0          ; N-1   START (bit 1: pull low)
        out x, 1        side 0          ; N     X = RW
        in x, 1         side 0          ; N+1
        pull            side 0          ; N+2   address bits 20..16
        mov x, osr      side 0          ; N+3
        in x, 5         side 0          ; N+4   ISR low 11 bits = ID 100 RW A20..A16
        mov osr, isr    side 0          ; N+5
        out null, 5     side 0          ; N+6   11 bits left
        mov isr, null   side 0          ; N+7   ISR count 0: marks the header phase
        mov crc, null   side 0          ; N+8   CRC restarts from the START state
        nop             side 1 [6]      ; N+9..N+15

; send the OSR's remaining bits, one per slot (header, then address low)
LAB:    out x, 1        side 1          ; F-4
        in x, 1         side 1          ; F-3   CRC
        jmp !x ZAB      side 1          ; F-2
        set pins, 0     side 0          ; F-1   bit 1
        jmp KAB         side 0          ; F
ZAB:    set pins, 1     side 0 [1]      ; F-1..F  bit 0
KAB:    jmp !osre CAB   side 0          ; F+1
        jmp !isrf EA    side 0          ; F+2   header done (ISR count 11)
; after the address field (ISR full)
EB:     jmp !y BW1      side 0          ; F+3   W1
        mov osr, y      side 0          ; F+4
        out null, 14    side 0          ; F+5
        out x, 1        side 0          ; F+6   X = S1; OSR now holds S0, 1 bit left
        jmp !x BJ       side 0 [1]      ; F+7..F+8
        set x, 3        side 1          ; F+9   4 bytes: field "11"
        mov osr, x      side 1          ; F+10
        out null, 14    side 1 [3]      ; F+11..F+14
TBE:    set page, 1     side 1          ; F+15  falls into page 1 (LCD) at F+16

; ============================ page 1 ============================

; send the OSR's remaining bits: size/data fields
LCD:    out x, 1        side 1          ; F-4
        in x, 1         side 1          ; F-3   CRC
        jmp !x ZCD      side 1          ; F-2
        set pins, 0     side 0          ; F-1
        jmp KCD         side 0          ; F
ZCD:    set pins, 1     side 0 [1]      ; F-1..F
KCD:    jmp !osre CCD   side 0          ; F+1
        mov osr, y      side 0          ; F+2
        out null, 13    side 0          ; F+3
        out x, 1        side 0          ; F+4   X = RW
        jmp !x CW       side 0          ; F+5
        jmp CS          side 0 [2]      ; F+6..F+8   read: CRC next
CW:     jmp !y CWZ      side 0          ; F+6   write with no data left
        jmp y-- CWD     side 0 [1]      ; F+7..F+8   Y-1: 2 -> 1 -> 0
CWD:    pull            side 1 [5]      ; F+9..F+14  16 data bits
        jmp LCD         side 1          ; F+15
CWZ:    jmp CS          side 0 [1]      ; F+7..F+8
CCD:    nop             side 0 [6]      ; F+2..F+8
        jmp LCD         side 1 [6]      ; F+9..F+15

; CRC: Y = the register (first bit to send in bit 0); send bits until the
; rest are 0 (a 0 bit is a released line, the same as not sending it)
CS:     mov isr, y      side 1          ; F+9   keep the type in the ISR
        mov y, crc      side 1 [4]      ; F+10..F+14
CL:     mov osr, y      side 1          ; F-5
        out null, 15    side 1          ; F-4
        out x, 1        side 1          ; F-3   X = Y bit 0
        jmp !x CZ       side 1          ; F-2
        set pins, 0     side 0          ; F-1
        jmp CJ          side 0          ; F
CZ:     set pins, 1     side 0 [1]      ; F-1..F
CJ:     mov osr, y      side 0          ; F+1
        out y, 15       side 0 [6]      ; F+2..F+8   Y >>= 1
        jmp !y CX       side 1          ; F+9
        jmp CL          side 1 [4]      ; F+10..F+14
CX:     set pins, 1     side 1          ; F+10  release FSI_DAT (clock high)
        mov osr, isr    side 1          ; F+11  type into the OSR
        out null, 13    side 1 [6]      ; F+12..F+18  OSR top: RW S1 S0
; first slot after the command: learn the released-line pin snapshot
RXE:    nop             side 0 [5]      ; F-1..F+4
        mov y, pins     side 0 [3]      ; F+5..F+8
        nop             side 1 [7]      ; F+9..F+16
        nop             side 1 [1]      ; F+17..F+18
; wait for the slave's START
W:      nop             side 0 [5]      ; F-1..F+4
        mov x, pins     side 0          ; F+5   sample (bit visible F-4..F+15)
        jmp x!=y FOUND  side 0          ; F+6
        nop             side 0 [1]      ; F+7..F+8
        nop             side 1 [7]      ; F+9..F+16
        jmp W           side 1 [1]      ; F+17..F+18

        nop             side 1          ; padding (never executed) so that
        nop             side 1          ; FOUND ends the page and falls into
        nop             side 1          ; page 2
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
        nop             side 1
FOUND:  mov isr, null   side 0          ; F+7
        in null, 12     side 0          ; F+8   4 bits to read: ID, ID, code, code
        nop             side 1 [7]      ; F+9..F+16
        set page, 2     side 1 [1]      ; F+17..F+18

; ============================ page 2 ============================

RQ:     nop             side 0 [5]      ; F-1..F+4
        mov x, pins     side 0          ; F+5
        jmp x!=y RQ1    side 0          ; F+6
        in null, 1      side 0          ; F+7   line high: bit 0
        jmp RQJ         side 0          ; F+8
RQ1:    in y, 1         side 0 [1]      ; F+7..F+8  line low: bit 1 (Y bit 0 is 1)
RQJ:    jmp !isrf RQC   side 1          ; F+9
        mov x, isr      side 1          ; F+10  ID ID C C
        mov isr, null   side 1          ; F+11
        in x, 2         side 1          ; F+12
        mov x, isr      side 1          ; F+13  X = response code
        push            side 1          ; F+14
        jmp !x ACK      side 1          ; F+15
        jmp TOI         side 1 [1]      ; F+16..F+17  ERR_A / ERR_C: no data
ACK:    out x, 1        side 1          ; F+16  X = RW
        jmp !x TOI      side 1          ; F+17  write: no data
        mov x, osr      side 1          ; F+18  S1 S0 at the top
        jmp !x PRE      side 0          ; F+19  (falling edge of the first data clock)
        nop             side 0 [3]      ; F..F+3
PJ:     jmp RD1         side 0          ; F+4
PRE:    in null, 8      side 0 [2]      ; F..F+2   1 byte: 8 bits to read
        jmp PJ          side 0          ; F+3
RQC:    nop             side 1 [7]      ; F+10..F+17
        jmp RQ          side 1          ; F+18

; receive data bits until the ISR is full, then push
RD:     nop             side 0 [5]      ; F-1..F+4
RD1:    mov x, pins     side 0          ; F+5
        jmp x!=y RD2    side 0          ; F+6
        in null, 1      side 0          ; F+7
        jmp RDJ         side 0          ; F+8
RD2:    in y, 1         side 0 [1]      ; F+7..F+8
RDJ:    jmp !isrf RDC   side 1          ; F+9
        push            side 1          ; F+10
        out x, 1        side 1          ; F+11  S1: another 16 bits follow (once)
        jmp !x DXL      side 1          ; F+12
        mov osr, null   side 1 [4]      ; F+13..F+17
        jmp RD          side 1          ; F+18
DXL:    jmp TOI         side 1 [4]      ; F+13..F+17
RDC:    nop             side 1 [7]      ; F+10..F+17
        jmp RD          side 1          ; F+18

; back to page 0: idle for the response CRC and the 20 idle clocks
TOI:    set page, 0     side 1          ; F+18
        jmp I23         side 0          ; F+19 -> I23 at F+20
