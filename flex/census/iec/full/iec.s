; IEC (Commodore serial bus) controller, thread 0, 1 MHz core clock.
; Pins: P0 DATA, P1 CLK, P2 ATN, all open-drain.
; CLK  : side-set (sideset_base=1, sideset_count=1): every instruction says
;        what CLK is (side 0 = pulled low, side 1 = released).
; ATN  : set pins (set_base=2, set_count=1): 0 = low, 1 = released.
; DATA : out pins / mov pins (out_base=0, out_count=1).
; ISR shifts left (in_msb_first=1) and is used to build command bytes.
; Y holds what the byte being sent is:
;   0 data byte (not last), 1 last data byte (EOI), 2 SECOND, 3 LISTEN,
;   4 UNLISTEN.
; Only the low 8 bits of the OSR are ever sent, so bits above them are
; don't-care.

        .side_set 1

; ---- wait for a free bus, take a header, build LISTEN and SECOND ----
idle:
        wait 1 pin 0    side 1          ; bus free (DATA released)
        pull            side 1          ; header (stalls here when no words: all released)
        set x, 1        side 1
        in x, 3         side 1          ; ISR = ..001
        out x, 5        side 1          ; X = D
        in x, 5         side 1          ; ISR low byte = 001DDDDD = 0x20 + D
        out null, 3     side 1
        out y, 4        side 1          ; Y = S
        mov osr, isr    side 1          ; OSR = LISTEN
        set x, 6        side 1
        in x, 4         side 1          ; ..0110
        in y, 4         side 1          ; ISR low byte = 0110SSSS = 0x60 + S
        set x, 28       side 1
i1:     jmp x-- i1      side 1 [7]      ; 29 * 8 = 232 cycles
        set pins, 0     side 1          ; ATN low (~248 after bus free)
        set y, 3        side 0          ; CLK low one cycle later; byte is LISTEN
        wait 0 pin 0    side 0          ; device: "I am here"
        jmp predelay    side 0

; ---- after SECOND: release ATN, then the data bytes ----
aftersecond:
        set pins, 1     side 0          ; ATN released (CLK stays low)
loaddata:
        pull            side 0          ; data word
        out y, 8        side 0          ; Y = byte
        out x, 1        side 0          ; X = EOI flag
        mov osr, y      side 0          ; OSR = byte
        mov y, x        side 0          ; Y = 0 (more) or 1 (last)
predelay:
        set x, 24       side 0
pd:     jmp x-- pd      side 0 [7]      ; 25 * 8 = 200 cycles
; ---- send one byte (OSR), steps 1 to 6 ----
send:
        set x, 1        side 1          ; step 1: release CLK
        wait 1 pin 0    side 1          ; step 2: device ready for data
        jmp x!=y n1     side 1          ; not the EOI byte: go straight on
        wait 0 pin 0    side 1          ; EOI: device acknowledges with a pulse
        wait 1 pin 0    side 1
n1:     jmp x-- n1      side 1 [7]      ; X = 1: 16 cycles
bit:
        out pins, 1     side 0          ; CLK low, DATA = bit
        set x, 3        side 0
lo:     jmp x-- lo      side 0 [7]      ; 32 cycles
        set x, 3        side 1          ; CLK released
hi:     jmp x-- hi      side 1 [7]      ; 32 cycles, leaves X = 0xFFFF
        jmp !osre bit   side 0          ; CLK low (fall after the bit)
        mov pins, x     side 0 [7]      ; release DATA (bit 0 of X is 1)
        wait 0 pin 0    side 0          ; step 6: acknowledge
        set x, 5        side 0
pa:     jmp x-- pa      side 0 [7]      ; 48 cycles
; ---- what next, from Y ----
        jmp !y loaddata side 0          ; 0: next data byte
        jmp y-- d1      side 0
d1:     jmp !y lastdata side 0          ; 1: last data byte sent
        jmp y-- d2      side 0
d2:     jmp !y aftersecond side 0       ; 2: SECOND sent
        jmp y-- d3      side 0
d3:     jmp !y afterlisten side 0       ; 3: LISTEN sent
; 4: UNLISTEN sent: release ATN, then CLK, and wait for the bus to be free
        set pins, 1     side 0          ; ATN released
        jmp idle        side 1          ; CLK released

afterlisten:
        mov osr, isr    side 0          ; OSR = SECOND
        set y, 2        side 0
        jmp predelay    side 0

lastdata:
        set pins, 0     side 0          ; ATN low
        set x, 31       side 0
        in null, 2      side 0
        in x, 5         side 0
        in x, 1         side 0          ; ISR low byte = 00111111 = 0x3F
        mov osr, isr    side 0          ; OSR = UNLISTEN
        set y, 4        side 0
        jmp predelay    side 0
