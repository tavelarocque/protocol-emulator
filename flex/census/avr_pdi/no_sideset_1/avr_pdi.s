; AVR PDI programmer for the protocol emulator, thread 0, 50 MHz core.
; P0 = PDI_CLK (push-pull), P1 = PDI_DATA (open-drain).
; Config: set_base=0 set_count=1 (set pins = clock only),
;         out_base=1 out_count=1 (out/mov pins = data only), in_base=1,
;         crc_poly=1 (CRC register bit 0 = running XOR = even parity bit),
;         timeout_vector=1, timeout=T (start-up delay, see notes.md).
; Every slot is 50 cycles. "t" is the cycle in which `set pins 0` runs;
; the falling edge shows at t+1 (= 2000+50k), the rising edge at t+26.
; P1 may change only when visible in [t+1, t+21].
;
; Registers: X loop counter / scratch, Y answer frames left,
;            OSR host word, ISR decode scratch and received byte.

init:   wait 0 pin 0 timeout    ; P0 is high: always times out -> address 1
        set x, 15               ; 16 enable slots; Y = 0 so idle ends in fstart

; ---- idle slot, X+1 times. Then: Y = 0 -> fstart, else -> samp
idle:   set pins 0 [15]         ; t      clock low
        nop [8]                 ; t+16
        set pins 1 [15]         ; t+25   clock high
        jmp x-- idle2 [6]       ; t+41
        jmp !y fstart           ; t+48
        set x, 7                ; t+49   8 bits to sample

; ---- sample one bit of the ATxmega's frame, 8 slots
samp:   set pins 0 [15]         ; t
        in pins, 1 [8]          ; t+16   level set at t+6, seen from t+8
        set pins 1 [15]         ; t+25
        jmp x-- samp [8]        ; t+41

; ---- parity slot of the answer frame: push byte, choose idle count
post:   set pins 0 [3]          ; t
        push                    ; t+4
        jmp y-- p1              ; t+5    one frame fewer
p1:     set x, 2                ; t+6    more frames: stop, stop, start
        jmp !y p3               ; t+7
        jmp p4                  ; t+8
p3:     set x, 3                ; t+8    last frame: stop, stop, idle, idle
p4:     nop [15]                ; t+9
tail:   set pins 1 [15]         ; t+25
        jmp idle [8]            ; t+41 -> idle at t+50

idle2:  jmp idle [1]            ; t+48 -> idle at t+50

; ---- start slot of the chip's frame (or first of the 16 end slots)
fstart: pull                    ; t-1    (stalls forever after the end word)
        set pins 0              ; t
        mov isr, osr            ; t+1
        in null, 15             ; t+2    ISR = word >> 15
        mov x, isr              ; t+3    1 for the end word
        jmp !x notend           ; t+4
        set x, 14 [15]          ; t+5    end: 15 more idle slots, then pull stalls
        jmp tail [3]            ; t+21
notend: mov pins, null          ; t+5    start bit 0
        mov crc, null [2]       ; t+6    parity restarts
        set x, 7 [15]           ; t+9
        set pins 1 [15]         ; t+25
        nop [8]                 ; t+41

; ---- 8 data bits, LSB first
dbit:   set pins 0 [8]          ; t
        out pins, 1 [15]        ; t+9
        set pins 1 [15]         ; t+25
        jmp x-- dbit [8]        ; t+41

; ---- parity slot; also take N and build 129 in the ISR
par:    set pins 0              ; t
        mov x, crc              ; t+1    bit 0 = XOR of the data bits
        mov pins, x             ; t+2
        out y, 4 [1]            ; t+3    Y = answer length
        set x, 1                ; t+5
        in x, 1                 ; t+6
        in null, 6              ; t+7
        in x, 1                 ; t+8
        in null, 8 [15]         ; t+9    ISR = 0x0081 = 129
        set pins 1 [15]         ; t+25
        nop [8]                 ; t+41

; ---- first stop bit; then 1 idle slot (no answer) or 130 (answer)
s10:    set pins 0              ; t
        mov pins, x             ; t+1    X = 1: release P1
        mov x, isr              ; t+2
        jmp !y s10b             ; t+3
        jmp s10c                ; t+4
s10b:   set x, 0                ; t+4
s10c:   mov isr, null [15]      ; t+5    empty ISR for the answer
        jmp tail [3]            ; t+21
