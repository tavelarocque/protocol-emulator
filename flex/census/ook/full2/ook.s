; OOK transmitter, Manchester, 2000 bit/s at 1 MHz, P0 push-pull, thread 0.
; Config: out_msb_first=1, threshold=16, set_base=0, set_count=1 (default).
; Every pin write is a "set pins" at a half-bit boundary; the cycles between
; two consecutive writes are counted so that each half bit is exactly 250
; cycles (or 500 where a level holds over a boundary with no transition).
; Registers: X = bit value, then the delay counter; Y = preamble counter,
; then the "last byte" flag. OSR = current host word (msb first).

        set pins, 0             ; P0 low at once (the pin starts high)
frame:  pull                    ; first word of the next frame (stalls when none)
        set y, 11               ; gap: 12 x 514 cycles, about 6.2 ms of low
gapo:   set x, 31
gapi:   jmp x-- gapi [15]
        jmp y-- gapo
        set y, 15               ; 16 preamble bits
; ---- preamble: 16 ones. A window 1+1+248 = 250, B window 1+1+240+8 = 250
pre:    set pins, 1             ; first half of a 1 (rise, frame time zero for bit 0)
        set x, 30
pa:     jmp x-- pa [7]
        set pins, 0             ; second half
        set x, 29
pb:     jmp x-- pb [7]
        jmp y-- pre [7]
; ---- sync 0101: line low until 250 into bit 16, then levels hold 500 each
        set x, 30 [1]           ; 2 + 248 = 250 (bit 16 first half, low)
w0:     jmp x-- w0 [7]
        set pins, 1 [2]         ; mid bit 16: rise; 3+1+496 = 500
        set x, 30
s1:     jmp x-- s1 [15]
        set pins, 0 [2]         ; mid bit 17: fall
        set x, 30
s2:     jmp x-- s2 [15]
        set pins, 1 [2]         ; mid bit 18: rise
        set x, 30
s3:     jmp x-- s3 [15]
        set pins, 0             ; mid bit 19: fall; 1+1+232+8, then 8 in nb2..bit = 250
        set x, 28
s4:     jmp x-- s4 [7]
        jmp nb2 [7]
; ---- next byte of the frame
nextbyte: pull
nb2:    out null, 7             ; drop bits 15..9
        out y, 1                ; bit 8: last byte flag
        jmp bit [3]
bpad:   nop [7]                 ; next bit of the same byte
bit:    out x, 1                ; data bit, msb first
        jmp !x zero
        set pins, 1             ; 1: first half high
        set x, 30
o1:     jmp x-- o1 [7]
        set pins, 0             ; 1: second half low
        set x, 28
o2:     jmp x-- o2 [7]
        jmp tail [4]
zero:   set pins, 0             ; 0: first half low
        set x, 30
z1:     jmp x-- z1 [7]
        set pins, 1             ; 0: second half high
        set x, 28
z2:     jmp x-- z2 [7]
        nop [4]
tail:   jmp !osre bpad          ; more bits in this byte
        jmp !y nextbyte         ; not the last byte
        nop [8]
        set pins, 0             ; end of the last bit: line low
        jmp frame
